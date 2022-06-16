// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


import "./FxBaseChildTunnel.sol";

contract GardenFountain is FxBaseChildTunnel {

    uint256 public amountAdded;

    mapping(address => uint256) private _darkInReserve;
    mapping(address => uint256) private _glowingInReserve;

    constructor(address _fxChild) FxBaseChildTunnel(_fxChild) {}


    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        address holder;
        uint256 earned;
        (holder, earned) = abi.decode(data, (address, uint256));
amountAdded += earned;

    }
}