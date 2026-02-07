package com.reliabilitylab.queryservice.api;

import com.reliabilitylab.queryservice.app.QueryBalanceService;
import com.reliabilitylab.queryservice.app.QueryMetricsSnapshot;
import com.reliabilitylab.queryservice.app.QueryResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping
public class QueryController {
    private final QueryBalanceService queryBalanceService;

    public QueryController(QueryBalanceService queryBalanceService) {
        this.queryBalanceService = queryBalanceService;
    }

    @GetMapping("/accounts/{id}/balance")
    public BalanceQueryResponse getBalance(@PathVariable("id") String accountId) {
        QueryResult result = queryBalanceService.queryBalance(accountId);
        return new BalanceQueryResponse(
                result.accountId(),
                result.balance(),
                result.cacheSource().name(),
                result.cacheKey()
        );
    }

    @GetMapping("/internal/query/metrics")
    public QueryMetricsResponse metrics() {
        QueryMetricsSnapshot metrics = queryBalanceService.metrics();
        return new QueryMetricsResponse(metrics.cacheHit(), metrics.cacheMiss(), metrics.dbRead());
    }
}
