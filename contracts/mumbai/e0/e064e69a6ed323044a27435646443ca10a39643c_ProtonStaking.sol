/**
 *Submitted for verification at polygonscan.com on 2022-10-07
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

// helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

}

contract ProtonStaking is Ownable, ReentrancyGuard  {
    
    using SafeMath for uint256;
    IERC20 public token;

    uint256 internal totalRewardsClaimed;
    
    uint256 private immutable ONE_MONTH_SEC = 2592000;

    struct stakes{
        uint256 poolId;
        uint256 stakeId;
        address owner;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 months;
        bool collected;
        uint256 claimed;
    }
    
    event StakingUpdate(
        uint256 poolId,
        uint256 stakeId,
        address wallet,
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        bool collected,
        uint256 claimed
    );

    event rewardsClaimed(uint256 poolId, uint256 stakeId, address wallet, uint256 amount);
    
    event APYSet(
        uint256[] APYs
    );
    mapping(address=>stakes[]) public Stakes;
    //mapping(uint256=>uint256) public APY;
    mapping(uint256=>mapping(uint256=>uint256)) public APY;
    mapping(uint256=>bool) public stakesAllowed;

    constructor(IERC20 add_) {
        token = add_;
    }

    function pausePool(uint256 poolId, bool status) public onlyOwner {
        stakesAllowed[poolId] = status;
    }

    function stake(uint256 poolId, uint256 amount, uint256 months) public nonReentrant {
        require(months == 1 || months == 4 || months == 12,"ENTER VALID MONTH");
        require(stakesAllowed[poolId] == true, "Pool is paused for stakes");
        _stake(poolId, amount, months);
    }

    function _stake(uint256 poolId, uint256 amount, uint256 months) private {
        TransferHelper.safeTransferFrom(address(token), msg.sender, address(this), amount);
        uint256 duration = block.timestamp.add(months.mul(1 minutes));   
        uint256 stakeId = Stakes[msg.sender].length;
        Stakes[msg.sender].push(stakes(poolId, stakeId, msg.sender, amount, block.timestamp, duration, months, false, 0));
        emit StakingUpdate(poolId, stakeId, msg.sender, amount, block.timestamp, duration, false, 0);
    }

    function unStake(uint256 stakeId) public nonReentrant{
        require(Stakes[msg.sender][stakeId].collected == false ,"ALREADY WITHDRAWN");
        require(Stakes[msg.sender][stakeId].endTime < block.timestamp,"STAKING TIME NOT ENDED");
        _unstake(stakeId);
    }

    function _unstake(uint256 stakeId) private {
        stakes storage staked = Stakes[msg.sender][stakeId];
        staked.collected = true;
        uint256 stakeamt = staked.amount;
        uint256 gtreward = getTotalRewards(msg.sender, stakeId) > Stakes[msg.sender][stakeId].claimed ? 
                            getTotalRewards(msg.sender, stakeId) : Stakes[msg.sender][stakeId].claimed;
        uint256 rewards = gtreward.sub(Stakes[msg.sender][stakeId].claimed);
        staked.claimed += rewards;
        totalRewardsClaimed = totalRewardsClaimed.add(rewards);
        TransferHelper.safeTransfer(address(token), msg.sender, stakeamt.add(rewards));
        emit StakingUpdate(staked.poolId, staked.poolId, msg.sender, stakeamt, staked.startTime, staked.endTime, true, getTotalRewards(msg.sender, stakeId));
    }

    function claimRewards(uint256 stakeId) public nonReentrant {
        stakes storage staked = Stakes[msg.sender][stakeId];
        require(staked.claimed < getTotalRewards(msg.sender, stakeId), "Claimed Everything");
        uint256 cuamt = getCurrentRewards(msg.sender, stakeId);
        require(cuamt>Stakes[msg.sender][stakeId].claimed, "Nothing is available");
        uint256 clamt = cuamt.sub(staked.claimed);
        staked.claimed += clamt;
        totalRewardsClaimed = totalRewardsClaimed.add(clamt);
        TransferHelper.safeTransfer(address(token), msg.sender, clamt);
        emit rewardsClaimed(staked.poolId, staked.stakeId, msg.sender, clamt);
    }

    function getStakes(address wallet) public view returns(stakes[] memory){
        uint256 itemCount = Stakes[wallet].length;
        uint256 currentIndex = 0;
        stakes[] memory items = new stakes[](itemCount);

        for (uint256 i = 0; i < itemCount; i++) {
                stakes storage currentItem = Stakes[wallet][i];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        return items;
    }

    function getTotalRewards(address wallet, uint256 stakeId) public view returns(uint256) {
        stakes memory staked = Stakes[wallet][stakeId];
        require(staked.amount != 0);
        uint256 stakeamt = staked.amount;
        uint256 mos = staked.months;
        uint256  rewards = (((stakeamt.mul(APY[staked.poolId][mos])).mul(mos)).div(12)).div(100);
        return rewards;
    }

     function getCurrentRewards(address wallet, uint256 stakeId) public view returns(uint256) {
        require(Stakes[wallet][stakeId].amount != 0,"ZERO amount staked");
        uint256 mos = Stakes[wallet][stakeId].months;
        uint256 etime = Stakes[wallet][stakeId].endTime > block.timestamp ? block.timestamp : Stakes[wallet][stakeId].endTime;
        uint256 timec = etime.sub(Stakes[wallet][stakeId].startTime);
        uint256  rewards = getTotalRewards(wallet, stakeId);
        uint256 crewards = (rewards.mul(timec)).div(mos.mul(1 minutes));
        return crewards;
    }


    function getTotalClaimed() public view returns(uint256){
       return(totalRewardsClaimed);
    }

    function setAPYs(uint256 poolId, uint256[] memory apys) external onlyOwner {
       require(apys.length == 3,"3 INDEXED ARRAY ALLOWED");
        APY[poolId][1] = apys[0];
        APY[poolId][4] = apys[1];
        APY[poolId][12] = apys[2];
        emit APYSet(apys);
    }

    function getAPY(uint256 poolId) public view returns(uint256[] memory){
        uint256[] memory apys = new uint256[](3);
        apys[1] = APY[poolId][1];
        apys[4] = APY[poolId][4];
        apys[12] = APY[poolId][12];
        return apys;
    }   

    function withdraw(uint256 amount) external nonReentrant onlyOwner {
        TransferHelper.safeTransfer(address(token), owner(), amount);
    }

    /* Only for testing */
    function addStakes(uint256 poolId,address owner, uint256 amount, uint256 st, uint256 et, uint256 m, bool collected, uint256 claimed) public {
        uint256 stakeId = Stakes[owner].length;
        Stakes[owner].push(stakes(poolId, stakeId, owner, amount, st, et, m, collected, claimed));
        emit StakingUpdate(poolId, stakeId, owner, amount, st, et, false, claimed);
    }

}