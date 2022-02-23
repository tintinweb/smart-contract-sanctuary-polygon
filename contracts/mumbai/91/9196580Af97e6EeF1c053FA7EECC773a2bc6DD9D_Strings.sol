/**
 *Submitted for verification at polygonscan.com on 2022-02-22
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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



    //SPDX-License-Identifier: GPL-3.0
    pragma solidity ^0.8.2;

    

    contract test {

        string[] private players;
        address public admin;
        uint256 startingPoint = 0;

        constructor() {
            admin = msg.sender;
        }

        

        function addToArray(uint256 amountToAdd) public {
            // Reset the mapping
            for (uint i=0; i< amountToAdd ; i++){
                string memory value = append(Strings.toString(startingPoint), '-', Strings.toString(i), '', '');
                players.push(value);
            }

            startingPoint += 1;
        }


        function getTotalPlayers() public view returns (uint256){
            return players.length;
        }

        function getPlayers() public view returns (string[] memory){
            return players;
        }

        function getOnePlayer(uint256 lookup) public view returns (string memory){
            return players[lookup];
        }

        function lookForPlayers() public view returns (bool){
            string memory whatToMatch = "nope";
            for (uint i=0; i< players.length - 1 ; i++){
                if (keccak256(abi.encodePacked(players[i])) == keccak256(abi.encodePacked(whatToMatch))){
                    return false;
                }
            }
            return true;
        }

        function append(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {
            return string(abi.encodePacked(a, b, c, d, e));
        }
    }