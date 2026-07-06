package prm.projectbase.controller;

import lombok.AccessLevel;
import lombok.experimental.FieldDefaults;
import prm.projectbase.dto.request.LoginRequest;
import prm.projectbase.dto.request.RegisterRequest;
import prm.projectbase.dto.response.AuthResponse;
import prm.projectbase.dto.response.BaseResponse;
import prm.projectbase.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AuthController {

    AuthService authService;

    @PostMapping("/register")
    public BaseResponse<AuthResponse> register(@RequestBody @Valid RegisterRequest request) {
        AuthResponse response = authService.register(request);
        return BaseResponse.success(response, "User registered successfully");
    }

    @PostMapping("/login")
    public BaseResponse<AuthResponse> login(@RequestBody @Valid LoginRequest request) {
        AuthResponse response = authService.login(request);
        return BaseResponse.success(response, "Login successful");
    }
}
