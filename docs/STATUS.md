# Trạng thái 0.9.0-test

**Đã triển khai và đóng gói bản sửa luồng tải Featured/Tips. Còn cần nghiệm thu trên iPhone 15/iOS 18.5.**

File `dist/Douyin-40.6.0-Guest-0.9.0-iPhone15-TEST.ipa` — 704,851,094 byte. SHA-256 `20200a54134741c6f8e80f16bd6655ab9115941cb8d4b50cf893cec2edf519aa`. Dylib `8f1f564654b7cc8234fee64129ea53136d502b77f7d1c11b6e7dd15375ea276d`. Source biên dịch `8c594db4f6654382747e2d0ca6911652c9c94809`.

| Hạng mục | Kết quả |
|---|---|
| Featured/Tips | Hai bộ tải native mới được nhận diện; chọn định dạng thông thường ở cả bộ dựng yêu cầu và bộ tải. Không che lỗi, đổi video hoặc giả phân trang. Chưa xác nhận hiệu quả trên máy thật |
| CSP -4 | Đã truy tới nhánh kết thúc luồng chưa hoàn chỉnh và thêm phân loại domain; không đồng nghĩa với lỗi đăng nhập |
| 0.8 | Log không có lần chọn luồng tương thích; có HTTP200 nhưng NSData rỗng/numeric không đọc thành JSON. Chưa chứng minh nguyên nhân phía server |
| Rollback | Feed compatibility OFF và restart; giữ dữ liệu và các bản cũ |
| CI | [Run 36969913287](https://github.com/phucdinhIA/Douyin/actions/runs/36969913287): 17 Python, Foundation contracts, arm64/signature, 101/101 UIKit fixture đạt |
| UI | 893 bản dịch, mười ảnh fixture được xem. Đây là fixture, không phải UI Douyin/server trên máy thật |
| IPA | 5,629 entry hash/readback; 5,620 CRC/size/mode và 4,977 SHA so audit; 0 mismatch |
| Binary | AwemeCore giữ nguyên; executable chỉ đổi 51 byte header; giữ code/size |
| Phần khác | Chưa có nghiệm thu mới cho phát nền/xoay/search không giới hạn/bình luận/ảnh chậm; không tuyên bố đã sửa |

[Menu](evidence/ui-feed-compat-0.9.0.png) · [Fixture](evidence/ui-results-0.9.0.json) · [Kế hoạch](PLAN-0.9.md) · [Nghiên cứu](RESEARCH-0.9.md) · [Validation](VALIDATION.json) · [Thiết bị](DEVICE_TESTS.md) · [Lịch sử 0.8](evidence/status-0.8.0.md).

**Còn thiếu:** thử riêng Featured và Tips, refresh và cuộn nhiều trang trên iPhone. Installed không chứng minh hook được gọi hoặc feed đã hết lỗi.
