# JSON-Lines Output Format

This model supports a [JSON-Lines](https://jsonlines.org/) structured logging format that should be used whenever a machine-readable execution log is needed.

**DO NOT PARSE THE HUMAN-READABLE OUTPUT**

The schema matches the following Serde definition. Also note:

- Tuples are represented as arrays.
- Where a key is `Option<>` or `#[serde(default)]` that means it may be omitted entirely in the JSON (and it will default to `None`/`false`/empty `Vec`).
- This uses unsigned 64-bit integers for exception & interrupt causes which some JSON libraries may not support. In most cases the cause won't be more than 53 bits but for custom extensions it is allowed. In that case you'll need to use a parser that supports 64-bit integers. Those work fine in Python, Rust (`serde_json`), and C++ (Nlohmann/JSON for Modern C++). For Javascript (`JSON.parse()`) you need to use the `reviver` parameter and parse `context.source` into a BigInt.

```rust
/// Little endian bytes, used for register writes and memory accesses.
/// The length must match the access size; leading 0 bytes cannot be omitted.
type ByteVec = Vec<u8>;

#[derive(Serialize, Deserialize)]
struct Step {
    /// PC when this step was executed. This is always known and must be always present.
    pc: ByteVec,
    /// PC for the next step. This is mostly redundant but useful for verifying branches
    /// in verification flows where PC is forced every step.
    next_pc: ByteVec,
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
    /// List of X register writes. May be omitted if there are none.
    #[serde(default)]
    x: Vec<(u8, ByteVec)>,
    /// List of F register writes. May be omitted if there are none.
    #[serde(default)]
    f: Vec<(u8, ByteVec)>,
    /// List of V register writes. May be omitted if there are none.
    /// The values are a little endian array.
    #[serde(default)]
    v: Vec<(u8, ByteVec)>,
    /// List of CSR writes. May be omitted if there are none.
    #[serde(default)]
    csr: Vec<(u16, ByteVec)>,
    /// Loads and stores. May be omitted if there are none.
    #[serde(default)]
    loads: Vec<MemAccess>,
    #[serde(default)]
    stores: Vec<MemAccess>,
}

#[derive(Serialize, Deserialize)]
struct MemAccess {
    /// Physical address.
    paddr: ByteVec,
    // /// Virtual address. TODO: Not included yet.
    // vaddr: u64,
    /// Access width in bytes.
    width: u8,
    /// Value read or written.
    value: ByteVec,
}
```
