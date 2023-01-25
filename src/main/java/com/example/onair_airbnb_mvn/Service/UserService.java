package com.example.onair_airbnb_mvn.Service;

import com.example.onair_airbnb_mvn.dto.user.UserDto;

public interface UserService {

    UserDto signup(UserDto userDto);

    UserDto findUserByEmail(String email);

    UserDto updateProfile(UserDto userDto);

    UserDto changePassword(UserDto userDto, String newPassword);


}
