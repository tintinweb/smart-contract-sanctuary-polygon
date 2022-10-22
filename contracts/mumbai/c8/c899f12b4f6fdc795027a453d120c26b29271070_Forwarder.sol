/**
 *Submitted for verification at polygonscan.com on 2022-10-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IForwarder {
  function approveAndDeposit(
    address, // ERC20
    uint8, // destinationDomainID
    bytes32, // resourceID
    bytes calldata, // depositData
    bytes calldata // feeData
  ) external;

  function deposit(
    uint8, // destinationDomainID
    bytes32, // resourceID
    bytes calldata, // depositData
    bytes calldata // feeData
  ) external;
}

contract Forwarder is IForwarder{
    function approveAndDeposit(
        address, // ERC20
        uint8, // destinationDomainID
        bytes32, // resourceID
        bytes calldata, // depositData
        bytes calldata // feeData
    ) external override {

    }


    function deposit(
        uint8, // destinationDomainID
        bytes32, // resourceID
        bytes calldata, // depositData
        bytes calldata // feeData
    ) external override{

    }

    function init(
        bytes calldata _userDID,
        address _bridgeAddress,
        address _handlerAddress,
        address _relayerAddress,
        address _wethAddress
    ) external {}
}