<?php

namespace App\Filament\Resources;

use App\Filament\Resources\LibraryItemResource\Pages;
use App\Models\LibraryCategory;
use App\Models\LibraryItem;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Actions\DeleteAction;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
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
use Illuminate\Database\Eloquent\Builder;

class LibraryItemResource extends Resource
{
    protected static ?string $model = LibraryItem::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedDocumentText;

    protected static ?string $recordTitleAttribute = 'title_ar';

    protected static ?string $navigationLabel = 'عناصر المكتبة';

    protected static ?string $modelLabel = 'عنصر مكتبة';

    protected static ?string $pluralModelLabel = 'عناصر المكتبة';
    protected static string|\UnitEnum|null $navigationGroup = 'المكتبة';


    protected static ?int $navigationSort = 2;

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
                Select::make('library_category_id')
                    ->label('تصنيف المكتبة')
                    ->relationship('category', 'name_ar')
                    ->searchable()
                    ->preload()
                    ->native(false),

                TextInput::make('title_ar')
                    ->label('العنوان')
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

                Textarea::make('content_ar')
                    ->label('المحتوى')
                    ->rows(8)
                    ->columnSpanFull(),

                Select::make('type')
                    ->label('النوع')
                    ->options([
                        'book' => 'كتاب',
                        'article' => 'مقال',
                        'audio' => 'صوتي',
                        'video' => 'فيديو',
                        'pdf' => 'PDF',
                    ])
                    ->required()
                    ->native(false)
                    ->default('book'),

                FileUpload::make('cover_image')
                    ->label('صورة الغلاف')
                    ->disk('public')
                    ->directory('library/covers')
                    ->visibility('public')
                    ->image()
                    ->acceptedFileTypes([
                        'image/jpeg',
                        'image/png',
                        'image/webp',
                    ])
                    ->downloadable()
                    ->openable()
                    ->maxSize(20480),

                FileUpload::make('file_url')
                    ->label('ملف العنصر')
                    ->disk('public')
                    ->directory('library/files')
                    ->visibility('public')
                    ->acceptedFileTypes([
                        'application/pdf',
                        'application/msword',
                        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                        'audio/mpeg',
                        'video/mp4',
                        'application/zip',
                        'application/x-zip-compressed',
                    ])
                    ->downloadable()
                    ->openable()
                    ->maxSize(102400),

                TextInput::make('price')
                    ->label('السعر')
                    ->numeric()
                    ->required()
                    ->default(0)
                    ->minValue(0),

                Toggle::make('is_free')
                    ->label('مجاني')
                    ->default(true),

                Toggle::make('is_featured')
                    ->label('مميز')
                    ->default(false),

                Toggle::make('is_published')
                    ->label('منشور')
                    ->default(false),

                DateTimePicker::make('published_at')
                    ->label('تاريخ النشر')
                    ->seconds(false),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with('category'))
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('title_ar')
                    ->label('العنوان')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('category.name_ar')
                    ->label('التصنيف')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('type')
                    ->label('النوع')
                    ->formatStateUsing(fn (?string $state): string => match ($state) {
                        'book' => 'كتاب',
                        'article' => 'مقال',
                        'audio' => 'صوتي',
                        'video' => 'فيديو',
                        'pdf' => 'PDF',
                        default => $state ?? '-',
                    })
                    ->badge()
                    ->sortable(),

                TextColumn::make('price')
                    ->label('السعر')
                    ->formatStateUsing(fn ($state): string => number_format((float) $state, 2))
                    ->sortable(),

                ToggleColumn::make('is_free')
                    ->label('مجاني')
                    ->sortable(),

                ToggleColumn::make('is_featured')
                    ->label('مميز')
                    ->sortable(),

                ToggleColumn::make('is_published')
                    ->label('منشور')
                    ->sortable(),

                TextColumn::make('published_at')
                    ->label('تاريخ النشر')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->toggleable(),

                TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('library_category_id')
                    ->label('التصنيف')
                    ->options(fn (): array => LibraryCategory::query()
                        ->orderBy('order')
                        ->pluck('name_ar', 'id')
                        ->toArray()),

                SelectFilter::make('type')
                    ->label('النوع')
                    ->options([
                        'book' => 'كتاب',
                        'article' => 'مقال',
                        'audio' => 'صوتي',
                        'video' => 'فيديو',
                        'pdf' => 'PDF',
                    ]),

                SelectFilter::make('is_free')
                    ->label('مجاني')
                    ->options([
                        '1' => 'مجاني',
                        '0' => 'مدفوع',
                    ]),

                SelectFilter::make('is_featured')
                    ->label('مميز')
                    ->options([
                        '1' => 'مميز',
                        '0' => 'غير مميز',
                    ]),

                SelectFilter::make('is_published')
                    ->label('حالة النشر')
                    ->options([
                        '1' => 'منشور',
                        '0' => 'غير منشور',
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
            'index' => Pages\ManageLibraryItems::route('/'),
        ];
    }
}