package prm.projectbase.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import prm.projectbase.dto.request.ProjectGroupCreateRequest;
import prm.projectbase.dto.request.ProjectGroupUpdateRequest;
import prm.projectbase.dto.response.BaseResponse;
import prm.projectbase.dto.response.ProjectGroupDetailResponse;
import prm.projectbase.dto.response.ProjectGroupListResponse;
import prm.projectbase.service.ProjectGroupService;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class ProjectGroupController {

    private final ProjectGroupService groupService;

    /**
     * Teacher creates a project group in a classroom
     * POST /api/v1/teacher/classrooms/{classroomId}/project-groups
     */
    @PostMapping("/teacher/classrooms/{classroomId}/project-groups")
    public ResponseEntity<BaseResponse<ProjectGroupDetailResponse>> createProjectGroup(
            @PathVariable Long classroomId,
            @Valid @RequestBody ProjectGroupCreateRequest request) {

        log.info("POST /teacher/classrooms/{}/project-groups - Creating project group", classroomId);

        ProjectGroupDetailResponse response = groupService.createProjectGroup(classroomId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(BaseResponse.success(response, "Project group created successfully", HttpStatus.CREATED));
    }

    /**
     * Teacher gets all project groups in a classroom
     * GET /api/v1/teacher/classrooms/{classroomId}/project-groups
     */
    @GetMapping("/teacher/classrooms/{classroomId}/project-groups")
    public ResponseEntity<BaseResponse<List<ProjectGroupListResponse>>> getClassroomProjectGroupsForTeacher(
            @PathVariable Long classroomId) {

        log.info("GET /teacher/classrooms/{}/project-groups - Fetching project groups", classroomId);

        List<ProjectGroupListResponse> response = groupService.getClassroomProjectGroups(classroomId);
        return ResponseEntity.ok(BaseResponse.success(response, "Get classroom project groups successfully"));
    }

    /**
     * Teacher gets a specific project group detail
     * GET /api/v1/teacher/project-groups/{groupId}
     */
    @GetMapping("/teacher/project-groups/{groupId}")
    public ResponseEntity<BaseResponse<ProjectGroupDetailResponse>> getProjectGroupDetailForTeacher(
            @PathVariable Long groupId) {

        log.info("GET /teacher/project-groups/{} - Fetching group detail", groupId);

        ProjectGroupDetailResponse response = groupService.getProjectGroupDetail(groupId);
        return ResponseEntity.ok(BaseResponse.success(response, "Get project group detail successfully"));
    }

    /**
     * Teacher updates a project group (details, status, members)
     * PUT /api/v1/teacher/project-groups/{groupId}
     */
    @PutMapping("/teacher/project-groups/{groupId}")
    public ResponseEntity<BaseResponse<ProjectGroupDetailResponse>> updateProjectGroup(
            @PathVariable Long groupId,
            @Valid @RequestBody ProjectGroupUpdateRequest request) {

        log.info("PUT /teacher/project-groups/{} - Updating project group", groupId);

        ProjectGroupDetailResponse response = groupService.updateProjectGroup(groupId, request);
        return ResponseEntity.ok(BaseResponse.success(response, "Project group updated successfully"));
    }

    /**
     * Student gets their active project group in a classroom
     * GET /api/v1/student/classrooms/{classroomId}/project-group
     */
    @GetMapping("/student/classrooms/{classroomId}/project-group")
    public ResponseEntity<BaseResponse<ProjectGroupDetailResponse>> getStudentProjectGroup(
            @PathVariable Long classroomId) {

        log.info("GET /student/classrooms/{}/project-group - Fetching student project group", classroomId);

        ProjectGroupDetailResponse response = groupService.getStudentProjectGroup(classroomId);
        return ResponseEntity.ok(BaseResponse.success(response, "Get student project group successfully"));
    }
}
