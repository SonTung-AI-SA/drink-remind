# Yêu cầu sản phẩm — App nhắc uống nước

- Ngày cập nhật: 28/10/2026
- Phiên bản: 0.1
- Trạng thái: Tổng hợp thảo luận; chưa phải đặc tả đã duyệt toàn bộ.
- Tài liệu liên quan: [Kiến trúc project](architecture.md).

## 1. Mục tiêu

Phát triển app cho iOS và Android giúp người dùng duy trì thói quen uống nước, kết hợp nuôi thú ảo để tạo động lực. Hai nền tảng sử dụng chung backend; người dùng có thể khôi phục lịch sử sử dụng và tiến độ đã đồng bộ khi đổi điện thoại.

## 2. Cách đọc trạng thái yêu cầu

- **Đã xác nhận:** người dùng trực tiếp yêu cầu hoặc đã xác nhận phạm vi.
- **Đề xuất:** nội dung tư vấn bổ sung, cần được duyệt trước khi triển khai.
- **Cần chốt:** quyết định chưa đủ thông tin để đặc tả hoặc triển khai.

Việc tạo tài liệu này không đồng nghĩa phê duyệt triển khai mã nguồn, hạ tầng hoặc toàn bộ đề xuất.

## 3. Yêu cầu đã xác nhận

| ID | Nhóm | Yêu cầu |
| --- | --- | --- |
| FR-01 | Nền tảng | Có app iOS và Android, dùng chung backend. |
| FR-02 | Nhắc uống nước | Nhắc người dùng đạt mục tiêu nước trong ngày; chia lịch theo lượng nước còn lại cần uống. |
| FR-03 | Mục tiêu | Cho phép đề xuất mục tiêu dựa trên giới tính, cân nặng, chiều cao, tuổi hoặc tự nhập lượng nước cụ thể. Phương pháp tính cần được chọn và xác minh trước khi triển khai. |
| FR-04 | Ghi nhận | Người dùng kiểm tra/ghi nhận việc uống nước trên app. |
| FR-05 | Thú ảo | Giao diện vui vẻ, có thú ảo như cá, mèo, chó; uống đúng giờ và ghi nhận sẽ cho thú ăn và phát triển. |
| FR-06 | Dữ liệu | Lưu lịch sử sử dụng trên backend, khôi phục phần đã đồng bộ khi đổi điện thoại và đăng nhập cùng tài khoản. |
| FR-07 | Đăng nhập | Hỗ trợ Facebook Login, Sign in with Google và Sign in with Apple. “Gmail” và “iCloud” được hiểu là đăng nhập Google và Apple, không truy cập hộp thư. |
| FR-08 | Danh tính | Dùng đầu mối xác thực chung; hỗ trợ Apple ẩn email và liên kết phương thức đăng nhập để hạn chế tài khoản trùng. |
| FR-09 | Tài khoản | Cho phép đăng xuất và xóa tài khoản cùng dữ liệu liên quan. |
| NFR-01 | Thương mại | Ưu tiên công nghệ miễn phí bản quyền, có giấy phép cho phép sử dụng thương mại; tuân thủ nghĩa vụ giấy phép. |

## 4. Chi tiết chức năng đề xuất

### 4.1. Hồ sơ và mục tiêu

- Thu thập thông tin phục vụ phương pháp tính đã được lựa chọn.
- Hiển thị mức gợi ý, cách tính và cho người dùng xác nhận hoặc sửa trước khi áp dụng.
- Cho phép nhập mục tiêu trực tiếp.
- Lưu mục tiêu theo từng ngày để thay đổi hiện tại không làm thay đổi lịch sử.
- Không mặc định mọi trường hồ sơ đều phải tham gia công thức; không dùng công thức 30 ml/kg của bản thử nghiệm làm quyết định sản phẩm đã duyệt.

### 4.2. Lịch nhắc

- Thiết lập giờ bắt đầu, kết thúc nhắc, dung tích thường uống và khoảng thời gian không muốn bị làm phiền.
- Phân bổ lượng nước còn lại trong thời gian sinh hoạt còn lại.
- Cập nhật lịch khi ghi nhận nước, sửa/xóa lần uống, đổi mục tiêu hoặc khung giờ.
- Hỗ trợ các thao tác: Đã uống, Nhắc sau, Bỏ qua.
- Bỏ lỡ lịch không dẫn tới yêu cầu uống bù một lượng lớn trong một lần.
- Dừng nhắc khi đạt mục tiêu hoặc kết thúc khung giờ.
- Thông báo được đặt trên điện thoại; không phụ thuộc hoàn toàn vào kết nối mạng.
- Hiển thị trạng thái chưa cấp quyền thông báo và hướng dẫn bật lại khi cần.

### 4.3. Ghi nhận uống nước

- Ghi nhận nhanh theo dung tích có sẵn hoặc nhập dung tích khác.
- Lưu thời gian uống; cho phép sửa, xóa hoặc hoàn tác.
- Hiển thị tổng đã uống, lượng còn lại và phần trăm hoàn thành.
- Hoạt động offline và hiển thị trạng thái đồng bộ.

### 4.4. Thú nuôi và phần thưởng

- Chọn cá, mèo hoặc chó, có trạng thái chờ, ăn, vui vẻ và các giai đoạn phát triển.
- Phản hồi bằng hoạt ảnh sau khi ghi nhận thành công trên thiết bị.
- Đề xuất mở rộng yêu cầu gốc: mọi lần uống đều giúp thú phát triển; đúng lịch nhận thưởng nhỏ bổ sung.
- Đề xuất giới hạn phần thưởng theo ngày, ưu tiên duy trì thói quen qua nhiều ngày thay vì uống thêm để tăng cấp.
- Không trừng phạt người dùng bằng việc làm thú chết hoặc mất tiến độ khi bỏ lỡ.
- Backend xác nhận phần thưởng, không cộng trùng khi đồng bộ lại.

Quy tắc thưởng, định nghĩa “đúng giờ”, giới hạn và tác động của sửa/xóa lần uống đều cần chốt.

### 4.5. Lịch sử và thống kê

- Xem lịch sử từng ngày và thống kê tuần.
- Phân biệt dữ liệu chưa đồng bộ và đã được backend xác nhận.
- Khôi phục mục tiêu, lịch sử, sở hữu thú và tiến độ khi đổi thiết bị.
- Dữ liệu chưa từng đồng bộ không được cam kết khôi phục nếu mất thiết bị.

### 4.6. Tài khoản và đăng nhập bên thứ ba

- Đăng nhập Google, Apple, Facebook trên hai nền tảng.
- Dữ liệu gắn với ID tài khoản nội bộ, không dùng email làm khóa nghiệp vụ.
- Liên kết thêm phương thức đăng nhập yêu cầu xác thực phù hợp; không tự gộp chỉ vì email giống nhau.
- Nếu đã có hai tài khoản cùng chứa dữ liệu, cần luồng hợp nhất riêng với quy tắc rõ ràng.
- Xử lý người dùng hủy đăng nhập, nhà cung cấp lỗi, phiên hết hạn và mất mạng.
- Đăng xuất phải cách ly dữ liệu local của tài khoản cũ.
- Xóa tài khoản cần xác nhận trong sản phẩm và xử lý dữ liệu trên server, thiết bị cùng phiên đăng nhập liên quan.
- Quyền truy cập email/mật khẩu, chế độ khách và cơ chế khôi phục khi mất tài khoản nhà cung cấp chưa được chốt.

## 5. Yêu cầu phi chức năng đề xuất

| Nhóm | Yêu cầu |
| --- | --- |
| Trải nghiệm | Tiếng Việt, vui vẻ, dễ đọc; ghi nhận thường dùng trong ít thao tác. |
| Offline | Không mất lần ghi nhận khi kết nối gián đoạn; có hàng đợi gửi lại. |
| Nhất quán | Gửi lại không tạo lần uống hoặc phần thưởng trùng; xử lý xung đột đa thiết bị. |
| Thời gian | Lưu thời điểm UTC và thông tin múi giờ/ngày địa phương phù hợp; xác định hành vi khi đổi múi giờ. |
| Bảo mật | Dữ liệu được phân quyền theo tài khoản; không nhúng khóa quản trị vào app. |
| Vận hành | Có backup, quy trình phục hồi, migration và môi trường phát triển/kiểm thử/sản xuất tách biệt. |
| Mở rộng | Tách nghiệp vụ, giao diện và truy cập dữ liệu; có thể bổ sung chức năng mà không viết lại toàn bộ app. |
| Bản quyền | Kiểm tra giấy phép thư viện trực tiếp và phụ thuộc, hình ảnh, font, âm thanh; giữ thông báo theo giấy phép. |

Chỉ tiêu định lượng về hiệu năng, dung lượng, thời gian đồng bộ, thời gian phục hồi và lưu giữ dữ liệu cần được xác định sau.

## 6. Phạm vi MVP đề xuất

1. Đăng nhập bằng ba nhà cung cấp; liên kết phương thức, đăng xuất, xóa tài khoản.
2. Hồ sơ, mục tiêu nhập tay và phương pháp gợi ý đã được duyệt.
3. Thiết lập khung giờ và lịch nhắc tự điều chỉnh.
4. Ghi nhận, sửa/xóa, tiến độ ngày và lịch sử tuần.
5. Chọn cá/mèo/chó, dùng chung cơ chế phát triển với đồ họa 2D đơn giản.
6. Lưu offline, đồng bộ, phục hồi trên điện thoại mới.
7. Đề xuất một thiết bị nhận nhắc chính để giảm thông báo trùng.

Chưa đưa vào MVP: mạng xã hội, thử thách nhóm, vật phẩm phong phú, thanh toán/gói trả phí, Apple Health/Health Connect, dashboard quản trị riêng và phân tích nâng cao.

## 7. Tiêu chí nghiệm thu dự kiến

| Luồng | Kết quả cần kiểm chứng |
| --- | --- |
| Đăng nhập | Ba nhà cung cấp hoạt động trên iOS/Android; hủy hoặc lỗi không tạo trạng thái đăng nhập sai. |
| Apple ẩn email | Tài khoản được nhận diện bằng danh tính xác thực, không phụ thuộc email thật. |
| Đổi điện thoại | Đăng nhập cùng tài khoản khôi phục dữ liệu đã đồng bộ. |
| Ghi nhận offline | Hiển thị ngay, còn dữ liệu sau khi mở lại app; lên mạng gửi lại không trùng. |
| Sửa/xóa offline | Thay đổi được đồng bộ, không bị phục hồi sai từ thiết bị khác. |
| Lịch nhắc | Cập nhật theo phần nước còn lại, không giữ mốc cũ đã bị thay thế. |
| Phần thưởng | Một lần uống chỉ phát sinh phần thưởng hợp lệ một lần dù yêu cầu được gửi lại. |
| Đăng xuất/đổi tài khoản | Không hiển thị dữ liệu người trước cho người sau. |
| Xóa tài khoản | Dữ liệu bị xử lý theo chính sách đã công bố, không được hàng đợi offline tạo lại ngoài ý muốn. |
| Nâng cấp app | Migration bảo toàn dữ liệu lịch sử. |

Các tiêu chí phụ thuộc quy tắc chưa chốt sẽ được hoàn thiện khi duyệt đặc tả.

## 8. Quyết định còn mở

- Nhóm tuổi và nhóm người dùng mục tiêu; phương pháp tính lượng nước và phạm vi sử dụng phù hợp.
- Theo dõi nước lọc hay tổng các loại đồ uống.
- Quy tắc đúng giờ, cho ăn, tăng cấp, giới hạn thưởng và xử lý hoàn tác.
- Riverpod hay Cubit; hiện đề xuất Riverpod.
- Supabase tự triển khai hay dịch vụ quản lý; ngân sách và người phụ trách vận hành.
- Chính sách hợp nhất hai tài khoản có sẵn và phương thức khôi phục tài khoản.
- Chế độ khách, đăng nhập email/mật khẩu có nằm trong MVP hay không.
- Quy tắc thay đổi ngày/múi giờ và thiết bị nhận nhắc chính.
- Chính sách lưu giữ/xóa dữ liệu, backup và dữ liệu offline khi đăng xuất.
- Tên thương hiệu chính thức; “Mizu” chỉ là tên trong bản thử nghiệm hiện có.

## 9. Chi phí và giới hạn

Công nghệ miễn phí bản quyền không có nghĩa tổng chi phí bằng không. Vẫn cần ngân sách server, backup, email nếu sử dụng, đồ họa, kiểm thử thiết bị và tài khoản phát hành ứng dụng. Giấy phép cho công cụ không tự cấp quyền dùng mọi tài nguyên tải từ cộng đồng.

Thông báo phụ thuộc quyền người dùng và giới hạn hệ điều hành; cần kiểm thử trên thiết bị thật, không cam kết chính xác tuyệt đối trong mọi trạng thái thiết bị.

## 10. Nguyên tắc thực hiện

Theo [AGENTS.md](../AGENTS.md): xác nhận yêu cầu, trình bày việc dự định làm và chờ người dùng đồng ý trước khi triển khai. Chỉ thực hiện trong phạm vi được cho phép rõ ràng.
