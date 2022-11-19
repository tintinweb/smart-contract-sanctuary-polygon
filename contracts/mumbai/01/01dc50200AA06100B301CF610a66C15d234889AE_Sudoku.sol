//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[81] memory input
    ) external view returns (bool);
}

contract Sudoku {
    address public verifyAddr;

    uint8[9][9][3] sudokuBoardList = [
        [
            [1, 2, 7, 5, 8, 4, 6, 9, 3],
            [8, 5, 6, 3, 7, 9, 1, 2, 4],
            [3, 4, 9, 6, 2, 1, 8, 7, 5],
            [4, 7, 1, 9, 5, 8, 2, 3, 6],
            [2, 6, 8, 7, 1, 3, 5, 4, 9],
            [9, 3, 5, 4, 6, 2, 7, 1, 8],
            [5, 8, 3, 2, 9, 7, 4, 6, 1],
            [7, 1, 4, 8, 3, 6, 9, 5, 2],
            [6, 9, 2, 1, 4, 5, 3, 0, 7]
        ],
        [
            [0, 2, 7, 5, 0, 4, 0, 0, 0],
            [0, 0, 0, 3, 7, 0, 0, 0, 4],
            [3, 0, 0, 0, 0, 0, 8, 0, 0],
            [4, 7, 0, 9, 5, 8, 0, 3, 6],
            [2, 6, 8, 7, 1, 0, 0, 4, 9],
            [0, 0, 0, 0, 0, 2, 0, 1, 8],
            [0, 8, 3, 0, 9, 0, 4, 0, 0],
            [7, 1, 0, 0, 0, 0, 9, 0, 2],
            [0, 0, 0, 0, 0, 5, 0, 0, 7]
        ],
        [
            [0, 0, 0, 0, 0, 6, 0, 0, 0],
            [0, 0, 7, 2, 0, 0, 8, 0, 0],
            [9, 0, 6, 8, 0, 0, 0, 1, 0],
            [3, 0, 0, 7, 0, 0, 0, 2, 9],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [4, 0, 0, 5, 0, 0, 0, 7, 0],
            [6, 5, 0, 1, 0, 0, 0, 0, 0],
            [8, 0, 1, 0, 5, 0, 3, 0, 0],
            [7, 9, 2, 0, 0, 0, 0, 0, 4]
        ]
    ];

    constructor(address _verifyAddr) {
        verifyAddr = _verifyAddr;
    }

    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[81] memory input
    ) public view returns (bool) {
        return IVerifier(verifyAddr).verifyProof(a, b, c, input);
    }

    function verifySudokuBoard(uint256[81] memory board) private view returns (bool) {
        bool isEqual = true;
        for (uint256 i = 0; i < sudokuBoardList.length; ++i) {
            isEqual = true;
            for (uint256 j = 0; j < sudokuBoardList[i].length; ++j) {
               for (uint256 k = 0; k < sudokuBoardList[i][j].length; ++k) {
                   if (sudokuBoardList[i][j][k] != board[j * 9 + k]) {
                       isEqual = false;
                       break;
                   }
               }
            }
            if (isEqual) {
                return isEqual;
            }
        }
        return isEqual;
    }

    function verifySudoku(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[81] memory input
    ) public view returns (bool) {
        require(verifySudokuBoard(input), "This board does not exist");
        require(verifyProof(a, b, c, input), "Filed proof check");
        return true;
    }

    function pickRandomBoard(string memory stringTime) private view returns (uint8[9][9] memory) {
        uint256 randPosition = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    msg.sender,
                    stringTime
                )
            ) 
        ) % sudokuBoardList.length;
        return sudokuBoardList[randPosition];
    }

    function generateSudokuBoard(string memory stringTime) public view returns (uint8[9][9] memory) {
        return pickRandomBoard(stringTime);
    }

}