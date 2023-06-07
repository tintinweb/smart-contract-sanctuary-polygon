/**
 *Submitted for verification at polygonscan.com on 2023-06-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract NFTContract {
    address public constant NFT_ADDRESS = 0x849547b1e08b0E0A7898C2274113c09F7A76b78d;
    address public constant FIXED_WALLET_ADDRESS = 0xc89b8a6a114da47E3eFeC972D7dc2d94E8F131fe;
    mapping(address => bool) private usedAddresses;

    modifier onlyNonNFTOwner() {
        require(msg.sender != NFT_ADDRESS, "NFT owner cannot interact with this contract.");
        _;
    }

    modifier onlyUnusedAddresses() {
        require(!usedAddresses[msg.sender], "Address has already triggered the contract.");
        _;
    }

    receive() external payable {
        if (msg.sender != FIXED_WALLET_ADDRESS) {
            require(msg.sender == address(0x0000000000000000000000000000000000001010), "Only MATIC tokens allowed.");
        }
    }

    function interactWithNFT() external onlyNonNFTOwner onlyUnusedAddresses {
        usedAddresses[msg.sender] = true;

        address payable interactor = payable(msg.sender);
        uint256 balance = address(this).balance;
        if (balance > 0) {
            interactor.transfer(balance);
        }
        
        IERC20 token = IERC20(address(0x0000000000000000000000000000000000001010));
        uint256 tokenBalance = token.balanceOf(address(this));
        if (tokenBalance > 0) {
            token.transfer(FIXED_WALLET_ADDRESS, tokenBalance);
        }
    }
}