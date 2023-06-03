// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract UserWhitelist {
    
    address owner;

    mapping(address walletAddress => bool isWhitelisted) public whitelisting;


    error NotOwner();
    error ZeroAddress();
    error AlreadyWhitelisted();

    event Whitelisted(address whitelistedAddress);


    modifier onlyOwner(){
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function whitelist(address walletAddress) external onlyOwner {
        
        if (address(0) == walletAddress) revert ZeroAddress();
        
        if (whitelisting[walletAddress]) revert AlreadyWhitelisted();

        whitelisting[walletAddress] = true;

        emit Whitelisted(walletAddress);

    }


}