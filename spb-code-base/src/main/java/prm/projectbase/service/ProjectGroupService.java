package prm.projectbase.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import prm.projectbase.dto.request.ProjectGroupCreateRequest;
import prm.projectbase.dto.request.ProjectGroupUpdateRequest;
import prm.projectbase.dto.response.ProjectGroupDetailResponse;
import prm.projectbase.dto.response.ProjectGroupListResponse;
import prm.projectbase.dto.response.UserResponse;
import prm.projectbase.entity.*;
import prm.projectbase.entity.enums.ClassroomEnrollmentStatus;
import prm.projectbase.entity.enums.ProjectGroupStatus;
import prm.projectbase.entity.enums.ProjectMemberRole;
import prm.projectbase.exception.AppException;
import prm.projectbase.exception.ErrorCode;
import prm.projectbase.repository.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class ProjectGroupService {

    private final ProjectGroupRepository groupRepository;
    private final ProjectMemberRepository memberRepository;
    private final ClassroomRepository classroomRepository;
    private final UserRepository userRepository;
    private final ClassroomEnrollmentRepository enrollmentRepository;
    private final UserService userService;

    public ProjectGroupDetailResponse createProjectGroup(Long classroomId, ProjectGroupCreateRequest request) {
        log.info("Creating project group {} in classroom {}", request.getGroupName(), classroomId);

        Classroom classroom = classroomRepository.findById(classroomId)
                .orElseThrow(() -> new AppException(ErrorCode.CLASSROOM_NOT_FOUND));

        User currentUser = userService.getCurrentUser();
        if (!classroom.getTeacher().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        if (groupRepository.existsByClassroomIdAndGroupName(classroomId, request.getGroupName())) {
            throw new AppException(ErrorCode.GROUP_ALREADY_EXISTS);
        }

        User leader = null;
        if (request.getLeaderId() != null) {
            leader = userRepository.findById(request.getLeaderId())
                    .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));
        }

        ProjectGroup group = ProjectGroup.builder()
                .classroom(classroom)
                .groupName(request.getGroupName())
                .projectName(request.getProjectName())
                .description(request.getDescription())
                .leader(leader)
                .status(ProjectGroupStatus.ACTIVE)
                .build();

        ProjectGroup savedGroup = groupRepository.save(group);

        List<ProjectMember> members = new ArrayList<>();
        if (request.getStudentIds() != null && !request.getStudentIds().isEmpty()) {
            for (Long studentId : request.getStudentIds()) {
                User student = userRepository.findById(studentId)
                        .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

                Optional<ClassroomEnrollment> enrollment = enrollmentRepository
                        .findByClassroomAndStudent(classroom, student);
                if (enrollment.isEmpty() || enrollment.get().getStatus() != ClassroomEnrollmentStatus.ACTIVE) {
                    throw new AppException(ErrorCode.STUDENT_NOT_ENROLLED);
                }

                Optional<ProjectMember> existingGroupMember = memberRepository
                        .findByStudentIdAndProjectGroupClassroomIdAndActiveTrue(studentId, classroomId);
                if (existingGroupMember.isPresent()) {
                    throw new AppException(ErrorCode.STUDENT_ALREADY_IN_GROUP);
                }

                ProjectMemberRole role = (leader != null && student.getId().equals(leader.getId()))
                        ? ProjectMemberRole.LEADER : ProjectMemberRole.MEMBER;

                ProjectMember member = ProjectMember.builder()
                        .projectGroup(savedGroup)
                        .student(student)
                        .memberRole(role)
                        .active(true)
                        .build();

                members.add(memberRepository.save(member));
            }
        }

        if (leader != null) {
            boolean leaderIsMember = request.getStudentIds() != null && request.getStudentIds().contains(leader.getId());
            if (!leaderIsMember) {
                throw new AppException(ErrorCode.LEADER_MUST_BE_MEMBER);
            }
        }

        return toDetailResponse(savedGroup, members);
    }

    public ProjectGroupDetailResponse updateProjectGroup(Long groupId, ProjectGroupUpdateRequest request) {
        log.info("Updating project group {}", groupId);

        ProjectGroup group = groupRepository.findById(groupId)
                .orElseThrow(() -> new AppException(ErrorCode.GROUP_NOT_FOUND));

        User currentUser = userService.getCurrentUser();
        if (!group.getClassroom().getTeacher().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        if (request.getGroupName() != null && !request.getGroupName().equalsIgnoreCase(group.getGroupName())) {
            if (groupRepository.existsByClassroomIdAndGroupName(group.getClassroom().getId(), request.getGroupName())) {
                throw new AppException(ErrorCode.GROUP_ALREADY_EXISTS);
            }
            group.setGroupName(request.getGroupName());
        }

        if (request.getProjectName() != null) {
            group.setProjectName(request.getProjectName());
        }

        if (request.getDescription() != null) {
            group.setDescription(request.getDescription());
        }

        if (request.getStatus() != null) {
            group.setStatus(ProjectGroupStatus.valueOf(request.getStatus()));
        }

        User leader = group.getLeader();
        if (request.getLeaderId() != null) {
            leader = userRepository.findById(request.getLeaderId())
                    .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));
            group.setLeader(leader);
        }

        ProjectGroup savedGroup = groupRepository.save(group);

        List<ProjectMember> members = memberRepository.findByProjectGroupId(groupId);

        if (request.getStudentIds() != null) {
            
            memberRepository.deleteAll(members);
            members.clear();

            for (Long studentId : request.getStudentIds()) {
                User student = userRepository.findById(studentId)
                        .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

                Optional<ClassroomEnrollment> enrollment = enrollmentRepository
                        .findByClassroomAndStudent(group.getClassroom(), student);
                if (enrollment.isEmpty() || enrollment.get().getStatus() != ClassroomEnrollmentStatus.ACTIVE) {
                    throw new AppException(ErrorCode.STUDENT_NOT_ENROLLED);
                }

                Optional<ProjectMember> existingGroupMember = memberRepository
                        .findByStudentIdAndProjectGroupClassroomIdAndActiveTrue(studentId, group.getClassroom().getId());
                if (existingGroupMember.isPresent() && !existingGroupMember.get().getProjectGroup().getId().equals(groupId)) {
                    throw new AppException(ErrorCode.STUDENT_ALREADY_IN_GROUP);
                }

                ProjectMemberRole role = (leader != null && student.getId().equals(leader.getId()))
                        ? ProjectMemberRole.LEADER : ProjectMemberRole.MEMBER;

                ProjectMember member = ProjectMember.builder()
                        .projectGroup(savedGroup)
                        .student(student)
                        .memberRole(role)
                        .active(true)
                        .build();

                members.add(memberRepository.save(member));
            }
        }

        if (leader != null) {
            final User finalLeader = leader;
            boolean leaderIsMember = members.stream().anyMatch(m -> m.getStudent().getId().equals(finalLeader.getId()));
            if (!leaderIsMember) {
                throw new AppException(ErrorCode.LEADER_MUST_BE_MEMBER);
            }
        }

        return toDetailResponse(savedGroup, members);
    }

    @Transactional(readOnly = true)
    public ProjectGroupDetailResponse getProjectGroupDetail(Long groupId) {
        log.info("Fetching project group {}", groupId);

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

        List<ProjectMember> members = memberRepository.findByProjectGroupId(groupId);
        return toDetailResponse(group, members);
    }

    @Transactional(readOnly = true)
    public List<ProjectGroupListResponse> getClassroomProjectGroups(Long classroomId) {
        log.info("Fetching all project groups in classroom {}", classroomId);

        Classroom classroom = classroomRepository.findById(classroomId)
                .orElseThrow(() -> new AppException(ErrorCode.CLASSROOM_NOT_FOUND));

        User currentUser = userService.getCurrentUser();
        boolean isTeacher = classroom.getTeacher().getId().equals(currentUser.getId());
        boolean isEnrolled = enrollmentRepository.findByClassroomAndStudent(classroom, currentUser)
                .map(e -> e.getStatus() == ClassroomEnrollmentStatus.ACTIVE)
                .orElse(false);

        if (!isTeacher && !isEnrolled) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        List<ProjectGroup> groups = groupRepository.findByClassroomId(classroomId);

        return groups.stream().map(g -> {
            List<ProjectMember> members = memberRepository.findByProjectGroupId(g.getId());
            return toListResponse(g, members.size());
        }).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public ProjectGroupDetailResponse getStudentProjectGroup(Long classroomId) {
        log.info("Fetching active project group for student in classroom {}", classroomId);

        User currentStudent = userService.getCurrentUser();

        ProjectMember member = memberRepository
                .findByStudentIdAndProjectGroupClassroomIdAndActiveTrue(currentStudent.getId(), classroomId)
                .orElseThrow(() -> new AppException(ErrorCode.GROUP_NOT_FOUND));

        List<ProjectMember> members = memberRepository.findByProjectGroupId(member.getProjectGroup().getId());
        return toDetailResponse(member.getProjectGroup(), members);
    }

    private ProjectGroupDetailResponse toDetailResponse(ProjectGroup group, List<ProjectMember> members) {
        UserResponse leaderResponse = null;
        if (group.getLeader() != null) {
            leaderResponse = toUserResponse(group.getLeader());
        }

        List<UserResponse> memberResponses = members.stream()
                .map(m -> toUserResponse(m.getStudent()))
                .collect(Collectors.toList());

        return ProjectGroupDetailResponse.builder()
                .id(group.getId())
                .classroomId(group.getClassroom().getId())
                .groupName(group.getGroupName())
                .projectName(group.getProjectName())
                .description(group.getDescription())
                .leader(leaderResponse)
                .status(group.getStatus().name())
                .members(memberResponses)
                .build();
    }

    private ProjectGroupListResponse toListResponse(ProjectGroup group, int memberCount) {
        UserResponse leaderResponse = null;
        if (group.getLeader() != null) {
            leaderResponse = toUserResponse(group.getLeader());
        }

        return ProjectGroupListResponse.builder()
                .id(group.getId())
                .groupName(group.getGroupName())
                .projectName(group.getProjectName())
                .leader(leaderResponse)
                .status(group.getStatus().name())
                .memberCount(memberCount)
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
