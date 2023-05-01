/**
 *Submitted for verification at polygonscan.com on 2023-05-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract BattleCity {
    address public owner;
    mapping(address => uint) public balances;

    mapping(address => bool) public whitelistedWinners;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier isWhitelisted(address _address) {
        require(whitelistedWinners[_address], "You need to be whitelisted");
        _;
    }


    function deposit() external payable {
        require(msg.value == 0.05 ether, "Need to send 0.05 MATIC");

        balances[msg.sender] = balances[msg.sender] + msg.value;
    }

    function addUser(address _addressWinner, address[] calldata _addressesLoser) external onlyOwner {
        whitelistedWinners[_addressWinner] = true;
        balances[_addressWinner] = balances[_addressWinner] + 0.05 ether;

        for (uint i = 0; i < _addressesLoser.length; i++) {
            balances[_addressesLoser[i]] = balances[_addressesLoser[i]] - 0.05 ether;
        }
    }

    function claim() external isWhitelisted(msg.sender) {     
        require(balances[msg.sender] >= 0.1 ether, "Insufficient Funds!");

        (bool sent,) = msg.sender.call{value: balances[msg.sender]}("sent");

        balances[msg.sender] = 0;
        whitelistedWinners[msg.sender] = true;
        require(sent, "Failed Send!");
    }
}