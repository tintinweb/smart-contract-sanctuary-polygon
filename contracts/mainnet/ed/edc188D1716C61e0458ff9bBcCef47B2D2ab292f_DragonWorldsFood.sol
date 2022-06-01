pragma solidity ^ 0.8.0;

import "./SafeMath.sol";

interface IDragonWorlds
{
    function createNFT(address owner, bytes memory data) external returns (uint256);

    function createBatchNFT(address owner, uint256 num, bytes memory data) external returns (uint256[] memory);

    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) external;
}

interface IDragonWorldsVerifyTool
{
    function verifySign(uint256 id, address account, uint256[] memory data, bytes memory key) external returns (bool);
}

interface IMoneyToken
{
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function getOwner() external view returns (address);
}

interface IPlayToEarn
{
    function getOwner() external view returns (address);
}

interface IDRAGTokenCostDistribution
{
    function getCurContractAddress() external view returns (address);

    function getRatio() external view returns (uint256);

    function incrCostToken(uint256 amount) external;
}

import "./Pausable.sol";
import "./AccessControl.sol";

contract DragonWorldsFood is Pausable, AccessControl
{
    using SafeMath for uint256;

    IDragonWorlds private dragonWorlds;

    IDragonWorldsVerifyTool private dragonWorldsVerifyTool;

    IMoneyToken private dragToken;

    IMoneyToken private silvToken;

    IPlayToEarn private playToEarn;

    IDRAGTokenCostDistribution private tokenCost4;

    IDRAGTokenCostDistribution private tokenCost6;

    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address private chairman;

    struct Food
    {
        uint256 nftId;
        uint8 id;
    }

    struct FoodBag
    {
        Food[] foods;
        mapping (uint256 => uint256) indexes;
        mapping (uint256 => uint256) saleings;
    }

    struct BreedInfo
    {
        uint32 buildId;
        uint32 endAt;
        uint256 nftId;
        uint256 nftId1;
        uint256 nftId2;
    }

    mapping (address => FoodBag) private foodBags;

    mapping (address => BreedInfo[]) private beedInfos;

    event EventMintToChain(address sender, uint256[] data, uint256 result);

    event EventCostToken(address sender, uint256 id, uint256 uid, uint256 gold, uint256 silv);

    event EventCostFood(address sender, uint256 id, uint256 uid, uint256 foodType, uint256 foodNum);

    event EventBreedDragon(uint256 indexed nftId, uint256 indexed nftId1, uint256 indexed nftId2, address msgSender, uint256 gold, uint256 silv, uint256 buildId);

    constructor(address dragonWorldsAddress, address dragonWorldsVerifyToolAddress, address dragTokenAddress, address silvTokenAddress, address playEarnAddress, address cost4Address, address cost6Address) public
    {
        chairman = msg.sender;
        _setupRole(ADMIN_ROLE, chairman);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        dragonWorlds =  IDragonWorlds(dragonWorldsAddress);
        dragonWorldsVerifyTool = IDragonWorldsVerifyTool(dragonWorldsVerifyToolAddress);
        dragToken = IMoneyToken(dragTokenAddress);
        silvToken = IMoneyToken(silvTokenAddress);
        playToEarn = IPlayToEarn(playEarnAddress);
        tokenCost4 = IDRAGTokenCostDistribution(cost4Address);
        tokenCost6 = IDRAGTokenCostDistribution(cost6Address);
    }

    function getOwner() public view returns (address)
    {
        return chairman;
    }

    function setOwner(address owner) external
    {
        require(owner != address(0), "dragonworlds food: set owner address is 0");
        renounceRole(ADMIN_ROLE, chairman);
        chairman = owner;
        _setupRole(ADMIN_ROLE, chairman);
    }

    function removeFood(address owner, uint256 nftId) private returns (uint8)
    {
        uint256 curLen = foodBags[owner].indexes[nftId];
        if (curLen > 0)
        {
            uint256 maxLen = foodBags[owner].foods.length;
            Food memory food = foodBags[owner].foods[maxLen.sub(1)];
            if (curLen != maxLen)
            {
                foodBags[owner].foods[curLen.sub(1)] = food;
                foodBags[owner].indexes[food.nftId] = curLen;
            }
            foodBags[owner].foods.pop();
            delete foodBags[owner].indexes[nftId];
            return food.id;
        }
        delete foodBags[owner].saleings[nftId];
        return 0;
    }

    function addFood(address owner, uint256 nftId, uint8 id) private
    {
        foodBags[owner].foods.push(Food(nftId, id));
        foodBags[owner].indexes[nftId] = foodBags[owner].foods.length;
    }

    function mintToChain(uint256[] memory data, bytes memory key) external whenNotPaused
    {
        address msgSender = msg.sender;
        uint256 len = data.length;
        if (len < 2 || len % 2 != 0)
        {
            emit EventMintToChain(msgSender, data, 1);
            return;
        }
        require(dragonWorldsVerifyTool.verifySign(1, msgSender, data, key), "tochain verifysign error");
        uint256 goldNum = 0;
        uint256 silvNum = 0;
        uint256 nftType = 0;
        uint256 nftNum = 0;
        for (uint256 i = 0; i < len; i+=2)
        {
            uint256 id = data[i];
            uint256 num = data[i + 1];
            if (id == 1)
            {
                goldNum = goldNum.add(num);
            }
            else if (id == 2)
            {
                silvNum = silvNum.add(num);
            }
            else
            {
                nftType = id;
                nftNum = nftNum.add(num);
            }
        }
        if (goldNum > 0)
        {
            dragToken.transferFrom(playToEarn.getOwner(), msgSender, goldNum * (10 ** 18));
        }
        if (silvNum > 0)
        {
            silvToken.transferFrom(silvToken.getOwner(), msgSender, silvNum * (10 ** 18));
        }
        if (nftNum > 0)
        {
            uint256 index = 0;
            uint256[] memory nftIds = dragonWorlds.createBatchNFT(msgSender, nftNum, new bytes(0));
            for (uint256 i = 0; i < len; i+=2)
            {
                uint8 id = uint8(data[i]);
                if (!(id == 1 || id == 2))
                {
                    for (uint256 j = 0; j < data[i + 1]; j++)
                    {
                        addFood(msgSender, nftIds[index], id);
                        index = index.add(1);
                    }
                }
            }
        }
        // else if (nftNum > 0)
        // {
        //     addFood(msgSender, dragonWorlds.createNFT(msgSender, new bytes(0)), uint8(nftType));
        // }
        emit EventMintToChain(msgSender, data, 0);
    }

    function costToken(uint256 id, uint256 uid, uint256 gold, uint256 silv) external whenNotPaused
    {
        address msgSender = msg.sender;
        costToken(msgSender, gold, silv);
        emit EventCostToken(msgSender, id, uid, gold, silv);
    }

    function costToken(address account, uint256 gold, uint256 silv) private
    {
        uint256 goldAmount = gold * (10 ** 18);
        uint256 silvAmount = silv * (10 ** 18);
        require(dragToken.balanceOf(account) >= goldAmount,"gold number not enough");
        require(silvToken.balanceOf(account) >= silvAmount,"silv number not enough");
        if (gold > 0)
        {
            uint256 amount4 = (goldAmount.mul(tokenCost4.getRatio()).div(10000));
            uint256 amount6 = goldAmount.sub(amount4);
            dragToken.transferFrom(account, tokenCost4.getCurContractAddress(), amount4);
            dragToken.transferFrom(account, tokenCost6.getCurContractAddress(), amount6);
            tokenCost4.incrCostToken(amount4);
            tokenCost6.incrCostToken(amount6);
        }
        if (silv > 0)
        {
            silvToken.transferFrom(account, silvToken.getOwner(), silvAmount);
        }
    }

    function costFood(uint256 id, uint256 uid, uint256 foodType, uint256 foodNum) external whenNotPaused
    {
        require(foodNum > 0,"food number must be greater than 0.");
        address msgSender = msg.sender;
        Food[] memory foods = foodBags[msgSender].foods;
        uint256 len = foods.length;
        require(len >= foodNum,"food number not enough.");
        uint256[] memory burnNftIds = new uint256[](foodNum);
        uint256[] memory nums = new uint256[](foodNum);
        uint256 count = 0;
        for (uint256 i = 0; i < len; i++)
        {
            Food memory food = foods[i];
            uint256 nftId = food.nftId;
            if (food.id == foodType && foodBags[msgSender].saleings[nftId] == 0)
            {
                burnNftIds[count] = nftId;
                nums[count] = 1;
                count = count.add(1);
                if (count == foodNum)
                {
                    break;
                }
            }
        }
        require(count == foodNum,"food type number not enough.");
        dragonWorlds.burnBatch(msgSender, burnNftIds, nums);
        for (uint256 i = 0; i < foodNum; i++)
        {
            removeFood(msgSender, burnNftIds[i]);
        }
        emit EventCostFood(msgSender, id, uid, foodType, foodNum);
    }

    function getFoodNum(address owner, uint256 foodType, bool filterSale) public view returns (uint256)
    {
        if (foodType == 0 && !filterSale)
        {
            return foodBags[owner].foods.length;
        }
        uint256 count = 0;
        Food[] memory foods = foodBags[owner].foods;
        uint256 len = foods.length;
        for (uint256 i = 0; i < len; i++)
        {
            if ((foodType == 0 || foods[i].id == foodType) && (!filterSale || foodBags[owner].saleings[foods[i].nftId] == 0))
            {
                count = count.add(1);
            }
        }
        return count;
    }

    function isMaySaleFood(address owner, uint256[] memory nftIds) public view returns (bool)
    {
        uint256 len = nftIds.length;
        for (uint256 i = 0; i < len; i++)
        {
            uint256 nftId = nftIds[i];
            if (len > 1 && foodBags[owner].indexes[nftId] == 0)
            {
                return false;
            }
            if (foodBags[owner].saleings[nftId] > 0)
            {
                return false;
            }
        }
        return true;
    }

    function saleFood(address owner, uint256[] memory nftIds) public onlyRole(ADMIN_ROLE) returns (int8)
    {
        if (isMaySaleFood(owner, nftIds))
        {
            uint256 curLen = 0;
            uint256 len = nftIds.length;
            for (uint256 i = 0; i < len; i++)
            {
                uint256 nftId = nftIds[i];
                curLen = foodBags[owner].indexes[nftId];
                if (curLen > 0)
                {
                    foodBags[owner].saleings[nftId] = nftIds[0];
                }
            }
            if (len > 1)
            {
                curLen = foodBags[owner].indexes[nftIds[0]];
            }
            if (curLen > 0)
            {
                return int8(foodBags[owner].foods[curLen.sub(1)].id);
            }
            return 0;
        }
        return -1;
    }

    function tradeFoodSucce(address seller, address buyer, uint256[] memory nftIds) public onlyRole(ADMIN_ROLE)
    {
        for (uint256 i = 0; i < nftIds.length; i++)
        {
            uint256 nftId = nftIds[i];
            uint8 id = removeFood(seller, nftId);
            if (id > 0)
            {
                addFood(buyer, nftId, id);
            }
        }
    }

    function tradeFoodCancel(address owner, uint256[] memory nftIds) public onlyRole(ADMIN_ROLE)
    {
        for (uint256 i = 0; i < nftIds.length; i++)
        {
            delete foodBags[owner].saleings[nftIds[i]];
        }
    }

    function getFoodId(address owner, uint256 nftId) private view returns (uint8)
    {
        uint256 curLen = foodBags[owner].indexes[nftId];
        if (curLen > 0)
        {
            return foodBags[owner].foods[curLen.sub(1)].id;
        }
        return 0;
    }

    function getFoodType(address owner, uint256 nftId) public view returns (uint8)
    {
        return getFoodId(owner, nftId);
    }

    function getFoodTypes(address owner, uint256[] memory nftIds) public  view returns (uint8[] memory)
    {
        uint256 len = nftIds.length;
        uint8[] memory ids = new uint8[](len);
        for (uint256 i = 0; i < len; i++)
        {
            ids[i] = getFoodId(owner, nftIds[i]);
        }
        return ids;
    }

    function getPageFoods(address owner, uint256 page, uint256 max) public view returns (uint256 total, uint256 count, uint256[2][] memory arrays)
    {
        // total = foodBags[owner].foods.length;
        // uint256 skip = (page.sub(1)).mul(max);
        // count = max;
        // if (total.sub(skip) < max)
        // {
        //     count = total.sub(skip);
        // }
        // arrays = new uint256[2][](count);
        // for (uint256 i = 0; i < count; i++)
        // {
        //     uint256 index = i.add(skip);
        //     arrays[i][0] = foodBags[owner].foods[index].nftId;
        //     arrays[i][1] = foodBags[owner].foods[index].id;
        // }
        uint256 skip = (page.sub(1)).mul(max);
        arrays = new uint256[2][](max);
        uint256 len = foodBags[owner].foods.length;
        for (uint256 i = 0; i < len; i++)
        {
            uint256 nftId = foodBags[owner].foods[i].nftId;
            uint256 saleNftId = foodBags[owner].saleings[nftId];
            if ((saleNftId == 0) || (saleNftId == nftId))
            {
                total = total.add(1);
                if (skip > 0)
                {
                    skip = skip.sub(1);
                }
                else
                {
                    if (count < max)
                    {
                        arrays[count][0] = nftId;
                        arrays[count][1] = foodBags[owner].foods[i].id;
                        count = count.add(1);
                    }
                }
            }
        }
    }

    function isBreeding(address account, uint256 nftId) public view returns (bool)
    {
        BreedInfo[] memory infos = beedInfos[account];
        for (uint256 i = 0; i < infos.length; i++)
        {
            if ((block.timestamp <= infos[i].endAt) && (infos[i].nftId == nftId || infos[i].nftId1 == nftId || infos[i].nftId2 == nftId))
            {
                return true;
            }
        }
        return false;
    }

    function breed(uint256[] memory data, bytes memory key) external whenNotPaused
    {
        uint256 nftId1 = data[0];
        uint256 nftId2 = data[1];
        uint256 gold = data[2];
        uint256 silv = data[3];
        uint256 duration = data[4];
        uint256 buildId = data[5];
        address msgSender = msg.sender;
        uint256 len = beedInfos[msgSender].length;
        uint256 index = len;
        for (uint256 i = 0; i < len; i++)
        {
            if (beedInfos[msgSender][i].buildId == buildId)
            {
                index = i;
                break;
            }
        }
        require((index == len) || (index < len && block.timestamp > beedInfos[msgSender][index].endAt),"building is breeding.");
        require(!isBreeding(msgSender, nftId1) && !isBreeding(msgSender, nftId2),"dragon is breeding.");
        require(dragonWorldsVerifyTool.verifySign(2, msgSender, data, key),"breed verifysign error.");
        costToken(msgSender, gold, silv);
        uint256 nftId = dragonWorlds.createNFT(msgSender, new bytes(0));
        if (index == len)
        {
            beedInfos[msgSender].push(BreedInfo(uint32(buildId), uint32(block.timestamp.add(duration)), nftId, nftId1, nftId2));
        }
        else
        {
            beedInfos[msgSender][index].buildId = uint32(buildId);
            beedInfos[msgSender][index].endAt = uint32(block.timestamp.add(duration));
            beedInfos[msgSender][index].nftId = nftId;
            beedInfos[msgSender][index].nftId1 = nftId1;
            beedInfos[msgSender][index].nftId2 = nftId2;
        }
        emit EventBreedDragon(nftId, nftId1, nftId2, msgSender, gold, silv, buildId);
    }
}