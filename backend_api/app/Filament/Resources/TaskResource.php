<?php

namespace App\Filament\Resources;

use App\Filament\Resources\TaskResource\Pages;
use App\Models\Task;
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

class TaskResource extends Resource
{
    protected static ?string $model = Task::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCheckCircle;

    protected static ?string $recordTitleAttribute = 'title_ar';

    protected static ?string $navigationLabel = 'المهام';

    protected static ?string $modelLabel = 'مهمة';

    protected static ?string $pluralModelLabel = 'المهام';
    protected static string|\UnitEnum|null $navigationGroup = 'المهام والإنجازات';


    protected static ?int $navigationSort = 2;

    public static function canViewAny(): bool
    {
        return auth()->user()?->can('review tasks') ?? false;
    }

    public static function canCreate(): bool
    {
        return auth()->user()?->can('review tasks') ?? false;
    }

    public static function canEdit($record): bool
    {
        return auth()->user()?->can('review tasks') ?? false;
    }


    public static function canDelete($record): bool
    {
        return auth()->user()?->can('review tasks') ?? false;
    }

    public static function canDeleteAny(): bool
    {
        return auth()->user()?->can('review tasks') ?? false;
    }
    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('title_ar')
                    ->label('عنوان المهمة')
                    ->required()
                    ->maxLength(255),

                Textarea::make('description_ar')
                    ->label('الوصف')
                    ->rows(4)
                    ->columnSpanFull(),

                Select::make('type')
                    ->label('نوع المهمة')
                    ->options([
                        'general' => 'عام',
                        'lesson' => 'درس',
                        'quiz' => 'اختبار',
                        'reading' => 'قراءة',
                        'mentor' => 'مرشد',
                        'habit' => 'عادة',
                    ])
                    ->required()
                    ->native(false)
                    ->default('general'),

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

                Toggle::make('is_active')
                    ->label('نشطة')
                    ->default(true),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('order')
            ->columns([
                TextColumn::make('title_ar')
                    ->label('عنوان المهمة')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('type')
                    ->label('النوع')
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'lesson' => 'درس',
                        'quiz' => 'اختبار',
                        'reading' => 'قراءة',
                        'mentor' => 'مرشد',
                        'habit' => 'عادة',
                        'general' => 'عام',
                        default => $state,
                    })
                    ->badge()
                    ->sortable(),

                TextColumn::make('points')
                    ->label('النقاط')
                    ->sortable(),

                TextColumn::make('order')
                    ->label('الترتيب')
                    ->sortable(),

                ToggleColumn::make('is_active')
                    ->label('نشطة')
                    ->sortable(),

                TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('type')
                    ->label('نوع المهمة')
                    ->options([
                        'general' => 'عام',
                        'lesson' => 'درس',
                        'quiz' => 'اختبار',
                        'reading' => 'قراءة',
                        'mentor' => 'مرشد',
                        'habit' => 'عادة',
                    ]),

                SelectFilter::make('is_active')
                    ->label('الحالة')
                    ->options([
                        '1' => 'نشطة',
                        '0' => 'غير نشطة',
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
            'index' => Pages\ManageTasks::route('/'),
        ];
    }
}