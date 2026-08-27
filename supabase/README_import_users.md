# วิธีเพิ่ม User เข้าระบบ

## ขั้นตอน (3 ขั้น)

### 1. แก้ไขไฟล์ users.csv

เปิดไฟล์ `supabase\users.csv` แล้วเพิ่ม user ที่ต้องการ

| column | ความหมาย | ตัวอย่าง |
|---|---|---|
| username | ชื่อผู้ใช้ (ห้ามมี space) | `somchai` |
| password | รหัสผ่านเริ่มต้น | `Pass1234!` |
| display_name | ชื่อที่แสดงในระบบ | `สมชาย ใจดี` |
| role | สิทธิ์ (`admin` / `lv2` / `lv1`) | `lv1` |
| issuer_name | ชื่อผู้ออกงาน (auto-fill ในฟอร์ม) | `สมชาย ใจดี` |
| issuer_branch | ฝ่าย/สาขา | `ฝ่ายประกันภัยรถยนต์` |

> email จะถูกสร้างอัตโนมัติเป็น `username@dhipaya.co.th`
> ถ้า issuer_name ว่าง ระบบจะใช้ display_name แทน

**ตัวอย่าง:**
```
username,password,display_name,role,issuer_name,issuer_branch
somchai,Pass1234!,สมชาย ใจดี,lv1,สมชาย ใจดี,ฝ่ายประกันภัยรถยนต์
malee,Pass5678!,มาลี รักดี,lv2,มาลี รักดี,สาขาเชียงใหม่
```

---

### 2. รัน Script

**วิธีที่ 1 — เปิด PowerShell จาก File Explorer (แนะนำ)**
1. เปิด File Explorer → เข้าโฟลเดอร์ `supabase`
2. คลิกที่ address bar ด้านบน → พิมพ์ `powershell` → กด Enter
3. รันคำสั่ง:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; .\import_users.ps1
```

**วิธีที่ 2 — เปิด PowerShell จากที่ไหนก็ได้**
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; .\import_users.ps1
```
> ต้องอยู่ใน folder `supabase` ก่อน ถ้ายังอยู่ใน `JSON` ให้ `cd supabase` ก่อน 1 ครั้ง

---

### 3. ตรวจสอบผลลัพธ์

ผลลัพธ์ที่ควรเห็น:
```
Found 2 users
  somchai (สมชาย ใจดี / ฝ่ายประกันภัยรถยนต์) ... OK
  malee   (มาลี รักดี / สาขาเชียงใหม่)         ... OK
Done - Success: 2  Failed: 0
```

- **OK** — เพิ่มสำเร็จ
- **SKIP** — มี user นี้อยู่แล้ว (ข้ามไป)
- **FAIL** — เกิดข้อผิดพลาด (ดู error message)

---

## หมายเหตุ

- รัน script ซ้ำได้อย่างปลอดภัย — user ที่มีอยู่แล้วจะถูก **อัปเดต** ข้อมูล (display_name, role, issuer_name, issuer_branch) ไม่ได้สร้างซ้ำ
- แก้ข้อมูล issuer_name / issuer_branch ของ user ที่มีอยู่แล้วได้ผ่าน **Admin Panel** ในเว็บได้เลย ไม่ต้องรัน script
