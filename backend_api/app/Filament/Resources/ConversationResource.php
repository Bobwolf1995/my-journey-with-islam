<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ConversationResource\Pages;
use App\Models\Conversation;
use App\Models\User;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class ConversationResource extends Resource
{
    protected static ?string $model = Conversation::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedChatBubbleLeftRight;

    protected static ?string $recordTitleAttribute = 'title';

    protected static ?string $navigationLabel = 'المحادثات';

    protected static ?string $modelLabel = 'محادثة';

    protected static ?string $pluralModelLabel = 'المحادثات';
    protected static string|\UnitEnum|null $navigationGroup = 'الرسائل';


    protected static ?int $navigationSort = 1;

    public static function canViewAny(): bool
    {
        return auth()->user()?->can('answer students') ?? false;
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canEdit($record): bool
    {
        return false;
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
            ->components([]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->withCount(['participants', 'messages']))
            ->defaultSort('last_message_at', 'desc')
            ->columns([
                TextColumn::make('title')
                    ->label('العنوان')
                    ->searchable()
                    ->sortable()
                    ->placeholder('بدون عنوان'),

                TextColumn::make('type')
                    ->label('النوع')
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'mentor' => 'مرشد',
                        'support' => 'دعم',
                        'admin' => 'إدارة',
                        default => $state,
                    })
                    ->badge()
                    ->sortable(),

                TextColumn::make('participants_count')
                    ->label('المشاركون')
                    ->sortable(),

                TextColumn::make('messages_count')
                    ->label('الرسائل')
                    ->sortable(),

                TextColumn::make('last_message_at')
                    ->label('آخر رسالة')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->placeholder('-'),

                TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('Y-m-d H:i')
                    ->sortable(),
            ])
            ->filters([
                SelectFilter::make('type')
                    ->label('النوع')
                    ->options([
                        'mentor' => 'مرشد',
                        'support' => 'دعم',
                        'admin' => 'إدارة',
                    ]),

                SelectFilter::make('created_by')
                    ->label('أنشئت بواسطة')
                    ->options(fn (): array => User::query()
                        ->orderBy('name')
                        ->pluck('name', 'id')
                        ->toArray()),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ManageConversations::route('/'),
        ];
    }
}