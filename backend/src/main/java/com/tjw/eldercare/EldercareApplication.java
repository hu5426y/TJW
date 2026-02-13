package com.tjw.eldercare;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@MapperScan("com.tjw.eldercare.mapper")
public class EldercareApplication {
    public static void main(String[] args) {
        SpringApplication.run(EldercareApplication.class, args);
    }
}
