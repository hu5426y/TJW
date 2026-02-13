CREATE TABLE IF NOT EXISTS t_user (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL,
    phone VARCHAR(20),
    real_name VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS t_service_item (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(100),
    category VARCHAR(50),
    description TEXT,
    price DECIMAL(10,2),
    provider_id BIGINT,
    status VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS t_booking (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    elder_id BIGINT,
    family_id BIGINT,
    service_id BIGINT,
    status VARCHAR(20),
    appointment_time DATETIME,
    full_trace VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS t_health_record (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    elder_id BIGINT,
    systolic INT,
    diastolic INT,
    heart_rate INT,
    blood_oxygen INT,
    warning_level VARCHAR(20),
    record_time DATETIME
);

CREATE TABLE IF NOT EXISTS t_complaint (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT,
    booking_id BIGINT,
    type VARCHAR(20),
    content TEXT,
    status VARCHAR(20),
    reply VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS t_emergency_call (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    elder_id BIGINT,
    location VARCHAR(255),
    detail VARCHAR(255),
    status VARCHAR(20),
    created_at DATETIME
);
