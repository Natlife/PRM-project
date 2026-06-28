package prm.projectbase.controller;

import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import prm.projectbase.dto.request.ClassroomCreateRequest;
import prm.projectbase.dto.request.ClassroomUpdateRequest;
import prm.projectbase.dto.request.StudentJoinClassroomRequest;
import prm.projectbase.dto.response.BaseResponse;
import prm.projectbase.dto.response.ClassroomDetailResponse;
import prm.projectbase.dto.response.ClassroomEnrollmentResponse;
import prm.projectbase.dto.response.ClassroomListResponse;
import prm.projectbase.dto.response.UserResponse;
import prm.projectbase.service.ClassroomService;

import java.util.List;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class ClassroomController {

    ClassroomService classroomService;

    @PostMapping("/teacher/classrooms")
    public BaseResponse<ClassroomDetailResponse> createClassroom(
            @RequestBody @Valid ClassroomCreateRequest request) {
        ClassroomDetailResponse response = classroomService.createClassroom(request);
        return BaseResponse.success(response, "Classroom created successfully", HttpStatus.CREATED);
    }

    @GetMapping("/teacher/classrooms")
    public BaseResponse<List<ClassroomListResponse>> getTeacherClassrooms() {
        List<ClassroomListResponse> response = classroomService.getTeacherClassrooms();
        return BaseResponse.success(response, "Classrooms retrieved successfully");
    }

    @GetMapping("/teacher/classrooms/{classroomId}")
    public BaseResponse<ClassroomDetailResponse> getClassroomDetail(
            @PathVariable Long classroomId) {
        ClassroomDetailResponse response = classroomService.getClassroomDetail(classroomId);
        return BaseResponse.success(response, "Classroom detail retrieved successfully");
    }

    @GetMapping("/teacher/classrooms/{classroomId}/students")
    public BaseResponse<List<UserResponse>> getTeacherClassroomStudents(
            @PathVariable Long classroomId) {
        List<UserResponse> response = classroomService.getTeacherClassroomStudents(classroomId);
        return BaseResponse.success(response, "Classroom students retrieved successfully");
    }

    @PutMapping("/teacher/classrooms/{classroomId}")
    public BaseResponse<ClassroomDetailResponse> updateClassroom(
            @PathVariable Long classroomId,
            @RequestBody @Valid ClassroomUpdateRequest request) {
        ClassroomDetailResponse response = classroomService.updateClassroom(classroomId, request);
        return BaseResponse.success(response, "Classroom updated successfully");
    }

    @PostMapping("/teacher/classrooms/{classroomId}/rotate-code")
    public BaseResponse<ClassroomDetailResponse> rotateJoinCode(
            @PathVariable Long classroomId) {
        ClassroomDetailResponse response = classroomService.rotateJoinCode(classroomId);
        return BaseResponse.success(response, "Classroom join code rotated successfully");
    }

    @PostMapping("/student/classrooms/join")
    public BaseResponse<ClassroomEnrollmentResponse> joinClassroom(
            @RequestBody @Valid StudentJoinClassroomRequest request) {
        ClassroomEnrollmentResponse response = classroomService.studentJoinClassroom(request.getJoinCode());
        return BaseResponse.success(response, "Classroom joined successfully", HttpStatus.CREATED);
    }

    @GetMapping("/student/classrooms")
    public BaseResponse<List<ClassroomListResponse>> getStudentClassrooms() {
        List<ClassroomListResponse> response = classroomService.getStudentClassrooms();
        return BaseResponse.success(response, "Classrooms retrieved successfully");
    }

    @GetMapping("/student/classrooms/{classroomId}")
    public BaseResponse<ClassroomDetailResponse> getStudentClassroomDetail(
            @PathVariable Long classroomId) {
        ClassroomDetailResponse response = classroomService.getStudentClassroomDetail(classroomId);
        return BaseResponse.success(response, "Classroom detail retrieved successfully");
    }
}
