package com.example.onair_airbnb_mvn.ui;

import com.example.onair_airbnb_mvn.controller.command.SignupFormCommand;
import com.example.onair_airbnb_mvn.dto.user.UserDto;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Controller;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.servlet.ModelAndView;

import javax.validation.Valid;

@Controller
public class AdminController {
    @GetMapping(value = {"/", "/login"})
    public ModelAndView login() {
        return new ModelAndView("login");
    }

    @GetMapping(value="logout")
    public String logout() {
        SecurityContextHolder.getContext().setAuthentication(null);
        return "redirect:login";
    }

    @GetMapping(value = "/signup")
    public ModelAndView signup() {
        ModelAndView modelAndView = new ModelAndView("signup");
        modelAndView.addObject("SignupFormData", new SignupFormCommand());
        return modelAndView;
    }

    @PostMapping(value="/signup")
    public ModelAndView createUser(@Valid @ModelAttribute("SignupFormData") SignupFormCommand signupFormCommand, BindingResult bindingResult){
        ModelAndView modelAndView = new ModelAndView("signup");
        if(bindingResult.hasErrors()){
            return modelAndView;
        } else {
            try {
                UserDto newUser = registerUser(signupFormCommand);
            } catch (Exception exception) {
                bindingResult.rejectValue("email", "error.signupFormCommand", exception.getMessage());
                return modelAndView;
            }
        }
        return new ModelAndView("login");
    }

    private UserDto registerUser(@Valid SignupFormCommand signupFormCommand){
        UserDto userDto = new UserDto()
                .setEmail(signupFormCommand.getEmail())
                .setPassword(signupFormCommand.getPassword())
                .setFirstName(signupFormCommand.getFirstName())
                .setLastName(signupFormCommand.getLastName())
                .setMobileNumber(signupFormCommand.getMobileNumber())
                .setAdmin(true);
    }

}
