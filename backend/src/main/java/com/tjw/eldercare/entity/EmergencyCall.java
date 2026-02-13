package com.tjw.eldercare.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("t_emergency_call")
public class EmergencyCall {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long elderId;
    private String location;
    private String detail;
    private String status;
    private LocalDateTime createdAt;
}
