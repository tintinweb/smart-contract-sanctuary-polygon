//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

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
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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

interface IToken {
    function sellFeeRecipient() external view returns (address);
}

interface ICustomizedRewards {
    function trigger(address user, uint256 amount, address yieldToken) external;
}

contract STSStaking is Ownable, IERC20 {

    using SafeMath for uint256;

    // name and symbol for tokenized contract
    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;

    // Staked Token
    address public immutable token;

    // Reward Token
    address public immutable reward;

    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public ZERO = 0x0000000000000000000000000000000000000000;

    // User Info
    struct UserInfo {
        uint256 amount; // amount of tokens staked
        uint256 totalExcluded; // tracked reward debt
        uint256 index; // index in holders list
    }
    // Address => UserInfo
    mapping ( address => UserInfo ) public userInfo;

    // List of all holders
    address[] public allHolders;

    // Tracks Dividends
    uint256 public totalRewards;
    uint256 private totalShares;
    uint256 private dividendsPerShare;
    uint256 private constant precision = 10**18;

    // Index of current holder in multi claim
    uint256 public currentMultiClaimHolderIndex;

    // Minimum token holding amount to have rewards claimed via bounty
    uint256 public minHoldingsForAutoClaim = 1;

    // minimum pending rewards needed to be auto claimed
    uint256 public minPendingRewardsForAutoClaim = 1;

    // Staking Fees
    uint256 public stakingFee = 20;
    uint256 public unstakingFee = 20;
    uint256 public reflectFeePercent = 750;
    uint256 private constant FEE_DENOM = 1000;

    // Lets this many users pass in `iterations` when mass claiming if they do not meet the criteria
    uint256 public inelligibleClaimsCheck = 50;

    // Customizable Rewards Contract
    ICustomizedRewards public customizedRewards;

    //events
    event Stake(address indexed user, uint256 amount, uint256 fee);
    event Withdraw(address indexed user, uint256 amount, uint256 fee);
    event ClaimReward(address indexed user, uint256 amount);
    event DepositRewards(uint256 amount);
    event SetStakingFee(uint256 newFee);
    event SetUnstakingFee(uint256 newFee);
    event SetReflectFeePercent(uint256 newFee);
    event SetInelligibleClaimsCheck(uint256 newCheck);
    event SetMinHoldingsForAutoClaim(uint256 newMin);
    event SetMinPendingRewardsForAutoClaim(uint256 newMin);
    event SetCustomizedRewards(address newCustomizedRewards);

    constructor(
        address token_, 
        address reward_, 
        string memory name_, 
        string memory symbol_
    ){
        require(
            token_ != address(0) &&
            reward_ != address(0),
            'Zero Address'
        );
        token = token_;
        reward = reward_;
        _name = name_;
        _symbol = symbol_;
        _decimals = IERC20(token_).decimals();
        emit Transfer(address(0), msg.sender, 0);
    }

    /** Returns the total number of tokens in existence */
    function totalSupply() external view override returns (uint256) { 
        return totalShares; 
    }

    /** Returns the number of tokens owned by `account` */
    function balanceOf(address account) public view override returns (uint256) { 
        return userInfo[account].amount;
    }

    /** Returns the number of tokens `spender` can transfer from `holder` */
    function allowance(address, address) external pure override returns (uint256) { 
        return 0; 
    }
    
    /** Token Name */
    function name() public view override returns (string memory) {
        return _name;
    }

    /** Token Ticker Symbol */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /** Tokens decimals */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /** Approves `spender` to transfer `amount` tokens from caller */
    function approve(address spender, uint256) public override returns (bool) {
        emit Approval(msg.sender, spender, 0);
        return true;
    }
  
    /** Transfer Function */
    function transfer(address recipient, uint256) external override returns (bool) {
        require(goodAddress(recipient) == true, 'Invalid Address!');
        _claimReward(msg.sender);
        emit Transfer(msg.sender, recipient, 0);
        return true;
    }

    /** transferFrom Function */
    function transferFrom(address, address recipient, uint256) external override returns (bool) {
        _claimReward(msg.sender);
        emit Transfer(msg.sender, recipient, 0);
        return true;
    }

    function setCustomizedRewards(address newCustomizedRewards) external onlyOwner {
        require(newCustomizedRewards != address(0), 'Zero Addr');
        require(newCustomizedRewards != address(0x000000000000000000000000000000000000dEaD), 'Dead Addr');
        customizedRewards = ICustomizedRewards(newCustomizedRewards);
        emit SetCustomizedRewards(newCustomizedRewards);
    }

    function withdrawForeignToken(address token_, uint256 amount) external onlyOwner {
        require(
            token != token_,
            'Cannot Withdraw Farm Token'
        );
        require(
            IERC20(token_).transfer(
                msg.sender,
                amount
            ),
            'Failure On Token Withdraw'
        );
    }

    function withdrawETH() external onlyOwner {
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    function resetMulticlaimIndex() external onlyOwner {
        currentMultiClaimHolderIndex = 0;
    }

    function setMinHoldingsForAutoClaim(uint256 newMin) external onlyOwner {
        require(newMin > 0, 'Must be at least 1 wei of tokens');
        minHoldingsForAutoClaim = newMin;
        emit SetMinHoldingsForAutoClaim(newMin);
    }

    function setMinPendingRewardsForAutoClaim(uint256 newMin) external onlyOwner {
        require(newMin > 0, 'Cannot Claim Zero Rewards');
        minPendingRewardsForAutoClaim = newMin;
        emit SetMinPendingRewardsForAutoClaim(newMin);
    }

    function setStakingFee(uint256 newFee) external onlyOwner {
        require(
            newFee <= FEE_DENOM / 2,
            'Fee Too Large'
        );
        stakingFee = newFee;
        emit SetStakingFee(newFee);
    }

    function setUnStakingFee(uint256 newFee) external onlyOwner {
        require(
            newFee <= FEE_DENOM / 2,
            'Fee Too Large'
        );
        unstakingFee = newFee;
        emit SetUnstakingFee(newFee);
    }

    function setReflectFeePercent(uint256 newFee) external onlyOwner {
        require(
            newFee <= FEE_DENOM,
            'Fee Too Large'
        );
        reflectFeePercent = newFee;
        emit SetReflectFeePercent(newFee);
    }

    function setInelligibleClaimsCheck(uint256 newCheck) external onlyOwner {
        inelligibleClaimsCheck = newCheck;
        emit SetInelligibleClaimsCheck(newCheck);
    }

    function claimRewards() external {
        _claimReward(msg.sender);
    }

    function multiClaim(uint256 iterations) external {

        uint256 inelligibleClaims = 0;

        for (uint256 i = 0; i < iterations;) {
            
            // reset index if applicable
            if (currentMultiClaimHolderIndex >= allHolders.length) {
                currentMultiClaimHolderIndex = 0;
            }

            // gas efficiency
            address user = allHolders[currentMultiClaimHolderIndex];

            // claim reward for holder if they pass all checks
            if (
                userInfo[user].amount >= minHoldingsForAutoClaim &&
                pendingRewards(user) >= minPendingRewardsForAutoClaim
            ) {
                _claimReward(user);
            } else {
                if (inelligibleClaims < inelligibleClaimsCheck) {
                    unchecked {
                        ++inelligibleClaims;
                        ++currentMultiClaimHolderIndex;
                    }
                    continue;
                }
            }

            // increment loop index and current multi claim holder index
            unchecked { ++i; ++currentMultiClaimHolderIndex; }
        }

    }

    function withdraw(uint256 amount) external {
        require(
            amount <= userInfo[msg.sender].amount,
            'Insufficient Amount'
        );
        require(
            amount > 0,
            'Zero Amount'
        );
        if (userInfo[msg.sender].amount > 0) {
            _claimReward(msg.sender);
        }

        // transfer in tokens
        uint256 fee = ( ( amount * unstakingFee ) / FEE_DENOM );

        totalShares -= amount;
        userInfo[msg.sender].amount -= amount;
        userInfo[msg.sender].totalExcluded = getCumulativeDividends(userInfo[msg.sender].amount);

        if (userInfo[msg.sender].amount == 0) {

            // copy the last element of the array into their index
            allHolders[
                userInfo[msg.sender].index
            ] = allHolders[allHolders.length - 1];

            // set the index of the last holder to be the removed index
            userInfo[
                allHolders[allHolders.length - 1]
            ].index = userInfo[msg.sender].index;

            // pop the last element off the array
            allHolders.pop();

            // save storage space
            delete userInfo[msg.sender].index;
        }

        // send tokens to user
        require(
            IERC20(token).transfer(msg.sender, amount - fee),
            'Failure On Token Transfer To Sender'
        );
        emit Transfer(msg.sender, address(0), amount);

        // take fee
        _takeFee(fee);
        emit Withdraw(msg.sender, amount, fee);
    }

    function stake(address user, uint256 amount) external {
        require(
            amount > 0,
            'Must Stake Greater Than 0'
        );
        require(
            user != address(0),
            'Zero Address'
        );

        if (userInfo[user].amount > 0) {
            _claimReward(user);
        } else {
            userInfo[user].index = allHolders.length;
            allHolders.push(user);
        }

        // transfer in tokens
        uint256 received = _transferIn(token, amount);
        uint256 fee = ( ( received * stakingFee ) / FEE_DENOM );
        uint256 credit = received - fee;
        
        // update data
        totalShares += credit;
        userInfo[user].amount += credit;
        userInfo[user].totalExcluded = getCumulativeDividends(userInfo[user].amount);
        emit Transfer(address(0), user, credit);

        // take fee, distributing reward
        _takeFee(fee);
        emit Stake(user, credit, fee);
    }

    function depositRewards(uint256 amount) external {
        uint256 received = _transferIn(reward, amount);
        if (totalShares > 0) {
            unchecked {
                dividendsPerShare += ( received * precision ) / totalShares;
            }
        }

        unchecked {
            totalRewards += received;
        }
        emit DepositRewards(received);
    }


    function _claimReward(address user) internal {

        // exit if zero value locked
        if (userInfo[user].amount == 0) {
            return;
        }

        // fetch pending rewards
        uint256 amount = pendingRewards(user);
        
        // exit if zero rewards
        if (amount == 0) {
            return;
        }

        // update total excluded
        userInfo[user].totalExcluded = getCumulativeDividends(userInfo[user].amount);

        // send tokens to customized rewards
        IERC20(reward).transfer(address(customizedRewards), amount);
        customizedRewards.trigger(user, amount, token);
        emit ClaimReward(user, amount);
    }

    function _transferIn(address _token, uint256 amount) internal returns (uint256) {
        require(
            IERC20(_token).balanceOf(msg.sender) >= amount,
            'Insufficient Balance'
        );
        require(
            IERC20(_token).allowance(msg.sender, address(this)) >= amount,
            'Insufficient Allowance'
        );
        uint256 before = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transferFrom(msg.sender, address(this), amount);
        uint256 After = IERC20(_token).balanceOf(address(this));
        require(
            After > before,
            'Error On Transfer From'
        );
        return After - before;
    }

    function _takeFee(uint256 amount) internal {

        uint256 forStakers = ( amount * reflectFeePercent ) / FEE_DENOM;
        uint256 forReceiver = amount - forStakers;

        // send portion of fee to SellReceiver
        address receiver = IToken(token).sellFeeRecipient();
        if (receiver == address(0) || forReceiver == 0) {
            forStakers = amount;
        } else {
            IERC20(token).transfer(receiver, forReceiver);
        }

        // reflect portion of fee for stakers
        if (totalShares > 0) {
            unchecked {
                dividendsPerShare += ( forStakers * precision ) / totalShares;
            }
        }
        unchecked {
            totalRewards += forStakers;
        }
    }

    function goodAddress(address _target) internal returns (bool) {
        if (
            _target == DEAD || 
            _target == ZERO
        ) {
            return false;
        } else {
            return true;
        }
    }

    function pendingRewards(address shareholder) public view returns (uint256) {
        if(userInfo[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(userInfo[shareholder].amount);
        uint256 shareholderTotalExcluded = userInfo[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(precision);
    }

    function viewAllHolders() external view returns (address[] memory) {
        return allHolders;
    }

    function numHolders() external view returns (uint256) {
        return allHolders.length;
    }

    receive() external payable {}

}