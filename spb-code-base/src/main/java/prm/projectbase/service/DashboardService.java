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
import java.util.List;
import java.util.Optional;
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
                .collect(Collectors.toList());

        List<ActivityListResponse> upcomingActivities = new ArrayList<>();
        int pendingActivitiesCount = 0;
        LocalDateTime now = LocalDateTime.now();

        for (Classroom classroom : classrooms) {
            List<LearningActivity> activities = activityRepository.findPublishedInClassroom(classroom.getId());
            for (LearningActivity activity : activities) {
                
                Optional<ActivitySubmission> submission = submissionRepository
                        .findByActivityIdAndStudentId(activity.getId(), student.getId());

                boolean submitted = submission.isPresent() &&
                        (submission.get().getStatus() == SubmissionWorkflowStatus.SUBMITTED ||
                                submission.get().getStatus() == SubmissionWorkflowStatus.LATE_SUBMITTED ||
                                submission.get().getStatus() == SubmissionWorkflowStatus.GRADED);

                if (!submitted && activity.getDueAt().isAfter(now)) {
                    pendingActivitiesCount++;
                    upcomingActivities.add(ActivityListResponse.builder()
                            .id(activity.getId())
                            .title(activity.getTitle())
                            .description(activity.getDescription())
                            .activityType(activity.getActivityType().name())
                            .dueAt(activity.getDueAt())
                            .maxScore(activity.getMaxScore())
                            .status(activity.getStatus().name())
                            .build());
                }
            }
        }

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
                List<ActivitySubmission> submissions = submissionRepository.findByActivityId(activity.getId());
                for (ActivitySubmission submission : submissions) {
                    if (submission.getStatus() == SubmissionWorkflowStatus.SUBMITTED ||
                            submission.getStatus() == SubmissionWorkflowStatus.LATE_SUBMITTED) {
                        pendingGradingCount++;
                    }
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
}
