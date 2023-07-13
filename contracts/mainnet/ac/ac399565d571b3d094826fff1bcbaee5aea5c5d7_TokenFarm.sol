/**
 *Submitted for verification at polygonscan.com on 2023-07-13
*/

// SPDX-License-Identifier: MIT

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
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

interface ISocietyToken is IERC20 {
    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(address spender, uint256 amount) external returns (bool);
}


pragma solidity ^0.8.0;

contract TokenFarm is Ownable{

    // Provider info
    struct Provider {
        // The deposited tokens of the Provider
        uint256 deposited;
        // Last time of details update for Deposit
        uint256 timeOfLastUpdate;
        // Calculated, but unclaimed rewards. These are calculated each time
        // a user writes to the contract.
        uint256 unclaimedRewards;
    }

    uint256 public rewardsPerHour = 285; // 0.00285%/h or 25% APR

    // Mapping of address to Provider info
    mapping(address => Provider) internal providers;

    uint256 public totalTokensDeposited;
    uint256 public totalRewardsPaid;
    uint256 public buyFeePercentage;

    uint256 public USDCRate;
    uint256 public SocietyRate;

    IERC20 public tokenToDeposit;
    ISocietyToken public rewardToken;
    IERC20 public usdcToken;

    mapping(address => uint) public deposits;
    mapping(address => uint) public rewards;

    event Deposit(address indexed provider, uint256 amount);
    event Withdraw(address indexed provider, uint256 amount);
    event RewardPaid(address indexed provider, uint256 amount);

    constructor(
        address _tokenToDeposit,
        address _rewardToken,
        address _usdcToken,
        uint256 _buyFeePercentage,
        uint256 _usdcRate,
        uint256 _societyRate
    ) {
        tokenToDeposit = IERC20(_tokenToDeposit);
        rewardToken = ISocietyToken(_rewardToken);
        usdcToken = IERC20(_usdcToken);
        buyFeePercentage =_buyFeePercentage;
        USDCRate = _usdcRate;
        SocietyRate = _societyRate;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Amount cannot be 0");
        require(tokenToDeposit.balanceOf(msg.sender) >= amount, "Insufficient balance");

        require(
            tokenToDeposit.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        if (providers[msg.sender].deposited == 0) {
            providers[msg.sender].deposited = amount;
            providers[msg.sender].timeOfLastUpdate = block.timestamp;
            providers[msg.sender].unclaimedRewards = 0;
        } else {
            uint256 _rewards = calculateReward(msg.sender);
            providers[msg.sender].unclaimedRewards += _rewards;
            providers[msg.sender].deposited += amount;
            providers[msg.sender].timeOfLastUpdate = block.timestamp;
        }

        totalTokensDeposited += amount;
        emit Deposit(msg.sender, amount);
    }


    // Withdraw specified amount of staked tokens
    function withdraw(uint256 _amount) external  {
        require(
            providers[msg.sender].deposited >= _amount,
            "Can't withdraw more than you have"
        );
        uint256 _rewards = calculateReward(msg.sender);
        providers[msg.sender].deposited -= _amount;
        providers[msg.sender].timeOfLastUpdate = block.timestamp;
        providers[msg.sender].unclaimedRewards = _rewards;
        require(tokenToDeposit.transfer(msg.sender, _amount), "Transfer failed");
        totalTokensDeposited -= _amount;
    }

    // Function useful for fron-end that returns user stake and rewards by address
    function getDepositInfo(address _user)
        public
        view
        returns (uint256 _stake, uint256 _rewards)
    {
        _stake = providers[_user].deposited;
        _rewards =
            calculateReward(_user) +
            providers[msg.sender].unclaimedRewards;
        return (_stake, _rewards);
    }

    function claimReward() external {
        uint256 _rewards = calculateReward(msg.sender) +
            providers[msg.sender].unclaimedRewards;
        require(_rewards > 0, "You have no rewards");
        providers[msg.sender].unclaimedRewards = 0;
        providers[msg.sender].timeOfLastUpdate = block.timestamp;
        // rewardToken.mint(msg.sender, _rewards);
        rewardToken.transfer(msg.sender, _rewards);
        totalRewardsPaid += _rewards;
        emit RewardPaid(msg.sender, _rewards);
    }

    function calculateReward(address provider) public view returns (uint256) {
        return (((((block.timestamp - providers[provider].timeOfLastUpdate) *
            providers[provider].deposited) * rewardsPerHour) / 3600) / 10000000);
    }

    function buyTokensWithUSDC(uint256 amount) external {
        require(amount > 0, "Amount cannot be 0");
        require(usdcToken.balanceOf(msg.sender) >= amount, "Insufficient USDC balance");

        uint256 tokenAmount = amount / USDCRate;
        uint256 buyFee = tokenAmount * buyFeePercentage / 100;
        tokenAmount -= buyFee;
        tokenToDeposit.transfer(msg.sender, tokenAmount);
        usdcToken.transferFrom(msg.sender, address(this), amount);
    }

    function buyTokensWithSocietyKey(uint256 amount) external {
        require(amount > 0, "Amount cannot be 0");
        require(rewardToken.balanceOf(msg.sender) >= amount, "Insufficient SocietyKey balance");

        uint256 tokenAmount = amount / SocietyRate;
        uint256 buyFee = tokenAmount * buyFeePercentage / 100;
        tokenAmount -= buyFee;
        tokenToDeposit.transfer(msg.sender, tokenAmount);
        rewardToken.transferFrom(msg.sender, address(this), amount);
    }

    function setUSDCRate(uint256 _rate) external onlyOwner {
        USDCRate = _rate;
    }

    function setSocietyRate(uint256 _rate) external onlyOwner{
        SocietyRate = _rate;
    }

    function setBuyFeePercentage (uint256 _percent) external onlyOwner {
        buyFeePercentage = _percent;
    }

    function setRewardsPerHour (uint256 _rewardsPerHour) external onlyOwner {
        rewardsPerHour = _rewardsPerHour;
    }

}