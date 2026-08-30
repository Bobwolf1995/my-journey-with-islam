<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CommunityGroupMemberResource\Pages;
use App\Models\CommunityGroup;
use App\Models\CommunityGroupMember;
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

class CommunityGroupMemberResource extends Resource
{
    protected static ?string $model = CommunityGroupMember::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedUsers;

    protected static ?string $navigationLabel = 'أعضاء المجموعات';

    protected static ?string $modelLabel = 'عضو مجموعة';

    protected static ?string $pluralModelLabel = 'أعضاء المجموعات';
    protected static string|\UnitEnum|null $navigationGroup = 'المجتمع';


    protected static ?int $navigationSort = 4;

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
                Select::make('community_group_id')
                    ->label('المجموعة')
                    ->relationship('group', 'name_ar')
                    ->searchable()
                    ->preload()
                    ->required()
                    ->native(false),

                Select::make('user_id')
                    ->label('المستخدم')
                    ->relationship('user', 'name')
                    ->searchable()
                    ->preload()
                    ->required()
                    ->native(false),

                Select::make('role')
                    ->label('الدور')
                    ->options([
                        'member' => 'عضو',
                        'moderator' => 'مشرف',
                        'admin' => 'مدير',
                    ])
                    ->required()
                    ->native(false)
                    ->default('member'),

                DateTimePicker::make('joined_at')
                    ->label('تاريخ الانضمام')
                    ->seconds(false),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['group', 'user']))
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('group.name_ar')
                    ->label('المجموعة')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('user.name')
                    ->label('المستخدم')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('user.email')
                    ->label('البريد الإلكتروني')
                    ->searchable()
                    ->toggleable(),

                TextColumn::make('role')
                    ->label('الدور')
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'member' => 'عضو',
                        'moderator' => 'مشرف',
                        'admin' => 'مدير',
                        default => $state,
                    })
                    ->badge()
                    ->sortable(),

                TextColumn::make('joined_at')
                    ->label('تاريخ الانضمام')
                    ->dateTime('Y-m-d H:i')
                    ->sortable(),

                TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('community_group_id')
                    ->label('المجموعة')
                    ->options(fn (): array => CommunityGroup::query()
                        ->orderBy('name_ar')
                        ->pluck('name_ar', 'id')
                        ->toArray()),

                SelectFilter::make('user_id')
                    ->label('المستخدم')
                    ->options(fn (): array => User::query()
                        ->orderBy('name')
                        ->pluck('name', 'id')
                        ->toArray()),

                SelectFilter::make('role')
                    ->label('الدور')
                    ->options([
                        'member' => 'عضو',
                        'moderator' => 'مشرف',
                        'admin' => 'مدير',
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
            'index' => Pages\ManageCommunityGroupMembers::route('/'),
        ];
    }
}