-- Extensions/Pragmas (ปลอดภัยถ้ารันซ้ำ)
CREATE EXTENSION IF NOT EXISTS citext;

-- ฟังก์ชัน trigger สำหรับอัปเดต updated_at อัตโนมัติ
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END; $$ LANGUAGE plpgsql;
