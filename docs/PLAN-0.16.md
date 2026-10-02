# 0.16 repair and dubbing plan

The user reports that 0.15 passed only one subtitle video on iOS 18.5, GTX never sent a translation, and background playback failed. Previous Simulator success did not establish compatibility with the original app on a physical iPhone.

## Evidence and provider contracts

- Recent Apify runs all succeeded. Actor video URLs redirect to Douyin video CDNs.
- A 13.536-second recent video reproduced Deepgram HTTP 400, `REMOTE_CONTENT_ERROR`: its server received HTTP 460 from the CDN. The same video sent as binary MP4 returned HTTP 200, 13.537 seconds, 34 timed words. Nova-3's documented Mandarin codes include `zh-CN`; retain it.
- Vbee's official Studio frontend links to [its public API collection](https://documenter.getpostman.com/view/12951168/Uz5FHbSd). Verified the voice catalog with the user's application. Selected the production Vietnamese male voice Mạnh Dũng (`hn_male_manhdung_news_48k-fhg`). A minimal live `response_type: direct` request succeeded without a callback and returned an MP3. Indirect requests require a callback URL. Audio URLs expire after three minutes, so download immediately.
- Static native metadata verifies `YYLabel.textLayout`, `YYTextLayout.text/container`, comment panel lifecycle methods, native playback URL/clock, pause/resume, mute and seek methods. Never assume private completion-block parameters from the selector alone.

## Flows

1. Opening an ordinary native comment panel starts a bounded visible-view scan. Read native comment labels including `textLayout`, or match label contents to known comment-model text. Exclude hidden/offscreen text, author names, input fields and AI/Lynx renderers. Queue GTX requests serially, reuse cached translations, apply answers in place only to a still-visible matching source. Closing/backgrounding cancels work. Stop the queue on quota/network failure. Reopening permits another attempt.
2. Four taps still opt in to subtitles for only the current video. Pause before any provider request. Reuse ASR/translations when available. Otherwise run the existing Apify actor, try the original Deepgram URL request, and only for verified `REMOTE_CONTENT_ERROR` download the source (256 MiB limit), extract M4A audio, and upload binary data. Authentication, configuration and quota errors do not trigger this fallback. Validate timing against actor duration and translate the timestamped cues through Gemini.
3. When Vietnamese cues are complete and private Vbee configuration exists, synthesize individual cues with at most three in-flight requests. Cache MP3s by voice/text digest. Measure audio duration; place each cue at its subtitle start. Compress overlong speech within the available cue/gap using spectral time-pitch export. Reject compression beyond 3x, retain subtitles and expose the failure. Export one local M4A timeline. Mute the native source while dubbing and synchronize against the actual video clock, pause, rate, seeks and loops.
4. Background playback uses a dedicated AVPlayer for the audited current native source URL; it makes no Apify requests. Capture whether the user was playing at resign-active, seek to that position, activate the audio playback session and mute the native source to prevent overlap. Dubbing follows the companion clock. Foreground return seeks the native player to the companion position; restore mute state and playback appropriately. Stop on model changes, route disconnection, interruption or explicit cancellation. Preserve the original audio background entitlement.
5. Strip only HTML `mark` highlight tags from the Vietnamese AI-analysis display, including cached results; retain their contents.

## Verification and handoff

Provider probes, request/response validation, cache and cancellation regressions, native UIKit fixtures, timeline export/audio tests, arm64 compilation, strict private packaging validation and credential-leak scans are required. Use synthetic keys in CI. Keep personal configurations outside Git and embed only in the private deliverable. Retain previous IPA files. Physical iPhone acceptance must still cover ordinary and Swift comments, consecutive short videos, seeks, loops, foreground/background transitions, headphones and incoming calls. Do not claim physical-device stability from fixtures.
