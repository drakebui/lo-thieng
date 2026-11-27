extends Control

# Stub giữ tương thích cho node ForgeBookUI trong scenes/forge/ForgeSession.tscn.
# ForgeSessionUI._ready() tự gọi queue_free() node này ngay khi khởi chạy.
# Có thể xóa hẳn tệp này sau khi gỡ node ForgeBookUI khỏi ForgeSession.tscn trong Godot Editor.
