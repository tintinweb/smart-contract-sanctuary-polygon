// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRateProvider {
    function getRate() external view returns (uint256);
}

interface IFxStateChildTunnel {
    function latestStateId() external view returns (uint256);

    function latestRootMessageSender() external view returns (address);

    function latestData() external view returns (bytes memory);

    function sendMessageToRoot(bytes memory message) external;

    function setFxRootTunnel(address _fxRootTunnel) external;

    function getReserves() external view returns (uint256, uint256);
}

/**
 * @title RateProvider
 */
contract FxRateProvider is IRateProvider {
    IFxStateChildTunnel public fxChild;

    constructor(IFxStateChildTunnel _fxChild) {
        fxChild = _fxChild;
    }

    function getRate() external override view returns (uint256) {
        (uint256 stMatic, uint256 matic) = fxChild.getReserves();
        return matic * 1 ether / stMatic;
    }
}