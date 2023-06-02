// SPDX-License-Identifier: MIT
// File: contracts/UChildERC20Proxy.sol

pragma solidity 0.6.12;

import "./UpgradableProxy.sol";
contract UChildERC20Proxy is UpgradableProxy {
    constructor(address _proxyTo) public UpgradableProxy(_proxyTo) {}
}