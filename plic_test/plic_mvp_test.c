/* No headers: define minimal types ourselves */
typedef unsigned int        u32;
typedef unsigned long       ul;
typedef unsigned long long  u64;
typedef unsigned long       uptr;

extern void trap_entry(void);

/* Written by trap handler */
volatile u32 g_irq_seen = 0;
volatile u32 g_claim    = 0;

/* HTIF tohost */
volatile u64 tohost __attribute__((section(".tohost"))) = 0;
volatile u64 fromhost __attribute__((section(".fromhost"))) = 0;

static inline void htif_exit(u32 code) {
  /* device=0, payload LSB=1 means exit; exit_code = payload>>1 */
  tohost = ((u64)code << 1) | 1ULL;
  for (;;) { asm volatile("wfi"); }
}

/* CSR helpers */
static inline ul csr_read_mstatus(void) {
  ul x; asm volatile("csrr %0, mstatus" : "=r"(x)); return x;
}
static inline void csr_write_mstatus(ul x) {
  asm volatile("csrw mstatus, %0" :: "r"(x));
}
static inline ul csr_read_mie(void) {
  ul x; asm volatile("csrr %0, mie" : "=r"(x)); return x;
}
static inline void csr_write_mie(ul x) {
  asm volatile("csrw mie, %0" :: "r"(x));
}
static inline void csr_write_mtvec(ul x) {
  asm volatile("csrw mtvec, %0" :: "r"(x));
}

/* bits */
#define MSTATUS_MIE (1UL << 3)
#define MIE_MEIE    (1UL << 11)

/* PLIC (matches your default config: base=0x0c000000) */
#define PLIC_BASE        0x0c000000UL
#define PLIC_PRIORITY(id)   (PLIC_BASE + 0x000000UL + ((uptr)(id) * 4UL))
#define PLIC_PENDING0       (PLIC_BASE + 0x001000UL)          /* word0: IDs 0..31 */
#define PLIC_ENABLE0_CTX0   (PLIC_BASE + 0x002000UL)          /* ctx0 word0 */
#define PLIC_THRESHOLD_CTX0 (PLIC_BASE + 0x200000UL)          /* ctx0 threshold */
#define PLIC_CLAIM_CTX0     (PLIC_BASE + 0x200004UL)          /* ctx0 claim/complete */

static inline void mmio_write32(uptr addr, u32 val) {
  *(volatile u32 *)addr = val;
}
static inline u32 mmio_read32(uptr addr) {
  return *(volatile u32 *)addr;
}

void main(void) {
  const u32 ID = 10;

  /* install trap vector (direct mode) */
  csr_write_mtvec((ul)(uptr)trap_entry);

  /* global off first */
  csr_write_mstatus(csr_read_mstatus() & ~MSTATUS_MIE);

  /* enable machine external interrupt */
  csr_write_mie(csr_read_mie() | MIE_MEIE);

  /* ---- PLIC init (ctx0 = M-mode) ---- */
  mmio_write32(PLIC_PRIORITY(ID), 1);                 /* priority=1 */
  mmio_write32(PLIC_ENABLE0_CTX0, (1u << ID));        /* enable ID10 */
  mmio_write32(PLIC_THRESHOLD_CTX0, 0);               /* threshold=0 */

  /* ---- inject pending (non-standard write you added) ---- */
  mmio_write32(PLIC_PENDING0, (1u << ID));            /* set pending bit10 */

  /* global on */
  csr_write_mstatus(csr_read_mstatus() | MSTATUS_MIE);

  /* wait until interrupt handled */
  while (!g_irq_seen) {
    asm volatile("wfi");
  }

  /* validate claim id */
  if (g_claim == ID) htif_exit(0);
  else htif_exit(1);
}
