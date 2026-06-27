package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import prm.projectbase.entity.Classroom;
import prm.projectbase.entity.ClassroomEnrollment;
import prm.projectbase.entity.User;
import prm.projectbase.entity.enums.ClassroomEnrollmentStatus;

import java.util.List;
import java.util.Optional;

public interface ClassroomEnrollmentRepository extends JpaRepository<ClassroomEnrollment, Long> {
    List<ClassroomEnrollment> findByStudentId(Integer studentId);
    List<ClassroomEnrollment> findByClassroomId(Integer classroomId);
    Optional<ClassroomEnrollment> findByClassroomIdAndStudentId(Integer classroomId, Integer studentId);
    Optional<ClassroomEnrollment> findByClassroomAndStudent(Classroom classroom, User student);
    List<ClassroomEnrollment> findByStudentAndStatusActive(User student, ClassroomEnrollmentStatus status);
    long countByClassroomAndStatus(Classroom classroom, ClassroomEnrollmentStatus status);
}
