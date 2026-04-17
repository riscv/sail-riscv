# Simple Interrupt Generator

This model includes a very simple MMIO device that allows setting interrupts that are difficult to set via other means (though software or CLINT). This is intended for testing purposes.

This describes version 0 of the device. Future versions may add additional features but will be backwards compatible.

## Memory Layout

The device consists only of 4-byte registers, and it must be 4-byte aligned.
Only naturally aligned 4-byte accesses succeed. Other accesses raise an access fault.

| Offset (Bytes) | Size (Bytes) | Register   | Read    | Write                |
| -------------- | ------------ | ---------- | ------- | -------------------- |
| 0              | 4            | `version`  | Version | _ignored_            |
| 4              | 4            | `platform` | _zeros_ | Set/clear interrupts |
| 8              | 24           | _reserved_ | _fault_ | _fault_              |

`version`: reads as as the current version (0x00010000 currently). The version is split into major/minor 16-bit integers, so the current version is 1.0. Versioning follows semver, so minor version updates are backwards compatible with existing software, major version updates are not. Writes to `version` are ignored.

`platform`: reads as 0. Writes can be used to set or clear platform-generated interrupts as follows:

| Offset (Bits) | Meaning        |
| ------------- | -------------- |
| 0             | _reserved_     |
| 1             | SSI            |
| 2             | _reserved_     |
| 3             | MSI            |
| 4-8           | _reserved_     |
| 9             | SEI            |
| 10            | _reserved_     |
| 11            | MEI            |
| 12-30         | _reserved_     |
| 31            | 1=set, 0=clear |

_Reserved_ bits must be written with 0 otherwise an access fault is raised. In future versions writing 1 may be allowed and have an effect, but writing 0 will have no effect so writing 0 is forwards compatible (with minor version number changes).

Bit 31 controls whether the relevant interrupts are set or cleared.

MEI and MSI control the platform interrupt inputs to the hart, which directly control the corresponding bits in `mip` (there is no way for software running on the hart to set these bits directly. SEI and SSI are slightly more subtle because software on the hart can also write to these bits.

SEI controls the supervisor external platform interrupt input, which is distinct from the software-writable `mip[SEI]` bit. These two values are ORed together when reading `mip` (or `sip`) for CSR reads and to dispatch interrupts, but NOT when reading `mip`/`sip` for the CSR read-modify-write process.

Setting or clearing SSI updates the value in `mip[SSI]`, but in this case there is only one bit of state.

Space for other registers is reserved for future use. In version 1.0, accessing them raises an access fault.

## Example C++ Code

```cpp
constexpr uint32_t SIG_SSI = (1 << 1);
constexpr uint32_t SIG_MSI = (1 << 3);
constexpr uint32_t SIG_SEI = (1 << 9);
constexpr uint32_t SIG_MEI = (1 << 11);
constexpr uint32_t SIG_SET = (1 << 31);

struct SimpleInterruptGenerator {
    uint32_t version;
    uint32_t platform;
    uint32_t reserved[6];
};

void set_meip(volatile SimpleInterruptGenerator* sig) {
    uint32_t version = sig->version;
    uint32_t minor = version & 0xFFFF;
    uint32_t major = version >> 16;
    assert(major == 1 && minor >= 0);
    sig->platform = SIG_SET | SIG_MEI;
}

// etc.
```
