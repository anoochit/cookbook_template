---
name: mermaid-figures
description: สร้างและอัปเดตไดอะแกรมของหนังสือ ADK-Rust Cookbook โดยแยก Mermaid source ออกเป็นไฟล์ .mmd แล้วเรนเดอร์เป็นภาพ PNG ที่ฝังในบท ต้องใช้เมื่อเพิ่ม แก้ไข หรือตรวจสอบไดอะแกรมใน chapters/
version: "1.0.0"
license: MIT
compatibility: ต้องมี Node.js และ mermaid-cli (@mermaid-js/mermaid-cli) ติดตั้งแบบ global
tags: [documentation, mermaid, diagram, images, ebook]
triggers: ["*.md", "images/*", "chapters/*"]
references:
  - references/mermaid-config.json
---

# Mermaid Figures Skill

ทักษะนี้ควบคุมวิธีสร้างไดอะแกรมในหนังสือ **ปั้น AI Agent ด้วย ADK-Rust** ให้เป็นภาพ PNG
ที่ฝังอยู่ในบทจริง แทนการใช้บล็อก ` ```mermaid ` แบบ inline

## กติกาที่ห้ามละเมิด

1. **ห้ามใส่บล็อก ` ```mermaid ` ในไฟล์บท** — บทต้องอ้างอิงภาพ PNG เท่านั้น
2. **ชื่อไฟล์ต้องผูกกับเลขไดอะแกรม** — `images/figX-Y.png` = บท X ไดอะแกรม Y (แหล่ง Mermaid อยู่ที่ `images/fig-X-Y.mmd`)
3. **ต้องมี alt text ที่บรรยายไดอะแกรม และย่อหน้าอธิบายทันทีใต้ภาพเสมอ**:
   ```markdown
   ![<คำบรรยายไดอะแกรม>](images/fig1-1.png)

   <ย่อหน้าอธิบายกลไก ขั้นตอน และความสัมพันธ์ของส่วนประกอบในภาพ>
   ```
   - alt text ต้องบอกว่าภาพนี้แสดงอะไร ห้ามใช้คำนำหน้ากว้าง ๆ เช่น `แผนภาพ...` อย่างเดียว
   - **ไม่ใช้ caption line** (เช่น `*ไดอะแกรมที่ 1.1: ...*`) อีกต่อไป
4. **สไตล์ภาพต้องเป็น flowchart แนวตั้ง** (`flowchart TD` / `graph TD`) เพราะภาพแนวนอน
   จะถูกย่อจนอ่านไม่ออกบนหน้าจอ e-reader

## โครงสร้างไฟล์

| ไฟล์ | บทบาท |
|---|---|
| `images/figN-N.mmd` | Mermaid source ของไดอะแกรม N.N (แก้ไขที่นี่เมื่อเปลี่ยนภาพ) |
| `images/figN-N.png` | ภาพเรนเดอร์ที่บทอ้างอิง (สร้างจาก `.mmd`) |
| `references/mermaid-config.json` | ธีม mermaid-cli (ฟอนต์ Google Sans, พื้นหลังขาว) |

> ชื่อไฟล์สองแบบต่างกันโดยเจตนา: `.mmd` ใช้ `fig-N-N.mmd` (มีขีดคั่น) ส่วน `.png`
> ใช้ `figN-N.png` (ไม่มีขีดคั่น) เพื่อให้สอดคล้องกับรูปแบบเดิมของหนังสือ

## เพิ่มไดอะแกรมใหม่

1. เขียนบล็อก ` ```mermaid ` ในบทเป้าหมาย แล้วเขียน image reference พร้อม alt text
   ที่บรรยายไดอะแกรมไว้ใต้บล็อก พร้อมย่อหน้าอธิบายใต้ภาพ:
   ```markdown
   ```mermaid
   flowchart TD
       A[...] --> B[...]
   ```

   ![<คำบรรยายไดอะแกรม>](images/fig1-5.png)

   <ย่อหน้าอธิบายกลไก ขั้นตอน และความสัมพันธ์ของส่วนประกอบในภาพ>
   ```
2. ดึงบล็อกออกเป็นไฟล์ `.mmd` (image reference ที่เขียนไว้แล้วจะถูกคงไว้):
   ```bash
   node .agents/skills/mermaid-figures/scripts/extract-mermaid.js --dry-run   # ดูตัวอย่างก่อน
   node .agents/skills/mermaid-figures/scripts/extract-mermaid.js
   ```
3. เรนเดอร์ภาพ:
   ```bash
   node .agents/skills/mermaid-figures/scripts/render-mermaid.js --jobs 4
   ```

## แก้ไขไดอะแกรมที่มีอยู่แล้ว

1. แก้ `images/fig-N-N.mmd` โดยตรง (ห้ามแก้ไฟล์ `.png`)
2. เรนเดอร์ใหม่ — เรนเดอร์เฉพาะบทที่แก้ไขเพื่อความรวดเร็ว:
   ```bash
   node .agents/skills/mermaid-figures/scripts/render-mermaid.js --chapter 1 --jobs 4
   ```

   ตัวเลือกการกรอง:

   | ตัวเลือก | ความหมาย |
   |---|---|
   | (ไม่ระบุ) | เรนเดอร์ทุกไดอะแกรมในหนังสือ |
   | `--chapter N` | เรนเดอร์เฉพาะบทที่ N เช่น `--chapter 1` |
   | `--figure N.M` | เรนเดอร์เฉพาะไดอะแกรม N.M เช่น `--figure 1.2` |
   | `--jobs N` | จำนวนการเรนเดอร์พร้อมกัน (ค่าเริ่มต้น 4) |

### ความละเอียดภาพ (สำคัญสำหรับ PDF/EPUB)

`references/mermaid-config.json` ตั้ง `useMaxWidth: false` เพื่อให้แต่ละไดอะแกรมถูกเรนเดอร์
ที่ **สัดส่วนตามธรรมชาติ** (ไม่ถูกยืดให้เต็มกรอบ 1600px) แล้วขยายด้วย `--scale 4`
ให้ได้ภาพความละเอียดสูงพอสำหรับงานพิมพ์ (~200 DPI เมื่อย่อเต็งความกว้างหน้า)

> ถ้าเปลี่ยน `useMaxWidth` กลับเป็น `true` ต้องเพิ่ม `--scale` ให้สูงพอด้วย
> ไม่เช่นนั้นความละเอียดภาพจะลดลงเหลือครึ่งหนึ่ง

## ตรวจสอบความถูกต้อง

```bash
node .agents/skills/mermaid-figures/scripts/verify-figures.js
```

สคริปต์นี้ตรวจว่า ทุก image reference มีไฟล์ `.png` และ `.mmd` ครบ, alt text บรรยายไดอะแกรม
จริง, มีย่อหน้าอธิบายอยู่ใต้ภาพ, ไม่มี caption line ค้างเก่า และไม่มีบล็อก mermaid เหลือค้างในบท

## ข้อควรระวังด้านไวยากรณ์ Mermaid

ข้อความในป้ายที่มี `{`, `}` หรือ `#[` **ต้องครอบด้วย double quotes** ไม่เช่นนั้น
parser จะตีความเป็น shape แล้ว render ไม่ผ่าน

```mermaid
flowchart TD
    Good["Resolve {user_name} from Session State"]
    AlsoGood["#[entrypoint] fn process_workflow"]
    Bad[Resolve {user_name} from Session State]
```

## สร้างหนังสือหลังแก้ไข

```bash
make gen
```

ผลลัพธ์อยู่ที่ `build/ebook_epub3.epub` และ `build/output.pdf`
