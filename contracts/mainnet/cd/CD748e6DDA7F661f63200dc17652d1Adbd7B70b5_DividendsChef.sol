// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract DividendsChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of token contract.
        uint256 lastRewardBlock; // Last block number that Rewards distribution occurs.
        uint256 accRewardPerShare; // Accumulated Rewards per share, times 1e18. See below.
        uint256 burnFee; // burning fee for deposit tokens
        uint256 lpSupply; // Pool balance
    }

    IERC20 public rewardToken;

    // Project address to manage fees for burn
    address public projectAddress;

    // Reward tokens created per block.
    uint256 public rewardPerBlock;

    // Info of each pool.
    PoolInfo public poolInfo;
    // Info of each user that stakes tokens.
    mapping(address => UserInfo) public userInfo;
    // Block number when pool start giving reward
    uint256 public startBlock;
    // Block number when pool ends giving rewards
    uint256 public endBlock;
    // Maximum deposit fees
    uint256 public constant MAX_BURN_FEES = 500;
    // Deposit fees divider
    uint256 private constant DEPOSIT_FEES_DIVIDER = 10000;

    enum UpdateRewardType {
        UpdateEndOp,
        UpdateStartOp,
        DepositOp
    }

    modifier enoughAmountToWithdraw(uint256 _amount) {
        require(userInfo[msg.sender].amount >= _amount, "withdraw: not good");
        _;
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    event DepositRewards(uint256 amount);
    event UpdateStartBlock(uint256 startBlock);
    event UpdateEndBlock(uint256 endBlock);

    constructor(
        IERC20 _depositToken,
        IERC20 _rewardToken,
        uint256 _startBlock,
        uint256 _endBlock,
        address _projectAddress,
        uint256 _burnFee
    ) {
        require(
            _burnFee <= MAX_BURN_FEES,
            "add: invalid deposit fee basis points"
        );
        rewardToken = _rewardToken;
        startBlock = _startBlock;
        endBlock = _endBlock;
        projectAddress = _projectAddress;

        // staking pool
        poolInfo = PoolInfo({
            token: _depositToken,
            lastRewardBlock: startBlock,
            accRewardPerShare: 0,
            burnFee: _burnFee,
            lpSupply: 0
        });

        rewardPerBlock = 0;
    }

    /**
     * Returns the reward token balance left in the pool
     */
    function rewardBalance() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    /**
     * Returns the total deposited tokens
     */
    function stakeBalance() public view returns (uint256) {
        // Return pool balance
        return poolInfo.lpSupply;
    }

    /**
     * Deposit pool rewards. After deposit it recalculates reward tokens per block
     * @param _amount must be bigger than 0
     */
    function depositRewards(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Deposit value must be greater than 0.");
        updatePool();
        rewardToken.safeTransferFrom(msg.sender, address(this), _amount);
        updateRewardPerBlock(UpdateRewardType.DepositOp);
        emit DepositRewards(_amount);
    }

    /**
     * Stop pool rewards
     */
    function stopReward() external onlyOwner {
        endBlock = block.number;
    }

    /**
     * Adjust endBlock by calculating the tokens left for rewards and the rewardPerBlock amount.
     */
    function adjustBlockEnd() external onlyOwner {
        uint256 totalLeft = rewardBalance();
        endBlock = block.number + totalLeft.div(rewardPerBlock);
    }

    /**
     * Updates de rewardPerBlock value based in the reward balance left in the pool and the _blockNumber param
     * and updates the pool
     * @param _type type of function operation that is calling updateRewardPerBlock funcion
     */
    function updateRewardPerBlock(UpdateRewardType _type) internal {
        uint256 totalLeft = rewardBalance();
        bool farmStarted = block.number > startBlock;
        if (
            (_type == UpdateRewardType.UpdateEndOp ||
                _type == UpdateRewardType.DepositOp) && farmStarted == true
        ) {
            rewardPerBlock = totalLeft.div(
                endBlock.sub(poolInfo.lastRewardBlock)
            );
        } else if (
            (_type == UpdateRewardType.UpdateEndOp ||
                _type == UpdateRewardType.DepositOp ||
                _type == UpdateRewardType.UpdateStartOp) && farmStarted == false
        ) {
            rewardPerBlock = totalLeft.div(endBlock.sub(startBlock));
        }
    }

    /**
     * Updates endBlock recalculating the rewardPerBlock based in actual amount
     */
    function updateEndBlock(uint256 _endBlock) external onlyOwner {
        require(
            _endBlock > block.number,
            "New endblock must be bigger than actual block"
        );

        endBlock = _endBlock;
        // recalculate rewardPerBlock
        updatePool();
        updateRewardPerBlock(UpdateRewardType.UpdateEndOp);
        emit UpdateEndBlock(_endBlock);
    }

    /**
     * Updates start block if the new start block is bigger than actual block number
     * and dividend pool has not started
     + @param _startBlock New startBlock for dividend pool
     */
    function updateStartBlock(uint256 _startBlock) external onlyOwner {
        require(
            block.number < startBlock,
            "cannot change start block if dividend pool has already started"
        );
        require(
            block.number < _startBlock,
            "New startBlock must be bigger than actual block"
        );
        poolInfo.lastRewardBlock = _startBlock;
        startBlock = _startBlock;
        updatePool();
        updateRewardPerBlock(UpdateRewardType.UpdateStartOp);
        emit UpdateStartBlock(startBlock);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= endBlock) {
            return _to.sub(_from);
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return endBlock.sub(_from);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = poolInfo.accRewardPerShare;

        if (block.number > poolInfo.lastRewardBlock && poolInfo.lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                poolInfo.lastRewardBlock,
                block.number
            );
            uint256 reward = multiplier.mul(rewardPerBlock);
            uint256 totalLeft = rewardBalance();
            // If reward is bigger thant total amount left for rewards
            if (reward > totalLeft) {
                reward = totalLeft;
            }
            accRewardPerShare = accRewardPerShare.add(
                reward.mul(1e18).div(poolInfo.lpSupply)
            );
        }
        return
            user.amount.mul(accRewardPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        if (block.number <= poolInfo.lastRewardBlock) {
            return;
        }
        if (poolInfo.lpSupply == 0) {
            poolInfo.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(
            poolInfo.lastRewardBlock,
            block.number
        );
        uint256 reward = multiplier.mul(rewardPerBlock);
        uint256 totalLeft = rewardBalance();
        if (reward > totalLeft) {
            reward = totalLeft;
        }
        poolInfo.accRewardPerShare = poolInfo.accRewardPerShare.add(
            reward.mul(1e18).div(poolInfo.lpSupply)
        );
        poolInfo.lastRewardBlock = block.number;
    }

    // Stake depositToken tokens to SmartChef.
    // If burning fee bigger than 0 it will send percentage tokens
    // to project Address to manage those tokens and send to dead wallet
    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(poolInfo.accRewardPerShare)
                .div(1e18)
                .sub(user.rewardDebt);
            if (pending > 0) {
                rewardToken.safeTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            uint256 balanceBefore = poolInfo.token.balanceOf(address(this));
            poolInfo.token.safeTransferFrom(msg.sender, address(this), _amount);
            _amount = poolInfo.token.balanceOf(address(this)).sub(
                balanceBefore
            );
            if (poolInfo.burnFee > 0) {
                uint256 burnFee = _amount.mul(poolInfo.burnFee).div(
                    DEPOSIT_FEES_DIVIDER
                );
                poolInfo.token.safeTransfer(projectAddress, burnFee);
                user.amount = user.amount.add(_amount).sub(burnFee);
                poolInfo.lpSupply = poolInfo.lpSupply.add(_amount).sub(burnFee);
            } else {
                user.amount = user.amount.add(_amount);
                poolInfo.lpSupply = poolInfo.lpSupply.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(poolInfo.accRewardPerShare).div(1e18);
        emit Deposit(msg.sender, _amount);
    }

    // Withdraw depositToken tokens from STAKING.
    function withdraw(uint256 _amount)
        external
        enoughAmountToWithdraw(_amount)
        nonReentrant
    {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        uint256 pending = user
            .amount
            .mul(poolInfo.accRewardPerShare)
            .div(1e18)
            .sub(user.rewardDebt);
        if (pending > 0) {
            rewardToken.safeTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            poolInfo.token.safeTransfer(msg.sender, _amount);
            poolInfo.lpSupply = poolInfo.lpSupply.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(poolInfo.accRewardPerShare).div(1e18);
        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        poolInfo.token.safeTransfer(msg.sender, amount);
        if (poolInfo.lpSupply >= amount) {
            poolInfo.lpSupply = poolInfo.lpSupply.sub(amount);
        } else {
            poolInfo.lpSupply = 0;
        }
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        require(
            _amount <= rewardToken.balanceOf(address(this)),
            "not enough token"
        );
        rewardToken.safeTransfer(msg.sender, _amount);
    }
}