package prm.projectbase.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import prm.projectbase.dto.request.SubmissionUpdateRequest;
import prm.projectbase.dto.request.GradeSubmissionRequest;
import prm.projectbase.dto.request.SubmissionCommentRequest;
import prm.projectbase.dto.response.BaseResponse;
import prm.projectbase.dto.response.SubmissionDetailResponse;
import prm.projectbase.dto.response.SubmissionListResponse;
import prm.projectbase.dto.response.SubmissionCommentResponse;
import prm.projectbase.service.SubmissionService;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class SubmissionController {
    
    private final SubmissionService submissionService;
    
    /**
     * Student creates or updates their submission (draft)
     * PUT /api/v1/student/activities/{activityId}/submission
     */
    @PutMapping("/student/activities/{activityId}/submission")
    public ResponseEntity<BaseResponse<SubmissionDetailResponse>> updateSubmission(
            @PathVariable Long activityId,
            @Valid @RequestBody SubmissionUpdateRequest request) {
        
        log.info("PUT /student/activities/{}/submission - Updating submission", activityId);
        
        SubmissionDetailResponse response = submissionService.submitActivity(activityId, request);
        return ResponseEntity.ok(BaseResponse.success(response));
    }
    
    /**
     * Student finalizes their submission (marks as submitted)
     * POST /api/v1/student/activities/{activityId}/submission/finalize
     */
    @PostMapping("/student/activities/{activityId}/submission/finalize")
    public ResponseEntity<BaseResponse<SubmissionDetailResponse>> finalizeSubmission(
            @PathVariable Long activityId) {
        
        log.info("POST /student/activities/{}/submission/finalize - Finalizing submission", activityId);
        
        SubmissionDetailResponse response = submissionService.finalizeSubmission(activityId);
        return ResponseEntity.ok(BaseResponse.success(response));
    }
    
    /**
     * Student gets their submission
     * GET /api/v1/student/activities/{activityId}/submission
     */
    @GetMapping("/student/activities/{activityId}/submission")
    public ResponseEntity<BaseResponse<SubmissionDetailResponse>> getStudentSubmission(
            @PathVariable Long activityId) {
        
        log.info("GET /student/activities/{}/submission - Fetching student submission", activityId);
        
        SubmissionDetailResponse response = submissionService.getStudentSubmission(activityId);
        return ResponseEntity.ok(BaseResponse.success(response));
    }
    
    /**
     * Teacher gets all submissions for an activity
     * GET /api/v1/teacher/activities/{activityId}/submissions
     */
    @GetMapping("/teacher/activities/{activityId}/submissions")
    public ResponseEntity<BaseResponse<List<SubmissionListResponse>>> getActivitySubmissions(
            @PathVariable Long activityId) {
        
        log.info("GET /teacher/activities/{}/submissions - Fetching all submissions", activityId);
        
        List<SubmissionListResponse> response = submissionService.getActivitySubmissions(activityId);
        return ResponseEntity.ok(BaseResponse.success(response));
    }
    
    /**
     * Teacher gets a specific submission
     * GET /api/v1/teacher/submissions/{submissionId}
     */
    @GetMapping("/teacher/submissions/{submissionId}")
    public ResponseEntity<BaseResponse<SubmissionDetailResponse>> getSubmission(
            @PathVariable Long submissionId) {
        
        log.info("GET /teacher/submissions/{} - Fetching submission detail", submissionId);
        
        SubmissionDetailResponse response = submissionService.getSubmission(submissionId);
        return ResponseEntity.ok(BaseResponse.success(response));
    }
    
    /**
     * Teacher grades a submission
     * PUT /api/v1/teacher/submissions/{submissionId}/grade
     */
    @PutMapping("/teacher/submissions/{submissionId}/grade")
    public ResponseEntity<BaseResponse<SubmissionDetailResponse>> gradeSubmission(
            @PathVariable Long submissionId,
            @Valid @RequestBody GradeSubmissionRequest request) {
        
        log.info("PUT /teacher/submissions/{}/grade - Grading submission", submissionId);
        
        SubmissionDetailResponse response = submissionService.gradeSubmission(submissionId, request);
        return ResponseEntity.ok(BaseResponse.success(response));
    }
    
    /**
     * Add a comment to a submission (teacher feedback or student reply)
     * POST /api/v1/submissions/{submissionId}/comments
     */
    @PostMapping("/submissions/{submissionId}/comments")
    public ResponseEntity<BaseResponse<SubmissionCommentResponse>> addComment(
            @PathVariable Long submissionId,
            @Valid @RequestBody SubmissionCommentRequest request) {
        
        log.info("POST /submissions/{}/comments - Adding comment", submissionId);
        
        SubmissionCommentResponse response = submissionService.addComment(submissionId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(BaseResponse.success(response, "Comment added successfully", HttpStatus.CREATED));
    }
    
    /**
     * Get all comments for a submission
     * GET /api/v1/submissions/{submissionId}/comments
     */
    @GetMapping("/submissions/{submissionId}/comments")
    public ResponseEntity<BaseResponse<List<SubmissionCommentResponse>>> getSubmissionComments(
            @PathVariable Long submissionId) {
        
        log.info("GET /submissions/{}/comments - Fetching comments", submissionId);
        
        List<SubmissionCommentResponse> response = submissionService.getSubmissionComments(submissionId);
        return ResponseEntity.ok(BaseResponse.success(response));
    }
}
