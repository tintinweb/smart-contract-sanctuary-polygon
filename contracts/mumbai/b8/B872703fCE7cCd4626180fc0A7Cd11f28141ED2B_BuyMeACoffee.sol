/**
 *Submitted for verification at polygonscan.com on 2023-05-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract BuyMeACoffee {
    address payable owner;

    struct Memo {
        string name;
        string message;
        address from;
        uint time;
    }

    event AddMemo(string, string, address, uint);

    Memo[] public memos;

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You are not allowed to withdraw funds form this account"
        );
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }

    function buyCoffee(
        string memory name,
        string memory message
    ) public payable {
        Memo memory memo = Memo(name, message, msg.sender, block.timestamp);
        memos.push(memo);
        emit AddMemo(name, message, msg.sender, msg.value);
    }

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}