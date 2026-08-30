<?php

namespace App\Filament\Resources\LibraryCategoryResource\Pages;

use App\Filament\Resources\LibraryCategoryResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ManageRecords;

class ManageLibraryCategories extends ManageRecords
{
    protected static string $resource = LibraryCategoryResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}