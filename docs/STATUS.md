# Trạng thái 0.10.0-test

**Đã tạo IPA thử và kiểm tra contracts/UI/archive. Còn nghiệm thu Featured/Tips và âm thanh khóa màn hình trên iPhone.**

File `dist/Douyin-40.6.0-Guest-0.10.0-iPhone15-TEST.ipa`, 704,852,866 byte. SHA-256 `c6d934945066f8830642e3ff5a3b64cc832b4730651b932f7fb4221753b31f9b`. Dylib `afd1915a66fcbec2127deaf99cc82c45f5f482ba970c3abd6cb74e26b0a3b4d4`. Source `94a4e21cd75846b8abab5eb9dd7bd38012d24ccb`.

| Hạng mục | Kết quả |
|---|---|
| Feed | Sửa cờ định dạng trong body của đường JSON chuẩn; chỉ field/value đã kiểm chứng, config khác giữ nguyên. Chưa biết field này có xuất hiện trên thiết bị |
| Phát nền | Phục hồi thông báo với các điều kiện ownership/model/pause/ABI/native eligibility; chưa xác nhận nghe được khi khóa máy |
| AI | 5 mục dịch native bổ sung; UI hybrid chưa nghiệm thu. Chat AI của Douyin vẫn cần đăng nhập |
| CI | [Run 36979226991](https://github.com/phucdinhIA/Douyin/actions/runs/36979226991): 18 Python, Foundation, arm64/signature và 105/105 UIKit đạt |
| Archive | 5,629 entry readback/hash; 5,620 CRC/size/mode và 4,977 SHA so audit; 0 mismatch |
| Binary | AwemeCore giữ nguyên; executable đổi 51 byte header, giữ code/size |
| Rollback | Feed compatibility/Background audio OFF rồi restart; giữ data và candidate cũ |
| Chưa hoàn tất | Nguyên nhân deployed payload, actual loader/flag, âm thanh khóa máy, xoay, search/bình luận không giới hạn, hybrid AI UI |

[Menu](evidence/ui-feed-compat-0.10.0.png) · [Fixture](evidence/ui-results-0.10.0.json) · [Kế hoạch](PLAN-0.10.md) · [Nghiên cứu](RESEARCH-0.10.md) · [Validation](VALIDATION.json) · [Thiết bị](DEVICE_TESTS.md) · [Lịch sử](evidence/status-0.9.0.md).

Installed/active chỉ xác nhận hook gắn vào method, không chứng minh request hay tiếng phát nền thành công.
