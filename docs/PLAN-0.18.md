# 0.18 repair and provider migration

## Evidence and contracts

- Device 0.17: comments translate successfully through the authorized Gemini fallback after GTX 429, but replacing YYLabel text retains the Chinese layout/container/cell height. Translation UI must own its measured height and never place long text into the old fixed frame.
- Nested comment containers each attach a status control. Only one visible comment surface may own translation UI and requests.
- AI capture currently recognizes three Markdown renderers only. New native A2UI/web rendering paths appear in the audited binary. Read scoped native text/web content and use bounded on-device OCR of the AI analysis surface when text is drawn; never fabricate a summary or send ordinary comments as analysis.
- Extension files reviewed: background.js API services; RealtimeDubbingEngine providers, chain resolution, first batch, context, horizon, cancellation, endpoint leases, audio lifecycle and rate adjustment; voice catalog and model migration bundles.
- Authenticated backend login is POST /login with form username/password. Subsequent JSON API requests use Ck session. Use only the supplied account; exclude the extension's unrelated account rotation and quota manipulation code.
- Translation: POST /api/v2/ai-translate/translate, model claude-sonnet-5, toLanguage vi-VN, ordered subtitles with index/text/start/end and surrounding context. Response subtitleTranslateResults is positional with translateResult/useAiTranslate; retain source IDs and timestamps locally. Validate count, nonempty Vietnamese and bounds before committing.
- Voice catalog: vi-VN-NamMinhNeural. Authenticated POST /api/v2/dubbing/generateDubbing accepts translated subtitles and config skipTranslation=true, voiceType=azure. videoDetails.subtitleLevel is omitted (a guessed string produces HTTP 400). Response subtitleDubbingResults contains ttsUrl/translateResult/useAiTranslate. Verified Nam Minh MP3 download HTTP 200 from static-ja.youtube-dubbing.com. Do not embed Microsoft's extracted signing secret; use the authenticated backend contract.
- Live synthetic checks: login and membership verified; requested Claude model returns nonempty AI translation; requested Nam Minh returns downloadable audio. These do not establish physical iPhone behavior.

## Implementation sequence

1. Add isolated backend client, bounded response parsers, session handling, sanitized errors, cancellation and provider-specific caches. Credentials remain outside Git/CI and are included only in the private package.
2. Keep GTX primary for comments and the already authorized Gemini fallback. Replace fixed-frame inline substitution with a single full-text comment translation surface, automatic row heights, scrolling and access to original comments. No duplicated video overlay controls.
3. Extend AI capture for verified native content and scoped web views; bounded local OCR is the last capture fallback. Capture while original analysis is displayed, reject stale results after tab/video changes. Keep original summary for Q&A and strip mark tags from display.
4. Replace subtitle Gemini calls with Claude backend calls. For speech under 600 seconds, translate all cues in one request, preserving complete context and timestamps. Cache provider/model explicitly. Keep Apify and verified Nova-3 zh-CN flow and upload fallback.
5. Remove Vbee source, configuration, package option, runtime diagnostics and tests. Nam Minh synthesis is progressive: first three cues unlock playback, subsequent groups prefetch under backpressure. Cache by voice/text, cancel old work on video change, prioritize seek. Account/session errors stop without retry storms.
6. Keep native video/audio clock authoritative. Avoid repeated tiny corrective seeks; distinguish a real seek/loop from small clock jitter. Preserve working background playback and mute ownership. Verify composition padding, adjacent chunk duration and missing audio behavior.

## Verification and release gates

- Parser/request tests: malformed/count mismatch, auth/quota, untrusted hosts, credential forwarding, cancellation and caches.
- UI fixtures: short Chinese to long Vietnamese, native fixed-height cells, nested containers, image/reply preservation through original mode, safe areas, scrolling and no duplicated controls; AI native/custom/web capture and stale OCR.
- Audio tests: cue timing, silence padding, first chunk before remaining work, prefetch/seek/cancel/failure, jitter and queue boundaries.
- Minimal live probes: actual whole ASR transcript -> Claude -> Nam Minh first group; validate audio durations and Vietnamese language. Never publish private transcripts/tokens/URLs.
- macOS build, iPhone Simulator fixtures, package integrity and original binary comparison. Produce a new private IPA only after checks pass. Physical iOS 18.5 validation remains explicitly separate from simulator/live API checks.
