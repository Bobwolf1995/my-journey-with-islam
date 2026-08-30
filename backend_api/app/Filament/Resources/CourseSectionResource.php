<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CourseSectionResource\Pages;
use App\Models\Course;
use App\Models\CourseSection;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Actions\DeleteAction;
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

class CourseSectionResource extends Resource
{
    protected static ?string $model = CourseSection::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedQueueList;

    protected static ?string $recordTitleAttribute = 'title_ar';

    protected static ?string $navigationLabel = 'أقسام الدورات';

    protected static ?string $modelLabel = 'قسم دورة';

    protected static ?string $pluralModelLabel = 'أقسام الدورات';
    protected static string|\UnitEnum|null $navigationGroup = 'التعليم';


    protected static ?int $navigationSort = 4;

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
                Select::make('course_id')
                    ->label('الدورة')
                    ->relationship('course', 'title_ar')
                    ->searchable()
                    ->preload()
                    ->required()
                    ->native(false),

                TextInput::make('title_ar')
                    ->label('عنوان القسم')
                    ->required()
                    ->maxLength(255),

                Textarea::make('description_ar')
                    ->label('الوصف')
                    ->rows(4)
                    ->columnSpanFull(),

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
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with('course'))
            ->defaultSort('order')
            ->columns([
                TextColumn::make('title_ar')
                    ->label('عنوان القسم')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('course.title_ar')
                    ->label('الدورة')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('order')
                    ->label('الترتيب')
                    ->sortable(),

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
                SelectFilter::make('course_id')
                    ->label('الدورة')
                    ->options(fn (): array => Course::query()
                        ->orderBy('order')
                        ->pluck('title_ar', 'id')
                        ->toArray()),

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
            'index' => Pages\ManageCourseSections::route('/'),
        ];
    }
}