<?php

namespace App\Filament\Resources;

use App\Filament\Resources\NotificationResource\Pages;
use App\Models\Notification;
use App\Models\User;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Actions\DeleteAction;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\KeyValue;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class NotificationResource extends Resource
{
    protected static ?string $model = Notification::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedBell;

    protected static ?string $recordTitleAttribute = 'title_ar';

    protected static ?string $navigationLabel = 'الإشعارات';

    protected static ?string $modelLabel = 'إشعار';

    protected static ?string $pluralModelLabel = 'الإشعارات';
    protected static string|\UnitEnum|null $navigationGroup = 'النظام';


    protected static ?int $navigationSort = 1;

    public static function canViewAny(): bool
    {
        return auth()->user()?->can('manage users') ?? false;
    }

    public static function canCreate(): bool
    {
        return auth()->user()?->can('manage users') ?? false;
    }

    public static function canEdit($record): bool
    {
        return auth()->user()?->can('manage users') ?? false;
    }


    public static function canDelete($record): bool
    {
        return auth()->user()?->can('manage users') ?? false;
    }

    public static function canDeleteAny(): bool
    {
        return auth()->user()?->can('manage users') ?? false;
    }
    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('user_id')
                    ->label('المستخدم')
                    ->relationship('user', 'name')
                    ->searchable()
                    ->preload()
                    ->native(false),

                TextInput::make('title_ar')
                    ->label('العنوان')
                    ->required()
                    ->maxLength(255),

                Textarea::make('body_ar')
                    ->label('نص الإشعار')
                    ->required()
                    ->rows(5)
                    ->columnSpanFull(),

                Select::make('type')
                    ->label('النوع')
                    ->options([
                        'general' => 'عام',
                        'course' => 'دورة',
                        'lesson' => 'درس',
                        'task' => 'مهمة',
                        'order' => 'طلب',
                        'community' => 'مجتمع',
                        'system' => 'نظام',
                    ])
                    ->required()
                    ->native(false)
                    ->default('general'),

                KeyValue::make('data')
                    ->label('بيانات إضافية')
                    ->keyLabel('المفتاح')
                    ->valueLabel('القيمة')
                    ->columnSpanFull(),

                DateTimePicker::make('read_at')
                    ->label('تاريخ القراءة')
                    ->seconds(false),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with('user'))
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('title_ar')
                    ->label('العنوان')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('user.name')
                    ->label('المستخدم')
                    ->searchable()
                    ->sortable()
                    ->placeholder('عام'),

                TextColumn::make('type')
                    ->label('النوع')
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'general' => 'عام',
                        'course' => 'دورة',
                        'lesson' => 'درس',
                        'task' => 'مهمة',
                        'order' => 'طلب',
                        'community' => 'مجتمع',
                        'system' => 'نظام',
                        default => $state,
                    })
                    ->badge()
                    ->sortable(),

                TextColumn::make('read_at')
                    ->label('تاريخ القراءة')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->placeholder('غير مقروء'),

                TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('Y-m-d H:i')
                    ->sortable(),
            ])
            ->filters([
                SelectFilter::make('user_id')
                    ->label('المستخدم')
                    ->options(fn (): array => User::query()
                        ->orderBy('name')
                        ->pluck('name', 'id')
                        ->toArray()),

                SelectFilter::make('type')
                    ->label('النوع')
                    ->options([
                        'general' => 'عام',
                        'course' => 'دورة',
                        'lesson' => 'درس',
                        'task' => 'مهمة',
                        'order' => 'طلب',
                        'community' => 'مجتمع',
                        'system' => 'نظام',
                    ]),
            ])
            ->recordActions([
                EditAction::make(),
                DeleteAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ManageNotifications::route('/'),
        ];
    }
}