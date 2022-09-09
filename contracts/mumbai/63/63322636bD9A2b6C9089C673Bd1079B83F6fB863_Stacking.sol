/**
 *Submitted for verification at polygonscan.com on 2022-09-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

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
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);
    
    function burn(uint256 amount) external ;
    
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

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
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

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
            if (returndata.length > 0) {
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

library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeBEP20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeBEP20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

contract Stacking is Ownable {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;
    uint256 public APY;
    uint256 public minimumDepositeAmount;
    uint256 public maximumDepositeAmount;
    IBEP20 public stakedToken=IBEP20(0x0DbC6724fFACF4D4AcEaE8b97661d10176339dD1);
    IBEP20 public rewardToken=IBEP20(0x842B097BD4Ed52d296E967d45F7800c8fEB81A97);
    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] public plans;
    struct Stakes {
        uint256 amount;
        address userAddress;
        uint256 time;
        uint256 stackId;
        bool isWithdrawal;
        uint8 plan;
    }
    
    struct User{
        Stakes[] stake;
    }
    
    mapping(address => User) internal users;
    address[] public stakeholders;
    bool public  hasStartStakcing = true;
    bool public hasStartsale=true;
    uint256 public currentID = 1;

    function toggleStacking ( bool _stacking ) public onlyOwner {
        hasStartStakcing = _stacking;
    }
    function toggleSale ( bool _sale ) public onlyOwner {
        hasStartsale = _sale;
    }

    function setDepositeAmount(uint256 minimumAmount, uint256 maximumAmount) public {
        maximumDepositeAmount = maximumAmount;
        minimumDepositeAmount = minimumAmount;
    }

    function setAPY(uint256 _APY) public onlyOwner {
        APY =_APY;
    }

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].stake.length;
	}

    function userInfo(uint256 amount,uint8 _plan) internal {
        currentID = currentID + 1;
        User storage user = users[msg.sender];
        user.stake.push(Stakes(amount,msg.sender,block.timestamp,currentID,false,_plan));        
    }

    

    function deposite(uint256 amount,uint8 _plan) public {
        require(hasStartStakcing, "Stacking is not Start yet");
        
        require(
            stakedToken.allowance(msg.sender, address(this)) >= amount,
            "please allow fund first"
        );
        stakedToken.safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        userInfo(amount,_plan);
    }
    
    /**
    * @dev Calculates reward for the current time and outputs reward in reward token format. Frontend should divde by rewardTokenDecial to show the formatted figure
    */
    function calclulateReward(address _address,uint256 id) public view returns (uint256) {
        User storage user = users[_address];
        if(user.stake[id].amount > 0) {
            
            uint256 tokensPerSecond = user.stake[id].amount.mul(plans[user.stake[id].plan].time).div(100).div(31536000);
            uint256 depositeTime = user.stake[id].time;
            uint256 currentTime = block.timestamp;
            return (currentTime.sub(depositeTime)).mul(tokensPerSecond);
        } else {
            return uint256(0);
        }
    }

    function withdrawFunds(uint256 amount, IBEP20 _withdrawalCurrency) public onlyOwner {
        IBEP20 withdrawalCurrency = IBEP20(_withdrawalCurrency);
        require(
            withdrawalCurrency.balanceOf(address(this)) >= amount,
            "Contract balance is low"
        );
        withdrawalCurrency.safeTransfer(msg.sender, amount);
    }

    function claim(uint256 id) public {
        User storage user = users[msg.sender];
        uint256 finish = user.stake[id].time.add(plans[user.stake[id].plan].time.mul(1 days));
        require(hasStartStakcing, "Staking isn't started right now!");
        require(user.stake[id].isWithdrawal == false, "Stake already withdrawn!");
        require(user.stake[id].userAddress == msg.sender, "Only stake owner can claim tokens!");
        require(finish <=block.timestamp, "Locking Time is not over yet");
        uint256 reward = calclulateReward(msg.sender,id);

        require(
            rewardToken.balanceOf(address(this)) >= reward,
            "Insufficent Balance in contract please withdraw after sometime "
        );

        require(
            stakedToken.balanceOf(address(this)) >= user.stake[id].amount,
            "Insufficent Balance"
        );

        rewardToken.safeTransfer(user.stake[id].userAddress, reward);
        stakedToken.burn(user.stake[id].amount);
        user.stake[id].isWithdrawal = true;
    }
    // swaping functions

    /**
    * @dev Returns the bep token owner.
    */
    function buyToken(uint256 amount) public {
        require(hasStartsale,"Sale is not started");
        uint256 buyTokens=(amount.div(1e6)).mul(1e18);
        rewardToken.transferFrom(msg.sender,address(this),amount);
        stakedToken.transfer(msg.sender, buyTokens);
    }

    function getConverted(uint256 amount) public pure returns(uint256){
        uint256 buyTokens=(amount.div(1e6)).mul(1e18);
        return buyTokens;
    }
    /**
    * @dev Returns the bep token owner.
    */
    function sellToken(uint256 amount) public {
        require(hasStartsale,"Sale is not started");
        uint256 _rate=amount.mul(75).div(100);
        _rate=_rate.div(1e18).mul(1e6);
        stakedToken.transferFrom(msg.sender,address(this),amount);
        rewardToken.transfer(msg.sender, _rate);
    }

    // get total plans
    function getTotalPlans() public view returns(uint256){
        return plans.length;
    }

    // Get user amount of deposits
    function getTotalUserDeposits(address _address) public view returns(uint256){
        User storage user = users[_address];
        return user.stake.length;
    }

    // GET USER DEPOSIT INFO
    function getUserDepositInformation(address _address,uint256 id) public view returns(uint256 amount,uint256 time,uint256 stackId,bool isWithdrawal,uint256 plan){
        User storage user = users[_address];
        amount = user.stake[id].amount;
        time = user.stake[id].time;
        stackId = user.stake[id].stackId;
        isWithdrawal = user.stake[id].isWithdrawal;
        plan = user.stake[id].plan;        
    }
    
    constructor() {
        plans.push(Plan(730, 20));
        plans.push(Plan(1095, 23));
        plans.push(Plan(1703, 30));  
    }
}