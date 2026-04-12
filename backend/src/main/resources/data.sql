INSERT INTO t_user (username, password, role, phone, real_name)
SELECT 'demo_elder', '$2b$10$1OdoklpaJVC6QnAWAzhUZOylDmmIUa/R2SKxomx8ANSRmFEy6nIJu', 'ELDER', '13800000001', '张爷爷'
WHERE NOT EXISTS (SELECT 1 FROM t_user WHERE username = 'demo_elder');

INSERT INTO t_user (username, password, role, phone, real_name)
SELECT 'demo_family', '$2b$10$1OdoklpaJVC6QnAWAzhUZOylDmmIUa/R2SKxomx8ANSRmFEy6nIJu', 'FAMILY', '13800000002', '李女士'
WHERE NOT EXISTS (SELECT 1 FROM t_user WHERE username = 'demo_family');

INSERT INTO t_user (username, password, role, phone, real_name)
SELECT 'demo_provider', '$2b$10$1OdoklpaJVC6QnAWAzhUZOylDmmIUa/R2SKxomx8ANSRmFEy6nIJu', 'PROVIDER', '13800000003', '康养服务站'
WHERE NOT EXISTS (SELECT 1 FROM t_user WHERE username = 'demo_provider');

INSERT INTO t_user (username, password, role, phone, real_name)
SELECT 'demo_admin', '$2b$10$1OdoklpaJVC6QnAWAzhUZOylDmmIUa/R2SKxomx8ANSRmFEy6nIJu', 'ADMIN', '13800000004', '社区管理员'
WHERE NOT EXISTS (SELECT 1 FROM t_user WHERE username = 'demo_admin');

UPDATE t_user
SET password = '$2b$10$1OdoklpaJVC6QnAWAzhUZOylDmmIUa/R2SKxomx8ANSRmFEy6nIJu',
    role = 'ELDER',
    phone = '13800000001',
    real_name = '张爷爷'
WHERE username = 'demo_elder';

UPDATE t_user
SET password = '$2b$10$1OdoklpaJVC6QnAWAzhUZOylDmmIUa/R2SKxomx8ANSRmFEy6nIJu',
    role = 'FAMILY',
    phone = '13800000002',
    real_name = '李女士'
WHERE username = 'demo_family';

UPDATE t_user
SET password = '$2b$10$1OdoklpaJVC6QnAWAzhUZOylDmmIUa/R2SKxomx8ANSRmFEy6nIJu',
    role = 'PROVIDER',
    phone = '13800000003',
    real_name = '康养服务站'
WHERE username = 'demo_provider';

UPDATE t_user
SET password = '$2b$10$1OdoklpaJVC6QnAWAzhUZOylDmmIUa/R2SKxomx8ANSRmFEy6nIJu',
    role = 'ADMIN',
    phone = '13800000004',
    real_name = '社区管理员'
WHERE username = 'demo_admin';

DELETE FROM t_service_item
WHERE HEX(title) = 'C3A4C2B8C5A0C3A9E28094C2A8C3A5C5A0C2A9C3A6C2B5C2B4';

INSERT INTO t_service_item (title, category, description, price, provider_id, status)
SELECT '上门助浴', '生活照护', '专业护理员上门助浴服务', 120.00,
       (SELECT id FROM t_user WHERE username = 'demo_provider'),
       'ENABLED'
WHERE NOT EXISTS (
  SELECT 1 FROM t_service_item
  WHERE title = '上门助浴'
    AND provider_id = (SELECT id FROM t_user WHERE username = 'demo_provider')
);

INSERT INTO t_service_item (title, category, description, price, provider_id, status)
SELECT '康复陪诊', '医疗陪护', '陪同门诊、取药与康复复诊提醒', 168.00,
       (SELECT id FROM t_user WHERE username = 'demo_provider'),
       'ENABLED'
WHERE NOT EXISTS (
  SELECT 1 FROM t_service_item
  WHERE title = '康复陪诊'
    AND provider_id = (SELECT id FROM t_user WHERE username = 'demo_provider')
);

INSERT INTO t_service_item (title, category, description, price, provider_id, status)
SELECT '助餐配送', '生活照护', '午晚餐配送与饮食偏好记录', 48.00,
       (SELECT id FROM t_user WHERE username = 'demo_provider'),
       'ENABLED'
WHERE NOT EXISTS (
  SELECT 1 FROM t_service_item
  WHERE title = '助餐配送'
    AND provider_id = (SELECT id FROM t_user WHERE username = 'demo_provider')
);

INSERT INTO t_service_item (title, category, description, price, provider_id, status)
SELECT '夜间巡护', '安全守护', '夜间上门巡查、睡眠与跌倒风险关注', 96.00,
       (SELECT id FROM t_user WHERE username = 'demo_provider'),
       'ENABLED'
WHERE NOT EXISTS (
  SELECT 1 FROM t_service_item
  WHERE title = '夜间巡护'
    AND provider_id = (SELECT id FROM t_user WHERE username = 'demo_provider')
);

INSERT INTO t_booking (elder_id, family_id, service_id, status, appointment_time, full_trace)
SELECT
  (SELECT id FROM t_user WHERE username = 'demo_elder'),
  NULL,
  (SELECT id FROM t_service_item WHERE title = '上门助浴' LIMIT 1),
  'PENDING',
  DATE_ADD(NOW(), INTERVAL 1 DAY),
  '预约创建->待接单'
WHERE NOT EXISTS (
  SELECT 1 FROM t_booking
  WHERE elder_id = (SELECT id FROM t_user WHERE username = 'demo_elder')
    AND service_id = (SELECT id FROM t_service_item WHERE title = '上门助浴' LIMIT 1)
    AND status = 'PENDING'
);

INSERT INTO t_booking (elder_id, family_id, service_id, status, appointment_time, full_trace)
SELECT
  (SELECT id FROM t_user WHERE username = 'demo_elder'),
  (SELECT id FROM t_user WHERE username = 'demo_family'),
  (SELECT id FROM t_service_item WHERE title = '康复陪诊' LIMIT 1),
  'ASSIGNED',
  DATE_ADD(NOW(), INTERVAL 2 DAY),
  '预约创建->已派单->待上门'
WHERE NOT EXISTS (
  SELECT 1 FROM t_booking
  WHERE family_id = (SELECT id FROM t_user WHERE username = 'demo_family')
    AND service_id = (SELECT id FROM t_service_item WHERE title = '康复陪诊' LIMIT 1)
    AND status = 'ASSIGNED'
);

INSERT INTO t_booking (elder_id, family_id, service_id, status, appointment_time, full_trace)
SELECT
  (SELECT id FROM t_user WHERE username = 'demo_elder'),
  NULL,
  (SELECT id FROM t_service_item WHERE title = '助餐配送' LIMIT 1),
  'COMPLETED',
  DATE_SUB(NOW(), INTERVAL 2 DAY),
  '预约创建->已派单->服务完成'
WHERE NOT EXISTS (
  SELECT 1 FROM t_booking
  WHERE elder_id = (SELECT id FROM t_user WHERE username = 'demo_elder')
    AND service_id = (SELECT id FROM t_service_item WHERE title = '助餐配送' LIMIT 1)
    AND status = 'COMPLETED'
);

INSERT INTO t_health_record (elder_id, systolic, diastolic, heart_rate, blood_oxygen, warning_level, record_time)
SELECT
  (SELECT id FROM t_user WHERE username = 'demo_elder'),
  122, 82, 74, 98, 'NORMAL',
  DATE_SUB(NOW(), INTERVAL 2 DAY)
WHERE NOT EXISTS (
  SELECT 1 FROM t_health_record
  WHERE elder_id = (SELECT id FROM t_user WHERE username = 'demo_elder')
    AND systolic = 122
    AND diastolic = 82
    AND heart_rate = 74
);

INSERT INTO t_health_record (elder_id, systolic, diastolic, heart_rate, blood_oxygen, warning_level, record_time)
SELECT
  (SELECT id FROM t_user WHERE username = 'demo_elder'),
  158, 96, 112, 93, 'HIGH',
  DATE_SUB(NOW(), INTERVAL 1 DAY)
WHERE NOT EXISTS (
  SELECT 1 FROM t_health_record
  WHERE elder_id = (SELECT id FROM t_user WHERE username = 'demo_elder')
    AND systolic = 158
    AND diastolic = 96
    AND heart_rate = 112
);

INSERT INTO t_health_record (elder_id, systolic, diastolic, heart_rate, blood_oxygen, warning_level, record_time)
SELECT
  (SELECT id FROM t_user WHERE username = 'demo_elder'),
  136, 88, 83, 97, 'NORMAL',
  DATE_SUB(NOW(), INTERVAL 5 HOUR)
WHERE NOT EXISTS (
  SELECT 1 FROM t_health_record
  WHERE elder_id = (SELECT id FROM t_user WHERE username = 'demo_elder')
    AND systolic = 136
    AND diastolic = 88
    AND heart_rate = 83
);

INSERT INTO t_complaint (user_id, booking_id, type, content, status, reply)
SELECT
  (SELECT id FROM t_user WHERE username = 'demo_family'),
  (SELECT id FROM t_booking WHERE status = 'COMPLETED' ORDER BY id DESC LIMIT 1),
  '履约问题',
  '服务人员迟到约20分钟，沟通提醒不及时。',
  'PENDING',
  NULL
WHERE NOT EXISTS (
  SELECT 1 FROM t_complaint
  WHERE user_id = (SELECT id FROM t_user WHERE username = 'demo_family')
    AND type = '履约问题'
    AND status = 'PENDING'
);

INSERT INTO t_complaint (user_id, booking_id, type, content, status, reply)
SELECT
  (SELECT id FROM t_user WHERE username = 'demo_elder'),
  (SELECT id FROM t_booking WHERE status = 'ASSIGNED' ORDER BY id DESC LIMIT 1),
  '服务态度',
  '上门前未提前电话确认，希望增加提醒。',
  'RESOLVED',
  '已完成服务站回访，并补充上门前30分钟电话提醒。'
WHERE NOT EXISTS (
  SELECT 1 FROM t_complaint
  WHERE user_id = (SELECT id FROM t_user WHERE username = 'demo_elder')
    AND type = '服务态度'
    AND status = 'RESOLVED'
);

INSERT INTO t_emergency_call (elder_id, location, detail, status, created_at)
SELECT
  (SELECT id FROM t_user WHERE username = 'demo_elder'),
  '3号楼2单元',
  '夜间胸闷，已通知社区值班人员回电确认。',
  'PROCESSING',
  DATE_SUB(NOW(), INTERVAL 3 HOUR)
WHERE NOT EXISTS (
  SELECT 1 FROM t_emergency_call
  WHERE elder_id = (SELECT id FROM t_user WHERE username = 'demo_elder')
    AND location = '3号楼2单元'
    AND status = 'PROCESSING'
);
