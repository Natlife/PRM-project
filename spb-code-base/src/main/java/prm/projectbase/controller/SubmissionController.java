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

    @PutMapping("/student/activities/{activityId}/submission")
    public ResponseEntity<BaseResponse<SubmissionDetailResponse>> updateSubmission(
            @PathVariable Long activityId,
            @Valid @RequestBody SubmissionUpdateRequest request) {
        
        log.info("PUT /student/activities/{}/submission - Updating submission", activityId);
        
        SubmissionDetailResponse response = submissionService.submitActivity(activityId, request);
        return ResponseEntity.ok(BaseResponse.success(response));
    }

    @PostMapping("/student/activities/{activityId}/submission/finalize")
    public ResponseEntity<BaseResponse<SubmissionDetailResponse>> finalizeSubmission(
            @PathVariable Long activityId) {
        
        log.info("POST /student/activities/{}/submission/finalize - Finalizing submission", activityId);
        
        SubmissionDetailResponse response = submissionService.finalizeSubmission(activityId);
        return ResponseEntity.ok(BaseResponse.success(response));
    }

    @GetMapping("/student/activities/{activityId}/submission")
    public ResponseEntity<BaseResponse<SubmissionDetailResponse>> getStudentSubmission(
            @PathVariable Long activityId) {
        
        log.info("GET /student/activities/{}/submission - Fetching student submission", activityId);
        
        SubmissionDetailResponse response = submissionService.getStudentSubmission(activityId);
        return ResponseEntity.ok(BaseResponse.success(response));
    }

    @GetMapping("/teacher/activities/{activityId}/submissions")
    public ResponseEntity<BaseResponse<List<SubmissionListResponse>>> getActivitySubmissions(
            @PathVariable Long activityId) {
        
        log.info("GET /teacher/activities/{}/submissions - Fetching all submissions", activityId);
        
        List<SubmissionListResponse> response = submissionService.getActivitySubmissions(activityId);
        return ResponseEntity.ok(BaseResponse.success(response));
    }

    @GetMapping("/teacher/submissions/{submissionId}")
    public ResponseEntity<BaseResponse<SubmissionDetailResponse>> getSubmission(
            @PathVariable Long submissionId) {
        
        log.info("GET /teacher/submissions/{} - Fetching submission detail", submissionId);
        
        SubmissionDetailResponse response = submissionService.getSubmission(submissionId);
        return ResponseEntity.ok(BaseResponse.success(response));
    }

    @PutMapping("/teacher/submissions/{submissionId}/grade")
    public ResponseEntity<BaseResponse<SubmissionDetailResponse>> gradeSubmission(
            @PathVariable Long submissionId,
            @Valid @RequestBody GradeSubmissionRequest request) {
        
        log.info("PUT /teacher/submissions/{}/grade - Grading submission", submissionId);
        
        SubmissionDetailResponse response = submissionService.gradeSubmission(submissionId, request);
        return ResponseEntity.ok(BaseResponse.success(response));
    }

    @PostMapping("/submissions/{submissionId}/comments")
    public ResponseEntity<BaseResponse<SubmissionCommentResponse>> addComment(
            @PathVariable Long submissionId,
            @Valid @RequestBody SubmissionCommentRequest request) {
        
        log.info("POST /submissions/{}/comments - Adding comment", submissionId);
        
        SubmissionCommentResponse response = submissionService.addComment(submissionId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(BaseResponse.success(response, "Comment added successfully", HttpStatus.CREATED));
    }

    @GetMapping("/submissions/{submissionId}/comments")
    public ResponseEntity<BaseResponse<List<SubmissionCommentResponse>>> getSubmissionComments(
            @PathVariable Long submissionId) {
        
        log.info("GET /submissions/{}/comments - Fetching comments", submissionId);
        
        List<SubmissionCommentResponse> response = submissionService.getSubmissionComments(submissionId);
        return ResponseEntity.ok(BaseResponse.success(response));
    }
}
