package prm.projectbase.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import prm.projectbase.dto.response.*;
import prm.projectbase.entity.*;
import prm.projectbase.entity.enums.ClassroomEnrollmentStatus;
import prm.projectbase.entity.enums.SubmissionWorkflowStatus;
import prm.projectbase.exception.AppException;
import prm.projectbase.exception.ErrorCode;
import prm.projectbase.repository.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class OverviewService {

    private final UserService userService;
    private final ClassroomRepository classroomRepository;
    private final ClassroomEnrollmentRepository enrollmentRepository;
    private final LearningActivityRepository activityRepository;
    private final ClassMaterialRepository materialRepository;
    private final ProjectMemberRepository memberRepository;
    private final ProjectGroupRepository groupRepository;
    private final ProjectMilestoneRepository milestoneRepository;
    private final MilestoneAttachmentRepository milestoneAttachmentRepository;
    private final ActivitySubmissionRepository submissionRepository;
    private final SubmissionAttachmentRepository submissionAttachmentRepository;
    private final SubmissionCommentRepository submissionCommentRepository;
    private final FileService fileService;

    public StudentClassroomOverviewResponse getStudentClassroomOverview(Long classroomId) {
        User currentUser = userService.getCurrentUser();
        if (!"ROLE_STUDENT".equals(currentUser.getRole().getName())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        Classroom classroom = classroomRepository.findById(classroomId)
                .orElseThrow(() -> new AppException(ErrorCode.CLASSROOM_NOT_FOUND));

        ClassroomEnrollment enrollment = enrollmentRepository.findByClassroomAndStudent(classroom, currentUser)
                .orElseThrow(() -> new AppException(ErrorCode.FORBIDDEN));
        if (enrollment.getStatus() != ClassroomEnrollmentStatus.ACTIVE) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        List<LearningActivity> activities = activityRepository.findPublishedInClassroom(classroomId);
        List<Long> activityIds = activities.stream().map(LearningActivity::getId).toList();
        List<ActivitySubmission> submissions = activityIds.isEmpty()
                ? Collections.emptyList()
                : submissionRepository.findByStudentIdAndActivityIdIn(currentUser.getId(), activityIds);

        List<Long> submissionIds = submissions.stream().map(ActivitySubmission::getId).toList();
        java.util.Map<Long, Long> attachmentCounts = submissionIds.isEmpty()
                ? Collections.emptyMap()
                : submissionAttachmentRepository.countBySubmissionIds(submissionIds).stream()
                        .collect(java.util.stream.Collectors.toMap(row -> (Long) row[0], row -> (Long) row[1]));
        java.util.Map<Long, Long> commentCounts = submissionIds.isEmpty()
                ? Collections.emptyMap()
                : submissionCommentRepository.countBySubmissionIds(submissionIds).stream()
                        .collect(java.util.stream.Collectors.toMap(row -> (Long) row[0], row -> (Long) row[1]));
        java.util.Map<Long, ActivitySubmission> submissionByActivityId = submissions.stream()
                .collect(java.util.stream.Collectors.toMap(s -> s.getActivity().getId(), s -> s, (left, right) -> left));

        List<ActivityListResponse> activityResponses = activities.stream()
                .map(activity -> {
                    ActivitySubmission submission = submissionByActivityId.get(activity.getId());
                    SubmissionSummaryResponse summary = submission == null
                            ? null
                            : SubmissionSummaryResponse.builder()
                                    .id(submission.getId())
                                    .status(submission.getStatus() != null ? submission.getStatus().name() : null)
                                    .submittedAt(submission.getSubmittedAt())
                                    .score(submission.getScore())
                                    .teacherFeedback(submission.getTeacherFeedback())
                                    .attachmentCount(attachmentCounts.getOrDefault(submission.getId(), 0L))
                                    .commentCount(commentCounts.getOrDefault(submission.getId(), 0L))
                                    .build();

                    return ActivityListResponse.builder()
                            .id(activity.getId())
                            .title(activity.getTitle())
                            .description(activity.getDescription())
                            .activityType(activity.getActivityType() != null ? activity.getActivityType().toApiValue() : null)
                            .dueAt(activity.getDueAt())
                            .maxScore(activity.getMaxScore())
                            .status(activity.getStatus() != null ? activity.getStatus().name() : null)
                            .classroomId(classroom.getId())
                            .classroomCode(classroom.getCode())
                            .classroomName(classroom.getName())
                            .submissionSummary(summary)
                            .build();
                })
                .toList();

        List<MaterialListResponse> materialResponses = materialRepository.findPublishedInClassroom(
                        classroomId,
                        java.time.LocalDateTime.now()
                ).stream()
                .map(material -> MaterialListResponse.builder()
                        .id(material.getId())
                        .title(material.getTitle())
                        .description(material.getDescription())
                        .materialType(material.getMaterialType().name())
                        .originalFileName(material.getOriginalFileName())
                        .sizeBytes(material.getSizeBytes())
                        .fileUrl(fileService.getFileUrl(material.getStorageKey()))
                        .publishedAt(material.getPublishedAt())
                        .build())
                .toList();

        ProjectGroupDetailResponse projectGroup = null;
        java.util.Optional<ProjectMember> membership = memberRepository
                .findByStudentIdAndProjectGroupClassroomIdAndActiveTrue(currentUser.getId(), classroomId);
        if (membership.isPresent()) {
            projectGroup = buildProjectDetailResponses(
                    List.of(membership.get().getProjectGroup()),
                    List.of(membership.get())
            ).stream().findFirst().orElse(null);
        }

        return StudentClassroomOverviewResponse.builder()
                .classroom(ClassroomDetailResponse.builder()
                        .id(classroom.getId())
                        .code(classroom.getCode())
                        .name(classroom.getName())
                        .description(classroom.getDescription())
                        .semesterCode(classroom.getSemesterCode())
                        .joinCode(classroom.getJoinCode())
                        .active(classroom.isActive())
                        .teacher(UserResponse.builder()
                                .id(classroom.getTeacher().getId())
                                .userName(classroom.getTeacher().getUserName())
                                .email(classroom.getTeacher().getEmail())
                                .fullName(classroom.getTeacher().getFullName())
                                .phone(classroom.getTeacher().getPhone())
                                .avatarUrl(classroom.getTeacher().getAvatarUrl())
                                .institutionalId(classroom.getTeacher().getInstitutionalId())
                                .active(classroom.getTeacher().isActive())
                                .build())
                        .studentCount((int) enrollmentRepository.countByClassroomAndStatus(classroom, ClassroomEnrollmentStatus.ACTIVE))
                        .schedules(classroom.getSchedules() == null ? Collections.emptyList() : classroom.getSchedules().stream()
                                .map(schedule -> ClassroomScheduleResponse.builder()
                                        .id(schedule.getId())
                                        .dayOfWeek(schedule.getDayOfWeek().getValue() - 1)
                                        .slotLabel(schedule.getSlotLabel())
                                        .startTime(schedule.getStartTime())
                                        .endTime(schedule.getEndTime())
                                        .roomName(schedule.getRoomName())
                                        .build())
                                .toList())
                        .createdAt(classroom.getCreatedAt())
                        .updatedAt(classroom.getUpdatedAt())
                        .build())
                .activities(activityResponses)
                .materials(materialResponses)
                .projectGroup(projectGroup)
                .build();
    }

    public TeacherDashboardOverviewResponse getTeacherDashboardOverview() {
        User currentUser = userService.getCurrentUser();
        if (!"ROLE_TEACHER".equals(currentUser.getRole().getName())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        List<Classroom> classrooms = classroomRepository.findByTeacherIdAndActiveTrue(currentUser.getId());
        List<Long> classroomIds = classrooms.stream().map(Classroom::getId).toList();

        List<LearningActivity> activities = classroomIds.isEmpty()
                ? Collections.emptyList()
                : activityRepository.findByClassroomIdInOrderByDueAtAsc(classroomIds);
        List<Long> activityIds = activities.stream().map(LearningActivity::getId).toList();
        List<ActivitySubmission> submissions = activityIds.isEmpty()
                ? Collections.emptyList()
                : submissionRepository.findByActivityIdIn(activityIds);

        int pendingGradingCount = (int) submissions.stream()
                .filter(submission -> submission.getStatus() == SubmissionWorkflowStatus.SUBMITTED
                        || submission.getStatus() == SubmissionWorkflowStatus.LATE_SUBMITTED)
                .count();

        List<ClassroomListResponse> classroomResponses = classrooms.stream()
                .map(classroom -> ClassroomListResponse.builder()
                        .id(classroom.getId())
                        .code(classroom.getCode())
                        .name(classroom.getName())
                        .semesterCode(classroom.getSemesterCode())
                        .teacher(UserResponse.builder()
                                .id(classroom.getTeacher().getId())
                                .userName(classroom.getTeacher().getUserName())
                                .email(classroom.getTeacher().getEmail())
                                .fullName(classroom.getTeacher().getFullName())
                                .phone(classroom.getTeacher().getPhone())
                                .avatarUrl(classroom.getTeacher().getAvatarUrl())
                                .institutionalId(classroom.getTeacher().getInstitutionalId())
                                .active(classroom.getTeacher().isActive())
                                .build())
                        .studentCount((int) enrollmentRepository.countByClassroomAndStatus(classroom, ClassroomEnrollmentStatus.ACTIVE))
                        .active(classroom.isActive())
                        .createdAt(classroom.getCreatedAt())
                        .build())
                .toList();

        Map<Long, Long> pendingCountByActivityId = submissions.stream()
                .filter(submission -> submission.getStatus() == SubmissionWorkflowStatus.SUBMITTED
                        || submission.getStatus() == SubmissionWorkflowStatus.LATE_SUBMITTED)
                .collect(Collectors.groupingBy(
                        submission -> submission.getActivity().getId(),
                        Collectors.counting()
                ));

        List<ActivityListResponse> activityResponses = activities.stream()
                .map(activity -> ActivityListResponse.builder()
                        .id(activity.getId())
                        .title(activity.getTitle())
                        .description(activity.getDescription())
                        .activityType(activity.getActivityType() != null ? activity.getActivityType().toApiValue() : null)
                        .dueAt(activity.getDueAt())
                        .maxScore(activity.getMaxScore())
                        .status(activity.getStatus() != null ? activity.getStatus().name() : null)
                        .classroomId(activity.getClassroom().getId())
                        .classroomCode(activity.getClassroom().getCode())
                        .classroomName(activity.getClassroom().getName())
                        .submissionSummary(SubmissionSummaryResponse.builder()
                                .commentCount(pendingCountByActivityId.getOrDefault(activity.getId(), 0L))
                                .build())
                        .build())
                .toList();

        List<ProjectGroup> groups = classroomIds.isEmpty()
                ? Collections.emptyList()
                : groupRepository.findByClassroomIdIn(classroomIds);
        List<ProjectMember> activeMembers = groups.isEmpty()
                ? Collections.emptyList()
                : memberRepository.findByProjectGroupIdIn(
                        groups.stream().map(ProjectGroup::getId).toList()
                ).stream().filter(ProjectMember::isActive).toList();
        List<ProjectGroupDetailResponse> projectResponses = buildProjectDetailResponses(groups, activeMembers);

        int totalStudentsCount = classrooms.stream()
                .mapToInt(classroom -> (int) enrollmentRepository.countByClassroomAndStatus(classroom, ClassroomEnrollmentStatus.ACTIVE))
                .sum();

        return TeacherDashboardOverviewResponse.builder()
                .managedClassroomsCount(classrooms.size())
                .totalStudentsCount(totalStudentsCount)
                .pendingGradingCount(pendingGradingCount)
                .activeGroupsCount(projectResponses.size())
                .classrooms(classroomResponses)
                .activities(activityResponses)
                .projects(projectResponses)
                .build();
    }

    private List<ProjectGroupDetailResponse> buildProjectDetailResponses(
            List<ProjectGroup> groups,
            List<ProjectMember> members
    ) {
        if (groups.isEmpty()) {
            return Collections.emptyList();
        }

        List<Long> groupIds = groups.stream().map(ProjectGroup::getId).toList();
        Map<Long, List<ProjectMember>> membersByGroupId = new HashMap<>();
        for (ProjectMember member : members) {
            membersByGroupId
                    .computeIfAbsent(member.getProjectGroup().getId(), ignored -> new ArrayList<>())
                    .add(member);
        }

        List<ProjectMilestone> milestones = milestoneRepository.findByProjectGroupIdIn(groupIds);
        Map<Long, List<ProjectMilestone>> milestonesByGroupId = milestones.stream()
                .collect(Collectors.groupingBy(milestone -> milestone.getProjectGroup().getId()));

        List<Long> milestoneIds = milestones.stream().map(ProjectMilestone::getId).toList();
        Map<Long, List<MilestoneAttachment>> attachmentsByMilestoneId = milestoneIds.isEmpty()
                ? Collections.emptyMap()
                : milestoneAttachmentRepository.findByMilestoneIdIn(milestoneIds).stream()
                        .collect(Collectors.groupingBy(attachment -> attachment.getMilestone().getId()));

        return groups.stream()
                .map(group -> {
                    List<ProjectMember> groupMembers = membersByGroupId.getOrDefault(group.getId(), Collections.emptyList());
                    List<ProjectMilestoneResponse> milestoneResponses = milestonesByGroupId
                            .getOrDefault(group.getId(), Collections.emptyList())
                            .stream()
                            .map(milestone -> toMilestoneResponse(
                                    milestone,
                                    attachmentsByMilestoneId.getOrDefault(milestone.getId(), Collections.emptyList())
                            ))
                            .toList();

                    double progressPercent = milestoneResponses.isEmpty()
                            ? 0.0
                            : milestoneResponses.stream()
                                    .map(ProjectMilestoneResponse::getProgressPercent)
                                    .filter(Objects::nonNull)
                                    .mapToInt(Integer::intValue)
                                    .average()
                                    .orElse(0.0);
                    LocalDateTime latestMilestoneDueAt = milestoneResponses.stream()
                            .map(ProjectMilestoneResponse::getDueAt)
                            .filter(Objects::nonNull)
                            .max(LocalDateTime::compareTo)
                            .orElse(null);

                    return ProjectGroupDetailResponse.builder()
                            .id(group.getId())
                            .classroomId(group.getClassroom().getId())
                            .groupName(group.getGroupName())
                            .projectName(group.getProjectName())
                            .description(group.getDescription())
                            .leader(group.getLeader() != null ? toUserResponse(group.getLeader()) : null)
                            .status(group.getStatus().name())
                            .classroomCode(group.getClassroom().getCode())
                            .classroomName(group.getClassroom().getName())
                            .memberCount(groupMembers.size())
                            .progressPercent(progressPercent)
                            .latestMilestoneDueAt(latestMilestoneDueAt)
                            .members(groupMembers.stream()
                                    .map(ProjectMember::getStudent)
                                    .map(this::toUserResponse)
                                    .toList())
                            .milestones(milestoneResponses)
                            .build();
                })
                .toList();
    }

    private ProjectMilestoneResponse toMilestoneResponse(
            ProjectMilestone milestone,
            List<MilestoneAttachment> attachments
    ) {
        return ProjectMilestoneResponse.builder()
                .id(milestone.getId())
                .groupId(milestone.getProjectGroup().getId())
                .title(milestone.getTitle())
                .description(milestone.getDescription())
                .dueAt(milestone.getDueAt())
                .progressPercent(milestone.getProgressPercent())
                .status(milestone.getStatus().name())
                .attachments(attachments.stream()
                        .map(attachment -> MilestoneAttachmentResponse.builder()
                                .id(attachment.getId())
                                .storageKey(attachment.getStorageKey())
                                .originalFileName(attachment.getOriginalFileName())
                                .contentType(attachment.getContentType())
                                .sizeBytes(attachment.getSizeBytes())
                                .uploadedById(attachment.getUploadedBy().getId())
                                .uploadedByName(attachment.getUploadedBy().getFullName())
                                .build())
                        .toList())
                .build();
    }

    private UserResponse toUserResponse(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .userName(user.getUserName())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .phone(user.getPhone())
                .avatarUrl(user.getAvatarUrl())
                .institutionalId(user.getInstitutionalId())
                .active(user.isActive())
                .build();
    }
}
