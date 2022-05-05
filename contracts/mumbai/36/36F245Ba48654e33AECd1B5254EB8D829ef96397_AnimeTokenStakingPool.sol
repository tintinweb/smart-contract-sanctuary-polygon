// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "../interface/IAnimeTokenStakingPool.sol";
import "../interface/IERC721Mintable.sol";
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * DEFINITION: User Staking Reward Model
 *   reward := SUM(ΔTi * x(T_{i-1}) / S(Ti) * Ri / Di| i = 1..n)
 *              _
 *             |  0 (i = 0)
 *      ΔTi := |  the ith duration between init, Stake or Unstake events(i = 1 .. n-1)
 *             |_ a duration from the last event (i = n)
 *      Tk - SUM(ΔTk | i = 0..k) after inital time
 *      x(t) - staking amount at t after 'initialTime'
 *      S(t) - total staking amount
 *      Ri - rewardAmount
 *      Di - rewardDuratoin
 *
 * FORMULA:
 *   Let, RPT(n) := SUM(ΔTi / S(Ti) | i = 1..n) * R / D
 *        x(Ti): up/down at t = Tk
 *        Ri, Di: fixed as R,D
 *   Then,
 *       (Thm. 1) reward = x(T1) * RPT(k) + x(Tk) * (RPT(n) - RPT(k))
 *
 *   In general,
 *       (Thm. 2) reward = x(T1) * RPT(k1) + x(Tk1) * (RPT(k2) - RPT(k1))
 *                  + x(Tk2) * (RPT(k3) - RPT(k2))
 *                  ... + x(Tk_m) * (RPT(n) - RPT(k_m))
 *       x(Ti): up/down at i = k1, k2..., k_m
 *
 * PROOF:
 *  Apply x(t) funcs to be fixed and move them outside of SUM().
 *  (Thm. 1)) reward = SUM(ΔTi * x(T1) / S(Ti) | i = 1..k) * R  / D
 *         + SUM(ΔTi * x(Tk) / S(Ti) | i = k+1..n) * R / D
 *         = x(T1) * SUM(ΔTi / S(Ti) | i = 1..k) * R / D
 *         + x(Tk) * SUM(ΔTi / S(Ti) | i = k+1..n) * R / D
 *         = x(T1) * RPT(k) + x(Tk) * (RPT(n) - RPT(k))
 *
 * Comment:
 *   When the user stakes, unstakes, or claims,
 *      x(T_{k}) * RPT_{k} is stored as rewards[user]
 *      rewards[user] is reset when the user claimed
 *      RPT_k is stored as rewardPerTokenPayed[user]
 *      RPT_n is stored as rewardPerToken to calc RPT_{n+1}
 *
 * DEFINITION: Average Total Supply(:ATS)
 *   ATS(t) := SUM((S(Ti)*ΔTi) | i = 1..n) / (t - initialTime)
 *    S(Ti) - total supply at Ti after initial time
 *
 * Comment:
 *   We watch ATS to decide next rewardAmount and rewardDuration
 *   relative to other pools according to our token schedule
 */

contract AnimeTokenStakingPool is Ownable {
  // times
  uint256 public lastUpdateTime;
  uint256 public periodFinish = 0;

  // reward setting
  uint256 public rewardAmount = 0;
  uint256 public rewardDuration = 0;
  uint256 public rewardRate = 0;

  // rewards
  mapping(address => uint256) public rewards;
  uint256 public rewardPerTokenStored;
  mapping(address => uint256) public userRewardPerTokenPaid;
  uint256 public studioRewardPayed = 0;

  // balance
  mapping(address => uint256) private _balances;
  mapping(address => uint256) private _depositTime;

  // supply
  uint256 private _totalSupply;
  uint256 public cumulativeStoredTotalSupply = 0;
  uint256 public lastUpdateTimeOfTotalSupply = 0;
  uint256 public initialTime = 0;

  // status
  bool public initialize;
  bool public paused;

  // address
  address public stakingToken;
  address public productNft;
  address public animeStudio;

  // nft sell info
  mapping(uint256 => uint256) public priceOfProductType;
  mapping(uint256 => uint256) public minRewardOfProductType;

  // token_id parameters
  uint256 public animeStudioNumber;
  mapping(uint256 => uint256) public nonceOfProductType;
  mapping(address => uint256) public userProductType;

  // events
  event RewardAdded(uint256 reward, uint256 duration);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);

  constructor(address _stakingToken, address _nft) {
    stakingToken = _stakingToken;
    productNft = _nft;
    initialize = false;
  }

  function init(uint256 reward, uint256 duration) external onlyOwner {
    notifyRewardAmount(reward, duration);
    initialTime = block.timestamp;
    lastUpdateTimeOfTotalSupply = block.timestamp;
    initialize = true;
  }

  // store SUM((S(Ti)*ΔTi) | i = 1..k) at this moment
  // store current time as initialTime + SUM(ΔTi)
  modifier updateCumulativeTotalSupply() {
    cumulativeStoredTotalSupply = getLatestCumulativeTotalSupply();
    lastUpdateTimeOfTotalSupply = block.timestamp;
    _;
  }

  // RPT(n) at this moment Tn
  function rewardPerToken() public view returns (uint256) {
    if (_totalSupply == 0) {
      return 0;
    }
    uint256 _rewardPerToken = rewardPerTokenStored +
      ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) /
      _totalSupply;
    return _rewardPerToken;
  }

  // earned = x(Tkv) * (RPT(k_{v+1}) - RPT(kv))+ ... + x(Tk_{m}) * (RPT(n) - RPT(k_{m}))
  function earned(address account) public view returns (uint256) {
    if (rewardPerToken() == 0) {
      return rewards[account];
    }
    return
      (_balances[account] *
        (rewardPerToken() - userRewardPerTokenPaid[account])) /
      1e18 +
      rewards[account];
  }

  modifier updateReward(address account) {
    // store RPT(n) to calc later RPT(n+1)
    rewardPerTokenStored = rewardPerToken();
    // Tn
    lastUpdateTime = lastTimeRewardApplicable();

    // if updated by user
    if (account != address(0)) {
      // store reward (Def. 1) except for the last term in Thm.2
      rewards[account] = earned(account);
      // store current RPT(n) for user to substract later from latest RPT(n+x) in Thm.2
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  function stake(uint256 amount)
    external
    whenNotPaused
    updateReward(msg.sender)
    updateCumulativeTotalSupply
  {
    require(initialize == true, "AnimeBankStakingPool: not initialized");
    require(amount > 0, "AnimeBankStakingPool: Cannot stake 0");
    _depositTime[msg.sender] = block.timestamp;
    _totalSupply = _totalSupply + amount;
    _balances[msg.sender] = _balances[msg.sender] + amount;
    IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);
    emit Staked(msg.sender, amount);
  }

  function unstake(uint256 amount)
    private
    updateReward(msg.sender)
    updateCumulativeTotalSupply
  {
    require(initialize == true, "AnimeTokenStakingPool: not initialized");
    if (amount == 0) return;
    _totalSupply = _totalSupply - amount;
    _balances[msg.sender] = _balances[msg.sender] - amount;
    IERC20(stakingToken).transfer(msg.sender, amount);
    emit Withdrawn(msg.sender, amount);
  }

  function claim() private updateReward(msg.sender) {
    require(initialize == true, "AnimeBankStakingPool: not initialized");
    uint256 reward = rewards[msg.sender];
    if (reward > 0) {
      rewards[msg.sender] = 0;
      if (reward > IERC20(stakingToken).balanceOf(address(this))) {
        reward = IERC20(stakingToken).balanceOf(address(this));
      }
      IERC20(stakingToken).transfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  function exit() external {
    claim();
    unstake(_balances[msg.sender]);
  }

  // Studio claims the half of the sum of notified amounts according to the following vesting scheme:
  function claimStudioReward() external {
    require(msg.sender == animeStudio);
    require(initialize == true, "AnimeBankStakingPool: not initialized");
    uint256 claimable = _vestingSchedule() - studioRewardPayed;
    studioRewardPayed += claimable;
    IERC20(stakingToken).transfer(animeStudio, claimable);
  }

  function _vestingSchedule() internal view returns (uint256) {
    uint256 timestamp = block.timestamp;
    uint256 duration = periodFinish - initialTime;
    if (timestamp < initialTime) {
      return 0;
    } else if (timestamp > periodFinish) {
      return rewardAmount;
    } else {
      return (rewardAmount * (timestamp - initialTime)) / duration;
    }
  }

  function notifyRewardAmount(uint256 reward, uint256 duration)
    public
    onlyOwner
    updateReward(address(0))
  {
    require(duration <= 366 days, "duration too long");
    uint256 balance = IERC20(stakingToken).balanceOf(address(this));
    uint256 userReward = reward / 2;
    require(userReward > 0, "AnimeBankStakingPool: userReward must over zero");
    require(duration > 0, "AnimeBankStakingPool: duration must over zero");
    require(
      balance >= userReward,
      "AnimeBankStakingPool: not enough userReward balance"
    );
    require(
      periodFinish <= block.timestamp,
      "AnimeBankStakingPool: userReward in duration, must wait until finish"
    );

    rewardRate = userReward / duration;

    // Ensure the provided reward amount is not more than the balance in the contract.
    // This keeps the reward rate in the right range, preventing overflows due to
    // very high values of rewardRate in the earned and rewardsPerToken functions;
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    require(
      rewardRate <= balance / duration,
      "AnimeBankStakingPool: Provided reward too high"
    );

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp + duration;
    rewardAmount = rewardAmount + userReward;
    rewardDuration = rewardDuration + duration;
    emit RewardAdded(userReward, duration);
  }

  modifier whenNotPaused() {
    require(
      !paused,
      "AnimeTokenStakingPool: This action cannot be performed while the contract is paused"
    );
    _;
  }

  // claim productType of token
  function claimNft(uint256 productType) private {
    // e.g.) token_id: 1_000_000000000001
    uint256 tokenId = animeStudioNumber *
      1e15 +
      productType *
      1e12 +
      nonceOfProductType[productType];
    ++nonceOfProductType[productType];
    IERC721Mintable(productNft).mint(msg.sender, tokenId);
  }

  function buyNft() external updateReward(msg.sender) {
    // count up type for sender to avoid to buy same type of nft
    require(initialize == true, "AnimeBankStakingPool: not initialized");
    ++userProductType[msg.sender];
    uint256 productType = userProductType[msg.sender];
    require(
      nonceOfProductType[productType] > 0 &&
        priceOfProductType[productType] > 0,
      "AnimeBankStakingPool: Owner has not set the type of nft"
    );

    uint256 reward = rewards[msg.sender];
    uint256 minReward = minRewardOfProductType[productType];
    require(
      minReward <= reward,
      "AnimeBankStakingPool: Reward has not rearched to buy nft"
    );

    uint256 price = priceOfProductType[productType];
    require(
      price <= reward,
      "AnimeBankStakingPool: price is higher than reward"
    );

    // consume rewards and claim nft
    rewards[msg.sender] = reward - price;
    IERC20(stakingToken).transfer(owner(), reward);
    claimNft(productType);
    emit RewardPaid(msg.sender, price);
  }

  // getters
  //

  function lastTimeRewardApplicable() public view returns (uint256) {
    return (block.timestamp < periodFinish) ? block.timestamp : periodFinish;
  }

  function depositTime(address account) public view returns (uint256) {
    return _depositTime[account];
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function getRewardForDuration() external view returns (uint256) {
    return rewardRate * rewardDuration;
  }

  function getAverageTotalSupply() external view returns (uint256) {
    return getLatestCumulativeTotalSupply() / (block.timestamp - initialTime);
  }

  // get SUM((S(Ti)*ΔTi) | i = 1..k) at this moment
  function getLatestCumulativeTotalSupply() private view returns (uint256) {
    uint256 latest = cumulativeStoredTotalSupply +
      (_totalSupply * (block.timestamp - lastUpdateTimeOfTotalSupply));
    return latest;
  }

  // setters
  //

  function setPaused(bool _paused) external onlyOwner {
    paused = _paused;
  }

  function setProductPrice(uint256 _productType, uint256 _price)
    external
    onlyOwner
  {
    priceOfProductType[_productType] = _price;
  }

  function setProductNonce(uint256 _productType, uint256 _nonce)
    external
    onlyOwner
  {
    nonceOfProductType[_productType] = _nonce;
  }

  function setMinRewardOfProductType(uint256 _productType, uint256 _minReward)
    external
    onlyOwner
  {
    minRewardOfProductType[_productType] = _minReward;
  }

  function setProductNft(address _productNft) external onlyOwner {
    productNft = _productNft;
  }

  function setAnimeStudioNumber(uint256 _animeStudioNumber) external onlyOwner {
    animeStudioNumber = _animeStudioNumber;
  }

  function setInitialTime(uint256 _time) external onlyOwner {
    initialTime = _time;
  }

  function setInitialTime() external onlyOwner {
    initialTime = block.timestamp;
  }

  function setAnimeStudio(address _animeStudio) external onlyOwner {
    animeStudio = _animeStudio;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

interface IAnimeTokenStakingPool {
    // Views

    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getAverageTotalSupply() external view returns (uint256);

    // Mutative

    function exit() external;

    function buyNft() external;

    function stake(uint256 amount) external;

    function setPaused(bool _paused) external;

    function setProductPrice(uint256 _productType, uint256 _price) external;

    function setProductNonce(uint256 _productType, uint256 _nonce) external;

    function setMinRewardOfProductType(uint256 _productType, uint256 _minReward) external;

    function setProductNft(address _productNft) external;

    function setAnimeStudioNumber(uint256 _animeStudioNumber) external;

    function setInitialTime(uint256 _time) external;

    function setInitialTime() external;

    function setAnimeStudio(address _animeStudio) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;


interface IERC721Mintable {
    function exists(uint256 _tokenId) external view returns (bool);
    function mint(address _to, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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