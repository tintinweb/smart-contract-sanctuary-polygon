/**
 *Submitted for verification at polygonscan.com on 2022-09-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract FavoriteIPFS {
    struct Favorite {
        string name;
        string url;
    }

    mapping(address => Favorite) public favorites;

    function setFavorite(string memory name, string memory url) public {
        favorites[msg.sender] = Favorite(name, url);
    }

    function getFavorite() public view returns (string memory name, string memory url) {
        Favorite memory favorite = favorites[msg.sender];
        return (favorite.name, favorite.url);
    }

}