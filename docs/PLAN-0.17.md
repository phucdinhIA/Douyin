# 0.17 comments and progressive dubbing

## Device evidence

The user confirms 0.16 background audio works on iOS 18.5. Preserve the companion player's source resolution, notifications, clock capture, remote commands and foreground resync. GTX captured 8 comments but received 7 HTTP 429 responses. Subtitles reached Deepgram/Gemini successfully; Vbee received a 504 and never completed its all-video export. These are provider/buffering failures, not evidence that Mandarin language selection is wrong. Nova-3 `zh-CN` remains the verified source language.

## Desktop extension study

Read-only reference: `C:/Users/Quoc Phuc/Desktop/Project/Extension/Bản dubbing xịn nhất/Youtube Dubbing`. No AGENTS.md exists in it or its Project/Extension ancestors. Its production files are bundled/minified, so character offsets identify the algorithms more precisely than their very long line numbers.

`chunks/RealtimeDubbingEngine-dw5e_iKG.js`:

- `Lr.getBatchPendingSubtitles`, offsets ~81,000–82,500: exclude completed/cached audio; take at most 3 pending subtitles. `processContentBatch` downloads audio immediately into blobs, deduplicates completed items, and carries cancellation signals/request IDs. Text longer than 40 characters is split at punctuation/space, with proportional display timings. Translation context includes 3 preceding and 2 following source segments; this is less context than the user's requested full short-video transcript.
- `ze.processNextSingleBatch` and `Br`, ~85,000–88,500: serialize subtitle track updates; first prepare one batch, then continue asynchronously. Prefetch is bounded to 300 video seconds ahead; sleep 1 second beyond that horizon, waking on stop. Audio/translation metadata is retained per subtitle.
- `start`, ~127,000–129,500: pause video, recalculate current subtitle, await its first batch, launch the remainder without awaiting it, then play. `onTimeUpdate`/`isSubtitleAudioReady` pause when playback reaches unprepared speech. `onSeeked` clears playback state and restarts from the new anchor, retaining prepared metadata.
- `onCueEnter`, current-playing maps and seek methods: anchor audio to the media clock rather than wall time. Pause/resume audio with video. Restore volume and release stale sessions on media identity changes. The duration/rate adjusters near offsets 3,500–7,000 bound audio speed (~0.9–1.5x) and may slow video; the Douyin mixed-original branch instead keeps the user's video speed and bounds audio (~0.85–1.65x).
- The extension uses endpoint leases and up to 10 retry attempts for its own providers. Do not copy that retry policy to paid Vbee POSTs: a gateway timeout may already have consumed credit, and Vbee's public contract does not promise an idempotency key. Its empty-audio placeholder also must not be reported as successful narration.

Read the associated local-player/content bundles to distinguish subtitle scheduling from bundled HLS buffering and parser lookahead; those HLS terms are not the TTS algorithm. Audio-lifecycle ownership/restoration is already present in the native patch.

## Implementation

1. Ordinary visible comments: batch up to 8 unique visible sources into one GTX request with validated per-comment markers; persist individual cache entries. Pace all clients through one shared gate, honor Retry-After on 429, retain cooldown across panel reopen/app restart. Do not rotate endpoints to bypass limits. A minimal local live probe returned HTTP 200 and preserved both markers. Ask the user whether paid Gemini fallback is acceptable when free GTX is blocked; do not silently change the free-only requirement.
2. Short video (speech timeline <=600 seconds): send every ASR cue in timeline order in one Gemini structured translation request, with a larger bounded output budget and complete-ID validation. Keep authoritative times locally. Long videos retain bounded prioritized batches. Cache translation as a whole; never accept truncated or missing IDs as completion.
3. Rolling Vbee: synthesize/export 3-cue chunks, up to 3 concurrent synthesis calls within a chunk. Prepare the current chunk first, then prefetch at most 60 seconds ahead. Download expiring links immediately, cache voice/text audio and reuse it after seeks. Each chunk contains exact start/end offsets and silence gaps. Start after the first relevant chunk aligns, while later chunks continue. A failed chunk falls back to Vietnamese subtitles and original audio; continue preparing later chunks, expose the error, and never silently repeat an ambiguous paid POST.
4. Queue local chunks ahead in AVQueuePlayer, align to the native clock with per-item offsets, and rebuild after seeks/loops. Pause when foreground playback reaches an unprepared chunk; resume only when the same video's audio is ready. Keep background companion lifecycle intact. Cancel stale work on model/controller changes and delete temporary exports.
5. Verify contracts, full-context output, batching/cooldown/cancellation, first-chunk startup, seeks, missing chunks, isolated timeout, real audio timing and end-to-end fixtures. Run live minimal provider probes without publishing keys, signed URLs or transcripts. Compile arm64/Simulator on macOS CI; package a new private IPA without overwriting 0.16. Physical iPhone acceptance remains separate from fixture success.
