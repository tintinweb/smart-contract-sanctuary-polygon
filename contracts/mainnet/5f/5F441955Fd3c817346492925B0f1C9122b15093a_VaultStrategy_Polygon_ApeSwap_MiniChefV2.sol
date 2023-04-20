/**
 *Submitted for verification at polygonscan.com on 2023-04-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

//File: [IMiniChefV2_Polygon_ApeSwap.sol]

interface IMiniChefV2_Polygon_ApeSwap
{    
    function poolInfo(uint256 _pid) external view returns (uint128, uint64, uint64);	
	
	function lpToken(uint256 _pid) external view returns (address);	
	
	function userInfo(uint256 _pid, address _user) external view returns (uint256);

    function pendingBanana(uint256 _pid, address _user) external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount, address _to) external;

    function withdraw(uint256 _pid, uint256 _amount, address _to) external;
	
	function withdrawAndHarvest(uint256 _pid, uint256 _amount, address _to) external;

    function emergencyWithdraw(uint256 _pid, address _to) external;
}

//File: [Address.sol]

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

//File: [IMigrationManager.sol]

interface IMigrationManager
{
    //========================
    // MIGRATION FUNCTIONS
    //========================

    function requestMigration(address _user, string memory _topic) external returns (uint256);
    function cancelMigration(address _user, uint256 _id) external;
    function executeMigration(address _user, uint256 _id) external returns (bool);
}

//File: [IRouter.sol]

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

//File: [IERC20.sol]

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

//File: [IToken.sol]

interface IToken
{
	//========================
    // EVENTS FUNCTIONS
    //========================

	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

	//========================
    // INFO FUNCTIONS
    //========================
	
	function decimals() external view returns (uint8);	
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
	function totalSupply() external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);

	//========================
    // USER INFO FUNCTIONS
    //========================

    function balanceOf(address account) external view returns (uint256);

    //========================
    // TRANSFER / APPROVE FUNCTIONS
    //========================

    function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);    
    function approve(address spender, uint256 amount) external returns (bool);
}

//File: [ML_TransferETH.sol]

contract ML_TransferETH
{
    //========================
    // ATTRIBUTES
    //======================== 

    uint256 public transferGas = 30000;

    //========================
    // CONFIG FUNCTIONS
    //======================== 

    function _setTransferGas(uint256 _gas) internal
    {
        require(_gas >= 30000, "Gas to low");
        require(_gas <= 250000, "Gas to high");
        transferGas = _gas;
    }

    //========================
    // TRANSFER FUNCTIONS
    //======================== 

    function transferETH(address _to, uint256 _amount) internal
    {
        (bool success, ) = payable(_to).call{ value: _amount, gas: transferGas }("");
        success; //prevent warning
    }
}

//File: [IRouterSwap.sol]

contract IRouterSwap
{
    //========================
    // STRUCTS
    //========================

    struct SwapResult
    {
        uint256 fromBefore;     //balance of from-token, before swap
        uint256 toBefore;       //balance of to-token, before swap
        uint256 toAfter;        //balance of to-token, after swap
        uint256 swapped;        //swapped amount of to-token
    }
}

//File: [ITokenPair.sol]

interface ITokenPair is IToken
{	
	//========================
    // INFO FUNCTIONS
    //========================
	
	function token0() external view returns (address);	
	function token1() external view returns (address);	
	function getReserves() external view returns (uint112, uint112, uint32);	
}

//File: [IWrappedCoin.sol]

interface IWrappedCoin is IToken
{
	function deposit() external payable;
    function withdraw(uint256 _amount) external;
}

//File: [IBank.sol]

interface IBank
{  
    //========================
    // USER INFO FUNCTIONS
    //========================

    function balanceOf(IToken _token, address _user) external view returns (uint256);
    function allowance(IToken _token, address _user, address _spender) external view returns (uint256);
    
    //========================
    // DEPOSIT FUNCTIONS
    //========================

    function depositETHFor(address _user) external payable;
    function depositFor(IToken _token, address _user, uint256 _amount) external;

    //========================
    // TRANSFER FUNCTIONS
    //========================

    function transfer(IToken _token, address _from, address _to, uint256 _amount) external;
    function transferToAccount(IToken _token, address _from, address _to, uint256 _amount) external;

    //========================
    // ALLOWANCE FUNCTIONS
    //========================

    function approve(IToken _token, address _spender, uint256 _amount) external;
    function increaseAllowance(IToken _token, address _spender, uint256 _amount) external;
    function decreaseAllowance(IToken _token, address _spender, uint256 _amount) external;
}

//File: [ML_MakeSwapPath.sol]

contract ML_MakeSwapPath
{
    //========================
    // SWAP INFO FUNCTIONS
    //========================

    function makeSwapPath(IToken _from, IToken _to, IToken _swapOver) internal pure returns (address[] memory)
	{
	    address[] memory path;
		if (_from == _swapOver
			|| _to == _swapOver
            || address(_swapOver) == address(0))
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
			path[1] = address(_swapOver);
			path[2] = address(_to);
		}
		
		return path;
	}
}

//File: [SafeERC20.sol]

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

//File: [IVaultPoolInfo.sol]

interface IVaultPoolInfo
{
    //========================
    // POOL INFO FUNCTIONS
    //========================

    function depositToken() external view returns (IToken);
    function rewardToken() external view returns (IToken);

    function poolCompoundReward() external view returns (uint256);
    function poolPending() external view returns (uint256);
    function poolAllocPoints() external view returns (uint256);
    function poolTotalAllocPoints() external view returns (uint256);        
    function poolRewardEmission() external view returns (uint256);
    function poolTotalRewardEmission() external view returns (uint256);

    function poolBlockOrTime() external view returns (bool);
    function poolDepositFee() external view returns (uint256);
    function poolWithdrawFee() external view returns (uint256); 
    function poolStart() external view returns (uint256);
    function poolEnd() external view returns (uint256);
    function poolHarvestLockUntil() external view returns (uint256);
    function poolHarvestLockDelay() external view returns (uint256);

    function isPoolFarmable() external view returns (bool);
}

//File: [IVaultConfig.sol]

interface IVaultConfig
{
    //========================
    // CONSTANTS
    //========================

    function PERCENT_FACTOR() external view returns (uint256);

    //========================
    // ATTRIBUTES
    //========================
    
    //fees
    function rewardFeeReceiver() external view returns (address);
    function compoundFee() external view returns (uint256);
    function rewardFee() external view returns (uint256);
    function withdrawFee() external view returns (uint256);
    function withdrawFeePeriod() external view returns (uint256);

    //contracts
    function migrationManager() external view returns (IMigrationManager);
    function bank() external view returns (IBank);
    function payoutManager() external view returns (address);

    //tokens
    function wrappedCoin() external view returns (IWrappedCoin);
    function stableCoin() external view returns (IToken);

    //deposit/withdraw logic
    function autoCompound() external view returns (bool);
}

//File: [VaultStrategy_withPoolInfo.sol]

///@notice This contract defines the interface for all pool info
abstract contract VaultStrategy_withPoolInfo is
    IVaultPoolInfo
{
    //========================
    // REQUIRED POOL INFO FUNCTIONS
    //========================

    ///@return Total reward for compounding in ETH (sum of all pending rewards => ETH)
    function poolCompoundReward() external view virtual override returns (uint256)
    {
        return 0;
    }

    ///@return Pending reward
    function poolPending() external view virtual override returns (uint256)
    {
        return 0;
    }    

    ///@return Total alloc points of the chef
    function poolTotalAllocPoints() public view virtual override returns (uint256)
    {
        return 1;
    }

    ///@return Alloc points of utilized pool
    function poolAllocPoints() public view virtual override returns (uint256)
    {
        return 1;
    }

    ///@return Chef total reward emission
    function poolTotalRewardEmission() public view virtual override returns (uint256)
    {
        return 1;
    }

    //========================
    // OPTIONAL POOL INFO FUNCTIONS
    //========================

    ///@return Are rewards given out per block (false) or per second (true)
    function poolBlockOrTime() public view virtual override returns (bool)
    {
        return false; //block
    }

    ///@return Pool deposit fee
    function poolDepositFee() external view virtual override returns (uint256)
    {
        return 0;
    }

    ///@return Pool withdraw fee
    function poolWithdrawFee() external view virtual override returns (uint256)
    {
        return 0;
    }

    ///@return Start time of pool/chef
    function poolStart() public view virtual override returns (uint256)
    {
        return 0;
    }

    ///@return End time of pool/chef
    function poolEnd() public view virtual override returns (uint256)
    {
        return 0;
    }

    ///@return Harvest lock until timestamp (lastHarvestTimestamp + harvestLockDelay)
    function poolHarvestLockUntil() external view virtual override returns (uint256)
    {
        return 0;
    }

    ///@return Horvest lock delay time
    function poolHarvestLockDelay() external view virtual override returns (uint256)
    {
        return 0;
    }

    //========================
    // STATIC POOL INFO FUNCTIONS
    //========================

    ///@return Is farming still possible for pool
    function isPoolFarmable() external view virtual override returns (bool)
    {
        //TODO: check ALL reward sources
        uint256 current = (poolBlockOrTime()
            ? block.timestamp
            : block.number
        );
        return (poolAllocPoints() > 0           //reward share
            && current >= poolStart()           //after start
            && (poolEnd() == 0                  //before end
                || current < poolEnd())
            && poolTotalRewardEmission() > 0    //has emission
        );
    }

    ///@return Pool reward share for main reward
    function poolRewardEmission() external view virtual override returns (uint256)
    {
        return (poolTotalAllocPoints() * poolAllocPoints()) / poolTotalAllocPoints();
    }
}

//File: [ML_RecoverFunds.sol]

contract ML_RecoverFunds is ML_TransferETH
{
    //========================
    // LIBS
    //========================

    using SafeERC20 for IERC20;

    //========================
    // EMERGENCY FUNCTIONS
    //======================== 

    function _recoverETH(uint256 _amount, address _to) internal
    {
        transferETH(_to, _amount);
    }

    function _recoverToken(IToken _token, uint256 _amount, address _to) internal
    {
        IERC20(address(_token)).safeTransfer(_to, _amount);
    }  
}

//File: [ML_TransferHelper.sol]

contract ML_TransferHelper
{
    //========================
    // LIBS
    //========================

    using SafeERC20 for IERC20;

    //========================
    // STRUCTS
    //========================

    struct TransferResult
    {
        uint256 fromBefore;     //balance of from-token, before transfer
        uint256 toBefore;       //balance of token, before transfer
        uint256 toAfter;        //balance of token, after transfer
        uint256 transferred;    //transferred amount 
    }

    //========================
    // FUNCTIONS
    //========================

    function safeTransferFrom(
        IToken _token,
        uint256 _amount,
        address _from,
        address _to
    ) internal returns (TransferResult memory)
    {
        //init
        TransferResult memory result = TransferResult(
        {
            fromBefore: _token.balanceOf(_from),
            toBefore: _token.balanceOf(_to),
            toAfter: 0,
            transferred: 0
        });

        //transfer
        IERC20(address(_token)).safeTransferFrom(
            _from, 
            _to, 
            _amount
        );

        //process
        result.toAfter = _token.balanceOf(_to);
        result.transferred = result.toAfter - result.toBefore;

        return result;
    }

    function safeTransfer(
        IToken _token,
        uint256 _amount,
        address _to
    ) internal returns (TransferResult memory)
    {
        //init
        TransferResult memory result = TransferResult(
        {
            fromBefore: _token.balanceOf(msg.sender),
            toBefore: _token.balanceOf(_to),
            toAfter: 0,
            transferred: 0
        });

        //transfer
        IERC20(address(_token)).safeTransfer(
            _to, 
            _amount
        );

        //process
        result.toAfter = _token.balanceOf(_to);
        result.transferred = result.toAfter - result.toBefore;

        return result;
    }

    function safeApprove(IToken _token, address _spender, uint256 _amount) internal
    {
        _token.approve(_spender, 0); //first reset to 0 to be safe
        if (_amount != 0)
        {
            _token.approve(_spender, _amount);
        }
    }
}

//File: [ML_RouterSwap_UniSwapV2.sol]

contract ML_RouterSwap_UniSwapV2 is
    IRouterSwap,
    ML_TransferHelper
{
    //========================
    // LIBS
    //========================

    using SafeERC20 for IToken;

    //========================
    // FUNCTIONS
    //========================

    function swapTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _router,
        address[] memory _path,
        address _to
    ) internal returns (SwapResult memory)
    {
        //init
        IToken from = IToken(_path[0]);
        IToken to = IToken(_path[_path.length - 1]);
        SwapResult memory result = SwapResult(
        {
            fromBefore: from.balanceOf(address(this)),
            toBefore: to.balanceOf(_to),
            toAfter: 0,
            swapped: 0
        });

        //swap
        safeApprove(from, address(_router), _amountIn);
        IUniRouterV2(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            _amountOutMin,
            _path,
            _to,
            block.timestamp
        );

        //process
        result.toAfter = to.balanceOf(_to);
        result.swapped = result.toAfter - result.toBefore;

        return result;
    }
}

//File: [IVault.sol]

interface IVault
{
    function config() external view returns (IVaultConfig);  

    function userRemainingWithdrawFeeTime(address _user) external view returns (uint256);
}

//File: [IVaultStrategy.sol]

interface IVaultStrategy is
    IVaultPoolInfo
{
    //========================
    // ATTRIBUTES
    //========================

    function vault() external view returns (IVault);

    //========================
    // POOL INFO FUNCTIONS
    //========================

    function balanceOf() external view returns (uint256);
    function rewardsContainsDepositToken() external view returns (bool);

    //========================
    // DEPOSIT / WITHDRAW FUNCTIONS / COMPOUND
    //========================

    function deposit() external returns (uint256);
    function withdraw(address _user, uint256 _amount) external returns (uint256);
    function compound(address _user) external returns (bool);

    //========================
    // STRATEGY FUNCTIONS
    //========================

    function retireStrategy(IVaultStrategy _newStrategy) external;  
}

//File: [VaultStrategy_base.sol]

abstract contract VaultStrategy_base is
    IVaultStrategy
{
    //========================
    // STRUCTS
    //========================

    struct SwapPath
    {
        address router; //router to use for swap
        address[] path; //only the inbetween path
    }

    struct Reward
    {
        IToken token; //utilized token
        SwapPath swap; //swap path to swap token to mainReward
    }

    //========================
    // ATTRIBUTES
    //========================

    //base
    IVault public immutable override vault; //parent vault
    IToken public override depositToken; //deposit token    

    //rewards
    Reward[] public rewards; //reward (at least 1)
    mapping(uint256 => SwapPath) public rewardToDepositTokenChild; //reward => depositChild
    SwapPath public rewardToETH; //path to convert reward to ETH

    //harvest / compound
    uint256 public lastHarvestBlock; //timestamp of last harvest

    //========================
    // EVENTS
    //========================

    event Compound(
        address indexed _user,
        uint256 _totalDepositBefore,
        uint256 _totalDepositAfter,
        uint256 _reward,
        uint256 _dust
    );

    //========================
    // CREATE
    //========================

    constructor(IVault _vault)
    {
        vault = _vault;
    }

    //========================
    // CONFIG FUNCTIONS
    //========================

    ///@notice path to convert main reward to ETH (for price oracle)
    function setRewardToETHSwapPath(SwapPath memory _swapPath) external
    {
        rewardToETH = _swapPath;
    }

    ///@notice remove rewards (except main reward)
    function removeReward(uint256 _index) external
    {
        //check
        requireValidRewardIndex(_index);
        require(_index == 0, "Can't delete main reward");

        //clone
        if (_index != rewards.length - 1)
        {
            rewards[_index] = rewards[rewards.length - 1];
        }        

        //remove
        rewards.pop();        
    }

    ///@notice add a reward
    function addReward(Reward memory _reward) public
    {
        //check
        require((rewards.length != 0
                || _reward.swap.path.length == 0
            ),
            "Main reward can't have path"
        );

        //add
        rewards.push(_reward);
    }    

    ///@notice set path of additional rewards to main reward
    function setRewardSwapPath(uint256 _index, SwapPath memory _swapPath) external
    {
        //check
        requireValidRewardIndex(_index);
        require((_index != 0
                || _swapPath.path.length == 0
            ),
            "Main reward can't have path"
        );

        //set
        rewards[_index].swap = _swapPath;
    }

    ///@notice set reward to deposit token child path
    function setRewardToDepositTokenChild(uint256 _index, SwapPath memory _swapPath) public 
    {
        //check
        require((_index < getDepositTokenChildLength()
                || (_index == 0
                    && getDepositTokenChildLength() == 0)
            ),
            "Invalid deposit token child"
        );

        //set
        rewardToDepositTokenChild[_index] = _swapPath;
    }

    function _setRewardToDepositTokenChild(uint256 _index, address _router) internal 
    {
        address[] memory path;
        setRewardToDepositTokenChild(
            _index,
            SwapPath(
            {
                router: _router,
                path: path
            })
        );
    }

    //========================
    // POOL INFO FUNCTIONS
    //========================

    ///@return Main reward token
    function rewardToken() public view override returns (IToken)
    {
        return rewards[0].token;
    }

    function additionalRewardToken(uint256 _index) public view returns (IToken)
    {
        return rewards[_index].token;
    }    

    function rewardsLength() external view returns (uint256)
    {
        return rewards.length;
    }

    //========================
    // INFO FUNCTIONS
    //========================    

    ///@return Balance of main reward
    function balanceOfReward() public view returns (uint256)
    {
        return rewardToken().balanceOf(address(this));
    }

    ///@return Balance of main reward
    function balanceOfAdditionalReward(uint256 _index) public view returns (uint256)
    {
        return additionalRewardToken(_index).balanceOf(address(this));
    }

    ///@return Balance of deposit token
    function balanceOfStrategy() public view returns (uint256)
    {
        return depositToken.balanceOf(address(this));
    }

    ///@return Is one of the rewards = deposit token
    function rewardsContainsDepositToken() external view override returns (bool)
    {
        for (uint256 n = 0; n < rewards.length; n++)
        {
            if (rewards[n].token == depositToken)
            {
                return true;
            }
        }
        return false;
    }

    function getRewardToDepositTokenChild(
        uint256 _index
    ) external view returns(
        address router,
        address[] memory path
    )
    {
        return (
            rewardToDepositTokenChild[_index].router,
            rewardToDepositTokenChild[_index].path
        );
    }

    //========================
    // INFO FUNCTIONS (OVERRIDE in extension:deposit)
    //========================

    ///@notice Depending on deposit extension, it returns the child tokens, for example token0/token1 from an LP
    ///@return Child token of the deposit token    
    function getDepositTokenChild(uint256 _index) public view virtual returns (address)
    {        
        if (_index == 0
            && getDepositTokenChildLength() == 0)
        {
            return address(depositToken);
        }
        return address(0);
    }

    ///@notice Depending on deposit extension, it returns how many children the deposit token hast
    ///@return Number of child tokens from deposit token
    function getDepositTokenChildLength() public view virtual returns (uint256)
    {
        return 0;
    }

    //========================
    // SWAP FUNCTIONS
    //========================

    ///@notice convert main reward => deposit
    function swapRewardToDeposit() internal virtual
    {
        //check if swap required
        if (rewardToken() == depositToken)
        {
            return;
        }

        //swap reward to deposit
        swap(
            balanceOfReward(),
            rewards[0].swap.router,
            createSwapPath(
                address(rewardToken()),
                address(depositToken),
                rewards[0].swap.path
            )
        );
    }

    function swapAdditionalRewardToReward(uint256 _index) internal
    {
        //check if swap required
        address tokenFrom = address(additionalRewardToken(_index));
        if (_index == 0
            || tokenFrom == address(depositToken)
            || tokenFrom == address(rewardToken()))
        {
            return;
        }

        //swap reward to deposit
        swap(
            balanceOfAdditionalReward(_index),
            rewards[_index].swap.router, 
            createSwapPath(
                tokenFrom,
                address(rewardToken()),
                rewards[_index].swap.path
            )
        );
    }

    ///@notice convert main reward => depositTokenChild
    function swapRewardToDepositTokenChild(uint256 _index, uint256 _amount) internal
    {
        //check if swap required
        address depositTokenChild = getDepositTokenChild(_index);
        if (address(rewardToken()) == depositTokenChild)
        {
            return;
        }
        
        //swap reward to deposit
        swap(
            _amount,
            rewards[0].swap.router, 
            createSwapPath(
                address(rewardToken()),
                depositTokenChild,
                rewards[0].swap.path
            )
        );
    }

    //========================
    // 3rd PARTY FUNCTIONS
    //========================

    function swap(uint256 _amount, address _router, address[] memory _path) internal virtual;

    //========================
    // HELPER FUNCTIONS
    //========================

    function createSwapPath(
        address _start, 
        address _end, 
        address[] memory _path
    ) internal pure returns (address[] memory)
    {
        address[] memory fullPath = new address[](2 + _path.length);

        //fill
        fullPath[0] = _start;
        for (uint256 n = 0; n < _path.length; n++)
        {
            fullPath[n + 1] = _path[n];
        }        
        fullPath[fullPath.length - 1] = _end;

        return fullPath;
    }
    
    function createSwapPath(
        address _start, 
        address _end
    ) internal pure returns (address[] memory)
    {
        address[] memory path;
        return createSwapPath(
            _start, 
            _end, 
            path
        );
    }

    function createReward(
        IToken _token, 
        address _router, 
        address[] memory _path
    ) internal pure returns (Reward memory)
    {
        return Reward(
            {
                token: _token,
                swap: SwapPath(
                    {
                        router: _router,
                        path: _path
                    }
                )
            }
        );
    }

    function createReward(IToken _token, address _router) internal pure returns (Reward memory)
    {
        address[] memory path;
        return createReward(
            _token,
            _router,
            path
        );
    }

    function requireValidRewardIndex(uint256 _index) internal view
    {
        require(_index < rewards.length, "Invalid reward index");
    }
}

//File: [VaultStrategy_withPoolAccess.sol]

///@notice This contract defines the interface for pool interaction
abstract contract VaultStrategy_withPoolAccess is
    VaultStrategy_base
{
    //========================
    // ATTRIBUTES
    //========================

    //3rd party contracts
    address public poolProvider; //address of the pool contract
    uint256 public poolID; //ID of pool

    //========================
    // CREATE
    //========================

    constructor(IVault _vault, address _poolProvider, uint256 _poolID)
    VaultStrategy_base(_vault)
    {
        poolProvider = _poolProvider;
        poolID = _poolID;
    }

    //========================
    // POOL INFO FUNCTIONS
    //========================

    ///@return Balance of pool
    function balanceOfPool() public view virtual returns (uint256)
    {
        return 0;
    }

    //========================
    // OVERRIDE DEPOSIT / WITHDRAW / CLAIM FUNCTIONS
    //========================

    ///@notice Deposit into pool
    function poolDeposit(uint256 _amount) internal virtual
    {
        _amount; //hide warning
    }

    ///@notice Withdraw from pool
    function poolWithdraw(uint256 _amount) internal virtual
    {
        _amount; //hide warning
    }    

    ///@notice Emergency withdraw
    function poolEmergencyWithdraw() internal virtual
    {
        poolWithdraw(balanceOfPool());
    }

    ///@notice Harvest from pool
    function poolHarvest() internal virtual
    {
        poolWithdraw(0);
    }
}

//File: [VaultStrategy_withFees.sol]

///@notice This part only handles protocol fees
abstract contract VaultStrategy_withFees is
    VaultStrategy_base
{
    //========================
    // FEE FUNCTIONS
    //======================== 

    ///@notice Take withdraw fee and let it in pool
    ///@return _amount after fee is deducted
    function takeWithdrawFee(address _user, uint256 _amount) internal pure returns (uint256)
    {
        _user; //prevent warning
        return _amount; //not in Phase 1
        /*

        //check if withdraw fee period
        if (vault.userRemainingWithdrawFeeTime(_user) == 0)
        {
            return _amount;
        }

        //take withdraw fee
        uint256 withdrawFeeAmount = (_amount * vault.config().withdrawFee()) / vault.config().PERCENT_FACTOR();
        return _amount - withdrawFeeAmount;
        */
    }

    ///@notice Take reward fee and send it to compounder and reward distributor
    ///@return _amount after fee is deducted
    function takeRewardFee(address _compoundUser, uint256 _amount) internal pure returns (uint256)
    {
        _compoundUser; //prevent warning
        return _amount; //not in phase 1

        /*
        //check fee
        uint256 feeShare = vault.config().compoundFee();
        if (vault.config().rewardFeeReceiver() != address(0))
        {
            feeShare += vault.config().rewardFee();
        }

        //take reward fee
        uint256 rewardFeeAmount = (_amount * feeShare) / vault.config().PERCENT_FACTOR();
        if (rewardFeeAmount == 0)
        {
            return _amount;
        }

        //swap to ETH and unwrap
        uint256 rewardFeeETH = swapTokens(
            rewardFeeAmount,
            0,
            rewardToETH.router,
            rewardToETH.path,
            address(this)
        ).swapped;
        vault.config().wrappedCoin().withdraw(rewardFeeETH);

        //transfer to compounder & reward fee receiver     
        if (vault.config().compoundFee() > 0)
        {
            uint256 compoundFeeAmount = (rewardFeeAmount * vault.config().compoundFee()) / feeShare;
            transferETH(_compoundUser, compoundFeeAmount);
            rewardFeeETH -= compoundFeeAmount;            
        }        
        if (rewardFeeETH > 0)
        {
            transferETH(vault.config().rewardFeeReceiver(), rewardFeeETH);
        }

        return (_amount - rewardFeeAmount);
        */
    }
}

//File: [VaultStrategy.sol]

abstract contract VaultStrategyV2 is
    VaultStrategy_base,
    VaultStrategy_withPoolInfo,
    VaultStrategy_withPoolAccess,
    VaultStrategy_withFees,
    ML_MakeSwapPath,
    ML_RecoverFunds,
    ML_TransferHelper
{
    //========================
    // CREATE
    //========================

    constructor(
        IVault _vault,
        address _poolProvider,
        uint256 _poolID
    )
    VaultStrategy_withPoolAccess(
        _vault,
        _poolProvider,
        _poolID
    )
    {
        
    }

    //========================
    // INFO FUNCTIONS
    //========================

    ///@return Total balance of strategy + pool
    function balanceOf() external view override returns (uint256)
    {
        return balanceOfStrategy() + balanceOfPool();
    }

    //========================
    // DEPOSIT FUNCTIONS
    //========================    

    function deposit() public virtual override returns (uint256)
    {
        uint256 currentBalance = balanceOfStrategy();
        if (currentBalance > 0)
        {
            uint256 poolBalanceBeforeDeposit = balanceOfPool();

            //approve
            safeApprove(
                depositToken, 
                poolProvider, 
                currentBalance
            );

            //deposit into pool
            poolDeposit(currentBalance);

            //unapprove
            safeApprove(
                depositToken, 
                poolProvider, 
                0
            );

            //return the amount that pool received after taxes
            return balanceOfPool() - poolBalanceBeforeDeposit;
        }

        return 0;
    } 

    //========================
    // WITHDRAW FUNCTIONS
    //======================== 

    function withdraw(address _user, uint256 _amount) external virtual override returns (uint256)
    {
        //take withdraw fee
        uint256 amount = takeWithdrawFee(_user, _amount);

        //withdraw from pool
        (uint256 poolWithdrawAmount, uint256 receivedWithdraw) = withdrawFromPool(amount);

        //withdraw from strategy
        uint256 strategyWithdrawAmount = amount - poolWithdrawAmount; //remaining after tax
        uint256 userWithdrawAmount = strategyWithdrawAmount + receivedWithdraw; //actual withdraw for user
        return withdrawFromStrategy(_user, userWithdrawAmount);
    }

    function withdrawFromPool(uint256 _amount) internal virtual returns (uint256 poolWithdrawAmount, uint256 receivedWithdraw)
    {
        //check if not enough in strategy
        uint256 strategyBalanceBefore = balanceOfStrategy();
        if (strategyBalanceBefore < _amount)
        {
            //withdraw from pool
            poolWithdrawAmount = _amount - strategyBalanceBefore;
            poolWithdraw(poolWithdrawAmount);
            receivedWithdraw = balanceOfStrategy() - strategyBalanceBefore;
        }

        return (poolWithdrawAmount, receivedWithdraw);
    }

    function withdrawFromStrategy(address _user, uint256 _amount) internal virtual returns (uint256)
    {
        return safeTransfer(depositToken, _amount, _user).transferred;
    }

    //========================
    // COMPOUND FUNCTIONS
    //======================== 
    
    function harvest() internal virtual
    {        
        if (block.number != lastHarvestBlock)
        {
            poolHarvest();
            lastHarvestBlock = block.number;
        }
    }  

    function compound(address _user) external override returns (bool)
    {
        //harvest all rewards from pool
        harvest();

        //convert additional rewards into reward
        for (uint256 n = 1; n < rewards.length; n++)
        {
            swapAdditionalRewardToReward(n);
        }
        uint256 rewardBalance = balanceOfReward();

        if (rewardBalance > 0)
        {
            //take protocol fees
            takeRewardFee(_user, rewardBalance);

            //claim native reward
            //transferNativeRewardShare();

            //convert from reward to deposit token
            swapRewardToDeposit();
        }

        //deposit
        return (deposit() > 0);
    }

    //========================
    // SWAP FUNCTIONS
    //========================

    function transferNativeRewardShare() private
    {
        //check amount
        uint256 amount = balanceOfReward() / 2;
        if (amount == 0)
        {
            return;
        }

        //hard coded 50% reward into vault
        swap(
            amount,
            rewardToETH.router,
            createSwapPath(
                address(rewardToken()), 
                address(vault.config().wrappedCoin()),
                rewardToETH.path
            )
        );
    }

    //========================
    // HELPER FUNCTIONS
    //========================  

    receive() external payable {}

    //========================
    // STRATEGY MIGRATION FUNCTIONS
    //======================== 

    function retireStrategy(IVaultStrategy _newStrategy) external override
    {
        //check
        require(address(_newStrategy) != address(0), "Invalid new strategy");
        require(msg.sender == address(vault), "Not called by vault");
        require(depositToken == _newStrategy.depositToken(), "Deposit token mismatch");

        //emergency withdraw
        poolEmergencyWithdraw();

        //transfer to new strategy
        safeTransfer(
            depositToken,
            balanceOfStrategy(),
            address(_newStrategy)            
        );
    }

    //========================
    // EMERGENCY FUNCTIONS
    //======================== 

    function recoverETH(uint256 _amount, address _to) external
    {
        //TODO: check restrictions to prevent rug

        //recover
        _recoverETH(_amount, _to);        
    }

    function recoverToken(IToken _token, uint256 _amount, address _to) external
    {
        //TODO: check restrictions to prevent rug

        //recover
        _recoverToken(_token, _amount, _to);
    }  
}

//File: [VaultStrategy_deposit_LP.sol]

abstract contract VaultStrategy_deposit_LP is
    VaultStrategyV2
{
    //========================
    // ATTRIBUTES
    //========================

    bool public isLPToken; //use LP swap instead of direct
    address public routerForLP; //router used to add liquidity

    //========================
    // CREATE FUNCTIONS
    //========================

    constructor(
        IVault _vault,
        address _poolProvider,
        uint256 _poolID,
        bool _isLP,
        address _router
    )
    VaultStrategyV2(
        _vault,
        _poolProvider,
        _poolID
    )
    {
        isLPToken = _isLP;
        routerForLP = _router;
    }

    //========================
    // INFO FUNCTIONS (OVERRIDE in extension:deposit)
    //========================

    function getDepositTokenChild(uint256 _index) public view virtual override returns (address)
    {
        if (isLPToken)
        {
            if (_index == 0)
                return ITokenPair(address(depositToken)).token0();
            if (_index == 1)
                return ITokenPair(address(depositToken)).token1();
        }
        return super.getDepositTokenChild(_index);
    }

    function getDepositTokenChildLength() public view virtual override returns (uint256)
    {
        return (isLPToken ? 2 : 0);
    }

    //========================
    // SWAP FUNCTIONS
    //========================

    ///@dev Swap reward to token0/token1 and add liquidity
    function swapRewardToDeposit() internal virtual override
    {
        //check if swap required
        if (!isLPToken)
        {
            super.swapRewardToDeposit();
            return;
        }        
        uint256 halfReward = balanceOfReward() / 2;

        //swap reward to token0 (only swap balance - half)
        IToken token0 = IToken(getDepositTokenChild(0));        
        swapRewardToDepositTokenChild(0, balanceOfReward() - halfReward);

        //swap reward to token1
        IToken token1 = IToken(getDepositTokenChild(1));
        swapRewardToDepositTokenChild(1, halfReward);

        //add liquidity
        IUniRouterV2(routerForLP).addLiquidity(
            address(token0),
            address(token1),
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this)),
            1,
            1,
            address(this),
            block.timestamp
        );        
    }
}

//File: [VaultStrategy_swap_UniSwapV2.sol]

abstract contract VaultStrategy_swap_UniSwapV2 is
    VaultStrategyV2,
    ML_RouterSwap_UniSwapV2
{
    //========================
    // 3rd PARTY FUNCTIONS
    //========================

    function swap(uint256 _amount, address _router, address[] memory _path) internal virtual override
    {
        //swap
        swapTokens(
            _amount,
            0,
            _router,
            _path,
            address(this)
        );

        //unapprove
        safeApprove(
            IToken(_path[0]),
            address(_router),
            0
        );
    }
}

//File: [VaultStrategy_LP_UniSwapV2.sol]

abstract contract VaultStrategy_LP_UniSwapV2 is
    VaultStrategy_base,
    VaultStrategy_withPoolInfo,
    VaultStrategy_deposit_LP,
    VaultStrategy_swap_UniSwapV2
{
    //========================
    // INHERIT FUNCTIONS
    //========================

    ///@inheritdoc VaultStrategy_base
    function swapRewardToDeposit() internal override(VaultStrategy_base, VaultStrategy_deposit_LP)
    {
        super.swapRewardToDeposit();     
    }

    ///@inheritdoc VaultStrategy_base
    function getDepositTokenChild(uint256 _index) public view override(VaultStrategy_base, VaultStrategy_deposit_LP) returns (address)
    {        
        return super.getDepositTokenChild(_index);
    }

    ///@inheritdoc VaultStrategy_base
    function getDepositTokenChildLength() public view override(VaultStrategy_base, VaultStrategy_deposit_LP) returns (uint256)
    {
        return super.getDepositTokenChildLength(); 
    }
}

contract VaultStrategy_Polygon_ApeSwap_MiniChefV2 is
    IVaultPoolInfo,
    VaultStrategy_withPoolInfo,
    VaultStrategy_LP_UniSwapV2
{
    //========================
    // LIBS
    //========================

    using SafeERC20 for IToken;

    //========================
    // CONSTANTS
    //========================

    string public constant POOL_VERSION = "1.0.0";
    IToken private constant REWARD_TOKEN = IToken(0x5d47bAbA0d66083C52009271faF3F50DCc01023C);
    IToken private constant ADDITIONAL_REWARD_TOKEN = IToken(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address private constant MASTERCHEF = 0x54aff400858Dcac39797a81894D9920f16972D1D;
    address private constant ROUTER = 0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607;

    //========================
    // CREATE
    //========================

    constructor(
        IVault _vault,
        uint256 _poolID
    )
    VaultStrategy_deposit_LP(
        _vault,
        MASTERCHEF,
        _poolID,
        true,
        ROUTER
    )
    {
        //init      
        depositToken = IToken(IMiniChefV2_Polygon_ApeSwap(MASTERCHEF).lpToken(_poolID));
        addReward(createReward(REWARD_TOKEN, ROUTER));
        _setRewardToDepositTokenChild(0, ROUTER);   
        if (isLPToken)
        {
            _setRewardToDepositTokenChild(1, ROUTER);
        }    
    }    

    //========================
    // POOL INFO FUNCTIONS
    //========================

    function balanceOfPool() public view virtual override returns (uint256)
    {
        return IMiniChefV2_Polygon_ApeSwap(poolProvider).userInfo(poolID, address(this));
    }

    function poolPending() public view virtual override(IVaultPoolInfo, VaultStrategy_withPoolInfo) returns (uint256)
    {
        return IMiniChefV2_Polygon_ApeSwap(poolProvider).pendingBanana(poolID, address(this));
    }

    //========================
    // DEPOSIT / WITHDRAW / COMPOUND FUNCTIONS
    //========================

    function poolDeposit(uint256 _amount) internal override
    {
        IMiniChefV2_Polygon_ApeSwap(poolProvider).deposit(poolID, _amount, address(this));
    }

    function poolWithdraw(uint256 _amount) internal override
    {
        IMiniChefV2_Polygon_ApeSwap(poolProvider).withdrawAndHarvest(poolID, _amount, address(this));
    }

    function poolEmergencyWithdraw() internal override
    {
        IMiniChefV2_Polygon_ApeSwap(poolProvider).emergencyWithdraw(poolID, address(this));
    }
}