/**
 *Submitted for verification at polygonscan.com on 2022-03-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {

    event Win(uint256 amount, address addr);
    event NewBet(address addr, bytes32 nums);

    struct Game {
        Bet[] bets;
        bytes32 winningNum;
    }

    struct Bet {
        bytes32 playerNums;
        address playerAddress;
    }

    mapping(address => bool) admins;
    uint256 public ticketCost;

    Game public currentGame;

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

        for (uint i = 0; i < numOfBets; i++) {
            bytes32 nums = generateNum(msg.sender, i);

            Bet memory bet = Bet(nums, msg.sender);

            currentGame.bets.push(bet);

            emit NewBet(msg.sender, nums);
        }
    }

    /** INTERNAL FUNCTIONS */
    function generateNum(address addr, uint256 index) private view returns(bytes32) {
        return keccak256(abi.encodePacked(block.difficulty, block.timestamp, addr, index));
    }

    function generateWinNums() private view returns(bytes32) {
        return keccak256(abi.encodePacked(block.difficulty, block.timestamp, address(this).balance));
    }

    function payoutWinners() private {
        for(uint256 i = 0; i < currentGame.bets.length; i++) {
            bytes32 playNum = currentGame.bets[i].playerNums;
            address playAddr = currentGame.bets[i].playerAddress;

            uint256 sendAmount = getWinAmount(playNum);

            if(sendAmount > 0) {
            bool sent = payable(playAddr).send(sendAmount);
            require(sent, "Failed to send Ether");

            emit Win(sendAmount, playAddr);
            }
        }
    }

    function getWinAmount(bytes32 playerNum) private view returns(uint256){
        require(currentGame.winningNum != 0, "Error setting winningNum");

        uint8 winTally;

        for(uint i = 0; i < 6; i++) {
            if(uint8(playerNum[i]) % 10 == uint8(currentGame.winningNum[i]) % 10) {
                winTally++;
            } else {
                break;
            }
        }

        return winTally > 0 ? ticketCost * 5 ** winTally : 0;
    }

    function endCurrentGame() private {
        bytes32 num = generateWinNums();
        currentGame.winningNum = num;

        payoutWinners();
    }

    function instantiateGame() private {
        delete currentGame.bets;
        currentGame.winningNum = 0;
    }

    /** ADMIN FUNCTIONS */
    function newGame() external onlyAdmins {
        endCurrentGame();
        instantiateGame();
    }

    function setTicketCost(uint cost) external onlyAdmins {            
        ticketCost = cost;
    }

    function deposit() external payable onlyAdmins {}

    function balance() external view onlyAdmins returns(uint256) {
        return address(this).balance;
    }

}