# Smart Attendance PMS Backend

## Mô tả

Laravel backend cho hệ thống chấm công thông minh.

Chức năng chính:
- Đăng nhập, đăng xuất, lấy thông tin user hiện tại
- Chấm công vào / ra
- Lịch sử chấm công và log chấm công
- Hồ sơ user hiện tại
- Rule kiểm tra thời gian, GPS, geofence, network và thiếu check-in

## Yêu cầu môi trường

- Docker Desktop / Docker Compose
- Hoặc PHP 8.3+
- Composer 2+
- MySQL 8.0+

## Chạy bằng Docker

Chạy từ thư mục gốc của project:

```bash
docker compose up -d --build
docker compose exec app composer install
docker compose exec app cp .env.example .env
docker compose exec app php artisan key:generate
docker compose exec app php artisan migrate
docker compose exec app php artisan db:seed
docker compose exec app php artisan optimize:clear
```

URL dùng để test:
- API: `http://localhost:8000`
- phpMyAdmin: `http://localhost:8080`

## Migrate / Seed

Nếu container đã chạy sẵn:

```bash
docker compose exec app php artisan migrate
docker compose exec app php artisan db:seed
```

Nếu chạy local trong thư mục `backend`:

```bash
php artisan migrate
php artisan db:seed
php artisan optimize:clear
```

## Login test

Endpoint:

```http
POST /api/auth/login
```

Body mẫu:

```json
{
  "employee_code": "nv001",
  "password": "Ekalat_9090"
}
```

Header cho các API có auth:

```http
Authorization: Bearer <token>
Accept: application/json
Content-Type: application/json
```

## Tài khoản test mẫu

| employee_code | password | role |
| --- | --- | --- |
| admin01 | password123 | admin |
| nv001 | password123 | employee |

## Dữ liệu mẫu để test attendance

- `work_location_id`: `2`
- `allowed_network` của `work_location`: `113.161.12.141,2001:ee0:4bbb:a90::/64`
- `network_info`: chỉ dùng để ghi log, không phải nguồn xác minh chính
- `latitude`: `17.46655`
- `longitude`: `106.59854`
- `accuracy_m`: `5`

Khung giờ mặc định:
- `morning_check_in`: `07:40 - 08:20`
- `morning_check_out`: `11:20 - 11:40`
- `afternoon_check_in`: `13:00 - 13:30`
- `afternoon_check_out`: `16:40 - 17:30`

Rule mạng hiện tại:
- Backend ưu tiên kiểm tra `public IP` thật của request theo `work_locations.allowed_network`
- Hỗ trợ IP đơn, CIDR hoặc nhiều giá trị cách nhau bởi dấu phẩy
- Ví dụ: `113.161.12.141`, `113.161.12.128/27` hoặc `2001:ee0:4bbb:a90::/64`
- `network_info` client gửi lên chỉ để lưu log/phục vụ debug

## API chính

Auth:
- `POST /api/auth/login`
- `GET /api/auth/me`
- `POST /api/auth/logout`

Attendance:
- `POST /api/attendance/check-in`
- `POST /api/attendance/check-out`
- `GET /api/attendance`
- `GET /api/attendance/{id}`
- `GET /api/attendance/logs`
- `GET /api/attendance/logs/{id}`

Profile:
- `GET /api/profile`
- `PUT /api/profile`

Danh sách / cấu hình:
- `GET /api/work-locations`
- `GET /api/shift-rules`

## Ví dụ filter attendance

```http
GET /api/attendance?date=2026-03-25
GET /api/attendance?from=2026-03-01&to=2026-03-31
GET /api/attendance?status=valid
GET /api/attendance?check_type=morning_check_in
```

## Kiem tra IP mang hien tai

De test rule `wrong_network` theo `public IP`, uu tien kiem tra `public IP` hien tai cua mang dang dung:

PowerShell:

```powershell
(Invoke-RestMethod https://api.ipify.org?format=json).ip
```

Hoac:

```powershell
curl https://api.ipify.org
```

Neu can xem IP noi bo (LAN) tren may Windows:

```powershell
ipconfig
```

Neu backend dang chay bang Docker + `http://localhost:8000`, Laravel co the nhin thay IP noi bo cua Docker bridge, vi du `172.18.0.1`, thay vi `public IP` that cua Wi-Fi hien tai.

De xem chinh xac backend dang nhin thay IP nao, goi API:

```http
GET /api/attendance/network-check?work_location_id=2&network_info=Room%20WiFi
```

Response se tra ve:
- `request_ip`: IP ma backend nhin thay
- `allowed_network`: IP hoac CIDR duoc phep trong `work_locations`
- `is_allowed`: `true` neu hop le, `false` neu khong hop le

Khi `check-in` / `check-out` bi `wrong_network`, response cung tra them `data.request_ip` va `data.allowed_network` de debug nhanh.

Neu muon test giong thuc te:
- Deploy backend ra URL public, khong dung `localhost`
- Dat `work_locations.allowed_network` bang `public IP` cua cong ty, vi du `113.161.12.141`
- Noi Wi-Fi cong ty thi ky vong `is_allowed = true`
- Doi sang hotspot/4G/Wi-Fi khac thi ky vong `is_allowed = false`
