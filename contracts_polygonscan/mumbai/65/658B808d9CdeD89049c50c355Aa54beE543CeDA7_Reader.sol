// SPDX-License-Identifier: GPL 3.0
pragma solidity ^0.8.2;
import "../mining/EntropyLiquidityFarm.sol";
import "../mining/EntropySponsorFarm.sol";

contract Reader {
	// DAO contract address
	address public DAO;
	address public pendingDAO;
	EntropyLiquidityFarm public lpFarm;
	EntropySponsorFarm public spFarm;
	modifier onlyDAO() {
		require(msg.sender == DAO, "Reader: FORBIDDEN");
		_;
	}

	constructor(
		address DAO_,
		address lpFarm_,
		address spFarm_
	) {
		require(DAO_ != address(0), "Reader:  ZERO ADDR");
		require(lpFarm_ != address(0), "Reader:  ZERO ADDR");
		require(spFarm_ != address(0), "Reader:  ZERO ADDR");
		DAO = DAO_; // default is DAO
		lpFarm = EntropyLiquidityFarm(lpFarm_);
		spFarm = EntropySponsorFarm(spFarm_);
	}

  /// @dev ---------------- user earned erp at lp and sp -------------------
  function userLPEarnedERPAmounts(address userAddr_)  public view returns(uint256[] memory results_) {
    uint256 poolAmount = lpFarm.poolLength();
		results_ = new uint256[](poolAmount);
		for (uint256 i = 0; i < poolAmount; i++) {
			results_[i] = _userLPEarnedERP(i, userAddr_);
		}
  }

  function userSPEarnedERPAmounts(address userAddr_)  public view returns(uint256[] memory results_) {
    uint256 poolAmount = spFarm.poolLength();
		results_ = new uint256[](poolAmount);
		for (uint256 i = 0; i < poolAmount; i++) {
			results_[i] = _userSPEarnedERP(i, userAddr_);
		}
  }

  function userEarnedERPAmounts(uint256 pid_, address userAddr_)  public view returns (uint256 lpEarned_, uint256 spEarned_) {
    lpEarned_ = _userLPEarnedERP(pid_, userAddr_);
    spEarned_ = _userSPEarnedERP(pid_, userAddr_);
  }

	/// @dev ---------------- user staked balance at lp and sp ---------------
	/// @dev user staked balance at lpfarm for all pids
	function userLPStakedBalances(address userAddr_) public view returns (uint256[] memory results_) {
		uint256 poolAmount = lpFarm.poolLength();
		results_ = new uint256[](poolAmount);
		for (uint256 i = 0; i < poolAmount; i++) {
			results_[i] = _userLPStakedBalance(i, userAddr_);
		}
	}

	/// @dev user staked balance at spfarm for all pids
	function userSPStakedBalances(address userAddr_) public view returns (uint256[] memory results_) {
		uint256 poolAmount = spFarm.poolLength();
		results_ = new uint256[](poolAmount);
		for (uint256 i = 0; i < poolAmount; i++) {
			results_[i] = _userSPStakedBalance(i, userAddr_);
		}
	}

  function userLPStakedBalance(uint256 pid_, address userAddr_) public view returns (uint256 balance_) {
    balance_ = _userLPStakedBalance(pid_, userAddr_);
  }

  function userSPStakedBalance(uint256 pid_, address userAddr_) public view returns (uint256 balance_) {
    balance_ = _userSPStakedBalance(pid_, userAddr_);
  }


	/// @dev -------------------------privte functions---------------------------------
	function _userLPStakedBalance(uint256 pid_, address userAddr_) private view returns (uint256 balance_) {
    (balance_, ) = lpFarm.userInfo(pid_, userAddr_);
  }

	function _userSPStakedBalance(uint256 pid_, address userAddr_) private view returns (uint256 balance_) {
    (balance_, ) = spFarm.userInfo(pid_, userAddr_);
  }
  /// @dev user's pending erp rewards
  function _userLPEarnedERP(uint256 pid_, address userAddr_) private view returns(uint256 result_) {
    result_ = lpFarm.pendingEntropy(pid_, userAddr_);
  }
  function _userSPEarnedERP(uint256 pid_, address userAddr_) private view returns(uint256 result_) {
    result_ = spFarm.pendingEntropy(pid_, userAddr_);
  }

	/**
	 * @dev set pendingDAO
	 * @notice only DAO can set pendingDAO
	 * @param _pendingDAO pending DAO address
	 */
	function setPendingDAO(address _pendingDAO) external onlyDAO {
		require(_pendingDAO != address(0), "Reader: set _pendingDAO to the zero address");
		pendingDAO = _pendingDAO;
	}

	/**
	 * @dev set DAO
	 * @notice only DAO can set the new DAO and it need to be pre added to pendingDAO
	 */
	function setDAO() external onlyDAO {
		require(pendingDAO != address(0), "Reader: set _DAO to the zero address");
		DAO = pendingDAO;
		pendingDAO = address(0);
	}

	function setLP(address lp_) external onlyDAO {
		require(lp_ != address(0), "Reader: ZERO ADDR");
		lpFarm = EntropyLiquidityFarm(lp_);
	}

	function setSP(address sp_) external onlyDAO {
		require(sp_ != address(0), "Reader: ZERO ADDR");
		spFarm = EntropySponsorFarm(sp_);
	}
}

// SPDX-License-Identifier: GPL 3.0
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EntropyLiquidityFarm is Ownable {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	// Info of each user.
	struct UserInfo {
		uint256 amount; // How many lp tokens the user has provided.
		uint256 rewardDebt; // Reward debt. See explanation below.
		//
		// We do some fancy math here. Basically, any point in time, the amount of ENTROPYs
		// entitled to a user but is pending to be distributed is:
		//
		//   pending reward = (user.amount * pool.accEntropyPerShare) - user.rewardDebt
		//
		// Whenever a user deposits or withdraws lp tokens to a pool. Here's what happens:
		//   1. The pool's `accEntropyPerShare` (and `lastRewardBlock`) gets updated.
		//   2. User receives the pending reward sent to his/her address.
		//   3. User's `amount` gets updated.
		//   4. User's `rewardDebt` gets updated.
	}
	// Info of each pool.
	struct PoolInfo {
		uint256 allocPoint; // How many allocation points assigned to this pool. ENTROPYs to distribute per block.
		uint256 lastRewardBlock; // Last block number that ENTROPYs distribution occurs.
		uint256 accEntropyPerShare; // Accumulated ENTROPYs per share, times 1e12. See below.
	}
	// The ENTROPY TOKEN!
	IERC20 public immutable entropy;
	// ENTROPY tokens created per block.
	uint256 public entropyPerBlock;
	// Info of each pool.
	PoolInfo[] public poolInfo;
	// Info of lp token.
	IERC20[] public lpToken;
	// check if the lp token already been added or not
	mapping(address => bool) public isTokenAdded;
	// check the pool ID from a specific sponsor token
	mapping(address => uint256) public getPoolID;
	// Info of each user that stakes lp tokens.
	mapping(uint256 => mapping(address => UserInfo)) public userInfo;
	// Total allocation poitns. Must be the sum of all allocation points in all pools.
	uint256 public totalAllocPoint = 0;

	// user actions event
	event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
	event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
	event Claim(address indexed user, uint256 indexed pid, uint256 amount);
	event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
	// admin actions event
	event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, bool withUpdate);
	event LogSetPool(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, bool withUpdate);
	event LogUpdatePool(uint256 indexed pid, uint256 lastRewardBlock, IERC20 indexed lpToken, uint256 accEntropyPerShare);

	modifier validatePoolByPid(uint256 _pid) {
		require(_pid < poolInfo.length, "LPFARM: Pool does not exist");
		_;
	}

	constructor(address _entropy, uint256 _entropyPerBlock) {
		entropy = IERC20(_entropy);
		entropyPerBlock = _entropyPerBlock;
	}

	function poolLength() external view returns (uint256) {
		return poolInfo.length;
	}

	// Add a new lp token to the pool. Can only be called by the owner.
	function add(
		uint256 _allocPoint,
		address _lpToken,
		bool _withUpdate
	) external onlyOwner {
		require(isTokenAdded[_lpToken] == false, "LPFARM: SPONSOR TOKEN ALREADY IN POOL");
		isTokenAdded[_lpToken] = true;
		if (_withUpdate) {
			massUpdatePools();
		}
		uint256 lastRewardBlock = block.number;
		totalAllocPoint = totalAllocPoint.add(_allocPoint);
		lpToken.push(IERC20(_lpToken));
		poolInfo.push(PoolInfo({ allocPoint: _allocPoint, lastRewardBlock: lastRewardBlock, accEntropyPerShare: 0 }));
		getPoolID[_lpToken] = poolInfo.length.sub(1);
		emit LogPoolAddition(poolInfo.length.sub(1), _allocPoint, IERC20(_lpToken), _withUpdate);
	}

	// Update the given pool's ENTROPY allocation point. Can only be called by the owner.
	function set(
		uint256 _pid,
		uint256 _allocPoint,
		bool _withUpdate
	) external onlyOwner validatePoolByPid(_pid) {
		if (_withUpdate) {
			massUpdatePools();
		}
		totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
		poolInfo[_pid].allocPoint = _allocPoint;
		emit LogSetPool(_pid, _allocPoint, lpToken[_pid], _withUpdate);
	}

	// View function to see pending ENTROPYs on frontend.
	function pendingEntropy(uint256 _pid, address _user) external view validatePoolByPid(_pid) returns (uint256) {
		PoolInfo memory pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][_user];
		uint256 accEntropyPerShare = pool.accEntropyPerShare;
		uint256 lpSupply = lpToken[_pid].balanceOf(address(this));
		if (block.number > pool.lastRewardBlock && lpSupply != 0) {
			uint256 blocks = block.number.sub(pool.lastRewardBlock);
			uint256 entropyReward = blocks.mul(entropyPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
			accEntropyPerShare = accEntropyPerShare.add(entropyReward.mul(1e12).div(lpSupply));
		}
		return user.amount.mul(accEntropyPerShare).div(1e12).sub(user.rewardDebt);
	}

	// Update reward vairables for all pools. Be careful of gas spending!
	function massUpdatePools() public {
		uint256 length = poolInfo.length;
		for (uint256 pid = 0; pid < length; ++pid) {
			updatePool(pid);
		}
	}

	// Update reward variables of the given pool to be up-to-date.
	function updatePool(uint256 _pid) public validatePoolByPid(_pid) {
		PoolInfo storage pool = poolInfo[_pid];
		if (block.number <= pool.lastRewardBlock) {
			return;
		}
		uint256 lpSupply = lpToken[_pid].balanceOf(address(this));
		if (lpSupply == 0) {
			pool.lastRewardBlock = block.number;
			return;
		}
		uint256 blocks = block.number.sub(pool.lastRewardBlock);
		uint256 entropyReward = blocks.mul(entropyPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
		pool.accEntropyPerShare = pool.accEntropyPerShare.add(entropyReward.mul(1e12).div(lpSupply));
		pool.lastRewardBlock = block.number;
		emit LogUpdatePool(_pid, pool.lastRewardBlock, lpToken[_pid], pool.accEntropyPerShare);
	}

	// Deposit lp tokens to MasterChef for ENTROPY allocation.
	function deposit(uint256 _pid, uint256 _amount) external validatePoolByPid(_pid) {
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];
		updatePool(_pid);
		if (user.amount > 0) {
			uint256 pending = user.amount.mul(pool.accEntropyPerShare).div(1e12).sub(user.rewardDebt);
			safeEntropyTransfer(msg.sender, pending);
		}
		lpToken[_pid].safeTransferFrom(address(msg.sender), address(this), _amount);
		user.amount = user.amount.add(_amount);
		user.rewardDebt = user.amount.mul(pool.accEntropyPerShare).div(1e12);
		emit Deposit(msg.sender, _pid, _amount);
	}

	// Withdraw lp tokens from MasterChef.
	function withdraw(uint256 _pid, uint256 _amount) external validatePoolByPid(_pid) {
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];
		require(user.amount >= _amount, "LPFARM: INSUFFICIENT BALANCE");
		updatePool(_pid);

		uint256 pending = user.amount.mul(pool.accEntropyPerShare).div(1e12).sub(user.rewardDebt);
		safeEntropyTransfer(msg.sender, pending);
		emit Claim(msg.sender, _pid, pending);

		user.amount = user.amount.sub(_amount);
		user.rewardDebt = user.amount.mul(pool.accEntropyPerShare).div(1e12);
		lpToken[_pid].safeTransfer(address(msg.sender), _amount);
		emit Withdraw(msg.sender, _pid, _amount);
	}

	// Claim mint entropy tokens
	function claim(uint256 _pid) external validatePoolByPid(_pid) {
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];
		updatePool(_pid);
		uint256 accumulatedEntropy = user.amount.mul(pool.accEntropyPerShare).div(1e12);
		uint256 pending = accumulatedEntropy.sub(user.rewardDebt);
		user.rewardDebt = accumulatedEntropy;
		safeEntropyTransfer(msg.sender, pending);
		emit Claim(msg.sender, _pid, pending);
	}

	// Withdraw without caring about rewards. EMERGENCY ONLY.
	function emergencyWithdraw(uint256 _pid) external validatePoolByPid(_pid) {
		UserInfo storage user = userInfo[_pid][msg.sender];

		uint256 amount = user.amount;
		user.amount = 0;
		user.rewardDebt = 0;

		lpToken[_pid].safeTransfer(address(msg.sender), amount);
		emit EmergencyWithdraw(msg.sender, _pid, user.amount);
	}

	// Safe entropy transfer function, just in case if rounding error causes pool to not have enough ENTROPYs.
	function safeEntropyTransfer(address _to, uint256 _amount) private {
		uint256 entropyBal = entropy.balanceOf(address(this));
		if (_amount > entropyBal) {
			entropy.transfer(_to, entropyBal);
		} else {
			entropy.transfer(_to, _amount);
		}
	}

	// Rescue left over ERP token
	function rescue(uint256 amount_) external onlyOwner {
		IERC20(entropy).transfer(owner(), amount_);
	}
}

// SPDX-License-Identifier: GPL 3.0
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EntropySponsorFarm is Ownable {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	// Info of each user.
	struct UserInfo {
		uint256 amount; // How many sponsor tokens the user has provided.
		uint256 rewardDebt; // Reward debt. See explanation below.
		//
		// We do some fancy math here. Basically, any point in time, the amount of ENTROPYs
		// entitled to a user but is pending to be distributed is:
		//
		//   pending reward = (user.amount * pool.accEntropyPerShare) - user.rewardDebt
		//
		// Whenever a user deposits or withdraws sponsor tokens to a pool. Here's what happens:
		//   1. The pool's `accEntropyPerShare` (and `lastRewardBlock`) gets updated.
		//   2. User receives the pending reward sent to his/her address.
		//   3. User's `amount` gets updated.
		//   4. User's `rewardDebt` gets updated.
	}
	// Info of each pool.
	struct PoolInfo {
		uint256 allocPoint; // How many allocation points assigned to this pool. ENTROPYs to distribute per block.
		uint256 lastRewardBlock; // Last block number that ENTROPYs distribution occurs.
		uint256 accEntropyPerShare; // Accumulated ENTROPYs per share, times 1e12. See below.
	}
	// The ENTROPY TOKEN!
	IERC20 public immutable entropy;
	// ENTROPY tokens created per block.
	uint256 public entropyPerBlock;
	// Info of each pool.
	PoolInfo[] public poolInfo;
	// Info of sponsor token.
	IERC20[] public sponsorToken;
	// check if the sponsor token already been added or not
	mapping(address => bool) public isTokenAdded;
	// check the pool ID from a specific sponsor token
	mapping(address => uint256) public getPoolID;
	// Info of each user that stakes sponsor tokens.
	mapping(uint256 => mapping(address => UserInfo)) public userInfo;
	// Total allocation poitns. Must be the sum of all allocation points in all pools.
	uint256 public totalAllocPoint = 0;

	// user actions event
	event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
	event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
	event Claim(address indexed user, uint256 indexed pid, uint256 amount);
	event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
	// admin actions event
	event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed sponsorToken, bool withUpdate);
	event LogSetPool(uint256 indexed pid, uint256 allocPoint, IERC20 indexed sponsorToken, bool withUpdate);
	event LogUpdatePool(uint256 indexed pid, uint256 lastRewardBlock, IERC20 indexed sponsorToken, uint256 accEntropyPerShare);

	modifier validatePoolByPid(uint256 _pid) {
		require(_pid < poolInfo.length, "SPFARM: Pool does not exist");
		_;
	}

	constructor(address _entropy, uint256 _entropyPerBlock) {
		entropy = IERC20(_entropy);
		entropyPerBlock = _entropyPerBlock;
	}

	function poolLength() external view returns (uint256) {
		return poolInfo.length;
	}

	// Add a new sponsor token to the pool. Can only be called by the owner.
	function add(
		uint256 _allocPoint,
		address _sponsorToken,
		bool _withUpdate
	) external onlyOwner {
		require(isTokenAdded[_sponsorToken] == false, "SPFARM: SPONSOR TOKEN ALREADY IN POOL");
		isTokenAdded[_sponsorToken] = true;
		if (_withUpdate) {
			massUpdatePools();
		}
		uint256 lastRewardBlock = block.number;
		totalAllocPoint = totalAllocPoint.add(_allocPoint);
		sponsorToken.push(IERC20(_sponsorToken));
		poolInfo.push(PoolInfo({ allocPoint: _allocPoint, lastRewardBlock: lastRewardBlock, accEntropyPerShare: 0 }));
		getPoolID[_sponsorToken] = poolInfo.length.sub(1);
		emit LogPoolAddition(poolInfo.length.sub(1), _allocPoint, IERC20(_sponsorToken), _withUpdate);
	}

	// Update the given pool's ENTROPY allocation point. Can only be called by the owner.
	function set(
		uint256 _pid,
		uint256 _allocPoint,
		bool _withUpdate
	) external onlyOwner validatePoolByPid(_pid) {
		if (_withUpdate) {
			massUpdatePools();
		}
		totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
		poolInfo[_pid].allocPoint = _allocPoint;
		emit LogSetPool(_pid, _allocPoint, sponsorToken[_pid], _withUpdate);
	}

	// View function to see pending ENTROPYs on frontend.
	function pendingEntropy(uint256 _pid, address _user) external view validatePoolByPid(_pid) returns (uint256) {
		PoolInfo memory pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][_user];
		uint256 accEntropyPerShare = pool.accEntropyPerShare;
		uint256 sponsorSupply = sponsorToken[_pid].balanceOf(address(this));
		if (block.number > pool.lastRewardBlock && sponsorSupply != 0) {
			uint256 blocks = block.number.sub(pool.lastRewardBlock);
			uint256 entropyReward = blocks.mul(entropyPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
			accEntropyPerShare = accEntropyPerShare.add(entropyReward.mul(1e12).div(sponsorSupply));
		}
		return user.amount.mul(accEntropyPerShare).div(1e12).sub(user.rewardDebt);
	}

	// Update reward vairables for all pools. Be careful of gas spending!
	function massUpdatePools() public {
		uint256 length = poolInfo.length;
		for (uint256 pid = 0; pid < length; ++pid) {
			updatePool(pid);
		}
	}

	// Update reward variables of the given pool to be up-to-date.
	function updatePool(uint256 _pid) public validatePoolByPid(_pid) {
		PoolInfo storage pool = poolInfo[_pid];
		if (block.number <= pool.lastRewardBlock) {
			return;
		}
		uint256 sponsorSupply = sponsorToken[_pid].balanceOf(address(this));
		if (sponsorSupply == 0) {
			pool.lastRewardBlock = block.number;
			return;
		}
		uint256 blocks = block.number.sub(pool.lastRewardBlock);
		uint256 entropyReward = blocks.mul(entropyPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
		pool.accEntropyPerShare = pool.accEntropyPerShare.add(entropyReward.mul(1e12).div(sponsorSupply));
		pool.lastRewardBlock = block.number;
		emit LogUpdatePool(_pid, pool.lastRewardBlock, sponsorToken[_pid], pool.accEntropyPerShare);
	}

	// Deposit sponsor tokens to MasterChef for ENTROPY allocation.
	function deposit(uint256 _pid, uint256 _amount) external validatePoolByPid(_pid) {
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];
		updatePool(_pid);
		if (user.amount > 0) {
			uint256 pending = user.amount.mul(pool.accEntropyPerShare).div(1e12).sub(user.rewardDebt);
			safeEntropyTransfer(msg.sender, pending);
		}
		sponsorToken[_pid].safeTransferFrom(address(msg.sender), address(this), _amount);
		user.amount = user.amount.add(_amount);
		user.rewardDebt = user.amount.mul(pool.accEntropyPerShare).div(1e12);
		emit Deposit(msg.sender, _pid, _amount);
	}

	// Withdraw sponsor tokens from MasterChef.
	function withdraw(uint256 _pid, uint256 _amount) external validatePoolByPid(_pid) {
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];
		require(user.amount >= _amount, "SPFARM: INSUFFICIENT BALANCE");
		updatePool(_pid);

		uint256 pending = user.amount.mul(pool.accEntropyPerShare).div(1e12).sub(user.rewardDebt);
		safeEntropyTransfer(msg.sender, pending);
		emit Claim(msg.sender, _pid, pending);

		user.amount = user.amount.sub(_amount);
		user.rewardDebt = user.amount.mul(pool.accEntropyPerShare).div(1e12);
		sponsorToken[_pid].safeTransfer(address(msg.sender), _amount);
		emit Withdraw(msg.sender, _pid, _amount);
	}

	// Claim mint entropy tokens
	function claim(uint256 _pid) external validatePoolByPid(_pid) {
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];
		updatePool(_pid);
		uint256 accumulatedEntropy = user.amount.mul(pool.accEntropyPerShare).div(1e12);
		uint256 pending = accumulatedEntropy.sub(user.rewardDebt);
		user.rewardDebt = accumulatedEntropy;
		safeEntropyTransfer(msg.sender, pending);
		emit Claim(msg.sender, _pid, pending);
	}

	// Withdraw without caring about rewards. EMERGENCY ONLY.
	function emergencyWithdraw(uint256 _pid) external validatePoolByPid(_pid) {
		UserInfo storage user = userInfo[_pid][msg.sender];

		uint256 amount = user.amount;
		user.amount = 0;
		user.rewardDebt = 0;

		sponsorToken[_pid].safeTransfer(address(msg.sender), amount);
		emit EmergencyWithdraw(msg.sender, _pid, user.amount);
	}

	// Safe entropy transfer function, just in case if rounding error causes pool to not have enough ENTROPYs.
	function safeEntropyTransfer(address _to, uint256 _amount) private {
		uint256 entropyBal = entropy.balanceOf(address(this));
		if (_amount > entropyBal) {
			entropy.transfer(_to, entropyBal);
		} else {
			entropy.transfer(_to, _amount);
		}
	}

	// Rescue left over ERP token
	function rescue(uint256 amount_) external onlyOwner {
		IERC20(entropy).transfer(owner(), amount_);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}