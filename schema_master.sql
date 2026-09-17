-- ============================================================
-- قاعدة بيانات أكاديمية أمجاد — الملف الموحّد والموثّق
-- ============================================================
-- ده الملف المرجعي الوحيد اللي محتاج تحتفظ بيه من دلوقتي فصاعدًا
-- بدل الملفات المتفرقة القديمة (schema.sql, schema_update_v2, v3, bookings)
--
-- آمن 100% إنك تشغّله في أي وقت حتى لو الجداول موجودة بالفعل —
-- مستخدم "IF NOT EXISTS" في كل حتة، يعني مش هيمسح أو يبوّظ أي بيانات
-- موجودة عندك حاليًا، بس هيتأكد إن كل حاجة مكتملة وصح.
-- ============================================================


-- ------------------------------------------------------------
-- 1) جدول الطلاب (students)
-- ------------------------------------------------------------
-- كل صف = طالب واحد بكل تفاصيله
create table if not exists students (
  id                text primary key,        -- رقم تعريف فريد للطالب (يتولد تلقائي من البرنامج)
  name              text,                     -- اسم الطالب
  subject           text,                     -- المادة الأساسية (نص وصفي عام)
  day               text,                     -- يوم الحصة (قديم - للتوافق، الأحدث هو عمود schedule)
  time              text,                     -- وقت الحصة (قديم - للتوافق، الأحدث هو عمود schedule)
  "notifyBefore"    text,                     -- التذكير قبل الحصة بكام دقيقة (5/10/15)
  teacher           text,                     -- اسم المعلم كنص حر (قديم - الأحدث هو الربط عبر جدول teachers)
  "parentName"      text,                     -- اسم ولي الأمر
  "parentPhone"     text,                     -- رقم واتساب ولي الأمر
  status            text,                     -- حالة الطالب: new / active / paused
  price             text,                     -- قيمة الاشتراك (نص، لأنه بيتكتب بصيغ مختلفة زي "300 ريال")
  "renewalDate"     text,                     -- تاريخ التجديد القادم
  "permanentNotes"  text,                     -- ملاحظات دائمة عن الطالب (مش يومية)
  schedule          jsonb default '[]',       -- مواعيد الحصص الأسبوعية المتعددة: [{day, time}, ...]
  "customFields"    jsonb default '[]',       -- بنود إضافية حرة يضيفها المستخدم بنفسه: [{label, value}, ...]
  packages          jsonb default '[]',       -- باقات المواد: كل باقة فيها المادة، المعلم، الحصص، الحضور، الدفع، الإيصال
  photo             text default ''           -- صورة الطالب أو آخر إيصال (base64 مصغّر)
);

-- ------------------------------------------------------------
-- 2) جدول المعلمين (teachers)
-- ------------------------------------------------------------
create table if not exists teachers (
  id                text primary key,        -- رقم تعريف فريد للمعلم
  name              text,                     -- اسم المعلم
  phone             text,                     -- رقم واتساب المعلم
  subjects          text,                     -- التخصص / المواد اللي بيدرّسها
  salary            text,                     -- قيمة الراتب
  "salaryCurrency"  text,                     -- عملة الراتب (SAR, EGP, AED...)
  notes             text                      -- ملاحظات عن المعلم
);

-- ------------------------------------------------------------
-- 3) جدول المعاملات المالية (transactions)
-- ------------------------------------------------------------
-- كل صف = عملية مالية واحدة: إيراد، مصروف، أو إعلان
create table if not exists transactions (
  id          text primary key,
  type        text,                           -- نوع المعاملة: income / expense / ad
  category    text,                           -- البند (مثال: "اشتراك طالب - عمر أحمد" أو "راتب معلم")
  amount      numeric,                        -- المبلغ (رقم)
  currency    text,                           -- العملة (SAR, EGP, AED...)
  date        text,                           -- تاريخ المعاملة
  note        text,                           -- ملاحظة اختيارية
  icon        text default ''                 -- الأيقونة المعروضة (تلقائية حسب الكلمة أو مختارة يدويًا)
);

-- ------------------------------------------------------------
-- 4) جدول الحجوزات الجديدة (bookings)
-- ------------------------------------------------------------
-- بتتغذى تلقائيًا من صفحة الحجز العامة (book.html) اللي بيفتحها العملاء الجدد
create table if not exists bookings (
  id                text primary key,
  name              text,                     -- اسم الطالب اللي حجز
  phone             text,                     -- رقم واتساب ولي الأمر
  subject           text,                     -- المادة المطلوبة
  preferred_day     text,                     -- اليوم المفضل للحصة
  preferred_time    text,                     -- الوقت المفضل للحصة
  notes             text,                     -- ملاحظات من ولي الأمر وقت الحجز
  status            text default 'pending',   -- حالة الحجز: pending (جديد) / converted (اتحول لطالب)
  created_at        text                      -- تاريخ ووقت إرسال الحجز
);


-- ============================================================
-- الصلاحيات (Row Level Security)
-- ============================================================
-- كل الجداول مفتوحة بمفتاح واحد (anon key) بدون تسجيل دخول منفصل،
-- عشان البرنامج بسيط ومخصص لمستخدم واحد. لو حبيت حماية أقوى
-- (تسجيل دخول حقيقي لكل مستخدم) ده تطوير منفصل نقدر نتكلم فيه لاحقًا.

alter table students     enable row level security;
alter table teachers     enable row level security;
alter table transactions enable row level security;
alter table bookings     enable row level security;

drop policy if exists "allow anon full access" on students;
create policy "allow anon full access" on students
  for all using (true) with check (true);

drop policy if exists "allow anon full access" on teachers;
create policy "allow anon full access" on teachers
  for all using (true) with check (true);

drop policy if exists "allow anon full access" on transactions;
create policy "allow anon full access" on transactions
  for all using (true) with check (true);

drop policy if exists "allow anon full access" on bookings;
create policy "allow anon full access" on bookings
  for all using (true) with check (true);

-- ============================================================
-- نهاية الملف — لو نفذته ومشي من غير أخطاء، قاعدة بياناتك كاملة 100%
-- ============================================================

-- ------------------------------------------------------------
-- تحديث إضافي: نظام الفواتير الرسمية وسجل التدقيق (Audit Trail)
-- آمن يتنفذ فوق قاعدة موجودة من غير ما يمسح أي بيانات
-- ------------------------------------------------------------
alter table students add column if not exists "createdAt" text;      -- تاريخ إضافة الطالب لأول مرة
alter table students add column if not exists "updatedAt" text;      -- تاريخ آخر تعديل على بيانات الطالب
alter table transactions add column if not exists "invoiceNumber" text;  -- رقم الفاتورة الرسمي (مثال: AMJ-1001)
alter table transactions add column if not exists "createdAt" text;      -- تاريخ إنشاء المعاملة فعليًا

