<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CommunityLikeResource\Pages;
use App\Models\CommunityLike;
use App\Models\CommunityPost;
use App\Models\User;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class CommunityLikeResource extends Resource
{
    protected static ?string $model = CommunityLike::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedHandThumbUp;

    protected static ?string $navigationLabel = 'إعجابات المجتمع';

    protected static ?string $modelLabel = 'إعجاب مجتمع';

    protected static ?string $pluralModelLabel = 'إعجابات المجتمع';
    protected static string|\UnitEnum|null $navigationGroup = 'المجتمع';


    protected static ?int $navigationSort = 99;

    public static function canViewAny(): bool
    {
        return auth()->user()?->can('manage community') ?? false;
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
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['post', 'user']))
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('post.title_ar')
                    ->label('المنشور')
                    ->searchable()
                    ->sortable()
                    ->placeholder('بدون عنوان'),

                TextColumn::make('user.name')
                    ->label('المستخدم')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('user.email')
                    ->label('البريد الإلكتروني')
                    ->searchable()
                    ->toggleable(),

                TextColumn::make('created_at')
                    ->label('تاريخ الإعجاب')
                    ->dateTime('Y-m-d H:i')
                    ->sortable(),
            ])
            ->filters([
                SelectFilter::make('community_post_id')
                    ->label('المنشور')
                    ->options(fn (): array => CommunityPost::query()
                        ->orderByDesc('created_at')
                        ->get()
                        ->mapWithKeys(fn (CommunityPost $post): array => [
                            $post->id => $post->title_ar ?? 'منشور #' . $post->id,
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
            'index' => Pages\ManageCommunityLikes::route('/'),
        ];
    }
}