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
pragma solidity ^0.8.17;

//  ==========  EXTERNAL IMPORTS    ==========

import "@openzeppelin/contracts/access/Ownable.sol";

//  ==========  INTERNAL IMPORTS    ==========

import "./IGuildRental.sol";
import "./IGuild.sol";
import "./IGuildID.sol";

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

contract GuildRental is IGuildRental, Ownable {
    /// @notice Guild contract address
    IGuild public guildContract;

    /// @notice Base Variable Rate
    uint256 public rBase;

    /// @notice Optimal Utilization Rate of the Asset Pool
    uint256 public uOpt;

    /// @dev Rates of exponential increase
    uint256 public rSlope1;
    uint256 public rSlope2;

    uint256 public constant MAX_RATE = 100_0000;
    uint256 public constant BASIS_POINT = 10000;

    event GuildContractSet(address indexed guildContract);
    event RBaseSet(uint256 rBase);
    event UOptSet(uint256 uOpt);
    event RSlope1Set(uint256 rSlope1);
    event RSlope2Set(uint256 rSlope2);

    error ZeroAddress();
    error ZeroValue();
    error GreaterThanMaxRate(uint256 rate);
    error NoPlayer(uint256 playerRank);

    /*///////////////////////////////////////////////////////////////
                                USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(address _guildContract, uint256 _rBase, uint256 _uOpt, uint256 _rSlope1, uint256 _rSlope2) {
        if (_guildContract == address(0)) revert ZeroAddress();
        if (_rBase > MAX_RATE) revert GreaterThanMaxRate(_rBase);
        // if (_uOpt == 0) revert ZeroValue();
        if (_uOpt >= MAX_RATE) revert GreaterThanMaxRate(_uOpt);
        if (_rSlope1 > MAX_RATE) revert GreaterThanMaxRate(_rSlope1);
        if (_rSlope2 > MAX_RATE) revert GreaterThanMaxRate(_rSlope2);

        guildContract = IGuild(_guildContract);
        rBase = _rBase;
        uOpt = _uOpt;
        rSlope1 = _rSlope1;
        rSlope2 = _rSlope2;
    }

    /*///////////////////////////////////////////////////////////////
                            OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setGuildContract(address _guildContract) external onlyOwner {
        if (_guildContract == address(0)) revert ZeroAddress();
        guildContract = IGuild(_guildContract);

        emit GuildContractSet(_guildContract);
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

    /*///////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the actual utilization rate of the asset pool
    /// @param _totalDeposit Total number of assets deposited in the pool
    /// @param _totalRental Total number of rentals
    function getActualUtilizationRate(uint256 _totalDeposit, uint256 _totalRental) external pure returns (uint256) {
        return (_totalRental * MAX_RATE) / _totalDeposit;
    }

    /// @notice Returns the rental premium based on the actual utilaization rate
    /// @param _uActual _uActual utilization rate based on BASIS_POINT
    /// @return rPremium Rental premium based on BASIS_POINT
    function getRentalPremium(uint256 _uActual) public view returns (uint256 rPremium) {
        if (_uActual < uOpt) {
            rPremium = rBase + (_uActual * rSlope1) / uOpt;
        } else {
            rPremium = rBase + rSlope1 + ((_uActual - uOpt) * rSlope2) / (MAX_RATE - uOpt);
        }
    }

    /// @notice Returns the XP amount needed for renting the asset in the pool
    /// @param _user User address to rent the asset in the pool
    /// @param _uActual Actual utilization rate based on BASIS_POINT
    /// @return xpCost XP amount
    function getXPCost(address _user, uint256 _uActual) external view returns (uint256 xpCost) {
        IGuild.GuildParameters memory guildParams = guildContract.getGuildParams();
        IGuildID guildID = IGuildID(guildParams.guildID);

        uint256 userGuildID = guildID.getID(_user);
        uint256 userGuildRank = uint256(guildID.getRank(userGuildID));
        uint256 totalUsersInRank = guildID.getMembersInRank(userGuildRank);
        uint256 totalXPEarned = guildContract.getTotalXPEarnedPerRank(userGuildRank);
        uint256 userRankMultiplier = guildContract.getRankMultiplier(userGuildRank);
        uint256 rankMultiplierBasisPoint = 10000;

        if (totalUsersInRank != 0) {
            xpCost =
                (totalXPEarned * getRentalPremium(_uActual) * userRankMultiplier) /
                totalUsersInRank /
                MAX_RATE /
                rankMultiplierBasisPoint;
        } else {
            revert NoPlayer(userGuildRank);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGuild {
    struct GuildParameters {
        string guildName;
        string guildSymbol;
        address guildID;
        address guildXP;
        address guildToken;
        address guildTreasury;
        uint256 rankUpBasePriceXP;
        uint256 rankMultiplierBasisPoints;
        address guildTokenOracle;
        address guildBank;
        address guildRental;
    }

    struct GuildFees {
        uint256 mintETH;
        uint256 nameETH;
        uint256 rankETH;
        uint256 mintGuildToken;
        uint256 nameGuildToken;
        uint256 rankGuildToken;
        uint256 mintUSD;
        uint256 nameUSD;
        uint256 rankUSD;
    }

    function burnXPFrom(address from, uint256 amount) external;

    function getGuildParams() external view returns (GuildParameters memory params_);

    function getTotalXPEarnedPerRank(uint256 rank) external view returns (uint256 totalPxpEarnedPerRank_);

    function getRankMultiplier(uint256 rank) external view returns (uint256 rankMultiplier_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGuildID {
    struct GuildIDParameters {
        string name;
        string symbol;
        string imageUrl;
        uint256 minRankForTransfers;
        uint256 maxRank;
    }

    function mint(address _user, string calldata _name) external;

    function upgradeName(address _user, string calldata _newName) external;

    function upgradeRank(address _user) external;

    function updateParams(GuildIDParameters memory _params) external;

    function getID(address _member) external view returns (uint256 tokenID_);

    function getName(uint256 _tokenID) external view returns (string memory name_);

    function getRank(uint256 _tokenID) external view returns (uint64 rank_);

    function getMintDate(uint256 _tokenID) external view returns (uint64 mintDate_);

    function getMembersInRank(uint256 _rank) external view returns (uint256 membersInRank_);

    function totalSupply() external view returns (uint256 totalSupply_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGuildRental {
    function getActualUtilizationRate(
        uint256 _totalDeposit,
        uint256 _totalRental
    ) external view returns (uint256 actualUtilizationRate);

    function getXPCost(address _player, uint256 _uActual) external returns (uint256 xpCost);
}