package com.example.onair_airbnb_mvn.repository.user;

import com.example.onair_airbnb_mvn.model.user.User;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface UserRepository extends MongoRepository<User, String> {
    User findByEmail(String email);
}
