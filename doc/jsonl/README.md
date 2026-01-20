# JSON-Lines Output Format

This model supports a [JSON-Lines](https://jsonlines.org/) structured logging format that should be used whenever a machine-readable execution log is needed.

**DO NOT PARSE THE HUMAN-READABLE OUTPUT**

The schema matches the following Serde definition. Also note:

- Tuples are represented as arrays.
- Optional values that are `None` are simply omitted.
- This uses unsigned 64-bit integers which some JSON libraries may not support.
  You need to use one that does. This works fine in Python, Rust (`serde_json`),
  and C++ (Nlohmann/JSON for Modern C++). For Javascript (`JSON.parse()`) you
  need to use the `reviver` parameter and parse `context.source` into a BigInt.

```rust
#[derive(Serialize, Deserialize)]
struct Step {
    /// PC when this step was executed. This is always known and must be always present.
    pc: u64,
    /// PC for the next step. This is mostly redundant but useful for verifying branches
    /// in verification flows where PC is forced every step.
    next_pc: u64,
    /// Whether this step involved a redirect (branch, jump, exception, etc).
    /// If omitted defaults to `false`.
    #[serde(default)]
    redirect: bool,
    /// Opcode may be missing e.g. for fetch faults.
    opcode: Option<u32>,
    /// On exception, this is equal to the cause. Mutually exclusive with interrupt.
    exception: Option<u64>,
    /// On interrupt, this is equal to the cause. Mutually exclusive with
    /// exception. The top 'interrupt' bit of mstatus is not included.
    interrupt: Option<u64>,
    /// List of X register writes. May be missing if there are none.
    #[serde(default)]
    x: Vec<(u8, u64)>,
    /// List of F register writes. May be missing if there are none.
    #[serde(default)]
    f: Vec<(u8, u64)>,
    /// List of V register writes. May be missing if there are none.
    /// The values are a little endian array.
    #[serde(default)]
    v: Vec<(u8, Vec<u8>)>,
    /// List of CSR writes. May be missing if there are none.
    #[serde(default)]
    csr: Vec<(u16, u64)>,
    /// Loads and stores. May be missing if none.
    #[serde(default)]
    loads: Vec<MemAccess>,
    #[serde(default)]
    stores: Vec<MemAccess>,
}

#[derive(Serialize, Deserialize)]
struct MemAccess {
    /// Physical address.
    paddr: u64,
    // /// Virtual address. TODO: Not included yet.
    // vaddr: u64,
    /// Access width in bytes.
    width: u8,
    /// Value read or written.
    value: Vec<u8>,
}
```
