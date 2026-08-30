<?php

namespace App\Filament\Resources\MentorStudentResource\Pages;

use App\Filament\Resources\MentorStudentResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ManageRecords;

class ManageMentorStudents extends ManageRecords
{
    protected static string $resource = MentorStudentResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}