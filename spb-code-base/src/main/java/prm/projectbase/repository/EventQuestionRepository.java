package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import prm.projectbase.entity.EventQuestion;
import prm.projectbase.entity.enums.EventQuestionType;

import java.util.List;

public interface EventQuestionRepository extends JpaRepository<EventQuestion, Long> {
    List<EventQuestion> findByEventIdOrderByAskedAtAsc(Long eventId);
    List<EventQuestion> findByEventIdAndQuestionTypeOrderByAskedAtAsc(Long eventId, EventQuestionType questionType);
    List<EventQuestion> findByEventIdIn(List<Long> eventIds);
}
