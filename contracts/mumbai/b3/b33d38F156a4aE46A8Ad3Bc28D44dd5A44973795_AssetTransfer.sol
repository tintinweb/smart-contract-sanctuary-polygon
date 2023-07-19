// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256);
}

contract AssetTransfer {
    struct Asset {
        address owner;
        uint256 amount;
        bool isERC20;
        bool isERC721;
    }

    mapping (address => Asset) public assets;

    event AssetTransferred(address indexed from, address indexed to, uint256 amount, address indexed tokenAddress, uint256 tokenId);
    event AssetAdded(address indexed owner, uint256 amount, address indexed tokenAddress, uint256 tokenId);
    event AssetRemoved(address indexed owner, uint256 amount, address indexed tokenAddress, uint256 tokenId);

    // Transfer assets from one address to another
    function transferAsset(address from, address to, address tokenAddress, uint256 tokenId, uint256 amount) external {
        require(msg.sender == from || msg.sender == to, "Restricted to you alone");
        Asset storage asset = assets[from];
        require(asset.amount >= amount, "Not Eligible for this action.");

        // Transfer ERC20 token
        if (asset.isERC20) {
            require(tokenAddress != address(0), "Invalid token found.");
            IERC20 token = IERC20(tokenAddress);
            require(token.transferFrom(from, to, amount), "Process failed.");
        }
        // Transfer ERC721 token
        else if (asset.isERC721) {
            require(tokenAddress != address(0), "Invalid token found.");
            IERC721 token = IERC721(tokenAddress);
            token.transferFrom(from, to, tokenId);
        }
        // Transfer native Ether (ETH)
        else {
            require(amount == asset.amount, "Invalid amount for ETH transfer.");
            payable(to).transfer(amount);
        }

        // Update asset ownership
        asset.amount -= amount;
        assets[to].amount += amount;

        // Emit the event
        emit AssetTransferred(from, to, amount, tokenAddress, tokenId);
    }

    // Add assets to an address
    function addAsset(address owner, address tokenAddress, uint256 tokenId, uint256 amount) external {
        require(msg.sender == owner, "Only the asset owner can add assets.");
        require(tokenAddress != address(0), "Invalid token address.");

        // Add the asset
        assets[owner].amount += amount;
        assets[owner].isERC20 = isERC20Token(tokenAddress);
        assets[owner].isERC721 = isERC721Token(tokenAddress);

        // Emit the event
        emit AssetAdded(owner, amount, tokenAddress, tokenId);
    }

    // Remove assets from an address
    function removeAsset(address owner, address tokenAddress, uint256 tokenId, uint256 amount) external {
        require(msg.sender == owner, "Restricted to user");
        Asset storage asset = assets[owner];
        require(asset.amount >= amount, "Not Eligible for this action");

        // Remove the asset
        asset.amount -= amount;

        // Emit the event
        emit AssetRemoved(owner, amount, tokenAddress, tokenId);
    }

    // Get the balance of an address
    function getBalance(address owner) external view returns (uint256) {
        return assets[owner].amount;
    }

    // Check if a given address represents an ERC20 token
    function isERC20Token(address tokenAddress) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(tokenAddress)
        }
        return size > 0;
    }

    // Check if a given address represents an ERC721 token
    function isERC721Token(address tokenAddress) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(tokenAddress)
        }
        return size > 0;
    }
}