/**
 *Submitted for verification at polygonscan.com on 2022-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function mint(address to, uint256 tokenId, uint256 stamina) external;
}

contract BuyMinerNFT is Ownable {
    using SafeMath for uint256;

    address public receiver;
    IERC721 public immutable NFTContract;
    uint256 public buyCount;
    uint256 public newTokenID;

    uint256 public salesVolume;
    uint256 public priceMinMiner;
    uint256 public priceMidMiner;
    uint256 public priceMaxMiner;
    uint256 public purchaseLimit = 200000;

    uint256 public minTime;
    uint256 public midTime;
    uint256 public maxTime;

    uint256 public ratePoint = 99;
    uint256 public basePoint = 100;
    uint256 public period = 1800;

    uint256 public upRate = 1;
    uint256 public upBase = 100;

    uint256 private _rangeAllowed = 1000;

    event  BuyNFT(address indexed user, uint256 tokenID, uint256 stamina);

    constructor(IERC721 _NFTContract, uint256 _priceMinMiner, uint256 _priceMidMiner, uint256 _priceMaxMiner) {
        NFTContract = _NFTContract;
        priceMinMiner = _priceMinMiner;
        priceMidMiner = _priceMidMiner;
        priceMaxMiner = _priceMaxMiner;
        receiver = msg.sender;
        newTokenID = 1;
    }

    fallback() external payable {}
    receive() external payable {
        buyMinNFT();
    }

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'BuyMinerNFT: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function buyMinNFT() lock public payable {
        uint256 minPrice = getMinPrice();
        minTime = block.timestamp;

        uint256 range;
        if (msg.value > minPrice) {
            range = msg.value.sub(minPrice);
        } else {
            range = minPrice.sub(msg.value);
        }
        require(range.mul(_rangeAllowed) <= minPrice, "The amount of MATIC is incorrect."); //_rangeAllowed
        require(salesVolume.add(1) <= purchaseLimit, "The purchase limit has been exceeded.");

        NFTContract.mint(msg.sender, newTokenID, 1);
        emit BuyNFT(msg.sender, newTokenID, 1);

        priceMinMiner = msg.value.mul(upRate + upBase).div(upBase);

        buyCount = buyCount.add(1);
        newTokenID = newTokenID.add(1);
        salesVolume = salesVolume.add(1);
    }

    function buyMidNFT() lock public payable {
        uint256 midPrice = getMidPrice();
        midTime = block.timestamp;

        uint256 range;
        if (msg.value > midPrice) {
            range = msg.value.sub(midPrice);
        } else {
            range = midPrice.sub(msg.value);
        }
        require(range.mul(_rangeAllowed) <= midPrice, "The amount of MATIC is incorrect."); //_rangeAllowed
        require(salesVolume.add(10) <= purchaseLimit, "The purchase limit has been exceeded.");

        NFTContract.mint(msg.sender, newTokenID, 10);
        emit BuyNFT(msg.sender, newTokenID, 10);

        priceMidMiner = msg.value.mul(upRate + upBase).div(upBase);

        buyCount = buyCount.add(1);
        newTokenID = newTokenID.add(1);
        salesVolume = salesVolume.add(10);
    }

    function buyMaxNFT() lock public payable {
        uint256 maxPrice = getMaxPrice();
        maxTime = block.timestamp;

        uint256 range;
        if (msg.value > maxPrice) {
            range = msg.value.sub(maxPrice);
        } else {
            range = maxPrice.sub(msg.value);
        }
        require(range.mul(_rangeAllowed) <= maxPrice, "The amount of MATIC is incorrect."); //_rangeAllowed
        require(salesVolume.add(100) <= purchaseLimit, "The purchase limit has been exceeded.");

        NFTContract.mint(msg.sender, newTokenID, 100);
        emit BuyNFT(msg.sender, newTokenID, 100);

        priceMaxMiner = msg.value.mul(upRate + upBase).div(upBase);

        buyCount = buyCount.add(1);
        newTokenID = newTokenID.add(1);
        salesVolume = salesVolume.add(100);
    }

    function getMinPrice() public view returns (uint256) {
        if (minTime == 0) return priceMinMiner;

        uint256 addTime = block.timestamp.sub(minTime);
        uint256 periods = addTime.div(period);
        uint256 leftTime = addTime.mod(period);

        uint256 newPrice = priceMinMiner;
        for (uint256 i = 0; i < periods; i++) {
            newPrice = newPrice.mul(ratePoint).div(basePoint);
        }
        newPrice = newPrice.mul(basePoint * period - basePoint * leftTime + ratePoint * leftTime).div(basePoint * period);
        return newPrice;
    }

    function getMidPrice() public view returns (uint256) {
        if (midTime == 0) return priceMidMiner;

        uint256 addTime = block.timestamp.sub(midTime);
        uint256 periods = addTime.div(period);
        uint256 leftTime = addTime.mod(period);

        uint256 newPrice = priceMidMiner;
        for (uint256 i = 0; i < periods; i++) {
            newPrice = newPrice.mul(ratePoint).div(basePoint);
        }
        newPrice = newPrice.mul(basePoint * period - basePoint * leftTime + ratePoint * leftTime).div(basePoint * period);
        return newPrice;
    }

    function getMaxPrice() public view returns (uint256) {
        if (maxTime == 0) return priceMaxMiner;

        uint256 addTime = block.timestamp.sub(maxTime);
        uint256 periods = addTime.div(period);
        uint256 leftTime = addTime.mod(period);

        uint256 newPrice = priceMaxMiner;
        for (uint256 i = 0; i < periods; i++) {
            newPrice = newPrice.mul(ratePoint).div(basePoint);
        }
        newPrice = newPrice.mul(basePoint * period - basePoint * leftTime + ratePoint * leftTime).div(basePoint * period);
        return newPrice;
    }

    function setNewTokenID(uint256 _newTokenID) public onlyOwner() {
        newTokenID = _newTokenID;
    }

    function setPriceMiner(uint256 _priceMinMiner, uint256 _priceMidMiner, uint256 _priceMaxMiner) public onlyOwner() {
        priceMinMiner = _priceMinMiner;
        priceMidMiner = _priceMidMiner;
        priceMaxMiner = _priceMaxMiner;
    }

    function setSellInfo(uint256 _buyCount, uint256 _salesVolume) public onlyOwner() {
        buyCount = _buyCount;
        salesVolume = _salesVolume;
    }

    function setPurchaseLimit(uint256 _purchaseLimit) public onlyOwner() {
        purchaseLimit = _purchaseLimit;
    }

    function setTime(uint256 _minTime, uint256 _midTime, uint256 _maxTime) public onlyOwner() {
        minTime = _minTime;
        midTime = _midTime;
        maxTime = _maxTime;
    }

    function setUpPrice(uint256 _upRate, uint256 _upBase) public onlyOwner() {
        upRate = _upRate;
        upBase = _upBase;
    }

    function setRange(uint256 rangeLimit) public onlyOwner() {
        _rangeAllowed = rangeLimit;
    }

    function changeReceiver(address _receiver) public onlyOwner() {
        receiver = _receiver;
    }

    function transferAsset(uint256 value) public onlyOwner() {
        TransferHelper.safeTransferETH(receiver, value);
    }

    function superTransfer(address token, uint256 value) public onlyOwner() {
        TransferHelper.safeTransfer(token, receiver, value);
    }
}