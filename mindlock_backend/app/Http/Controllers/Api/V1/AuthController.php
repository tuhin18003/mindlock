<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Requests\Auth\ForgotPasswordRequest;
use App\Http\Requests\Auth\ResetPasswordRequest;
use App\Http\Resources\Auth\AuthUserResource;
use App\Models\DeviceSession;
use App\Models\User;
use App\Services\EntitlementResolver;
use App\Services\FeatureGateService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function __construct(
        private readonly EntitlementResolver $entitlementResolver,
        private readonly FeatureGateService $featureGateService,
    ) {}

    public function register(RegisterRequest $request): JsonResponse
    {
        $user = User::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'password' => Hash::make($request->password),
            'timezone' => $request->timezone ?? 'UTC',
        ]);

        // Create default notification preferences
        $user->notificationPreferences()->create();
        $user->streak()->create();

        // Create default free entitlement
        $this->entitlementResolver->grant($user, 'admin_grant');

        $this->createDeviceSession($user, $request);

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'success' => true,
            'data' => [
                'user'        => new AuthUserResource($user),
                'token'       => $token,
                'entitlement' => $this->entitlementResolver->getSummary($user),
                'gates'       => $this->featureGateService->getGates($user),
            ],
        ], 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        if ($user->status !== 'active') {
            return response()->json([
                'success' => false,
                'message' => 'Your account has been suspended.',
            ], 403);
        }

        $this->createDeviceSession($user, $request);
        $user->update(['last_active_at' => now()]);

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'success' => true,
            'data' => [
                'user'        => new AuthUserResource($user),
                'token'       => $token,
                'entitlement' => $this->entitlementResolver->getSummary($user),
                'gates'       => $this->featureGateService->getGates($user),
            ],
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        // Mark device session inactive
        if ($request->has('device_id')) {
            DeviceSession::where('user_id', $request->user()->id)
                ->where('device_id', $request->device_id)
                ->update(['is_active' => false]);
        }

        return response()->json(['success' => true, 'message' => 'Logged out.']);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->load(['activeEntitlement', 'streak', 'notificationPreferences']);

        return response()->json([
            'success' => true,
            'data' => [
                'user'        => new AuthUserResource($user),
                'entitlement' => $this->entitlementResolver->getSummary($user),
                'gates'       => $this->featureGateService->getGates($user),
            ],
        ]);
    }

    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        Password::sendResetLink($request->only('email'));

        return response()->json([
            'success' => true,
            'message' => 'If an account exists with that email, a reset link has been sent.',
        ]);
    }

    public function resetPassword(ResetPasswordRequest $request): JsonResponse
    {
        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function (User $user, string $password) {
                $user->forceFill(['password' => Hash::make($password)])
                     ->setRememberToken(Str::random(60));
                $user->save();
            }
        );

        if ($status !== Password::PASSWORD_RESET) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired reset token.',
            ], 422);
        }

        return response()->json(['success' => true, 'message' => 'Password reset successfully.']);
    }

    private function createDeviceSession(User $user, Request $request): void
    {
        $deviceId = $request->header('X-Device-ID') ?? $request->device_id ?? Str::uuid();

        DeviceSession::updateOrCreate(
            ['user_id' => $user->id, 'device_id' => $deviceId],
            [
                'device_name' => $request->header('X-Device-Name'),
                'platform'    => $request->header('X-Platform', 'android'),
                'os_version'  => $request->header('X-OS-Version'),
                'app_version' => $request->header('X-App-Version'),
                'timezone'    => $request->timezone ?? $request->header('X-Timezone'),
                'is_active'   => true,
                'last_seen_at' => now(),
            ]
        );
    }
}
