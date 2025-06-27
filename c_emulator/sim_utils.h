#pragma once

#include <stdint.h>
#include <sys/types.h>
#include <vector>

std::vector<char> make_reset_rom(bool is_32bit, uint64_t entry,
                                 const unsigned char *dtb, size_t dtb_len);

bool is_32bit_model(void);
