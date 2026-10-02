> Hiện tại: **0.6.0-test**. Diagnostics 0.5.0 xác nhận 6/6 kiểm tra Search có mã 2483 và handler báo limit; không thấy adapter/gateway được dùng trong phiên. Đây là bằng chứng hạn chế được handler nhận, chưa chứng minh lỗi mạng hay guest có quyền vô hạn. 0.6 giữ nguyên policy server, không giả tài khoản. [Kế hoạch mới](../ROUND_0.6.md) và [ca thiết bị](../DEVICE_TESTS.md). Phần 0.4–0.5 bên dưới lưu lịch sử.

# Tìm kiếm guest và mã 2483

0.4.0 trên iPhone có 39 fixed hooks active nhưng adapter động 0; Search status code 2483 hai lần và handler báo limit hai lần. Điều này là bằng chứng đường handler search có nhận mã hạn chế, không phải bằng chứng adapter đã được cài hoặc lỗi kết nối thông thường. Đọc phần [bằng chứng và nghiên cứu](../ROUND_0.5.md).

0.5.0 giữ class getter/service gốc và quan sát 5 gateway: số invocation, trả nil, tương thích hai method BOOL. Không ép enableGuestSearch hoặc hasRemainingGuestSearchCount. Disassembly cho thấy enableGuestSearch false có thể gửi query trực tiếp, true vào kiểm tra quota; ép true không phải tối ưu đã được chứng minh. Handler statusCode/message gốc giữ nguyên result/state; diagnostics chỉ ghi mã số, không từ khóa/message/token.

Search diagnostics ON/OFF điều khiển quan sát gateway, không làm guest thành tài khoản. Status observer vẫn hoạt động để phân biệt hạn chế khi diagnostic switch OFF. search_adapter_hooks installed/active kỳ vọng **0 theo thiết kế**; adapter_classes là số lớp tương thích đã quan sát. Nếu gateway invocation 0, chưa thấy gateway chạy; nếu returned nil, app trả nil; không giả lớp hoặc method để che hiện tượng đó.

Các nguồn DYYY đã đọc chưa có giải pháp native phù hợp; web public search và tải video theo link không chứng minh server cấp toàn bộ kết quả search cho guest. Không dùng cookie của người khác hoặc rewrite server status thành success. [Nguồn hiện tại có commit/hash](research-0.5.0.json); [tài liệu vòng 0.4.0 để đối chiếu](guest-search-0.4.0.md).

Thử hai từ khóa công khai trong native Search, đổi tab/Back và Copy diagnostics ngay khi lỗi. Không cần login để làm vòng kiểm tra này. Có 2483 thì ghi nhận đúng hạn chế; không coi việc popup biến mất là đã tìm kiếm thành công. Tìm kiếm không giới hạn hiện **chưa đạt**.
