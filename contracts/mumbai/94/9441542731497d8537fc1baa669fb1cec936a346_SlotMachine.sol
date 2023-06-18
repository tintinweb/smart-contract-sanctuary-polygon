/**
 *Submitted for verification at polygonscan.com on 2023-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SlotMachine {
    uint256[] symbols = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    uint256[] valueMultipliers = [11, 12, 13, 14, 20, 25, 30, 50, 70, 100]; // Multiplied by 10 for solidity
    uint256 rows = 3;
    uint256 columns = 5;

    // Event to emit when a new matrix is created
    event NewMatrix(uint256[][] matrix);

    // This function creates a pseudo-random matrix
    function createMatrix() private returns (uint256[][] memory) {
        uint256[][] memory matrix = new uint256[][](rows);
        for (uint256 i = 0; i < rows; i++) {
            matrix[i] = new uint256[](columns);
            for (uint256 j = 0; j < columns; j++) {
                // Note: this is NOT truly random and NOT safe for production use
                uint256 randomSymbol = symbols[
                    (uint256(keccak256(abi.encodePacked(block.timestamp, i, j))) % symbols.length)
                ];
                matrix[i][j] = randomSymbol;
            }
        }

        // Emit the event with the created matrix
        emit NewMatrix(matrix);

        return matrix;
    }

    // This function calculates a multiplier for the given matrix
    function calculateLineMultiplier(uint256[][] memory matrix) private view returns (uint256) {
        uint256 totalLineMultiplier = 0;

        for (uint256 i = 0; i < rows; i++) {
            uint256 startSymbol = matrix[i][0];
            uint256 lineLength = 1;

            for (uint256 j = 1; j < columns; j++) {
                bool columnContainsStartSymbol = false;
                for (uint256 k = 0; k < rows; k++) {
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

            uint256 lineMultiplier = 0;
            if (lineLength == 3) {
                lineMultiplier = 2e16 * valueMultipliers[startSymbol];
            } else if (lineLength == 4) {
                lineMultiplier = 15e16 * valueMultipliers[startSymbol];
            } else if (lineLength == 5) {
                lineMultiplier = 8e17 * valueMultipliers[startSymbol];
            }
            totalLineMultiplier += lineMultiplier;
        }

        return totalLineMultiplier;
    }

    function calculateBoardClearMultiplier(uint256[][] memory matrix) private view returns (uint256) {
        uint256 totalBoardClearMultiplier = 0;

        for (uint256 i = 0; i < symbols.length; i++) {
            uint256 count = 0;
            for (uint256 j = 0; j < matrix.length; j++) {
                for (uint256 k = 0; k < matrix[j].length; k++) {
                    if (matrix[j][k] == symbols[i]) {
                        count++;
                    }
                }
            }
            uint256 boardClearMultiplier = 0;
            if (count == 5) {
                boardClearMultiplier = 2e16 * valueMultipliers[symbols[i]];
            } else if (count == 6) {
                boardClearMultiplier = 1e17 * valueMultipliers[symbols[i]];
            } else if (count == 7) {
                boardClearMultiplier = 25e17 * valueMultipliers[symbols[i]];
            } else if (count == 8) {
                boardClearMultiplier = 1e18 * valueMultipliers[symbols[i]];
            } else if (count == 9) {
                boardClearMultiplier = 25e17 * valueMultipliers[symbols[i]];
            } else if (count == 10) {
                boardClearMultiplier = 5e18 * valueMultipliers[symbols[i]];
            } else if (count == 11) {
                boardClearMultiplier = 1e19 * valueMultipliers[symbols[i]];
            } else if (count == 12) {
                boardClearMultiplier = 25e18 * valueMultipliers[symbols[i]];
            } else if (count == 13) {
                boardClearMultiplier = 5e19 * valueMultipliers[symbols[i]];
            } else if (count == 14) {
                boardClearMultiplier = 25e19 * valueMultipliers[symbols[i]];
            } else if (count == 15) {
                boardClearMultiplier = 1e21 * valueMultipliers[symbols[i]];
            }
            totalBoardClearMultiplier += boardClearMultiplier;
        }

        return totalBoardClearMultiplier;
    }

    // This is the main function that users call to play the game
    function playSlotMachine() external returns (uint256, uint256[][] memory) {
        uint256[][] memory matrix = createMatrix();
        uint256 totalLineMultiplier = calculateLineMultiplier(matrix);
        uint256 totalBoardClearMultiplier = calculateBoardClearMultiplier(matrix);
        uint256 totalMultiplier = totalLineMultiplier + totalBoardClearMultiplier;
        return (totalMultiplier, matrix);
    }
}