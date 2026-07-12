package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import prm.projectbase.entity.EventAsset;

import java.util.List;

public interface EventAssetRepository extends JpaRepository<EventAsset, Long> {
    List<EventAsset> findByEventId(Long eventId);
    List<EventAsset> findByEventIdIn(List<Long> eventIds);
}
