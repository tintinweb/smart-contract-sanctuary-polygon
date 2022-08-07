/**
 *Submitted for verification at polygonscan.com on 2022-08-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


contract LiquidityLocker is IERC721Receiver { 
    address public constant nonfungiblePositionManager = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    struct Deposit {
        address owner;
        uint256 releaseBlockNumber;
    }
    // deposits[tokenId] => Deposit
    mapping (uint256 => Deposit) public deposits;

    event Lock(address indexed from, uint256 tokenId, uint256 releaseBlockNumber);
    event Unlock(address indexed from, uint256 tokenId, uint256 blockNumber);

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function lockPosition(uint256 tokenId, uint256 releaseBlockNumber) external {
        require(deposits[tokenId].owner == address(0), "already registered");

        IERC721 v3Nft = IERC721(nonfungiblePositionManager);

        // transfer NFT to locker (approve first)
        v3Nft.safeTransferFrom(msg.sender, address(this), tokenId);

        // register deposit
        deposits[tokenId] = Deposit({owner:msg.sender, releaseBlockNumber:releaseBlockNumber});

        emit Lock(msg.sender, tokenId, releaseBlockNumber);
    }

    function unlockPosition(uint256 tokenId) external {
        require(deposits[tokenId].owner == msg.sender, "invalid owner");
        require(deposits[tokenId].releaseBlockNumber <= block.number, "not yet unlockable");

        IERC721 v3Nft = IERC721(nonfungiblePositionManager);

        // send back to owner
        v3Nft.safeTransferFrom(address(this), msg.sender, tokenId);

        // restore deposits state
        deposits[tokenId] = Deposit({owner:address(0), releaseBlockNumber:0});

        emit Unlock(msg.sender, tokenId, block.number);
    }
}