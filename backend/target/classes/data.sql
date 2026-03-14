INSERT INTO t_user (username, password, role, phone, real_name) VALUES
('demo_elder', '$2b$10$1OdoklpaJVC6QnAWAzhUZOylDmmIUa/R2SKxomx8ANSRmFEy6nIJu', 'ELDER', '13800000001', '张爷爷'),
('demo_family', '$2b$10$1OdoklpaJVC6QnAWAzhUZOylDmmIUa/R2SKxomx8ANSRmFEy6nIJu', 'FAMILY', '13800000002', '李女士'),
('demo_provider', '$2b$10$1OdoklpaJVC6QnAWAzhUZOylDmmIUa/R2SKxomx8ANSRmFEy6nIJu', 'PROVIDER', '13800000003', '康养服务站'),
('demo_admin', '$2b$10$1OdoklpaJVC6QnAWAzhUZOylDmmIUa/R2SKxomx8ANSRmFEy6nIJu', 'ADMIN', '13800000004', '社区管理员')
ON DUPLICATE KEY UPDATE username=username;

INSERT INTO t_service_item (title, category, description, price, provider_id, status)
VALUES ('上门助浴', '生活照护', '专业护理员上门助浴服务', 120.00, 3, 'ENABLED')
ON DUPLICATE KEY UPDATE title=title;
