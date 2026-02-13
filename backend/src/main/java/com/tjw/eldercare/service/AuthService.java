package com.tjw.eldercare.service;

import com.tjw.eldercare.dto.LoginRequest;
import com.tjw.eldercare.dto.RegisterRequest;

import java.util.Map;

public interface AuthService {
    void register(RegisterRequest request);

    Map<String, Object> login(LoginRequest request);
}
