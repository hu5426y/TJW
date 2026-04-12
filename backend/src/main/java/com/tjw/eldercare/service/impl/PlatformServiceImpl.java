package com.tjw.eldercare.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.tjw.eldercare.entity.*;
import com.tjw.eldercare.mapper.*;
import com.tjw.eldercare.service.PlatformService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class PlatformServiceImpl implements PlatformService {
    private final ServiceItemMapper serviceItemMapper;
    private final BookingMapper bookingMapper;
    private final HealthRecordMapper healthRecordMapper;
    private final EmergencyCallMapper emergencyCallMapper;
    private final ComplaintMapper complaintMapper;
    private final StringRedisTemplate redisTemplate;
    private final SimpMessagingTemplate messagingTemplate;

    @Override
    public List<ServiceItem> listServices() {
        return serviceItemMapper.selectList(new LambdaQueryWrapper<ServiceItem>().eq(ServiceItem::getStatus, "ENABLED"));
    }

    @Override
    public void createService(ServiceItem serviceItem) {
        serviceItem.setStatus("ENABLED");
        serviceItemMapper.insert(serviceItem);
        redisTemplate.delete("services:list");
    }

    @Override
    public void createBooking(Booking booking) {
        booking.setStatus("PENDING");
        booking.setFullTrace("预约创建->待接单");
        bookingMapper.insert(booking);
    }

    @Override
    public List<Booking> listBookings() {
        return bookingMapper.selectList(new LambdaQueryWrapper<Booking>().orderByDesc(Booking::getId));
    }

    @Override
    public void saveHealthRecord(HealthRecord healthRecord) {
        healthRecord.setRecordTime(LocalDateTime.now());
        if (healthRecord.getSystolic() > 150 || healthRecord.getHeartRate() > 110) {
            healthRecord.setWarningLevel("HIGH");
            messagingTemplate.convertAndSend("/topic/warning", "检测到高风险健康指标，请及时关注");
        } else {
            healthRecord.setWarningLevel("NORMAL");
        }
        healthRecordMapper.insert(healthRecord);
        redisTemplate.opsForValue().set("health:last:" + healthRecord.getElderId(), healthRecord.getWarningLevel(), Duration.ofHours(1));
    }

    @Override
    public List<HealthRecord> listHealthRecords(Long elderId) {
        return healthRecordMapper.selectList(new LambdaQueryWrapper<HealthRecord>().eq(HealthRecord::getElderId, elderId).orderByDesc(HealthRecord::getRecordTime));
    }

    @Override
    public List<HealthRecord> listHealthRecords() {
        return healthRecordMapper.selectList(new LambdaQueryWrapper<HealthRecord>().orderByDesc(HealthRecord::getRecordTime));
    }

    @Override
    public void emergency(EmergencyCall emergencyCall) {
        emergencyCall.setCreatedAt(LocalDateTime.now());
        emergencyCall.setStatus("PROCESSING");
        emergencyCallMapper.insert(emergencyCall);
        messagingTemplate.convertAndSend("/topic/emergency", "收到新的紧急呼叫，位置：" + emergencyCall.getLocation());
    }

    @Override
    public List<EmergencyCall> listEmergencies() {
        return emergencyCallMapper.selectList(new LambdaQueryWrapper<EmergencyCall>().orderByDesc(EmergencyCall::getCreatedAt));
    }

    @Override
    public void submitComplaint(Complaint complaint) {
        complaint.setStatus("PENDING");
        complaintMapper.insert(complaint);
    }

    @Override
    public List<Complaint> listComplaints() {
        return complaintMapper.selectList(new LambdaQueryWrapper<Complaint>().orderByDesc(Complaint::getId));
    }
}
