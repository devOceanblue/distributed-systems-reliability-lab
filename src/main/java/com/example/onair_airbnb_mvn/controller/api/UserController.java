package com.example.onair_airbnb_mvn.controller.api;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.ModelAndView;

@RestController
@RequestMapping("/user")
public class UserController {

    @RequestMapping("")
    public ModelAndView hello() {
        return new ModelAndView("hello");
    }
}
