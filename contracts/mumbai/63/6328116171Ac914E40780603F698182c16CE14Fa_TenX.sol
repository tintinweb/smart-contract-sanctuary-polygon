// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

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
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * BNB testnet address :- 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
 * busd testnet address :- 0x9331b55D9830EF609A2aBCfAc0FBCE050A52fdEa
 * BNB mainnet address :- 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
 * busd mainnet address :- 0xcBb98864Ef56E9042e7d2efef76141f15731B82f
 */

contract TenX is Ownable {
    using SafeERC20 for IERC20;
    uint256 public totalReferralIds;
    uint256 public BNBFromFailedTransfers; // BNB left in the contract from failed transfers

    uint256 public referralLevels;
    address public reInvestmentWallet;
    address[] public shareHolderWallet;
    uint256[] public shareHolderPercentage; // percentage should whithout decimal EX:- 33.75 will like 3375
    mapping(uint256 => uint256) public referralPercentage;

    struct SubscriptionPlan {
        uint256 price;
        uint256 duration;
        bool exist;
    }
    mapping(uint256 => SubscriptionPlan) public subscriptionPlans; // months -> plan details

    struct User {
        uint256 referralId;
        uint256 referredBy;
        uint256 subscriptionValidity;
    }
    mapping(address => User) public users; // user address -> User
    mapping(uint256 => address) public referralIdToUser; // referralId -> user address

    struct PaymentToken {
        address priceFeed; // Chainlink price feed
        bool exist;
    }
    mapping(address => PaymentToken) public paymentTokens;

    /* Events */
    event TransferOfBNBFail(address indexed receiver, uint256 indexed amount);
    event SetShareHolder(address indexed shareHolderWallet, uint128 index);
    event SetShareHolderPercentage(
        uint256 indexed shareHolderPercentage,
        uint128 index
    );

    event SetReferralPercentage(uint256 referralPercentage, uint128 index);
    event SetReInvestmentWallet(address indexed reInvestmentWallet);

    event CreateUser(
        address indexed user,
        uint256 indexed referralId,
        uint256 indexed referredBy
    );

    event Subscription(
        uint256 amount,
        uint256 period,
        address indexed subscriber,
        address paymentToken
    );
    event AddPaymentToken(address indexed paymentToken);
    event RemovePaymentToken(address indexed paymentToken);

    constructor(
        address[] memory _shareHolderWallet,
        uint256[] memory _shareHolderPercentage,
        address _reinvestmentWallet,
        uint256 _referralLevel,
        uint256[] memory _referralPercentage,
        uint256[] memory months,
        uint256[] memory pricing
    ) {
        require(
            _shareHolderPercentage.length == _shareHolderWallet.length,
            "TenX: share holder length mismatch"
        );
        require(
            _referralLevel == _referralPercentage.length,
            "TenX: referral length mismatch"
        );
        require(
            months.length == pricing.length,
            "TenX: pricing length mismatch"
        );

        shareHolderWallet = _shareHolderWallet;
        shareHolderPercentage = _shareHolderPercentage;
        reInvestmentWallet = _reinvestmentWallet;
        referralLevels = _referralLevel;

        for (uint256 i; i < referralLevels; i++) {
            referralPercentage[i] = _referralPercentage[i];
        }

        addpricing(months, pricing);
    }

    function addpricing(
        uint256[] memory months,
        uint256[] memory pricing
    ) internal {
        for (uint256 i; i < pricing.length; i++) {
            subscriptionPlans[months[i]] = SubscriptionPlan(
                pricing[i],
                months[i] * 30 days,
                true
            );
        }
    }

    function addPaymentToken(
        address paymentToken,
        address priceFeed
    ) external onlyOwner {
        require(
            !paymentTokens[paymentToken].exist,
            "TenX: paymentToken already added"
        );
        require(priceFeed != address(0), "TenX: priceFeed address zero");

        paymentTokens[paymentToken] = PaymentToken(priceFeed, true);
        emit AddPaymentToken(paymentToken);
    }

    function removePaymentToken(address paymentToken) external onlyOwner {
        require(
            paymentTokens[paymentToken].exist,
            "TenX: paymentToken not added"
        );

        delete paymentTokens[paymentToken];
        emit RemovePaymentToken(paymentToken);
    }

    function changePriceFeed(
        address paymentToken,
        address priceFeed
    ) external onlyOwner {
        require(
            paymentTokens[paymentToken].exist,
            "TenX: paymentToken not added"
        );

        require(priceFeed != address(0), "TenX: priceFeed address zero");
        paymentTokens[paymentToken].priceFeed = priceFeed;
    }

    function addSubscriptionPlan(
        uint256 months,
        uint256 price
    ) external onlyOwner {
        require(months > 0 && price > 0, "TenX: month or price zero");

        subscriptionPlans[months] = SubscriptionPlan(
            price,
            months * 30 days,
            true
        );
    }

    function changeSubscriptionPricing(
        uint256 newPrice,
        uint256 months
    ) external onlyOwner {
        require(
            subscriptionPlans[months].exist,
            "TenX: invalid subscription plan"
        );
        subscriptionPlans[months].price = newPrice;
    }

    function removeSubscriptionPlan(uint256 months) external onlyOwner {
        require(
            subscriptionPlans[months].exist,
            "TenX: invalid subscription plan"
        );
        delete subscriptionPlans[months];
    }

    function getUserReferralId() internal returns (uint256) {
        return ++totalReferralIds;
    }

    function createUser(
        address userAddress,
        uint256 referredBy
    ) internal returns (uint256 userReferralId) {
        userReferralId = getUserReferralId();
        users[userAddress] = User(userReferralId, referredBy, 0);
        referralIdToUser[userReferralId] = userAddress;
        emit CreateUser(userAddress, userReferralId, referredBy);
    }

    function subscribe(
        uint256 amount,
        uint120 months,
        uint256 referredBy,
        address paymentToken
    ) external payable {
        require(
            subscriptionPlans[months].exist,
            "TenX: subscription plan doesn't exist"
        );
        require(
            getSubscriptionAmount(months, paymentToken) <= amount,
            "TenX: amount paid less. increase slippage"
        );
        if (referredBy != 0)
            require(
                referralIdToUser[referredBy] != address(0),
                "TenX: invalid referredBy"
            );

        if (paymentToken != address(0)) {
            require(
                IERC20(paymentToken).allowance(msg.sender, address(this)) >=
                    amount,
                "TenX: insufficient allowance"
            );
            require(msg.value == 0, "TenX: msg.value not zero");
        } else require(amount == msg.value, "TenX: msg.value not equal amount");

        uint256 amountAfterReferrals = amount;

        User memory user = users[msg.sender];
        if (user.referralId == 0) {
            createUser(msg.sender, referredBy);
            amountAfterReferrals -= processReferrals(
                referredBy,
                amount,
                paymentToken
            );
        }

        processPayment(amountAfterReferrals, paymentToken);
        uint256 subscriptionValidity = block.timestamp +
            subscriptionPlans[months].duration;
        users[msg.sender].subscriptionValidity = subscriptionValidity;

        emit Subscription(
            amount,
            subscriptionValidity,
            msg.sender,
            paymentToken
        );
    }

    function calculatePercentage(
        uint256 amount,
        uint256 percentage
    ) internal pure returns (uint256 shareAmount) {
        shareAmount = (amount * percentage) / 10_000;
    }

    function transferTokens(
        address from,
        address to,
        uint256 amount,
        address paymentToken
    ) internal {
        if (amount > 0 && to != address(0)) {
            if (paymentToken != address(0)) {
                if (from == address(this))
                    IERC20(paymentToken).safeTransfer(to, amount);
                else IERC20(paymentToken).safeTransferFrom(from, to, amount);
            } else {
                (bool success, ) = payable(to).call{value: amount}("");
                if (!success) {
                    BNBFromFailedTransfers += amount;
                    emit TransferOfBNBFail(to, amount);
                }
            }
        }
    }

    function processReferrals(
        uint256 referredBy,
        uint256 amount,
        address paymentToken
    ) internal returns (uint256 totalReferralRewards) {
        if (referredBy != 0) {
            (address[] memory referralList, uint256 count) = getReferralList(
                referredBy
            );
            for (uint256 i; i < count; i++) {
                uint256 referralReward = calculatePercentage(
                    amount,
                    referralPercentage[i]
                );
                totalReferralRewards += referralReward;
                transferTokens(
                    msg.sender,
                    referralList[i],
                    referralReward,
                    paymentToken
                );
            }
        }
    }

    function getReferralList(
        uint256 referredBy
    ) internal view returns (address[] memory, uint256) {
        uint256 currentReferralId = referredBy;
        address[] memory referralList = new address[](referralLevels);
        uint256 count;

        for (uint256 i; i < referralLevels; i++) {
            referralList[i] = referralIdToUser[currentReferralId];
            currentReferralId = users[referralList[i]].referredBy;
            count++;
            if (currentReferralId == 0) break;
        }
        return (referralList, count);
    }

    function processPayment(uint256 amount, address paymentToken) internal {
        // Share Holder Payments
        uint256 totalShareHolderAmount;
        for (uint256 i; i < shareHolderPercentage.length; i++) {
            uint256 shareHolderAmount = calculatePercentage(
                amount,
                shareHolderPercentage[i]
            );
            totalShareHolderAmount += shareHolderAmount;
            transferTokens(
                msg.sender,
                shareHolderWallet[i],
                shareHolderAmount,
                paymentToken
            );
        }
        // Re Investment Wallet Payments
        transferTokens(
            msg.sender,
            reInvestmentWallet,
            amount - totalShareHolderAmount,
            paymentToken
        );
    }

    function getSubscriptionAmount(
        uint256 months,
        address paymentToken
    ) public view returns (uint256 subscriptionAmount) {
        require(
            subscriptionPlans[months].exist,
            "TenX: invalid subscription plan"
        );
        require(
            paymentTokens[paymentToken].exist,
            "TenX: paymentToken not added"
        );

        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            paymentTokens[paymentToken].priceFeed
        );

        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());

        subscriptionAmount = paymentToken != address(0)
            ? ((subscriptionPlans[months].price *
                10 ** (decimals + IERC20Metadata(paymentToken).decimals())) /
                uint256(price))
            : ((subscriptionPlans[months].price * 10 ** (decimals + 18)) /
                uint256(price));
    }

    function changeShareHolder(
        address _shareHolderWallet,
        uint128 index
    ) external onlyOwner {
        require(index < shareHolderWallet.length, "invalid index");
        require(
            _shareHolderWallet != address(0),
            "TenX: _shareHolderWallet wallet zero"
        );
        shareHolderWallet[index] = _shareHolderWallet;
        emit SetShareHolder(_shareHolderWallet, index);
    }

    /**
     * @param _shareHolderPercentage always be multiplied by 100
     * For example 9 % should be added as 900 which is 9 * 100
     */
    function changeShareHolderPercentage(
        uint256 _shareHolderPercentage,
        uint128 index
    ) external onlyOwner {
        require(index < shareHolderPercentage.length, "TenX: invalid index");
        shareHolderPercentage[index] = _shareHolderPercentage;
        emit SetShareHolderPercentage(_shareHolderPercentage, index);
    }

    function changeReInvestmentWallet(
        address _reInvestmentWallet
    ) external onlyOwner {
        require(
            _reInvestmentWallet != address(0),
            "TenX: _reInvestmentWallet zero"
        );
        reInvestmentWallet = _reInvestmentWallet;
        emit SetReInvestmentWallet(_reInvestmentWallet);
    }

    /**
     * @param _referralPercentage always be multiplied by 100
     * For example 9 % should be added as 900 which is 9 * 100
     */

    function changeReferralPercentage(
        uint256 _referralPercentage,
        uint128 index
    ) external onlyOwner {
        require(index < referralLevels, "TenX: invalid index");
        referralPercentage[index] = _referralPercentage;
        emit SetReferralPercentage(_referralPercentage, index);
    }

    /**
     * @notice This method is to collect any BNB left from failed transfers.
     * @dev This method can only be called by the contract owner
     */
    function collectBNBFromFailedTransfers() external onlyOwner {
        uint256 bnbToSend = BNBFromFailedTransfers;
        BNBFromFailedTransfers = 0;
        (bool success, ) = payable(owner()).call{value: bnbToSend}("");
        require(success, "TenX: BNB transfer failed");
    }
}