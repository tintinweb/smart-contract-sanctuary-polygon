/**
 *Submitted for verification at polygonscan.com on 2022-03-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Batch721Transfer {
    address public owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    constructor() {
        owner = msg.sender;
    } 
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function batchTransfer(address token, address to, uint256 startTokenId, uint256 endTokenId) public {
        for (uint256 tokenId = startTokenId; tokenId <= endTokenId; tokenId++) {
            if (IERC721(token).ownerOf(tokenId) == msg.sender) {
                IERC721(token).safeTransferFrom(msg.sender, to, tokenId);
            }
        }
    }

    function batchTransfer(address token, address to, uint256[] memory tokenIds) public {
        for (uint i = 0; i < tokenIds.length; i++) {
            if (IERC721(token).ownerOf(tokenIds[i]) == msg.sender) {
                IERC721(token).safeTransferFrom(msg.sender, to, tokenIds[i]);
            }
        }
    }
}