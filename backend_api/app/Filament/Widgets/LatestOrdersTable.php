<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;

class LatestOrdersTable extends TableWidget
{
    protected int | string | array $columnSpan = 'full';

    public function table(Table $table): Table
    {
        return $table
            ->heading('آخر الطلبات')
            ->query(
                Order::query()
                    ->with('user')
                    ->latest('created_at')
                    ->limit(5)
            )
            ->paginated(false)
            ->columns([
                TextColumn::make('order_number')
                    ->label('رقم الطلب')
                    ->formatStateUsing(fn (?string $state, Order $record): string => filled($state) ? $state : '#' . $record->id)
                    ->searchable(),

                TextColumn::make('user.name')
                    ->label('المستخدم')
                    ->placeholder('-')
                    ->searchable(),

                TextColumn::make('status')
                    ->label('الحالة')
                    ->badge()
                    ->formatStateUsing(fn (?string $state): string => match ($state) {
                        'pending' => 'قيد الانتظار',
                        'processing' => 'قيد المعالجة',
                        'paid' => 'مدفوع',
                        'completed' => 'مكتمل',
                        'cancelled' => 'ملغي',
                        'failed' => 'فشل',
                        'refunded' => 'مسترد',
                        default => $state ?? '-',
                    })
                    ->color(fn (?string $state): string => match ($state) {
                        'paid', 'completed' => 'success',
                        'pending', 'processing' => 'warning',
                        'cancelled', 'failed' => 'danger',
                        'refunded' => 'info',
                        default => 'gray',
                    }),

                TextColumn::make('total')
                    ->label('الإجمالي')
                    ->formatStateUsing(fn ($state): string => number_format((float) $state, 2))
                    ->sortable(),

                TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('Y-m-d H:i')
                    ->sortable(),
            ]);
    }
}