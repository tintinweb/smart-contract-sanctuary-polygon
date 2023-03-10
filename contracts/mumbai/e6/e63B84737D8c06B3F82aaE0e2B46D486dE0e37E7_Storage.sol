/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Storage {
    string ipfsHash;

    address payable[] contractPartners = [
        payable(0xE4b3717A2b902327BCe7473F68A996Ea0860397F),
        payable(0xB9fe0Ff0fC8CB73Be7A887e8319bA7AC7dD8ecEC)
    ];

    function sendHash(string memory x) public {
        ipfsHash = x;
    }

    function getHash() public view returns (string memory) {
        return ipfsHash;
    }

    function transfer() public payable returns (bool) {
        if (msg.sender == contractPartners[0]) {
            contractPartners[1].transfer(msg.value);
            return true;
        } else if (msg.sender == contractPartners[1]) {
            contractPartners[0].transfer(msg.value);
            return true;
        }

        return false;
    }
}