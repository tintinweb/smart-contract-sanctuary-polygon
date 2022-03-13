/**
 *Submitted for verification at polygonscan.com on 2022-03-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BestAnimeContract {
    address private owner;
    string private BestAnime;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Not The Owner :)");
        _;
    }

    function TheBestAnime() public view returns (string memory) {
        return BestAnime;
    }

    function setBestAnime(string memory _bestanime) external onlyOwner {
        BestAnime = _bestanime;
    }
}