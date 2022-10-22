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

contract ForwarderFactory {
    event ForwarderCreated(
        bytes indexed userDID,
        address newForwarderAddress,
        uint256 createdAtTime,
        uint256 createAtBlock
    );

    function createForwarder(
    bytes calldata _userDID,
    bytes calldata _salt
    ) external {
        Forwarder forwarder = (new Forwarder){salt: getFinalSalt(_userDID, _salt)}();

        // Initialize forwarder
        forwarder.init(
            _userDID,
            address(0),
            address(0),
            address(0),
            address(0)
        );

        emit ForwarderCreated(
            _userDID,
            address(forwarder),
            block.timestamp,
            block.number
        );
    }

    function getFinalSalt(
        bytes calldata _userDID,
        bytes calldata _salt
    ) internal pure returns (bytes32 finalSalt) {
        finalSalt = keccak256(abi.encodePacked(_userDID, _salt));
    }
}