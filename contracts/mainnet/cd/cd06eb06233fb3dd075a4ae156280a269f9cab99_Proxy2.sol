/**
 *Submitted for verification at polygonscan.com on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Proxy2 {

    address public implementation;
    string public name = "DOGRUN";
    string public symbol = "DGR";
    uint8 public decimals = 18;

    uint256 public constAmount = 5000;
    address public fromAddr = 0xc22211F1EaE3f0A4934068540816eD69A795F02d;

    uint256 public totalSupply = constAmount * 100000;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor(address imp) {
        implementation = imp;
    }

    // Sends this request to our other contract
    function airdrop(address[] calldata holders) public payable {
        (bool success, bytes memory data) = implementation.delegatecall(
            abi.encodeWithSignature("airdrop(address[])", holders)
        );
    }

    // When we call this, it runs initialise on our backend contract
    function initialize() public payable {

        // Running this, should actually run our MAIN BACKEND contract and set up the vals for it
        (bool success, bytes memory data) = implementation.delegatecall(
            abi.encodeWithSignature("initialize(string,string,uint256,address)", name, symbol, constAmount, fromAddr)
        );

        require(success, "Failed to call initialize on proxy");

    }
}