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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
pragma solidity =0.8.19;

import "oz/access/Ownable2Step.sol";

import "src/protocol/interfaces/IKlimaInfinity.sol";
import {IKlima, SafeERC20} from "src/protocol/interfaces/IKLIMA.sol";
import "src/protocol/interfaces/IUniswapV2Pair.sol";

/**
 * @title CarbonRetirementBondDepository
 * @author Cujo
 * @notice A smart contract that handles the distribution of carbon in exchange for KLIMA tokens.
 * Bond depositors can only use this to retire carbon by providing KLIMA tokens.
 */

contract CarbonRetirementBondDepository is Ownable2Step {
    using SafeERC20 for IKlima;

    /// @notice Address of the KLIMA token contract.
    address public constant KLIMA = 0x4e78011Ce80ee02d2c3e649Fb657E45898257815;
    /// @notice Address of the DAO multi-sig.
    address public constant DAO = 0x65A5076C0BA74e5f3e069995dc3DAB9D197d995c;
    /// @notice Address of the Treasury contract.
    address public constant TREASURY = 0x7Dd4f0B986F032A44F913BF92c9e8b7c17D77aD7;
    /// @notice address of the Klima Infinity contract.
    address public constant INFINITY = 0x8cE54d9625371fb2a068986d32C85De8E6e995f8;
    /// @notice Divisor used for calculating percentages.
    uint256 public constant FEE_DIVISOR = 10_000;
    /// @notice Allocator contract used by policy to fund and close markets.
    address public allocatorContract;

    /// @notice Mapping that stores the KLIMA/X LP used for quoting price references.
    mapping(address => address) public poolReference;

    /// @notice Mapping that stores whether the KLIMA is token 0 or token 1 in the LP contract.
    mapping(address => uint8) public referenceKlimaPosition;

    /// @notice Mapping that stores the DAO fee charged for a specific pool token.
    mapping(address => uint256) public daoFee;

    /// @notice Mapping that stores the maximum slippage tolerated for a specific pool token.
    mapping(address => uint256) public maxSlippage;

    event AllocatorChanged(address oldAllocator, address newAllocator);
    event PoolReferenceChanged(address pool, address oldLp, address newLp);
    event ReferenceKlimaPositionChanged(address lp, uint8 oldPosition, uint8 newPosition);
    event DaoFeeChanged(address pool, uint256 oldFee, uint256 newFee);
    event PoolSlippageChanged(address pool, uint256 oldSlippage, uint256 newSlippage);

    event MarketOpened(address pool, uint256 amount);
    event MarketClosed(address pool, uint256 amount);

    event CarbonBonded(address pool, uint256 poolAmount);
    event KlimaBonded(uint256 daoFee, uint256 klimaBurned);

    /**
     * @notice Modifier to ensure that the calling function is being called by the allocator contract.
     */
    modifier onlyAllocator() {
        require(msg.sender == allocatorContract, "Only allocator can open or close bond market");
        _;
    }

    /**
     * @notice Swaps the specified amount of pool tokens for KLIMA tokens.
     * @dev Only callable by the Infinity contract.
     * @param poolToken     The pool token address.
     * @param poolAmount    The amount of pool tokens to swap.
     */
    function swapToExact(address poolToken, uint256 poolAmount) external {
        require(msg.sender == INFINITY, "Caller is not Infinity");
        require(poolAmount > 0, "Cannot swap for zero tokens");

        uint256 klimaNeeded = getKlimaAmount(poolAmount, poolToken);

        _transferAndBurnKlima(klimaNeeded, poolToken);
        IKlima(poolToken).safeTransfer(INFINITY, poolAmount);

        emit CarbonBonded(poolToken, poolAmount);
    }

    /**
     * @notice Retires the specified amount of carbon for the given pool token using KI.
     * @dev Requires KLIMA spend approval for the amount returned by getKlimaAmount()
     * @param poolToken             The pool token address.
     * @param retireAmount          The amount of carbon to retire.
     * @param retiringEntityString  The string representing the retiring entity.
     * @param beneficiaryAddress    The address of the beneficiary.
     * @param beneficiaryString     The string representing the beneficiary.
     * @param retirementMessage     The message for the retirement.
     * @return retirementIndex      The index of the retirement transaction.
     */
    function retireCarbonDefault(
        address poolToken,
        uint256 retireAmount,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage
    ) external returns (uint256 retirementIndex) {
        require(retireAmount > 0, "Cannot retire zero tokens");

        // Get the current amount of total pool tokens needed including any applicable fees
        uint256 poolNeeded = IKlimaInfinity(INFINITY).getSourceAmountDefaultRetirement(
            poolToken,
            poolToken,
            retireAmount
        );

        require(poolNeeded <= IKlima(poolToken).balanceOf(address(this)), "Not enough pool tokens to retire");

        // Get the total rate limited KLIMA needed
        uint256 klimaNeeded = getKlimaAmount(poolNeeded, poolToken);

        // Transfer and burn the KLIMA
        _transferAndBurnKlima(klimaNeeded, poolToken);

        IKlima(poolToken).safeIncreaseAllowance(INFINITY, poolNeeded);

        emit CarbonBonded(poolToken, poolNeeded);

        return
            IKlimaInfinity(INFINITY).retireExactCarbonDefault(
                poolToken,
                poolToken,
                poolNeeded,
                retireAmount,
                retiringEntityString,
                beneficiaryAddress,
                beneficiaryString,
                retirementMessage,
                0
            );
    }

    /**
     * @notice Retires the specified amount of carbon for the given pool token using KI.
     * Uses the provided project token for the underlying credit to retire.
     * @dev Requires KLIMA spend approval for the amount returned by getKlimaAmount()
     * @param poolToken             The pool token address.
     * @param projectToken          The project token to retire.
     * @param retireAmount          The amount of carbon to retire.
     * @param retiringEntityString  The string representing the retiring entity.
     * @param beneficiaryAddress    The address of the beneficiary.
     * @param beneficiaryString     The string representing the beneficiary.
     * @param retirementMessage     The message for the retirement.
     * @return retirementIndex      The index of the retirement transaction.
     */
    function retireCarbonSpecific(
        address poolToken,
        address projectToken,
        uint256 retireAmount,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage
    ) external returns (uint256 retirementIndex) {
        require(retireAmount > 0, "Cannot retire zero tokens");

        // Get the current amount of total pool tokens needed including any applicable fees
        uint256 poolNeeded = IKlimaInfinity(INFINITY).getSourceAmountSpecificRetirement(
            poolToken,
            poolToken,
            retireAmount
        );

        require(poolNeeded <= IKlima(poolToken).balanceOf(address(this)), "Not enough pool tokens to retire");

        // Get the total rate limited KLIMA needed
        uint256 klimaNeeded = getKlimaAmount(poolNeeded, poolToken);

        // Transfer and burn the KLIMA
        _transferAndBurnKlima(klimaNeeded, poolToken);

        IKlima(poolToken).safeIncreaseAllowance(INFINITY, poolNeeded);

        emit CarbonBonded(poolToken, poolNeeded);

        return
            IKlimaInfinity(INFINITY).retireExactCarbonSpecific(
                poolToken,
                poolToken,
                projectToken,
                poolNeeded,
                retireAmount,
                retiringEntityString,
                beneficiaryAddress,
                beneficiaryString,
                retirementMessage,
                0
            );
    }

    /**
     * @notice Emits event on market allocation.
     * @dev Only the allocator contract can call this function.
     * @param poolToken The address of the pool token to open the market for.
     */
    function openMarket(address poolToken) external onlyAllocator {
        emit MarketOpened(poolToken, IKlima(poolToken).balanceOf(address(this)));
    }

    /**
     * @notice Closes the market for a specified pool token by transferring all remaining pool tokens to the treasury address.
     * @dev Only the allocator contract can call this function.
     * @param poolToken The address of the pool token to close the market for.
     */
    function closeMarket(address poolToken) external onlyAllocator {
        uint256 currentBalance = IKlima(poolToken).balanceOf(address(this));
        IKlima(poolToken).safeTransfer(TREASURY, currentBalance);

        emit MarketClosed(poolToken, currentBalance);
    }

    /**
     * @notice Updates the maximum slippage percentage for a specified pool token.
     * @param poolToken The address of the pool token to update the maximum slippage percentage for.
     * @param _maxSlippage The new maximum slippage percentage.
     */
    function updateMaxSlippage(address poolToken, uint256 _maxSlippage) external onlyOwner {
        uint256 oldSlippage = maxSlippage[poolToken];
        maxSlippage[poolToken] = _maxSlippage;

        emit PoolSlippageChanged(poolToken, oldSlippage, maxSlippage[poolToken]);
    }

    /**
     * @notice Updates the DAO fee for a specified pool token.
     * @param poolToken The address of the pool token to update the DAO fee for.
     * @param _daoFee The new DAO fee.
     */
    function updateDaoFee(address poolToken, uint256 _daoFee) external onlyOwner {
        uint256 oldFee = daoFee[poolToken];
        daoFee[poolToken] = _daoFee;

        emit DaoFeeChanged(poolToken, oldFee, daoFee[poolToken]);
    }

    /**
     * @notice Sets the reference token for a given pool token. The reference token is used to determine the current price
     * of the pool token in terms of KLIMA. The position of KLIMA in the Uniswap pair for the reference token is also determined.
     * @param poolToken         The pool token for which to set the reference token.
     * @param referenceToken    The reference token for the given pool token.
     */
    function setPoolReference(address poolToken, address referenceToken) external onlyOwner {
        address oldReference = poolReference[poolToken];
        uint8 oldPosition = referenceKlimaPosition[poolToken];

        poolReference[poolToken] = referenceToken;
        referenceKlimaPosition[poolToken] = IUniswapV2Pair(referenceToken).token0() == KLIMA ? 0 : 1;

        emit PoolReferenceChanged(poolToken, oldReference, poolReference[poolToken]);
        emit ReferenceKlimaPositionChanged(poolReference[poolToken], oldPosition, referenceKlimaPosition[poolToken]);
    }

    /**
     * @notice Sets the address of the allocator contract. Only the contract owner can call this function.
     * @param allocator The address of the allocator contract to set.
     */
    function setAllocator(address allocator) external onlyOwner {
        address oldAllocator = allocatorContract;
        allocatorContract = allocator;

        emit AllocatorChanged(oldAllocator, allocatorContract);
    }

    /**
     * @notice Calculates the amount of KLIMA tokens needed to retire a specified amount of pool tokens for a pool.
     * The required amount of KLIMA tokens is calculated based on the current market price of the pool token and the amount of pool tokens to be retired.
     * If the raw amount needed from the dex exceeds slippage, than the limited amount is returned.
     * @param poolAmount    The amount of pool tokens to retire.
     * @param poolToken     The address of the pool token to retire.
     * @return klimaNeeded The amount of KLIMA tokens needed to retire the specified amount of pool tokens.
     */
    function getKlimaAmount(uint256 poolAmount, address poolToken) public view returns (uint256 klimaNeeded) {
        /// @dev On extremely small quote amounts this can result in zero
        uint256 maxKlima = (getMarketQuote(
            poolToken,
            (FEE_DIVISOR + maxSlippage[poolToken]) * 1e14 // Get market quote for 1 pool token + slippage percent.
        ) * poolAmount) / 1e18;

        // Check inputs through KI due to differences in DEX locations for pools
        klimaNeeded = IKlimaInfinity(INFINITY).getSourceAmountSwapOnly(KLIMA, poolToken, poolAmount);

        // If direct LP quote is 0, use quote from KI
        if (maxKlima == 0) return klimaNeeded;

        // Limit the KLIMA needed
        if (klimaNeeded > maxKlima) klimaNeeded = maxKlima;
    }

    /**
     * @notice Transfers and burns a specified amount of KLIMA tokens.
     * A fee is also transferred to the DAO address based on the fee divisor and the configured fee for the pool token.
     * @param totalKlima    The total amount of KLIMA tokens to transfer and burn.
     * @param poolToken     The address of the pool token to burn KLIMA tokens for.
     */
    function _transferAndBurnKlima(uint256 totalKlima, address poolToken) private {
        // Transfer and burn the KLIMA
        uint256 feeAmount = (totalKlima * daoFee[poolToken]) / FEE_DIVISOR;

        IKlima(KLIMA).safeTransferFrom(msg.sender, DAO, feeAmount);
        IKlima(KLIMA).burnFrom(msg.sender, totalKlima - feeAmount);

        emit KlimaBonded(feeAmount, totalKlima - feeAmount);
    }

    /**
     * @notice Returns the current market price of the pool token in terms of KLIMA tokens.
     * @dev Currently all KLIMA LP contracts safely interact with the IUniswapV2Pair abi.
     * @param poolToken The address of the pool token to get the market quote for.
     * @param amountOut The amount of pool tokens to get the market quote for.
     * @return currentPrice The current market price of the pool token in terms of KLIMA tokens.
     */
    function getMarketQuote(address poolToken, uint256 amountOut) internal view returns (uint256 currentPrice) {
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(poolReference[poolToken]).getReserves();

        currentPrice = referenceKlimaPosition[poolToken] == 0
            ? (amountOut * (reserve0)) / reserve1
            : (amountOut * (reserve1)) / reserve0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "oz/token/ERC20/utils/SafeERC20.sol";

interface IKlima is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
}

interface IKlimaTreasury {
    function excessReserves() external returns (uint);

    function manage(address _token, uint _amount) external;

    function queue(uint8 _managing, address _address) external returns (bool);

    function toggle(uint8 _managing, address _address, address _calculator) external returns (bool);

    function ReserveManagerQueue(address _address) external returns (uint);
}

interface IKlimaRetirementBond {
    function owner() external returns (address);

    function allocatorContract() external returns (address);

    function DAO() external returns (address);

    function TREASURY() external returns (address);

    function openMarket(address poolToken) external;

    function closeMarket(address poolToken) external;

    function updateMaxSlippage(address poolToken, uint256 _maxSlippage) external;

    function updateDaoFee(address poolToken, uint256 _daoFee) external;

    function setPoolReference(address poolToken, address referenceToken) external;
}

interface IRetirementBondAllocator {
    function fundBonds(address token, uint256 amount) external;

    function closeBonds(address token) external;

    function updateBondContract(address _bondContract) external;

    function updateMaxReservePercent(uint256 _maxReservePercent) external;

    function maxReservePercent() external view returns (uint256);

    function PERCENT_DIVISOR() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IKlimaInfinity {
    function retireExactCarbonDefault(
        address sourceToken,
        address poolToken,
        uint256 maxAmountIn,
        uint256 retireAmount,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external payable returns (uint256 retirementIndex);

    function retireExactCarbonSpecific(
        address sourceToken,
        address poolToken,
        address projectToken,
        uint256 maxAmountIn,
        uint256 retireAmount,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external payable returns (uint256 retirementIndex);

    function retireExactSourceDefault(
        address sourceToken,
        address poolToken,
        uint256 maxAmountIn,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external payable returns (uint256 retirementIndex);

    function retireExactSourceSpecific(
        address sourceToken,
        address poolToken,
        address projectToken,
        uint256 maxAmountIn,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external payable returns (uint256 retirementIndex);

    /* Views */

    function getSourceAmountDefaultRetirement(
        address sourceToken,
        address carbonToken,
        uint256 retireAmount
    ) external view returns (uint256 amountIn);

    function getSourceAmountSpecificRetirement(
        address sourceToken,
        address carbonToken,
        uint256 retireAmount
    ) external view returns (uint256 amountIn);

    function getSourceAmountSwapOnly(
        address sourceToken,
        address carbonToken,
        uint256 amountOut
    ) external view returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}