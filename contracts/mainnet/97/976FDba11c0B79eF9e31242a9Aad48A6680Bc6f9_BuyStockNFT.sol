/**
 *Submitted for verification at polygonscan.com on 2022-04-29
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
    function mint(address to, uint256 tokenId, uint256 numberOfStock) external;
}

contract BuyStockNFT is Ownable {
    using SafeMath for uint256;

    address public receiver;
    IERC721 public immutable NFTContract;
    uint256 public buyCount;
    uint256 public newTokenID;

    uint256 public salesVolume;
    uint256 public pricePerStock;
    uint256 public purchaseLimit = 3000;

    event  BuyNFT(address indexed user, uint256 tokenID, uint256 numberOfStock);

    constructor(IERC721 _NFTContract, uint256 _pricePerStock) {
        NFTContract = _NFTContract;
        pricePerStock = _pricePerStock;
        receiver = msg.sender;
        newTokenID = 1;
    }

    fallback() external payable {}
    receive() external payable {
        buyNFT();
    }

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'BuyStockNFT: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function buyNFT() lock public payable {
        require(msg.value.mod(pricePerStock) == 0, "The amount of MATIC is incorrect.");

        uint256 salesVolumeAdd = msg.value.div(pricePerStock);
        uint256 minCount = salesVolumeAdd.mod(10);
        uint256 midCount = salesVolumeAdd.mod(100).div(10);
        uint256 maxCount = salesVolumeAdd.div(100);

        uint256 creatNumber = minCount.add(midCount).add(maxCount);
        require(creatNumber > 0, "You need pay enough MATIC.");
        require(salesVolume.add(salesVolumeAdd) <= purchaseLimit, "The purchase limit has been exceeded.");

        if (minCount > 0) {
            for (uint256 i = 0; i < minCount; i++) {
                NFTContract.mint(msg.sender, newTokenID + i, 1);
                emit BuyNFT(msg.sender, newTokenID + i, 1);
            }
        }

        if (midCount > 0) {
            for (uint256 i = 0; i < midCount; i++) {
                NFTContract.mint(msg.sender, newTokenID + minCount + i, 10);
                emit BuyNFT(msg.sender, newTokenID + minCount + i, 10);
            }
        }

        if (maxCount > 0) {
            for (uint256 i = 0; i < maxCount; i++) {
                NFTContract.mint(msg.sender, newTokenID + minCount + midCount + i, 100);
                emit BuyNFT(msg.sender, newTokenID + minCount + midCount + i, 100);
            }
        }

        buyCount = buyCount.add(creatNumber);
        newTokenID = newTokenID.add(creatNumber);
        salesVolume = salesVolume.add(salesVolumeAdd);
    }

    function buyMinNFT() lock public payable {
        require(msg.value.mod(pricePerStock) == 0, "The amount of MATIC is incorrect.");
        uint256 creatNumber = msg.value.div(pricePerStock);
        require(creatNumber > 0, "You need pay enough MATIC.");
        require(salesVolume.add(creatNumber) <= purchaseLimit, "The purchase limit has been exceeded.");

        for (uint256 i = 0; i < creatNumber; i++) {
            NFTContract.mint(msg.sender, newTokenID + i, 1);
            emit BuyNFT(msg.sender, newTokenID + i, 1);
        }

        buyCount = buyCount.add(creatNumber);
        newTokenID = newTokenID.add(creatNumber);
        salesVolume = salesVolume.add(creatNumber);
    }

    function buyMidNFT() lock public payable {
        require(msg.value.mod(pricePerStock * 10) == 0, "The amount of MATIC is incorrect.");
        uint256 creatNumber = msg.value.div(pricePerStock * 10);
        require(creatNumber > 0, "You need pay enough MATIC.");
        require(salesVolume.add(creatNumber * 10) <= purchaseLimit, "The purchase limit has been exceeded.");

        for (uint256 i = 0; i < creatNumber; i++) {
            NFTContract.mint(msg.sender, newTokenID + i, 10);
            emit BuyNFT(msg.sender, newTokenID + i, 10);
        }

        buyCount = buyCount.add(creatNumber);
        newTokenID = newTokenID.add(creatNumber);
        salesVolume = salesVolume.add(creatNumber * 10);
    }

    function buyMaxNFT() lock public payable {
        require(msg.value.mod(pricePerStock * 100) == 0, "The amount of MATIC is incorrect.");
        uint256 creatNumber = msg.value.div(pricePerStock * 100);
        require(creatNumber > 0, "You need pay enough MATIC.");
        require(salesVolume.add(creatNumber * 100) <= purchaseLimit, "The purchase limit has been exceeded.");

        for (uint256 i = 0; i < creatNumber; i++) {
            NFTContract.mint(msg.sender, newTokenID + i, 100);
            emit BuyNFT(msg.sender, newTokenID + i, 100);
        }

        buyCount = buyCount.add(creatNumber);
        newTokenID = newTokenID.add(creatNumber);
        salesVolume = salesVolume.add(creatNumber * 100);
    }

    function setNewTokenID(uint256 _newTokenID) public onlyOwner() {
        newTokenID = _newTokenID;
    }

    function setPricePerStock(uint256 _pricePerStock) public onlyOwner() {
        pricePerStock = _pricePerStock;
    }

    function setPurchaseLimit(uint256 _purchaseLimit) public onlyOwner() {
        purchaseLimit = _purchaseLimit;
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