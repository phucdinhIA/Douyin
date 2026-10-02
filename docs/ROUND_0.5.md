# Điều tra và bản sửa 0.5.0

## Bằng chứng thiết bị

Người dùng đã chạy 0.4.0-test trên iPhone 15/iOS 18.5: 39/39 hook active, tìm kiếm trả 2483 hai lần; adapter động 0/0. Callback feed được quan sát thành công 2 initial, 2 load-more, 1 refresh, chưa có NSError. Đây không chứng minh Featured/Tips hoạt động: hai mục vẫn lỗi trong báo cáo người dùng và có thể đi qua luồng khác. Lỗi vẫn tồn tại khi tắt cả lọc quảng cáo và nhắc đăng nhập ở vòng trước.

Ảnh bình luận trắng có thể tải sau khi đợi/chạm và đợi. Chưa phân biệt được tải mạng chậm, retry SDK, lazy loading, giải mã hay cập nhật view. Long press dẫn đến đăng nhập là một luồng thao tác khác; chưa có bằng chứng nó là nguyên nhân ảnh tải chậm. Thông báo “đăng nhập để xem thêm” chưa chứng minh toàn bộ bình luận được máy chủ cấp cho guest.

## Kế hoạch và thay đổi

1. Đối chiếu ABI với metadata đúng IPA, giữ hook sai ABI ở trạng thái bỏ qua. Thêm 11 hook, tổng 50: 7 presentation, DC feed, image failure/finish, comment list. Giữ nguyên Featured/Tips.
2. Dịch config của empty page và toast trước khi renderer đo chữ. Bổ sung compact title `Load error`/`Check connection` khi chiều rộng không đủ; khôi phục full title khi đủ rộng; không thay frame/constraints toàn app.
3. Nhận diện đúng native comment header/bottom tips và survey. Dịch count bằng mẫu neo toàn chuỗi, thay riêng prefix Collection và giữ title/link/style; giữ mixed attributes khi YYLabel co chữ. Reply chỉ dịch trong control được nhận diện, không rewrite mọi label trong comment cell.
4. Dịch evaluation qua các key UI đã xác nhận bằng disassembly. Survey chỉ map chính xác câu hỏi/rating đã thấy, trong các key trình bày cho phép; giữ ID/value/URL/schema/bizParams và nhánh không biết. Giới hạn 64 KiB JSON, 12 mức, 2.048 node; lỗi/không phù hợp giữ dữ liệu gốc. Schema survey thật/Lynx vẫn cần kiểm tra thiết bị.
5. Search gateway chỉ quan sát lời gọi, nil, tương thích ABI. Bỏ ép enableGuestSearch/hasRemainingGuestSearchCount: trạng thái/quota gốc được giữ. Disassembly có nhánh enableGuestSearch false gửi query trực tiếp, true có thêm quota gate; việc ép true không phải cách sửa được chứng minh. Mã 2483 và các tác dụng phụ của handler gốc không đổi.
6. Quan sát thêm DC feed callback, numeric status trên AWEBaseApiModel đã xác nhận getter object, thất bại/kết thúc BDWebImageRequest và count comment list. Image SDK bao phủ ảnh toàn app, không được gọi đó là chỉ ảnh bình luận. Không ghi URL, nội dung ảnh/comment, tài khoản, cookie, keyword, message hoặc NSError userInfo. Giới hạn số loại counter.
7. Kiểm tra Foundation forwarding/ON-OFF/content protection/bounds, UIKit thực trên app fixture, build arm64 bằng CI. Chỉ đóng gói sau khi checks đạt và đã review ảnh. So sánh IPA với nguồn/audit độc lập. Sau đó ký/cài thử trên iPhone; chưa thể chứng nhận server/feed/image thật qua fixture.

## Nghiên cứu chọn lọc

- [huami1314/DYYY DYYY.xm](https://github.com/huami1314/DYYY/blob/6c3dfbd911822b4d0f758f184c196566e8142291/DYYY.xm#L2672), SHA-256 `6f005f7903bf315947662ea478136db0db6a21e7dd2d53a426491d10fc94408a`.
- [pxx917144686/DYYY DYYY.xm](https://github.com/pxx917144686/DYYY/blob/39561aef7fff5ac039eb2f6a202dd05beba42d89/DYYY.xm#L4509), SHA-256 `c31e8dab66d315e4cc395b7d377ac6a4a3c4e41c169f5fee5fa18b21abd811e3`.

Đã đọc lại hai file nguồn pinned qua GitHub. Cả hai dùng AWECommentImageModel downloadUrl → originUrl khi bật lưu ảnh không watermark; không phải sửa thumbUrl/render ảnh. Không áp dụng cách đó cho thumbnail vì thiếu bằng chứng nó sửa lỗi của mẫu này, và có thể tải ảnh lớn hơn. Hai file được kiểm tra không chứa 2483/enableGuestSearch/hasRemainingGuestSearchCount; không suy rộng điều này thành mọi repo/mod đều không có giải pháp.

Issue search cho hai repo về ảnh/comment không có kết quả phù hợp. Query rộng có số 2483 bị GitHub diễn giải thành issue number và trả kết quả không liên quan, đã loại khỏi bằng chứng. Tham khảo vòng trước: [VideoGet PR4](https://github.com/Loccao102/VideoGet/pull/4) xử lý 2483 bằng cookie đăng nhập, và [bb-sites PR41](https://github.com/epiral/bb-sites/pull/41) là web search công khai; chúng không chứng minh native search không giới hạn trên bản iOS này. Không chạy mã tải về hoặc đưa cookie bên thứ ba vào app.

## Trạng thái còn thiếu

Chưa xác định nguyên nhân Network error của Featured/Tips hoặc độ trễ ảnh. Chưa chứng minh toàn bộ control/Lynx đã dịch, toàn bộ bình luận có thể đọc hoặc tìm kiếm không giới hạn. Không fake thành công/quyền tài khoản hoặc vượt hạn chế xác thực máy chủ. Bản 0.5.0 là candidate giao diện/chẩn đoán để có bằng chứng đúng luồng, không phải cam kết guest full chức năng.
