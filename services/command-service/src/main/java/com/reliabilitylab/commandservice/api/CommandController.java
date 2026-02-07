package com.reliabilitylab.commandservice.api;

import com.reliabilitylab.commandservice.app.CommandApplicationService;
import com.reliabilitylab.commandservice.app.CommandResult;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/accounts")
public class CommandController {
    private final CommandApplicationService commandApplicationService;

    public CommandController(CommandApplicationService commandApplicationService) {
        this.commandApplicationService = commandApplicationService;
    }

    @PostMapping("/{id}/deposit")
    public BalanceCommandResponse deposit(@PathVariable("id") String accountId,
                                          @RequestBody @Valid BalanceCommandRequest request) {
        CommandResult result = commandApplicationService.deposit(accountId, request.txId(), request.amount(), request.traceId());
        return new BalanceCommandResponse(
                accountId,
                request.txId(),
                request.amount(),
                result.balance(),
                result.produceMode(),
                "OK"
        );
    }

    @PostMapping("/{id}/withdraw")
    public BalanceCommandResponse withdraw(@PathVariable("id") String accountId,
                                           @RequestBody @Valid BalanceCommandRequest request) {
        CommandResult result = commandApplicationService.withdraw(accountId, request.txId(), request.amount(), request.traceId());
        return new BalanceCommandResponse(
                accountId,
                request.txId(),
                -request.amount(),
                result.balance(),
                result.produceMode(),
                "OK"
        );
    }
}
