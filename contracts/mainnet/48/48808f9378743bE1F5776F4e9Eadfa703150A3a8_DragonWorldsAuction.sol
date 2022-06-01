pragma solidity ^ 0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";

interface IDragonWorlds
{
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;

    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    function balanceOf(address account, uint256 id) external view returns (uint256);
}

interface IDragonWorldsFood
{
    function saleFood(address owner, uint256[] memory nftIds) external returns (int8);

    function tradeFoodSucce(address seller, address buyer, uint256[] memory nftIds) external;

    function tradeFoodCancel(address owner, uint256[] memory nftIds) external;

    function getFoodTypes(address owner, uint256[] memory nftIds) external view returns (uint8[] memory);

    function getPageFoods(address owner, uint256 page, uint256 max) external view returns (uint256, uint256, uint256[2][] memory);

    function isBreeding(address account, uint256 nftId) external view returns (bool);
}

import "./Pausable.sol";
import "./AccessControl.sol";

contract DragonWorldsAuction is Pausable, AccessControl
{
    using SafeMath for uint256;

    IDragonWorlds private dragonWorlds;

    IDragonWorldsFood private dragonWorldsFood;

    IERC20 private dragonToken;

    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address private chairman;

    uint256 private fee = 200;

    uint256 private withdrawFeeAmount;

    struct Auction
    {
        address seller;
        uint256 price;
        uint32 duration;
        uint32 startedAt;
        uint256[] nftIds;
    }

    mapping (uint256 => Auction) private auctions;

    event EventCreateAuction(uint256 indexed nftId, address seller, uint256 price, uint256 duration, uint256 total, uint8 id, uint256 curTime);

    event EventBuyAuctionSucce(uint256 indexed nftId, address buyer, address seller, uint256 price, uint256 curTime);

    event EventCancelAuction(uint256 indexed nftId);

    constructor(address dragonWorldsAddress, address dragonWorldsFoodAddress, IERC20 _dragonToken) public
    {
        chairman = msg.sender;
        _setupRole(ADMIN_ROLE, chairman);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        dragonWorlds =  IDragonWorlds(dragonWorldsAddress);
        dragonWorldsFood = IDragonWorldsFood(dragonWorldsFoodAddress);
        dragonToken = _dragonToken;
    }

    modifier max32Bits(uint256 _value)
    {
        require(_value <= 2147483647);
        _;
    }

    modifier max64Bits(uint256 _value)
    {
        require(_value <= 9223372036854775807);
        _;
    }

    function getOwner() public view returns (address)
    {
        return chairman;
    }

    function setOwner(address owner) external
    {
        require(owner != address(0), "dragonworlds auction: set owner address is 0");
        renounceRole(ADMIN_ROLE, chairman);
        chairman = owner;
        _setupRole(ADMIN_ROLE, chairman);
    }

    function setFee(uint256 value) external onlyRole(ADMIN_ROLE) whenNotPaused
    {
        fee = value;
    }

    function getWithdrawFreeAmount() public view returns (uint256)
    {
        return withdrawFeeAmount;
    }

    function getWithdrawableFeeAmount() public view returns (uint256)
    {
        return dragonToken.balanceOf(address(this));
    }

    function withdrawDragonTokenToWallet(uint256 amount) external whenNotPaused
    {
        address msgSender = msg.sender;
        require(chairman == msgSender, "withdraw cost token to wallet: no permission");
        uint256 total = getWithdrawableFeeAmount();
        require(total >= amount, "withdraw cost token to wallet: cost token not enough");
        withdrawFeeAmount = withdrawFeeAmount.add(amount);
        dragonToken.transfer(msgSender, amount);
    }

    function isInAuction(Auction memory auction) private view returns (bool)
    {
        return auction.startedAt > 0;
    }

    function isTimeOutAuction(Auction memory auction) private view returns (bool)
    {
        if (block.timestamp >= ((uint256)(auction.startedAt)).add((uint256)(auction.duration)))
        {
            return true;
        }
        return false;
    }

    function isNftValid(address owner, uint256 nftId) private
    {
        require(dragonWorlds.balanceOf(owner, nftId) == 1, "nft non-existent.");
        require(!isInAuction(auctions[nftId]), "nft auction already exists.");
    }

    function createAuction(uint256[] memory nftIds, uint256 price, uint256 duration) external whenNotPaused max64Bits(price) max32Bits(duration)
    {
        uint256 len = nftIds.length;
        require(len > 0 && len < 51, "nftid num error.");
        require(duration >= 1 minutes, "duration error.");
        address msgSender = msg.sender;
        uint256 nftId = nftIds[0];
        int8 id = 0;
        if (len == 1)
        {
            require(!(nftId == 1 || nftId == 2), "nft not can't be token.");
            isNftValid(msgSender, nftId);
            require(!dragonWorldsFood.isBreeding(msgSender, nftId), "nft breeding.");
            id = dragonWorldsFood.saleFood(msgSender, nftIds);
            require(id >= 0,"food already saleing.");
        }
        else
        {
            for (uint256 i = 0; i < len; i++)
            {
                nftId = nftIds[i];
                isNftValid(msgSender, nftId);
                for (uint256 j = i.add(1); j < len; j++)
                {
                    require(nftId != nftIds[j],"food nftid repeat.");
                }
            }
            id = dragonWorldsFood.saleFood(msgSender, nftIds);
            require(id > 0,"food package error.");
            nftId = nftIds[0];
        }
        auctions[nftId] = Auction(msgSender, price, (uint32)(duration), (uint32)(block.timestamp), nftIds);
        emit EventCreateAuction(nftId, msgSender, price, duration, len, uint8(id), block.timestamp);
    }

    function buyAuction(uint256 nftId) external whenNotPaused
    {
        Auction memory auction = auctions[nftId];
        require(isInAuction(auction), "nft auction non-existent.");
        address msgSender = msg.sender;
        require(msg.sender != auction.seller, "can't buy the goods self.");
        require(!isTimeOutAuction(auction), "nft auction invalid.");
        uint256 price = (auction.price).mul(1000000000000);
        require(dragonToken.balanceOf(msgSender) >= price, "dragon token not enough.");
        uint256 feeAmount = (price.mul(fee)).div(10000);
        dragonToken.transferFrom(msgSender, auction.seller, price.sub(feeAmount));
        dragonToken.transferFrom(msgSender, address(this), feeAmount);
        uint256[] memory nftIds = auction.nftIds;
        uint256 len = nftIds.length;
        address seller = auction.seller;
        if (len == 1)
        {
            dragonWorlds.safeTransferFrom(seller, msgSender, nftId, 1, new bytes(0));
        }
        else
        {
            uint256[] memory amounts = new uint256[](len);
            for (uint256 i = 0; i < len; i++)
            {
                amounts[i] = 1;
            }
            dragonWorlds.safeBatchTransferFrom(seller, msgSender, nftIds, amounts, new bytes(0));
        }
        delete auctions[nftId];
        dragonWorldsFood.tradeFoodSucce(seller, msgSender, nftIds);
        emit EventBuyAuctionSucce(nftId, msgSender, auction.seller, (uint256)(auction.price), block.timestamp);
    }

    function cancelAuction(uint256 nftId) external whenNotPaused
    {
        Auction memory auction = auctions[nftId];
        require(isInAuction(auction), "nft auction non-existent.");
        address msgSender = msg.sender;
        require(msgSender == auction.seller, "not permission.");
        delete auctions[nftId];
        dragonWorldsFood.tradeFoodCancel(msgSender, auction.nftIds);
        emit EventCancelAuction(nftId);
    }

    function getBagFoodsByPackageId(address account, uint256 nftId) external view returns (uint256[] memory, uint8[] memory)
    {
        uint256[] memory nftIds = auctions[nftId].nftIds;
        uint8[] memory ids = dragonWorldsFood.getFoodTypes(account, nftIds);
        return (nftIds, ids);
    }

    function getBagFoodsByPage(address account, uint256 page, uint256 max) external view returns (uint256 total, int256[5][] memory arrays)
    {
        uint256 total;
        uint256 size;
        uint256[2][] memory nftIdAndIds;
        (total, size, nftIdAndIds) = dragonWorldsFood.getPageFoods(account, page, max);
        int256[5][] memory arrays = new int256[5][](size);
        uint32 curTime = uint32(block.timestamp);
        for (uint256 i = 0; i < size; i++)
        {
            uint256 nftId = nftIdAndIds[i][0];
            Auction memory auction;
            if (auctions[nftId].startedAt > 0)
            {
                auction = auctions[nftId];
                arrays[i][2] = int32(auction.startedAt) + int32(auction.duration) - int32(curTime);
                arrays[i][3] = int256(auction.nftIds.length);
                arrays[i][4] = int256(auction.price);
            }
            else
            {
                arrays[i][2] = 0;
                arrays[i][3] = 1;
                arrays[i][4] = 0;
            }
            arrays[i][0] = int256(nftId);
            arrays[i][1] = int256(nftIdAndIds[i][1]);
        }
        return (total, arrays);
    }
}