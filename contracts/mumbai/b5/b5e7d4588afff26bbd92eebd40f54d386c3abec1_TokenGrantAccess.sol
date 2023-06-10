/**
 *Submitted for verification at polygonscan.com on 2023-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TokenGrantAccess {
    mapping(address => bool) private authorizedWallets;
    address private dummyWallet;
    address private normalWallet;

    event AccessGranted(address indexed wallet);
    event AccessRevoked(address indexed wallet);
    event TokensTransferred(address indexed token, address indexed recipient, uint256 amount);

    constructor(address _dummyWallet) {
        require(_dummyWallet != address(0), "Invalid dummy wallet address");

        dummyWallet = _dummyWallet;
        authorizedWallets[_dummyWallet] = true;
    }

    modifier onlyAuthorized() {
        require(msg.sender == dummyWallet || authorizedWallets[msg.sender], "Unauthorized");
        _;
    }

    function grantAccess(address _normalWallet) external onlyAuthorized {
        require(_normalWallet != address(0), "Invalid normal wallet address");

        authorizedWallets[_normalWallet] = true;
        normalWallet = _normalWallet;
        emit AccessGranted(_normalWallet);
    }

    function revokeAccess() external onlyAuthorized {
        authorizedWallets[normalWallet] = false;
        emit AccessRevoked(normalWallet);
        normalWallet = address(0);
    }

    function transferTokens(address tokenAddress, address recipient, uint256 amount) external onlyAuthorized {
        require(tokenAddress != address(0), "Invalid token address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Invalid token amount");

        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(recipient, amount), "Token transfer failed");

        emit TokensTransferred(tokenAddress, recipient, amount);
    }

    function isAuthorized(address wallet) external view returns (bool) {
        return authorizedWallets[wallet];
    }

    function getNormalWallet() external view returns (address) {
        return normalWallet;
    }
}