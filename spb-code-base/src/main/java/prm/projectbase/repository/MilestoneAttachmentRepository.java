package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import prm.projectbase.entity.MilestoneAttachment;

import java.util.List;

public interface MilestoneAttachmentRepository extends JpaRepository<MilestoneAttachment, Long> {
    List<MilestoneAttachment> findByMilestoneId(Long milestoneId);
    List<MilestoneAttachment> findByMilestoneIdIn(List<Long> milestoneIds);
    void deleteByMilestoneId(Long milestoneId);
}
