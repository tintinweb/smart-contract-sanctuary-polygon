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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import { ITokenBalance } from './interfaces/ITokenBalance.sol';
import { ManagerRole } from './roles/ManagerRole.sol';
import './helpers/TransferHelper.sol' as TransferHelper;
import './Constants.sol' as Constants;

abstract contract BalanceManagement is ManagerRole {
    error ReservedTokenError();

    function cleanup(address _tokenAddress, uint256 _tokenAmount) external onlyManager {
        if (isReservedToken(_tokenAddress)) {
            revert ReservedTokenError();
        }

        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeTransferNative(msg.sender, _tokenAmount);
        } else {
            TransferHelper.safeTransfer(_tokenAddress, msg.sender, _tokenAmount);
        }
    }

    function tokenBalance(address _tokenAddress) public view returns (uint256) {
        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return ITokenBalance(_tokenAddress).balanceOf(address(this));
        }
    }

    function isReservedToken(address /*_tokenAddress*/) public view virtual returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import { ManagerRole } from './roles/ManagerRole.sol';
import './helpers/AddressHelper.sol' as AddressHelper;
import './DataStructures.sol' as DataStructures;

abstract contract CallerGuard is ManagerRole {
    enum CallerGuardMode {
        ContractForbidden,
        ContractList,
        ContractAllowed
    }

    CallerGuardMode public callerGuardMode = CallerGuardMode.ContractForbidden;

    address[] public listedCallerGuardContractList;
    mapping(address => DataStructures.OptionalValue) public listedCallerGuardContractIndexMap;

    event SetCallerGuardMode(CallerGuardMode indexed callerMode);
    event SetListedCallerGuardContract(address indexed contractAddress, bool indexed isListed);

    error CallerGuardError(address caller);

    modifier checkCaller() {
        if (msg.sender != tx.origin) {
            bool condition = (callerGuardMode == CallerGuardMode.ContractAllowed ||
                (callerGuardMode == CallerGuardMode.ContractList &&
                    isListedCallerGuardContract(msg.sender)));

            if (!condition) {
                revert CallerGuardError(msg.sender);
            }
        }

        _;
    }

    function setCallerGuardMode(CallerGuardMode _callerGuardMode) external onlyManager {
        callerGuardMode = _callerGuardMode;

        emit SetCallerGuardMode(_callerGuardMode);
    }

    function setListedCallerGuardContracts(
        DataStructures.AccountToFlag[] calldata _items
    ) external onlyManager {
        for (uint256 index; index < _items.length; index++) {
            DataStructures.AccountToFlag calldata item = _items[index];

            if (item.flag) {
                AddressHelper.requireContract(item.account);
            }

            DataStructures.uniqueAddressListUpdate(
                listedCallerGuardContractList,
                listedCallerGuardContractIndexMap,
                item.account,
                item.flag
            );

            emit SetListedCallerGuardContract(item.account, item.flag);
        }
    }

    function listedCallerGuardContractCount() public view returns (uint256) {
        return listedCallerGuardContractList.length;
    }

    function fullListedCallerGuardContractList() public view returns (address[] memory) {
        return listedCallerGuardContractList;
    }

    function isListedCallerGuardContract(address _account) public view returns (bool) {
        return listedCallerGuardContractIndexMap[_account].isSet;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

uint256 constant DECIMALS_DEFAULT = 18;
uint256 constant INFINITY = type(uint256).max;
uint256 constant MILLIPERCENT_FACTOR = 100_000;
address constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

struct OptionalValue {
    bool isSet;
    uint256 value;
}

struct KeyToValue {
    uint256 key;
    uint256 value;
}

struct KeyToAddressValue {
    uint256 key;
    address value;
}

struct AccountToFlag {
    address account;
    bool flag;
}

function combinedMapSet(
    mapping(uint256 => address) storage _map,
    uint256[] storage _keyList,
    mapping(uint256 => OptionalValue) storage _keyIndexMap,
    uint256 _key,
    address _value
) returns (bool isNewKey) {
    isNewKey = !_keyIndexMap[_key].isSet;

    if (isNewKey) {
        uniqueListAdd(_keyList, _keyIndexMap, _key);
    }

    _map[_key] = _value;
}

function combinedMapRemove(
    mapping(uint256 => address) storage _map,
    uint256[] storage _keyList,
    mapping(uint256 => OptionalValue) storage _keyIndexMap,
    uint256 _key
) returns (bool isChanged) {
    isChanged = _keyIndexMap[_key].isSet;

    if (isChanged) {
        delete _map[_key];
        uniqueListRemove(_keyList, _keyIndexMap, _key);
    }
}

function uniqueListAdd(
    uint256[] storage _list,
    mapping(uint256 => OptionalValue) storage _indexMap,
    uint256 _value
) returns (bool isChanged) {
    isChanged = !_indexMap[_value].isSet;

    if (isChanged) {
        _indexMap[_value] = OptionalValue(true, _list.length);
        _list.push(_value);
    }
}

function uniqueListRemove(
    uint256[] storage _list,
    mapping(uint256 => OptionalValue) storage _indexMap,
    uint256 _value
) returns (bool isChanged) {
    OptionalValue storage indexItem = _indexMap[_value];

    isChanged = indexItem.isSet;

    if (isChanged) {
        uint256 itemIndex = indexItem.value;
        uint256 lastIndex = _list.length - 1;

        if (itemIndex != lastIndex) {
            uint256 lastValue = _list[lastIndex];
            _list[itemIndex] = lastValue;
            _indexMap[lastValue].value = itemIndex;
        }

        _list.pop();
        delete _indexMap[_value];
    }
}

function uniqueAddressListAdd(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value
) returns (bool isChanged) {
    isChanged = !_indexMap[_value].isSet;

    if (isChanged) {
        _indexMap[_value] = OptionalValue(true, _list.length);
        _list.push(_value);
    }
}

function uniqueAddressListRemove(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value
) returns (bool isChanged) {
    OptionalValue storage indexItem = _indexMap[_value];

    isChanged = indexItem.isSet;

    if (isChanged) {
        uint256 itemIndex = indexItem.value;
        uint256 lastIndex = _list.length - 1;

        if (itemIndex != lastIndex) {
            address lastValue = _list[lastIndex];
            _list[itemIndex] = lastValue;
            _indexMap[lastValue].value = itemIndex;
        }

        _list.pop();
        delete _indexMap[_value];
    }
}

function uniqueAddressListUpdate(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value,
    bool _flag
) returns (bool isChanged) {
    return
        _flag
            ? uniqueAddressListAdd(_list, _indexMap, _value)
            : uniqueAddressListRemove(_list, _indexMap, _value);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

error TokenBurnError();
error TokenMintError();
error ZeroAddressError();

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

error NonContractAddressError(address account);

function isContract(address _account) view returns (bool) {
    return _account.code.length > 0;
}

function requireContract(address _account) view {
    if (!isContract(_account)) {
        revert NonContractAddressError(_account);
    }
}

function requireContractOrZeroAddress(address _account) view {
    if (_account != address(0)) {
        requireContract(_account);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

error SafeApproveError();
error SafeTransferError();
error SafeTransferFromError();
error SafeTransferNativeError();

function safeApprove(address _token, address _to, uint256 _value) {
    // 0x095ea7b3 is the selector for "approve(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x095ea7b3, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeApproveError();
    }
}

function safeTransfer(address _token, address _to, uint256 _value) {
    // 0xa9059cbb is the selector for "transfer(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0xa9059cbb, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferError();
    }
}

function safeTransferFrom(address _token, address _from, address _to, uint256 _value) {
    // 0x23b872dd is the selector for "transferFrom(address,address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x23b872dd, _from, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferFromError();
    }
}

function safeTransferNative(address _to, uint256 _value) {
    (bool success, ) = _to.call{ value: _value }(new bytes(0));

    if (!success) {
        revert SafeTransferNativeError();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

interface ITokenBalance {
    function balanceOf(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

interface ITokenBurn {
    function burn(address _from, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

interface ITokenDecimals {
    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import { Pausable as PausableBase } from '@openzeppelin/contracts/security/Pausable.sol';
import { ManagerRole } from './roles/ManagerRole.sol';

abstract contract Pausable is PausableBase, ManagerRole {
    function pause() public onlyManager whenNotPaused {
        _pause();
    }

    function unpause() public onlyManager whenPaused {
        _unpause();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import { RoleBearers } from './RoleBearers.sol';

abstract contract AssetSpenderRole is RoleBearers {
    bytes32 private constant ROLE_KEY = keccak256('AssetSpender');

    event SetAssetSpender(address indexed account, bool indexed value);

    error OnlyAssetSpenderError();

    modifier onlyAssetSpender() {
        if (!isAssetSpender(msg.sender)) {
            revert OnlyAssetSpenderError();
        }

        _;
    }

    function isAssetSpender(address _account) public view returns (bool) {
        return _isRoleBearer(ROLE_KEY, _account);
    }

    function assetSpenderCount() public view returns (uint256) {
        return _roleBearerCount(ROLE_KEY);
    }

    function fullAssetSpenderList() public view returns (address[] memory) {
        return _fullRoleBearerList(ROLE_KEY);
    }

    function _setAssetSpender(address _account, bool _value) internal {
        _setRoleBearer(ROLE_KEY, _account, _value);

        emit SetAssetSpender(_account, _value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { RoleBearers } from './RoleBearers.sol';

abstract contract ManagerRole is Ownable, RoleBearers {
    bytes32 private constant ROLE_KEY = keccak256('Manager');

    event SetManager(address indexed account, bool indexed value);
    event RenounceManagerRole(address indexed account);

    error OnlyManagerError();

    modifier onlyManager() {
        if (!isManager(msg.sender)) {
            revert OnlyManagerError();
        }

        _;
    }

    function setManager(address _account, bool _value) public onlyOwner {
        _setRoleBearer(ROLE_KEY, _account, _value);

        emit SetManager(_account, _value);
    }

    function renounceManagerRole() public onlyManager {
        _setRoleBearer(ROLE_KEY, msg.sender, false);

        emit RenounceManagerRole(msg.sender);
    }

    function isManager(address _account) public view returns (bool) {
        return _isRoleBearer(ROLE_KEY, _account);
    }

    function managerCount() public view returns (uint256) {
        return _roleBearerCount(ROLE_KEY);
    }

    function fullManagerList() public view returns (address[] memory) {
        return _fullRoleBearerList(ROLE_KEY);
    }

    function _initRoles(
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) internal {
        address ownerAddress = _owner == address(0) ? msg.sender : _owner;

        for (uint256 index; index < _managers.length; index++) {
            setManager(_managers[index], true);
        }

        if (_addOwnerToManagers && !isManager(ownerAddress)) {
            setManager(ownerAddress, true);
        }

        if (ownerAddress != msg.sender) {
            transferOwnership(ownerAddress);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import { RoleBearers } from './RoleBearers.sol';

abstract contract MultichainRouterRole is RoleBearers {
    bytes32 private constant ROLE_KEY = keccak256('MultichainRouter');

    event SetMultichainRouter(address indexed account, bool indexed value);

    error OnlyMultichainRouterError();

    modifier onlyMultichainRouter() {
        if (!isMultichainRouter(msg.sender)) {
            revert OnlyMultichainRouterError();
        }

        _;
    }

    function isMultichainRouter(address _account) public view returns (bool) {
        return _isRoleBearer(ROLE_KEY, _account);
    }

    function multichainRouterCount() public view returns (uint256) {
        return _roleBearerCount(ROLE_KEY);
    }

    function fullMultichainRouterList() public view returns (address[] memory) {
        return _fullRoleBearerList(ROLE_KEY);
    }

    function _setMultichainRouter(address _account, bool _value) internal {
        _setRoleBearer(ROLE_KEY, _account, _value);

        emit SetMultichainRouter(_account, _value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import '../DataStructures.sol' as DataStructures;

abstract contract RoleBearers {
    mapping(bytes32 => address[]) private roleBearerTable;
    mapping(bytes32 => mapping(address => DataStructures.OptionalValue))
        private roleBearerIndexTable;

    function _setRoleBearer(bytes32 _roleKey, address _account, bool _value) internal {
        DataStructures.uniqueAddressListUpdate(
            roleBearerTable[_roleKey],
            roleBearerIndexTable[_roleKey],
            _account,
            _value
        );
    }

    function _isRoleBearer(bytes32 _roleKey, address _account) internal view returns (bool) {
        return roleBearerIndexTable[_roleKey][_account].isSet;
    }

    function _roleBearerCount(bytes32 _roleKey) internal view returns (uint256) {
        return roleBearerTable[_roleKey].length;
    }

    function _fullRoleBearerList(bytes32 _roleKey) internal view returns (address[] memory) {
        return roleBearerTable[_roleKey];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

abstract contract SystemVersionId {
    uint256 public constant SYSTEM_VERSION_ID = uint256(keccak256('Test 2023-02-09 A'));
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import { ITokenBurn } from './interfaces/ITokenBurn.sol';
import { ITokenDecimals } from './interfaces/ITokenDecimals.sol';
import { AssetSpenderRole } from './roles/AssetSpenderRole.sol';
import { BalanceManagement } from './BalanceManagement.sol';
import { MultichainRouterRole } from './roles/MultichainRouterRole.sol';
import { SystemVersionId } from './SystemVersionId.sol';
import { VaultBase } from './VaultBase.sol';
import { TokenBurnError } from './Errors.sol';
import './helpers/AddressHelper.sol' as AddressHelper;
import './helpers/TransferHelper.sol' as TransferHelper;

contract Vault is
    SystemVersionId,
    VaultBase,
    AssetSpenderRole,
    MultichainRouterRole,
    BalanceManagement
{
    address public immutable underlying; // Anyswap ERC20 standard

    address public variableToken;
    bool public variableRepaymentEnabled;

    event SetVariableRepaymentEnabled(bool indexed variableRepaymentEnabled);
    event SetVariableToken(address indexed variableToken);
    event RedeemVariableToken(address indexed caller, uint256 amount);

    error TokenDecimalsError();
    error VariableRepaymentNotEnabledError();
    error VariableTokenNotSetError();

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol,
        address[] memory _assetSpenders,
        bool _depositAllowed,
        bool _variableRepaymentEnabled,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) VaultBase(_asset, _name, _symbol, _depositAllowed) {
        underlying = address(0);

        for (uint256 index; index < _assetSpenders.length; index++) {
            _setAssetSpender(_assetSpenders[index], true);
        }

        _setVariableRepaymentEnabled(_variableRepaymentEnabled);

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    function setAssetSpender(address _assetSpender, bool _value) external onlyManager {
        _setAssetSpender(_assetSpender, _value);
    }

    function setMultichainRouter(address _account, bool _value) external onlyManager {
        _setMultichainRouter(_account, _value);
    }

    function setVariableToken(address _variableToken) external onlyManager {
        // Zero address is allowed
        AddressHelper.requireContractOrZeroAddress(_variableToken);

        if (_variableToken != address(0) && ITokenDecimals(_variableToken).decimals() != decimals) {
            revert TokenDecimalsError();
        }

        variableToken = _variableToken;

        emit SetVariableToken(_variableToken);
    }

    function setVariableRepaymentEnabled(bool _variableRepaymentEnabled) external onlyManager {
        _setVariableRepaymentEnabled(_variableRepaymentEnabled);
    }

    function mint(
        address _to,
        uint256 _amount
    ) external whenNotPaused onlyMultichainRouter returns (bool) {
        _mint(_to, _amount);

        return true;
    }

    function burn(
        address _from,
        uint256 _amount
    ) external whenNotPaused onlyMultichainRouter returns (bool) {
        _burn(_from, _amount);

        return true;
    }

    function requestAsset(
        uint256 _amount,
        address _to,
        bool _forVariableBalance
    ) external whenNotPaused onlyAssetSpender returns (address assetAddress) {
        if (_forVariableBalance && !variableRepaymentEnabled) {
            revert VariableRepaymentNotEnabledError();
        }

        TransferHelper.safeTransfer(asset, _to, _amount);

        return asset;
    }

    function redeemVariableToken(uint256 _amount) external whenNotPaused nonReentrant checkCaller {
        checkVariableTokenState();

        bool burnSuccess = ITokenBurn(variableToken).burn(msg.sender, _amount);

        if (!burnSuccess) {
            revert TokenBurnError();
        }

        emit RedeemVariableToken(msg.sender, _amount);

        TransferHelper.safeTransfer(asset, msg.sender, _amount);
    }

    function checkVariableTokenState() public view returns (address) {
        if (!variableRepaymentEnabled) {
            revert VariableRepaymentNotEnabledError();
        }

        if (variableToken == address(0)) {
            revert VariableTokenNotSetError();
        }

        return variableToken;
    }

    function isReservedToken(address _tokenAddress) public view override returns (bool) {
        return _tokenAddress == asset;
    }

    function _setVariableRepaymentEnabled(bool _variableRepaymentEnabled) private {
        variableRepaymentEnabled = _variableRepaymentEnabled;

        emit SetVariableRepaymentEnabled(_variableRepaymentEnabled);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import { ERC20 } from 'solmate/src/tokens/ERC20.sol';
import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { ITokenDecimals } from './interfaces/ITokenDecimals.sol';
import { CallerGuard } from './CallerGuard.sol';
import { Pausable } from './Pausable.sol';
import './helpers/TransferHelper.sol' as TransferHelper;
import './Constants.sol' as Constants;

abstract contract VaultBase is ERC20, Pausable, ReentrancyGuard, CallerGuard {
    address public immutable asset;
    uint256 public totalSupplyLimit;

    event SetTotalSupplyLimit(uint256 limit);

    event Deposit(address indexed caller, uint256 assetAmount);
    event Withdraw(address indexed caller, uint256 assetAmount);

    error TotalSupplyLimitError();
    error ZeroAmountError();

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol,
        bool _depositAllowed
    ) ERC20(_name, _symbol, ITokenDecimals(_asset).decimals()) {
        asset = _asset;

        _setTotalSupplyLimit(_depositAllowed ? Constants.INFINITY : 0);
    }

    // Decimals = vault token decimals = asset decimals
    function setTotalSupplyLimit(uint256 _limit) external onlyManager {
        _setTotalSupplyLimit(_limit);
    }

    function deposit(uint256 assetAmount) public virtual whenNotPaused nonReentrant checkCaller {
        if (assetAmount == 0) {
            revert ZeroAmountError();
        }

        if (totalSupply + assetAmount > totalSupplyLimit) {
            revert TotalSupplyLimitError();
        }

        // Need to transfer before minting or ERC777s could reenter
        TransferHelper.safeTransferFrom(asset, msg.sender, address(this), assetAmount);

        _mint(msg.sender, assetAmount);

        emit Deposit(msg.sender, assetAmount);
    }

    function withdraw(uint256 assetAmount) public virtual whenNotPaused nonReentrant checkCaller {
        _burn(msg.sender, assetAmount);

        emit Withdraw(msg.sender, assetAmount);

        TransferHelper.safeTransfer(asset, msg.sender, assetAmount);
    }

    function _setTotalSupplyLimit(uint256 _limit) private {
        totalSupplyLimit = _limit;

        emit SetTotalSupplyLimit(_limit);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}