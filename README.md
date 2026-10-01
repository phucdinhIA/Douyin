# Douyin Guest — bản thử 0.3.0

Mã chỉnh sửa dành riêng cho mẫu Douyin **40.6.0 / 406019 / arm64**, SHA-256 nguồn:

`3444d6045147b772e8f5e7e844c38a0f72464f34a4eb1af5c5df5f9433d706af`

**Đây là bản thử cần kiểm tra trên iPhone, chưa phải bản hoàn chỉnh đã kiểm chứng.** Repository chứa mã do dự án viết, cấu hình, công cụ đóng gói và kiểm tra; không chứa IPA, binary hoặc mã nguồn của Douyin.

**Bản hiện tại: 0.3.0-test**, bổ sung 24 bản dịch theo ảnh sidebar/error page, fitting cho control hẹp và ba observer tải feed. Bản 0.2.0 đã cài/mở được trên iPhone 15/iOS 18.5 sau sửa thinning; LIVE/Nearby phát theo báo cáo của người dùng, nhưng Featured/经验 vẫn Network error kể cả khi tắt ad/login. **Lỗi này chưa được sửa**; hai mục vẫn giữ nguyên. Xem [điều tra feed](docs/FEED_NETWORK.md) và [hash/kết quả](docs/STATUS.md).

Các thay đổi được triển khai:

- 11 hook cho bộ điều khiển nhắc đăng nhập trước khi xem, trong luồng cuộn và nút gợi ý đăng nhập. Không giả mạo trạng thái đã đăng nhập và không sửa quyền truy cập do máy chủ áp dụng.
- 19 hook cho lọc video quảng cáo trong ba loại response và chặn các cổng hiển thị quảng cáo khởi động/splash đã xác định. Đọc `isAds` và bổ sung `checkIsAd`, `isHardAdModel`, `isHardAd` đã đối chiếu trên `AWEAwemeModel`; không làm initializer trả `nil`. Cursor, `hasMore`, retry và quyền truy cập video được giữ nguyên.
- 302 bản dịch chính xác cho chữ điều khiển thường gặp. Xử lý UILabel, UIButton, nhãn điều hướng theo ngữ cảnh, tab, placeholder và lookup localization. Chữ một dòng được phép co trong giới hạn 65%; chuỗi attributed có nhiều kiểu giữ nguyên. Sửa fitting sau setter, giữ fallback state của button và bảo vệ tiêu đề profile. Nội dung video/caption không được gửi ra dịch vụ dịch.
- Bảng tùy chọn và chẩn đoán cục bộ, hỗ trợ scene/delegate window; 33 hook gồm 30 hook tính năng và 3 observer feed. Ghi category/mã NSError và thống kê list, không ghi URL, token hoặc description; callback gốc vẫn nhận nguyên argument. Không có endpoint/analytics mới.

Giới hạn hiện tại: chưa bao phủ mọi màn hình, WebView/Lynx, chữ tải từ máy chủ, quảng cáo lồng trong video hay tất cả đường dữ liệu. Không bảo đảm xem mọi video hoặc không giới hạn khi máy chủ yêu cầu xác thực. Hành vi thực tế và bố cục cần kiểm tra trên thiết bị.

## Build và đóng gói

GitHub Actions dùng macOS với SDK từ Xcode để biên dịch thư viện. WSL không có SDK iOS chính thức được cài trong môi trường này; không cần tải toolchain hay IPA không rõ nguồn gốc để build. Runner tiêu chuẩn của repository công khai không dùng runner trả phí hay dịch vụ build ngoài.

1. Workflow **Build and verify guest library** chạy kiểm tra Python, kiểm tra policy/hook với Foundation, build arm64 iOS 15.0, ký ad-hoc, xác minh thư viện và chạy UIKit fixture trên iPhone 15 Simulator. Chỉ upload thư viện khi tất cả kiểm tra đạt.
2. Artifact `DouyinGuest-arm64` chứa thư viện, SHA-256, commit nguồn và phiên bản Xcode/SDK. Kiểm tra `SOURCE_COMMIT` khớp commit cần build.
3. Đóng gói trên Windows/macOS/Linux với Python 3.11 trở lên:

```powershell
python scripts/ipa_patch.py "path\original.ipa" "build\DouyinGuest.dylib" "dist\Douyin-40.6.0-Guest-0.3.0-iPhone15-TEST.ipa" --library-sha256 HASH_FROM_ARTIFACT
```

Công cụ từ chối hash nguồn sai, binary mã hóa, kiến trúc sai, vùng header không trống, tên ZIP không an toàn, đường dẫn trùng, hoặc ghi đè file đã tồn tại. Nó đọc lại tất cả file output và kiểm chứng hash, đồng thời kiểm tra IPA nguồn vẫn nguyên vẹn. Báo cáo `.validation.json` đi kèm ghi chi tiết thay đổi.

Ký/cài bản thử bằng Sideloadly. IPA cần ký lại toàn bộ thành phần theo công cụ của bạn; chữ ký App Store cũ không chứng thực bản đã sửa.

## Bảng tùy chọn

Chạm đồng thời **hai ngón tay, ba lần** trên màn hình app để mở **Douyin Guest**:

- bật/tắt nhắc đăng nhập, lọc quảng cáo hoặc tiếng Anh;
- **Copy diagnostics** sao chép phiên bản, số hook đã cài/còn active và các bộ đếm; không chứa token, tài khoản hoặc URL video;
- khởi động lại ứng dụng sau khi thay đổi. Việc tắt lọc không khôi phục mục quảng cáo đã bị lọc khỏi response cũ; cần tải lại feed.

Hook chỉ bật cho build đã chọn; bundle ID gốc hoặc ID có hậu tố do ký lại được hỗ trợ. Nếu dùng Sideloadly đổi hẳn bundle ID, hook không bật. Các kiểu hàm khác cấu hình sẽ bị bỏ qua và xuất hiện trong chẩn đoán.

## Tài liệu và kiểm tra

Vòng [36844285286](https://github.com/phucdinhIA/Douyin/actions/runs/36844285286) đã đạt 14 Python tests, Foundation, build và **37/37 UIKit checks** trên iPhone 15 Simulator/iOS 18.2. Đã xem ảnh menu/error fixture; đây không phải Douyin thật. IPA mới đã được đọc lại/hash toàn bộ 5.629 entry và đối chiếu 4.977 file không sửa với audit, không sai lệch. Bản 0.3.0 vẫn cần kiểm tra trên iPhone và lấy mã lỗi feed. [Trạng thái kiểm chứng](docs/STATUS.md).

- [Kế hoạch triển khai và luồng xử lý](docs/PLAN.md)
- [Nguồn nghiên cứu, lựa chọn kỹ thuật](docs/RESEARCH.md)
- [Quy trình kiểm tra iPhone 15 / iOS 18.5](docs/DEVICE_TESTS.md)
- [Trạng thái kiểm chứng](docs/STATUS.md)

```powershell
python -m unittest discover -s tests -p "test_*.py" -v
```

Khôi phục bằng cách cài lại IPA gốc đã giữ nguyên. Không gỡ ứng dụng nếu cần giữ dữ liệu hiện có; bản thử không cần migration dữ liệu tài khoản.
