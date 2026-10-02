# Nghiệm thu tự dịch AI 0.12 — iPhone 15/iOS18.5

Ký/cài IPA cá nhân bằng Sideloadly với cùng định danh, giữ dữ liệu. Restart app; Copy diagnostics phải ghi 0.12.0-test.

1. Mở bình luận thường ở vài video; chưa vào AI. Bộ đếm `Gemini translation sent` không tăng. Không dịch bình luận do người dùng viết.
2. Chuyển sang tab phân tích AI và chờ nội dung tải. Sau khi ổn định, panel Tiếng Việt phải xuất hiện với bản dịch đúng tên/số/ý nghĩa. Lượt mới đầu tiên tăng `Gemini translation sent` một lần và `Gemini translation ready` nếu hoàn tất. Tab mới có nội dung mới vẫn có thể phát sinh phí Google.
3. Chọn Bản gốc, cuộn nguồn gốc; chuyển Tiếng Việt trở lại không tăng sent. Rời/mở lại cùng AI: phải hiện “Bản dịch đã lưu · Không gọi API lại”, tăng cached chứ không tăng sent. Restart app và mở lại đúng nguồn vẫn dùng cache nếu chưa bị loại/xóa.
4. Đổi video/nguồn khác: không được hiển thị nhầm bản dịch cũ. Nếu nguồn đổi trong lúc gửi, hiển thị yêu cầu Dịch lại; không tự lặp API. So sánh ý nghĩa bản dịch với nguồn; không giả định debounce 3 giây là tín hiệu streaming đã kết thúc.
5. Vào AI rồi rời ngay, đóng bình luận, hoặc chuyển nền: không gửi nếu còn đang chờ; hủy request nếu đã gửi, không cập nhật UI từ callback muộn. Google có thể tính phí request đã nhận trước khi hủy. Chỉ trở về một tab đã mở trước đó mới được khôi phục.
6. Mất mạng/quota: thấy lỗi, không tự retry. Bấm Dịch lại khi có mạng: một lần thử thủ công. Không có phân tích: chờ tối đa 60 giây rồi cho thử lại, không gọi API với nguồn trống. Nếu không capture được renderer thật, báo diagnostics, không bịa ngữ cảnh.
7. Ask Gemini → Context vẫn là phân tích gốc, không phải bản dịch overlay. Gửi câu hỏi, đóng/mở sheet, thử draft từ ô native: hỏi đáp giữ hành vi 0.11. Gemini OFF rồi vào tab: không tự dịch.
8. Hồi quy feed/bình luận/LIVE; ghi riêng các lỗi Featured/Tips/phát nền/xoay nếu còn. Bản này chỉ bổ sung tự dịch AI, không xác nhận các lỗi đó đã hết.

Copy diagnostics sau lỗi; không cần gửi API key hoặc nội dung cá nhân. Cache tối đa 32 bản/2 MiB; xóa dữ liệu app/nguồn đổi/cache bị loại có thể khiến dịch lại phát sinh phí. IPA chứa key riêng, không chia sẻ.

**Fixture dùng mock provider và lớp native giả, chưa chứng nhận renderer/tab thực trên iPhone.**
