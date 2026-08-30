<?php

namespace App\Filament\Resources;

use App\Filament\Resources\BadgeResource\Pages;
use App\Models\Badge;
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

class BadgeResource extends Resource
{
    protected static ?string $model = Badge::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedShieldCheck;

    protected static ?string $recordTitleAttribute = 'name_ar';

    protected static ?string $navigationLabel = 'الأوسمة';

    protected static ?string $modelLabel = 'وسام';

    protected static ?string $pluralModelLabel = 'الأوسمة';
    protected static string|\UnitEnum|null $navigationGroup = 'المهام والإنجازات';


    protected static ?int $navigationSort = 1;

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
                TextInput::make('name_ar')
                    ->label('اسم الوسام')
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

                Select::make('category')
                    ->label('التصنيف')
                    ->options([
                        'learning' => 'التعلم',
                        'progress' => 'التقدم',
                        'library' => 'المكتبة',
                        'community' => 'المجتمع',
                        'mentorship' => 'الإرشاد',
                    ])
                    ->required()
                    ->native(false)
                    ->default('learning'),

                TextInput::make('required_points')
                    ->label('النقاط المطلوبة')
                    ->numeric()
                    ->required()
                    ->default(0)
                    ->minValue(0),

                TextInput::make('icon')
                    ->label('الأيقونة')
                    ->maxLength(255),

                TextInput::make('color')
                    ->label('اللون')
                    ->maxLength(255)
                    ->placeholder('#0F766E'),

                Toggle::make('is_active')
                    ->label('نشط')
                    ->default(true),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('required_points')
            ->columns([
                TextColumn::make('name_ar')
                    ->label('اسم الوسام')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('slug')
                    ->label('المعرف')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('category')
                    ->label('التصنيف')
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'learning' => 'التعلم',
                        'progress' => 'التقدم',
                        'library' => 'المكتبة',
                        'community' => 'المجتمع',
                        'mentorship' => 'الإرشاد',
                        default => $state,
                    })
                    ->badge()
                    ->sortable(),

                TextColumn::make('required_points')
                    ->label('النقاط المطلوبة')
                    ->sortable(),

                TextColumn::make('icon')
                    ->label('الأيقونة')
                    ->toggleable(),

                TextColumn::make('color')
                    ->label('اللون')
                    ->toggleable(),

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
                SelectFilter::make('category')
                    ->label('التصنيف')
                    ->options([
                        'learning' => 'التعلم',
                        'progress' => 'التقدم',
                        'library' => 'المكتبة',
                        'community' => 'المجتمع',
                        'mentorship' => 'الإرشاد',
                    ]),

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
            'index' => Pages\ManageBadges::route('/'),
        ];
    }
}