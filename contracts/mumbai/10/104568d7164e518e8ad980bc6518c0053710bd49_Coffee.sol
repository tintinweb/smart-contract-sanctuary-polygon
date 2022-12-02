/**
 *Submitted for verification at polygonscan.com on 2022-12-01
*/

// File: contracts/4_coffee.sol



pragma solidity >=0.7.0 <0.9.0;

contract Coffee {
    // 投票者
    address[] voters;
    // 获得的得票数
    mapping(address => uint256) voteGet;
    // 投票者投给的人
    mapping(address => address) voteTo;

    // 是否已投票
    modifier isVoted() {
        for (uint256 i = 0; i < voters.length; i++) {
            require(voters[i] != msg.sender);
        }
        _;
    }

    // 投票
    function vote(address to) public isVoted {
        voters.push(msg.sender);
        voteTo[msg.sender] = to;
        voteGet[to] = ++voteGet[to];
    }

    // 获取投票结果
    function voteResult(address person) public view returns (uint256) {
        return voteGet[person];
    }
}