# Research and static evidence — 0.9

Sources retrieved by HTTPS on 2026-10-02, read as untrusted information; no third-party mod or original app binary was executed. [Fetch status, hashes and symbol counts](evidence/0.9-online-evidence.json).

- [Apple JSONSerialization](https://developer.apple.com/documentation/foundation/jsonserialization): HTTP success/MIME do not replace successful JSON decoding. The existing bounded probe remains diagnostic only.
- [RFC 9112 §7.1](https://www.rfc-editor.org/rfc/rfc9112.html#section-7.1): HTTP chunk framing is distinct from the app's newline-delimited decimal chunk grammar; no speculative prefix-stripping decoder is added.
- [DYYY pinned source](https://github.com/huami1314/DYYY/blob/6c3dfbd911822b4d0f758f184c196566e8142291/DYYY.xm): checked for the two controllers, manager, enableChunkRequest, CSP-Domain and is_tidy. This reviewed file has no matching references and provides no validated fix for this feed failure. Earlier Android research remains in [0.7 research](RESEARCH-0.7.md); techniques are not assumed portable to iOS.

[Version-specific native trace](evidence/0.9-feed-format-static-trace.json) and [two new hook ABIs](evidence/0.9-native-hook-abi.json):

- `AWEFeedDoubleColumnListDataController enableChunkRequest`, `B16@0:8`, AwemeCore `0x15402574`: checks scene, chunk style and column type. `addBodyParamsForChunkModel:` calls that decision and writes `is_tidy = "true"` only when enabled. Initial, refresh and load-more build their own bodies and consult the same decision to choose native chunk versus normal AWEAwemeManager loading. All three normal branches are retained.
- `AWESearchCachalotDCFeedDataController enableChunkRequest`, `B16@0:8`, AWESearchFramework `0xb680b0`: checks chunk style/column type. Its body builder writes the same tidy flag conditionally. Its three request paths use `AWESearchCachalotDCFeedNetManager`, whose native method constructs ordinary GET/POST requests, handles client-extra/body settings and uses the existing request machinery. Selecting NO avoids that builder's tidy flag; no URL, signature, session or credential is forged. Other native parameter contributors remain untouched.
- The runtime checks verify the three `v40@0:8@16@24@?32` entry points and the `v24@0:8@16` body builder. Unknown loaders or ABI drift preserve native decisions.
- `CSPChunkDataHelper` flow-read callback at `0x1533acd8` constructs `CSP-Domain/-4` in an unfinished EOF branch through `p_sendError:error:extraLog:`. Native helpers include buffered data in error metadata; diagnostics must not export it. A separate early-EOF setting can produce -14 and is not enabled as a supposed fix.
- `AWEFeedDoubleColumnCSPChunkDataHelper` and `AWEDCFeedChunkBasicDataHelper` use newline separators, decimal length scanning and `0\n\n` end markers. Numeric-prefix data may be framing but that classification alone does not prove a complete recoverable response.

The user reports Tips can receive new videos before an error page covers them, while Featured currently receives none. Native failure-state presentation can explain the flash; suppressing the error page would not fix incomplete requests or prove pagination. Preserve real failure handling and correct negotiation first.

**Limit:** static evidence establishes the local branches, not the exact deployed server payload or a verified endpoint root cause. Runtime fixtures model contracts; they do not run Douyin, its proprietary network manager or the live server. The candidate must be tested on the physical iPhone before claiming resolution.
