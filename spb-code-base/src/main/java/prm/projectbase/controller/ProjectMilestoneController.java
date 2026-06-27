package prm.projectbase.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import prm.projectbase.dto.request.MilestoneProgressUpdateRequest;
import prm.projectbase.dto.request.ProjectMilestoneCreateRequest;
import prm.projectbase.dto.request.ProjectMilestoneUpdateRequest;
import prm.projectbase.dto.response.BaseResponse;
import prm.projectbase.dto.response.MilestoneAttachmentResponse;
import prm.projectbase.dto.response.ProjectMilestoneResponse;
import prm.projectbase.service.ProjectMilestoneService;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class ProjectMilestoneController {

    private final ProjectMilestoneService milestoneService;

    /**
     * Teacher creates a milestone for a project group
     * POST /api/v1/teacher/project-groups/{groupId}/milestones
     */
    @PostMapping("/teacher/project-groups/{groupId}/milestones")
    public ResponseEntity<BaseResponse<ProjectMilestoneResponse>> createMilestone(
            @PathVariable Long groupId,
            @Valid @RequestBody ProjectMilestoneCreateRequest request) {

        log.info("POST /teacher/project-groups/{}/milestones - Creating milestone", groupId);

        ProjectMilestoneResponse response = milestoneService.createMilestone(groupId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(BaseResponse.success(response, "Milestone created successfully", HttpStatus.CREATED));
    }

    /**
     * Teacher updates a milestone (title, description, due date, status)
     * PUT /api/v1/teacher/milestones/{milestoneId}
     */
    @PutMapping("/teacher/milestones/{milestoneId}")
    public ResponseEntity<BaseResponse<ProjectMilestoneResponse>> updateMilestone(
            @PathVariable Long milestoneId,
            @Valid @RequestBody ProjectMilestoneUpdateRequest request) {

        log.info("PUT /teacher/milestones/{} - Updating milestone", milestoneId);

        ProjectMilestoneResponse response = milestoneService.updateMilestone(milestoneId, request);
        return ResponseEntity.ok(BaseResponse.success(response, "Milestone updated successfully"));
    }

    /**
     * Get all milestones for a project group
     * GET /api/v1/project-groups/{groupId}/milestones
     */
    @GetMapping("/project-groups/{groupId}/milestones")
    public ResponseEntity<BaseResponse<List<ProjectMilestoneResponse>>> getGroupMilestones(
            @PathVariable Long groupId) {

        log.info("GET /project-groups/{}/milestones - Fetching milestones", groupId);

        List<ProjectMilestoneResponse> response = milestoneService.getGroupMilestones(groupId);
        return ResponseEntity.ok(BaseResponse.success(response, "Get group milestones successfully"));
    }

    /**
     * Get details of a milestone
     * GET /api/v1/milestones/{milestoneId}
     */
    @GetMapping("/milestones/{milestoneId}")
    public ResponseEntity<BaseResponse<ProjectMilestoneResponse>> getMilestone(
            @PathVariable Long milestoneId) {

        log.info("GET /milestones/{} - Fetching milestone details", milestoneId);

        ProjectMilestoneResponse response = milestoneService.getMilestone(milestoneId);
        return ResponseEntity.ok(BaseResponse.success(response, "Get milestone details successfully"));
    }

    /**
     * Student updates progress percent and status of a milestone
     * PUT /api/v1/student/milestones/{milestoneId}/progress
     */
    @PutMapping("/student/milestones/{milestoneId}/progress")
    public ResponseEntity<BaseResponse<ProjectMilestoneResponse>> updateMilestoneProgress(
            @PathVariable Long milestoneId,
            @Valid @RequestBody MilestoneProgressUpdateRequest request) {

        log.info("PUT /student/milestones/{}/progress - Updating progress", milestoneId);

        ProjectMilestoneResponse response = milestoneService.updateMilestoneProgress(milestoneId, request);
        return ResponseEntity.ok(BaseResponse.success(response, "Milestone progress updated successfully"));
    }

    /**
     * Student uploads milestone evidence files
     * POST /api/v1/student/milestones/{milestoneId}/attachments
     */
    @PostMapping(value = "/student/milestones/{milestoneId}/attachments", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<BaseResponse<List<MilestoneAttachmentResponse>>> addMilestoneAttachment(
            @PathVariable Long milestoneId,
            @RequestParam("files") List<MultipartFile> files) {

        log.info("POST /student/milestones/{}/attachments - Uploading evidence", milestoneId);

        List<MilestoneAttachmentResponse> response = milestoneService.addMilestoneAttachment(milestoneId, files);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(BaseResponse.success(response, "Milestone attachments uploaded successfully", HttpStatus.CREATED));
    }
}
