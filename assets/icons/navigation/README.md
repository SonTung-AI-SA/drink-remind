# Bộ icon điều hướng

Ba biểu tượng tự viết riêng cho project, mỗi biểu tượng có trạng thái thường và đang chọn:

| Nút | Thường | Đang chọn | Nhãn đọc màn hình |
| --- | --- | --- | --- |
| Không gian chính | island.svg | island-active.svg | Không gian đảo |
| Lịch sử | journey.svg | journey-active.svg | Hành trình |
| Tài khoản | profile.svg | profile-active.svg | Cá nhân |

- SVG viewBox 28 × 28, nét 1.8, đầu nét và góc bo tròn.
- Màu thường #5C737D, đang chọn #2987AD, phần tô #B5E0E7.
- App chỉ hiển thị icon, không hiện tên nút. Giữ nhãn hỗ trợ tiếp cận.
- Vùng chạm tối thiểu 48 × 48; bản xem trước dùng 68 × 48.
- Nút active có nền #E9F5F6 hình viên thuốc và phần tô trong icon.
- SVG dùng màu tường minh để dễ xem độc lập. Khi tích hợp dark theme, ánh xạ màu qua theme app.
- Không sao chép từ bộ icon bên thứ ba, không cần font icon hoặc ảnh emoji hệ thống.
- Các icon cũ tại thư mục cha vẫn giữ nguyên. Bộ này là bản điều hướng có trạng thái rõ ràng.

Mở `preview.html` để xem và bấm thử ba nút.
