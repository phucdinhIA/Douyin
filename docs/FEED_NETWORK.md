# Lỗi Featured / Tips và kết quả điều tra

## Bằng chứng trên iPhone, do người dùng cung cấp

App 40.6.0 / 406019, patch 0.2.0-test, iPhone 15 / iOS 18.5 đã cài và mở được sau sửa thinning. Diagnostics cho thấy 30/30 hook đã cài và còn active; 278 bản dịch. LIVE và Nearby phát video mượt theo báo cáo của người dùng. Featured và mục `经验` hiện màn hình Network error.

| Trạng thái sau khi đóng hẳn và mở lại app | Featured / 经验 |
|---|---|
| Lọc ad ON, ẩn nhắc login ON | Network error |
| Lọc ad OFF, ẩn nhắc login ON | Vẫn Network error |
| Lọc ad OFF, ẩn nhắc login OFF | Vẫn Network error |

Đây là kiểm tra do người dùng thực hiện, không phải kiểm tra từ Simulator hoặc quan sát trực tiếp bằng công cụ. Chưa có mã NSError/HTTP của các lần lỗi. Diagnostics cũ không có bộ đếm callback tải feed; không thể suy ra nguyên nhân từ việc không có bộ đếm “Feed ad items removed”.

## Ý nghĩa đối với việc xem video

`精选` được dịch thành **Featured**, mục tuyển chọn video; `经验` được dịch thành **Tips**, mục chia sẻ kinh nghiệm/hướng dẫn. Cả hai là kênh nội dung. Lỗi Featured có ảnh hưởng đến khả năng xem luồng đó; LIVE/Nearby hoạt động không thay thế mọi video của Featured. Tips là một kênh bổ sung, nhưng cũng chưa thể kết luận nó không cần thiết đối với người dùng. **Không xóa hoặc ẩn hai mục**; người dùng yêu cầu xác nhận trước khi xóa và chưa xác nhận.

## Kết luận hiện tại và các khả năng cần phân biệt

Kết quả OFF/OFF làm nguyên nhân do logic lọc ad hoặc chặn nhắc đăng nhập ít có khả năng hơn. Khi tắt, các wrapper chuyển tiếp về implementation gốc, và mã không thêm request/retry hay thay lỗi thành thành công. Tuy nhiên đây chưa phải phép so với IPA hoàn toàn chưa sửa, và các thay đổi metadata/localization vẫn còn.

Ưu tiên kiểm tra:

1. Lỗi kết nối tới đường tải dữ liệu riêng của Featured/Tips hoặc lỗi API/app được quy về màn hình lỗi chung. Cần NSError category/code hoặc kết quả callback để phân biệt hai nhánh; kết nối tới LIVE/Nearby không chứng minh mọi đường dịch vụ đều truy cập được.
2. Điều kiện của máy chủ đối với guest/session/thiết bị ký lại hoặc khả năng tương thích của app 40.6.0. Đây là giả thuyết, chưa có bằng chứng để nói bắt buộc login hoặc chặn sideload. Không giả tài khoản, không sửa TLS/request signing để thử che lỗi.
3. Nội dung rỗng, đường điều khiển chưa quan sát được, hoặc vấn đề ở app gốc/bản thinned. Chưa có response hoặc callback để kết luận; không xóa dữ liệu app để thử khi chưa cần.

Tìm thêm GitHub issues với các truy vấn `repo:huami1314/DYYY 网络`, `repo:pxx917144686/DYYY 网络`, `Douyin sideload network error`, `抖音 经验 网络错误` trong phiên này không cho thấy bản sửa có bằng chứng phù hợp ca hiện tại. Kết quả tìm kiếm không được dùng làm nguyên nhân của lỗi trên thiết bị.

## Chẩn đoán bổ sung ở 0.3.0

Thêm ba observer trên `AWEFeedTableViewController`, đã đối chiếu với metadata đúng IPA:

| Callback | Type encoding | IMP bằng chứng |
|---|---|---|
| `initialFetchCompletion:error:` | `v32@0:8@16@24` | `0x13145de4` |
| `loadMoreCompletion:error:isFooterRefreshing:` | `v36@0:8@16@24B32` | `0x15420310` |
| `refreshCompletion:error:needAnimation:` | `v36@0:8@16@24B32` | `0x14d17fe8` |

Observer gọi implementation gốc với nguyên argument, sau đó ghi số callback, success/failure, nhóm NSError cố định (`URL`, `POSIX`, `Cocoa`, `CFNetwork`, `App`) và mã số. Không ghi domain tùy ý, description, userInfo, URL, body, token hoặc thông tin tài khoản. NSError lạ giữ nguyên, không ép thành lỗi mạng. Mã App không được tự diễn giải là HTTP status.

Bộ đếm getter/setter của ba loại response ghi số lần đọc/gán list, số item mẫu đầu vào, list rỗng và list bị lọc hết. Getter có thể được gọi nhiều lần và setter có thể đã lọc trước getter; đây **không phải** số request hoặc số video duy nhất. Chỉ observer có scope callback, cũng có thể lặp khi các hàm gọi nhau. Mọi phép quan sát đều giữ nguyên cursor/hasMore/retry và lỗi thật.

Các mã URL thường gặp giúp chọn kiểm tra tiếp: `-1009` không có kết nối, `-1001` timeout, `-1003` không tìm thấy host, `-1004` không kết nối được, `-1200/-1202` lỗi TLS/chứng chỉ. Cần xem mã thực tế, không đổi cài đặt bảo mật hoặc hạ kiểm tra chứng chỉ theo phỏng đoán. Nếu callback không chạy, đường tải lỗi chưa được observer này bao phủ; không xem sự im lặng là thành công.

## Bước cần làm trên thiết bị

Cài bản 0.3.0, giữ hai tùy chọn ad/login OFF trong vòng chẩn đoán đầu. Mở Featured, nhấn Retry một lần; mở Tips, nhấn Retry một lần, rồi Copy diagnostics. Báo mục vừa thử để ghép với các mã; diagnostics không lưu nội dung đang xem hoặc tên kênh đang chọn. Thử một kênh trong một lần mở app nếu cần phân biệt callback chính xác hơn. Nếu mã nghiêng về kết nối, thử Wi-Fi so với dữ liệu di động để đối chiếu, không cần tài khoản.

Hiện **chưa sửa được root cause Network error** vì thiếu mã lỗi trên iPhone. Bản dịch và fitting được xử lý độc lập; bản mới là candidate có chẩn đoán bổ sung, không phải cam kết feed đã hoạt động.
