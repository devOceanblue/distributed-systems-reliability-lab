package com.example.onair_airbnb_mvn.controller.api;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/user")
public class UserController {

    @RequestMapping("")
    public String hello() {
        return "hello user!!!!";
    }
}
