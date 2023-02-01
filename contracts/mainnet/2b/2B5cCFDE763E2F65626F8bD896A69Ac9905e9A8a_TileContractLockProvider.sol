// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILockProvider {
    function onTokenLocked(
        address _user,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _relayerFee
    ) external payable;

    function onTokenUnlocked(
        address _user,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _relayerFee
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IMissionControlStakeable.sol";

/// @title Interface defining the mission control
/// @dev This defines only essential functionality and not admin functionality
interface IMissionControl {
    /**
     * @notice This is a struct which contains information regarding a tile element
     * @param steakeable Address for the stakeable token on the tile
     * @param tokenId Id of the staked token
     * @param nonce Staking nonce
     * @param staked Boolean defining whether the token is actively staked, used as opposed to clearing the previous two on unstaking.
     */
    struct TileElement {
        address stakeable;
        uint256 tokenId;
        uint256 nonce;
    }

    struct TileRentalInfo {
        bool isRented;
        uint256 pausedAt;
        address rentalToken;
    }

    struct TileRequirements {
        uint256 price;
        uint256 tileContractId;
    }

    /**
     * @notice Struct to hold instructions for tile resource collection
     * @param x X-coordinate of tile
     * @param y Y-coordinate of tile
     * @param z Z-coordinate of tile
     */
    struct CollectOrder {
        int256 x;
        int256 y;
        int256 z;
    }

    /**
     * @notice Struct to hold instructions for placing NFTs on tiles
     * @param x X-coordinate of tile
     * @param y Y-coordinate of tile
     * @param z Z-coordinate of tile
     * @param tokenId Token ID of NFT
     * @param tokenAddress Address of NFT, which is presumed to implement the IMissionControlStakeable interface
     */
    struct PlaceOrder {
        CollectOrder order;
        uint256 tokenId;
        address tokenAddress;
    }

    struct RemoveNFTVars {
        uint256 zeroOrOne;
        uint256 tokenId;
        address stakeable;
    }

    struct TotalTileInfo {
        int256 timeLeft;
        uint256 flowRate;
        address rentalToken;
        bool isRented;
        CollectOrder order;
        TileElement base;
        TileElement top;
    }

    struct TotalCheckTileInfo {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
        CollectOrder order;
    }

    struct CheckTileInputs {
        address user;
        int256 x;
        int256 y;
        int256 z;
    }

    struct HandleRaidCollectInputs {
        address defender;
        int256 x;
        int256 y;
    }

    struct HandleRaidCollectVars {
        TileElement tileElement;
        TileRentalInfo tileRentalInfo;
        IMissionControlStakeable iStakeable;
    }

    struct HandleCollectInputs {
        int256 x;
        int256 y;
        int256 z;
    }

    struct HandleCollectVars {
        TileElement tileElement;
        TileRentalInfo tileRentalInfo;
    }

    struct UpdateRentTileVars {
        int96 requiredFlow;
        uint256 index;
        uint256 size;
        uint256 removeTileLength;
        TileRentalInfo tile;
        CollectOrder removeTileItem;
        CollectOrder order;
    }

    struct GetAllCheckTileInfoVars {
        uint256 amount;
        uint256 tokenId;
        uint256 count;
        uint256 totalTiles;
        int256 radius;
    }

    /**
     * @notice Stakes an NFT on a tile
     */
    function placeNFT(PlaceOrder memory placeOrder) external;

    /**
     * @notice Stakes multiple NFTs on various tiles in one transaction
     * @param _placeOrders Array of structs containing information regarding where to place what
     * @dev Any downside to using structs as an argument?
     */
    function placeNFTs(PlaceOrder[] calldata _placeOrders) external;

    /**
     * @notice Unstakes an NFT from a tile
     */
    function removeNFT(CollectOrder memory order) external;

    /**
     * @notice Removes multiple NFTs on various tiles in one transaction
     * @param orders Array of structs containing information regarding where to remove something
     * @dev Token id, address are ignored
     */
    function removeNFTs(CollectOrder[] memory orders) external;

    /**
     * @notice Queries a tile regarding the resources which are able to collected from it at the current moment
     * @dev Add support for multiple types of tokens, i.e return would be an array?
     * @return uint Number of tokens that can be collected
     * @return uint Token identifier for token to be collected
     */
    function checkTile(CheckTileInputs memory c) external view returns (uint256, uint256);

    /**
     * @notice Collects (mints) tokens from tiles
     * @dev An alternative worth considering would be to have an alternative mint function
     * @param _orders Array containing collect orders
     * @dev Any downside to using structs as an argument?
     */
    function collectFromTiles(
        CollectOrder[] calldata _orders,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @notice Used to check what a user has staked on a tile
     * @param _user The user whose Mission Control we should check
     * @param _x X-coordinate of tile
     * @param _y Y-coordinate of tile
     * @param _z Z-coordinate of tile
     */
    function checkStakedOnTile(
        address _user,
        int256 _x,
        int256 _y,
        int256 _z
    ) external view returns (TileElement memory _base, TileElement memory _top);

    /**
     * @notice Returns when the tile was last updated
     * @param _user The user whose Mission Control we should check
     * @param _x X-coordinate of tile
     * @param _y Y-coordinate of tile
     * @param _z Z-coordinate of tile
     * @return _timestamp The time in blockchain seconds
     */
    function checkLastUpdated(
        address _user,
        int256 _x,
        int256 _y,
        int256 _z
    ) external view returns (uint256 _timestamp);

    /**
     * @notice Notifies the contract that a user has been raided
     * @param _defender Address of the player being raided
     * @param _timestamp The timestamp the signature was written
     * @param _raidId The raid id
     * @param _orders Collect orders denoting which tiles we should wipe the waste from
     * @param _v Sig
     * @param _r Sig
     * @param _s Sig
     */
    function notifyRaided(
        address _defender,
        uint256 _timestamp,
        uint256 _raidId,
        CollectOrder[] calldata _orders,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @notice returns the remaining time until a tile is filled
     * @param _user The user whose Mission Control we should check
     * @param _x X-coordinate of tile
     * @param _y Y-coordinate of tile
     * @param _z Z-coordinate of tile
     * @return _timeLeft The time left, -1 if the time can not be predicted
     */
    function timeLeft(
        address _user,
        int256 _x,
        int256 _y,
        int256 _z
    ) external view returns (int256 _timeLeft);

    // user start streaming to the game
    function createRentTiles(
        address supertoken,
        address renter,
        CollectOrder[] memory tiles, // changed to PlaceOrder so that it inclues tokenId and token Address
        int96 flowRate
    ) external;

    // user is streaming and change the rented tiles
    function updateRentTiles(
        address supertoken,
        address renter,
        CollectOrder[] memory addTiles,
        CollectOrder[] memory removeTiles,
        int96 oldFlowRate,
        int96 flowRate
    ) external;

    function toggleTile(
        address _renter,
        int256 _x,
        int256 _y,
        uint256 rad,
        bool _shouldPause
    ) external;

    // user stop streaming to the game
    function deleteRentTiles(address supertoken, address renter) external;

    function getAllTileInfo(address _renter) external view returns (TotalTileInfo[] memory _totalTileInfo);

    function getAllCheckTileInfo(address _renter)
        external
        view
        returns (TotalCheckTileInfo[] memory _totalCheckTileInfo);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Interface defining a contract which can be staked upon a "tile" in the mission control
interface IMissionControlStakeable {
    /**
     * @notice Event emitted when a token is staked
     * @param _userAddress address of the staker
     * @param _stakeable Address to either the IMCStakeable implementation or the possibly the underlying token?
     * @param _tokenId Token id which has been staked
     */
    event TokenClaimed(address _userAddress, address _stakeable, uint256 _tokenId);
    /**
     * @notice Event emitted when a token is unstaked
     * @param _userAddress address of the staker
     * @param _stakeable Address to either the IMCStakeable implementation or the possibly the underlying token?
     * @param _tokenId Token id which has been unstaked
     */
    event TokenReturned(address _userAddress, address _stakeable, uint256 _tokenId);

    /**
     * @notice Event emitted when the mission control is set
     * @param missionControl The address of the mission control
     */
    event MissionControlSet(address missionControl);

    /**
     * @notice Resets the seed of a staked token. A cheaper alternative to onCollect when you do not need the number of harvested tokens
     * @param _userAddress The players address
     * @param _nonce Tile-staking nonce
     */
    function reset(address _userAddress, uint256 _nonce) external;

    /**
     * @notice Function to check the number of tokens ready to be harvested from this tile
     * @param _userAddress The players address
     * @param _nonce Tile-staking nonce
     * @return _amount Number of tokens that can be collected
     * @return _retTokenId The tokenId of the tokens that can be collected
     */
    function checkTile(
        address _userAddress,
        uint256 _nonce,
        uint256 _pausedAt,
        int256 _x,
        int256 _y
    ) external view returns (uint256 _amount, uint256 _retTokenId);

    /**
     * @notice Used to fetch new seed time upon collection some resources
     * @param _userAddress The players address
     * @param _nonce Tile-staking nonce
     * @return _amount Number of tokens that can be collected
     * @return _retTokenId The tokenId of the tokens that can be collected
     * @dev It is vital for this function to update the rng
     */
    function onCollect(
        address _userAddress,
        uint256 _nonce,
        uint256 _pausedAt,
        int256 _x,
        int256 _y
    ) external returns (uint256 _amount, uint256 _retTokenId);

    /**
     * @notice Used to see if the token can be used as the base of a tile, or if it is meant to be staked upon another token
     * @param _tokenId The id of the token
     * @return _isBase Whether this token is a base or not
     */
    function isBase(
        uint256 _tokenId,
        int256 _x,
        int256 _y
    ) external view returns (bool _isBase);

    function isRaidable(
        uint256 _tokenId,
        int256 _x,
        int256 _y
    ) external view returns (bool _isRaidable);

    /**
     * @notice transfers ownership of a token from the player to the stakeable contract
     * @param _currentOwner Address of the current owner
     * @param _tokenId The id of the token
     * @param _nonce Tile-staking nonce
     * @param _underlyingToken todo
     * @param _underlyingTokenId todo
     */
    function onStaked(
        address _currentOwner,
        uint256 _tokenId,
        uint256 _nonce,
        address _underlyingToken,
        uint256 _underlyingTokenId,
        int256 _x,
        int256 _y
    ) external;

    function onResume(address _renter, uint256 _nonce) external;

    /**
     * @notice transfers ownership of a token from the stakeable contract back to the player
     * @param _newOwner Address of the soon-to-be owner
     * @param _nonce Tile-staking nonce
     */
    function onUnstaked(address _newOwner, uint256 _nonce) external;

    function checkTimestamp(address _userAddress, uint256 _nonce) external view returns (uint256 _timestamp);

    /**
     * @notice returns the remaining time until a tile is filled
     * @param _userAddress The players address
     * @param _nonce Tile-staking nonce
     * @return _timeLeft The time left, -1 if the time can not be predicted
     */
    // note: removed tokenId as a param. was unused
    function timeLeft(
        address _userAddress,
        uint256 _nonce,
        int256 _x,
        int256 _y
    ) external view returns (int256 _timeLeft);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMissionControlStaking {
    struct Lockup {
        uint256 amount;
        uint256 lockedAt;
    }

    event TokenStaked(address tokenAddress, uint256 tokenId, uint256 amount, address user);

    event TokenUnstaked(address tokenAddress, uint256 tokenId, uint256 amount, address user);

    event TokensWhitelisted(address tokenAddress, uint256[] tokenIds);

    event UnstakeProviderSet(address tokenAddress, uint256[] tokenIds, address provider);

    /**
     * @notice This allows the user to stake a token Id from a particular contract
     * @param tokenAddress Address for the token
     * @param tokenId Id of token
     */
    function stakeNonFungible(
        address tokenAddress,
        uint256 tokenId,
        uint256 relayerFee
    ) external payable;

    /**
     * @notice This allows the user to stake a token Id from a particular contract
     * @param tokenAddress Address for the token
     * @param tokenId Id of token
     * @param amount amount of the token th user would like to stake.
     */
    function stakeSemiFungible(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 relayerFee
    ) external payable;

    /**
     * @notice This allows the user to stake multiple token Ids from a particular contract
     * @param tokenAddresses Address for the token
     * @param tokenIds Id of token
     */
    function stakeManyNonFungible(
        address[] memory tokenAddresses,
        uint256[] memory tokenIds,
        uint256 relayerFee
    ) external payable;

    /**
     * @notice This allows the user to stake multiple token Ids from a particular contract
     * @param tokenAddresses Address for the token
     * @param tokenIds Id of token
     * @param amounts amount of the token th user would like to stake. 1 if ERC721
     */
    function stakeManySemiFungible(
        address[] memory tokenAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256 relayerFee
    ) external payable;

    /**
     * @notice This allows the user to unstake a tokenId from a particular contract
     * @param tokenAddress Address for the token
     * @param tokenId Id of the staked token
     * @param amount amount of the token th user would like to unstake. 1 if ERC721
     */
    function unstake(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 relayerFee
    ) external payable;

    /**
     * @notice This allows the user to unstake multiple token Ids from a particular contract
     * @param tokenAddresses Address for the token
     * @param tokenIds Id of token
     * @param amounts amount of the token th user would like to stake. 1 if ERC721
     */
    function unstakeMany(
        address[] memory tokenAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256 relayerFee
    ) external payable;

    /**
     * @notice Allows admin to whitelist a set of tokenIds for staking
     * @param tokenAddress Address for the token
     * @param tokenIds List of ids to be whitelisted
     */
    function whitelistTokens(
        address tokenAddress,
        uint256[] memory tokenIds,
        bool isWhitelisted
    ) external;

    /**
     * @notice Allows admin to add logic for what happens when a user unstakes a set of tokenIds
     * @param tokenAddress Address for the token
     * @param tokenIds Id of the staked token
     * @param provider logic contract to handle all unstake events involving the tokenIds in the array. should implement IUnlockProvider
     */
    function setUnstakeProvider(
        address tokenAddress,
        uint256[] memory tokenIds,
        address provider
    ) external;

    /**
     * @notice View function for checking how much of a particular token a user has staked.
     * @param tokenAddress Address for the token
     * @param tokenId Id of the staked token
     */
    function getUserStakedBalance(
        address user,
        address tokenAddress,
        uint256 tokenId
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./ILockProvider.sol";
import "./IMissionControl.sol";
import "./IMissionControlStaking.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

contract TileContractLockProvider is ILockProvider, OwnableUpgradeable, ERC165Upgradeable {
    struct Coords {
        int256 x;
        int256 y;
        int256 z;
    }

    IMissionControlStaking public missionControlStaking;
    IMissionControl public missionControl;

    mapping(uint256 => Coords[]) idToRing;

    modifier onlyMCStaking() {
        require(msg.sender == address(missionControlStaking), "LOCK_PROVIDER: MC STAKING ONLY");
        _;
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    function onTokenLocked(
        address _user,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _relayerFee
    ) external payable onlyMCStaking {
        Coords[] memory ring = idToRing[_tokenId];
        for (uint256 i; i < ring.length; i++) {
            uint256 rad = (abs(ring[i].x) + abs(ring[i].y) + abs(ring[i].z)) / 2;
            missionControl.toggleTile(_user, ring[i].x, ring[i].y, rad, false);
        }
    }

    function onTokenUnlocked(
        address _user,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _relayerFee
    ) external payable onlyMCStaking {
        Coords[] memory ring = idToRing[_tokenId];
        if (_amount == 0) {
            for (uint256 i; i < ring.length; i++) {
                uint256 rad = (abs(ring[i].x) + abs(ring[i].y) + abs(ring[i].z)) / 2;
                missionControl.toggleTile(_user, ring[i].x, ring[i].y, rad, true);
            }
        }
    }

    function setMCStaking(address _mcStaking) external onlyOwner {
        require(_mcStaking != address(0), "LOCK_PROVIDER: ADDRESS ZERO");
        missionControlStaking = IMissionControlStaking(_mcStaking);
    }

    function setMissionControl(address _missionControl) external onlyOwner {
        require(_missionControl != address(0), "LOCK_PROVIDER: ADDRESS ZERO");
        missionControl = IMissionControl(_missionControl);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable) returns (bool) {
        return interfaceId == type(ILockProvider).interfaceId || super.supportsInterface(interfaceId);
    }

    function addCoords(uint256 id, Coords[] memory coords) external onlyOwner {
        for (uint256 i; i < coords.length; i++) {
            idToRing[id].push(coords[i]);
        }
    }

    function abs(int256 _value) private pure returns (uint256) {
        return _value < 0 ? uint256(-_value) : uint256(_value);
    }
}