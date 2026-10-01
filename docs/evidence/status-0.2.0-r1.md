# Trạng thái kiểm chứng

Candidate: **0.2.0-test / packaging revision 1**. Đã đóng gói và kiểm thử tự động; **chưa kiểm chứng trên iPhone thật, chưa phải bản hoàn chỉnh**.

| Hạng mục | Kết quả đã kiểm tra |
|---|---|
| Identity/hash IPA gốc | 40.6.0 / 406019 / arm64; hash trước/sau khớp audit |
| 30 native hook | Selector, method kind và type encoding khớp metadata mẫu; 11 login guide, 19 ads/feed/splash |
| Bốn dấu hiệu ad | `isAds`, `checkIsAd`, `isHardAdModel`, `isHardAd` đúng BOOL trên `AWEAwemeModel`; disassembly giới hạn bằng `LC_FUNCTION_STARTS` |
| Python | 14/14 tests đóng gói đạt trên Windows và CI macOS |
| Foundation | Policy và hook regressions đạt; gồm bốn dấu hiệu ad, forwarding, metaclass, inheritance, direct-ivar list, switch, sai ABI và malformed config |
| Build | arm64 / deployment iOS 15.0; Xcode 15.4 / SDK iOS 17.5; warnings-as-errors đạt |
| Chữ ký thư viện | Ad-hoc `codesign --verify --strict` đạt; IPA vẫn cần ký lại bằng Sideloadly |
| UIKit fixture | **26/26 checks đạt**, iPhone 15 Simulator / iOS 18.2 |
| Chuỗi và fitting trong fixture | 278/278 labels đi qua UIKit hook ở ngữ cảnh Settings; thử 120pt/16pt, reuse, nil, attributed styles, button fallback và dark appearance |
| Bảo vệ nội dung trong fixture | Caption/comment/search text và creator profile không bị dịch nhầm trong các ca đã dựng |
| Bảng chẩn đoán trong fixture | Gesture không lặp; fallback khi scene enumeration rỗng; modal mở được |
| ZIP candidate | Đọc lại/hash **5.629 entry**, không sai lệch |
| So sánh độc lập | **5.620 entry** khớp CRC/size/mode nguồn; **4.977 file không sửa** khớp SHA-256 audit trước đó |
| Binary gốc | AwemeCore nguyên vẹn; executable chỉ đổi 51 byte trong header, không đổi kích thước/nội dung code phía sau |
| Cài candidate trước trên iPhone 15/iOS 18.5 | Người dùng báo `DeviceNotSupportedByThinning`; chưa vào được app |
| Cài candidate sửa metadata | **Chưa thử lại trên iPhone** |
| Không popup, không ad, xem video, layout mọi màn | **Chưa được chứng minh trên app thật** |
| An toàn tổng thể của mẫu internet | Kiểm thử patch không chứng minh toàn bộ IPA gốc an toàn |

CI thành công: [36827280855](https://github.com/phucdinhIA/Douyin/actions/runs/36827280855), source commit `b3357d16888c9e59087c51f5c83cd4d45638d00b`. Artifact tải về đã đối chiếu commit, trạng thái run và SHA-256.

Hai vòng fixture trước đã phát hiện lỗi kiểm tra: [36826255486](https://github.com/phucdinhIA/Douyin/actions/runs/36826255486), [36826863437](https://github.com/phucdinhIA/Douyin/actions/runs/36826863437). Giả định “không Scene Manifest thì connectedScenes rỗng” không đúng trên runtime này; test hiện kiểm tra plist và dựng riêng tình huống scene rỗng. UILabel lưu/trả minimum scale `0.6499999761581421` khi đặt `0.65`; đã đo trực tiếp và dùng tolerance `1e-6`, vẫn kiểm tra đúng chuỗi, fitting và scale. Không bỏ ca thất bại để cho test đạt.

Candidate cục bộ: `dist/Douyin-40.6.0-Guest-0.2.0-iPhone15-TEST.ipa`, **704.813.212 byte**.

SHA-256 IPA:

`b994e7807752a9dbe9a6168fdb3e844c4ddc4e3220eb4d9d4f7d8c9f131a6b5d`

SHA-256 thư viện:

`24facd4d87f47880c53c4919b4095e31968d23c531df925bb1ace3d92cf6824c`

Bản 0.1.0 và IPA gốc vẫn được giữ nguyên. Repository không chứa IPA/binary Douyin.

- [Kết quả UIKit nguyên bản từ artifact](ui-results-0.2.0.json)
- [Ảnh fixture đã xem để kiểm tra chữ/bố cục](ui-fixture-0.2.0.png)
- [Tóm tắt kiểm chứng máy](validation-0.2.0-r1.json)
- [Nguồn nghiên cứu và quyết định áp dụng](../RESEARCH.md)
- [Nguồn internet đã đọc và hash file](research-sources-0.2.0.json)
- [14 ca cần chạy trên iPhone](../DEVICE_TESTS.md)

Báo cáo chi tiết hash mọi entry nằm cạnh IPA dưới đuôi `.validation.json`; đối chiếu audit độc lập nằm trong `.independent-validation.json`. Bước còn thiếu để chốt là ký/cài candidate 0.2.0 bằng Sideloadly trên iPhone 15/iOS 18.5, chạy D01–D14 và cung cấp diagnostics/kết quả lỗi. Fixture không xác nhận khả năng truy cập video do máy chủ giới hạn hoặc bao phủ mọi quảng cáo/WebView/Lynx.

## Sửa lỗi cài đặt DeviceNotSupportedByThinning

Danh sách `UISupportedDevices` trong IPA trước chỉ có `iPhone10,1`, `iPhone10,4`, `iPhone12,8`, `iPhone14,6`, `iPhone9,1`, `iPhone9,3`; thông báo của thiết bị yêu cầu tương thích `iPhone15,4`/`iPhone15,2`. Bộ đóng gói trước đã giữ nhầm danh sách của bản App Store thinned.

Revision 1 bỏ đúng khóa `UISupportedDevices` ở Info.plist chính. Sau sửa đã quét **287 Info.plist**, không còn khóa đó; app và tám extension đều có executable arm64. `UIDeviceFamily`, `UIRequiredDeviceCapabilities` và `MinimumOSVersion` được giữ nguyên. Bộ đóng gói cũng xử lý allowlist nếu gặp trong extension, nhưng các extension của mẫu hiện tại không có khóa này.

Đối chiếu trực tiếp với candidate 0.2.0 trước: **5.628 entry có bytes giống hệt**, chỉ một entry `Payload/Aweme.app/Info.plist` khác; nội dung dictionary chỉ mất khóa nêu trên. Thư viện và cấu hình không đổi nên kết quả Foundation/UIKit trước vẫn là bằng chứng cho cùng mã, không phải kết quả chạy lại Douyin thật. Full read-back/hash và đối chiếu audit của IPA mới cũng đạt, không có sai lệch.

[Bằng chứng sửa metadata cài đặt](installation-compatibility-0.2.0-r1.json). Test mới dựng IPA fixture chứa allowlist ở app/extension để kiểm tra cả quá trình đóng gói và giữ nguyên các yêu cầu phần cứng/OS; 14/14 Python tests đạt cục bộ và CI macOS.

Sửa allowlist xử lý nguyên nhân từ chối cài được báo trong ảnh; không chứng minh đầy đủ tài nguyên của mẫu thinned phù hợp mọi thiết bị. Cần thử lại Sideloadly, mở app và kiểm tra playback/layout trên iPhone. Diagnostics vẫn báo `0.2.0-test`; nhận biết revision 1 bằng tên file có `iPhone15` và SHA-256 mới.

CI vòng sửa metadata [36836830226](https://github.com/phucdinhIA/Douyin/actions/runs/36836830226) đã đạt: 14 Python tests, Foundation, build arm64 và 26/26 UIKit checks trên iPhone 15 Simulator/iOS 18.2. Thư viện build lại có SHA-256 khớp chính thư viện đã đóng gói; [kết quả UIKit vòng này](ui-results-0.2.0-r1.json). Vẫn chưa thử cài lại trên iPhone thật.
