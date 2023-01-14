// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.17;

contract MetaPaymentMock {
    function setFreezeStatus(address erc20, bool freeze) external {}

    function increaseBalance(
        address erc20,
        uint256 idUser,
        uint256 amount
    ) external {}

    function decreaseBalance(
        address erc20,
        uint256 idUser,
        address principal,
        uint256 amount
    ) external {}
}