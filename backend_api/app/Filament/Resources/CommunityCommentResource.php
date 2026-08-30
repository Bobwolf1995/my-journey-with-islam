<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CommunityCommentResource\Pages;
use App\Models\CommunityComment;
use App\Models\CommunityPost;
use App\Models\User;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Actions\DeleteAction;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class CommunityCommentResource extends Resource
{
    protected static ?string $model = CommunityComment::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedChatBubbleOvalLeftEllipsis;

    protected static ?string $recordTitleAttribute = 'content_ar';

    protected static ?string $navigationLabel = 'تعليقات المجتمع';

    protected static ?string $modelLabel = 'تعليق مجتمع';

    protected static ?string $pluralModelLabel = 'تعليقات المجتمع';
    protected static string|\UnitEnum|null $navigationGroup = 'المجتمع';


    protected static ?int $navigationSort = 3;

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
                Select::make('community_post_id')
                    ->label('المنشور')
                    ->relationship('post', 'title_ar')
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

                Textarea::make('content_ar')
                    ->label('التعليق')
                    ->required()
                    ->rows(6)
                    ->columnSpanFull(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['post', 'user']))
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('content_ar')
                    ->label('التعليق')
                    ->limit(80)
                    ->searchable(),

                TextColumn::make('post.title_ar')
                    ->label('المنشور')
                    ->limit(50)
                    ->searchable()
                    ->sortable()
                    ->placeholder('بدون عنوان'),

                TextColumn::make('user.name')
                    ->label('المستخدم')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
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
            ])
            ->recordActions([
                EditAction::make(),
                DeleteAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ManageCommunityComments::route('/'),
        ];
    }
}