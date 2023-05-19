/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Enumerable {
    function totalSupply() external view returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

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
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

contract PartnersOW {
    uint256 public constant MINIMUM_INVESTMENT = 0.00000000000001 ether;

    address private _owner;
    uint256 private _totalInvestment;
    uint256 private _tokenIdCounter;

    mapping(address => uint256) private _investments;

    event NFTMinted(address indexed investor, uint256 tokenId);

    constructor() {
        _owner = msg.sender;
        _tokenIdCounter = 1;
    }

    function invest() external payable {
        require(msg.value >= MINIMUM_INVESTMENT, "Investment amount is less than minimum investment");

        // Check investment limit
        require(msg.value <= address(this).balance, "Investment limit reached");

        // Add investment to total and record investor's investment
        _totalInvestment += msg.value;
        _investments[msg.sender] += msg.value;

        // Mint investment NFT to investor
        uint256 tokenId = _getNextTokenId();
        _safeTransferFrom(address(this), msg.sender, tokenId);

        emit NFTMinted(msg.sender, tokenId);
    }

    function withdraw() external {
        require(msg.sender == _owner, "Only contract owner can withdraw");

        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available to withdraw");

        payable(msg.sender).transfer(balance);
    }

    function updateInvestment(uint256 newInvestment) external {
        require(msg.sender == _owner, "Only contract owner can update investment");

        // Add new investment to total
        _totalInvestment += newInvestment;
    }

    function distributeProfit(uint256 profitPercentage) external {
        require(msg.sender == _owner, "Only contract owner can distribute profit");

        // Calculate payout for each investor and send payout
        for (uint256 i = 0; i < _totalSupply(); i++) {
            uint256 tokenId = _tokenByIndex(i);
            address investor = _ownerOf(tokenId);

            uint256 investment = _investments[investor];
            uint256 payout = investment + ((investment * profitPercentage) / 100);

            payable(investor).transfer(payout);
            _investments[investor] = 0;

            // Transfer investment NFT back to the contract
            _safeTransferFrom(investor, address(this), tokenId);
        }

        _totalInvestment = 0;
    }

    function _totalSupply() private view returns (uint256) {
        // Implement your logic to get the total supply of NFTs
    }

    function _tokenByIndex(uint256 index) private view returns (uint256) {
        // Implement your logic to get the token ID by index
    }

    function _ownerOf(uint256 tokenId) private view returns (address) {
        // Implement your logic to get the owner of a token
    }

    function _getNextTokenId() private returns (uint256) {
        uint256 nextTokenId = _tokenIdCounter;
        _tokenIdCounter++;
        return nextTokenId;
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) private {
        // Implement your logic for safe transfer of NFTs
    }

    // Implement other internal functions and view functions as needed
}