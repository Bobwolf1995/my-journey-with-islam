<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\PermissionRegistrar;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class RolesAndPermissionsSeeder extends Seeder
{
    public function run(): void
    {
        app(PermissionRegistrar::class)->forgetCachedPermissions();

        $permissions = [
            'manage users',
            'manage roles',
            'manage courses',
            'manage lessons',
            'manage library',
            'manage orders',
            'manage community',
            'manage mentors',
            'view reports',
            'answer students',
            'review tasks',
            'access admin panel',
        ];

        foreach ($permissions as $permission) {
            Permission::firstOrCreate([
                'name' => $permission,
                'guard_name' => 'web',
            ]);
        }

        $admin = Role::firstOrCreate(['name' => 'admin', 'guard_name' => 'web']);
        $supervisor = Role::firstOrCreate(['name' => 'supervisor', 'guard_name' => 'web']);
        $teacher = Role::firstOrCreate(['name' => 'teacher', 'guard_name' => 'web']);
        $mentor = Role::firstOrCreate(['name' => 'mentor', 'guard_name' => 'web']);
        $student = Role::firstOrCreate(['name' => 'student', 'guard_name' => 'web']);

        $admin->syncPermissions($permissions);

        $supervisor->syncPermissions([
            'manage courses',
            'manage lessons',
            'manage library',
            'manage community',
            'manage mentors',
            'view reports',
            'answer students',
            'review tasks',
            'access admin panel',
        ]);

        $teacher->syncPermissions([
            'manage courses',
            'manage lessons',
            'review tasks',
            'answer students',
            'access admin panel',
        ]);

        $mentor->syncPermissions([
            'answer students',
            'review tasks',
            'view reports',
        ]);

        $student->syncPermissions([]);

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }
}