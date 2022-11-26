/**
 *Submitted for verification at polygonscan.com on 2022-11-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Bank {
    event Deposit(address customer, uint256 amount);
    address public bankOwner;
    string public bankName;

    mapping(address => uint256) public customerToBalance;

    constructor(string memory _name) {
        bankOwner = msg.sender;
        bankName = _name;
    }

    // Deposit Money
    function depositMoney() public payable {
        require(msg.value != 0, "You need to deposit some amount of money!");
        customerToBalance[msg.sender] = msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // Set Bank Name
    function setBankName(string memory _name) external {
        require(msg.sender == bankOwner, "You must be the owner to the name of the bank");
        bankName = _name;
    }

    // Withdraw Money
    function withdrawMoney(address payable _to,uint256 _total) public {
        require(_total <= customerToBalance[msg.sender],"You have insufficient funds to withdraw Money");
        customerToBalance[msg.sender] -= _total;
         (bool sent, ) = _to.call{value: _total}("");
        require(sent, "Failed to send Ether");
    }

    // get My Balance
    function getMyBalance() external view returns (uint256) {
        return customerToBalance[msg.sender];
    }

    // Get Bank Balance
    function getBankBalance() public view returns(uint256) {
        require(msg.sender == bankOwner, "You must be the owner of the bank to see all balances");
        return address(this).balance;
    }

}