package prm.projectbase.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import prm.projectbase.dto.request.ActivityCreateRequest;
import prm.projectbase.dto.request.ActivityUpdateRequest;
import prm.projectbase.dto.response.BaseResponse;
import prm.projectbase.dto.response.ActivityDetailResponse;
import prm.projectbase.dto.response.ActivityListResponse;
import prm.projectbase.service.ActivityService;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class ActivityController {
    
    private final ActivityService activityService;
    
    /**
     * Teacher creates a learning activity in a classroom
     * POST /api/v1/teacher/classrooms/{classroomId}/activities
     */
    @PostMapping("/teacher/classrooms/{classroomId}/activities")
    public ResponseEntity<BaseResponse<ActivityDetailResponse>> createActivity(
            @PathVariable Long classroomId,
            @Valid @RequestBody ActivityCreateRequest request) {
        
        log.info("POST /teacher/classrooms/{}/activities - Creating activity", classroomId);
        
        ActivityDetailResponse response = activityService.createActivity(classroomId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(BaseResponse.success(response, "Activity created successfully", HttpStatus.CREATED));
    }
    
    /**
     * Teacher updates an activity
     * PUT /api/v1/teacher/activities/{activityId}
     */
    @PutMapping("/teacher/activities/{activityId}")
    public ResponseEntity<BaseResponse<ActivityDetailResponse>> updateActivity(
            @PathVariable Long activityId,
            @Valid @RequestBody ActivityUpdateRequest request) {
        
        log.info("PUT /teacher/activities/{} - Updating activity", activityId);
        
        ActivityDetailResponse response = activityService.updateActivity(activityId, request);
        return ResponseEntity.ok(BaseResponse.success(response));
    }
    
    /**
     * Get all activities in a classroom for teacher
     * GET /api/v1/teacher/classrooms/{classroomId}/activities
     */
    @GetMapping("/teacher/classrooms/{classroomId}/activities")
    public ResponseEntity<BaseResponse<List<ActivityListResponse>>> getTeacherActivities(
            @PathVariable Long classroomId) {
        
        log.info("GET /teacher/classrooms/{}/activities - Fetching activities", classroomId);
        
        List<ActivityListResponse> response = activityService.getClassroomActivitiesForTeacher(classroomId);
        return ResponseEntity.ok(BaseResponse.success(response));
    }
    
    /**
     * Get published activities in a classroom for student
     * GET /api/v1/student/classrooms/{classroomId}/activities
     */
    @GetMapping("/student/classrooms/{classroomId}/activities")
    public ResponseEntity<BaseResponse<List<ActivityListResponse>>> getStudentActivities(
            @PathVariable Long classroomId) {
        
        log.info("GET /student/classrooms/{}/activities - Fetching published activities", classroomId);
        
        List<ActivityListResponse> response = activityService.getClassroomActivitiesForStudent(classroomId);
        return ResponseEntity.ok(BaseResponse.success(response));
    }
    
    /**
     * Get teacher activity detail
     * GET /api/v1/teacher/activities/{activityId}
     */
    @GetMapping("/teacher/activities/{activityId}")
    public ResponseEntity<BaseResponse<ActivityDetailResponse>> getTeacherActivityDetail(
            @PathVariable Long activityId) {
        
        log.info("GET /teacher/activities/{} - Fetching activity detail", activityId);
        
        ActivityDetailResponse response = activityService.getActivityDetail(activityId);
        return ResponseEntity.ok(BaseResponse.success(response));
    }
    
    /**
     * Get student activity detail
     * GET /api/v1/student/activities/{activityId}
     */
    @GetMapping("/student/activities/{activityId}")
    public ResponseEntity<BaseResponse<ActivityDetailResponse>> getStudentActivityDetail(
            @PathVariable Long activityId) {
        
        log.info("GET /student/activities/{} - Fetching activity detail", activityId);
        
        ActivityDetailResponse response = activityService.getActivityDetail(activityId);
        return ResponseEntity.ok(BaseResponse.success(response));
    }
}
