/* Extensions may wish to interpose and transform decoded instructions,
 * based on other machine state.  This is supported via a post-decode
 * instruction hook, the default implementation of which is provided below.
 */

val ext_post_decode_hook : ast -> ast effect {rreg}
function ext_post_decode_hook(x) = x
