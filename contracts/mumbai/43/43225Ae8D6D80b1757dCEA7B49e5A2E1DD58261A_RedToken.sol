/**
 *Submitted for verification at polygonscan.com on 2023-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract RedToken {
   
    string public name = "Red Token";
    string public symbol = "RT";
    uint public decimals = 18;
    uint public totalSupply;

    mapping(address => uint256) public balanceOf;

    uint public transactionFeeRate = 100; // Transaction fee rate in basis points (1 basis point = 0.01%)
    address public transactionFeeReceiver = 0x3Ae04031F0CCFc442Ae112ff0561d10521512893; // Address that receives the transaction fee

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed to, uint256 value);

    constructor(uint256 initialSupply) {
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        uint256 transactionFee = _value * transactionFeeRate / 10000; // Calculate transaction fee
        uint256 amountToTransfer = _value - transactionFee; // Calculate amount to transfer after fee deduction
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(balanceOf[_to] + amountToTransfer >= balanceOf[_to], "Invalid transfer amount");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += amountToTransfer;

        // Transfer transaction fee
        if (transactionFee > 0) {
            balanceOf[transactionFeeReceiver] += transactionFee;
            emit Transfer(msg.sender, transactionFeeReceiver, transactionFee);
        }

        emit Transfer(msg.sender, _to, amountToTransfer);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;

        emit Burn(msg.sender, _value);
        return true;
    }

    function mint(uint256 _value) public returns (bool success) {
        balanceOf[msg.sender] += _value;
        totalSupply += _value;

        emit Mint(msg.sender, _value);
        return true;
    }

    function setTransactionFee(uint256 _transactionFeeRate, address _transactionFeeReceiver) public {
        transactionFeeRate = _transactionFeeRate;
        transactionFeeReceiver = _transactionFeeReceiver;
    }
}