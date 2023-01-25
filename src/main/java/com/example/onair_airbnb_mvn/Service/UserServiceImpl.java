package com.example.onair_airbnb_mvn.Service;


import com.example.onair_airbnb_mvn.dto.mapper.UserMapper;
import com.example.onair_airbnb_mvn.dto.user.UserDto;
import com.example.onair_airbnb_mvn.exception.EntityType;
import com.example.onair_airbnb_mvn.exception.ExceptionType;
import com.example.onair_airbnb_mvn.model.user.Role;
import com.example.onair_airbnb_mvn.model.user.User;
import com.example.onair_airbnb_mvn.model.user.UserRoles;
import com.example.onair_airbnb_mvn.repository.user.RoleRepository;
import com.example.onair_airbnb_mvn.repository.user.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.HashSet;

import static com.example.onair_airbnb_mvn.exception.EntityType.USER;
import static com.example.onair_airbnb_mvn.exception.ExceptionType.DUPLICATE_ENTITY;

@Component
public class UserServiceImpl implements UserService {
    @Autowired
    private BCryptPasswordEncoder bCryptPasswordEncoder;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;


    @Override
    public UserDto signup(UserDto userDto) {
        Role userRole;
        User user = userRepository.findByEmail(userDto.getEmail());
        if (user == null) {
            if (userDto.isAdmin()) {
                userRole = roleRepository.findByRole(UserRoles.ADMIN.name());
            } else {
                userRole = roleRepository.findByRole(UserRoles.PASSENGER.name());
            }
            user = new User()
                    .setEmail(userDto.getEmail())
                    .setPassword(bCryptPasswordEncoder.encode(userDto.getPassword()))
                    .setRoles(new HashSet<>(Arrays.asList(userRole)))
                    .setFirstName(userDto.getFirstName())
                    .setLastName(userDto.getLastName())
                    .setMobileNumber(userDto.getMobileNumber());
            return UserMapper.toUserDto(userRepository.save(user));
        }
        throw exception(USER, DUPLICATE_ENTITY, userDto.getEmail());
    }

    @Override
    public UserDto findUserByEmail(String email){

    }

    @Override
    public UserDto updateProfile(UserDto userDto){

    }

    @Override
    public UserDto changePassword(UserDto userDto, String newPassword){

    }


    private RuntimeException exception(EntityType entityType, ExceptionType exceptionType, String... args) {
        return BRSException.throwException(entityType, exceptionType, args);
    }
}




}
