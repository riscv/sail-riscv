// See LICENSE for license details.

#include <map>
#include <optional>
#include <memory>
#include <functional>
#include <filesystem>
#include <cmath>
#include <unistd.h>
#include "semihosting.h"
#include "riscv_semihosting.h"

namespace semihosting {

RiscvSemihosting::File::File(const std::string &name, const char *mode)
    : name(name)
    , mode(mode)
    , file(nullptr)
{
}

RiscvSemihosting::File::~File()
{
  if (file) {
    fclose(file);
  }
}

const std::array<uint8_t, 5> features {
    0x53, 0x48, 0x46, 0x42, // Magic
    0x3,                    // EXT_EXIT_EXTENDED, EXT_STDOUT_STDERR
};

int64_t RiscvSemihosting::File::open()
{
  if (name == ":tt") {
    if (mode[0] == 'r') {
      file = stdin;
    } else if (mode[0] == 'w') {
      file = stdout;
    } else if (mode[0] == 'a') {
      file = stderr;
    } else {
      printf("Unknown file mode for the ':tt' special file");
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

int64_t RiscvSemihosting::File::read(uint8_t *buf, uint64_t size)
{
  if (!file) {
    EXIT_FAILURE_WITH("Trying to read from a closed file\n");
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

int64_t RiscvSemihosting::File::write(const uint8_t *buf, uint64_t size)
{
  return fwrite(buf, 1, size, file);
}

int64_t RiscvSemihosting::File::seek(uint64_t pos)
{
  return fseek(file, pos, SEEK_SET);
}
int64_t RiscvSemihosting::File::flen()
{
  errno = 0;
  long pos = ftell(file);
  if (pos < 0)
    return -errno;

  if (fseek(file, 0, SEEK_END) != 0)
    return -errno;

  long len = ftell(file);
  if (len < 0)
    return -errno;

  if (fseek(file, pos, SEEK_SET) != 0)
    return -errno;

  return 0;
}

bool RiscvSemihosting::File::isTTY() const
{
  return file == stdout || file == stderr || file == stdin;
}

int64_t RiscvSemihosting::File::close()
{
  fclose(file);
  file = nullptr;
  return 0;
}

RiscvSemihosting::FileFeatures::FileFeatures(const std::string &name,
                                             const char *mode)
    : name(name)
    , mode(mode)
{
}

int64_t RiscvSemihosting::FileFeatures::read(uint8_t *buffer, uint64_t size)
{
  int64_t len = 0;
  for (; len < size && pos < features.size(); pos++)
    buffer[len++] = features[pos];
  return len;
}

int64_t RiscvSemihosting::FileFeatures::seek(uint64_t _pos)
{
  if (_pos < features.size()) {
    pos = _pos;
    return 0;
  } else {
    return -ENXIO;
  }
}
int64_t RiscvSemihosting::FileFeatures::flen()
{
  return features.size();
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

std::unique_ptr<RiscvSemihosting::FileBase>
RiscvSemihosting::create_file_object(const std::string &fname, const char *mode)
{
  if (fname == ":semihosting-features") {
    return std::make_unique<RiscvSemihosting::FileFeatures>(fname, mode);
  } else {
    return std::make_unique<RiscvSemihosting::File>(fname, mode);
  }
}

RetErrno RiscvSemihosting::callOpen(Context *, const uint64_t name_base,
                                    int fmode, size_t name_size)
{
  const char *mode = fmode < fmodes.size() ? fmodes[fmode] : nullptr;

  if (!mode || !name_base)
    return retError(EINVAL);

  std::optional<std::string> fname
      = mem::read_string((const char *)name_base, name_size);
  if (!fname.has_value())
    return retError(ERANGE);

  std::unique_ptr<FileBase> file
      = create_file_object(get_full_path(*fname), mode);

  int ret = file->open();
  if (ret < 0) {
    return retError(-ret);
  } else {
    files.push_back(std::move(file));
    return retOK(files.size() - 1);
  }
}

RetErrno RiscvSemihosting::callClose(Context *, Handle handle)
{
  if (handle >= files.size()) {
    printf("Semihosting SYS_CLOSE(%ld): Illegal file\n", handle);
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

RetErrno RiscvSemihosting::callWriteC(Context *, const char c)
{
  putchar(c);
  return retOK(0);
}
RetErrno RiscvSemihosting::callWrite(Context *, Handle handle, Addr addr,
                                     size_t size)
{
  if (handle > files.size() || !files[handle])
    return RetErrno(size, EBADF);

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

RetErrno RiscvSemihosting::callWrite0(Context *, const char *s)
{
  std::string str = mem::read_string(s);
  printf("%s", str.c_str());
  return retOK(0);
}

RetErrno RiscvSemihosting::callExit32(Context *, uint32_t)
{
  zhtif_exit_code = 0;
  zhtif_done = true;
  return retOK(0);
}

/**
 * @param code: The exception type, which is one of the set of reason codes in
 * the tables.
 * @param subcode: A subcode, whose meaning depends on the code.
 */
RetErrno RiscvSemihosting::callExit64(Context *, uint64_t code,
                                      uint64_t subcode)
{
  if (code == ADP_Stopped_ApplicationExit) {
    zhtif_exit_code = subcode;
  } else {
    zhtif_exit_code = 1;
  }
  zhtif_done = true;
  return retOK(0);
}

RetErrno RiscvSemihosting::callExitExtended(Context *ctx, uint64_t code,
                                            uint64_t subcode)
{
  callExit64(ctx, code, subcode);
  return retOK(0);
}

RetErrno RiscvSemihosting::callRead(Context *, Handle handle, Addr addr,
                                    size_t size)
{
  if (handle > files.size() || !files[handle])
    return RetErrno(size, EBADF);

  std::vector<uint8_t> buffer(size);
  int64_t ret = files[handle]->read(buffer.data(), buffer.size());
  if (ret < 0) {
    return RetErrno(size, -ret);
  } else {
    if (ret > buffer.size()) {
      EXIT_FAILURE_WITH("Read longer than buffer size.\n");
    };
    mem::write(addr, buffer.data(), ret);
    return retOK(size - ret);
  }
}

RetErrno RiscvSemihosting::callReadC(Context *)
{
  char c = getchar();
  return retOK(c);
}

RetErrno RiscvSemihosting::callIsError(Context *, int64_t status)
{
  return retOK(status < 0 ? 1 : 0);
}

RetErrno RiscvSemihosting::callIsTTY(Context *, Handle handle)
{
  if (handle > files.size() || !files[handle])
    return retError(EBADF);

  int64_t ret = files[handle]->isTTY();
  if (ret < 0) {
    return retError(-ret);
  } else {
    return retOK(ret ? 1 : 0);
  }
}

RetErrno RiscvSemihosting::callSeek(Context *, Handle handle, uint64_t pos)
{
  if (handle > files.size() || !files[handle])
    return retError(EBADF);

  int64_t ret = files[handle]->seek(pos);
  if (ret < 0) {
    return retError(-ret);
  } else {
    return retOK(0);
  }
}

RetErrno RiscvSemihosting::callFLen(Context *, Handle handle)
{
  if (handle > files.size() || !files[handle])
    return retError(EBADF);

  int64_t ret = files[handle]->flen();
  if (ret < 0) {
    return retError(-ret);
  } else {
    return retOK(ret);
  }
}

RetErrno RiscvSemihosting::callTmpNam(Context *, Addr addr, uint64_t /*id*/,
                                      size_t size)
{
  char *path = NULL;
  int64_t unlink_call_ret = 0;
  do {
    if (path) {
      free(path);
      path = NULL;
    }
    if (asprintf(&path, "%s.tmp%05i", "sail-riscv", tmpNameIndex++) < 0) {
      EXIT_FAILURE_WITH(
          "RiscvSemihosting::callTmpNam: format tmp file name failed");
    }
    // remove the (potentially existing) file of the given path
    unlink_call_ret = unlink(path);
    // if the file is busy, find another name
  } while ((unlink_call_ret < 0 && errno == EBUSY));

  const size_t path_len = strlen(path);
  if (path_len >= size)
    return retError(ENOSPC);

  mem::write(addr, path, path_len + 1);
  return retOK(0);
}

RetErrno RiscvSemihosting::callRemove(Context *, Addr name_base,
                                      size_t name_size)
{
  if (name_size > 65536) {
    // If the semihosting RiscvSemihosting::call passes an incorrect argument,
    // reject it rather than attempting to allocate a buffer of that size. We
    // chose 64K as an arbitrary limit here since no valid program should be
    // attempting to open a file with such a large filename.
    printf("RiscvSemihosting::readString(): attempting to read too large "
           "(%ld bytes) string from %#lx",
           name_size, name_base);
    return retError(ERANGE);
  }
  std::string fname = mem::read_string((const char *)name_base, name_size);
  if (remove(fname.c_str()) != 0) {
    return retError(errno);
  } else {
    return retOK(0);
  }
}

RetErrno RiscvSemihosting::callRename(Context *, Addr from_addr,
                                      size_t from_size, Addr to_addr,
                                      size_t to_size)
{
  if (from_size > 65535 || to_size > 65535) {
    printf("RiscvSemihosting::rename(): attempting to rename too large "
           "(%ld bytes) string from %#lx",
           from_size, from_addr);
    return retError(ERANGE);
  }
  std::string from = mem::read_string((char *)from_addr, from_size);
  std::string to = mem::read_string((char *)to_addr, to_size);
  if (rename(from.c_str(), to.c_str()) != 0) {
    return retError(errno);
  } else {
    return retOK(0);
  }
}

RetErrno RiscvSemihosting::callSystem(Context *, Addr cmd_addr, size_t cmd_size)
{
  if (cmd_size > 65535)
    return retError(ERANGE);
  std::string cmd = mem::read_string((char *)cmd_addr, cmd_size);
  return retOK(system(cmd.c_str()));
}

RetErrno RiscvSemihosting::callErrno(Context *)
{
  return RetErrno(semiErrno, semiErrno);
}

RetErrno RiscvSemihosting::callGetCmdLine(Context *, Addr addr,
                                          InPlaceArg<size_t> size)
{
  std::string cmd = elfInfo.name + " " + elfInfo.arguments;
  if (cmd.size() + 1 < size.read()) {
    mem::write(addr, cmd.c_str(), cmd.size() + 1);
    size.write(cmd.size());
    return retOK(0);
  } else {
    return retError(0);
  }
}

RetErrno RiscvSemihosting::callHeapInfo(Context *, Addr block_addr)
{
  uint64_t heap_base = elfInfo.heap_base;
  uint64_t heap_limit = elfInfo.heap_size;
  uint64_t stack_base = elfInfo.stack_base;
  uint64_t stack_limit = elfInfo.stack_size;
  if (zxlen == 32) {
    std::array<uint32_t, 4> block = {
        {(uint32_t)heap_base, (uint32_t)heap_limit, (uint32_t)stack_base,
         (uint32_t)stack_limit}
    };
    mem::write(block_addr, block);
  } else {
    std::array<uint64_t, 4> block = {
        {heap_base, heap_limit, stack_base, stack_limit}
    };
    mem::write(block_addr, block);
  }

  return retOK(0);
}

uint64_t curTick()
{
  return zmcycle;
}

RetErrno RiscvSemihosting::callClock(Context *)
{
  return retOK(curTick() / (SIMULATED_CPU_FREQUENCY_HZ / 100));
}

RetErrno RiscvSemihosting::callTime(Context *)
{
  return retOK(time(NULL));
}

RetErrno RiscvSemihosting::callElapsed32(Context *, InPlaceArg<uint32_t> low,
                                         InPlaceArg<uint32_t> high)
{
  uint64_t tick = curTick();
  low.write(tick);
  high.write(tick >> 32);
  return retOK(0);
}

RetErrno RiscvSemihosting::callElapsed64(Context *,
                                         InPlaceArg<uint64_t> lowhigh)
{
  lowhigh.write(curTick());
  return retOK(0);
}

RetErrno RiscvSemihosting::callTickFreq(Context *)
{
  return retOK(SIMULATED_CPU_FREQUENCY_HZ);
}

void RiscvSemihosting::call()
{
  uint64_t op = zrX(10).bits;
  uint64_t addr = zrX(11).bits;
  auto it = handlers.find(op);
  if (it != handlers.end()) {
    Context ctx(addr);
    if (zxlen == 32) {
      (it->second).call32(this, &ctx);
    } else if (zxlen == 64) {
      it->second.call64(this, &ctx);
    } else {
      EXIT_FAILURE_WITH("Invalid xlen 0x%lx\n", zxlen);
    }
  } else {
    EXIT_FAILURE_WITH("Unknown semihosting call 0x%lx\n", op);
  }
}

semihosting::RiscvSemihosting riscv_semihosting;

void register_elf_info(semihosting::elfinfo cmd)
{
  riscv_semihosting.register_elf_info(cmd);
}

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
  semihosting::riscv_semihosting.call();
  return UNIT;
}
