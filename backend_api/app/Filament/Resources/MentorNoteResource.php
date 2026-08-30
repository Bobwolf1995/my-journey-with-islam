<?php

namespace App\Filament\Resources;

use App\Filament\Resources\MentorNoteResource\Pages;
use App\Models\Mentor;
use App\Models\MentorNote;
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

class MentorNoteResource extends Resource
{
    protected static ?string $model = MentorNote::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedClipboardDocumentList;

    protected static ?string $recordTitleAttribute = 'note';

    protected static ?string $navigationLabel = 'ملاحظات المرشدين';

    protected static ?string $modelLabel = 'ملاحظة مرشد';

    protected static ?string $pluralModelLabel = 'ملاحظات المرشدين';
    protected static string|\UnitEnum|null $navigationGroup = 'المرشدون';


    protected static ?int $navigationSort = 3;

    public static function canViewAny(): bool
    {
        return auth()->user()?->can('manage mentors') ?? false;
    }

    public static function canCreate(): bool
    {
        return auth()->user()?->can('manage mentors') ?? false;
    }

    public static function canEdit($record): bool
    {
        return auth()->user()?->can('manage mentors') ?? false;
    }


    public static function canDelete($record): bool
    {
        return auth()->user()?->can('manage mentors') ?? false;
    }

    public static function canDeleteAny(): bool
    {
        return auth()->user()?->can('manage mentors') ?? false;
    }
    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('mentor_id')
                    ->label('المرشد')
                    ->relationship('mentor.user', 'name')
                    ->searchable()
                    ->preload()
                    ->required()
                    ->native(false),

                Select::make('student_id')
                    ->label('الطالب')
                    ->relationship('student', 'name')
                    ->searchable()
                    ->preload()
                    ->required()
                    ->native(false),

                Textarea::make('note')
                    ->label('الملاحظة')
                    ->required()
                    ->rows(7)
                    ->columnSpanFull(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['mentor.user', 'student']))
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('mentor.user.name')
                    ->label('المرشد')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('student.name')
                    ->label('الطالب')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('note')
                    ->label('الملاحظة')
                    ->limit(80)
                    ->searchable(),

                TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('Y-m-d H:i')
                    ->sortable(),
            ])
            ->filters([
                SelectFilter::make('mentor_id')
                    ->label('المرشد')
                    ->options(fn (): array => Mentor::query()
                        ->with('user')
                        ->get()
                        ->mapWithKeys(fn (Mentor $mentor): array => [
                            $mentor->id => $mentor->user?->name ?? 'مرشد #' . $mentor->id,
                        ])
                        ->toArray()),

                SelectFilter::make('student_id')
                    ->label('الطالب')
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
            'index' => Pages\ManageMentorNotes::route('/'),
        ];
    }
}
