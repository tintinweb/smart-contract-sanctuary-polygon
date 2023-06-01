// SPDX-License-Identifier: MIT

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function token0() external view returns (address);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
contract OwnableData {
    address public owner;
    address public pendingOwner;
}

abstract contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {

            require(newOwner != address(0) || renounce, "Ownable: zero address");

            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        } else {
            pendingOwner = newOwner;
        }
    }

    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IStrategyCommonChefLP {
    function yelRewards() external view returns (uint256);
    function beforeDeposit() external;
    function chef() external view returns (address);
    function outputToNativeToYel() external view returns (address[] memory);
    function poolId() external view returns (uint256);
    function rewardPool() external view returns (address);
    function booster() external view returns (address);
    function want() external view returns (address);
    function balanceOf() external view returns (uint256);
    function routerYel() external view returns (address);
    function rewardV3ToNative() external view returns (address[] memory);
    function nativeToYelRouteView() external view returns (address[] memory);
    function pid() external view returns (uint);
}

interface PancakeRouter {
    function getAmountsOut(uint256, address[] memory) external view returns (uint256[] memory);
}

interface IGauge {
    function period() external view returns (uint256);
    function period_timestamp(uint256) external view returns (uint256);
    function integrate_inv_supply(uint256) external view returns (uint256);
    function working_balances(address) external view returns (uint256);
    function working_supply() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

interface IBooster {
    struct PoolInfo {
        address lptoken; //the curve lp token
        address gauge; //the curve gauge
        address rewards; //the main reward/staking contract
        bool shutdown; //is this pool shutdown?
        address factory; //a reference to the curve factory used to create this pool (needed for minting crv)
    }

    function staker() external view returns (address);
    function poolInfo(uint256) external view returns (PoolInfo memory);
}

interface IRewardPool {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId) external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract Yeller is Ownable {
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 remainingYelTokenReward;  // YEL Tokens that weren't distributed for user per pool.
        //
        // Any point in time, the amount of YEL entitled to a user but is pending to be distributed is:
        // pending reward = (user.amount * pool.accYELPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws Staked tokens to a pool. Here's what happens:
        //   1. The pool's `accYELPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 stakingToken; // Contract address of staked token
        uint256 stakingTokenTotalAmount; //Total amount of deposited tokens
        uint256 accYelPerShare; // Accumulated YEL per share, times 1e12. See below.
        uint32 lastRewardTime; // Last timestamp number that YEL distribution occurs.
    }

    IStrategyCommonChefLP strategy; // Farming strategy.
    AggregatorV3Interface internal priceFeed;
    
    IERC20 immutable public yel; // The YEL token.
    
    PoolInfo[] public poolInfo; // Info of each pool.
    
    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // Info of each user that stakes tokens.
    
    uint256 immutable public DIVISOR = 1e10; // Divisor for formating numbers.

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IERC20 _yel,
        address _strategy,
        address _priceFeed
    ) {
        yel = _yel;
        strategy = IStrategyCommonChefLP(_strategy);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    // How many pools are in the contract
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new staking token to the pool. Can only be called by the owner.
    // VERY IMPORTANT NOTICE 
    // ----------- DO NOT add the same staking token more than once. Rewards will be messed up if you do. -------------
    // Good practice to update pools without messing up the contract
    function add(IERC20 _stakingToken,bool _withUpdate) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTime = block.timestamp;
        poolInfo.push(
            PoolInfo({
                stakingToken: _stakingToken,
                stakingTokenTotalAmount: 0,
                lastRewardTime: uint32(lastRewardTime),
                accYelPerShare: 0
            })
        );
    }

    // View function to see pending YEL on frontend.
    function pendingYel(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accYelPerShare = pool.accYelPerShare;

        if (block.timestamp > pool.lastRewardTime && pool.stakingTokenTotalAmount != 0) {
            address boosterAddress = strategy.booster();
            uint pId = strategy.pid();
            IBooster.PoolInfo memory farmingPoolInfo = IBooster(boosterAddress).poolInfo(pId);
            address gauge = farmingPoolInfo.gauge;
            address unirouter = strategy.routerYel();

            uint rewardsPerSec = periodCrvRewards(gauge);
            uint currentTime = block.timestamp;
            uint differentInTime = currentTime - pool.lastRewardTime;
            uint pendingRewardsCrv = differentInTime * rewardsPerSec;

            uint rewardsForUs = getPartInRewardForPending(gauge, pendingRewardsCrv);
            address[] memory crvToNativeToYel = getRoutesForPending();

            uint[] memory amountsOut = PancakeRouter(unirouter).getAmountsOut(rewardsForUs, crvToNativeToYel);
            accYelPerShare += (amountsOut[2] - (amountsOut[2] * 10 / 100)) * DIVISOR / pool.stakingTokenTotalAmount;
        }
        return user.amount * accYelPerShare / DIVISOR - user.rewardDebt + user.remainingYelTokenReward;
    }

    function getPartInRewardForPending(address _gauge, uint _pendingRewardsCrv) private view returns (uint) {
        IGauge gauge = IGauge(_gauge);

        uint stakedAmount = strategy.balanceOf();
        uint workingSupply = gauge.totalSupply();

        uint ourPartShares = stakedAmount * 1e18 / workingSupply;
        uint ourCrvRewards = _pendingRewardsCrv * ourPartShares / 1e18;

        return ourCrvRewards;
    }

    function getRoutesForPending() private view returns (address[] memory) {
        address[] memory rewardsToNativeRoute = strategy.rewardV3ToNative();
        address[] memory nativeToYelRoute = strategy.nativeToYelRouteView();
        address[] memory crvToNativeToYel = new address[](3);
        crvToNativeToYel[0] = rewardsToNativeRoute[0];
        crvToNativeToYel[1] = nativeToYelRoute[0];
        crvToNativeToYel[2] = nativeToYelRoute[1];

        return crvToNativeToYel;
    }

    // View function to see pending APR on frontend.
    function getFullApr() public view returns (uint, uint) {
        address boosterAddress = strategy.booster();
        uint pId = strategy.pid();
        address staker = IBooster(boosterAddress).staker();
        IBooster.PoolInfo memory farmingPoolInfo = IBooster(boosterAddress).poolInfo(pId);
        address gauge = farmingPoolInfo.gauge;

        (, int price, , , ) = priceFeed.latestRoundData();
        uint decimalsPriceFeed = priceFeed.decimals();
        uint divisor = 10**decimalsPriceFeed;
        uint nativeUsdtPrice = (uint(price) * 1e18) / divisor;

        uint stakedAmount = strategy.balanceOf();
        uint cleanApr = getSimpleApr(gauge, staker, nativeUsdtPrice);
        (, uint lpTokenPriceUsdt)= getLpValue();

        uint yelApr = getYelApr(stakedAmount, lpTokenPriceUsdt, cleanApr, nativeUsdtPrice);

        uint finalApr = wholeApr(cleanApr, yelApr);
       
        return (finalApr, cleanApr);
    }

    function getSimpleApr(address _gauge, address _staker, uint _nativeUsdtPrice) private view returns (uint) {
        address unirouter = strategy.routerYel();
        uint32 secondsPerYear = 31560000;

        uint crvPerSecondForPool = partInPool(_gauge, _staker);
        uint crvPerYearForPool = crvPerSecondForPool * secondsPerYear;
        uint pricePerRewardToken = convertRewardToUsdt(_nativeUsdtPrice, unirouter);
        uint usdtRewardPerYear = crvPerYearForPool * pricePerRewardToken / 1e18;
        (uint stakedValue, ) = getLpValue();
        uint aprClean = usdtRewardPerYear * 1e18 / stakedValue;

        return aprClean;
    }

    function partInPool(address _gauge, address _staker) private view returns (uint) {
        IGauge gauge = IGauge(_gauge);

        uint crvRewardPerSecond = periodCrvRewards(_gauge);
        uint wholePool = gauge.working_supply();
        uint stakerPartInPool = gauge.working_balances(_staker);
        uint partInPoolShares = stakerPartInPool * 1e18 / wholePool;
        uint stakerRewardPerSecond = crvRewardPerSecond * partInPoolShares / 1e18;

        return stakerRewardPerSecond;
    }

    function periodCrvRewards(address _gauge) private view returns (uint) {
        IGauge gauge = IGauge(_gauge);

        uint currentPeriod = gauge.period();
        uint currentPeriodTime = gauge.period_timestamp(currentPeriod);
        uint lastPeriod = gauge.period() - 1;
        uint lastPeriodTime = gauge.period_timestamp(lastPeriod);

        if(currentPeriodTime == lastPeriodTime) {
            for(uint256 i; i < currentPeriod; i++) {
                lastPeriod = gauge.period() - i;
                lastPeriodTime = gauge.period_timestamp(lastPeriod);

                if(currentPeriodTime != lastPeriodTime) {
                    break;
                }
            }
        }

        uint differenceTime = currentPeriodTime - lastPeriodTime;
        uint currentIntegrateInvSupply = gauge.integrate_inv_supply(currentPeriod);
        uint lastIntegrateInvSupply = gauge.integrate_inv_supply(lastPeriod);
        uint differenceSupply = currentIntegrateInvSupply - lastIntegrateInvSupply;

        uint workingBalance = gauge.working_supply();
        uint crvRewards = workingBalance * differenceSupply / 1e18;
        uint crvRewardPerSecond = crvRewards / differenceTime;

        return crvRewardPerSecond;
    }

    function convertRewardToUsdt(uint _nativeUsdtPrice, address _unirouter) private view returns (uint256) {
        address[] memory rewardsToNativeRoute = strategy.rewardV3ToNative();
        uint[] memory amountsOut = PancakeRouter(_unirouter).getAmountsOut(1 * 1e18, rewardsToNativeRoute);
        uint pricePerRewardToken = (amountsOut[1] * _nativeUsdtPrice) / 1e18;

        return pricePerRewardToken;
    }

    function getLpValue() public view returns (uint, uint) {
        address boosterAddress = strategy.booster();
        uint pId = strategy.pid();
        IBooster.PoolInfo memory farmingPoolInfo = IBooster(boosterAddress).poolInfo(pId);
        address gauge = farmingPoolInfo.gauge;

        address stable = 0xb5DFABd7fF7F83BAB83995E72A52B97ABb7bcf63;
        address lpToken = strategy.want();
        uint usdtInLps = IERC20(stable).balanceOf(lpToken);
        uint lpWorkFromGauge = IERC20(lpToken).balanceOf(gauge);
        uint decimalsStable = IERC20(stable).decimals();
        uint lpSupply = IERC20(lpToken).totalSupply();
        uint lpTokenPriceUsdt = ((usdtInLps / 10**decimalsStable) * 1e36 * 2) / lpSupply;
        uint usdtStakedValue = (lpWorkFromGauge * lpTokenPriceUsdt) / 1e36;

        return (usdtStakedValue, lpTokenPriceUsdt);
    }

    function getYelApr(uint stakedAmount, uint lpTokenPriceUsdt, uint cleanApr, uint _nativeUsdtPrice) private view returns (uint) {
        address unirouter = strategy.routerYel();

        uint buyPressureUsdt = ((stakedAmount * lpTokenPriceUsdt) / 1e18 * cleanApr) / 1e18;
        address[] memory nativeToYelRoute = strategy.nativeToYelRouteView();
        address[] memory yelToNative = new address[](2);
        yelToNative[0] = nativeToYelRoute[1];
        yelToNative[1] = nativeToYelRoute[0];
      
        uint[] memory yelPriceInNative = PancakeRouter(unirouter).getAmountsOut(1*1e18, yelToNative);
  
        uint yelInUsdtNow = (yelPriceInNative[1] * _nativeUsdtPrice) / 1e18;
     
        uint preassureInNative = (buyPressureUsdt * 1e18) / _nativeUsdtPrice;
        address[] memory nativeToYel = new address[](2);
        nativeToYel[0] = nativeToYelRoute[0];
        nativeToYel[1] = nativeToYelRoute[1];
        uint[] memory yelPressureInNative = PancakeRouter(unirouter).getAmountsOut(preassureInNative, nativeToYel);

        uint afterYelPriceUsdt = (buyPressureUsdt * 1e18) / yelPressureInNative[1];
        uint yelApr = ((afterYelPriceUsdt - yelInUsdtNow) * 1e18 / yelInUsdtNow);

        return yelApr;
    }
    
    function wholeApr(uint _cleanApr, uint _yelApr) private pure returns (uint) {
        uint feeOwner = 10;
        uint allAprs = _cleanApr + _yelApr;
        uint finalApr = allAprs - (allAprs / feeOwner);
        return finalApr;
    }

    // View function for ZAP contract 
    function getUserInfo(uint256 _pid, address _user) public view returns (UserInfo memory) {
        return userInfo[_pid][_user];
    }

    // View function for ZAP contract 
    function getUserAmount(uint256 _pid, address _user) public view returns (uint256) {
        return userInfo[_pid][_user].amount;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }

        if (pool.stakingTokenTotalAmount == 0) {
            pool.lastRewardTime = uint32(block.timestamp);
            return;
        }

        uint256 yelReward = strategy.yelRewards();
        pool.accYelPerShare += yelReward * DIVISOR / pool.stakingTokenTotalAmount;
        pool.lastRewardTime = uint32(block.timestamp);
    }

    // Deposit staking tokens for YEL allocation.
    function deposit(uint256 _pid, uint256 _amount, address _depositor) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_depositor];
        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending =
                user.amount * pool.accYelPerShare / DIVISOR - user.rewardDebt + user.remainingYelTokenReward;
            user.remainingYelTokenReward = safeRewardTransfer(msg.sender, pending);
        }

        pool.stakingToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        user.amount += _amount;
        pool.stakingTokenTotalAmount += _amount;
        user.rewardDebt = user.amount * pool.accYelPerShare / DIVISOR;

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw staked tokens.
    function withdraw(uint256 _pid, uint256 _amount) public { // IF _AMOUNT 0 === CLAIM
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][tx.origin];
        require(user.amount >= _amount, "You do not have enough tokens to complete this operation");

        strategy.beforeDeposit();
        updatePool(_pid);
        uint256 pending = user.amount * pool.accYelPerShare / DIVISOR - user.rewardDebt + user.remainingYelTokenReward;

        user.remainingYelTokenReward = safeRewardTransfer(tx.origin, pending);
        user.amount -= _amount;
        pool.stakingTokenTotalAmount -= _amount;
        user.rewardDebt = user.amount * pool.accYelPerShare / DIVISOR;

        pool.stakingToken.safeTransfer(address(tx.origin), _amount);

        emit Withdraw(tx.origin, _pid, _amount);
    }

    // Safe YEL transfer function. Just in case if the pool does not have enough YEL token,
    // The function returns the amount which is owed to the user
    function safeRewardTransfer(address _to, uint256 _amount) internal returns(uint256) {
        uint256 yelTokenBalance = yel.balanceOf(address(this));
        if (_amount > yelTokenBalance) {
            yel.safeTransfer(_to, yelTokenBalance);
            return _amount - yelTokenBalance;
        }
        yel.safeTransfer(_to, _amount);
        return 0;
    }
}