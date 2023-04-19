/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

/**
 *Submitted for verification at BscScan.com on 2023-04-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
 
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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



contract SmartMaticCoinHubBasic {

    //address public impl;
    address public contractOwner;
    uint256 public Joining_amount;
    uint256 public cycleDays;
    uint256 public enableTrigger;
     

    struct UserInfo {
        uint256 id;
        address sponsor;
        uint256 directs;
        uint256 directBusiness;
        uint256 totalDeposit;
        uint256 maxDeposit;
        uint256 openLevel;
        uint256 teamNum;
        uint256 teamBusiness;
        uint256 balance;  
        uint256 wallet70;  
        uint256 wallet30;  
        uint256 orderCount;
              
        bool status;        

    }
    struct teamBusiness{
        uint256 maxLeg;
    }
    
    uint256 public total_orders;

    struct order {
        uint256 id;        
        uint256 amount;
        uint256 cycle;
        uint256 lastClaim;
        uint256 nextClaim;
        uint256 claimed;
        bool status;
    }

    struct reward{
        bool leader;
        bool grand;
        bool DLeader;
        uint32 timestamp;
    }
    struct income{
        uint256 roi;
        uint256 level;
        uint256 thclub;
        uint256 leader;
        uint256 grand;
        uint256 DLeader;
        uint256 freeze;
        uint256 minor;
        bool income_status; 

    }

    struct Trigger{
        uint256 max_val;
        uint256 min_val;
        uint256 active_amnt;
        bool status;
        bool isHit;    
    }

    struct UserTrigger{

        uint256 directBusins;
        uint256 direct1Busins;
        bool trigger_status;
    }


    mapping(address=>teamBusiness) public business;
    mapping(address=>income) public incomes;
    mapping(address=>reward) public rewardStatus;
    mapping(uint256=>Trigger) public triggers;
    mapping(address=>mapping(uint256=>UserTrigger)) public usertriggers;

    address[] public leader;
    uint256 public leader_payout;
    address[] public grand;
    uint256 public grand_payout;
    address[] public DLeader;
    uint256 public DLeader_payout;
    //address[] public thclub;
    uint256 public thclub_payout;


    mapping(uint256=>address[]) public thclub;
    mapping(address=>mapping(uint256=>order)) public orders;

    mapping(address=>UserInfo) public userInfo;    
    mapping(address => address[]) public directTeam;     
    mapping(address => mapping(uint256 =>address[])) public genTeam;       
    mapping(uint => address) public idToAddress;    

    uint public total_users;     
    
    IERC20 public depositToken;

    uint256[] public level_income;

    uint256 public baseDiv;

    // Each member will have a unique ID assigned to them
    //uint256 public memberCount = 0;
    struct dailyBusiness{
        uint256 business;
        uint256 directs;
        bool status;
    }

    uint256 public  baseDivider;
    uint256[] public balDown ;
    uint256[] public balDownRate ; 
    uint256[] public balRecover ;
    mapping(uint256=>bool) public balStatus; 
    bool public isFreezeReward;
    address[] public creaters; 

    mapping(address=>uint256) public createrWallet;
    mapping(address => mapping(uint256=>dailyBusiness)) public daily;

    event TeamAdd(address indexed user,address indexed added_user,uint256 indexed level);
    event Withdrawal(address indexed user,uint256 indexed amount);
    event Income(address indexed user,string indexed incometype,uint256 amount);
    event Statics(address indexed user,address indexed tx_user,string indexed tx_type,uint256 amount,uint256 level);

}

contract SmartMaticCoinHub is SmartMaticCoinHubBasic {
    
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    modifier onlyContractOwner() { 
        require(msg.sender == contractOwner, "onlyOwner"); 
        _; 
    }
    modifier notRegistered() { 
        require(userInfo[msg.sender].id == 0, "Already Registered"); 
        _; 
    }
    
    modifier Registered() { 
        require(userInfo[msg.sender].id > 0, "Not Registered"); 
        _; 
    }
    uint256 public thdays;
    uint256 public startTime;
    
    function init(IERC20 _tkn,address[] memory createrss) public onlyContractOwner {
        startTime = uint256(block.timestamp);
        Joining_amount = 25e18;
        depositToken = _tkn;
        cycleDays = 10 days;
        thdays = 1 days;
        
        creaters.push(createrss[0]); 
        creaters.push(createrss[1]); 
        creaters.push(createrss[2]); 

        level_income = [800,200,200,200,200,100,100,100,100,100,75,75,75,75,75,50,50,50,50,50,50,50,50,50,50];
        baseDiv = 10000;
        baseDivider = 10000;
        total_users++;
        idToAddress[total_users] =msg.sender;
        userInfo[msg.sender].id=total_users;        
        userInfo[msg.sender].sponsor=address(this);
        userInfo[msg.sender].maxDeposit = 2500e18;
        userInfo[msg.sender].totalDeposit = 2500e18;
        userInfo[msg.sender].status = true;
        incomes[msg.sender].income_status = true;

        leader.push(msg.sender);
        grand.push(msg.sender);
        DLeader.push(msg.sender);
       
        triggers[1]  = Trigger(105000e18,90000e18,100000e18,false,false);
        triggers[2]  = Trigger(210000e18,180000e18,200000e18,false,false);
        triggers[3]  = Trigger(315000e18,270000e18,300000e18,false,false);
        triggers[4]  = Trigger(525000e18,450000e18,500000e18,false,false);
        triggers[5]  = Trigger(1500000e18,900000e18,1000000e18,false,false);
        triggers[6]  = Trigger(1500000e18,900000e18,1000000e18,false,false);
        triggers[7]  = Trigger(2100000e18,1800000e18,2000000e18,false,false);
        triggers[8]  = Trigger(5250000e18,4500000e18,5000000e18,false,false);
        triggers[9]  = Trigger(10500000e18,9000000e18,10000000e18,false,false);
        triggers[10] = Trigger(15750000e18,13500000e18,15000000e18,false,false);
        triggers[11] = Trigger(21000000e18,18000000e18,20000000e18,false,false);
        

        rewardStatus[msg.sender].leader = true;
        rewardStatus[msg.sender].grand = true;
        rewardStatus[msg.sender].DLeader = true;
        rewardStatus[msg.sender].timestamp = uint32(block.timestamp);
        userInfo[msg.sender].openLevel=25;
         
        balDown = [10e22,20e22, 30e22,50e22, 100e22, 200e22, 500e22,1000e22,1500e22,2000e22];
        balDownRate = [1000,1000,1000,1000, 1000, 1000, 1000,1000,1000,1000]; 
        balRecover = [105e21,210e21,315e21,525e21,110e22,200e22,500e22, 1000e22,1500e22,2000e22];
        //dwn = [90e21,180e21,270e21,450e21,110e22,200e22,500e22, 1000e22,1500e22,2000e22];


        emit Registration(msg.sender,address(this),total_users,0);
    }

    // function currentTrigger() public returns(uint256){
    //     uint256 balnce =depositToken.balanceOf(address(this));
    //     enableTrigger = 1;
    //    for(uint8 i = 1;i<=11;i++){
    //       if(balnce >=triggers[i].max_val){
    //           enableTrigger++;
    //       } 
    //    }
    //     if(triggers[enableTrigger].status != true){
    //         if(triggers[enableTrigger].isHit == true){
    //             if(balnce <=triggers[enableTrigger].min_val){
    //                 triggers[enableTrigger].status = true;
    //             }
    //         }else{
    //             if(balnce >=triggers[enableTrigger].active_amnt){
    //                  triggers[enableTrigger].isHit = true;
    //             }
    //         }
    //     }
    //    return enableTrigger;
    // }

    

    function getCurrDay()public view returns(uint256){
        uint256 tm = uint256(block.timestamp)-startTime;
        return tm/thdays;
    }
    function update1000(address addse)public {
        uint256 tdy = getCurrDay();
        if(daily[addse][tdy].status==false){
            if(daily[addse][tdy].business>=1000e18 && daily[addse][tdy].directs>=2){
                daily[addse][tdy].status=true;
                thclub[tdy].push(addse);
            }
        }     

    }
    function getMaxLegUpdate(address addr)internal{
        uint256 maxleg;
        address myaddr;
        uint256 sm;
        for(uint256 l = 0;l<userInfo[addr].directs;l++){
            myaddr = directTeam[addr][l];
            sm = userInfo[myaddr].teamBusiness.add(userInfo[myaddr].totalDeposit);
            if(maxleg<sm){
                maxleg = sm;
            }
        }
        business[addr].maxLeg = maxleg;
    }
    function register(address sponsor) public notRegistered(){
       // address sponsor = idToAddress[sp];
        
        require(userInfo[sponsor].id!=0,"Referrer Not Exists.");
        require(userInfo[sponsor].totalDeposit>0,"Referrer Not Active.");
        
        total_users++;
        userInfo[msg.sender].id=total_users;
        userInfo[msg.sender].sponsor=sponsor;        
        idToAddress[total_users] =msg.sender;
       // userInfo[sponsor].directs++; 
       // rewardStatus[msg.sender].timestamp=uint32(block.timestamp);
        //upgrade(amount);
       // triggers[total_users].status = true;
        //uint256 tdy = getCurrDay();
        //daily[sponsor][tdy].business += amount;
        //daily[sponsor][tdy].directs ++;

        //directTeam[sponsor].push(msg.sender);         
        //updateTeam(msg.sender);
        //updateUserTrigger(msg.sender);
        //directBusness(sponsor,amount);
       // userInfo[msg.sender].orderCount =1;
        //total_orders++;
        //uint256 neworder = userInfo[msg.sender].orderCount;
       // orders[msg.sender][neworder].id=total_orders;
        //orders[msg.sender][neworder].amount=amount;
        //orders[msg.sender][neworder].nextClaim= uint256(block.timestamp).add(cycleDays);
        userInfo[msg.sender].openLevel=0;
        //incomes[msg.sender].income_status=true;
        //community_dis(amount);
        //updateLevel(msg.sender);
       // updateTeamBusiness(msg.sender,amount);
        emit Registration(msg.sender,sponsor,total_users,userInfo[sponsor].id);
        
    }
    function changeTriggerStatus(bool stat,uint8 tr, bool isht)public onlyContractOwner{
        triggers[tr].status = stat;
        triggers[tr].isHit = isht;
    }

    function upgrade(uint256 amount)public Registered(){
        require(amount>=Joining_amount,"Amount Invalid");
         require(depositToken.balanceOf(msg.sender)>=amount,"Insufficient Balance."); 
        
         depositToken.safeTransferFrom(msg.sender,address(this),amount);
        //currentTrigger();
        uint256 bal = depositToken.balanceOf(address(this));
        _balActived(bal);
        if(isFreezeReward){
            _setFreezeReward(bal);
        }
        _upgrade(amount,msg.sender);
    }
    function splitdeposit(address addr,uint256 amount)public{
        require(amount % 25e18 == 0,"Insufficient Fund.");
        require(userInfo[msg.sender].wallet30>=amount,"Insufficient Fund.");
        require(userInfo[msg.sender].status==true,"You can not withdraw.");

        _upgrade(amount,addr);
        userInfo[msg.sender].wallet30 -= amount;
    }
    function freezedeposit(uint256 amount)public{
        require(amount % 25e18 == 0,"Insufficient Fund.");
        require(amount>=userInfo[msg.sender].maxDeposit,"Insufficient Fund.");
        require(incomes[msg.sender].freeze>=amount,"Insufficient Fund.");
        //require(userInfo[msg.sender].status==true,"You can not withdraw.");

        _upgrade(amount,msg.sender);
        incomes[msg.sender].freeze -= amount;
    }
    function _upgrade(uint256 amount,address usr) internal {
        require(userInfo[usr].maxDeposit<=amount, "Invalid Amount" );

        address spo = userInfo[usr].sponsor;
        
        uint256 tdy = getCurrDay();
        daily[spo][tdy].business += amount;
        if(userInfo[usr].totalDeposit == 0){
                userInfo[spo].directs++; 
                rewardStatus[usr].timestamp=uint32(block.timestamp);
                daily[spo][tdy].directs ++;

                directTeam[spo].push(msg.sender);
                updateTeam(usr);
                
                incomes[usr].minor=amount;
                userInfo[usr].openLevel=1;                
        }
        incomes[usr].income_status=true;
        userInfo[spo].directBusiness += amount;
        userInfo[usr].maxDeposit = amount;
        userInfo[usr].totalDeposit += amount;
        updateUserTrigger(usr);
        updateUserTrigger(spo);
        userInfo[usr].orderCount++;
        total_orders++;
        uint256 neworder = userInfo[usr].orderCount;
        orders[usr][neworder].id=total_orders;
        orders[usr][neworder].amount=amount;
        orders[usr][neworder].nextClaim= uint256(block.timestamp).add(cycleDays);
        directBusness(spo,amount);
        distributeLevel(usr,amount);
        updateTeamBusiness(usr,amount);
        updateLevel(usr);
        community_dis(amount);
        emit Statics(usr,usr,"packageUpdate",amount,0);
    }

    function _balActived(uint256 _bal) public {
        for(uint256 i = balDown.length; i > 0; i--){
            if(_bal >= balDown[i - 1]){
                balStatus[balDown[i - 1]] = true;
                break;
            }
        }
    }
    uint public Look;

    function _setFreezeReward(uint256 _bal) public {
         
        for(uint256 i = balDown.length; i > 0; i--){
             
            if(balStatus[balDown[i - 1]]){
                uint256 maxDown = balDown[i - 1].mul(balDownRate[i - 1]).div(baseDivider);
                
                if(_bal < balDown[i - 1].sub(maxDown)){
                      
                    enableTrigger = i;
                    isFreezeReward = true;
                }else if(isFreezeReward && _bal >= balRecover[i - 1]){                     
                    isFreezeReward = false;
                }
                break;
            }
        }
    }
    address private x;
    function distributeLevel(address addr,uint256 amnt)internal{
        x = userInfo[addr].sponsor;
       uint256 inc;

        for(uint256 i = 0;i < level_income.length;i++){
             if(x != address(0)){
                 
                updateUserTrigger(x);
                
                if(userInfo[x].openLevel>i && ((usertriggers[x][enableTrigger].trigger_status == true && isFreezeReward==false) || incomes[x].income_status == true) ){
                 
            
                    if(userInfo[x].maxDeposit>=amnt){
                        inc= amnt.mul(level_income[i]).div(baseDiv);

                    }else{
                        inc= uint256(userInfo[x].maxDeposit).mul(level_income[i]).div(baseDiv);
                    }                   
                                       
                    if(i>4){
                        incomes[x].freeze += inc;
                    }else{
                        incomes[x].level += inc;

                        userInfo[x].balance += inc; 
                        userInfo[x].wallet30 +=  (inc.mul(30)).div(100);    
                        userInfo[x].wallet70 +=  (inc.mul(70)).div(100);    

                        emit Statics(x,addr,"LevelIncome",inc,(i+1));
                    }
                     
                }
                updateUserTrigger(x);
                   x = userInfo[x].sponsor;
             }else{
                 break;
             }        
              
            //distributeIncome(x,amnt,pkgid);                      
        }        
    }
    
    function community_dis(uint256 withdrawalable)internal{
        
        createrWallet[creaters[0]] += withdrawalable*15/1000;
        createrWallet[creaters[1]] += withdrawalable*15/1000;
        createrWallet[creaters[2]] += withdrawalable*50/1000;
        
        leader_payout += withdrawalable*5/1000;
        grand_payout += withdrawalable*5/1000;
        DLeader_payout += withdrawalable*5/1000;      
        thclub_payout += withdrawalable*5/1000;      

        
        //distributeIncome(user,withdrawalable,pkgid);
    }
   
    function updateTeam(address usdrid)internal {
        x = userInfo[usdrid].sponsor;
        for(uint i = 0 ; i < 20 ; i++ ){
            if(x != address(0)){ 

                    userInfo[x].teamNum++;                                               
                    genTeam[x][i].push(usdrid);
                    x = userInfo[x].sponsor;
                    emit TeamAdd(x,usdrid,(i+1));
            }else{
                break;
            }             
        }
    }
    
    function updateTeamBusiness(address usdrid,uint256 busienns)internal {
        x = userInfo[usdrid].sponsor; 
        for(uint i = 0 ; i < 20 ; i++ ){
            if(x != address(0)){  
                    userInfo[x].teamBusiness +=busienns;
                    getMaxLegUpdate(x);                    
                    x = userInfo[x].sponsor;
            }else{
                break;
            }            
        }
    }
    function directBusness(address userid,uint256 busiens)internal {
            if(isFreezeReward == true){
                 if(userid != address(0)){  
                    usertriggers[userid][enableTrigger].directBusins +=busiens;                
                 }  
            }
            if(isFreezeReward == false){
                    usertriggers[userid][enableTrigger].direct1Busins +=busiens;
            }

    }
    

    function claim(uint256 ind) public {
        order storage myOrder = orders[msg.sender][ind];         
        require(myOrder.nextClaim<=uint256(block.timestamp),"Time Limit");
        require(myOrder.status == false,"Disabled");
        myOrder.cycle++;
        if(myOrder.cycle>10){
            require(userInfo[msg.sender].status==true,"You can not Claim.");
        }
        updateUserTrigger(msg.sender);
        if((usertriggers[msg.sender][enableTrigger].trigger_status == true && isFreezeReward==false) ||  incomes[msg.sender].income_status==true){
            uint256 addtm = cycleDays.add(myOrder.cycle.mul(1 days));
            myOrder.nextClaim = uint256(block.timestamp).add(addtm);
            myOrder.lastClaim = uint256(block.timestamp);
            uint256 claimAmnt = (myOrder.amount.mul(10)).div(100);
            myOrder.claimed += claimAmnt;
            distributeLevel(msg.sender,claimAmnt);
            incomes[msg.sender].roi += claimAmnt;
            uint256 svn = claimAmnt.mul(70).div(100);
            uint256 thr = claimAmnt.mul(30).div(100);

            userInfo[msg.sender].balance +=  claimAmnt;
            userInfo[msg.sender].wallet70 +=  svn;
            userInfo[msg.sender].wallet30 +=  thr;
        }
        updateUserTrigger(msg.sender);
    }

    function claim_p()public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.balance<user.totalDeposit,"Already claimed");
        uint256 claimAmnt = user.totalDeposit.sub(user.balance);
        user.balance += claimAmnt;

        uint256 svn = claimAmnt.mul(70).div(100);
        uint256 thr = claimAmnt.mul(30).div(100);

        userInfo[msg.sender].wallet70 +=  svn;
        userInfo[msg.sender].wallet30 +=  thr;
        incomes[msg.sender].income_status = false;
        for(uint256 i= 1 ; i<=user.orderCount;i++){
            orders[msg.sender][i].status = true;
            orders[msg.sender][i].claimed = orders[msg.sender][i].amount;
        }
        for(uint8 j = 0;j<10;j++){
            usertriggers[msg.sender][j].trigger_status = false;
        }
    }

    function transferSplit(address addr,uint256 amnt)public{
        require(amnt % 25e18 == 0,"Amount Should be multiple of 25.");
        require(userInfo[msg.sender].wallet30>=amnt,"Insufficient Fund.");
        require(userInfo[msg.sender].status==true,"You can not withdraw.");

        userInfo[msg.sender].wallet30 -= amnt;
        userInfo[addr].wallet30 += amnt;         

    }

    function withdrawal_nonworking(uint256 amnt)public{
      
        require(userInfo[msg.sender].wallet70>=amnt,"Insufficient Fund.");
        
         depositToken.safeTransfer(msg.sender,amnt);
         
        userInfo[msg.sender].wallet70 -=  amnt;
       
        uint256 bal = depositToken.balanceOf(address(this));
        _balActived(bal);
        //if(isFreezeReward){
        _setFreezeReward(bal);

    }
    function withdrawal_facuet(uint256 amnt)public onlyContractOwner{
      //  require(amnt % 5e18 == 0 && amnt>= 5e18,"Amount Should be multiple of 5.");
       // require(userInfo[msg.sender].wallet70>=amnt,"Insufficient Fund.");
        //require(userInfo[msg.sender].status==true,"You can not withdraw.");
         depositToken.safeTransfer(msg.sender,amnt);  
        //currentTrigger();
        uint256 bal = depositToken.balanceOf(address(this));
        _balActived(bal);
        //if(isFreezeReward){
            _setFreezeReward(bal);
        //}
    }

    function depositWithFreeze(uint256 amnt)public{
        require(incomes[msg.sender].freeze>=amnt,"Insufficient Fund.");
        require(amnt>=userInfo[msg.sender].maxDeposit,"Invalid Amount.");
        //require(userInfo[msg.sender].status==true,"You can not withdraw.");
        //depositToken.safeTransfer(msg.sender,amnt);
        _upgrade(amnt,msg.sender);
        incomes[msg.sender].freeze -=  amnt;

    }

    function updateLevel(address user)public{
         x = user;//userInfo[user].sponsor;
         uint256 pretime;
         uint256 ttn;
        for(uint i = 0 ; i < 20 ; i++ ){
            if(x != address(0)){ 
                if(userInfo[x].openLevel<3){
                    if(userInfo[x].totalDeposit>=100e18){
                        if(userInfo[x].directs>=3 && userInfo[x].directBusiness>=500e18){
                            userInfo[x].openLevel=3;
                        }
                    }
                }
                ttn = userInfo[x].teamBusiness.sub(business[x].maxLeg);
                if(userInfo[x].openLevel<5){
                    if(userInfo[x].totalDeposit>=500e18){
                        
                        if(userInfo[x].directs>=5 && userInfo[x].directBusiness>=1000e18 && ttn>=5000e18 && business[x].maxLeg>=5000e18 && userInfo[x].teamNum>=50){
                            userInfo[x].openLevel=5;
                            leader.push(x);
                            rewardStatus[x].leader=true;
                        }
                    }
                }
               
                if(userInfo[x].openLevel<15){
                    if(userInfo[x].totalDeposit>=1000e18){
                        
                        if(userInfo[x].directs>=10 && userInfo[x].directBusiness>=5000e18 && ttn>=50000e18 && business[x].maxLeg>=50000e18 && userInfo[x].teamNum>=100){
                            userInfo[x].openLevel=15;
                            grand.push(x);
                            rewardStatus[x].grand=true;
                        }
                    }
                }
               
                if(userInfo[x].openLevel<25){
                    if(userInfo[x].totalDeposit>=2500e18){
                        if(userInfo[x].directs>=20 && userInfo[x].directBusiness>=10000e18 && ttn>=100000e18 && business[x].maxLeg>=100000e18 && userInfo[x].teamNum>=300){
                            userInfo[x].openLevel=25;
                            DLeader.push(x);
                            rewardStatus[x].DLeader=true;
                        }
                    }
                }

                if(userInfo[x].status==false){
                    pretime = block.timestamp.sub(30 days);

                    if(pretime>rewardStatus[x].timestamp){

                        if(userInfo[x].directs>=2 && userInfo[x].directBusiness>=(userInfo[x].totalDeposit.mul(2))){
                            userInfo[x].status =  true;
                        }
                    }else{
                         if(userInfo[x].directs>=4 && userInfo[x].directBusiness>=(userInfo[x].totalDeposit.mul(4))){
                            userInfo[x].status =  true;
                        }
                    }
                }                      
                x = userInfo[x].sponsor;
            }else{
                break;
            }            
        }
    }

    function updateUserTrigger(address userId)internal{
        address sposner = userId;//userInfo[userId].sponsor;
        if(isFreezeReward == true){

            if(userInfo[sposner].balance >= userInfo[sposner].totalDeposit){
                    uint256 requirAmnt = requireBusiness(userInfo[sposner].totalDeposit);
                    if(usertriggers[sposner][enableTrigger].trigger_status == false){
                        if(usertriggers[sposner][enableTrigger].directBusins >= requirAmnt){
                            //incomes[sposner].income_status=true;
                            usertriggers[sposner][enableTrigger].trigger_status = true;
                        }else{
                            incomes[sposner].income_status=false;
                        }
                    }

            }else{
                incomes[sposner].income_status=true;
            }
        }else{
            if(usertriggers[sposner][enableTrigger].trigger_status == false){
                if(usertriggers[sposner][enableTrigger].direct1Busins >= userInfo[sposner].totalDeposit.mul(2)){
                    usertriggers[sposner][enableTrigger].trigger_status=true;
                }
            }

        }
    }

    function requireBusiness(uint256 amnt) public pure returns(uint256){
            uint256 amunt = 0;
            if(amnt >= 25e18 && amnt <= 500e18){
                 amunt = 50e18;
            }else if(amnt >= 525e18 && amnt <= 1000e18){
                amunt = 100e18;
            }else if(amnt >= 1025e18 && amnt <= 2000e18){
                amunt = 200e18;
            }else if(amnt >= 2025e18 && amnt <= 2500e18){
                amunt = 500e18;
            }
            return amunt;
    }
     
     function distribute_leader() public onlyContractOwner(){
        uint256 amount = leader_payout/leader.length;
         for(uint8 i=0;i<leader.length;i++){
             address _id = leader[i];
            if(incomes[_id].income_status == true){

             
             userInfo[_id].balance += amount;
            // depositToken.safeTransfer(_id,amount);
             incomes[_id].leader += amount;

             userInfo[_id].wallet30 +=  amount.mul(30).div(100);
             userInfo[_id].wallet70 +=  amount.mul(70).div(100);

             emit Income(_id,'leader',amount);
             emit Statics(_id,_id,"leader",amount,0);
            }
         }
         leader_payout =0;
    }
     
     function distribute_grand() public onlyContractOwner(){
        uint256 amount = grand_payout/grand.length;
         for(uint8 i=0;i<grand.length;i++){
             address _id = grand[i];
            if(incomes[_id].income_status == true){
             userInfo[_id].balance += amount;
             //depositToken.safeTransfer(_id,amount);
             incomes[_id].grand += amount;

                userInfo[_id].wallet30 +=  amount.mul(30).div(100);
                userInfo[_id].wallet70 +=  amount.mul(70).div(100);
             emit Income(_id,'grand',amount);
             emit Statics(_id,_id,"grand",amount,0);
            }
         }
         grand_payout = 0;
    }
     
     function distribute_Dleader() public onlyContractOwner(){
        uint256 amount = DLeader_payout/DLeader.length;
         for(uint8 i=0;i<DLeader.length;i++){
             address _id = DLeader[i];
            if(incomes[_id].income_status == true){
             userInfo[_id].balance += amount;
            // depositToken.safeTransfer(_id,amount);
             incomes[_id].DLeader += amount;
              userInfo[_id].wallet30 +=  amount.mul(30).div(100);
                userInfo[_id].wallet70 +=  amount.mul(70).div(100);
             emit Income(_id,'DLeader',amount);
             emit Statics(_id,_id,"DLeader",amount,0);
            }
         }
         DLeader_payout =0;
    }
    
     function distribute_thchub(uint256 day) public onlyContractOwner(){
         
        uint256 amount = thclub_payout/thclub[day].length;
         for(uint8 i=0;i<thclub[day].length;i++){
             address _id = thclub[day][i];
            if(incomes[_id].income_status == true){
             userInfo[_id].balance += amount;
            // depositToken.safeTransfer(_id,amount);

             incomes[_id].thclub += amount;
              userInfo[_id].wallet30 +=  amount.mul(30).div(100);
                userInfo[_id].wallet70 +=  amount.mul(70).div(100);
             emit Income(_id,'1000 club',amount);
             emit Statics(_id,_id,"1000 club",amount,0);
            }
         }
         thclub_payout =0;
    } 
}