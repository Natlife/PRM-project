package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import prm.projectbase.entity.ProjectGroup;

import java.util.List;

public interface ProjectGroupRepository extends JpaRepository<ProjectGroup, Long> {
    List<ProjectGroup> findByClassroomId(Long classroomId);
    List<ProjectGroup> findByClassroomIdIn(List<Long> classroomIds);
    boolean existsByClassroomIdAndGroupName(Long classroomId, String groupName);
}
