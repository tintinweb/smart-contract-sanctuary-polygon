/**
 *Submitted for verification at polygonscan.com on 2023-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract RandomNumberGenerator {
    uint private constant MAX_NUMBER = 10000;
    uint private seed;
    address private deployer;
    
    struct RandomNumberData {
        uint randomNumber;
        uint timestamp;
    }
    
    RandomNumberData[] public randomNumberHistory;

    event NewRandomNumber(uint randomNumber, uint timestamp);

    constructor() {
        // Set the seed to a combination of the block timestamp and the address of the last miner
        seed = uint(keccak256(abi.encodePacked(block.timestamp, block.coinbase)));
        
        // Set the deployer as the contract creator
        deployer = msg.sender;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Caller is not the deployer");
        _;
    }

    function generateRandomNumber() public onlyDeployer {
        // Generate the random number between 1 and MAX_NUMBER
        uint randomNumber = (uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed))) % MAX_NUMBER) + 1;
        
        // Update the seed for the next random number generation
        seed = randomNumber;
        
        // Create a new RandomNumberData struct
        RandomNumberData memory data = RandomNumberData(randomNumber, block.timestamp);
        
        // Add the new random number data to the history
        randomNumberHistory.push(data);
        
        // Emit the event with the new random number and timestamp
        emit NewRandomNumber(randomNumber, block.timestamp);
    }
    
    function getHistory() public view returns (RandomNumberData[] memory) {
        return randomNumberHistory;
    }
    
    function timestampToReadable(uint timestamp) public pure returns (string memory) {
        return timestampToString(timestamp, "MMMM d, yyyy");
    }
    
    function timestampToString(uint timestamp, string memory format) internal pure returns (string memory) {
        bytes memory buffer = new bytes(20);
        uint i = 0;
        
        // Convert the DateTime to a readable string based on the format
        for (uint j = 0; j < bytes(format).length && i < buffer.length; j++) {
            if (bytes(format)[j] == "y") {
                // Year
                uint year = (timestamp / 31536000) + 1970; // Approximate seconds in a year
                buffer[i++] = bytes1(uint8(year / 1000 % 10 + 48));
                buffer[i++] = bytes1(uint8(year / 100 % 10 + 48));
                buffer[i++] = bytes1(uint8(year / 10 % 10 + 48));
                buffer[i++] = bytes1(uint8(year % 10 + 48));
            } else if (bytes(format)[j] == "M") {
                // Month
                uint month = (timestamp / 2628000) % 12; // Approximate seconds in a month
                buffer[i++] = bytes1(uint8(month / 10 + 48));
                buffer[i++] = bytes1(uint8(month % 10 + 48));
            } else if (bytes(format)[j] == "d") {
                // Day
                uint day = (timestamp / 86400) % 30; // Approximate seconds in a day
                buffer[i++] = bytes1(uint8(day / 10 + 48));
                buffer[i++] = bytes1(uint8(day % 10 + 48));
            } else {
                buffer[i++] = bytes(format)[j];
            }
        }
        
        return string(buffer);
    }
}