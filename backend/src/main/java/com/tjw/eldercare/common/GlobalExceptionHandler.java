package com.tjw.eldercare.common;

import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(Exception.class)
    public ApiResponse<String> handleException(Exception exception) {
        return ApiResponse.fail(exception.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ApiResponse<String> handleValidException(MethodArgumentNotValidException exception) {
        return ApiResponse.fail(exception.getBindingResult().getFieldError() == null
                ? "参数校验失败" : exception.getBindingResult().getFieldError().getDefaultMessage());
    }
}
