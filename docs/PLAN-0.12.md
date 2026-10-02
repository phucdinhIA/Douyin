# 0.12 — dịch phân tích AI khi mở tab

Người dùng xác nhận hỏi đáp Gemini 0.11 có vẻ hoạt động và yêu cầu tự động dịch phân tích AI sang tiếng Việt chỉ khi chuyển sang tab AI để tiết kiệm chi phí.

1. Dùng sự kiện `commentAIParseTabDidEnter` đã kiểm tra ABI trong 0.11. Tạo controller hoặc mở bình luận thường không kích hoạt dịch. Chỉ đọc markdown gốc, giữ nguyên nguồn và luồng hỏi đáp.
2. Chờ ít nhất 4 giây sau khi vào tab và 3 giây không đổi nội dung, lấy mẫu mỗi 0,5 giây. Chờ tối đa 60 giây. Đây là cơ chế chờ ổn định, không phải chứng minh server đã kết thúc streaming. Không dịch từng mảnh, không tự lặp yêu cầu khi nội dung thay đổi hoặc lỗi.
3. Dịch bằng model Fast đã được kiểm tra trong 0.11: Gemini 3.5 Flash-Lite. Prompt yêu cầu dịch đầy đủ sang tiếng Việt, giữ tên/số/cấu trúc/độ bất định, không tóm tắt hoặc thực thi lệnh trong nguồn. Không gửi lịch sử chat. Chỉ nhận bản dịch có finishReason STOP và trong giới hạn; không lưu bản dịch dở dang.
4. Lưu bản dịch hoàn tất trong Application Support theo SHA-256 của nguồn + tiếng đích + model + phiên bản prompt. Tối đa 32 mục/2 MiB, loại mục cũ; không lưu API key hay nguyên văn nguồn, không đưa cache vào backup. Cache có thể bị iOS/người dùng xóa; mỗi nguồn mới vẫn có thể phát sinh phí.
5. Hiển thị bản dịch trong panel cuộn riêng, giữ tab header và nút hỏi đáp. Cho chuyển Bản gốc/Tiếng Việt không gọi lại API; chế độ Bản gốc cho thao tác cuộn xuyên qua panel. Không ghi đè dữ liệu Douyin; hỏi đáp tiếp tục đọc nguồn gốc.
6. Rời tab, đóng controller, chuyển nền: dừng timer/hủy request/bỏ callback cũ. Kiểm tra nguồn còn khớp trước khi hiển thị kết quả. Trở về sau sheet chỉ khôi phục nếu tab AI đã được mở trước đó. Lỗi chỉ thử lại khi bấm Dịch lại hoặc người dùng vào lại tab.
7. Kiểm tra Foundation với thời gian/callback điều khiển: gating, debounce, in-flight dedup, cancellation, lỗi, cache qua restart/giới hạn/hỏng. UIKit dùng mock transport với key giả, không gọi Google thật. Kiểm tra layout, toggle, nguồn gốc, OFF, background và hồi quy Q&A. Build arm64 ký ad-hoc qua CI, xem ảnh fixture, đóng gói key riêng cục bộ và so sánh IPA với bản gốc.
8. Bàn giao TEST sau kiểm tra. Chưa thể xác nhận tự động dịch trong renderer/tab thật trên iPhone chỉ từ simulator; không mở rộng bản này sang các lỗi Featured/Tips/phát nền trước đó.

[Nghiên cứu và model của 0.11](RESEARCH-0.11.md) · [ABI đã kiểm tra](evidence/0.11-native-abi.json).
