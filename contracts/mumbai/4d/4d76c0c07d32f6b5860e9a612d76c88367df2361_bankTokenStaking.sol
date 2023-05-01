/**
 *Submitted for verification at polygonscan.com on 2023-04-30
*/

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

// File: BankTokenStaking.sol


pragma solidity ^0.8.9;

/* -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. */
/* -.-.-.-. BANK OF NOWHERE $BANK STAKING POOL -.-.-.-. */
/* -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. */



contract bankTokenStaking is Ownable{

    IERC20 public bankTokenAddress;

    uint256 public timerDuration;
    uint256 public rwdRate;
    uint256 public stakedPoolSupply;
    bool public stakingOpen;

    mapping(address => bool) public isStaked;
    mapping(address => uint256) public withdrawTimer;
    mapping(address => uint256) public stakedPoolBalances;

    event DepositEmit(address user, uint256 amountDeposited, uint256 userBalance);
    event WithdrawEmit(address user, uint256 userBalance);
    event RewardsEmit(address user, uint256 userBalance, uint256 userReward);

    constructor(
        address _bankTokenAddress, 
        uint256 _timerDuration, 
        uint256 _rwdRate){
        bankTokenAddress = IERC20(_bankTokenAddress);
        timerDuration = _timerDuration;
        rwdRate = _rwdRate;
        stakingOpen = false;
    }
    
    function calculateRewards(address _user) public view returns (uint256) {
        require(stakingOpen == true, "Staking pool is closed");
        require(isStaked[_user], "This address has not staked");
        uint256 totalTokenBalance = IERC20(bankTokenAddress).balanceOf(address(this));
        uint256 rwdPoolSupply = totalTokenBalance - stakedPoolSupply;
        uint256 rwdPoolAftrRate = rwdPoolSupply * rwdRate / 1000;
        uint256 userBalance = stakedPoolBalances[_user];
        uint256 userRewardsAmount =  rwdPoolAftrRate * userBalance / stakedPoolSupply;
        return userRewardsAmount;
    }

    function calculateTime(address _user) public view returns (uint256) {
        require(isStaked[_user], "This address has not staked");
        uint256 timeElapsed = block.timestamp - withdrawTimer[_user];
        return timeElapsed;
    }

    function depositToStaking(uint256 _amount) public{
        require(stakingOpen == true, "Staking pool is closed");
        require(_amount > 0, "Deposit must be > 0");
        // all users must APPROVE staking contract to use erc20 before v-this-v can work
        bool success = IERC20(bankTokenAddress).transferFrom(msg.sender, address(this), _amount);
        require(success == true, "transfer failed!");
        
        isStaked[msg.sender] = true;
        withdrawTimer[msg.sender] = block.timestamp;
        stakedPoolBalances[msg.sender] += _amount;
        stakedPoolSupply += _amount;

        emit DepositEmit(msg.sender, _amount, stakedPoolBalances[msg.sender]);
    }

    function withdrawAll() public{
        require(isStaked[msg.sender], "This address has not staked");

        uint256 userBalance = stakedPoolBalances[msg.sender];
        require(userBalance > 0, 'insufficient balance');
        
        uint256 timeElapsed = calculateTime(msg.sender);
        require(timeElapsed < timerDuration, 'withdraw rewards first');

        delete isStaked[msg.sender];
        delete withdrawTimer[msg.sender];
        delete stakedPoolBalances[msg.sender];
        stakedPoolSupply -= userBalance;

        bool success = IERC20(bankTokenAddress).transfer(msg.sender, userBalance);
        require(success == true, "transfer failed!");

        emit WithdrawEmit(msg.sender, userBalance);
    }

    function withdrawRewards() public{
        require(stakingOpen == true, "Staking pool is closed");
        require(isStaked[msg.sender], "This address has not staked");
        
        uint256 timeElapsed = calculateTime(msg.sender);
        require(timeElapsed >= timerDuration, 'Minimum required staking time not met');

        uint256 userBalance = stakedPoolBalances[msg.sender];
        require(userBalance > 0, 'insufficient balance');

        uint256 userReward = calculateRewards(msg.sender);
        require(userReward > 0, 'insufficient reward');
        
        withdrawTimer[msg.sender] = block.timestamp;
        bool success = IERC20(bankTokenAddress).transfer(msg.sender, userReward);
        require(success == true, "transfer failed!");

        emit RewardsEmit(msg.sender, userBalance, userReward);
    }

    //onlyOwners
    function setTimer(uint256 _time) external onlyOwner {
        timerDuration = _time;
    }

    function setRate(uint256 _rwdRate) external onlyOwner {
        require(_rwdRate > 0 && _rwdRate < 1000, "Rate must be > 0 and < 1000");
        rwdRate = _rwdRate;
    }

    function setTokenAddress(address _newTokenAddress) external onlyOwner {
        bankTokenAddress = IERC20(_newTokenAddress);
    } 

    function setStakingOpen(bool _trueOrFalse) external onlyOwner {
        stakingOpen =  _trueOrFalse;
    } 
    
    function closeRewardsPool() external payable onlyOwner {
        uint256 tokenBalance = IERC20(bankTokenAddress).balanceOf(address(this));
        uint256 gasBalance = address(this).balance;
        if(tokenBalance > 0){
            bool success1 = IERC20(bankTokenAddress).transfer(msg.sender, tokenBalance - stakedPoolSupply);
            require(success1 == true, "transfer failed!");
        }
        if(gasBalance > 0){
            (bool success2,) = payable(msg.sender).call{value: gasBalance}("");
            require(success2 == true, "transfer failed!");
        }
    }
}