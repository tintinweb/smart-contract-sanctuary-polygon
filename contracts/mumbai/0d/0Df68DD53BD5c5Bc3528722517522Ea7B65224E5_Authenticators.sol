// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


// Manages a directory of all authenticators 
// Also sets rules for adding and removing an authenticator
contract Authenticators {
    struct Authenticator {
        address authenticatorAddress;
        uint weight;
    }

    Authenticator[] public authenticators;
    mapping(address => bool) public isAuthenticator;

    function registerAuthenticator(address payable _authenticatorAddress) public {
        Authenticator memory newAuthenticator = Authenticator({
            authenticatorAddress: _authenticatorAddress,
            weight: 10
        });

        authenticators.push(newAuthenticator);
        isAuthenticator[_authenticatorAddress] = true;
    }

    function removeAuthenticator() public {
        // removes authenticators with weight less than 1
    }
}