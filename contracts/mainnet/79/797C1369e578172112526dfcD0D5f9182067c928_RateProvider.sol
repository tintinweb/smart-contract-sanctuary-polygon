// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/IRateProvider.sol";
import "../interfaces/IFxStateChildTunnel.sol";

/**
 * @title RateProvider
 */
contract RateProvider is IRateProvider {
    IFxStateChildTunnel public fxChild;

    constructor(IFxStateChildTunnel _fxChild) {
        fxChild = _fxChild;
    }

    function getRate() external override view returns (uint256) {
        (uint256 matic, uint256 stMatic) = fxChild.getReserves();
        return stMatic * 1 ether / matic;
    }
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface IRateProvider {
    function getRate() external view returns (uint256);
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface IFxStateChildTunnel {
    function latestStateId() external view returns (uint256);

    function latestRootMessageSender() external view returns (address);

    function latestData() external view returns (bytes memory);

    function sendMessageToRoot(bytes memory message) external;

    function setFxRootTunnel(address _fxRootTunnel) external;

    function getReserves() external view returns (uint256, uint256);
}