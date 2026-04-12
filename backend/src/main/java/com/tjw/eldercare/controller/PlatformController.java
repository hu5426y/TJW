package com.tjw.eldercare.controller;

import com.tjw.eldercare.common.ApiResponse;
import com.tjw.eldercare.entity.*;
import com.tjw.eldercare.service.PlatformService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/platform")
@RequiredArgsConstructor
public class PlatformController {
    private final PlatformService platformService;

    @GetMapping("/services")
    public ApiResponse<List<ServiceItem>> listServices() {
        return ApiResponse.success(platformService.listServices());
    }

    @PostMapping("/services")
    @PreAuthorize("hasAnyRole('PROVIDER','ADMIN')")
    public ApiResponse<String> createService(@RequestBody ServiceItem serviceItem) {
        platformService.createService(serviceItem);
        return ApiResponse.success("服务发布成功");
    }

    @PostMapping("/bookings")
    @PreAuthorize("hasAnyRole('ELDER','FAMILY')")
    public ApiResponse<String> createBooking(@RequestBody Booking booking) {
        platformService.createBooking(booking);
        return ApiResponse.success("预约提交成功");
    }

    @GetMapping("/bookings")
    public ApiResponse<List<Booking>> listBookings() {
        return ApiResponse.success(platformService.listBookings());
    }

    @PostMapping("/health")
    public ApiResponse<String> saveHealth(@RequestBody HealthRecord healthRecord) {
        platformService.saveHealthRecord(healthRecord);
        return ApiResponse.success("健康数据已上报");
    }

    @GetMapping("/health/{elderId}")
    public ApiResponse<List<HealthRecord>> listHealth(@PathVariable Long elderId) {
        return ApiResponse.success(platformService.listHealthRecords(elderId));
    }

    @GetMapping("/health")
    @PreAuthorize("hasRole('ADMIN')")
    public ApiResponse<List<HealthRecord>> listAllHealth() {
        return ApiResponse.success(platformService.listHealthRecords());
    }

    @PostMapping("/emergency")
    @PreAuthorize("hasRole('ELDER')")
    public ApiResponse<String> emergency(@RequestBody EmergencyCall emergencyCall) {
        platformService.emergency(emergencyCall);
        return ApiResponse.success("紧急呼叫已发送");
    }

    @GetMapping("/emergency")
    @PreAuthorize("hasRole('ADMIN')")
    public ApiResponse<List<EmergencyCall>> emergencies() {
        return ApiResponse.success(platformService.listEmergencies());
    }

    @PostMapping("/complaints")
    public ApiResponse<String> complaint(@RequestBody Complaint complaint) {
        platformService.submitComplaint(complaint);
        return ApiResponse.success("投诉已提交");
    }

    @GetMapping("/complaints")
    @PreAuthorize("hasRole('ADMIN')")
    public ApiResponse<List<Complaint>> complaints() {
        return ApiResponse.success(platformService.listComplaints());
    }
}
