package com.tjw.eldercare.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("t_health_record")
public class HealthRecord {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long elderId;
    private Integer systolic;
    private Integer diastolic;
    private Integer heartRate;
    private Integer bloodOxygen;
    private String warningLevel;
    private LocalDateTime recordTime;
}
