package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import prm.projectbase.entity.Classroom;

import java.util.List;
import java.util.Optional;

public interface ClassroomRepository extends JpaRepository<Classroom, Long> {
    List<Classroom> findByTeacherId(Long teacherId);
    List<Classroom> findByTeacherIdAndActiveTrue(Long teacherId);
    List<Classroom> findByActiveTrue();
    Optional<Classroom> findByJoinCode(String joinCode);
    Optional<Classroom> findByCode(String code);
    boolean existsByCode(String code);
}
