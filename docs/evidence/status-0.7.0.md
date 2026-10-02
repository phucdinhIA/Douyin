# Trạng thái 0.7.0-test

**Đã tạo bản thử và kiểm tra build/fixture/IPA; chưa chứng nhận hết lỗi trên iPhone thật.**

File `dist/Douyin-40.6.0-Guest-0.7.0-iPhone15-TEST.ipa`, 704,847,682 byte. SHA-256 `a1047e7fbbc54698416ea0b5e0fe34fba4192811208bc32460e46691e6f4fb3c`. Dylib `6c70d803f783940d3805bb90f3245b67a1d59df39a3bdec29349430821246b80`. Source `69bcdd07d8bf4dd056339e5319d6c53fce642157`. Commit tài liệu sau đó không đổi mã đã build.

| Hạng mục | Kết quả / giới hạn |
|---|---|
| Phát nền | Thêm overlay `enableBGPlayComponent` trước khi app dựng module; ba preference getter được giữ. Có quan sát player thật; chưa xác nhận âm thanh khi khóa |
| Xoay | Đã sửa manifest chỉ-dọc iPhone; giữ native fullscreen/controller policy. Chưa xác nhận trên iPhone |
| Tìm kênh | Đã thêm web finder và mở official HTTPS profile link. Không tăng quota native, chưa chứng minh mọi kết quả/video guest khả dụng |
| Featured/Tips | Chưa xác định domain lỗi trên thiết bị. Static -11001 ở `com.aweme.network.error` là lỗi chuyển dữ liệu; observer mới giúp phân biệt. Chưa sửa root cause, không xóa tab |
| Comments/ảnh | Giữ native tải/retry/guest policy; chưa chứng nhận toàn bộ bình luận hoặc sửa độ trễ ảnh |
| UI | Giữ 893 bản dịch; 99/99 fixture checks đạt, không overflow ở fixture. Không chứng nhận tổng thể UI Douyin thật |
| CI | [Run 36958376223](https://github.com/phucdinhIA/Douyin/actions/runs/36958376223): 15 Python, Foundation, arm64/signature và UIKit đạt |
| IPA | 5,629 entry đọc lại/hash; 5,620 CRC/size/mode nguyên vẹn; 4,977 SHA so audit; 0 mismatch |
| Binary | AwemeCore nguyên vẹn; executable chỉ đổi 51 byte header, giữ size/code |

Review chín ảnh **fixture**: [LIVE](ui-live-0.7.0.png), [comments](ui-comments-0.7.0.png), [Featured hẹp](ui-featured-narrow-0.7.0.png), [sidebar](ui-sidebar-0.7.0.png), [error](ui-network-error-0.7.0.png), [Search](ui-search-0.7.0.png), [Settings](ui-settings-0.7.0.png), [web finder](ui-public-finder-0.7.0.png), [profile link](ui-public-profile-0.7.0.png).

Run 36957864228 thất bại do trùng tên biến trong Foundation test; đã sửa. Đồng thời kiểm tra phát hiện đổi nhầm guard phiên bản 40.6.0 khi cập nhật patch version; đã sửa và thêm regression. Run 36957970255 đạt Foundation/build nhưng fixture mở prompt tiếp theo trước khi dismissal hoàn tất; đã sửa fixture chờ completion và chụp hai prompt mới. Không dùng artifact của run thất bại.

[Kế hoạch](../PLAN-0.7.md) · [Nghiên cứu có pin/hash](../RESEARCH-0.7.md) · [12 ABI mới](0.7-native-hook-abi.json) · [Validation](validation-0.7.0.json) · [Thử thiết bị](../DEVICE_TESTS.md) · [Lịch sử 0.6](status-0.6.0.md).

**Còn thiếu:** kết quả iPhone 15/iOS 18.5 cho phát nền/xoay, và diagnostics từng phiên Featured/Tips để xác định phản hồi lỗi; không thể nghiệm thu đầy đủ từ fixture.
