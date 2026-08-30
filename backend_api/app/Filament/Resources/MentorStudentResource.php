<?php

namespace App\Filament\Resources;

use App\Filament\Resources\MentorStudentResource\Pages;
use App\Models\Mentor;
use App\Models\MentorStudent;
use App\Models\User;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Actions\DeleteAction;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class MentorStudentResource extends Resource
{
    protected static ?string $model = MentorStudent::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedUserGroup;

    protected static ?string $navigationLabel = 'طلاب المرشدين';

    protected static ?string $modelLabel = 'طالب مرشد';

    protected static ?string $pluralModelLabel = 'طلاب المرشدين';
    protected static string|\UnitEnum|null $navigationGroup = 'المرشدون';


    protected static ?int $navigationSort = 2;

    public static function canViewAny(): bool
    {
        return auth()->user()?->can('manage mentors') ?? false;
    }

    public static function canCreate(): bool
    {
        return auth()->user()?->can('manage mentors') ?? false;
    }

    public static function canEdit($record): bool
    {
        return auth()->user()?->can('manage mentors') ?? false;
    }


    public static function canDelete($record): bool
    {
        return auth()->user()?->can('manage mentors') ?? false;
    }

    public static function canDeleteAny(): bool
    {
        return auth()->user()?->can('manage mentors') ?? false;
    }
    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('mentor_id')
                    ->label('المرشد')
                    ->relationship('mentor.user', 'name')
                    ->searchable()
                    ->preload()
                    ->required()
                    ->native(false),

                Select::make('student_id')
                    ->label('الطالب')
                    ->relationship('student', 'name')
                    ->searchable()
                    ->preload()
                    ->required()
                    ->native(false),

                Select::make('status')
                    ->label('الحالة')
                    ->options([
                        'active' => 'نشط',
                        'paused' => 'متوقف مؤقتًا',
                        'ended' => 'منتهي',
                    ])
                    ->required()
                    ->native(false)
                    ->default('active'),

                DateTimePicker::make('assigned_at')
                    ->label('تاريخ الإسناد')
                    ->seconds(false),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['mentor.user', 'student']))
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('mentor.user.name')
                    ->label('المرشد')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('student.name')
                    ->label('الطالب')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('student.email')
                    ->label('بريد الطالب')
                    ->searchable()
                    ->toggleable(),

                TextColumn::make('status')
                    ->label('الحالة')
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'active' => 'نشط',
                        'paused' => 'متوقف مؤقتًا',
                        'ended' => 'منتهي',
                        default => $state,
                    })
                    ->badge()
                    ->sortable(),

                TextColumn::make('assigned_at')
                    ->label('تاريخ الإسناد')
                    ->dateTime('Y-m-d H:i')
                    ->sortable(),

                TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('mentor_id')
                    ->label('المرشد')
                    ->options(fn (): array => Mentor::query()
                        ->with('user')
                        ->get()
                        ->mapWithKeys(fn (Mentor $mentor): array => [
                            $mentor->id => $mentor->user?->name ?? 'مرشد #' . $mentor->id,
                        ])
                        ->toArray()),

                SelectFilter::make('student_id')
                    ->label('الطالب')
                    ->options(fn (): array => User::query()
                        ->orderBy('name')
                        ->pluck('name', 'id')
                        ->toArray()),

                SelectFilter::make('status')
                    ->label('الحالة')
                    ->options([
                        'active' => 'نشط',
                        'paused' => 'متوقف مؤقتًا',
                        'ended' => 'منتهي',
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
            'index' => Pages\ManageMentorStudents::route('/'),
        ];
    }
}