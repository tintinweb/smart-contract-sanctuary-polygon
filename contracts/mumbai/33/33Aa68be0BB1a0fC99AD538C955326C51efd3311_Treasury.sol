// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../system/RolesAndKeys.sol";
import "../system/HSystemChecker.sol";
import "./IMilkChild.sol";
import "../../common/Multicall.sol";

contract Treasury is HSystemChecker, Multicall {
    IMilkChild _milkChild;
    address public _milkChildContractAddress;

    uint256 public _baseRate = 1000 ether;
    // Date contract is launched
    uint256 public _contractStartTime;

    mapping(uint256 => uint256) public _lastUpdate;
    // Class bonus
    mapping(uint256 => uint256) public _catClassBonus;

    /// @notice Emitted when gold is claimed
    /// @param user - Address to pay gold to
    /// @param gold - Amount of gold claimed
    /// @param time - Time gold was claimed
    /// @param uuid - Unique id for backend signing
    event LogGoldClaimed(address user, uint256 gold, uint256 time, uint256 uuid);

    /// @notice Emitted when the start time for MILK earning is set
    /// @param timestamp - Unix timestamp UTC in seconds
    event LogSetStartTime(uint256 timestamp);

    /// @notice Emitted when the base gold rate for all cats is set
    /// @param baseRate - Daily earn amount of gold
    event LogSetBaseRate(uint256 baseRate);

    /// @notice Emitted when the cat class to daily earning bonus is set
    /// @dev Bonus should account for tiers [3 ... 11] where 11 are the unknown cats
    /// @param catClass - Cat classes
    /// @param bonus - Daily bonus per class, respective to the first param index
    event LogSetCatClassBonus(uint256[] catClass, uint256[] bonus);

    /// @notice Emitted when the Milk Child contract address is updated
    /// @param milkChildContractAddress - Milk Child contract address
    event LogSetMilkChildContractAddress(address milkChildContractAddress);

    constructor(address systemCheckerContractAddress, address milkChildContractAddress) HSystemChecker(systemCheckerContractAddress) {
        _contractStartTime = block.timestamp;
        _milkChildContractAddress = milkChildContractAddress;
        _milkChild = IMilkChild(milkChildContractAddress);
    }

    /// @notice Claim gold for an owner, cats[] and the reward
    /// @dev It is vital that this call from a trusted source as ids and classes could otherwise
    /// @dev be stacked and someone could claim against a single cat multiple times
    /// @dev Rate limiting is imposed by the client
    /// @param owner - Address to pay gold to
    /// @param catIds - Array of cat ids being claimed against
    /// @param catClasses - Array of cat classes
    /// @param uuid - Unique id for backend signing
    function claim(
        address owner,
        uint256[] calldata catIds,
        uint256[] calldata catClasses,
        uint256 uuid
    ) public onlyRole(GAME_ROLE) isUser(owner) {
        // Time now
        uint256 currentTime = block.timestamp;
        uint256 reward;

        // Stop claiming against too many pets, prevent gassing out
        // Tested up to 2000 cats, 1000+ was the limit, just being careful
        require(catIds.length < 601, "G: Claimed for too many cats");

        // Iterate over each cat and check what rewards are owed
        for (uint256 i; i < catIds.length; i++) {
            uint256 catClass = catClasses[i];
            uint256 catId = catIds[i];

            // This check doubles up to check a cat has the desired class and the class has a bonus
            // If cat[0] and catClasses[12] are submitted catClassBonus[i] would return 0
            // This double check trick saves us gas on the loop
            // It does however make the assumption that admin have submitted the correct class bonuses
            require(_catClassBonus[catClass] > 0, "G: Cat class has no bonus");

            // Determine what time to calc claim with
            uint256 timeToken = _lastUpdate[catId];
            if (timeToken == 0) timeToken = _contractStartTime;

            // For the sake of saving gas all maths is raw and done inline
            // _baseRate > 86399
            // currentTime is always > timeToken
            unchecked {
                reward += ((_baseRate + _catClassBonus[catClass]) * (currentTime - timeToken)) / 86400;
            }

            // Track claim time per cat
            _lastUpdate[catId] = currentTime;
        }

        _milkChild.gameMint(owner, reward);

        emit LogGoldClaimed(owner, reward, currentTime, uuid);
    }

    /// @notice Calculate how much gold can be earned for these cats
    /// @param catIds - Array of cat ids being claimed against
    /// @param catClasses - Array if cat classes
    /// @return reward - The amount claimed (redundant? unless a function specifically needs it)
    function calcClaim(
        uint256[] calldata catIds,
        uint256[] calldata catClasses
    ) public view returns (uint256 reward) {
        require(catIds.length == catClasses.length, "G: Invalid data length");

        // Iterate over each cat and check what rewards are owed
        // claim() for full notes
        for (uint256 i; i < catIds.length; i++) {
            uint256 catClass = catClasses[i];
            require(_catClassBonus[catClass] > 0, "G: Cat class has no bonus");
            uint256 timeToken = _lastUpdate[catIds[i]];
            if (timeToken == 0) timeToken = _contractStartTime;

            unchecked {
                reward += ((_baseRate + _catClassBonus[catClass]) * (block.timestamp - timeToken)) / 86400;
            }
        }

        return reward;
    }


    ///@notice called when user wants to withdraw tokens back to root chain
    ///@dev Should burn user's tokens. This transaction will be verified when exiting on root chain
    ///@dev User requests withdrawal and game system handles it so we have to stipulate the users address
    ///@dev _burn() handles quantity check
    ///@param owner - Address of user withdrawing tokens
    ///@param amount - Amount of tokens to withdraw
    function withdraw(address owner, uint256 amount) external onlyRole(GAME_ROLE) {
        _milkChild.gameWithdraw(owner, amount);
    }

    /// @notice Check balance of MILK for a given user
    /// @param user - Address to mint check
    /// @return uint256 - Amount of Milk
    function balanceOf(address user) external view returns (uint256) {
        return _milkChild.balanceOf(user);
    }

    /// @notice Mint a user some Milk
    /// @dev Only activate users should ever be minted Milk
    /// @dev Reserved for game generation of Milk via quests/battles/etc...
    /// @dev Milk contract handles and isUser()
    /// @param to - Address to mint to
    /// @param amount - Amount of Gold to send - wei
    function mint(address to, uint256 amount) external onlyRole(CONTRACT_ROLE) {
        _milkChild.gameMint(to, amount);
    }

    /// @notice Allows system to burn tokens
    /// @dev Milk contract handles isUser() and amount check
    /// @param owner - Holder address to burn tokens of
    /// @param amount - Amount of tokens to burn
    function burn(address owner, uint256 amount) external onlyRole(CONTRACT_ROLE) {
        _milkChild.gameBurn(owner, amount);
    }

    /// @notice Game transferring around itself to handle Milk transfers
    /// @param sender - Address to transfer from
    /// @param recipient - Address to transfer to
    /// @param amount - Amount of Gold to send - wei
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external onlyRole(CONTRACT_ROLE) {
        _milkChild.gameTransferFrom(sender, recipient, amount);
    }

    /// @notice Set the start time for MILK earning
    /// @dev call this before unlocking mint earning in MilkChild
    /// @param timestamp - Unix timestamp UTC in seconds
    function setStartTime(uint256 timestamp) external onlyRole(ADMIN_ROLE) {
        require(timestamp <= block.timestamp, "G: We cant travel into the future");
        _contractStartTime = timestamp;

        emit LogSetStartTime(timestamp);
    }

    /// @notice Set the base gold rate for all cats
    /// @dev See the $MILK balancing sheet for values
    /// @param baseRate - Daily earn amount of Milk
    function setBaseRate(uint256 baseRate) external onlyRole(ADMIN_ROLE) {
        require(baseRate > 86399, "G: Base rate value too low");
        _baseRate = baseRate;

        emit LogSetBaseRate(baseRate);
    }

    /// @notice Log cat class to daily earning bonus
    /// @dev Bonus should account for tiers [3 ... 11] where 11 are the unknown cats
    /// @param catClass[] - Cat classes
    /// @param bonus[] - Daily bonus per class, respective to the first param index
    function setCatClassBonus(
        uint256[] calldata catClass,
        uint256[] calldata bonus
    ) external onlyRole(ADMIN_ROLE) {
        for (uint256 i; i < catClass.length; i++) {
            _catClassBonus[catClass[i]] = bonus[i];
        }

        emit LogSetCatClassBonus(catClass, bonus);
    }

    /// @notice Push new address for the MilkChild Contract
    /// @param milkChildContractAddress - Address of the MilkChild contract
    function setMilkChildContractAddress(address milkChildContractAddress) external onlyRole(ADMIN_ROLE) {
        _milkChildContractAddress = milkChildContractAddress;
        _milkChild = IMilkChild(milkChildContractAddress);

        emit LogSetMilkChildContractAddress(milkChildContractAddress);
    }
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

interface IMilkChild {
    function mint(address user, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function gameWithdraw(address user, uint256 amount) external;

    function gameBurn(address owner, uint256 amount) external;

    function gameMint(address owner, uint256 amount) external;

    function gameTransferFrom(address sender, address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IMulticall.sol';

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /**
      * @dev mostly lifted from https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
      */
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
        // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
        // All that remains is the revert string
    }

    /**
      * @inheritdoc IMulticall
      * @dev does a basic multicall to any function on this contract
      */
    function multicall(bytes[] calldata data, bool revertOnFail)
    external payable override
    returns (bytes[] memory returning)
    {
        returning = new bytes[](data.length);
        bool success;
        bytes memory result;
        for (uint256 i = 0; i < data.length; i++) {
            (success, result) = address(this).delegatecall(data[i]);

            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }
            returning[i] = result;
        }
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

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data, bool revertOnFail) external payable returns (bytes[] memory results);
}