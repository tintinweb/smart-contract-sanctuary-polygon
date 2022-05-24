// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '../providers/ProvidersWrapper.sol';
import '../resources/interfaces/IIPFSStorageController.sol';

/// @author Alexandas
/// @dev IPFS content tracer
contract ContentTracer is ProvidersWrapper, OwnableUpgradeable {
	using SafeMathUpgradeable for uint256;

	/// @dev ipfs storage controller
	IIPFSStorageController public controller;

	struct ContentMeta {
		uint256 size;
		uint256 count;
	}

	/// @dev ipfs content content meta
	mapping(address => mapping(bytes32 => mapping(string => ContentMeta))) public metas;

	/// @dev emit when ipfs storage controller updated
	/// @param controller ipfs storage controller
	event ControllerUpdated(IIPFSStorageController controller);

	/// @dev emit when ipfs content inserted
	/// @param provider provider address
	/// @param account user account
	/// @param content ipfs content
	/// @param size ipfs content size
	/// @param count ipfs content count
	/// @param expiration ipfs content expiration
	event Insert(address provider, bytes32 account, string content, uint256 size, uint256 count, uint256 expiration);

	/// @dev emit when ipfs content removed
	/// @param provider provider address
	/// @param account user account
	/// @param content ipfs content
	/// @param size ipfs content size
	/// @param count ipfs content count
	event Remove(address provider, bytes32 account, string content, uint256 size, uint256 count);

	modifier onlyProvider() {
		require(providers.isProvider(msg.sender), 'ContentTracer: caller is not the provider');
		_;
	}

	modifier nonSize(uint256 size) {
		require(size > 0, 'ContentTracer: zero size.');
		_;
	}

	/// @dev proxy initialize function
	/// @param owner contract owner
	/// @param providers providers contract address
	/// @param controller ipfs storage controller
	function initialize(
		address owner,
		IProviders providers,
		IIPFSStorageController controller
	) external initializer {
		_transferOwnership(owner);
		__Init_Providers(providers);
		_setController(controller);
	}

	/// @dev update ipfs storage controller
	/// @param _controller ipfs storage controller
	function setController(IIPFSStorageController _controller) external onlyOwner {
		_setController(_controller);
	}

	function _setController(IIPFSStorageController _controller) internal {
		controller = _controller;
		emit ControllerUpdated(_controller);
	}

	/// @dev insert multiple ipfs content for accounts
	/// @param accounts array of user account
	/// @param contents array of ipfs contents
	/// @param sizes array of ipfs content size
	/// @param counts array of ipfs content count
	function insertMult(
		bytes32[] memory accounts,
		string[] memory contents,
		uint256[] memory sizes,
		uint256[] memory counts
	) external onlyProvider {
		require(accounts.length == contents.length, 'ContentTracer: Invalid parameter length.');
		require(accounts.length == sizes.length, 'ContentTracer: Invalid parameter length.');
		require(accounts.length == counts.length, 'ContentTracer: Invalid parameter length.');

		for (uint256 i = 0; i < accounts.length; i++) {
			_insert(msg.sender, accounts[i], contents[i], sizes[i], counts[i]);
		}
	}

	/// @dev insert ipfs content
	/// @param account user account
	/// @param content ipfs content
	/// @param size ipfs account size
	function insert(
		bytes32 account,
		string memory content,
		uint256 size,
		uint256 count
	) public nonSize(size) onlyProvider {
		_insert(msg.sender, account, content, size, count);
	}

	function _insert(
		address provider,
		bytes32 account,
		string memory content,
		uint256 size, 
		uint256 count
	) internal nonSize(size) {
		require(!exists(provider, account, content), 'ContentTracer: content exists');
		require(!controller.isExpired(account), 'ContentTracer: account expired');
		metas[provider][account][content] = ContentMeta(size, count);

		emit Insert(provider, account, content, size, count, controller.expiredAt(account));
	}

	/// @dev remove ipfs content
	/// @param accounts array of user account
	/// @param contents array of ipfs contents
	function removeMult(bytes32[] memory accounts, string[] memory contents) external onlyProvider {
		require(accounts.length == contents.length, 'ContentTracer: Invalid parameter length');
		for (uint256 i = 0; i < accounts.length; i++) {
			_remove(msg.sender, accounts[i], contents[i]);
		}
	}

	/// @dev remove ipfs content
	/// @param account user account
	/// @param content ipfs content
	function remove(bytes32 account, string memory content) public onlyProvider {
		_remove(msg.sender, account, content);
	}

	function _remove(
		address provider,
		bytes32 account,
		string memory content
	) internal {
		require(exists(provider, account, content), 'ContentTracer: nonexistent content');
		ContentMeta memory meta = metas[provider][account][content];
		delete metas[provider][account][content];

		emit Remove(provider, account, content, meta.size, meta.count);
	}

	/// @dev return whether ipfs content exists in provider
	/// @param provider provider address
	/// @param account user account
	/// @param content ipfs content
	/// @return ipfs ipfs content exists
	function exists(
		address provider,
		bytes32 account,
		string memory content
	) public view returns (bool) {
		return metas[provider][account][content].size != 0;
	}

	/// @dev return ipfs content size
	/// @param provider provider address
	/// @param account user account
	/// @param content ipfs content
	/// @return ipfs ipfs content size
	function size(
		address provider,
		bytes32 account,
		string memory content
	) public view returns (uint256) {
		require(providers.isProvider(provider), 'ContentTracer: nonexistent provider');
		require(exists(provider, account, content), 'ContentTracer: nonexistent content');
		return metas[provider][account][content].size;
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