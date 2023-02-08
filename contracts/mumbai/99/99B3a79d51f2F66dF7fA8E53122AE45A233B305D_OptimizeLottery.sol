/**
 *Submitted for verification at polygonscan.com on 2023-02-07
*/

// File: Solidity/lottery.sol


pragma solidity ^0.8.0;

contract Lottery{

    address public Manager;
    address payable [] public participants;

    constructor(){
        Manager = msg.sender;
    }

    function getBalance() public view returns(uint){
        require(msg.sender == Manager,"only manager can access");
        return address(this).balance;
    }

    receive() external payable {
        require(msg.value == 1 ether,"price equal to be 1 ether");
        participants.push(payable(msg.sender));
    }

    function random() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length)));
    }

    function selectWinner() external {
        require(msg.sender == Manager,"only manager can call");
        require(participants.length>= 3,"participants should be greater or equal 3");
        uint r = random();
        uint index = r % participants.length;
        address payable winner;
        winner =participants[index] ;
        winner.transfer(getBalance());
        participants = new address payable[](0);
    }
}

contract OptimizeLottery{

    address public Manager;
    address payable [] public participants;

    constructor(){
        Manager = msg.sender;
    }

    function getBalance() public view returns(uint){
        require(msg.sender == Manager,"only manager can access");
        return address(this).balance;
    }

    // receive() external payable {
    //     require(msg.value == 1 ether,"price equal to be 1 ether");
    //     participants.push(payable(msg.sender));
    // }

    function payFee() external payable {
        require(msg.value == 1 ether,"price equal to be 2 ether");
        // payable (address(this)).transfer(msg.value);

    }

    function random() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length)));
    }

    function selectWinner() external {
        require(msg.sender == Manager,"only manager can call");
        require(participants.length>= 3,"participants should be greater or equal 3");
        uint index = random() % participants.length;
        payable (participants[index]).transfer(getBalance());
        participants = new address payable[](0);
    }
}