#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <spawn.h>
#include <unistd.h>
#include <string.h>

#include <string>
#include <iostream>
#include <optional>
#include <filesystem>
#include <cstdio>

#include "sail_config.h"
#include "default_config.h"
#include "schema_file_info.h"
#include "config_utils.h"

uint64_t get_config_uint64(const std::vector<const char *> &keypath)
{
  sail_config_json json = sail_config_get(keypath.size(), keypath.data());

  if (!json) {
    std::cerr << "Failed to find configuration option '";
    for (auto part : keypath) {
      std::cerr << "." << part;
    }
    std::cerr << "'.\n";
    exit(EXIT_FAILURE);
  }

  sail_int big_n;
  uint64_t n;

  if (!sail_config_is_int(json)) {
    std::cerr << "Configuration option '";
    for (auto part : keypath) {
      std::cerr << "." << part;
    }
    std::cerr << "' could not be parsed as an integer.\n";
    exit(EXIT_FAILURE);
  }

  CREATE(sail_int)(&big_n);
  sail_config_unwrap_int(&big_n, json);
  n = sail_int_get_ui(big_n);
  KILL(sail_int)(&big_n);
  return n;
}

const char *get_default_config()
{
  return DEFAULT_JSON;
}

namespace fs = std::filesystem;

static std::optional<fs::path> get_base_install_directory()
{
  std::error_code ec;
  fs::path p = fs::read_symlink("/proc/self/exe", ec);
  if (!ec) {
    // This executable is installed under "bin/", so "../" would be the
    // base install directory.
    if (p.has_parent_path()) {
      const fs::path pp = p.parent_path(); // "bin/"
      if (pp.has_parent_path()) {
        return pp.parent_path(); // "bin/../"
      }
    }
  }

  // This may not be a Linux system.
  // TODO: make it more portable.
  return std::nullopt;
}

static std::string locate_schema_file()
{
  struct stat st;

  std::string location(schema_file_info::build_location);
  if (!stat(location.c_str(), &st)) {
    return location;
  }

  std::optional<fs::path> base_dir = get_base_install_directory();
  if (base_dir) {
    location
        = base_dir.value().append(schema_file_info::relative_install_location);
    if (!stat(location.c_str(), &st)) {
      return location;
    }
  }

  fprintf(stderr,
          "Unable to automatically locate the configuration schema file; "
          "please specify it using the --config-schema option.\n");
  exit(EXIT_FAILURE);
}

static std::string temp_saved_default_config()
{
  char tmpname[] = "/tmp/default_config_XXXXXX";
  int fd = mkstemp(tmpname);
  if (fd < 0) {
    return std::string();
  }
  FILE *tmpf = fdopen(fd, "w");
  if (tmpf == nullptr) {
    return std::string();
  }

  fputs(get_default_config(), tmpf);
  fflush(tmpf);
  fclose(tmpf);
  close(fd);
  return std::string(tmpname);
}

void validate_config_schema(std::string schema_file_name,
                            const std::string &config_file_name)
{
  if (schema_file_name.empty()) {
    schema_file_name = locate_schema_file();
  }

  std::string cf_name;
  bool have_temp_file = false;
  if (config_file_name.empty()) {
    // Check the default config by saving it to a temp file.
    cf_name = temp_saved_default_config();
    if (cf_name.empty()) {
      std::cerr << "Could not save default config to temp file: "
                << strerror(errno) << std::endl;
      exit(EXIT_FAILURE);
    }
    have_temp_file = true;
  } else {
    cf_name = config_file_name;
  }

  const char *args[]
      = {"boon", schema_file_name.c_str(), cf_name.c_str(), nullptr};
  pid_t pid;
  int ret = posix_spawnp(&pid, "boon",
                         nullptr, // file actions
                         nullptr, // attrs
                         const_cast<char **>(args),
                         nullptr); // envp
  if (ret != 0) {
    fprintf(stderr,
            "Error validating schema file with 'boon'. "
            "Please install boon with 'cargo install boon-cli' and ensure it "
            "is in PATH.\n");
    if (have_temp_file) {
      unlink(cf_name.c_str());
    }
    exit(EXIT_FAILURE);
  }

  int status;
  do {
    ret = waitpid(pid, &status, WUNTRACED | WCONTINUED);
  } while (!WIFEXITED(status) && !WIFSIGNALED(status));

  if (have_temp_file) {
    unlink(cf_name.c_str());
  }
  if (WIFEXITED(status)) {
    exit(WEXITSTATUS(status));
  }
  exit(EXIT_FAILURE);
}
