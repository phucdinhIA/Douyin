# 0.18.1 — Deepgram timestamp repair

The reported message came from one broad guard that rejected the entire transcript if any word had zero duration, a negative rounded start, a start below the previous start, an inverted end or a large duration overshoot. Saved live responses do not reproduce the user's exact latest case; new regression cases reproduce the failing guard. The latest video's link/diagnostics are requested for further correlation.

The parser now retains transcript order and all text. Point timestamps join adjacent real speech intervals; leading point text joins the next timed word, and silence before that word remains silent. Tiny negative/rounding errors up to 20 ms and start regressions up to 500 ms are repaired inside existing timing anchors. Cue boundaries do not overlap. Repair flags survive short-cue coalescing and appear as `Captions timing repaired` counters.

Large resets, substantial inversions, timestamps more than two seconds beyond the media duration, nonnumeric timing and entirely zero-duration transcripts still fail explicitly. Errors identify the word position and category rather than returning one generic message. No uniform fabricated word durations, sorting of transcript text or automatic paid ASR retries are introduced.

Verification covers zero timestamps at the beginning/middle/end, silence, small regressions/negative starts, rounding inversions, major resets, duration drift, all-point input and repair diagnostics. UIKit's complete subtitle/voice flow now includes a zero-duration Chinese word. An anonymized real 209-word timing fixture is replayed with malformed point/regression examples. The fixture retains timing and word lengths only, with neutral text replacing private speech.

Release gates: Foundation/media regressions, audio regressions, complete UIKit fixture, arm64 build, private package resource/hash checks and independent original-IPA comparison. Physical iPhone acceptance remains separate.
