# Trạng thái 0.8.0-test

**Đã sửa lựa chọn đường tải DC feed và tạo IPA thử; chưa nghiệm thu Featured/Tips trên iPhone thật.**

File `dist/Douyin-40.6.0-Guest-0.8.0-iPhone15-TEST.ipa`, 704,850,128 byte. SHA-256 `d3196a51575321adfb341f6e7d8424afdaa86f64f1f6b2aa3e94b8df6529885c`. Dylib `5ff74043a4c0ef4cead321edf23532ca12a9b5b317bcdc3f288aa9c44adbaaf8`. Source `9e9f66280f52b1b5040494035cab16085eafcf77`.

| Hạng mục | Kết quả |
|---|---|
| Featured/Tips | Feed compatibility mặc định ON: chọn bộ tải thông thường native nếu đủ class/ABI; không sửa giả response/cursor/hasMore. Chưa xác nhận tải thêm video hoặc hết chớp lỗi |
| Nguyên nhân xác nhận | 0.7 có NSData và lỗi chuyển dictionary ở serializer; chưa biết dữ liệu thực tế là nén/framed/JSON lỗi hay phản hồi khác |
| Rollback | Feed compatibility OFF rồi đóng/mở app; giữ dữ liệu và bản cũ |
| CI | [Run 36964217268](https://github.com/phucdinhIA/Douyin/actions/runs/36964217268): 16 Python, Foundation, arm64/signature và 101/101 UIKit fixture đạt |
| UI | Giữ 893 bản dịch; đã xem mười ảnh fixture, gồm menu tùy chọn mới. Không phải UI của Douyin chạy với máy chủ |
| IPA | 5,629 entry hash/readback; 5,620 CRC/size/mode và 4,977 SHA so audit; 0 mismatch |
| Binary | AwemeCore giữ nguyên; executable chỉ đổi 51 byte header, giữ code/size |
| Phần khác | Phát nền/xoay/search native/toàn bộ bình luận/ảnh chậm chưa có kết quả nghiệm thu mới; không đưa tuyên bố đã sửa |

[Menu](evidence/ui-feed-compat-0.8.0.png) · [Fixture results](evidence/ui-results-0.8.0.json) · [Kế hoạch](PLAN-0.8.md) · [Nghiên cứu](RESEARCH-0.8.md) · [Validation](VALIDATION.json) · [Thiết bị](DEVICE_TESTS.md) · [Lịch sử 0.7](evidence/status-0.7.0.md).

**Còn thiếu:** một vòng test iPhone 15/iOS 18.5 cho refresh, tải nhiều trang và chuyển Featured/Tips. Khi còn lỗi cần diagnostics mới để phân biệt HTTP/định dạng/bộ giải mã; chưa có bằng chứng đủ để chứng nhận hết lỗi.
