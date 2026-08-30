<?php

use Illuminate\Foundation\Console\ClosureCommand;
use Illuminate\Support\Facades\Artisan;

Artisan::command('app:about', function (): void {
    /** @var ClosureCommand $this */
    $this->info('رحلتي مع الإسلام API');
    $this->line('Backend service for the mobile app and admin dashboard.');
})->purpose('Show application information');