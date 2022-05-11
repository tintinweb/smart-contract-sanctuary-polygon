// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../contracts/Const.sol";
import "../contracts/AddressResolverImpl.sol";
import "../contracts/Economics.sol";

import "../contracts/interfaces/ITerrainHolder.sol";
import "../contracts/interfaces/INftManager.sol";
import "../contracts/interfaces/ITycoon.sol";

// Staking demo
// https://github.com/gnufoo/ERC2917-Proposal

contract Tycoon is AddressResolverImpl, Initializable, Economics, ReentrancyGuardUpgradeable {
    bytes32 private constant CONTRACT_NFTMANAGER = "NftManager";
    bytes32 private constant CONTRACT_MARKETPLACE = "MarketPlace";
    bytes32 private constant CONTRACT_TERRAINHOLDER = "TerrainHolder";

    struct UserGameInfo {
        uint256 Xp;
        UserStakeInfo XpStaking;
    }

    mapping(address => UserGameInfo) private UserGameInfos;
    // Mapped NFT token to experience Req/Grants
    mapping(uint256 => Const.StakeRecordEntry) private ExperienceRecords;

    UserLevelDefinition[] private LevelDefs;

    function initialize(AddressResolver resolver) public initializer {
        __Ownable_init();

        Resolver = resolver;
    }

    function SetLevelDefs(UserLevelDefinition[] memory defs) external override onlyOwner {
        delete LevelDefs;
        for(uint n = 0; n < defs.length; n++) {
            LevelDefs.push(defs[n]);
        }
    }

    function GetLevelDefs() external view override returns (UserLevelDefinition[] memory) {
        return LevelDefs;
    }

    function BuyLand(uint32 sector, uint16 posx, uint16 posy) external override nonReentrant {
        /*uint256 token = */GetNftManagerContract().BuyLand(msg.sender, sector, posx,  posy);

        uint256 price = ObjectRequirements[Const.GO_LAND][Const.Resource_MainToken];

        GetMainTokenContract().transferFrom(msg.sender, address(this), price);
    }
    
    function Construct(uint32 sector, uint16 posx, uint16 posy, uint16 obj_type) external override nonReentrant {
        uint256 token = GetNftManagerContract().Build(msg.sender, sector, posx, posy, obj_type);

        // Ensure enough user level
        (uint256 user_level, ) = GetUserLevelXp(msg.sender);
        require(user_level >= ObjectRequirements[obj_type][Const.Resource_UserLevel], "User low level");

        // Update Experience staking
        UpdateStaking(UserGameInfos[msg.sender].XpStaking);
        if(ObjectGrants[obj_type][Const.Resource_Experience] > 0) {
            UserGameInfos[msg.sender].XpStaking.Amount += ObjectGrants[obj_type][Const.Resource_Experience];
            ExperienceRecords[token].Grants = ObjectGrants[obj_type][Const.Resource_Experience];
        }

        StakeForObject(msg.sender, user_level, 0, token, obj_type);     // Zero upgrade level
    }
    
    function Destroy(uint256 token) external override nonReentrant {
        INftManager nftManager = GetNftManagerContract();

        Const.GameObject memory object = nftManager.GetGameObject(token);
        Const.LandObject memory land = nftManager.GetLandObject(token);

        if(object.TileIdx > 0) {
            nftManager.Destroy(msg.sender, token);
 
            // Update Experience staking
            UpdateStaking(UserGameInfos[msg.sender].XpStaking);
            if(ExperienceRecords[token].Grants > 0)
                UserGameInfos[msg.sender].XpStaking.Amount -= ExperienceRecords[token].Grants;

            UnstakeForObject(msg.sender, token, object.Type);
        }
        else if(land.TileIdx > 0)
            GetNftManagerContract().RevokeLand(msg.sender, token);
        else
            revert("Invalid object to destory");
    }

    function UpgradeObject(uint256 token) external override nonReentrant {
        (bool success, uint256 obj_type, uint256 upgrade_level) = GetNftManagerContract().UpgradeObject(token);

        if(success) {
            (uint256 user_level, ) = GetUserLevelXp(msg.sender);

            uint256 cost = UpgradesCosts[user_level][upgrade_level];
         
            GetMainTokenContract().transferFrom(msg.sender, address(this), cost);
            
            UpgradeForObject(msg.sender, user_level, upgrade_level, token, obj_type);
        }
        else
            revert("Object cannot be upgraded!");
    }

    function TransferNftObject(address from, address to, uint256 token, uint256 obj_type) external override onlyNftManagerContract {
        (uint256 user_level, ) = GetUserLevelXp(to);
        Const.GameObject memory object = GetNftManagerContract().GetGameObject(token);

        TransferForObject(from, to, user_level, object.Level, token, obj_type);
    }

    function GetUserLevelXp(address to) internal view returns (uint256, uint256) {
        uint256 xp = UserGameInfos[to].Xp + CalcClaimAllInternal(UserGameInfos[to].XpStaking);

        for(uint n = 0; n < LevelDefs.length; n++) {
            if(xp < LevelDefs[n].PriceXp)
                return (n, xp);
        }

        // In case user has higher experiences than found in levels, it must be top level
        return (LevelDefs.length, xp);
    }

    function GetUserInfo(address to) external view override returns (UserGameReturnInfo memory info) {
        (uint256 level, uint256 xp) = GetUserLevelXp(to);
        uint256 xpnext;
        if(level < LevelDefs.length)
            xpnext = LevelDefs[level].PriceXp;
        else
            xpnext = 0;
        return UserGameReturnInfo ({
            Level: level,
            Xp: xp,
            Xp_Stake: UserGameInfos[to].XpStaking.Amount,
            XpNext: xpnext,
            Staking: GetStakingInfo(to)
        });
    }

    modifier onlyNftManagerContract {
        require(msg.sender == address(GetNftManagerContract()), "Only NftManager contract");
        _;
    }

    function GetMarketPlaceContract() internal view returns (IMarketPlace) {
        return IMarketPlace(Resolver.GetAddressAndRequire(CONTRACT_MARKETPLACE));
    }

    function GetNftManagerContract() internal view returns (INftManager) {
        return INftManager(Resolver.GetAddressAndRequire(CONTRACT_NFTMANAGER));
    }

    function GetTerrainHolderContract() internal view returns (ITerrainHolder) {
        return ITerrainHolder(Resolver.GetAddressAndRequire(CONTRACT_TERRAINHOLDER));
    }

    function GetContractAddresses() external view override returns (ITerrainHolder th, INftManager nft, IERC20Upgradeable main, IERC20Upgradeable reward, IMarketPlace marketplace, IResources resources) {
        return (GetTerrainHolderContract(), GetNftManagerContract(), GetMainTokenContract(), GetRewardTokenContract(), GetMarketPlaceContract(), GetResourcesContract());
    }

    // TODO, remove this before launch
    function DevMintTokens(address to) external onlyOwner {
        GetResourcesContract().Mint(to, Const.Resource_Wood, 1000 * 10**18);
        GetResourcesContract().Mint(to, Const.Resource_Wood_Processed, 1000 * 10**18);
        GetResourcesContract().Mint(to, Const.Resource_Tool, 1000 * 10**18);
        GetResourcesContract().Mint(to, Const.Resource_Stone, 1000 * 10**18);
        GetResourcesContract().Mint(to, Const.Resource_Machine, 1000 * 10**18);
        GetResourcesContract().Mint(to, Const.Resource_Oil, 1000 * 10**18);
        GetResourcesContract().Mint(to, Const.Resource_Chemistry, 1000 * 10**18);
        GetResourcesContract().Mint(to, Const.Resource_Coal, 1000 * 10**18);
        GetResourcesContract().Mint(to, Const.Resource_Energy, 1000 * 10**18);
        GetResourcesContract().Mint(to, Const.Resource_Food, 1000 * 10**18);

        GetRewardTokenContract().Mint(to, 1000 * 10**18);

        emit UserInfoChanged(to);
    }

    uint256[47] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../../contracts/interfaces/ITerrainHolder.sol";
import "../../contracts/interfaces/INftManager.sol";
import "../../contracts/interfaces/IRewardToken.sol";
import "../../contracts/interfaces/IMarketPlace.sol";
import "../../contracts/interfaces/IResources.sol";

interface ITycoon {

    struct UserLevelDefinition {
        uint256 PriceXp;
        uint256 PriceReward;
    }
    
    struct UserGameReturnInfo {
        uint256 Level;
        uint256 Xp;
        uint256 Xp_Stake;
        uint256 XpNext;
        Const.UserStakingInfo Staking;
    }

    function GetContractAddresses() external view returns (ITerrainHolder th, INftManager nft, IERC20Upgradeable main, IERC20Upgradeable reward, IMarketPlace marketplace, IResources resources);

    function SetLevelDefs(UserLevelDefinition[] memory defs) external;

    function GetLevelDefs() external view returns (UserLevelDefinition[] memory);

    function BuyLand(uint32 sector, uint16 posx, uint16 posy) external;
    
    function Construct(uint32 sector, uint16 posx, uint16 posy, uint16 obj_type) external;
    
    function Destroy(uint256 token) external;

    function UpgradeObject(uint256 token) external;

    function TransferNftObject(address from, address to, uint256 token, uint256 obj_type) external;

    function GetUserInfo(address to) external view returns (UserGameReturnInfo memory info);

    function CalcClaimAllReward(address to) external view returns(uint256);
    function ClaimAllRewardToken(address to) external;
    function ClaimAll(address to, uint256 resource) external;
    function CalcClaimAllResource(address to, uint256 token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev 
 */
interface ITerrainHolder {
    struct SectorData {
        // Position on map overview
        int16 PosX;
        int16 PosY;

        // Definition of sector
        uint16 Width;
        uint16 Height;
        uint8 TerrainType;
        bytes Landscape;
    }

    function GetTileIdx(uint32 sector_index, uint16 x, uint16 y) external view returns(uint16 tile_idx);
    function CanBuidl(uint32 sector_index, uint16 x, uint16 y) external view returns (uint16 tile_idx, uint8 ownable, uint8 building, uint8 tree, uint8 road);
    function GetSectorData(uint32 sector_index) external view returns (SectorData memory sector);
    function GetSectorSize(uint32 sector_index) external view returns (uint16 width, uint16 height);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "../../contracts/interfaces/IERC20Mintable.sol";
import "../../contracts/interfaces/ITycoon.sol";

interface IRewardToken is IERC20Mintable {
    function SetTycoonAddress(ITycoon tycoon) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

import "../../contracts/interfaces/ITycoon.sol";

interface IResources is IERC1155Upgradeable{
    function SetTycoonContractAddress(ITycoon addr) external;

    function Mint(address to, uint256 token, uint256 amount) external;

    function Burn(address to, uint256 token, uint256 amount) external;

    function EnsureEnoughToken(address to, uint256 token, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "../../contracts/Const.sol";
import "../../contracts/interfaces/ITerrainHolder.sol";

interface INftManager {
    function BuyLand(address to, uint32 sector, uint16 posx, uint16 posy) external returns (uint256);
    function Build(address to, uint32 sector, uint16 posx, uint16 posy, uint16 obj_type) external returns (uint256);
    
    function RevokeLand(address sender, uint256 token) external;
    function Destroy(address sender, uint256 token) external;
    
    function UpgradeObject(uint256 token) external returns (bool, uint256, uint256);

    function GetLandObject(uint256 token) external view returns (Const.LandObject memory);
    function GetGameObject(uint256 token) external view returns (Const.GameObject memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "../../contracts/interfaces/IResources.sol";
import "../../contracts/interfaces/IRewardToken.sol";
import "../../contracts/interfaces/ITycoon.sol";

interface IMarketPlace {

    struct OrderBook {
        address Owner;
        uint256 Token;
        uint256 UserArrayPosition;

        uint256 LowerPosition;
        uint256 HigherPosition;
        uint256 Position;
        uint256 Amount;

        uint256 UnitPrice;
    }

    struct Market {
        uint256 FirstOrder;
        uint256 Length;
    }

    struct ReadEntry {
        uint256 Position;
        uint256 Amount;
        uint256 UnitPrice;
    }

    function GetMarket(uint256 token) external view returns (Market memory market);

    function SellOrder(uint256 token, uint256 amount, uint256 unitprice) external;

    function BuyOrder(uint256 token, uint256 amount, uint256 unitprice, bool canpartial) external;

    function ChangeSellOrder(uint256 position, uint256 newamount) external;

    /// Orders returned are ordered as in contract
    function GetSellOrdersAll(uint256 token) external view returns (ReadEntry[] memory);

    /// Orders returned are NOT ordered
    function GetSellOrdersUser(address owner) external view returns (ReadEntry[] memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20Mintable is IERC20Upgradeable {
	function Mint(address to, uint256 amount) external;
	function Burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../contracts/interfaces/ITerrainHolder.sol";
import "../contracts/interfaces/INftManager.sol";
import "../contracts/interfaces/ITycoon.sol";

import "../contracts/AddressResolverImpl.sol";
import "../contracts/Const.sol";

abstract contract Economics is AddressResolverImpl, Initializable, ITycoon, OwnableUpgradeable {
    bytes32 internal constant CONTRACT_RESOURCES = "Resources";
    bytes32 internal constant CONTRACT_MAINTOKEN = "MainToken";
    bytes32 internal constant CONTRACT_REWARDTOKEN = "RewardToken";

    struct UserStakeInfo {
        uint256 LastRewardBlock;
        uint256 Amount;
        uint256 RewardDebt;
    }

    struct UserResourceInfo {
        uint256 ResidentialPower;
        uint256 ResidentialUsed;
        uint256 CulturalPower;
        uint256 CulturalUsed;
        mapping(uint256 => UserStakeInfo) Stake;
    }
    
    mapping(address => UserResourceInfo) internal ResourceInfos;

    mapping(uint256 => uint256[]) internal ObjectRequirements;
    mapping(uint256 => uint256[]) internal ObjectGrants;

    // When unstaking, we must revoke only originaly granted values, even actual values changed
    // So original values is stored to this super mapping
    // Mapped NFT token to resource to Req/Grants
    mapping(uint256 => mapping(uint256 => Const.StakeRecordEntry)) internal StakeRecords;

    // Object level to upgrade level
    // Cost required in MainToken
    uint256[][] internal UpgradesCosts;
    // Grants in whole numbers as increase
    uint256[][] internal UpgradesGrantsResidence;
    // Grants in percentage
    uint256[][] internal UpgradesGrantsOthers;

    event UserInfoChanged(address owner);

    function SetUpgradesCostsGrants(uint256[][] memory cost, uint256[][] memory grants, uint256[][] memory residence) external onlyOwner {
        delete UpgradesCosts;
        delete UpgradesGrantsOthers;
        delete UpgradesGrantsResidence;
        for(uint n = 0; n < cost.length; n++) {
            // +1 because final level is the level that can be achieved, so if max level 10, it is total 11 levels (from 0)
            uint256[] memory c_entry = new uint256[](Const.MAX_UPGRADE_LEVEL + 1);
            uint256[] memory g_entry = new uint256[](Const.MAX_UPGRADE_LEVEL + 1);
            uint256[] memory g_entry_res = new uint256[](Const.MAX_UPGRADE_LEVEL + 1);

            for(uint i = 0; i < Const.MAX_UPGRADE_LEVEL + 1; i++) {
                c_entry[i] = cost[n][i];
                g_entry[i] = grants[n][i];
                g_entry_res[i] = residence[n][i];
            }
            UpgradesCosts.push(c_entry);
            UpgradesGrantsOthers.push(g_entry);
            UpgradesGrantsResidence.push(g_entry_res);
        }
    }

    function GetUpgradesCostsGrants() external view returns (uint256[][] memory costs, uint256[][] memory grants, uint256[][] memory residence) {
        return (UpgradesCosts, UpgradesGrantsOthers, UpgradesGrantsResidence);
    }

    function SetObjectRequirements(uint256 obj, uint256[] memory req) public onlyOwner {
        delete ObjectRequirements[obj];
        ObjectRequirements[obj] = new uint256[](Const.Resource_MAX);
        for(uint n = 0; n < Const.Resource_MAX; n++)
            ObjectRequirements[obj][n] = req[n];
    }

    function SetObjectRequirementsBulk(uint256[] memory obj, uint256[][] memory req) external onlyOwner {
        for(uint n = 0; n < obj.length; n++)
            SetObjectRequirements(obj[n], req[n]);
    }

    function SetObjectGrants(uint256 obj, uint256[] memory grants) public onlyOwner {
        delete ObjectGrants[obj];
        ObjectGrants[obj] = new uint256[](Const.Resource_MAX);
        for(uint n = 0; n < Const.Resource_MAX; n++)
            ObjectGrants[obj][n] = grants[n];
    }

    function SetObjectGrantsBulk(uint256[] memory obj, uint256[][] memory grants) external onlyOwner {
        for(uint n = 0; n < obj.length; n++)
            SetObjectGrants(obj[n], grants[n]);
    }

    function GetObjectReqGrants() external view returns(uint256[] memory, Const.ReqGrantsReturnStruct[] memory, Const.ReqGrantsReturnStruct[] memory) {
        uint256 idx = 0;
        uint256[] memory ids = new uint256[](Const.TOTAL_OBJECT_COUNT);
        Const.ReqGrantsReturnStruct[] memory reqs = new Const.ReqGrantsReturnStruct[](Const.TOTAL_OBJECT_COUNT);
        Const.ReqGrantsReturnStruct[] memory grants = new Const.ReqGrantsReturnStruct[](Const.TOTAL_OBJECT_COUNT);

        for(uint n = Const.TALLOFFICE_00; n <= Const.TRANSMITTER; n++) {
            ids[idx] = n;
            reqs[idx] = Const.GetObjectReqGrantsSingle(ObjectRequirements[n]);
            grants[idx] = Const.GetObjectReqGrantsSingle(ObjectGrants[n]);
            idx++;
        }
        for(uint n = Const.BANK_NE; n <= Const.STEELMILL; n++) {
            ids[idx] = n;
            reqs[idx] = Const.GetObjectReqGrantsSingle(ObjectRequirements[n]);
            grants[idx] = Const.GetObjectReqGrantsSingle(ObjectGrants[n]);
            idx++;
        }
        ids[idx] = Const.GO_LAND;
        reqs[idx] = Const.GetObjectReqGrantsSingle(ObjectRequirements[Const.GO_LAND]);
        grants[idx] = Const.GetObjectReqGrantsSingle(ObjectGrants[Const.GO_LAND]);
        idx++;
        ids[idx] = Const.GO_ROAD;
        reqs[idx] = Const.GetObjectReqGrantsSingle(ObjectRequirements[Const.GO_ROAD]);
        grants[idx] = Const.GetObjectReqGrantsSingle(ObjectGrants[Const.GO_ROAD]);
        idx++;
        ids[idx] = Const.TREE_00;
        reqs[idx] = Const.GetObjectReqGrantsSingle(ObjectRequirements[Const.TREE_00]);
        grants[idx] = Const.GetObjectReqGrantsSingle(ObjectGrants[Const.TREE_00]);
        idx++;

        return (ids, reqs, grants);
    }

    function GetStakingInfo(address to) internal view returns (Const.UserStakingInfo memory info) {
        IResources resources = GetResourcesContract();

        // CalculateCulturalGrants will simulate 1BASE if no power applied
        uint256 cul_power = ResourceInfos[to].CulturalPower;
        if(cul_power == 0)
            cul_power = Const.BASE_UNIT;

        return Const.UserStakingInfo ({
            ResUsed: ResourceInfos[to].ResidentialUsed,
            ResPower: ResourceInfos[to].ResidentialPower,
            CulUsed: ResourceInfos[to].CulturalUsed,
            CulPower: cul_power,
            CulPercent: CalculateCulturalGrants(ResourceInfos[to]),
            Wood: resources.balanceOf(to, Const.Resource_Wood),
            Wood_Processed: resources.balanceOf(to, Const.Resource_Wood_Processed),
            Tools: resources.balanceOf(to, Const.Resource_Tool),
            Stone: resources.balanceOf(to, Const.Resource_Stone),
            Machines: resources.balanceOf(to, Const.Resource_Machine),
            Oil: resources.balanceOf(to, Const.Resource_Oil),
            Chemistry: resources.balanceOf(to, Const.Resource_Chemistry),
            Coal: resources.balanceOf(to, Const.Resource_Coal),
            Energy: resources.balanceOf(to, Const.Resource_Energy),
            Food: resources.balanceOf(to, Const.Resource_Food),

            Wood_Stake: ResourceInfos[to].Stake[Const.Resource_Wood].Amount,
            Wood_Processed_Stake: ResourceInfos[to].Stake[Const.Resource_Wood_Processed].Amount,
            Tools_Stake: ResourceInfos[to].Stake[Const.Resource_Tool].Amount,
            Stone_Stake: ResourceInfos[to].Stake[Const.Resource_Stone].Amount,
            Machines_Stake: ResourceInfos[to].Stake[Const.Resource_Machine].Amount,
            Oil_Stake: ResourceInfos[to].Stake[Const.Resource_Oil].Amount,
            Chemistry_Stake: ResourceInfos[to].Stake[Const.Resource_Chemistry].Amount,
            Coal_Stake: ResourceInfos[to].Stake[Const.Resource_Coal].Amount,
            Energy_Stake: ResourceInfos[to].Stake[Const.Resource_Energy].Amount,
            Food_Stake: ResourceInfos[to].Stake[Const.Resource_Food].Amount,
            Reward_Stake: ResourceInfos[to].Stake[Const.Resource_RewardToken].Amount
        });
    }

    // Update reward variables
    function UpdateStaking(UserStakeInfo storage stakeInfo) internal {
        if (block.number <= stakeInfo.LastRewardBlock)
            return;

        if (stakeInfo.Amount > 0) {
            uint256 multiplier = block.number - stakeInfo.LastRewardBlock;
            uint256 reward = multiplier * stakeInfo.Amount;
            stakeInfo.RewardDebt += reward;
        }
        stakeInfo.LastRewardBlock = block.number;
    }

    function CalcClaimAllInternal(UserStakeInfo memory stakeInfo) internal view returns (uint256) {
        if (block.number > stakeInfo.LastRewardBlock && stakeInfo.Amount > 0) {
            uint256 multiplier = block.number - stakeInfo.LastRewardBlock;
            uint256 reward = multiplier * stakeInfo.Amount;
            
            return stakeInfo.RewardDebt + reward;
        }
        return stakeInfo.RewardDebt;
    }

    function CalcClaimAllResource(address to, uint256 token) external view override returns (uint256) {
        UserStakeInfo memory stakeInfo = ResourceInfos[to].Stake[token];
        return CalcClaimAllInternal(stakeInfo);
    }

    /// Called from RewardToken
    function CalcClaimAllReward(address to) external view override returns(uint256) {
        return CalcClaimAllInternal(ResourceInfos[to].Stake[Const.Resource_RewardToken]);
    }

    function ClaimAllRewardTokenInternal(address to, UserResourceInfo storage userInfo) internal {
        UserStakeInfo storage stakeInfo = userInfo.Stake[Const.Resource_RewardToken];

        UpdateStaking(stakeInfo);

        uint256 to_pay = stakeInfo.RewardDebt;
        stakeInfo.RewardDebt = 0;
        GetRewardTokenContract().Mint(to, to_pay);
    }

    function ClaimAllRewardToken(address to) external override onlyRewardTokenContract {
        UserResourceInfo storage userInfo = ResourceInfos[to];

        ClaimAllRewardTokenInternal(to, userInfo);
    }

    function ClaimAllInternal(address to, uint256 resource) internal {
        UserStakeInfo storage stakeInfo = ResourceInfos[to].Stake[resource];

        UpdateStaking(stakeInfo);

        uint256 to_pay = stakeInfo.RewardDebt;
        stakeInfo.RewardDebt = 0;
        GetResourcesContract().Mint(to, resource, to_pay);
    }

    function ClaimAll(address to, uint256 resource) external override onlyResourcesContract {
        ClaimAllInternal(to, resource);
    }

    function CalculateCulturalGrants(UserResourceInfo storage userInfo) internal view returns (uint256) {
        // When user has zero power, calculate like he has one unit of power
        if(userInfo.CulturalPower == 0) {
            // Protection from zero division
            if(userInfo.CulturalUsed == 0)
                return Const.BASE_UNIT;

            return Const.BASE_UNIT / (userInfo.CulturalUsed / Const.BASE_UNIT);
        }

        // More power than used, return 100%
        if(userInfo.CulturalPower >= userInfo.CulturalUsed)
            return Const.BASE_UNIT;

        return userInfo.CulturalPower * Const.BASE_UNIT / userInfo.CulturalUsed;
    }

    function StakeForObjectReqs(address to, uint256 token, uint256 obj_type, bool spend) private {
        UserResourceInfo storage userInfo = ResourceInfos[to];
        IResources resources = GetResourcesContract();
        IRewardToken rewardToken = GetRewardTokenContract();
        IERC20Upgradeable mainToken = GetMainTokenContract();

        // 1) Spend or apply used resources
        uint256[] memory req = ObjectRequirements[obj_type];

        // 1.1) Apply residential requirement
        if(req[Const.Resource_Residential] > 0) {
            if(userInfo.ResidentialUsed + req[Const.Resource_Residential] > userInfo.ResidentialPower) {
                revert("Residential over limit!");
            }
            userInfo.ResidentialUsed += req[Const.Resource_Residential];
            StakeRecords[token][Const.Resource_Residential].Req = req[Const.Resource_Residential];
        }

        // 1.2) Apply cultural requirement
        if(req[Const.Resource_Cultural] > 0) {
            userInfo.CulturalUsed += req[Const.Resource_Cultural];
            StakeRecords[token][Const.Resource_Cultural].Req = req[Const.Resource_Cultural];
        }

        // Only if we want to spend all the required tokens
        if(spend) {
            // 1.3) Claim and spend resources
            for(uint256 source = Const.Resource_Wood; source <= Const.Resource_Food; source++) {
                if(req[source] > 0) {
                    ClaimAllInternal(to, source);

                    uint256 avail = resources.balanceOf(to, source);
                    require(avail >= req[source], "Missing resource!");
                    resources.Burn(to, source, req[source]);
                }
            }

            // 1.4) Claim and spend reward tokens
            if(req[Const.Resource_RewardToken] > 0) {
                ClaimAllRewardTokenInternal(to, userInfo);

                uint256 avail = rewardToken.balanceOf(to);
                require(avail >= req[Const.Resource_RewardToken], "Missing reward token!");
                rewardToken.Burn(to, req[Const.Resource_RewardToken]);
            }

            // 1.5) Claim and spend main tokens
            if(req[Const.Resource_MainToken] > 0) {
                uint256 avail = mainToken.balanceOf(to);
                require(avail >= req[Const.Resource_MainToken], "Missing main token!");
                mainToken.transferFrom(to, address(this), req[Const.Resource_MainToken]);
            }
        }
    }

    function StakeForObjectGrants(address to, uint256 user_level, uint256 upgrade_level, uint256 token, uint256 obj_type) private {
        UserResourceInfo storage userInfo = ResourceInfos[to];

        // 2) Apply stakings or add amounts
        uint256[] memory grants = ObjectGrants[obj_type];
        uint256 upgrade_grants_others = UpgradesGrantsOthers[user_level][upgrade_level];
        uint256 upgrade_grants_residence = UpgradesGrantsResidence[user_level][upgrade_level];

        // 2.1) Apply residential power
        if(grants[Const.Resource_Residential] > 0) {
            uint256 improv = grants[Const.Resource_Residential] + upgrade_grants_residence;
            userInfo.ResidentialPower += improv;
            StakeRecords[token][Const.Resource_Residential].Grants = improv;
        }

        // 2.2) Apply cultural power
        if(grants[Const.Resource_Cultural] > 0) {
            uint256 improv = Const.GetPercentMultiplyValue(grants[Const.Resource_Cultural], upgrade_grants_others);
            userInfo.CulturalPower += improv;
            StakeRecords[token][Const.Resource_Cultural].Grants = improv;
        }

        // input = 1000
        // power = 120
        // used = 20
        // output = 833,3
        // coef = ((power - used) * input) / power

        // TODO update cultural COEF
        // Apply cultural coef to upgrade_grants_others
        upgrade_grants_others = CalculateCulturalGrants(ResourceInfos[to]);

        // 2.3) Apply industry staking and commercial staking too (reward token)
        for(uint256 source = Const.Resource_Wood; source <= Const.Resource_RewardToken; source++) {
            if(grants[source] > 0) {
                UpdateStaking(userInfo.Stake[source]);
                uint256 improv = Const.GetPercentMultiplyValue(grants[source], upgrade_grants_others);
                userInfo.Stake[source].Amount += improv;
                StakeRecords[token][source].Grants = improv;
            }
        }
    }

    function UnstakeForObjectReqs(address to, uint256 token, uint256 /*obj_type*/) private {
        UserResourceInfo storage userInfo = ResourceInfos[to];

        // 1) Return used powers

        // 1.1) Return used residential
        if(StakeRecords[token][Const.Resource_Residential].Req > 0)
            userInfo.ResidentialUsed -= StakeRecords[token][Const.Resource_Residential].Req; // req[Const.Resource_Residential];

        // 1.2) Return used cultural
        if(StakeRecords[token][Const.Resource_Cultural].Req > 0)
            userInfo.CulturalUsed -= StakeRecords[token][Const.Resource_Cultural].Req; // req[Const.Resource_Cultural];
    }

    function UnstakeForObjectGrants(address to, uint256 token, uint256 /*obj_type*/) private {
        UserResourceInfo storage userInfo = ResourceInfos[to];

        // 2) Take applied grants

        // 2.1) Take residential power
        if(StakeRecords[token][Const.Resource_Residential].Grants > 0) {
            userInfo.ResidentialPower -= StakeRecords[token][Const.Resource_Residential].Grants; // grants[Const.Resource_Residential];

            // Residential power lowered, it may be too low
            require(userInfo.ResidentialUsed <= userInfo.ResidentialPower, "Residential power will be low!");
        }

        // 2.2) Take cultural power
        if(StakeRecords[token][Const.Resource_Cultural].Grants > 0)
            userInfo.CulturalPower -= StakeRecords[token][Const.Resource_Cultural].Grants; // grants[Const.Resource_Cultural];

        // 2.3) Take applied industry and commercial staking
        for(uint256 source = Const.Resource_Wood; source <= Const.Resource_RewardToken; source++) {
            if(StakeRecords[token][source].Grants > 0) {
                UpdateStaking(userInfo.Stake[source]);
                userInfo.Stake[source].Amount -= StakeRecords[token][source].Grants; // grants[source];
            }
        }
    }

    function StakeForObject(address to, uint256 user_level, uint256 upgrade_level, uint256 token, uint256 obj_type) internal {
        StakeForObjectReqs(to, token, obj_type, true);
        StakeForObjectGrants(to, user_level, upgrade_level, token, obj_type);

        emit UserInfoChanged(to);
    }

    function UnstakeForObject(address to, uint256 token, uint256 obj_type) internal {
        UnstakeForObjectGrants(to, token, obj_type);
        UnstakeForObjectReqs(to, token, obj_type);

        emit UserInfoChanged(to);
    }

    function UpgradeForObject(address to, uint256 user_level, uint256 upgrade_level, uint256 token, uint256 obj_type) internal {
        // Restake only grants as requirements was already counted
        UnstakeForObjectGrants(to, token, obj_type);
        StakeForObjectGrants(to, user_level, upgrade_level, token, obj_type);

        emit UserInfoChanged(to);
    }

    function TransferForObject(address from, address to, uint256 user_level, uint256 upgrade_level, uint256 token, uint256 obj_type) internal {
        UnstakeForObjectGrants(from, token, obj_type);
        UnstakeForObjectReqs(from, token, obj_type);

        // Here spend is false, in transfer to another user, do not want the required tokens from them
        StakeForObjectReqs(to, token, obj_type, false);
        StakeForObjectGrants(to, user_level, upgrade_level, token, obj_type);

        emit UserInfoChanged(from);
        emit UserInfoChanged(to);
    }

    modifier onlyResourcesContract {
        require(msg.sender == address(GetResourcesContract()), "Only Resources contract");
        _;
    }

    modifier onlyRewardTokenContract {
        require(msg.sender == address(GetRewardTokenContract()), "Only RewardToken contract");
        _;
    }

    function GetResourcesContract() internal view returns (IResources) {
        return IResources(Resolver.GetAddressAndRequire(CONTRACT_RESOURCES));
    }

    function GetRewardTokenContract() internal view returns (IRewardToken) {
        return IRewardToken(Resolver.GetAddressAndRequire(CONTRACT_REWARDTOKEN));
    }

    function GetMainTokenContract() internal view returns (IERC20Upgradeable) {
        return IERC20Upgradeable(Resolver.GetAddressAndRequire(CONTRACT_MAINTOKEN));
    }

    uint256[44] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

library Const {
    string constant TOKEN_REWARD_NAME       = "Simple Penny";
    string constant TOKEN_REWARD_TICKER     = "SIP";
    string constant TOKEN_MAIN_NAME         = "Simpleland";
    string constant TOKEN_MAIN_TICKER       = "SMPL";
    string constant TOKEN_NFT_NAME          = "Simpleland NFT";
    string constant TOKEN_NFT_TICKER        = "SMPL NFT";

    uint256 constant BASE_UNIT      = 1e18;

    uint16 constant LIST_PAGE_SIZE  = 512;

    uint16 constant MAX_UPGRADE_LEVEL = 10;
    
    uint8 constant Terrain_Temperate = 0;
    uint8 constant Terrain_Snow = 1;
    uint8 constant Terrain_Toyland = 2;

    uint8 constant ObjectType_None = 0;
    uint8 constant ObjectType_Residence = 1;
    uint8 constant ObjectType_Commercial = 2;
    uint8 constant ObjectType_Culture = 3;
    uint8 constant ObjectType_Industry = 4;

    uint16 constant TALLOFFICE_00		= 1;		// 1421
    uint16 constant OFFICE_01			= 2;		// 1426
    uint16 constant SMLBLCKFLATS_02	    = 3;		// 1430
    uint16 constant TEMPCHURCH		    = 4;		// 1434
    uint16 constant LARGEOFFICE_04	    = 5;		// 1440
    uint16 constant TOWNHOUSE_06		= 6;		// 1444
    uint16 constant HOTEL_07_NW		    = 7;		// 1448     // chained
    uint16 constant HORSERIDER_09		= 8;		// 1454
    uint16 constant FOUNTAIN_0A		    = 9;		// 1454
    uint16 constant PARKSTATUE_0B		= 10;		// 1456
    uint16 constant OFFICE_0D			= 11;		// 1458
    uint16 constant SHOPOFFICE_0E		= 12;		// 1461
    uint16 constant SHOPOFFICE_0F		= 13;		// 1464
    uint16 constant SHOPOFFICE_10		= 14;		// 1467
    uint16 constant POINTY_MODERN_11	= 15;		// 1470
    uint16 constant WAREHOUSE_12		= 16;		// 1473
    uint16 constant MODERN_WAREHOUSE_13	= 17;		// 1476
    uint16 constant STADIUM_N			= 18;		// 1479     // chained
    uint16 constant OLD_HOUSE_18		= 19;		// 1487
    uint16 constant OLD_HOUSE_19		= 20;		// 1489
    uint16 constant OLD_HOUSE_1A		= 21;		// 1491
    uint16 constant OLD_HOUSE_1B		= 22;		// 1493
    uint16 constant OLD_HOUSE_1C		= 23;		// 1495
    uint16 constant HOUSE_1D			= 24;		// 1497
    uint16 constant TOWNHOUSE_1E	    = 25;		// 1501
    uint16 constant TOWNHOUSE_1F		= 26;		// 1507
    uint16 constant TOWNHOUSE_20		= 27;		// 1513
    uint16 constant SMALL_FLATS_21		= 28;		// 1519
    uint16 constant SMALL_FLATS_22		= 29;		// 1524
    uint16 constant OFFICE_BLOCK_23		= 30;		// 1530
    uint16 constant OLD_FLATS_24		= 31;		// 1536
    uint16 constant OLD_FLATS_25		= 32;		// 1538
    uint16 constant OFFICE_BLOCK_26		= 33;		// 1540
    uint16 constant OFFICE_TOWER_27		= 34;		// 1546
    uint16 constant THEATRE_28			= 35;		// 1552
    uint16 constant STADIUM_N_V2		= 36;		// 1554     // chained
    uint16 constant MODERN_OFFICE_2D	= 37;		// 1562
    uint16 constant HOUSE_2E			= 38;		// 1570
    uint16 constant CINEMA_2F			= 39;		// 4404
    uint16 constant MALL_N_30			= 40;		// 4406     // chained
    uint16 constant LIGHTHOUSE      	= 41;
    uint16 constant TRANSMITTER			= 42;

    uint16 constant BANK_NE			    = 101;
    uint16 constant COAL_MINE		    = 102;
    uint16 constant FACTORY 		    = 103;
    uint16 constant FARM     		    = 104;
    uint16 constant FOREST     		    = 105;
    uint16 constant IRON_ORE   		    = 106;
    uint16 constant OIL_REFINERY	    = 107;
    uint16 constant OIL_WELL     	    = 108;
    uint16 constant POWER_STATION  	    = 109;
    uint16 constant SAWMILL     	    = 110;
    uint16 constant STEELMILL     	    = 111;

	uint16 constant Building_First      = TALLOFFICE_00;
	uint16 constant Building_Last       = TRANSMITTER;

	uint16 constant Industries_First      = BANK_NE;
	uint16 constant Industries_Last       = STEELMILL;

	uint16 constant TREE_00			= 1001;		// 1576
	uint16 constant TREE_01			= 1002;		// 1583
	uint16 constant TREE_02			= 1003;		// 1590
	uint16 constant TREE_03			= 1004;		// 1597
	uint16 constant TREE_04			= 1005;		// 1604
	uint16 constant TREE_05			= 1006;		// 1611
	uint16 constant TREE_06			= 1007;		// 1618
	uint16 constant TREE_07			= 1008;		// 1625
	uint16 constant TREE_08			= 1009;		// 1632
	uint16 constant TREE_09			= 1010;		// 1639
	uint16 constant TREE_0A			= 1011;		// 1646
	uint16 constant TREE_0B			= 1012;		// 1653
	uint16 constant TREE_0C			= 1013;		// 1660
	uint16 constant TREE_0D			= 1014;		// 1667
	uint16 constant TREE_0E			= 1015;		// 1674
	uint16 constant TREE_0F			= 1016;		// 1681
	uint16 constant TREE_10			= 1017;		// 1688
	uint16 constant TREE_11			= 1018;		// 1695
	uint16 constant TREE_12			= 1019;		// 1702

    uint16 constant TOTAL_OBJECT_COUNT       = 56;

	uint16 constant GO_LAND				= 1999;
	uint16 constant GO_ROAD             = 2000;
	
	uint16 constant GroupType_Building = 1;
    uint16 constant GroupType_Tree     = 2;
    uint16 constant GroupType_Road     = 3;
    
    uint16 constant MAX_GO_WIDTH        = 4;
    uint16 constant MAX_GO_HEIGHT       = 4;
    uint16 constant MAX_GO_SIZE         = MAX_GO_WIDTH * MAX_GO_HEIGHT;

    function GetObjectGroupType(uint16 itype) internal pure returns (uint16 otype) {
        if((itype >= TALLOFFICE_00 && itype <= TRANSMITTER) ||
        (itype >= BANK_NE && itype <= STEELMILL))
            return GroupType_Building;
        else if(itype >= TREE_00 && itype <= TREE_12)
            return GroupType_Tree;
        else if(itype == GO_ROAD)
            return GroupType_Road;
    }

    uint256 constant Resource_Residential       = 0;   // residential buildings
    uint256 constant Resource_Cultural          = 1;   // cultural buildings
    uint256 constant Resource_Wood              = 2;    // forest
    uint256 constant Resource_Wood_Processed    = 3;    // saw mill
    uint256 constant Resource_Tool              = 4;    // factory
    uint256 constant Resource_Stone             = 5;    // iron ore mine
    uint256 constant Resource_Machine           = 6;    // steel mill
    uint256 constant Resource_Oil               = 7;    // oil well
    uint256 constant Resource_Chemistry         = 8;    // refinery
    uint256 constant Resource_Coal              = 9;    // coal mine
    uint256 constant Resource_Energy            = 10;    // power station
    uint256 constant Resource_Food              = 11;   // farm
    uint256 constant Resource_RewardToken       = 12;   // commercial buildings
    uint256 constant Resource_MainToken         = 13;
    uint256 constant Resource_Experience        = 14;
    uint256 constant Resource_UserLevel         = 15;
    uint256 constant Resource_MAX               = 16;

    function GetStakingReward(uint256 obj) internal pure returns (uint256 amount) {
        if(obj == COAL_MINE)
            return 1;
        else if(obj == FACTORY)
            return 2;
        else if(obj == FARM)
            return 3;
        else if(obj == FOREST)
            return 4;
        else if(obj == IRON_ORE)
            return 5;
        else if(obj == OIL_REFINERY)
            return 6;
        else if(obj == OIL_WELL)
            return 7;
        else if(obj == POWER_STATION)
            return 8;
        else if(obj == SAWMILL)
            return 9;
        else if(obj == STEELMILL)
            return 10;
    }

    function GetObjectProperties(uint256 obj) internal pure returns (uint16 tilemask, uint8 group) {
        /* Level 0 *********************************************************************/
        // Residential
        if(obj == OLD_HOUSE_19)
            return (0x0001, ObjectType_Residence);
        else if(obj == OLD_HOUSE_1C)
            return (0x0001, ObjectType_Residence);
        // Commercial
        else if(obj == SHOPOFFICE_0F)
            return (0x0001, ObjectType_Commercial);
        else if(obj == OFFICE_0D)
            return (0x0001, ObjectType_Commercial);
        else if(obj == GO_ROAD)
            return (0x0001, ObjectType_Commercial);
        // Culture
        else if(obj == TEMPCHURCH)
            return (0x0001, ObjectType_Culture);
        else if(obj == FOUNTAIN_0A)
            return (0x0001, ObjectType_Culture);
        else if(obj == PARKSTATUE_0B)
            return (0x0001, ObjectType_Culture);
        else if(obj >= TREE_00 && obj <= TREE_12)
            return (0x0001, ObjectType_Culture);
        
        /* Level 1 *********************************************************************/
        // Residential
        else if(obj == OLD_HOUSE_1B)
            return (0x0001, ObjectType_Residence);
        else if(obj == HOUSE_1D)
            return (0x0001, ObjectType_Residence);
        else if(obj == OLD_HOUSE_18)
            return (0x0001, ObjectType_Residence);
        else if(obj == OLD_HOUSE_1A)
            return (0x0001, ObjectType_Residence);
        // Commercial
        else if(obj == SHOPOFFICE_10)
            return (0x0001, ObjectType_Commercial);
        else if(obj == SMALL_FLATS_22)
            return (0x0001, ObjectType_Commercial);
        else if(obj == OFFICE_TOWER_27)
            return (0x0001, ObjectType_Commercial);
        else if(obj == WAREHOUSE_12)
            return (0x0001, ObjectType_Commercial);
        // Culture
        else if(obj == MALL_N_30)
            return (0x0033, ObjectType_Culture);
        else if(obj == THEATRE_28)
            return (0x0001, ObjectType_Culture);
        else if(obj == HORSERIDER_09)
            return (0x0001, ObjectType_Culture);
        // Industry
        else if(obj == FACTORY)
            return (0x0033, ObjectType_Industry);
        else if(obj == FARM)
            return (0x0777, ObjectType_Industry);
        else if(obj == FOREST)
            return (0x0033, ObjectType_Industry);


        /* Level 2 *********************************************************************/
        // Residential
        else if(obj == HOUSE_2E)
            return (0x0001, ObjectType_Residence);
        else if(obj == TOWNHOUSE_06)
            return (0x0001, ObjectType_Residence);
        else if(obj == TOWNHOUSE_1E)
            return (0x0001, ObjectType_Residence);
        else if(obj == TOWNHOUSE_20)
            return (0x0001, ObjectType_Residence);
        else if(obj == TOWNHOUSE_1F)
            return (0x0001, ObjectType_Residence);
        else if(obj == SMLBLCKFLATS_02)
            return (0x0001, ObjectType_Residence);
        // Commercial
        else if(obj == SHOPOFFICE_0E)
            return (0x0001, ObjectType_Commercial);
        else if(obj == LARGEOFFICE_04)
            return (0x0001, ObjectType_Commercial);
        else if(obj == TALLOFFICE_00)
            return (0x0001, ObjectType_Commercial);
        else if(obj == OFFICE_01)
            return (0x0001, ObjectType_Commercial);
        // Cultural
        else if(obj == LIGHTHOUSE)
            return (0x0001, ObjectType_Culture);
        else if(obj == POINTY_MODERN_11)
            return (0x0001, ObjectType_Culture);
        else if(obj == CINEMA_2F)
            return (0x0001, ObjectType_Culture);
        // Industry
        else if(obj == SAWMILL)
            return (0x0777, ObjectType_Industry);
        else if(obj == OIL_WELL)
            return (0x0001, ObjectType_Industry);
        else if(obj == OIL_REFINERY)
            return (0x0777, ObjectType_Industry);
        else if(obj == STEELMILL)
            return (0x0033, ObjectType_Industry);

        /* Level 3 *********************************************************************/
        // Residential
        else if(obj == SMALL_FLATS_21)
            return (0x0001, ObjectType_Residence);
        else if(obj == OLD_FLATS_25)
            return (0x0001, ObjectType_Residence);
        // Commercial
        else if(obj == HOTEL_07_NW)
            return (0x0003, ObjectType_Commercial);
        else if(obj == OFFICE_BLOCK_26)
            return (0x0001, ObjectType_Commercial);
        else if(obj == MODERN_WAREHOUSE_13)
            return (0x0001, ObjectType_Commercial);
        // Culture
        else if(obj == BANK_NE)
            return (0x0011, ObjectType_Culture);
        else if(obj == TRANSMITTER)
            return (0x0001, ObjectType_Culture);
        // Industry
        else if(obj == POWER_STATION)
            return (0x0333, ObjectType_Industry);
        else if(obj == IRON_ORE)
            return (0xFFFF, ObjectType_Industry);
        else if(obj == COAL_MINE)
            return (0x0777, ObjectType_Industry);

        /* Level 4 *********************************************************************/
        // Residential
        else if(obj == OLD_FLATS_24)
            return (0x0001, ObjectType_Residence);
        // Commercial
        else if(obj == MODERN_OFFICE_2D)
            return (0x0001, ObjectType_Commercial);
        else if(obj == OFFICE_BLOCK_23)
            return (0x0001, ObjectType_Commercial);
        // Culture
        else if(obj == STADIUM_N)
            return (0x0033, ObjectType_Culture);
        else if(obj == STADIUM_N_V2)
            return (0x0033, ObjectType_Culture);

        else
            return (0, ObjectType_None);
    }
    
    struct ReqGrantsReturnStruct {
        uint256 Residential;
        uint256 Cultural;
        uint256 Wood;
        uint256 Wood_Processed;
        uint256 Tool;
        uint256 Stone;
        uint256 Machine;
        uint256 Oil;
        uint256 Chemistry;
        uint256 Coal;
        uint256 Energy;
        uint256 Food;
        uint256 RewardToken;
        uint256 MainToken;
        uint256 Experience;
        uint256 UserLevel;
    }

    function GetObjectReqGrantsSingle(uint256[] memory data) internal pure returns (ReqGrantsReturnStruct memory) {
        return ReqGrantsReturnStruct({
            Residential: data[Const.Resource_Residential],
            Cultural: data[Const.Resource_Cultural],
            Wood: data[Const.Resource_Wood],
            Wood_Processed: data[Const.Resource_Wood_Processed],
            Tool: data[Const.Resource_Tool],
            Stone: data[Const.Resource_Stone],
            Machine: data[Const.Resource_Machine],
            Oil: data[Const.Resource_Oil],
            Chemistry: data[Const.Resource_Chemistry],
            Coal: data[Const.Resource_Coal],
            Energy: data[Const.Resource_Energy],
            Food: data[Const.Resource_Food],
            RewardToken: data[Const.Resource_RewardToken],
            MainToken: data[Const.Resource_MainToken],
            Experience: data[Const.Resource_Experience],
            UserLevel: data[Const.Resource_UserLevel]
        });
    }

    function GetPercentMultiplyValue(uint256 value, uint256 percent) internal pure returns (uint256) {
        return value * percent / BASE_UNIT;
    }

    struct StakeRecordEntry {
        uint256 Req;
        uint256 Grants;
    }

    struct UserStakingInfo {
        uint256 ResUsed;
        uint256 ResPower;
        uint256 CulUsed;
        uint256 CulPower;
        uint256 CulPercent;
        uint256 Wood;
        uint256 Wood_Processed;
        uint256 Tools;
        uint256 Stone;
        uint256 Machines;
        uint256 Oil;
        uint256 Chemistry;
        uint256 Coal;
        uint256 Energy;
        uint256 Food;

        uint256 Wood_Stake;
        uint256 Wood_Processed_Stake;
        uint256 Tools_Stake;
        uint256 Stone_Stake;
        uint256 Machines_Stake;
        uint256 Oil_Stake;
        uint256 Chemistry_Stake;
        uint256 Coal_Stake;
        uint256 Energy_Stake;
        uint256 Food_Stake;
        uint256 Reward_Stake;
    }

    struct GameObject {
        uint32 Sector;
        uint16 TileIdx;
        uint16 Type;            // base type
        uint16 GroupType;      // type group
        uint16 Mask;
        uint16 ListPos;
        uint8 Level;
    }
    
    struct LandObject {
        uint32 Sector;
        uint16 TileIdx;
        uint8 Buildability;
        uint16 ListPos;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "../contracts/AddressResolver.sol";

abstract contract AddressResolverImpl {
    AddressResolver internal Resolver;

    function GetAddressAndRequire(bytes32 name) external view returns (address) {
        return Resolver.GetAddressAndRequire(name);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Heavily inspired from synthetix AddressResolver
contract AddressResolver is OwnableUpgradeable {
    mapping(bytes32 => address) public Repository;

    function initialize() public initializer {
        __Ownable_init();
    }

    function GetAddressAndRequire(bytes32 name) external view returns (address) {
        address target = Repository[name];
        require(target != address(0), string(abi.encodePacked("Missing address: ", name)));
        return target;
    }

    function SetAddress(bytes32 name, address target) external onlyOwner {
        Repository[name] = target;
    }

    uint256[49] __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal initializer {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}