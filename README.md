# Douyin Guest — bản thử 0.5.0

Dành riêng cho Douyin **40.6.0 / build 406019 / arm64**. Source SHA-256 `3444d6045147b772e8f5e7e844c38a0f72464f34a4eb1af5c5df5f9433d706af`. Repository chứa mã patch tự viết và công cụ kiểm tra; IPA/binary Douyin chỉ nằm cục bộ.

**0.5.0 là candidate giao diện/chẩn đoán. Chưa chứng minh guest tìm kiếm không giới hạn, đọc toàn bộ bình luận, hết lỗi Featured/Tips hoặc ảnh tải chậm.** Không xóa/ẩn hai tab. [Trạng thái và hash](docs/STATUS.md).

- Giữ 11 hook nhắc đăng nhập và 19 hook quảng cáo của các đường đã đối chiếu; không fake tài khoản, success/cursor/hasMore hay quyền server.
- 873 bản dịch control. Native comment header/bottom tips, count/reply templates, toast/empty config trước đo chữ, collection prefix giữ title/link/mixed style. UILabel/UIButton/YYLabel co chữ một dòng tối đa 65%, có compact labels; không sửa frame/constraints toàn app.
- Evaluation config chỉ dịch key UI đã thấy trong disassembly; survey map câu hỏi/rating chính xác trong key trình bày cho phép, giữ ID/value/URL/bizParams. Nội dung comment, usernames và từ khóa vẫn giữ. Lynx/schema thật và mọi màn chưa được chứng nhận đầy đủ.
- 50 fixed hooks và diagnostics cục bộ: DC/generic feed, status số, image SDK failures/finish và count comment list. Không log URL/token/keyword/comment/image/error description. Search gateway chỉ quan sát; bỏ ép guest/quota gates.

Build macOS CI bằng Xcode SDK, kiểm Foundation và UIKit fixture trên iPhone 15 Simulator. [Vòng 36950206145](https://github.com/phucdinhIA/Douyin/actions/runs/36950206145) đạt 14 Python tests, Foundation/build và 74 UIKit checks; đã xem sáu ảnh fixture. Đây không phải Douyin chạy trên Simulator và không thay được kiểm tra iPhone 15/iOS 18.5.

## Build và cài thử

```powershell
python -m unittest discover -s tests -p "test_*.py" -v
python scripts/ipa_patch.py "path\original.ipa" "build\DouyinGuest.dylib" "dist\Douyin-40.6.0-Guest-0.5.0-iPhone15-TEST.ipa" --library-sha256 HASH_FROM_ARTIFACT
```

Công cụ khóa hash/version/arm64, từ chối encrypted executable, unsafe ZIP paths, header thiếu vùng trống và ghi đè output; đọc lại/hash output và giữ IPA nguồn. Thư viện đã ký ad-hoc để kiểm tra; IPA cần ký lại bằng Sideloadly. Thinning allowlists cũ được bỏ ở app/extensions để hỗ trợ iPhone 15; capabilities giữ nguyên.

Chạm **hai ngón tay ba lần** mở Douyin Guest: Hide login reminders, Filter feed / startup ads, English controls, **Search diagnostics**, Copy diagnostics, Close. Khởi động lại sau đổi tùy chọn. Mục Search diagnostics chỉ bật quan sát gateway, không mở quota tài khoản. Không đổi hẳn bundle ID; ID gốc hoặc hậu tố do ký lại được hỗ trợ.

- [Kế hoạch và nghiên cứu vòng này](docs/ROUND_0.5.md)
- [Luồng tìm kiếm và mã 2483](docs/GUEST_SEARCH.md)
- [Lỗi Featured/Tips](docs/FEED_NETWORK.md)
- [Các ca kiểm tra thiết bị](docs/DEVICE_TESTS.md)
- [Trạng thái kiểm chứng](docs/STATUS.md)

Candidate/IPA gốc/các bản cũ được giữ nguyên. Khôi phục bằng IPA cũ đã giữ; không cần migration tài khoản. Không gỡ app nếu cần giữ dữ liệu hiện có.
