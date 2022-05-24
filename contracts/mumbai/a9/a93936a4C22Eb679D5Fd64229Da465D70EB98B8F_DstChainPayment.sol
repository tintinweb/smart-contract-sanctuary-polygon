// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '../resources/ControllersWrapper.sol';
import '../interfaces/IDstChainPayment.sol';
import '../providers/ProvidersWrapper.sol';
import '../messages/MessageReceiverWrapper.sol';
import '../access/OwnerWithdrawable.sol';
import '../access/Pauser.sol';
import './ResourPayloadTool.sol';
import './ResourcePayTokenWrapper.sol';

/// @author Alexandas
/// @dev Celer SGN source chain sender contract
contract DstChainPayment is
	IDstChainPayment,
	ResourPayloadTool,
	ResourcePayTokenWrapper,
	MessageReceiverWrapper,
	ReentrancyGuardUpgradeable,
	ProvidersWrapper,
	ControllersWrapper,
	OwnerWithdrawable,
	Pauser
{
	using SafeMathUpgradeable for uint256;
	using SafeERC20Upgradeable for IERC20Upgradeable;

	constructor() initializer {}

	/// @dev proxy initialize function
	/// @param owner contract owner
	/// @param pauser contract pauser
	/// @param providers providers contract
	/// @param messageReceiver message receiver contract address
	/// @param token token address
	function initialize(
		address owner,
		address pauser,
		IProviders providers,
		address messageReceiver,
		IERC20Upgradeable token
	) external initializer {
		_transferOwnership(owner);
		__Init_Pauser(pauser);
		__Init_Providers(providers);
		__Init_Message_Receiver(messageReceiver);
		__Init_Token(token);
	}

	/// @dev pay from source chain only called by message receiver
	/// @param _token token address
	/// @param dstAmount token amount
	/// @param message payment payload message bytes
	/// @return value payment value
	function payFromSourceChain(
		IERC20Upgradeable _token,
		uint256 dstAmount,
		bytes calldata message
	) external override onlyMessageReceiver whenNotPaused nonReentrant returns (uint256 value) {
		require(token == _token, 'DstChainPayment: invalid token');
		(address provider, uint64 nonce, bytes32 account, ResourceData.Payload[] memory payloads) = decodeSourceChainMessage(message);
		uint256 amount = matchTokenToResource(dstAmount);
		PaymentPayload memory payload = PaymentPayload(provider, nonce, account, _convertSourceChainPayloads(amount, payloads));
		_processPayloads(payload.account, payload.payloads, false);
		_pay(payload.provider, dstAmount);

		emit Paid(token, payload);
	}

	/// @dev pay on dst chain
	/// @param payload payment payload
	/// @return value payment value
	function pay(PaymentPayload memory payload) public override whenNotPaused nonReentrant returns (uint256 value) {
		value = _processPayloads(payload.account, payload.payloads, true);
		value = matchResourceToToken(value);
		_pay(payload.provider, value);

		emit Paid(token, payload);
	}

	function _pay(address provider, uint256 amount) internal returns (uint256 value) {
		require(providers.isProvider(provider), 'DstChainPayment: nonexistent provider');
		token.safeTransferFrom(msg.sender, address(this), amount);
	}

	function _processPayloads(
		bytes32 account,
		ResourceData.Payload[] memory payloads,
		bool withValue
	) internal returns (uint256 value) {
		require(payloads.length > 0, 'DstChainPayment: invalid payloads');
		for (uint256 i = 0; i < payloads.length; i++) {
			ResourceData.Payload memory payload = payloads[i];
			if (payload.resourceType == ResourceData.ResourceType.BuildingTime) {
				require(payload.values.length == 1, 'DstChainPayment: invalid value length for BuildingTime');
				buildingTimeController.expand(account, payload.values[0]);
			} else if (payload.resourceType == ResourceData.ResourceType.ARStorage) {
				require(payload.values.length == 1, 'DstChainPayment: invalid value length for ARStorage');
				arStorageController.expand(account, payload.values[0]);
			} else if (payload.resourceType == ResourceData.ResourceType.Bandwidth) {
				require(payload.values.length == 1, 'DstChainPayment: invalid value length for Bandwidth');
				bandwidthController.expand(account, payload.values[0]);
			} else if (payload.resourceType == ResourceData.ResourceType.IPFSStorage) {
				require(payload.values.length == 2, 'DstChainPayment: invalid value length for IPFSStorage');
				ipfsStorageController.expand(account, payload.values[0], payload.values[1]);
			} else {
				revert('DstChainPayment: unknown resource type');
			}
			if (withValue) {
				for (uint256 j = 0; j < payload.values.length; j++) {
					value = value.add(payload.values[j]);
				}
			}
		}
	}

	/// @dev set token address
	/// @param _token token address
	function setToken(IERC20Upgradeable _token) external onlyOwner {
		_setToken(_token);
	}

	/// @dev convert source chain payloads
	/// @param amount amount tokens
	/// @param payloads payment payloads
	/// @return converted payment payloads
	function convertSourceChainPayloads(uint256 amount, ResourceData.Payload[] memory payloads) public view returns (ResourceData.Payload[] memory) {
		return _convertSourceChainPayloads(amount, payloads);
	}

	/// @dev decode source chain message
	/// @param message message bytes
	/// @return provider provider address
	/// @return nonce nonce
	/// @return account user account
	/// @return payloads payment payloads
	function decodeSourceChainMessage(bytes memory message)
		public
		view
		returns (
			address provider,
			uint64 nonce,
			bytes32 account,
			ResourceData.Payload[] memory payloads
		)
	{
		(provider, nonce, account, payloads) = abi.decode(message, (address, uint64, bytes32, ResourceData.Payload[]));
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '../resources/interfaces/INormalResourceController.sol';
import '../resources/interfaces/IIPFSStorageController.sol';

/// @author Alexandas
/// @dev all resource controller wrapper contract
abstract contract ControllersWrapper is OwnableUpgradeable {
	/// @dev return building time controller
	INormalResourceController public buildingTimeController;

	/// @dev return bandwidth controller
	INormalResourceController public bandwidthController;

	/// @dev return AR storage controller
	INormalResourceController public arStorageController;

	/// @dev return ipfs storage controller
	IIPFSStorageController public ipfsStorageController;

	/// @dev emit when building time controller updated
	/// @param _buildingTimeController building time controller contract
	event BuildingTimeControllerUpdated(INormalResourceController _buildingTimeController);

	/// @dev emit when bandwidth controller updated
	/// @param _bandwidthController bandwidth controller contract
	event BandwidthControllerUpdated(INormalResourceController _bandwidthController);

	/// @dev emit when AR storage controller updated
	/// @param _arStorageController AR storage controller contract
	event ARStorageControllerUpdated(INormalResourceController _arStorageController);

	/// @dev emit when ipfs storage controller updated
	/// @param _ipfsStorageController IPFS storage controller contract
	event IPFSStorageControllerUpdated(IIPFSStorageController _ipfsStorageController);

	/// @dev update building time controller contract
	/// @param _buildingTimeController building time controller contract
	function setBuildingTimeController(INormalResourceController _buildingTimeController) external onlyOwner {
		_setBuildingTimeController(_buildingTimeController);
	}

	/// @dev update bandwidth controller contract
	/// @param _bandwidthController bandwidth controller contract
	function setBandwidthController(INormalResourceController _bandwidthController) external onlyOwner {
		_setBandwidthController(_bandwidthController);
	}

	/// @dev update AR storage controller contract
	/// @param _arStorageController AR storage controller contract
	function setARStorageController(INormalResourceController _arStorageController) external onlyOwner {
		_setARStorageController(_arStorageController);
	}

	/// @dev update ipfs storage controller contract
	/// @param _ipfsStorageController IPFS storage controller contract
	function setIPFSStorageController(IIPFSStorageController _ipfsStorageController) external onlyOwner {
		_setIPFSStorageController(_ipfsStorageController);
	}

	function _setBuildingTimeController(INormalResourceController _buildingTimeController) internal {
		buildingTimeController = _buildingTimeController;
		emit BuildingTimeControllerUpdated(_buildingTimeController);
	}

	function _setBandwidthController(INormalResourceController _bandwidthController) internal {
		bandwidthController = _bandwidthController;
		emit BandwidthControllerUpdated(_bandwidthController);
	}

	function _setARStorageController(INormalResourceController _arStorageController) internal {
		arStorageController = _arStorageController;
		emit ARStorageControllerUpdated(_arStorageController);
	}

	function _setIPFSStorageController(IIPFSStorageController _ipfsStorageController) internal {
		ipfsStorageController = _ipfsStorageController;
		emit IPFSStorageControllerUpdated(_ipfsStorageController);
	}
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol';
import '../libraries/ResourceData.sol';

/// @author Alexandas
/// @dev DstChainPayment interface
interface IDstChainPayment {
	struct PaymentPayload {
		address provider;
		uint64 nonce;
		bytes32 account;
		ResourceData.Payload[] payloads;
	}

	/// @dev emit when a user paid
	/// @param token token address
	/// @param payload payment payload
	event Paid(IERC20Upgradeable token, PaymentPayload payload);

	/// @dev pay from the source chain
	/// @param token token address
	/// @param amount token amount
	/// @param message payment payload message
	/// @return value token used
	function payFromSourceChain(
		IERC20Upgradeable token,
		uint256 amount,
		bytes calldata message
	) external returns (uint256 value);

	/// @dev pay on the dst chain
	/// @param payload payment payload
	/// @return value token used
	function pay(PaymentPayload memory payload) external returns (uint256 value);
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '../interfaces/IProvidersWrapper.sol';

/// @author Alexandas
/// @dev providers wrapper contract
abstract contract ProvidersWrapper is IProvidersWrapper, Initializable {
	/// @dev providers contract address
	IProviders public override providers;

	/// @dev initialize providers contract
	/// @param _providers providers contract address
	function __Init_Providers(IProviders _providers) internal onlyInitializing {
		_setProviders(_providers);
	}

	function _setProviders(IProviders _providers) internal {
		providers = _providers;
		emit ProvidersUpdated(_providers);
	}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

/// @author Alexandas
/// @dev dst chain message receiver wrapper
abstract contract MessageReceiverWrapper is OwnableUpgradeable {
	/// @dev message receiver contract address
	address public messageReceiver;

	/// @dev emit when message receiver updated
	/// @param messageReceiver message receiver contract address
	event MessageReceiverUpdated(address messageReceiver);

	modifier onlyMessageReceiver() {
		require(msg.sender == messageReceiver, 'MessageReceiverWrapper: caller is not message receiver');
		_;
	}

	/// @dev initialize messageReceiver contract address
	/// @param _messageReceiver message receiver contract address
	function __Init_Message_Receiver(address _messageReceiver) internal onlyInitializing {
		_setMessageReceiver(_messageReceiver);
	}

	/// @dev set messageReceiver contract address
	/// @param _messageReceiver message receiver contract address
	function setMessageReceiver(address _messageReceiver) external onlyOwner {
		_setMessageReceiver(_messageReceiver);
	}

	function _setMessageReceiver(address _messageReceiver) internal {
		messageReceiver = _messageReceiver;
		emit MessageReceiverUpdated(_messageReceiver);
	}
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';

/// @author Alexandas
/// @dev Make the contract owner can withdraw token and eth
abstract contract OwnerWithdrawable is OwnableUpgradeable {
	using SafeERC20Upgradeable for IERC20Upgradeable;

	/// @dev emit when token is withdrawn
	/// @param token token address
	/// @param to receiver address
	/// @param value token value
	event Withdrawal(IERC20Upgradeable token, address to, uint256 value);

	/// @dev emit when ETH is withdrawn
	/// @param to receiver address
	/// @param value token value
	event NativeWithdrawal(address to, uint256 value);

	/// @dev withdraw token
	/// @param token token address
	/// @param to receiver address
	/// @param value token value
	function ownerWithdrawERC20(
		IERC20Upgradeable token,
		address to,
		uint256 value
	) external onlyOwner {
		token.safeTransfer(to, value);
		emit Withdrawal(token, to, value);
	}

	/// @dev withdraw ETH
	/// @param to receiver address
	/// @param value token value
	function ownerWithdrawNative(address payable to, uint256 value) external onlyOwner {
		bool success = to.send(value);
		require(success, 'Payment: withdraw native token failed');
		emit NativeWithdrawal(to, value);
	}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

/// @author Alexandas
/// @dev make contract pausable
abstract contract Pauser is OwnableUpgradeable, PausableUpgradeable {
	/// @dev all pausers
	mapping(address => bool) public pausers;

	/// @dev emit when pauser is added
	/// @param account pauser address
	event PauserAdded(address account);

	/// @dev emit when pauser is removed
	/// @param account pauser address
	event PauserRemoved(address account);

	function __Init_Pauser(address account) internal onlyInitializing {
		_addPauser(account);
	}

	modifier onlyPauser() {
		require(isPauser(msg.sender), 'Pauser: caller is not the pauser');
		_;
	}

	/// @dev pause the contract
	function pause() public onlyPauser {
		_pause();
	}

	/// @dev unpause the contract
	function unpause() public onlyPauser {
		_unpause();
	}

	/// @dev whether the account is the contract pauser
	/// @param account address
	/// @return whether account is a pauser
	function isPauser(address account) public view returns (bool) {
		return pausers[account];
	}

	/// @dev add a pauser for the contract
	/// @param account address
	function addPauser(address account) public onlyOwner {
		_addPauser(account);
	}

	/// @dev remove a pauser for the contract
	/// @param account address
	function removePauser(address account) public onlyOwner {
		_removePauser(account);
	}

	/// @dev remove a pauser for the contract
	function renouncePauser() public {
		_removePauser(msg.sender);
	}

	function _addPauser(address account) private {
		require(!isPauser(account), 'Pauser: account is already pauser');
		pausers[account] = true;
		emit PauserAdded(account);
	}

	function _removePauser(address account) private {
		require(isPauser(account), 'Pauser: account is not pauser');
		delete pausers[account];
		emit PauserRemoved(account);
	}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '../libraries/ResourceData.sol';

/// @author Alexandas
/// @dev resource payload tool contract
abstract contract ResourPayloadTool {
	using SafeMathUpgradeable for uint256;

	/// @dev convert source chain payment payload into dst chain payment payload
	/// @param dstAmount token amount
	/// @param payloads source chain payment payload
	/// @return newPayloads dst chain payment payload
	function _convertSourceChainPayloads(uint256 dstAmount, ResourceData.Payload[] memory payloads)
		internal
		pure
		returns (ResourceData.Payload[] memory newPayloads)
	{
		require(payloads.length > 0, 'ResourPayloadTool: invalid payload length');
		uint256 total = totalValue(payloads);
		require(total > 0, 'ResourPayloadTool: zero total value');
		for (uint256 i = 0; i < payloads.length; i++) {
			require(payloads[i].values.length > 0, 'ResourPayloadTool: invalid value length');
			for (uint256 j = 0; j < payloads[i].values.length; j++) {
				payloads[i].values[j] = payloads[i].values[j].mul(dstAmount).div(total);
			}
		}
		return payloads;
	}

	/// @dev payment payload total value
	/// @param payloads payment payloads
	/// @return value total value
	function totalValue(ResourceData.Payload[] memory payloads) public pure returns (uint256 value) {
		require(payloads.length > 0, 'ResourPayloadTool: invalid payloads length');
		for (uint256 i = 0; i < payloads.length; i++) {
			for (uint256 j = 0; j < payloads[i].values.length; j++) {
				value = value.add(payloads[i].values[j]);
			}
		}
	}
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';

/// @author Alexandas
/// @dev token wrapper contract
abstract contract ResourcePayTokenWrapper is Initializable {
	using SafeMathUpgradeable for uint256;

	/// @dev token address
	IERC20Upgradeable public token;

	/// @dev emit when token updated
	/// @param token token address
	event TokenUpdated(IERC20Upgradeable token);

	/// @dev initialize token
	/// @param _token token address
	function __Init_Token(IERC20Upgradeable _token) internal onlyInitializing {
		_setToken(_token);
	}

	function _setToken(IERC20Upgradeable _token) internal {
		require(address(_token) != address(0), 'ResourcePayTokenWrapper: zero address');
		token = _token;
		emit TokenUpdated(token);
	}

	/// @dev match token amount to resource decimals
	/// @param value token amount with resource decimals
	/// @return resource value
	function matchTokenToResource(uint256 value) public view returns (uint256) {
		uint256 _tokenDecimals = tokenDecimals();
		uint256 _resourceDecimals = resourceDecimals();
		if (_tokenDecimals <= _resourceDecimals) {
			return value.mul(10**(_resourceDecimals.sub(_tokenDecimals)));
		}
		return value.div(10**(_tokenDecimals.sub(_resourceDecimals)));
	}

	/// @dev match value to token decimals
	/// @param value resource value
	/// @return token value
	function matchResourceToToken(uint256 value) public view returns (uint256) {
		uint256 _tokenDecimals = tokenDecimals();
		uint256 _resourceDecimals = resourceDecimals();
		if (_tokenDecimals <= _resourceDecimals) {
			return value.div(10**(_resourceDecimals.sub(_tokenDecimals)));
		}
		return value.mul(10**(_tokenDecimals.sub(_resourceDecimals)));
	}

	/// @dev return resource decimals
	/// @return resource decimals
	function resourceDecimals() public view returns (uint256) {
		return 18;
	}

	/// @dev return token decimals
	/// @return token decimals
	function tokenDecimals() public view returns (uint256) {
		// keccak256(bytes4('decimals()'))
		(bool success, bytes memory data) = address(token).staticcall(hex'313ce567');
		require(success, 'ResourcePayTokenWrapper: invalid token');
		return abi.decode(data, (uint256));
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import './IAdaptorWrapper.sol';

/// @author Alexandas
/// @dev normal resource controller interface
interface INormalResourceController is IAdaptorWrapper {
	/// @dev emit when resource expanded
	/// @param account user account
	/// @param value token value for resource decimals
	event Expanded(bytes32 account, uint256 value);

	/// @dev expand user's normal resource balance
	/// @param account user account
	/// @param value token value in resource decimals(18)
	function expand(bytes32 account, uint256 value) external;

	/// @dev resource balance
	/// @param account user account
	/// @return balance of the account
	function balanceOf(bytes32 account) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import './IAdaptorWrapper.sol';

/// @author Alexandas
/// @dev IPFS storage controller interface
interface IIPFSStorageController is IAdaptorWrapper {
	struct IPFSStorage {
		uint256 startTime;
		uint256 expiration;
		uint256 amount;
	}

	/// @dev emit when ipfs resource expanded
	/// @param account user account
	/// @param expandedStorageFee storage fee
	/// @param expandedExpirationFee expiration fee
	event Expanded(bytes32 account, uint256 expandedStorageFee, uint256 expandedExpirationFee);

	/// @dev expand ipfs resource
	/// @param account user account
	/// @param expandedStorageFee storage fee
	/// @param expandedExpirationFee expiration fee
	function expand(
		bytes32 account,
		uint256 expandedStorageFee,
		uint256 expandedExpirationFee
	) external;

	/// @dev return whether the account is expired
	/// @param account user account
	/// @return whether the account is expired
	function isExpired(bytes32 account) external view returns (bool);

	/// @dev ipfs resource start time
	/// @param account user account
	/// @return start time for ipfs resource
	function startTime(bytes32 account) external view returns (uint256);

	/// @dev return available expiration time for the account
	/// @param account user account
	/// @return available expiration time for the account
	function availableExpiration(bytes32 account) external view returns (uint256);

	/// @dev return total expiration time for the account
	/// @param account user account
	/// @return total expiration time for the account
	function expiration(bytes32 account) external view returns (uint256);

	/// @dev return when the account will expire
	/// @param account user account
	/// @return when the account will expire
	function expiredAt(bytes32 account) external view returns (uint256);

	/// @dev return ipfs storage amount for the account
	/// @param account user account
	/// @return ipfs storage amount for the account
	function balanceOf(bytes32 account) external view returns (uint256);

	/// @dev calculate fee for storage and expiration
	/// @param account user account
	/// @param expandedStorage storage amount
	/// @param expandedExpiration  expiration(in seconds)
	/// @return expandedStorageFee storage fee
	/// @return expandedExpirationFee expiration fee
	function expandedFee(
		bytes32 account,
		uint256 expandedStorage,
		uint256 expandedExpiration
	) external view returns (uint256 expandedStorageFee, uint256 expandedExpirationFee);

	/// @dev calculate fee for storage and expiration
	/// @param account user account
	/// @param expandedStorageFee storage fee
	/// @param expandedExpirationFee expiration fee
	/// @return expandedStorage storage amount
	/// @return expandedExpiration expiration(in seconds)
	function expansions(
		bytes32 account,
		uint256 expandedStorageFee,
		uint256 expandedExpirationFee
	) external view returns (uint256 expandedStorage, uint256 expandedExpiration);
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

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '../interfaces/IResourceAdaptor.sol';
import '../../libraries/ResourceData.sol';

/// @author Alexandas
/// @dev resource adaptor interface
interface IAdaptorWrapper {
	/// @dev emit when resource adaptor updated
	/// @param adaptor resource adaptor contract address
	event ResourceAdaptorUpdated(IResourceAdaptor adaptor);

	/// @dev emit when resource type updated
	/// @param resourceType resource type
	event ResourceTypeUpdated(ResourceData.ResourceType resourceType);

	/// @dev return resource adaptor contract address
	function adaptor() external view returns (IResourceAdaptor);

	/// @dev return resource type
	function resourceType() external view returns (ResourceData.ResourceType);

	/// @dev return resource price
	function price() external view returns (uint256);

	/// @dev calculate resource value for amount
	function getValueOf(uint256 amount) external view returns (uint256);

	/// @dev calculate resource amount for value
	function getAmountOf(uint256 value) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '../../libraries/ResourceData.sol';

/// @author Alexandas
/// @dev resource adpator interface
interface IResourceAdaptor {
	struct PriceAdaptor {
		ResourceData.ResourceType resourceType;
		uint256 price;
	}

	/// @dev emit when price updated
	/// @param adaptors price adaptors
	event PriceAdaptorsUpdated(PriceAdaptor[] adaptors);

	/// @dev get price for resource at a specific block
	/// @param resourceType resource type
	/// @param _indexBlock block number
	/// @return price for resource at a specific block
	function priceAt(ResourceData.ResourceType resourceType, uint256 _indexBlock) external view returns (uint256);

	/// @dev get value for `amount` resource at a specific block
	/// @param resourceType resource type
	/// @param amount resource amount
	/// @param _indexBlock block number
	/// @return token value in resource decimals(18)
	function getValueAt(
		ResourceData.ResourceType resourceType,
		uint256 amount,
		uint256 _indexBlock
	) external view returns (uint256);

	/// @dev get amount resource with value at a specific block
	/// @param resourceType resource type
	/// @param value token value
	/// @param _indexBlock block numer
	/// @return resource amount
	function getAmountAt(
		ResourceData.ResourceType resourceType,
		uint256 value,
		uint256 _indexBlock
	) external view returns (uint256);

	/// @dev return resource price
	/// @param resourceType resource type
	/// @return resource price
	function priceOf(ResourceData.ResourceType resourceType) external view returns (uint256);

	/// @dev return value of amount resource
	/// @param resourceType resource type
	/// @param amount resource amount
	/// @return token value in resource decimals(18)
	function getValueOf(ResourceData.ResourceType resourceType, uint256 amount) external view returns (uint256);

	/// @dev return resource amount with value
	/// @param resourceType resource type
	/// @param value token value in resource decimals(18)
	/// @return resource amount
	function getAmountOf(ResourceData.ResourceType resourceType, uint256 value) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

/// @author Alexandas
/// @dev resource data library
library ResourceData {
	enum ResourceType {
		Null,
		BuildingTime,
		Bandwidth,
		ARStorage,
		IPFSStorage
	}

	struct Payload {
		ResourceData.ResourceType resourceType;
		uint256[] values;
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
library SafeMathUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '../interfaces/IProviders.sol';

/// @author Alexandas
/// @dev providers wrapper interface
interface IProvidersWrapper {
	/// @dev emit when providers contract updated
	/// @param providers providers contract
	event ProvidersUpdated(IProviders providers);

	/// @dev return providers contract address
	function providers() external view returns (IProviders);
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

/// @author Alexandas
/// @dev providers interface
interface IProviders {
	/// @dev emit when provider is added
	/// @param provider provider address
	event AddProvider(address provider);

	/// @dev emit when provider removed
	/// @param provider provider address
	event RemoveProvider(address provider);

	/// @dev return whether address is a provider
	/// @param provider address
	function isProvider(address provider) external view returns (bool);

	/// @dev return whether a valid signature
	/// @param provider address
	/// @param hash message hash
	/// @param signature provider signature for message hash
	/// @return is valid signature
	function isValidSignature(
		address provider,
		bytes32 hash,
		bytes memory signature
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