/**
 *Submitted for verification at polygonscan.com on 2022-09-01
*/

// File: PuddyCopyrighter.sol


pragma solidity 0.8.15;

contract PuddyCopyrighter {

    // Info
    address payable public owner;
    mapping (string => string) public ipfs;

    // Event
    event IPFS(address indexed from, string index, string value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Constructor
    constructor() {
        owner = payable(msg.sender);
    }

    // Info
    function getOwner() public view returns (address) {
        return owner;
    }

    function transferOwnership(address newOwner) public {
        require(address(msg.sender) == address(owner), "You are not allowed to do this.");
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = payable(newOwner);
    }

    function getIPFS(string memory _value) external view returns (string memory) {
        return ipfs[_value];
    }

    // Register IPFS here
    function insertIPFS(string memory _index, string memory _value) public returns (bool success) {

        // Validate
        require(address(msg.sender) == address(owner), "You are not allowed to do this.");
        require(keccak256(abi.encode(ipfs[_index])) == keccak256(abi.encode("")), "This storage has already been used.");

        // Complete
        ipfs[_index] = _value;
        emit IPFS(msg.sender, _index, _value);
        return true;

    }
    
}