package prm.projectbase.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DashboardService {

    private final ClassroomRepository classroomRepository;
    private final ClassroomEnrollmentRepository enrollmentRepository;
    private final LearningActivityRepository activityRepository;
    private final ActivitySubmissionRepository submissionRepository;
    private final ProjectGroupRepository groupRepository;
    private final ProjectMemberRepository memberRepository;
    private final NotificationRepository notificationRepository;
    private final SubmissionAttachmentRepository submissionAttachmentRepository;
    private final SubmissionCommentRepository submissionCommentRepository;
    private final UserService userService;

    public StudentDashboardResponse getStudentDashboard() {
        User student = userService.getCurrentUser();
        log.info("Generating student dashboard summary for user {}", student.getId());

        if (!"ROLE_STUDENT".equals(student.getRole().getName())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        List<ClassroomEnrollment> enrollments = enrollmentRepository.findByStudentAndStatus(
                student, ClassroomEnrollmentStatus.ACTIVE
        );
        int enrolledCount = enrollments.size();

        List<Classroom> classrooms = enrollments.stream()
                .map(ClassroomEnrollment::getClassroom)
                .toList();
        List<Long> classroomIds = classrooms.stream().map(Classroom::getId).toList();

        List<ActivityListResponse> upcomingActivities = new ArrayList<>();
        int pendingActivitiesCount = 0;
        LocalDateTime now = LocalDateTime.now();
        List<LearningActivity> activities = classroomIds.isEmpty()
                ? Collections.emptyList()
                : activityRepository.findPublishedInClassroomIds(classroomIds);
        Map<Long, SubmissionSummaryResponse> submissionSummaryMap = buildSubmissionSummaryMap(student.getId(), activities);

        for (LearningActivity activity : activities) {
            try {
                SubmissionSummaryResponse submissionSummary = submissionSummaryMap.get(activity.getId());
                String submissionStatus = submissionSummary != null ? submissionSummary.getStatus() : null;
                boolean submitted = SubmissionWorkflowStatus.SUBMITTED.name().equals(submissionStatus) ||
                        SubmissionWorkflowStatus.LATE_SUBMITTED.name().equals(submissionStatus) ||
                        SubmissionWorkflowStatus.GRADED.name().equals(submissionStatus);

                if (!submitted && activity.getDueAt() != null && activity.getDueAt().isAfter(now)) {
                    pendingActivitiesCount++;
                    upcomingActivities.add(toActivityListResponse(activity, submissionSummary));
                }
            } catch (Exception ex) {
                log.error("Skipping malformed student dashboard activity {}", activity.getId(), ex);
            }
        }

        // Sort upcoming activities by due date ascending (closest deadline first)
        upcomingActivities.sort((a, b) -> {
            if (a.getDueAt() == null && b.getDueAt() == null) return 0;
            if (a.getDueAt() == null) return 1;
            if (b.getDueAt() == null) return -1;
            return a.getDueAt().compareTo(b.getDueAt());
        });

        long unreadNotifications = notificationRepository.countByRecipientIdAndReadAtIsNull(student.getId());

        List<ProjectMember> memberships = memberRepository.findByStudentId(student.getId());
        List<ProjectGroupListResponse> activeGroups = memberships.stream()
                .filter(ProjectMember::isActive)
                .map(m -> {
                    ProjectGroup g = m.getProjectGroup();
                    List<ProjectMember> groupMembers = memberRepository.findByProjectGroupId(g.getId());
                    return toGroupListResponse(g, groupMembers.size());
                })
                .collect(Collectors.toList());

        return StudentDashboardResponse.builder()
                .enrolledClassroomsCount(enrolledCount)
                .pendingActivitiesCount(pendingActivitiesCount)
                .unreadNotificationsCount(unreadNotifications)
                .upcomingActivities(upcomingActivities)
                .activeGroups(activeGroups)
                .build();
    }

    public List<ActivityListResponse> getStudentDeadlines(int page, int size) {
        User student = userService.getCurrentUser();
        log.info("Fetching student deadlines for user {}, page={}, size={}", student.getId(), page, size);

        if (!"ROLE_STUDENT".equals(student.getRole().getName())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        List<ClassroomEnrollment> enrollments = enrollmentRepository.findByStudentAndStatus(
                student, ClassroomEnrollmentStatus.ACTIVE
        );

        List<Classroom> classrooms = enrollments.stream()
                .map(ClassroomEnrollment::getClassroom)
                .toList();
        List<Long> classroomIds = classrooms.stream().map(Classroom::getId).toList();

        List<ActivityListResponse> upcomingActivities = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();
        List<LearningActivity> activities = classroomIds.isEmpty()
                ? Collections.emptyList()
                : activityRepository.findPublishedInClassroomIds(classroomIds);
        Map<Long, SubmissionSummaryResponse> submissionSummaryMap = buildSubmissionSummaryMap(student.getId(), activities);

        for (LearningActivity activity : activities) {
            try {
                SubmissionSummaryResponse submissionSummary = submissionSummaryMap.get(activity.getId());
                String submissionStatus = submissionSummary != null ? submissionSummary.getStatus() : null;
                boolean submitted = SubmissionWorkflowStatus.SUBMITTED.name().equals(submissionStatus) ||
                        SubmissionWorkflowStatus.LATE_SUBMITTED.name().equals(submissionStatus) ||
                        SubmissionWorkflowStatus.GRADED.name().equals(submissionStatus);

                if (!submitted && activity.getDueAt() != null && activity.getDueAt().isAfter(now)) {
                    upcomingActivities.add(toActivityListResponse(activity, submissionSummary));
                }
            } catch (Exception ex) {
                log.error("Skipping malformed student activity {}", activity.getId(), ex);
            }
        }

        // Sort upcoming activities by due date ascending
        upcomingActivities.sort((a, b) -> {
            if (a.getDueAt() == null && b.getDueAt() == null) return 0;
            if (a.getDueAt() == null) return 1;
            if (b.getDueAt() == null) return -1;
            return a.getDueAt().compareTo(b.getDueAt());
        });

        int start = page * size;
        if (start >= upcomingActivities.size()) {
            return new ArrayList<>();
        }
        int end = Math.min(start + size, upcomingActivities.size());
        return upcomingActivities.subList(start, end);
    }

    public TeacherDashboardResponse getTeacherDashboard() {
        User teacher = userService.getCurrentUser();
        log.info("Generating teacher dashboard summary for user {}", teacher.getId());

        if (!"ROLE_TEACHER".equals(teacher.getRole().getName())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        List<Classroom> classrooms = classroomRepository.findByTeacherIdAndActiveTrue(teacher.getId());
        int managedCount = classrooms.size();

        int totalStudents = 0;
        int activeGroupsCount = 0;
        int pendingGradingCount = 0;

        for (Classroom classroom : classrooms) {
            long enrolledCount = enrollmentRepository.countByClassroomAndStatus(classroom, ClassroomEnrollmentStatus.ACTIVE);
            totalStudents += enrolledCount;

            List<ProjectGroup> groups = groupRepository.findByClassroomId(classroom.getId());
            activeGroupsCount += groups.size();

            List<LearningActivity> activities = activityRepository.findByClassroomIdOrderByDueAtAsc(classroom.getId());
            for (LearningActivity activity : activities) {
                try {
                    List<ActivitySubmission> submissions = submissionRepository.findByActivityId(activity.getId());
                    for (ActivitySubmission submission : submissions) {
                        if (submission.getStatus() == SubmissionWorkflowStatus.SUBMITTED ||
                                submission.getStatus() == SubmissionWorkflowStatus.LATE_SUBMITTED) {
                            pendingGradingCount++;
                        }
                    }
                } catch (Exception ex) {
                    log.error("Skipping malformed teacher dashboard activity {}", activity.getId(), ex);
                }
            }
        }

        List<ClassroomListResponse> classroomResponses = classrooms.stream()
                .map(this::toClassroomListResponse)
                .collect(Collectors.toList());

        return TeacherDashboardResponse.builder()
                .managedClassroomsCount(managedCount)
                .totalStudentsCount(totalStudents)
                .pendingGradingCount(pendingGradingCount)
                .activeGroupsCount(activeGroupsCount)
                .classrooms(classroomResponses)
                .build();
    }

    private ProjectGroupListResponse toGroupListResponse(ProjectGroup group, int memberCount) {
        UserResponse leaderResponse = null;
        if (group.getLeader() != null) {
            leaderResponse = UserResponse.builder()
                    .id(group.getLeader().getId())
                    .userName(group.getLeader().getUserName())
                    .email(group.getLeader().getEmail())
                    .fullName(group.getLeader().getFullName())
                    .phone(group.getLeader().getPhone())
                    .avatarUrl(group.getLeader().getAvatarUrl())
                    .institutionalId(group.getLeader().getInstitutionalId())
                    .active(group.getLeader().isActive())
                    .build();
        }

        return ProjectGroupListResponse.builder()
                .id(group.getId())
                .groupName(group.getGroupName())
                .projectName(group.getProjectName())
                .leader(leaderResponse)
                .status(group.getStatus().name())
                .memberCount(memberCount)
                .classroomId(group.getClassroom().getId())
                .classroomCode(group.getClassroom().getCode())
                .classroomName(group.getClassroom().getName())
                .build();
    }

    private ClassroomListResponse toClassroomListResponse(Classroom classroom) {
        long studentCount = enrollmentRepository.countByClassroomAndStatus(
                classroom, ClassroomEnrollmentStatus.ACTIVE
        );

        return ClassroomListResponse.builder()
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
                .studentCount((int) studentCount)
                .active(classroom.isActive())
                .createdAt(classroom.getCreatedAt())
                .build();
    }

    private ActivityListResponse toActivityListResponse(
            LearningActivity activity,
            SubmissionSummaryResponse submissionSummary
    ) {
        return ActivityListResponse.builder()
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
                .submissionSummary(submissionSummary)
                .build();
    }

    private Map<Long, SubmissionSummaryResponse> buildSubmissionSummaryMap(
            Long studentId,
            List<LearningActivity> activities
    ) {
        if (activities.isEmpty()) {
            return Collections.emptyMap();
        }

        List<Long> activityIds = activities.stream().map(LearningActivity::getId).toList();
        List<ActivitySubmission> submissions = submissionRepository.findByStudentIdAndActivityIdIn(studentId, activityIds);
        if (submissions.isEmpty()) {
            return Collections.emptyMap();
        }

        List<Long> submissionIds = submissions.stream().map(ActivitySubmission::getId).toList();
        Map<Long, Long> attachmentCounts = submissionAttachmentRepository.countBySubmissionIds(submissionIds)
                .stream()
                .collect(Collectors.toMap(row -> (Long) row[0], row -> (Long) row[1]));
        Map<Long, Long> commentCounts = submissionCommentRepository.countBySubmissionIds(submissionIds)
                .stream()
                .collect(Collectors.toMap(row -> (Long) row[0], row -> (Long) row[1]));

        return submissions.stream().collect(Collectors.toMap(
                submission -> submission.getActivity().getId(),
                submission -> SubmissionSummaryResponse.builder()
                        .id(submission.getId())
                        .status(submission.getStatus() != null ? submission.getStatus().name() : null)
                        .submittedAt(submission.getSubmittedAt())
                        .score(submission.getScore())
                        .teacherFeedback(submission.getTeacherFeedback())
                        .attachmentCount(attachmentCounts.getOrDefault(submission.getId(), 0L))
                        .commentCount(commentCounts.getOrDefault(submission.getId(), 0L))
                        .build(),
                (left, right) -> left
        ));
    }
}
