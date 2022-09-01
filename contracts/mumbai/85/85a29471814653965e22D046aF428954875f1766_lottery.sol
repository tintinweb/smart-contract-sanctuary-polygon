/**
 *Submitted for verification at polygonscan.com on 2022-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
contract lottery
{
    address public owner;
    address payable[] public players;
    uint public id;
    mapping (uint => address payable) private history;

    constructor (){
        owner = msg.sender;
        id = 0;
    }
//------------We Can Get the PoolBalance Value With This Function ---------------
    function PoolBalance() public view returns (uint)
    {
        return address(this).balance;
    }

//------------ Player Can Get Into lottery with call This Function ---------------    
    function play() public payable
    {
        require(msg.value == 3 ether,"Not Enough ETH");
        players.push(payable(msg.sender));
    }   //a public function for enter the lottery

//------------ Random Number Generate Method -------------------------------------
    function randomness() public view returns (uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players)))% players.length;
    }   //this functuin helps the contract to pick the random winner

//------------ Picking Winner Function -------------------------------------
    function winner () public restrict {
        uint index = randomness() ;
        players[index].transfer(address(this).balance);
        history[id] = players [index];
        id++;

        players = new address payable[](0);
    }

//------------ Custom Modifier for restrict players -------------------------------------
    modifier restrict(){
        require(msg.sender == owner,"You Are Not the Owner");
        _;
    }   //we need this modifier for restrict players to picking winner
}