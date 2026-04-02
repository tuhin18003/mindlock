<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
| The admin SPA is served from a single Blade view.
| All /admin/* routes fall through to the React app.
*/

Route::get('/admin/{any?}', function () {
    return view('admin');
})->where('any', '.*')->name('admin');

// Health check (non-API)
Route::get('/up', fn() => response()->json(['status' => 'ok', 'timestamp' => now()->toIso8601String()]));

// Root redirect
Route::get('/', fn() => redirect('/admin'));
