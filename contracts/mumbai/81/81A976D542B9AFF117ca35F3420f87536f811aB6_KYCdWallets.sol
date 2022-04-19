/**
 *Submitted for verification at polygonscan.com on 2022-04-18
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File contracts/interfaces/IRBAC.sol

pragma solidity ^0.6.12;

interface IRBAC {
    function isAdmin(address user) external view returns (bool);
}


// File contracts/KYCdWallets.sol

pragma solidity ^0.6.12;

contract KYCdWallets {
    // Pointer to admin contract
    IRBAC public admin;
    // List of all whitelisted wallets
    address [] public whitelistedWallets;
    // Mapping weather wallet is whitelisted or not.
    mapping(address => bool) public isWalletWhitelisted;

    event AddWalletToWhitelist(address _account);
    event RemoveWalletFromWhiteList(address _account);

    constructor (address _admin) public {
        require(_admin != address(0), "_admin can not be 0x0 address.");
        admin = IRBAC(_admin);
    }


    // Function to whitelist wallet
    function whitelistWallet(address _account) external {
        require(admin.isAdmin(msg.sender), "Only admin can whitelist wallet.");
        require(!isWalletWhitelisted[_account], "Wallet is already whitelisted.");

        isWalletWhitelisted[_account] = true; // Mark wallet as whitelisted
        whitelistedWallets.push(_account); // Add marked wallet to array

        emit AddWalletToWhitelist(_account);
    }

    function removeWhitelistedWallet(address _wallet) external
    {
        require(admin.isAdmin(msg.sender), "Only admin can whitelist wallet.");
        // wallet has to be whitelisted previously
        require(isWalletWhitelisted[_wallet] == true, "Wallet is not whitelisted.");

        uint i = 0;

        while(whitelistedWallets[i] != _wallet) {
            if(i == whitelistedWallets.length) {
                revert("Passed wallet address does not exist");
            }
        }
        // Copy the last whitelisted position to the current index
        whitelistedWallets[i] = whitelistedWallets[whitelistedWallets.length-1];
        // Mapping that wallet is not whitelisted anymore
        isWalletWhitelisted[_wallet] = false;
        // Remove the last whitelisted wallet, since it's double present
        whitelistedWallets.pop();

        emit RemoveWalletFromWhiteList(_wallet);
    }

    // Function to return whitelist status for the wallet
    function getWhitelistStatus(address _wallet) external view returns (bool) {
        return isWalletWhitelisted[_wallet];
    }
}