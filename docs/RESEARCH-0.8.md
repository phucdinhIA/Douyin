# Research and static evidence — 0.8

Retrieved by HTTPS on 2026-10-02 and reviewed as untrusted data. Neither original IPA nor third-party mod code was executed. Fetch hashes/statuses: [online evidence](evidence/0.8-online-evidence.json).

- [Apple JSONSerialization](https://developer.apple.com/documentation/foundation/jsonserialization) describes conversion between JSON and Foundation objects and thread safety. Used for a bounded diagnostic probe, not to overwrite native errors or invent a response.
- [RFC 9112 §7.1](https://www.rfc-editor.org/rfc/rfc9112.html#section-7.1) specifies HTTP chunk framing and length boundaries. The app's own helper uses newline delimiters and `0\n\n`; similarity does not prove standard HTTP chunk coding. No speculative chunk/gzip/protobuf decoder is added.
- [DYYY pinned source](https://github.com/huami1314/DYYY/blob/6c3dfbd911822b4d0f758f184c196566e8142291/DYYY.xm) was fetched and checked again. No references to `AWEDCFeedListDataManager`, `shouldRequestWithChunk` or `AWEJSONResponseSerializer` appear in this file. This is not proof that no mod implements a fix; this reviewed file does not substantiate one. Previous Android sources are recorded in [0.7 research](RESEARCH-0.7.md).

[Version-specific disassembly](evidence/0.8-feed-static-trace.json) supports selecting the app's built-in normal request path:

- `AWEDCFeedListDataManager shouldRequestWithChunk`, `B16@0:8`, IMP `0x14a994d8`, reads config → strategyConfig → tidyAwemeConfig → useChunk.
- Initial fetch checks that decision and chunk controller; otherwise it invokes `dataController fetchDataWithRequestParams:args:completion:`. Load more has the same branch shape. Refresh is included in the evidence and uses the same decision.
- Default wrapper's initial/refresh/load-more methods are `v40@0:8@16@24@?32`. The compatibility hook checks all three and the controller's native class at runtime before selection.
- `AWEJSONResponseSerializer` at `0x12b11b84` builds conversion error in `com.aweme.network.error/-11001`. It already uses a cache parser and a fallback parser. Adding an unproven second serializer invocation could duplicate native side effects; not adopted.
- `TTHttpResponse statusCode` is `q16@0:8`, MIMEType is `@16@0:8`. They can be observed without reading cookies or headers.
- `AWEDCFeedListViewController handleFetchDataState:` maps failed data state 8 to error page 10. This supports the reported flicker mechanism, but does not establish whether the briefly displayed videos came from cache, placeholder or a partial response.

**Limit:** the actual failing response bytes and a physical-device run of 0.8 are unavailable here. Transport incompatibility is the working hypothesis; it is not yet a proven server-specific root cause or a claim that the IPA is safe.
