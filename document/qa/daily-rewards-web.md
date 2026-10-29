# Phần thưởng trong ngày — web

Phạm vi được duyệt: apply sáu asset phần thưởng vào code và build web trước.

- Vật phẩm chỉ hiện khi tổng nước ngày hiện tại đạt mục tiêu ngày đó. Khôi phục khi mở lại app từ dữ liệu lịch sử sẵn có; không thay backend schema.
- Sang ngày mới, refresh định kỳ mỗi phút hoặc lúc app resume tính lại trạng thái. Hoàn tác/xóa khiến tiến độ xuống dưới mục tiêu gỡ ngay vật phẩm.
- Nemo đội vương miện, Corgi đeo khăn xanh, Mèo Cam đeo huy hiệu cá vàng. Accessory đi cùng transform của nhân vật và có vị trí theo từng khung; không thêm khăn thứ hai ở hàng GOAL đã có khăn trong ảnh Corgi.
- Hiệu ứng bong bóng/giấy màu/ánh sao phát 4 giây khi complete chuyển false → true, rồi biến mất; không lặp khi progress vẫn complete. Khôi phục trang đã complete không phát lại. Nếu hoàn tác rồi đạt lại, có thể phát một đợt mới.
- Giảm chuyển động tắt hiệu ứng, vẫn giữ vật phẩm. Lớp hiệu ứng không chặn thao tác.
- Bỏ toàn bộ banner bông hoa cũ khỏi TodayPage; giữ phần ghi nhận nước, lịch và gợi ý mục tiêu.
- Asset runtime cắt phần trống theo alpha từ PNG nguồn, không thay artwork gốc. Vị trí phụ kiện được căn theo atlas đã duyệt; chuyển tư thế vẫn dùng các khung chính, chưa phải rig.

Kiểm tra: test nhận/gỡ/khôi phục, FX hữu hạn và không replay khi dựng lại trang, giảm chuyển động; test dữ liệu ở 23:59 và ngày kế tiếp; render đủ ba thú cùng vật phẩm. Ảnh Flutter: [daily-rewards-gallery.png](daily-rewards-gallery.png).

Chưa build Android/iOS trong lần này. Không sửa dữ liệu thật để tạo cảnh đạt mục tiêu trong trình duyệt; ảnh minh chứng dùng widget fixture.

Kết quả: 11 test liên quan qua (gồm test ngày mới bổ sung), analyzer không lỗi/cảnh báo, web release build thành công. Reload trình duyệt xác nhận Nemo đội vương miện từ tiến độ đã lưu sẵn 2.500/2.450 ml, không phát lại FX; banner hoa đã bỏ. Ảnh web thật: [web-daily-rewards.png](web-daily-rewards.png). Gallery ba thú là widget fixture riêng.
