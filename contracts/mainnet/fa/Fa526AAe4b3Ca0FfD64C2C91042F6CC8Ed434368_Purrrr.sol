// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract Purrrr {

    address payable public owner;
    bool isClosed;

    mapping(address => bool) public submitted;
    mapping(address => uint) public contributions;

    event Withdrawal(uint amount, uint when);
    event Purr(address indexed sender);
    event IWish(address indexed sender);
    event Contribution(address indexed sender, uint amount, string guess);

    constructor() payable {
        owner = payable(msg.sender);
    }

    function shesGoingTo(string memory protocol) public payable {
        require(!isClosed, "SORRY_TOO_LATE");
        require(!submitted[msg.sender], "YOU_DONE_DID_THIS_ALREADY_WITH_THIS_ADDRESS");
        require(msg.value > 0, "CMON_YOU_NEED_SHMOOOONEY");

        if(keccak256(bytes(protocol)) == keccak256(bytes("CELESTIA"))) emit Purr(msg.sender); // YEAH, WE KNOW 
        if(keccak256(bytes(protocol)) == keccak256(bytes("POLYGON"))) emit IWish(msg.sender);  
        
        emit Contribution(msg.sender, msg.value, protocol);

        contributions[msg.sender] = msg.value;
        submitted[msg.sender] = true;
    }

    function withdraw() public { 
        // I DONT HAVE TIME TO WRITE OUT CHAIN REWARDS, I'LL SEND SUCCESSFUL REWARDEES AN AIRDROP OF THEIR WINNINGS
        // 10% OF ALL FUNDS WILL BE SENT TO WBW3
        require(msg.sender == owner, "You aren't the owner");
        emit Withdrawal(address(this).balance, block.timestamp);

        owner.transfer(address(this).balance);
    }

    function close() public {
        require(msg.sender == owner, "You aren't the owner");
        isClosed = true;
    }
}