/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

interface IVWManager {
    struct VWExecuteParam {
        uint256 code;
        uint256 gasTokenPrice;
        uint256 priorityFee;
        uint256 gasLimit;
        address manager;
        address service;
        address gasToken;
        address feeReceiver;
        bool isGateway;
        bytes data;
        bytes serviceSignature;
        bytes32[] proof;
    }

    function execute(address wallet, VWExecuteParam calldata vweParam)
        external
        returns (bool res);
}

contract VWManagerTest {
    function execute(address vwm, bytes calldata data) external {
        (address wallet, IVWManager.VWExecuteParam memory param) = abi.decode(
            data,
            (address, IVWManager.VWExecuteParam)
        );
        IVWManager(vwm).execute(wallet, param);
    }
}