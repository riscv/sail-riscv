Some notes about this implementation of the Remote Serial Protocol:

- It depends on `asio` for asynchronous networking. Despite being a
  mostly synchronous request-response protocol, it does have an
  asynchronous interrupt (`0x03`) notification, which could appear
  when the user wants to interrupt a long execution, such as one
  caused by a `continue` '`c`' command.

- The idiomatic use of `asio` has some tricky pieces. There is no
  global variable keeping an accepted connection alive; the shared
  pointer to the connection is kept alive entirely by being part of
  the contexts of the (lambda) callbacks. This is implemented using
  the `enable_shared_from_this` inheritance of `connection`, and the
  `self` captures in the connection callbacks.

- Handling asynchronous interrupt messages during `continue` is
  implemented using `asio::post` for each execution step. This allows
  the `asio::io_context` to interleave socket reads with continuing
  model execution. When the `protocol_handler` dispatches these
  `asio::post`s, it keeps the connection alive by storing the `parent`
  pointer (to the connection object that owns the `protocol_handler`) in
  the context for the `asio::post` callback.

  New requests from the protocol client may arrive before the previous
  response has been sent (this is seen with LLDB). The `continue` '`c`'
  request is the only request that is not responded to immediately
  since it could take a very long time to complete (and hence the need
  for the user to interrupt it). New requests arriving before the
  `continue` response has been sent are queued up for dispatch when
  the `continue` completes.

- The debug server claims (in its `qSupported` response) to support
  only hardware breakpoints, despite which both GDB and LLDB
  request software breakpoints (using `Z0` and `z0`). The server
  implements these in terms of hardware breakpoints.

  Software breakpoints are typically implemented in terms of writing
  breakpoint instructions to instruction memory after recording the
  overwritten instruction, and then replacing the overwritten
  instruction when the breakpoint is removed. To avoid keeping track
  of these overwritten instructions, only hardware breakpoints are
  implemented. This may cause discrepancies in corner cases; e.g. when
  instruction memory is examined, real software breakpoints would show
  up as inserted breakpoint instructions, but no change in instruction
  memory would be seen in this implementation.

- Binary data in packet payloads needs to be escaped. The server
  doesn't send any such packets _yet_, so no escaping is done on
  transmission.

- The server only serves one client connection and then exits when
  that connection closes. For the server to stay alive to serve
  another client, the model will likely need to be re-initialized and
  the ELF file re-loaded, and current APIs would need to be extended
  if this use case really needs to be supported.
