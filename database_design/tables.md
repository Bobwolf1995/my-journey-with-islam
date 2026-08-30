# جداول قاعدة البيانات - رحلتي مع الإسلام

هذا الملف يوضح الجداول الأساسية المقترحة للمنصة.  
سيتم تحويل هذه الجداول لاحقًا إلى Laravel Migrations.

## 1. users

جدول المستخدمين الأساسي.

| الحقل | النوع | الوصف |
|---|---|---|
| id | bigint | رقم المستخدم |
| name | string | اسم المستخدم |
| email | string | البريد الإلكتروني |
| phone | string nullable | رقم الهاتف |
| password | string | كلمة المرور المشفرة |
| account_type | enum | user, mentor, teacher, supervisor, admin |
| status | enum | active, inactive, suspended |
| email_verified_at | timestamp nullable | تاريخ تفعيل البريد |
| last_login_at | timestamp nullable | آخر تسجيل دخول |
| created_at | timestamp | تاريخ الإنشاء |
| updated_at | timestamp | تاريخ التحديث |
| deleted_at | timestamp nullable | حذف ناعم |

## 2. profiles

ملف المستخدم الشخصي.

| الحقل | النوع | الوصف |
|---|---|---|
| id | bigint | رقم الملف |
| user_id | foreignId | المستخدم |
| avatar | string nullable | صورة المستخدم |
| bio | text nullable | نبذة |
| country | string nullable | الدولة |
| city | string nullable | المدينة |
| language | string | اللغة المفضلة |
| current_level_id | foreignId nullable | الرتبة الحالية |
| total_points | integer | مجموع النقاط |
| created_at | timestamp | تاريخ الإنشاء |
| updated_at | timestamp | تاريخ التحديث |

## 3. roles

الأدوار.

| الحقل | النوع | الوصف |
|---|---|---|
| id | bigint | رقم الدور |
| name | string | اسم الدور البرمجي |
| display_name_ar | string | الاسم العربي |
| display_name_en | string nullable | الاسم الإنجليزي |
| created_at | timestamp | تاريخ الإنشاء |
| updated_at | timestamp | تاريخ التحديث |

## 4. permissions

الصلاحيات.

| الحقل | النوع | الوصف |
|---|---|---|
| id | bigint | رقم الصلاحية |
| name | string | اسم الصلاحية البرمجي |
| display_name_ar | string | الاسم العربي |
| group | string nullable | مجموعة الصلاحية |
| created_at | timestamp | تاريخ الإنشاء |
| updated_at | timestamp | تاريخ التحديث |

## 5. levels

رتب المستخدمين.

| الحقل | النوع | الوصف |
|---|---|---|
| id | bigint | رقم الرتبة |
| name_ar | string | اسم الرتبة بالعربية |
| name_en | string nullable | اسم الرتبة بالإنجليزية |
| slug | string | معرف الرتبة |
| required_points | integer | النقاط المطلوبة |
| sort_order | integer | ترتيب الرتبة |
| icon | string nullable | أيقونة الرتبة |
| created_at | timestamp | تاريخ الإنشاء |
| updated_at | timestamp | تاريخ التحديث |

## 6. badges

الأوسمة.

| الحقل | النوع | الوصف |
|---|---|---|
| id | bigint | رقم الوسام |
| name_ar | string | اسم الوسام |
| name_en | string nullable | الاسم الإنجليزي |
| description_ar | text nullable | الوصف |
| icon | string nullable | أيقونة الوسام |
| badge_type | enum | normal, secret, achievement |
| required_points | integer nullable | النقاط المطلوبة |
| is_active | boolean | حالة الوسام |
| created_at | timestamp | تاريخ الإنشاء |
| updated_at | timestamp | تاريخ التحديث |

## 7. learning_paths

المسارات التعليمية.

| الحقل | النوع | الوصف |
|---|---|---|
| id | bigint | رقم المسار |
| title_ar | string | عنوان المسار |
| title_en | string nullable | العنوان الإنجليزي |
| description_ar | text nullable | الوصف |
| thumbnail | string nullable | صورة المسار |
| sort_order | integer | الترتيب |
| is_active | boolean | حالة النشر |
| created_at | timestamp | تاريخ الإنشاء |
| updated_at | timestamp | تاريخ التحديث |

## 8. courses

الدورات.

| الحقل | النوع | الوصف |
|---|---|---|
| id | bigint | رقم الدورة |
| learning_path_id | foreignId | المسار |
| title_ar | string | عنوان الدورة |
| title_en | string nullable | العنوان الإنجليزي |
| description_ar | text nullable | الوصف |
| thumbnail | string nullable | صورة الدورة |
| level | enum | beginner, intermediate, advanced |
| price | decimal | السعر |
| is_free | boolean | مجانية أم مدفوعة |
| is_published | boolean | حالة النشر |
| sort_order | integer | الترتيب |
| created_at | timestamp | تاريخ الإنشاء |
| updated_at | timestamp | تاريخ التحديث |

## 9. lessons

الدروس.

| الحقل | النوع | الوصف |
|---|---|---|
| id | bigint | رقم الدرس |
| course_id | foreignId | الدورة |
| section_id | foreignId nullable | القسم |
| title_ar | string | عنوان الدرس |
| title_en | string nullable | العنوان الإنجليزي |
| description_ar | text nullable | الوصف |
| summary_ar | text nullable | ملخص الدرس |
| video_url | string nullable | رابط الفيديو |
| audio_url | string nullable | رابط الصوت |
| pdf_url | string nullable | رابط PDF |
| thumbnail | string nullable | صورة مصغرة |
| duration_minutes | integer nullable | مدة الدرس |
| sort_order | integer | ترتيب الدرس |
| is_free | boolean | مجاني أم مدفوع |
| is_published | boolean | منشور أم لا |
| created_at | timestamp | تاريخ الإنشاء |
| updated_at | timestamp | تاريخ التحديث |

## 10. lesson_completions

إكمال الدروس.

| الحقل | النوع | الوصف |
|---|---|---|
| id | bigint | الرقم |
| user_id | foreignId | المستخدم |
| lesson_id | foreignId | الدرس |
| course_id | foreignId | الدورة |
| completed_at | timestamp | تاريخ الإكمال |
| created_at | timestamp | تاريخ الإنشاء |
| updated_at | timestamp | تاريخ التحديث |

## 11. tasks

المهام اليومية والأسبوعية.

| الحقل | النوع | الوصف |
|---|---|---|
| id | bigint | رقم المهمة |
| title_ar | string | عنوان المهمة |
| description_ar | text nullable | وصف المهمة |
| task_type | enum | daily, weekly, practical, learning |
| points | integer | عدد النقاط |
| is_active | boolean | حالة المهمة |
| created_at | timestamp | تاريخ الإنشاء |
| updated_at | timestamp | تاريخ التحديث |

## 12. mentors

المرشدون.

| الحقل | النوع | الوصف |
|---|---|---|
| id | bigint | الرقم |
| user_id | foreignId | حساب المرشد |
| specialization | string nullable | التخصص |
| bio | text nullable | نبذة |
| is_available | boolean | متاح أم لا |
| rating | decimal nullable | التقييم |
| created_at | timestamp | تاريخ الإنشاء |
| updated_at | timestamp | تاريخ التحديث |

## 13. conversations

المحادثات.

| الحقل | النوع | الوصف |
|---|---|---|
| id | bigint | رقم المحادثة |
| type | enum | mentor, support, admin |
| title | string nullable | عنوان المحادثة |
| created_by | foreignId | منشئ المحادثة |
| last_message_at | timestamp nullable | آخر رسالة |
| created_at | timestamp | تاريخ الإنشاء |
| updated_at | timestamp | تاريخ التحديث |

## 14. messages

الرسائل.

| الحقل | النوع | الوصف |
|---|---|---|
| id | bigint | رقم الرسالة |
| conversation_id | foreignId | المحادثة |
| sender_id | foreignId | المرسل |
| body | text nullable | نص الرسالة |
| message_type | enum | text, file, image, audio |
| is_read | boolean | مقروءة أم لا |
| created_at | timestamp | تاريخ الإرسال |
| updated_at | timestamp | تاريخ التحديث |

## 15. library_items

عناصر مكتبة المعرفة.

| الحقل | النوع | الوصف |
|---|---|---|
| id | bigint | رقم العنصر |
| category_id | foreignId nullable | التصنيف |
| title_ar | string | العنوان |
| description_ar | text nullable | الوصف |
| item_type | enum | course, book, pdf, audio, product |
| price | decimal | السعر |
| is_free | boolean | مجاني أم مدفوع |
| file_url | string nullable | رابط الملف |
| thumbnail | string nullable | الصورة |
| is_published | boolean | منشور أم لا |
| created_at | timestamp | تاريخ الإنشاء |
| updated_at | timestamp | تاريخ التحديث |

## 16. orders

الطلبات.

| الحقل | النوع | الوصف |
|---|---|---|
| id | bigint | رقم الطلب |
| user_id | foreignId | المستخدم |
| order_number | string | رقم الطلب |
| subtotal | decimal | المجموع قبل الخصم |
| discount | decimal | الخصم |
| total | decimal | الإجمالي |
| status | enum | pending, paid, failed, cancelled, refunded |
| created_at | timestamp | تاريخ الإنشاء |
| updated_at | timestamp | تاريخ التحديث |

## 17. notifications

الإشعارات.

| الحقل | النوع | الوصف |
|---|---|---|
| id | bigint | رقم الإشعار |
| user_id | foreignId nullable | المستخدم |
| title_ar | string | عنوان الإشعار |
| body_ar | text | نص الإشعار |
| type | string | نوع الإشعار |
| data | json nullable | بيانات إضافية |
| read_at | timestamp nullable | تاريخ القراءة |
| created_at | timestamp | تاريخ الإنشاء |
| updated_at | timestamp | تاريخ التحديث |

## ملاحظة

هذه ليست كل الحقول النهائية، لكنها النسخة الأولية المنظمة التي سنبني عليها.  
عند كتابة Laravel Migrations سنضيف المفاتيح الأجنبية، الفهارس، والحذف الناعم حسب الحاجة.