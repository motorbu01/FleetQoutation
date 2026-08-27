# Template ไฟล์ users.csv / users.xlsx

สร้างไฟล์ `users.csv` (หรือ `users.xlsx`) ในโฟลเดอร์ `supabase\`
โดยมี **header แถวแรก** และข้อมูล user ตั้งแต่แถว 2 เป็นต้นไป

## Columns (ตามลำดับ)

| คอลัมน์ | Header | ตัวอย่าง | หมายเหตุ |
|---|---|---|---|
| A | username | tanuser01 | ห้ามมี @ หรือ space, ตัวเล็กแนะนำ |
| B | password | Pass1234! | ต้องมีตัวใหญ่+ตัวเล็ก+ตัวเลข อย่างน้อย 6 ตัว |
| C | display_name | ธนดล รักดี | ชื่อที่แสดงในระบบ |
| D | role | lv1 | ต้องเป็น lv1 / lv2 / admin เท่านั้น |
| E | issuer_name | ธนดล รักดี | ชื่อผู้ออกงาน (auto-fill ในฟอร์ม) ถ้าว่างจะใช้ display_name แทน |
| F | issuer_branch | ฝ่ายขาย 1 | ฝ่าย/สาขา ถ้าว่างได้ |

## ตัวอย่างข้อมูล

| username | password | display_name | role | issuer_name | issuer_branch |
|---|---|---|---|---|---|
| tanuser01 | Pass1234! | ธนดล รักดี | lv1 | ธนดล รักดี | ฝ่ายขาย 1 |
| tanuser02 | Pass5678! | สมชาย กาญจน์ | lv2 | สมชาย กาญจน์ | ฝ่ายขาย 2 |
| tanuser03 | Pass9012! | วิภา สุขใจ | lv1 | วิภา สุขใจ | สาขาเชียงใหม่ |

## วิธีรัน

1. ใส่ Service Role Key ใน `import_users.ps1` บรรทัด `$SERVICE_ROLE_KEY`
2. วางไฟล์ `users.csv` ในโฟลเดอร์ `supabase\`
3. เปิด PowerShell ใน Kiro แล้วรัน:

```powershell
cd "D:\Report Tan\Project Quotation\JSON\supabase"
.\import_users.ps1
```

## หมายเหตุ
- Script จะสร้าง email เป็น `username@dhipaya.local` อัตโนมัติ
- `issuer_name` ถ้าว่างใน CSV → ระบบจะใช้ `display_name` แทนอัตโนมัติ
- `issuer_branch` ถ้าว่างจะบันทึกเป็น null และไม่ auto-fill ช่องสาขาในฟอร์ม
- ถ้า user มีอยู่แล้วจะข้ามไป (ไม่ error)
- รัน import ซ้ำได้อย่างปลอดภัย
- user ที่มีอยู่แล้วสามารถอัปเดต issuer_name/issuer_branch ได้ผ่าน Admin Panel
