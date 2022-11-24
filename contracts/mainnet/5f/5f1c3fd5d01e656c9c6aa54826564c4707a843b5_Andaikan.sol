/**
 *Submitted for verification at polygonscan.com on 2022-11-23
*/

pragma solidity ^0.8.0;

contract Andaikan {
    mapping(uint256 => string) private saveMessage;

    constructor(string[] memory _saveMessage) {
        for (uint256 i = 0; i < 5; i++) {
            saveMessage[i + 1] = _saveMessage[i];
        }
    }

    function showLove(uint256 numMsg) external view returns(string memory) {
        return saveMessage[numMsg];
    }
}