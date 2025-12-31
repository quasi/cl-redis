# CL-REDIS Modernization and Upgrade Plan

## Analysis of Current State

The `cl-redis` library is a Common Lisp client for Redis, currently tested against Redis 3.0.0. While it provides a solid foundation with support for Pipelining, PubSub, and SSL, it is significantly outdated compared to the current Redis ecosystem (Redis 7.2+).

### Key Problems Identified

1.  **Outdated Protocol Support (RESP2)**:
    -   The library implements RESP2 (Redis Serialization Protocol 2).
    -   It lacks support for **RESP3**, which was introduced in Redis 6. RESP3 is more efficient and supports richer data types (Maps, Sets, Booleans, Doubles, BigNumbers, Nulls, etc.).
    -   Modern Redis clients should negotiate RESP3 via the `HELLO` command.

2.  **Missing Commands (Redis 3.2 - 7.2)**:
    -   A vast number of commands introduced in the last decade are missing.
    -   **Geo** commands (`GEOADD`, `GEODIST`, etc.) - Added in 3.2.
    -   **Streams** (`XADD`, `XREAD`, `XGROUP`, etc.) - Added in 5.0. This is a major missing feature.
    -   **ACL** commands (`ACL SETUSER`, etc.) - Added in 6.0. The current `AUTH` implementation is legacy (password only).
    -   **Cluster** support is minimal (`CLUSTER SLOTS` only).
    -   **Modules** support is missing.
    -   **Scripting**: Only basic `EVAL` support exists; Redis Functions (7.0) are missing.

3.  **Connection Management**:
    -   **Blocking I/O**: Uses `usocket` in a blocking manner. No async support (e.g., via `cl-async` or `iolib`).
    -   **No Connection Pooling**: The README mentions it as a planned feature, but it is not implemented. This is critical for high-concurrency applications.
    -   **Sentinel Support**: Missing.
    -   **Cluster Support**: Partial/Minimal.

4.  **Testing & CI**:
    -   Tests rely on a locally running Redis instance.
    -   No modern CI/CD pipeline (e.g., GitHub Actions) to test against multiple Redis versions.

## Unsupported Redis Protocol (RESP3) Features

The current `redis.lisp` only supports the following RESP2 types:
-   `+` Simple String
-   `-` Error
-   `:` Integer
-   `$` Bulk String
-   `*` Array

The following RESP3 types are **not supported**:
-   `_` Null
-   `#` Boolean
-   `,` Double
-   `(` BigNumber
-   `!` Bulk Error
-   `=` Verbatim String
-   `%` Map
-   `~` Set
-   `>` Push (for out-of-band data like PubSub in RESP3)

## Upgrade Implementation Plan

### Phase 1: Modernization & Infrastructure (Week 1)

1.  **CI/CD Setup**:
    -   Create a GitHub Actions workflow.
    -   Spin up Redis service containers for versions 3.0, 4.0, 5.0, 6.0, 6.2, 7.0, 7.2.
    -   Run existing tests against all versions to establish a baseline.

2.  **Code Cleanup**:
    -   Address any compiler warnings.
    -   Ensure compatibility with modern SBCL and other Lisp implementations.
    -   Review dependencies (`rutils`, `cl+ssl`, etc.) for updates.

### Phase 2: Protocol Upgrade to RESP3 (Week 2)

1.  **Refactor `expect`**:
    -   Modify the `expect` generic function in `redis.lisp` to handle new type prefixes.
    -   Implement parsers for RESP3 types:
        -   Maps (`%`) -> Lisp Hash Tables or Alists.
        -   Sets (`~`) -> Lisp Lists or Sets.
        -   Booleans (`#`) -> Lisp `T` / `NIL`.
        -   Doubles (`,`) -> Lisp Floats.
        -   Nulls (`_`) -> Lisp `NIL` (or specific symbol if needed to distinguish from empty list).

2.  **Handshake**:
    -   Implement the `HELLO` command to switch to RESP3 protocol if the server supports it (Redis 6+).
    -   Fallback to RESP2 for older servers.

### Phase 3: Feature Expansion (Week 3-4)

1.  **Implement Missing Command Groups**:
    -   **Geo**: `GEOADD`, `GEORADIUS`, etc.
    -   **Streams**: Implement `XADD`, `XREAD`, `XRANGE` parsing. Streams return complex nested structures that benefit significantly from RESP3.
    -   **ACL**: Update `AUTH` to support `AUTH [username] password`. Add `ACL` admin commands.

2.  **Redis Functions (7.0)**:
    -   Implement `FCALL`, `FUNCTION LOAD`.

### Phase 4: Connection & Architecture (Week 5+)

1.  **Connection Pool**:
    -   Implement a thread-safe connection pool to reuse connections, reducing overhead.

2.  **Sentinel/Cluster**:
    -   Implement Sentinel support for high availability.
    -   Improve Cluster client to handle redirections (`MOVED`, `ASK`).

### Phase 5: Documentation & Release

1.  **Update README**:
    -   Document new features and supported Redis versions.
    -   Provide examples for Streams and Geo commands.

2.  **Release**:
    -   Bump version (likely to 3.0.0 due to RESP3 and breaking changes).
