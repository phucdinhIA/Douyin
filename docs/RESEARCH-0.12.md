# Dịch phân tích AI theo thao tác mở tab

Kế thừa [nguồn chính thức Google và ABI native đã kiểm tra ở 0.11](RESEARCH-0.11.md). Không đổi model hỏi đáp, không thay quyền server Douyin. Tự dịch dùng `gemini-3.5-flash-lite` để giảm độ trễ/chi phí; mẫu đơn lẻ không chứng minh model có chất lượng tốt nhất cho mọi nội dung.

Một lượt probe riêng ngày 2026-10-02 dùng nguồn tiếng Trung tổng hợp, cùng system instruction và generation config của luồng dịch mới (`temperature=0.1`, `maxOutputTokens=16384`). Google trả HTTP200/STOP trong 1,28 giây; bản dịch giữ heading, số 3 và câu giới hạn “chỉ mang tính tham khảo / có thể không phù hợp cho mọi trường hợp”. 116 input + 47 output tokens. Không gửi dữ liệu Douyin thật trong probe này và không tự retry. [Kết quả tổng hợp](evidence/0.12-generation-probe.json).

`commentAIParseTabDidEnter` là điểm kích hoạt đã kiểm tra trong bản 0.11. Capture vẫn chỉ đọc renderer markdown đã biết; phân tích gốc không bị sửa. Hai override vòng đời UIKit trên chính subclass comment-AI kiểm tra ABI runtime `v20@0:8B16`; chúng chỉ dừng/khôi phục một tab đã được mở rõ ràng, không khiến việc tạo controller hay mở bình luận thường gọi dịch.

Chưa có tín hiệu native đã xác minh cho kết thúc streaming. Vì vậy dùng heuristic: ít nhất 4 giây sau vào tab, 3 giây không đổi nguồn, chờ tối đa 60 giây. Không gửi từng mảnh; nếu nguồn thay đổi trong lúc request chạy, bỏ kết quả và cho thử thủ công. Nguồn lớn hơn khả năng capture/response không được bảo đảm dịch toàn bộ.

Cache gắn với digest của chính nguồn, ngôn ngữ, model và phiên bản prompt; chỉ bản dịch STOP hoàn tất được lưu. Cache không thể bảo đảm miễn phí vĩnh viễn: nguồn đổi, cache bị xóa hoặc bị loại, hay thao tác thử lại mới có thể tạo request tính phí. Hủy phía client không bảo đảm Google chưa xử lý hoặc chưa tính phí.

Foundation state tests và UIKit fake-native/mock-provider kiểm tra hành vi ứng dụng thêm vào; chúng không chứng minh renderer/tab/controller thật trên iPhone hoạt động giống fixture. Người dùng báo hỏi đáp 0.11 có vẻ hoạt động; tự dịch 0.12 vẫn cần nghiệm thu trên máy thật.
