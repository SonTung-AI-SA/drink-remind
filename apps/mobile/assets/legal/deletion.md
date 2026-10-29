# Thông tin xóa dữ liệu

Bản thử nghiệm · Chức năng xóa toàn bộ tài khoản trong app chưa được triển khai. Hiện chỉ có tài liệu chuẩn bị quy trình.

## Lần uống riêng lẻ

Bạn có thể xóa lần uống trong Hành trình. Nếu đang đăng nhập, dấu xóa được gửi lên server khi có mạng và giữ để thiết bị khác không khôi phục nhầm lần uống đó.

## Dữ liệu khách

Dữ liệu khách chỉ lưu trên thiết bị. Gỡ app hoặc xóa dữ liệu ứng dụng trong hệ điều hành có thể xóa lịch sử khách; không thực hiện nếu còn dữ liệu cần giữ. Việc này không xóa dữ liệu tài khoản đã đồng bộ trên server.

## Tài khoản

Đăng xuất không xóa tài khoản hoặc lịch sử trên server. Bản production phải bổ sung luồng xác nhận và xóa tài khoản cùng hồ sơ, mục tiêu, lịch sử, phiên đăng nhập và dữ liệu liên quan; đồng thời xử lý bản sao lưu và quyền liên kết nhà cung cấp theo chính sách được công bố.

## Trạng thái hỗ trợ

Chưa cấu hình liên hệ hỗ trợ hoặc trang yêu cầu xóa dữ liệu công khai. Chỉ dùng tài khoản kiểm thử cho đến khi quy trình và đầu mối liên hệ chính thức được hoàn thiện.
