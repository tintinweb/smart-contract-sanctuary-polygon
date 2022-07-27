// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* lib deps */
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IERC20PermitUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import { IERC20Upgradeable, SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/* interfaces */
import { IAccessController } from "../common/interface/IAccessController.sol";
import { ICoreController } from "../common/interface/ICoreController.sol";
import { ISavingsCore } from "../common/interface/ISavingsCore.sol";
import { ILendingCore } from "../common/interface/ILendingCore.sol";
import { IWrappedNativeToken } from "../common/interface/IWrappedNativeToken.sol";
/* models */
import { VaultModel } from "../common/model/VaultModel.sol";
/* types */
import { SharedTypes } from "../common/type/SharedTypes.sol";
/* Logics */
import { NativeWalletLogic } from "../common/logic/NativeWalletLogic.sol";

contract NativeCore is Initializable, UUPSUpgradeable {
	/* using deps */
	using SafeERC20Upgradeable for IERC20Upgradeable;
	/* errors */
	/// Action not allowed
	error NotAllowed();

	/// Caller is not configurator
	error NotConfigurator();

	/// Caller is not upgrader
	error NotUpgrader();

	/// Sender is the same as receiver
	error SendingToSelf();

	/* events */
	/// @dev emitted when a Vault asset got transferred
	/// @param id Transaction ID, can be prefixed with N- in the frontend...
	/// ...to differentiate it with WalletCore's Sent(id). Cheaper this way than...
	/// ...making the transaction ID centralized in CoreController.
	/// @param asset asset
	/// @param amount Transaction amount
	/// @param from Sender
	/// @param to Receiver
	event Sent(
		uint256 id,
		address indexed asset,
		address indexed from,
		address indexed to,
		uint256 amount
	);

	/* private vars */
	ICoreController private _controller;
	IWrappedNativeToken private _nativeToken;

	uint256 private _transactionID; // N-prefixed ID for frontends

	function initialize(ICoreController coreController) external initializer {
		//initialize deps
		__UUPSUpgradeable_init();

		_configureController(coreController);
	}

	/* modifiers */
	modifier onlyConfigurator() {
		_onlyConfigurator();
		_;
	}

	modifier onlyUpgrader() {
		_onlyUpgrader();
		_;
	}

	/**
	 * @dev Only WrappedNativeToken contract is allowed to transfer NativeToken here.
	 * Prevent other addresses to send NativeToken to this contract.
	 */
	receive() external payable {
		if (msg.sender != address(_nativeToken)) revert NotAllowed();
	}

	/**
	 * @dev Revert fallback calls
	 */
	fallback() external payable {
		revert NotAllowed();
	}

	/**
	 * @dev deposits WrappedNativeToken(e.g WETH) into the native vault, using the native digital-asset(e.g ETH).
	 * A corresponding amount of the overlying asset (vaultTokens) is minted.
	 * @param to The account who will receive the vaultTokens representing the deposit
	 **/
	function deposit(address to) external payable {
		NativeWalletLogic.executeDeposit(_controller, _nativeToken, to);
	}

	/**
	 * @dev See `deposit` above, but deposits directly to msg.sender vault
	 **/
	function deposit() external payable {
		NativeWalletLogic.executeDeposit(_controller, _nativeToken, msg.sender);
	}

	/**
	 * @dev See `deposit` and `borrow`. This method does both in a single call
	 **/
	function depositNBorrow(
		address assetToBorrow,
		uint256 amountToBorrow,
		uint256 rateMode
	) external payable {
		// `deposit` msg.value to msg.sender
		NativeWalletLogic.executeDeposit(_controller, _nativeToken, msg.sender);

		//initiate borrowing on behalf of msg.sender
		NativeWalletLogic.executeBorrow(
			_controller,
			_nativeToken,
			assetToBorrow,
			amountToBorrow,
			rateMode,
			msg.sender
		);
	}

	/**
	 * @dev withdraws WrappedNativeToken vault underlying asset of msg.sender.
	 * @param amount amount of nativeVault(e.g ETH) to withdraw
	 */
	function withdraw(uint256 amount) external {
		NativeWalletLogic.executeWithdraw(
			_controller,
			_nativeToken,
			_transactionID,
			address(_nativeToken),
			amount,
			msg.sender,
			SharedTypes.PermitSignature(0, 0, 0, 0, 0)
		);
	}

	/**
	 * @dev See `withdraw` above, but with Signature-permit
	 **/
	function withdrawBySig(
		uint256 amount,
		SharedTypes.PermitSignature memory permitSignature
	) external {
		NativeWalletLogic.executeWithdraw(
			_controller,
			_nativeToken,
			_transactionID,
			address(_nativeToken),
			amount,
			msg.sender,
			permitSignature
		);
	}

	/**
	 * @dev See `withdraw` above, but this sends the underlying asset to `to`
	 * @param to the account who will receive the native Asset(e.g ETH)
	 **/
	function send(uint256 amount, address to) external {
		if (to == msg.sender) {
			revert SendingToSelf();
		}
		NativeWalletLogic.executeWithdraw(
			_controller,
			_nativeToken,
			_transactionID,
			address(_nativeToken),
			amount,
			to,
			SharedTypes.PermitSignature(0, 0, 0, 0, 0)
		);
	}

	/**
	 * @dev See `send` above, but to eaZI ID
	 **/
	function send(uint256 amount, uint256 to) external {
		address recipient = _controller.getAddressByID(to);

		if (recipient == msg.sender) {
			revert SendingToSelf();
		}
		NativeWalletLogic.executeWithdraw(
			_controller,
			_nativeToken,
			_transactionID,
			address(_nativeToken),
			amount,
			recipient,
			SharedTypes.PermitSignature(0, 0, 0, 0, 0)
		);
	}

	/**
	 * @dev See `send` above, but with Signature-permit
	 **/
	function sendBySig(
		uint256 amount,
		address to,
		SharedTypes.PermitSignature memory permitSignature
	) external {
		if (to == msg.sender) {
			revert SendingToSelf();
		}
		NativeWalletLogic.executeWithdraw(
			_controller,
			_nativeToken,
			_transactionID,
			address(_nativeToken),
			amount,
			to,
			permitSignature
		);
	}

	/**
	 * @dev See `send` above, but with Signature-permit
	 **/
	function sendBySig(
		uint256 amount,
		uint256 to,
		SharedTypes.PermitSignature memory permitSignature
	) external {
		address recipient = _controller.getAddressByID(to);

		if (recipient == msg.sender) {
			revert SendingToSelf();
		}
		NativeWalletLogic.executeWithdraw(
			_controller,
			_nativeToken,
			_transactionID,
			address(_nativeToken),
			amount,
			recipient,
			permitSignature
		);
	}

	/**
	 * @dev borrow WrappedNativeToken, unwraps to NativeToken and send both the NativeToken and CreditTokens to msg.sender
	 * @param amount the amount of NativeToken to borrow
	 * @param rateMode the interest rate mode
	 **/
	function borrow(uint256 amount, uint256 rateMode) external {
		//initiate borrowing on behalf of msg.sender
		NativeWalletLogic.executeBorrow(
			_controller,
			_nativeToken,
			address(_nativeToken),
			amount,
			rateMode,
			msg.sender
		);
	}

	/**
	 * @notice This method ensures `to` is not the same as msg.sender
	 * @dev Send vaultToken underlying `asset` to `to` by borrowing from LendingCore
	 * @param to The account receiving `asset` to be borrowed by msg.sender
	 **/
	function borrowNSend(
		uint256 amount,
		address to,
		uint256 rateMode
	) external {
		if (to == msg.sender) {
			revert SendingToSelf();
		}

		address wNative = address(_nativeToken);
		NativeWalletLogic.executeBorrow(
			_controller,
			_nativeToken,
			wNative,
			amount,
			rateMode,
			to
		);
		emit Sent(++_transactionID, wNative, msg.sender, to, amount);
	}

	/**
	 * @notice This method ensures `to` is not the same as msg.sender
	 * @dev Send vaultToken underlying `asset` to `to` by borrowing from LendingCore
	 * @param to The eaZI ID receiving `asset` to be borrowed by msg.sender
	 **/
	function borrowNSend(
		uint256 amount,
		uint256 to,
		uint256 rateMode
	) external {
		address recipient = _controller.getAddressByID(to);

		if (recipient == msg.sender) {
			revert SendingToSelf();
		}

		address wNative = address(_nativeToken);
		NativeWalletLogic.executeBorrow(
			_controller,
			_nativeToken,
			wNative,
			amount,
			rateMode,
			recipient
		);
		emit Sent(++_transactionID, wNative, msg.sender, recipient, amount);
	}

	/**
	 * @notice Repays a borrowed `amount` on the nativeToken vault, burning the equivalent credit tokens owned
	 * - E.g. Account repays 100 WrappedNativeToken(e.g WETH), burning 100 variable/stable credit tokens of the `msg.sender`
	 * @param amount The amount of NativeToken to repay
	 * - Send the value type(uint256).max in order to repay the whole debt on the specific `rateMode`
	 * @param rateMode The interest rate mode of the debt the account wants to repay: 1 for Stable, 2 for Variable
	 **/
	function repay(uint256 amount, uint256 rateMode) external payable {
		NativeWalletLogic.executeRepay(
			_controller,
			_nativeToken,
			amount,
			rateMode,
			msg.sender
		);
	}

	/**
	 * @dev See `repay` above, but repaying on behalf of `onBehalfOf` instead
	 **/
	function repay(
		uint256 amount,
		uint256 rateMode,
		address onBehalfOf
	) external payable {
		NativeWalletLogic.executeRepay(
			_controller,
			_nativeToken,
			amount,
			rateMode,
			onBehalfOf
		);
	}

	/**
	 * @dev See `repay` and `withdraw`. This method does both in a single call
	 **/
	function repayNWithdraw(
		address assetToWithdraw,
		uint256 amountToWithdraw,
		uint256 amountToRepay,
		uint256 rateMode
	) external payable {
		// `repay` msg.value onBehalfOf msg.sender
		NativeWalletLogic.executeRepay(
			_controller,
			_nativeToken,
			amountToRepay,
			rateMode,
			msg.sender
		);

		//initiate withdrawal to msg.sender
		NativeWalletLogic.executeWithdraw(
			_controller,
			_nativeToken,
			_transactionID,
			assetToWithdraw,
			amountToWithdraw,
			msg.sender,
			SharedTypes.PermitSignature(0, 0, 0, 0, 0)
		);
	}

	/**
	 * @dev See `repayNWithdraw` above, but with Signature-permit
	 **/
	function repayNWithdrawBySig(
		address assetToWithdraw,
		uint256 amountToWithdraw,
		uint256 amountToRepay,
		uint256 rateMode,
		SharedTypes.PermitSignature memory permitSignature
	) external payable {
		// `repay` msg.value onBehalfOf msg.sender
		NativeWalletLogic.executeRepay(
			_controller,
			_nativeToken,
			amountToRepay,
			rateMode,
			msg.sender
		);

		//initiate withdrawal to msg.sender
		NativeWalletLogic.executeWithdraw(
			_controller,
			_nativeToken,
			_transactionID,
			assetToWithdraw,
			amountToWithdraw,
			msg.sender,
			permitSignature
		);
	}

	/* setters, rescuers & getters below */
	function setController(ICoreController coreController)
		external
		onlyConfigurator
	{
		_configureController(coreController);
	}

	function updateNativeToken() external onlyConfigurator {
		_configureController(_controller);
	}

	/**
	 * @dev transfer native Token(e.g Ether) from the utility contract, for native Token recovery in case of stuck native Token
	 * due selfdestructs or transfer to pre-computated contract address before deployment.
	 * @param to recipient of the transfer
	 * @param amount amount to send
	 */
	function emergencyTransfer(address to, uint256 amount)
		external
		onlyConfigurator
	{
		NativeWalletLogic.executeSafeTransferNative(to, amount);
	}

	/**
	 * @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due to
	 * direct transfers to the contract address.
	 * @param token token to transfer
	 * @param to recipient of the transfer
	 * @param amount amount to send
	 */
	function emergencyTokenTransfer(
		address token,
		address to,
		uint256 amount
	) external onlyConfigurator {
		IERC20Upgradeable(token).safeTransfer(to, amount);
	}

	/**
	 * @dev core Controller address
	 **/
	function controller() external view returns (address) {
		return address(_controller);
	}

	/**
	 * @dev Wrapped Native Token address
	 **/
	function nativeToken() external view returns (address) {
		return address(_nativeToken);
	}

	/* internal functions */

	function _configureController(ICoreController coreController) internal {
		address coreWrappedNative = coreController.getNativeToken();
		// check Wrapped Native Token is set in CoreController
		if (coreWrappedNative == address(0)) {
			revert NotAllowed();
		}

		// set partners by initializing variables
		_controller = coreController;
		_nativeToken = IWrappedNativeToken(coreWrappedNative);

		// grant Unlimited Approval to _coreController
		_nativeToken.approve(address(coreController), type(uint256).max);
	}

	function _onlyConfigurator() internal view {
		if (!IAccessController(_controller.getACL()).isConfigurator(msg.sender))
			revert NotConfigurator();
	}

	function _onlyUpgrader() internal view {
		if (!IAccessController(_controller.getACL()).isUpgrader(msg.sender))
			revert NotUpgrader();
	}

	function _authorizeUpgrade(address newImplementation)
		internal
		override
		onlyUpgrader
	{}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
pragma solidity ^0.8.0;

/* lib deps */
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

interface IAccessController is IAccessControlUpgradeable {
	/* errors */
	/// Can only be called by upgrader
	error NotUpgrader();

	/* methods */
	function isPauser(address pauser) external view returns (bool);

	function isRiskAdmin(address admin) external view returns (bool);

	function isGroup(address group) external view returns (bool);

	function isConfigurator(address configurator) external view returns (bool);

	function isGroupOrConfigurator(address groupOrConfigurator)
		external
		view
		returns (bool);

	function isUpgrader(address upgrader) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* lib deps */
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/* Models */
import { AccountModel } from "../model/AccountModel.sol";
import { VaultModel } from "../model/VaultModel.sol";
/* interfaces */
import { IPriceOracle } from "./IPriceOracle.sol";
import { ILendingRateOracle } from "./ILendingRateOracle.sol";
import { IWrappedNativeToken } from "./IWrappedNativeToken.sol";

interface ICoreController {
	struct AssetSymbol {
		string symbol;
		address asset;
	}

	struct PartnersEmissions {
		address asset; // underlying asset whose emissionPerSecond are checked
		uint256 vaultTokenEPS; // vaultToken Emission per second
		uint256 variableCreditTokenEPS; // variableCreditToken Emission per second
	}

	/* errors */
	/// Can only be called by partner group
	error NotGroup();

	/// Can only be called by pauser
	error NotPauser();

	/// Can only be called by upgrader
	error NotUpgrader();

	/// Can only be called by configurator
	error NotConfigurator();

	/// Can only be called by partner group or configurator
	error NotGroupOrConfigurator();

	/// Inconsistent parameter length
	error InconsistentParameterLength();

	/// Invalid to address(usually 0x address)
	error InvalidToAddress();

	/// No such account ID exists(or registered) on eaZI
	error NoSuchAccountID();

	/// Vault already initialized
	error VaultAlreadyInitialized();

	/* events */

	/**
	 * @dev Emitted when the Price Oracle address is updated
	 */
	event PriceOracleUpdated(address indexed newAddress);

	/**
	 * @dev Emitted when the Lending Rate Oracle address is updated
	 */
	event LendingRateOracleUpdated(address indexed newAddress);

	/**
	 * @dev Emitted when the whole group(the conglomerate) pause is triggered by `by`
	 */
	event PausedGroup(address by);

	/**
	 * @dev Emitted when the whole group(the conglomerate) pause is lifted by `by`
	 */
	event UnpausedGroup(address by);

	/**
	 * @dev Emitted when a partner(vault, any core, token, etc part of the group) pause is triggered by `by`
	 */
	event PausedPartner(address by, address partner);

	/**
	 * @dev Emitted when a partner(vault, any core, token, etc part of the group) pause is lifted by `by`
	 */
	event UnpausedPartner(address by, address partner);

	/**
	 * @dev Emitted when the state of a vault is updated
	 * @param asset The underlying asset of the vault
	 * @param liquidityRate The new liquidity rate
	 * @param stableCreditRate The new stable credit rate
	 * @param variableCreditRate The new variable credit rate
	 * @param liquidityIndex The new liquidity index
	 * @param variableCreditIndex The new variable credit index
	 **/
	event VaultDataUpdated(
		address indexed asset,
		uint256 liquidityRate,
		uint256 stableCreditRate,
		uint256 variableCreditRate,
		uint256 liquidityIndex,
		uint256 variableCreditIndex
	);

	/**
	 * @dev Emitted when a new `account` get created and assigned `accountID`
	 **/
	event AccountCreated(address indexed account, uint256 indexed accountID);

	/* methods */

	/**
	 * @dev Create eaZI account, assigning it an ID then returning it
	 * @notice Throws when account Exist
	 * - Only callable by the group(s) contract
	 * @param account The account being created
	 * @return newAccountId New account ID created
	 **/
	// function createAccount(address account) external returns (uint256);

	/**
	 * @dev Create eaZI account, but not returning it, useful where the ID value doesn't matter
	 * @notice - Only callable by the group(s) contract
	 * @param account The account being created
	 **/
	function tryCreateAccount(address account) external;

	function pullAsset(
		address asset,
		address from,
		address to,
		uint256 amount
	) external;

	function onInterestRateUpdate(
		address asset,
		uint256 liquidityRate,
		uint256 stableCreditRate,
		uint256 variableCreditRate,
		uint256 liquidityIndex,
		uint256 variableCreditIndex
	) external;

	/**
	 * @dev Initializes a vault, activating it, assigning vaultToken, credit tokens and an interest rate model
	 * @param asset The underlying asset of the vault
	 * @param vaultToken The vaultToken that will be assigned to the vault
	 * @param stableCreditToken The StableCreditToken that will be assigned to the vault
	 * @param variableCreditToken The VariableCreditToken that will be assigned to the vault
	 * @param interestRateModel The interest rate model contract
	 **/
	function initializeVault(
		address asset, //Skipped IERC20 to avoid incompatibility issues with bytes32(name & symbol)
		address vaultToken,
		address stableCreditToken,
		address variableCreditToken,
		address interestRateModel
	) external;

	/* controller config setters & getters below */

	/* setters below */
	/**
	 * @dev Pause a `partner`, can trigger global pause by making `partner` address(of CoreController, this contract)
	 * @param partner The partner to pause
	 */
	function pause(address partner) external;

	/**
	 * @dev Unpause a `partner`, even address of CoreController(this contract)
	 * @param partner The partner to unpause
	 */
	function unpause(address partner) external;

	// function updateAccount(address account, AccountModel.Data memory data)
	// 	external;

	/**
	 * @dev Sets the configuration bitmap of an account as a whole
	 * - Only callable by the group(s) contract
	 * @param account The account being updated
	 * @param config The new configuration bitmap
	 **/
	function updateAccountConfig(address account, uint256 config) external;

	function updateVault(address asset, VaultModel.Data memory data) external;

	/**
	 * @dev Sets the configuration bitmap of the vault as a whole
	 * - Only callable by the group(s) contract or configurator
	 * @param asset The underlying asset of the vault
	 * @param config The new configuration bitmap
	 **/
	function updateVaultConfig(address asset, uint256 config) external;

	/**
	 * @dev Updates a vault interest rate Model
	 * @param asset The underlying asset of the vault
	 * @param model The interest rate Model
	 **/
	function updateVaultInterestRateModel(address asset, address model)
		external;

	function setNativeToken(IWrappedNativeToken wrappedNativeToken) external;

	function setBurner(address burner) external;

	function setStaticPercent(uint256 ratePercent) external;

	function setRewardController(address rewardController) external;

	function setFlashMintMaxPercent(address asset, uint256 inPercent) external;

	function setFlashMintFee(address asset, uint256 inPercent) external;

	function setLendingCore(address addr) external;

	function setSavingsCore(address addr) external;

	function setSwapController(address addr) external;

	function setPriceOracle(IPriceOracle priceOracle) external;

	function setStableRateOracle(ILendingRateOracle lendingRateOracle) external;

	/* getters */

	function paused(address partner) external view returns (bool);

	/**
	 * @dev find eaZI account's ID by its address
	 * - returns 0x if no such account registered
	 * @param account The account native address(e.g Ethereum address)
	 * @return accountID The account ID or 0 if not registered
	 **/
	function findIDByAddress(address account) external view returns (uint256);

	/**
	 * @dev find an eaZI account's address by its ID
	 * - returns 0x if no such account registered
	 * @param accountID The account ID
	 * @return The account address or 0x if not registered
	 **/
	function findAddressByID(uint256 accountID) external view returns (address);

	/**
	 * @dev get an eaZI account's address by its ID
	 * - throws/reverts if no such account registered
	 * @param accountID The account ID
	 * @return account The account address
	 **/
	function getAddressByID(uint256 accountID)
		external
		view
		returns (address account);

	/**
	 * @dev get eaZI account's ID by its address
	 * - throws/reverts if no such account registered
	 * @param account The account native address(e.g Ethereum address)
	 * @return accountID The account ID
	 **/
	function getIDByAddress(address account)
		external
		view
		returns (uint256 accountID);

	/**
	 * @dev Returns `account` configuration
	 * @param account The account holder
	 * @return The account config
	 **/
	function getAccountConfig(address account)
		external
		view
		returns (AccountModel.Config memory);

	/**
	 * @dev Returns `account` data state
	 * @param account The account holder
	 * @return The account data
	 **/
	function getAccountData(address account)
		external
		view
		returns (AccountModel.Data memory);

	function getAccountVaultData(address account, address asset)
		external
		view
		returns (
			uint256 currentVaultBalance,
			uint256 currentStableDebt,
			uint256 currentVariableDebt,
			uint256 principalStableDebt,
			uint256 scaledVariableDebt,
			uint256 stableCreditRate,
			uint256 liquidityRate,
			uint40 stableRateLastUpdated,
			bool enabledAsCollateral
		);

	/**
	 * @dev Returns liquidity data across all vaults and various partners
	 * @param account The account
	 * @return savingsBalanceInBaseCurrency The total savings balance of the account in Base Currency
	 * @return outstandingDebtInBaseCurrency the outstanding debt of the account in Base Currency
	 * @return availableCreditInBaseCurrency The available credit limit of the account in Base Currency
	 * @return currentLiquidationThreshold The liquidation threshold of the account
	 * @return ltv the loan to value of the account
	 * @return healthFactor the current health factor of the account, as represented internally
	 **/
	function getAccountLiquidityData(address account)
		external
		view
		returns (
			uint256 savingsBalanceInBaseCurrency,
			uint256 outstandingDebtInBaseCurrency,
			uint256 availableCreditInBaseCurrency,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		);

	/**
	 * @dev Returns the list of the initialized vaults
	 **/
	function getVaults() external view returns (address[] memory);

	/**
	 * @dev Returns `asset` vault state and configuration
	 * @param asset The vault underlying asset
	 * @return The vault state
	 **/
	function getVaultData(address asset)
		external
		view
		returns (VaultModel.Data memory);

	/**
	 * @dev Returns `asset` vault liquidity(including rates) data
	 * @param asset The vault underlying asset
	 * @return availableLiquidity vault available liquidity
	 * @return totalStableDebt vault total stable debt
	 * @return totalVariableDebt vault total variable debt
	 * @return liquidityRate vault liquidity rate
	 * @return variableCreditRate variable credit rate
	 * @return stableCreditRate stable credit rate
	 * @return averageStableCreditRate average stable credit rate
	 * @return liquidityIndex liquidity index
	 * @return variableCreditIndex variable credit index
	 * @return lastUpdateTimestamp vault last updated timestamp
	 **/
	function getVaultLiquidityData(address asset)
		external
		view
		returns (
			uint256 availableLiquidity,
			uint256 totalStableDebt,
			uint256 totalVariableDebt,
			uint256 liquidityRate,
			uint256 variableCreditRate,
			uint256 stableCreditRate,
			uint256 averageStableCreditRate,
			uint256 liquidityIndex,
			uint256 variableCreditIndex,
			uint40 lastUpdateTimestamp
		);

	/**
	 * @dev Returns `asset` vault configuration
	 * @param asset The vault underlying asset
	 * @return The vault config
	 **/
	function getVaultConfig(address asset)
		external
		view
		returns (VaultModel.Config memory);

	/**
	 * @dev Returns `asset` vault configuration data
	 * @param asset The vault underlying asset
	 * @return decimals vault decimals
	 * @return ltv vault loan to value
	 * @return liquidationThreshold vault liquidation threshold
	 * @return liquidationBonus vault liquidation bonus
	 * @return reserveFactor vault reserve factor
	 * @return enabledAsCollateral is `asset` accepted as collateral
	 * @return creditEnabled is `asset` enabled for credit borrowing
	 * @return stableCreditEnabled is `asset` enabled for Stable Credit borrowing
	 * @return isActive is Vault Active
	 * @return isFrozen is Vault frozen
	 **/
	function getVaultConfigData(address asset)
		external
		view
		returns (
			uint256 decimals,
			uint256 ltv,
			uint256 liquidationThreshold,
			uint256 liquidationBonus,
			uint256 reserveFactor,
			bool enabledAsCollateral,
			bool creditEnabled,
			bool stableCreditEnabled,
			bool isActive,
			bool isFrozen
		);

	/**
	 * @dev Returns the normalized income per unit of asset
	 * @param asset The underlying asset of the vault
	 * @return The vault's normalized income
	 */
	function getVaultNormalizedIncome(address asset)
		external
		view
		returns (uint256);

	function getACL() external view returns (address);

	function getBurner() external view returns (address);

	function getNativeToken() external view returns (address);

	function getLendingCore() external view returns (address);

	function getSavingsCore() external view returns (address);

	function getSwapController() external view returns (address);

	function getPriceOracle() external view returns (address);

	function getStableRateOracle() external view returns (address);

	function getRewardController() external view returns (address);

	function getStaticPercent() external view returns (uint256);

	function getFlashMintMaxPercent(address asset)
		external
		view
		returns (uint256);

	function getFlashMintFee(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISavingsCore {
	/* errors */
	/// Action is paused
	error IsPaused();

	/// Can only be called by upgrader
	error NotUpgrader();

	/// Can only be called by configurator
	error NotConfigurator();

	/* events */
	/**
	 * @dev Emitted on deposit-related functions()
	 * @param asset The underlying asset
	 * @param account The account initiating the deposit
	 * @param onBehalfOf The beneficiary of the deposit, receiving the vaultTokens
	 * @param amount The amount deposited
	 **/
	event Deposited(
		address indexed asset,
		address indexed account,
		address indexed onBehalfOf,
		uint256 amount
	);

	/**
	 * @dev Emitted on deposit-related functions()
	 * @param asset The underlying asset
	 * @param account The account initiating the deposit
	 * @param onBehalfOf The beneficiary of the deposit, receiving the Certificate of Deposit
	 * @param amount The amount deposited
	 * @param id The Certificate ID
	 **/
	event DepositedCD(
		address indexed asset,
		address indexed account,
		address indexed onBehalfOf,
		uint256 amount,
		uint256 id
	);

	/**
	 * @dev Emitted on withdraw-related functions()
	 * @param asset The underlying asset being withdrawn
	 * @param account The account initiating the withdrawal, owner of vaultTokens
	 * @param to Address that will receive the underlying asset
	 * @param amount The amount to be withdrawn
	 **/
	event Withdrawn(
		address indexed asset,
		address indexed account,
		address indexed to,
		uint256 amount
	);

	/**
	 * @dev Emitted on withdraw-related functions()
	 * @param asset The underlying asset being withdrawn
	 * @param account The account initiating the CD withdrawal, owner(or approved beneficiary) of CD
	 * @param to Address that will receive the underlying asset
	 * @param amount The amount to be withdrawn
	 * @param id The Certificate ID
	 **/
	event WithdrawnCD(
		address indexed asset,
		address indexed account,
		address indexed to,
		uint256 amount,
		uint256 id
	);

	/**
	 * @dev Emitted when Vault Is Enabled as Collateral
	 * @param asset The underlying asset
	 * @param by The account enabling `asset` as collateral
	 **/
	event VaultEnabledAsCollateral(address indexed asset, address indexed by);

	/**
	 * @dev Emitted when Vault Is Disabled as Collateral
	 * @param asset The underlying asset
	 * @param by The account disabling `asset` as collateral
	 **/
	event VaultDisabledAsCollateral(address indexed asset, address indexed by);

	/**
	 * @dev Deposits an `amount` of underlying asset into the CD vault, receiving in return overlying vault NFT.
	 * - E.g. Account deposits 100 USDC and gets in return 1 CDv(which wraps the underlying asset as an NFT)
	 * @param asset The underlying asset to deposit
	 * @param amount The amount to be deposited
	 * @param to The account that will receive the vaultNFT
	 * @param termIndex The term index as can be seen in VaultCD termList, translates to minimum term length in seconds
	 **/
	function depositToCD(
		address asset,
		uint256 amount,
		address to,
		uint8 termIndex
	) external returns (uint256);

	/**
	 * @dev Same as `depositToCD`, but deposits to msg.sender
	 **/
	function depositToCD(
		address asset,
		uint256 amount,
		uint8 termIndex
	) external returns (uint256);

	/**
	 * @dev Deposits an `amount` of underlying asset into the vault, receiving in return overlying vaultTokens.
	 * - E.g. Account deposits 100 USDC and gets in return 100 USDCv
	 * @param asset The underlying asset to deposit
	 * @param amount The amount to be deposited
	 * @param to The account that will receive the vaultTokens
	 **/
	function deposit(
		address asset,
		uint256 amount,
		address to
	) external;

	/**
	 * @dev See `deposit` above, but deposits to msg.sender as the direct beneficiary
	 **/
	function deposit(address asset, uint256 amount) external;

	/**
	 * @dev See `deposit` above
	 * @notice This function replicates `deposit` function, with Signature permits added
	 **/
	function depositBySig(
		address asset,
		uint256 amount,
		address to,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	/**
	 * @dev See `depositBySig` above
	 * @notice This function replicates `depositBySig` function, but deposits to msg.sender
	 **/
	function depositBySig(
		address asset,
		uint256 amount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	/**
	 * @dev Withdraws an `amount` of underlying asset from the CD vault, burning the equivalent CD
	 * E.g. Account has 100 USDC in a CDv, calls withdraw() and receives 100 USDC, burning the CDv
	 * @param tokenId The CD to be withdrawn from
	 * @param to Account that will receive the underlying, same as msg.sender if the account
	 *   wants to receive it on its own wallet, or a different account if to different beneficiary
	 * @return The final amount withdrawn
	 **/
	function withdrawFromCD(uint256 tokenId, address to)
		external
		returns (uint256);

	/**
	 * @dev Same as `withdrawFromCD` but withdraws directly to msg.sender
	 **/
	function withdrawFromCD(uint256 tokenId) external returns (uint256);

	/**
	 * @dev Withdraws an `amount` of underlying asset from the vault, burning the equivalent vaultTokens owned
	 * E.g. Account has 100 USDCv, calls withdraw() and receives 100 USDC, burning the 100 USDCv
	 * @param asset The underlying asset to withdraw
	 * @param amount The underlying amount to be withdrawn
	 *   - Send the value type(uint256).max in order to withdraw the whole vaultToken balance
	 * @param to Address that will receive the underlying, same as msg.sender if the account
	 *   wants to receive it on its own wallet, or a different account if to different beneficiary
	 * @return The final amount withdrawn
	 **/
	function withdraw(
		address asset,
		uint256 amount,
		address to
	) external returns (uint256);

	/**
	 * @dev See `withdraw` above, but withdraws to msg.sender
	 **/
	function withdraw(address asset, uint256 amount) external returns (uint256);

	/**
	 * @dev Allows depositors to enable/disable a specific deposited asset as collateral
	 * @param asset The underlying asset deposited
	 * @param useAsCollateral `true` if the account wants to use the deposit as collateral, `false` otherwise
	 **/
	function useVaultAsCollateral(address asset, bool useAsCollateral) external;

	/**
	 * @dev Returns the account data across all the vaults
	 * @param account The account
	 * @return savingsBalanceInBaseCurrency The total savings balance of the account in Base Currency
	 **/
	function getSavingsData(address account)
		external
		view
		returns (uint256 savingsBalanceInBaseCurrency);

	/**
	 * @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
	 * direct transfers to the contract address.
	 * @param token token to transfer
	 * @param to recipient of the transfer
	 * @param amount amount to send
	 */
	function emergencyTokenTransfer(
		address token,
		address to,
		uint256 amount
	) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILendingCore {
	/* errors */
	/// Action is paused
	error IsPaused();

	/// Can only be called by partner group
	error NotGroup();

	/// Can only be called by upgrader
	error NotUpgrader();

	/// Can only be called by Vault Token
	error NotVaultToken();

	/// Can only be called by configurator
	error NotConfigurator();

	/// Flashloan callback failed
	error FlashloanCallbackFailed();

	/* events */
	/**
	 * @dev Emitted on borrow()
	 * @param asset The underlying asset being borrowed
	 * @param account The account initiating the borrow(), receiving the funds on borrow()
	 * @param onBehalfOf The account that will be getting the debt
	 * @param amount The amount borrowed
	 * @param creditRateMode The rate mode: 1 for Stable, 2 for Variable, 3 for Fixed
	 * @param creditRate The numeric rate at which the account has borrowed
	 **/
	event Borrowed(
		address indexed asset,
		address indexed account,
		address indexed onBehalfOf,
		uint256 amount,
		uint256 creditRateMode,
		uint256 creditRate
	);

	/**
	 * @dev Emitted on repay()
	 * @param asset The underlying asset
	 * @param account The beneficiary of the repayment, getting its debt repaid
	 * @param repayer The account initiating the `repay`ment(), providing the funds
	 * @param amount The amount repaid
	 **/
	event Repaid(
		address indexed asset,
		address indexed account,
		address indexed repayer,
		uint256 amount
	);

	/**
	 * @dev Emitted on swapCreditRateMode()
	 * @param asset The underlying asset
	 * @param account The account swapping its rate mode
	 * @param rateMode The rate mode being swapped to
	 **/
	event SwappedCreditRateMode(
		address indexed account,
		address indexed asset,
		uint256 rateMode
	);

	/**
	 * @dev Emitted when Vault Is Enabled as Collateral
	 * @param asset The underlying asset
	 * @param by The account enabling `asset` as collateral
	 **/
	event VaultEnabledAsCollateral(address indexed asset, address indexed by);

	/**
	 * @dev Emitted when Vault Is Disabled as Collateral
	 * @param asset The underlying asset
	 * @param by The account disabling `asset` as collateral
	 **/
	event VaultDisabledAsCollateral(address indexed asset, address indexed by);

	/**
	 * @dev Emitted on rebalanceStableCreditRate()
	 * @param asset The underlying asset
	 * @param account The account for which the rebalance has been executed
	 **/
	event RebalancedStableCreditRate(
		address indexed asset,
		address indexed account
	);

	/**
	 * @dev Emitted on flashLoan()
	 * @param target The flash loan receiver contract
	 * @param initiator The account initiating the flash loan
	 * @param asset The asset being flash borrowed
	 * @param amount The amount flash borrowed
	 * @param fee The flash fee
	 **/
	event FlashLoan(
		address indexed target,
		address indexed initiator,
		address indexed asset,
		uint256 amount,
		uint256 fee
	);

	/**
	 * @dev Allows accounts to borrow a specific `amount` of the vault underlying asset, provided that the borrower
	 * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
	 * corresponding Credit token (StableCreditToken or variableCreditToken)
	 * - E.g. Account borrows 100 USDC passing as `onBehalfOf` its account, receiving the 100 USDC in its wallet
	 *   and 100 stable/variable credit tokens, depending on the `interestRateMode`
	 * @param asset The underlying asset to borrow
	 * @param amount The amount to be borrowed
	 * @param interestRateMode The interest rate mode at which the account wants to borrow: 1 for Stable, 2 for Variable
	 * @param onBehalfOf Account who will receive the credit. Should be the borrower itself
	 * calling the function if he wants to borrow against its collateral, or the credit delegator
	 * if he has been given credit delegation allowance
	 **/
	function borrow(
		address asset,
		uint256 amount,
		uint256 interestRateMode,
		address onBehalfOf
	) external;

	/**
	 * @dev See `borrow` above, but borrows directly to msg.sender
	 **/
	function borrow(
		address asset,
		uint256 amount,
		uint256 interestRateMode
	) external;

	/**
	 * @notice Repays a borrowed `amount` on a specific vault, burning the equivalent credit tokens owned
	 * - E.g. Account repays 100 USDC, burning 100 variable/stable credit tokens of the `onBehalfOf` address
	 * @param asset The borrowed underlying asset previously borrowed
	 * @param amount The amount to repay
	 * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
	 * @param rateMode The interest rate mode at of the debt the account wants to repay: 1 for Stable, 2 for Variable
	 * @param onBehalfOf Account who will get its debt repaid/reduced. Should be the calling account, or the account
	 * of any other borrower whose debt should is being repaid on behalf of
	 * @return The final amount repaid
	 **/
	function repay(
		address asset,
		uint256 amount,
		uint256 rateMode,
		address onBehalfOf
	) external returns (uint256);

	/**
	 * @dev See `repay` above, `onBehalfOf` msg.sender
	 **/
	function repay(
		address asset,
		uint256 amount,
		uint256 rateMode
	) external returns (uint256);

	/**
	 * @dev See `repay` above
	 * @notice This function replicates `repay` function, with Signature permits added
	 **/
	function repayBySig(
		address asset,
		uint256 amount,
		uint256 rateMode,
		address to,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256);

	/**
	 * @dev See `repayBySig` above
	 * @notice This function replicates `repayBySig` function, but repays on behalf of msg.sender
	 **/
	function repayBySig(
		address asset,
		uint256 amount,
		uint256 rateMode,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256);

	/**
	 * @dev Allows a borrower to swap its debt between stable and variable mode, or viceversa
	 * @param asset The underlying asset borrowed
	 * @param rateMode The rate mode that the account wants to swap to
	 **/
	function swapCreditRateMode(address asset, uint256 rateMode) external;

	/**
	 * @dev Rebalances the stable interest rate of a specific account to the current stable rate defined on the vault.
	 * - Accounts can be rebalanced if the following conditions are satisfied:
	 *     1. Usage ratio is above 95%
	 *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableCreditRate, which means that too much has been
	 *        borrowed at a stable rate and depositors are not earning enough
	 * @param asset The underlying asset borrowed
	 * @param account The account to be rebalanced
	 **/
	function rebalanceStableCreditRate(address asset, address account) external;

	/**
	 * @dev Allows smart contracts to access and utilize the Group's liquidity within one transaction,
	 * as long as the amount taken plus a fee(which can be calculated in advance with calculateFlashFee) is returned.
	 * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
	 * @param receiver The contract receiving the funds, implementing the ERC3156->IFlashLoanReceiver interface
	 * @param asset The asset being flash-borrowed
	 * @param amount The amount being flash-borrowed
	 * @param data Variadic packed params to pass to the receiver as extra information
	 *   0 if the action is executed directly by the account, without any middle-man
	 **/
	function flashLoan(
		address receiver,
		address asset,
		uint256 amount,
		bytes memory data
	) external;

	/**
	 * Same as `flashLoan` above, except for multiple assets, amounts and IMultiFlashLoanReceiver-compatible `receiver` required
	 **/
	function flashLoan(
		address receiver,
		address[] calldata assets,
		uint256[] calldata amounts,
		bytes calldata data
	) external;

	/**
	 * @dev Validates and finalizes a vaultToken transfer
	 * - Only callable by the overlying vaultToken of the `asset`
	 * @param asset The underlying asset of the vaultToken
	 * @param from The account from which the vaultTokens are transferred
	 * @param to The account receiving the vaultTokens
	 * @param amount The amount being transferred/withdrawn
	 * @param balanceFromBefore The vaultToken balance of the `from` account before the transfer
	 * @param balanceToBefore The vaultToken balance of the `to` account before the transfer
	 */
	function validateTransfer(
		address asset,
		address from,
		address to,
		uint256 amount,
		uint256 balanceFromBefore,
		uint256 balanceToBefore
	) external;

	/**
	 * @dev Returns the normalized variable debt per unit of asset
	 * @param asset The underlying asset of the vault
	 * @return The vault normalized variable debt
	 */
	function getVaultNormalizedVariableDebt(address asset)
		external
		view
		returns (uint256);

	/**
	 * @dev Fetches the account current stable and variable debt balances
	 * @param account The account
	 * @param asset The asset being checked
	 * @return The stable and variable debt balance
	 **/
	function getAccountDebt(address account, address asset)
		external
		view
		returns (uint256, uint256);

	/**
	 * @dev Returns the credit data across all the vaults
	 * @param account The account
	 * @return savingsBalanceInBaseCurrency The total savings balance of the account in Base Currency
	 * @return outstandingDebtInBaseCurrency the outstanding debt of the account in Base Currency
	 * @return availableCreditInBaseCurrency The available credit limit of the account in Base Currency
	 * @return currentLiquidationThreshold The liquidation threshold of the account
	 * @return ltv the loan to value of the account
	 * @return healthFactor the current health factor of the account
	 **/
	function getCreditData(address account)
		external
		view
		returns (
			uint256 savingsBalanceInBaseCurrency,
			uint256 outstandingDebtInBaseCurrency,
			uint256 availableCreditInBaseCurrency,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		);

	/**
	 * @dev Returns the fee to pay for a flashloan
	 * @return amount The amount(face value) to pay in fee
	 **/
	function flashFee(address asset, uint256 amount)
		external
		view
		returns (uint256);

	/**
	 * @dev Returns the fee % to pay for a flashloan
	 * @return percentage The percentage to pay in fee, e.g 3 = 0.003%, 20 = 0.02%, 100 = 0.1%
	 **/
	function flashFeeInPercent(address asset, uint256 amount)
		external
		view
		returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWrappedNativeToken {
	function deposit() external payable;

	function withdraw(uint256) external;

	function approve(address guy, uint256 wad) external returns (bool);

	function transferFrom(
		address src,
		address dst,
		uint256 wad
	) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VaultModel library
 * @author eaZI
 * @notice Implements bitmap structure and variables to handle vault data, configurations and structures
 */
library VaultModel {
	struct Data {
		//stores the vault configuration
		Config config;
		//the liquidity index. Expressed in ray
		uint128 liquidityIndex;
		//variable credit index. Expressed in ray
		uint128 variableCreditIndex;
		//the current supply rate. Expressed in ray
		uint128 currentLiquidityRate;
		//the current variable credit rate. Expressed in ray
		uint128 currentVariableCreditRate;
		//the current stable credit rate. Expressed in ray
		uint128 currentStableCreditRate;
		uint40 lastUpdateTimestamp;
		/* tokens */
		address vaultToken;
		address stableCreditToken;
		address variableCreditToken;
		address fixedCreditToken;
		address interestRateModel; // interest rate model
		uint8 id; //vault ID
	}

	struct Config {
		//bit 0-15: LTV
		//bit 16-31: Liq. threshold
		//bit 32-47: Liq. bonus
		//bit 48-55: Decimals
		//bit 56: vault is active
		//bit 57: vault is frozen
		//bit 58: borrowing is enabled
		//bit 59: stable rate borrowing enabled
		//bit 60-63: reserved
		//bit 64-79: reserve factor
		uint256 data;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SharedTypes {
	/* Core */
	enum InterestRateMode {
		STABLE,
		VARIABLE
	}

	struct PermitSignature {
		uint256 amount;
		uint256 deadline;
		uint8 v;
		bytes32 r;
		bytes32 s;
	}

	/* SavungsCore */

	struct ExecuteWithdrawParams {
		address asset;
		uint256 amount;
		address to;
	}

	struct ValidateTransferParams {
		address asset;
		address from;
		address to;
		uint256 amount;
		uint256 balanceFromBefore;
		uint256 balanceToBefore;
	}

	/* LendingCore */
	struct ExecuteBorrowParams {
		address asset;
		address account;
		address onBehalfOf;
		address oracle;
		uint256 amount;
		uint256 interestRateMode;
	}

	struct ExecuteRepayParams {
		address asset;
		uint256 amount;
		uint256 rateMode;
		address onBehalfOf;
	}

	/* WalletCore */
	/**
	 * @dev Struct containing swap and repayment parameters
	 * @param initiator initiator account
	 * @param asset Savings asset to pull from Vault
	 * @param creditAsset credit token to repay
	 * @param amount Amount of Savings `asset` to pull
	 * @param amountToRepay Amount of the debt to be repaid, or maximum amount when repaying entire debt
	 * @param rateMode Rate mode of the debt to be repaid
	 * @param amountOffset Set to offset of fromAmount in Augustus calldata if wanting to swap all balance, otherwise 0
	 * @param swapData Paraswap data
	 * @param fee flash loan fee
	 * @param permitSignature struct containing the permit signature
	 */
	struct SwapAndRepayParams {
		uint256 fee;
		uint256 amount;
		uint256 amountOffset;
		uint256 amountToRepay;
		uint256 rateMode;
		bytes swapData;
		address initiator;
		address asset;
		address creditAsset;
		PermitSignature permitSignature;
	}

	/* Flashloan */
	struct ExecuteFlashLoanParams {
		address receiver;
		address asset;
		uint256 amount;
		bytes data;
	}

	struct ExecuteMultiFlashLoanParams {
		address receiver;
		address[] assets;
		uint256[] amounts;
		bytes data;
	}

	struct FlashLoanRepaymentParams {
		uint256 premium;
		uint256 amount;
		uint256 totalPremium;
		address asset;
		address receiver;
		address vaultToken;
	}

	/* GroupValidator */

	struct ValidateBorrowParams {
		address asset;
		address account;
		uint256 amount;
		uint256 amountInBaseCurrency;
		uint256 interestRateMode;
		uint256 maxStaticLoanPercent;
		address oracle;
		address[] vaults;
	}

	struct ValidateWithdrawParams {
		uint256 amount;
		uint256 accountBalance;
		address asset;
		address oracle;
		address[] vaults;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* lib deps */
import { IERC20PermitUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import { IERC20Upgradeable, SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/* interfaces */
import { IAccessController } from "../interface/IAccessController.sol";
import { ICoreController } from "../interface/ICoreController.sol";
import { ISavingsCore } from "../interface/ISavingsCore.sol";
import { ILendingCore } from "../interface/ILendingCore.sol";
import { IWrappedNativeToken } from "../interface/IWrappedNativeToken.sol";
/* models */
import { VaultModel } from "../model/VaultModel.sol";
/* types */
import { SharedTypes } from "../type/SharedTypes.sol";

/**
 * @title NativeWalletLogic library
 * @author eazi
 * @notice Implements the base logic for all the actions related to the Native Wallet
 */
library NativeWalletLogic {
	/* using deps */
	using SafeERC20Upgradeable for IERC20Upgradeable;

	/* errors */
	/// Action not allowed
	error NotAllowed();

	/// Transfer failed
	error TransferFailed();

	/// Value is less than amount
	error ValueIsLessThanAmount();

	/* events */
	event Sent(
		uint256 id,
		address indexed asset,
		address indexed from,
		address indexed to,
		uint256 amount
	);

	/**
	 * @notice Implements the native deposit feature of the SavingsCore.
	 */
	function executeDeposit(
		ICoreController coreController,
		IWrappedNativeToken nativeToken,
		address to
	) external {
		address asset = address(nativeToken);
		// pull msg.value amount of nativeToken from msg.sender
		nativeToken.deposit{ value: msg.value }(); // wrap it

		_allowControllerPull(
			nativeToken,
			address(coreController),
			asset,
			msg.value
		);

		// then deposit it on behalf of `to`
		ISavingsCore(coreController.getSavingsCore()).deposit(
			asset,
			msg.value,
			to
		);
	}

	function executeBorrow(
		ICoreController coreController,
		IWrappedNativeToken nativeToken,
		address asset,
		uint256 amount,
		uint256 rateMode,
		address to
	) external {
		// borrow `amount` of `asset` on behalf of `msg.sender`
		ILendingCore(coreController.getLendingCore()).borrow(
			asset,
			amount,
			rateMode,
			msg.sender
		);
		// by now, the credit Token would have been issued to `msg.sender`
		// and the borrowed `asset` received by `address(this)`

		// if received asset is the wrapped nativeToken
		if (asset == address(nativeToken)) {
			nativeToken.withdraw(amount); // unwrap amount
			_safeTransferNative(to, amount); // then send to `to`
			// else if other custom(non-native) asset received
		} else {
			// send to `to`
			IERC20Upgradeable(asset).safeTransfer(to, amount);
		}
	}

	function executeRepay(
		ICoreController coreController,
		IWrappedNativeToken nativeToken,
		uint256 amount,
		uint256 rateMode,
		address onBehalfOf
	) external {
		address asset = address(nativeToken);
		ILendingCore lendingCore = ILendingCore(
			coreController.getLendingCore()
		);
		(uint256 stableDebt, uint256 variableDebt) = lendingCore.getAccountDebt(
			onBehalfOf,
			asset
		);

		uint256 paybackAmount = SharedTypes.InterestRateMode(rateMode) ==
			SharedTypes.InterestRateMode.STABLE
			? stableDebt
			: variableDebt;

		if (amount < paybackAmount) {
			paybackAmount = amount;
		}
		if (msg.value < paybackAmount) {
			revert ValueIsLessThanAmount();
		}

		nativeToken.deposit{ value: paybackAmount }();

		_allowControllerPull(
			nativeToken,
			address(coreController),
			asset,
			msg.value
		);

		lendingCore.repay(asset, msg.value, rateMode, onBehalfOf);

		// refund remaining tokens being oversent by msg.sender
		if (msg.value > paybackAmount)
			_safeTransferNative(msg.sender, msg.value - paybackAmount);
	}

	function executeWithdraw(
		ICoreController coreController,
		IWrappedNativeToken nativeToken,
		uint256 transactionID,
		address asset,
		uint256 amount,
		address to,
		SharedTypes.PermitSignature memory permitSignature
	) external {
		VaultModel.Data memory vaultData = coreController.getVaultData(asset);
		// since the withdrawal is being performed on the asset Vault, get asset's VaultToken
		IERC20Upgradeable assetVault = IERC20Upgradeable(vaultData.vaultToken);
		// using IERC20 in place of IVaultToken since the interfaces needed are compatible with IERC20

		uint256 accountBalance = assetVault.balanceOf(msg.sender);
		uint256 amountToWithdraw = amount;

		// if amount is equal to type(uint).max, the account wants to redeem everything
		if (amount == type(uint256).max) {
			amountToWithdraw = accountBalance;
		}

		// pull amount from `msg.sender` asset's VaultToken
		_pullVaultUnderlying(
			coreController,
			nativeToken,
			asset,
			amountToWithdraw,
			permitSignature
		);

		if (asset == address(nativeToken)) {
			nativeToken.withdraw(amountToWithdraw);
			_safeTransferNative(to, amountToWithdraw);
		} else {
			IERC20Upgradeable(asset).safeTransfer(to, amountToWithdraw);
		}

		// Log Transfer event
		if (to != msg.sender) {
			emit Sent(++transactionID, asset, msg.sender, to, amountToWithdraw);
		}
	}

	function executeSafeTransferNative(address to, uint256 value) external {
		_safeTransferNative(to, value);
	}

	/* internals below */

	function _pullVaultUnderlying(
		ICoreController coreController,
		IWrappedNativeToken nativeToken,
		address asset,
		uint256 amount,
		SharedTypes.PermitSignature memory permitSig
	) internal {
		address vaultToken = coreController.getVaultData(asset).vaultToken;

		if (permitSig.deadline != 0) {
			// chose to permit `PermitSignature.amount`and not `amount` because of type(uint256).max possibilities.
			IERC20PermitUpgradeable(vaultToken).permit(
				msg.sender,
				address(coreController),
				permitSig.amount,
				permitSig.deadline,
				permitSig.v,
				permitSig.r,
				permitSig.s
			);
		}

		// pull `amount` from `to` asset Vault
		coreController.pullAsset(vaultToken, msg.sender, address(this), amount);

		_allowControllerPull(
			nativeToken,
			address(coreController),
			asset,
			amount
		);

		// withdraw to address(this)
		ISavingsCore(coreController.getSavingsCore()).withdraw(asset, amount);
	}

	/**
	 * @dev transfer NativeToken(e.g ETH) to an address, revert if it fails.
	 * @param to recipient of the transfer
	 * @param value the amount to send
	 */
	function _safeTransferNative(address to, uint256 value) internal {
		//solhint-disable-next-line avoid-low-level-calls
		(bool success, ) = to.call{ value: value }(new bytes(0));
		if (!success) {
			revert TransferFailed();
		}
	}

	function _allowControllerPull(
		IWrappedNativeToken nativeToken,
		address coreController,
		address asset,
		uint256 minimumAmount
	) internal {
		IERC20Upgradeable assetToken = IERC20Upgradeable(asset);
		uint256 allowance = assetToken.allowance(address(this), coreController);

		// check coreController allowance to pull from address(this)
		if (allowance <= minimumAmount) {
			nativeToken.approve(coreController, type(uint256).max);
		}
	}
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

/**
 * @title AccountModel library
 * @author eaZI
 * @notice Implements bitmap structure and variables to handle account data, configurations and structures
 */
library AccountModel {
	struct Data {
		Config config; //configuration data in bits
		uint256 id; //Account ID or Number
	}

	struct Config {
		uint256 data;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IPriceOracle interface
 * @notice Interface for the Price oracle.
 **/

interface IPriceOracle {
	/**
	 * @dev returns the asset price in Base Currency
	 * @param asset The asset
	 * @return the Base Currency price of the asset
	 **/
	function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ILendingRateOracle interface
 * @notice Interface for the credit rate oracle.
 * Provides the average credit rate to be used as a base for the stable/fixed credit rate calculations
 **/

interface ILendingRateOracle {
	event CreditRateSet(address indexed asset, uint256 rate);

	/**
    @dev returns the credit rate in ray
    **/
	function getCreditRate(address asset) external view returns (uint256);

	/**
    @dev sets the credit rate. Rate value must be in ray
    **/
	function setCreditRate(address asset, uint256 rate) external;
}