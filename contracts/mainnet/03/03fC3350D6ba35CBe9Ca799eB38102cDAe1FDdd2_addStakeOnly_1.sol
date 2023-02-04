/**
 *Submitted for verification at polygonscan.com on 2023-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract addStakeOnly_1 {

    mapping(bytes32 => address) public stakeHash; // off-chain hash value on chain
    bool public homeTeamWin; // update home/away winning`
    
    mapping(address => uint256) public stakeHome; // record the amount the user bet on the home team
    mapping(address => uint256) public stakeAway; // record the amount the user bet on the away team
    
    /* ========== usage: calculate the shares of winning user ========== */
    uint256 public stakesHome; // sum of all stakes on home side
    uint256 public stakesAway; // sum of all stakes on away side
    
    /* ========== usage: calculate the shares of winning user ========== */
    address payable[] public punterHome; // record all address bet on home win
    address payable[] public punterAway; // record all address bet on home win
    

    function addStake(bytes32 _hash, string memory _win) public payable {
        require(msg.value > 0, "You must send some ether to add a message.");
        stakeHash[_hash] = msg.sender;
        
        bytes32 inputValue = keccak256(abi.encodePacked(_win)); // user's bet convert to byte32

        if ( inputValue == keccak256(abi.encodePacked("home")) ) {
            // add user's wallet to home address list
            punterHome.push(payable(msg.sender));
            // record user's stake
            stakeHome[msg.sender] += msg.value;
            // increase home's pool value
            stakesHome += msg.value;
        } else {
            punterAway.push(payable(msg.sender));
            stakeAway[msg.sender] += msg.value;
            stakesAway += msg.value;
        }
    }



}