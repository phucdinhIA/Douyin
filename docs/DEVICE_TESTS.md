# Kiểm tra thiết bị — iPhone 15 / iOS 18.5 / Sideloadly

Bản 0.2.0 đã được người dùng cài/mở trên iPhone 15/iOS 18.5, gửi diagnostics 30/30 hook active và báo LIVE/Nearby phát. Các ca đầy đủ chưa được xác nhận; Featured/经验 lỗi kể cả khi tắt hai nhóm ad/login. Bản 0.3.0 chưa được người dùng cài/thử. Toàn bộ ca dưới đây cho **candidate 0.4.0** vẫn cần chạy lại trên iPhone; Simulator không thay thế app thật.

## Chuẩn bị

Giữ IPA gốc và dữ liệu cần thiết. Dùng candidate `Douyin-40.6.0-Guest-0.4.0-iPhone15-TEST.ipa`, ký bằng Sideloadly và cài. Không bật thêm tweak khác trong vòng kiểm tra này để xác định nguyên nhân lỗi. Bundle ID có hậu tố được hỗ trợ; không đổi hẳn sang tên khác. Diagnostics phải báo `patch_version: 0.4.0-test` để tránh thử nhầm bản 0.1.0. Bản mới giữ sửa thinning và có iPhone15 trong tên file. Trong Sideloadly chọn lại đúng IPA mới, không Retry tác vụ đang giữ file cũ.

Nếu Sideloadly báo lỗi, lưu nguyên văn mã lỗi. Nếu app đóng ngay, lấy crash report có tên Aweme tại **Settings → Privacy & Security → Analytics & Improvements → Analytics Data**. Trước khi gửi, bỏ thông tin cá nhân không cần thiết. Nếu lỗi liên quan ký hoặc extension/provisioning, phải xử lý riêng trước khi kết luận hook sai.

## Các ca bắt buộc

| ID | Thao tác | Kết quả cần đạt |
|---|---|---|
| D01 | Mở app sau khi đóng hoàn toàn, chưa đăng nhập | App vào được luồng nội dung công khai, không crash/đứng ở splash. Không tự bỏ qua màn consent/tuổi. |
| D02 | Chạm hai ngón ba lần; Copy diagnostics ngay sau mở và sau cuộn lâu | Bảng Douyin Guest mở; cả `native_hooks_installed` và `native_hooks_active` đối chiếu với 39, không có signature mismatch hoặc hook overwritten. |
| D03 | Xem/cuộn ít nhất 200 video hoặc 30 phút | Không popup nhắc login tự động gây gián đoạn. Ghi số video/thời điểm nếu máy chủ dừng cấp nội dung. |
| D04 | Mở video từ tìm kiếm/profile công khai; xem collection | Video máy chủ cho phép xem vẫn phát; không hỏng điều hướng quay lại. |
| D05 | Cold start ít nhất 5 lần, quay lại app từ background 5 lần | Không quảng cáo splash thuộc các đường đã sửa; không màn đen/lớp phủ không đóng. |
| D06 | Cuộn feed đủ lâu để có cơ hội nhận video ad | Bộ đếm lọc tăng khi gặp model quảng cáo; video thường vẫn giữ thứ tự/khả năng phát. Bộ đếm bằng 0 không chứng minh không còn ad. |
| D07 | Xem video ảnh, video ngang và video dài | Không crash, seek/pause/resume và next/previous hoạt động. |
| D08 | Tắt mạng rồi bật lại; đổi Wi-Fi/di động | Lỗi mạng và retry hoạt động; không spinning vô hạn hoặc gọi request liên tục do lọc. |
| D09 | Kiểm tra Home/Search/Profile/Settings/player menus | Label có trong từ điển hiện tiếng Anh; không cắt chữ/đè nút, vùng bấm còn đúng. Ghi màn hình còn chữ Trung Quốc và chuỗi cụ thể. |
| D10 | Font mặc định và font lớn; portrait/landscape; light/dark | Labels vẫn đọc được, không chồng bố cục. Các control custom chưa dịch được ghi lại. |
| D11 | Video có caption, username, subtitle/comment tiếng Trung | Nội dung do người dùng tạo không bị dịch nhầm; comment/search text không bị rewrite. |
| D12 | Tắt từng tùy chọn, khởi động lại và tải lại feed | Implementation gốc hoạt động; đối chiếu giúp phân biệt lỗi app/server với lỗi patch. |
| D13 | Chạm like/comment/share trong chế độ khách | Không báo đã thực hiện thành công khi thiếu tài khoản; có thể yêu cầu login chủ động theo chức năng gốc. |
| D14 | Chạy lại D01–D11 sau một lần reboot máy | Thư viện vẫn nạp sau ký; không chỉ hoạt động ở session đầu. |

## Dữ liệu cần ghi khi có lỗi

Phiên bản candidate/commit, ID ca, các bước ngắn tái hiện, kết quả mong đợi/thực tế, diagnostics, và screenshot cho lỗi layout. Không cần gửi token, mật khẩu hoặc dữ liệu tài khoản. Nếu không mở được bảng thì gửi lỗi Sideloadly/crash report trước.

## Điều kiện chốt

Chỉ chốt phạm vi đã thực hiện khi các ca bắt buộc đạt và lỗi còn chữ/layout/ad đã được xử lý hoặc ghi rõ phạm vi không bao phủ. Không thể chứng minh “mọi video không giới hạn” từ một phiên cuộn; hạn chế máy chủ phải được báo đúng. Không thể chứng minh “không có bất kỳ quảng cáo nào ở mọi tính năng” khi chỉ sửa feed/splash.

## Vòng chẩn đoán Featured / Tips

Trong bảng Douyin Guest (hai ngón tay chạm ba lần), giữ Filter feed / startup ads OFF và Hide login reminders OFF để so sánh. Sau khi cài candidate 0.4.0, đóng hẳn/mở lại app, chọn Featured, Retry một lần; chọn Tips (经验), Retry một lần, rồi Copy diagnostics. Gửi cả mã lỗi và bước tái hiện. Observer vẫn bật khi hai tùy chọn này OFF. Nếu cần tách từng kênh, thử mỗi kênh trong một lần mở app và sao chép diagnostics ngay sau đó. [Cách diễn giải và giới hạn](FEED_NETWORK.md).

Kiểm tra các tiêu đề/menu mới, nút Settings/Setup không bị cắt, các mục Tools & services/Quick tools/Creator tools/Lifestyle cân đối; coupon/booking/QR/teen controls dịch đúng. Xác nhận caption/username bên phải feed giữ nguyên. Các chức năng cần tài khoản vẫn có thể yêu cầu đăng nhập chủ động.

## Vòng thử tìm kiếm và giao diện 0.4.0

Không cần cài 0.3.0 trước. Sau cài 0.4.0, mở bảng Douyin Guest, bật Guest search và English controls, đóng hẳn/mở lại app. Giữ hai tùy chọn ad/login theo trải nghiệm muốn thử; Guest search có công tắc riêng.

| ID | Thao tác | Kết quả cần đạt |
|---|---|---|
| D15 | Tìm hai từ khóa công khai khác nhau; thử All/Videos/Users/LIVE, cuộn/tải thêm, đổi từ khóa, Back | Client không chặn trước request bằng popup login thuộc đường guest đã sửa; kết quả thực sự tải/phát. Nếu máy chủ từ chối, ghi nguyên lỗi và diagnostics, không coi là đã vượt được hạn chế. |
| D16 | Copy diagnostics sau Search; tắt Guest search, đóng/mở và thử lại để đối chiếu nếu cần | 0.4.0-test, fixed hooks kỳ vọng 39. search_adapter_hooks installed/active kỳ vọng 2 cho một adapter đã resolve; không có ABI mismatch. OFF gọi method gốc. |
| D17 | Rà Search/filter/sidebar/Settings/privacy/notifications/player/subtitles/cache/offline/LIVE/profile tabs; font mặc định/lớn | Labels được dịch không tràn/chồng, nút bấm/Back hoạt động; tên tác giả, nội dung video/comment/result và từ khóa giữ nguyên. |

Gửi JSON Copy diagnostics sau tìm kiếm và sau Retry Featured/Tips. Nếu một màn còn lỗi chữ/layout, ghi màn/chuỗi cụ thể và ảnh của chỗ đó. [Chi tiết tìm kiếm và giới hạn kiểm chứng](GUEST_SEARCH.md).
