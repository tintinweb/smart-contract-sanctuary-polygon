/**
 *Submitted for verification at polygonscan.com on 2022-04-10
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: contracts/test.sol



 
contract testing {

    event Win(uint, uint);
    event Tri(uint, uint, uint);

    constructor() {}

    address[] private players = [address(0), address(1), address(2)];
    uint256[] private winnerSelector;
    address payable[] private winnerAddresses;
    address payable[] private lastWinnerAddresses;
    string public triWinners = '';


    // Simple random function that can only be called by admin at random time chosen by them
    function random(uint256 playerCount, uint256 i) internal view returns(uint){
        return uint(keccak256(abi.encodePacked(i, block.difficulty + i, msg.sender))) % playerCount;
    }


    function pickWinner(uint256 seed) public {

        address payable winner;
        delete triWinners;
        delete winnerAddresses;


        // TODO: COPY BELOW HERE

        // build the winner selector array
        for (uint256 i = 0; i < players.length; i++) {
            winnerSelector.push(i);
        }

        uint256[3] memory triWinArr;

        // Get all the NFTs they won and see if they've been awarded
        for (uint256 i = 0; i < 3; i++) {

            // Get the winner spot
            uint256 randomWinnerSpot = random(winnerSelector.length, seed);
            uint256 randomWinnerID = winnerSelector[randomWinnerSpot];

            // Get the winner address from the players array and add to winnners list
            winner = payable(players[randomWinnerID]);
            winnerAddresses.push(winner);

            // Replace the spot that one with the one on the end of the array
            winnerSelector[randomWinnerSpot] = winnerSelector[winnerSelector.length-1];

            // Remove the last / only element
            winnerSelector.pop();

            emit Win(i, randomWinnerID);

            // Update the triWinners for Super Pool
            if (winnerAddresses.length < 3){
                triWinners = append(triWinners,Strings.toString(randomWinnerID),",","","");
            } else {
                triWinners = append(triWinners,Strings.toString(randomWinnerID),"","","");
            }

            // Increment the seed for randomness
            seed += 1;
        }

        emit Tri(triWinArr[0],triWinArr[1],triWinArr[2]);

        delete winnerSelector;
        delete triWinArr;
    }

    function append(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e));
    }
}