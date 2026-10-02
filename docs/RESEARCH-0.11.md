# Gemini evidence and integration limits

Official Google pages read on 2026-10-02:

- [Models](https://ai.google.dev/gemini-api/docs/models) lists Gemini 3.8 Flash and 3.5 Flash-Lite as stable; identifies 3.8 Flash for stronger performance and Flash-Lite for speed/cost. The page recommends current models for new projects and notes limited legacy 2.5 access. Stable model IDs are pinned rather than a moving `latest` alias.
- [Text generation](https://ai.google.dev/gemini-api/docs/text-generation) documents `generateContent`, `systemInstruction`, content parts/history and generation config.
- [API keys](https://ai.google.dev/gemini-api/docs/api-key) and [Troubleshooting](https://ai.google.dev/gemini-api/docs/troubleshooting) describe API credentials and quota/request errors. Key placement in the private IPA is explicitly requested, not a secure distribution scheme.
- The user's key successfully listed models. Synthetic Chinese-to-Vietnamese translation returned HTTP200 for 3.8 Flash (3.06s) and 3.5 Flash-Lite (1.20s), both preserving the disclaimer/uncertainty. Two single requests do not establish best quality, production uptime or a latency guarantee. [Source hashes](evidence/0.11-online-evidence.json) · [Synthetic probe](evidence/0.11-generation-probe.json).

Native 40.6.0/build406019 evidence:

- `AWEFeedDoubleColumnAIParseViewController inputViewSendQueryContext:sourceFrom:` at `0x1084fa50`, `v32@0:8@16q24`, invokes `requireLoginWithContext:completion:`. The comment-AI subclass inherits this method. Only that subclass receives a local override to open Gemini; it never grants access to Douyin's AI endpoint.
- `AWEFeedDoubleColumnCommentAIParseViewController commentAIParseTabDidEnter` at `0x1085211c`, `v16@0:8`, updates the native input bar. `commentAIParseTabWillLeave` at `0x10852194` has the same ABI. Originals remain called once; own entry is shown/hidden at these transitions.
- `AWESearchAIGCQueryContext query` is an object getter (`@16@0:8`). Query extraction checks this class and ABI; unknown/image-only requests are not guessed or sent automatically.
- `ServalMarkdownView getContent`, `@16@0:8`, is a native text getter. `LynxServalMarkdownViewWrapper` inherits it. `LynxMarkdownViewV2` -> `LynxMarkdownBundleV2 markdownView` -> `ServalMarkdownView` is also supported with checked getters. Legacy `LynxMarkdownView` allows its own UILabel/UITextView descendants only. Other rendering paths return no captured summary rather than inventing context.
- [Verified method metadata](evidence/0.11-native-abi.json). No private content or credential is included.

The integration reads loaded analysis text at chat opening; it does not obtain unseen full comments, the video, account data or server-only results. It cannot guarantee every renderer exposes the entire analysis. Review Context, or paste missing text there. The native send path prepares a draft in a Gemini sheet; Send in that sheet makes the Google request. No typing-triggered network call or automatic retry.

Physical-device routing/capture remains unverified until this candidate is installed. Simulated native classes and provider transport tests check our implementation contract, not the proprietary app or Google's behavior inside the iPhone.
