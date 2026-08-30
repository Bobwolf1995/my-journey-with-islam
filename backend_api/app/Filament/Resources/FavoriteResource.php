<?php

namespace App\Filament\Resources;

use App\Filament\Resources\FavoriteResource\Pages;
use App\Models\Favorite;
use App\Models\User;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class FavoriteResource extends Resource
{
    protected static ?string $model = Favorite::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedHeart;

    protected static ?string $navigationLabel = 'المفضلة';

    protected static ?string $modelLabel = 'عنصر مفضل';

    protected static ?string $pluralModelLabel = 'المفضلة';
    protected static string|\UnitEnum|null $navigationGroup = 'المستخدمون';


    protected static ?int $navigationSort = 99;

    public static function canViewAny(): bool
    {
        return auth()->user()?->can('manage users') ?? false;
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
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['user', 'favoritable']))
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('user.name')
                    ->label('المستخدم')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('favoritable_type')
                    ->label('نوع العنصر')
                    ->formatStateUsing(fn (string $state): string => class_basename($state))
                    ->badge()
                    ->searchable()
                    ->sortable(),

                TextColumn::make('favoritable_title')
                    ->label('العنصر')
                    ->state(fn (Favorite $record): string => $record->favoritable?->title_ar
                        ?? $record->favoritable?->name_ar
                        ?? 'عنصر #' . $record->favoritable_id)
                    ->searchable(false),

                TextColumn::make('favoritable_id')
                    ->label('رقم العنصر')
                    ->sortable()
                    ->toggleable(),

                TextColumn::make('created_at')
                    ->label('تاريخ الإضافة')
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

                SelectFilter::make('favoritable_type')
                    ->label('نوع العنصر')
                    ->options(fn (): array => Favorite::query()
                        ->whereNotNull('favoritable_type')
                        ->distinct()
                        ->orderBy('favoritable_type')
                        ->pluck('favoritable_type', 'favoritable_type')
                        ->mapWithKeys(fn (string $type, string $key): array => [
                            $key => class_basename($type),
                        ])
                        ->toArray()),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ManageFavorites::route('/'),
        ];
    }
}