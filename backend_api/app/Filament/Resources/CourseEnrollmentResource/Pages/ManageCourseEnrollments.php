<?php

namespace App\Filament\Resources\CourseEnrollmentResource\Pages;

use App\Filament\Resources\CourseEnrollmentResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ManageRecords;

class ManageCourseEnrollments extends ManageRecords
{
    protected static string $resource = CourseEnrollmentResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}