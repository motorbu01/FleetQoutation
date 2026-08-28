# Motor Insurance Quotation — Backlog

อัปเดตล่าสุด: 28 ส.ค. 69

---

## 🔴 ค้างจากที่คุยไว้

| # | รายการ | รายละเอียด |
|---|--------|-----------|
| 1 | Export รายงาน Follow-up | เพิ่มปุ่ม Export Excel ใน Admin → Reports สำหรับ quote_followup (user, เลขใบ, ผล, เหตุผล, วันที่) |
| 2 | Admin note ตอน Reset | ให้ admin กรอก note ก่อน reset เพื่อแจ้ง user ผ่าน notification ว่า reset เพราะอะไร |

---

## 🟡 อยากทำเพิ่ม (Nice to have)

| # | รายการ | รายละเอียด |
|---|--------|-----------|
| 3 | Filter ใน Admin tab คำขอแก้ไข | filter ตาม user / วันที่ / สถานะ pending/resolved |
| 4 | สถิติ Follow-up | แสดง % ตกลง vs ไม่ทำ แยกตาม user หรือช่วงเวลา |
| 5 | เหตุผล Follow-up หลายเหตุผล | ตอนนี้เลือกได้ 1 เหตุผล อาจเพิ่ม multi-select ถ้าจำเป็น |

---

## 🔵 ต้องทดสอบ / ตรวจสอบ

| # | รายการ | รายละเอียด |
|---|--------|-----------|
| 6 | Template Excel import (accessoryAmount) | เพิ่ม column "อุปกรณ์ตกแต่งเพิ่มเติม (บาท)" แล้ว ยังไม่ได้ทดสอบ import กลับว่าค่าเข้าฟอร์มถูกต้อง |
| 7 | Notification badge user side | ทดสอบ flow ครบ: user ขอแก้ → admin reset → user เห็น 🔔 และกดแล้วเปิด follow-up modal |

---

## ✅ ทำเสร็จแล้ว (อ้างอิง)

- Template Excel import: เพิ่ม column accessoryAmount
- Follow-up Modal: list+search, ส่วนบน=ค้าง, ส่วนล่าง=บันทึกแล้ว, lock row
- Notification System: bell badge + poll 5 นาที + modal อ่าน noti
- Admin tab คำขอแก้ไข: badge แดง, ตาราง pending requests, ปุ่ม Reset + ส่ง noti กลับ user
- SQL Schema: followup_reasons, quote_followup, notifications, followup_requests
