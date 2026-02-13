#pragma once

#include <cstdint>
#include <string>

class ModelImpl;

void dump_memory_to_elf(ModelImpl &model, const std::string &filename, uint64_t entry);
