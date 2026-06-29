-- MySQL Database Schema and Seed Data for Flipped Classroom App (project_base_db)

CREATE DATABASE IF NOT EXISTS prm_project CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
USE prm_project;

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS peer_reviews;
DROP TABLE IF EXISTS milestone_attachments;
DROP TABLE IF EXISTS project_milestones;
DROP TABLE IF EXISTS project_members;
DROP TABLE IF EXISTS project_groups;
DROP TABLE IF EXISTS submission_comments;
DROP TABLE IF EXISTS submission_attachments;
DROP TABLE IF EXISTS activity_submissions;
DROP TABLE IF EXISTS learning_activities;
DROP TABLE IF EXISTS class_materials;
DROP TABLE IF EXISTS classroom_enrollments;
DROP TABLE IF EXISTS classroom_schedules;
DROP TABLE IF EXISTS classrooms;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS roles;

-- ============================================================================
-- 1. ROLES TABLE
-- ============================================================================
CREATE TABLE roles (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_name (name)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 2. USERS TABLE
-- ============================================================================
CREATE TABLE users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_name VARCHAR(100) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  full_name VARCHAR(255),
  phone VARCHAR(20),
  avatar_url VARCHAR(500),
  institutional_id VARCHAR(50) UNIQUE,
  active BOOLEAN DEFAULT TRUE,
  role_id BIGINT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_users_role_id FOREIGN KEY (role_id) REFERENCES roles(id),
  INDEX idx_user_name (user_name),
  INDEX idx_email (email),
  INDEX idx_active (active),
  INDEX idx_institutional_id (institutional_id),
  INDEX idx_role_id (role_id)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 3. CLASSROOMS TABLE
-- ============================================================================
CREATE TABLE classrooms (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  code VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  semester_code VARCHAR(20),
  join_code VARCHAR(50) NOT NULL,
  teacher_id BIGINT NOT NULL,
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_classrooms_teacher_id FOREIGN KEY (teacher_id) REFERENCES users(id),
  INDEX idx_code (code),
  INDEX idx_join_code (join_code),
  INDEX idx_teacher_id (teacher_id),
  INDEX idx_active (active)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 4. CLASSROOM SCHEDULES TABLE
-- ============================================================================
CREATE TABLE classroom_schedules (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  classroom_id BIGINT NOT NULL,
  day_of_week INT NOT NULL,
  slot_label VARCHAR(50),
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  room_name VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_classroom_schedules_classroom_id FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE CASCADE,
  CONSTRAINT chk_day_of_week CHECK (day_of_week >= 0 AND day_of_week <= 6),
  CONSTRAINT chk_start_before_end CHECK (start_time < end_time),
  INDEX idx_classroom_id (classroom_id),
  INDEX idx_day_of_week (day_of_week),
  UNIQUE KEY unique_schedule_per_classroom (classroom_id, day_of_week, slot_label)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 5. CLASSROOM ENROLLMENTS TABLE
-- ============================================================================
CREATE TABLE classroom_enrollments (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  classroom_id BIGINT NOT NULL,
  student_id BIGINT NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_classroom_enrollments_classroom_id FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE CASCADE,
  CONSTRAINT fk_classroom_enrollments_student_id FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY unique_enrollment (classroom_id, student_id),
  INDEX idx_classroom_id (classroom_id),
  INDEX idx_student_id (student_id),
  INDEX idx_status (status)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 6. CLASS MATERIALS TABLE
-- ============================================================================
CREATE TABLE class_materials (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  classroom_id BIGINT NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  material_type VARCHAR(20) NOT NULL,
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
-- 7. LEARNING ACTIVITIES TABLE
-- ============================================================================
CREATE TABLE learning_activities (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  classroom_id BIGINT NOT NULL,
  title VARCHAR(255) NOT NULL,
  description LONGTEXT NOT NULL,
  activity_type VARCHAR(20) NOT NULL,
  open_at TIMESTAMP NULL,
  due_at TIMESTAMP NOT NULL,
  max_score DECIMAL(5,2) DEFAULT 10.00,
  status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
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
-- 8. ACTIVITY SUBMISSIONS TABLE
-- ============================================================================
CREATE TABLE activity_submissions (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  activity_id BIGINT NOT NULL,
  student_id BIGINT NOT NULL,
  submitted_at TIMESTAMP NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'NOT_SUBMITTED',
  score DECIMAL(5,2),
  teacher_feedback LONGTEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_activity_submissions_activity_id FOREIGN KEY (activity_id) REFERENCES learning_activities(id) ON DELETE CASCADE,
  CONSTRAINT fk_activity_submissions_student_id FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chk_score_valid CHECK (score IS NULL OR (score >= 0 AND score <= 100)),
  UNIQUE KEY unique_submission (activity_id, student_id),
  INDEX idx_activity_id (activity_id),
  INDEX idx_student_id (student_id),
  INDEX idx_status (status),
  INDEX idx_submitted_at (submitted_at)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 9. SUBMISSION ATTACHMENTS TABLE
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
-- 10. SUBMISSION COMMENTS TABLE
-- ============================================================================
CREATE TABLE submission_comments (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  submission_id BIGINT NOT NULL,
  author_id BIGINT NOT NULL,
  content LONGTEXT NOT NULL,
  comment_scope VARCHAR(50) NOT NULL DEFAULT 'PRIVATE',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_submission_comments_submission_id FOREIGN KEY (submission_id) REFERENCES activity_submissions(id) ON DELETE CASCADE,
  CONSTRAINT fk_submission_comments_author_id FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_submission_id (submission_id),
  INDEX idx_author_id (author_id),
  INDEX idx_created_at (created_at)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 11. PROJECT GROUPS TABLE
-- ============================================================================
CREATE TABLE project_groups (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    classroom_id BIGINT NOT NULL,
    group_name VARCHAR(100) NOT NULL,
    project_name VARCHAR(255),
    description TEXT,
    leader_id BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_project_groups_classroom FOREIGN KEY (classroom_id) REFERENCES classrooms(id),
    CONSTRAINT fk_project_groups_leader FOREIGN KEY (leader_id) REFERENCES users(id),
    CONSTRAINT uk_classroom_group_name UNIQUE (classroom_id, group_name),
    INDEX idx_project_groups_classroom (classroom_id)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 12. PROJECT MEMBERS TABLE
-- ============================================================================
CREATE TABLE project_members (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    project_group_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL,
    member_role VARCHAR(50),
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_project_members_group FOREIGN KEY (project_group_id) REFERENCES project_groups(id) ON DELETE CASCADE,
    CONSTRAINT fk_project_members_student FOREIGN KEY (student_id) REFERENCES users(id),
    CONSTRAINT uk_group_student UNIQUE (project_group_id, student_id),
    INDEX idx_project_members_group (project_group_id),
    INDEX idx_project_members_student (student_id)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 13. PROJECT MILESTONES TABLE
-- ============================================================================
CREATE TABLE project_milestones (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    project_group_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    due_at DATETIME,
    progress_percent INT NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'NOT_STARTED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_project_milestones_group FOREIGN KEY (project_group_id) REFERENCES project_groups(id) ON DELETE CASCADE,
    CONSTRAINT chk_milestone_progress CHECK (progress_percent BETWEEN 0 AND 100),
    INDEX idx_project_milestones_group (project_group_id)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 14. MILESTONE ATTACHMENTS TABLE
-- ============================================================================
CREATE TABLE milestone_attachments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    milestone_id BIGINT NOT NULL,
    uploaded_by BIGINT NOT NULL,
    storage_key VARCHAR(512) NOT NULL,
    original_file_name VARCHAR(255) NOT NULL,
    content_type VARCHAR(100),
    size_bytes BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_milestone_attachments_milestone FOREIGN KEY (milestone_id) REFERENCES project_milestones(id) ON DELETE CASCADE,
    CONSTRAINT fk_milestone_attachments_user FOREIGN KEY (uploaded_by) REFERENCES users(id)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 15. PEER REVIEWS TABLE
-- ============================================================================
CREATE TABLE peer_reviews (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    classroom_id BIGINT NOT NULL,
    reviewer_student_id BIGINT NOT NULL,
    reviewed_group_id BIGINT NOT NULL,
    code_quality_score INT NOT NULL,
    ui_ux_score INT NOT NULL,
    feature_score INT NOT NULL,
    presentation_score INT NOT NULL,
    comment TEXT,
    submitted_at DATETIME,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_peer_reviews_classroom FOREIGN KEY (classroom_id) REFERENCES classrooms(id),
    CONSTRAINT fk_peer_reviews_reviewer FOREIGN KEY (reviewer_student_id) REFERENCES users(id),
    CONSTRAINT fk_peer_reviews_group FOREIGN KEY (reviewed_group_id) REFERENCES project_groups(id),
    CONSTRAINT uk_reviewer_group UNIQUE (reviewer_student_id, reviewed_group_id),
    CONSTRAINT chk_code_quality CHECK (code_quality_score BETWEEN 1 AND 5),
    CONSTRAINT chk_ui_ux CHECK (ui_ux_score BETWEEN 1 AND 5),
    CONSTRAINT chk_feature CHECK (feature_score BETWEEN 1 AND 5),
    CONSTRAINT chk_presentation CHECK (presentation_score BETWEEN 1 AND 5),
    INDEX idx_peer_reviews_classroom (classroom_id),
    INDEX idx_peer_reviews_reviewer (reviewer_student_id),
    INDEX idx_peer_reviews_group (reviewed_group_id)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 16. NOTIFICATIONS TABLE
-- ============================================================================
CREATE TABLE notifications (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    recipient_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    body VARCHAR(2000) NOT NULL,
    notification_type VARCHAR(40) NOT NULL,
    reference_type VARCHAR(50),
    reference_id BIGINT,
    read_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_notifications_recipient FOREIGN KEY (recipient_id) REFERENCES users(id),
    INDEX idx_notifications_recipient (recipient_id),
    INDEX idx_notifications_read_at (read_at)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================
CREATE INDEX idx_activity_classroom_and_submissions ON activity_submissions(activity_id, student_id);
CREATE INDEX idx_materials_by_classroom_date ON class_materials(classroom_id, published_at DESC);
CREATE INDEX idx_activities_by_classroom_status ON learning_activities(classroom_id, status);

-- ============================================================================
-- SEED DATA
-- ============================================================================
-- Seed default roles
INSERT INTO roles (id, name, description) VALUES 
  (1, 'ROLE_ADMIN', 'System administrator with full access'),
  (2, 'ROLE_TEACHER', 'Instructor who manages classrooms and activities'),
  (3, 'ROLE_STUDENT', 'Learner who enrolls in classrooms and completes activities');

-- Seed default users (Passwords are BCrypt hashed version of 'admin123', 'teacher123', 'student123')
INSERT INTO users (id, user_name, email, password, full_name, institutional_id, active, role_id) VALUES
  (1, 'admin', 'admin@prm.com', '$2a$10$COIWq1uYlGJRqndeYOnBVexTeljO/aYpc95bvmrG1WrYNZArPs7ge', 'System Administrator', 'SYS-ADMIN', TRUE, 1),
  (2, 'teacher', 'teacher@flippedclassroom.edu.vn', '$2a$10$uIcMnne94R9uiZNmdh.Itug6H9xsKQ1YbzuP2cY1zTh5mxnAKkzNq', 'Default Teacher', 'GV001', TRUE, 2),
  (3, 'student', 'student@flippedclassroom.edu.vn', '$2a$10$0ORlfgFt/D./5sFDwwn6Wukb2VdevF6cUHY3hRuseFelh4yhIkTje', 'Default Student', 'HE160123', TRUE, 3);

-- Seed default classrooms
INSERT INTO classrooms (id, code, name, description, semester_code, join_code, teacher_id, active) VALUES
  (1, 'PRM393', 'Lập trình Thiết bị Di động', 'Môn học phát triển ứng dụng di động với Flutter.', 'SU26', 'JOIN123', 2, TRUE);

-- Seed classroom enrollments
INSERT INTO classroom_enrollments (id, classroom_id, student_id, status) VALUES
  (1, 1, 3, 'ACTIVE');

-- Seed learning activities
INSERT INTO learning_activities (id, classroom_id, title, description, activity_type, open_at, due_at, max_score, status) VALUES
  (1, 1, 'Bài tập lập trình Dart', 'Đọc kỹ slide bài 1, thực hiện các bài lab giới thiệu về Dart cơ bản, hướng đối tượng OOP và lập trình bất đồng bộ.', 'PRE_CLASS', CURRENT_TIMESTAMP, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 2 DAY), 10.00, 'PUBLISHED'),
  (2, 1, 'Trắc nghiệm Flutter Widget', 'Làm bài trắc nghiệm nhanh 15 câu về Stateless và Stateful widget.', 'PRE_CLASS', CURRENT_TIMESTAMP, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 5 DAY), 10.00, 'PUBLISHED');

-- Seed project groups
INSERT INTO project_groups (id, classroom_id, group_name, project_name, description, leader_id, status) VALUES
  (1, 1, 'Nhóm 1', 'Ứng dụng Flipped Classroom', 'Phát triển ứng dụng Flipped Classroom hỗ trợ quản lý học tập và đánh giá chéo.', 3, 'ACTIVE');

-- Seed project members
INSERT INTO project_members (id, project_group_id, student_id, member_role, active) VALUES
  (1, 1, 3, 'LEADER', TRUE);

-- Seed project milestones
INSERT INTO project_milestones (id, project_group_id, title, description, due_at, progress_percent, status) VALUES
  (1, 1, 'Phân tích yêu cầu', 'Lấy yêu cầu từ khách hàng, phân tích sơ đồ luồng dữ liệu (Data Flow Diagram) và thiết kế cơ sở dữ liệu Entity Relationship Diagram (ERD).', DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 10 DAY), 100, 'COMPLETED'),
  (2, 1, 'Thiết kế hệ thống', 'Vẽ wireframe chi tiết các màn hình (Mobile & Web), chuẩn bị kiến trúc thư mục Flutter, viết tài liệu đặc tả chức năng (SRS).', DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 20 DAY), 60, 'IN_PROGRESS'),
  (3, 1, 'Hoàn thiện MVP & Demo', 'Hoàn thành phát triển các tính năng cốt lõi (Authentication, class details, evidence upload), chạy demo thử nghiệm.', DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 30 DAY), 0, 'NOT_STARTED');

-- Seed notifications
INSERT INTO notifications (id, recipient_id, title, body, notification_type, reference_type, reference_id, read_at) VALUES
  (1, 3, 'Hạn nộp bài tập chuẩn bị', 'Bạn có bài tập môn PRM393 - Lập trình Mobile cần nộp trước 23:59 hôm nay.', 'ACTIVITY_ASSIGNED', 'ACTIVITY', 1, NULL),
  (2, 3, 'Điểm số mới được cập nhật', 'Giảng viên đã công bố điểm đánh giá Milestone 1 cho nhóm của bạn.', 'MILESTONE_UPDATED', 'MILESTONE', 1, NULL),
  (3, 3, 'Thông báo lớp học Flipped', 'Tài liệu chuẩn bị cho Bài 5: Flutter State Management đã được đăng tải.', 'MATERIAL_PUBLISHED', 'MATERIAL', 1, CURRENT_TIMESTAMP);
