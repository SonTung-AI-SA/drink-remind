# Tích hợp thú theo storyboard — web preview

Ngày: 2026-10-29. Phạm vi: Flutter UI và bản web local; chưa build lại Android/iOS.

- Tách 36 tư thế từ 3 atlas đã duyệt. Nguồn Mèo Cam là v1.
- Script `scripts/prepare-pet-frames.ps1` có vùng cắt điều chỉnh theo từng atlas, lấy bounding box alpha và đặt trên canvas 512×512 với tỉ lệ chung theo từng thú, căn chân ở cùng baseline. Ảnh gốc được giữ lại.
- Runtime dùng PNG tại `apps/mobile/assets/pets/storyboard-v1/`, không dùng atlas cũ hoặc CustomPainter chó/cá.
- Tên mặc định: Nemo, Corgi, Mèo Cam. Chưa bổ sung chỉnh sửa tên trong lần tích hợp này.
- Idle dài 5s sau khoảng nghỉ 16s, chạm 2s, phản ứng uống 3s; nếu lần ghi nhận vừa vượt mục tiêu, chạy tiếp cảnh goal 6s. Tiến độ nước vẫn được lưu trước hoạt cảnh. Không thay quy tắc XP/phần ăn trong repository.
- Chạm không ngắt cảnh thưởng. Đổi thú hủy cảnh đang chạy. Chế độ giảm chuyển động không chạy animation.
- Tăng vùng hiển thị thú trong đảo và thêm mặt nước cho Nemo.
- Khi lưu hồ sơ, xóa lời thoại cũ và trạng thái hoạt cảnh để tránh nhắc tên thú trước.

## Kiểm tra

- Analyzer không lỗi/cảnh báo trước bản build đầu; bộ offline gồm 20 test đã qua.
- Test hoạt cảnh kiểm tra DRINK → GOAL → IDLE, chạm không ngắt cảnh, giảm chuyển động; test hiển thị cả ba thú qua ba cấp độ.
- Web release build với cấu hình Supabase local thành công. Preview tại http://localhost:5174/.
- Kiểm tra trình duyệt ở 390×844: Mèo Cam, Nemo và Corgi hiển thị được, chọn thú qua trang Cá nhân và lưu được.

## Giới hạn của bản preview

Đây là chuyển đổi giữa các khung chính, kết hợp chuyển động vị trí/xoay; chưa có rig hoặc các frame trung gian cho chân/tai/đuôi. Không coi đây là animation sản xuất hoàn chỉnh. Đạo cụ và hiệu ứng còn gắn cùng ảnh. Growth hiện thay đổi kích thước, không có bộ tạo hình riêng từng tuổi. Cảnh goal dựa trên lần vượt mục tiêu của lần ghi nhận, chưa có cơ chế lưu riêng “đã ăn mừng ngày này” nếu hoàn tác rồi vượt lại.

OAuth, đồng bộ server và nhắc nền không được kiểm tra lại trong phạm vi thay asset này. Bản web vẫn không hỗ trợ nhắc nền như mobile.
