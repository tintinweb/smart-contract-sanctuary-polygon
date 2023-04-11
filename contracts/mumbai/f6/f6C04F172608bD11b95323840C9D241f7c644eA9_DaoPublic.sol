// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./LinkedList.sol";

interface IFxStateChildTunnel {
    function sendMessageToRoot(bytes memory message) external;

    function SEND_MESSAGE_EVENT_SIG() external view returns (bytes32);
}

interface IDaoCommittee {
    function committeeMembersCounter() external view returns (uint256);

    function Committee(address _add) external view returns (bool);
}

contract DaoPublic is LinkedList, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 public FIXED_DURATION;

    IFxStateChildTunnel public FxStateChildTunnel;

    struct NFTInfo {
        string uri;
        address owner;
        uint256 index;
        uint256 votes;
        uint256 winTime;
        uint256 votersCount;
        uint256 favourVotes;
        uint256 disApprovedVotes;
        bool isApprovedByCommittee;
        bool winnerStatus;
        bool isBlackListed;
        bool rewardClaim;
    }

    IDaoCommittee public daoCommittee;
    uint256 public timer;
    uint256 private nftIndex;

    uint256[] public winnersIndexes;
    mapping(uint256 => NFTInfo) public nftInfoo;
    mapping(uint256 => mapping(address => bool)) public voteCheck;
    mapping(uint256 => mapping(address => bool)) public isclaimed;

    modifier onlyDaoCommitte() {
        require(
            msg.sender == address(daoCommittee),
            "Only DaoCommittee can call"
        );
        _;
    }

    event PublicVote(address voter, uint256 index, NFTInfo _NFT);
    event NftApproved(uint256 index, NFTInfo _NFT, uint256 startTime);
    event Winner(uint256 index, NFTInfo _NFT);
    event claimed(
        address claimedBy,
        uint256 index,
        uint256 amount,
        uint256 claimTime,
        bool rewardClaim,
        bytes32 eventSign);
    event blackListed(uint256 index, bool decision, NFTInfo _NFT);
    event voteForBlackList(
        address committeeMember,
        uint256 index,
        bool decision,
        NFTInfo _NFT
    );

    function initialize(
        IDaoCommittee _daoCommittee,
        uint256 _timer,
        uint256 FIXED_DURATION_
    ) public initializer {
        __LinkedList_init();
        __Ownable_init();
        daoCommittee = _daoCommittee;
        timer = block.timestamp + _timer;
        FIXED_DURATION = FIXED_DURATION_;
    }

    function addInfo(
        string calldata uri,
        address _owner,
        bool _isApprovedByCommittee
    ) external onlyDaoCommitte {
        _addInfo(uri, _owner, _isApprovedByCommittee);
    }

    function _addInfo(
        string calldata uri,
        address _owner,
        bool _isApprovedByCommittee
    ) internal {
        nftInfoo[nftIndex] = NFTInfo(
            uri,
            _owner,
            nftIndex,
            0,
            0,
            0,
            0,
            0,
            _isApprovedByCommittee,
            false,
            false,
            false
        );
        emit NftApproved(nftIndex, nftInfoo[nftIndex], block.timestamp);
        nftIndex++;
    }

    function voteNfts(uint256 index) external {
        require(nftInfoo[index].isBlackListed == false, "Blacklisted");
        require(nftInfoo[index].winnerStatus == false, "Already winner");
        require(voteCheck[index][msg.sender] == false, "Already Voted");
        require(index < nftIndex, " Choose Correct NFT to vote ");

        NFTInfo storage nftToVote = nftInfoo[index];

        nftToVote.votes++;
        insertUp(index);
        voteCheck[index][msg.sender] = true;

        nftInfoo[index].votersCount++;
        isclaimed[index][msg.sender] = false;

        emit PublicVote(msg.sender, index, nftInfoo[index]);

        if (block.timestamp >= timer) {
            _announceWinner();
        }
    }

    function announceWinner() external {
        if (block.timestamp >= timer) {
            _announceWinner();
        }
    }

    function _announceWinner() internal {
        (bool isValid, uint256 index) = getHighest();

        if (
            isValid &&
            !nftInfoo[index].winnerStatus &&
            !nftInfoo[index].isBlackListed
        ) {
            nftInfoo[index].winnerStatus = true;
            nftInfoo[index].winTime = timer;
            winnersIndexes.push(index);
            FxStateChildTunnel.sendMessageToRoot(abi.encode(nftInfoo[index].owner, 720 ether));
            remove(index);
            emit Winner(index, nftInfoo[index]);
            emit claimed(
                nftInfoo[index].owner,
                index,
                720 ether,
                block.timestamp,
                true,
                FxStateChildTunnel.SEND_MESSAGE_EVENT_SIG() );
        }
        uint256 dDays = (block.timestamp.sub(timer.sub(FIXED_DURATION))).div(
            FIXED_DURATION
        );
        timer = timer.add(dDays.mul(FIXED_DURATION));
    }

    function claim(uint256 index) public {
        require(nftInfoo[index].isBlackListed == false, " Blacklisted");
        require(
            nftInfoo[index].winnerStatus == true,
            "Can't Claim: Not Winner"
        );
        require(voteCheck[index][msg.sender] == true, "You have not voted");
        require(isclaimed[index][msg.sender] == false, "Already Claimed");
        uint256 amount = 180 ether / (nftInfoo[index].votersCount);
        FxStateChildTunnel.sendMessageToRoot(abi.encode(msg.sender,amount));

        isclaimed[index][msg.sender] = true;
        emit claimed(msg.sender, index, amount, block.timestamp, true,FxStateChildTunnel.SEND_MESSAGE_EVENT_SIG() );
    }

    // check and modify claimbatch function

    function claimBatch(uint256[] calldata indexes) public {
        uint256 total;
        for (uint256 i; i < indexes.length; i++) {
            require(
                nftInfoo[indexes[i]].isBlackListed == false,
                " Blacklisted"
            );
            require(
                nftInfoo[indexes[i]].winnerStatus == true,
                "Can't Claim: Not Winner"
            );
            require(
                voteCheck[indexes[i]][msg.sender] == true,
                "You have not voted"
            );
            require(
                isclaimed[indexes[i]][msg.sender] == false,
                "Already Claimed"
            );
            uint256 amount = 180 ether / (nftInfoo[indexes[i]].votersCount);
            total += amount;
            isclaimed[indexes[i]][msg.sender] = true;
            nftInfoo[indexes[i]].rewardClaim = true;
            emit claimed(msg.sender, indexes[i], amount, block.timestamp,true, FxStateChildTunnel.SEND_MESSAGE_EVENT_SIG());
        }

        FxStateChildTunnel.sendMessageToRoot(
            abi.encode(msg.sender, total)
        );
    }

    function getTotalAmounts(address _address)
        public
        view
        returns (uint256, uint256[] memory)
    {
        uint256 totalAmount;

        uint256 loc;
        uint256 count;
        uint256[] memory indexes;

        for (uint256 i; i < nftIndex; i++) {
            if (
                voteCheck[i][_address] == true &&
                nftInfoo[i].isBlackListed == false &&
                isclaimed[i][_address] == false &&
                nftInfoo[i].winnerStatus == true
            ) {
                uint256 amount = 180 ether / (nftInfoo[i].votersCount);
                totalAmount += amount;
                // indexes[loc]=i;
                loc++;
            }
        }
        indexes = new uint256[](loc);

        for (uint256 j; j < nftIndex; j++) {
            if (
                voteCheck[j][_address] == true &&
                nftInfoo[j].isBlackListed == false &&
                isclaimed[j][_address] == false &&
                nftInfoo[j].winnerStatus == true
            ) {
                indexes[count] = j;
                count++;
            }
        }

        return (totalAmount, indexes);
    }

    function updateDaoCommitteeAddress(IDaoCommittee _address)
        external
        onlyOwner
    {
        daoCommittee = _address;
    }

    function setFxStateChildTunnel(IFxStateChildTunnel _FxStateChildTunnel)
        external
        onlyOwner
    {
        FxStateChildTunnel = _FxStateChildTunnel;
    }

    function setTimer(uint256 _FIXED_DURATION) public {
        FIXED_DURATION = _FIXED_DURATION;
    }

    function blackListArt(uint256 index, bool decision) public {
        require(nftInfoo[index].isBlackListed == false, "Already Blacklisted");
        require(
            daoCommittee.Committee(msg.sender) == true,
            "Only Committee Member can call"
        );
        uint256 votesTarget = (daoCommittee.committeeMembersCounter() / 2) + 1;

        // require either favour /disfavour votes < target votes, "already checked"
        require(
            nftInfoo[index].favourVotes < votesTarget ||
                nftInfoo[index].disApprovedVotes < votesTarget,
            "Already voted for this art"
        );
        if (block.timestamp >= timer) {
            _announceWinner();
        }

        if (decision == true) {
            nftInfoo[index].favourVotes++;
            if (nftInfoo[index].favourVotes >= votesTarget) {
                nftInfoo[index].isBlackListed = true;
                if (nftInfoo[index].votes > 0) {
                    remove(index);
                }
                emit blackListed(index, decision, nftInfoo[index]);
            }
            emit voteForBlackList(msg.sender, index, decision, nftInfoo[index]);
        } else {
            nftInfoo[index].disApprovedVotes++;
            emit voteForBlackList(msg.sender, index, decision, nftInfoo[index]);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev The `votes` are considered as the 1D index for each `tokenId`
 * @dev The `position` is the 2D index for each `tokenId`
 */
abstract contract LinkedList {

    struct Position {
        int votes;
        uint position;
    }

    struct Node {
        int next;
        int prev;

        uint[] tokenIds;
    }

    struct AllPosition {
        mapping (int => Node) nodes;

        int head;
        int tail;

        uint totalVoteCount;
    }

    /// @dev The LinkedList
    AllPosition internal _allPositions;
    /// @dev Reveals the number of votes and position in their corresponding node's `positions` array relevant to each `tokenId`
    mapping (uint => Position) public getPosition;

    function __LinkedList_init() internal {
        __LinkedList_init_unchained();
    }

    function __LinkedList_init_unchained() internal {
        // HEAD's next will always be ZERO and prev will always be HIGHEST VOTES
        _allPositions.head = -1;
        // TAIL's next will always be LOWEST VOTES and prev will always be ZERO
        _allPositions.tail = 0;

        _allPositions.nodes[_allPositions.head].prev = _allPositions.tail;
        _allPositions.nodes[_allPositions.tail].next = _allPositions.head;
    }

    function insertUp(uint tokenId) internal {
        bool nodeCreated;
        Position storage currentPosition = getPosition[tokenId];
        int lastVotes = currentPosition.votes;
        Node storage lastNode = _allPositions.nodes[lastVotes];
        if (currentPosition.votes != 0) {
            uint[] storage currentTokenIds = _allPositions.nodes[currentPosition.votes].tokenIds;

            // getting the last tokenId and its position data
            uint lastTokenId = currentTokenIds[currentTokenIds.length - 1];
            Position storage lastPosition = getPosition[lastTokenId];

            // replacing our given tokenId with last tokenId
            currentTokenIds[currentPosition.position] = currentTokenIds[lastPosition.position];

            // removing the duplicate last tokenId
            currentTokenIds.pop();

            if (currentTokenIds.length == 0) {
                Node storage currentNode = _allPositions.nodes[currentPosition.votes];

                // getting the given node's next and prev
                Node storage nextNode = _allPositions.nodes[currentNode.next];
                Node storage prevNode = _allPositions.nodes[currentNode.prev];

                // changing linkage for removal
                prevNode.next = currentNode.next;
                nextNode.prev = currentNode.prev;

                // setting lastVotes and lastNode
                lastVotes = currentNode.prev;
                lastNode = _allPositions.nodes[lastVotes];

                // deleting given node
                delete _allPositions.nodes[currentPosition.votes];
            }

            // saving new position of last tokenId
            lastPosition.position = currentPosition.position;
        }

        // changing votes for our given tokenId
        currentPosition.votes++;

        uint[] storage nextTokenIds = _allPositions.nodes[currentPosition.votes].tokenIds;

        if (nextTokenIds.length == 0) {
            nodeCreated = true;
        }

        // pushing our given tokenId into the relevant/next node
        nextTokenIds.push(tokenId);

        // changing the position of our given tokenId to it's new position in the relevant/next node
        currentPosition.position = nextTokenIds.length - 1;

        if (nodeCreated) {
            Node storage currentNode = _allPositions.nodes[currentPosition.votes];
            Node storage nextNode = _allPositions.nodes[lastNode.next];

            // changing linkage for node given it was newly created
            currentNode.next = lastNode.next;
            currentNode.prev = lastVotes;

            // changing next node's linkage
            nextNode.prev = currentPosition.votes;

            // changing given tokenId's last node's linkage
            lastNode.next = currentPosition.votes;
        }

        _allPositions.totalVoteCount++;
    }

    function remove(uint tokenId) internal {
        Position storage currentPosition = getPosition[tokenId];

        uint[] storage currentTokenIds = _allPositions.nodes[currentPosition.votes].tokenIds;

        // getting the last tokenId and its position data
        uint lastTokenId = currentTokenIds[currentTokenIds.length - 1];
        Position storage lastPosition = getPosition[lastTokenId];

        // replacing our given tokenId with last tokenId
        currentTokenIds[currentPosition.position] = currentTokenIds[lastPosition.position];

        // removing the duplicate last tokenId
        currentTokenIds.pop();

        // saving new position of last tokenId
        lastPosition.position = currentPosition.position;

        // adjusting next/prev if node is empty
        if (currentTokenIds.length == 0) {
            Node storage currentNode = _allPositions.nodes[currentPosition.votes];

            // getting the given node's next and prev
            Node storage nextNode = _allPositions.nodes[currentNode.next];
            Node storage prevNode = _allPositions.nodes[currentNode.prev];

            // changing linkage for removal
            prevNode.next = currentNode.next;
            nextNode.prev = currentNode.prev;

            // deleting given node
            delete _allPositions.nodes[currentPosition.votes];
        }

        // deleting given position
        delete getPosition[tokenId];
    }

    function getHighest() internal view returns (bool isValid, uint winner) {
        Node memory headNode = _allPositions.nodes[_allPositions.head];

        // node before head will contain tokenIds with highest votes
        Node memory highestNode = _allPositions.nodes[headNode.prev];

        // arbitrarily choosing the first tokenId in the node as the one with highest votes
        if (highestNode.tokenIds.length > 0) {
            isValid = true;
            winner = highestNode.tokenIds[0];
        }
    }

    function allPositions(int votes, uint position) external view returns (uint) {
        return _allPositions.nodes[votes].tokenIds[position];
    }

    function allNodes(int votes) external view returns (uint[] memory tokenIds, int next, int prev) {
        return (
            _allPositions.nodes[votes].tokenIds,
            _allPositions.nodes[votes].next,
            _allPositions.nodes[votes].prev
        );
    }
}