# دليل النشر - رحلتي مع الإسلام

هذا الملف يوضح خطة نشر مشروع "رحلتي مع الإسلام" بعد الانتهاء من التطوير والاختبار.

## أجزاء المشروع

يتكون المشروع من:

- تطبيق Flutter Android
- Backend API Laravel
- لوحة إدارة Laravel Filament
- قاعدة بيانات
- تخزين ملفات وفيديوهات
- إشعارات Push Notifications
- نظام دفع

## نشر Backend

يمكن نشر Laravel على:

- VPS
- DigitalOcean
- AWS
- Laravel Forge
- Ploi
- Render
- Railway

## متطلبات السيرفر

- PHP 8.2 أو أحدث
- Composer
- Nginx أو Apache
- MySQL أو PostgreSQL
- Redis اختياري للـ queues/cache
- Supervisor لتشغيل queues
- SSL Certificate
- Storage disk

## خطوات نشر Laravel

الأوامر العامة:

```bash
composer install --optimize-autoloader --no-dev
php artisan key:generate
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan storage:link