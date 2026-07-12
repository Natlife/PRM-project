package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import prm.projectbase.entity.EventAssignment;

import java.util.List;

public interface EventAssignmentRepository extends JpaRepository<EventAssignment, Long> {
    List<EventAssignment> findByEventIdOrderByOrderIndexAsc(Long eventId);
    List<EventAssignment> findByEventIdIn(List<Long> eventIds);
}
