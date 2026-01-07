#pragma once

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Memory block information structure
struct memory_block_info {
  uint64_t block_id;
  uint64_t size;
  uint8_t *data;
  struct memory_block_info *next;
};

// Get all memory blocks
// Returns the number of blocks and sets *blocks_out to the head of the list
size_t snapshot_get_memory_blocks(struct memory_block_info **blocks_out);

// Free memory block list
void snapshot_free_memory_blocks(struct memory_block_info *blocks);

// Restore a memory block
void snapshot_restore_memory_block(uint64_t block_id, const uint8_t *data,
                                   uint64_t size);

// Clear all memory (used during restore)
void snapshot_clear_memory(void);

#ifdef __cplusplus
}
#endif

