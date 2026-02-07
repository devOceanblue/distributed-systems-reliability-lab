package com.reliabilitylab.queryservice.infra;

import com.reliabilitylab.queryservice.app.ProjectionBalanceReader;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class ProjectionJdbcReader implements ProjectionBalanceReader {
    private final JdbcTemplate jdbcTemplate;

    public ProjectionJdbcReader(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public long readBalance(String accountId) {
        Long balance = jdbcTemplate.queryForObject(
                "SELECT balance FROM account_projection WHERE account_id = ?",
                Long.class,
                accountId
        );
        return balance == null ? 0L : balance;
    }
}
