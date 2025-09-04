# Pull Request: Fix function pointer type mismatches for GCC 15 compatibility

## Description
This PR fixes compilation errors when building nchan with GCC 15 (as used in Fedora 42+). GCC 15 has stricter type checking for function pointer assignments, which causes build failures with the current code.

## Problem
When compiling with GCC 15.2.1, the following errors occur:
```
error: assignment to 'subscriber_callback_pt' from incompatible pointer type 'void (*)(void)'
error: assignment to 'ngx_http_cleanup_pt' from incompatible pointer type 'void (*)(void)' 
error: assignment to 'callback_pt' from incompatible pointer type 'ngx_int_t (*)(void)'
```

## Solution
The fix involves ensuring all function pointers match their expected signatures:

1. **longpoll.c & websocket.c**: Split `empty_handler()` into two properly typed functions:
   - `empty_subscriber_handler(subscriber_t *sub, void *data)` for subscriber callbacks
   - `empty_cleanup_handler(void *data)` for cleanup callbacks

2. **eventsource.c**: Changed `empty_handler(void)` to `empty_cleanup_handler(void *data)`

3. **memstore_ipc.c & memstore.c**: Changed `empty_callback()` to `empty_callback(ngx_int_t status, void *ptr1, void *ptr2)` to match the `callback_pt` typedef

## Testing
- ✅ Compiles successfully with GCC 15.2.1 on Fedora 42
- ✅ Produces valid ngx_nchan_module.so (2.9MB shared object)
- ✅ No compilation warnings or errors

## Important Note
This patch was developed with AI assistance. While it has been tested to compile successfully on the target system and the changes are straightforward type corrections, please review carefully for:
- Completeness of the fix
- Any potential security implications
- Compatibility with other GCC versions

## Files Changed
- src/subscribers/longpoll.c
- src/subscribers/websocket.c
- src/subscribers/eventsource.c
- src/subscribers/memstore_ipc.c
- src/store/memory/memstore.c

## Related Issues
This addresses compilation failures on Fedora 42+ and other systems using GCC 15.