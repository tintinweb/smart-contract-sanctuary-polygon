/**
 *Submitted for verification at polygonscan.com on 2023-04-06
*/

pragma solidity ^0.8.0;

contract Lottery {
    address payable[] public participants;
    uint256 public participantCount;
    bool public lotteryDrawn = false;
    address payable[3] public winners;
    uint256 public totalPool;
    uint256 public ownerPercentage = 10;
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function participate() public payable {
        require(!lotteryDrawn, "The lottery has already been drawn.");
        require(msg.value == 1 ether, "You must pay 1 Ether to participate.");
        participants.push(payable(msg.sender));
        participantCount++;
        totalPool += msg.value;

        if(participantCount == 100) {
            drawLottery();
        }
    }

    function drawLottery() public {
        require(!lotteryDrawn, "The lottery has already been drawn.");
        require(participantCount == 100, "100 participants are required to draw the lottery.");

        // Pick winners
        uint256[3] memory winnerIndices;
        for (uint256 i = 0; i < 3; i++) {
            uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, participantCount, i))) % participantCount;
            winnerIndices[i] = randomIndex;
            winners[i] = participants[randomIndex];
        }

        // Distribute prize
        uint256 ownerAmount = (totalPool * ownerPercentage) / 100;
        owner.transfer(ownerAmount);
        uint256 prizePool = totalPool - ownerAmount;
        winners[0].transfer((prizePool * 45) / 100);
        winners[1].transfer((prizePool * 33) / 100);
        winners[2].transfer((prizePool * 22) / 100);

        lotteryDrawn = false;
        participantCount = 0;
        delete participants;
        totalPool = 0;
    }

    
}