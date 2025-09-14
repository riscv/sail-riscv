#pragma once

#include <vector>
#include <string>
#include <sail.h>
#include "riscv_config.h"

const std::vector<const char *> fmodes {
    "r", "rb", "r+", "r+b", "w", "wb", "w+", "w+b", "a", "ab", "a+", "a+b",
};

namespace semihosting {

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

const std::map<SemiErrno, const char *> exitCodes {
    // Hardware vector reason codes
    {0x20000, "semi:ADP_Stopped_BranchThroughZero"  },
    {0x20001, "semi:ADP_Stopped_UndefinedInstr"     },
    {0x20002, "semi:ADP_Stopped_SoftwareInterrupt"  },
    {0x20003, "semi:ADP_Stopped_PrefetchAbort"      },
    {0x20004, "semi:ADP_Stopped_DataAbort"          },
    {0x20005, "semi:ADP_Stopped_AddressException"   },
    {0x20006, "semi:ADP_Stopped_IRQ"                },
    {0x20007, "semi:ADP_Stopped_FIQ"                },

    // Software reason codes
    {0x20020, "semi:ADP_Stopped_BreakPoint"         },
    {0x20021, "semi:ADP_Stopped_WatchPoint"         },
    {0x20022, "semi:ADP_Stopped_StepComplete"       },
    {0x20023, "semi:ADP_Stopped_RunTimeErrorUnknown"},
    {0x20024, "semi:ADP_Stopped_InternalError"      },
    {0x20025, "semi:ADP_Stopped_UserInterruption"   },
    {0x20026, "semi:ADP_Stopped_ApplicationExit"    },
    {0x20027, "semi:ADP_Stopped_StackOverflow"      },
    {0x20028, "semi:ADP_Stopped_DivisionByZero"     },
    {0x20029, "semi:ADP_Stopped_DivisionByZero"     },
};

class Context {
public:
  Context(uint64_t base_addr)
      : base_addr(base_addr) { };
  uint64_t base_addr;
};

typedef std::pair<uint64_t, SemiErrno> RetErrno;
typedef size_t Handle;
typedef uint64_t Addr;

class FileBase {
public:
  virtual ~FileBase() = default;

  /** @{
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

}
