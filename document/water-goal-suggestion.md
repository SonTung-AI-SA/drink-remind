# Gợi ý mục tiêu nước — v1

Đã duyệt: tên hiển thị đúng Corgi, Nemo, Mèo Cam; gợi ý không tự đổi mục tiêu, người dùng có thể dùng gợi ý hoặc tự nhập.

## Phương pháp

Nguồn: [Gloucestershire Hospitals NHS Foundation Trust — Fluid and caffeine intake for bladder and bowel health](https://www.gloshospitals.nhs.uk/your-visit/patient-information-leaflets/fluid-and-caffeine-intake-bladder-and-bowel-health-ghpi0533/), phần Fluid intake, truy cập 2026-10-29.

Dùng bảng lượng đồ uống theo cân nặng trong nguồn. Nội suy tuyến tính giữa hai hàng kề nhau và làm tròn gần nhất theo bước 50 ml là quyết định triển khai của app, không phải công thức cá nhân hóa do NHS công nhận. Ví dụ 60 kg → khoảng 1.850 ml; 70 kg → 2.200 ml sau làm tròn.

Phạm vi bảng 38–102 kg; ngoài phạm vi không ngoại suy hoặc ép về ngưỡng. Kiểm tra tuổi 18–100 và chiều cao 100–230 cm theo phạm vi hồ sơ hiện tại của app. Tuổi dùng kiểm tra đối tượng người lớn; chiều cao kiểm tra dữ liệu hợp lệ; giới tính và chiều cao không tạo hệ số nhân không có trong nguồn. Không suy ra mức cá nhân từ đủ cả bốn chỉ số.

Kết quả tính lượng đồ uống gồm nước lọc và đồ uống khác, không phải tổng nước gồm độ ẩm thực phẩm. Không lấy định mức tổng nước rồi áp nguyên sang nước lọc. Gợi ý tham khảo không xử lý bệnh lý, mang thai/cho con bú, vận động nặng hoặc thời tiết nóng; người có chỉ định riêng dùng mục tiêu của bác sĩ.

## Hành vi

- Tính lại khi sửa chỉ số; dữ liệu thiếu/không hợp lệ hoặc ngoài bảng làm vô hiệu nút dùng gợi ý.
- “Dùng mục tiêu này” chỉ điền ô mục tiêu, không ghi database.
- “Lưu mục tiêu” dùng luồng lưu và tính lại lịch hiện có. Không thay lịch sử nước đã uống.
- Vẫn nhập mục tiêu 500–5.000 ml theo bước 50 ml như trước.
- Nguồn và cách tính đọc được trong hộp thoại ngay trong app.

Không thay backend schema và chưa build Android/iOS cho thay đổi này.

## Xác minh

- 14 test liên quan (app flow, domain, pets, water suggestion, widget) qua; analyzer không lỗi/cảnh báo.
- Web release build thành công với cấu hình backend local hiện có.
- Trình duyệt: tên Corgi không tiền tố/hậu tố; 60 kg → 1.850 ml; sửa thử 70 kg → 2.200 ml; bấm dùng gợi ý điền ô mục tiêu 2.200. Không bấm lưu dữ liệu thử; reload để trả lại hồ sơ/mục tiêu đã lưu.
- Ảnh minh chứng dùng dữ liệu nhập thử: [web-water-suggestion.png](qa/web-water-suggestion.png).
