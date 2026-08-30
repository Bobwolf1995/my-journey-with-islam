<?php

return [
    'default_currency' => env('PAYMENT_CURRENCY', 'USD'),

    'gateway' => env('PAYMENT_GATEWAY', 'stripe'),

    'stripe' => [
        'key' => env('STRIPE_KEY'),
        'secret' => env('STRIPE_SECRET'),
        'webhook_secret' => env('STRIPE_WEBHOOK_SECRET'),
    ],

    'test_mode' => env('PAYMENT_TEST_MODE', true),
];