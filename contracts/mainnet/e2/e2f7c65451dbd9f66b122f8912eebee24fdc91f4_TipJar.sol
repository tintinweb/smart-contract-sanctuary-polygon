/**
 *Submitted for verification at polygonscan.com on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract TipJar {
    event Payment(address indexed sender, uint256 amount, uint256 bal);

    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {
        emit Payment(msg.sender, msg.value, address(this).balance);
    }

    function deposit() external payable {
        emit Payment(msg.sender, msg.value, address(this).balance);
    }

    function withdraw() external {
        require(msg.sender == owner, "You are not the owner");

        uint256 amount = address(this).balance;
        emit Payment(address(this), amount, address(this).balance);
        
        owner.transfer(amount);
    }

    function transfer(address payable _to, uint256 _amount) external {
        require(msg.sender == owner, "You are not the owner");
        require(_amount <= address(this).balance, "Amount exceeds balance");

        emit Payment(address(this), _amount, address(this).balance);
        
        _to.transfer(_amount);
    }

    function erc20_safe_transfer(address _token, address _receiver, uint256 _amount) external {
        require(msg.sender == owner, "You are not the owner");

        (bool success, bytes memory data) = _token.call(abi.encodeWithSignature("transfer(address,uint256)", _receiver, _amount));

        require(success && (data.length == 0 || abi.decode(data, (bool))), "Transfer failed!");
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}