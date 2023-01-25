package com.example.onair_airbnb_mvn.dto.mapper;

import com.example.onair_airbnb_mvn.dto.user.RoleDto;
import com.example.onair_airbnb_mvn.dto.user.UserDto;
import com.example.onair_airbnb_mvn.model.user.User;
import org.modelmapper.ModelMapper;

import java.util.HashSet;
import java.util.stream.Collectors;

public class UserMapper {

    public static UserDto toUserDto(User user){
        return new UserDto()
                .setEmail(user.getEmail())
                .setFirstName(user.getFirstName())
                .setLastName(user.getLastName())
                .setMobileNumber(user.getMobileNumber())
                .setRoles(new HashSet<RoleDto>(user
                        .getRoles()
                        .stream()
                        .map(role -> new ModelMapper().map(role, RoleDto.class))
                        .collect(Collectors.toSet())));

    }
}
