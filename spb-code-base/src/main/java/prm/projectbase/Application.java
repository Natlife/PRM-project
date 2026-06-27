package prm.projectbase;

import prm.projectbase.entity.Role;
import prm.projectbase.entity.User;
import prm.projectbase.repository.RoleRepository;
import prm.projectbase.repository.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.password.PasswordEncoder;

@SpringBootApplication
public class Application {

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}

	@Bean
	public CommandLineRunner databaseInitializer(
			RoleRepository roleRepository,
			UserRepository userRepository,
			PasswordEncoder passwordEncoder) {
		return args -> {
			if (roleRepository.count() == 0) {
				// 1. Initialize Roles
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

				// 2. Initialize Users (Hashed passwords)
				userRepository.save(User.builder()
						.userName("admin")
						.password(passwordEncoder.encode("admin123"))
						.email("admin@prm.com")
						.fullName("System Administrator")
						.institutionalId("SYS-ADMIN")
						.active(true)
						.role(adminRole)
						.build());

				userRepository.save(User.builder()
						.userName("teacher")
						.password(passwordEncoder.encode("teacher123"))
						.email("teacher@flippedclassroom.edu.vn")
						.fullName("Default Teacher")
						.institutionalId("GV001")
						.active(true)
						.role(teacherRole)
						.build());

				userRepository.save(User.builder()
						.userName("student")
						.password(passwordEncoder.encode("student123"))
						.email("student@flippedclassroom.edu.vn")
						.fullName("Default Student")
						.institutionalId("HE160123")
						.active(true)
						.role(studentRole)
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
