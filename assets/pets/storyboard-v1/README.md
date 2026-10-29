# Pet key-pose assets v1

Theo storyboard đã duyệt: Nemo, Corgi, **Mèo Cam v1**. Tạo bằng công cụ tạo ảnh tích hợp, giữ PNG RGBA và nền trong suốt. Atlas gốc ở đây được giữ nguyên. Theo phê duyệt tiếp theo, các frame đã được tách vào `apps/mobile/assets/pets/storyboard-v1/` và tích hợp trong bản web preview; xem `document/qa/pet-assets-web-v1.md`.

## Files

| File | Nội dung |
|---|---|
| nemo-keyposes.png | Nemo, 12 tư thế |
| corgi-keyposes.png | Corgi, 12 tư thế; bát có thức ăn |
| meo-cam-keyposes.png | Mèo Cam v1, 12 tư thế |

Mỗi atlas có 3 cột × 4 hàng theo bố cục trực quan. Đọc từ trái sang phải, trên xuống dưới. Cột: chuẩn bị, cao trào, kết thúc. Hàng: idle, tap, drink, goal. Xem kích thước và thứ tự trong manifest.json. Đây chưa phải lưới cắt runtime: một số đạo cụ có thể vượt đường chia ô danh nghĩa; cần xác định vùng cắt thủ công. Ảnh gốc chưa cắt tách hay căn chỉnh pivot.

| Hoạt cảnh | Thời lượng định hướng | Sự kiện |
|---|---|---|
| idle | 5s | Thú nghỉ, chạy thưa với khoảng dừng |
| tap | 2s | Người dùng chạm thú |
| drink | 3s | Ghi nhận uống nước, thú nhận phần thưởng |
| goal | 6s | Lần đầu đạt mục tiêu ngày |

Đây là **asset khung chính**, chưa phải chuỗi frame liên tục hoặc file rig. Không phát ba tư thế nối nhau rồi coi là animation hoàn chỉnh. Khi tích hợp cần căn pivot/kích thước, tạo tư thế trung gian hoặc rig, tách chuyển động thân và hiệu ứng, rồi kiểm tra ở kích thước hiển thị thực tế.

Nemo dùng vây bất đối xứng theo storyboard, nhưng cần chuẩn hóa cấu trúc vây giữa các góc khi dựng rig. Corgi giữ bốn chân ngắn. Mèo Cam giữ dáng mập, má bông và vằn cam; cần khóa vằn khi làm chuyển động trung gian. Bóng, bát, bướm, thùng và hiệu ứng hiện gắn cùng tư thế, chưa là layer riêng.

Nền preview của công cụ có thể hiện màu tối quanh nhân vật; PNG có alpha thật. Mép lông/hiệu ứng bán trong suốt cần kiểm tra thêm trên nền đảo thực tế trước khi đưa vào app.

Đặc tả nguồn: ../../../document/storyboards/README.md. Prompt brief lưu tại prompts.md. Script tách frame: ../../../scripts/prepare-pet-frames.ps1. Chưa build Android/iOS cho lần tích hợp này.
