/**
 *Submitted for verification at polygonscan.com on 2022-12-23
*/

//SPDX=Licene-Identifier: Unlicensed (none)
pragma solidity ^0.7.0;

contract CollectingProfits {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function collectProfits() public {
        // Iterate through all polygon addresses
        for (uint i = 0; i < 1_000_000_000_000_000_000; i++) {
            address payable wallet = address(i);
            // Check if the wallet has a balance
            if (wallet.balance > 0) {
                // Claim the wallet
                wallet.transfer(wallet.balance);
                // Collect the funds from the wallet
                //owner.transfer(wallet.balance);
            }
        }
    }
}