BOX CONTROLLER - app iPhone gửi cảm biến + nút âm lượng cho phone_boxing.py

1) Tạo repo GitHub mới, upload TOÀN BỘ thư mục này (nhớ cả thư mục ẩn .github).
2) Tab Actions -> "Build IPA" chạy xong -> tải artifact BoxController-ipa -> giải nén ra BoxController.ipa
3) Chuyển sang iPhone -> mở bằng TrollStore -> Install.
4) PC: python phone_boxing.py  (in ra IP của PC)
5) iPhone cùng Wi-Fi với PC -> mở app, nhập IP, BẮT ĐẦU, cho phép "Mạng cục bộ".
6) Làm theo hướng dẫn hiện trên màn hình điện thoại (hiệu chỉnh ~20 giây).
7) Vol+ = đi trái (A), Vol- = đi phải (D). Đổi việc của nút trong phone_boxing.py (VOL_UP_ACTION / VOL_DOWN_ACTION).
