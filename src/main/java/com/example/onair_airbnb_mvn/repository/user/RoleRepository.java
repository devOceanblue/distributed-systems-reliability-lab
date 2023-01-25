package com.example.onair_airbnb_mvn.repository.user;

import com.example.onair_airbnb_mvn.model.user.Role;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface RoleRepository extends MongoRepository<Role,String> {
    Role findByRole(String role);
}
