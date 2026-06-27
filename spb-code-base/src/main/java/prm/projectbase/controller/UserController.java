package prm.projectbase.controller;

import lombok.AccessLevel;
import lombok.experimental.FieldDefaults;
import prm.projectbase.config.AuthFilter;
import prm.projectbase.dto.request.UserCreateRequest;
import prm.projectbase.dto.request.UserUpdateRequest;
import prm.projectbase.dto.response.BaseResponse;
import prm.projectbase.dto.response.UserResponse;
import prm.projectbase.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class UserController {

    UserService userService;

    @PostMapping
    @AuthFilter(permission = "ADMIN")
    public BaseResponse<UserResponse> createUser(@RequestBody @Valid UserCreateRequest request) {
        UserResponse response = userService.createUser(request);
        return BaseResponse.success(response, "User created successfully");
    }

    @GetMapping
    @AuthFilter(permission = "ADMIN")
    public BaseResponse<List<UserResponse>> getAllUsers() {
        List<UserResponse> response = userService.getAllUsers();
        return BaseResponse.success(response, "Get all users successfully");
    }

    @GetMapping("/{id}")
    @AuthFilter(permission = "ADMIN") // Allowed for ADMIN Globally, or standard USER if viewing their own ID
    public BaseResponse<UserResponse> getUserById(@PathVariable Long id) {
        UserResponse response = userService.getUserById(id);
        return BaseResponse.success(response, "Get user by ID successfully");
    }

    @PutMapping("/{id}")
    @AuthFilter(permission = "ADMIN") // Allowed for ADMIN Globally, or standard USER if updating their own ID
    public BaseResponse<UserResponse> updateUser(@PathVariable Long id, @RequestBody @Valid UserUpdateRequest request) {
        UserResponse response = userService.updateUser(id, request);
        return BaseResponse.success(response, "User updated successfully");
    }

    @DeleteMapping("/{id}")
    @AuthFilter(permission = "ADMIN")
    public BaseResponse<Void> deleteUser(@PathVariable Long id) {
        userService.deleteUser(id);
        return BaseResponse.success(null, "User deleted successfully");
    }
}
