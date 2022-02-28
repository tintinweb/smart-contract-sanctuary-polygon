// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;
pragma abicoder v2;

import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./INFTCore.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract ZukiConvertPoly is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    INFTCore public nftCore;

    event Convert(uint256 indexed tokenId, address userAddress);
    mapping(uint256 => bool) public converts;
    mapping(address => bool) public whiteList;

    modifier onlySafe() {
        require(whiteList[msg.sender], "require Safe Address.");
        _;
    }

    constructor(address _nft) {
        nftCore = INFTCore(_nft);
    }

    function modifyWhiteList(
        address[] memory newAddr,
        address[] memory removedAddr
    ) public onlyOwner {
        for (uint256 index; index < newAddr.length; index++) {
            whiteList[newAddr[index]] = true;
        }
        for (uint256 index; index < removedAddr.length; index++) {
            whiteList[removedAddr[index]] = false;
        }
    }

    function setNFT(address _address) external onlyOwner {
        nftCore = INFTCore(_address);
    }

    /**
     * @dev Convert NFT
     */
    function convertNFT(address userAddress, NFTItem[] memory tokenIds)
        public
        onlySafe
        nonReentrant
        whenNotPaused
    {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            require(!converts[tokenIds[index].tokenId], "already convert");
            converts[tokenIds[index].tokenId] = true;
            uint256 tokenId = nftCore.getNextNFTId();
            nftCore.safeMintNFT(_msgSender(), tokenId);
            NFTItem memory nftItem = NFTItem(
                tokenId,
                tokenIds[index].class,
                tokenIds[index].rare,
                block.timestamp
            );
            nftCore.setNFTFactory(nftItem, tokenId);
            emit Convert(tokenId, userAddress);
        }
    }

    /**
     * @dev Withdraw bnb from this contract (Callable by owner only)
     */
    function handleForfeitedBalance(
        address coinAddress,
        uint256 value,
        address payable to
    ) public onlyOwner {
        if (coinAddress == address(0)) {
            return to.transfer(value);
        }
        IERC20(coinAddress).transfer(to, value);
    }
}