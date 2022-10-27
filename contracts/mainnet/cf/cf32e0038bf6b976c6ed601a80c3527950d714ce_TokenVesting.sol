/**
 *Submitted for verification at polygonscan.com on 2022-10-26
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/tokenvesting.sol



pragma solidity ^0.8.0;



contract TokenVesting is Ownable{

    uint private denominator = 100;
    IERC20 public NiceToken;

    
    /**
     *@dev sets the address of NiceToken
     *
     *@param token address s of token to distribute during vesting
     */
    constructor(IERC20 token) Ownable(){
        NiceToken = IERC20(token);
    }

    enum Roles {
        liquidity,
        founding,
        marketing,
        strategic,
        ecosystem, 
        advisor,
        privatesale,
        earlybird,
        publicsale1,
        publicsale2,
        legal,
        community,
        tech
    }
 
    struct Vesting {
        Roles role;
        uint startTime;
        uint cliff;
        uint totalAmount;
        uint vestedAmount;                                          
        uint lastRewardUpdateTime;
        uint tgePercentage;
        uint duration;
        bool tgeClaimed;
        bool revoked;
    }

    mapping(address=>Vesting) public VestingSchedule;
    mapping(Roles=>uint) private roles;
    mapping(address =>uint) public Balances;
    mapping(address =>uint) public vestingCount;

    event TokenClaimed(address indexed by ,uint amount);
    event newRecipientAdded(address indexed recipient, Roles role,uint totalAmount,uint duration,uint cliff);

    /// @notice Add a new beneficiary to the vesting 

    /// @param beneficiary address of the beneficiary to be added to vesting 
    /// @param role role of the beneficiary
    /// @param startTime start time of vesting after adding the beneficiary In Days
    /// @param cliff cliff time between start time and vesting time
    /// @param totalAmount total Amount of tokens to be vested
    /// @param duration duration of vesting after the cliff period   
    function addVesting(
        address beneficiary,
        Roles role,
        uint startTime,
        uint cliff,
        uint totalAmount,
        uint duration
        )
        external onlyOwner {

        bool minimumAmount = getMinimumAmount(totalAmount, duration);
        require(minimumAmount,"Entered Amount is too low w.r.t duration");
        require(VestingSchedule[beneficiary].startTime ==  0,"Beneficiary already have a vesting Schedule");                
        VestingSchedule[beneficiary] = Vesting(
            role,
            block.timestamp + (startTime* 1 days),
            block.timestamp + (startTime + cliff)*1 days,
            totalAmount,
            0,
            block.timestamp +(startTime +cliff)*1 days,
            getTgePercentage(role),
            duration,
            false,
            false
        );
        emit newRecipientAdded(beneficiary, role, totalAmount,duration,cliff);
    }
    /**
     *@dev updates the balance of user according to their total amount and role
     *
     *@param user address of the user
     */
    function updateBalance(address user) internal {
        if(VestingSchedule[user].revoked){
            return;
        }
        
        uint time = VestingSchedule[user].cliff;
        if(block.timestamp < time && VestingSchedule[user].tgeClaimed == false){
            uint amount = VestingSchedule[user].totalAmount *VestingSchedule[user].tgePercentage /denominator;
            Balances[user] += amount;

            VestingSchedule[user].vestedAmount += amount;
            VestingSchedule[user].tgeClaimed = true;
        }

        else if(block.timestamp > time && block.timestamp < time+ VestingSchedule[user].duration*1 days) {
            if(VestingSchedule[user].tgeClaimed ==false)
            {
                uint tgeAmount = VestingSchedule[user].totalAmount * VestingSchedule[user].tgePercentage / denominator;
                Balances[user] += tgeAmount;
                VestingSchedule[user].tgeClaimed = true;
            }
            uint dailyReward = tokensToBeClaimedDaily(user);
            uint unPaidDays = (block.timestamp-VestingSchedule[user].lastRewardUpdateTime)/1 days; 
            uint amount = dailyReward * unPaidDays;    
            Balances[user] += amount;

            VestingSchedule[user].lastRewardUpdateTime = block.timestamp;
            VestingSchedule[user].vestedAmount += amount; 
        }

        else if(block.timestamp > time + VestingSchedule[user].duration)
        {
            uint amount = VestingSchedule[user].totalAmount - VestingSchedule[user].vestedAmount;
            Balances[user] = amount;

            VestingSchedule[user].lastRewardUpdateTime = block.timestamp;
            VestingSchedule[user].vestedAmount += amount;     
        }
        return;
        
    }

    /**
     *@dev updates the balance og the caller and
     *transfers 'amount' of tokens to the caller
     *and sets the balance of the caller to '0'
     */
    function collect(uint amount) external {
        
        require(amount >0,"Can't withdraw 0 tokens");
        updateBalance(msg.sender);
        uint withdrawAbleAmount = Balances[msg.sender];
        require(amount <=withdrawAbleAmount,"Not enough balance to withdraw");
         
        unchecked{
            NiceToken.transfer(msg.sender,amount);
        }
        Balances[msg.sender] -= amount;

        emit TokenClaimed(msg.sender, amount);
    }

    function getTimeStamp() public view returns(uint) {
        return block.timestamp;
    }
    
    /**
     *@dev Returns amount of token a user can claim
     */
    function viewClaimableRewards(address user) public view returns(uint) {
        
        uint time = VestingSchedule[user].cliff;

        if(block.timestamp < time ){
            uint amount = VestingSchedule[user].totalAmount *VestingSchedule[user].tgePercentage /denominator;
            return amount - VestingSchedule[user].vestedAmount ;           
        }

        else if(block.timestamp > time && block.timestamp < time+ VestingSchedule[user].duration*1 days) {
            
            uint tgeAmount = VestingSchedule[user].totalAmount * VestingSchedule[user].tgePercentage / denominator;
            uint dailyReward = tokensToBeClaimedDaily(user);
            uint unPaidDays = (block.timestamp-VestingSchedule[user].lastRewardUpdateTime)/1 days;
            uint balance = Balances[user]; 
            uint amount = (dailyReward * unPaidDays) + tgeAmount - VestingSchedule[user].vestedAmount + balance;
            return amount;    
        }

        else if(block.timestamp > time + VestingSchedule[user].duration)
        {
            uint amount = VestingSchedule[user].totalAmount - VestingSchedule[user].vestedAmount;
            return amount;
        }

    }
    
    /**
     *Returns daily claimable tokens for that user 
     */
    function tokensToBeClaimedDaily(address user) public  view returns (uint) {
        uint totalAmount = VestingSchedule[user].totalAmount;
        uint tgeAmount = (totalAmount * VestingSchedule[user].tgePercentage)/denominator;
        uint dailyReward = (totalAmount-tgeAmount)/VestingSchedule[user].duration;
        return dailyReward;
    }
    /**
     *@dev revokes vesting of the user 
     *
     *@param beneficiary address of the beneficiary 
     */
    function revokeVesting(address beneficiary) external onlyOwner {
        require(!VestingSchedule[beneficiary].revoked,"vesting schedule should not be revoked already");
        updateBalance(beneficiary);
        VestingSchedule[beneficiary].revoked = true;
    }

    /**
     *@dev updates the percentage of tokens for a role 
     *as a new user joins vesting with that role
     *   
     *Returns uint value of new percentage for the role
     *   
     *@param role role of the new recipient  
    */
    function getTgePercentage(Roles role) internal pure returns (uint) {
        uint rolePercentage;
        
        if(Roles.liquidity == role){
            rolePercentage =3;
        }
        else if(Roles.founding == role){
            rolePercentage =15;
        }
        else if(Roles.marketing == role) {
            rolePercentage = 12;
        }
        else if(Roles.strategic == role) {
            rolePercentage = 10;
        }
        else if(Roles.ecosystem == role) {
            rolePercentage = 15;
        }
        else if(Roles.advisor == role) {
            rolePercentage = 5;
        }
        else if(Roles.privatesale == role) {
            rolePercentage = 5;
        }
        else if(Roles.earlybird == role) {
            rolePercentage = 8;
        }
        else if(Roles.publicsale1 == role) {
            rolePercentage = 5;
        }
        else if(Roles.publicsale2 == role) {
            rolePercentage = 5;
        }
        else if(Roles.legal == role) {
            rolePercentage = 5;
        }
        else if(Roles.community == role) {
            rolePercentage = 5;
        }
        else rolePercentage = 8;
        return rolePercentage;
    }
    /**
     *@dev checks if the total amount and duration ration is big enough
     *to ensure daily rewards   
     *
     *Returns bool
     *@param totalAmount total amount of tokens to be vested
     *@param duration duration of vesting after the cliff period   
     */

    function getMinimumAmount(uint totalAmount,uint duration) internal pure returns(bool){
        if(totalAmount/duration >= 2){
            return true;
        }
        else{
            return false;
        }
    }
    
}