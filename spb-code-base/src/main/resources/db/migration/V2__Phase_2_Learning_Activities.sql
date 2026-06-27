-- Phase 2: Learning Activities, Materials, and Submissions Database Schema
-- Author: Production Architecture Team
-- Purpose: Establish learning activities, materials management, and submission tracking

-- ============================================================================
-- CLASS MATERIALS TABLE
-- ============================================================================
CREATE TABLE class_materials (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  classroom_id BIGINT NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  material_type VARCHAR(20) NOT NULL COMMENT 'DOCUMENT, VIDEO, LINK, etc.',
  storage_key VARCHAR(512) NOT NULL,
  original_file_name VARCHAR(255) NOT NULL,
  content_type VARCHAR(120),
  size_bytes BIGINT,
  published_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_class_materials_classroom_id FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE CASCADE,
  INDEX idx_classroom_id (classroom_id),
  INDEX idx_material_type (material_type),
  INDEX idx_published_at (published_at)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- LEARNING ACTIVITIES TABLE
-- ============================================================================
CREATE TABLE learning_activities (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  classroom_id BIGINT NOT NULL,
  title VARCHAR(255) NOT NULL,
  description LONGTEXT NOT NULL,
  activity_type VARCHAR(20) NOT NULL COMMENT 'PRE_CLASS, IN_CLASS, POST_CLASS',
  open_at TIMESTAMP NULL,
  due_at TIMESTAMP NOT NULL,
  max_score DECIMAL(5,2) DEFAULT 10.00,
  status VARCHAR(20) NOT NULL DEFAULT 'DRAFT' COMMENT 'DRAFT, PUBLISHED, CLOSED, ARCHIVED',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_learning_activities_classroom_id FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE CASCADE,
  CONSTRAINT chk_due_at_valid CHECK (due_at IS NOT NULL),
  CONSTRAINT chk_open_before_due CHECK (open_at IS NULL OR open_at < due_at),
  CONSTRAINT chk_max_score_positive CHECK (max_score > 0),
  INDEX idx_classroom_id (classroom_id),
  INDEX idx_activity_type (activity_type),
  INDEX idx_status (status),
  INDEX idx_due_at (due_at)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ACTIVITY SUBMISSIONS TABLE
-- ============================================================================
CREATE TABLE activity_submissions (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  activity_id BIGINT NOT NULL,
  student_id BIGINT NOT NULL,
  submitted_at TIMESTAMP NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'NOT_SUBMITTED' COMMENT 'NOT_SUBMITTED, DRAFT, SUBMITTED, GRADED, LATE_SUBMITTED',
  score DECIMAL(5,2),
  teacher_feedback LONGTEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_activity_submissions_activity_id FOREIGN KEY (activity_id) REFERENCES learning_activities(id) ON DELETE CASCADE,
  CONSTRAINT fk_activity_submissions_student_id FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chk_student_role CHECK (student_id IN (
    SELECT u.id FROM users u 
    INNER JOIN roles r ON u.role_id = r.id 
    WHERE r.name = 'ROLE_STUDENT'
  )),
  CONSTRAINT chk_score_valid CHECK (score IS NULL OR (score >= 0 AND score <= 100)),
  UNIQUE KEY unique_submission (activity_id, student_id),
  INDEX idx_activity_id (activity_id),
  INDEX idx_student_id (student_id),
  INDEX idx_status (status),
  INDEX idx_submitted_at (submitted_at)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SUBMISSION ATTACHMENTS TABLE
-- ============================================================================
CREATE TABLE submission_attachments (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  submission_id BIGINT NOT NULL,
  storage_key VARCHAR(512) NOT NULL,
  original_file_name VARCHAR(255) NOT NULL,
  content_type VARCHAR(120),
  size_bytes BIGINT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_submission_attachments_submission_id FOREIGN KEY (submission_id) REFERENCES activity_submissions(id) ON DELETE CASCADE,
  INDEX idx_submission_id (submission_id)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SUBMISSION COMMENTS TABLE (Discussion Thread)
-- ============================================================================
CREATE TABLE submission_comments (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  submission_id BIGINT NOT NULL,
  author_id BIGINT NOT NULL,
  content LONGTEXT NOT NULL,
  comment_scope VARCHAR(50) NOT NULL DEFAULT 'PRIVATE' COMMENT 'PRIVATE (teacher/student), PUBLIC (class visible)',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_submission_comments_submission_id FOREIGN KEY (submission_id) REFERENCES activity_submissions(id) ON DELETE CASCADE,
  CONSTRAINT fk_submission_comments_author_id FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_submission_id (submission_id),
  INDEX idx_author_id (author_id),
  INDEX idx_created_at (created_at)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================
-- Combined index for querying all submissions for a classroom
CREATE INDEX idx_activity_classroom_and_submissions 
  ON activity_submissions(activity_id, student_id);

-- Index for finding all materials in a classroom ordered by date
CREATE INDEX idx_materials_by_classroom_date 
  ON class_materials(classroom_id, published_at DESC);

-- Index for finding all activities in a classroom by status
CREATE INDEX idx_activities_by_classroom_status 
  ON learning_activities(classroom_id, status);

-- ============================================================================
-- AUDIT LOG
-- ============================================================================
-- Note: For production, consider adding a comprehensive audit log table
-- that captures all changes to activities, submissions, and grades
