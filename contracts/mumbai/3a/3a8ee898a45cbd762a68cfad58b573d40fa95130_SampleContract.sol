/**
 *Submitted for verification at polygonscan.com on 2022-03-24
*/

// File: SampleContract.sol


pragma solidity ^0.8;

contract SampleContract {
    address public owner = msg.sender;
    mapping(address => string) public store;
    
    modifier restricted() {
        require(
        msg.sender == owner,
        "This function is restricted to the contract's owner"
        );
        _;
    }
    
    function storeHash(address _a, string memory _h) public restricted {
        store[_a] = _h;
    }

    function getHash(address _a) public view returns (string memory) {
        return store[_a];
    }
}