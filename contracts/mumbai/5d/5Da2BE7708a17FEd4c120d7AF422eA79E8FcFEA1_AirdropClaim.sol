/**
 *Submitted for verification at polygonscan.com on 2023-05-20
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract AirdropClaim {
    // Token contract address
    address private constant TOKEN_ADDRESS = 0x4a79Ca87dA58c397971c0E86D0E7E12A29d4F67c; // Ganti dengan alamat kontrak token yang sesuai

    // Mapping to track claimed addresses
    mapping(address => bool) private claimedAddresses;
    address[] private claimedAddressList; // List of claimed addresses

    // Maximum number of addresses that can claim
    uint256 private constant MAX_CLAIM_ADDRESSES = 2000000;

    // Amount of tokens to be claimed
    uint256 private constant CLAIM_AMOUNT = 100000;

    // Claim the airdrop tokens
    function claimAirdrop() external {
        // Ensure address hasn't claimed before and total claimed addresses is within limit
        require(!claimedAddresses[msg.sender], "Address has already claimed the airdrop");
        require(claimedAddressList.length < MAX_CLAIM_ADDRESSES, "Maximum number of addresses have claimed");

        // Mark address as claimed
        claimedAddresses[msg.sender] = true;
        claimedAddressList.push(msg.sender);

        // Transfer tokens to the claimer
        (bool success, ) = TOKEN_ADDRESS.call(
            abi.encodeWithSignature("transfer(address,uint256)", msg.sender, CLAIM_AMOUNT)
        );
        require(success, "Token transfer failed");
    }

    // Check if an address has claimed the airdrop
    function hasClaimed(address _address) public view returns (bool) {
        return claimedAddresses[_address];
    }

    // Get the total number of claimed addresses
    function getTotalClaimedAddresses() public view returns (uint256) {
        return claimedAddressList.length;
    }
}