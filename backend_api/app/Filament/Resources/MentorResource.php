<?php

namespace App\Filament\Resources;

use App\Filament\Resources\MentorResource\Pages;
use App\Models\Mentor;
use App\Models\User;
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

class MentorResource extends Resource
{
    protected static ?string $model = Mentor::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedAcademicCap;

    protected static ?string $recordTitleAttribute = 'specialization';

    protected static ?string $navigationLabel = 'المرشدون';

    protected static ?string $modelLabel = 'مرشد';

    protected static ?string $pluralModelLabel = 'المرشدون';
    protected static string|\UnitEnum|null $navigationGroup = 'المرشدون';


    protected static ?int $navigationSort = 1;

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
                Select::make('user_id')
                    ->label('المستخدم')
                    ->relationship('user', 'name')
                    ->searchable()
                    ->preload()
                    ->required()
                    ->native(false)
                    ->unique(ignoreRecord: true),

                TextInput::make('specialization')
                    ->label('التخصص')
                    ->maxLength(255),

                Textarea::make('bio')
                    ->label('نبذة')
                    ->rows(5)
                    ->columnSpanFull(),

                Toggle::make('is_available')
                    ->label('متاح')
                    ->default(true),

                TextInput::make('rating')
                    ->label('التقييم')
                    ->numeric()
                    ->minValue(0)
                    ->maxValue(5),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with('user'))
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('user.name')
                    ->label('الاسم')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('user.email')
                    ->label('البريد الإلكتروني')
                    ->searchable()
                    ->toggleable(),

                TextColumn::make('specialization')
                    ->label('التخصص')
                    ->searchable()
                    ->sortable(),

                ToggleColumn::make('is_available')
                    ->label('متاح')
                    ->sortable(),

                TextColumn::make('rating')
                    ->label('التقييم')
                    ->formatStateUsing(fn ($state): string => $state === null ? '-' : number_format((float) $state, 2))
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

                SelectFilter::make('is_available')
                    ->label('الإتاحة')
                    ->options([
                        '1' => 'متاح',
                        '0' => 'غير متاح',
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
            'index' => Pages\ManageMentors::route('/'),
        ];
    }
}