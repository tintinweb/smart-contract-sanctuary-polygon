pragma solidity ^0.8.7;

contract Revocation {
    mapping(address => bool) public isRevoked;

    function revoke(address user) public {
        isRevoked[user] = true;
    }

    function unRevoke(address user) public {
        isRevoked[user] = false;
    }
}