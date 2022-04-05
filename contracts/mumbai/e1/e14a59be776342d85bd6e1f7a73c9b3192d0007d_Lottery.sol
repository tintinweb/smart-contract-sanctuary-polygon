/**
 *Submitted for verification at polygonscan.com on 2022-04-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Lottery {
    address public owner;
    address payable[] public players;
    uint public lotteryId;
    uint private NumberOfplayersJoined ; 
    mapping (uint => address payable) public lotteryHistory;

    constructor() {
        owner = msg.sender;
        lotteryId = 1;
    }

    function getWinnerByLottery(uint lottery) public view returns (address payable) {
        return lotteryHistory[lottery];
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    function WithDrawTheContractBalance() external onlyowner{
        payable(msg.sender).transfer(address(this).balance) ; 
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function ParticipateInLottery() public payable {
        require(msg.value >= 1 ether);
        // address of player entering lottery
       players.push(payable(msg.sender));
       NumberOfplayersJoined++ ; 
       if(NumberOfplayersJoined == 10){
           pickWinner() ; 
       }
    }

    function getRandomNumber() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    function pickWinner() internal {
        uint index = getRandomNumber() % players.length;
        players[index].transfer(5 ether);

        lotteryHistory[lotteryId] = players[index];
        lotteryId++;
       players = new address payable[](0);
       NumberOfplayersJoined = 0 ; 
    }

    modifier onlyowner() {
      require(msg.sender == owner);
      _;
    }
}