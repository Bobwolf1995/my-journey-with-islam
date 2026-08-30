<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CommunityPostResource\Pages;
use App\Models\CommunityGroup;
use App\Models\CommunityPost;
use App\Models\User;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Actions\DeleteAction;
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

class CommunityPostResource extends Resource
{
    protected static ?string $model = CommunityPost::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedDocumentText;

    protected static ?string $recordTitleAttribute = 'title_ar';

    protected static ?string $navigationLabel = 'منشورات المجتمع';

    protected static ?string $modelLabel = 'منشور مجتمع';

    protected static ?string $pluralModelLabel = 'منشورات المجتمع';
    protected static string|\UnitEnum|null $navigationGroup = 'المجتمع';


    protected static ?int $navigationSort = 2;

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
                    ->native(false),

                Select::make('user_id')
                    ->label('الكاتب')
                    ->relationship('user', 'name')
                    ->searchable()
                    ->preload()
                    ->required()
                    ->native(false),

                TextInput::make('title_ar')
                    ->label('العنوان')
                    ->maxLength(255),

                Textarea::make('content_ar')
                    ->label('المحتوى')
                    ->required()
                    ->rows(8)
                    ->columnSpanFull(),

                Select::make('status')
                    ->label('الحالة')
                    ->options([
                        'published' => 'منشور',
                        'pending' => 'قيد المراجعة',
                        'hidden' => 'مخفي',
                        'rejected' => 'مرفوض',
                    ])
                    ->required()
                    ->native(false)
                    ->default('published'),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['group', 'user']))
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('title_ar')
                    ->label('العنوان')
                    ->searchable()
                    ->sortable()
                    ->placeholder('بدون عنوان'),

                TextColumn::make('user.name')
                    ->label('الكاتب')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('group.name_ar')
                    ->label('المجموعة')
                    ->searchable()
                    ->sortable()
                    ->placeholder('عام'),

                TextColumn::make('status')
                    ->label('الحالة')
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'published' => 'منشور',
                        'pending' => 'قيد المراجعة',
                        'hidden' => 'مخفي',
                        'rejected' => 'مرفوض',
                        default => $state,
                    })
                    ->badge()
                    ->sortable(),

                TextColumn::make('likes_count')
                    ->label('الإعجابات')
                    ->sortable(),

                TextColumn::make('comments_count')
                    ->label('التعليقات')
                    ->sortable(),

                TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('Y-m-d H:i')
                    ->sortable(),
            ])
            ->filters([
                SelectFilter::make('community_group_id')
                    ->label('المجموعة')
                    ->options(fn (): array => CommunityGroup::query()
                        ->orderBy('name_ar')
                        ->pluck('name_ar', 'id')
                        ->toArray()),

                SelectFilter::make('user_id')
                    ->label('الكاتب')
                    ->options(fn (): array => User::query()
                        ->orderBy('name')
                        ->pluck('name', 'id')
                        ->toArray()),

                SelectFilter::make('status')
                    ->label('الحالة')
                    ->options([
                        'published' => 'منشور',
                        'pending' => 'قيد المراجعة',
                        'hidden' => 'مخفي',
                        'rejected' => 'مرفوض',
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
            'index' => Pages\ManageCommunityPosts::route('/'),
        ];
    }
}