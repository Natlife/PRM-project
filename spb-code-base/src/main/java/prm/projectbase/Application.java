package prm.projectbase;

import prm.projectbase.entity.*;
import prm.projectbase.entity.enums.*;
import prm.projectbase.repository.*;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.password.PasswordEncoder;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@SpringBootApplication
public class Application {

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}

	@Bean
	public CommandLineRunner databaseInitializer(
			RoleRepository roleRepository,
			UserRepository userRepository,
			ClassroomRepository classroomRepository,
			ClassroomEnrollmentRepository classroomEnrollmentRepository,
			LearningActivityRepository learningActivityRepository,
			ProjectGroupRepository projectGroupRepository,
			ProjectMemberRepository projectMemberRepository,
			ProjectMilestoneRepository projectMilestoneRepository,
			NotificationRepository notificationRepository,
			PasswordEncoder passwordEncoder) {
		return args -> {
			if (roleRepository.count() == 0) {
				
				Role adminRole = roleRepository.save(Role.builder()
						.name("ROLE_ADMIN")
						.description("Administrator with full system privileges")
						.build());

				Role teacherRole = roleRepository.save(Role.builder()
						.name("ROLE_TEACHER")
						.description("Teacher with ownership over assigned classrooms")
						.build());

				Role studentRole = roleRepository.save(Role.builder()
						.name("ROLE_STUDENT")
						.description("Student participating in classrooms, submissions, and peer review")
						.build());

				User adminUser = userRepository.save(User.builder()
						.userName("admin")
						.password(passwordEncoder.encode("admin123"))
						.email("admin@prm.com")
						.fullName("System Administrator")
						.institutionalId("SYS-ADMIN")
						.active(true)
						.role(adminRole)
						.build());

				User teacherUser = userRepository.save(User.builder()
						.userName("teacher")
						.password(passwordEncoder.encode("teacher123"))
						.email("teacher@flippedclassroom.edu.vn")
						.fullName("Default Teacher")
						.institutionalId("GV001")
						.active(true)
						.role(teacherRole)
						.build());

				User studentUser = userRepository.save(User.builder()
						.userName("student")
						.password(passwordEncoder.encode("student123"))
						.email("student@flippedclassroom.edu.vn")
						.fullName("Default Student")
						.institutionalId("HE160123")
						.active(true)
						.role(studentRole)
						.build());

				Classroom classroom = classroomRepository.save(Classroom.builder()
						.code("PRM393")
						.name("Lập trình Thiết bị Di động")
						.description("Môn học phát triển ứng dụng di động với Flutter.")
						.semesterCode("SU26")
						.joinCode("JOIN123")
						.teacher(teacherUser)
						.active(true)
						.build());

				classroomEnrollmentRepository.save(ClassroomEnrollment.builder()
						.classroom(classroom)
						.student(studentUser)
						.status(ClassroomEnrollmentStatus.ACTIVE)
						.build());

				LearningActivity act1 = learningActivityRepository.save(LearningActivity.builder()
						.classroom(classroom)
						.title("Bài tập lập trình Dart")
						.description("Đọc kỹ slide bài 1, thực hiện các bài lab giới thiệu về Dart cơ bản, hướng đối tượng OOP và lập trình bất đồng bộ.")
						.activityType(ActivityType.PRE_CLASS)
						.openAt(LocalDateTime.now())
						.dueAt(LocalDateTime.now().plusDays(2))
						.maxScore(BigDecimal.valueOf(10.00))
						.status(ActivityWorkflowStatus.PUBLISHED)
						.build());

				learningActivityRepository.save(LearningActivity.builder()
						.classroom(classroom)
						.title("Trắc nghiệm Flutter Widget")
						.description("Làm bài trắc nghiệm nhanh 15 câu về Stateless và Stateful widget.")
						.activityType(ActivityType.PRE_CLASS)
						.openAt(LocalDateTime.now())
						.dueAt(LocalDateTime.now().plusDays(5))
						.maxScore(BigDecimal.valueOf(10.00))
						.status(ActivityWorkflowStatus.PUBLISHED)
						.build());

				ProjectGroup group = projectGroupRepository.save(ProjectGroup.builder()
						.classroom(classroom)
						.groupName("Nhóm 1")
						.projectName("Ứng dụng Flipped Classroom")
						.description("Phát triển ứng dụng Flipped Classroom hỗ trợ quản lý học tập và đánh giá chéo.")
						.leader(studentUser)
						.status(ProjectGroupStatus.ACTIVE)
						.build());

				projectMemberRepository.save(ProjectMember.builder()
						.projectGroup(group)
						.student(studentUser)
						.memberRole(ProjectMemberRole.LEADER)
						.active(true)
						.build());

				projectMilestoneRepository.save(ProjectMilestone.builder()
						.projectGroup(group)
						.title("Phân tích yêu cầu")
						.description("Lấy yêu cầu từ khách hàng, phân tích sơ đồ luồng dữ liệu (Data Flow Diagram) và thiết kế cơ sở dữ liệu Entity Relationship Diagram (ERD).")
						.dueAt(LocalDateTime.now().plusDays(10))
						.progressPercent(100)
						.status(MilestoneWorkflowStatus.COMPLETED)
						.build());

				projectMilestoneRepository.save(ProjectMilestone.builder()
						.projectGroup(group)
						.title("Thiết kế hệ thống")
						.description("Vẽ wireframe chi tiết các màn hình (Mobile & Web), chuẩn bị kiến trúc thư mục Flutter, viết tài liệu đặc tả chức năng (SRS).")
						.dueAt(LocalDateTime.now().plusDays(20))
						.progressPercent(60)
						.status(MilestoneWorkflowStatus.IN_PROGRESS)
						.build());

				projectMilestoneRepository.save(ProjectMilestone.builder()
						.projectGroup(group)
						.title("Hoàn thiện MVP & Demo")
						.description("Hoàn thành phát triển các tính năng cốt lõi (Authentication, class details, evidence upload), chạy demo thử nghiệm.")
						.dueAt(LocalDateTime.now().plusDays(30))
						.progressPercent(0)
						.status(MilestoneWorkflowStatus.NOT_STARTED)
						.build());

				notificationRepository.save(AppNotification.builder()
						.recipient(studentUser)
						.title("Hạn nộp bài tập chuẩn bị")
						.body("Bạn có bài tập môn PRM393 - Lập trình Mobile cần nộp trước 23:59 hôm nay.")
						.notificationType(NotificationType.ACTIVITY_ASSIGNED)
						.referenceType("ACTIVITY")
						.referenceId(act1.getId())
						.readAt(null)
						.build());

				notificationRepository.save(AppNotification.builder()
						.recipient(studentUser)
						.title("Điểm số mới được cập nhật")
						.body("Giảng viên đã công bố điểm đánh giá Milestone 1 cho nhóm của bạn.")
						.notificationType(NotificationType.ACTIVITY_GRADED)
						.referenceType("MILESTONE")
						.referenceId(1L)
						.readAt(null)
						.build());

				System.out.println("\n======================================================================");
				System.out.println("   DATABASE SEEDED SUCCESSFULLY FOR DEVELOPMENT & LOCAL TESTING      ");
				System.out.println("======================================================================");
				System.out.println("Admin Account details       -> Username: admin,   Password: admin123");
				System.out.println("Teacher Account details     -> Username: teacher, Password: teacher123");
				System.out.println("Student Account details     -> Username: student, Password: student123");
				System.out.println("Database profile            -> MySQL via application.properties");
				System.out.println("======================================================================\n");
			}
		};
	}
}
