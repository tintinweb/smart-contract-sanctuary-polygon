/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {CollateralManagerStorage} from "./CollateralManagerStorage.sol";
import {Version} from "../Version/Version.sol";
import {COLLATERAL_MANAGER_VERSION} from "../ContractVersions.sol";
import {IAddressBook} from "../interfaces/IAddressBook.sol";
import {ICollateralManager} from "../interfaces/newInterfaces/managers/ICollateralManager.sol";
import {AddressHandlerAbstract} from "../utilities/AddressHandlerAbstract.sol";
import {ROLE_PAUSER, ROLE_ADMIN, ROLE_PAYMENT_CONTRACT, ZERO_ADDRESS} from "../Globals.sol";
import {Structs} from "../libraries/Structs.sol";
import {Errors} from "../libraries/Errors.sol";

/**
 * @title CollateralManager
 * @author RociFI Labs
 * @notice A contract to manage the collateral of the Roci protocol
 */
contract CollateralManagerUpgradable is
    Initializable,
    ICollateralManager,
    CollateralManagerStorage,
    UUPSUpgradeable,
    PausableUpgradeable,
    AddressHandlerAbstract,
    Version
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(IAddressBook _addressBook) public initializer {
        __UUPSUpgradeable_init();
        __Pausable_init();
        addressBook = _addressBook;
    }

    function getAddressBook() public view override returns (IAddressBook) {
        return addressBook;
    }

    function currentVersion() public pure override returns (string memory) {
        return COLLATERAL_MANAGER_VERSION;
    }

    /**
     * @dev function to return the ERC20 contract AND amount for a collateral deposit
     * @param _paymentContract address
     * @param _user borrower
     * @return ERC20 contract address of collateral
     * @return Collateral amount deposited
     */
    function getCollateralLookup(address _paymentContract, address _user)
        external
        view
        override
        returns (address, uint256)
    {
        return (collateralLookup[_user].ERC20Contract, collateralLookup[_user].amount);
    }

    function transferLookup(address[] memory users) external {
        address collateralManagerOld = 0xC1E308f498A70a83aaad3205879fd6e9eB356729;
        address paymentContract = 0xeD7f6f693178c7F8972A558fCa3FE5A6E2F12Bc2;
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            Structs.collateral memory c = collateralLookup[user];
            // ensure there was no transfer before
            require(c.ERC20Contract == ZERO_ADDRESS, Errors.MANAGER_COLLATERAL_TRANSFER);
            (address erc20, uint256 amount) = ICollateralManager(collateralManagerOld)
                .getCollateralLookup(paymentContract, user);
            // ensure there is some data to transfer
            require(erc20 != ZERO_ADDRESS && amount != 0, Errors.MANAGER_COLLATERAL_TRANSFER_EMPTY);
            uint256 balanceCurrent = IERC20Upgradeable(erc20).balanceOf(address(this));
            uint256 balanceOld = IERC20Upgradeable(erc20).balanceOf(collateralManagerOld);
            // ensure new CollateralManager has enough collateral
            require(balanceCurrent >= balanceOld, Errors.MANAGER_COLLATERAL_TRANSFER_BALANCE);
            collateralLookup[user] = Structs.collateral(block.timestamp, erc20, amount);
        }
    }

    /**
     * @dev function to add more accepted collateral
     * @param _toAdd is the collateral to add
     */
    function addAcceptedDeposits(address[] memory _toAdd) external override onlyRole(ROLE_ADMIN) {
        for (uint256 i = 0; i < _toAdd.length; i++) {
            acceptedCollateral[_toAdd[i]] = true;
        }
        emit AcceptedCollateralAdded(block.timestamp, _toAdd);
    }

    /**
     * @dev function to remove accepted collateral
     * @param _toRemove is the collateral to remove
     */
    function removeAcceptedDeposits(address[] memory _toRemove)
        external
        override
        onlyRole(ROLE_ADMIN)
    {
        for (uint256 i = 0; i < _toRemove.length; i++) {
            acceptedCollateral[_toRemove[i]] = false;
        }

        emit AcceptedCollateralRemoved(block.timestamp, _toRemove);
    }

    function deposit(
        address _from,
        address _erc20,
        uint256 _amount
    ) external override whenNotPaused onlyRole(ROLE_PAYMENT_CONTRACT) {
        require(acceptedCollateral[_erc20], Errors.MANAGER_COLLATERAL_NOT_ACCEPTED);
        IERC20Upgradeable(_erc20).safeTransferFrom(_from, address(this), _amount);

        if (collateralLookup[_from].amount == 0) {
            collateralLookup[_from] = Structs.collateral(block.timestamp, _erc20, _amount);
        } else {
            require(
                _erc20 == collateralLookup[_from].ERC20Contract,
                Errors.MANAGER_COLLATERAL_INCREASE
            );
            collateralLookup[_from].amount += _amount;
        }
    }

    /**
     * @dev function to withdra collateral
     * @notice it looks up the collateral based off the payment contract being MSG.sender. Meaning
     *   the payment contract must be the one to call this function
     * @param _user i.e., the borrower
     * @param _amount to withdraw
     * @param _receiver who receives the withdrawn collateral (also the borrower)
     */
    function withdrawal(
        address _user,
        uint256 _amount,
        address _receiver
    ) external override whenNotPaused onlyRole(ROLE_PAYMENT_CONTRACT) {
        require(_amount > 0, Errors.MANAGER_ZERO_WITHDRAW);
        Structs.collateral storage c = collateralLookup[_user];
        require(c.amount >= _amount, Errors.MANAGER_EXCEEDING_WITHDRAW);
        c.amount -= _amount;
        IERC20Upgradeable(c.ERC20Contract).safeTransfer(_receiver, _amount);
    }

    function pause() public onlyRole(ROLE_PAUSER) {
        _pause();
    }

    function unpause() public onlyRole(ROLE_PAUSER) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyRole(ROLE_ADMIN)
        whenPaused
    {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {IAddressBook} from "../interfaces/IAddressBook.sol";
import {Structs} from "../libraries/Structs.sol";

/**
 * @title CollateralManagerStorage
 * @author RociFI Labs
 */
abstract contract CollateralManagerStorage {
    IAddressBook public addressBook;
    mapping(address => Structs.collateral) internal collateralLookup;
    mapping(address => bool) public acceptedCollateral;
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;
import {IVersion} from "./IVersion.sol";
import {Errors} from "../libraries/Errors.sol";

/*
 * @title Version
 * @author RociFi Labs
 * @notice  Abstract contract for implementing versioning functionality
 * @notice Used to mark backwards-incompatible changes to the contract logic.
 * @notice checkVersion modifier should be applied to all external mutating methods
 */

abstract contract Version is IVersion {
    /**
     * @notice converts string to bytes32
     */
    function getVersionAsBytes(string memory v) public pure override returns (bytes32 result) {
        if (bytes(v).length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(v, 32))
        }
    }

    /**
     * @notice
     * Controls the call of mutating methods in versioned contract.
     * The following modifier reverts unless the value of the `versionToCheck` argument
     * matches the one provided in currentVersion method.
     */
    modifier checkVersion(string memory versionToCheck) {
        require(
            getVersionAsBytes(this.currentVersion()) == getVersionAsBytes(versionToCheck),
            Errors.VERSION
        );
        _;
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

string constant NFCS_VERSION = "1.0.1";
string constant POOL_INVESTOR_VERSION = "1.0.0";
string constant ROCI_PAYMENT_VERSION = "2.0.0";
string constant LIQUIDATOR_VERSION = "1.0.0";
string constant COLLATERAL_MANAGER_VERSION = "1.0.0";

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IAddressBook {
    function addressList(uint256 role) external view returns (address);

    function setAddressToRole(uint256 role, address newAddress) external;

    function roleLookupErrorMessage(uint256 role) external view returns (string memory);

    function dailyLimit() external view returns (uint128);

    function globalLimit() external view returns (uint128);

    function setDailyLimit(uint128 newLimit) external;

    function setGlobalLimit(uint128 newLimit) external;

    function getMaturityDate() external view returns (uint256);

    function setLoanDuration(uint256 _newLoanDuration) external;

    function userDailyLimit() external view returns (uint128);

    function userGlobalLimit() external view returns (uint128);

    function setUserDailyLimit(uint128 newLimit) external;

    function setUserGlobalLimit(uint128 newLimit) external;

    function globalNFCSLimit(uint256 _nfcsId) external view returns (uint128);

    function setGlobalNFCSLimit(uint256 _nfcsId, uint128 newLimit) external;

    function scoreGlobalLimit(uint16 score) external view returns (uint128);

    function setScoreGlobalLimit(uint16 score, uint128) external;

    function latePenalty() external view returns (uint256);

    function scoreValidityPeriod() external view returns (uint256);

    function setLatePenalty(uint256 newPenalty) external;

    function setScoreValidityPeriod(uint256 newValidityPeriod) external;

    function minScore() external view returns (uint16);

    function maxScore() external view returns (uint16);

    function setMinScore(uint16 newScore) external;

    function setMaxScore(uint16 newScore) external;

    function notGenerated() external view returns (uint16);

    function generationError() external view returns (uint16);

    function setNotGenerated(uint16 newValue) external;

    function setGenerationError(uint16 newValue) external;

    function penaltyAPYMultiplier() external view returns (uint8);

    function gracePeriod() external view returns (uint128);

    function setPenaltyAPYMultiplier(uint8 newMultiplier) external;

    function setGracePeriod(uint128 newPeriod) external;

    function defaultPoolDailyLimit() external view returns (uint128);

    function defaultPoolGlobalLimit() external view returns (uint256);

    function setDefaultPoolDailyLimit(uint128 newLimit) external;

    function setDefaultPoolGlobalLimit(uint256 newLimit) external;

    function poolDailyLimit(address pool) external view returns (uint128);

    function poolGlobalLimit(address pool) external view returns (uint256);

    function setPoolDailyLimit(address pool, uint128 newLimit) external;

    function setPoolGlobalLimit(address pool, uint256 newLimit) external;

    function limitResetTimestamp() external view returns (uint128);

    function updateLimitResetTimestamp() external;

    function setLimitResetTimestamp(uint128 newTimestamp) external;
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./IManager.sol";

/**
 * @title ICollateralManager
 * @author RociFI Labs
 * @notice A contract to manage the collateral of the Roci protocol
 * @dev the overrides of deposit/withdrawal will probably need to use data to store the loan ID
 */
interface ICollateralManager is IManager {
    /**
     * @dev function to return the ERC20 contract AND amount for a collateral deposit
     * @param _paymentContract address
     * @param _user of borrower
     * @return ERC20 contract address of collateral
     * @return Collateral amount deposited
     */
    function getCollateralLookup(address _paymentContract, address _user)
        external
        view
        returns (address, uint256);
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {IAddressBook} from "../interfaces/IAddressBook.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract AddressHandlerAbstract {
  function getAddressBook() public view virtual returns (IAddressBook);

  modifier onlyRole(uint256 _role) {
    require(msg.sender == lookup(_role), getAddressBook().roleLookupErrorMessage(_role));
    _;
  }

  function lookup(uint256 _role) internal view returns (address contractAddress) {
    contractAddress = getAddressBook().addressList(_role);
    require(contractAddress != address(0), getAddressBook().roleLookupErrorMessage(_role));
  }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.4;
uint256 constant ONE_HUNDRED_PERCENT = 100 ether; // NOTE This CAN NOT exceed 2^256/2 -1 as type casting to int occurs

uint256 constant ONE_YEAR = 31556926;
uint256 constant ONE_DAY = ONE_HOUR * 24;
uint256 constant ONE_HOUR = 60 * 60;

uint256 constant APY_CONST = 3000000000 gwei;

uint8 constant CONTRACT_DECIMALS = 18;

address constant DEAD = 0x000000000000000000000000000000000000dEaD;
address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

uint256 constant ROLE_TOKEN = 0;
uint256 constant ROLE_BONDS = 1;
uint256 constant ROLE_PAYMENT_CONTRACT = 2;
uint256 constant ROLE_REV_MANAGER = 3;
uint256 constant ROLE_NFCS = 4;
uint256 constant ROLE_COLLATERAL_MANAGER = 5;
uint256 constant ROLE_PRICE_FEED = 6;
uint256 constant ROLE_ORACLE = 7;
uint256 constant ROLE_ADMIN = 8;
uint256 constant ROLE_PAUSER = 9;
uint256 constant ROLE_LIQUIDATOR = 10;
uint256 constant ROLE_COLLECTOR = 11;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Structs {
    struct Score {
        uint256 tokenId;
        uint256 timestamp;
        uint16 creditScore;
    }

    /**
        * @param _amount to borrow
        * @param _duration of loan in seconds
        * @param _NFCSID is the user's NFCS NFT ID from Roci's Credit scoring system
        * @param _collateralAmount is the amount of collateral to send in
        * @param _collateral is the ERC20 address of the collateral
        * @param _hash is the hash of this address and the loan ID. See Bonds.sol for more info on this @newLoan()
        * @param _signature is the signature of the data hashed for hash
    */
    struct BorrowArgs{
        uint256 _amount;
        uint256 _NFCSID;
        uint256 _collateralAmount;
        address _collateral;
        bytes32 _hash;
        bytes _signature;
    }

    /// @notice collateral info is stored in a struct/mapping pair
    struct collateral {
        uint256 creationTimestamp;
        address ERC20Contract;
        uint256 amount;
    }

    // Share struct that decides the share of each address
    struct Share{
        address payee;
        uint share;
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author RociFi Labs
 * @notice Defines the error messages emitted by the different contracts of the RociFi protocol
 * @dev Error messages prefix glossary:
 *  - NFCS = NFCS
 *  - BONDS = Bonds
 *  - INVESTOR = Investor
 *  - POOL_INVESTOR = PoolInvestor
 *  - SCORE_DB = ScoreConfigs, ScoreDB
 *  - PAYMENT = ERC20CollateralPayment, ERC20PaymentStandard, RociPayment
 *  - PRICE_FEED = PriceFeed
 *  - REVENUE = PaymentSplitter, RevenueManager
 *  - LOAN = Loan
 *  - VERSION = Version
 */
library Errors {
    string public constant NFCS_TOKEN_MINTED = "0"; //  Token already minted
    string public constant NFCS_TOKEN_NOT_MINTED = "1"; //  No token minted for address
    string public constant NFCS_ADDRESS_BUNDLED = "2"; // Address already bundled
    string public constant NFCS_WALLET_VERIFICATION_FAILED = "3"; //  Wallet verification failed
    string public constant NFCS_NONEXISTENT_TOKEN = "4"; // Nonexistent NFCS token
    string public constant NFCS_TOKEN_HAS_BUNDLE = "5"; //  Token already has an associated bundle
    string public constant NFCS_TOKEN_HAS_NOT_BUNDLE = "6"; //  Token does not have an associated bundle

    string public constant BONDS_HASH_AND_ENCODING = "100"; //  Hash of data signed must be the paymentContractAddress and id encoded in that order
    string public constant BONDS_BORROWER_SIGNATURE = "101"; // Data provided must be signed by the borrower
    string public constant BONDS_NOT_STACKING = "102"; //  Not staking any NFTs
    string public constant BONDS_NOT_STACKING_INDEX = "103"; //  Not staking any tokens at this index
    string public constant BONDS_DELETE_HEAD = "104"; // Cannot delete the head

    string public constant INVESTOR_ISSUE_BONDS = "200"; //  Issue minting bonds
    string public constant INVESTOR_INSUFFICIENT_AMOUNT = "201"; //  Cannot borrow an amount of 0
    string public constant INVESTOR_BORROW_WITH_ANOTHER_SCORE = "202"; //  Cannot borrow if there is active loans with different score or pool does not support the score

    string public constant POOL_INVESTOR_INTEREST_RATE = "300"; // Interest rate has to be greater than zero
    string public constant POOL_INVESTOR_ZERO_POOL_VALUE = "301"; // Pool value is zero
    string public constant POOL_INVESTOR_ZERO_TOTAL_SUPPLY = "302"; // Total supply is zero
    string public constant POOL_INVESTOR_BONDS_LOST = "303"; // Bonds were lost in unstaking
    string public constant POOL_INVESTOR_NOT_ENOUGH_FUNDS = "304"; // Not enough funds to fulfill the loan
    string public constant POOL_INVESTOR_DAILY_LIMIT = "305"; // Exceeds daily deposits limit
    string public constant POOL_INVESTOR_GLOBAL_LIMIT = "306"; // Exceeds total deposits limit

    string public constant MANAGER_COLLATERAL_NOT_ACCEPTED = "400"; // Collateral is not accepted
    string public constant MANAGER_COLLATERAL_INCREASE = "401"; // When increasing collateral, the same ERC20 address should be used
    string public constant MANAGER_ZERO_WITHDRAW = "402"; // Cannot withdrawal zero
    string public constant MANAGER_EXCEEDING_WITHDRAW = "403"; // Requested withdrawal amount is too large
    string public constant MANAGER_COLLATERAL_TRANSFER = "404"; // The collateral struct was already transferred from old CollateralManager
    string public constant MANAGER_COLLATERAL_TRANSFER_BALANCE = "405"; // The balance of new CollateralManager is lower than old ones
    string public constant MANAGER_COLLATERAL_TRANSFER_EMPTY = "406"; // There is nothing to transfer from old CollateralManager

    string public constant SCORE_DB_EQUAL_LENGTH = "501"; // Arrays must be of equal length
    string public constant SCORE_DB_VERIFICATION = "502"; // Unverified score
    string public constant SCORE_DB_SCORE_NOT_GENERATED = "503"; // Score not yet generated.
    string public constant SCORE_DB_SCORE_GENERATING = "504"; // Error generating score.
    string public constant SCORE_DB_UNKNOW_FETCHING_SCORE = "505"; //  Unknown error fetching score.

    string public constant PAYMENT_NFCS_OUTDATED = "600"; // Outdated NFCS score outdated
    string public constant PAYMENT_ZERO_LTV = "601"; // LTV cannot be zero
    string public constant PAYMENT_NOT_ENOUGH_COLLATERAL = "602"; // Not enough collateral to issue a loan
    string public constant PAYMENT_NO_BONDS = "603"; // There is no bonds to liquidate a loan
    string public constant PAYMENT_FULFILLED = "604"; // Contract is paid off
    string public constant PAYMENT_NFCS_OWNERSHIP = "605"; // NFCS ID must belong to the borrower
    string public constant PAYMENT_NON_ISSUED_LOAN = "606"; // Loan has not been issued
    string public constant PAYMENT_WITHDRAWAL_COLLECTION = "607"; // There are not enough payments available for collection
    string public constant PAYMENT_LOAN_NOT_DELINQUENT = "608"; // Loan not delinquent
    string public constant PAYMENT_AMOUNT_TOO_LARGE = "609"; // Payment amount is too large
    string public constant PAYMENT_CLAIM_COLLATERAL = "610"; // Cannot claim collateral if this collateral is necessary for any non Closed/Liquidated loan's delinquency statu

    string public constant PRICE_FEED_TOKEN_NOT_SUPPORTED = "700"; // Token is not supported
    string public constant PRICE_FEED_TOKEN_BELOW_ZERO = "701"; // Token below zero price

    string public constant REVENUE_ADDRESS_TO_SHARE = "800"; // Non-equal length of addresses and shares
    string public constant REVENUE_UNIQUE_INDEXES = "801"; // Indexes in an array must not be duplicate
    string public constant REVENUE_FAILED_ETHER_TX = "802"; // Failed to send Ether
    string public constant REVENUE_UNVERIFIED_INVESTOR = "803"; // Only verified investors may request funds or make a payment
    string public constant REVENUE_NOT_ENOUGH_FUNDS = "804"; // Not enough funds to complete this request

    string public constant LOAN_MIN_PAYMENT = "900"; // Minimal payment should be made
    string public constant LOAN_DAILY_LIMIT = "901"; // Exceeds daily borrow limit
    string public constant LOAN_DAILY_LIMIT_USER = "902"; // Exceeds user daily borrow limit
    string public constant LOAN_TOTAL_LIMIT_USER = "903"; // Exceeds user total borrow limit
    string public constant LOAN_TOTAL_LIMIT = "904"; // Exceeds total borrow limit
    string public constant LOAN_CONFIGURATION = "905"; // Loan that is already issued, or not configured cannot be issued
    string public constant LOAN_TOTAL_LIMIT_NFCS = "906"; // Exceeds total nfcs borrow limit
    string public constant LOAN_DAILY_LIMIT_NFCS = "907"; // Exceeds daily nfcs borrow limit

    string public constant VERSION = "1000"; // Incorrect version of contract

    string public constant ADDRESS_BOOK_SET_MIN_SCORE = "1100"; // New min score must be less then maxScore
    string public constant ADDRESS_BOOK_SET_MAX_SCORE = "1101"; // New max score must be more then minScore

    string public constant ADDRESS_HANDLER_MISSING_ROLE_TOKEN = "1200"; // Lookup failed for role Token
    string public constant ADDRESS_HANDLER_MISSING_ROLE_BONDS = "1201"; // Lookup failed for role Bonds
    string public constant ADDRESS_HANDLER_MISSING_ROLE_INVESTOR = "1202"; // Lookup failed for role Investor
    string public constant ADDRESS_HANDLER_MISSING_ROLE_PAYMENT_CONTRACT = "1203"; // Lookup failed for role Payment Contract
    string public constant ADDRESS_HANDLER_MISSING_ROLE_REV_MANAGER = "1204"; // Lookup failed for role Revenue Manager
    string public constant ADDRESS_HANDLER_MISSING_ROLE_COLLATERAL_MANAGER = "1205"; // Lookup failed for role Collateral Manager
    string public constant ADDRESS_HANDLER_MISSING_ROLE_PRICE_FEED = "1206"; // Lookup failed for role Price Feed
    string public constant ADDRESS_HANDLER_MISSING_ROLE_ORACLE = "1207"; // Lookup failed for role Oracle
    string public constant ADDRESS_HANDLER_MISSING_ROLE_ADMIN = "1208"; // Lookup failed for role Admin
    string public constant ADDRESS_HANDLER_MISSING_ROLE_PAUSER = "1209"; // Lookup failed for role Pauser
    string public constant ADDRESS_HANDLER_MISSING_ROLE_LIQUIDATOR = "1210"; // Lookup failed for role Liquidator
    string public constant ADDRESS_HANDLER_MISSING_ROLE_COLLECTOR = "1211"; // Lookup failed for role Collector
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
interface IERC20 {
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

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/*
 * @title IVersion
 * @author RociFi Labs
 * @notice Interface for implementing versioning of contracts
 * @notice Used to mark backwards-incompatible changes to the contract logic.
 * @notice All interfaces of versioned contracts should inherit this interface
 */

interface IVersion {
    /**
     * @notice returns the current version of the contract
     */
    function currentVersion() external pure returns (string memory);

    /**
     * @notice converts string to bytes32
     */
    function getVersionAsBytes(string memory v) external pure returns (bytes32 result);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAddressBook} from "../../IAddressBook.sol";

/**
 * @title IManager
 * @author RociFI Labs
 * @dev base contract for other managers. Contracts that hold funds for others, keep track of the owners,
 *   and also have accepted deposited fund types that can be updated.
 */
interface IManager {
    event AcceptedCollateralAdded(uint256 timestamp, address[] indexed ERC20Tokens);
    event AcceptedCollateralRemoved(uint256 timestamp, address[] indexed ERC20CTokens);

    // function deposit(uint _amount, bytes memory _data) external;
    function deposit(
        address _from,
        address _erc20,
        uint256 _amount
    ) external;

    // function withdrawal(uint _amount, address _receiver, bytes memory _data) external;
    function withdrawal(
        address user,
        uint256 _amount,
        address _receiver
    ) external;

    function addAcceptedDeposits(address[] memory) external;

    function removeAcceptedDeposits(address[] memory) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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