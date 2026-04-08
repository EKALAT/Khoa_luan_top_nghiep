# Flutter Ready

## Mục tiêu

File này dùng để chuẩn bị cho phần Flutter kết nối với backend hiện tại.

Backend đã sẵn sàng cho các luồng chính:

- login
- logout
- me
- profile
- check-in
- check-out
- attendance history
- attendance logs
- network-check

## Base URL nên dùng

### 1. Khi test bằng laptop + Postman

```txt
http://localhost:8000
```

### 2. Khi test Flutter trên máy thật

Ưu tiên dùng `ngrok`:

```txt
https://<your-ngrok-domain>.ngrok-free.dev
```

Lý do:

- điện thoại thật truy cập được backend local
- backend nhìn thấy `request_ip` thực tế tốt hơn khi demo mạng

### 3. Khi test Flutter trên Android Emulator

Nếu không cần test rule mạng theo IP thật:

```txt
http://10.0.2.2:8000
```

Nếu cần test giống môi trường thật:

- vẫn dùng `ngrok`

## Header chuẩn cho Flutter

Các API có auth cần:

```http
Authorization: Bearer <token>
Accept: application/json
Content-Type: application/json
```

## Tài khoản test hiện tại

```json
{
  "employee_code": "nv001",
  "password": "password123"
}
```

```json
{
  "employee_code": "admin01",
  "password": "password123"
}
```

## Demo data hiện tại

`work_location_id` đang dùng để demo:

```txt
2
```

Tọa độ demo:

```txt
latitude  = 17.46655
longitude = 106.59854
radius_m  = 50
```

Rule mạng demo:

```txt
113.161.12.141,2001:ee0:4bbb:a90::/64
```

## Auth flow cho Flutter

### Login

```http
POST /api/auth/login
```

Body:

```json
{
  "employee_code": "nv001",
  "password": "password123"
}
```

Response:

```json
{
  "message": "Đăng nhập thành công.",
  "token": "37|xxxxx",
  "token_type": "Bearer",
  "user": {
    "id": 2,
    "employee_code": "nv001",
    "name": "Nguyen Van A",
    "email": "nv001@example.com",
    "phone": "0900000002",
    "role": "Employee",
    "department": "IT"
  }
}
```

Flutter nên làm:

1. gọi login
2. lưu `token`
3. lưu object `user`
4. set Bearer token cho các request sau

### Me

```http
GET /api/auth/me
```

Dùng để refresh user sau khi mở app lại.

### Logout

```http
POST /api/auth/logout
```

Sau khi logout:

- xóa token local
- quay về màn login

## Profile flow

### Lấy profile

```http
GET /api/profile
```

### Cập nhật profile

```http
PUT /api/profile
```

Body:

```json
{
  "name": "Nguyen Van A Updated",
  "email": "nv001.updated@example.com",
  "phone": "0901234567"
}
```

## Attendance flow

### Check-in

```http
POST /api/attendance/check-in
```

### Check-out

```http
POST /api/attendance/check-out
```

Body chuẩn:

```json
{
  "work_location_id": 2,
  "latitude": 17.46655,
  "longitude": 106.59854,
  "accuracy_m": 5,
  "network_info": "Company WiFi",
  "device_info": "Flutter app"
}
```

Lưu ý:

- `network_info` chỉ để log
- rule mạng thật dựa vào `request_ip`

### Attendance history

```http
GET /api/attendance
```

Các filter đang hỗ trợ:

```http
GET /api/attendance?date=2026-03-25
GET /api/attendance?from=2026-03-01&to=2026-03-31
GET /api/attendance?status=valid
GET /api/attendance?check_type=morning_check_in
```

### Attendance logs

```http
GET /api/attendance/logs
```

## API kiểm tra mạng

```http
GET /api/attendance/network-check?work_location_id=2&network_info=Company WiFi
```

API này rất hữu ích cho Flutter nếu muốn:

- hiện trạng thái mạng trước khi chấm công
- debug `wrong_network`
- hiển thị `request_ip` và `allowed_network`

## Các reason Flutter cần map ra UI

Flutter nên chuẩn bị hiển thị message theo `reason`:

- `wrong_time_window`
- `duplicate_check`
- `missing_check_in`
- `low_accuracy`
- `outside_geofence`
- `wrong_network`

Ngoài ra nên handle:

- `401` unauthenticated
- `403` account locked
- `422` validation error
- `500` server error

## Gợi ý message mapping

### Attendance

- `wrong_time_window`: Chưa tới hoặc đã qua khung giờ chấm công hợp lệ.
- `duplicate_check`: Bạn đã chấm công mốc này rồi.
- `missing_check_in`: Bạn chưa check-in ca tương ứng nên không thể check-out.
- `low_accuracy`: GPS chưa đủ chính xác, vui lòng thử lại.
- `outside_geofence`: Bạn đang ở ngoài khu vực cho phép.
- `wrong_network`: Thiết bị chưa kết nối đúng mạng hợp lệ.

### Auth

- `401`: Thông tin đăng nhập không đúng hoặc phiên đăng nhập đã hết hạn.
- `403`: Tài khoản đã bị khóa.

## Màn hình Flutter nên làm trước

Thứ tự tối ưu:

1. Splash
2. Login
3. Home
4. Check-in / Check-out
5. Attendance history
6. Profile

## State tối thiểu cần có trong Flutter

Nên có các model hoặc entity sau:

- `User`
- `LoginResponse`
- `AttendanceRecord`
- `AttendanceLog`
- `Profile`
- `NetworkCheckResponse`

## Checklist trước khi code Flutter tối nay

1. Backend chạy được ở `localhost:8000`
2. Nếu test trên máy thật thì mở `ngrok`
3. Login bằng `nv001 / password123`
4. `work_location_id = 2`
5. Tọa độ demo là `17.46655 / 106.59854`
6. Nếu test rule mạng, ưu tiên gọi `network-check` trước
7. Nếu test `check-out`, phải đảm bảo đã có `check-in` hợp lệ tương ứng

## Checklist trước khi demo Flutter

1. Kiểm tra `baseUrl` đang đúng môi trường
2. Kiểm tra token còn hợp lệ
3. Kiểm tra `shift_rules` có đúng khung giờ demo
4. Kiểm tra `work_location_id = 2`
5. Nếu demo mạng, gọi `network-check` trước
6. Nếu cần demo fail mạng, đổi sang hotspot hoặc mạng khác
