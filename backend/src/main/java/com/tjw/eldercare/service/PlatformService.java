package com.tjw.eldercare.service;

import com.tjw.eldercare.entity.*;

import java.util.List;

public interface PlatformService {
    List<ServiceItem> listServices();
    void createService(ServiceItem serviceItem);
    void createBooking(Booking booking);
    List<Booking> listBookings();
    void saveHealthRecord(HealthRecord healthRecord);
    List<HealthRecord> listHealthRecords(Long elderId);
    void emergency(EmergencyCall emergencyCall);
    void submitComplaint(Complaint complaint);
    List<Complaint> listComplaints();
}
