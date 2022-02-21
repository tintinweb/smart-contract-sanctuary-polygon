/**
 *Submitted for verification at polygonscan.com on 2022-02-21
*/

// File: @uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol


pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// File: @uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol


pragma solidity >=0.7.5;
pragma abicoder v2;


/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
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


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// File: @uniswap/v3-periphery/contracts/libraries/TransferHelper.sol


pragma solidity >=0.6.0;


library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
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

// File: contracts/interfaces/IOwnable.sol


pragma solidity ^0.8.0;

/**
* @dev Ownable interface
*/
interface IOwnable {
    function isOwner() external view returns(bool);

    function transferOwnership(address newOwner) external;
}
// File: contracts/Ownable.sol

pragma solidity ^0.8.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is IOwnable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Msg.sender is not the Owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view override returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Earn.sol

pragma solidity ^0.8.0;






contract Earn is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public AFN;
    IERC20 public USDC;
    address loanAddress;
    address feeAddress;

    // Interest Bonus based off time late
    uint256 public baseBonusMultiplier;
    uint256 public afnBonusMultiplier;

    uint256 public transferFee;

    // USDC Amounts Needed for AFN Value Tiers
    uint256 public highTier; // dollars + 6 decimals
    uint256 public medTier; // dollars + 6 decimals
    uint256 public lowTier; // dollars + 6 decimals

    event ContractOpened(address indexed owner, uint256 earnContractId);
    event ContractClosed(address indexed owner, uint256 earnContractId);
    event EarnContractOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner,
        uint256 earnContractId
    );

    constructor(
        IERC20 _USDC,
        IERC20 _AFN,
        address _loanAddress,
        address _feeAddress
    ) {
        USDC = _USDC;
        AFN = _AFN;
        baseBonusMultiplier = 150; //150 = 1.5x
        afnBonusMultiplier = 200; // 200 = 2x
        loanAddress = _loanAddress;
        feeAddress = _feeAddress;
    }

    enum ContractStatus {
        OPEN,
        CLOSED,
        FORSALE
    }

    struct EarnTerm {
        // Time Locked (in Days);
        uint256 time;
        // USDC APR (simple interest) (1000 = 10%)
        uint16 usdcRate;
        // AFN High Amount
        uint64 afnHighAmount;
        // AFN Med Amount
        uint64 afnMedAmount;
        // AFN Low Amount
        uint64 afnLowAmount;
        // Tokens other than AFN accepted?
        bool otherTokens;
        // Tokens need to be whitelisted?
        bool whitelist;
        // Array of whitelisted tokens
        address[] tokensAccepted;
    }

    struct EarnContract {
        // Contract Owner Address
        address owner;
        // Unix Epoch time started
        uint256 startTime;
        // length of contract in seconds
        uint256 contractLength;
        // Address of token lent
        address tokenAddress;
        // Amount of token lent
        uint256 tokenAmount;
        // Amount sent to contract in USDC (swap value);
        uint256 usdcPrincipal;
        // USDC interest rate
        uint256 usdcRate;
        // AFN interet rate
        uint256 afnAmount;
        // Rate usdc interest will be paid for days overdue
        uint256 usdcBonusRate;
        // Fixed AFN bonus for overdue payment
        uint256 afnBonusAmount;
        // Open, Closed, or ForSale
        ContractStatus status;
    }

    struct Bid {
        // Bid Owner Address
        address bidder;
        // Address of Contract Owner
        address to;
        // Earn Contract Id
        uint256 earnContractId;
        // Amount
        uint256 amount;
        // Accepted - false if pending
        bool accepted;
    }

    // Comes with a public getter function
    EarnTerm[] public earnTerms;
    EarnContract[] public earnContracts;
    Bid[] public bids;

    // Maps the earn contract id to the owner
    mapping(uint256 => address) public earnContractToOwner;

    // Maps the number of earn contracts for a given user
    mapping(address => uint256) public ownerEarnContractCount;

    // Maps the number of bids per earn contract
    mapping(uint256 => uint256) public earnContractBidCount;

    /**
     * @param _time Length of the contract in days
     * @param _usdcRate Interest rate for USDC (1000 = 10%)
     * @param _afnHighAmount AFN bonus for the high tier
     * @param _afnMedAmount AFN bonus for the medium tier
     * @param _afnLowAmount AFN bonus for the low tier
     * @dev Add an earn term with 8 parameters
     */
    function addTerm(
        uint256 _time,
        uint16 _usdcRate,
        uint64 _afnHighAmount,
        uint64 _afnMedAmount,
        uint64 _afnLowAmount,
        bool _otherTokens,
        bool _whitelist,
        address[] memory _tokensAccepted
    ) public onlyOwner {
        earnTerms.push(
            EarnTerm(
                _time,
                _usdcRate,
                _afnHighAmount,
                _afnMedAmount,
                _afnLowAmount,
                _otherTokens,
                _whitelist,
                _tokensAccepted
            )
        );
    }

    /**
     * Remove an earn term
     * Copies the last element of the array to the index specified then pops the last element off the array.
     * The order of the array will be changed.
     * @dev Removing an earn term may change the earnTermId for other terms
     * @param _earnTermsId index of the earn term in earnTerms
     */
    function removeTerm(uint256 _earnTermsId) public onlyOwner {
        require(_earnTermsId < earnTerms.length);
        earnTerms[_earnTermsId] = earnTerms[earnTerms.length - 1];
        earnTerms.pop();
    }

    /**
     * @dev Update an earn term passing the individual parameters
     * @param _earnTermsId index of the earn term in earnTerms
     * @param _time Length of the contract in days
     * @param _usdcRate Interest rate for USDC (1000 = 10%)
     * @param _afnHighAmount AFN bonus for the high tier
     * @param _afnMedAmount AFN bonus for the medium tier
     * @param _afnLowAmount AFN bonus for the low tier
     */
    function updateTerm(
        uint256 _earnTermsId,
        uint256 _time,
        uint16 _usdcRate,
        uint64 _afnHighAmount,
        uint64 _afnMedAmount,
        uint64 _afnLowAmount,
        bool _otherTokens,
        bool _whitelist,
        address[] memory _tokensAccepted
    ) public onlyOwner {
        earnTerms[_earnTermsId] = EarnTerm(
            _time,
            _usdcRate,
            _afnHighAmount,
            _afnMedAmount,
            _afnLowAmount,
            _otherTokens,
            _whitelist,
            _tokensAccepted
        );
    }

    /**
     * @notice Use the public getter function for earnTerms for a single earnTerm
     * @return An array of type EarnTerm
     */
    function getAllEarnTerms() public view returns (EarnTerm[] memory) {
        return earnTerms;
    }

    /**
     * @notice Use the public getter function for bids for a sinble bid
     * @return An array of type Bid
     */
    function getAllBids() public view returns (Bid[] memory) {
        return bids;
    }

    function getContractTier(uint256 _amount, EarnTerm memory earnTerm)
        internal
        view
        returns (uint256 afnAmount)
    {
        if (_amount >= highTier) {
            afnAmount = earnTerm.afnHighAmount;
        } else if (_amount >= medTier) {
            afnAmount = earnTerm.afnMedAmount;
        } else if (_amount >= lowTier) {
            afnAmount = earnTerm.afnLowAmount;
        } else {
            afnAmount = 0;
        }
        return afnAmount;
    }

    /**
     * Sends erc20 token to AltaFin Treasury Address and creates a contract with EarnContract[_id] terms for user.
     * User needs to approve USDC to be spent by this contract before calling this function
     * @param _earnTermsId index of the earn term in earnTerms
     * @param _amount Amount of USDC principal
     */
    function openContractUsdc(uint256 _earnTermsId, uint256 _amount) public {
        EarnTerm memory earnTerm = earnTerms[_earnTermsId];
        require(earnTerm.otherTokens, "Earn term doesn't accept USDC");
        if (earnTerm.whitelist) {
            // Check to see if token is on whitelist for earn term
            require(checkTokenWhitelist(address(USDC), _earnTermsId));
        }

        require(_amount > 0, "USDC amount must be greater than zero");
        // Check to see if the User has sufficient funds.
        require(
            USDC.balanceOf(address(msg.sender)) >= _amount,
            "Insufficient Tokens"
        );

        uint256 afnAmount = getContractTier(_amount, earnTerm);

        uint256 earnDays = earnTerm.time * 1 days;

        USDC.safeTransferFrom(msg.sender, loanAddress, _amount);

        _createContract(
            earnTerm,
            earnDays,
            _amount,
            afnAmount,
            _amount,
            address(USDC)
        );
    }

    /**
     * Sends erc20 token to AltaFin Treasury Address and creates a contract with EarnContract[_id] terms for user.
     * @param _earnTermsId index of the earn term in earnTerms
     * @param _tokenAddress Contract address of input token
     * @param _amount Amount of token to be swapped for USDC principal
     */
    function openContractTokenSwapToUSDC(
        uint256 _earnTermsId,
        address _tokenAddress,
        uint256 _amount,
        address _swapTarget,
        bytes calldata _swapCallData
    ) public {
        require(_amount > 0, "Token amount must be greater than zero");
        // User needs to first approve the token to be spent
        IERC20 token = IERC20(_tokenAddress);
        require(
            token.balanceOf(address(msg.sender)) >= _amount,
            "Insufficient Tokens"
        );

        EarnTerm memory earnTerm = earnTerms[_earnTermsId];

        // Check if input token is AFN
        if (_tokenAddress != address(AFN)) {
            // Earn Term must accept other tokens
            require(earnTerm.otherTokens);
            if (earnTerm.whitelist) {
                // Check to see if token is on whitelist for earn term
                require(checkTokenWhitelist(_tokenAddress, _earnTermsId));
            }
        }

        token.safeTransferFrom(msg.sender, address(this), _amount);

        // Swap tokens for USDC
        uint256 amountUsdc = _swapToUSDCOnZeroX(
            _tokenAddress,
            _amount,
            payable(_swapTarget), // address payable swapTarget
            _swapCallData // bytes calldata swapCallData
        );

        uint256 afnAmount = getContractTier(amountUsdc, earnTerm);

        uint256 earnDays = earnTerm.time * 1 days;

        _createContract(
            earnTerm,
            earnDays,
            amountUsdc,
            afnAmount,
            _amount,
            _tokenAddress
        );
    }

    function _createContract(
        EarnTerm memory _earnTerm,
        uint256 _earnDays,
        uint256 _amountUsdc,
        uint256 _amountAfn,
        uint256 _assetAmount,
        address _assetAddress
    ) internal {
        EarnContract memory earnContract = EarnContract(
            msg.sender, // owner
            block.timestamp, // startTime
            _earnDays, //contractLength,
            _assetAddress, // tokenAddress
            _assetAmount, // tokenAmount
            _amountUsdc, // usdcPrincipal
            _earnTerm.usdcRate, // usdcRate
            _amountAfn, // afnAmount
            (_earnTerm.usdcRate * baseBonusMultiplier) / 100, // usdcBonusRate
            (_amountAfn * afnBonusMultiplier) / 100, // afnBonusAmount
            ContractStatus.OPEN
        );

        earnContracts.push(earnContract);
        uint256 id = earnContracts.length - 1;
        earnContractToOwner[id] = msg.sender; // assign the earn contract to the owner;
        ownerEarnContractCount[msg.sender] =
            ownerEarnContractCount[msg.sender] +
            1; // increment the number of earn contract owned for the user;
        emit ContractOpened(msg.sender, id);
    }

    /**
     * Sends the amount usdc and afn owed to the contract owner and deletes the EarnContract from the mapping.
     * @param _earnContractId index of earn contract in earnContracts
     */
    function closeContract(uint256 _earnContractId) external onlyOwner {
        require(
            earnContracts[_earnContractId].status != ContractStatus.CLOSED,
            "Contract is already closed"
        );
        (uint256 usdcAmount, uint256 afnAmount) = _calculatePaymentAmounts(
            _earnContractId
        );

        address owner = earnContracts[_earnContractId].owner;

        USDC.safeTransferFrom(msg.sender, address(owner), usdcAmount);
        AFN.safeTransferFrom(msg.sender, address(owner), afnAmount);

        emit ContractClosed(owner, _earnContractId);

        _removeAllContractBids(_earnContractId);

        // Remove the earn contract from the array
        // NOTE: The order of the array will be changed.
        require(
            _earnContractId < earnContracts.length,
            "Contract Index not in the array"
        );

        earnContracts[_earnContractId].status = ContractStatus.CLOSED;
    }

    /**
     * Internal function to calculate the amount of USDC and AFN needed to close an earnContract
     * @param _earnContractId index of earn contract in earnContracts
     */
    // TODO: Test this function thoroughly
    function _calculatePaymentAmounts(uint256 _earnContractId)
        internal
        view
        returns (uint256 usdcAmount, uint256 afnAmount)
    {
        EarnContract memory earnContract = earnContracts[_earnContractId];
        uint256 timeOpen = block.timestamp -
            earnContracts[_earnContractId].startTime;

        // Calculate amounts to be paid out to earnContract Owner
        // If the position is closed within 3 days of the contract ending, no bonus rate. (Buffer time period for positions to be closed out)
        if (timeOpen <= earnContract.contractLength + 7 days) {
            // Calculate the total amount of usdc to be paid out (principal + interest)
            usdcAmount =
                earnContract.usdcPrincipal +
                ((earnContract.usdcPrincipal *
                    earnContract.usdcRate *
                    timeOpen) /
                    365 days /
                    10000);
            afnAmount = earnContract.afnAmount;
        } else {
            uint256 extraTime = timeOpen - earnContract.contractLength;
            uint256 usdcRegInterest = earnContract.usdcPrincipal +
                ((earnContract.usdcPrincipal *
                    earnContract.usdcRate *
                    earnContract.contractLength) /
                    365 days /
                    10000);
            uint256 usdcBonusInterest = (earnContract.usdcPrincipal *
                earnContract.usdcBonusRate *
                extraTime) /
                365 days /
                10000;
            usdcAmount =
                earnContract.usdcPrincipal +
                usdcRegInterest +
                usdcBonusInterest;
            afnAmount = earnContract.afnBonusAmount;
        }
        return (usdcAmount, afnAmount);
    }

    /**
     * Sends all Ether in the contract to the specified wallet.
     * @param _addr Address of wallet to send ether
     */
    function withdraw(address payable _addr) public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = _addr.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    /**
     * Sends all USDC in the contract to the specified wallet.
     * @param _addr Address of wallet to send USDC
     */
    function withdrawUSDC(address payable _addr) public onlyOwner {
        uint256 amount = USDC.balanceOf(address(this));
        USDC.safeTransfer(_addr, amount);
    }

    /**
     * @param _to address of transfer recipient
     * @param _amount amount of ether to be transferred
     */
    // Function to transfer Ether from this contract to address from input
    function transfer(address payable _to, uint256 _amount) public onlyOwner {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    /**
     * Gets the current value of all earn terms for a given user
     * @param _owner address of owner to query
     */
    function getCurrentUsdcValueByOwner(address _owner)
        public
        view
        returns (uint256)
    {
        uint256[] memory result = getContractsByOwner(_owner);
        uint256 currValue = 0;

        for (uint256 i = 0; i < result.length; i++) {
            EarnContract memory earnContract = earnContracts[result[i]];
            if (earnContract.status != ContractStatus.CLOSED) {
                uint256 timeHeld = (block.timestamp - earnContract.startTime) /
                    365 days;
                currValue =
                    currValue +
                    earnContract.usdcPrincipal +
                    (earnContract.usdcPrincipal *
                        earnContract.usdcRate *
                        timeHeld);
            }
        }
        return currValue;
    }

    /**
     * Gets the value at time of redemption for all earns terms for a given user
     * @param _owner address of owner to query
     */
    function getRedemptionUsdcValueByOwner(address _owner)
        public
        view
        returns (uint256)
    {
        uint256[] memory result = getContractsByOwner(_owner);
        uint256 currValue = 0;

        for (uint256 i = 0; i < result.length; i++) {
            EarnContract memory earnContract = earnContracts[result[i]];
            if (earnContract.status != ContractStatus.CLOSED) {
                currValue =
                    currValue +
                    earnContract.usdcPrincipal +
                    (
                        ((earnContract.usdcPrincipal *
                            earnContract.usdcRate *
                            earnContract.contractLength) / 365 days)
                    );
            }
        }
        return currValue;
    }

    /**
     * Gets every earn contract for a given user
     * @param _owner Wallet Address for expected earn contract owner
     */
    function getContractsByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](ownerEarnContractCount[_owner]);
        uint256 counter = 0;
        for (uint256 i = 0; i < earnContracts.length; i++) {
            if (earnContractToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function getAllEarnContracts() public view returns (EarnContract[] memory) {
        return earnContracts;
    }

    /**
     * Swaps ERC20->ERC20 tokens held by this contract using a 0x-API quote.
     * @param _swapTarget 'To' field from the 0x API response
     * @param _swapCallData 'Data' field from the 0x API response
     */
    function _swapToUSDCOnZeroX(
        address _token,
        uint256 _amount,
        // The `to` field from the API response.
        address payable _swapTarget,
        // The `data` field from the API response.
        bytes calldata _swapCallData
    ) internal returns (uint256) {
        uint256 currentUsdcBalance = USDC.balanceOf(address(this));

        require(IERC20(_token).approve(_swapTarget, _amount), "approve failed");

        // Call the encoded swap function call on the contract at `swapTarget`,
        // passing along any ETH attached to this function call to cover protocol fees.
        (bool success, ) = _swapTarget.call{value: msg.value}(_swapCallData);
        require(success, "SWAP_CALL_FAILED");

        uint256 usdcAmount = USDC.balanceOf(address(this)) - currentUsdcBalance;
        USDC.safeTransfer(loanAddress, usdcAmount);
        return usdcAmount;
    }

    /**
     * @param _token Token contract address
     * @param _earnTermsId Index of earn term in earnTerms
     */
    function checkTokenWhitelist(address _token, uint256 _earnTermsId)
        public
        view
        returns (bool)
    {
        EarnTerm memory earnTerm = earnTerms[_earnTermsId];
        for (uint256 i = 0; i < earnTerm.tokensAccepted.length; i++) {
            if (_token == earnTerm.tokensAccepted[i]) {
                return true;
            }
        }
        return false;
    }

    /**
     * Lists the associated earn contract for sale on the market
     * @param _earnContractId index of earn contract in earnContracts
     */
    function putSale(uint256 _earnContractId) external {
        require(
            msg.sender == earnContractToOwner[_earnContractId],
            "Msg.sender is not the owner"
        );
        earnContracts[_earnContractId].status = ContractStatus.FORSALE;
    }

    /**
     * Submits a bid for an earn contract on sale in the market
     * User must sign an approval transaction for first. AFN.approve(address(this), _amount);
     * @param _earnContractId index of earn contract in earnContracts
     * @param _amount Amount of AFN offered for bid
     */
    function makeBid(uint256 _earnContractId, uint256 _amount) external {
        EarnContract memory earnContract = earnContracts[_earnContractId];
        require(
            earnContract.status == ContractStatus.FORSALE,
            "Contract not for sale"
        );

        Bid memory bid = Bid(
            msg.sender, // bidder
            earnContract.owner, // to
            _earnContractId, // earnContractId
            _amount, // amount
            false // accepted
        );

        bids.push(bid);
        earnContractBidCount[_earnContractId] =
            earnContractBidCount[_earnContractId] +
            1; // increment the number of bids for the earn contract;

        // Send the bid amount to this contract
        _amount = _amount;
        AFN.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * Called by the owner of the earn contract for sale
     * Transfers the bid amount to the owner of the earn contract and transfers ownership of the contract to the bidder
     * @param _bidId index of bid in Bids
     */
    function acceptBid(uint256 _bidId) external {
        Bid memory bid = bids[_bidId];
        uint256 earnContractId = bid.earnContractId;

        uint256 fee = (bid.amount * transferFee) / 1000;
        if (fee > 0) {
            bid.amount = bid.amount - fee;
        }

        // Transfer bid AFN to contract seller
        require(
            msg.sender == earnContractToOwner[earnContractId],
            "Msg.sender is not the owner of the earn contract"
        );
        if (fee > 0) {
            AFN.safeTransfer(feeAddress, fee);
            bid.amount = bid.amount - fee;
        }
        AFN.safeTransfer(bid.to, bid.amount);

        bids[_bidId].accepted = true;

        // Transfer ownership of earn contract to bidder
        emit EarnContractOwnershipTransferred(
            bid.to,
            bid.bidder,
            earnContractId
        );
        earnContracts[earnContractId].owner = bid.bidder;
        earnContractToOwner[earnContractId] = bid.bidder;
        ownerEarnContractCount[bid.bidder] =
            ownerEarnContractCount[bid.bidder] +
            1;

        // Remove all bids
        _removeContractFromMarket(earnContractId);
    }

    /**
     * Remove Contract From Market
     * @param _earnContractId index of earn contract in earnContracts
     */
    function removeContractFromMarket(uint256 _earnContractId) external {
        require(
            earnContractToOwner[_earnContractId] == msg.sender,
            "Msg.sender is not the owner of the earn contract"
        );
        _removeContractFromMarket(_earnContractId);
    }

    /**
     * Removes all contracts bids and sets the status flag back to open
     * @param _earnContractId index of earn contract in earnContracts
     */
    function _removeContractFromMarket(uint256 _earnContractId) internal {
        earnContracts[_earnContractId].status = ContractStatus.OPEN;
        _removeAllContractBids(_earnContractId);
    }

    /**
     * Getter functions for all bids of a specified earn contract
     * @param _earnContractId index of earn contract in earnContracts
     */
    function getBidsByContract(uint256 _earnContractId)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](
            earnContractBidCount[_earnContractId]
        );
        uint256 counter = 0;
        for (uint256 i = 0; i < bids.length; i++) {
            if (bids[i].earnContractId == _earnContractId) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    /**
     * Sends all bid funds for an earn contract back to the bidder and removes them arrays and mappings
     * @param _earnContractId index of earn contract in earnContracts
     */
    function _removeAllContractBids(uint256 _earnContractId) internal {
        uint256[] memory contractBids = getBidsByContract(_earnContractId);
        for (uint256 i = 0; i < contractBids.length; i++) {
            uint256 bidId = contractBids[0];
            Bid memory bid = bids[bidId];
            if (bid.accepted != true) {
                AFN.safeTransfer(bid.bidder, bid.amount);
            }
            _removeBid(bidId);
        }
    }

    /**
     * Sends bid funds back to bidder and removes the bid from the array
     * @param _bidId index of bid in Bids
     */
    function removeBid(uint256 _bidId) external {
        Bid memory bid = bids[_bidId];
        require(msg.sender == bid.bidder, "Msg.sender is not the bidder");
        AFN.safeTransfer(bid.bidder, bid.amount);

        _removeBid(_bidId);
    }

    // TODO: Test that the mappings and arrays are updated correctly
    /**
     * @param _bidId index of bid in Bids
     */
    function _removeBid(uint256 _bidId) internal {
        require(_bidId < bids.length, "Bid ID longer than array length");
        Bid memory bid = bids[_bidId];

        // Update the mappings
        uint256 earnContractId = bid.earnContractId;
        if (earnContractBidCount[earnContractId] > 0) {
            earnContractBidCount[earnContractId] =
                earnContractBidCount[earnContractId] -
                1;
        }

        // Update the array
        if (bids.length > 1) {
            bids[_bidId] = bids[bids.length - 1];
        }
        bids.pop();
    }

    /**
     * Set the lower bound USDC amount needed to receive the respective AFN amounts
     * @param _highTier Minimum usdc amount needed to qualify for earn contract high tier
     * @param _medTier Minimum usdc amount needed to qualify for earn contract medium tier
     * @param _lowTier Minimum usdc amount needed to quallify for earn contract low tier
     */
    function setAfnContractTiers(
        uint256 _highTier,
        uint256 _medTier,
        uint256 _lowTier
    ) external onlyOwner {
        highTier = _highTier; // initially $150k
        medTier = _medTier; // initially $100k
        lowTier = _lowTier; // initially $50k
    }

    /**
     * Set the transfer fee rate for contracts sold on the market place
     * @param _transferFee Percent of accepted earn contract bid to be sent to AltaFin wallet
     */
    function setTransferFee(uint256 _transferFee) external onlyOwner {
        transferFee = _transferFee;
    }

    /**
     * Set the Bonus USDC multiplier ( e.g. 20 = 2x multiplier on the interest rate)
     * @param _baseBonusMultiplier Base Bonus multiplier for contract left open after contract length completion
     */
    function setBaseBonusMultiplier(uint256 _baseBonusMultiplier)
        external
        onlyOwner
    {
        baseBonusMultiplier = _baseBonusMultiplier;
    }

    /**
     * Set the Bonus AFN multiplier ( e.g. 20 = 2x multiplier on the AFN Amount)
     * @param _afnBonusMultiplier AFN Bonus multiplier for contract left open after contract length completion
     */
    function setAfnBonusMultiplier(uint256 _afnBonusMultiplier)
        external
        onlyOwner
    {
        afnBonusMultiplier = _afnBonusMultiplier;
    }

    /**
     * Set the loanAddress
     * @param _loanAddress Wallet address to recieve loan funds
     */
    function setLoanAddress(address _loanAddress) external onlyOwner {
        require(_loanAddress != address(0));
        loanAddress = _loanAddress;
    }

    /**
     * Set the feeAddress
     * @param _feeAddress Wallet address to recieve fee funds
     */
    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0));
        feeAddress = _feeAddress;
    }
}