/* The default implementation of hooks for the step() and main() functions. */

function ext_init() -> unit = ()

function ext_fetch_hook(f : FetchResult) -> FetchResult = f

function ext_pre_step_hook()  -> unit = ()
function ext_post_step_hook() -> unit = ()
