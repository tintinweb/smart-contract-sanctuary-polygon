// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SendMatic {
    address payable public owner;

    event sendMatic(address indexed from, uint indexed amount, bytes32 indexed wlTxId);

    constructor() payable {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    fallback() external payable {}

    function getBalance() public view returns (uint256) {
        require(owner == msg.sender);
        return address(this).balance;
    }

    function send(uint256 _amount,bytes32 _wlTxId) external payable {
        require(msg.value == _amount, "Error: Amount sent differs from the specified amount");
        emit sendMatic(msg.sender, msg.value, _wlTxId);
    }

    function withdraw(address payable _to, uint _amount) public {
        require(owner == msg.sender, "Failed to withdraw ether except owner");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send ether");
    }
}