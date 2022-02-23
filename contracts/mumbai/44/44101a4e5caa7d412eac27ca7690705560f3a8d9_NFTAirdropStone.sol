// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;
pragma abicoder v2;

import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ManagerInterface.sol";
import "./RandInterface.sol";
import "./INFTCore.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract NFTAirdropStone is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    INFTCore public nft;
    RandInterface public randManager;
    uint256 public PERCENTS_DIVIDER = 10000;
    uint256 public TOTAL_BOX = 10000;
    uint256 public CURRENT_BOX = 0;
    uint256 public startClaim = 1641531600;
    uint256 public endClaim = 1644210000;

    struct SaleBox {
        uint256 typeBox;
        uint256 price;
        uint256 fourRarePercent;
        uint256 thirdRarePercent;
        uint256 secondRarePercent;
    }

    mapping(uint256 => SaleBox) public saleBoxs;

    struct UserInfo {
        uint256 tokenId;
    }

    mapping(address => UserInfo) public userInfos;

    event Claim(uint256 indexed tokenId, address buyer);

    constructor(address _nft, address _randManager) {
        nft = INFTCore(_nft);
        randManager = RandInterface(_randManager);
        saleBoxs[3] = SaleBox(3, 0, 1, 501, 1501);
    }

    function setPercentBox(
        uint256 typeBox,
        uint256 fourRarePercent,
        uint256 thirdRarePercent,
        uint256 secondRarePercent
    ) public onlyOwner {
        saleBoxs[typeBox].fourRarePercent = fourRarePercent;
        saleBoxs[typeBox].thirdRarePercent = thirdRarePercent;
        saleBoxs[typeBox].secondRarePercent = secondRarePercent;
    }

    function setTotalBox(uint256 _box) external onlyOwner {
        TOTAL_BOX = _box;
    }

    function setStarSale(uint256 time) external onlyOwner {
        startClaim = time;
    }

    function setEndSale(uint256 time) external onlyOwner {
        endClaim = time;
    }

    /**
     * @dev Claim Box
     */
    function claimBox() public nonReentrant whenNotPaused {
        require(CURRENT_BOX.add(1) <= TOTAL_BOX, "box already claim out");
        uint256 typeBox = 3;
        _buyNFT(typeBox);
        CURRENT_BOX = CURRENT_BOX.add(1);
    }

    /**
     * @dev Sale NFT
     */
    function _buyNFT(uint256 _typeBox) internal {
        require(block.timestamp >= startClaim, "Claim has not started yet.");
        require(block.timestamp <= endClaim, "Claim already ended");
        UserInfo storage userInfo = userInfos[_msgSender()];
        require(userInfo.tokenId == 0, "already claimed");
        uint256 rareRand;
        uint256 rare;
        randManager.randMod(_msgSender(), PERCENTS_DIVIDER);
        rareRand = randManager.currentRandMod();
        if (rareRand <= saleBoxs[_typeBox].fourRarePercent) {
            rare = 3;
        }
        if (
            rareRand > saleBoxs[_typeBox].fourRarePercent &&
            rareRand <= saleBoxs[_typeBox].thirdRarePercent
        ) {
            rare = 2;
        }

        if (
            rareRand > saleBoxs[_typeBox].thirdRarePercent &&
            rareRand <= saleBoxs[_typeBox].secondRarePercent
        ) {
            rare = 1;
        }

        if (rareRand > saleBoxs[_typeBox].secondRarePercent) {
            rare = 0;
        }
        uint256 tokenId = nft.getNextNFTId();
        userInfo.tokenId = tokenId;
        nft.safeMintNFT(_msgSender(), tokenId);
        NFTItem memory nftItem = NFTItem(
            tokenId,
            "Zuki Stone",
            rare,
            block.timestamp
        );
        nft.setNFTFactory(nftItem, tokenId);
        nft.setNFTForUser(nftItem, tokenId, _msgSender());
        emit Claim(tokenId, _msgSender());
    }

    /**
     * @dev Withdraw bnb from this contract (Callable by owner only)
     */
    function handleForfeitedBalance(
        address coinAddress,
        uint256 value,
        address payable to
    ) external onlyOwner {
        if (coinAddress == address(0)) {
            return to.transfer(value);
        }
        IERC20(coinAddress).transfer(to, value);
    }
}