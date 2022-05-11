// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../contracts/Const.sol";
import "../contracts/AddressResolverImpl.sol";
import "../contracts/interfaces/ITerrainHolder.sol";
import "../contracts/interfaces/INftManager.sol";
import "../contracts/interfaces/ITycoon.sol";

contract NftManager is AddressResolverImpl, Initializable, ERC721EnumerableUpgradeable, INftManager, OwnableUpgradeable {
    bytes32 private constant CONTRACT_TYCOON = "Tycoon";
    bytes32 private constant CONTRACT_TERRAINHOLDER = "TerrainHolder";

    uint8 private constant BUILD_BIT_BUILDING	= 0;
	uint8 private constant BUILD_BIT_TREE		= 1;
	uint8 private constant BUILD_BIT_ROAD  	    = 2;

    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct ReturnLandObject {
        address Owner;
        uint256 Token;
        Const.LandObject Object;
    }

    struct ReturnGameObject {
        address Owner;
        uint256 Token;
        Const.GameObject Object;
    }

    CountersUpgradeable.Counter private TokenIdTracker;

    bool private BlockCheckTransferMultiple;

    /// @dev Land definition for token ID
    mapping(uint256 => Const.LandObject) private LandObjectsList;
    /// @dev Game object definition for token ID
    mapping(uint256 => Const.GameObject) private GameObjectsList;

    mapping(uint32 => mapping(uint16 => uint256)) private LandPositionMap;
    mapping(uint32 => uint16[]) private LandPositionList;
    
    mapping(uint32 => mapping(uint16 => uint256)) private GameObjectPositionMap;
    mapping(uint32 => uint16[]) private GameObjectPositionList;
    
    // Event is used for both land and game object change on tile
    event TileChanged(uint32 sector, uint16 tile_idx);

    function initialize(AddressResolver resolver) public initializer {
        __ERC721_init(Const.TOKEN_NFT_NAME, Const.TOKEN_NFT_TICKER);
        __Ownable_init();

        Resolver = resolver;

        BlockCheckTransferMultiple = false;
        
        // TokenId is used in mapping and must be from 1 to distinguish empty entry in mapping
        // This ensure that TokenId is from 1, not 0
        TokenIdTracker.increment();
    }

    function BuyLand(address to, uint32 sector, uint16 posx, uint16 posy) external override onlyTycoonContract returns (uint256) {
        (uint16 tile_idx, uint8 can_own, uint8 can_building, uint8 can_tree, uint8 can_road) = GetTerrainHolderContract().CanBuidl(sector, posx, posy);

        // Requirements
        require(LandPositionMap[sector][tile_idx] == 0, "Land already owned!");
        require(can_own == 1, "Land can't be owned!");

        uint256 token = TokenIdTracker.current();
        _mint(to, token);
        TokenIdTracker.increment();

        // assign object properties to token ID  
        Const.LandObject memory object = Const.LandObject({
            TileIdx: tile_idx,
            Sector: sector,
            Buildability: can_building << BUILD_BIT_BUILDING | can_tree << BUILD_BIT_TREE | can_road << BUILD_BIT_ROAD,
            ListPos: uint16(LandPositionList[sector].length)
        });
        LandObjectsList[token] = object;
        
        // assign token ID to tile_idx on sector
        LandPositionMap[sector][tile_idx] = token;
        // add tile_idx to sector list
        LandPositionList[sector].push(tile_idx);

        emit TileChanged(sector, tile_idx);

        return token;
    }

    function CheckRoadPlacement(ITerrainHolder th, uint32 sector, uint16 x, uint16 y) internal view {
        uint256 token1 = GameObjectPositionMap[sector][th.GetTileIdx(sector, x - 1, y)];
        uint256 token2 = GameObjectPositionMap[sector][th.GetTileIdx(sector, x, y - 1)];
        uint256 token3 = GameObjectPositionMap[sector][th.GetTileIdx(sector, x + 1, y)];
        uint256 token4 = GameObjectPositionMap[sector][th.GetTileIdx(sector, x, y + 1)];

        if(GameObjectsList[token1].GroupType == Const.GroupType_Road ||
            GameObjectsList[token1].GroupType == Const.GroupType_Building ||
            GameObjectsList[token2].GroupType == Const.GroupType_Road ||
            GameObjectsList[token2].GroupType == Const.GroupType_Building ||
            GameObjectsList[token3].GroupType == Const.GroupType_Road ||
            GameObjectsList[token3].GroupType == Const.GroupType_Building ||
            GameObjectsList[token4].GroupType == Const.GroupType_Road ||
            GameObjectsList[token4].GroupType == Const.GroupType_Building)
            {}
            else revert("No road possible");
    }

    function Build(address to, uint32 sector, uint16 posx, uint16 posy, uint16 obj_type) external override onlyTycoonContract returns (uint256) {
        ITerrainHolder terrainHolder = GetTerrainHolderContract();
        (uint16 mask, ) = Const.GetObjectProperties(obj_type);
        uint16 first_tile_idx;
        uint16 grouptype = Const.GetObjectGroupType(obj_type);
        
        {
            for(uint16 n = 0; n < 16; n++) {
                if(mask & (1 << n) == (1 << n)) {
                    uint16 tile_idx = terrainHolder.GetTileIdx(sector, posx + n % 4, posy + n / 4);
                    if(n == 0)
                        first_tile_idx = tile_idx;
                    
                    // Requirements
                    require(GameObjectPositionMap[sector][tile_idx] == 0, "Land has building already!");
                    uint256 landtoken = LandPositionMap[sector][tile_idx];
                    if(landtoken != 0)
                        require(ownerOf(landtoken) == to, "Land not yours!");
                    else
                        revert("Land not yours!");
                    
                    Const.LandObject memory land = LandObjectsList[landtoken];
        
                    if(grouptype == Const.GroupType_Building)
                        require((land.Buildability >> BUILD_BIT_BUILDING) & 1 == 1, "Minting on invalid tile!");
                    else if(grouptype == Const.GroupType_Tree) {
                        require((land.Buildability >> BUILD_BIT_TREE) & 1 == 1, "Minting on invalid tile!");
                        // Randomize tree object so it looks different but stored on blockchain
                        obj_type = uint16(Const.TREE_00 + block.number % ((Const.TREE_12 - Const.TREE_00) + 1));
                    }
                    else if(grouptype == Const.GroupType_Road) {
                        require((land.Buildability >> BUILD_BIT_ROAD) & 1 == 1, "Minting on invalid tile!");
                        CheckRoadPlacement(terrainHolder, sector, posx, posy);
                    }
                }
            }
        }

        uint256 token = TokenIdTracker.current();
        _mint(to, token);
        TokenIdTracker.increment();

        // assign object properties to token ID  
        Const.GameObject memory object = Const.GameObject({
            Type: obj_type,
            GroupType: grouptype,
            TileIdx: first_tile_idx,
            Sector: sector,
            Mask: mask,
            ListPos: uint16(GameObjectPositionList[sector].length),
            Level: 0
        });
        GameObjectsList[token] = object;
        //add tile_idx to sector list
        GameObjectPositionList[sector].push(first_tile_idx);

        for(uint16 n = 0; n < 16; n++) {
            if(mask & (1 << n) == (1 << n)) {
                uint16 tile_idx = terrainHolder.GetTileIdx(sector, posx + n % 4, posy + n / 4);

                // assign token ID to tile_idx on sector
                GameObjectPositionMap[sector][tile_idx] = token;
            }
        }

        emit TileChanged(sector, first_tile_idx);

        return token;
    }

    function RevokeLand(address sender, uint256 token) external override onlyTycoonContract {
        require(_exists(token), "Token not exists!");
        
        uint16 tile_idx = LandObjectsList[token].TileIdx;
        uint32 sector = LandObjectsList[token].Sector;
        uint16 listpos = LandObjectsList[token].ListPos;

        require(ownerOf(token) == sender, "Object not yours!");
        require(GameObjectPositionMap[sector][tile_idx] == 0, "Land has building!");

        LandPositionList[sector][listpos] = LandPositionList[sector][LandPositionList[sector].length - 1];
                uint16 movetileidx = LandPositionList[sector][listpos];
                uint256 movetoken = LandPositionMap[sector][movetileidx];
                LandObjectsList[movetoken].ListPos = listpos;

        LandPositionList[sector].pop();
        
        delete LandObjectsList[token];
        delete LandPositionMap[sector][tile_idx];

        _burn(token);
        
        emit TileChanged(sector, tile_idx);
    }

    function Destroy(address sender, uint256 token) external override onlyTycoonContract {
        require(_exists(token), "Token not exists!");

        require(ownerOf(token) == sender, "Object not yours!");

        uint32 sector = GameObjectsList[token].Sector;
        uint16 tile_idx = GameObjectsList[token].TileIdx;
        uint16 mask = GameObjectsList[token].Mask;
        uint16 listpos = GameObjectsList[token].ListPos;
        (, uint16 sector_h) = GetTerrainHolderContract().GetSectorSize(sector);

        GameObjectPositionList[sector][listpos] = GameObjectPositionList[sector][GameObjectPositionList[sector].length - 1];
            uint16 movetileidx = GameObjectPositionList[sector][listpos];
            uint256 movetoken = GameObjectPositionMap[sector][movetileidx];
            GameObjectsList[movetoken].ListPos = listpos;
               
            GameObjectPositionList[sector].pop();

        for(uint16 n = 0; n < 16; n++) {
            if(mask & (1 << n) == (1 << n)) {
                uint16 land_tile_idx = tile_idx + (n % 4) * sector_h + n / 4;

                delete GameObjectPositionMap[sector][land_tile_idx];
            }
        }

        delete GameObjectsList[token];

        _burn(token);

        emit TileChanged(sector, tile_idx);
    } 

    function UpgradeObject(uint256 token) external override onlyTycoonContract returns (bool, uint256, uint256) {
        Const.GameObject storage obj = GameObjectsList[token];
        if(obj.TileIdx == 0)
            return (false, 0, 0);

        // Cannot upgrade futher
        if(obj.Level >= Const.MAX_UPGRADE_LEVEL)
            return (false, 0, 0);

        obj.Level++;

        return (true, obj.Type, obj.Level);
    }

    function GetSectorDataSizes(uint32 sector) external view returns(uint16 pagesize, uint16 landsize, uint16 objectsize) {
        return (Const.LIST_PAGE_SIZE, uint16(LandPositionList[sector].length), uint16(GameObjectPositionList[sector].length));
    }

    function GetSectorLandList(uint32 sector, uint16 from, uint16 to) external view returns(ReturnLandObject[] memory lands) {
        if(from > LandPositionList[sector].length - 1)
            from = uint16(LandPositionList[sector].length - 1);

        if(to > LandPositionList[sector].length)
            to = uint16(LandPositionList[sector].length);

        uint16 len = to - from;
        ReturnLandObject[] memory retlist = new ReturnLandObject[](len);

        for(uint n = 0; n < len; n++) {
            uint16 tile_idx = LandPositionList[sector][from + n];
            uint256 token = LandPositionMap[sector][tile_idx];
            
            retlist[n].Owner = ownerOf(token);
            retlist[n].Token = token;
            retlist[n].Object = LandObjectsList[token];
        }
        return retlist;
    }

    function GetSectorObjectList(uint32 sector, uint16 from, uint16 to) external view returns(ReturnGameObject[] memory objects) {
        if(from > GameObjectPositionList[sector].length - 1)
            from = uint16(GameObjectPositionList[sector].length - 1);

        if(to > GameObjectPositionList[sector].length)
            to = uint16(GameObjectPositionList[sector].length);

        uint16 len = to - from;
        ReturnGameObject[] memory retlist = new ReturnGameObject[](len);
        
        for(uint n = 0; n < len; n++) {
            uint16 tile_idx = GameObjectPositionList[sector][from + n];
            uint256 token = GameObjectPositionMap[sector][tile_idx];

            retlist[n].Owner = ownerOf(token);
            retlist[n].Token = token;
            retlist[n].Object = GameObjectsList[token];
        }
        return retlist;
    }
/*
    function GetUserOwnedListForSector(uint32 sector, address user) external view returns (ReturnLandObject[] memory lands, ReturnGameObject[] memory objects) {
        uint length = balanceOf(user);
        ReturnLandObject[] memory landlist = new ReturnLandObject[](length);
        ReturnGameObject[] memory objectlist = new ReturnGameObject[](length);
    }
*/
    function GetSectorTileInfo(uint32 sector, uint16 tile_idx) external view returns(ReturnLandObject memory land, ReturnGameObject memory object) {
        uint256 landtoken = LandPositionMap[sector][tile_idx];
        uint256 objecttoken = GameObjectPositionMap[sector][tile_idx];

        ReturnLandObject memory landinfo;
        ReturnGameObject memory objectinfo;

        if(landtoken > 0) {
            landinfo = ReturnLandObject({
                Owner: ownerOf(landtoken),
                Token: landtoken,
                Object: LandObjectsList[landtoken]
            });
        }
        
        if(objecttoken > 0) {
            objectinfo = ReturnGameObject({
                Owner: ownerOf(objecttoken),
                Token: objecttoken,
                Object: GameObjectsList[objecttoken]
            });
        }
        
        return (landinfo, objectinfo);
    }
 
    function GetLandObject(uint256 token) external view override returns (Const.LandObject memory) {
        return LandObjectsList[token];
    }

    function GetGameObject(uint256 token) external view override returns (Const.GameObject memory) {
        return GameObjectsList[token];
    }

    function BulkTransfer(address from, address to, uint256 tokenId) private {
        // tokenId is iniciator, it can be land or game object
        // also tokenId iniciated is already transfered via _transfer from caller function
        // in case of gameobject, it must also transfer land under it

        if(GameObjectsList[tokenId].TileIdx > 0) {
            uint16 tile_idx = GameObjectsList[tokenId].TileIdx;
            uint32 sector = GameObjectsList[tokenId].Sector;
            uint16 mask = GameObjectsList[tokenId].Mask;
            (, uint16 sector_h) = GetTerrainHolderContract().GetSectorSize(sector);

            BlockCheckTransferMultiple = true;

            for(uint16 n = 0; n < 16; n++) {
                if(mask & (1 << n) == (1 << n)) {
                    uint16 land_tile_idx = tile_idx + (n % 4) * sector_h + n / 4;
                    ERC721Upgradeable._transfer(from, to, LandPositionMap[sector][land_tile_idx]);

                    emit TileChanged(sector, land_tile_idx);
                }
            }

            BlockCheckTransferMultiple = false;
        } else {
            uint32 sector = LandObjectsList[tokenId].Sector;

            emit TileChanged(sector, LandObjectsList[tokenId].TileIdx);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 token) internal override {
        ERC721EnumerableUpgradeable._beforeTokenTransfer(from, to, token);

        // Minting is not needed to be blocked
        if(from == address(0))
            return;

        // this is our semaphore for multiple land transfer
        if(BlockCheckTransferMultiple)
            return;

        // If no gameobject exists with given token, it must be land as only land transfer should be blocked
        // In case of gameobject transfer, bulktransfer will transfer all lands
        if(GameObjectsList[token].TileIdx == 0) {
            uint16 tile_idx = LandObjectsList[token].TileIdx;
            uint32 sector = LandObjectsList[token].Sector;

            if(GameObjectPositionMap[sector][tile_idx] > 0)
            {
                // There is building on that land token, that can be blocked if:
                //  - this is not main game object tile (top left)
                require(GameObjectsList[token].TileIdx == tile_idx, "This land is blocked from transfer!");
            }
        }
    }

    function _transfer(address from, address to, uint256 token) internal override {
        ERC721Upgradeable._transfer(from, to, token);

        // if transfer was without revert, we can now transfer connected lands if there are any
        BulkTransfer(from, to, token);

        // Staking must be updated too for new owner if game object
        if(GameObjectsList[token].TileIdx > 0)
            GetTycoonContract().TransferNftObject(from, to, token, GameObjectsList[token].Type);
    }

    modifier onlyTycoonContract {
        require(msg.sender == address(GetTycoonContract()), "Only Tycoon contract");
        _;
    }

    function GetTycoonContract() internal view virtual returns (ITycoon) {
        return ITycoon(Resolver.GetAddressAndRequire(CONTRACT_TYCOON));
    }

    function GetTerrainHolderContract() internal view returns (ITerrainHolder) {
        return ITerrainHolder(Resolver.GetAddressAndRequire(CONTRACT_TERRAINHOLDER));
    }

    uint256[42] private __gap;
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

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal initializer {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
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