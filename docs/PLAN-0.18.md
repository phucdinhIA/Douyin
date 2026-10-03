# 0.18 repair and provider migration

## Evidence and contracts

- Device 0.17: comments translate successfully through the authorized Gemini fallback after GTX 429, but replacing YYLabel text retains the Chinese layout/container/cell height. Translation UI must own its measured height and never place long text into the old fixed frame.
- Nested comment containers each attach a status control. Only one visible comment surface may own translation UI and requests.
- AI capture currently recognizes three Markdown renderers only. New native A2UI/web rendering paths appear in the audited binary. Read scoped native text/web content and use bounded on-device OCR of the AI analysis surface when text is drawn; never fabricate a summary or send ordinary comments as analysis.
- Extension files reviewed: background.js API services; RealtimeDubbingEngine providers, chain resolution, first batch, context, horizon, cancellation, endpoint leases, audio lifecycle and rate adjustment; voice catalog and model migration bundles.
- Authenticated backend login is POST /login with form username/password. Subsequent JSON API requests use Ck session. Use only the supplied account; exclude the extension's unrelated account rotation and quota manipulation code.
- Translation: POST /api/v2/ai-translate/translate, model claude-sonnet-5, toLanguage vi-VN, ordered subtitles with index/text/start/end and surrounding context. Each contextBefore/contextAfter entry is an object `{text: ...}`; live API rejected string arrays with HTTP 400. Response subtitleTranslateResults is positional with translateResult/useAiTranslate; retain source IDs and timestamps locally. Validate count, nonempty Vietnamese and bounds before committing.
- Voice catalog: vi-VN-NamMinhNeural. Authenticated POST /api/v2/dubbing/generateDubbing accepts translated subtitles and config skipTranslation=true, voiceType=azure. videoDetails.subtitleLevel is omitted (a guessed string produces HTTP 400). Response subtitleDubbingResults contains ttsUrl/translateResult/useAiTranslate. Verified Nam Minh MP3 download HTTP 200 from static-ja.youtube-dubbing.com. Do not embed Microsoft's extracted signing secret; use the authenticated backend contract.
- Live synthetic checks: login and membership verified; requested Claude model returns nonempty AI translation; requested Nam Minh returns downloadable audio. These do not establish physical iPhone behavior.

## Implementation sequence

1. Add isolated backend client, bounded response parsers, session handling, sanitized errors, cancellation and provider-specific caches. Credentials remain outside Git/CI and are included only in the private package.
2. Keep GTX primary for comments and the already authorized Gemini fallback. Replace fixed-frame inline substitution with a single full-text comment translation surface, automatic row heights, scrolling and access to original comments. No duplicated video overlay controls.
3. Extend AI capture for verified native content and scoped web views; bounded local OCR is the last capture fallback. Capture while original analysis is displayed, reject stale results after tab/video changes. Keep original summary for Q&A and strip mark tags from display.
4. Replace subtitle Gemini calls with Claude backend calls. For speech under 600 seconds, translate all cues in one request, preserving complete context and timestamps. Cache provider/model explicitly. Keep Apify and verified Nova-3 zh-CN flow and upload fallback.
5. Remove Vbee source, configuration, package option, runtime diagnostics and tests. Nam Minh synthesis is progressive: first three cues unlock playback, subsequent groups prefetch under backpressure. Cache by voice/text, cancel old work on video change, prioritize seek. Account/session errors stop without retry storms.
6. Keep native video/audio clock authoritative. Avoid repeated tiny corrective seeks; distinguish a real seek/loop from small clock jitter. Preserve working background playback and mute ownership. Verify composition padding, adjacent chunk duration and missing audio behavior.

## Extension techniques applied and deliberate choices

- The extension prepares its first three subtitles synchronously, then synthesizes later groups asynchronously. The iOS scheduler prepares the group containing the current playback position, publishes it immediately, and continues with at most three simultaneous unique cue requests. The prefetch horizon is 60 seconds rather than the extension's 300 seconds, to bound paid work on a short-video feed.
- Translation context follows the extension's three preceding/two following subtitle objects. For tracks ending within 600 seconds, the complete ordered transcript is sent in one request; longer tracks use bounded batches. AI analysis uses a source-specific SHA-256 identity to avoid backend cache collisions between unrelated analyses.
- Downloaded MP3s are cached by exact voice/text. Backend responses must echo the requested translation before their audio can enter the timeline. Session expiry renews the supplied account once, and concurrent expired requests share that renewal. Quota errors and ambiguous timeouts do not repeat paid synthesis automatically.
- Each three-cue group exports an exact source-time M4A, with spectral compression and real silent trailing padding. Short ASR fragments under 0.9 seconds merge into an adjacent preceding cue only within the length/gap limits; all source text is retained. Voice compression is capped at 3x. Where necessary, the native video rate is multiplied by a factor from 0.5 to 1 so the effective voice speed remains at most about 1.5x at normal user speed. The original user speed is restored on stop, except when the user has subsequently changed it.
- The player uses a queue across prepared group boundaries, small rate corrections for jitter, and hard reanchoring for actual seeks/loops. Missing groups pause the video while preparing; failed groups retain Vietnamese subtitles and original sound, while later groups continue.
- Comments use a measured, scrolling Vietnamese reader inside the native comment viewport. Original mode preserves native reply/image controls and reserves space for the language switch; nested controllers share one active reader. Failed comment batches stop until explicit retry.
- AI capture first uses audited native renderer getters, then scoped web text, then local Chinese OCR. Two identical OCR captures are required; OCR results explicitly cover the visible analysis region. Images are never uploaded. Hidden/clipped nodes, translation UI and stale tab results are excluded.

## Final live sample

The previously verified Mandarin Nova-3 transcript contains 209 words over 67.454 seconds. The final coalescing rules turn 17 cues into 15, retaining all source text. A whole-context request with the exact context-object contract returned 15 AI translations in 12.078 seconds, with no remaining Han characters. All 15 requested Nam Minh audios downloaded successfully and echoed the exact text. The first three downloaded in 3.234 seconds, without waiting for the remaining 12. The most compressed final cue needs 2.158x on the source timeline and a 0.695 native rate factor at normal user speed. These timings exclude extraction, ASR, local export and player preparation; they are one live sample, not a latency guarantee or physical-device acceptance.

## Verification and release gates

- Parser/request tests: malformed/count mismatch, auth/quota, untrusted hosts, credential forwarding, cancellation and caches.
- UI fixtures: short Chinese to long Vietnamese, native fixed-height cells, nested containers, image/reply preservation through original mode, safe areas, scrolling and no duplicated controls; AI native/custom/web capture and stale OCR.
- Audio tests: cue timing, silence padding, first chunk before remaining work, prefetch/seek/cancel/failure, jitter and queue boundaries.
- Minimal live probes: actual whole ASR transcript -> Claude -> Nam Minh first group; validate audio durations and Vietnamese language. Never publish private transcripts/tokens/URLs.
- macOS build, iPhone Simulator fixtures, package integrity and original binary comparison. Produce a new private IPA only after checks pass. Physical iOS 18.5 validation remains explicitly separate from simulator/live API checks.
