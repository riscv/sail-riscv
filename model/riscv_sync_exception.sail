/* model context for synchronous exceptions, parameterized for extensions */

struct sync_exception = {
  trap    : ExceptionType,
  excinfo : option(xlenbits),
  ext     : option(ext_exception)   /* for extensions */
}
