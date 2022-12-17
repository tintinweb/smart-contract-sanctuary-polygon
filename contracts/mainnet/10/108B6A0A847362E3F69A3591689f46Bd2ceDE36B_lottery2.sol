/**
 *Submitted for verification at polygonscan.com on 2022-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Lottery Contract


contract lottery2 {

    //Golbal veriables
    address public manger ;
    string[]  public codes;
    string public lottery;


    constructor(){
                  manger=msg.sender;
                  codes = new string[](200);
                  remaining = 0;
    }

    function addCode(string memory code) public {
            require(msg.sender==manger);
            codes[remaining] = code;
            remaining = remaining + 1;
    }

    //receive payable function for deposits
    receive() payable external{
           require(msg.value >= 1 ether,'Not Minimum Value');
           require(msg.sender!= manger , 'Manger cant buy Tick');
           //Lotterybuyers.push(payable(msg.sender));
    }
    // showing balance
    function getblance() view public returns(uint){
        require(msg.sender==manger,'Not manger');
        return address(this).balance;
    }
    // genreating Random Winner
    function random() public view returns(uint){
      return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,remaining)));
    }

    function drawIndex() internal returns (uint256 index) {
        //RNG
        uint256 i = uint(blockhash(block.number - 1)) % remaining;
        index = i;
    }

    uint256 public remaining;

    //generate lottery
    function draw() public returns(string memory) {
        require(msg.sender==manger);
        lottery = codes[drawIndex()];
        return lottery;
    }
    //search lottery
    function getLottery() public view returns (string memory){
      return lottery;
    }

}