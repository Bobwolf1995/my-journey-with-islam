<?php

namespace App\Filament\Resources;

use App\Filament\Resources\MessageAttachmentResource\Pages;
use App\Models\Message;
use App\Models\MessageAttachment;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class MessageAttachmentResource extends Resource
{
    protected static ?string $model = MessageAttachment::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedPaperClip;

    protected static ?string $recordTitleAttribute = 'file_name';

    protected static ?string $navigationLabel = 'مرفقات الرسائل';

    protected static ?string $modelLabel = 'مرفق رسالة';

    protected static ?string $pluralModelLabel = 'مرفقات الرسائل';
    protected static string|\UnitEnum|null $navigationGroup = 'الرسائل';


    protected static ?int $navigationSort = 90;

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
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with('message.sender'))
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('file_name')
                    ->label('اسم الملف')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('message.sender.name')
                    ->label('المرسل')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('file_type')
                    ->label('نوع الملف')
                    ->searchable()
                    ->sortable()
                    ->placeholder('-'),

                TextColumn::make('file_size')
                    ->label('الحجم')
                    ->formatStateUsing(fn ($state): string => $state === null ? '-' : number_format((int) $state / 1024, 2) . ' KB')
                    ->sortable(),

                TextColumn::make('file_url')
                    ->label('رابط الملف')
                    ->limit(60)
                    ->searchable()
                    ->toggleable(),

                TextColumn::make('created_at')
                    ->label('تاريخ الإضافة')
                    ->dateTime('Y-m-d H:i')
                    ->sortable(),
            ])
            ->filters([
                SelectFilter::make('message_id')
                    ->label('الرسالة')
                    ->options(fn (): array => Message::query()
                        ->orderByDesc('created_at')
                        ->get()
                        ->mapWithKeys(fn (Message $message): array => [
                            $message->id => 'رسالة #' . $message->id,
                        ])
                        ->toArray()),

                SelectFilter::make('file_type')
                    ->label('نوع الملف')
                    ->options(fn (): array => MessageAttachment::query()
                        ->whereNotNull('file_type')
                        ->distinct()
                        ->orderBy('file_type')
                        ->pluck('file_type', 'file_type')
                        ->toArray()),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ManageMessageAttachments::route('/'),
        ];
    }
}