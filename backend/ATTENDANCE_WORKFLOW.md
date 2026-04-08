# Attendance Workflow

## Mô tả tổng quan

Hệ thống chấm công thông minh hoạt động theo mô hình xác thực người dùng kết hợp kiểm tra thời gian, vị trí và mạng kết nối trước khi ghi nhận chấm công.

Người dùng phải đăng nhập trước để nhận `token` xác thực. Sau đó, khi thực hiện `check-in` hoặc `check-out`, thiết bị gửi request lên backend kèm theo các thông tin:

- `work_location_id`
- `latitude`
- `longitude`
- `accuracy_m`
- `network_info`
- `device_info`

Trong đó:

- `network_info` chỉ dùng để ghi log và hỗ trợ debug
- nguồn xác minh mạng chính là `request_ip` thật mà backend nhận được

## Luồng hoạt động chung

1. Người dùng đăng nhập vào hệ thống.
2. Hệ thống cấp `token` để xác thực các request tiếp theo.
3. Người dùng thực hiện `check-in` hoặc `check-out`.
4. Backend kiểm tra các điều kiện nghiệp vụ theo đúng thứ tự đã cấu hình.
5. Nếu tất cả điều kiện hợp lệ, hệ thống tạo bản ghi chấm công hợp lệ.
6. Nếu có điều kiện không hợp lệ, hệ thống từ chối và lưu log lỗi tương ứng.

## Thứ tự kiểm tra khi chấm công

Khi backend nhận request `check-in` hoặc `check-out`, hệ thống xử lý theo thứ tự sau:

### 1. Xác thực người dùng và dữ liệu đầu vào

Hệ thống kiểm tra:

- người dùng đã đăng nhập hay chưa
- dữ liệu request có hợp lệ hay không
- `work_location_id` có tồn tại hay không

Nếu không hợp lệ, request sẽ bị từ chối ngay.

### 2. Xác định loại chấm công theo thời gian hiện tại

Hệ thống dựa vào `shift_rules` đang active để xác định `check_type` tương ứng:

- `morning_check_in`
- `morning_check_out`
- `afternoon_check_in`
- `afternoon_check_out`

Nếu thời điểm hiện tại không thuộc bất kỳ khung giờ hợp lệ nào, hệ thống trả về:

- `reason = wrong_time_window`

### 3. Kiểm tra chấm công trùng

Hệ thống kiểm tra trong `attendance_records` xem người dùng đã chấm công cùng `check_type` trong cùng ngày hay chưa.

Nếu đã tồn tại bản ghi trước đó, hệ thống trả về:

- `reason = duplicate_check`

### 4. Kiểm tra thiếu check-in khi check-out

Rule này chỉ áp dụng cho thao tác `check-out`.

- Nếu là `morning_check_out`, hệ thống bắt buộc phải tìm thấy `morning_check_in` hợp lệ cùng ngày.
- Nếu là `afternoon_check_out`, hệ thống bắt buộc phải tìm thấy `afternoon_check_in` hợp lệ cùng ngày.

Nếu chưa có `check-in` hợp lệ tương ứng, hệ thống trả về:

- `reason = missing_check_in`

### 5. Kiểm tra độ chính xác GPS

Hệ thống kiểm tra giá trị `accuracy_m`.

Nếu độ chính xác GPS vượt quá ngưỡng cho phép, hệ thống trả về:

- `reason = low_accuracy`

### 6. Kiểm tra geofence

Hệ thống tính khoảng cách giữa vị trí hiện tại của người dùng và vị trí của `work_location`.

Nếu khoảng cách vượt quá `radius_m` của địa điểm làm việc, hệ thống trả về:

- `reason = outside_geofence`

### 7. Kiểm tra mạng hợp lệ

Sau khi qua các bước trên, hệ thống kiểm tra mạng bằng cách:

1. Lấy `request_ip` thật từ request
2. So sánh với `work_locations.allowed_network`

`allowed_network` hỗ trợ:

- một IP đơn
- CIDR
- nhiều giá trị ngăn cách bởi dấu phẩy
- cả IPv4 và IPv6

Ví dụ:

- `113.161.12.141`
- `113.161.12.128/27`
- `2001:ee0:4bbb:a90::/64`
- `113.161.12.141,2001:ee0:4bbb:a90::/64`

Nếu mạng không hợp lệ, hệ thống trả về:

- `reason = wrong_network`

### 8. Ghi nhận chấm công hợp lệ

Nếu người dùng vượt qua toàn bộ các bước kiểm tra trên, hệ thống sẽ:

1. Tạo bản ghi trong `attendance_records` với `status = valid`
2. Tạo bản ghi trong `attendance_logs` với `result = valid`
3. Trả về thông báo chấm công thành công

## Các lý do từ chối chấm công

Hệ thống hiện hỗ trợ các mã lỗi nghiệp vụ sau:

- `wrong_time_window`
- `duplicate_check`
- `missing_check_in`
- `low_accuracy`
- `outside_geofence`
- `wrong_network`

Các mã lỗi này được trả về trong JSON response để frontend hoặc ứng dụng mobile có thể hiển thị đúng thông báo cho người dùng.

## API kiểm tra mạng riêng

Ngoài `check-in` và `check-out`, hệ thống còn có API kiểm tra mạng riêng:

```http
GET /api/attendance/network-check
```

API này dùng để:

- kiểm tra backend đang nhìn thấy `request_ip` nào
- kiểm tra IP hiện tại có thuộc mạng hợp lệ hay không
- hỗ trợ debug rule `wrong_network`

Response sẽ gồm:

- `request_ip`
- `allowed_network`
- `is_allowed`

## Kết luận

Hệ thống chấm công được thiết kế theo hướng kiểm tra nhiều lớp điều kiện trước khi ghi nhận dữ liệu, bao gồm:

- thời gian
- chống chấm công trùng
- kiểm tra bắt buộc check-in trước khi check-out
- độ chính xác GPS
- geofence
- mạng hợp lệ

Nhờ đó, hệ thống giúp tăng độ tin cậy của dữ liệu chấm công và hạn chế các hành vi gian lận trong quá trình sử dụng.
