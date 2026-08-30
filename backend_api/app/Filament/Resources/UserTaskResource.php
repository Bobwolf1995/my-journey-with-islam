<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserTaskResource\Pages;
use App\Models\Task;
use App\Models\User;
use App\Models\UserTask;
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

class UserTaskResource extends Resource
{
    protected static ?string $model = UserTask::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedClipboardDocumentCheck;

    protected static ?string $navigationLabel = 'مهام المستخدمين';

    protected static ?string $modelLabel = 'مهمة مستخدم';

    protected static ?string $pluralModelLabel = 'مهام المستخدمين';
    protected static string|\UnitEnum|null $navigationGroup = 'المهام والإنجازات';


    protected static ?int $navigationSort = 3;

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

                Select::make('task_id')
                    ->label('المهمة')
                    ->relationship('task', 'title_ar')
                    ->searchable()
                    ->preload()
                    ->required()
                    ->native(false),

                Select::make('status')
                    ->label('الحالة')
                    ->options([
                        'pending' => 'قيد الانتظار',
                        'completed' => 'مكتملة',
                        'rejected' => 'مرفوضة',
                    ])
                    ->required()
                    ->native(false)
                    ->default('pending'),

                DateTimePicker::make('completed_at')
                    ->label('تاريخ الإكمال')
                    ->seconds(false),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['user', 'task']))
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('user.name')
                    ->label('المستخدم')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('task.title_ar')
                    ->label('المهمة')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('status')
                    ->label('الحالة')
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'pending' => 'قيد الانتظار',
                        'completed' => 'مكتملة',
                        'rejected' => 'مرفوضة',
                        default => $state,
                    })
                    ->badge()
                    ->sortable(),

                TextColumn::make('completed_at')
                    ->label('تاريخ الإكمال')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->placeholder('-'),

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

                SelectFilter::make('task_id')
                    ->label('المهمة')
                    ->options(fn (): array => Task::query()
                        ->orderBy('order')
                        ->pluck('title_ar', 'id')
                        ->toArray()),

                SelectFilter::make('status')
                    ->label('الحالة')
                    ->options([
                        'pending' => 'قيد الانتظار',
                        'completed' => 'مكتملة',
                        'rejected' => 'مرفوضة',
                    ]),
            ])
            ->recordActions([
                EditAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ManageUserTasks::route('/'),
        ];
    }
}