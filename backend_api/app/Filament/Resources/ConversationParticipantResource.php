<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ConversationParticipantResource\Pages;
use App\Models\Conversation;
use App\Models\ConversationParticipant;
use App\Models\User;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class ConversationParticipantResource extends Resource
{
    protected static ?string $model = ConversationParticipant::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedUserGroup;

    protected static ?string $navigationLabel = 'مشاركو المحادثات';

    protected static ?string $modelLabel = 'مشارك محادثة';

    protected static ?string $pluralModelLabel = 'مشاركو المحادثات';
    protected static string|\UnitEnum|null $navigationGroup = 'الرسائل';


    protected static ?int $navigationSort = 91;

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
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['conversation', 'user']))
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('conversation.title')
                    ->label('المحادثة')
                    ->searchable()
                    ->sortable()
                    ->placeholder('بدون عنوان'),

                TextColumn::make('conversation.type')
                    ->label('نوع المحادثة')
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'mentor' => 'مرشد',
                        'support' => 'دعم',
                        'admin' => 'إدارة',
                        default => $state,
                    })
                    ->badge()
                    ->sortable(),

                TextColumn::make('user.name')
                    ->label('المستخدم')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('user.email')
                    ->label('البريد الإلكتروني')
                    ->searchable()
                    ->toggleable(),

                TextColumn::make('last_read_at')
                    ->label('آخر قراءة')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->placeholder('-'),

                TextColumn::make('created_at')
                    ->label('تاريخ الإضافة')
                    ->dateTime('Y-m-d H:i')
                    ->sortable(),
            ])
            ->filters([
                SelectFilter::make('conversation_id')
                    ->label('المحادثة')
                    ->options(fn (): array => Conversation::query()
                        ->orderByDesc('last_message_at')
                        ->get()
                        ->mapWithKeys(fn (Conversation $conversation): array => [
                            $conversation->id => $conversation->title ?? 'محادثة #' . $conversation->id,
                        ])
                        ->toArray()),

                SelectFilter::make('user_id')
                    ->label('المستخدم')
                    ->options(fn (): array => User::query()
                        ->orderBy('name')
                        ->pluck('name', 'id')
                        ->toArray()),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ManageConversationParticipants::route('/'),
        ];
    }
}