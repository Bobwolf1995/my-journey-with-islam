<?php

namespace App\Filament\Resources\LessonCompletionResource\Pages;

use App\Filament\Resources\LessonCompletionResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ManageRecords;

class ManageLessonCompletions extends ManageRecords
{
    protected static string $resource = LessonCompletionResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}