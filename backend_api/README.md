# Backend API - رحلتي مع الإسلام

هذا المجلد يحتوي على Backend API ولوحة الإدارة الخاصة بمنصة "رحلتي مع الإسلام".

## التقنية

- Laravel 13
- PHP 8.3+
- Laravel Sanctum
- Spatie Laravel Permission
- Laravel Filament
- MySQL أو PostgreSQL

## المسؤوليات

Backend مسؤول عن:

- المصادقة وتسجيل الدخول
- إدارة المستخدمين
- الأدوار والصلاحيات
- المسارات التعليمية
- الدورات والدروس
- إكمال الدروس والتقدم
- المهام اليومية والأسبوعية
- المرشدين
- المحادثات
- مكتبة المعرفة
- الطلبات والمدفوعات
- العمولات والأرباح
- الأوسمة والرتب
- المجتمع
- الإشعارات
- لوحة الإدارة

## التثبيت

بعد إنشاء مشروع Laravel أو تجهيز الملفات:

```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan db:seed
php artisan serve