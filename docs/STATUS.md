# Trạng thái 0.5.0-test

**Candidate giao diện/chẩn đoán; chưa hoàn thành toàn bộ yêu cầu guest.** Featured/Tips, ảnh tải chậm và quyền đọc/tìm kiếm phía server chưa được khắc phục hoặc chứng nhận. Hai tab vẫn giữ.

File cục bộ `dist/Douyin-40.6.0-Guest-0.5.0-iPhone15-TEST.ipa` — 704,839,640 byte. SHA-256: `dcaad8fc9a26eccf1a4e54f73da709cf4891e67e2d49e191044e3f670ce84d35`. Thư viện `adc66517d67e17e09dca5a74b1178fe2ae26222186216982ce3583f662446cee`, build từ `b1feb4be8302b70554e5dbe72e4d3db459129cdb`; thay đổi tài liệu về sau không làm đổi binary.

| Kiểm tra | Bằng chứng |
|---|---|
| CI macOS | [Vòng 36950206145](https://github.com/phucdinhIA/Douyin/actions/runs/36950206145): 14 Python tests, Foundation regression, arm64 build/signature đạt |
| UIKit thật trong fixture | 74/74 checks trên iPhone 15 Simulator/iOS 18.2; 873 labels ở 120pt, Featured 60/120pt, comment controls, collection links, survey config, bảo vệ nội dung |
| IPA | 5,629 entry đọc lại/hash; 5,620 entry khớp CRC/size/mode; 4,977 file khớp SHA audit; 0 mismatch |
| Binary gốc | AwemeCore nguyên vẹn; executable đổi 51 byte header; size/code giữ nguyên |
| Native metadata | 50 fixed hooks; 7 presentation, 5 search observer gateways, 8 observers feed/search/image/comment, 30 ad/login; runtime vẫn kiểm ABI |
| iPhone thật | **0.5.0 chưa cài/chạy; không thay bằng kết quả fixture** |

Đã review sáu ảnh fixture: [comments](evidence/ui-comments-0.5.0.png), [Featured hẹp](evidence/ui-featured-narrow-0.5.0.png), [sidebar](evidence/ui-sidebar-0.5.0.png), [error](evidence/ui-network-error-0.5.0.png), [Search](evidence/ui-search-0.5.0.png), [Settings](evidence/ui-settings-0.5.0.png). Chữ Trung trong comment/result mẫu là nội dung được giữ nguyên. Các ảnh này **không phải Douyin thật**. [Kết quả checks](evidence/ui-results-0.5.0.json).

Vòng 36949411290 lỗi compile fixture do trùng biến, đã sửa. Vòng 36949649357 đạt 73 checks nhưng review ảnh thấy hai rating bị cắt/tách từ; đã rút ngắn nhãn và thêm ca kiểm 5 cột 64.2pt rồi chạy lại toàn bộ. Không dùng artifact từ vòng thất bại hoặc ảnh chưa đạt bố cục để giao IPA. [Thiết kế, bằng chứng thiết bị và nghiên cứu chọn lọc](ROUND_0.5.md), [metadata](evidence/methods-0.5.0.json), [nguồn pinned](evidence/research-0.5.0.json).

Tìm kiếm giữ enableGuestSearch/hasRemainingGuestSearchCount gốc; mục tùy chọn đổi thành **Search diagnostics**. 2483 đã xuất hiện trên 0.4.0; bỏ popup hoặc ép flag không tạo kết quả server. Không có chức năng giả tài khoản, sửa TLS hoặc request signing. Image observers không thêm retry/download hay đổi URL/cache; không được mô tả là đã sửa ảnh trắng.

**Bước còn thiếu:** ký/cài 0.5.0 bằng Sideloadly, kiểm giao diện và lấy diagnostics riêng sau Retry Featured, Retry Tips, Search lỗi và ảnh trắng. [Các ca cần chạy](DEVICE_TESTS.md). Mong đợi patch_version 0.5.0-test và native_hooks_expected 50; báo mismatch/overwritten nếu có. [Trạng thái 0.4.0 lưu lại](evidence/status-0.4.0.md).
