package com.tjw.eldercare.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("t_booking")
public class Booking {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long elderId;
    private Long familyId;
    private Long serviceId;
    private String status;
    private LocalDateTime appointmentTime;
    private String fullTrace;
}
