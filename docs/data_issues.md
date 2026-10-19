***Track evidence in 02_sql_analysis/profiling***

## SRC01: `raw.sales_transactions`

### Explore

- **File:** `SRC01_sales_transactions.csv`.
- **Phạm vi**: Profiling file SRC01_sales_transactions.csv trên Drive; thống kê Bronze là 4 batch, 4 x 119.101 dòng
- **Grain dự kiến:** chi tiết đơn bán theo sản phẩm. order_id không duy nhất ở cấp dòng;

### Kết quả đã quan sát

| Cột | Vai trò | `null_rows` | `empty_rows` | `space_rows` | `missing_rows` | `missing_pct` | `distinct_nonmissing` |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `order_id` | Mã đơn; không duy nhất ở cấp dòng | 0 | 0 | 0 | 0 | 0,00% | 50000 |
| `customer_id` | Mã khách hàng cần đối chiếu | 0 | 0 | 0 | 0 | 0,00% | 1802 |
| `employee_id` | Mã nhân viên cần đối chiếu | 0 | 0 | 0 | 0 | 0,00% | 108 |
| `product_id` | Mã sản phẩm cần đối chiếu | 0 | 0 | 0 | 0 | 0,00% | 92 |

- Tất cả 21 cột có dtype = str; null_rows, empty_rows, space_rows, missing_rows đều bằng 0 và missing_pct = 0,00%.
- **Duplicate nội dung:** 0 dòng dư; suy ra 0 nhóm trong phạm vi DataFrame và tập cột mà script đã kiểm tra.
- **Duplicate khóa dòng:** chưa xác định số nhóm và số dòng dư do chưa xác nhận grain và chưa có kết quả kiểm tra khóa ứng viên.

### Problem & Handle

- **Dự kiến:** giữ các mã dạng text; chuyển order_date sang date; chuyển quantity, unit_price, discount_pct, discount_amount, gross_amount, net_amount sang kiểu số phù hợp sau kiểm tra, thêm khóa PK cho (order_id, product_id)

## SRC02: `raw.sales_target_plan`

### Explore

- **File:** `SRC02_sales_target_plan.xlsx`.
- **Phạm vi:** Profiling riêng hai sheet trên Drive và thống kê các batch trong Bronze.
- **Bronze:** 3 batch trong ảnh, tổng cộng 4614 dòng:
  - Batch `e87b5427-b671-41c7-b8fd-461fde77f409`: 1950 dòng.
  - Hai batch trước: mỗi batch 1332 dòng.
- **Grain dự kiến:** Một dòng target của một nhân viên trong một tháng, năm và phiên bản kế hoạch.

### Kết quả đã quan sát

| Sheet | Số dòng | Số cột | `employee_id` phân biệt | `month` phân biệt |
| --- | ---: | ---: | ---: | ---: |
| `Plan_v1_Original` | 1332 | 13 | 111 | 12 |
| `Plan_v2_Adjustment_H2` | 618 | 13 | 103 | 6 |

- Cả hai sheet đều có null_rows, empty_rows, space_rows, missing_rows bằng 0 và missing_pct = 0%.
- **Duplicate nội dung:** 0 dòng dư; suy ra 0 nhóm trong phạm vi từng sheet.
- **Duplicate khóa dòng:** chưa có khóa 

### Problem & Handle

- **Dự kiến:** Chuẩn hóa đúng Dtype. Kiểm tra khóa PK cửa DL

## SRC03: `raw.customer_master`

### Explore

- **File:** `SRC03_customer_master.csv`.
- **Batch:** `0253548e-ef2c-49f2-a4c0-bf90b2ebf13b`.
- **Phạm vi:** batch hiển thị trong output; 2000 dòng × 12 cột.
- **Grain dự kiến:** một dòng cho một khách hàng trong snapshot; khóa customer_id.

### Kết quả đã quan sát

| Cột | Vai trò | `null_rows` | `empty_rows` | `space_rows` | `missing_rows` | `missing_pct` | `distinct_nonmissing` |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `customer_id` | Khóa khách hàng | 0 | 0 | 0 | 0 | 0,00% | 2000 |
| `tax_code` | Thuộc tính cần lưu ý | 0 | 1035 | 0 | 1035 | 51,75% | 965 |

- Các cột còn lại có `missing_rows = 0` và `missing_pct = 0,00%`.
- **Duplicate nội dung:** 0 dòng dư; suy ra 0 nhóm trong phạm vi kiểm tra của script.
- **Duplicate khóa:** suy ra 0 nhóm và 0 dòng dư theo customer_id, vì có 2000 giá trị không thiếu phân biệt trên 2000 dòng.


### Problem & Handle

- **Đã phát hiện:** 1035 chuỗi rỗng ở tax_code. Chuẩn hóa rỗng/khoảng trắng thành NULL
- **Dự kiến:** giữ customer_id, phone, tax_code dạng text; chuyển join_date sang date và credit_limit sang numeric sau kiểm tra. Kiểm tra lại tính duy nhất của ID sau chuẩn hóa.
> - **Note:** Thêm loyalty_tier theo yêu cầu

## SCR04: `raw.product_master`

### Explore

- **File:** `SRC04_product_master.xlsx`.
- **Batch:** `487949c4-b7c9-466f-b8d8-0f1755cbd30b`.
- **Phạm vi:** batch hiển thị trong output; 100 dòng × 10 cột.
- **Grain dự kiến:** một dòng cho một sản phẩm trong snapshot; khóa product_id.

### Kết quả đã quan sát

| Cột | Vai trò | `null_rows` | `empty_rows` | `space_rows` | `missing_rows` | `missing_pct` | `distinct_nonmissing` |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `product_id` | Khóa sản phẩm | 0 | 0 | 0 | 0 | 0,00% | 100 |

- Tất cả 10 cột có `missing_rows = 0` và `missing_pct = 0,00%`.
- **Duplicate nội dung:** 0 dòng dư; suy ra 0 nhóm trong phạm vi kiểm tra.
- **Duplicate khóa:** suy ra 0 nhóm và 0 dòng dư theo product_id trong batch

### Problem & Handle

- **Dự kiến:** chuẩn hóa tên/nhãn phân loại; giữ product_id dạng text; chuyển unit_price & cost_price & weight_gram sang numeric, lanch_date sau khi xác định định dạng. Sau đó kiểm tra lại tính duy nhất của ID.

## SRC05 — `raw.distributor_orders`

- **File:** `SRC05_distributor_orders.xlsx`.
- **Batch:** `098840ba-d9f6-435f-8e65-d349ba4164cf`.
- **Phạm vi:** batch hiển thị trong output; 35945 dòng × 21 cột.
- **Grain dự kiến:** chi tiết đơn hàng theo sản phẩm.

### Kết quả đã quan sát

| Cột | Vai trò | `null_rows` | `empty_rows` | `space_rows` | `missing_rows` | `missing_pct` | `distinct_nonmissing` |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `order_id` | Mã đơn; không duy nhất ở cấp dòng | 0 | 0 | 0 | 0 | 0,00% | 8000 |
| `distributor_id` | Mã nhà phân phối cần đối chiếu | 0 | 0 | 0 | 0 | 0,00% | 125 |
| `product_id` | Mã sản phẩm cần đối chiếu | 0 | 0 | 0 | 0 | 0,00% | 92 |

- Tất cả 21 cột có `missing_rows = 0` và `missing_pct = 0,00%`.
- **Duplicate nội dung:** 0 dòng dư; suy ra 0 nhóm trong phạm vi kiểm tra
- **Duplicate khóa dòng:** chưa xác định số nhóm và số dòng dư, do chưa xác nhận grain và chưa có kết quả kiểm tra

### Problem & Handle

- **Dự kiến:** Chuẩn hóa DType cho phù hợp các filde. Thêm khóa chi tiết đơn hàng. Kiểm tra nhóm `(order_id, product_id)`

## 6. SRC06 — `raw.distributor_master`

- **File:** `SRC06_distributor_master.csv`.
- **Batch:** `4ba2e0c0-9434-44d3-bcdc-b601fde9186d`.
- **Phạm vi:** batch hiển thị trong output; 138 dòng × 14 cột.
- **Grain dự kiến:** một dòng cho một nhà phân phối trong snapshot; khóa distributor_id.

### Kết quả đã quan sát

| Cột | Vai trò | `null_rows` | `empty_rows` | `space_rows` | `missing_rows` | `missing_pct` | `distinct_nonmissing` |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `distributor_id` | Khóa nhà phân phối | 0 | 0 | 0 | 0 | 0,00% | 138 |
| `assigned_supervisor_id` | Mã giám sát cần đối chiếu | 0 | 0 | 0 | 0 | 0,00% | 9 |

- Tất cả 14 cột có `missing_rows = 0` và `missing_pct = 0,00%`.
- **Duplicate nội dung:** 0 dòng dư; suy ra 0 nhóm trong phạm vi kiểm tra
- **Duplicate khóa:** suy ra 0 nhóm và 0 dòng dư theo `distributor_id` trong batch.

### Problem & Handle

> - **Note:** Trong bảng distributor chauw có efective_from nên set up theo thời gian trong bảng dim_employee baseline_effective_from ='2024-01-01'

## 7. SRC07 — `raw.employee_master`

### Kết quả đã quan sát

| Cột | Vai trò | `null_rows` | `empty_rows` | `space_rows` | `missing_rows` | `missing_pct` | `distinct_nonmissing` |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `employee_id` | Khóa nhân viên trong snapshot | 0 | 0 | 0 | 0 | 0,00% | 114 |
| `version` | Thành phần lịch sử cần xác nhận | 0 | 0 | 0 | 0 | 0,00% | Không ghi: vùng ảnh bị che |
| `effective_date` | Thành phần lịch sử cần xác nhận | 0 | 0 | 0 | 0 | 0,00% | Không ghi: vùng ảnh bị che |
| `resign_date` | Thuộc tính cần lưu ý | 0 | 114 | 0 | 114 | 100,00% | Không ghi từ ảnh |
| `transfer_note` | Thuộc tính cần lưu ý | 0 | 114 | 0 | 114 | 100,00% | Không ghi từ ảnh |

- Các cột còn lại có missing_rows = 0 và missing_pct = 0,00%.
- **Duplicate nội dung:** 0 dòng dư; suy ra 0 nhóm trong phạm vi kiểm tra của script.
- **Duplicate khóa:** suy ra 0 nhóm và 0 dòng dư theo employee_id trong batch;

### Problem & Handle

- **Đã phát hiện:** resign_date và transfer_note rỗng ở toàn bộ 114 dòng
- **Dự kiến:** chuẩn hóa hai trường rỗng thành NULL, chuản hóa định dạng date_of_birth, join_date, effective_date

> - **Note:** trong bảng sales_target_plan có 5 nhân viên thay đổi vùng/nhóm' -> bổ sung vào bảng dim_employee
> - **Note:** kiểm tra thêm employee_id trong gia đoạn effective_from - effective_to có anmwf trong order_daate cảu order_id không
> - **Note:** khi thêm vậy sẽ bị trùng cần thêm employee_key

## 8. SRC08 — `raw.territory_mapping`

- **File:** `SRC08_territory_mapping.xlsx`.
- **Batch:** `214cbd7f-23c1-4860-96d0-beca2796ada5`.
- **Phạm vi:** batch hiển thị trong output; 1843 dòng × 8 cột.
- **Grain dự kiến:** một bản ghi phân công khách hàng cho nhân viên trong một khoảng hiệu lực; cần xác nhận bằng tài liệu nghiệp vụ. territory_id là khóa ứng viên trong snapshot.

### Kết quả đã quan sát

| Cột | Vai trò | `null_rows` | `empty_rows` | `space_rows` | `missing_rows` | `missing_pct` | `distinct_nonmissing` |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `territory_id` | Khóa bản ghi phân công | 0 | 0 | 0 | 0 | 0,00% | 1843 |
| `employee_id` | Mã nhân viên cần đối chiếu | 0 | 0 | 0 | 0 | 0,00% | 102 |
| `customer_id` | Mã khách hàng cần đối chiếu | 0 | 0 | 0 | 0 | 0,00% | 1843 |
| `effective_date` | Mốc bắt đầu hiệu lực | 0 | 0 | 0 | 0 | 0,00% | 1 |
| `expiry_date` | Mốc kết thúc hiệu lực | 0 | 0 | 0 | 0 | 0,00% | 1 |
| `version` | Phiên bản | 0 | 0 | 0 | 0 | 0,00% | 1 |

- Tất cả 8 cột có missing_rows = 0 và missing_pct = 0,00%.
- **Duplicate nội dung:** 0 dòng dư; suy ra 0 nhóm trong phạm vi kiểm tra 
- **Duplicate khóa:** suy ra 0 nhóm và 0 dòng dư theo territory_id trong batch. customer_id cũng duy nhất trong batch

### Problem & Handle 

- **Đã phát hiện:** effective_date, expiry_date đều chỉ có 1 giá trị phân biệt.
- **Dự kiến:** Chuẩn hóa Dtype

## 9. SRC09 — `raw.return_transactions`

- **File:** `SRC09_return_transactions.csv`.
- **Batch:** `6df21728-9cd4-41f0-adc3-4e8145acda8f`.
- **Phạm vi:** batch hiển thị trong output; 3665 dòng × 14 cột.
- **Grain quan sát:** return_id duy nhất trong batch. Mỗi dòng có product_id; cần xác nhận một mã trả hàng có được chứa nhiều sản phẩm trong các batch khác hay không.

### Kết quả đã quan sát

| Cột | Vai trò | `null_rows` | `empty_rows` | `space_rows` | `missing_rows` | `missing_pct` | `distinct_nonmissing` |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `return_id` | Khóa ứng viên giao dịch trả hàng | 0 | 0 | 0 | 0 | 0,00% | 3665 |
| `original_order_id` | Mã đơn gốc cần đối chiếu | 0 | 0 | 0 | 0 | 0,00% | 3564 |
| `customer_id` | Mã khách hàng cần đối chiếu | 0 | 0 | 0 | 0 | 0,00% | 967 |
| `employee_id` | Mã nhân viên cần đối chiếu | 0 | 0 | 0 | 0 | 0,00% | 106 |
| `product_id` | Mã sản phẩm cần đối chiếu | 0 | 0 | 0 | 0 | 0,00% | 92 |

- Tất cả 14 cột có `missing_rows = 0` và `missing_pct = 0,00%`.
- **Duplicate nội dung:** 0 dòng dư; suy ra 0 nhóm trong phạm vi kiểm tra
- **Duplicate khóa:** suy ra 0 nhóm và 0 dòng dư theo `return_id` trong batch.
- `original_order_id` là `order_id` 

### Problem & Handle

- **Dự kiến:** Chuẩn hóa Dtype

## 10. SRC10 — `raw.promotion_program`

- **File:** `SRC10_promotion_program.xlsx`.
- **Batch:** `ad0afb01-0568-46c2-9c81-e9b0f5ebfa39`.
- **Phạm vi:** batch trong output văn bản được cung cấp; 40 dòng × 14 cột.
- **Grain dự kiến:** một dòng cho một chương trình khuyến mãi; khóa promotion_id.

### Kết quả đã quan sát

| Cột | Vai trò | `null_rows` | `empty_rows` | `space_rows` | `missing_rows` | `missing_pct` | `distinct_nonmissing` |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `promotion_id` | Khóa chương trình | 0 | 0 | 0 | 0 | 0,00% | 40 |
| `created_by` | Người/tài khoản tạo cần xác định | 0 | 0 | 0 | 0 | 0,00% | 40 |

- Tất cả 14 cột có missing_rows = 0 và missing_pct = 0,00%.
- **Duplicate nội dung:** 0 dòng dư; suy ra 0 nhóm trong phạm vi kiểm tra
- **Duplicate khóa:** suy ra 0 nhóm và 0 dòng dư theo promotion_id trong batch.

### Problem & Handle

- **Dự kiến:** Chuẩn hóa Dtype

