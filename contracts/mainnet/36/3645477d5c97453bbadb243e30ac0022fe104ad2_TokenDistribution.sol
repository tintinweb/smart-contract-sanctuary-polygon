/**
 *Submitted for verification at polygonscan.com on 2023-01-26
*/

// SPDX-License-Identifier: UNLICENSED
// (C) 2023 ONTROPY, INC. ALL RIGHTS RESERVED.
// Alexander Atamanov
// [email protected]

pragma solidity ^0.8.0;

contract TokenDistribution {
    address public owner;
    address[] public allowedAirdrop;
    address[] public allowedAccounts;
    uint256 public counter;

    mapping ( address => uint256 ) public orbTokens;
    
    constructor() {
        owner = msg.sender;
        counter = 0;
        allowedAirdrop.push(0x1B587644502e1cc7a57fdb4C3D0fB222F8240f7e);
        allowedAccounts.push(0xB986AE15b82d88b81A10E9E2B7fa13A7b9254fF4);
    }

    event LogDistribution(address recipient, uint256 tokenAmount);
    event LogAllowedAirdrop(address[] allowedAirdrop);
    event LogAllowedAccounts(address[] allowedAccounts);

    function distributeTokens(address recipient, uint256 tokenAmount) public {
        bool found = false;
        if(msg.sender == owner) {
            found = true;
        }
        else {
            for (uint256 i = 0; i < allowedAirdrop.length; i++) {
             if (allowedAirdrop[i] == msg.sender) {
                 found = true;
                 break;
                }
            }
        }
        require(found, "Sender is not an allowed airdrop address.");
        orbTokens[recipient] += tokenAmount;
        counter++;
        emit LogDistribution(recipient, tokenAmount);
    }

    function distributeTokensToArray(address[] memory wallets, uint256 tokenAmount) public {
        for (uint256 i = 0; i < wallets.length; i++) {
            distributeTokens(wallets[i], tokenAmount);
        }
    }

    function getBalance(address account) public view returns (uint256) {
        bool found = false;
        if ( msg.sender == account || msg.sender == owner) {
            found = true;
        } 
        else {
            for (uint256 i = 0; i < allowedAccounts.length; i++) {
                if (allowedAccounts[i] == msg.sender) {
                    found = true;
                    break;
                }
            }
        
        }
        require(found, "Sender is not an allowed account.");
        return orbTokens[account];
    }

    function updateAllowedAirdrop(address newAllowedAirdrop) public {
        require(msg.sender == owner, "Only owner can update allowed airdrop address.");
        allowedAirdrop.push(newAllowedAirdrop);
        emit LogAllowedAirdrop(allowedAirdrop);
    }

    function updateAllowedAccounts(address newAllowedAccount) public {
        require(msg.sender == owner, "Only owner can update allowed accounts.");
        allowedAccounts.push(newAllowedAccount);
        emit LogAllowedAccounts(allowedAccounts);
    }

    function clearAllowedAirdrop() public {
        require(msg.sender == owner, "Only owner can clear allowed airdrop addresses.");
        delete allowedAirdrop;
        allowedAirdrop = new address[](0);
    }

    function clearAllowedAccounts() public {
        require(msg.sender == owner, "Only owner can clear allowed accounts.");
        delete allowedAccounts;
        allowedAccounts = new address[](0);
    }
}