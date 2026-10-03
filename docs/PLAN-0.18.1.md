# 0.18.1 — Deepgram timestamp repair

The reported message came from one broad guard that rejected the entire transcript if any word had zero duration, a negative rounded start, a start below the previous start, an inverted end or a large duration overshoot. Saved live responses do not reproduce the user's exact latest case; new regression cases reproduce the failing guard. The latest video's link/diagnostics are requested for further correlation.

The parser now retains transcript order and all text. Point timestamps join adjacent real speech intervals; leading point text joins the next timed word, and silence before that word remains silent. Tiny negative/rounding errors up to 20 ms and start regressions up to 500 ms are repaired inside existing timing anchors. Cue boundaries do not overlap. Repair flags survive short-cue coalescing and appear as `Captions timing repaired` counters.

Large resets, substantial inversions, timestamps more than two seconds beyond the media duration, nonnumeric timing and entirely zero-duration transcripts still fail explicitly. Errors identify the word position and category rather than returning one generic message. No uniform fabricated word durations, sorting of transcript text or automatic paid ASR retries are introduced.

Verification covers zero timestamps at the beginning/middle/end, silence, small regressions/negative starts, rounding inversions, major resets, duration drift, all-point input and repair diagnostics. UIKit's complete subtitle/voice flow now includes a zero-duration Chinese word. An anonymized real 209-word timing fixture is replayed with malformed point/regression examples. The fixture retains timing and word lengths only, with neutral text replacing private speech.

Release gates: Foundation/media regressions, audio regressions, complete UIKit fixture, arm64 build, private package resource/hash checks and independent original-IPA comparison. Physical iPhone acceptance remains separate.


Latest accepted scope: subtitle-only delivery. Remove all Nam Minh synthesis/rolling audio and mute/rate code; retain the verified background audio companion. Strip the unused legacy voice field from private packaging. HTTP 200 empty ASR is diagnosed separately from the actual 3600-second limit. Use a valid nonempty channel/alternative or authoritative timed utterances; do not manufacture word timings. A valid empty remote response permits one audio-track/duration-verified binary upload with documented Nova-3 language detection, then terminates on another empty result. Authentication, rate limits, malformed JSON and genuine overlong media do not enter recovery.

Speed: use the same verified native source getter as background audio to download/inspect/extract aligned audio and bypass Apify when available. Fall back to Apify once if native downloading fails before any ASR charge. Cache completed ASR/translations, batch full context below 600 seconds, and allow translated current speech to start while later long-video batches run; pause only when an untranslated speech interval is reached. Actor waitForFinish=10 long-polls avoid extra one-second HTTP round trips. Never claim fixed network/provider response time.

Reading layout: follow BBC guidance (three lines for vertical, two for landscape), center within available video area, reserve bottom description/right action rail, use padded white text on a dark background at 19-24pt, and allow vertical dragging inside a safe band. Paginate exceptional long translated cues by TextKit's actual measured lines. All pages stay within the original cue start/end; page transitions are proportional to text length, not asserted word-level alignment. Pause/seek/loop uses native playback time.

References read 2026-10-03:
- https://developers.deepgram.com/docs/language-detection (documented nova-3-general + detect_language=true)
- https://developers.deepgram.com/docs/models-languages-overview (zh-CN supported)
- https://www.bbc.co.uk/accessibility/forproducts/guides/subtitles/ (line count, placement, contrast and avoiding picture information)
- https://partnerhelp.netflixstudios.com/hc/en-us/articles/215758617-Timed-Text-Style-Guide-General-Requirements (center justification and avoiding onscreen text)

Additional gates: real AVFoundation source-audio verification; mocked remote-empty/binary-success, repeated-empty terminal failure, native-source shortcut/cancellation; long accented Vietnamese/emoji pagination and timeline boundaries; live binary Mandarin probes with sanitized timings/counts only. No physical iPhone test is available in this environment.
