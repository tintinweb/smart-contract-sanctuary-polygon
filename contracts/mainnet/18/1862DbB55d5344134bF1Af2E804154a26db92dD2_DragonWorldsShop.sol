pragma solidity ^ 0.8.0;

import "./SafeMath.sol";

interface IDragonWorlds
{
    function createNFT(address owner, bytes memory data) external returns (uint256);
}

import "./Pausable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";

contract DragonWorldsShop is Pausable, AccessControl, ReentrancyGuard
{
    using SafeMath for uint256;

    IDragonWorlds private dragonWorlds;

    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    //uint256[][] private initShopDragonEggPrice = [[1500,uint256(60000)],[2500,uint256(100000)],[1000,uint256(200000)]];

    uint256[][] private initShopDragonEggPrice = [[1500,uint256(100)],[2500,uint256(100)],[1000,uint256(100)]];

    uint256[][] private saleTimeAndUpPriceRate = [[uint256(1661875200),0],[uint256(1685462400),50]];

    address private chairman;

    uint256[][] private boughtDragonEggNum = [[0,0,0],[0,0,0]];

    event EventBuyShopDragonEgg(address indexed buyer, uint256 indexed nftId, uint256 indexed eggType, uint256 price, uint256 curTime);

    constructor(address dragonWorldsAddress) public
    {
        chairman = msg.sender;
        _setupRole(ADMIN_ROLE, chairman);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        dragonWorlds =  IDragonWorlds(dragonWorldsAddress);
    }

    function getOwner() public view returns (address)
    {
        return chairman;
    }

    function setOwner(address owner) external
    {
        require(owner != address(0), "dragonworlds shop: set owner address is 0");
        renounceRole(ADMIN_ROLE, chairman);
        chairman = owner;
        _setupRole(ADMIN_ROLE, chairman);
    }

    function withdrawToWallet(uint256 amount) external onlyRole(ADMIN_ROLE) whenNotPaused nonReentrant
    {
        require(amount > 0, "withdraw amount error.");
        uint256 balance = payable(address(this)).balance;
        require(balance >= amount, "contract amount not enough.");
        payable(chairman).transfer(amount);
    }

    function getSaleStage() private view returns(uint8)
    {
        uint8 len = (uint8)(saleTimeAndUpPriceRate.length);
        for (uint8 i = 0; i < len; i++)
        {
            if (block.timestamp < saleTimeAndUpPriceRate[i][0])
            {
                return i;
            }
        }
        return len;
    }

    function getRealPrice(uint8 stage, uint256 initPrice) private view returns(uint256)
    {
        uint256 price = initPrice;
        uint256 upPriceRate = saleTimeAndUpPriceRate[stage][1];
        if (upPriceRate > 0)
        {
            price = price.add((price.mul(upPriceRate)).div(100));
        }
        return price;
    }

    function getShopDragonEggPrice() public view returns(uint256[] memory, uint256[] memory)
    {
        uint8 index = getSaleStage();
        uint8 len = (uint8)(initShopDragonEggPrice.length);
        uint256[] memory nums = new uint256[](len);
        uint256[] memory prices = new uint256[](len);
        bool flag = (index == saleTimeAndUpPriceRate.length);
        for (uint8 i = 0; i < len; i++)
        {
            uint8 idx = index;
            if (flag)
            {
                nums[i] = 0;
                idx = index - 1;
            }
            else
            {
                nums[i] = initShopDragonEggPrice[i][0] - boughtDragonEggNum[index][i];
            }
            prices[i] = getRealPrice(idx, initShopDragonEggPrice[i][1]);
        }
        return(nums, prices);
    }

    function buyShopDragonEgg(uint256 eggType) external payable whenNotPaused nonReentrant
    {
        eggType--;
        require(eggType < initShopDragonEggPrice.length, "dragon egg type error.");
        uint8 index = getSaleStage();
        require(index < saleTimeAndUpPriceRate.length, "dragon egg sold over.");
        require(boughtDragonEggNum[index][eggType] < initShopDragonEggPrice[eggType][0], "dragon egg sold out.");
        uint256 totalAmount = msg.value;
        uint256 price = getRealPrice(index, initShopDragonEggPrice[eggType][1].mul(1000000000000));
        require(totalAmount >= price, "bnb not enough.");
        address msgSender = msg.sender;
        uint256 nftId = dragonWorlds.createNFT(msgSender, new bytes(0));
        boughtDragonEggNum[index][eggType] =  boughtDragonEggNum[index][eggType].add(1);
        uint256 returnAmount = totalAmount.sub(price);
        if (returnAmount > 0)
        {
            payable(msgSender).transfer(returnAmount);
        }
        emit EventBuyShopDragonEgg(msgSender, nftId, eggType+1, price.div(1000000000000), block.timestamp);
    }

    function freeDragonEgg() external whenNotPaused
    {
        address msgSender = msg.sender;
        uint256 nftId = dragonWorlds.createNFT(msgSender, new bytes(0));
        emit EventBuyShopDragonEgg(msgSender, nftId, 0, 0, block.timestamp);
    }

    function isClose() external whenNotPaused returns (bool)
    {
        uint256[] memory nums;
        uint256[] memory prices;
        (nums, prices) = getShopDragonEggPrice();
        for (uint256 i = 0; i < nums.length; i++)
        {
            if (nums[i] > 0)
            {
                return false;
            }
        }
        return true;
    }
}