#pragma once

#include <vector>
#include <string>
#include <sail.h>
#include "riscv_config.h"
#include "mem.h"
#include "riscv_sail.h"
#include "log.h"

namespace semihosting {

const std::vector<const char *> fmodes {
    "r", "rb", "r+", "r+b", "w", "wb", "w+", "w+b", "a", "ab", "a+", "a+b",
};

enum Operation {
  SYS_OPEN = 0x01,
  SYS_CLOSE = 0x02,
  SYS_WRITEC = 0x03,
  SYS_WRITE0 = 0x04,
  SYS_WRITE = 0x05,
  SYS_READ = 0x06,
  SYS_READC = 0x07,
  SYS_ISERROR = 0x08,
  SYS_ISTTY = 0x09,
  SYS_SEEK = 0x0A,
  SYS_FLEN = 0x0C,
  SYS_TMPNAM = 0x0D,
  SYS_REMOVE = 0x0E,
  SYS_RENAME = 0x0F,
  SYS_CLOCK = 0x10,
  SYS_TIME = 0x11,
  SYS_SYSTEM = 0x12,
  SYS_ERRNO = 0x13,
  SYS_GET_CMDLINE = 0x15,
  SYS_HEAPINFO = 0x16,
  SYS_EXIT = 0x18,
  SYS_EXIT_EXTENDED = 0x20,
  SYS_ELAPSED = 0x30,
  SYS_TICKFREQ = 0x31,
};

typedef uint64_t SemiErrno;
typedef std::pair<uint64_t, SemiErrno> RetErrno;
inline static RetErrno retError(SemiErrno e)
{
  return RetErrno((uint64_t)-1, e);
}
inline static RetErrno retOK(uint64_t r)
{
  return RetErrno(r, 0);
}

typedef size_t Handle;
typedef uint64_t Addr;

enum ADP_Stopped {
  // Hardware vector reason codes
  ADP_Stopped_BranchThroughZero = 0x20000,
  ADP_Stopped_UndefinedInstr = 0x20001,
  ADP_Stopped_SoftwareInterrupt = 0x20002,
  ADP_Stopped_PrefetchAbort = 0x20003,
  ADP_Stopped_DataAbort = 0x20004,
  ADP_Stopped_AddressException = 0x20005,
  ADP_Stopped_IRQ = 0x20006,
  ADP_Stopped_FIQ = 0x20007,

  // Software reason codes
  ADP_Stopped_BreakPoint = 0x20020,
  ADP_Stopped_WatchPoint = 0x20021,
  ADP_Stopped_StepComplete = 0x20022,
  ADP_Stopped_RunTimeErrorUnknown = 0x20023,
  ADP_Stopped_InternalError = 0x20024,
  ADP_Stopped_UserInterruption = 0x20025,
  ADP_Stopped_ApplicationExit = 0x20026,
  ADP_Stopped_StackOverflow = 0x20027,
  ADP_Stopped_DivisionByZero = 0x20028,
  ADP_Stopped_OSSpecific = 0x20029,

};

class Context {
public:
  Context(uint64_t base_addr)
      : base_addr(base_addr) { };
  uint64_t base_addr;
};

struct elfinfo {
  std::string name;
  std::string arguments;
  uint64_t stack_base;
  uint64_t stack_size;
  uint64_t heap_base;
  uint64_t heap_size;
};

void register_elf_info(elfinfo cmd);

template <typename T> struct InPlaceArg {
public:
  using value_type = T;
  InPlaceArg()
      : addr(0)
      , size(0)
  {
  }
  InPlaceArg(uint64_t addr, size_t size)
      : addr(addr)
      , size(size)
  {
  }
  T read()
  {
    return mem::read<T>(addr, size);
  }
  void write(T value)
  {
    mem::write(addr, (uint8_t *)&value, size);
  }

private:
  uint64_t addr;
  size_t size;
};

class RiscvSemihosting {
public:
  RiscvSemihosting() { };

  void call();

  void register_elf_info(elfinfo new_info)
  {
    elfInfo = new_info;
  }

private:
  class FileBase {
  public:
    virtual ~FileBase() = default;

    /**
     * Semihosting file IO interfaces
     *
     * These interfaces implement common IO functionality in the
     * Semihosting interface.
     *
     * All functions return a negative value that corresponds to a
     * UNIX errno value when they fail and >=0 on success.
     */

    /**
     * Open the the file.
     *
     * @return <0 on error (-errno), 0 on success.
     */
    virtual int64_t open() = 0;

    /**
     * Close the file.
     *
     * @return <0 on error (-errno), 0 on success.
     */
    virtual int64_t close() = 0;

    /**
     * Check if a file corresponds to a TTY device.
     *
     * @return True if the file is a TTY, false otherwise.
     */
    virtual bool isTTY() const = 0;

    /**
     * Read data from file.
     *
     * @return <0 on error (-errno), bytes read on success (0 for EOF).
     */
    virtual int64_t read(uint8_t *buffer, uint64_t size) = 0;
    // size_t read(uint8_t *buf, size_t size);
    /**
     * Write data to file.
     *
     * @return <0 on error (-errno), bytes written on success.
     */
    virtual int64_t write(const uint8_t *buffer, uint64_t size) = 0;
    // size_t write(const uint8_t *buf, size_t size);

    /**
     * Seek to an absolute position in the file.
     *
     * @param pos Byte offset from start of file.
     * @return <0 on error (-errno), 0 on success.
     */
    virtual int64_t seek(uint64_t pos) = 0;

    /**
     * Get the length of a file in bytes.
     *
     * @return <0 on error (-errno), length on success
     */
    virtual int64_t flen() = 0;
  };

  class File : public FileBase {
  public:
    File(const std::string &filename, const char *mode);
    ~File();
    int64_t open() override;
    int64_t close() override;
    bool isTTY() const override;
    int64_t read(uint8_t *buffer, uint64_t size) override;
    int64_t write(const uint8_t *buffer, uint64_t size) override;
    int64_t seek(uint64_t pos) override;
    int64_t flen() override;

  private:
    std::string name;
    const char *mode;
    FILE *file = nullptr;
  };

  /** Implementation of the ':semihosting-features' magic file. */
  class FileFeatures : public FileBase {
  public:
    FileFeatures(const std::string &filename, const char *mode);
    int64_t open() override
    {
      return 0;
    };
    int64_t close() override
    {
      return 0;
    };
    bool isTTY() const override
    {
      return false;
    };
    int64_t read(uint8_t *buffer, uint64_t size) override;
    int64_t write(const uint8_t *, uint64_t) override
    {
      return 0;
    };
    int64_t seek(uint64_t pos) override;
    int64_t flen() override;

  private:
    std::string name;
    const char *mode;
    size_t pos = 0;
  };

  std::unique_ptr<FileBase> create_file_object(const std::string &fname,
                                               const char *mode);

private:
  template <typename T> struct is_inplace_arg : std::false_type { };

  template <typename T>
  struct is_inplace_arg<InPlaceArg<T>> : std::true_type { };

  template <typename T>
  inline static constexpr bool is_inplace_arg_v = is_inplace_arg<T>::value;

  class SemiCall {
  public:
    template <typename Ret, typename... Args>
    SemiCall(Ret (RiscvSemihosting::*func)(Context *, Args...))
        : func32(wrap_call<4>(func))
        , func64(wrap_call<8>(func))
    {
    }

    template <typename Ret, typename... Args32, typename... Args64>
    SemiCall(Ret (RiscvSemihosting::*func32)(Context *, Args32...),
             Ret (RiscvSemihosting::*func64)(Context *, Args64...))
        : func32(wrap_call<4>(func32))
        , func64(wrap_call<8>(func64))
    {
    }
    void call32(RiscvSemihosting *s, Context *ctx)
    {
      func32(s, ctx);
    }
    void call64(RiscvSemihosting *s, Context *ctx)
    {
      func64(s, ctx);
    }

  private:
    using innerFunc = std::function<void(RiscvSemihosting *, Context *)>;
    innerFunc func32;
    innerFunc func64;

    template <typename T, size_t ParamSize> T read_single_arg(uint64_t addr)
    {
      return mem::read<T>(addr, ParamSize);
    }

    template <typename T, size_t ParamSize>
    InPlaceArg<T> read_inplace_arg(uint64_t addr)
    {
      return InPlaceArg<T>(addr, ParamSize);
    }

    template <std::size_t ParamSize, typename... Args>
    auto read_args_impl(uint64_t, std::index_sequence<>)
    {
      return std::make_tuple();
    }

    template <std::size_t ParamSize, typename T, typename... RestArgs,
              std::size_t I, std::size_t... Is>
    auto read_args_impl(uint64_t base_addr, std::index_sequence<I, Is...>)
    {
      if constexpr (is_inplace_arg_v<T>) {
        auto current_arg
            = this->read_inplace_arg<typename T::value_type, ParamSize>(
                base_addr + I * ParamSize);
        return std::tuple_cat(std::make_tuple(current_arg),
                              read_args_impl<ParamSize, RestArgs...>(
                                  base_addr, std::index_sequence<Is...> {}));
      } else {
        auto current_arg
            = this->read_single_arg<T, ParamSize>(base_addr + I * ParamSize);
        return std::tuple_cat(std::make_tuple(current_arg),
                              read_args_impl<ParamSize, RestArgs...>(
                                  base_addr, std::index_sequence<Is...> {}));
      }
    }

    template <std::size_t ParamSize, typename... Args>
    auto read_args(uint64_t base_addr)
    {
      return read_args_impl<ParamSize, Args...>(
          base_addr, std::make_index_sequence<sizeof...(Args)> {});
    }

    template <size_t ParamSize, typename Ret, typename... Args>
    void invoke(RiscvSemihosting *s,
                Ret (RiscvSemihosting::*func)(Context *, Args...), Context *ctx)
    {
      // Collect arguments from mem
      auto args_tuple = this->read_args<ParamSize, Args...>(ctx->base_addr);
      auto full_tuple = std::tuple_cat(std::make_tuple(ctx), args_tuple);

      // Do semihosting function call
      Ret res = std::apply(
          [&](Context *c, auto &&...args) { return (s->*func)(c, args...); },
          full_tuple);

      // Preserve semihosting error code
      s->semiErrno = res.second;

      // Write return value to A0
      zwX(10, sbits {zxlen, res.first});
    }

    template <size_t ParamSize, typename Ret, typename... Args>
    innerFunc wrap_call(Ret (RiscvSemihosting::*func)(Context *, Args...))
    {
      return [this, func](RiscvSemihosting *s, Context *ctx) {
        invoke<ParamSize>(s, func, ctx);
      };
    }
  };

private:
  std::map<uint64_t, SemiCall> handlers = {
      {SYS_OPEN,          {&RiscvSemihosting::callOpen}                    },
      {SYS_CLOSE,         {&RiscvSemihosting::callClose}                   },
      {SYS_WRITEC,        {&RiscvSemihosting::callWriteC}                  },
      {SYS_WRITE0,        {&RiscvSemihosting::callWrite0}                  },
      {SYS_WRITE,         {&RiscvSemihosting::callWrite}                   },
      {SYS_READ,          {&RiscvSemihosting::callRead}                    },
      {SYS_READC,         {&RiscvSemihosting::callReadC}                   },
      {SYS_ISERROR,       {&RiscvSemihosting::callIsError}                 },
      {SYS_ISTTY,         {&RiscvSemihosting::callIsTTY}                   },
      {SYS_SEEK,          {&RiscvSemihosting::callSeek}                    },
      {SYS_FLEN,          {&RiscvSemihosting::callFLen}                    },
      {SYS_TMPNAM,        {&RiscvSemihosting::callTmpNam}                  },
      {SYS_REMOVE,        {&RiscvSemihosting::callRemove}                  },
      {SYS_RENAME,        {&RiscvSemihosting::callRename}                  },
      {SYS_CLOCK,         {&RiscvSemihosting::callClock}                   },
      {SYS_TIME,          {&RiscvSemihosting::callTime}                    },
      {SYS_SYSTEM,        {&RiscvSemihosting::callSystem}                  },
      {SYS_ERRNO,         {&RiscvSemihosting::callErrno}                   },
      {SYS_GET_CMDLINE,   {&RiscvSemihosting::callGetCmdLine}              },
      {SYS_HEAPINFO,      {&RiscvSemihosting::callHeapInfo}                },
      {SYS_EXIT,
       {&RiscvSemihosting::callExit32, &RiscvSemihosting::callExit64}      },
      {SYS_EXIT_EXTENDED, {&RiscvSemihosting::callExitExtended}            },
      {SYS_ELAPSED,
       {&RiscvSemihosting::callElapsed32, &RiscvSemihosting::callElapsed64}},
      {SYS_TICKFREQ,      {&RiscvSemihosting::callTickFreq}                },
  };

  bool enable_log = false;

  // 100,000 Hz (100 kIPS)
  const uint64_t SIMULATED_CPU_FREQUENCY_HZ = 100000;

  std::vector<std::unique_ptr<FileBase>> files = {};
  uint16_t tmpNameIndex = 0;
  uint64_t semiErrno = 0;
  elfinfo elfInfo = {};

  RetErrno callOpen(Context *, const uint64_t name_base, int fmode,
                    size_t name_size);
  RetErrno callClose(Context *, Handle handle);
  RetErrno callWriteC(Context *, const char c);
  RetErrno callWrite(Context *, Handle handle, Addr addr, size_t size);
  RetErrno callWrite0(Context *, const char *s);
  RetErrno callExit32(Context *, uint32_t code);
  RetErrno callExit64(Context *, uint64_t code, uint64_t subcode);
  RetErrno callExitExtended(Context *tc, uint64_t code, uint64_t subcode);
  RetErrno callRead(Context *, Handle handle, Addr addr, size_t size);
  RetErrno callReadC(Context *);
  RetErrno callIsError(Context *, int64_t status);
  RetErrno callIsTTY(Context *, Handle handle);
  RetErrno callSeek(Context *, Handle handle, uint64_t pos);
  RetErrno callFLen(Context *, Handle handle);
  RetErrno callTmpNam(Context *, Addr addr, uint64_t id, size_t size);
  RetErrno callRemove(Context *, Addr name_base, size_t name_size);
  RetErrno callRename(Context *, Addr from_addr, size_t from_size, Addr to_addr,
                      size_t to_size);
  RetErrno callSystem(Context *, Addr cmd_addr, size_t cmd_size);
  RetErrno callErrno(Context *);
  RetErrno callGetCmdLine(Context *, Addr addr, InPlaceArg<size_t> size);
  RetErrno callHeapInfo(Context *, Addr block_addr);
  RetErrno callClock(Context *);
  RetErrno callTime(Context *);
  RetErrno callElapsed32(Context *, InPlaceArg<uint32_t> low,
                         InPlaceArg<uint32_t> high);
  RetErrno callElapsed64(Context *, InPlaceArg<uint64_t> lowhigh);
  RetErrno callTickFreq(Context *);
};

}
