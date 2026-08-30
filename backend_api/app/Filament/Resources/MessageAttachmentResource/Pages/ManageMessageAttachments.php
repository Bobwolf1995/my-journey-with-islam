<?php

namespace App\Filament\Resources\MessageAttachmentResource\Pages;

use App\Filament\Resources\MessageAttachmentResource;
use Filament\Resources\Pages\ManageRecords;

class ManageMessageAttachments extends ManageRecords
{
    protected static string $resource = MessageAttachmentResource::class;

    protected function getHeaderActions(): array
    {
        return [];
    }
}