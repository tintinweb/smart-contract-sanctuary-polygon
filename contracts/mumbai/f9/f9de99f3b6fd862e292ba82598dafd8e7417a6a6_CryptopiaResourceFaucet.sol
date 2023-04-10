// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "./ICryptopiaResourceFaucet.sol";
import "../../map/CryptopiaMap/ICryptopiaMap.sol";
import "../../players/CryptopiaPlayerRegister/ICryptopiaPlayerRegister.sol";
import "../../inventories/CryptopiaInventories/ICryptopiaInventories.sol";
import "../../../assets/AssetEnums.sol";
import "../../../assets/CryptopiaAssetRegister/ICryptopiaAssetRegister.sol";
import "../../../tokens/ERC20/retriever/TokenRetriever.sol";
import "../../../tokens/ERC721/CryptopiaToolToken/ICryptopiaToolToken.sol";
import "../../../tokens/ERC777/CryptopiaAssetToken/ICryptopiaAssetToken.sol";

/// @title Allows players to mint non-finite resources
/// @author Frank Bonnet - <[email protected]>
contract CryptopiaResourceFaucet is ICryptopiaResourceFaucet, ContextUpgradeable, TokenRetriever {

    /** 
     * Storage
     */
    uint24 constant XP_BASE = 50;
    uint constant COOLDOWN_BASE = 60 seconds;
    uint24 constant MULTIPLIER_PRECISION = 100;
    uint constant RESOURCE_PRECISION = 1_000_000_000_000_000_000;

    // Refs
    address public mapContract;
    address public assetRegisterContract;
    address public playerRegisterContract;
    address public inventoriesContract;
    address public toolTokenContract;

    // Player => resource => cooldown
    mapping (address => mapping (AssetEnums.Resource => uint)) playerCooldown;


    /** 
     * Public functions
     */
    /// @param _mapContract Location of the map contract
    /// @param _assetRegisterContract Location of the asset register contract
    /// @param _playerRegisterContract Location of the player register contract
    /// @param _inventoriesContract Location of the inventories contract
    /// @param _toolTokenContract Location of the tool token contract
    function initialize(
        address _mapContract, 
        address _assetRegisterContract,
        address _playerRegisterContract,
        address _inventoriesContract,
        address _toolTokenContract) 
        public initializer 
    {
        __Context_init();

        // Assign refs
        mapContract = _mapContract;
        assetRegisterContract = _assetRegisterContract;
        playerRegisterContract = _playerRegisterContract;
        inventoriesContract = _inventoriesContract;
        toolTokenContract = _toolTokenContract;
    }


    /// @dev Returns the timestamp at which `player` can mint `resource` again
    /// @param player the account to retrieve the cooldown timestamp for
    /// @param resource the resource to retrieve the cooldown timestamp for
    /// @return uint cooldown timestamp at which `player` can mint `resource` again
    function getCooldown(address player, AssetEnums.Resource resource) 
        public virtual override view 
        returns (uint) 
    {
        return playerCooldown[player][resource];
    }


    /// @dev Mint `asset` to sender's inventory
    /// @param resource The {AssetEnums} to mint 
    /// @param tool The token ID of the tool used to mint the resource (0 means no tool)
    /// @param limit The maximum amount of tokens to mint (limit to prevent full backpack)
    function mint(AssetEnums.Resource resource, uint tool, uint limit) 
        public virtual override 
    {
        address player = _msgSender();
        uint amount = ICryptopiaMap(mapContract).getPlayerResourceData(player, resource);
        require(amount > 0, "CryptopiaResourceFaucet: Unable to mint resource");

        uint24 xp;
        uint cooldown;

        // Use tool
        if (_requiresTool(resource))
        {
            require(tool > 0, "CryptopiaResourceFaucet: Unable to mint resource without a tool");

            (address owner, InventoryEnums.Inventories inventory) = ICryptopiaInventories(inventoriesContract)
                .getNonFungibleTokenData(toolTokenContract, tool);

            require(owner == player, "CryptopiaResourceFaucet: Tool not owned by player");
            require(inventory == InventoryEnums.Inventories.Backpack, "CryptopiaResourceFaucet: Tool not in backpack");

            // Apply tool effects
            (uint24 multiplier_cooldown, uint24 multiplier_xp, uint24 multiplier_effectiveness) = ICryptopiaToolToken(toolTokenContract)
                .useForMinting(player, tool, resource, limit < amount ? limit : amount);

            xp = uint24(XP_BASE * (limit < amount ? limit : amount) / RESOURCE_PRECISION * multiplier_xp / MULTIPLIER_PRECISION);
            amount = amount * multiplier_effectiveness / MULTIPLIER_PRECISION;
            cooldown = COOLDOWN_BASE * multiplier_cooldown / MULTIPLIER_PRECISION;
        }
        else 
        {
            xp = uint24(XP_BASE * (limit < amount ? limit : amount) / RESOURCE_PRECISION);
            cooldown = COOLDOWN_BASE;
        }

        // Cooldown
        require(playerCooldown[player][resource] <= block.timestamp, "CryptopiaResourceFaucet: In cooldown period");
        playerCooldown[player][resource] = block.timestamp + cooldown;

        address asset = ICryptopiaAssetRegister(assetRegisterContract)
            .getAssetByResrouce(resource);

        // Mint tokens to inventory
        ICryptopiaAssetToken(asset)
            .mintTo(inventoriesContract, (limit < amount ? limit : amount));

        // Assign tokens to player
        ICryptopiaInventories(inventoriesContract)
            .assignFungibleToken(player, InventoryEnums.Inventories.Backpack, asset, (limit < amount ? limit : amount));

        // Award XP
        ICryptopiaPlayerRegister(playerRegisterContract)
            .award(player, xp, 0);
    }


    /**
     * Internal functions
     */
    /// @dev Returns true if the minting of `resource` requires the use of a tool
    /// @param resource {AssetEnums.Resource} the resource to mint
    /// @return bool True if `resource` requires a tool to mint
    function _requiresTool(AssetEnums.Resource resource)
        internal pure 
        returns (bool)
    {
        return resource != AssetEnums.Resource.Fruit;
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title Cryptopia Asset Token
/// @notice Cryptoipa asset such as natural resources.
/// @dev Implements the ERC777 standard
/// @author Frank Bonnet - <[email protected]>
interface ICryptopiaAssetToken {

    /// @dev Mints 'amount' token to an address
    /// @param to Account to mint the tokens for
    /// @param amount Amount of tokens to mint
    function mintTo(address to, uint amount) external;
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../../../game/GameEnums.sol";
import "../../../assets/AssetEnums.sol";

/// @title ICryptopiaToolToken Token
/// @dev Non-fungible token (ERC721) 
/// @author Frank Bonnet - <[email protected]>
interface ICryptopiaToolToken {

    /// @dev Returns the amount of different tools
    /// @return count The amount of different tools
    function getToolCount() 
        external view 
        returns (uint);


    /// @dev Retreive a tools by name
    /// @param name Tool name (unique)
    /// @return rarity Tool rarity {Rarity}
    /// @return level Tool level (determins where the tool can be used and by who)
    /// @return durability The higher the durability the less damage is taken each time the tool is used
    /// @return multiplier_cooldown The lower the multiplier_cooldown the faster an action can be repeated
    /// @return multiplier_xp The base amount of XP is multiplied by this value every time the tool is used
    /// @return multiplier_effectiveness The effect that the tool has is multiplied by this value. Eg. a value of 2 while fishing at a depth of 3 will give the user 6 fish
    /// @return value1 Tool specific value 
    /// @return value2 Tool specific value 
    function getTool(bytes32 name) 
        external view 
        returns (
            GameEnums.Rarity rarity,
            uint8 level, 
            uint24 durability,
            uint24 multiplier_cooldown,
            uint24 multiplier_xp,
            uint24 multiplier_effectiveness,
            uint24 value1,
            uint24 value2
        );


    /// @dev Retreive a rance of tools
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return name Tool name (unique)
    /// @return rarity Tool rarity {Rarity}
    /// @return level Tool level (determins where the tool can be used and by who)
    /// @return durability The higher the durability the less damage is taken each time the tool is used
    /// @return multiplier_cooldown The lower the multiplier_cooldown the faster an action can be repeated
    /// @return multiplier_xp The base amount of XP is multiplied by this value every time the tool is used
    /// @return multiplier_effectiveness The effect that the tool has is multiplied by this value. Eg. a value of 2 while fishing at a depth of 3 will give the user 6 fish
    /// @return value1 Tool specific value 
    /// @return value2 Tool specific value 
    function getTools(uint skip, uint take) 
        external view 
        returns (
            bytes32[] memory name,
            GameEnums.Rarity[] memory rarity,
            uint8[] memory level, 
            uint24[] memory durability,
            uint24[] memory multiplier_cooldown,
            uint24[] memory multiplier_xp,
            uint24[] memory multiplier_effectiveness,
            uint24[] memory value1,
            uint24[] memory value2
        );


    /// @dev Add or update tools
    /// @param name Tool name (unique)
    /// @param rarity Tool rarity {Rarity}
    /// @param level Tool level (determins where the tool can be used and by who)
    /// @param stats durability, multiplier_cooldown, multiplier_xp, multiplier_effectiveness
    /// @param minting_resources The resources {AssetEnums.Resource} that can be minted with the tool
    /// @param minting_amounts The max amounts of resources that can be minted with the tool
    function setTools(
        bytes32[] memory name, 
        GameEnums.Rarity[] memory rarity, 
        uint8[] memory level,
        uint24[7][] memory stats,
        AssetEnums.Resource[][] memory minting_resources,
        uint[][] memory minting_amounts) 
        external;


    /// @dev Retreive a tools by token id
    /// @param tokenId The id of the tool to retreive
    /// @return name Tool name (unique)
    /// @return rarity Tool rarity {Rarity}
    /// @return level Tool level (determins where the tool can be used and by who)
    /// @return damage The amount of damage the tool has taken (100_00 renders the tool unusable)
    /// @return durability The higher the durability the less damage is taken each time the tool is used
    /// @return multiplier_cooldown The lower the multiplier_cooldown the faster an action can be repeated
    /// @return multiplier_xp The base amount of XP is multiplied by this value every time the tool is used
    /// @return multiplier_effectiveness The effect that the tool has is multiplied by this value. Eg. a value of 2 while fishing at a depth of 3 will give the user 6 fish
    /// @return value1 Tool specific value 
    /// @return value2 Tool specific value 
    function getToolInstance(uint tokenId) 
        external view 
        returns (
            bytes32 name,
            GameEnums.Rarity rarity,
            uint8 level, 
            uint24 damage,
            uint24 durability,
            uint24 multiplier_cooldown,
            uint24 multiplier_xp,
            uint24 multiplier_effectiveness,
            uint24 value1,
            uint24 value2
        );


    /// @dev Applies tool effects to the `cooldown` period and the `amount` of `resource` that's being minted by `player`
    /// @param player The account that's using the tool for minting
    /// @param toolId The token ID of the tool being used to mint 
    /// @param resource The resource {AssetEnums.Resource} that's being minted
    /// @param amount The amount of tokens to be minted; checked against value1
    function useForMinting(address player, uint toolId, AssetEnums.Resource resource, uint amount) 
        external  
        returns (
            uint24 multiplier_cooldown,
            uint24 multiplier_xp,
            uint24 multiplier_effectiveness
        );


    /// @dev Mints a tool to an address
    /// @param to address of the owner of the tool
    /// @param name nnique tool name
    /// @return uint token ID
    function mintTo(address to, bytes32 name) 
        external 
        returns (uint);
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./ITokenRetriever.sol";

/**
 * TokenRetriever
 *
 * Allows tokens to be retrieved from a contract
 *
 * #created 31/12/2021
 * #author Frank Bonnet
 */
contract TokenRetriever is ITokenRetriever {

    /**
     * Extracts tokens from the contract
     *
     * @param _tokenContract The address of ERC20 compatible token
     */
    function retrieveTokens(address _tokenContract) override virtual public {
        ERC20Upgradeable tokenInstance = ERC20Upgradeable(_tokenContract);
        uint tokenBalance = tokenInstance.balanceOf(address(this));
        if (tokenBalance > 0) {
            tokenInstance.transfer(msg.sender, tokenBalance);
        }
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/**
 * ITokenRetriever
 *
 * Allows tokens to be retrieved from a contract
 *
 * #created 29/09/2017
 * #author Frank Bonnet
 */
interface ITokenRetriever {

    /**
     * Extracts tokens from the contract
     *
     * @param _tokenContract The address of ERC20 compatible token
     */
    function retrieveTokens(address _tokenContract) external;
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title Player enums
/// @author Frank Bonnet - <[email protected]>
contract PlayerEnums {

    enum Stats
    {
        Luck,
        Charisma,
        Intelligence,
        Strength,
        Speed
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0 < 0.9.0;

import "../../../accounts/AccountEnums.sol";
import "../../GameEnums.sol";
import "../PlayerEnums.sol";

/// @title Cryptopia Players
/// @dev Contains player data
/// @author Frank Bonnet - <[email protected]>
interface ICryptopiaPlayerRegister {

    /// @dev Creates an account (see CryptopiaAccountRegister.sol) and registers the account as a player
    /// @param owners List of initial owners
    /// @param required Number of required confirmations
    /// @param dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis
    /// @param username Unique username
    /// @param sex {Undefined, Male, Female}
    /// @param faction The choosen faction (immutable)
    /// @return account Returns wallet address
    function create(address[] memory owners, uint required, uint dailyLimit, bytes32 username, AccountEnums.Sex sex, GameEnums.Faction faction)
        external 
        returns (address payable account);


    /// @dev Register `account` as a player
    /// @param faction The choosen faction (immutable)
    function register(GameEnums.Faction faction)
        external;


    /// @dev Check if an account was created and registered 
    /// @param account Account address
    /// @return true if account is registered
    function isRegistered(address account)
        external view 
        returns (bool);


    /// @dev Returns player data for `player`
    /// @param player CryptopiaAccount address (registered as a player)
    /// @return username Player username (fetched from account)
    /// @return faction Faction to which the player belongs
    /// @return subFaction Sub Faction none/pirate/bounty hunter 
    /// @return level Current level (zero signals not initialized)
    /// @return karma Current karma (-100 signals piracy)
    /// @return xp Experience points towards next level; XP_BASE * ((100 + XP_FACTOR) / XP_DENOMINATOR)**(level - 1)
    /// @return luck STATS_BASE_LUCK + (0 - MAX_LEVEL player choice when leveling up)
    /// @return charisma STATS_CHARISMA_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return intelligence STATS_INTELLIGENCE_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return strength STATS_STRENGTH_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return speed STATS_SPEED_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return ship The equipted ship (token ID)
    function getPlayerData(address payable player) 
        external view 
        returns (
            bytes32 username,
            GameEnums.Faction faction,
            GameEnums.SubFaction subFaction, 
            uint8 level,
            int16 karma,
            uint24 xp,
            uint24 luck,
            uint24 charisma,
            uint24 intelligence,
            uint24 strength,
            uint24 speed,
            uint ship
        );


    /// @dev Returns player datas for `players`
    /// @param players CryptopiaAccount addresses (registered as a players)
    /// @return username Player usernames (fetched from account)
    /// @return faction Faction to which the player belongs
    /// @return subFaction Sub Faction none/pirate/bounty hunter 
    /// @return level Current level (zero signals not initialized)
    /// @return karma Current karma (zero signals piracy)
    /// @return xp experience points towards next level; XP_BASE * ((100 + XP_FACTOR) / XP_DENOMINATOR)**(level - 1)
    /// @return luck STATS_BASE_LUCK + (0 - MAX_LEVEL player choice when leveling up)  
    /// @return charisma STATS_CHARISMA_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return intelligence STATS_INTELLIGENCE_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return strength STATS_STRENGTH_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return speed STATS_SPEED_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return ship The equipted ship
    function getPlayerDatas(address payable[] memory players) 
        external view 
        returns (
            bytes32[] memory username,
            GameEnums.Faction[] memory faction,
            GameEnums.SubFaction[] memory subFaction,
            uint8[] memory level,
            int16[] memory karma,
            uint24[] memory xp,
            uint24[] memory luck,
            uint24[] memory charisma,
            uint24[] memory intelligence,
            uint24[] memory strength,
            uint24[] memory speed,
            uint[] memory ship
        );

    
    /// @dev Returns `player` level
    /// @param player CryptopiaAccount address (registered as a player)
    /// @return level Current level (zero signals not initialized)
    function getLevel(address player) 
        external view 
        returns (uint8);


    /// @dev Returns the tokenId from the ship that's equipted by `player`
    /// @param player The player to retrieve the ship for
    /// @return uint the tokenId of the equipted ship
    function getEquiptedShip(address player) 
        external view 
        returns (uint);


    /// @dev Equipt `ship` to calling sender
    /// @param ship The tokenId of the ship to equipt
    function equiptShip(uint ship)
        external;

    
    /// @dev Award xp/ karma to the player
    /// @param player The player to award
    /// @param xp The amount of xp that's awarded
    /// @param karma The amount of karma
    function award(address player, uint24 xp, int16 karma)
        external;


    /// @dev Level up by spending xp 
    /// @param stat The type of stat to increase
    function levelUp(PlayerEnums.Stats stat)
        external;
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../../../assets/AssetEnums.sol";

/// @title Allows players to mint non-finite resources
/// @author Frank Bonnet - <[email protected]>
interface ICryptopiaResourceFaucet {


    /// @dev Returns the timestamp at which `player` can mint `resource` again
    /// @param player The account to retrieve the cooldown timestamp for
    /// @param resource The resource to retrieve the cooldown timestamp for
    /// @return uint Cooldown timestamp at which `player` can mint `resource` again
    function getCooldown(address player, AssetEnums.Resource resource) 
        external view 
        returns (uint);
 

    /// @dev Mint `asset` to sender's inventory
    /// @param resource The {AssetEnums} to mint 
    /// @param tool The token ID of the tool used to mint the resource (0 means no tool)
    /// @param max The maximum amount of tokens to mint (limit to prevent full backpack)
    function mint(AssetEnums.Resource resource, uint tool, uint max) 
        external; 
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../../../assets/AssetEnums.sol";

/// @title Cryptopia Maps
/// @dev Responsible for world data and player movement
/// @author Frank Bonnet - <[email protected]>
interface ICryptopiaMap {

    /// @dev Retreives the amount of maps created
    /// @return count Number of maps created
    function getMapCount() 
        external view 
        returns (uint count);


    /// @dev Retreives the map at `index`
    /// @param index Map index (not mapping key)
    /// @return initialized True if the map is created
    /// @return finalized True if all tiles are added and the map is immutable
    /// @return sizeX Number of tiles in the x direction
    /// @return sizeZ Number of tiles in the z direction
    /// @return tileStartIndex The index of the first tile in the map (mapping key)
    /// @return name Unique name of the map
    function getMapAt(uint256 index) 
        external view 
        returns (
            bool initialized, 
            bool finalized, 
            uint32 sizeX, 
            uint32 sizeZ, 
            uint32 tileStartIndex,
            bytes32 name
        );

    
    /// @dev Retrieve a tile
    /// @param tileIndex Index of hte tile to retrieve
    /// @return terrainPrimaryIndex Primary texture used to paint tile
    /// @return terrainSecondaryIndex Secondary texture used to paint tile
    /// @return terrainBlendFactor Blend factor for primary and secondary textures
    /// @return terrainOrientation Orientation in degrees for texture
    /// @return terrainElevation The elevation of the terrain (seafloor in case of sea tile)
    /// @return elevation Tile elevation actual elevation used in navigation (underwater and >= waterlevel indicates seasteading)
    /// @return waterLevel Tile water level
    /// @return vegitationLevel Level of vegitation on tile
    /// @return rockLevel Level of rocks on tile
    /// @return incommingRiverData River data
    /// @return outgoingRiverData River data
    /// @return roadFlags Road data
    function getTile(uint32 tileIndex) 
        external view 
        returns (
            uint8 terrainPrimaryIndex,
            uint8 terrainSecondaryIndex,
            uint8 terrainBlendFactor,
            uint8 terrainOrientation,
            uint8 terrainElevation,
            uint8 elevation,
            uint8 waterLevel,
            uint8 vegitationLevel,
            uint8 rockLevel,
            uint8 incommingRiverData,
            uint8 outgoingRiverData,
            uint8 roadFlags
        );


    /// @dev Retrieve a range of tiles
    /// @param skip Starting index
    /// @param take Amount of tiles
    /// @return terrainPrimaryIndex Primary texture used to paint tile
    /// @return terrainSecondaryIndex Secondary texture used to paint tile
    /// @return terrainBlendFactor Blend factor for primary and secondary textures
    /// @return terrainOrientation Orientation in degrees for texture
    /// @return terrainElevation The elevation of the terrain (seafloor in case of sea tile)
    /// @return elevation Tile elevation actual elevation used in navigation (underwater and >= waterlevel indicates seasteading)
    /// @return waterLevel Tile water level
    /// @return vegitationLevel Level of vegitation on tile
    /// @return rockLevel Level of rocks on tile
    /// @return incommingRiverData River data
    /// @return outgoingRiverData River data
    /// @return roadFlags Road data
    function getTiles(uint32 skip, uint32 take) 
        external view 
        returns (
            uint8[] memory terrainPrimaryIndex,
            uint8[] memory terrainSecondaryIndex,
            uint8[] memory terrainBlendFactor,
            uint8[] memory terrainOrientation,
            uint8[] memory terrainElevation,
            uint8[] memory elevation,
            uint8[] memory waterLevel,
            uint8[] memory vegitationLevel,
            uint8[] memory rockLevel,
            uint8[] memory incommingRiverData,
            uint8[] memory outgoingRiverData,
            uint8[] memory roadFlags
        );

    
    /// @dev Retrieve static data for a range of tiles
    /// @param skip Starting index
    /// @param take Amount of tiles
    /// @return wildlife_creature Type of wildlife that the tile contains
    /// @return wildlife_initialLevel The level of wildlife that the tile contained initially
    /// @return resource1_asset A type of asset that the tile contains
    /// @return resource2_asset A type of asset that the tile contains
    /// @return resource3_asset A type of asset that the tile contains
    /// @return resource1_initialAmount The amount of resource1_asset the tile contains
    /// @return resource2_initialAmount The amount of resource2_asset the tile contains
    /// @return resource3_initialAmount The amount of resource3_asset the tile contains
    function getTileDataStatic(uint32 skip, uint32 take) 
        external view 
        returns (
            bytes32[] memory wildlife_creature,
            uint128[] memory wildlife_initialLevel,
            address[] memory resource1_asset,
            address[] memory resource2_asset,
            address[] memory resource3_asset,
            uint[] memory resource1_initialAmount,
            uint[] memory resource2_initialAmount,
            uint[] memory resource3_initialAmount
        );
    

    /// @dev Retrieve dynamic data for a range of tiles
    /// @param skip Starting index
    /// @param take Amount of tiles
    /// @return owner Account that owns the tile
    /// @return player1 Player that last entered the tile
    /// @return player2 Player entered the tile before player1
    /// @return player3 Player entered the tile before player2
    /// @return player4 Player entered the tile before player3
    /// @return player5 Player entered the tile before player4
    /// @return wildlife_level The remaining level of wildlife that the tile contains
    /// @return resource1_amount The remaining amount of resource1_asset that the tile contains
    /// @return resource2_amount The remaining amount of resource2_asset that the tile contains
    /// @return resource3_amount The remaining amount of resource3_asset that the tile contains
    function getTileDataDynamic(uint32 skip, uint32 take) 
        external view 
        returns (
            address[] memory owner,
            address[] memory player1,
            address[] memory player2,
            address[] memory player3,
            address[] memory player4,
            address[] memory player5,
            uint128[] memory wildlife_level,
            uint[] memory resource1_amount,
            uint[] memory resource2_amount,
            uint[] memory resource3_amount
        );


    /// @dev Retrieve players from the tile with tile
    /// @param tileIndex Retrieve players from this tile
    /// @param start Starting point in the chain
    /// @param max Max amount of players to return
    function getPlayers(uint32 tileIndex, address start, uint max)
        external view 
        returns (
            address[] memory players
        );

    
    /// @dev Retrieve data that's attached to players
    /// @param accounts The players to retreive player data for
    /// @return location_mapName The map that the player is at
    /// @return location_tileIndex The tile that the player is at
    /// @return location_arrival The datetime on wich the player arrives at `location_tileIndex`
    /// @return movement Player movement budget
    function getPlayerData(address[] memory accounts)
        external view 
        returns (
            bytes32[] memory location_mapName,
            uint32[] memory location_tileIndex,
            uint[] memory location_arrival,
            uint[] memory movement
        );

    
    /// @dev Returns data about the players ability to interact with wildlife 
    /// @param account Player to retrieve data for
    /// @param creature Type of wildlife to test for
    /// @return canInteract True if `account` can interact with 'creature'
    /// @return difficulty Based of level of wildlife and activity
    function getPlayerWildlifeData(address account, bytes32 creature) 
        external view 
        returns (
            bool canInteract,
            uint difficulty 
        );


    /// @dev Returns data about the players ability to interact with resources 
    /// @param account Player to retrieve data for
    /// @param resource Type of resource to test for
    /// @return resourceLevel the amount of `resource` on the tile where `account` is located
    function getPlayerResourceData(address account, AssetEnums.Resource resource) 
        external view 
        returns (uint resourceLevel);


    /// @dev Find out if a player with `account` has entred 
    /// @param account Player to test against
    /// @return Wether `account` has entered or not
    function playerHasEntered(address account) 
        external view 
        returns (bool);


    /// @dev Player entry point that adds the player to the Genesis map
    function playerEnter()
        external;

    
    /// @dev Moves a player from one tile to another
    /// @param path Tiles that represent a route
    function playerMove(uint32[] memory path)
        external;


    /// @dev Gets the cached movement costs to travel between `fromTileIndex` and `toTileIndex` or zero if no cache exists
    /// @param fromTileIndex Origin tile
    /// @param toTileIndex Destination tile
    /// @return uint Movement costs
    function getPathSegmentFromCache(uint32 fromTileIndex, uint32 toTileIndex)
        external view 
        returns (uint);
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title Inventory enums
/// @author Frank Bonnet - <[email protected]>
contract InventoryEnums {

    enum Inventories
    {
        Wallet,
        Backpack,
        Ship
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0 < 0.9.0;

import "../InventoryEnums.sol";

/// @title Cryptopia Inventories
/// @dev Contains player and ship assets
/// @author Frank Bonnet - <[email protected]>
interface ICryptopiaInventories {

    /**
     * System functions
     */
    /// @dev Set the `weight` for the fungible `asset` (zero invalidates the asset)
    /// @param asset The asset contract address
    /// @param weight The asset unit weight (kg/100)
    function setFungibleAsset(address asset, uint weight)
        external;

    
    /// @dev Set the `weight` for the non-fungible `asset` (zero invalidates the asset)
    /// @param asset The asset contract address
    /// @param accepted If true the inventory will accept the NFT asset
    function setNonFungibleAsset(address asset, bool accepted)
        external;


    /// @dev Update equipted ship for `player`
    /// @param player The player that equipted the `ship`
    /// @param ship The tokenId of the equipted ship
    function setPlayerShip(address player, uint ship) 
        external;


    /// @dev Update a ships inventory max weight
    /// - Fails if the ships weight exeeds the new max weight
    /// @param ship The tokenId of the ship to update
    /// @param maxWeight The new max weight of the ship
    function setShipInventory(uint ship, uint maxWeight)
        external;


    /// @dev Update a player's personal inventories 
    /// @param player The player of whom we're updateing the inventories
    /// @param maxWeight_backpack The new max weight of the player's backpack
    function setPlayerInventory(address player, uint maxWeight_backpack)
        external;


    /// @dev Assigns `amount` of `asset` to the `inventory` of `player`
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// - Weight will be zero if player does not exist
    /// - Assumes amount of asset is deposited to the contract
    /// @param player The inventory owner to assign the asset to
    /// @param inventory The inventory type to assign the asset to {BackPack | Ship}
    /// @param asset The asset contract address 
    /// @param amount The amount of asset to assign
    function assignFungibleToken(address player, InventoryEnums.Inventories inventory, address asset, uint amount)
        external;

    
    /// @dev Assigns `tokenId` from `asset` to the `inventory` of `player`
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// - Weight will be zero if player does not exist
    /// - Assumes tokenId is deposited to the contract
    /// @param player The inventory owner to assign the asset to
    /// @param inventory The inventory type to assign the asset to {BackPack | Ship}
    /// @param asset The asset contract address 
    /// @param tokenId The token id from asset to assign
    function assignNonFungibleToken(address player, InventoryEnums.Inventories inventory, address asset, uint tokenId)
        external;


    /// @dev Assigns `tokenIds` from `asset` to the `inventory` of `player`
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// - Weight will be zero if player does not exist
    /// - Assumes tokenId is deposited to the contract
    /// @param player The inventory owner to assign the asset to
    /// @param inventory The inventory type to assign the asset to {BackPack | Ship}
    /// @param asset The asset contract address 
    /// @param tokenIds The token ids from asset to assign
    function assignNonFungibleTokens(address player, InventoryEnums.Inventories inventory, address asset, uint[] memory tokenIds)
        external;

    
    /// @dev Assigns fungible and non-fungible tokens in a single transaction
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// - Weight will be zero if player does not exist
    /// - Assumes amount is deposited to the contract
    /// - Assumes tokenId is deposited to the contract
    /// @param player The inventory owner to assign the asset to
    /// @param inventory The inventory type to assign the asset to {BackPack | Ship}
    /// @param asset The asset contract address 
    /// @param tokenIds The token ids from asset to assign
    function assign(address[] memory player, InventoryEnums.Inventories[] memory inventory, address[] memory asset, uint[] memory amount, uint[][] memory tokenIds)
        external;


    /**
     * Public functions
     */
    /// @dev Retrieves info about 'player' inventory 
    /// @param player The account of the player to retrieve the info for
    /// @return weight The current total weight of player's inventory
    /// @return maxWeight The maximum weight of the player's inventory
    function getPlayerInventoryInfo(address player) 
        external view
        returns (uint weight, uint maxWeight);


    /// @dev Retrieves the contents from 'player' inventory 
    /// @param player The account of the player to retrieve the info for
    /// @return weight The current total weight of player's inventory
    /// @return maxWeight The maximum weight of the player's inventory
    /// @return fungible_asset Contract addresses of fungible assets
    /// @return fungible_amount Amounts of fungible tokens
    /// @return nonFungible_asset Contract addresses of non-fungible assets
    /// @return nonFungible_tokenIds Token Ids of non-fungible assets
    function getPlayerInventory(address player) 
        external view 
        returns (
            uint weight,
            uint maxWeight,
            address[] memory fungible_asset, 
            uint[] memory fungible_amount, 
            address[] memory nonFungible_asset, 
            uint[][] memory nonFungible_tokenIds);

    
    /// @dev Retrieves the amount of 'asset' in 'player' inventory 
    /// @param player The account of the player to retrieve the info for
    /// @param asset Contract addres of fungible assets
    /// @return uint Amount of fungible tokens
    function getPlayerBalanceFungible(address player, address asset) 
        external view 
        returns (uint);


    /// @dev Retrieves the amount of 'asset' 'tokenIds' in 'player' inventory 
    /// @param player The account of the player to retrieve the info for
    /// @param asset Contract addres of non-fungible assets
    /// @return uint Amount of non-fungible tokens
    function getPlayerBalanceNonFungible(address player, address asset) 
        external view 
        returns (uint);


    /// @dev Retrieves info about 'ship' inventory 
    /// @param ship The tokenId of the ship 
    /// @return weight The current total weight of ship's inventory
    /// @return maxWeight The maximum weight of the ship's inventory
    function getShipInventoryInfo(uint ship) 
        external view 
        returns (uint weight, uint maxWeight);


    /// @dev Retrieves the contents from 'ship' inventory 
    /// @param ship The tokenId of the ship 
    /// @return weight The current total weight of ship's inventory
    /// @return maxWeight The maximum weight of the ship's inventory
    /// @return fungible_asset Contract addresses of fungible assets
    /// @return fungible_amount Amounts of fungible tokens
    /// @return nonFungible_asset Contract addresses of non-fungible assets
    /// @return nonFungible_tokenIds Token Ids of non-fungible assets
    function getShipInventory(uint ship) 
        external view 
        returns (
            uint weight,
            uint maxWeight,
            address[] memory fungible_asset, 
            uint[] memory fungible_amount, 
            address[] memory nonFungible_asset, 
            uint[][] memory nonFungible_tokenIds);


    /// @dev Retrieves the amount of 'asset' in 'ship' inventory 
    /// @param ship The tokenId of the ship 
    /// @param asset Contract addres of fungible assets
    /// @return uint Amount of fungible tokens
    function getShipBalanceFungible(uint ship, address asset) 
        external view 
        returns (uint);


    /// @dev Retrieves the 'asset' 'tokenIds' in 'ship' inventory 
    /// @param ship The tokenId of the ship 
    /// @param asset Contract addres of non-fungible assets
    /// @return uint Amount of non-fungible tokens
    function getShipBalanceNonFungible(uint ship, address asset) 
        external view 
        returns (uint);


    /// @dev Returns non-fungible token data for `tokenId` of `asset`
    /// @param asset the contract address of the non-fungible asset
    /// @param tokenId the token ID to retrieve data about
    /// @return owner the account (player) that owns the token in the inventory
    /// @return inventory {InventoryEnums.Inventories} the inventory space where the token is stored 
    function getNonFungibleTokenData(address asset, uint tokenId)
        external view 
        returns (
            address owner, 
            InventoryEnums.Inventories inventory
        );


    /// @dev Transfer `asset` from 'inventory_from' to `inventory_to`
    /// @param player_to The receiving player (can be msg.sender)
    /// @param inventory_from Origin {Inventories}
    /// @param inventory_to Destination {Inventories} 
    /// @param asset The address of the ERC20, ERC777 or ERC721 contract
    /// @param amount The amount of fungible tokens to transfer (zero indicates non-fungible)
    /// @param tokenIds The token ID to transfer (zero indicates fungible)
    function transfer(address[] memory player_to, InventoryEnums.Inventories[] memory inventory_from, InventoryEnums.Inventories[] memory inventory_to, address[] memory asset, uint[] memory amount, uint[][] memory tokenIds)
        external;
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title Game enums
/// @author Frank Bonnet - <[email protected]>
contract GameEnums {

    enum Faction
    {
        Eco,
        Tech,
        Industrial,
        Traditional
    }

    enum SubFaction 
    {
        None,
        Pirate,
        BountyHunter
    }

    enum Rarity
    {
        Common,
        Rare,
        Legendary,
        Master
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../AssetEnums.sol";

/// @title Cryptopia asset register
/// @dev Cryptopia assets register that holds refs to assets such as natural resources and fabricates
/// @author Frank Bonnet - <[email protected]>
interface ICryptopiaAssetRegister {

    /// @dev Retreives the amount of assets.
    /// @return count Number of assets.
    function getAssetCount()
        external view 
        returns (uint256 count);


    /// @dev Retreives the asset at `index`.
    /// @param index Asset index.
    /// @return contractAddress Address of the asset.
    function getAssetAt(uint256 index)
        external view 
        returns (address contractAddress);


    /// @dev Retreives the assets from `cursor` to `cursor` plus `length`.
    /// @param cursor Starting index.
    /// @param length Amount of assets to return.
    /// @return contractAddresses Addresses of the assets.
    function getAssets(uint256 cursor, uint256 length)
        external view 
        returns (address[] memory contractAddresses);


    /// @dev Retreives asset and balance info for `account` from the asset at `index`.
    /// @param index Asset index.
    /// @param accounts Accounts to retrieve the balances for.
    /// @return contractAddress Address of the asset.
    /// @return name Address of the asset.
    /// @return symbol Address of the asset.
    /// @return balances Ballances of `accounts` the asset.
    function getAssetInfoAt(uint256 index, address[] memory accounts)
        external view 
        returns (
            address contractAddress, 
            string memory name, string 
            memory symbol, 
            uint256[] memory balances);


    /// @dev Retreives asset and balance infos for `accounts` from the assets from `cursor` to `cursor` plus `length`. Has limitations to avoid experimental.
    /// @param cursor Starting index.
    /// @param length Amount of asset infos to return.
    /// @param accounts Accounts to retrieve the balances for.
    /// @return contractAddresses Address of the asset.
    /// @return names Address of the asset.
    /// @return symbols Address of the asset.
    /// @return balances1 Asset balances of accounts[0].
    /// @return balances2 Asset balances of accounts[1].
    /// @return balances3 Asset balances of accounts[2].
    function getAssetInfos(uint256 cursor, uint256 length, address[] memory accounts)
        external view 
        returns (
            address[] memory contractAddresses, 
            bytes32[] memory names, 
            bytes32[] memory symbols, 
            uint256[] memory balances1, 
            uint256[] memory balances2, 
            uint256[] memory balances3);

        
    /// @dev Getter for resources
    /// @param resource {AssetEnums.Resource}
    /// @return address The resource asset contract address 
    function getAssetByResrouce(AssetEnums.Resource resource) 
        external view   
        returns (address);


    /// @dev Register an asset
    /// @param asset Contact address
    /// @param isResource true if `asset` is a resource
    /// @param resource {AssetEnums.Resource}
    function registerAsset(address asset, bool isResource, AssetEnums.Resource resource) 
        external;
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title Asset enums
/// @author Frank Bonnet - <[email protected]>
contract AssetEnums {

    enum Resource
    {
        Fish,
        Meat,
        Fruit,
        Wood,
        Stone,
        Sand,
        IronOre,
        Iron,
        CopperOre,
        Copper,
        GoldOre,
        Gold,
        Carbon,
        Oil,
        Glass,
        Steel
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title Account enums
/// @author Frank Bonnet - <[email protected]>
contract AccountEnums {

    enum Sex 
    {
        Undefined,
        Male,
        Female
    }

    enum Gender 
    {
        Male,
        Female
    }

    enum Relationship
    {
        None,
        Friend,
        Family,
        Spouse
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}