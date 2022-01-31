/**
 *Submitted for verification at polygonscan.com on 2022-01-31
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/finance/PaymentSplitter.sol


// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;




/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

// File: contracts/sale.sol


pragma solidity >=0.8.9;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */


//import "@openzeppelin/contracts/finance/VestingWallet.sol";
library SafeMath {
    function percent(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) internal pure returns (uint256 quotient) {
        // caution, check safe-to-multiply here
        uint256 _numerator = numerator * 10**(precision + 1);
        // with rounding of last digit
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface Token {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract TokenSaleV2 {
    struct Sale {
        uint256 initialSupply;
        uint256 burnedSupply;
        uint256 purchasedSupply;
        uint256 remainingSupply;
        uint256 supplyPerRound;
        uint256 currRound;
        uint256 totalRounds;
        uint256 initialPrice;
        uint256 currPrice;
        uint256 endingPrice;
        uint256 startTime;
        uint256 endTime;
    }

    struct SaleRound {
        uint256 round;
        uint256 tokenPrice;
        uint256 previousTokenPrice;
        uint256 supply;
        uint256 purchased;
        uint256 burned;
        uint256 raised;
        uint256 roundEnd;
        uint256 minContribution;
        uint256 maxContribution;
    }

    using SafeMath for uint256;
    Token token;
    address payable _owner;
    uint256 initialTokenPrice;
    uint256 currentTokenPrice;
    bool saleIsActive = false;
    bool saleIsWhitelist = false;
    uint256 public currRoundNum = 0;
    SaleRound public currRound;
    SaleRound[] public previousRounds;
    Sale public currSale;
    Sale[] public previousSales;
    uint256 public totalRounds;
    uint256 public tokensInNextRound;
    mapping(address => uint256) roundContributions;
    uint256 public remainingSaleSupply;
    uint256 public tokensBurned;
    uint256 public tokensPurchased;
    uint256 currentSupply = 0;
    address payable public payments;
    uint256 gweiRaised = 0;
    bool public initialized = false;
    uint256 public raisedAmount = 0;

    event PartlyRefundedContribution(
        uint256 contributionAmount,
        uint256 maxRoundContribution,
        uint256 refundAmount,
        address to
    );
    event PurchasedTokens(address indexed to, uint256 value);
    event BurnedTokens(address indexed to, uint256 value);
    event RoundEnded(address indexed to, uint256 value);
    event SaleStarted(address indexed by, uint256 value, uint256 rounds);
    event SaleRoundEnded(SaleRound round);
    event SaleEnded(Sale sale);

    constructor() {
        token = Token(0x1F435c17d7Ff631218827F9BA43a696650a9D512); 
        _owner = payable(msg.sender);
       
    }

    mapping(address => bool) whitelist;
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function add(address _address) public {
        require(
            msg.sender == _owner,
            "Only owner can add address to whitelist."
        );
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function remove(address _address) public {
        require(
            msg.sender == _owner,
            "Only owner can add address to whitelist."
        );
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    function initializeSale(
        uint256 _price,
        uint256 _tokensForSale,
        uint256 _rounds
    ) public {
        require(msg.sender == _owner, "Only owner can initialize Sale.");
        require(saleIsActive == false, "Sale must be inactive to initialize.");
        require(
            tokensAvailable() >= _tokensForSale * 1e18,
            "Must have enough tokens."
        ); // Must have enough tokens
        remainingSaleSupply = _tokensForSale * 1e18;
        currRoundNum = 0;
        initialTokenPrice = _price;
        currentTokenPrice = _price;

        uint256 supplyOfRounds = remainingSaleSupply.div(_rounds);
        currSale = Sale(
            remainingSaleSupply,
            0,
            0,
            remainingSaleSupply,
            supplyOfRounds,
            1, //currRound
            _rounds, //totalRounds
            initialTokenPrice,
            initialTokenPrice,
            0,
            block.timestamp,
            0
        );
        initialized = true;
        saleIsActive = true;
        createInitialRound(_rounds);
        emit SaleStarted(_owner, _tokensForSale, _rounds);
    }

    function createInitialRound(uint256 _rounds) private {
        require(
            saleIsActive == true,
            "Sale must be active to create initial round."
        );
        uint256 tokensAvailableInRound = remainingSaleSupply.div(_rounds);
        totalRounds = _rounds;
        currRoundNum = currRoundNum.add(1);
        currRound = SaleRound(
            currRoundNum,
            initialTokenPrice,
            0,
            tokensAvailableInRound,
            0,
            0,
            0,
            block.timestamp.add(24 hours),
            50 ether,
            5000 ether
        );
    }

    function endSale() private {
        require(saleIsActive == true, "Sale must be active to end sale.");

        saleIsActive = false;

        currSale.endTime = block.timestamp;
        currSale.endingPrice = currRound.tokenPrice;

        emit SaleEnded(currSale);
    }

    function reduceSupply(uint256 reductionType, uint256 amount) private {
        if (reductionType == 0) {
            //burn
            currRound.supply = currRound.supply.sub(amount);
            tokensBurned = tokensBurned.add(currRound.burned); //increment total tokens burned
            currSale.remainingSupply = currSale.remainingSupply.sub(amount);
            currSale.burnedSupply = currSale.burnedSupply.add(currRound.burned);
            remainingSaleSupply = remainingSaleSupply.sub(currRound.burned);
            emit BurnedTokens(
                0x000000000000000000000000000000000000dEaD,
                currRound.burned
            );
        } else if (reductionType == 1) {
            //purchase
            currRound.purchased = currRound.purchased.add(amount);
            currRound.supply = currRound.supply.sub(amount);
            currSale.purchasedSupply = currSale.purchasedSupply.add(amount);
            currSale.remainingSupply = currSale.remainingSupply.sub(amount);
            remainingSaleSupply = remainingSaleSupply.sub(amount);
            tokensPurchased = tokensPurchased.add(amount);
            emit PurchasedTokens(msg.sender, amount); // log event onto the blockchain
        }
    }

    function purchaseTokens() public payable {
        require(isRoundEnded() == false, "Round has ended.");
        require(
            saleIsActive == true,
            "Sale must be active to purchase tokens."
        );
        require(
            msg.value <= currRound.minContribution,
            "Contribution is below minimum specified, please increase contribution and try again."
        );
        require(
            msg.value >= currRound.maxContribution,
            "Contribution is above maximum specified, please decrease contribution and try again."
        );
        if (saleIsWhitelist) {
            require(
                isWhitelisted(msg.sender),
                "Must be whitelisted to participate in sale."
            );
        }
        uint256 weiAmount = msg.value; // Calculate tokens to sell
        uint256 tokens = weiAmount.mul(currRound.tokenPrice);
        if (tokens >= currRound.supply) {
            uint256 remainingRoundSupplyPurchase = currRound.tokenPrice *
                currRound.supply;
            payable(msg.sender).transfer(
                msg.value.sub(remainingRoundSupplyPurchase)
            ); //refund extra paid
            emit PartlyRefundedContribution(
                weiAmount,
                remainingRoundSupplyPurchase,
                weiAmount.sub(remainingRoundSupplyPurchase),
                msg.sender
            );
            currRound.raised = currRound.raised.add(
                remainingRoundSupplyPurchase
            );
            token.transfer(msg.sender, remainingRoundSupplyPurchase); // Send tokens to buyer
            reduceSupply(1, currRound.supply); //reduce supply by amount purchased
        } else {
            token.transfer(msg.sender, tokens); // Send tokens to buyer
            // _owner.transfer(msg.value); // Send funds to owner
            currRound.raised = currRound.raised.add(weiAmount);
            reduceSupply(1, tokens);
        }
    }

    function setWhitelistStatus(bool _isWhitelist) public returns (bool) {
        require(msg.sender == _owner, "Only owner can set whitelist status.");
        saleIsWhitelist = _isWhitelist;

        return saleIsWhitelist;
    }

    function prepareNextRound(
        uint256 _newPrice,
        uint256 _minContribution,
        uint256 _maxContribution
    ) public {
        require(msg.sender == _owner, "Only owner can prepare next round.");
        currRound.burned = currRound.supply; //calculate tokens to burn

        if (currRound.burned > 0) {
            reduceSupply(0, currRound.burned);
            token.transfer(
                0x000000000000000000000000000000000000dEaD,
                currRound.burned
            ); //burn tokens
        }

        previousRounds.push(currRound);
        emit SaleRoundEnded(currRound);
        currRound.previousTokenPrice = currRound.tokenPrice;

        currSale.currRound = currSale.currRound.add(1);
        currRoundNum = currRoundNum.add(1);
        currSale.currPrice = _newPrice;

        currRound = SaleRound(
            currRoundNum,
            _newPrice,
            currRound.tokenPrice,
            currSale.supplyPerRound,
            0,
            0,
            0,
            block.timestamp.add(24 hours),
            _minContribution * 1e18,
            _maxContribution * 1e18
        );
    }

    function tokenBalance() private returns (uint256) {
        return tokensAvailable();
    }

    function isRoundEnded() public view returns (bool) {
        return ((block.timestamp > currRound.roundEnd) ||
            (currRound.supply == 0));
    }

    /**
     * @dev Fallback function if ether is sent to address insted of buyTokens function
     **/
    fallback() external payable {
        purchaseTokens();
    }

    /**
     * tokensAvailable
     * @dev returns the number of tokens allocated to this contract
     **/
    function tokensAvailable() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function setPaymentsContract(address payable _payments) public {
        payments = payable(0x0000000000000000000000000000000000000000);
    }

    function withdraw() public payable {
        require(msg.sender == _owner, "Only owner can call withdraw");
        (bool success, ) = payable(payments).call{value: address(this).balance}(
            ""
        );
        require(success);
    }

    /**
     * destroy
     * @notice Terminate contract and refund to owner
     **/
    function destroy() public {
        // Transfer tokens back to owner
        require(msg.sender == _owner, "Only owner can destroy");
        uint256 balance = token.balanceOf(address(this));
        assert(balance > 0);
        token.transfer(_owner, balance);
        // There should be no ether in the contract but just in case
        selfdestruct(_owner);
    }
}