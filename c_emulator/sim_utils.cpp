#include "sail.h"
#include "sim_utils.h"
#include "riscv_sail.h"

std::vector<char> make_reset_rom(bool is_32bit, uint64_t entry,
                                 const unsigned char *dtb, size_t dtb_len)
{
#define RST_VEC_SIZE 8
  uint32_t reset_vec[RST_VEC_SIZE]
      = {0x297,                              // auipc  t0,0x0
         0x28593 + (RST_VEC_SIZE * 4 << 20), // addi   a1, t0, &dtb
         0xf1402573,                         // csrr   a0, mhartid
         is_32bit ? 0x0182a283u :            // lw     t0,24(t0)
             0x0182b283u,                    // ld     t0,24(t0)
         0x28067,                            // jr     t0
         0,
         (uint32_t)(entry & 0xffffffff),
         (uint32_t)(entry >> 32)};

  const char *reset_buf = reinterpret_cast<const char *>(reset_vec);
  std::vector<char> rom(reset_buf, reset_buf + RST_VEC_SIZE * sizeof(uint32_t));

  if ((dtb != nullptr) && (dtb_len > 0)) {
    rom.insert(rom.end(), dtb, dtb + dtb_len);
  }
  /* zero-fill to page boundary */
  const int align = 0x1000;
  rom.resize((rom.size() + align - 1) / align * align);
  return rom;
}

bool is_32bit_model(void)
{
  return zxlen == 32;
}
