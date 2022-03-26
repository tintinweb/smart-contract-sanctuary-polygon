/**
 *Submitted for verification at polygonscan.com on 2022-03-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {

    event Win(uint256 amount, address addr);
    event NewBet(address addr, uint256 nums);

    uint256 gameID;

    struct Game {
        address[] addresses;
        uint256 winningNum;
    }

    mapping(uint256 => mapping (address => bool)) isIncluded;
    mapping(uint256 => mapping(address => uint256[])) bets;
    mapping(address => bool) admins;
    uint256 public ticketCost;

    Game currentGame;

    constructor () {
        admins[msg.sender] = true;
    }

    receive() external payable {}

    modifier onlyAdmins() {
        require(admins[msg.sender] == true);
        _;
    }

    /** PLAYER FUNCTIONS */
    function placeBet(uint256 numOfBets) external payable {
        require(numOfBets * ticketCost == msg.value, "Incorrect amount received");

        if (isIncluded[gameID][msg.sender] == false) {
            currentGame.addresses.push(msg.sender);
            isIncluded[gameID][msg.sender] = true;
        }

        for (uint i = 0; i < numOfBets; i++) {
            uint256 nums = generateNum(msg.sender, i);

            bets[gameID][msg.sender].push(nums);

            emit NewBet(msg.sender, nums);
        }
    }

    function getCurrentBets() external view returns(uint256[] memory){
        return bets[gameID][msg.sender];
    }

    /** INTERNAL FUNCTIONS */
    function generateNum(address addr, uint256 index) private view returns(uint256) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, addr, index))) % 900000 + 100000;
    }

    function generateWinNums() private view returns(uint256) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, address(this).balance)))  % 900000 + 100000;
    }

    function payoutWinners() private {
        for(uint256 i = 0; i < currentGame.addresses.length; i++) {
            address playAddr = currentGame.addresses[i];
            uint256[] memory playNums = bets[gameID][playAddr];

            sendWinnings(playNums, playAddr);
            }
    }

    function sendWinnings(uint256[] memory playerBets, address addr) private {
        uint256 winAmount;
        uint256 individualWin;

        for (uint i = 0; i < playerBets.length; i++) {
            individualWin = 0;

            for (uint j = 6; j > 0; j--) {
                if (playerBets[i] / 10 ** (j - 1) == currentGame.winningNum / 10 ** (j - 1)) {
                    individualWin = ticketCost * 5 ** (7 - j);
                } else {
                    break;
                }
            }

            winAmount += individualWin;
        }

        if(winAmount > 0) {
            bool sent = payable(addr).send(winAmount);
            require(sent, "Failed to send");
            emit Win(winAmount, addr);
        }
    }

    /** ADMIN FUNCTIONS */
    function newGame() external onlyAdmins {
        uint256 num = generateWinNums();
        currentGame.winningNum = num;

        payoutWinners();

        delete currentGame.addresses;

        gameID++;
    }

    function setTicketCost(uint cost) external onlyAdmins {            
        ticketCost = cost;
    }

    function balance() external view onlyAdmins returns(uint256) {
        return address(this).balance;
    }

    function addAdmin(address addr) external onlyAdmins {
        admins[addr] = true;
    }

    function deposit() external payable onlyAdmins {}

}