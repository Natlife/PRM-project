-- Phase 1: Identity and Classroom Management Database Schema
-- Author: Production Architecture Team
-- Purpose: Establish core identity, classroom, and enrollment structures

-- ============================================================================
-- ROLES TABLE
-- ============================================================================
CREATE TABLE roles (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_name (name)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed default roles
INSERT INTO roles (name, description) VALUES 
  ('ROLE_ADMIN', 'System administrator with full access'),
  ('ROLE_TEACHER', 'Instructor who manages classrooms and activities'),
  ('ROLE_STUDENT', 'Learner who enrolls in classrooms and completes activities');

-- ============================================================================
-- USERS TABLE
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
-- CLASSROOMS TABLE
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
  CONSTRAINT chk_teacher_role CHECK (teacher_id IN (
    SELECT u.id FROM users u 
    INNER JOIN roles r ON u.role_id = r.id 
    WHERE r.name = 'ROLE_TEACHER'
  )),
  INDEX idx_code (code),
  INDEX idx_join_code (join_code),
  INDEX idx_teacher_id (teacher_id),
  INDEX idx_active (active)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- CLASSROOM SCHEDULES TABLE
-- ============================================================================
CREATE TABLE classroom_schedules (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  classroom_id BIGINT NOT NULL,
  day_of_week INT NOT NULL COMMENT '0=Sunday, 1=Monday, ..., 6=Saturday',
  slot_label VARCHAR(50) COMMENT 'e.g., "Slot 1", "Morning", etc.',
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
-- CLASSROOM ENROLLMENTS TABLE
-- ============================================================================
CREATE TABLE classroom_enrollments (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  classroom_id BIGINT NOT NULL,
  student_id BIGINT NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'ENROLLED' COMMENT 'ENROLLED, DROPPED, etc.',
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_classroom_enrollments_classroom_id FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE CASCADE,
  CONSTRAINT fk_classroom_enrollments_student_id FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chk_student_role CHECK (student_id IN (
    SELECT u.id FROM users u 
    INNER JOIN roles r ON u.role_id = r.id 
    WHERE r.name = 'ROLE_STUDENT'
  )),
  UNIQUE KEY unique_enrollment (classroom_id, student_id),
  INDEX idx_classroom_id (classroom_id),
  INDEX idx_student_id (student_id),
  INDEX idx_status (status)
) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- AUDIT LOG HELPER
-- ============================================================================
-- Note: For future production hardening, add a proper audit log table
-- that captures all changes to sensitive entities (users, enrollments, etc.)
-- Structure: id, entity_type, entity_id, action, old_value, new_value, 
--           actor_id, timestamp
