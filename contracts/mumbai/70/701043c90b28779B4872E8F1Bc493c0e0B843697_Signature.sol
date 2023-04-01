// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract Signature {
    function mapToken(address token, address bridgeToken) external {}

    function bridge(address token, uint256 amount) external {}

    function cycle(address token, address[] memory accounts, uint256[] memory amounts) external {}

    function claimYield(address token, uint256 amount, bytes memory signature) external {}

    function mint(address account, uint256 amount) external {}

    function burn(address account, uint256 amount) external {}
}