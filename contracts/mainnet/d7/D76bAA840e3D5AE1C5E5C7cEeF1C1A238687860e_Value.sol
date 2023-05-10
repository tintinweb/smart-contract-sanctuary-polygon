/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Value {

    uint256 public value;
    uint256 public value2;

    address public _owner;

    event updateValue(uint256 value);
    event updateValue2(uint256 value);
    event donateMessage(string message);

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function setValue(uint256 newValue) public {
        value = newValue;

        emit updateValue(newValue);
    }

    function setValue2(uint256 newValue) public {
        value2 = newValue;

        emit updateValue2(newValue);
    }

    function donate(string memory message) payable public {
        emit donateMessage(message);
    }

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }

    function customError() public pure {
        require(false, "Some custom error happened on contract");
    }

    function arithmeticError(uint256 a) public pure returns (uint256) {
        uint256 b = a - 100;
        return b;
    }

}