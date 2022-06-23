//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Aria{

    address public owner;
    string[] public tickArray;

    constructor() {
        owner = msg.sender;
    }

    struct tick{
        bool exists;
        uint256 like;
        uint256 dislike;
        mapping(address => bool) Voters;
    }

    event updatetick(
        uint256 like,
        uint256 dislike,
        address voter,
        string ticker
    );

    mapping(string => tick) private Ticks;

    function addTick(string memory _tick) public{
        require(msg.sender == owner, "You can create topics only if you are an owner");
        tick storage newTick = Ticks[_tick];
        newTick.exists = true;
        tickArray.push(_tick);
    }

    function vote(string memory _tick, bool _vote) public {
        require(Ticks[_tick].exists, "You can't vote on this topic");
        require(!Ticks[_tick].Voters[msg.sender],"You can't vote more than once");

        tick storage t = Ticks[_tick];
        t.Voters[msg.sender] = true;

        if(_vote){
            t.like ++;
        }else{
            t.dislike ++;
        }

        emit updatetick(t.like, t.dislike, msg.sender, _tick);
    }

    function countVotes(string memory _tick) public view returns (
        uint256 like,
        uint256 dislike
    ){
        require(Ticks[_tick].exists, "There is no premise defined");
        tick storage t = Ticks[_tick];
        return(t.like,t.dislike);
    }

}