// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
/**
 * @version 0.1.2
 */

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

interface Nft {
    function minterMint(address to, uint256 quantity) external;
}

contract SimpleSeller is Ownable, ReentrancyGuard {
    using Strings for uint256;
    bool public _isSaleActive = false;

    uint256 public mintPrice = 0.002 ether;
    uint256 public maxMint = 1;

    address public nftContract;

    constructor(address _nftContract) {
        nftContract = _nftContract;
    }

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "callerIsUser: The Caller Can Not Be Another Contract"
        );
        _;
    }

    function filpSaleActive() external onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function mint(uint256 quantity) external payable callerIsUser nonReentrant {
        require(_isSaleActive, "mint: Sale Must be Active to Mint");
        require(quantity * mintPrice <= msg.value, "mint: No Enough Eth Sent");
        Nft(nftContract).minterMint(msg.sender, quantity);
    }

    function withdraw(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }
}