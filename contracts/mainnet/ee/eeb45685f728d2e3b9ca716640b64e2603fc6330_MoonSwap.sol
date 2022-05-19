/**
 *Submitted for verification at polygonscan.com on 2022-05-18
*/

// File: contracts/interfaces/IFactory.sol



pragma solidity 0.8.9;

interface IFactory
{
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
// File: contracts/interfaces/IRouter.sol



pragma solidity 0.8.9;

interface IUniRouterV1
{
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniRouterV2 is IUniRouterV1
{
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/*
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

// File: @openzeppelin/contracts/security/Pausable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// File: contracts/interfaces/IToken.sol



pragma solidity 0.8.9;


interface IToken is IERC20
{
	function decimals() external view returns (uint8);	
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
}
// File: contracts/interfaces/IWrappedCoin.sol



pragma solidity 0.8.9;


interface IWrappedCoin is IToken
{
	function deposit() external payable;
    function withdraw(uint256 _amount) external;
}
// File: contracts/interfaces/ITokenPair.sol



pragma solidity 0.8.9;


interface ITokenPair is IToken
{	
	function token0() external view returns (address);
	
	function token1() external view returns (address);
	
	function getReserves() external view returns (uint112, uint112, uint32);	
}
// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol



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

// File: contracts/libs/RouterSwap.sol



pragma solidity ^0.8.0;




contract RouterSwap
{
    //========================
    // LIBS
    //========================

    using SafeERC20 for IToken;

    //========================
    // STRUCTS
    //========================

    struct SwapResult
    {
        uint256 fromBefore;
        uint256 toBefore;
        uint256 toAfter;
        uint256 swapped;
    }

    //========================
    // FUNCTIONS
    //========================

    function swapTokens(uint256 _amountIn, uint256 _amountOutMin, IUniRouterV2 _router, address[] memory _path) internal returns (SwapResult memory)
    {
        //init
        IToken from = IToken(_path[0]);
        IToken to = IToken(_path[_path.length - 1]);
        SwapResult memory result = SwapResult(
        {
            fromBefore: from.balanceOf(address(this)),
            toBefore: to.balanceOf(address(this)),
            toAfter: 0,
            swapped: 0
        });

        //swap
        from.safeApprove(address(_router), 0);
        from.safeApprove(address(_router), type(uint256).max);
        _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            _amountOutMin,
            _path,
            address(this),
            block.timestamp
        );

        //process
        result.toAfter = to.balanceOf(address(this));
        result.swapped = result.toAfter - result.toBefore;

        return result;
    }
}
// File: contracts/MoonSwap.sol



pragma solidity ^0.8.0;











contract MoonSwap is Ownable, Pausable, RouterSwap
{
    //========================
    // LIBS
    //========================

    using SafeERC20 for IToken;
    using SafeERC20 for ITokenPair;
    using SafeERC20 for IWrappedCoin;
    using Address for address payable;

    //========================
    // STRUCTS
    //========================

    struct RouterSwapInfo
    {
        IUniRouterV2 router;
        address[] path;
    }

    struct MoonSwapInfo
    {        
        uint256 amountIn;
        uint256 minEarned;
        RouterSwapInfo swapFrom;
        RouterSwapInfo swapTo;
    }

    //========================
    // EVENTS
    //========================

    event MoonSwapETH(address indexed _user, IToken indexed _token, IUniRouterV2 _routerFrom, IUniRouterV2 _routerTo, uint256 _minEarned, uint256 _earned);
    event MoonSwapToken(address indexed _user, IToken indexed _tokenFrom, IToken indexed _tokenTo, IUniRouterV2 _routerFrom, IUniRouterV2 _routerTo, uint256 _minEarned, uint256 _earned);

    //========================
    // CREATE
    //========================

    constructor()
    {
    }

    //========================
    // SWAP FUNCTIONS
    //========================

    function swapETH(IToken _tokenTo, IUniRouterV2 _routerFrom, IUniRouterV2 _routerTo, uint256 _minEarned) external payable returns (uint256)
    {
        //init
        IWrappedCoin wETH = IWrappedCoin(_routerFrom.WETH());

        //wrap
        wETH.deposit{ value: msg.value }();
        
        //swap
        (uint256 swapped, uint256 earned) = swap(
            msg.value,
            _minEarned,
            wETH,
            _tokenTo,
            _routerFrom,
            _routerTo
        );

        //wrap
        wETH.withdraw(swapped);

        //transfer
        payable(msg.sender).sendValue(swapped);

        //event
        emit MoonSwapETH(msg.sender, _tokenTo, _routerFrom, _routerTo, _minEarned, earned);

        return earned;
    }

    function swapToken(uint256 _amountIn, IToken _tokenFrom, IToken _tokenTo, IUniRouterV2 _routerFrom, IUniRouterV2 _routerTo, uint256 _minEarned) external returns (uint256)
    {        
        //swap
        (uint256 swapped, uint256 earned) = swap(
            _amountIn,
            _minEarned,
            _tokenFrom,
            _tokenTo,
            _routerFrom,
            _routerTo
        );

        //transfer
        _tokenFrom.safeTransfer(msg.sender, swapped);

        //event
        emit MoonSwapToken(msg.sender, _tokenFrom, _tokenTo, _routerFrom, _routerTo, _minEarned, earned);

        return earned;
    }

    //========================
    // SWAP INFO FUNCTIONS
    //========================

    function getSwapRouteOuts(uint256 _in, IUniRouterV2 _from, address[] memory _fromPath, IUniRouterV2 _to, address[] memory _toPath) public view returns (uint256, uint256)
    {
        uint256 fromTo = getSwapRouteOut(
            _in,
            _from,
            _fromPath,
            _to,
            _toPath
        );
        uint256 toFrom = getSwapRouteOut(
            _in,
            _to,
            reverseSwapPath(_toPath),
            _from,
            reverseSwapPath(_fromPath)
        );

        return (fromTo, toFrom);
    }

    function getSwapRouteOut(uint256 _in, IUniRouterV2 _from, address[] memory _fromPath, IUniRouterV2 _to, address[] memory _toPath) public view returns (uint256)
    {
        //check
        require(_fromPath[0] == _toPath[_toPath.length - 1], "Start != End");
        require(_fromPath[_fromPath.length - 1] == _toPath[0], "Pathes not connected");

        //get estimated out from => to
        uint256 fromOut = getSwapOut(_from, _fromPath, _in);
        uint256 toOut = getSwapOut(_to, _toPath, fromOut);

        return toOut;
    }

    function getSwapOut(IUniRouterV2 _router, address[] memory _path, uint256 _in) private view returns (uint256)
    {
        uint256[] memory outs = _router.getAmountsOut(_in, _path);
        return outs[outs.length - 1];
    }

    //========================
    // HELPER FUNCTIONS
    //========================

    receive() external payable {}  

    function swap(uint256 _amountIn, uint256 _minEarned, IToken _tokenFrom, IToken _tokenTo, IUniRouterV2 _routerFrom, IUniRouterV2 _routerTo) private returns (uint256, uint256)
    {
        IWrappedCoin wETH = IWrappedCoin(_routerFrom.WETH());
        
        //swap
        return swap(MoonSwapInfo(
        {
            amountIn: _amountIn,
            minEarned: _minEarned,
            swapFrom: RouterSwapInfo(
            {
                router: _routerFrom,
                path: makeSwapPath(wETH, _tokenFrom, _tokenTo)
            }),
            swapTo: RouterSwapInfo(
            {
                router: _routerTo,
                path: makeSwapPath(wETH, _tokenTo, _tokenFrom)
            })
        }));
    }

    function swap(MoonSwapInfo memory _swapInfo) private returns (uint256, uint256)
    {
        //init
        uint256 estimatedOut = getSwapRouteOut(
            _swapInfo.amountIn,
            _swapInfo.swapFrom.router,
            _swapInfo.swapFrom.path,
            _swapInfo.swapTo.router,
            _swapInfo.swapTo.path
        );

        //check estimate
        require(estimatedOut >= _swapInfo.amountIn, "Estimated swap would cause loss");
        require(estimatedOut - _swapInfo.amountIn >= _swapInfo.minEarned, "Estimated profit to small");

        //swap from => to
        RouterSwap.SwapResult memory swapFromResult = swapTokens(
            _swapInfo.amountIn,
            0,
            _swapInfo.swapFrom.router,
            _swapInfo.swapFrom.path);

        //swap to => from
        RouterSwap.SwapResult memory swapToResult = swapTokens(
            swapFromResult.swapped,
            0,
            _swapInfo.swapTo.router,
            _swapInfo.swapTo.path);         
            
        //check estimate
        require(estimatedOut == swapToResult.swapped, "Estimate different from reality");

        //check profits                    
        require(swapToResult.swapped > _swapInfo.amountIn, "Swap would cause loss");
        uint256 earned = swapToResult.swapped - _swapInfo.amountIn;
        require(earned >= _swapInfo.minEarned, "Profit to small");         

        return (swapToResult.swapped, earned);
    }

    function reverseSwapPath(address[] memory _path) private pure returns (address[] memory)
    {
        address[] memory pathReversed = new address[](_path.length);
        for (uint256 n = 0; n < _path.length; n++)
        {
            pathReversed[n] = _path[_path.length - 1 - n];
        }
        return pathReversed;
    }

    function makeSwapPath(IWrappedCoin _wETH, IToken _from, IToken _to) private pure returns (address[] memory)
	{
	    address[] memory path;
		if (_from == _wETH
			|| _to == _wETH)
		{
            //direct
			path = new address[](2);
			path[0] = address(_from);
			path[1] = address(_to);
		}
		else
		{
            //indirect over wrapped coin
			path = new address[](3);
			path[0] = address(_from);
			path[1] = address(_wETH);
			path[2] = address(_to);
		}
		
		return path;
	}

    //========================
    // SECURITY FUNCTION
    //========================

    function adminEmergencyWithdrawETH() external onlyOwner
    {
        uint256 balance = address(this).balance;
        payable(msg.sender).sendValue(balance);
    }

    function adminEmergencyWithdrawToken(IToken _token) external onlyOwner
    {
        uint256 balance = _token.balanceOf(address(this));
        _token.safeTransfer(msg.sender, balance);
    }

    function pause() external onlyOwner
    {
        _pause();
    }

    function unpause() external onlyOwner
    {
        _unpause();
    }
}