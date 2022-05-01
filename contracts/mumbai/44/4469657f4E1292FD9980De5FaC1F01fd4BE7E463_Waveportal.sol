/**
 *Submitted for verification at polygonscan.com on 2022-04-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;


contract Waveportal {
    uint256 totalWaves;
    uint private seed;

    /*
     * A little magic, Google what events are in Solidity!
     */
    event NewWave(string name, uint256 timestamp, string message);

    /*
     * I created a struct here named Wave.
     * A struct is basically a custom datatype where we can customize what we want to hold inside it.
     */
    struct Wave {
        address waver; // The address of the user who waved.
        string name; // The name of our friend
        string message; // The message the user sent.
        uint256 timestamp; // The timestamp when the user waved.
    }

    /*
     * I declare a variable waves that lets me store an array of structs.
     * This is what lets me hold all the waves anyone ever sends to me!
     */
    Wave[] waves;
    // to trace the user last visit
    mapping(address => uint256) public lastWavedAt;

    constructor() payable {
        seed = (block.timestamp + block.difficulty) % 100;
    }

    /*
     * You'll notice I changed the wave function a little here as well and
     * now it requires a string called _message. This is the message our user
     * sends us from the frontend!
     */
    function wave(string memory _message, string memory _name) public {
        if(lastWavedAt[msg.sender] > 0){
            require(
            lastWavedAt[msg.sender] + 45 seconds < block.timestamp,
            "Wait 45 seconds"
            );

        }
        

        /*
         * Update the current timestamp we have for the user
         */
        lastWavedAt[msg.sender] = block.timestamp;
        
        totalWaves += 1;

        waves.push(Wave(msg.sender, _name, _message, block.timestamp));


        /*
         * Generate a new seed for the next user that sends a wave
         */
        seed = (block.difficulty + block.timestamp + seed) % 100;



        /*
         * Give a 50% chance that the user wins the prize.
         */
        if (seed <= 50) {

            emit NewWave(_name, block.timestamp, _message);

            uint256 prizeAmount = 1 gwei;
            require(
                prizeAmount <= address(this).balance,
                "Trying to withdraw more money than the contract has."
            );
            (bool success, ) = (msg.sender).call{value: prizeAmount}("");
            require(success, "Failed to withdraw money from contract.");
        }
    }

    /*
     * I added a function getAllWaves which will return the struct array, waves, to us.
     * This will make it easy to retrieve the waves from our website!
     */
    function getAllWaves() public view returns (Wave[] memory) {
        return waves;
    }

    function getTotalWaves() public view returns (uint256) {
        // Optional: Add this line if you want to see the contract print the value!
        // We'll also print it over in run.js as well.
        return totalWaves;
    }
}