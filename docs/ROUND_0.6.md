# Bản thử 0.6.0 — LIVE và âm thanh nền

## Bằng chứng và quyết định trước khi sửa

Diagnostics 0.5.0 trên iPhone 15/iOS 18.5: 50/50 hook active; DC feed có 8 callback, 4 lỗi `App -4` và 4 lỗi `App -11001`. Feed một cột có callback thành công. Search có 6 kiểm tra, đều 2483; adapter không được quan sát trong phiên này. Comment status 0 xuất hiện 155 lần đọc getter; không phải 155 trang hoặc số bình luận duy nhất. Image SDK có 36 failure callback, nhưng bao phủ toàn app và có retry; không thể tính tỷ lệ lỗi ảnh bình luận từ chúng. `App` là nhãn domain chưa biết; chưa thể gọi -1001 là timeout URL hoặc 900014 là lỗi giải mã.

Người dùng xác nhận năm control LIVE còn chữ Trung: 明星, 聊天, 唱歌, 团播, 颜值. Tên phòng/chat/bình luận không thuộc phạm vi dịch.

IPA gốc đã có `UIBackgroundModes = audio, fetch, voip, remote-notification`. Metadata/disassembly đúng build 406019 xác nhận store tùy chọn cục bộ `AWEAwemeBackgroundPlayStoreService`: `switchState` BOOL, `audioSwitchState` và `audioSceneState` NSInteger. `isSwitchON` đọc switchState; nhánh pinch đọc audioSwitchState; config all-scene chọn trạng thái 1. Bộ phát có lifecycle, radio mode và remote controls sẵn có. **Không ép `shouldEnterBackgroundPlayMode`, không đổi quyền nội dung, không chặn pause/interruption, không chạy âm thanh im lặng để giữ tiến trình.**

## Kế hoạch triển khai và tiêu chí kiểm tra

1. Dịch Stars / Chat / Singing / Groups / Beauty trong control LIVE được nhận diện, bổ sung namespace HTS và Swift AWELive với vùng bảo vệ nội dung. Nhận diện cụ thể `AWEFeedLiveTabTagView`. Dịch các getter title thuần trình bày trong model menu LIVE trước khi đo chữ. Giữ frames/constraints, co chữ và nhãn ngắn có khôi phục khi reuse.
2. Thêm tùy chọn `Background audio` trong Douyin Guest, mặc định ON theo yêu cầu. Chồng ba **getter preference** cục bộ trên store đã xác nhận; gọi getter gốc đúng một lần, OFF trả giá trị gốc, không ghi đè preference Douyin trên đĩa. Không đổi enum auto-next/replay hoặc cấu hình audio session chung. Tiếp tục dùng bộ phát/audio lifecycle gốc. Khởi động lại app sau khi đổi tùy chọn. Có thể vẫn bị native policy từ chối trên một số video; phải đo thực tế.
3. Quan sát nguyên trạng quyết định/entry/exit của background module. Phân loại domain lỗi theo whitelist cố định đã thấy trong binary; quan sát tối đa ba NSError underlying, bảo vệ cycle. Không đưa URL, keyword, cookie, error description, nội dung ảnh/comment hoặc raw domain lạ vào diagnostics. Giữ nguyên retry/alternative URL của SDK ảnh.
4. Kiểm tra Foundation: ABI, gọi gốc một lần, ON/OFF, giá trị integer, lỗi domain/chain/cycle, không đổi trạng thái server. UIKit fixture: năm LIVE control ở bề ngang hẹp, reuse và bảo vệ chat/tên phòng; settings mới. Packaging giữ nguyên background modes, quyền, code/offsets; build arm64 và signature qua macOS CI. Review ảnh fixture trước khi đóng gói; kiểm tra IPA độc lập so với nguồn.
5. iPhone: video đang chạy → khóa 30 giây/2 phút; pause → khóa không tự phát; cuộc gọi; rút tai nghe; chuyển app; quay lại; ON/OFF sau restart; LIVE có bị ảnh hưởng không. Kiểm tra video thật/thumbnail/pagination riêng, Search/Featured/Tips riêng. Fixture không thay thế việc chạy Douyin trên thiết bị.

## Nghiên cứu đã đọc

- [Apple UIBackgroundModes](https://developer.apple.com/documentation/bundleresources/information-property-list/uibackgroundmodes): khai báo audio chỉ là một phần của hỗ trợ chạy nền.
- [Apple playback category](https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct/playback): audio khi khóa màn hình cần playback category và background audio; kích hoạt session ảnh hưởng các app khác.
- [Apple Media Playback Guide](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/MediaPlaybackGuide/Contents/Resources/en.lproj/ConfiguringAudioSettings/ConfiguringAudioSettings.html): cấu hình session, activation và background capability; phù hợp API trên iOS 18.5.
- [Apple interruptions](https://developer.apple.com/documentation/avfaudio/handling-audio-interruptions): giữ xử lý ngắt của bộ phát; phần API iOS 27 trong tài liệu hiện hành không áp dụng cho thiết bị iOS 18.5.
- [DYYY pinned source](https://github.com/huami1314/DYYY/blob/6c3dfbd911822b4d0f758f184c196566e8142291/DYYY.xm#L5855): thay listenVideoStatus 1→2. Không sao chép cách này vì nó đổi trạng thái nội dung thay vì preference và chưa chứng minh semantics/quyền trong mẫu này. Giải pháp dùng preference native được tự viết từ metadata/disassembly mẫu chính xác.

Đọc tài liệu/source qua HTTPS ngày 2026-10-02, lưu SHA-256/URL trong evidence; không thực thi mã tải về. Không có bằng chứng đã kiểm chứng về guest native Search không giới hạn tương thích bản này trong các nguồn đã đọc ở vòng 0.4–0.6.

## Giới hạn còn nguyên

Không giả mạo cookie/token/account state hoặc lấy nguồn phát không được cấp quyền. Server vẫn có thể hạn chế Search, comment pagination, Featured/Tips; chưa biết ý nghĩa domain của DC -4/-11001 trên thiết bị. Không xóa hai tab vì người dùng chưa xác nhận. Không gọi bản này là hết lỗi hoặc đã xác nhận phát khóa màn hình nếu chưa có kết quả iPhone.

## Vòng kiểm tra và sửa lại

Vòng 36953743503 phát hiện trùng biến trong Foundation test; 36953877340 phát hiện trùng biến trong UIKit visual fixture. Đã sửa. Vòng 36953968534 đạt 93/94 UIKit checks nhưng đo thực tế hai nhãn background dài 198.34/200.15pt, chưa vừa control 120pt tại scale tối thiểu 65%. Thêm compact `Audio after lock` / `Background playback` khi cần; giữ full label khi đủ rộng rồi chạy lại toàn bộ. Năm LIVE label đạt cả 63pt/32pt, khôi phục full khi rộng và bảo vệ room/chat. Review ảnh LIVE cũng không thấy cắt chữ. Không đóng gói từ các vòng thất bại.
