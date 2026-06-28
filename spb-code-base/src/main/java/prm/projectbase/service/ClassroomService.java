package prm.projectbase.service;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import prm.projectbase.dto.request.ClassroomCreateRequest;
import prm.projectbase.dto.request.ClassroomScheduleRequest;
import prm.projectbase.dto.request.ClassroomUpdateRequest;
import prm.projectbase.dto.response.*;
import prm.projectbase.entity.Classroom;
import prm.projectbase.entity.ClassroomEnrollment;
import prm.projectbase.entity.ClassroomSchedule;
import prm.projectbase.entity.User;
import prm.projectbase.entity.enums.ClassroomEnrollmentStatus;
import prm.projectbase.exception.AppException;
import prm.projectbase.exception.ErrorCode;
import prm.projectbase.repository.ClassroomEnrollmentRepository;
import prm.projectbase.repository.ClassroomRepository;
import prm.projectbase.repository.UserRepository;
import prm.projectbase.util.JwtUtil;

import java.time.DayOfWeek;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class ClassroomService {

    ClassroomRepository classroomRepository;
    ClassroomEnrollmentRepository enrollmentRepository;
    UserRepository userRepository;
    JwtUtil jwtUtil;
    NotificationService notificationService;

    @Transactional
    public ClassroomDetailResponse createClassroom(ClassroomCreateRequest request) {
        User teacher = getCurrentUser();

        if (!"ROLE_TEACHER".equals(teacher.getRole().getName())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        if (classroomRepository.existsByCode(request.getCode())) {
            throw new AppException(ErrorCode.CLASSROOM_CODE_ALREADY_EXISTS);
        }

        String joinCode = generateUniqueJoinCode();

        Classroom classroom = Classroom.builder()
                .code(request.getCode())
                .name(request.getName())
                .description(request.getDescription())
                .semesterCode(request.getSemesterCode())
                .joinCode(joinCode)
                .teacher(teacher)
                .active(true)
                .build();

        List<ClassroomSchedule> schedules = new ArrayList<>();
        if (request.getSchedules() != null && !request.getSchedules().isEmpty()) {
            request.getSchedules().forEach(scheduleRequest -> {
                ClassroomSchedule schedule = ClassroomSchedule.builder()
                        .classroom(classroom)
                        .dayOfWeek(DayOfWeek.of(scheduleRequest.getDayOfWeek() + 1)) 
                        .slotLabel(scheduleRequest.getSlotLabel())
                        .startTime(scheduleRequest.getStartTime())
                        .endTime(scheduleRequest.getEndTime())
                        .roomName(scheduleRequest.getRoomName())
                        .build();
                schedules.add(schedule);
            });
        }
        classroom.setSchedules(schedules);

        Classroom savedClassroom = classroomRepository.save(classroom);

        return mapToClassroomDetailResponse(savedClassroom);
    }

    @Transactional(readOnly = true)
    public List<ClassroomListResponse> getTeacherClassrooms() {
        User teacher = getCurrentUser();
        
        if (!"ROLE_TEACHER".equals(teacher.getRole().getName())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        List<Classroom> classrooms = classroomRepository.findByTeacherIdAndActiveTrue(teacher.getId());
        
        return classrooms.stream()
                .map(this::mapToClassroomListResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public ClassroomDetailResponse getClassroomDetail(Long classroomId) {
        Classroom classroom = classroomRepository.findById(classroomId)
                .orElseThrow(() -> new AppException(ErrorCode.CLASSROOM_NOT_FOUND));

        User currentUser = getCurrentUser();

        if ("ROLE_TEACHER".equals(currentUser.getRole().getName()) && 
                !classroom.getTeacher().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        return mapToClassroomDetailResponse(classroom);
    }

    @Transactional(readOnly = true)
    public List<UserResponse> getTeacherClassroomStudents(Long classroomId) {
        Classroom classroom = classroomRepository.findById(classroomId)
                .orElseThrow(() -> new AppException(ErrorCode.CLASSROOM_NOT_FOUND));

        User currentUser = getCurrentUser();
        if (!classroom.getTeacher().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        return enrollmentRepository.findByClassroomId(classroomId).stream()
                .filter(enrollment -> enrollment.getStatus() == ClassroomEnrollmentStatus.ACTIVE)
                .map(ClassroomEnrollment::getStudent)
                .map(this::mapToUserResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public ClassroomDetailResponse updateClassroom(Long classroomId, ClassroomUpdateRequest request) {
        Classroom classroom = classroomRepository.findById(classroomId)
                .orElseThrow(() -> new AppException(ErrorCode.CLASSROOM_NOT_FOUND));

        User currentUser = getCurrentUser();

        if (!classroom.getTeacher().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        if (request.getName() != null) {
            classroom.setName(request.getName());
        }
        if (request.getDescription() != null) {
            classroom.setDescription(request.getDescription());
        }
        if (request.getSemesterCode() != null) {
            classroom.setSemesterCode(request.getSemesterCode());
        }
        if (request.getActive() != null) {
            classroom.setActive(request.getActive());
        }

        Classroom updatedClassroom = classroomRepository.save(classroom);

        if (request.getSchedules() != null && !request.getSchedules().isEmpty()) {

            updateSchedulesForClassroom(updatedClassroom, request.getSchedules());
        }

        return mapToClassroomDetailResponse(updatedClassroom);
    }

    @Transactional
    public ClassroomEnrollmentResponse studentJoinClassroom(String joinCode) {
        User student = getCurrentUser();

        if (!"ROLE_STUDENT".equals(student.getRole().getName())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        Classroom classroom = classroomRepository.findByJoinCode(joinCode)
                .orElseThrow(() -> new AppException(ErrorCode.CLASSROOM_NOT_FOUND));

        if (!classroom.isActive()) {
            throw new AppException(ErrorCode.CLASSROOM_INACTIVE);
        }

        if (enrollmentRepository.findByClassroomAndStudent(classroom, student).isPresent()) {
            throw new AppException(ErrorCode.ALREADY_ENROLLED);
        }

        ClassroomEnrollment enrollment = ClassroomEnrollment.builder()
                .classroom(classroom)
                .student(student)
                .status(ClassroomEnrollmentStatus.ACTIVE)
                .build();

        ClassroomEnrollment savedEnrollment = enrollmentRepository.save(enrollment);

        notificationService.createNotification(
                student,
                "Classroom Joined",
                "You successfully joined classroom: " + classroom.getName(),
                prm.projectbase.entity.enums.NotificationType.CLASSROOM_JOINED,
                "Classroom",
                classroom.getId()
        );

        return mapToClassroomEnrollmentResponse(savedEnrollment);
    }

    @Transactional
    public ClassroomDetailResponse rotateJoinCode(Long classroomId) {
        Classroom classroom = classroomRepository.findById(classroomId)
                .orElseThrow(() -> new AppException(ErrorCode.CLASSROOM_NOT_FOUND));

        User currentUser = getCurrentUser();
        if (!classroom.getTeacher().getId().equals(currentUser.getId())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        classroom.setJoinCode(generateUniqueJoinCode());
        Classroom updated = classroomRepository.save(classroom);
        return mapToClassroomDetailResponse(updated);
    }

    @Transactional(readOnly = true)
    public List<ClassroomListResponse> getStudentClassrooms() {
        User student = getCurrentUser();
        
        if (!"ROLE_STUDENT".equals(student.getRole().getName())) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        List<ClassroomEnrollment> enrollments = enrollmentRepository.findByStudentAndStatus(
                student, ClassroomEnrollmentStatus.ACTIVE
        );

        return enrollments.stream()
                .map(e -> mapToClassroomListResponse(e.getClassroom()))
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public ClassroomDetailResponse getStudentClassroomDetail(Long classroomId) {
        Classroom classroom = classroomRepository.findById(classroomId)
                .orElseThrow(() -> new AppException(ErrorCode.CLASSROOM_NOT_FOUND));

        User student = getCurrentUser();

        ClassroomEnrollment enrollment = enrollmentRepository.findByClassroomAndStudent(classroom, student)
                .orElseThrow(() -> new AppException(ErrorCode.FORBIDDEN));

        if (!enrollment.getStatus().equals(ClassroomEnrollmentStatus.ACTIVE)) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        return mapToClassroomDetailResponse(classroom);
    }

    private User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new AppException(ErrorCode.UNAUTHENTICATED);
        }
        try {
            Long userId = Long.parseLong(authentication.getName());
            return userRepository.findById(userId)
                    .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));
        } catch (NumberFormatException e) {
            String username = authentication.getName();
            return userRepository.findByUserName(username)
                    .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));
        }
    }

    private String generateUniqueJoinCode() {
        String joinCode;
        do {
            joinCode = generateRandomCode();
        } while (classroomRepository.findByJoinCode(joinCode).isPresent());
        return joinCode;
    }

    private String generateRandomCode() {
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        StringBuilder code = new StringBuilder();
        Random random = new Random();
        for (int i = 0; i < 10; i++) {
            code.append(chars.charAt(random.nextInt(chars.length())));
        }
        return code.toString();
    }

    private void createScheduleForClassroom(Classroom classroom, ClassroomScheduleRequest request) {
        ClassroomSchedule schedule = ClassroomSchedule.builder()
                .classroom(classroom)
                .dayOfWeek(DayOfWeek.of(request.getDayOfWeek() + 1)) 
                .slotLabel(request.getSlotLabel())
                .startTime(request.getStartTime())
                .endTime(request.getEndTime())
                .roomName(request.getRoomName())
                .build();
        if (classroom.getSchedules() == null) {
            classroom.setSchedules(new ArrayList<>());
        }
        classroom.getSchedules().add(schedule);
    }

    private void updateSchedulesForClassroom(Classroom classroom, List<ClassroomScheduleRequest> scheduleRequests) {
        List<ClassroomSchedule> newSchedules = new ArrayList<>();
        if (scheduleRequests != null) {
            scheduleRequests.forEach(req -> {
                ClassroomSchedule schedule = ClassroomSchedule.builder()
                        .classroom(classroom)
                        .dayOfWeek(DayOfWeek.of(req.getDayOfWeek() + 1)) 
                        .slotLabel(req.getSlotLabel())
                        .startTime(req.getStartTime())
                        .endTime(req.getEndTime())
                        .roomName(req.getRoomName())
                        .build();
                newSchedules.add(schedule);
            });
        }
        if (classroom.getSchedules() == null) {
            classroom.setSchedules(new ArrayList<>());
        } else {
            classroom.getSchedules().clear();
        }
        
        // Force flush to delete orphan schedules first to prevent unique constraint conflict on insertion
        classroomRepository.saveAndFlush(classroom);
        
        classroom.getSchedules().addAll(newSchedules);
        classroomRepository.saveAndFlush(classroom);
    }

    private ClassroomDetailResponse mapToClassroomDetailResponse(Classroom classroom) {
        List<ClassroomScheduleResponse> schedules = classroom.getSchedules() != null 
                ? classroom.getSchedules().stream()
                    .map(this::mapToScheduleResponse)
                    .collect(Collectors.toList())
                : Collections.emptyList();

        long studentCount = enrollmentRepository.countByClassroomAndStatus(
                classroom, ClassroomEnrollmentStatus.ACTIVE
        );

        return ClassroomDetailResponse.builder()
                .id(classroom.getId())
                .code(classroom.getCode())
                .name(classroom.getName())
                .description(classroom.getDescription())
                .semesterCode(classroom.getSemesterCode())
                .joinCode(classroom.getJoinCode())
                .active(classroom.isActive())
                .teacher(mapToUserResponse(classroom.getTeacher()))
                .studentCount((int) studentCount)
                .schedules(schedules)
                .createdAt(classroom.getCreatedAt())
                .updatedAt(classroom.getUpdatedAt())
                .build();
    }

    private ClassroomListResponse mapToClassroomListResponse(Classroom classroom) {
        long studentCount = enrollmentRepository.countByClassroomAndStatus(
                classroom, ClassroomEnrollmentStatus.ACTIVE
        );

        return ClassroomListResponse.builder()
                .id(classroom.getId())
                .code(classroom.getCode())
                .name(classroom.getName())
                .semesterCode(classroom.getSemesterCode())
                .teacher(mapToUserResponse(classroom.getTeacher()))
                .studentCount((int) studentCount)
                .active(classroom.isActive())
                .createdAt(classroom.getCreatedAt())
                .build();
    }

    private ClassroomScheduleResponse mapToScheduleResponse(ClassroomSchedule schedule) {
        return ClassroomScheduleResponse.builder()
                .id(schedule.getId())
                .dayOfWeek(schedule.getDayOfWeek().getValue() - 1) 
                .slotLabel(schedule.getSlotLabel())
                .startTime(schedule.getStartTime())
                .endTime(schedule.getEndTime())
                .roomName(schedule.getRoomName())
                .build();
    }

    private ClassroomEnrollmentResponse mapToClassroomEnrollmentResponse(ClassroomEnrollment enrollment) {
        return ClassroomEnrollmentResponse.builder()
                .id(enrollment.getId())
                .classroom(mapToClassroomListResponse(enrollment.getClassroom()))
                .student(mapToUserResponse(enrollment.getStudent()))
                .status(enrollment.getStatus().toString())
                .joinedAt(enrollment.getJoinedAt())
                .build();
    }

    private UserResponse mapToUserResponse(User user) {
        if (user == null) return null;

        RoleResponse roleResponse = null;
        if (user.getRole() != null) {
            roleResponse = RoleResponse.builder()
                    .id(user.getRole().getId())
                    .name(user.getRole().getName())
                    .description(user.getRole().getDescription())
                    .build();
        }

        return UserResponse.builder()
                .id(user.getId())
                .userName(user.getUserName())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .phone(user.getPhone())
                .avatarUrl(user.getAvatarUrl())
                .institutionalId(user.getInstitutionalId())
                .active(user.isActive())
                .role(roleResponse)
                .build();
    }
}
