<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CommunityGroupResource\Pages;
use App\Models\CommunityGroup;
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

class CommunityGroupResource extends Resource
{
    protected static ?string $model = CommunityGroup::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedChatBubbleLeftRight;

    protected static ?string $recordTitleAttribute = 'name_ar';

    protected static ?string $navigationLabel = 'مجموعات المجتمع';

    protected static ?string $modelLabel = 'مجموعة مجتمع';

    protected static ?string $pluralModelLabel = 'مجموعات المجتمع';
    protected static string|\UnitEnum|null $navigationGroup = 'المجتمع';


    protected static ?int $navigationSort = 1;

    public static function canViewAny(): bool
    {
        return auth()->user()?->can('manage community') ?? false;
    }

    public static function canCreate(): bool
    {
        return auth()->user()?->can('manage community') ?? false;
    }

    public static function canEdit($record): bool
    {
        return auth()->user()?->can('manage community') ?? false;
    }


    public static function canDelete($record): bool
    {
        return auth()->user()?->can('manage community') ?? false;
    }

    public static function canDeleteAny(): bool
    {
        return auth()->user()?->can('manage community') ?? false;
    }
    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('name_ar')
                    ->label('اسم المجموعة')
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

                TextInput::make('icon')
                    ->label('الأيقونة')
                    ->maxLength(255),

                TextInput::make('color')
                    ->label('اللون')
                    ->maxLength(255)
                    ->placeholder('#0F766E'),

                Select::make('visibility')
                    ->label('الظهور')
                    ->options([
                        'public' => 'عام',
                        'private' => 'خاص',
                    ])
                    ->required()
                    ->native(false)
                    ->default('public'),

                Toggle::make('is_active')
                    ->label('نشط')
                    ->default(true),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('name_ar')
                    ->label('اسم المجموعة')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('slug')
                    ->label('المعرف')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('visibility')
                    ->label('الظهور')
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'public' => 'عام',
                        'private' => 'خاص',
                        default => $state,
                    })
                    ->badge()
                    ->sortable(),

                TextColumn::make('icon')
                    ->label('الأيقونة')
                    ->toggleable(isToggledHiddenByDefault: true),

                TextColumn::make('color')
                    ->label('اللون')
                    ->toggleable(isToggledHiddenByDefault: true),

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
                SelectFilter::make('visibility')
                    ->label('الظهور')
                    ->options([
                        'public' => 'عام',
                        'private' => 'خاص',
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
            'index' => Pages\ManageCommunityGroups::route('/'),
        ];
    }
}