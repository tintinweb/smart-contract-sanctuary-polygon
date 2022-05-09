/**
 *Submitted for verification at polygonscan.com on 2022-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Lottery {
    address public owner;
    address payable[] public players;
    address public winner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //Enter lottery function
    function enter() public payable {
        require(msg.value == 0.1 ether);
        players.push(payable(msg.sender));
    }

    //Get a random number
    function random() public view returns (uint8) {
        return
            uint8(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            players
                        )
                    )
                ) % 251
            );
    }

    //Picking winnner using random number
    function pickWinner() public onlyOwner {
        uint256 index = random() % players.length;

        //transfer reward to the winner
        players[index].transfer(address(this).balance);
        winner = players[index];

        //reset the state of the contract
        players = new address payable[](0);
    }
}