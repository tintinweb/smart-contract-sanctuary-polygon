/**
 *Submitted for verification at polygonscan.com on 2022-06-02
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

contract LuckyDraw {
    
    event WinnerDrawn(uint256 position, address candidate);


    mapping(uint256 => mapping(uint256 => address)) draws; // drawId => winningPosition => winnerAddress

    uint256 id;

    mapping(uint256 => mapping(address => bool)) drawnCandidates;

    function draw(address[] calldata candidates, uint256 winnersCount) external {
        uint256 drawId = ++id;
        uint256 uniqueToDraw = winnersCount;
        while(uniqueToDraw > 0) {
            uint256 random =  uint256(keccak256(abi.encode(block.number, uniqueToDraw, msg.sender, block.timestamp)));
            uint256 winningIndex = random % candidates.length;
            address currentCandidate = candidates[winningIndex];
            if(drawnCandidates[drawId][currentCandidate]) continue;
            drawnCandidates[drawId][currentCandidate] = true;
            uniqueToDraw--;
            draws[drawId][uniqueToDraw] = currentCandidate;
            emit WinnerDrawn(uniqueToDraw, draws[drawId][uniqueToDraw]);
        }
    }

    function getWinner(uint256 drawId, uint256 winningPosition) external view returns (address) {
        return draws[drawId][winningPosition];
    }

}