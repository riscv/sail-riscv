// See LICENSE for license details.

#include <map>
#include <optional>
#include <memory>
#include "mem.h"
#include "semihosting.h"
#include "riscv_sail.h"
#include "riscv_config.h"
#include "riscv_semihosting.h"
#include <functional>
#include <filesystem>
#include "log.h"

extern sbits zPC;

namespace semihosting {
std::vector<std::unique_ptr<FileBase>> files = {};

File::File(const std::string &name, const char *mode)
    : name(name)
    , mode(mode)
    , file(nullptr)
{
}

File::~File()
{
  if (file) {
    fclose(file);
  }
}

const std::array<uint8_t, 5> features {
    0x53, 0x48, 0x46, 0x42, // Magic
    0x3,                    // EXT_EXIT_EXTENDED, EXT_STDOUT_STDERR
};

int64_t File::open()
{
  if (name == ":tt") {
    if (mode[0] == 'r') {
      file = stdin;
    } else if (mode[0] == 'w') {
      file = stdout;
    } else if (mode[0] == 'a') {
      file = stderr;
    } else {
      INFO_IF(config_enable_semihosting,
              "WARN: Unknown file mode for the ':tt' special file");
      return -EINVAL;
    }
    return 0;
  } else {
    std::string real_mode(mode);
    if (real_mode[0] == 'w')
      real_mode[0] = 'a';
    file = fopen(name.c_str(), real_mode.c_str());
    return file ? 0 : -errno;
  }
}

int64_t File::read(uint8_t *buf, uint64_t size)
{
  if (!file) {
    PANIC_IF(config_enable_semihosting, "Trying to read from a closed file\n");
  }
  size_t ret = fread(buf, 1, size, file);
  if (ret == 0) {
    // Error or EOF. Assume errors are due to invalid file
    // operations (e.g., reading a write-only stream).
    return ferror(file) ? -EINVAL : 0;
  } else {
    return ret;
  }
}

int64_t File::write(const uint8_t *buf, uint64_t size)
{
  return fwrite(buf, 1, size, file);
}

int64_t File::seek(uint64_t pos)
{
  return fseek(file, pos, SEEK_SET);
}
int64_t File::flen()
{
  // TODO:
  return 0;
}

bool File::isTTY() const
{
  // TODO:
  return false;
}
int64_t File::close()
{
  fclose(file);
  file = nullptr;
  return 0;
}

FileFeatures::FileFeatures(const std::string &name, const char *mode)
    : name(name)
    , mode(mode)
{
}

int64_t FileFeatures::read(uint8_t *buffer, uint64_t size)
{
  int64_t len = 0;
  for (; len < size && pos < features.size(); pos++)
    buffer[len++] = features[pos];
  return len;
}

int64_t FileFeatures::seek(uint64_t _pos)
{
  if (_pos < features.size()) {
    pos = _pos;
    return 0;
  } else {
    return -ENXIO;
  }
}
int64_t FileFeatures::flen()
{
  return features.size();
}

static RetErrno retError(SemiErrno e)
{
  return RetErrno((uint64_t)-1, e);
}
static RetErrno retOK(uint64_t r)
{
  return RetErrno(r, 0);
}

const std::filesystem::path &get_current_dir()
{
  static const std::filesystem::path g_currentDir
      = std::filesystem::current_path();
  return g_currentDir;
}

std::string get_full_path(const std::string &fname)
{
  if (!fname.empty() && fname.front() != '/' && fname != ":tt"
      && fname != ":semihosting-features") {
    std::filesystem::path full_path = get_current_dir() / fname;
    return full_path.string();
  }
  return fname;
}
std::unique_ptr<FileBase> create_file_object(const std::string &fname,
                                             const char *mode)
{
  if (fname == ":semihosting-features") {
    return std::make_unique<FileFeatures>(fname, mode);
  } else {
    return std::make_unique<File>(fname, mode);
  }
}

RetErrno callOpen(Context *, const uint64_t name_base, int fmode,
                  size_t name_size)
{
  const char *mode = fmode < fmodes.size() ? fmodes[fmode] : nullptr;

  INFO_IF(config_enable_semihosting,
          "Semihosting SYS_OPEN(name_base: 0x%lx, fmode: %i[%s], size: %ld)\n",
          (uint64_t)name_base, fmode, mode ? mode : "-", name_size);

  if (!mode || !name_base)
    return retError(EINVAL);

  std::optional<std::string> fname
      = mem::read_string((const char *)name_base, name_size);
  if (!fname.has_value())
    return retError(ERANGE);

  std::unique_ptr<FileBase> file
      = create_file_object(get_full_path(*fname), mode);

  INFO_IF(config_enable_semihosting, "Semihosting SYS_OPEN(name: \"%s\")\n",
          fname.value().c_str());
  int ret = file->open();
  if (ret < 0) {
    return retError(-ret);
  } else {
    files.push_back(std::move(file));
    return retOK(files.size() - 1);
  }
}

RetErrno callClose(Context *, Handle handle)
{
  if (handle > files.size()) {
    INFO_IF(config_enable_semihosting,
            "Semihosting SYS_CLOSE(%ld): Illegal file\n", handle);
    return retError(EBADF);
  }
  std::unique_ptr<FileBase> &file = files[handle];
  int64_t error = file->close();
  if (error < 0) {
    return retError(-error);
  } else {
    // Zap the pointer and free the entry in the file table as well.
    files[handle].reset();
    return retOK(0);
  }
}

RetErrno callWriteC(Context *, const char c)
{
  INFO_IF(config_enable_semihosting, "Semihosting SYS_WRITEC('%c')\n", c);
  putchar(c);
  return retOK(0);
}
RetErrno callWrite(Context *, Handle handle, Addr addr, size_t size)
{
  if (handle > files.size() || !files[handle])
    return RetErrno(size, EBADF);

  INFO_IF(config_enable_semihosting, "Semihosting SYS_WRITE(%lx, %ld)\n", addr,
          size);
  std::vector<uint8_t> buffer(size);
  mem::read(addr, buffer.data(), buffer.size());
  int64_t ret = files[handle]->write(buffer.data(), buffer.size());
  if (ret < 0) {
    // No bytes written (we're returning the number of bytes not written)
    return RetErrno(size, -ret);
  } else {
    // Return the number of bytes not written
    return RetErrno(size - ret, 0);
  }
}

RetErrno callWrite0(Context *, const char *s)
{
  INFO_IF(config_enable_semihosting, "Semihosting SYS_WRITE0(...)\n");
  std::string str = mem::read_string(s);
  printf("%s", str.c_str());
  return retOK(0);
}

// code: The exception type, which is one of the set of reason codes in the
// above tables.
// subcode: A subcode, whose meaning depends on the code.
RetErrno callExit(Context *, uint64_t code, uint64_t subcode)
{
  INFO_IF(config_enable_semihosting,
          "Semihosting SYS_EXIT(code: %ld, subcode: %ld)\n", code, subcode);
  zhtif_exit_code = subcode;
  zhtif_done = true;
  return retOK(0);
}

RetErrno callExitExtended(Context *tc, uint64_t code, uint64_t subcode)
{
  callExit(tc, code, subcode);
  return retOK(0);
}

RetErrno callRead(Context *, Handle handle, Addr addr, size_t size)
{
  if (handle > files.size() || !files[handle])
    return RetErrno(size, EBADF);

  std::vector<uint8_t> buffer(size);
  int64_t ret = files[handle]->read(buffer.data(), buffer.size());
  if (ret < 0) {
    return RetErrno(size, -ret);
  } else {
    if (ret > buffer.size()) {
      PANIC_IF(config_enable_semihosting, "Read longer than buffer size.\n");
    };
    mem::write(addr, buffer.data(), ret);
    return retOK(size - ret);
  }
}

RetErrno callReadC(Context *)
{
  char c = getchar();
  return retOK(c);
}

template <typename... Args, size_t... I>
auto read_args(uint64_t base_addr, std::index_sequence<I...>)
{

  const size_t XLEN_BYTES = zxlen / 8;
  // read args
  // addr based on xlen acc
  // size based on sizeof<Arg>
  return std::make_tuple(
      mem::read<std::tuple_element_t<I, std::tuple<Args...>>>(
          base_addr + I * XLEN_BYTES)...);
}

template <typename Ret, typename... Args>
void invoke(Ret (*func)(Context *, Args...), Context *ctx)
{
  // Collect args from memory, addr based on xlen, size based on sizeof<Arg>
  auto indexes = std::index_sequence_for<Args...> {};
  auto args_tuple = read_args<Args...>(ctx->base_addr, indexes);
  auto full_tuple = std::tuple_cat(std::make_tuple(ctx), args_tuple);

  // Do semihosting call
  Ret res = std::apply(func, full_tuple);

  // Write return value to A0
  zwX(10, sbits {zxlen, res.first});
}

using Dispatcher = std::function<void(Context *)>;

template <typename Ret, typename... Args>
static Dispatcher make_dispatcher(Ret (*func)(Context *, Args...))
{
  return [=](Context *ctx) { invoke(func, ctx); };
}

const std::map<uint64_t, Dispatcher> handlers = {
    {SYS_OPEN,          make_dispatcher(callOpen)        },
    {SYS_CLOSE,         make_dispatcher(callClose)       },
    {SYS_WRITEC,        make_dispatcher(callWriteC)      },
    {SYS_WRITE0,        make_dispatcher(callWrite0)      },
    {SYS_WRITE,         make_dispatcher(callWrite)       },
    {SYS_READ,          make_dispatcher(callRead)        },
    {SYS_READC,         make_dispatcher(callReadC)       },
    {SYS_EXIT,          make_dispatcher(callExit)        },
    {SYS_EXIT_EXTENDED, make_dispatcher(callExitExtended)}
};

}

// Prefix = 0x01f01013, // slli x0, x0, 0x1f Entry NOP
// EBreak = 0x00100073, // ebreak            Break to debugger
// Suffix = 0x40705013, // srai x0, x0, 7    NOP encoding semihosting
bool is_semihosting()
{
  return (mem::read<uint32_t>(zPC.bits - 4) == 0x01f01013)
      && (mem::read<uint32_t>(zPC.bits) == 0x00100073)
      && (mem::read<uint32_t>(zPC.bits + 4) == 0x40705013);
}

unit semihosting_call()
{
  uint64_t op = zrX(10).bits;
  uint64_t addr = zrX(11).bits;

  if (config_enable_semihosting) {
    INFO_IF(config_enable_semihosting, "call semihosting op=%lx\n", op);
  }
  auto it = semihosting::handlers.find(op);
  if (it != semihosting::handlers.end()) {
    semihosting::Context ctx(addr);
    it->second(&ctx);
  } else {
    PANIC_IF(config_enable_semihosting, "Error: Unknown syscall 0x%lx\n", op);
  }
  return UNIT;
}
