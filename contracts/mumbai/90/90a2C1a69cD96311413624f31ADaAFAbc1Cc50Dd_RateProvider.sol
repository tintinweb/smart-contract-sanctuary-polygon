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
        (uint256 stMatic, uint256 matic) = fxChild.getReserves();
        return matic * 1 ether / stMatic;
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
    
    /// @dev Function that returns the amount of stMATIC and MATIC in the PoLido protocol
    /// @return stMATIC return value is the number of stMATIC.
    /// @return MATIC return value is the number of MATIC.
    function getReserves() external view returns (uint256 stMATIC, uint256 MATIC);
}