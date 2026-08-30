<?php

namespace App\Filament\Resources\MentorNoteResource\Pages;

use App\Filament\Resources\MentorNoteResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ManageRecords;

class ManageMentorNotes extends ManageRecords
{
    protected static string $resource = MentorNoteResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}