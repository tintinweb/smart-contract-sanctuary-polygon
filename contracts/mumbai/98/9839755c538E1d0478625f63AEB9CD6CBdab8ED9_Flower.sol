//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Flower {
    string public myFlower = "Rose";

    function changeWord() external {
        myFlower = "Ebuka";
    }
}