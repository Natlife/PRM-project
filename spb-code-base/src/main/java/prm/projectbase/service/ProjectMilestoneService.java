package prm.projectbase.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import prm.projectbase.dto.request.MilestoneProgressUpdateRequest;
import prm.projectbase.dto.request.ProjectMilestoneCreateRequest;
import prm.projectbase.dto.request.ProjectMilestoneUpdateRequest;
import prm.projectbase.dto.response.MilestoneAttachmentResponse;
import prm.projectbase.dto.response.ProjectMilestoneResponse;
import prm.projectbase.entity.*;
import prm.projectbase.entity.enums.ClassroomEnrollmentStatus;
import prm.projectbase.entity.enums.MilestoneWorkflowStatus;
import prm.projectbase.exception.AppException;
import prm.projectbase.exception.ErrorCode;
import prm.projectbase.repository.*;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class ProjectMilestoneService {

    private final ProjectMilestoneRepository milestoneRepository;
    private final ProjectGroupRepository groupRepository;
    private final ProjectMemberRepository memberRepository;
    private final MilestoneAttachmentRepository attachmentRepository;
    private final ClassroomEnrollmentRepository enrollmentRepository;
    private final UserService userService;
    private final FileService fileService;

    public ProjectMilestoneResponse createMilestone(Long groupId, ProjectMilestoneCreateRequest request) {
        log.info("Creating milestone for group {}", groupId);

        ProjectGroup group = groupRepository.findById(groupId)
                .orElseThrow(() -> new AppException(ErrorCode.GROUP_NOT_FOUND));

        User currentUser = userService.getCurrentUser();
        if (!group.getClassroom().getTeacher().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        ProjectMilestone milestone = ProjectMilestone.builder()
                .projectGroup(group)
                .title(request.getTitle())
                .description(request.getDescription())
                .dueAt(request.getDueAt())
                .progressPercent(0)
                .status(MilestoneWorkflowStatus.NOT_STARTED)
                .build();

        ProjectMilestone saved = milestoneRepository.save(milestone);
        return toResponse(saved);
    }

    public ProjectMilestoneResponse updateMilestone(Long milestoneId, ProjectMilestoneUpdateRequest request) {
        log.info("Updating milestone {}", milestoneId);

        ProjectMilestone milestone = milestoneRepository.findById(milestoneId)
                .orElseThrow(() -> new AppException(ErrorCode.MILESTONE_NOT_FOUND));

        User currentUser = userService.getCurrentUser();
        if (!milestone.getProjectGroup().getClassroom().getTeacher().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        if (request.getTitle() != null) {
            milestone.setTitle(request.getTitle());
        }

        if (request.getDescription() != null) {
            milestone.setDescription(request.getDescription());
        }

        if (request.getDueAt() != null) {
            milestone.setDueAt(request.getDueAt());
        }

        if (request.getStatus() != null) {
            milestone.setStatus(MilestoneWorkflowStatus.valueOf(request.getStatus()));
        }

        ProjectMilestone saved = milestoneRepository.save(milestone);
        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<ProjectMilestoneResponse> getGroupMilestones(Long groupId) {
        log.info("Fetching milestones for group {}", groupId);

        ProjectGroup group = groupRepository.findById(groupId)
                .orElseThrow(() -> new AppException(ErrorCode.GROUP_NOT_FOUND));

        User currentUser = userService.getCurrentUser();
        boolean isTeacher = group.getClassroom().getTeacher().getId().equals(currentUser.getId());
        boolean isEnrolled = enrollmentRepository.findByClassroomAndStudent(group.getClassroom(), currentUser)
                .map(e -> e.getStatus() == ClassroomEnrollmentStatus.ACTIVE)
                .orElse(false);

        if (!isTeacher && !isEnrolled) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        List<ProjectMilestone> milestones = milestoneRepository.findByProjectGroupId(groupId);
        return milestones.stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public ProjectMilestoneResponse getMilestone(Long milestoneId) {
        log.info("Fetching milestone {}", milestoneId);

        ProjectMilestone milestone = milestoneRepository.findById(milestoneId)
                .orElseThrow(() -> new AppException(ErrorCode.MILESTONE_NOT_FOUND));

        User currentUser = userService.getCurrentUser();
        ProjectGroup group = milestone.getProjectGroup();
        boolean isTeacher = group.getClassroom().getTeacher().getId().equals(currentUser.getId());
        boolean isEnrolled = enrollmentRepository.findByClassroomAndStudent(group.getClassroom(), currentUser)
                .map(e -> e.getStatus() == ClassroomEnrollmentStatus.ACTIVE)
                .orElse(false);

        if (!isTeacher && !isEnrolled) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        return toResponse(milestone);
    }

    public ProjectMilestoneResponse updateMilestoneProgress(Long milestoneId, MilestoneProgressUpdateRequest request) {
        log.info("Updating progress for milestone {}", milestoneId);

        ProjectMilestone milestone = milestoneRepository.findById(milestoneId)
                .orElseThrow(() -> new AppException(ErrorCode.MILESTONE_NOT_FOUND));

        User currentUser = userService.getCurrentUser();

        // Verify user is member of the project group
        boolean isMember = memberRepository.existsByProjectGroupIdAndStudentIdAndActiveTrue(
                milestone.getProjectGroup().getId(), currentUser.getId());
        if (!isMember) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        milestone.setProgressPercent(request.getProgressPercent());
        milestone.setStatus(MilestoneWorkflowStatus.valueOf(request.getStatus()));

        ProjectMilestone saved = milestoneRepository.save(milestone);
        return toResponse(saved);
    }

    public List<MilestoneAttachmentResponse> addMilestoneAttachment(Long milestoneId, List<MultipartFile> files) {
        log.info("Uploading attachments for milestone {}", milestoneId);

        ProjectMilestone milestone = milestoneRepository.findById(milestoneId)
                .orElseThrow(() -> new AppException(ErrorCode.MILESTONE_NOT_FOUND));

        User currentUser = userService.getCurrentUser();

        // Verify user is member of the project group
        boolean isMember = memberRepository.existsByProjectGroupIdAndStudentIdAndActiveTrue(
                milestone.getProjectGroup().getId(), currentUser.getId());
        if (!isMember) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        List<MilestoneAttachmentResponse> responses = new ArrayList<>();
        for (MultipartFile file : files) {
            FileService.StorageResult storageResult = fileService.storeFile(
                    file,
                    "milestones/" + milestoneId
            );

            MilestoneAttachment attachment = MilestoneAttachment.builder()
                    .milestone(milestone)
                    .uploadedBy(currentUser)
                    .storageKey(storageResult.getStorageKey())
                    .originalFileName(storageResult.getOriginalFileName())
                    .contentType(storageResult.getContentType())
                    .sizeBytes(storageResult.getSizeBytes())
                    .build();

            MilestoneAttachment saved = attachmentRepository.save(attachment);
            responses.add(toAttachmentResponse(saved));
        }

        return responses;
    }

    // DTO helpers

    private ProjectMilestoneResponse toResponse(ProjectMilestone milestone) {
        List<MilestoneAttachment> attachments = attachmentRepository.findByMilestoneId(milestone.getId());
        List<MilestoneAttachmentResponse> attachmentResponses = attachments.stream()
                .map(this::toAttachmentResponse)
                .collect(Collectors.toList());

        return ProjectMilestoneResponse.builder()
                .id(milestone.getId())
                .groupId(milestone.getProjectGroup().getId())
                .title(milestone.getTitle())
                .description(milestone.getDescription())
                .dueAt(milestone.getDueAt())
                .progressPercent(milestone.getProgressPercent())
                .status(milestone.getStatus().name())
                .attachments(attachmentResponses)
                .build();
    }

    private MilestoneAttachmentResponse toAttachmentResponse(MilestoneAttachment attachment) {
        return MilestoneAttachmentResponse.builder()
                .id(attachment.getId())
                .storageKey(attachment.getStorageKey())
                .originalFileName(attachment.getOriginalFileName())
                .contentType(attachment.getContentType())
                .sizeBytes(attachment.getSizeBytes())
                .uploadedById(attachment.getUploadedBy().getId())
                .uploadedByName(attachment.getUploadedBy().getFullName())
                .build();
    }
}
