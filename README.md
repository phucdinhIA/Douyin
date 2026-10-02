# Douyin Guest — bản thử 0.8.0

Dành riêng cho Douyin **40.6.0 / build 406019 / arm64**. IPA gốc và các candidate cũ được giữ cục bộ; không đăng IPA lên repo public. Cần ký lại bằng Sideloadly.

**Đã triển khai chế độ tải tương thích cho Featured/Tips. Chưa xác nhận hết lỗi hoặc tải thêm video thành công trên iPhone thật.**

- **Feed compatibility ON** mặc định: chọn đường tải thông thường có sẵn của DC feed khi bộ tải native tương thích; không giải mã khối bằng phỏng đoán hoặc thay video. OFF và restart trả quyết định gốc.
- Lỗi chuyển NSData → dictionary đã được xác nhận từ 0.7. Bản mới phân loại HTTP/MIME qua TTHttpResponse, kích thước/định dạng dữ liệu; không ghi payload, URL, cookie hoặc token. Không đổi mã lỗi, phân trang hoặc trạng thái đăng nhập.
- Giữ 893 bản dịch, phát nền, khai báo xoay iPhone và web finder từ 0.7. Không có xác nhận mới trên iPhone cho phát nền/xoay/tìm kiếm/bình luận/ảnh; không tuyên bố những chức năng đó đã hết lỗi.
- Giữ Featured/Tips. Bộ đếm Installed không chứng minh hook đã chạy hoặc dữ liệu mới đã tải.

File cục bộ: `dist/Douyin-40.6.0-Guest-0.8.0-iPhone15-TEST.ipa`. SHA-256 `d3196a51575321adfb341f6e7d8424afdaa86f64f1f6b2aa3e94b8df6529885c`.

[Trạng thái](docs/STATUS.md) · [Kế hoạch](docs/PLAN-0.8.md) · [Nghiên cứu](docs/RESEARCH-0.8.md) · [Validation](docs/VALIDATION.json) · [Kiểm tra iPhone](docs/DEVICE_TESTS.md).

## Build và đóng gói

Workflow macOS build source, chạy Foundation/UIKit fixtures, kiểm tra arm64/signature và lưu artifact. [Run thành công](https://github.com/phucdinhIA/Douyin/actions/runs/36964217268).

```text
python scripts/ipa_patch.py "path\original.ipa" "build\DouyinGuest.dylib" "dist\Douyin-40.6.0-Guest-0.8.0-iPhone15-TEST.ipa" --library-sha256 HASH_FROM_SUCCESSFUL_ARTIFACT
```

Không cần xóa dữ liệu app; giữ bản đã ký trước đó để rollback. Không thay đổi schema dữ liệu.
