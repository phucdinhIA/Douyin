# Douyin Guest — bản thử 0.7.0

Dành riêng cho Douyin **40.6.0 / build 406019 / arm64**. IPA gốc và mọi candidate cũ được giữ cục bộ, không đăng lên repo public. Cần ký lại bằng Sideloadly.

**Đã triển khai cấu hình thành phần phát nền, khai báo ngang iPhone và tìm hồ sơ công khai qua web. Chưa xác nhận hết lỗi trên iPhone thật. Featured/Tips, search native, toàn bộ bình luận và ảnh chậm vẫn chưa được giải quyết/chứng nhận.**

- Background audio ON: kích hoạt component native và ba preference getter; OFF trả giá trị gốc. Không ghi đè preference native, không ép nội dung được nghe nền, pause/interruption/PiP vẫn xử lý bằng app gốc.
- Manifest iPhone cho phép Portrait/LandscapeLeft/LandscapeRight. Full screen và xoay do controller native quyết định; không ép toàn bộ màn hình app xoay.
- Hai ngón tay chạm ba lần → **Find public profiles (web)** → nhập tên → Search để mở Bing trong trình duyệt. **Open public profile link** nhận liên kết HTTPS chính thức dạng `www.douyin.com/user/...`. Đây là tìm qua web; kết quả và khả năng xem guest phụ thuộc dịch vụ.
- Giữ 893 bản dịch và căn chữ LIVE/controls của 0.6, bảo vệ comment/chat/tên người dùng/nội dung video. Không khẳng định toàn bộ giao diện Douyin đã được dịch.
- 75 hook cố định; diagnostics phân loại JSON input/HTTP/MIME khi gặp lỗi phù hợp, không ghi payload, URL, keyword, cookie hoặc domain lạ. Hai tab Featured/Tips vẫn giữ.

File cục bộ: `dist/Douyin-40.6.0-Guest-0.7.0-iPhone15-TEST.ipa`. SHA-256 `a1047e7fbbc54698416ea0b5e0fe34fba4192811208bc32460e46691e6f4fb3c`.

[CI 36958376223](https://github.com/phucdinhIA/Douyin/actions/runs/36958376223): 15 Python tests, Foundation ABI/forwarding/error-pointer/privacy/URL-input tests, arm64 warnings-as-errors/signature và 99 UIKit checks đạt. Fixture iPhone 15 Simulator/iOS 18.2 **không chạy app Douyin gốc hoặc máy chủ**. Đã review chín ảnh fixture và kiểm tra độc lập 5,629 IPA entries, không mismatch.

[Kế hoạch](docs/PLAN-0.7.md) · [Nghiên cứu](docs/RESEARCH-0.7.md) · [Trạng thái/hash](docs/STATUS.md) · [Ca kiểm tra iPhone](docs/DEVICE_TESTS.md) · [Validation](docs/VALIDATION.json).

## Build

```powershell
python -m unittest discover -s tests -p "test_*.py" -v
python scripts/ipa_patch.py "path\original.ipa" "build\DouyinGuest.dylib" "dist\Douyin-40.6.0-Guest-0.7.0-iPhone15-TEST.ipa" --library-sha256 HASH_FROM_SUCCESSFUL_ARTIFACT
```

Build bằng macOS Actions/Xcode. Packager khóa hash/version/ABI/arm64, từ chối ghi đè output hoặc encrypted binary, giữ code offsets/background modes/capabilities. Giữ IPA cũ và dữ liệu app khi cài candidate. **Trạng thái: TEST, chưa nghiệm thu đầy đủ trên thiết bị.**
