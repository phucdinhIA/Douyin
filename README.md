# Douyin Guest — bản thử 0.6.0

Dành riêng cho Douyin **40.6.0 / build 406019 / arm64**. Mã patch/công cụ kiểm tra được tự viết; IPA/binary gốc chỉ nằm cục bộ, không tải lên repo public. Cần ký lại bằng Sideloadly.

**0.6.0 bổ sung control LIVE và preference âm thanh nền. Chưa xác nhận phát khóa màn hình trên iPhone, guest Search không giới hạn, toàn bộ bình luận hoặc hết lỗi Featured/Tips/ảnh.** [Trạng thái và hash](docs/STATUS.md).

- 893 bản dịch; năm nút LIVE dùng Stars / Chat / Singing / Groups / Beauty. Có Sing / Team / Looks khi ô rất hẹp, tự khôi phục full label khi đủ chỗ. Giữ room titles, chat, comment/usernames, frames và constraints.
- `Background audio` ON mặc định: bật preference âm thanh nền trong bộ phát native; OFF trả cấu hình gốc. Không ghi đè dữ liệu preference gốc, không ép quyền nội dung hoặc các lệnh pause/resume; không phát âm thanh im lặng. Nội dung/native policy có thể vẫn từ chối phát nền.
- 63 fixed hooks: 30 ad/login, 13 presentation, 5 search gateways quan sát, 12 diagnostic observers, 3 local audio preferences. SDK ảnh vẫn dùng retry/alternative URL gốc. Diagnostics phân loại lỗi theo domain whitelist và tối đa 3 underlying errors, không ghi URL/token/keyword/nội dung/error description/raw domain lạ.

[CI 36954417420](https://github.com/phucdinhIA/Douyin/actions/runs/36954417420) đạt 14 Python tests, Foundation/build/signature và 94 UIKit fixture checks; đã review bảy ảnh. Fixture iPhone 15 Simulator/iOS 18.2 **không chạy Douyin gốc hoặc máy chủ**, không thay cho thử iPhone 15/iOS 18.5.

## Cài và bật tùy chọn

Ký/cài file cục bộ `dist/Douyin-40.6.0-Guest-0.6.0-iPhone15-TEST.ipa` bằng Sideloadly. Giữ IPA cũ, không gỡ app nếu cần giữ dữ liệu. Chạm **hai ngón tay ba lần** → Douyin Guest → Background audio ON/OFF; đóng hẳn rồi mở lại sau thay đổi. Menu còn có ad/login/English switches, Search diagnostics và Copy diagnostics. Search diagnostics chỉ quan sát, không cấp quyền tài khoản. ID gốc hoặc hậu tố của nó do ký lại được hỗ trợ.

## Build

```powershell
python -m unittest discover -s tests -p "test_*.py" -v
python scripts/ipa_patch.py "path\original.ipa" "build\DouyinGuest.dylib" "dist\Douyin-40.6.0-Guest-0.6.0-iPhone15-TEST.ipa" --library-sha256 HASH_FROM_SUCCESSFUL_ARTIFACT
```

Build iOS bằng macOS Actions/Xcode. Packager khóa hash/version/ABI/arm64, từ chối ghi đè output hoặc encrypted binary, giữ background modes/capabilities và không dịch chuyển code. WSL không thay được Apple iOS SDK.

[Kế hoạch/nghiên cứu](docs/ROUND_0.6.md) · [Các ca test iPhone](docs/DEVICE_TESTS.md) · [Search 2483](docs/GUEST_SEARCH.md) · [Featured/Tips](docs/FEED_NETWORK.md).

Candidate/nguồn/các IPA cũ được giữ nguyên. Bản này vẫn là TEST; nghiệm thu tính năng máy chủ và phát nền thật còn thiếu.
