/**
 *Submitted for verification at polygonscan.com on 2022-12-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

 //ERC20 and ERC721

contract Winner {

    string private winner;

    event WinnerSet(string winner);

    function getWinner() view external returns (string memory) {
        return winner;
    }

    function setWinner(string calldata _winner) external {
        winner = _winner;
        emit WinnerSet(winner);
    }
}