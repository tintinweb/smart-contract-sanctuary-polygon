pragma solidity 0.8.9;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IPangolinPair.sol";
import "./interfaces/IPangolinRouter.sol";
import "./interfaces/IStakingRewards.sol";
import "./interfaces/IMiniChef.sol";

contract PangolinFeeCollector is Ownable {

    using SafeERC20 for IERC20;
    using Address for address;

    address public immutable pangolinRouter;
    address public immutable governor;
    address public immutable wrappedNativeToken;

    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public constant MAX_INCENTIVE = 200;

    address public stakingRewards;
    address public treasury; // Joint Treasury
    uint256 public harvestIncentive = 10;
    uint256 public treasuryFee = 3000;
    address public miniChef;
    uint256 public miniChefPoolId;


    constructor(
        address _stakingRewards,
        address _router,
        address _miniChef,
        uint256 _pid,
        address _governor,
        address _wrappedToken,
        address _treasury
    ) {
        require(_stakingRewards != address(0), "Invalid address");
        stakingRewards = _stakingRewards;
        pangolinRouter = _router;
        miniChef = _miniChef;
        miniChefPoolId = _pid;
        governor = _governor;
        wrappedNativeToken = _wrappedToken;
        treasury = _treasury;
    }

    /// @notice Change staking rewards contract address
    /// @param _stakingRewards - New contract address
    function setRewardsContract(address _stakingRewards) external onlyOwner {
        require(_stakingRewards != address(0), "Invalid address");
        stakingRewards = _stakingRewards;
    }

    /// @notice Change the percentage of each harvest that goes to the caller
    /// @param _harvestIncentive - New incentive ratio in bips
    function setHarvestIncentive(uint256 _harvestIncentive) external onlyOwner {
        require(_harvestIncentive <= MAX_INCENTIVE, "Incentive too large");
        require(_harvestIncentive + treasuryFee <= FEE_DENOMINATOR,
            "Total fees must <= 100");
        harvestIncentive = _harvestIncentive;
    }

    /// @notice Change the percentage of each harvest that goes to the treasury
    /// @param _treasuryFee - New ratio in bips
    /// @dev Can only be called through a governance vote
    function setTreasuryFee(uint256 _treasuryFee) external {
        require(msg.sender == governor, "Governor only");
        require(harvestIncentive + _treasuryFee <= FEE_DENOMINATOR,
            "Total fees must <= 100");
        treasuryFee = _treasuryFee;
    }

    /// @notice Updates the recipient of treasury fees
    /// @param _treasury - New treasury wallet
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0));
        treasury = _treasury;
    }

    /// @notice Sets the MiniChef address to collect rewards from
    /// @param _miniChef - New MiniChef address
    function setMiniChef(address _miniChef) external onlyOwner {
        require(_miniChef != address(0));
        miniChef = _miniChef;
    }

    /// @notice Sets the MiniChef pool used to accumulate rewards from emissions
    /// @param _pid - ID of the pool on MiniChef
    function setMiniChefPool(uint256 _pid) external onlyOwner {
        miniChefPoolId = _pid;
    }

    /// @notice Proxy function to set reward duration on the staking contract
    /// @param _rewardsDuration - the duration of the new period
    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        IStakingRewards(stakingRewards).setRewardsDuration(_rewardsDuration);
    }

    /// @notice Proxy function to change ownership of the staking contract
    /// @param _newOwner - address to transfer ownership to
    function transferStakingOwnership(address _newOwner) external onlyOwner {
        IStakingRewards(stakingRewards).transferOwnership(_newOwner);
    }

    /// @notice Remove liquidity associated with a pair
    /// @param pair - The pair from which to retrieve liquidity
    /// @param balance - The amount to pull
    function _pullLiquidity(IPangolinPair pair, uint256 balance) internal {
        pair.approve(pangolinRouter, balance);
        IPangolinRouter(pangolinRouter).removeLiquidity(
            pair.token0(),
            pair.token1(),
            balance,
            0,
            0,
            address(this),
            block.timestamp + 60
        );
    }

    /// @notice Swap a token for the specified output token
    /// @param token - address of the token to swap
    /// @param amount - amount of the token to swap
    /// @dev Swaps are executed via router, there is currently no check
    /// for existence of LP for output token
    function _swap(address token, address outputToken, uint256 amount)
    internal {

        address[] memory path;

        if (outputToken == wrappedNativeToken || token == wrappedNativeToken) {
            path = new address[](2);
            path[0] = token;
            path[1] = outputToken;
        } else {
            path = new address[](3);
            path[0] = token;
            path[1] = wrappedNativeToken;
            path[2] = outputToken;
        }

        IERC20(token).safeApprove(pangolinRouter, 0);
        IERC20(token).safeApprove(pangolinRouter, amount);
        IPangolinRouter(pangolinRouter).swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp + 60
        );
    }

    /// @notice For a list of liquidity pairs, pulls all liquidity and swaps it
    /// to the same previously specified output token
    /// @param liquidityPairs - list of all the pairs to pull
    /// @param outputToken - the token into which all liquidity will be swapped
    function _collectFees(address[] memory liquidityPairs,
        address outputToken) internal {
        require(outputToken != address(0), "Output token unspecified");
        for (uint256 i; i < liquidityPairs.length; ++i) {
            address currentPairAddress = liquidityPairs[i];
            IPangolinPair currentPair = IPangolinPair(currentPairAddress);
            uint256 pglBalance = currentPair.balanceOf(address(this));
            if (pglBalance > 0) {
                _pullLiquidity(currentPair, pglBalance);
                address token0 = currentPair.token0();
                address token1 = currentPair.token1();
                if (token0 != outputToken) {
                    _swap(token0, outputToken,
                        IERC20(token0).balanceOf(address(this)));
                }
                if (token1 != outputToken) {
                    _swap(token1, outputToken,
                        IERC20(token1).balanceOf(address(this)));
                }
            }
        }
    }

    /// @notice - Converts all the LP tokens specified to the rewards token and
    /// transfers it to the staking contract
    /// @param liquidityPairs - list of all the pairs to harvest
    /// @param claimMiniChef - whether to also harvest additional rewards
    /// accrued via MiniChef
    function harvest(address[] memory liquidityPairs, bool claimMiniChef)
    external {

        require(!address(msg.sender).isContract() && msg.sender == tx.origin, "No contracts");
        require(liquidityPairs.length <= 50, "50 pairs max");

        address _outputToken = IStakingRewards(stakingRewards).rewardsToken();

        if (claimMiniChef) {
            IMiniChef(miniChef).harvest(miniChefPoolId, address(this));
        }

        if (liquidityPairs.length > 0) {
            _collectFees(liquidityPairs, _outputToken);
        }

        uint256 _finalBalance = IERC20(_outputToken).balanceOf(address(this));

        uint256 _callIncentive = _finalBalance * harvestIncentive
        / FEE_DENOMINATOR;
        uint256 _treasuryFee = _finalBalance * treasuryFee / FEE_DENOMINATOR;
        uint256 _totalRewards = _finalBalance - _callIncentive - _treasuryFee;

        if (_totalRewards > 0) {
            IERC20(_outputToken).safeTransfer(stakingRewards, _totalRewards);
            IStakingRewards(stakingRewards).notifyRewardAmount(_totalRewards);
        }
        if (_treasuryFee > 0) {
            IERC20(_outputToken).safeTransfer(treasury, _treasuryFee);
        }
        if (_callIncentive > 0) {
            IERC20(_outputToken).safeTransfer(msg.sender, _callIncentive);
        }

    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
pragma solidity 0.8.9;

interface IPangolinPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPangolinRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

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
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountAVAX);
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
    function removeLiquidityAVAXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountAVAX);
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
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IStakingRewards {
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);

    function setRewardsDuration(uint256 _rewardsDuration) external;
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
    function notifyRewardAmount(uint256 reward) external;
    function exit() external;
    function getReward() external;
    function transferOwnership(address newOwner) external;
    function owner() external view;
    function rewardsDuration() external view;
    function withdraw(uint256 amount) external;
    function stake(uint256 amount) external;
    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function getRewardForDuration() external view;
    function earned(address account) external view;
    function rewardPerToken() external view;
    function lastTimeRewardApplicable() external view;
    function balanceOf(address account) external view;
    function totalSupply() external view;
    function rewardsToken() external view returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


interface IMiniChef {

    function poolLength() external view returns (uint256 poolLength);
    function lpTokens() external view;
    function poolInfos() external view;
    function disableMigrator() external;
    function migrate(uint256 _pid) external;
    function pendingReward(uint256 _pid, address _user) external view returns (uint256 pending);
    function deposit(uint256 pid, uint256 amount, address to) external;
    function depositWithPermit(uint256 pid, uint256 amount, address to, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
    function emergencyWithdraw(uint256 pid, address to) external;
    function addFunder(address _funder) external;
    function removeFunder(address _funder) external;
    function isFunder(address _funder) external view returns (bool allowed);
    function fundRewards(uint256 funding, uint256 duration) external;
    function resetRewardsDuration(uint256 duration) external;
    function extendRewardsViaFunding(uint256 funding, uint256 minExtension) external;
    function extendRewardsViaDuration(uint256 extension, uint256 maxFunding) external;
    function setPool(uint256 _pid, uint256 _allocPoint, address _rewarder, bool overwrite) external;
    function setPools(uint256[] calldata pids, uint256[] calldata allocPoints, address[] calldata rewarders, bool[] calldata overwrites) external;
    function addPools(uint256[] calldata _allocPoints, address[] calldata _lpTokens, address[] calldata _rewarders) external;
    function addPool(uint256 _allocPoint, address _lpToken, address _rewarder) external;
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