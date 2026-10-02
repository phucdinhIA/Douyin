# Evidence and limits — 0.10

Source pages fetched on 2026-10-02 and read as untrusted data; original IPA and third-party mods were not executed. [Online status/hashes](evidence/0.10-online-evidence.json) · [Native trace](evidence/0.10-static-trace.json) · [Hook/getter ABIs](evidence/0.10-native-abi.json).

- [Official Douyin download page](https://www.douyin.com/downloadpage/app) returned HTTP200. It is distribution/product material, not the source implementation of Android networking. No claim of decompiling or testing the official APK is made.
- [APKPure Douyin listing](https://apkpure.com/douyin/com.ss.android.ugc.aweme) could not be retrieved successfully. No technical fix is attributed to it.
- [Android douyim pinned README](https://github.com/1zzzzzlll/douyim/blob/1f662082493f909dcf121a9681aac1574a97421a/README.md) describes native VideoEngineListener playback state tracking. It supports tracking actual state and lifecycle, not unconditional play-state overrides or portable iOS feed repair.
- [DYYY pinned source](https://github.com/huami1314/DYYY/blob/6c3dfbd911822b4d0f758f184c196566e8142291/DYYY.xm) includes listen-mode changes but no validated fix for this exact failing DC request. Its per-content restrictions rewrite is not adopted.
- [Apple AVAudioSession playback](https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct/playback) and [UIBackgroundModes](https://developer.apple.com/documentation/bundleresources/information-property-list/uibackgroundmodes) describe platform requirements for background audio. The original IPA already includes audio background mode. Preference getters and a declaration do not establish an audible running player or valid audio session.

Native evidence:

- `AWEDCFeedDefaultDataController buildRequestParams:` `v24@0:8@16`, `0xf72440c`, copies dataConfig.requestBodyParams to a newly built dictionary. `fetchDataWithPullType:completion:` at `0xf723878` creates that dictionary, calls the builder, and creates a normal request. Only its exact tidy negotiation field is omitted in this candidate; whether that field is present at runtime remains unknown. Response parsing/error semantics remain native.
- `AWEDCFeedDefaultDataControllerWrapper` forwards refresh to its `dataController refreshWithCompletion:`. Actual runtime categories are now observed with a fixed whitelist; unknown controllers are not forcibly cast to the default.
- `AWESearchMidDCDataController` also implements the DC protocol, builds separate outer/inner body params and has stream/ordinary request paths. No hook is invented for an unresolved selector ABI or inferred superclass. Prior class-name filtering alone was insufficient. These facts do not prove this is the user's current controller.
- `AWEAwemeBackgroundPlayModule shouldResponseNotification`, `B16@0:8`, `0x1d0cded8`, can reject a module when its model/appearance/playback state does not satisfy native conditions. The device report has eight native NO decisions and no entry call. The precise rejected condition is not yet proven.
- `isActivePlayModule` at `0x1d0cdcd8` compares the module's fromID with native Now Playing fromID. Recovery requires this original ownership check, model identity, verified delegate class/ABIs, original eligibility and no explicit user pause. The original handlers still check PiP and transition through native radio-mode/Now Playing handling.
- `AWEPlayVideoViewController shouldEnterBackgroundPlayMode` retains player action-state and settings/model decisions. No hook forces its result. The candidate cannot promise playback for blocked content or a valid AVAudioSession merely from hook installation.

The AI screenshot is an analysis page with Chinese generated prose and native/hybrid chrome. AI解析 was already mapped to AI summary; its continued appearance demonstrates renderer/scope limitations. Five exact chrome/placeholder entries are added and tested on native fixtures only. Douyin's authenticated AI chat is not unlocked; dismissing its login dialog would not grant server access.

**Unverified:** deployed payload/framing root cause, the user's actual loader/body flag, audible lock-screen playback, complete hybrid AI translation and physical-device behavior of this candidate. Static traces/contracts are evidence for the client changes, not server or iPhone acceptance.
