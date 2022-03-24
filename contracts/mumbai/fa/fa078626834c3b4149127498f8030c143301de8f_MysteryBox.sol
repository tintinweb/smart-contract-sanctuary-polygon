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

contract MysteryBox is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    INFTCore public nft;
    IERC20 public nftToken;
    RandInterface public randManager;
    uint256 public PERCENTS_DIVIDER = 10000;
    uint256 public BASE_PRICE = 100 * 10**18;

    struct SaleBox {
        uint256 typeBox;
        uint256 price;
        uint256 startSale;
        uint256 endSale;
        uint256 thirdRarePercent;
        uint256 secondRarePercent;
        uint256 partFourRarePercent;
        uint256 partThirdRarePercent;
        uint256 partTwoRarePercent;
        uint256 totalBox;
        uint256 currentBox;
    }

    mapping(uint256 => SaleBox) saleBoxs;

    event FeeSale(uint256 indexed tokenId, address buyer, uint256 fee);
    event Sale(
        uint256 indexed tokenId,
        address buyer,
        uint256 price,
        uint256 typeBox
    );

    uint256 public feeSale = 0;
    address payable public feeWallet;
    address payable public saleWallet;

    constructor(
        address payable _feeWallet,
        address payable _saleWallet,
        address _nft,
        IERC20 _nftToken,
        address _randManager
    ) {
        nft = INFTCore(_nft);
        feeWallet = _feeWallet;
        saleWallet = _saleWallet;
        nftToken = _nftToken;
        randManager = RandInterface(_randManager);
        saleBoxs[0] = SaleBox(
            0,
            4,
            1648093544,
            1648093544,
            0,
            0,
            25,
            50,
            75,
            0,
            0
        );
        saleBoxs[1] = SaleBox(
            1,
            2,
            1648093544,
            1648093544,
            0,
            0,
            25,
            50,
            75,
            0,
            0
        );
        saleBoxs[2] = SaleBox(
            2,
            1,
            1648093544,
            1648093544,
            0,
            0,
            25,
            50,
            75,
            0,
            0
        );
    }

    function setFeeSale(uint256 _fee) public onlyOwner {
        feeSale = _fee;
    }

    function setNFTToken(IERC20 _address) public onlyOwner {
        nftToken = _address;
    }

    function setNFT(address _address) public onlyOwner {
        nft = INFTCore(_address);
    }

    function setFeeWallet(address payable _wallet) public onlyOwner {
        feeWallet = _wallet;
    }

    function setBasePrice(uint256 _price) public onlyOwner {
        BASE_PRICE = _price;
    }

    function setSaleWallet(address payable _wallet) public onlyOwner {
        saleWallet = _wallet;
    }

    function setStarSale(uint256 typeBox, uint256 time) public onlyOwner {
        saleBoxs[typeBox].startSale = time;
    }

    function setEndSale(uint256 typeBox, uint256 time) public onlyOwner {
        saleBoxs[typeBox].endSale = time;
    }

    function setPriceBox(uint256 typeBox, uint256 price) public onlyOwner {
        saleBoxs[typeBox].price = price;
    }

    function setPercentBox(
        uint256 typeBox,
        uint256 thirdRarePercent,
        uint256 secondRarePercent
    ) public onlyOwner {
        saleBoxs[typeBox].thirdRarePercent = thirdRarePercent;
        saleBoxs[typeBox].secondRarePercent = secondRarePercent;
    }

    function setPercentNFTBox(
        uint256 typeBox,
        uint256 partFourRarePercent,
        uint256 partThirdRarePercent,
        uint256 partTwoRarePercent
    ) public onlyOwner {
        saleBoxs[typeBox].partFourRarePercent = partFourRarePercent;
        saleBoxs[typeBox].partThirdRarePercent = partThirdRarePercent;
        saleBoxs[typeBox].partTwoRarePercent = partTwoRarePercent;
    }

    function setTotalBox(uint256 typeBox, uint256 totalBox) external onlyOwner {
        saleBoxs[typeBox].totalBox = totalBox;
    }

    /**
     * @dev Gets current Box price.
     */
    function getNFTPrice(uint256 _typeBox)
        public
        view
        returns (uint256 priceSale)
    {
        return BASE_PRICE.mul(saleBoxs[_typeBox].price);
    }

    /**
     * @dev Sale Diamond Box
     */
    function buyPeice(uint256 _amount)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        uint256 typeBox = 0;
        require(
            saleBoxs[typeBox].currentBox.add(1) <= saleBoxs[typeBox].totalBox,
            "box already sold out"
        );
        _buyNFT(typeBox, _amount);
        saleBoxs[typeBox].currentBox = saleBoxs[typeBox].currentBox.add(1);
    }

    /**
     * @dev Sale Gun Box
     */
    function buyGun(uint256 _amount) public payable nonReentrant whenNotPaused {
        uint256 typeBox = 1;
        require(
            saleBoxs[typeBox].currentBox.add(1) <= saleBoxs[typeBox].totalBox,
            "box already sold out"
        );

        _buyGun(typeBox, _amount);
        saleBoxs[typeBox].currentBox = saleBoxs[typeBox].currentBox.add(1);
    }

    /**
     * @dev Sale Stone Box
     */
    function buyStone(uint256 _amount)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        uint256 typeBox = 2;
        require(
            saleBoxs[typeBox].currentBox.add(1) <= saleBoxs[typeBox].totalBox,
            "box already sold out"
        );

        _buyStone(typeBox, _amount);
        saleBoxs[typeBox].currentBox = saleBoxs[typeBox].currentBox.add(1);
    }

    /**
     * @dev Sale NFT
     */
    function _buyNFT(uint256 _typeBox, uint256 _amount) internal {
        require(
            block.timestamp >= saleBoxs[_typeBox].startSale,
            "Sale has not started yet."
        );
        require(
            block.timestamp <= saleBoxs[_typeBox].endSale,
            "Sale already ended"
        );
        require(
            getNFTPrice(_typeBox) == _amount,
            "Amount of token sent is not correct."
        );
        require(
            nftToken.allowance(msg.sender, address(this)) >= _amount,
            "Token allowance too low"
        );
        require(msg.value == feeSale, "Amount of BNB sent is not correct.");
        nftToken.transferFrom(msg.sender, saleWallet, _amount);
        if (feeSale > 0) {
            feeWallet.transfer(feeSale);
        }
        randManager.randMod(_msgSender(), 10000);
        uint256 rareRand = randManager.currentRandMod();
        uint256 rarePart;

        if (rareRand <= saleBoxs[_typeBox].partFourRarePercent) {
            rarePart = 3;
        }
        if (
            rareRand > saleBoxs[_typeBox].partFourRarePercent &&
            rareRand <= saleBoxs[_typeBox].partThirdRarePercent
        ) {
            rarePart = 2;
        }

        if (
            rareRand > saleBoxs[_typeBox].partThirdRarePercent &&
            rareRand <= saleBoxs[_typeBox].partTwoRarePercent
        ) {
            rarePart = 1;
        }

        if (rareRand > saleBoxs[_typeBox].partTwoRarePercent) {
            rarePart = 0;
        }
        uint256 tokenId;

        tokenId = nft.getNextNFTId();
        nft.safeMintNFT(_msgSender(), tokenId);
        NFTItem memory nftItem = NFTItem(
            tokenId,
            "Zuki Assembly Part",
            rarePart,
            block.timestamp
        );
        nft.setNFTFactory(nftItem, tokenId);

        emit Sale(tokenId, _msgSender(), _amount, _typeBox);
    }

    /**
     * @dev Sale Gun
     */
    function _buyGun(uint256 _typeBox, uint256 _amount) internal {
        require(
            block.timestamp >= saleBoxs[_typeBox].startSale,
            "Sale has not started yet."
        );
        require(
            block.timestamp <= saleBoxs[_typeBox].endSale,
            "Sale already ended"
        );
        require(
            getNFTPrice(_typeBox) == _amount,
            "Amount of token sent is not correct."
        );
        require(
            nftToken.allowance(msg.sender, address(this)) >= _amount,
            "Token allowance too low"
        );
        require(msg.value == feeSale, "Amount of BNB sent is not correct.");
        nftToken.transferFrom(msg.sender, saleWallet, _amount);
        if (feeSale > 0) {
            feeWallet.transfer(feeSale);
        }
        randManager.randMod(_msgSender(), 10000);
        uint256 rareRand = randManager.currentRandMod();
        uint256 rarePart;

        if (rareRand <= saleBoxs[_typeBox].partFourRarePercent) {
            rarePart = 3;
        }
        if (
            rareRand > saleBoxs[_typeBox].partFourRarePercent &&
            rareRand <= saleBoxs[_typeBox].partThirdRarePercent
        ) {
            rarePart = 2;
        }

        if (
            rareRand > saleBoxs[_typeBox].partThirdRarePercent &&
            rareRand <= saleBoxs[_typeBox].partTwoRarePercent
        ) {
            rarePart = 1;
        }

        if (rareRand > saleBoxs[_typeBox].partTwoRarePercent) {
            rarePart = 0;
        }
        uint256 tokenId;
        tokenId = nft.getNextNFTId();
        nft.safeMintNFT(_msgSender(), tokenId);
        NFTItem memory nftItem = NFTItem(
            tokenId,
            "Zuki Gun",
            rarePart,
            block.timestamp
        );
        nft.setNFTFactory(nftItem, tokenId);
        emit Sale(tokenId, _msgSender(), _amount, _typeBox);
    }

    /**
     * @dev Sale Stone
     */
    function _buyStone(uint256 _typeBox, uint256 _amount) internal {
        require(
            block.timestamp >= saleBoxs[_typeBox].startSale,
            "Sale has not started yet."
        );
        require(
            block.timestamp <= saleBoxs[_typeBox].endSale,
            "Sale already ended"
        );
        require(
            getNFTPrice(_typeBox) == _amount,
            "Amount of token sent is not correct."
        );
        require(
            nftToken.allowance(msg.sender, address(this)) >= _amount,
            "Token allowance too low"
        );
        require(msg.value == feeSale, "Amount of BNB sent is not correct.");
        nftToken.transferFrom(msg.sender, saleWallet, _amount);
        if (feeSale > 0) {
            feeWallet.transfer(feeSale);
        }
        randManager.randMod(_msgSender(), 10000);
        uint256 rareRand = randManager.currentRandMod();
        uint256 rarePart;

        if (rareRand <= saleBoxs[_typeBox].partFourRarePercent) {
            rarePart = 3;
        }
        if (
            rareRand > saleBoxs[_typeBox].partFourRarePercent &&
            rareRand <= saleBoxs[_typeBox].partThirdRarePercent
        ) {
            rarePart = 2;
        }

        if (
            rareRand > saleBoxs[_typeBox].partThirdRarePercent &&
            rareRand <= saleBoxs[_typeBox].partTwoRarePercent
        ) {
            rarePart = 1;
        }

        if (rareRand > saleBoxs[_typeBox].partTwoRarePercent) {
            rarePart = 0;
        }
        uint256 tokenId;
        tokenId = nft.getNextNFTId();
        nft.safeMintNFT(_msgSender(), tokenId);
        NFTItem memory nftItem = NFTItem(
            tokenId,
            "Zuki Stone",
            rarePart,
            block.timestamp
        );
        nft.setNFTFactory(nftItem, tokenId);
        emit Sale(tokenId, _msgSender(), _amount, _typeBox);
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

    function getSaleStore(uint256 _typeBox)
        public
        view
        returns (SaleBox memory _saleStore)
    {
        return saleBoxs[_typeBox];
    }
}