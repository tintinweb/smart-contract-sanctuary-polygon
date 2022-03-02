/**
 *Submitted for verification at polygonscan.com on 2022-03-02
*/

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract DigitalOilStrike1 {

    string[] public jokes;
    mapping (address => string) public jokers;
    mapping (address => bool) public jokerSet;

    function submitJoke(string memory joke) public {
        require(checkJokeUnique(joke), "This joke has already been submitted");
        require(jokerSet[msg.sender] == false, "You can only submit one joke");
        jokerSet[msg.sender] = true;
        jokes.push(joke);
        jokers[msg.sender] = joke;
    }

    function checkJokeUnique(string memory joke) internal view returns (bool) {
        for (uint8 i = 0; i < jokes.length; i++) {
            if (sha256(bytes(joke)) == sha256(bytes(jokes[i]))) {
                return false;
            }
        }

        return true;
    }

    function getJokes() public view returns (string[] memory) {
        return jokes;
    }

}