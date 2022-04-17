// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./WizardToken.sol";

// Masterchef is the master of Wizard. He can make Wizard and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once TEST is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract WizardMasterchef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of WIZARDs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accWizardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accWizardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. WIZARDs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that WIZARDs distribution occurs.
        uint256 accWizardPerShare;   // Accumulated WIZARDs per share, times 1e12. See below.
        uint256 depositFeeBP;      // Deposit fee in basis points
        uint256 lpSupply; // To determine more precisely the deposits and avoid the dilution of rewards
    }

    // The WIZARD TOKEN!
    WizardToken public wizard;
    // Dev address.
    address public devAddress;
    // Deposit Fee address
    address public feeAddress;
    // WIZARD tokens created per block.
    uint256 public wizardPerBlock;
    // Bonus muliplier for early wizard makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Max deposit fee: 4%.
    uint16 public constant MAXIMUM_DEPOSIT_FEE = 400;
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when WIZARD mining starts.
    uint256 public startBlock;

    // Max Wizard Supply
    uint256 public WizardMaxSupply = 25000000e18;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);

    constructor(
        WizardToken _wizard,
        uint256 _startBlock,
        uint256 _wizardPerBlock
    ) public {
        wizard = _wizard;
        startBlock = _startBlock;
        wizardPerBlock = _wizardPerBlock;

        devAddress = msg.sender;
        feeAddress = msg.sender;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function currentBlock() external view returns (uint256) {
        return block.number;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, address _lpToken, uint256 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accWizardPerShare: 0,
            depositFeeBP: _depositFeeBP,
            lpSupply: 0
        }));
    }

    // Update the given pool's WIZARD allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint256 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (IBEP20(wizard).totalSupply() >= WizardMaxSupply) {return 0;}
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending WIZARDs on frontend.
    function pendingWizard(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accWizardPerShare = pool.accWizardPerShare;
        if (block.number > pool.lastRewardBlock && pool.lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 wizardReward = multiplier.mul(wizardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accWizardPerShare = accWizardPerShare.add(wizardReward.mul(1e12).div(pool.lpSupply));
        }
        uint256 pending = user.amount.mul(accWizardPerShare).div(1e12).sub(user.rewardDebt);
        return pending;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 wizardReward = multiplier.mul(wizardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        wizard.mint(devAddress, wizardReward.div(20));
        wizard.mint(address(this), wizardReward);
        pool.accWizardPerShare = pool.accWizardPerShare.add(wizardReward.mul(1e12).div(pool.lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to Masterchef for WIZARD allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accWizardPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeWizardTransfer(msg.sender, pending);
            }
        }

        if (_amount > 0) {
            uint256 beforeDeposit = IBEP20(pool.lpToken).balanceOf(address(this));
            IBEP20(pool.lpToken).safeTransferFrom(msg.sender, address(this), _amount);
            uint256 afterDeposit = IBEP20(pool.lpToken).balanceOf(address(this));
            _amount = afterDeposit.sub(beforeDeposit); // real amount of LP transfer to this address

            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(1e4);
                IBEP20(pool.lpToken).safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
                pool.lpSupply = pool.lpSupply.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
                pool.lpSupply = pool.lpSupply.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accWizardPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    
    // Safe wizard transfer function, just in case if rounding error causes pool to not have enough WIZARDs.
    function safeWizardTransfer(address _to, uint256 _amount) internal {
        uint256 wizardBal = wizard.balanceOf(address(this));
        if (_amount > wizardBal) {
            wizard.transfer(_to, wizardBal);
        } else {
            wizard.transfer(_to, _amount);
        }
    }
    
    // Withdraw LP tokens from Masterchef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);

        uint256 pending = user.amount.mul(pool.accWizardPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeWizardTransfer(msg.sender, pending);
        }

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpSupply = pool.lpSupply.sub(_amount);
            IBEP20(pool.lpToken).safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accWizardPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        pool.lpSupply = pool.lpSupply.sub(user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        IBEP20(pool.lpToken).safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Update dev address by the previous dev.
    function setDevAddress(address _devAddress) public {
        require(msg.sender == devAddress, "setDevAddress: FORBIDDEN");
        require(_devAddress != address(0), "setDevAddress: ZERO");
        devAddress = _devAddress;
    }
    
    // Update Fee Address
    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
    }

    // Pancake has to add hidden dummy pools in order to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _wizardPerBlock) public onlyOwner {
        massUpdatePools();
        emit EmissionRateUpdated(msg.sender, wizardPerBlock, _wizardPerBlock);
        wizardPerBlock = _wizardPerBlock;
    }

    // Only update before start of farm
    function updaartBlock(uint256 _startBlock) external onlyOwner {
	    require(startBlock > block.number, "Farm already started");
        startBlock = _startBlock;
        
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lastRewardBlock = startBlock;
        }
    }
}