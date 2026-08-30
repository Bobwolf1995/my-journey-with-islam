<?php

namespace App\Filament\Resources;

use App\Filament\Resources\LessonCompletionResource\Pages;
use App\Models\Course;
use App\Models\Lesson;
use App\Models\LessonCompletion;
use App\Models\User;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class LessonCompletionResource extends Resource
{
    protected static ?string $model = LessonCompletion::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCheckCircle;

    protected static ?string $navigationLabel = 'إكمال الدروس';

    protected static ?string $modelLabel = 'إكمال درس';

    protected static ?string $pluralModelLabel = 'إكمال الدروس';
    protected static string|\UnitEnum|null $navigationGroup = 'المهام والإنجازات';


    protected static ?int $navigationSort = 5;

    public static function canViewAny(): bool
    {
        return auth()->user()?->can('view reports') ?? false;
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
        return false;
    }

    public static function canDeleteAny(): bool
    {
        return false;
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
                    ->required()
                    ->native(false),

                Select::make('course_id')
                    ->label('الدورة')
                    ->relationship('course', 'title_ar')
                    ->searchable()
                    ->preload()
                    ->required()
                    ->native(false),

                Select::make('lesson_id')
                    ->label('الدرس')
                    ->relationship('lesson', 'title_ar')
                    ->searchable()
                    ->preload()
                    ->required()
                    ->native(false),

                DateTimePicker::make('completed_at')
                    ->label('تاريخ الإكمال')
                    ->required()
                    ->seconds(false),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['user', 'course', 'lesson']))
            ->defaultSort('completed_at', 'desc')
            ->columns([
                TextColumn::make('user.name')
                    ->label('المستخدم')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('course.title_ar')
                    ->label('الدورة')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('lesson.title_ar')
                    ->label('الدرس')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('completed_at')
                    ->label('تاريخ الإكمال')
                    ->dateTime('Y-m-d H:i')
                    ->sortable(),

                TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('user_id')
                    ->label('المستخدم')
                    ->options(fn (): array => User::query()
                        ->orderBy('name')
                        ->pluck('name', 'id')
                        ->toArray()),

                SelectFilter::make('course_id')
                    ->label('الدورة')
                    ->options(fn (): array => Course::query()
                        ->orderBy('order')
                        ->pluck('title_ar', 'id')
                        ->toArray()),

                SelectFilter::make('lesson_id')
                    ->label('الدرس')
                    ->options(fn (): array => Lesson::query()
                        ->orderBy('order')
                        ->pluck('title_ar', 'id')
                        ->toArray()),
            ])
            ->recordActions([
                EditAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ManageLessonCompletions::route('/'),
        ];
    }
}