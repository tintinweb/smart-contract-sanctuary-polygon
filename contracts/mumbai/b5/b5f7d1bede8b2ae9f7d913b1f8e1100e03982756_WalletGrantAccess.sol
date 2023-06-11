/**
 *Submitted for verification at polygonscan.com on 2023-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WalletGrantAccess {
    mapping(address => bool) private authorizedWallets;

    event AccessGranted(address indexed wallet);
    event AccessRevoked(address indexed wallet);

    modifier onlyAuthorized() {
        require(authorizedWallets[msg.sender], "Unauthorized");
        _;
    }

    function grantAccess() external {
        authorizedWallets[msg.sender] = true;
        emit AccessGranted(msg.sender);
    }

    function revokeAccess() external onlyAuthorized {
        authorizedWallets[msg.sender] = false;
        emit AccessRevoked(msg.sender);
    }

    function isAuthorized(address wallet) external view returns (bool) {
        return authorizedWallets[wallet];
    }
}