# Nghiệm thu tự dịch AI 0.13 — iPhone 15/iOS18.5

Ký/cài IPA cá nhân bằng Sideloadly với cùng định danh, giữ dữ liệu. Restart app; Copy diagnostics phải ghi 0.13.0-test.

1. Mở bình luận thường ở vài video, chưa vào AI: `Gemini translation sent` không tăng.
2. Sang Phân tích AI: nguồn gốc vẫn hiện/cuộn trong lúc chờ. Theo dõi `Gemini translation poll`, `Gemini summary captured`, một trong `Gemini capture legacy renderer`/`V2 renderer`/`Serval renderer`; `Gemini capture owner fallback` có thể tăng. Cache hiện ngay; nguồn mới chờ native complete hoặc 750ms không đổi rồi gửi đúng một request. Chất lượng bản dịch phải giữ tên/số/ý nghĩa.
3. Nếu sau 20 giây vẫn chưa đọc được chữ: có lỗi capture cụ thể và nút Đọc lại; gửi Copy diagnostics với counters mới. Không giả định tất cả renderer thật đã được fixture bao phủ. Cuộn trong lúc đợi: timer vẫn lấy mẫu.
4. Bản gốc/Tiếng Việt không tăng sent. Rời/mở lại cùng nguồn: hiện “Bản dịch đã lưu”, tăng cached thay vì sent. Restart vẫn dùng cache nếu nguồn không đổi và cache chưa bị loại/xóa.
5. Đổi nguồn/video: không hiện nhầm bản cũ. Nguồn thay đổi khi dịch phải báo thử lại, không tự lặp API. Rời tab/đóng controller/chuyển nền hủy; callback cũ không cập nhật UI. Google có thể tính phí request đã nhận.
6. Mất mạng/quota: lỗi, không tự retry. Dịch lại là một lượt thủ công. Nguồn rỗng không gọi API. Gemini OFF không tự dịch.
7. Ask Gemini → Context vẫn là phân tích gốc. Thử hỏi đáp, đóng/mở sheet và draft từ ô native. Không dùng bản dịch overlay làm nguồn gốc.
8. Hồi quy feed/bình luận/LIVE; ghi riêng Featured/Tips/phát nền/xoay/search nếu còn lỗi. Bản này chưa xác nhận các lỗi đó đã hết.

Fixture dùng mock provider và lớp native giả, không chứng nhận renderer/tab thực trên iPhone. Không cần gửi lại key hoặc nội dung cá nhân. IPA chứa key riêng, không chia sẻ.
