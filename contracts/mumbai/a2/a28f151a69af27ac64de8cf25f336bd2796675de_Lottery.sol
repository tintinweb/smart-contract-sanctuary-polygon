/**
 *Submitted for verification at polygonscan.com on 2022-11-16
*/

/**
 *Submitted for verification at polygonscan.com on 2022-11-10
*/

pragma solidity ^0.4.24;

// 彩票项目

contract Lottery {
    // 1. 管理员： 负责开奖和退钱
    // 2. 彩民池，address[] player
    // 3. 当前期数， round ,每期结束加一

    address public manager;
    address[] public players;
    uint256 public round;
    address public winner;

    // 管理员
    constructor() public {
        manager = msg.sender;
    }

    // 投注函数：1. 每个人可以投多次，但是每次只能投注 1 ether
    function play() payable public {
        require(msg.value == 0.001 ether);
        //  把参与者加入到彩票池中
        players.push(msg.sender);
    }

    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }

    // 开奖函数：从彩民池（数组）中找到一个随机彩民（找随机数）
    // 找到一个特别大的数（随机），对我们的彩民数组长度求余数
    // 用哈希数值来实现大的随机数
    // 哈希内容的随机：当前时间，区块的挖矿难度，彩民数量，作为输入

    // 找随机数
    function kaijiang() onlyManager public {
        bytes memory v1 = abi.encodePacked(block.timestamp, block.difficulty, players.length);
        bytes32 v2 = keccak256(v1);
        uint256 v3 = uint256(v2);

        // 求余
        uint256 index = v3 % players.length;
        winner = players[index];

        // require(msg.sender == manager); // 限定管理员

        uint256 money = address(this).balance * 90 / 100;
        uint256 money1 = address(this).balance - money;

        winner.transfer(money);
        manager.transfer(money1);

        round++;  //期数加一
        delete players;  // 一轮之后清理彩民池

    }

    // 退奖逻辑
    // 1. 遍历players数组，逐一退款1 ether
    // 2. 期数加一
    // 3. 彩民池清零
    ///  调用者的花费手续费（管理者）
    uint256 public i;
    function tuijiang() onlyManager public {
        for (i=0;i<players.length;i++){
            players[i].transfer(0.001 ether);
        }
        round++;
        delete players;
    }



    // 获取彩民数
    function getPlayersCount() public view returns(uint256) {
        return players.length;
    }


    // 返回余额
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    // 返回彩民地址
    function getplayers() public view returns(address[]) {
        return players;
    }



}