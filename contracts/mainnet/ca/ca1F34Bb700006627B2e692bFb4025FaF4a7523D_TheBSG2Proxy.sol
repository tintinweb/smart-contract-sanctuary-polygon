/**
 *Submitted for verification at polygonscan.com on 2023-01-04
*/

// SPDX-License-Identifier: MIT
 

pragma solidity ^0.8.14;
 
/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 * 
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 * 
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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


abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal virtual view returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () payable external {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () payable external {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     * 
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}
contract TheBSG2Proxy is Proxy {
    
    address public impl;
    address public contractOwner;

    modifier onlyContractOwner() { 
        require(msg.sender == contractOwner); 
        _; 
    }

    constructor(address _impl)  {
        impl = _impl;
        contractOwner = msg.sender;
    }
    
    function update(address newImpl) public onlyContractOwner {
        impl = newImpl;
    }

    function removeOwnership() public onlyContractOwner {
        contractOwner = address(0);
    }
    
    function _implementation() internal override view returns (address) {
        return impl;
    }
}
contract TheBSG2Basic{
     address public impl;
     address public contractOwner;
     //Non Working Ring Ring 1
     bool public locked;
    bool public devmode;
    IERC20 public usdt;
    uint256 internal constant baseDivider = 10000;
    uint256 internal constant limitProfit = 20000;
    uint256 internal constant boosterLimitProfit = 30000;
    uint256 internal constant feePercents = 200; 
    uint256 internal constant minDeposit = 100e6; 
    uint256 internal constant maxDeposit = 6000e6; 
    uint256 internal constant freezeIncomePercents = 3000;
    uint256 internal constant LuckDeposit = 1000e6; 
    uint256 internal constant timeStep = 1 days; 
    uint256 internal constant dayPerCycle = 10 days;
    uint256 internal constant maxAddFreeze = 50 days; 
    uint256 internal constant normalcycleRewardPercents = 1000;
    uint256 internal constant boostercycleRewardPercents = 2000;
    uint256 internal constant referDepth = 12;
    uint256 internal constant boosterPoolTimeLimit = 60 days;

    uint256 internal constant directPercents = 500;
    uint256[] internal diamondLevels = [100,200,300,100]; 
    uint256[] internal blueDiamondLevels = [100,100,100,100,100,50,50]; 

    uint256 internal constant infiniteRewardPercents = 400; 
    uint256 internal constant boosterPoolPercents = 50; 
    uint256 internal constant supportPoolPercents = 100; 
    uint256 internal constant more1kIncomePoolPercents = 50; 

    address public feeReceivers; 
    address public supportFundAccount;

    address public defaultRefer; 
    uint256 internal startTime;
    uint256 public lastDistribute; 
    uint256 public totalUser;
    uint256 public more1kIncomePool;
    uint256 public boosterPool;

    uint256 internal balDown = 40e10;
    bool internal balReached;
    uint256 internal balDownRateSL1 = 8000;
    uint256 internal balDownRateSL2 = 6000;
    uint256 internal balRecover = 11000;
    uint256 public AllTimeHigh;
    uint256 public balDownHitAt;
    bool public isRecoveredFirstTime = false;
    bool public isStopLoss20ofATH = false;
    bool public isStopLoss40ofATH = false;
    uint256 public lastFreezed;
    bool internal balanceHitZero;     
    mapping(uint256=>address[]) public dayMore1kUsers;
    address[] public boosterUsers;
    uint256 public dayMore1KLastDistributed;

    struct OrderInfo {
        uint256 amount;
        uint256 start;
        uint256 unfreeze;
        bool isClaimed;
    }

    mapping(address => OrderInfo[]) public orderInfos;

    address[] public depositors;

    struct UserInfo {
        address referrer;
        uint256 start; 
        uint256 level;
        uint256 maxDeposit;
        uint256 maxDirectDeposit;
        uint256 totalDeposit;
        uint256 teamNum;
        uint256 teamTotalDeposit;
        uint256 directTeamTotalVolume;
        uint256 totalFreezed;
        uint256 totalRevenue;
        uint256 depositDistributed;
    }

    struct UserAchievements {
        bool isbooster;
        uint256 boosterAcheived;
        uint256 boosterAcheivedAmount;
    }

    mapping(address => UserAchievements) public userAchieve;
    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(uint256 => address[])) public teamUsers;
    mapping(address => address[]) public myTeamUsers;

    struct RewardInfo {
        uint256 capitals;
        uint256 statics;
        uint256 directs;
        uint256 levelReleased;
        uint256 blueDiamondReleased;
        uint256 blueDiamondFreezed;
        uint256 infinityBonusReleased;
        uint256 infinityFreezed;
        uint256 blueDiamondReceived;
        uint256[2] crownDiamondReceived;
        uint256 more1k;
        uint256 booster;
        uint256 lockusdt;
        uint256 lockusdtDebt; 
    }

    mapping(address => RewardInfo) public rewardInfo;
    uint256 internal constant maxBlueDiamondFreeze = 50000e6;
    uint256 internal constant maxCrownDiamondFreeze = 25000e6;
    uint256 internal constant maxInfinityL1toL5 = 10000e6;
    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event DepositBylockusdt(address user, uint256 amount);
    event TransferBylockusdt(address user, address receiver, uint256 amount);
    event Withdraw(address user, uint256 withdrawable);

      
}

contract  TheBSG2 is TheBSG2Basic{

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    struct SentsAmount{        
        uint256 _id;
        address _address;
        uint256 _amount;
    } 
    mapping(uint => SentsAmount[]) public recevers;

	modifier onlyContractOwner() { 
        require(msg.sender == contractOwner, "onlyOwner"); 
        _; 
    }
    modifier onlyUnlocked() { 
        require(!locked || msg.sender == contractOwner); 
        _; 
    }

     function init(address _usdtAddr, address _defaultRefer,address _supportFund,address  _feeReceivers) public   onlyContractOwner {        
        usdt = IERC20(_usdtAddr);
        defaultRefer = _defaultRefer;
        supportFundAccount = _supportFund;
        feeReceivers = _feeReceivers;
        startTime = block.timestamp;
        lastDistribute = block.timestamp;
    }
  

    function changeLock() external onlyContractOwner() {
        locked = !locked;
    } 
    function changeMode() external onlyContractOwner() {
        devmode = !devmode;
    }   
 
	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    } 
    function register(address _referral) external {
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer,"invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        if(msg.sender == defaultRefer) {
            user.referrer = address(this);
        } else {
            user.referrer = _referral;
        }
        totalUser = totalUser.add(1);
        emit Register(msg.sender, _referral);
    }
    
    function _updateTeamNum(address _user) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for (uint256 i = 0; i < referDepth; i++) {
            if (upline != address(0)) {
                userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);
                teamUsers[upline][i].push(_user);
                _updateLevel(upline);
                if (upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function _updateLevel(address _user) private {
        UserInfo storage user = userInfo[_user];
        user.level = _calLevelNow(_user);
    }

    function _calLevelNow(address _user) private view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 level;
        uint256 directTeam = myTeamUsers[_user].length;
        (uint256 maxTeam, uint256 otherTeam, ) = getTeamDeposit(_user);
        uint256 totalTeam = user.teamNum;
        if(user.maxDeposit >= 2500e6 && directTeam >=12 && user.maxDirectDeposit >= 12000e6 && totalTeam >= 300 && maxTeam >= 150000e6 && otherTeam >= 150000e6){
            level = 4;
        }else if(user.maxDeposit >= 2500e6 && directTeam >=8 && user.maxDirectDeposit >= 8000e6 && totalTeam >= 150 && maxTeam >= 60000e6 && otherTeam >= 60000e6){
            level = 3;
        }else if(user.maxDeposit >= 1000e6 && directTeam >=4 && user.maxDirectDeposit >= 4000e6 && totalTeam >= 50 && maxTeam >= 25000e6 && otherTeam >= 25000e6){
            level = 2;
        } else if(user.maxDeposit >= minDeposit) {
            level = 1;
        }
        return level;
    }

    function _updatemaxdirectdepositInfo(address _user, uint256 _amount, uint256 _prevMax) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;

        if (upline != address(0)) {
            userInfo[upline].maxDirectDeposit = userInfo[upline]
                .maxDirectDeposit
                .add(_amount);
            userInfo[upline].maxDirectDeposit = userInfo[upline]
                .maxDirectDeposit
                .sub(_prevMax);

            userInfo[upline].directTeamTotalVolume = userInfo[upline].directTeamTotalVolume.add(_amount);
        }
    }

    function deposit(uint256 _amount) external {
        if(_amount<100e6){
            require(_amount==30e6 || _amount==50e6,"Invalid Amount");
        }
        else{
                require(_amount.mod(minDeposit) == 0,"amount should be multiple of 100");
        }
        
        usdt.safeTransferFrom(msg.sender, address(this), _amount);
        _deposit(msg.sender, _amount);
        emit Deposit(msg.sender, _amount);
    }

    function _deposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        uint256 prevMax = user.maxDeposit;
        require(user.referrer != address(0),"register first with referral address");
        if(_amount>=100e6)
        require(_amount >= minDeposit, "should be more than 100");

        require(_amount <= maxDeposit, "should be less than 2500");
        require(user.maxDeposit == 0 || _amount >= user.maxDeposit,"next deposit should be equal or more than previous");

        if (user.maxDeposit == 0) {
            user.maxDeposit = _amount;
            user.start = block.timestamp;
            myTeamUsers[user.referrer].push(_user);
            _updateTeamNum(_user);
        } else if (user.maxDeposit < _amount) {
            user.maxDeposit = _amount;
        }

        _distributeDeposit(_amount);

        if(user.totalDeposit == 0){
            uint256 dayNow = dayMore1KLastDistributed;
            _updateDayMore1kUsers(_user, dayNow);
        }

        _updateDepositors(_user);

        user.totalDeposit = user.totalDeposit.add(_amount);
        user.totalFreezed = user.totalFreezed.add(_amount);

        uint256 addFreeze = (orderInfos[_user].length).mul(timeStep);
        if (addFreeze > maxAddFreeze) {
            addFreeze = maxAddFreeze;
        }

        uint256 unfreezeTime = block.timestamp.add(dayPerCycle).add(addFreeze);
        orderInfos[_user].push(OrderInfo(_amount, block.timestamp, unfreezeTime, false));

        _updatemaxdirectdepositInfo(_user, _amount, prevMax);
        
        _unfreezeFundAndUpdateReward(_user, _amount); 

        _isBooster(_user);

        _isBooster(user.referrer);

        distributePoolRewards(); 

        _updateReferInfo(_user, _amount); 

        _updateReward(_user, _amount, prevMax); 

        _updateInfinity(_user, _amount);

        _updateLevel(_user);

        uint256 bal = usdt.balanceOf(address(this));

        if(bal >= balDown) {
            balReached = true;
        }

        if(bal > AllTimeHigh) {
            AllTimeHigh = bal;
        }

        if (isStopLoss20ofATH || isStopLoss40ofATH) {
            _setFreezeReward(bal);
        }
    }

    function _isBooster(address _user) private {
        if(!(userAchieve[_user].isbooster) && myTeamUsers[_user].length >= 2 && userInfo[_user].maxDeposit >= 100e6) {
            uint256 count;
            for(uint256 i=0; i<myTeamUsers[_user].length; i++) {
                address downline = myTeamUsers[_user][i]; 
                if(userInfo[downline].start < userInfo[_user].start.add(21 days)) {
                    if(userInfo[downline].maxDeposit >= userInfo[_user].maxDeposit) {
                        count = count.add(1);
                    }
                } else {
                    break;
                }
            }

            if(count >= 2) {
                if(_user == msg.sender) {
                    userAchieve[_user].isbooster = true;
                    userAchieve[_user].boosterAcheivedAmount = userInfo[_user].maxDeposit;
                }                 
                if(!(userAchieve[_user].boosterAcheived > 0)) {
                    userAchieve[_user].boosterAcheived = block.timestamp;
                    boosterUsers.push(_user);
                }
            }
        } 
    }

    function _updateDayMore1kUsers(address _user, uint256 _dayNow) private {
        bool isFound;
        for(uint256 i=0; i<dayMore1kUsers[_dayNow].length; i++) {
            if(dayMore1kUsers[_dayNow][i] == userInfo[_user].referrer) {
                isFound = true;
                break;
            }
        }

        if(!isFound) {
            address referrer = userInfo[_user].referrer;
            uint256 myTeam = myTeamUsers[referrer].length;
            uint256 volume;
            for(uint256 i=myTeam; i>0; i--) {
                address _newUser = myTeamUsers[referrer][i-1];
                if(userInfo[_newUser].start > lastDistribute) {
                    volume = volume.add(userInfo[_newUser].maxDeposit);
                } else {
                    break;
                }
            }

            if(volume >= LuckDeposit) {
                dayMore1kUsers[_dayNow].push(userInfo[_user].referrer);
            }
        } 
    }

    function _distributeDeposit(uint256 _amount) private {
        uint256 fee = _amount.mul(feePercents).div(baseDivider);
        usdt.safeTransfer(feeReceivers, fee);
       // usdt.transfer(feeReceivers[1], fee.div(2));
        if(!balanceHitZero) {
            uint256 _support = _amount.mul(supportPoolPercents).div(baseDivider);
            usdt.safeTransfer(supportFundAccount, _support);
        }
        uint256 more1kPool = _amount.mul(more1kIncomePoolPercents).div(baseDivider);
        more1kIncomePool = more1kIncomePool.add(more1kPool);
        uint256 _booster = _amount.mul(more1kIncomePoolPercents).div(baseDivider);
        boosterPool = boosterPool.add(_booster); 
    }

    function _unfreezeFundAndUpdateReward(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        bool isUnfreezed;

        for (uint256 i = 0; i < orderInfos[_user].length; i++) {
            OrderInfo storage order = orderInfos[_user][i];
            if (block.timestamp > order.unfreeze && !order.isClaimed) {
                if (user.totalFreezed > order.amount) {
                    user.totalFreezed = user.totalFreezed.sub(order.amount);
                } else {
                    user.totalFreezed = 0;
                }

                _removeInvalidDeposit(_user, order.amount);

                uint256 staticReward = _returnStaticReward(_user, order.amount);

                if(user.level > 2 && staticReward >= 25e6 && !balanceHitZero) {
                    usdt.safeTransfer(supportFundAccount, 25e6);
                    staticReward = staticReward.sub(25e6);
                }

                rewardInfo[_user].capitals = rewardInfo[_user].capitals.add(order.amount);
                rewardInfo[_user].statics = rewardInfo[_user].statics.add(staticReward);
                userInfo[_user].totalRevenue = userInfo[_user].totalRevenue.add(staticReward);
                
                order.isClaimed = true;
                isUnfreezed = true;
                break;
            }
        }

        if(!isUnfreezed) {
            RewardInfo storage userReward = rewardInfo[_user];
            uint256 release = _amount;

            if(userReward.blueDiamondFreezed > 0) {
                if(release >= userReward.blueDiamondFreezed) {
                  release = release.sub(userReward.blueDiamondFreezed);
                  user.totalRevenue = user.totalRevenue.add(userReward.blueDiamondFreezed);
                  userReward.blueDiamondReleased = userReward.blueDiamondReleased.add(userReward.blueDiamondFreezed);
                  userReward.blueDiamondFreezed = 0;  
                } else {
                  userReward.blueDiamondFreezed = userReward.blueDiamondFreezed.sub(release);
                  userReward.blueDiamondReleased = userReward.blueDiamondReleased.add(release);
                  user.totalRevenue = user.totalRevenue.add(release);
                  release = 0;
                }
            }

            if(userReward.infinityFreezed > 0 && release > 0) {
                if(release >= userReward.infinityFreezed) {
                  release = release.sub(userReward.infinityFreezed);
                  user.totalRevenue = user.totalRevenue.add(userReward.infinityFreezed);
                  userReward.infinityBonusReleased = userReward.infinityBonusReleased.add(userReward.infinityFreezed);
                  userReward.infinityFreezed = 0;  
                } else {
                  userReward.infinityFreezed = userReward.infinityFreezed.sub(release);
                  userReward.infinityBonusReleased = userReward.infinityBonusReleased.add(release);
                  user.totalRevenue = user.totalRevenue.add(release);
                  release = 0;
                }
            }
        }
    }

    function _returnStaticReward(address _user, uint256 _amount) private view returns(uint256) {
        uint256 staticReward;
        UserInfo memory user = userInfo[_user];

        if(user.totalRevenue < getMaxFreezing(_user).mul(limitProfit).div(baseDivider) || user.level > 1 || _isEligible(_user) || _user == defaultRefer) {
            staticReward = _amount.mul(normalcycleRewardPercents).div(baseDivider);
        }
        
        if(userAchieve[_user].isbooster){
            uint256 boosterIncome;
            if(user.level > 1) {
                staticReward = _amount.mul(boostercycleRewardPercents).div(baseDivider);
            } else if(user.totalRevenue < getMaxFreezing(_user).mul(boosterLimitProfit).div(baseDivider) || _isEligible(_user) || _user == defaultRefer) {
                if(userAchieve[_user].boosterAcheivedAmount < _amount) {
                    boosterIncome = userAchieve[_user].boosterAcheivedAmount.mul(boostercycleRewardPercents).div(baseDivider);
                    staticReward = (_amount.sub(userAchieve[_user].boosterAcheivedAmount)).mul(normalcycleRewardPercents).div(baseDivider);
                    staticReward = staticReward.add(boosterIncome);
                } else {
                    staticReward = _amount.mul(boostercycleRewardPercents).div(baseDivider);
                }
            }
        }

        if(isStopLoss40ofATH || isStopLoss20ofATH) {
            if(user.totalRevenue >= user.totalFreezed) {
                staticReward = 0;
            } else {
                uint256 temp = user.totalFreezed.sub(user.totalRevenue);
                if(temp < staticReward) {
                    staticReward = temp;
                }
            }
        } else if(isRecoveredFirstTime && staticReward > 0 && user.level > 1) {
            staticReward = staticReward.div(2);
        }

        return staticReward;
    }

    function _returnDynamicReward(address _user, address _upline, uint256 _amount) private view returns(uint256) {
        uint256 newAmount;
        UserInfo memory upline = userInfo[_upline];

        if(upline.totalRevenue < getMaxFreezing(_upline).mul(limitProfit).div(baseDivider) || upline.level > 1 || _isEligible(_upline) || _upline == defaultRefer) {
            newAmount = _amount;
        } 
        
        if(userAchieve[_upline].isbooster){
            if(upline.totalRevenue < getMaxFreezing(_upline).mul(boosterLimitProfit).div(baseDivider) || upline.level > 1 || _isEligible(_upline) || _upline == defaultRefer) {
                newAmount = _amount;
            }
        }

        if(isStopLoss20ofATH) {
            if(upline.totalRevenue < upline.totalFreezed || userInfo[_user].start > lastFreezed) {
                newAmount = newAmount;
            } else {
                newAmount = newAmount.div(2);
            }
        }

        if(isStopLoss40ofATH) {
            if(!(userInfo[_user].start > lastFreezed)) {
                newAmount = 0;
            }
        }

        return newAmount;
    }

    function _isEligible(address _user) private view returns(bool) {
        bool isEligible;
        uint256 volume;
        for(uint256 j=0; j<myTeamUsers[_user].length; j++) {
            address downline = myTeamUsers[_user][j]; 
            if(orderInfos[downline].length > 0) {
                volume = volume.add(userInfo[downline].maxDeposit);
            }
        }

        if(volume >= 5000e6 && myTeamUsers[_user].length >= 5) {
            isEligible = true;
        }

        return isEligible;
    }

    function _removeInvalidDeposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for (uint256 i = 0; i < referDepth; i++) {
            if (upline != address(0)) {
                if (userInfo[upline].teamTotalDeposit > _amount) {
                    userInfo[upline].teamTotalDeposit = userInfo[upline]
                        .teamTotalDeposit
                        .sub(_amount);
                } else {
                    userInfo[upline].teamTotalDeposit = 0;
                }
                if (upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function distributePoolRewards() public {
        if (block.timestamp > lastDistribute.add(timeStep)) {
            uint256 dayNow = dayMore1KLastDistributed;
            _distributeLuckPool1k(dayNow);
            _distributeBoosterPool();
            lastDistribute = block.timestamp;
            dayMore1KLastDistributed = dayMore1KLastDistributed.add(1);
        }
    }

    function getCurDay() public view returns(uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }

    function _distributeLuckPool1k(uint256 _dayNow) private {
        uint256 day1kDepositCount = dayMore1kUsers[_dayNow].length;
        if(day1kDepositCount > 0){
            uint256 reward = more1kIncomePool.div(day1kDepositCount);
            uint256 totalReward;

            for(uint256 i = day1kDepositCount; i > 0; i--){
                address userAddr = dayMore1kUsers[_dayNow][i - 1];
                if(userAddr != address(0)){
                    uint256 givenReward = reward;
                    if(!(getMaxFreezing(userAddr) > 0)) {
                        givenReward = 0;
                    }
                    rewardInfo[userAddr].more1k = rewardInfo[userAddr].more1k.add(givenReward);
                    userInfo[userAddr].totalRevenue = userInfo[userAddr].totalRevenue.add(givenReward);
                    totalReward = totalReward.add(givenReward);
                }
            }

            if(more1kIncomePool > totalReward){
                more1kIncomePool = more1kIncomePool.sub(totalReward);
            }else{
                more1kIncomePool = 0;
            }
        }
    }

    function _distributeBoosterPool() private {
        uint256 boosterCount;
        for(uint256 i=boosterUsers.length; i>0; i--) {
            UserAchievements memory userboost = userAchieve[boosterUsers[i-1]];
            if((block.timestamp - userboost.boosterAcheived) < boosterPoolTimeLimit) {
                boosterCount = boosterCount.add(1);
            } else {
                break;
            }
        }

        if(boosterCount > 0) {
            uint256 reward = boosterPool.div(boosterCount);
            uint256 totalReward;
    
            for(uint256 i=boosterUsers.length; i>0; i--) {
                address userAddr = boosterUsers[i-1];
                UserAchievements memory userboost = userAchieve[boosterUsers[i-1]];
                if((block.timestamp - userboost.boosterAcheived) < boosterPoolTimeLimit && userAddr != address(0)) {
                    uint256 calReward = _returnPoolReward(userAddr, reward);
                    rewardInfo[userAddr].booster = rewardInfo[userAddr].booster.add(calReward);
                    userInfo[userAddr].totalRevenue = userInfo[userAddr].totalRevenue.add(calReward);
                    totalReward = totalReward.add(calReward);
                } else {
                    break;
                }
            }

            if(boosterPool > totalReward){
                boosterPool = boosterPool.sub(totalReward);
            }else{
                boosterPool = 0;
            }
        }
    }

    function _returnPoolReward(address _user, uint256 _amount) private view returns(uint256) {
        uint256 reward = 0;
        UserInfo memory user = userInfo[_user];
        
        if(user.totalRevenue < getMaxFreezing(_user).mul(boosterLimitProfit).div(baseDivider) || user.level > 1) {
            reward = _amount;
        }

        if(isStopLoss20ofATH && !(user.totalRevenue < user.totalFreezed)) {
            reward = reward.div(2);
        }

        if(isStopLoss40ofATH) {
            reward = 0;
        }

        if(!(getMaxFreezing(_user) > 0)) {
            reward = 0;
        }

        return reward;
    }

    function _updateReferInfo(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i=0; i<referDepth; i++) {
            if (upline != address(0)) {
                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.add(_amount);
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function _updateReward(address _user, uint256 _amount, uint256 _prevMax) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;

        bool isDistributed;
        bool shouldDistribute;
        if (_amount > _prevMax || user.depositDistributed < 8) {
            shouldDistribute = true;
        }

        if (_amount > _prevMax) {
            user.depositDistributed = 0;
        }

        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                uint256 newAmount = _amount;

                uint256 maxFreezing = getMaxFreezing(upline);
                if (maxFreezing < _amount && upline != defaultRefer) {
                    newAmount = maxFreezing;
                }

                newAmount = _returnDynamicReward(_user, upline, newAmount);

                RewardInfo storage upRewards = rewardInfo[upline];
                uint256 reward;

                if(i > 4) {
                    if (userInfo[upline].level >= 3 && upRewards.blueDiamondReceived < maxBlueDiamondFreeze) {
                        reward = newAmount.mul(blueDiamondLevels[i - 5]).div(baseDivider);
                        upRewards.blueDiamondFreezed = upRewards.blueDiamondFreezed.add(reward);
                        upRewards.blueDiamondReceived = upRewards.blueDiamondReceived.add(reward);
                    } 
                } else if(i > 0) {
                    if(userInfo[upline].level >= 2) {
                        reward = newAmount.mul(diamondLevels[i - 1]).div(baseDivider);
                        upRewards.levelReleased = upRewards.levelReleased.add(reward);
                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                    }
                } else if(shouldDistribute) {
                    reward = newAmount.mul(directPercents).div(baseDivider);
                    upRewards.directs = upRewards.directs.add(reward);
                    userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                    
                    isDistributed = true;
                }

                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }

        if (isDistributed) {
            user.depositDistributed = (user.depositDistributed).add(1);
        }
    }

    function _updateInfinity(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        uint256 layer = 1;
        for(int i=0; i<50; i++) {
            if(upline != address(0)) {
                if(userInfo[upline].level >= 4) {
                    uint256 newAmount = _amount;
                    uint256 maxFreezing = getMaxFreezing(upline);
                    if (maxFreezing < _amount && upline != defaultRefer) {
                        newAmount = maxFreezing;
                    }

                    newAmount = _returnDynamicReward(_user, upline, newAmount);

                    RewardInfo storage upRewards = rewardInfo[upline];

                    if(layer <= 5 && upRewards.crownDiamondReceived[0] < maxInfinityL1toL5) {
                        uint256 reward = newAmount.mul(infiniteRewardPercents).div(baseDivider);
                        upRewards.crownDiamondReceived[0] = upRewards.crownDiamondReceived[0].add(reward);
                        upRewards.infinityBonusReleased = upRewards.infinityBonusReleased.add(reward); 
                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                    } else if(layer > 5 && upRewards.crownDiamondReceived[1] < maxCrownDiamondFreeze) {
                        uint256 reward = newAmount.mul(infiniteRewardPercents).div(baseDivider);
                        upRewards.infinityFreezed = upRewards.infinityFreezed.add(reward); 
                        upRewards.crownDiamondReceived[1] = upRewards.crownDiamondReceived[1].add(reward);
                    }

                    break;
                } else {
                    upline = userInfo[upline].referrer;
                }

                layer = layer.add(1);
            } else {
                break;
            }
        }
    }

    function getMaxFreezing(address _user) public view returns (uint256) {
        uint256 maxFreezing;
        for(uint256 i = orderInfos[_user].length; i > 0; i--){
            OrderInfo storage order = orderInfos[_user][i - 1];
            if(order.unfreeze > block.timestamp){
                if(order.amount > maxFreezing){
                    maxFreezing = order.amount;
                }
            }else{
                break;
            }
        }
        return maxFreezing;
    }

    function _setFreezeReward(uint256 _bal) private {
        if(balReached) {
            if (_bal <= AllTimeHigh.mul(balDownRateSL1).div(baseDivider) && !isStopLoss20ofATH) {
                isStopLoss20ofATH = true;
                balDownHitAt = AllTimeHigh;
                lastFreezed = block.timestamp;
                depositFromSupportFunds();
            } else if (isStopLoss20ofATH && _bal >= balDownHitAt.mul(balRecover).div(baseDivider)) {
                isStopLoss20ofATH = false;
                isRecoveredFirstTime = true;
            }

            if (isStopLoss20ofATH && _bal <= AllTimeHigh.mul(balDownRateSL2).div(baseDivider)) {
                isStopLoss40ofATH = true;
            } else if (isStopLoss40ofATH && _bal >= balDownHitAt.mul(balRecover).div(baseDivider)) {
                isStopLoss40ofATH = false;
            }

            if(_bal <= 50e6) {
                depositFromSupportFunds();
                balanceHitZero = true;
            }
        }
    }

    function withdraw() external {
        RewardInfo storage userRewards = rewardInfo[msg.sender];
        distributePoolRewards();
        (uint256 staticReward, uint256 staticlockusdt) = _calCurStaticRewards(msg.sender);
        uint256 lockusdtAmt = staticlockusdt;
        uint256 withdrawable = staticReward;

        (uint256 dynamicReward, uint256 dynamiclockusdt) = _calCurDynamicRewards(msg.sender);
        withdrawable = withdrawable.add(dynamicReward);
        lockusdtAmt = lockusdtAmt.add(dynamiclockusdt);

        UserInfo storage userin = userInfo[msg.sender];

        userRewards.lockusdt = userRewards.lockusdt.add(lockusdtAmt);

        userRewards.statics = 0;
        userRewards.directs = 0;
        userRewards.levelReleased = 0;
        userRewards.blueDiamondReleased = 0;
        userRewards.infinityBonusReleased = 0;
        
        userRewards.more1k = 0;
        userRewards.booster = 0;
        withdrawable = withdrawable.add(userRewards.capitals);
        userRewards.capitals = 0;

        if(userin.maxDeposit >= 1000e6 && withdrawable >= 10e6) {
            withdrawable = withdrawable.sub(10e6);
        }
        
       
        usdt.safeTransfer(msg.sender, withdrawable);
        uint256 bal = usdt.balanceOf(address(this));
        _setFreezeReward(bal);

        emit Withdraw(msg.sender, withdrawable);
    }

    function _calCurStaticRewards(address _user) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.statics;
        uint256 lockusdtAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        uint256 withdrawable = totalRewards.sub(lockusdtAmt);
        return(withdrawable, lockusdtAmt);
    }

    function _calCurDynamicRewards(address _user) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = (userRewards.directs).add(userRewards.levelReleased);
        totalRewards = totalRewards.add(userRewards.more1k).add(userRewards.booster).add(userRewards.blueDiamondReleased).add(userRewards.infinityBonusReleased);

        uint256 lockusdtAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);

        uint256 withdrawable = totalRewards.sub(lockusdtAmt);
        return(withdrawable, lockusdtAmt);
    }

    function depositBylockusdt(uint256 _amount) external {
        require(_amount >= minDeposit && _amount.mod(minDeposit) == 0, "amount err");
        require(orderInfos[msg.sender].length == 0, "First depositors can only use this function");
        uint256 lockusdtLeft = getCurlockusdt(msg.sender);
        if(lockusdtLeft > _amount.div(2)) {
            lockusdtLeft = _amount.div(2);
        }
        usdt.safeTransferFrom(msg.sender, address(this), _amount.sub(lockusdtLeft));
        rewardInfo[msg.sender].lockusdtDebt = rewardInfo[msg.sender].lockusdtDebt.add(lockusdtLeft);
        _deposit(msg.sender, _amount);
        emit DepositBylockusdt(msg.sender, _amount);
    }

    function getCurlockusdt(address _user) public view returns(uint256){
        (, uint256 staticlockusdt) = _calCurStaticRewards(_user);
        (, uint256 dynamiclockusdt) = _calCurDynamicRewards(_user);
        return rewardInfo[_user].lockusdt.add(staticlockusdt).add(dynamiclockusdt).sub(rewardInfo[_user].lockusdtDebt);
    }

    function getCurclaimableusdt(address _user) public view returns(uint256){
        (uint256 staticReward,) = _calCurStaticRewards(_user);
        (uint256 dynamicReward,) = _calCurDynamicRewards(_user);
        return staticReward.add(dynamicReward);
    }

    function transferBylockusdt(address _receiver, uint256 _amount) external {
        require(_amount >= minDeposit.div(2) && _amount.mod(minDeposit.div(2)) == 0, "amount err");
        require(userInfo[_receiver].referrer != address(0), "Receiver should be registrant");
        uint256 lockusdtLeft = getCurlockusdt(msg.sender);
        require(lockusdtLeft >= _amount, "insufficient Locked USDT");
        rewardInfo[msg.sender].lockusdtDebt = rewardInfo[msg.sender].lockusdtDebt.add(_amount);
        rewardInfo[_receiver].lockusdt = rewardInfo[_receiver].lockusdt.add(_amount);
        emit TransferBylockusdt(msg.sender, _receiver, _amount);
    }

    function getDayMore1kLength(uint256 _day) external view returns(uint256) {
        return dayMore1kUsers[_day].length;
    }

    function getTeamUsersLength(address _user) external view returns(uint256) {
        UserInfo storage user = userInfo[_user];
        return user.teamNum;
    }

    function getOrderLength(address _user) public view returns(uint256) {
        return orderInfos[_user].length;
    }

    function getDepositorsLength() external view returns(uint256) {
        return depositors.length;
    }

    function getTeamDeposit(address _user) public view returns(uint256, uint256, uint256){
        uint256 totalTeam;
        uint256 maxTeam;
        uint256 otherTeam;
        for (uint256 i = 0; i < teamUsers[_user][0].length; i++) {
            uint256 userTotalTeam = userInfo[teamUsers[_user][0][i]].teamTotalDeposit.add(userInfo[teamUsers[_user][0][i]].totalDeposit);
            totalTeam = totalTeam.add(userTotalTeam);
            if (userTotalTeam > maxTeam) {
                maxTeam = userTotalTeam;
            }
        }

        otherTeam = totalTeam.sub(maxTeam);
        return (maxTeam, otherTeam, totalTeam);
    }

    function depositFromSupportFunds() private {
        uint256 allowanceAmount = usdt.allowance(supportFundAccount, address(this));
        uint256 _bal = usdt.balanceOf(supportFundAccount);
        if(allowanceAmount >= _bal) {
            usdt.safeTransferFrom(supportFundAccount, address(this), _bal);
        } else if(allowanceAmount > 0) {
            usdt.safeTransferFrom(supportFundAccount, address(this), allowanceAmount);
        }
    }

    function _checkRegistered(address _user) public view returns(bool) {
        UserInfo storage user = userInfo[_user];
        if(user.referrer != address(0)) {
            return true;
        }
        return false;
    }

    function getMyTeamNumbers(address _user) public view returns(uint256) {
        return myTeamUsers[_user].length;
    }

    function _updateDepositors(address _user) private {
        bool contains = false;
        for (uint256 i = 0; i < depositors.length; i++) {
            if(_user == depositors[i]){
                contains = true;
                break;
            }
        }
        if(!contains){
            depositors.push(_user);
        }
    }
     

}

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}