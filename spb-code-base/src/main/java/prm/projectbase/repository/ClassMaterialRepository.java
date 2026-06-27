package prm.projectbase.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import prm.projectbase.entity.ClassMaterial;
import prm.projectbase.entity.Classroom;
import prm.projectbase.entity.enums.ClassroomMaterialType;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ClassMaterialRepository extends JpaRepository<ClassMaterial, Long> {
    
    /**
     * Find all materials in a classroom, ordered by publication date descending
     */
    @Query("SELECT m FROM ClassMaterial m WHERE m.classroom.id = :classroomId ORDER BY m.publishedAt DESC")
    List<ClassMaterial> findByClassroomIdOrderByPublishedAtDesc(@Param("classroomId") Long classroomId);
    
    /**
     * Find materials in a classroom by type
     */
    @Query("SELECT m FROM ClassMaterial m WHERE m.classroom.id = :classroomId AND m.materialType = :type ORDER BY m.publishedAt DESC")
    List<ClassMaterial> findByClassroomAndType(@Param("classroomId") Long classroomId, @Param("type") ClassroomMaterialType type);
    
    /**
     * Find published materials (not future-dated)
     */
    @Query("SELECT m FROM ClassMaterial m WHERE m.classroom.id = :classroomId AND m.publishedAt <= :now ORDER BY m.publishedAt DESC")
    List<ClassMaterial> findPublishedInClassroom(@Param("classroomId") Long classroomId, @Param("now") LocalDateTime now);
    
    /**
     * Check if material belongs to classroom
     */
    @Query("SELECT CASE WHEN COUNT(m) > 0 THEN TRUE ELSE FALSE END FROM ClassMaterial m WHERE m.id = :materialId AND m.classroom.id = :classroomId")
    boolean materialBelongsToClassroom(@Param("materialId") Long materialId, @Param("classroomId") Long classroomId);
    
    /**
     * Count materials in classroom
     */
    Long countByClassroom(Classroom classroom);
}
