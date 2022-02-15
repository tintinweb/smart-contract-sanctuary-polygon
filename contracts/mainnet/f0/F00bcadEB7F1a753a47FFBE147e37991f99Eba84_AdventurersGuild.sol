// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "../system/HSystemChecker.sol";
import "../milk/ITreasury.sol";
import "../items/IPetInteractionHandler.sol";


contract AdventurersGuild is HSystemChecker {

    address public _petInteractionHandlerContractAddress;
    address public _treasuryContractAddress;

    // @dev Avg expected $MILK from manual questing * 0.6
    uint256 public _dailyRate = 756 ether;

    /// @dev Maps pet token id to the last claim time
    mapping(uint256 => uint256) public _lastClaim;

    /// @dev Map pet token id to a bool if staked or not
    mapping(uint256 => bool) public _staked;

    event LogAdventuringGoldClaimed(address user, uint256 gold, uint256 time, uint256 uuid);

    event LogPetStaked(address user, uint256[] tokenIds);
    event LogPetUnStaked(address user, uint256[] tokenIds);

    constructor(address systemCheckerContractAddress, address treasuryContractAddress, address petInteractionHandlerContractAddress) HSystemChecker(systemCheckerContractAddress) {
        _treasuryContractAddress = treasuryContractAddress;
        _petInteractionHandlerContractAddress = petInteractionHandlerContractAddress;
    }

    /// @notice Add a pet to the adventurers guild
    /// @dev Sets the last claim time as the block timestamp
    /// @param owner - address of the pet owner
    /// @param tokenIds - array of pet ids to stake
    function stake(
        address owner,
        uint256[] calldata tokenIds
    ) public onlyRole(GAME_ROLE) isUser(owner) {
        IPetInteractionHandler pi = IPetInteractionHandler(_petInteractionHandlerContractAddress);

        for(uint256 i; i < tokenIds.length; i++) {
            require(!_staked[tokenIds[i]], "AG 101 - Pet is already staked");
            require(pi.getCurrentPetStage(tokenIds[i]) == 3, "AG 103 - Pet must be final form to be staked");

            _lastClaim[tokenIds[i]] = block.timestamp;

            _staked[tokenIds[i]] = true;
        }

        emit LogPetStaked(owner, tokenIds);
    }

    /// @notice Remove a pet from the adventurers guild
    /// @dev Calls processClaim with an extra boolean to unstake at the same time
    /// @dev this saves us running an extra loop
    /// @param owner - owner of the pet
    /// @param tokenIds - the pet ids to unstake
    /// @param uuid - UUID for backend purposes
    function unStake(
        address owner,
        uint256[] calldata tokenIds,
        uint256 uuid
    ) public onlyRole(GAME_ROLE) isUser(owner) {
        _processClaim(owner, tokenIds, block.timestamp, uuid, true);

        emit LogPetUnStaked(owner, tokenIds);
    }

    /// @notice Claim gold for an owner with an array of pet token ids
    /// @dev It is vital that this call from a trusted source as the token ids could
    /// @dev be stacked and someone could claim against a single pet multiple times
    /// @dev we also have no way to verify pet ownership
    /// @dev Rate limited is imposed
    /// @param owner Address to pay gold to
    /// @param ids Array of cat ids being claimed against
    function claim(
        address owner,
        uint256[] calldata ids,
        uint256 uuid
    ) public onlyRole(GAME_ROLE) isUser(owner) {
        _processClaim(owner, ids, block.timestamp, uuid, false);
    }

    /// @notice Calculates the current gold claim amount for staked pets
    /// @param ids - array of pet ids to calculate for
    /// @param timestamp - epoch time to calculate the claim amount up to
    function calculateClaim(
        uint256[] calldata ids,
        uint256 timestamp
    ) public view returns (uint256) {
        uint256 currentTime = timestamp;
        if (currentTime == 0) {
            currentTime = block.timestamp;
        }

        uint256 reward;
        // Iterate over each pet and check what rewards are owed
        for(uint256 i; i < ids.length; i++) {
            if (!_staked[ids[i]]) {
                continue;
            }
            require(currentTime >= _lastClaim[ids[i]], "AG 400 - Cannot calculate claim for negative time difference");

            // Reward owner based on fraction of a day
            reward += (_dailyRate * (currentTime - _lastClaim[ids[i]])) / 86400;
        }

        return reward;
    }

    /// @notice Calculates and processes the current gold claim amount for staked pets
    /// @dev If unstake is true, also removes the pet from the adventurers guild
    /// @param owner - address of the pet owner
    /// @param ids - array of pet ids to calculate for
    /// @param currentTime - the time to claim up to
    /// @param uuid - UUID for backend reasons
    /// @param unstake - boolean to unstake or not
    function _processClaim(
        address owner,
        uint256[] calldata ids,
        uint256 currentTime,
        uint256 uuid,
        bool unstake
    ) internal {
        ITreasury treasury = ITreasury(_treasuryContractAddress);

        uint256 reward = calculateClaim(ids, currentTime);

        // Iterate over each pet and update last claim time
        for(uint256 i; i < ids.length; i++) {
            require(_staked[ids[i]], "AG 102 - Pet is not staked");

            _lastClaim[ids[i]] = currentTime;

            if (unstake) {
                _staked[ids[i]] = false;
            }
        }

        treasury.mint(owner, reward);

        emit LogAdventuringGoldClaimed(owner, reward, currentTime, uuid);
    }

    /// @notice Returns whether a pet is staked in the guild or not
    /// @param tokenId - the pet token id
    /// @return isStaked - boolean result
    function isPetStaked(uint256 tokenId) external view returns (bool isStaked) {
        return _staked[tokenId];
    }

    /// @notice Returns the last claim time for a given pet
    /// @param tokenId - the pet token id to check the claim time of
    /// @return time - epoch time of last claim
    function getLastClaimTime(uint256 tokenId) external view returns (uint256 time) {
        return _lastClaim[tokenId];
    }

    /// @notice Set the daily rate earned by each pet
    /// @dev Rate has 18 decimals, so a daily rate of 5 gold should be entered as 5x10^18
    /// @param rate - the daily rate
    function setDailyRate(uint256 rate) external onlyRole(ADMIN_ROLE) {
        require(rate > 86399, "AG 104 - Daily rate value too low");
        _dailyRate = rate;
    }

    /// @notice Push new address for the treasury Contract
    /// @param treasuryContractAddress - address of the new treasury contract
    function setTreasuryContractAddress(address treasuryContractAddress) external onlyRole(ADMIN_ROLE) {
        _treasuryContractAddress = treasuryContractAddress;
    }

    /// @notice Push new address for the pet interaction handler
    /// @param petInteractionHandlerContractAddress - address of the new pet interaction handler
    function setPetInteractionHandlerContractAddress(address petInteractionHandlerContractAddress) external onlyRole(ADMIN_ROLE) {
        _petInteractionHandlerContractAddress = petInteractionHandlerContractAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISystemChecker.sol";
import "./RolesAndKeys.sol";

contract HSystemChecker is RolesAndKeys {

    ISystemChecker _systemChecker;
    address public _systemCheckerContractAddress;

    constructor(address systemCheckerContractAddress) {
        _systemCheckerContractAddress = systemCheckerContractAddress;
        _systemChecker = ISystemChecker(systemCheckerContractAddress);
    }

    /// @notice Check if an address is a registered user or not
    /// @dev Triggers a require in systemChecker
    modifier isUser(address user) {
        _systemChecker.isUser(user);
        _;
    }

    /// @notice Check that the msg.sender has the desired role
    /// @dev Triggers a require in systemChecker
    modifier onlyRole(bytes32 role) {
        require(_systemChecker.hasRole(role, _msgSender()), "SC: Invalid transaction source");
        _;
    }

    /// @notice Push new address for the SystemChecker Contract
    /// @param systemCheckerContractAddress - address of the System Checker
    function setSystemCheckerContractAddress(address systemCheckerContractAddress) external onlyRole(ADMIN_ROLE) {
        _systemCheckerContractAddress = systemCheckerContractAddress;
        _systemChecker = ISystemChecker(systemCheckerContractAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasury {
    function balanceOf(address account) external view returns (uint256);
    function withdraw(address user, uint256 amount) external;
    function burn(address owner, uint256 amount) external;
    function mint(address owner, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPetInteractionHandler {
    function getCurrentPetStage(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISystemChecker {
    function createNewRole(bytes32 role) external;
    function hasRole(bytes32 role, address account) external returns (bool);
    function hasPermission(bytes32 role, address account) external;
    function isUser(address user) external;
    function getSafeAddress(bytes32 key) external returns (address);
    function grantRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

abstract contract RolesAndKeys is Context {
    // ROLES
    bytes32 constant MASTER_ROLE = keccak256("MASTER_ROLE");
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 constant GAME_ROLE = keccak256("GAME_ROLE");
    bytes32 constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
    bytes32 constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    // KEYS
    bytes32 constant MARKETPLACE_KEY_BYTES = keccak256("MARKETPLACE");
    bytes32 constant SYSTEM_KEY_BYTES = keccak256("SYSTEM");
    bytes32 constant QUEST_KEY_BYTES = keccak256("QUEST");
    bytes32 constant BATTLE_KEY_BYTES = keccak256("BATTLE");
    bytes32 constant HOUSE_KEY_BYTES = keccak256("HOUSE");
    bytes32 constant QUEST_GUILD_KEY_BYTES = keccak256("QUEST_GUILD");

    // COMMON
    bytes32 constant public PET_BYTES = 0x5065740000000000000000000000000000000000000000000000000000000000;
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