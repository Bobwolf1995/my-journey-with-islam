<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ProfileResource\Pages;
use App\Models\Level;
use App\Models\Profile;
use App\Models\User;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\KeyValue;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class ProfileResource extends Resource
{
    protected static ?string $model = Profile::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedIdentification;

    protected static ?string $recordTitleAttribute = 'display_name';

    protected static ?string $navigationLabel = 'الملفات الشخصية';

    protected static ?string $modelLabel = 'ملف شخصي';

    protected static ?string $pluralModelLabel = 'الملفات الشخصية';
    protected static string|\UnitEnum|null $navigationGroup = 'المستخدمون';


    protected static ?int $navigationSort = 2;

    public static function canViewAny(): bool
    {
        return auth()->user()?->can('manage users') ?? false;
    }

    public static function canCreate(): bool
    {
        return auth()->user()?->can('manage users') ?? false;
    }

    public static function canEdit($record): bool
    {
        return auth()->user()?->can('manage users') ?? false;
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
                    ->native(false)
                    ->unique(ignoreRecord: true),

                Select::make('current_level_id')
                    ->label('المستوى الحالي')
                    ->relationship('level', 'name_ar')
                    ->searchable()
                    ->preload()
                    ->native(false),

                TextInput::make('display_name')
                    ->label('اسم العرض')
                    ->maxLength(255),

                TextInput::make('avatar')
                    ->label('الصورة الشخصية')
                    ->maxLength(255),

                Textarea::make('bio')
                    ->label('نبذة')
                    ->rows(4)
                    ->columnSpanFull(),

                TextInput::make('country')
                    ->label('الدولة')
                    ->maxLength(255),

                TextInput::make('city')
                    ->label('المدينة')
                    ->maxLength(255),

                TextInput::make('language')
                    ->label('اللغة')
                    ->required()
                    ->default('ar')
                    ->maxLength(255),

                TextInput::make('points')
                    ->label('النقاط')
                    ->numeric()
                    ->required()
                    ->default(0)
                    ->minValue(0),

                TextInput::make('streak_days')
                    ->label('أيام الاستمرارية')
                    ->numeric()
                    ->required()
                    ->default(0)
                    ->minValue(0),

                DatePicker::make('last_activity_date')
                    ->label('آخر نشاط'),

                KeyValue::make('preferences')
                    ->label('التفضيلات')
                    ->keyLabel('المفتاح')
                    ->valueLabel('القيمة')
                    ->columnSpanFull(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['user', 'level']))
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('user.name')
                    ->label('المستخدم')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('display_name')
                    ->label('اسم العرض')
                    ->searchable()
                    ->sortable()
                    ->placeholder('-'),

                TextColumn::make('level.name_ar')
                    ->label('المستوى')
                    ->searchable()
                    ->sortable()
                    ->placeholder('-'),

                TextColumn::make('points')
                    ->label('النقاط')
                    ->sortable(),

                TextColumn::make('streak_days')
                    ->label('الاستمرارية')
                    ->suffix(' يوم')
                    ->sortable(),

                TextColumn::make('country')
                    ->label('الدولة')
                    ->searchable()
                    ->toggleable(),

                TextColumn::make('city')
                    ->label('المدينة')
                    ->searchable()
                    ->toggleable(),

                TextColumn::make('last_activity_date')
                    ->label('آخر نشاط')
                    ->date('Y-m-d')
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

                SelectFilter::make('current_level_id')
                    ->label('المستوى')
                    ->options(fn (): array => Level::query()
                        ->orderBy('order')
                        ->pluck('name_ar', 'id')
                        ->toArray()),
            ])
            ->recordActions([
                EditAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ManageProfiles::route('/'),
        ];
    }
}