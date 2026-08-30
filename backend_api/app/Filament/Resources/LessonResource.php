<?php

namespace App\Filament\Resources;

use App\Filament\Resources\LessonResource\Pages;
use App\Models\Course;
use App\Models\CourseSection;
use App\Models\Lesson;
use BackedEnum;
use Filament\Actions\DeleteAction;
use Filament\Actions\EditAction;
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

class LessonResource extends Resource
{
    protected static ?string $model = Lesson::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedDocumentText;

    protected static ?string $recordTitleAttribute = 'title_ar';

    protected static ?string $navigationLabel = 'الدروس';

    protected static ?string $modelLabel = 'درس';

    protected static ?string $pluralModelLabel = 'الدروس';

    protected static string|\UnitEnum|null $navigationGroup = 'التعليم';

    protected static ?int $navigationSort = 5;

    public static function canViewAny(): bool
    {
        return auth()->user()?->can('manage lessons') ?? false;
    }

    public static function canCreate(): bool
    {
        return auth()->user()?->can('manage lessons') ?? false;
    }

    public static function canEdit($record): bool
    {
        return auth()->user()?->can('manage lessons') ?? false;
    }

    public static function canDelete($record): bool
    {
        return auth()->user()?->can('manage lessons') ?? false;
    }

    public static function canDeleteAny(): bool
    {
        return auth()->user()?->can('manage lessons') ?? false;
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('course_id')
                    ->label('الدورة')
                    ->relationship('course', 'title_ar')
                    ->searchable()
                    ->preload()
                    ->required()
                    ->native(false),

                Select::make('course_section_id')
                    ->label('القسم')
                    ->relationship('section', 'title_ar')
                    ->searchable()
                    ->preload()
                    ->native(false),

                TextInput::make('title_ar')
                    ->label('عنوان الدرس')
                    ->required()
                    ->maxLength(255),

                TextInput::make('slug')
                    ->label('المعرف')
                    ->required()
                    ->unique(ignoreRecord: true)
                    ->maxLength(255),

                Textarea::make('content_ar')
                    ->label('محتوى الدرس')
                    ->rows(8)
                    ->columnSpanFull(),

                Select::make('lesson_type')
                    ->label('نوع الدرس')
                    ->options([
                        'text' => 'نصي',
                        'video' => 'فيديو',
                        'audio' => 'صوتي',
                        'file' => 'ملف',
                        'quiz' => 'اختبار',
                    ])
                    ->required()
                    ->native(false)
                    ->default('text'),

                FileUpload::make('video_url')
                    ->label('رابط الفيديو أو ملف الفيديو')
                    ->disk('public')
                    ->directory('lessons/videos')
                    ->visibility('public')
                    ->acceptedFileTypes([
                        'video/mp4',
                        'video/webm',
                        'video/quicktime',
                    ])
                    ->preserveFilenames()
                    ->openable()
                    ->downloadable()
                    ->maxSize(512000),

                FileUpload::make('audio_url')
                    ->label('رابط الصوت أو ملف الصوت')
                    ->disk('public')
                    ->directory('lessons/audio')
                    ->visibility('public')
                    ->acceptedFileTypes([
                        'audio/mpeg',
                        'audio/mp3',
                        'audio/mp4',
                        'audio/wav',
                        'audio/x-wav',
                        'audio/ogg',
                    ])
                    ->preserveFilenames()
                    ->openable()
                    ->downloadable()
                    ->maxSize(102400),

                FileUpload::make('file_url')
                    ->label('ملف مرفق')
                    ->disk('public')
                    ->directory('lessons/files')
                    ->visibility('public')
                    ->acceptedFileTypes([
                        'application/pdf',
                        'application/msword',
                        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                        'application/vnd.ms-powerpoint',
                        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
                        'application/zip',
                        'application/x-zip-compressed',
                        'text/plain',
                    ])
                    ->preserveFilenames()
                    ->openable()
                    ->downloadable()
                    ->maxSize(102400),

                TextInput::make('duration_minutes')
                    ->label('المدة بالدقائق')
                    ->numeric()
                    ->required()
                    ->default(0)
                    ->minValue(0),

                TextInput::make('points')
                    ->label('النقاط')
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
                    ->label('مجاني')
                    ->default(true),

                Toggle::make('is_published')
                    ->label('منشور')
                    ->default(false),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['course', 'section']))
            ->defaultSort('order')
            ->columns([
                TextColumn::make('title_ar')
                    ->label('عنوان الدرس')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('course.title_ar')
                    ->label('الدورة')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('section.title_ar')
                    ->label('القسم')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('lesson_type')
                    ->label('النوع')
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'text' => 'نصي',
                        'video' => 'فيديو',
                        'audio' => 'صوتي',
                        'file' => 'ملف',
                        'quiz' => 'اختبار',
                        default => $state,
                    })
                    ->badge()
                    ->sortable(),

                TextColumn::make('duration_minutes')
                    ->label('المدة')
                    ->suffix(' دقيقة')
                    ->sortable(),

                TextColumn::make('points')
                    ->label('النقاط')
                    ->sortable(),

                TextColumn::make('order')
                    ->label('الترتيب')
                    ->sortable(),

                ToggleColumn::make('is_free')
                    ->label('مجاني')
                    ->sortable(),

                ToggleColumn::make('is_published')
                    ->label('منشور')
                    ->sortable(),

                TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('course_id')
                    ->label('الدورة')
                    ->options(fn (): array => Course::query()
                        ->orderBy('order')
                        ->pluck('title_ar', 'id')
                        ->toArray()),

                SelectFilter::make('course_section_id')
                    ->label('القسم')
                    ->options(fn (): array => CourseSection::query()
                        ->orderBy('order')
                        ->pluck('title_ar', 'id')
                        ->toArray()),

                SelectFilter::make('lesson_type')
                    ->label('نوع الدرس')
                    ->options([
                        'text' => 'نصي',
                        'video' => 'فيديو',
                        'audio' => 'صوتي',
                        'file' => 'ملف',
                        'quiz' => 'اختبار',
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
            'index' => Pages\ManageLessons::route('/'),
        ];
    }
}