/**
 *Submitted for verification at polygonscan.com on 2022-03-03
*/

/**
 *Submitted for verification at polygonscan.com on 2022-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
contract Banka {
    event newBet(address player, uint bet, uint time);
    address owner;
    uint totalGames;
    struct Game {
        uint blockStarted;
        uint timeEnd;
        uint totalInPot;
        uint highestBet;
        address lastPlayer;
    }
    Game[] games;
    mapping(address => int) winners;
    address ERC20 = 0x70B6e8b4754734f461b284f8480D89a016186923;
    constructor() {
        owner = msg.sender;
        games.push(Game(block.number, block.timestamp, 0, 0, address(0)));
    }
    function totalInPot() public view returns(uint) {
        return games[totalGames].timeEnd > block.timestamp ? games[totalGames].totalInPot : 0;
    }
    function blockStarted() public view returns(uint) {  
        return games[totalGames].timeEnd > block.timestamp ? games[totalGames].blockStarted : 0;
    }
    function timeLeft() public view returns(uint) {
        return games[totalGames].timeEnd > block.timestamp ? games[totalGames].timeEnd : 0;
    }
    function isGame() public view returns(bool) {
        return games[totalGames].timeEnd > block.timestamp; 
    }
    function profit(address addr) public view returns(uint) {
        if (winners[addr] < 0) {
            return 0;
        }
        else { 
            if (games[totalGames].timeEnd < block.timestamp) {
                return games[totalGames].lastPlayer == addr ? ((games[totalGames].totalInPot + uint(winners[addr]))/100)*95 : (uint(winners[addr])/100)*95;
            }
            else {
                return (uint(winners[addr])/100)*95;
            }
        }
    }
    function makeBet(uint amount) public {
        require(amount > 500000, "your bet need to be more than 0.5$");
        if (games[totalGames].timeEnd < block.timestamp) {
            winners[games[totalGames].lastPlayer] = winners[games[totalGames].lastPlayer] + int(games[totalGames].totalInPot);
            IERC20(ERC20).transferFrom(msg.sender, address(this), amount);
            totalGames++;
            games.push(Game(block.number, block.timestamp + 300, amount, amount, msg.sender));
            emit newBet(msg.sender, amount, block.timestamp);
        }
        else {
            require(amount>=games[totalGames].highestBet+500000, "your bet need be more than last bet plus 0.5$");
            IERC20(ERC20).transferFrom(msg.sender, address(this), amount);
            games[totalGames] = Game(games[totalGames].blockStarted, block.timestamp + 300, games[totalGames].totalInPot + amount, amount, msg.sender);
            emit newBet(msg.sender, amount, block.timestamp);
        }
    }
    function withdraw() public {
        require(games[totalGames].timeEnd < block.timestamp, "whait till game end");
        if (msg.sender == games[totalGames].lastPlayer) {
            winners[games[totalGames].lastPlayer] = int(uint(winners[games[totalGames].lastPlayer]) + games[totalGames].totalInPot);
            IERC20(ERC20).transfer(msg.sender, (uint(winners[msg.sender])/100)*95);
            IERC20(ERC20).transfer(owner, (uint(winners[msg.sender])/100)*5);
            winners[msg.sender] = 0 - int(games[totalGames].totalInPot);
        }
        else {
            require(winners[msg.sender] > 0, "you are not winner");
            IERC20(ERC20).transfer(msg.sender, (uint(winners[msg.sender])/100)*95);
            IERC20(ERC20).transfer(owner, (uint(winners[msg.sender])/100)*5);
            winners[msg.sender] = 0;
        }
    }
}