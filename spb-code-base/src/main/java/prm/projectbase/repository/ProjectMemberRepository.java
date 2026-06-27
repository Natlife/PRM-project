package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import prm.projectbase.entity.ProjectMember;

import java.util.List;
import java.util.Optional;

public interface ProjectMemberRepository extends JpaRepository<ProjectMember, Long> {
    List<ProjectMember> findByProjectGroupId(Long projectGroupId);
    List<ProjectMember> findByStudentId(Long studentId);
    Optional<ProjectMember> findByProjectGroupIdAndStudentId(Long projectGroupId, Long studentId);
    Optional<ProjectMember> findByStudentIdAndProjectGroupClassroomIdAndActiveTrue(Long studentId, Long classroomId);
    boolean existsByProjectGroupIdAndStudentIdAndActiveTrue(Long projectGroupId, Long studentId);
}
