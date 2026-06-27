package prm.projectbase.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import prm.projectbase.dto.request.PeerReviewRequest;
import prm.projectbase.dto.response.BaseResponse;
import prm.projectbase.dto.response.PeerReviewResponse;
import prm.projectbase.dto.response.ProjectGroupListResponse;
import prm.projectbase.service.PeerReviewService;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class PeerReviewController {

    private final PeerReviewService peerReviewService;

    /**
     * Student gets list of project groups they can peer review in a classroom
     * GET /api/v1/student/classrooms/{classroomId}/peer-review/targets
     */
    @GetMapping("/student/classrooms/{classroomId}/peer-review/targets")
    public ResponseEntity<BaseResponse<List<ProjectGroupListResponse>>> getPeerReviewTargets(
            @PathVariable Long classroomId) {

        log.info("GET /student/classrooms/{}/peer-review/targets - Fetching targets", classroomId);

        List<ProjectGroupListResponse> response = peerReviewService.getPeerReviewTargets(classroomId);
        return ResponseEntity.ok(BaseResponse.success(response, "Get peer review targets successfully"));
    }

    /**
     * Student submits/creates/updates a peer review
     * POST /api/v1/student/peer-reviews
     */
    @PostMapping("/student/peer-reviews")
    public ResponseEntity<BaseResponse<PeerReviewResponse>> createOrUpdatePeerReview(
            @Valid @RequestBody PeerReviewRequest request) {

        log.info("POST /student/peer-reviews - Submitting review");

        PeerReviewResponse response = peerReviewService.createOrUpdatePeerReview(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(BaseResponse.success(response, "Peer review submitted successfully", HttpStatus.CREATED));
    }

    /**
     * Student gets all peer reviews they have made in a classroom
     * GET /api/v1/student/classrooms/{classroomId}/peer-reviews/me
     */
    @GetMapping("/student/classrooms/{classroomId}/peer-reviews/me")
    public ResponseEntity<BaseResponse<List<PeerReviewResponse>>> getStudentPeerReviewsMe(
            @PathVariable Long classroomId) {

        log.info("GET /student/classrooms/{}/peer-reviews/me - Fetching reviews made by current student", classroomId);

        List<PeerReviewResponse> response = peerReviewService.getStudentPeerReviewsMe(classroomId);
        return ResponseEntity.ok(BaseResponse.success(response, "Get peer reviews made by you successfully"));
    }
}
