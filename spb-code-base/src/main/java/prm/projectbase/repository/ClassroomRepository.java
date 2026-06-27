package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import prm.projectbase.entity.Classroom;

import java.util.List;
import java.util.Optional;

public interface ClassroomRepository extends JpaRepository<Classroom, Integer> {
    List<Classroom> findByTeacherIdAndActiveTrue(Integer teacherId);
    List<Classroom> findByActiveTrue();
    Optional<Classroom> findByJoinCode(String joinCode);
    boolean existsByCode(String code);
}
