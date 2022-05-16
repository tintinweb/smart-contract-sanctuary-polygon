// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "./GlobalMerchantToken.sol";

contract GMTSTaking {
    string public name = "Yield Farming / Token dApp";
    GlobalMerchantToken public testToken;

    //declaring owner state variable
    address public owner;

    //declaring default APY (default 0.054% daily or 20% APY yearly)
    uint256 public defaultAPY  =  54;

    //declaringAPY for custom staking (default 0.08% daily or 30% APY yearly)
    uint256 public customAPY = 82;

    //declaring APY for custom staking 2 ( default 0.137% daily or 50% APY yearly)

    uint256 public customAPY2 = 137;
  
    //declaring total staked
    uint256 public totalStaked;
    uint256 public customTotalStaked;
    uint256 public customTotalStaked2;

    // uint8 public stakingTimeInterval = 15;
    mapping (address => uint) public stakingTime;
    mapping (address => uint) public customStakingTime;
    mapping (address => uint) public customStakingTime2;

    //starting staking time
    mapping (address => uint) public start1;
    mapping (address => uint) public start2;
    mapping (address => uint) public start3;

    bool public opCooldownEnabled = true;
    mapping (address => bool) public isTimelockExempt;
    // uint256 private date
    
    //users staking balance
    mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public customStakingBalance;
    mapping(address => uint256) public customStakingBalance2;

    //Claimed Vault
    mapping(address => uint256) public Vault1;
    mapping(address => uint256) public Vault2;
    mapping(address => uint256) public Vault3;

    //mapping list of users who ever staked
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public customHasStaked;
    mapping(address => bool) public customHasStaked2;

    //mapping list of users who are staking at the moment
    mapping(address => bool) public isStakingAtm;
    mapping(address => bool) public customIsStakingAtm;
    mapping(address => bool) public customIsStakingAtm2;


    //array of all stakers
    address[] public stakers;
    address[] public customStakers;
    address[] public customStakers2;
    
    constructor(GlobalMerchantToken _testToken) public payable {
        testToken = _testToken;

        //assigning owner on deployment
        owner = msg.sender;
    }

    //stake tokens function

    function stakeTokens(uint256 _amount, uint256 _days,uint256 _minutes) public {
        //must be more than 0
        // require(unlockTime > block.timestamp, "UNLOCK TIME IN THE PAST");
        // require(unlockTime < 10000000000, "INVALID UNLOCK TIME, MUST BE UNIX TIME IN SECONDS");
        // require(_days = 30 && _days = 60 )
        require(_amount > 0, "amount cannot be 0");
        require(stakingTime[msg.sender] < block.timestamp,"Staking Still On Progress");
        stakingTime[msg.sender] = block.timestamp + (_days * 1 days) + (_minutes * 1 minutes);
        start1[msg.sender] = block.timestamp;
        
     
   
        //User adding test tokens
        testToken.transferFrom(msg.sender, address(this), _amount);
        totalStaked = totalStaked + _amount;

        //updating staking balance for user by mapping
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        //checking if user staked before or not, if NOT staked adding to array of stakers
        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        //updating staking status
        hasStaked[msg.sender] = true;
        isStakingAtm[msg.sender] = true;
    }

    //claiming tokens
    function Claim(uint _claim) public returns(uint256) {
            
            uint start = 0;
            uint stakebalance = 0;
            uint totaltime = 0;
            uint apy = 0;
             if(_claim == 1) {
               start = start1[msg.sender];
               stakebalance =  stakingBalance[msg.sender];
               totaltime = stakingTime[msg.sender];
               apy = defaultAPY;
             }
            else if(_claim == 2) {
               start = start2[msg.sender];
               stakebalance =  customStakingBalance[msg.sender];
               totaltime = customStakingTime[msg.sender];
               apy = customAPY;
             }
            else if(_claim == 3) {
               start = start3[msg.sender];
               stakebalance =  customStakingBalance2[msg.sender];
               totaltime = customStakingTime2[msg.sender];
               apy = customAPY2;
             }
             
            uint limit = (totaltime - start ) / 60 ;
            // uint diff = (stakingTime[msg.sender] - block.timestamp) / 60 / 60 / 24; // days calculation 
            //  require(((block.timestamp - stakingTime[msg.sender] ) / 60) > 0, "TESTING" );
             
            uint diff =  (block.timestamp - start) / 60 ; // mins calculation 
            if(diff > limit){
                diff = limit;
            }
            //calculating daily apy for user
            uint256 balance = stakebalance * (apy * diff); // multiply the days to daily apy
            balance = balance / 100000;

            // deducts the rewards already claimed by sender
            balance = balance - Vault1[msg.sender];

            // send the rewards to sender
            if (balance > 0) {
                testToken.transfer(msg.sender, balance);
                //update the rewards claimed
                Vault1[msg.sender] = Vault1[msg.sender] + balance;
            }

            
            return balance;
        
    }

 

    //unstake tokens function

    function unstakeTokens() public {
        //get staking balance for user
        
        uint256 balance = stakingBalance[msg.sender];

        //amount should be more than 0
        require(balance > 0, "amount has to be more than 0");
        require(stakingTime[msg.sender] < block.timestamp,"Your tokens are still lock on staking");   
        
     
        Claim(1);
        //transfer staked tokens back to user
        testToken.transfer(msg.sender, balance);
        totalStaked = totalStaked - balance;
      
        //reseting users staking balance
        stakingBalance[msg.sender] = 0;

        //updating staking status
        isStakingAtm[msg.sender] = false;
        stakingTime[msg.sender] = 0;
        Vault1[msg.sender] = 0;
       
    }

   function Claim11() external view returns  (uint[2] memory) {
            // uint diff = (stakingTime[msg.sender] - block.timestamp) / 60 / 60 / 24; // 40 days 
            // uint diff2 = (stakingTime[msg.sender] - block.timestamp) / 60 / 60 ; //  hrs
            // uint diff3 = (stakingTime[msg.sender] - block.timestamp) / 60 ; //mins;
            uint diff3 = (block.timestamp - start1[msg.sender] ) / 60 ; //mins;
            uint diff4 = (stakingTime[msg.sender] - start1[msg.sender] ) / 60 ; //mins;
            return ([diff3,diff4]);
        }
        //airdropp tokens
    function redistributeRewardsCLaim() public {
        //only owner can issue airdrop
        require(msg.sender == owner, "Only contract creator can redistribute");

        //doing drop for all addresses
        for (uint256 i = 0; i < stakers.length; i++) {
            address recipient = stakers[i];

            //calculating daily apy for user
            uint256 balance = stakingBalance[recipient] * defaultAPY;
            balance = balance / 100000;

            if (balance > 0) {
                testToken.transfer(recipient, balance);
            }
        }
    }

    // different APY Pool
    function customStaking(uint256 _amount, uint256 _days,uint256 _minute) public {
        require(_amount > 0, "amount cannot be 0");
          if ( opCooldownEnabled &&
            !isTimelockExempt[msg.sender]) {
            require(customStakingTime[msg.sender] < block.timestamp,"Staking Still On Progress");
            customStakingTime[msg.sender] = block.timestamp + (_days * 1 days) + (_minute * 1 minutes)  ;
            start2[msg.sender] = block.timestamp;
        }

        testToken.transferFrom(msg.sender, address(this), _amount);
        customTotalStaked = customTotalStaked + _amount;
        customStakingBalance[msg.sender] =
            customStakingBalance[msg.sender] +
            _amount;

        if (!customHasStaked[msg.sender]) {
            customStakers.push(msg.sender);
        }
        customHasStaked[msg.sender] = true;
        customIsStakingAtm[msg.sender] = true;
    }

    function customUnstake() public {
        uint256 balance = customStakingBalance[msg.sender];
        require(balance > 0, "amount has to be more than 0");
        require(customStakingTime[msg.sender] < block.timestamp,"Your tokens are still lock on staking");   
        Claim(2);
        testToken.transfer(msg.sender, balance);
        customTotalStaked = customTotalStaked - balance;
        customStakingBalance[msg.sender] = 0;
        customIsStakingAtm[msg.sender] = false;
        customStakingTime[msg.sender] = 0;
        Vault2[msg.sender] = 0;
    }




       function customStaking2(uint256 _amount, uint256 _days,uint256 _minutes) public {
        require(_amount > 0, "amount cannot be 0");
          if ( opCooldownEnabled &&
            !isTimelockExempt[msg.sender]) {
            require(customStakingTime2[msg.sender] < block.timestamp,"Staking Still On Progress");
            customStakingTime2[msg.sender] = block.timestamp + (_days * 1 days) + (_minutes * 1 minutes)  ;
            start3[msg.sender] = block.timestamp;
        }

        testToken.transferFrom(msg.sender, address(this), _amount);
        customTotalStaked2 = customTotalStaked2 + _amount;
        customStakingBalance2[msg.sender] =
            customStakingBalance2[msg.sender] +
            _amount;

        if (!customHasStaked2[msg.sender]) {
            customStakers2.push(msg.sender);
        }
        customHasStaked2[msg.sender] = true;
        customIsStakingAtm2[msg.sender] = true;
    }

    function customUnstake2() public {
        uint256 balance = customStakingBalance2[msg.sender];
        require(balance > 0, "amount has to be more than 0");
        require(customStakingTime2[msg.sender] < block.timestamp,"Your tokens are still lock on staking");   
        Claim(3);
        testToken.transfer(msg.sender, balance);
        customTotalStaked2 = customTotalStaked2 - balance;
        customStakingBalance2[msg.sender] = 0;
        customIsStakingAtm2[msg.sender] = false;
        customStakingTime2[msg.sender] = 0;
        Vault3[msg.sender] = 0;
    }

 

    //customAPY airdrop
    function customRewards2() public {
        require(msg.sender == owner, "Only contract creator can redistribute");
        for (uint256 i = 0; i < customStakers2.length; i++) {
            address recipient = customStakers2[i];
            uint256 balance = customStakingBalance2[recipient] * customAPY2;
            balance = balance / 100000;

            if (balance > 0) {
                testToken.transfer(recipient, balance);
            }
        }
    }

   


    function cooldownEnabled(bool _status) public{
        require(msg.sender == owner, "Only contract creator can Enable");
        opCooldownEnabled = _status;
    }


     function TimelockExempt(address holder, bool exempt) external  {
        require(msg.sender == owner, "Only contract creator Edit");
        isTimelockExempt[holder] = exempt;
    }

    function changeAPY(uint256 _value) public {
        //only owner can issue airdrop
        require(msg.sender == owner, "Only contract creator can change APY");
        require(
            _value > 0,
            "APY value has to be more than 0, try 100 for (0.100% daily) instead"
        );
        defaultAPY = _value;
    }

    //change APY value for custom staking
    function changeAPY2(uint256 _value) public {
        //only owner can issue airdrop
        require(msg.sender == owner, "Only contract creator can change APY");
        require(
            _value > 0,
            "APY value has to be more than 0, try 100 for (0.100% daily) instead"
        );
        customAPY = _value;
    }
     
    function changeAPY3(uint256 _value) public {
        //only owner can issue airdrop
        require(msg.sender == owner, "Only contract creator can change APY");
        require(
            _value > 0,
            "APY value has to be more than 0, try 100 for (0.100% daily) instead"
        );
        customAPY2 = _value;
    }

    //cliam test 1000 Tst (for testing purpose only !!)
    function claimTst() public {
        address recipient = msg.sender;
        uint256 tst = 1000* 1**9;
        uint256 balance = tst;
        testToken.transfer(recipient, balance);
    }

    function fetchtokens(address _address, uint256 _amount) external {
        IERC20(_address).transfer(this.owner(), _amount);
        emit fetch(_address, _amount);  
    }

    event fetch(address _address, uint256 _amount);
}

/**
 *Submitted for verification at BscScan.com on 2022-05-11
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-26
 */
pragma solidity ^0.8.10;

// SPDX-License-Identifier: Unlicensed
interface IERC20 {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() external view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) external virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() external virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
    }
}

contract GlobalMerchantToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isBlacklisted;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    address public immutable _marketingAndDev;
    address public constant _burn = address(0xdead);

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 5000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "Global Merchant Token";
    string private constant _symbol = "GMT";
    uint8  private constant _decimals = 9;

    uint256 public _taxFee = 5; // 5% redistributed among hodlers
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _burnFee = 0; // 5% burn fee
    uint256 private _previousBurnFee = _burnFee;

    uint256 public marketingAndDevelopment = 5; // 2% Marketing and Development
    uint256 private _previousMarketingAndDev = marketingAndDevelopment;

    uint256 public _maxTxAmount = (_tTotal * 3) / 100; 
    uint256 public _maxWalletToken = (_tTotal * 3) / 100; 
    bool pauseFeature = false;
    address stakingAddress;

    event ExcludeFromReward(address indexed account);
    event IncludeInFee(address indexed account);
    event ExcludeFromFee(address indexed account);
    event IncludeInReward(address indexed account);
    event TaxFeeChange(uint256 oldValue, uint256 newValue);
    event LiquidityFeeChange(uint256 oldValue, uint256 newValue);
    event BurnFeeChange(uint256 oldValue, uint256 newValue);
    event MarketAndDevFeeChange(uint256 oldValue, uint256 newValue);
    event MaxTxAmountChange(uint256 oldValue, uint256 newValue);
    event MaxWalletAmountChange(uint256 oldValue, uint256 newValue);
    event EventBlacklisted(address indexed account, bool value);
    event TransferStuckTokens(
        address indexed token,
        address account,
        uint256 amount
    );
    event TransferStuckBNB(address indexed account, uint256 amount);

    constructor(address marketingAndDev) {
        require(
            marketingAndDev != address(0),
            "Invalid marketing and development address"
        );
        _rOwned[_msgSender()] = _rTotal;
        _marketingAndDev = marketingAndDev;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAndDev] = true;
        _isExcludedFromFee[_burn] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account)
        external
        view
        returns (bool)
    {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        _isBlacklisted[account] = value;
        emit EventBlacklisted(account, value);
    }

    function excludeFromReward(address account) external onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
        emit ExcludeFromReward(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _rOwned[account] = reflectionFromToken(_tOwned[account], false);
                _isExcluded[account] = false;
                _excluded.pop();
                emit IncludeInReward(account);
                (account);
                break;
            }
        }
    }

    function setStakingAddress(address _staking) external onlyOwner {
        stakingAddress = _staking;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFee(account);
    }



    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludeInFee(account);
    }

    function setTaxFeePercent(uint256 newValue) external onlyOwner {
        require(newValue <= 10, "taxFee must be less than or equal to 10");
        _previousTaxFee = newValue;
        _taxFee = newValue;
        emit TaxFeeChange(_previousTaxFee, newValue);
    }

    function setBurnFeePercent(uint256 newValue) external onlyOwner {
        require(newValue <= 3, "burnFee must be less than or equal to  3");
        _previousBurnFee = newValue;
        _burnFee = newValue;
        emit BurnFeeChange(_previousBurnFee, newValue);
    }

    function setMaxTxPercent(uint256 newValue) external onlyOwner {
        require(
            newValue <= 3 * 10**6 * 10**9,
            "transfer amount must be less than or equal to three million"
        );
        emit MaxTxAmountChange(_maxTxAmount, newValue);
        _maxTxAmount = newValue;
    }

    function setMaxWalletAmount(uint256 newValue) external onlyOwner {
        require(
            newValue <= 3844 * 10**3 * 10**9,
            "max wallet amount must be less than or equal to three million eight hundred forty-four thousand"
        );
        emit MaxWalletAmountChange(_maxWalletToken, newValue);
        _maxWalletToken = newValue;
    }

    function setMarketingAndDevFeePercent(uint256 newValue) external onlyOwner {
        require(
            newValue <= 2,
            "marketingAndDevelopment fee must be less than or equal to  2"
        );
        _previousMarketingAndDev = newValue;
        marketingAndDevelopment = newValue;
        emit MarketAndDevFeeChange(_previousMarketingAndDev, newValue);
    }

    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    //Messy code to avoid stack to deep :)

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tTransferAmount = tAmount.sub(calculateTaxFee(tAmount)).sub(
            calculateBurnFee(tAmount)
        );
        tTransferAmount = tTransferAmount.sub(
            calculateMarketingAndDevFee(tAmount)
        );
        uint256 currentRate = _getRate();
        uint256 rTransferAmount = tAmount.mul(currentRate).sub(
            calculateTaxFee(tAmount).mul(currentRate)
        );
        rTransferAmount = rTransferAmount
            .sub(calculateBurnFee(tAmount).mul(currentRate))
            .sub(calculateMarketingAndDevFee(tAmount).mul(currentRate));
        return (
            tAmount.mul(currentRate),
            rTransferAmount,
            calculateTaxFee(tAmount).mul(currentRate),
            tTransferAmount,
            calculateTaxFee(tAmount)
        );
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(10**2);
    }

    function calculateMarketingAndDevFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(marketingAndDevelopment).div(10**2);
    }

    function isPaused(bool status) public {
        pauseFeature = status;
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _burnFee == 0 && marketingAndDevelopment == 0)
            return;
        _taxFee = 0;
        _burnFee = 0;
        marketingAndDevelopment = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _burnFee = _previousBurnFee;
        marketingAndDevelopment = _previousMarketingAndDev;
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            !_isBlacklisted[from] && !_isBlacklisted[to],
            "Blacklisted address"
        );
        require(!pauseFeature,"Trading Paused");
        require(amount > 0, "Transfer amount must be greater than zero");
        
         if (from == stakingAddress) {
           
         
        }
        else {
             if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
            uint256 BalanceRecepient = balanceOf(to);
            require(
                BalanceRecepient + amount <= _maxWalletToken,
                "Exceeds maximum wallet token amount (3,844,000)"
            );
        }

        }

       

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
        if (takeFee) {
            if (_isExcluded[_burn]) {
                _tOwned[_burn] = _tOwned[_burn].add(calculateBurnFee(amount));
            }
            _rOwned[_burn] = _rOwned[_burn].add(
                calculateBurnFee(amount).mul(_getRate())
            );
            if (_isExcluded[_marketingAndDev]) {
                _tOwned[_marketingAndDev] = _tOwned[_marketingAndDev].add(
                    calculateMarketingAndDevFee(amount)
                );
            }
            _rOwned[_marketingAndDev] = _rOwned[_marketingAndDev].add(
                calculateMarketingAndDevFee(amount).mul(_getRate())
            );
            emit Transfer(from, _burn, calculateBurnFee(amount));
            emit Transfer(
                from,
                _marketingAndDev,
                calculateMarketingAndDevFee(amount)
            );
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) {
            removeAllFee();
        }
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        if (!takeFee) {
            restoreAllFee();
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function transferAnyBEP20(
        address _tokenAddress,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address");
        IERC20(_tokenAddress).transfer(_to, _amount);
        emit TransferStuckTokens(_tokenAddress, _to, _amount);
    }

    function transferStuckBNB(address _to, uint256 _amount) external onlyOwner {
        payable(_to).transfer(_amount);
        emit TransferStuckBNB(_to, _amount);
    }
}