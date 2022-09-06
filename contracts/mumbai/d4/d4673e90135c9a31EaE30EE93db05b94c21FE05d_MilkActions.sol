// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../system/HSystemChecker.sol';
import '../../../common/Multicall.sol';
import '../../items/IItemFactory.sol';
import '../ITreasury.sol';

contract MilkActions is HSystemChecker, Multicall {
    address public _itemFactoryContractAddress;
    address public _treasuryContractAddress;

    IItemFactory _itemFactory;
    ITreasury _treasury;

    struct Cost {
        uint64 price;
        uint256[] itemIds;
        uint256[] itemAmounts;
    }

    mapping(bytes32 => Cost) public _actionCost;
    mapping(bytes32 => mapping(address => uint256)) _actionsBought;

    /// @notice Emitted when the Item Factory contract address is updated
    /// @param account - Address of user triggering action
    /// @param actionKey - Key of action being triggered
    /// @param data - Action data used on backend
    event LogBuyAction(address indexed account, bytes32 indexed actionKey, bytes32 data);

    /// @notice Emitted when action is created
    /// @param actionKey - Key of action being triggered
    /// @param price - Price of action in gwei
    /// @param itemIds - Array of required itemIds
    /// @param itemAmounts - Array of required item amounts
    event LogCreateAction(
        bytes32 actionKey,
        uint64 price,
        uint256[] itemIds,
        uint256[] itemAmounts
    );

    /// @notice Emitted when action is edited
    /// @param actionKey - Key of action being triggered
    /// @param price - Price of action in gwei
    /// @param itemIds - Array of required itemIds
    /// @param itemAmounts - Array of required item amounts
    event LogEditAction(bytes32 actionKey, uint64 price, uint256[] itemIds, uint256[] itemAmounts);

    /// @notice Emitted when action is deleted
    /// @param actionKey - Key of action being triggered
    event LogDeleteAction(bytes32 actionKey);

    /// @notice Emitted when the Item Factory contract address is updated
    /// @param itemFactoryContractAddress - Item Factory contract address
    event LogSetItemFactoryContractAddress(address itemFactoryContractAddress);

    /// @notice Emitted when the Treasury contract address is updated
    /// @param treasuryContractAddress - Treasury contract address
    event LogSetTreasuryContractAddress(address treasuryContractAddress);

    /// @notice Check that a category exists
    /// @param key - Identifier for the desired category
    modifier actionExists(bytes32 key) {
        require(_actionCost[key].price > 0, 'MA 400: Action doesnt exist');
        _;
    }

    constructor(
        address systemCheckerContractAddress,
        address itemFactoryContractAddress,
        address treasuryContractAddress
    ) HSystemChecker(systemCheckerContractAddress) {
        _itemFactoryContractAddress = itemFactoryContractAddress;
        _treasuryContractAddress = treasuryContractAddress;
    }

    /// @notice Buy whatever from the store
    /// @dev All validation checks are handled by burn() and burnItem()
    /// @param buyer - Address of buyer
    /// @param actionKey - Key of action being bought
    /// @param data - Data required for processing
    function buy(
        address buyer,
        bytes32 actionKey,
        bytes32 data
    ) public actionExists(actionKey) onlyRole(GAME_ROLE) {
        Cost memory cost = _actionCost[actionKey];

        ITreasury treasury = ITreasury(_treasuryContractAddress);
        IItemFactory itemFactory = IItemFactory(_itemFactoryContractAddress);

        // burn MILK
        treasury.burn(buyer, uint256(cost.price) * 1 gwei);

        for (uint256 i; i < cost.itemIds.length; ) {
            itemFactory.burnItem(buyer, cost.itemIds[i], cost.itemAmounts[i]);
            unchecked {
                ++i;
            }
        }

        unchecked {
            ++ _actionsBought[actionKey][buyer];
        }

        emit LogBuyAction(buyer, actionKey, data);
    }

    /// @notice Create a new actions
    /// @param actionKey - Key identifier for new action
    /// @param price - Price of new action in gwei
    /// @param itemIds - Array of required itemIds
    /// @param itemAmounts - Array of required item amounts
    function createAction(
        bytes32 actionKey,
        uint64 price,
        uint256[] calldata itemIds,
        uint256[] calldata itemAmounts
    ) external onlyRole(ADMIN_ROLE) {
        _createAction(actionKey, price, itemIds, itemAmounts);
        emit LogCreateAction(actionKey, price, itemIds, itemAmounts);
    }

    /// @notice Edit action
    /// @param actionKey - Key identifier for new action
    /// @param price - Price of new action in gwei
    /// @param itemIds - Array of required itemIds
    /// @param itemAmounts - Array of required item amounts
    function editAction(
        bytes32 actionKey,
        uint64 price,
        uint256[] calldata itemIds,
        uint256[] calldata itemAmounts
    ) external actionExists(actionKey) onlyRole(ADMIN_ROLE) {
        _createAction(actionKey, price, itemIds, itemAmounts);
        emit LogEditAction(actionKey, price, itemIds, itemAmounts);
    }

    /// @notice Edit action
    /// @param actionKey - Key identifier of action to delete
    function deleteAction(bytes32 actionKey) external actionExists(actionKey) onlyRole(ADMIN_ROLE) {
        delete _actionCost[actionKey];
        emit LogDeleteAction(actionKey);
    }

    /// @notice Get number of actions a user bought
    /// @param actionKey - Key identifier of action to delete
    /// @param buyer - Address of buyer
    /// @return uint256 - Number of actions bought
    function getActionsBought(bytes32 actionKey, address buyer) external view returns(uint256){
        return _actionsBought[actionKey][buyer];
    }

    /// @notice Push new address for the Item Factory Contract
    /// @param itemFactoryContractAddress - Address of the Item Factory
    function setItemFactoryContractAddress(address itemFactoryContractAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        _itemFactoryContractAddress = itemFactoryContractAddress;
        emit LogSetItemFactoryContractAddress(itemFactoryContractAddress);
    }

    /// @notice Push new address for the Treasury Contract
    /// @param treasuryContractAddress - Address of the Item Factory
    function setTreasuryContractAddress(address treasuryContractAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        _treasuryContractAddress = treasuryContractAddress;
        emit LogSetTreasuryContractAddress(treasuryContractAddress);
    }

    /// @notice Create action
    /// @param actionKey - Key identifier for new action
    /// @param price - Price of new action in gwei
    /// @param itemIds - Array of required itemIds
    /// @param itemAmounts - Array of required item amounts
    function _createAction(
        bytes32 actionKey,
        uint64 price,
        uint256[] calldata itemIds,
        uint256[] calldata itemAmounts
    ) internal {
        require(price > 0, 'MA 100 - Price cant be zero');
        require(itemIds.length == itemAmounts.length, 'MA 101 - Array mismatch');
        _actionCost[actionKey] = Cost(price, itemIds, itemAmounts);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ISystemChecker.sol';
import './RolesAndKeys.sol';

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
        require(_systemChecker.hasRole(role, _msgSender()), 'SC: Invalid transaction source');
        _;
    }

    /// @notice Push new address for the SystemChecker Contract
    /// @param systemCheckerContractAddress - address of the System Checker
    function setSystemCheckerContractAddress(address systemCheckerContractAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        _systemCheckerContractAddress = systemCheckerContractAddress;
        _systemChecker = ISystemChecker(systemCheckerContractAddress);
    }
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
        if (_returnData.length < 68) return 'Transaction reverted silently';

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
        external
        payable
        override
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
pragma solidity ^0.8.0;

interface IItemFactory {
    function burnItem(
        address owner,
        uint256 itemTokenId,
        uint256 amount
    ) external;

    function mintItem(
        address owner,
        uint256 itemTokenId,
        uint256 amount
    ) external;

    function gameSafeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function getItemById(uint256 itemTokenId)
        external
        returns (bytes32 categoryKey, bytes32 typeKey);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasury {
    function balanceOf(address account) external view returns (uint256);

    function withdraw(address user, uint256 amount) external;

    function burn(address owner, uint256 amount) external;

    function mint(address owner, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
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
    bytes32 constant MASTER_ROLE = keccak256('MASTER_ROLE');
    bytes32 constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    bytes32 constant GAME_ROLE = keccak256('GAME_ROLE');
    bytes32 constant CONTRACT_ROLE = keccak256('CONTRACT_ROLE');
    bytes32 constant TREASURY_ROLE = keccak256('TREASURY_ROLE');

    // KEYS
    bytes32 constant MARKETPLACE_KEY_BYTES = keccak256('MARKETPLACE');
    bytes32 constant SYSTEM_KEY_BYTES = keccak256('SYSTEM');
    bytes32 constant QUEST_KEY_BYTES = keccak256('QUEST');
    bytes32 constant BATTLE_KEY_BYTES = keccak256('BATTLE');
    bytes32 constant HOUSE_KEY_BYTES = keccak256('HOUSE');
    bytes32 constant QUEST_GUILD_KEY_BYTES = keccak256('QUEST_GUILD');

    // COMMON
    bytes32 public constant PET_BYTES =
        0x5065740000000000000000000000000000000000000000000000000000000000;
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

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data, bool revertOnFail)
        external
        payable
        returns (bytes[] memory results);
}