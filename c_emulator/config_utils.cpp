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
#include "default_config_schema.h"
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

const char *get_default_config_schema()
{
  return DEFAULT_CONFIG_SCHEMA;
}

static std::string mk_temp_file(const std::string &filename_template,
                                const std::string &content)
{
  std::string tmpname_src = "/tmp/" + filename_template + "XXXXXX";

  char tmpname[tmpname_src.length() + 1];
  std::copy(tmpname_src.begin(), tmpname_src.end(), tmpname);
  tmpname[tmpname_src.length()] = '\0';

  int fd = mkstemp(tmpname);
  if (fd < 0) {
    fprintf(stderr, "Unable to create tmp file for %s.\n", tmpname);
    return std::string();
  }

  FILE *tmpf = fdopen(fd, "w");
  if (tmpf == nullptr) {
    fprintf(stderr, "Unable to write to tmp file for %s.\n", tmpname);
    return std::string();
  }

  fputs(content.c_str(), tmpf);
  fflush(tmpf);
  fclose(tmpf);
  close(fd);

  return std::string(tmpname);
}

static std::string temp_saved_default_config_schema()
{
  return mk_temp_file("default_config_schema", get_default_config_schema());
}

static std::string temp_saved_default_config()
{
  return mk_temp_file("default_config", get_default_config());
}

void validate_config_schema(const std::string &config_file_name)
{
  std::string schema_file_name = temp_saved_default_config_schema();
  if (schema_file_name.empty()) {
    std::cerr << "Could not save schema to temp file: " << strerror(errno)
              << std::endl;
    exit(EXIT_FAILURE);
  }

  std::string cf_name;
  bool have_temp_config_file = false;
  if (config_file_name.empty()) {
    // Check the default config by saving it to a temp file.
    cf_name = temp_saved_default_config();
    if (cf_name.empty()) {
      std::cerr << "Could not save default config to temp file: "
                << strerror(errno) << std::endl;
      unlink(schema_file_name.c_str());
      exit(EXIT_FAILURE);
    }
    have_temp_config_file = true;
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
    unlink(schema_file_name.c_str());
    if (have_temp_config_file) {
      unlink(cf_name.c_str());
    }
    exit(EXIT_FAILURE);
  }

  int status;
  do {
    ret = waitpid(pid, &status, WUNTRACED | WCONTINUED);
  } while (!WIFEXITED(status) && !WIFSIGNALED(status));

  unlink(schema_file_name.c_str());
  if (have_temp_config_file) {
    unlink(cf_name.c_str());
  }
  if (WIFEXITED(status)) {
    exit(WEXITSTATUS(status));
  }
  exit(EXIT_FAILURE);
}
