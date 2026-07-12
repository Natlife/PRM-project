package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import prm.projectbase.entity.Event;

import java.util.List;

public interface EventRepository extends JpaRepository<Event, Long> {
    List<Event> findByClassroomTeacherIdOrderByStartAtDesc(Long teacherId);
    List<Event> findByClassroomIdInOrderByStartAtDesc(List<Long> classroomIds);
}
