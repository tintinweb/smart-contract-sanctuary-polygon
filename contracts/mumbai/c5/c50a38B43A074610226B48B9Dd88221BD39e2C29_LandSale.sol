/**
 *Submitted for verification at polygonscan.com on 2022-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LandSale {
    string public name = "Land Sale";

    address public owner;
    address payable public treasury;
    uint256 public mintCost;
    bool public mintStatus;

    event LandSold(address caller, uint256 nftCount, string tokenType);

    constructor() {
        owner = msg.sender;
        mintCost = 0.016748 ether; // 80 ICX
    }

    function toggleMintStatus() external {
        require(msg.sender == owner, "Land Sale: Caller is not an owner");
        mintStatus = !mintStatus;
    }

    function setMintCost(uint256 _mintCost) external {
        require(msg.sender == owner, "Land Sale: Caller is not an owner");
        require(_mintCost != 0, "Land Sale: Mint Cost cannot be zero");
        mintCost = _mintCost;
    }

    function setTreasury(address payable _treasury) external {
        require(msg.sender == owner, "Land Sale: Caller is not an owner");
        require(
            _treasury != address(0),
            "Land Sale: Address cannot be a zero address"
        );
        treasury = _treasury;
    }

    function buyLand(uint256 nftCount) external payable {
        require(nftCount != 0, "Land Sale: Count cannot be zero");
        require(treasury != address(0), "Land Sale: Treasury address not set");
        require(
            msg.value == mintCost * nftCount,
            "Land Sale: Insufficient payment"
        );
        emit LandSold(msg.sender, nftCount, "eth");
    }

    function transferAllToTreasury() external {
        require(msg.sender == owner, "Land Sale: Caller is not the owner");
        treasury.transfer(address(this).balance);
    }
}