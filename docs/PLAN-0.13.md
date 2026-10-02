# 0.13 — sửa capture phân tích AI rỗng

Diagnostics 0.12 của người dùng: `Gemini summary unavailable=198`, `Gemini translation failed=1`, không có `Gemini translation sent`. Bộ lấy mẫu đã chạy nhưng không đọc được nguồn; không phải một request Gemini đang dịch chậm. Không có bằng chứng xác định renderer cụ thể trên máy thật, vì 0.12 chưa ghi loại renderer.

1. Rà metadata/ivar/disassembly bản gốc 40.6.0. V2 không có getter bundle; dùng object ivar `_markdownView` kiểu `LynxServalMarkdownViewWrapper` đã xác minh. Legacy bundle có node là `LynxMarkdownShadowNode`, nguồn là ivar NSString `_content`, không cần UILabel con. Đọc bằng ObjC runtime với kiểm tra class/encoding, không dùng offset cố định/C++ pointers/KVC đoán. Giữ bounds/visibility và giới hạn nguồn.
2. Khi contentVC đã được tạo nhưng chưa chứa renderer, fallback sang cây view của chính comment-AI controller. Không đọc toàn app hay bình luận thường. Thêm counters theo renderer đã biết/root fallback/poll, không ghi nguyên văn nguồn/key.
3. Legacy `content_complete` ABI B16@0:8 cho biết hoàn tất: nguồn không rỗng có thể dịch ngay. Các renderer còn lại chờ 750ms không đổi, bỏ fixed entry delay 4 giây. Cache hit hiển thị ngay; chỉ một request tự động mỗi entry, không retry tự động.
4. Timer 250ms trên main run loop/common modes để tiếp tục lấy mẫu khi cuộn. Timeout 20 giây báo không đọc được nguồn, không đánh đồng lỗi capture với tải mạng. Trong lúc capture/dịch vẫn thấy và cuộn được nguồn gốc; chỉ chuyển mặc định sang bản dịch khi có kết quả.
5. Fixture mô phỏng legacy/V2 có source không tồn tại trong UILabel/subviews, contentVC trống, source complete, cache nhanh, common-mode timer thật khi tracking, source preservation/cancel/cost gating và hồi quy Q&A. Không gọi Google thật từ fixture.
6. Build CI, xem ảnh, đóng gói private key cục bộ, kiểm tra archive độc lập. Bàn giao TEST; cần máy thật xác nhận capture đúng renderer. Không tuyên bố chỉ từ fixture rằng mọi renderer/proprietary server đã được sửa.
