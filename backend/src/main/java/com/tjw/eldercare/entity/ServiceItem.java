package com.tjw.eldercare.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;

@Data
@TableName("t_service_item")
public class ServiceItem {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String title;
    private String category;
    private String description;
    private BigDecimal price;
    private Long providerId;
    private String status;
}
