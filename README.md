# Douyin — bản thử cá nhân 0.14.0

Douyin **40.6.0/build406019/arm64**, tên hiển thị **Douyin**. Ký/cài IPA riêng bằng Sideloadly.

- Trên video, bấm **Phụ đề Việt** để lấy lời nói tiếng Trung qua Apify → Deepgram Nova-3 → Gemini và hiện phụ đề tiếng Việt theo thời gian player. Chỉ chạy sau khi bấm; đổi video/chuyển nền hủy. Nhóm đầu 8 cue, sau đó 16 cue, ưu tiên đoạn đang xem và dùng cache. Tối ưu cho video dưới 10 phút, giới hạn tối đa 60 phút.
- Trong bình luận, bấm **Dịch bình luận**, rồi chạm một dòng để dịch miễn phí bằng Google Translate GTX. Bình luận gốc giữ nguyên; cache GTX tách riêng để không đẩy transcript trả phí ra khỏi cache.
- Tự dịch tab phân tích AI và hỏi đáp Gemini của 0.13 được giữ; người dùng đã xác nhận dịch AI hoạt động.

Mẫu 67,8 giây: trích link 8,82 giây, Nova-3 31,53 giây, nhóm dịch đầu 2,34 giây; các chặng cộng khoảng 43 giây tới phụ đề đầu trong thử nghiệm dịch vụ, chưa phải tốc độ đo trên iPhone. Cache giúp các lần xem lại không cần API. Đây là nhận dạng prerecorded cả clip, không phải phụ đề trực tiếp tức thời.

Đã đạt 21 Python, 29 Gemini, 36 dịch AI, 49 media và 161 UIKit checks, cùng build arm64 với warnings-as-errors. API thật đã trả phụ đề hợp lệ trên mẫu ngắn và link 45 phút người dùng cung cấp. Kiểm tra 5,631 mục IPA, 0 mismatch, core gốc giữ nguyên. Cần nghiệm thu phụ đề/bình luận trên iPhone thật; simulator dùng lớp giả và mock.

IPA: `dist/Douyin-40.6.0-0.14.0-iPhone15-SUBTITLES-PRIVATE-TEST.ipa`. SHA-256: `b09c82dbfe1a244d3680141145f80558944973e6a41787e03333f04f4b538a35`.

IPA nhúng key cá nhân theo yêu cầu, giữ riêng; Git/CI chỉ key giả. Apify/Deepgram/Gemini có chi phí; không tự retry yêu cầu trả phí, nhà cung cấp có thể tính phí yêu cầu đã nhận trước khi hủy. GTX là endpoint công khai, có thể giới hạn lượt hoặc thay đổi.

[Kế hoạch](docs/PLAN-0.14.md) · [Tài liệu/đo API](docs/MEDIA-0.14.md) · [Test iPhone](docs/DEVICE_TESTS.md) · [Trạng thái](docs/STATUS.md) · [Validation](docs/VALIDATION.json) · [CI](https://github.com/phucdinhIA/Douyin/actions/runs/37005881752) · [UI phụ đề](docs/evidence/ui-captions-0.14.0.png) · [UI bình luận](docs/evidence/ui-gtx-comments-0.14.0.png).
