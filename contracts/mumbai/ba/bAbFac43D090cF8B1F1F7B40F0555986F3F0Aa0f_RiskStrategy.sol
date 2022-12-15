// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IAddressRegistry {
    function uriGenerator() external view returns (address);

    function treasury() external view returns (address);

    function pdp() external view returns (address);

    function pxp() external view returns (address);

    function pdt() external view returns (address);

    function pdtOracle() external view returns (address);

    function pxpOracle() external view returns (address);

    function playerMgmt() external view returns (address);

    function poolMgmt() external view returns (address);

    function svgGenerator() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IPDP {
    function publicMint(bytes32 name) external;

    function whitelistMint(bytes32 name, bytes memory _signature) external;

    function getPlayerAddress(uint256 id) external view returns (address playerAddress_);

    function getPlayerId(address player) external view returns (uint256 playerId_);

    function totalPlayers() external view returns (uint256 totalPlayers_);

    function playerExists(uint256 id) external view returns (bool playerExists_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IPlayerManagement {
    struct PlayerData {
        bytes32 playerName;
        uint64 playerRank;
        uint64 mintDate;
    }

    function claimPlayerXp(bytes memory signature, uint256 pxpAmount, uint256 claimCount) external;

    function setPlayerName(bytes32 newName) external;

    function upgradePlayerRank() external;

    function getPlayerData(uint256 id) external view returns (PlayerData memory playerData_);

    function getPlayersInRank(uint256 rank) external view returns (uint256 playersInRank_);

    function getPdpMintCost(bool whitelist) external view returns (uint256 pdtCost_);

    function getNameChangeCost() external view returns (uint256 pdtCost_);

    function getRankUpCosts(uint256 rank) external view returns (uint256 pdtCost_, uint256 pxpCost_);

    function getMinRankForTransfers() external view returns (uint256 minRankForTransfers_);

    function getClaimCount(uint256 playerId) external view returns (uint256 claimCount_);

    function getPDTPrice() external view returns (uint256 pdtPrice_);

    function getTotalPXPEarned(uint256 rank) external view returns (uint256 totalPxpEarned_);

    function getRankMultiplierBasisPoints() external view returns (uint256 rankMultiplierBasisPoints_);

    function getLevelMultiplier(uint256 rank) external view returns (uint256 levelMultiplier_);

    function getMaxRank() external view returns (uint256 maxRank_);

    function initializePlayerData(uint256 id, bytes32 name) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IPoolManagement {
    struct PoolInfo {
        string poolName;
        address assetPool721;
        address assetPool1155;
        address playerRental;
        address riskStrategy;
    }

    function isActivatedPool(uint256 _pid) external view returns (bool);

    function getPoolInfo(uint256 _pid) external view returns (string memory, address, address, address, address);

    function poolCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IRiskStrategy {
    function setPid(uint256 _pid) external;

    function getActualUtilizationRate(uint256 _totalLiquidity, uint256 _totalBorrows) external view returns (uint256);

    function getPXPCost(uint256 uActual) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IAddressRegistry.sol";
import "../interfaces/IPoolManagement.sol";
import "../interfaces/IRiskStrategy.sol";
import "../interfaces/IPlayerManagement.sol";
import "../interfaces/IPDP.sol";

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

contract RiskStrategy is IRiskStrategy, Ownable {
    /// @dev Pool Id
    uint256 public pid;

    /// @notice Base Variable Rate
    uint256 rBase;

    /// @notice Optimal Utilization Rate of the Asset Pool
    uint256 public uOpt;

    /// @dev Rates of exponential increase
    uint256 public rSlope1;
    uint256 public rSlope2;

    uint256 public constant MAX_RATE = 100_0000;
    uint256 public constant BASIS_POINT = 10000;

    /// @notice AddressRegstry contract
    IAddressRegistry public addressRegistry;

    /// @notice PoolManagement contract
    IPoolManagement public poolManagement;

    event RBaseSet(uint256 rBase);
    event UOptSet(uint256 uOpt);
    event RSlope1Set(uint256 rSlope1);
    event RSlope2Set(uint256 rSlope2);

    error ZeroAddress();
    error ZeroValue();
    error GreaterThanMaxRate(uint256 rate);
    error OnlyPoolManagement(address by);
    error NoPlayer(uint256 userLevel);

    constructor(address _addressRegistry, uint256 _rBase, uint256 _uOpt, uint256 _rSlope1, uint256 _rSlope2) {
        if (_addressRegistry == address(0)) revert ZeroAddress();
        if (_rBase > MAX_RATE) revert GreaterThanMaxRate(_rBase);
        if (_uOpt == 0) revert ZeroValue();
        if (_uOpt >= MAX_RATE) revert GreaterThanMaxRate(_uOpt);
        if (_rSlope1 > MAX_RATE) revert GreaterThanMaxRate(_rSlope1);
        if (_rSlope2 > MAX_RATE) revert GreaterThanMaxRate(_rSlope2);

        addressRegistry = IAddressRegistry(_addressRegistry);
        rBase = _rBase;
        uOpt = _uOpt;
        rSlope1 = _rSlope1;
        rSlope2 = _rSlope2;
    }

    function setPid(uint256 _pid) external {
        if (msg.sender != address(poolManagement)) revert OnlyPoolManagement(msg.sender);
        pid = _pid;
    }

    /// @notice Returns the actual utilization rate of the asset pool
    function getActualUtilizationRate(uint256 _totalLiquidity, uint256 _totalBorrows) public pure returns (uint256) {
        return (_totalBorrows * MAX_RATE) / _totalLiquidity;
    }

    /// @notice Returns the rental premium based on the actual utilaization rate
    /// @param uActual Actual utilization rate based on BASIS_POINT
    /// @return rPremium Rental premium based on BASIS_POINT
    function getRentalPremium(uint256 uActual) public view returns (uint256 rPremium) {
        if (uActual < uOpt) {
            rPremium = rBase + (uActual * rSlope1) / uOpt;
        } else {
            rPremium = rBase + rSlope1 + ((uActual - uOpt) * rSlope2) / (MAX_RATE - uOpt);
        }
    }

    /// @notice Returns the PXP cost
    /// @param uActual Actual utilization rate based on BASIS_POINT
    /// @return pxpCost PXP cost
    function getPXPCost(uint256 uActual) external view returns (uint256 pxpCost) {
        address playerMgmt = addressRegistry.playerMgmt();
        address pdp = addressRegistry.pdp();

        uint256 userPlayerId = IPDP(pdp).getPlayerId(msg.sender);
        uint256 userLevel = uint256(IPlayerManagement(playerMgmt).getPlayerData(userPlayerId).playerRank);
        uint256 totalPlayers = IPlayerManagement(playerMgmt).getPlayersInRank(userLevel);
        uint256 totalPXPEarned = IPlayerManagement(playerMgmt).getTotalPXPEarned(userLevel);
        uint256 userLevelMultiplier = IPlayerManagement(playerMgmt).getLevelMultiplier(userLevel);
        uint256 levelMultiplierBasisPoint = 10000;

        if (totalPlayers != 0) {
            pxpCost =
                (totalPXPEarned * getRentalPremium(uActual) * userLevelMultiplier) /
                totalPlayers /
                MAX_RATE /
                levelMultiplierBasisPoint;
        } else {
            revert NoPlayer(userLevel);
        }
    }

    function setRBase(uint256 _rBase) external onlyOwner {
        if (_rBase > MAX_RATE) revert GreaterThanMaxRate(_rBase);
        rBase = _rBase;

        emit RBaseSet(_rBase);
    }

    function setUOpt(uint256 _uOpt) external onlyOwner {
        if (_uOpt == 0) revert ZeroValue();
        if (_uOpt >= MAX_RATE) revert GreaterThanMaxRate(_uOpt);
        uOpt = _uOpt;

        emit UOptSet(_uOpt);
    }

    function setRSlop1(uint256 _rSlope1) external onlyOwner {
        if (_rSlope1 > MAX_RATE) revert GreaterThanMaxRate(_rSlope1);
        rSlope1 = _rSlope1;

        emit RSlope1Set(_rSlope1);
    }

    function setRSlop2(uint256 _rSlope2) external onlyOwner {
        if (_rSlope2 > MAX_RATE) revert GreaterThanMaxRate(_rSlope2);
        rSlope2 = _rSlope2;

        emit RSlope2Set(_rSlope2);
    }
}