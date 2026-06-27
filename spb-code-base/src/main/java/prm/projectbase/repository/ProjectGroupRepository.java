package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import prm.projectbase.entity.ProjectGroup;

import java.util.List;

public interface ProjectGroupRepository extends JpaRepository<ProjectGroup, Integer> {
    List<ProjectGroup> findByClassroomId(Integer classroomId);
}
