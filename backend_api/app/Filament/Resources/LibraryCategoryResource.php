<?php

namespace App\Filament\Resources;

use App\Filament\Resources\LibraryCategoryResource\Pages;
use App\Models\LibraryCategory;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Actions\DeleteAction;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\ToggleColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class LibraryCategoryResource extends Resource
{
    protected static ?string $model = LibraryCategory::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedFolder;

    protected static ?string $recordTitleAttribute = 'name_ar';

    protected static ?string $navigationLabel = 'تصنيفات المكتبة';

    protected static ?string $modelLabel = 'تصنيف مكتبة';

    protected static ?string $pluralModelLabel = 'تصنيفات المكتبة';
    protected static string|\UnitEnum|null $navigationGroup = 'المكتبة';


    protected static ?int $navigationSort = 1;

    public static function canViewAny(): bool
    {
        return auth()->user()?->can('manage library') ?? false;
    }

    public static function canCreate(): bool
    {
        return auth()->user()?->can('manage library') ?? false;
    }

    public static function canEdit($record): bool
    {
        return auth()->user()?->can('manage library') ?? false;
    }


    public static function canDelete($record): bool
    {
        return auth()->user()?->can('manage library') ?? false;
    }

    public static function canDeleteAny(): bool
    {
        return auth()->user()?->can('manage library') ?? false;
    }
    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('name_ar')
                    ->label('اسم التصنيف')
                    ->required()
                    ->maxLength(255),

                TextInput::make('slug')
                    ->label('المعرف')
                    ->required()
                    ->unique(ignoreRecord: true)
                    ->maxLength(255),

                Textarea::make('description_ar')
                    ->label('الوصف')
                    ->rows(4)
                    ->columnSpanFull(),

                TextInput::make('icon')
                    ->label('الأيقونة')
                    ->maxLength(255),

                TextInput::make('color')
                    ->label('اللون')
                    ->maxLength(255)
                    ->placeholder('#0F766E'),

                TextInput::make('order')
                    ->label('الترتيب')
                    ->numeric()
                    ->required()
                    ->default(1)
                    ->minValue(1),

                Toggle::make('is_active')
                    ->label('نشط')
                    ->default(true),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('order')
            ->columns([
                TextColumn::make('name_ar')
                    ->label('اسم التصنيف')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('slug')
                    ->label('المعرف')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('order')
                    ->label('الترتيب')
                    ->sortable(),

                TextColumn::make('icon')
                    ->label('الأيقونة')
                    ->toggleable(),

                TextColumn::make('color')
                    ->label('اللون')
                    ->toggleable(),

                ToggleColumn::make('is_active')
                    ->label('نشط')
                    ->sortable(),

                TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('is_active')
                    ->label('الحالة')
                    ->options([
                        '1' => 'نشط',
                        '0' => 'غير نشط',
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
            'index' => Pages\ManageLibraryCategories::route('/'),
        ];
    }
}