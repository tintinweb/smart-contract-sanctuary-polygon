/**
 *Submitted for verification at polygonscan.com on 2023-01-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Unknow {

    function store() public view returns (bytes4) {
        bytes4 selector = bytes4(keccak256("store(uint256)"));
        return selector;
    }

     function retrieve() public view returns (bytes4) {
        bytes4 selector = bytes4(keccak256("retrieve()"));
        return selector;
    }
    
    function mintByLaunchpadPlatform() public view returns (bytes4) {
        bytes4 selector = bytes4(keccak256("mintByLaunchpadPlatform(address, uint256)"));
        return selector;
    }

     function setBaseURIByLaunchpadPlatform() public view returns (bytes4) {
        bytes4 selector = bytes4(keccak256("setBaseURIByLaunchpadPlatform(string)"));
        return selector;
    }

    function judge() public view returns (bool) {
        return block.timestamp > 1672806600;
    }

     function timestamp1() public view returns (uint) {
        uint time = block.timestamp;
        return time;
    }
}