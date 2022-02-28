// SPDX-License-Identifier: MIT

//     ___                         __ 
//    /   |  _____________  ____  / /_
//   / /| | / ___/ ___/ _ \/ __ \/ __/
//  / ___ |(__  |__  )  __/ / / / /_  
// /_/  |_/____/____/\___/_/ /_/\__/  
// 
// 2022 - Assent Protocol

pragma solidity 0.8.11;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IMultipleRewards.sol";
import "./IReferral.sol";
import "./SafeERC20.sol";
import "./ASNTToken.sol";
import "./IAssentVIP.sol";

contract AssentMasterchef is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardLockedUp; // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
		uint256 noHarvestFeeAfter; //No harvest fee after this duration
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. ASNT to distribute per block.
        uint256 lastRewardTimestamp; // Last block number that ASNT distribution occurs.
        uint256 accASNTPerShare; // Accumulated ASNT per share, times 1e18. See below.
        uint256 depositFeeRate; // Deposit fee
        uint256 harvestInterval; // Harvest interval in seconds
        uint256 harvestFeeInterval; // Harvest fee minimum interval in seconds
        uint256 harvestFeeRate; // Harvest fee ONLY on rewards in basis points when the harvest occurs before the minimum interval        
        uint256 totalLp; // Total token in Pool
        IMultipleRewards[] rewarders; // Array of rewarder contract for pools with incentives
    }
   
	// ASNT token
    ASNTToken immutable public ASNT;

    // ASNT tokens created per second
    uint256 public ASNTPerSec;

    // Maximum emission rate : ASNTPerBlock can't be more than 50 per sec
    uint256 public constant MAX_EMISSION_RATE = 50 ether;
    // Max harvest interval: 14 days
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;    
    // Max harvest fee interval: 10 days.
    uint256 public constant MAXIMUM_HARVESTFEE_INTERVAL = 10 days; 
    // Max harvest fee : 10% / Harvest fee applied ONLY on rewards, never on deposited assets
    uint256 public constant MAXIMUM_HARVEST_FEE_RATE = 0.1 ether; // 10%
    // Maximum deposit fee rate: 10%
    uint256 public constant MAXIMUM_DEPOSIT_FEE_RATE = 0.1 ether; // 10%
    // Maximum percentage of pool rewards that goto the share address: 10%
    uint16 public constant MAXIMUM_SHARE_RATE = 1000;
    // Maximum number of rewarders per pool
    uint16 public constant MAXIMUM_REWARDERS = 10;      
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint public constant MULTIPLIER = 10**18;
    uint public constant MAXFEEREDUCTION = 0.8 ether; // 80%    

    // Info of each pool
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    // The timestamp when ASNT mining starts.
    uint256 public startTimestamp;

    // Total locked up rewards
    uint256 public totalLockedUpRewards;
    
    // ASNT referral contract address.
    IReferral public ASNTReferral;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 100;

    // Total ASNT in ASNT Pools (can be multiple pools)
    uint256 public totalASNTInPools;

    // ASNTshare address.
    address public ASNTShareAddress;

    // deposit fee address if needed
    address public feeAddress;

    // Percentage of pool rewards that goto the share address
    uint256 public ASNTSharePercent;

    // The precision factor
    uint256 private constant ACC_TOKEN_PRECISION = 1e18;
	
	// Assent VIP fee reduction contract
	IAssentVIP public vip;

    modifier validatePoolByPid(uint256 _pid) {
        require(_pid < poolInfo.length, "Pool does not exist");
        _;
    }

    event Add(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, uint256 depositFeeRate, uint256 harvestInterval, uint256 harvestFeeInterval, uint256 harvestFeeBP, IMultipleRewards[] indexed rewarders);
    event Set(uint256 indexed pid, uint256 allocPoint, uint256 depositFeeRate, uint256 harvestInterval, uint256 harvestFeeInterval, uint256 harvestFeeBP, IMultipleRewards[] indexed rewarders);
    event UpdatePool(uint256 indexed pid, uint256 lastRewardTimestamp, uint256 lpSupply, uint256 accASNTPerShare);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousValue, uint256 newValue);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event AllocPointsUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event SetASNTShareAddress(address indexed oldAddress, address indexed newAddress);
    event SetFeeAddress(address indexed oldAddress, address indexed newAddress);
    event SetASNTSharePercent(uint256 oldPercent, uint256 newPercent);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 newAmount);
    event ReferralRateUpdated(address indexed user, uint256 previousAmount, uint256 newAmount);
    event ASNTReferralUpdated(address indexed user, IReferral newAddress);
    event RewardsMinted( address indexed caller, address indexed recipient, uint amount );
    event ASNTMaxSupplyReached( address indexed recipient, uint amount );
	event VIPUpdated(IAssentVIP indexed previousAddress, IAssentVIP indexed newAddress);

    constructor(
        ASNTToken _ASNT,
        uint256 _ASNTPerSec
    ) {        
        startTimestamp = block.timestamp + (60 * 60 * 24 * 365);
        ASNT = _ASNT;
		require(_ASNTPerSec <= MAX_EMISSION_RATE, "Emission > max emission rate");        
        ASNTPerSec = _ASNTPerSec;
        ASNTSharePercent = 0;
        ASNTShareAddress = msg.sender;
        feeAddress = msg.sender;
    }

    //
    // VIEW
    //

    // Get pool lenght
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // View function to see pending rewards on frontend.
    function pendingTokens(uint256 _pid, address _user) external view validatePoolByPid(_pid) returns (
            address[] memory addresses,
            string[] memory symbols,
            uint256[] memory decimals,
            uint256[] memory amounts
        )
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accASNTPerShare = pool.accASNTPerShare;
        uint256 lpSupply = pool.totalLp;

        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 multiplier = block.timestamp - pool.lastRewardTimestamp;
            uint256 total = 1000;
            uint256 lpPercent = total - ASNTSharePercent;

            uint256 ASNTReward = (multiplier * ASNTPerSec * pool.allocPoint * lpPercent) / totalAllocPoint / total;

            accASNTPerShare += (ASNTReward * ACC_TOKEN_PRECISION) / lpSupply;
        }

        uint256 pendingASNT = (((user.amount * accASNTPerShare) / ACC_TOKEN_PRECISION) - user.rewardDebt) + user.rewardLockedUp;

        addresses = new address[](pool.rewarders.length + 1);
        symbols = new string[](pool.rewarders.length + 1);
        amounts = new uint256[](pool.rewarders.length + 1);
        decimals = new uint256[](pool.rewarders.length + 1);

        addresses[0] = address(ASNT);
        symbols[0] = IERC20(ASNT).symbol();
        decimals[0] = IERC20(ASNT).decimals();
        amounts[0] = pendingASNT;

        for (uint256 rewarderId = 0; rewarderId < pool.rewarders.length; ++rewarderId) {
            addresses[rewarderId + 1] = address(pool.rewarders[rewarderId].rewardToken());

            symbols[rewarderId + 1] = IERC20(pool.rewarders[rewarderId].rewardToken()).symbol();

            decimals[rewarderId + 1] = IERC20(pool.rewarders[rewarderId].rewardToken()).decimals();

            amounts[rewarderId + 1] = pool.rewarders[rewarderId].pendingTokens(_pid, _user);
        }
    }

    // View function to see pool rewards datas
    function poolRewardsDatas(uint256 _pid) external view validatePoolByPid(_pid)
        returns (
            address[] memory addresses,
            string[] memory symbols,
            uint256[] memory decimals,
            uint256[] memory rewardsPerSec,
            uint256[] memory rewardStartTime,
            uint256[] memory rewardEndTime,
            IMultipleRewards.RewarderType[] memory rewarderType
        )
    {
        PoolInfo storage pool = poolInfo[_pid];

        addresses = new address[](pool.rewarders.length + 1);
        symbols = new string[](pool.rewarders.length + 1);
        decimals = new uint256[](pool.rewarders.length + 1);
        rewardsPerSec = new uint256[](pool.rewarders.length + 1);
        rewardStartTime = new uint256[](pool.rewarders.length + 1);
        rewardEndTime = new uint256[](pool.rewarders.length + 1);
        rewarderType = new IMultipleRewards.RewarderType[](pool.rewarders.length + 1);

        addresses[0] = address(ASNT);
        symbols[0] = IERC20(ASNT).symbol();
        decimals[0] = IERC20(ASNT).decimals();

        uint256 total = 1000;
        uint256 lpPercent = total - ASNTSharePercent;

        rewardsPerSec[0] = (pool.allocPoint * ASNTPerSec * lpPercent) / totalAllocPoint / total;

        for (uint256 rewarderId = 0; rewarderId < pool.rewarders.length; ++rewarderId) {
            addresses[rewarderId + 1] = address(pool.rewarders[rewarderId].rewardToken());

            symbols[rewarderId + 1] = IERC20(pool.rewarders[rewarderId].rewardToken()).symbol();

            decimals[rewarderId + 1] = IERC20(pool.rewarders[rewarderId].rewardToken()).decimals();

            rewardsPerSec[rewarderId + 1] = pool.rewarders[rewarderId].poolRewardsPerSec(_pid);

            (,,,rewardStartTime[rewarderId + 1],rewardEndTime[rewarderId + 1],rewarderType[rewarderId + 1]) = pool.rewarders[rewarderId].getPoolInfo(_pid);
        }
    }

    // View function to see rewarders contract address for a pool
    function poolRewarders(uint256 _pid) external view validatePoolByPid(_pid) returns (address[] memory rewarders) {
        PoolInfo storage pool = poolInfo[_pid];
        rewarders = new address[](pool.rewarders.length);
        for (uint256 rewarderId = 0; rewarderId < pool.rewarders.length; ++rewarderId) {
            rewarders[rewarderId] = address(pool.rewarders[rewarderId]);
        }
    }

    // View function to see if user can harvest ASNT.
    function canHarvest(uint256 _pid, address _user) public view validatePoolByPid(_pid) returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= startTimestamp && block.timestamp >= user.nextHarvestUntil;
    }

    // View function to see if user harvest fees apply to the harvest
    function noHarvestFee(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.noHarvestFeeAfter;
    }

    // Get pool total deposit
    function poolTotalLp(uint256 pid) external view returns (uint256) {
        return poolInfo[pid].totalLp;
    }

    // Get the deposit fee reduction for user including the user fee reduction from VIP system
    function getUserDepositFee(address user, uint256 _depositfeeRate) public view returns (uint256 newDepositFeeRate) {
        uint userFeeReduction = getFarmsDepFeeReduction(user);
        require (userFeeReduction <= MAXFEEREDUCTION, "Fee reduction too high");
        return _depositfeeRate*(MULTIPLIER-userFeeReduction)/MULTIPLIER;
    }

    // Get fee reduction from vip contract
    function getFarmsDepFeeReduction(address _user) public view returns(uint _farmDepFeeReduction) { //TODO need test with whitelist contract
        if (address(vip) != address(0)) {
            return vip.getFarmsDepFeeReduction(_user);
        }
        else {
            return 0;
        }        
    }

    //
    // ACTION
    //

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() external nonReentrant {
        _massUpdatePools();
    }

    // Internal method for massUpdatePools
    function _massUpdatePools() internal {
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            _updatePool(pid);
        }
    }

    // Check if a mint is possible
    function _checkBeforeMintRewards(address _recipient, uint _amount ) internal returns ( bool ) {
        // Mint only if max supply not reached
        uint256 _totalSupply = ASNT.totalSupply();
        uint256 _maxCapSupply = ASNT.maxSupply();

        if ((_totalSupply + _amount) <= _maxCapSupply) {
            ASNT.mint(_recipient, _amount);
            emit RewardsMinted(msg.sender, _recipient, _amount);
            return true;
        }
        else {
            emit ASNTMaxSupplyReached(_recipient, _amount);       
            return false;
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) external nonReentrant {
        _updatePool(_pid);
    }

    // Internal method for _updatePool
    function _updatePool(uint256 _pid) internal validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];

        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }

        uint256 lpSupply = pool.totalLp;

        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }

        uint256 multiplier = block.timestamp - pool.lastRewardTimestamp;

        uint256 ASNTReward = ((multiplier * ASNTPerSec) * pool.allocPoint) / totalAllocPoint;

        uint256 total = 1000;
        uint256 lpPercent = total - ASNTSharePercent;

        _checkBeforeMintRewards(ASNTShareAddress, (ASNTReward * ASNTSharePercent) / total );

        //Only update pool if the mint is successful
        if (_checkBeforeMintRewards(address(this), (ASNTReward * lpPercent) / total )) {
            pool.accASNTPerShare += (ASNTReward * ACC_TOKEN_PRECISION * lpPercent) / pool.totalLp / total;
            pool.lastRewardTimestamp = block.timestamp;
        }

        emit UpdatePool(_pid, pool.lastRewardTimestamp, lpSupply, pool.accASNTPerShare);
    }

    // Deposit tokens for ASNT allocation.
    function deposit(uint256 _pid, uint256 _amount, address _referrer) public nonReentrant {
        _deposit(_pid, _amount, _referrer);
    }

    // Deposit tokens for ASNT allocation.
    function _deposit(uint256 _pid, uint256 _amount, address _referrer) internal validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        _updatePool(_pid);

        if (_amount > 0 && address(ASNTReferral) != address(0) && _referrer != BURN_ADDRESS && _referrer != address(0) && _referrer != msg.sender) {
            ASNTReferral.recordReferral(msg.sender, _referrer);
        }

        payOrLockupPendingASNT(_pid);

        if (_amount > 0) {
            uint256 beforeDeposit = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
            uint256 afterDeposit = pool.lpToken.balanceOf(address(this));
            _amount = afterDeposit - beforeDeposit;

            if (pool.depositFeeRate > 0) {
                uint userDepositFeeRate = getUserDepositFee(msg.sender, pool.depositFeeRate);
                uint256 depositFee = (_amount * userDepositFeeRate) / MULTIPLIER;
                _amount = _amount - depositFee;
                pool.lpToken.safeTransfer(feeAddress, depositFee);                
            }

            user.amount += _amount;

            if (address(pool.lpToken) == address(ASNT)) {
                totalASNTInPools += _amount;
            }
            
            pool.totalLp += _amount;
        }
        user.rewardDebt = (user.amount * pool.accASNTPerShare) / ACC_TOKEN_PRECISION;

        for (uint256 rewarderId = 0; rewarderId < pool.rewarders.length; ++rewarderId) {
            pool.rewarders[rewarderId].onASNTReward(_pid, msg.sender, user.amount);
        }

        emit Deposit(msg.sender, _pid, _amount);
    }

    //withdraw tokens
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        //this will make sure that user can only withdraw from his pool
        require(user.amount >= _amount, "withdraw: user amount not enough");

        //cannot withdraw more than pool's balance
        require(pool.totalLp >= _amount, "withdraw: pool total not enough");

        _updatePool(_pid);

        payOrLockupPendingASNT(_pid);

        if (_amount > 0) {
            user.amount -= _amount;
            if (address(pool.lpToken) == address(ASNT)) {
                totalASNTInPools -= _amount;
            }
            pool.totalLp -= _amount;
            pool.lpToken.safeTransfer(msg.sender, _amount);
        }

        user.rewardDebt =
            (user.amount * pool.accASNTPerShare) /
            ACC_TOKEN_PRECISION;

        for (
            uint256 rewarderId = 0;
            rewarderId < pool.rewarders.length;
            ++rewarderId
        ) {
            pool.rewarders[rewarderId].onASNTReward(
                _pid,
                msg.sender,
                user.amount
            );
        }

        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;

        //cannot withdraw more than pool's balance
        require(pool.totalLp >= amount, "emergency withdraw: pool total not enough");

        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        user.noHarvestFeeAfter = 0;   
             
        pool.totalLp -= amount;
        if (address(pool.lpToken) == address(ASNT)) {
            totalASNTInPools -= amount;
        } 
               
        pool.lpToken.safeTransfer(msg.sender, amount);

        for (uint256 rewarderId = 0; rewarderId < pool.rewarders.length; ++rewarderId) {
            pool.rewarders[rewarderId].onASNTReward(_pid, msg.sender, 0);
        }

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Pay or lockup pending ASNT.
    function payOrLockupPendingASNT(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0 && block.timestamp >= startTimestamp) {
            user.nextHarvestUntil = block.timestamp + pool.harvestInterval;
        }
        if (user.noHarvestFeeAfter == 0) {
            user.noHarvestFeeAfter = block.timestamp + pool.harvestFeeInterval;
        }

        uint256 pending = ((user.amount * pool.accASNTPerShare) / ACC_TOKEN_PRECISION) - user.rewardDebt;

        if (canHarvest(_pid, msg.sender)) {
            // if user harvest before the interval, user pay fee on pending reward               
            if (noHarvestFee(_pid, msg.sender)==false && pending > 0) {
                uint256 pendingIncludeRewardLockedUp = pending + user.rewardLockedUp;
                uint256 harvestfeeamount = (pendingIncludeRewardLockedUp * pool.harvestFeeRate) / MULTIPLIER;
                pending = pending - harvestfeeamount;
                // tax on harvest is send to the share address
                safeASNTTransfer(ASNTShareAddress, harvestfeeamount);     
            }
            // reset timer at each harvest
            user.noHarvestFeeAfter = block.timestamp + pool.harvestFeeInterval;                

            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 pendingRewards = pending + user.rewardLockedUp;
                // reset lockup
                totalLockedUpRewards -= user.rewardLockedUp;
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp + pool.harvestInterval;
                // send rewards
                safeASNTTransfer(msg.sender, pendingRewards);
                payReferralCommission(msg.sender, pendingRewards); // extra mint for referral
            }
        } else if (pending > 0) {
            totalLockedUpRewards += pending;
            user.rewardLockedUp += pending;
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    // Safe ASNT transfer function, just in case if rounding error causes pool do not have enough ASNT.
    function safeASNTTransfer(address _to, uint256 _amount) internal {
        if (ASNT.balanceOf(address(this)) > totalASNTInPools) {
            //ASNTBal = total ASNT in ASNTChef - total ASNT in ASNT pools, this will make sure that ASNTMasterchef never transfer rewards from deposited ASNT pools
            uint256 ASNTBal = ASNT.balanceOf(address(this)) - totalASNTInPools;
            if (_amount >= ASNTBal) {
                IERC20(ASNT).safeTransfer(_to, ASNTBal);
            } else if (_amount > 0) {
                IERC20(ASNT).safeTransfer(_to, _amount);
            }
        }
    }

    // Function to harvest many pools in a single transaction
    function harvestMany(uint256[] calldata _pids, address _referrer) public nonReentrant {
        require(_pids.length <= 30, "harvest many: too many pool ids");
        for (uint256 index = 0; index < _pids.length; ++index) {
            _deposit(_pids[index], 0, _referrer);
        }
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(ASNTReferral) != address(0) && referralCommissionRate > 0) {
            address referrer = ASNTReferral.getReferrer(_user);
            uint256 commissionAmount = (_pending * referralCommissionRate) / 10000;
            if (referrer != address(0) && referrer != BURN_ADDRESS && commissionAmount > 0) {
                ASNT.mint(referrer, commissionAmount);
                ASNTReferral.recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }

    //
    // ADMIN
    //

    // Add a new lp to the pool. Can only be called by the owner.
    // Can add multiple pool with same lp token without messing up rewards, because each pool's balance is tracked using its own totalLp
    function add(uint256 _allocPoint, IERC20 _lpToken, uint256 _depositFeeRate, uint256 _harvestInterval, uint256 _harvestFeeInterval, uint256 _harvestFeeRate, IMultipleRewards[] calldata _rewarders) public onlyOwner {
        require(_rewarders.length <= MAXIMUM_REWARDERS, "add: too many rewarders");
        require(_harvestFeeRate <= MAXIMUM_HARVEST_FEE_RATE, "add: harvest fee too high");      
        require(_harvestFeeInterval <= MAXIMUM_HARVESTFEE_INTERVAL, "add: invalid harvest fee interval");
        require(_depositFeeRate <= MAXIMUM_DEPOSIT_FEE_RATE, "add: deposit fee too high");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "add: invalid harvest interval");
        
        for (uint256 rewarderId = 0; rewarderId < _rewarders.length; ++rewarderId) {
            require(Address.isContract(address(_rewarders[rewarderId])),"add: rewarder must be contract");
            (,uint lastRewardTime,,,,) = _rewarders[rewarderId].getPoolInfo(poolInfo.length);
            require(lastRewardTime != 0, "Pool doesn't exist yet in rewarder");
        }

        _massUpdatePools();

        uint256 lastRewardTimestamp = block.timestamp > startTimestamp ? block.timestamp : startTimestamp;

        totalAllocPoint += _allocPoint;

        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardTimestamp: lastRewardTimestamp,
                accASNTPerShare: 0,
                depositFeeRate: _depositFeeRate,
                harvestInterval: _harvestInterval,
            	harvestFeeInterval: _harvestFeeInterval,
            	harvestFeeRate: _harvestFeeRate,                
                totalLp: 0,
                rewarders: _rewarders
            })
        );

        emit Add(poolInfo.length - 1,_allocPoint,_lpToken,_depositFeeRate,_harvestInterval,_harvestFeeInterval,_harvestFeeRate,_rewarders);
    }

    // Update the given pool's ASNT parameters. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeRate, uint256 _harvestInterval, uint256 _harvestFeeInterval, uint256 _harvestFeeRate, IMultipleRewards[] calldata _rewarders) public onlyOwner validatePoolByPid(_pid) {
        require(_rewarders.length <= MAXIMUM_REWARDERS, "set: too many rewarders");
        require(_harvestFeeRate <= MAXIMUM_HARVEST_FEE_RATE, "set: harvest fee too high");      
        require(_harvestFeeInterval <= MAXIMUM_HARVESTFEE_INTERVAL, "set: invalid harvest fee interval");
        require(_depositFeeRate <= MAXIMUM_DEPOSIT_FEE_RATE, "set: deposit fee too high");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "set: invalid harvest interval");

        for (uint256 rewarderId = 0; rewarderId < _rewarders.length; ++rewarderId) {
            require(Address.isContract(address(_rewarders[rewarderId])),"set: rewarder must be contract"
            );
        }

        _massUpdatePools();

        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;

        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeRate = _depositFeeRate;
        poolInfo[_pid].harvestInterval = _harvestInterval;
        poolInfo[_pid].rewarders = _rewarders;
        poolInfo[_pid].harvestFeeInterval = _harvestFeeInterval;
        poolInfo[_pid].harvestFeeRate = _harvestFeeRate;        

        emit Set(_pid, _allocPoint, _depositFeeRate, _harvestInterval, _harvestFeeInterval, _harvestFeeRate, _rewarders);
    }

    // Update pool allocation point
    function updateAllocPoint(uint256 _pid, uint256 _allocPoint) public onlyOwner {
        _massUpdatePools();
        emit AllocPointsUpdated(msg.sender,poolInfo[_pid].allocPoint,_allocPoint);
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Update emission rate
    function updateEmissionRate(uint256 _ASNTPerSec) public onlyOwner {
		require(_ASNTPerSec <= MAX_EMISSION_RATE, "Emission > max emission rate");
        _massUpdatePools();
        emit EmissionRateUpdated(msg.sender, ASNTPerSec, _ASNTPerSec);
        ASNTPerSec = _ASNTPerSec;
    }

    // Set farming start now, can call only if farming not started
    function startFarmingNow() public onlyOwner {
        require(block.timestamp < startTimestamp, "farm already started");
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lastRewardTimestamp = block.timestamp;
        }
        startTimestamp = block.timestamp;
    }

    // Set farming start at fixed time, can call only if farming not started
    function startFarmingAtTime(uint _startTimestamp) public onlyOwner {
        require(block.timestamp < startTimestamp, "farm already started");

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lastRewardTimestamp = _startTimestamp;
        }
        startTimestamp = _startTimestamp;
    }       
	
    // Update the ASNT referral contract address by the owner
    function setASNTReferral(IReferral _ASNTReferral) public onlyOwner {
        ASNTReferral = _ASNTReferral;
        emit ASNTReferralUpdated(msg.sender, _ASNTReferral);
    }

    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate) public onlyOwner {
        // Max referral commission rate: 10%.
        require(_referralCommissionRate <= 1000, "setReferralCommissionRate: invalid referral commission rate basis points");
        emit ReferralRateUpdated(msg.sender, referralCommissionRate, _referralCommissionRate);
        referralCommissionRate = _referralCommissionRate;
    }

    // Update ASNTShare address
    function setASNTShareAddress(address _ASNTShareAddress) public {
        require(msg.sender == ASNTShareAddress, "setASNTShareAddress: FORBIDDEN");
        require(_ASNTShareAddress != address(0), "setASNTShareAddress: ZERO");
        ASNTShareAddress = _ASNTShareAddress;
        emit SetASNTShareAddress(msg.sender, _ASNTShareAddress);
    }

    // Update ASNT Share percentage
    function setASNTSharePercent(uint256 _newASNTSharePercent) public onlyOwner {
        require(_newASNTSharePercent <= MAXIMUM_SHARE_RATE, "invalid percent value");
        emit SetASNTSharePercent(ASNTSharePercent, _newASNTSharePercent);
        ASNTSharePercent = _newASNTSharePercent;
    }

    // Update fee address by the previous fee address
    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    // Update vip contract address
    function setVIP(IAssentVIP _vip) public onlyOwner { //TODO need test
        require (_vip.isVIP(), "Not a vip contract");
        require (_vip.getFarmsDepFeeReduction(address(this)) == 0, "getFarmsDepFeeReduction wrong answer");
        emit VIPUpdated(vip, _vip);
        vip = _vip;
    }

}