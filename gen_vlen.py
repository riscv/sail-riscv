import sys
import os
import math

vlen = int(sys.argv[1])
elen = int(sys.argv[2])
sail_path = 'model/riscv_vlen.sail'

# Check value of VLEN
if vlen < 128:
    vlen = 128
    print('WARN: VLEN less than 128; setting VLEN to 128\n')
if vlen % 2 != 0:
    vlen = vlen - (vlen % 2)
    print('WARN: VLEN not a power of 2; setting VLEN to %d\n' % vlen)

# Check value of ELEN
if elen < 8:
    elen = 8
    print('WARN: ELEN less than 8; setting ELEN to 8\n')
if elen % 2 != 0:
    elen = elen - (elen % 2)
    print('WARN: ELEN not a power of 2; setting ELEN to %d\n' % elen)

if os.path.exists(sail_path):
    os.remove(sail_path)

lb = ['/* Define the VLEN value for the architecture */\n',
      '\n',
      'type vlen          : Int = %d\n' % vlen,
      'type vlen_bytes    : Int = %d\n' % (vlen / 8),
      'type vstart_int    : Int = %d\n' % math.log(vlen, 2),
      'type vstartbits          = bits(vstart_int)\n',
      '\n',
      'type elen          : Int = %d\n' % elen,
      '\n']

    
fh_sail = open('model/riscv_vlen.sail', 'w')
fh_sail.writelines(lb)
fh_sail.close()

exit()
