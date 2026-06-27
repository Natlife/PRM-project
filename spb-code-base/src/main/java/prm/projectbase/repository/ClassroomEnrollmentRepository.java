package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import prm.projectbase.entity.ClassroomEnrollment;

import java.util.List;
import java.util.Optional;

public interface ClassroomEnrollmentRepository extends JpaRepository<ClassroomEnrollment, Integer> {
    List<ClassroomEnrollment> findByStudentId(Integer studentId);
    List<ClassroomEnrollment> findByClassroomId(Integer classroomId);
    Optional<ClassroomEnrollment> findByClassroomIdAndStudentId(Integer classroomId, Integer studentId);
}
