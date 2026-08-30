<?php

namespace App\Filament\Resources;

use App\Filament\Resources\MessageResource\Pages;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class MessageResource extends Resource
{
    protected static ?string $model = Message::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedChatBubbleOvalLeftEllipsis;

    protected static ?string $recordTitleAttribute = 'body';

    protected static ?string $navigationLabel = 'الرسائل';

    protected static ?string $modelLabel = 'رسالة';

    protected static ?string $pluralModelLabel = 'الرسائل';
    protected static string|\UnitEnum|null $navigationGroup = 'الرسائل';


    protected static ?int $navigationSort = 2;

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
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['conversation', 'sender'])->withCount('attachments'))
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('conversation.title')
                    ->label('المحادثة')
                    ->searchable()
                    ->sortable()
                    ->placeholder('بدون عنوان'),

                TextColumn::make('sender.name')
                    ->label('المرسل')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('body')
                    ->label('الرسالة')
                    ->limit(100)
                    ->searchable()
                    ->placeholder('-'),

                TextColumn::make('message_type')
                    ->label('نوع الرسالة')
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'text' => 'نص',
                        'file' => 'ملف',
                        'image' => 'صورة',
                        'audio' => 'صوت',
                        default => $state,
                    })
                    ->badge()
                    ->sortable(),

                IconColumn::make('is_read')
                    ->label('مقروءة')
                    ->boolean()
                    ->sortable(),

                TextColumn::make('attachments_count')
                    ->label('المرفقات')
                    ->sortable(),

                TextColumn::make('created_at')
                    ->label('تاريخ الإرسال')
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

                SelectFilter::make('sender_id')
                    ->label('المرسل')
                    ->options(fn (): array => User::query()
                        ->orderBy('name')
                        ->pluck('name', 'id')
                        ->toArray()),

                SelectFilter::make('message_type')
                    ->label('نوع الرسالة')
                    ->options([
                        'text' => 'نص',
                        'file' => 'ملف',
                        'image' => 'صورة',
                        'audio' => 'صوت',
                    ]),

                SelectFilter::make('is_read')
                    ->label('حالة القراءة')
                    ->options([
                        '1' => 'مقروءة',
                        '0' => 'غير مقروءة',
                    ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ManageMessages::route('/'),
        ];
    }
}