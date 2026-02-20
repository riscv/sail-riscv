.section .text.start
.global _start
_start:
  la  t0, tohost
  li  t1, 1
  sd  t1, 0(t0)
1: j 1b