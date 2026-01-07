// Snapshot memory functions for dumping and restoring memory state
// These functions interface with the Sail runtime memory system

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>


struct block {
  uint64_t block_id;
  uint8_t *mem;
  struct block *next;
};

struct tag_block {
  uint64_t block_id;
  bool *mem;
  struct tag_block *next;
};

extern struct block *sail_memory;
extern struct tag_block *sail_tags;
extern uint64_t MASK;

// Memory block information for snapshot
struct memory_block_info {
  uint64_t block_id;
  uint64_t size;
  uint8_t *data;
  struct memory_block_info *next;
};

// Get all memory blocks
// Returns the number of blocks and sets *blocks_out to the head of the list
size_t snapshot_get_memory_blocks(struct memory_block_info **blocks_out)
{
  if (blocks_out == NULL) {
    return 0;
  }

  struct memory_block_info *head = NULL;
  struct memory_block_info *tail = NULL;
  size_t count = 0;

  struct block *current = sail_memory;
  while (current != NULL) {
    struct memory_block_info *info =
        (struct memory_block_info *)malloc(sizeof(struct memory_block_info));
    if (info == NULL) {
      
      while (head != NULL) {
        struct memory_block_info *next = head->next;
        free(head->data);
        free(head);
        head = next;
      }
      *blocks_out = NULL;
      return 0;
    }

    info->block_id = current->block_id;
    info->size = MASK + 1;
    info->data = (uint8_t *)malloc(MASK + 1);
    if (info->data == NULL) {
      free(info);
     
      while (head != NULL) {
        struct memory_block_info *next = head->next;
        free(head->data);
        free(head);
        head = next;
      }
      *blocks_out = NULL;
      return 0;
    }

    memcpy(info->data, current->mem, MASK + 1);
    info->next = NULL;

    if (head == NULL) {
      head = info;
      tail = info;
    } else {
      tail->next = info;
      tail = info;
    }

    count++;
    current = current->next;
  }

  *blocks_out = head;
  return count;
}

// Free memory block list
void snapshot_free_memory_blocks(struct memory_block_info *blocks)
{
  while (blocks != NULL) {
    struct memory_block_info *next = blocks->next;
    free(blocks->data);
    free(blocks);
    blocks = next;
  }
}

// Restore a memory block
// This will create a new block if it doesn't exist, or overwrite existing one
void snapshot_restore_memory_block(uint64_t block_id, const uint8_t *data,
                                   uint64_t size)
{
  if (data == NULL) {
    return;
  }

  uint64_t mask = block_id & ~MASK;

  // Find existing block
  struct block *current = sail_memory;
  struct block *prev = NULL;

  while (current != NULL && current->block_id != mask) {
    prev = current;
    current = current->next;
  }

  if (current == NULL) {
    // Create new block
    current = (struct block *)malloc(sizeof(struct block));
    if (current == NULL) {
      return;
    }
    current->block_id = mask;
    current->mem = (uint8_t *)calloc(MASK + 1, sizeof(uint8_t));
    if (current->mem == NULL) {
      free(current);
      return;
    }
    current->next = sail_memory;
    sail_memory = current;
  }

  // Copy data (limit to block size)
  uint64_t copy_size = (size < (MASK + 1)) ? size : (MASK + 1);
  memcpy(current->mem, data, copy_size);
}

// Clear all memory (used during restore)
void snapshot_clear_memory(void)
{
  while (sail_memory != NULL) {
    struct block *next = sail_memory->next;
    free(sail_memory->mem);
    free(sail_memory);
    sail_memory = next;
  }

  while (sail_tags != NULL) {
    struct tag_block *next = sail_tags->next;
    free(sail_tags->mem);
    free(sail_tags);
    sail_tags = next;
  }
}

