/**
 *Submitted for verification at polygonscan.com on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SlotMachine {
    uint[] symbols = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    uint[] valueMultipliers = [11, 12, 13, 14, 20, 25, 30, 50, 70, 100]; // Multiplied by 10 for solidity
    uint rows = 3;
    uint columns = 5;

    // Event to emit when a new matrix is created
    event NewMatrix(uint[][] matrix);

    // This function creates a pseudo-random matrix
    function createMatrix() public returns(uint[][] memory) {
        uint[][] memory matrix = new uint[][](rows);
        for (uint i = 0; i < rows; i++) {
            matrix[i] = new uint[](columns);
            for (uint j = 0; j < columns; j++) {
                // Note: this is NOT truly random and NOT safe for production use
                uint randomSymbol = symbols[(uint(keccak256(abi.encodePacked(block.timestamp, i, j))) % symbols.length)];
                matrix[i][j] = randomSymbol;
            }
        }
        
        // Emit the event with the created matrix
        emit NewMatrix(matrix);
        
        return matrix;
    }

    // This function calculates a multiplier for the given matrix
    function calculateMultiplier(uint[][] memory matrix) public view returns (uint) {
        uint totalMultiplier = 0;

        for (uint i = 0; i < rows; i++) {
            uint startSymbol = matrix[i][0];
            uint lineLength = 1;

            for (uint j = 1; j < columns; j++) {
                bool columnContainsStartSymbol = false;
                for (uint k = 0; k < rows; k++) {
                    if (matrix[k][j] == startSymbol) {
                        columnContainsStartSymbol = true;
                        break;
                    }
                }
                if (columnContainsStartSymbol) {
                    lineLength++;
                } else {
                    break;
                }
            }

            uint lineMultiplier = 0;
            if (lineLength == 3) {
                lineMultiplier =  2e16 * valueMultipliers[startSymbol];
            } else if (lineLength == 4) {
                lineMultiplier = 15e16 * valueMultipliers[startSymbol];
            } else if (lineLength == 5) {
                lineMultiplier = 8e17 * valueMultipliers[startSymbol];
            }
            totalMultiplier += lineMultiplier;
        }

        return totalMultiplier;
    }

    // This is the main function that users call to play the game
    function playSlotMachine() external returns (uint, uint[][] memory) {
        uint[][] memory matrix = createMatrix();
        uint totalMultiplier = calculateMultiplier(matrix);
        return (totalMultiplier, matrix);
    }
}