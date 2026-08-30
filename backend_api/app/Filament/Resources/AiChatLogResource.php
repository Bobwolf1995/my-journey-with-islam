<?php

namespace App\Filament\Resources;

use App\Filament\Resources\AiChatLogResource\Pages;
use App\Models\AiChatLog;
use App\Models\User;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class AiChatLogResource extends Resource
{
    protected static ?string $model = AiChatLog::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCpuChip;

    protected static ?string $recordTitleAttribute = 'title_ar';

    protected static ?string $navigationLabel = 'سجلات الذكاء الاصطناعي';

    protected static ?string $modelLabel = 'سجل ذكاء اصطناعي';

    protected static ?string $pluralModelLabel = 'سجلات الذكاء الاصطناعي';
    protected static string|\UnitEnum|null $navigationGroup = 'التقارير والسجلات';


    protected static ?int $navigationSort = 1;

    public static function canViewAny(): bool
    {
        return auth()->user()?->can('view reports') ?? false;
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canEdit($record): bool
    {
        return false;
    }


    public static function canDelete($record): bool
    {
        return false;
    }

    public static function canDeleteAny(): bool
    {
        return false;
    }
    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([]);
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
                    ->sortable()
                    ->placeholder('بدون عنوان'),

                TextColumn::make('user.name')
                    ->label('المستخدم')
                    ->searchable()
                    ->sortable()
                    ->placeholder('غير محدد'),

                TextColumn::make('category')
                    ->label('التصنيف')
                    ->badge()
                    ->searchable()
                    ->sortable(),

                TextColumn::make('question')
                    ->label('السؤال')
                    ->limit(80)
                    ->searchable(),

                TextColumn::make('answer')
                    ->label('الإجابة')
                    ->limit(80)
                    ->searchable()
                    ->toggleable(),

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

                SelectFilter::make('category')
                    ->label('التصنيف')
                    ->options(fn (): array => AiChatLog::query()
                        ->whereNotNull('category')
                        ->distinct()
                        ->orderBy('category')
                        ->pluck('category', 'category')
                        ->toArray()),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ManageAiChatLogs::route('/'),
        ];
    }
}