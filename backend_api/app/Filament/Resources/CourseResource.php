<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CourseResource\Pages;
use App\Models\Course;
use App\Models\LearningPath;
use BackedEnum;
use Filament\Actions\DeleteAction;
use Filament\Actions\EditAction;
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

class CourseResource extends Resource
{
    protected static ?string $model = Course::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedBookOpen;

    protected static ?string $recordTitleAttribute = 'title_ar';

    protected static ?string $navigationLabel = 'الدورات';

    protected static ?string $modelLabel = 'دورة';

    protected static ?string $pluralModelLabel = 'الدورات';

    protected static string|\UnitEnum|null $navigationGroup = 'التعليم';

    protected static ?int $navigationSort = 3;

    public static function canViewAny(): bool
    {
        return auth()->user()?->can('manage courses') ?? false;
    }

    public static function canCreate(): bool
    {
        return auth()->user()?->can('manage courses') ?? false;
    }

    public static function canEdit($record): bool
    {
        return auth()->user()?->can('manage courses') ?? false;
    }

    public static function canDelete($record): bool
    {
        return auth()->user()?->can('manage courses') ?? false;
    }

    public static function canDeleteAny(): bool
    {
        return auth()->user()?->can('manage courses') ?? false;
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('learning_path_id')
                    ->label('المسار التعليمي')
                    ->relationship('learningPath', 'name_ar')
                    ->searchable()
                    ->preload()
                    ->native(false),

                TextInput::make('title_ar')
                    ->label('عنوان الدورة')
                    ->required()
                    ->maxLength(255),

                TextInput::make('slug')
                    ->label('المعرف')
                    ->required()
                    ->unique(ignoreRecord: true)
                    ->maxLength(255),

                Textarea::make('short_description_ar')
                    ->label('الوصف المختصر')
                    ->rows(3)
                    ->columnSpanFull(),

                Textarea::make('description_ar')
                    ->label('الوصف الكامل')
                    ->rows(5)
                    ->columnSpanFull(),

                FileUpload::make('cover_image')
                    ->label('صورة الغلاف')
                    ->disk('public')
                    ->directory('courses/covers')
                    ->visibility('public')
                    ->image()
                    ->preserveFilenames()
                    ->openable()
                    ->downloadable()
                    ->maxSize(20480),

                Select::make('level')
                    ->label('المستوى')
                    ->options([
                        'beginner' => 'مبتدئ',
                        'intermediate' => 'متوسط',
                        'advanced' => 'متقدم',
                    ])
                    ->required()
                    ->native(false)
                    ->default('beginner'),

                TextInput::make('duration_minutes')
                    ->label('المدة بالدقائق')
                    ->numeric()
                    ->required()
                    ->default(0)
                    ->minValue(0),

                TextInput::make('lessons_count')
                    ->label('عدد الدروس')
                    ->numeric()
                    ->required()
                    ->default(0)
                    ->minValue(0),

                TextInput::make('order')
                    ->label('الترتيب')
                    ->numeric()
                    ->required()
                    ->default(1)
                    ->minValue(1),

                Toggle::make('is_free')
                    ->label('دورة مجانية؟')
                    ->default(true),

                TextInput::make('price')
                    ->label('السعر')
                    ->numeric()
                    ->prefix('EGP')
                    ->default(0)
                    ->minValue(0),

                Toggle::make('is_featured')
                    ->label('مميزة')
                    ->default(false),

                Toggle::make('is_published')
                    ->label('منشورة')
                    ->default(false),

                DateTimePicker::make('published_at')
                    ->label('تاريخ النشر')
                    ->seconds(false),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with('learningPath'))
            ->defaultSort('order')
            ->columns([
                TextColumn::make('title_ar')
                    ->label('عنوان الدورة')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('learningPath.name_ar')
                    ->label('المسار')
                    ->sortable(),

                TextColumn::make('level')
                    ->label('المستوى')
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'beginner' => 'مبتدئ',
                        'intermediate' => 'متوسط',
                        'advanced' => 'متقدم',
                        default => $state,
                    })
                    ->badge()
                    ->sortable(),

                TextColumn::make('duration_minutes')
                    ->label('المدة')
                    ->suffix(' دقيقة')
                    ->sortable(),

                TextColumn::make('lessons_count')
                    ->label('الدروس')
                    ->sortable(),

                TextColumn::make('price')
                    ->label('السعر')
                    ->formatStateUsing(fn ($state): string => number_format((float) ($state ?? 0), 2) . ' EGP')
                    ->sortable(),

                TextColumn::make('is_free')
                    ->label('نوع الدفع')
                    ->formatStateUsing(fn ($state): string => $state ? 'مجانية' : 'مدفوعة')
                    ->badge()
                    ->sortable(),

                TextColumn::make('order')
                    ->label('الترتيب')
                    ->sortable(),

                ToggleColumn::make('is_featured')
                    ->label('مميزة')
                    ->sortable(),

                ToggleColumn::make('is_published')
                    ->label('منشورة')
                    ->sortable(),

                TextColumn::make('published_at')
                    ->label('تاريخ النشر')
                    ->dateTime('Y-m-d H:i')
                    ->sortable(),

                TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('learning_path_id')
                    ->label('المسار التعليمي')
                    ->options(fn (): array => LearningPath::query()
                        ->orderBy('order')
                        ->pluck('name_ar', 'id')
                        ->toArray()),

                SelectFilter::make('level')
                    ->label('المستوى')
                    ->options([
                        'beginner' => 'مبتدئ',
                        'intermediate' => 'متوسط',
                        'advanced' => 'متقدم',
                    ]),

                SelectFilter::make('is_published')
                    ->label('حالة النشر')
                    ->options([
                        '1' => 'منشورة',
                        '0' => 'غير منشورة',
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
            'index' => Pages\ManageCourses::route('/'),
        ];
    }
}