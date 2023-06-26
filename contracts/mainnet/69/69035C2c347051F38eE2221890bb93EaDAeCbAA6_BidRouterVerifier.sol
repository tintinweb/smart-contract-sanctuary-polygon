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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
interface IERC20Permit {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IAuctionFactory.sol";
import "../interfaces/IAuctionCredit.sol";
import "../interfaces/IAuctionPool.sol";
import "../interfaces/IAuctionPoolSlim.sol";
import "../interfaces/IBidVerifier.sol";
import "../interfaces/IBidRouter.sol";

//import "hardhat/console.sol";

interface IDecimalsToken {
    function decimals() external view returns (uint8);
}

interface IRouterMigratable {
    function migrateRouter(address _newRouter) external;
}

contract BidRouterVerifier is Ownable, ReentrancyGuard, IBidRouter {
    using SafeERC20 for IERC20;

    /// @notice Router locked from adding new factories
    event RouterLocked();

    /// @notice added operator
    event NewOperator(address _op);

    /// @notice added operator
    event RemovedOperator(address _op);

    /// @notice Verifier set
    event NewVerifier(address _verifier);

    /// @notice event for none auction pools
    event NewNoneAuctionPool(address _pool, address _correspondingCredit);

    /// @notice event for removing pools of any kind
    event DisownedPool(address _pool);

    /// @notice new auction pool was added by a factory
    event NewAuctionPool(address _pool);

    /// @notice set receiver of per bid extra gas fee
    event SetGasReceiver(address _newGasReceiver);

    /// @notice set the gas fee paid per bid to cover administrative expenses
    event SetGasFee(uint256 _fee);

    /// @notice set receiver of expired credit token's pegged token
    event SetTeamAddress(address _newTeamAddress);

    /// @notice new factory of pool
    event AddFactory(address _newFactory,uint256 _factoryId, address _feeToken, address _creditToken);

    /// @notice a removed factory
    event RemoveFactory(address _factory, uint256 _factoryId);

    /// @notice emitted when bidding on behalf
    event BidDelegated(address _agent, address _user, address _pool, uint256 _bidsAmount);

    /// @notice pool sent funds
    event PoolPaid(address _pool, address _credit, address _to, uint256 _amount);

    /// @notice a user's credit threshold is reset on tokens expiry
    event ThresholdReset(address _user);

    /// @notice the death of one router is the birth on another
    event RouterReplaced(address _newRouter);

    /// @notice Pre-bid called contract
    IBidVerifier public bidVerifierContract;

    /// @notice The address receive expired credit's feeToken
    address public teamAddress;

    /// @notice This address receive gas
    address public gasReceiver;

    /// @notice Multiple factories are indexed
    uint256 public factoryIdCounter;

    /// @notice Used to route bids to the correct pool by finding the factory and requesting the pool's address (factory ID => factory address)
    mapping(uint256 => address) public factoryMap;
    /// @notice Address => is it a factory?
    mapping(address => bool) public isFactory;
    /// @notice A mapping of a factory's feeToken decimal delta to handle none-18-decimals tokens
    mapping(address => uint256) public factoryTokenDecimalsDelta;

    /// @notice Credits have privilege threshold alter function. Multiple factories means multiple credits
    mapping(address => bool) public isCredit;

    /// @notice Multiple credits having separate thresholds (credit address => user => Threshold) causing volume penalty on bid. 
    mapping(address => mapping(address => uint256)) public userPointsThreshold;

    /// @notice maps the unchangeable bidFee of a pool to spare a view call
    // pool => bidFee
    mapping(address => uint256) public poolFee;

    /// @notice Pool has privilege functions
    mapping(address => bool) public isPool;

    /// @notice Operators can create pools and conduct action on them
    mapping(address => bool) public isOperator;

    /// @notice Payed on bid, covered gas expense of platform
    uint256 public gasFee;

    /// @notice Is router locked from adding new factories
    bool public locked;

    constructor(address _teamAddress) {
        require(_teamAddress!=address(0),"Team can not be address(0)");
        isOperator[msg.sender] = true;
        teamAddress = _teamAddress;
        gasReceiver = _teamAddress;
        emit SetGasReceiver(_teamAddress);
        emit SetTeamAddress(_teamAddress);
    }

    /// @notice Pool has privilege functions
    modifier onlyPool() {
        //max(uint256) of expiry is how a pool is being marked
        require(isPool[msg.sender] == true, "Not pool");
        _;
    }

    /// @notice Operators
    modifier onlyOperator() {
        require(isOperator[msg.sender], "Not operator");
        _;
    }

    /**
     * @param _newAmount New gas covering fee per bid
     */
    function changeGasFee(uint256 _newAmount) external onlyOperator {
        gasFee = _newAmount;
        emit SetGasFee(_newAmount);
    }

    /// @notice Add a new factory on which bids can be conducted.
    /**
     * @param _factory The address of a new added factory
     */
    function addFactory(address _factory) external onlyOwner {
        require(factoryIdCounter < 20, "Router will not be migrateable, please migrate first to a router that supports seq migration");
        require(!locked, "Router is locked");
        require(_factory != address(0), "No zero address");
        factoryIdCounter += 1;
        factoryMap[factoryIdCounter] = _factory;
        isFactory[_factory] = true;
        address _credits = IAuctionFactory(_factory).creditToken();
        isCredit[_credits] = true;
        address _feeToken = IAuctionFactory(_factory).feeToken();

        IERC20 _feeTokenContract = IERC20(_feeToken);
        if (_feeTokenContract.allowance(address(this), _credits) == 0) {
            _feeTokenContract.safeIncreaseAllowance(_credits, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        }
        //19+ decimal tokens will revert, contract supports up to 18 decimals. If using future compilers, confirm that this still reverts.
        factoryTokenDecimalsDelta[_factory] = 10 ** (18 - IDecimalsToken(_feeToken).decimals());

        emit AddFactory(_factory,factoryIdCounter, _feeToken, _credits);
    }

    /// @notice Deprecate a factory from the router
    /**
     * @param _factoryId the incremented id given to a factory when it was added
     * @param _isSharedCredit in case credit is shared between factories and should not be removed
     */
    function removeFactory(uint256 _factoryId, bool _isSharedCredit) external onlyOwner {
        if (!_isSharedCredit) {
            isCredit[IAuctionFactory(factoryMap[_factoryId]).creditToken()] = false;
        }
        isFactory[factoryMap[_factoryId]] = false;
        emit RemoveFactory(factoryMap[_factoryId], _factoryId);
        factoryMap[_factoryId] = address(0);
    }

    /// @notice bid calls are through router
    /**
     * @param _token The address of the token being spent to bid
     * @param _factoryId The id of the factory in which the bid plays
     * @param _poolId The id of the pool within the factory in which the bid plays
     * @param _roundId The id of the round in which the bid plays
     * @param _ciphers The array of encrypted bid values
     * @param _hashes The hashed amount+nonce of the user, for value verification during finalization
     * @param _nftListId The nft list id which the user reserves
     */
    function bid(
        address _token,
        uint256 _factoryId,
        uint256 _poolId,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hashes,
        uint256 _nftListId
    ) external payable nonReentrant {
        require(msg.value == gasFee * _hashes.length, "Not enough gas fee");
        Address.sendValue(payable(gasReceiver),msg.value);

        IAuctionFactory _factory = IAuctionFactory(factoryMap[_factoryId]);
        conductBid(msg.sender, _token, _factory.pools(_poolId), _factory, _roundId, _ciphers, _hashes, _nftListId);
    }

    function bidOnBehalf(
        address _user,
        address _token,
        uint256 _factoryId,
        uint256 _poolId,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hashes,
        uint256 _nftListId
    ) external onlyOperator nonReentrant {
        IAuctionFactory _factory = IAuctionFactory(factoryMap[_factoryId]);
        address _pool = _factory.pools(_poolId);
        conductBid(_user, _token, _pool, _factory, _roundId, _ciphers, _hashes, _nftListId);
        emit BidDelegated(msg.sender,_user,_pool,_hashes.length);
    }

    /// @notice bid calls are through router
    /**
     * @param _tokens The address of the tokens being spent to bid
     * @param _bidsPerToken The amount of bids for each token (i.e _bidsPerToken[0] is amount of bids to spend with _tokens[0])
     * @param _factoryId The id of the factory in which the bid plays
     * @param _poolId The id of the pool within the factory in which the bid plays
     * @param _roundId The id of the round in which the bid plays
     * @param _ciphers The array of encrypted bid values
     * @param _hashes The hashed amount+nonce of the user, for value verification during finalization
     * @param _nftListId The nft list id which the user reserves
     */
    function bidMultipleTokens(
        address[] calldata _tokens,
        uint256[] calldata _bidsPerToken,
        uint256 _factoryId,
        uint256 _poolId,
        uint256 _roundId,
        string[][] calldata _ciphers,
        bytes32[][] calldata _hashes,
        uint256 _nftListId
    ) external payable nonReentrant {
        require(_tokens.length==_bidsPerToken.length,"Array length mismatch");
        require(_tokens.length==_ciphers.length,"Array length mismatch");
        require(_tokens.length==_hashes.length,"Array length mismatch");

        uint256 totalBidsOrIteratorForLater;

        unchecked{
            for (uint256 i; i < _tokens.length; ++i) {
                totalBidsOrIteratorForLater += _bidsPerToken[i];
                require(_ciphers[i].length == _bidsPerToken[i], "Requested bid count mismatch");
            }
        }
        require(msg.value == gasFee * totalBidsOrIteratorForLater, "Not enough gas fee");
        Address.sendValue(payable(gasReceiver),msg.value);

        IAuctionFactory _factory = IAuctionFactory(factoryMap[_factoryId]);

        //Using totalBids as iterator now to reduce stack depth
        unchecked{
            for (totalBidsOrIteratorForLater = 0; totalBidsOrIteratorForLater < _tokens.length; ++totalBidsOrIteratorForLater) {
                conductBid(
                    msg.sender,
                    _tokens[totalBidsOrIteratorForLater],
                    _factory.pools(_poolId),
                    _factory,
                    _roundId,
                    _ciphers[totalBidsOrIteratorForLater],
                    _hashes[totalBidsOrIteratorForLater],
                    _nftListId
                );
            }
        }
    }

    function conductBid(
        address _user,
        address _token,
        address _poolAddress,
        IAuctionFactory _factory,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hashes,
        uint256 _nftListId
    ) internal {
        require(_hashes.length > 0, "Can't place 0 bids");

        Tokens memory _tokens = _factory.getTokens();

        if (!isPool[_poolAddress]) {
            isPool[_poolAddress] = true;
            IAuctionCredit(_tokens.credit).routerProtectPoolExpiry(_poolAddress);
            poolFee[_poolAddress] = IAuctionPool(_poolAddress).bidFee();
            emit NewAuctionPool(_poolAddress);
        }

        require(_token == _tokens.feeToken || _token == _tokens.credit || _token == _tokens.bonus, "!token");
        require(_ciphers.length == _hashes.length, "!length");

        uint256 _amount = poolFee[_poolAddress] * _hashes.length;

        uint256 _deservingVolume;

        bool _isBonus;

        if (_token != _tokens.bonus) {
            //Note: getting bonus twice on bonus case due stack too deep
            if (_token == _tokens.feeToken) {
                // Transfer feeToken to the contract
                IERC20(_tokens.feeToken).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _amount / factoryTokenDecimalsDelta[address(_factory)]
                );

                // Convert feeToken to Credit
                IAuctionCredit(_tokens.credit).deposit(_amount);
                // Transfer credits to pool
                IERC20(_tokens.credit).safeTransferFrom(address(this), _poolAddress, _amount);
                _deservingVolume = _amount;
            } else {
                //else if (_token == _tokens.credit) //note being credit is the only possible option to reach here (otherwise revert)
                //Note using a function due stack too deep.
                _deservingVolume = _handleDeservingVolume(_user, _tokens.credit, _amount);
                // Transfer Credit to the contract
                IERC20(_tokens.credit).safeTransferFrom(msg.sender, _poolAddress, _amount);
            }
        } else {
            // Transfer Bonus to the contract
            IERC20(_tokens.bonus).safeTransferFrom(msg.sender, _poolAddress, _amount);
            _isBonus = true;
        }
        //We'll add volume before bid call so that when bid calls bonus minter it could read the new user volume
        _factory.addUserVolume(_user, _deservingVolume / factoryTokenDecimalsDelta[address(_factory)]);

        IAuctionPool(_poolAddress).bid(_user, _roundId, _ciphers, _hashes, _nftListId, _isBonus);

        require(
            IAuctionPool(_poolAddress).coolOffPeriodStartTime() + IAuctionPool(_poolAddress).coolOffPeriodTime() < block.timestamp,
            "Can't bid during coolOff"
        );
        require(IAuctionPool(_poolAddress).getRoundStatus(_roundId) == 1, "Round not active"); //Should be inited by IAuctionPool(_poolAddress).bid to be allays correct
        //The edge case for which this is required ^ is due get round status no acknowledging coolOff while initround does.

        //We check this *at the end* because "bidListId" Must be inited in the pool before verifier checks for the value!
        bidVerifierContract.verifyBid(_poolAddress, msg.sender, _roundId, _hashes.length);
    }

    /// @notice bid calls are through router
    /**
     * @param _token The address of the token being spent to bid
     * @param _factoryId The id of the factory in which the bid plays
     * @param _poolId The id of the pool within the factory in which the bid plays
     * @param _roundId The id of the round in which the bid plays
     * @param _ciphers The array of encrypted bid values
     * @param _hashes The hashed amount+nonce of the user, for value verification during finalization
     */
    function bidSlim(
        address _token,
        uint256 _factoryId,
        uint256 _poolId,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hashes
    ) external payable nonReentrant {
        require(msg.value == gasFee * _hashes.length, "Not enough gas fee");
        Address.sendValue(payable(gasReceiver),msg.value);

        IAuctionFactory _factory = IAuctionFactory(factoryMap[_factoryId]);
        conductBidSlim(msg.sender, _token, IAuctionPoolSlim(_factory.pools(_poolId)), _factory, _roundId, _ciphers, _hashes);
    }

    function bidOnBehalfSlim(
        address _user,
        address _token,
        uint256 _factoryId,
        uint256 _poolId,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hashes
    ) external onlyOperator nonReentrant {
        IAuctionFactory _factory = IAuctionFactory(factoryMap[_factoryId]);
        address _pool = _factory.pools(_poolId);
        conductBidSlim(_user, _token, IAuctionPoolSlim(_pool), _factory, _roundId, _ciphers, _hashes);
        emit BidDelegated(msg.sender,_user,_pool,_hashes.length);
    }

    /// @notice bid calls are through router
    /**
     * @param _tokens The address of the tokens being spent to bid
     * @param _bidsPerToken The amount of bids for each token (i.e _bidsPerToken[0] is amount of bids to spend with _tokens[0])
     * @param _factoryId The id of the factory in which the bid plays
     * @param _poolId The id of the pool within the factory in which the bid plays
     * @param _roundId The id of the round in which the bid plays
     * @param _ciphers The array of encrypted bid values
     * @param _hashes The hashed amount+nonce of the user, for value verification during finalization
     */
    function bidMultipleTokensSlim(
        address[] calldata _tokens,
        uint256[] calldata _bidsPerToken,
        uint256 _factoryId,
        uint256 _poolId,
        uint256 _roundId,
        string[][] calldata _ciphers,
        bytes32[][] calldata _hashes
    ) external payable nonReentrant {
        require(_tokens.length==_bidsPerToken.length,"Array length mismatch");
        require(_tokens.length==_ciphers.length,"Array length mismatch");
        require(_tokens.length==_hashes.length,"Array length mismatch");

        uint256 totalBidsOrIteratorForLater;

        unchecked{
            for (uint256 i; i < _tokens.length; ++i) {
                totalBidsOrIteratorForLater += _bidsPerToken[i];
                require(_ciphers[i].length == _bidsPerToken[i], "Requested bid count mismatch");
            }
        }
        require(msg.value == gasFee * totalBidsOrIteratorForLater, "Not enough gas fee");
        Address.sendValue(payable(gasReceiver),msg.value);

        IAuctionFactory _factory = IAuctionFactory(factoryMap[_factoryId]);

        //Using totalBids as iterator now to reduce stack depth
        unchecked{
            for (totalBidsOrIteratorForLater = 0; totalBidsOrIteratorForLater < _tokens.length; ++totalBidsOrIteratorForLater) {
                conductBidSlim(
                    msg.sender,
                    _tokens[totalBidsOrIteratorForLater],
                    IAuctionPoolSlim(_factory.pools(_poolId)),
                    _factory,
                    _roundId,
                    _ciphers[totalBidsOrIteratorForLater],
                    _hashes[totalBidsOrIteratorForLater]
                );
            }
        }
    }

    function conductBidSlim(
        address _user,
        address _token,
        IAuctionPoolSlim _poolAddress,
        IAuctionFactory _factory,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hashes
    ) internal {
        require(_hashes.length > 0, "Can't place 0 bids");

        Tokens memory _tokens = _factory.getTokens();

        if (!isPool[address(_poolAddress)]) {
            isPool[address(_poolAddress)] = true;
            IAuctionCredit(_tokens.credit).routerProtectPoolExpiry(address(_poolAddress));
            poolFee[address(_poolAddress)] = _poolAddress.bidFee();
            emit NewAuctionPool(address(_poolAddress));
        }

        require(_ciphers.length == _hashes.length, "!length");

        uint256 _amount = _poolAddress.bidFee() * _ciphers.length;

        if (_token != _tokens.bonus) {
            //Note: getting bonus twice on bonus case due stack too deep
            if (_token == _tokens.feeToken) {
                // Transfer feeToken to the contract
                IERC20(_tokens.feeToken).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _amount / factoryTokenDecimalsDelta[address(_factory)]
                );
                // Convert feeToken to Credit
                IAuctionCredit(_tokens.credit).deposit(_amount);
                // Transfer credits to pool
                IERC20(_tokens.credit).safeTransferFrom(address(this), address(_poolAddress), _amount);
            } else {
                // Transfer Credit to the contract
                IERC20(_tokens.credit).safeTransferFrom(msg.sender, address(_poolAddress), _amount);
                require(_token == _tokens.credit, "Unknown token");
            }
            _poolAddress.bid(_user, _roundId, _ciphers, _hashes, false);
        } else {
            // Transfer Bonus to the contract
            IERC20(_tokens.bonus).safeTransferFrom(msg.sender, address(_poolAddress), _amount);
            _poolAddress.bid(_user, _roundId, _ciphers, _hashes, true);
        }

        require(
            _poolAddress.coolOffPeriodStartTime() + _poolAddress.coolOffPeriodTime() < block.timestamp,
            "Can't bid during coolOff"
        );
        require(_poolAddress.getRoundStatus(_roundId) == 1, "Round not active"); //Should be inited by IAuctionPool(_poolAddress).bid to be allays correct
        //The edge case for which this is required ^ is due get round status no acknowledging coolOff while initround does.
    }

    ////// @notice the bid slim with verifier function are *exactly the same* as the other bid slim function only that the conduct bid of them also calls the verifier
    /// @notice bid calls are through router
    /**
     * @param _token The address of the token being spent to bid
     * @param _factoryId The id of the factory in which the bid plays
     * @param _poolId The id of the pool within the factory in which the bid plays
     * @param _roundId The id of the round in which the bid plays
     * @param _ciphers The array of encrypted bid values
     * @param _hashes The hashed amount+nonce of the user, for value verification during finalization
     */
    function bidSlimWithVerifier(
        address _token,
        uint256 _factoryId,
        uint256 _poolId,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hashes
    ) external payable nonReentrant {
        require(msg.value == gasFee * _hashes.length, "Not enough gas fee");
        Address.sendValue(payable(gasReceiver),msg.value);

        IAuctionFactory _factory = IAuctionFactory(factoryMap[_factoryId]);
        address _pool = _factory.pools(_poolId);
        conductBidSlim(
            msg.sender,
            _token,
            IAuctionPoolSlim(_factory.pools(_poolId)),
            _factory,
            _roundId,
            _ciphers,
            _hashes
        );

        
        //We check this *at the end* because "bidListId" Must be inited in the pool before verifier checks for the value!
        bidVerifierContract.verifyBid(_pool, msg.sender, _roundId, _hashes.length);
        
    }

    function bidOnBehalfSlimWithVerifier(
        address _user,
        address _token,
        uint256 _factoryId,
        uint256 _poolId,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hashes
    ) external onlyOperator nonReentrant {
        IAuctionFactory _factory = IAuctionFactory(factoryMap[_factoryId]);
        address _pool = _factory.pools(_poolId);
        conductBidSlim(_user, _token, IAuctionPoolSlim(_pool), _factory, _roundId, _ciphers, _hashes);
        //We check this *at the end* because "bidListId" Must be inited in the pool before verifier checks for the value!
        bidVerifierContract.verifyBid(_pool, msg.sender, _roundId, _hashes.length);
        emit BidDelegated(msg.sender,_user,_pool,_hashes.length);
    }

    /// @notice bid calls are through router
    /**
     * @param _tokens The address of the tokens being spent to bid
     * @param _bidsPerToken The amount of bids for each token (i.e _bidsPerToken[0] is amount of bids to spend with _tokens[0])
     * @param _factoryId The id of the factory in which the bid plays
     * @param _poolId The id of the pool within the factory in which the bid plays
     * @param _roundId The id of the round in which the bid plays
     * @param _ciphers The array of encrypted bid values
     * @param _hashes The hashed amount+nonce of the user, for value verification during finalization
     */
    function bidMultipleTokensSlimWithVerifier(
        address[] calldata _tokens,
        uint256[] calldata _bidsPerToken,
        uint256 _factoryId,
        uint256 _poolId,
        uint256 _roundId,
        string[][] calldata _ciphers,
        bytes32[][] calldata _hashes
    ) external payable nonReentrant {
        require(_tokens.length==_bidsPerToken.length,"Array length mismatch");
        require(_tokens.length==_ciphers.length,"Array length mismatch");
        require(_tokens.length==_hashes.length,"Array length mismatch");


        uint256 totalBidsOrIteratorForLater;
        unchecked{
            for (uint256 i; i < _tokens.length; ++i) {
                totalBidsOrIteratorForLater += _bidsPerToken[i];
                require(_ciphers[i].length == _bidsPerToken[i], "Requested bid count mismatch");
            }
        }
        require(msg.value == gasFee * totalBidsOrIteratorForLater, "Not enough gas fee");
        Address.sendValue(payable(gasReceiver),msg.value);

        IAuctionFactory _factory = IAuctionFactory(factoryMap[_factoryId]);
        address _pool = _factory.pools(_poolId);

        //Using totalBids as iterator now to reduce stack depth
        unchecked{
            for (totalBidsOrIteratorForLater = 0; totalBidsOrIteratorForLater < _tokens.length; ++totalBidsOrIteratorForLater) {
                conductBidSlim(
                    msg.sender,
                    _tokens[totalBidsOrIteratorForLater],
                    IAuctionPoolSlim(_pool),
                    _factory,
                    _roundId,
                    _ciphers[totalBidsOrIteratorForLater],
                    _hashes[totalBidsOrIteratorForLater]
                );
            }
        }

        //We check this *at the end* because "bidListId" Must be inited in the pool before verifier checks for the value!
        bidVerifierContract.verifyBid(_pool, msg.sender, _roundId, _hashes.length);
    }


    /// @notice declares pool on auction creation
    function factoryDeclarePool(address _pool) external {
        require(isFactory[msg.sender], "!factory");
        Tokens memory _tokens = IAuctionFactory(msg.sender).getTokens();
        isPool[_pool] = true;
        poolFee[_pool] = IAuctionPool(_pool).bidFee();
        IAuctionCredit(_tokens.credit).routerProtectPoolExpiry(_pool);

        emit NewAuctionPool(_pool);
    }

    /**
     * @param _teamAddress The new address receiving expired credit's feeToken (referred to as pegToken on AuctionCredit)
     */
    function setTeamAddress(address _teamAddress) external onlyOwner {
        require(_teamAddress!=address(0),"Team can not be address(0)");
        teamAddress = _teamAddress;
        emit SetTeamAddress(_teamAddress);
    }

    /**
     * @param _gasReceiver The new address receiving gas covering fee (gasFee)
     */
    function setGasReceiver(address _gasReceiver) external onlyOwner {
        require(_gasReceiver!=address(0),"Receiver can not be address(0)");
        gasReceiver = _gasReceiver;
        emit SetGasReceiver(_gasReceiver);
    }

    /// @notice Pool returns credits to a user revoking a bid (Or none-auction pool sends credits for any reason)
    /**
     * @param _user The address of the receiving the credits
     * @param _amount The amount of credits transfer from pool to user
     */
    function poolTransferTo(address _user, uint256 _amount) external onlyPool {
        address _credit = IAuctionFactory(IAuctionPool(msg.sender).factory()).creditToken();
        IERC20(_credit).safeTransferFrom(msg.sender, _user, _amount);
        userPointsThreshold[_credit][_user] += _amount;
        emit PoolPaid(msg.sender, _credit, _user, _amount);
    }

    /// @notice When tokens expire they reset the Threshold of a the user
    /**
     * @param _user The address of the user whose credits expired
     */
    function onExpireThresholdReset(address _user) external {
        require(isCredit[msg.sender], "Credit only function");
        userPointsThreshold[msg.sender][_user] = 0;
        emit ThresholdReset(_user);
    }

    /// @notice Returns the deserving volume and reduces penalty from threshold.
    /// @notice The value for this function is truthful and relevant only for credit tokens that are exclusive to fat-pools-only factories.
    /**
     * @param _user The address of user whose bidding volume is checked
     * @param _credit The address of the credit
     * @param _amount The amount of credits used
     */
    function _handleDeservingVolume(address _user, address _credit, uint256 _amount) internal returns (uint256 _deservingVolume) {
        uint256 _bal = IERC20(_credit).balanceOf(_user);
        //require(_bal >= _amount, "ERC20: transfer amount exceeds balance"); //NOTE: If bal is not enough this function will underflow and revert(even without this require)(credits will not reach this revert on their end when user tries to bid with credits he does not have)
        uint256 _threshold = userPointsThreshold[_credit][_user];
        if (_bal < _threshold) {
            userPointsThreshold[_credit][_user] = _bal - _amount; //handle an edge case regarding refund enabled fat pools that share credit token with slim pool
            return 0;
        }
        uint256 _delta = _bal - _threshold;
        //_delta is the amount of tokens that "deserve volume"
        //If delta isn't greater or equal to amount then we in fact consume penalized tokens thus we penalize
        if (_delta < _amount) {
            //We penalize, because the amount of tokens used is greater then the amount of "volume deserving tokens"
            _deservingVolume = _delta;
            userPointsThreshold[_credit][_user] -= _amount - _delta;
        } else {
            _deservingVolume = _amount;
        }
    }

    /**
     * @notice Add operator
     *
     * @param _operator The address of the operator to add
     */
    function addOperator(address _operator) external onlyOwner {
        isOperator[_operator] = true;
        emit NewOperator(_operator);
    }

    /**
     * @notice Remove operator
     *
     * @param _operator The address of the operator to remove
     */
    function removeOperator(address _operator) external onlyOwner {
        isOperator[_operator] = false;
        emit RemovedOperator(_operator);
    }

    function setBidVerifierContract(address _newContract) external onlyOperator {
        bidVerifierContract = IBidVerifier(_newContract);

        emit NewVerifier(_newContract);
    }

    /// @notice lock the router forever, preventing new bids
    function lockRouter(string memory _confirm) external onlyOwner {
        require(keccak256(abi.encodePacked(_confirm)) == keccak256(abi.encodePacked("Lock the router forever")), "Not confirmed");
        require(!locked, "Already locked");

        locked = true;

        emit RouterLocked();
    }

    /// @notice pools have control over the credit token via the router! (can transfer from and withdraw(dismember into fee token))
    function addNoneAuctionPool(address _pool, address _credit) external onlyOwner {
        require(!locked, "Router is locked");
        require(isCredit[_credit], "None existing credit token");
        IAuctionCredit(_credit).routerProtectPoolExpiry(_pool);
        isPool[_pool] = true;

        emit NewNoneAuctionPool(_pool, _credit);
    }

    /// @notice pools have control over the credit token via the router! (can transfer from and withdraw(dismember into fee token))
    function disownPool(address _pool) external onlyOwner {
        isPool[_pool] = false;
        emit DisownedPool(_pool);
    }

    /// @notice migration function
    function migrateSelf(address _newRouter, IRouterMigratable[] memory _utilityContracts) external onlyOwner {
        uint256 i;
        unchecked{
            for (i; i < _utilityContracts.length; ++i) {
                _utilityContracts[i].migrateRouter(_newRouter);
            }
        }

        Tokens memory _tokens;
        address curFac;
        unchecked{
            for (i = 1; i <= factoryIdCounter; ++i) {
                curFac = factoryMap[i];
                if (isFactory[curFac]) {
                    IRouterMigratable(curFac).migrateRouter(_newRouter);
                    _tokens = IAuctionFactory(curFac).getTokens();

                    if (isCredit[_tokens.credit]) {
                        IRouterMigratable(_tokens.credit).migrateRouter(_newRouter);
                        isCredit[_tokens.credit] = false;
                    }
                }
            }
        }

        IRouterMigratable(address(bidVerifierContract)).migrateRouter(_newRouter);

        emit RouterReplaced(_newRouter);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IAuctionCredit {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function routerProtectPoolExpiry(address _pool) external;

    function promoterMint(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

struct Tokens {
    address feeToken;
    address credit;
    address bonus;
}

interface IAuctionFactory {
    function feeToken() external view returns (address);

    function creditToken() external view returns (address);

    function bonusToken() external view returns (address);

    function stakingTreasury() external view returns (address);

    function bidRouter() external view returns (address);

    function pools(uint256 id) external view returns (address);

    function isOperator(address _operator) external view returns (bool);

    function addUserVolume(address _user, uint256 _amount) external;

    function getTokens() external view returns (Tokens memory);

    function isPool(address _pool) external view returns (bool);

    function poolLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./IAuctionFactory.sol";

enum BidInfoStatus {
    Untouch,
    Valid,
    Invalid,
    Revoked
}

struct BidInfo {
    address bidder;
    uint256 nftListId;
    uint256 amount;
    uint256 bidAt;
    string cipher;
    bytes32 bidHash;
    BidInfoStatus status;
    bool isBonus;
}

struct NFTInfo {
    address nftAddress;
    uint256 nftId;
    NFTInfoStatus status;
    uint256 lastActiveBidList;
    uint256 listPrice;
    address owner;
}
enum NFTInfoStatus {
    Active,
    Delisted,
    Withdrawn
}

interface IAuctionPool {
    function bid(
        address _bidder,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hash,
        uint256 _nftListId,
        bool _isBonus
    ) external;

    function bidFee() external view returns (uint256);

    function factory() external view returns (IAuctionFactory);

    function alive() external view returns (bool);

    function getRoundStatus(uint256 _roundId) external view returns (uint8 _status);

    function totalUserBidsTimeAlive(uint256 _bidListId, address _user) external view returns (uint256);

    function totalBidPerformanceRewards(uint256 _bidListId) external view returns (uint256);

    function totalBidsTimeAlive(uint256 _bidListId) external view returns (uint256);

    function sellerTotalGameReserves(uint256 _bidListId, address _user) external view returns (uint256);

    function totalReserveIncome(uint256 _bidListId) external view returns (uint256);

    function settlementTime(uint256 _roundId) external view returns (uint256);

    function roundIdToBidListId(uint256 _roundId) external view returns (uint256);

    function highestValidBid(uint256 _roundId) external view returns (uint256);

    //function bidsList(uint256 _bidListId, uint256 _bidId) external view returns (BidInfo memory);

    function reserveCount(uint256 _bidListId) external view returns (uint256);

    function roundStartTime(uint256 roundId) external view returns (uint256);

    function minBids() external view returns (uint256);

    function roundDuration() external view returns (uint256);

    function roundCount() external view returns (uint256);

    function valuedBidsLength(uint256 _bidListId) external view returns (uint256);

    function coolOffPeriodStartTime() external view returns (uint256);

    function coolOffPeriodTime() external view returns (uint256);

    function totalBidListCount() external view returns (uint256);

    function whichRoundInitedMyBids(uint256 bidListId) external view returns (uint256);

    function nftInfo(uint256 nftListId) external view returns (NFTInfo memory);

    function whichRoundFinalizedMyBids(uint256 bidList) external view returns (uint256);

    function nftExists(uint256 nftListId) external view returns (bool);

    function pid() external view returns (uint256);

    function maxOffer() external view returns (uint256);

    function slotDecimals() external view returns (uint256);

    function bidListLength(uint256 bidListId) external view returns (uint256);

    function minValue() external view returns (uint256);

    function faceValue() external view returns (uint256);

    function bidTimeAlive(uint256 bidListId, uint256 bidId) external view returns (uint256);

    function bidListSlotsDataReindexer(uint256 bidListId) external view returns (uint256);

    function SlotsData(uint256 reindexerId, uint256 slotIndex) external view returns (uint256);

    function slotBurnTime(uint256 bidListId, uint256 slot) external view returns (uint256);

    function periodOfExtension() external view returns (uint256);

    function bidsForExtension() external view returns (uint256);

    function roundExtensionChunk() external view returns (uint256);

    function extenderBids(uint256 roundId) external view returns (uint256);

    function roundExtension(uint256 roundId) external view returns (uint256);

    function extensionsHad(uint256 roundId) external view returns (uint256);

    function extensionStep() external view returns (uint256);

    //function roundExtensionChunk() external view returns (uint256);
}

abstract contract poolMock is IAuctionPool {
    mapping(uint256 => mapping(uint256 => BidInfo)) public bidsList;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./IAuctionFactory.sol";

enum stat {
    Untouch,
    Valid,
    Invalid,
    Revoked
}

struct BidInfoSlim {
    address bidder;
    bytes32 bidHash;
    stat status;
}

interface IAuctionPoolSlim {
    function bid(address _bidder, uint256 _roundId, string[] calldata _ciphers, bytes32[] calldata _hash, bool _isBonus) external;

    function bidFee() external view returns (uint256);

    function factory() external view returns (IAuctionFactory);

    function alive() external view returns (bool);

    function getRoundStatus(uint256 _roundId) external view returns (uint8 _status);

    function settlementTime(uint256 _roundId) external view returns (uint256);

    function roundIdToBidListId(uint256 _roundId) external view returns (uint256);

    function highestValidBid(uint256 _roundId) external view returns (uint256);

    function roundStartTime(uint256 roundId) external view returns (uint256);

    function roundDuration() external view returns (uint256);

    function roundCount() external view returns (uint256);

    function valuedBidsLength(uint256 _bidListId) external view returns (uint256);

    function coolOffPeriodStartTime() external view returns (uint256);

    function coolOffPeriodTime() external view returns (uint256);

    function totalBidListCount() external view returns (uint256);

    function whichRoundInitedMyBids(uint256 bidListId) external view returns (uint256);

    function whichRoundFinalizedMyBids(uint256 bidList) external view returns (uint256);

    function pid() external view returns (uint256);

    function maxOffer() external view returns (uint256);

    function slotDecimals() external view returns (uint256);

    function bidListLength(uint256 bidListId) external view returns (uint256);

    function faceValue() external view returns (uint256);

    function bidListSlotsDataReindexer(uint256 bidListId) external view returns (uint256);

    function SlotsData(uint256 reindexerId, uint256 slotIndex) external view returns (uint256);

    function periodOfExtension() external view returns (uint256);

    function bidsForExtension() external view returns (uint256);

    function roundExtensionChunk() external view returns (uint256);

    function extenderBids(uint256 roundId) external view returns (uint256);

    function roundExtension(uint256 roundId) external view returns (uint256);

    function extensionsHad(uint256 roundId) external view returns (uint256);

    function extensionStep() external view returns (uint256);

    function minBids()  external view returns (uint256);
}

abstract contract ISlimPool is IAuctionPoolSlim {
    mapping(uint256 => mapping(uint256 => BidInfoSlim)) public bidsList;
    mapping(uint256 => mapping(uint256 => uint256)) public bidAmounts;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IBidRouter {

    function isPool(address _pool) external view returns (bool);

    function teamAddress() external view returns (address);

    function gasReceiver() external view returns (address);

    /// @notice pool function used when refunding a bid for credits
    function poolTransferTo(address _user, uint256 _amount) external;

    function onExpireThresholdReset(address _user) external;

    function gasFee() external view returns (uint256);

    function bid(
        address _token,
        uint256 _factoryId,
        uint256 _poolId,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hashes,
        uint256 _nftListId
    ) external payable;

    function bidOnBehalf(
        address _user,
        address _token,
        uint256 _factoryId,
        uint256 _poolId,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hashes,
        uint256 _nftListId
    ) external;

    function factoryDeclarePool(address _pool) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IBidVerifier {
    function verifyBid(
        address _pool,
        address _user,
        uint256 _roundId,
        uint256 _newBids
    ) external;
}