# Trạng thái kiểm chứng — 0.4.0-test

Candidate gộp 0.3.0 và các yêu cầu tìm kiếm/giao diện mới. **Người dùng chưa cài 0.3.0; có thể bỏ qua bản đó và thử thẳng 0.4.0.** Tìm kiếm trên iPhone thật chưa được kiểm chứng; Network error của Featured/Tips chưa được sửa nguyên nhân và hai mục vẫn giữ nguyên.

File: `dist/Douyin-40.6.0-Guest-0.4.0-iPhone15-TEST.ipa`, **704,832,301 byte**.

SHA-256 IPA: `b9aaec9f01039839ee92f5af25a9c076ab986ef5137d2ce04520f8bbd1e8241a`

SHA-256 thư viện: `d95995453bd0e54a8d27ed2a2016ed8b23302d8035376fa65e2a56708819d1d0`

Commit build: `930ebb35aab201df890a29324b3b88f34fe21f67`. CI [vòng cuối 36863785258](https://github.com/phucdinhIA/Douyin/actions/runs/36863785258) thành công.

| Phần kiểm tra | Kết quả |
|---|---|
| Python | 14/14 packaging regressions đạt Windows và macOS CI |
| Foundation | Policy, hook, guest adapter, đổi ON/OFF, giữ superclass, cài lặp, adapter nil/sai ABI và giữ status/message gốc đạt |
| Build | arm64 / iOS 15.0, Xcode 15.4 / SDK 17.5; warnings-as-errors và ad-hoc signature verification đạt |
| UIKit | **58/58 checks đạt**, iPhone 15 Simulator / iOS 18.2 |
| Từ điển | **853 chuỗi**, thêm 551; toàn bộ 853 đi qua hook trong fixture và vừa control 120pt ở font 16pt, với compact variant khi cần |
| Rà soát tĩnh | AwemeCore + AWESearchFramework; 752 khóa dịch có trong hai binary; 104 file .strings/.stringsdict được đọc, không lỗi parse resource |
| Bố cục | 94pt grid, Settings 32pt, UIKit/YYLabel, font thay đổi, mở rộng/thu hẹp, multiline, attributed styles, nil/reuse, dark appearance đạt trong fixture |
| Nội dung người dùng | Caption, comment body, result content, nickname, tên profile và từ khóa nhập được giữ trong các ca fixture |
| SDK | Chọn giá trị en.lproj cùng key/table; thiếu bản Anh giữ chữ gốc; format %ld được giữ trong fixture |
| Tìm kiếm khách | 5 gateway metadata đúng; resolve adapter bằng app, preflight 2 method BOOL thực tế; OFF gọi gốc; **chưa xác nhận adapter thật active trên iPhone** |
| Diagnostics | 39 fixed hooks; dynamic search adapter counts riêng; feed NSError category/code và numeric search status, không ghi từ khóa/message/URL/token |
| ZIP | 5,629 entry read-back/hash; 5,620 entry không sửa khớp CRC/size/mode; 4,977 file khớp SHA-256 audit; 0 mismatch |
| Binary gốc | AwemeCore nguyên vẹn; executable chỉ đổi 51 byte header, giữ size/code sau header |
| iPhone 15 / iOS 18.5 | **Candidate mới chưa được cài/chạy** |
| Network error Featured/Tips | **Chưa xác định nguyên nhân, chưa sửa; không xóa/ẩn** |

## Thay đổi có thể thử ngay

**Guest search** là tùy chọn riêng, mặc định ON khi chưa có preference. Wrapper mở cổng `enableGuestSearch`/`hasRemainingGuestSearchCount` trên service mà app thực sự trả về, khi cả hai có đúng ABI. Không thay isLogin, tài khoản, token, TLS, request signing hoặc status máy chủ. Không tạo method giả nếu service thiếu hoặc chỉ có forwarding; diagnostics báo không cài được. [Luồng tìm kiếm, metadata, nguồn nghiên cứu và giới hạn](GUEST_SEARCH.md).

Tiếng Anh mở rộng ở Search/filter/empty page, Settings/privacy/notifications, playback/offline/cache/subtitles, sidebar/profile tabs/LIVE và các lỗi thông thường. Có xử lý khoảng trắng quanh label, nhận diện tên Swift của control, dịch control cụ thể trong màn kết quả/comment nhưng giữ body. YYLabel có ABI đối chiếu được hỗ trợ riêng vì không phải UILabel; co font một dòng tới mức tối thiểu 65%, giữ màu/styles và khôi phục font/tên đầy đủ khi rộng hơn hoặc reuse. Không đổi frame/constraints. SDK có en.lproj dùng tài nguyên tiếng Anh có sẵn cho cùng key/table, không gọi dịch vụ dịch ngoài.

Rà soát không đồng nghĩa mọi chữ Trung trong binary là UI: có logs, flags và nội dung. 2.700 CFString đủ điều kiện ở AwemeCore trỏ vào vùng không có bytes trong file (đuôi zero-fill của __DATA), chưa đọc được tĩnh; 101 khóa từ điển chưa tìm thấy trong hai binary. WebView/Lynx, chuỗi máy chủ, chữ trong ảnh và mọi màn thật chưa được chứng nhận dịch đầy đủ. [Báo cáo rà soát theo nhóm và resource](evidence/localization-audit-0.4.0.json).

## Bằng chứng hình ảnh và vòng sửa

Đã xem [sidebar](evidence/ui-sidebar-0.4.0.png), [màn lỗi](evidence/ui-network-error-0.4.0.png), [Search](evidence/ui-search-0.4.0.png), [Settings](evidence/ui-settings-0.4.0.png). Chữ control mẫu rõ, không bị cắt/chồng; chữ Trung `首页` trong ảnh Search là **nội dung kết quả được cố ý bảo vệ**. Đây là app fixture riêng với UIKit thật/lớp AWE giả, **không phải Douyin chạy trên Simulator hoặc ảnh iPhone thật**. Constraints và dịch vụ thực tế cần kiểm tra trên thiết bị.

Vòng [36862205349](https://github.com/phucdinhIA/Douyin/actions/runs/36862205349) thất bại ở phép kiểm độ rộng, đã thêm compact title cho câu kiểm tra kết nối và các chuỗi dài. Vòng [36863160540](https://github.com/phucdinhIA/Douyin/actions/runs/36863160540) đạt 58/58; review ảnh phát hiện nền đen do YYLabel giả của fixture vẽ opaque, đã sửa fixture thành nền trong để đọc được chữ. Vòng cuối chạy lại đầy đủ và review ảnh cuối, không bỏ ca lỗi để cho test đạt. [Kết quả UIKit nguyên bản](evidence/ui-results-0.4.0.json).

IPA gốc và các candidate cũ giữ nguyên. [Trạng thái 0.3.0 được lưu](evidence/status-0.3.0.md); [summary máy](VALIDATION.json). Manifest hash/đối chiếu độc lập ở cạnh IPA cục bộ. Repository không upload binary Douyin.

**Bước còn thiếu:** ký/cài 0.4.0 bằng Sideloadly, bật Guest search/English controls, thử tìm kiếm và các màn UI rồi gửi Copy diagnostics; thử Retry Featured/Tips để lấy mã lỗi feed. Mong đợi patch_version 0.4.0-test, native_hooks_expected 39 và search_adapter_hooks riêng sau khi Search.
