//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract record {
    string[] public ipfsHash;

    function set(string memory x) public {
        ipfsHash.push(x);
    }

    function get() public view returns (string[] memory) {
        return ipfsHash;
    }

    function getCount() public view returns (uint256) {
        return ipfsHash.length;
    }
}