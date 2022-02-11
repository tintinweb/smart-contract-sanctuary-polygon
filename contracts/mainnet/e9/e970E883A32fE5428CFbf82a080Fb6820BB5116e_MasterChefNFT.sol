/*
    ,-,--.   ,---.      .-._                           ___    ,---.      .-._         
 ,-.'-  _\.--.'  \    /==/ \  .-._  _,..---._  .-._ .'=.'\ .--.'  \    /==/ \  .-._  
/==/_ ,_.'\==\-/\ \   |==|, \/ /, /==/,   -  \/==/ \|==|  |\==\-/\ \   |==|, \/ /, / 
\==\  \   /==/-|_\ |  |==|-  \|  ||==|   _   _\==|,|  / - |/==/-|_\ |  |==|-  \|  |  
 \==\ -\  \==\,   - \ |==| ,  | -||==|  .=.   |==|  \/  , |\==\,   - \ |==| ,  | -|  
 _\==\ ,\ /==/ -   ,| |==| -   _ ||==|,|   | -|==|- ,   _ |/==/ -   ,| |==| -   _ |  
/==/\/ _ /==/-  /\ - \|==|  /\ , ||==|  '='   /==| _ /\   /==/-  /\ - \|==|  /\ , |  
\==\ - , |==\ _.\=\.-'/==/, | |- ||==|-,   _`//==/  / / , |==\ _.\=\.-'/==/, | |- |  
 `--`---' `--`        `--`./  `--``-.`.____.' `--`./  `--` `--`        `--`./  `--`  
                                                                    by sandman.finance                                     
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "./libs/IFactoryNFT.sol";
import "./libs/ImergeAPI.sol";
import "./SandManToken.sol";
import "./TheEndlessToken.sol";

/*
 * Errors Ref Table
 * E1: !nonzero
 * E2: nonDuplicated: duplicated
 * E3: add: invalid deposit fee basis points
 * E4: add: invalid harvest interval
 * E5: set: invalid deposit fee basis points
 * E6: we dont accept deposits of 0 size
 * E7: withdraw: not good
 * E8: safeTokenTransfer: transfer failed
 * E9: cannot change start block if sale has already commenced
 * E10: cannot set start block in the past
 * E11: user already added nft
 * E12: User is not owner of nft sent
 * E13: user no has nft
 * E14: we dont accept deposits of 0 size
 */

contract MasterChefNFT is Ownable, ReentrancyGuard, ERC721Holder {
    using SafeERC20 for IERC20;

    // Info for user
    struct UserInfo {
        uint256 amount;
        uint256 sandManRewardDebt;
        uint256 theEndlessRewardDebt;
        uint256 usdRewardDebt;
        uint256 sandManRewardLockup;
        uint256 theEndlessRewardLockup;
        uint256 usdRewardLockup;
        uint256 nextHarvestUntil;
        uint256 nftID;
        uint256 powerStaking;
        uint256 experience;
        bool hasNFT;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardTime;
        uint256 accSandManPerShare;
        uint256 accTheEndlessPerShare;
        uint256 totalLocked;
        uint256 harvestInterval;
        uint256 depositFeeBP;
        uint256 tokenType;
    }

    uint256 public constant sandManMaximumSupply = 500 * (10 ** 3) * (10 ** 18); // 500,000 sandManToken
    uint256 constant MAX_EMISSION_RATE = 10 * (10 ** 18); // 10
    uint256 constant MAXIMUM_HARVEST_INTERVAL = 4 hours;
    
    // The SANDMAN TOKEN!
    SandManToken public immutable sandManToken;
    // SandMan Treasury
    TreasuryDAO public immutable treasuryDAO;
    // The THE ENDLESS TOKEN!
    TheEndlessToken public immutable theEndlessToken;    
    // Interface NFT FACTORY
    IFactoryNFT public immutable iFactoryNFT;
    // Interface Merge API
    ImergeAPI immutable iMergeAPI;


    // USD
    uint256 public accDepositUSDRewardPerShare;
    // SANDMAN tokens created per second.
    uint256 public sandManPerSecond;
    // TheEndless tokens created per second.
    uint256 public theEndlessPerSecond;
    // Experience rate created per second.
    uint256 public experienceRate;
    // Deposit Fee address.
    address public feeAddress;
    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    
    // The Endless PID.
    uint256 public theEndlessPID;
    
    // The block number when SANDMAN mining starts.
    uint256 public startTime;

    // The block number when SANDMAN mining ends.
    uint256 public emmissionEndTime = type(uint256).max;

    // Used NFT.
    mapping(uint256 => bool) nftIDs;

    // Whitelist for avoid harvest lockup for some operative contracts like vaults.
    mapping(address => bool) public harvestLockupWhiteList;

    // Pool existence
    mapping(IERC20 => bool) public poolExistence;

    // The harvest interval.
    uint256 harvestInterval;

    // Total token minted for farming.
    uint256 totalSupplyFarmed;

    // Total usd lockup
    uint256 public totalUsdLockup;

    // Events definitions
    event AddPool(uint256 indexed pid, uint256 tokenType, uint256 allocPoint, address lpToken, uint256 depositFeeBP);
    event SetPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint256 depositFeeBP);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawNFT(address indexed user, uint256 indexed pid, uint256 nftID);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetEmissionRate(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetStartTime(uint256 indexed newStartTime);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event WithDrawNFTByIndex(uint256 indexed _nftID, address indexed _userAddress);

    constructor(
        TreasuryDAO _treasuryDAO,
        SandManToken _sandManToken,
        TheEndlessToken _theEndlessToken,
        IFactoryNFT _iFactoryNFT,
        ImergeAPI _iMergeAPI,
        address _feeAddress,
        uint256 _sandManPerSecond,
        uint256 _theEndlessPerSecond,
        uint256 _experienceRate,
        uint256 _startTime
    ) {

        treasuryDAO = _treasuryDAO;
        sandManToken = _sandManToken;
        theEndlessToken = _theEndlessToken;
        iFactoryNFT = _iFactoryNFT;
        iMergeAPI = _iMergeAPI;
        feeAddress = _feeAddress;
        sandManPerSecond = _sandManPerSecond;
        theEndlessPerSecond = _theEndlessPerSecond;
        experienceRate = _experienceRate;
        startTime = _startTime;
    }

    ///@dev MODIFIERS
    modifier nonDuplicated(IERC20 _lpToken) {
        require(!poolExistence[_lpToken], "E2");
        _;
    }
    ///

    ///@dev INTERNALS
    // Pay pending USD from the TheEndless staking reward scheme.
    function _payPendingUSDReward() internal {
        UserInfo storage user = userInfo[theEndlessPID][msg.sender];

        uint256 usdPending = (((user.amount * accDepositUSDRewardPerShare) / 1e18) - user.usdRewardDebt) + user.usdRewardLockup;

        if (usdPending > 0) {
            treasuryDAO.transferUSDToOwner(msg.sender, usdPending);
            user.usdRewardLockup = 0;
            totalUsdLockup = totalUsdLockup - usdPending;
        }
    }
    // Safe token transfer function, just in case if rounding error causes pool to not have enough SANDMANs.
    function _safeTokenTransfer(address token, address _to, uint256 _amount) internal {
        uint256 tokenBal = IERC20(token).balanceOf(address(this));
        if (_amount > tokenBal) {
            IERC20(token).safeTransfer(_to, tokenBal);
        } else {
            IERC20(token).safeTransfer(_to, _amount);
        }
    }

    // Update lastRewardTime variables for all pools.
    function _massUpdateLastRewardTimePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 _pid = 0; _pid < length; ++_pid) {
            poolInfo[_pid].lastRewardTime = startTime;
        }
    }

    // Pay or Lockup pending sandManToken and the endless token.
    function _payPendingTheEndlessSandMan(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0) {
            _updateHarvestLockup(_pid, msg.sender);
        }
        uint256 pendingSandManToken = ((user.amount * pool.accSandManPerShare) / 1e18) - user.sandManRewardDebt;
        uint256 pendingTheEndlessToken = ((user.amount * pool.accTheEndlessPerShare) / 1e18) - user.theEndlessRewardDebt;

        if (canHarvest(_pid, msg.sender)) {
            if (pendingSandManToken > 0 || user.sandManRewardLockup > 0) {
                uint256 totalRewards = pendingSandManToken + user.sandManRewardLockup;
                // reset lockup
                user.sandManRewardLockup = 0;
                _updateHarvestLockup(_pid, msg.sender);

                // send rewards
                _safeTokenTransfer(address(sandManToken), msg.sender, totalRewards);

                if (user.hasNFT) {
                    _payNFTBoost(_pid, msg.sender, totalRewards);
                    user.experience = user.experience + ((totalRewards * experienceRate) / 10000);
                    iFactoryNFT.setExperience(user.nftID, user.experience);
                }
            }

            if (pendingTheEndlessToken > 0 || user.theEndlessRewardLockup > 0) {
                user.theEndlessRewardLockup = 0;
                _safeTokenTransfer(address(theEndlessToken), msg.sender, pendingTheEndlessToken);
            }

            if (_pid == theEndlessPID) {
                _payPendingUSDReward();
            }

        } else if (pendingSandManToken > 0 || pendingTheEndlessToken > 0) {
            user.sandManRewardLockup = user.sandManRewardLockup + pendingSandManToken;
            user.theEndlessRewardLockup = user.theEndlessRewardLockup + pendingTheEndlessToken;

            if (_pid == theEndlessPID) {
                uint256 pendingUSDReward = ((user.amount * accDepositUSDRewardPerShare) / 1e18) - user.usdRewardDebt;
                if (pendingUSDReward > 0){
                    user.usdRewardLockup = user.usdRewardLockup + pendingUSDReward;
                    totalUsdLockup = totalUsdLockup + pendingUSDReward;
                }
                    
            }
            
        }

        emit RewardLockedUp(msg.sender, _pid, pendingSandManToken);
    }

    //Get PowerStaking from NFT Factory
    function _getNFTPowerStaking(uint256 _nftID) internal view returns (uint256) {
        uint256 strength;
        uint256 agility;
        uint256 endurance;
        uint256 intelligence;
        uint256 wisdom;
        uint256 magic;

        (
            strength,
            agility,
            endurance,
            intelligence,
            magic,
            wisdom
        ) = iMergeAPI.getSkillCard(_nftID); // support for merged cards

        if (strength == 0 && agility == 0 ) {
            (
                strength,
                agility,
                endurance,
                intelligence,
                wisdom,
                magic
            ) = iFactoryNFT.getCharacterStats(_nftID);
        }

        return (strength + agility + endurance + intelligence + magic + wisdom);
    }

    // Get NFT EXPERIENCE
    function _getNFTExperience(uint256 _nftID) internal returns (uint256) {
        (,uint256 experience,) = iFactoryNFT.getCharacterOverView(_nftID);

        return experience;
    }

    // Update Harvest Lockup
    function _updateHarvestLockup(uint256 _pid, address _userAddress) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_userAddress];

        uint256 newHarvestInverval = harvestLockupWhiteList[_userAddress] ? 0 : pool.harvestInterval;

        if (user.hasNFT && newHarvestInverval > 0) {
            uint256 quarterInterval = (newHarvestInverval * 2500) / 10000;
            uint256 extraBoosted = 0;
            if(user.experience > 100){
                extraBoosted = (user.experience / 10) / 1e18; 
            }
            if (extraBoosted > quarterInterval) {
                extraBoosted = quarterInterval;
            }
            newHarvestInverval = newHarvestInverval - quarterInterval - extraBoosted;
        }

        user.nextHarvestUntil = block.timestamp + newHarvestInverval;
    }

    // Pay NFT Boost
    function _payNFTBoost(uint256 _pid, address _userAddress, uint256 _pending) internal {
        UserInfo storage user = userInfo[_pid][_userAddress];

        uint256 extraBoosted = 0;
        if(user.experience > 100){
            extraBoosted = (user.experience / 100) / 1e18; 
        }


        uint256 rewardBoosted = (_pending * (user.powerStaking + extraBoosted)) / 10000;
        if (rewardBoosted > 0) {
            sandManToken.mint(_userAddress, rewardBoosted);
        }
    }
    ///

    ///@dev PUBLIC
    
    // Check if user can harvest.
    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];

        return block.timestamp >= user.nextHarvestUntil;
    }

    // Return reward multiplier over the given _from to _to time.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        // As we set the multiplier to 0 here after emmissionEndTime
        // deposits aren't blocked after farming ends.
        if (_from > emmissionEndTime) {
            return 0;
        }
        if (_to > emmissionEndTime) {
            return emmissionEndTime - _from;
        } else {
            return _to - _from;
        }
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
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }

        if (pool.totalLocked == 0 || pool.allocPoint == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }

        // TheEndless pool is always pool 0.
        if (poolInfo[theEndlessPID].totalLocked > 0) {
            uint256 usdRelease = treasuryDAO.getUSDDrip(totalUsdLockup);

            accDepositUSDRewardPerShare = accDepositUSDRewardPerShare + ((usdRelease * 1e18) / poolInfo[theEndlessPID].totalLocked);
        }

        uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint256 sandManReward = (multiplier * sandManPerSecond * pool.allocPoint) / totalAllocPoint;
        uint256 theEndlessReward;

        if (_pid == theEndlessPID) { 
            theEndlessReward = (multiplier * theEndlessPerSecond * pool.allocPoint) / totalAllocPoint;
        }
            

        // This shouldn't happen, but just in case we stop rewards.
        if (totalSupplyFarmed > sandManMaximumSupply) {
            sandManReward = 0;
        } else if ((totalSupplyFarmed + sandManReward) > sandManMaximumSupply) {
            sandManReward = sandManMaximumSupply - totalSupplyFarmed;
        }

        if (sandManReward > 0) {
            sandManToken.mint(address(this), sandManReward);
            totalSupplyFarmed = totalSupplyFarmed + sandManReward;
        }

        if (theEndlessReward > 0) {
            theEndlessToken.mint(address(this), theEndlessReward);
        }

        // The first time we reach SandMan max supply we solidify the end of farming.
        if (totalSupplyFarmed >= sandManMaximumSupply && emmissionEndTime == type(uint256).max) {
            emmissionEndTime = block.timestamp;
        }

        pool.accSandManPerShare = pool.accSandManPerShare + ((sandManReward * 1e18) / pool.totalLocked);
        pool.accTheEndlessPerShare = pool.accTheEndlessPerShare + ((theEndlessReward * 1e18) / pool.totalLocked);
        pool.lastRewardTime = block.timestamp;
    }
    ///

    ///@dev EXTERNALS
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // View function to see pending USDs on frontend.
    function pendingUSD(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[0][_user];

        return (((user.amount * accDepositUSDRewardPerShare) / (1e18)) - user.usdRewardDebt) + user.usdRewardLockup;
    }


    // View function to see pending SANDMANs on frontend.
    function pendingSandMan(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSandManPerShare = pool.accSandManPerShare;
        if (block.timestamp > pool.lastRewardTime && pool.totalLocked != 0 && totalAllocPoint > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            uint256 sandManReward = (multiplier * sandManPerSecond * pool.allocPoint) / totalAllocPoint;
            accSandManPerShare = accSandManPerShare + ((sandManReward * 1e18) / pool.totalLocked);
        }
        uint256 pending = ((user.amount * accSandManPerShare) /  1e18) - user.sandManRewardDebt;

        return pending + user.sandManRewardLockup;
    }

    // View function to see pending Endless on frontend.
    function pendingTheEndless(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTheEndlessPerShare = pool.accTheEndlessPerShare;
        if (block.timestamp > pool.lastRewardTime && pool.totalLocked != 0 && totalAllocPoint > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            uint256 theEndlessReward = (multiplier * theEndlessPerSecond * pool.allocPoint) / totalAllocPoint;
            accTheEndlessPerShare = accTheEndlessPerShare + ((theEndlessReward * 1e18) / pool.totalLocked);
        }
        uint256 pending = ((user.amount * accTheEndlessPerShare) /  1e18) - user.theEndlessRewardDebt;

        return pending + user.theEndlessRewardLockup;
    }
    

    // Deposit LP tokens to MasterChef for SANDMAN allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        _payPendingTheEndlessSandMan(_pid);
        
        if (_amount > 0) {
            uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            _amount = pool.lpToken.balanceOf(address(this)) - balanceBefore;
            require(_amount > 0, "E6");

            if (pool.depositFeeBP > 0) {
                uint256 totalDepositFee = (_amount * pool.depositFeeBP) / 10000;
                uint256 devDepositFee = (totalDepositFee * 7500) / 10000;
                uint256 treasuryDepositFee = (totalDepositFee * 2500) / 10000;
                 _amount = _amount - totalDepositFee;
                // send 3% to sandman finance
                pool.lpToken.safeTransfer(feeAddress, devDepositFee);
                // send 1% to treasury
                pool.lpToken.safeTransfer(address(treasuryDAO), treasuryDepositFee);
                treasuryDAO.convertDepositFeesToUSD(address(pool.lpToken), pool.tokenType, treasuryDepositFee);
                
                user.amount = user.amount + _amount;
                pool.totalLocked = pool.totalLocked + _amount;
            } else {
                user.amount = user.amount + _amount;
                pool.totalLocked = pool.totalLocked + _amount;
            }
        }
        user.sandManRewardDebt = (user.amount * pool.accSandManPerShare) / 1e18;
        user.theEndlessRewardDebt = (user.amount * pool.accTheEndlessPerShare) / 1e18;

        if (_pid == theEndlessPID)
            user.usdRewardDebt = ((user.amount * accDepositUSDRewardPerShare) / 1e18);

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "E7");

        updatePool(_pid);
        _payPendingTheEndlessSandMan(_pid);
        
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.totalLocked = pool.totalLocked - _amount;
        }

        user.sandManRewardDebt = (user.amount * pool.accSandManPerShare) / 1e18;
        user.theEndlessRewardDebt = (user.amount * pool.accTheEndlessPerShare) / 1e18;

        if (_pid == 0)
            user.usdRewardDebt = ((user.amount * accDepositUSDRewardPerShare) / 1e18);


        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.sandManRewardDebt = 0;
        user.sandManRewardLockup = 0;

        user.theEndlessRewardDebt = 0;
        user.theEndlessRewardLockup = 0;
        
        user.usdRewardDebt = 0;
        user.usdRewardLockup = 0;

        user.nextHarvestUntil = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        // In the case of an accounting error, we choose to let the user emergency withdraw anyway
        if (pool.totalLocked >=  amount) {
            pool.totalLocked = pool.totalLocked - amount;
        } else {
            pool.totalLocked = 0;
        }

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Add NFT to Pool
    function addNFT(uint256 _pid, uint256 _nftID) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(!user.hasNFT, "E11");
        require(iFactoryNFT.ownerOf(_nftID) == msg.sender, "E12");

        updatePool(_pid);
        _payPendingTheEndlessSandMan(_pid);

        iFactoryNFT.safeTransferFrom(msg.sender, address(this), _nftID);

        user.hasNFT = true;
        nftIDs[_nftID] = true;
        user.nftID = _nftID;
        user.powerStaking = _getNFTPowerStaking(user.nftID);
        user.experience = _getNFTExperience(user.nftID);

        _updateHarvestLockup(_pid, msg.sender);

        user.sandManRewardDebt = (user.amount * pool.accSandManPerShare) / 1e18;
    }

    // WithDraw NFT from Pool
    function withdrawNFT(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.hasNFT, "E13");

        updatePool(_pid);

        _payPendingTheEndlessSandMan(_pid);
        
        if (user.sandManRewardLockup > 0) {
            _payNFTBoost(_pid, msg.sender, user.sandManRewardLockup);
            user.experience = user.experience + ((user.sandManRewardLockup * experienceRate) / 10000);
            iFactoryNFT.setExperience(user.nftID, user.experience);
        }

        iFactoryNFT.safeTransferFrom(address(this), msg.sender, user.nftID); 

        nftIDs[user.nftID] = false;

        user.hasNFT = false;
        user.nftID = 0;
        user.powerStaking = 0;
        user.experience = 0;

        _updateHarvestLockup(_pid, msg.sender);

        user.sandManRewardDebt = (user.amount * pool.accSandManPerShare) / 1e18;

        emit WithdrawNFT(msg.sender, _pid, user.nftID);
    }

    ///@dev ONLYONWER METHODS
    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _tokenType,
                 uint256 _allocPoint,
                 IERC20 _lpToken,
                 uint256 _depositFeeBP, 
                 uint256 _harvestInterval, 
                 bool _withUpdate) external onlyOwner nonDuplicated(_lpToken) {
        // Make sure the provided token is ERC20
        _lpToken.balanceOf(address(this));

        require(_depositFeeBP <= 401, "E3");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "E4");

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolExistence[_lpToken] = true;

        poolInfo.push(PoolInfo({
          tokenType: _tokenType,
          lpToken : _lpToken,
          allocPoint : _allocPoint,
          lastRewardTime : lastRewardTime,
          depositFeeBP : _depositFeeBP,
          totalLocked: 0,
          accSandManPerShare: 0,
          accTheEndlessPerShare: 0,
          harvestInterval: _harvestInterval
        }));

        emit AddPool(poolInfo.length - 1, _tokenType, _allocPoint, address(_lpToken), _depositFeeBP);
    }

    // Update the given pool's SANDMAN allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, 
                 uint256 _tokenType,
                 uint256 _allocPoint, 
                 uint256 _depositFeeBP, 
                 uint256 _harvestInterval, 
                 bool _withUpdate) external onlyOwner {
        require(_depositFeeBP <= 401, "E5");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].tokenType = _tokenType;
        poolInfo[_pid].harvestInterval = _harvestInterval;

        emit SetPool(_pid, address(poolInfo[_pid].lpToken), _allocPoint, _depositFeeBP);
    }

    // Set fee address. OnlyOwner
    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0), "E1");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    // Set start time. Only can run before start by Owner.
    function setStartTime(uint256 _newStartTime) external onlyOwner {
        require(block.timestamp < startTime, "E9");
        require(block.timestamp < _newStartTime, "E10");

        startTime = _newStartTime;
        _massUpdateLastRewardTimePools();

        emit SetStartTime(startTime);
    }

    // Set emission rate. OnlyOwner.
    function setEmissionRate(uint256 _sandManPerSecond) external onlyOwner {
        require(_sandManPerSecond > 0);
        require(_sandManPerSecond < MAX_EMISSION_RATE);

        massUpdatePools();
        sandManPerSecond = _sandManPerSecond;

        emit SetEmissionRate(msg.sender, sandManPerSecond, _sandManPerSecond);
    }

    // Set experience rate. onlyOwner.
    function setExperienceRate(uint256 _experienceRate) external onlyOwner {
        require(_experienceRate >= 0);

        experienceRate = _experienceRate;
    }

    // WithDraw NFT from Pool. OnlyOwner. Only for emergency.
    function withDrawNFTByIndex(uint256 _nftID, address _userAddress) external onlyOwner {
        require(iFactoryNFT.ownerOf(_nftID) == address(this));

        iFactoryNFT.safeTransferFrom(address(this), _userAddress, _nftID);

        emit WithDrawNFTByIndex(_nftID, _userAddress);
    }

    // Add address to whitelist for havest lockup.
    function addHarvestLockupWhiteList(address[] memory _recipients) external onlyOwner {
        for(uint i = 0; i < _recipients.length; i++) {
            harvestLockupWhiteList[_recipients[i]] = true;
        }
    }

    // Remove address from whitelist for havest lockup
    function removeHarvestLockupWhiteList(address[] memory _recipients) external onlyOwner {
        for(uint i = 0; i < _recipients.length; i++) {
            harvestLockupWhiteList[_recipients[i]] = false;
        }
    }
    ///
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

/*
    ,-,--.   ,---.      .-._                           ___    ,---.      .-._         
 ,-.'-  _\.--.'  \    /==/ \  .-._  _,..---._  .-._ .'=.'\ .--.'  \    /==/ \  .-._  
/==/_ ,_.'\==\-/\ \   |==|, \/ /, /==/,   -  \/==/ \|==|  |\==\-/\ \   |==|, \/ /, / 
\==\  \   /==/-|_\ |  |==|-  \|  ||==|   _   _\==|,|  / - |/==/-|_\ |  |==|-  \|  |  
 \==\ -\  \==\,   - \ |==| ,  | -||==|  .=.   |==|  \/  , |\==\,   - \ |==| ,  | -|  
 _\==\ ,\ /==/ -   ,| |==| -   _ ||==|,|   | -|==|- ,   _ |/==/ -   ,| |==| -   _ |  
/==/\/ _ /==/-  /\ - \|==|  /\ , ||==|  '='   /==| _ /\   /==/-  /\ - \|==|  /\ , |  
\==\ - , |==\ _.\=\.-'/==/, | |- ||==|-,   _`//==/  / / , |==\ _.\=\.-'/==/, | |- |  
 `--`---' `--`        `--`./  `--``-.`.____.' `--`./  `--` `--`        `--`./  `--`  
                                                                    by sandman.finance                                     
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface  IFactoryNFT {
    function setExperience(uint256 tokenId, uint256 _newExperience) external;
    function getCharacterStats(uint256 tokenId) external view returns (uint256,uint256,uint256,uint256,uint256,uint256);
    function getCharacterOverView(uint256 tokenId) external returns (string memory,uint256,uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

/*
    ,-,--.   ,---.      .-._                           ___    ,---.      .-._         
 ,-.'-  _\.--.'  \    /==/ \  .-._  _,..---._  .-._ .'=.'\ .--.'  \    /==/ \  .-._  
/==/_ ,_.'\==\-/\ \   |==|, \/ /, /==/,   -  \/==/ \|==|  |\==\-/\ \   |==|, \/ /, / 
\==\  \   /==/-|_\ |  |==|-  \|  ||==|   _   _\==|,|  / - |/==/-|_\ |  |==|-  \|  |  
 \==\ -\  \==\,   - \ |==| ,  | -||==|  .=.   |==|  \/  , |\==\,   - \ |==| ,  | -|  
 _\==\ ,\ /==/ -   ,| |==| -   _ ||==|,|   | -|==|- ,   _ |/==/ -   ,| |==| -   _ |  
/==/\/ _ /==/-  /\ - \|==|  /\ , ||==|  '='   /==| _ /\   /==/-  /\ - \|==|  /\ , |  
\==\ - , |==\ _.\=\.-'/==/, | |- ||==|-,   _`//==/  / / , |==\ _.\=\.-'/==/, | |- |  
 `--`---' `--`        `--`./  `--``-.`.____.' `--`./  `--` `--`        `--`./  `--`  
                                                                    by sandman.finance                                     
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface  ImergeAPI {
    function getSkillCard(uint256 _nftID)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );
}

/*
    ,-,--.   ,---.      .-._                           ___    ,---.      .-._         
 ,-.'-  _\.--.'  \    /==/ \  .-._  _,..---._  .-._ .'=.'\ .--.'  \    /==/ \  .-._  
/==/_ ,_.'\==\-/\ \   |==|, \/ /, /==/,   -  \/==/ \|==|  |\==\-/\ \   |==|, \/ /, / 
\==\  \   /==/-|_\ |  |==|-  \|  ||==|   _   _\==|,|  / - |/==/-|_\ |  |==|-  \|  |  
 \==\ -\  \==\,   - \ |==| ,  | -||==|  .=.   |==|  \/  , |\==\,   - \ |==| ,  | -|  
 _\==\ ,\ /==/ -   ,| |==| -   _ ||==|,|   | -|==|- ,   _ |/==/ -   ,| |==| -   _ |  
/==/\/ _ /==/-  /\ - \|==|  /\ , ||==|  '='   /==| _ /\   /==/-  /\ - \|==|  /\ , |  
\==\ - , |==\ _.\=\.-'/==/, | |- ||==|-,   _`//==/  / / , |==\ _.\=\.-'/==/, | |- |  
 `--`---' `--`        `--`./  `--``-.`.____.' `--`./  `--` `--`        `--`./  `--`  
                                                                    by sandman.finance                                     
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./libs/IWETH.sol";
import "./TreasuryDAO.sol";

/*
  TABLE ERROR REFERENCE:
  ERR1: The sender is on the blacklist. Please contact to support.
  ERR2: The recipient is on the blacklist. Please contact to support.
  ERR3: User cannot send more than allowed.
  ERR4: User is not operator.
  ERR5: User is excluded from antibot system.
  ERR6: Bot address is already on the blacklist.
  ERR7: The expiration time has to be greater than 0.
  ERR8: Bot address is not found on the blacklist.
  ERR9: Address cant be 0.
*/

// SandManToken
contract SandManToken is ERC20, Ownable {

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event TransferTaxRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event HoldingAmountRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event AntiBotWorkingStatus(address indexed operator, bool previousStatus, bool newStatus);
    event AddBotAddress(address indexed botAddress);
    event RemoveBotAddress(address indexed botAddress);
    event ExcludedOperatorsUpdated(address indexed operatorAddress, bool previousStatus, bool newStatus);
    event ExcludedHoldersUpdated(address indexed holderAddress, bool previousStatus, bool newStatus);
    

    using SafeMath for uint256;

    ///@dev Max transfer amount rate. (default is 3% of total supply)
    uint16 public maxUserTransferAmountRate = 300;
    
    ///@dev Max holding rate. (default is 9% of total supply)
    uint16 public maxUserHoldAmountRate = 900;

    ///@dev Length of blacklist addressess
    uint256 public blacklistLength;
 
    ///@dev Enable|Disable antiBot
    bool public antiBotWorking;
    
    ///@dev Exclude operators from antiBot system
    mapping(address => bool) private _excludedOperators;

    ///@dev Exclude holders from antiBot system
    mapping(address => bool) private _excludedHoldersFromAntiBot;

    ///@dev mapping store blacklist. address=>ExpirationTime 
    mapping(address => uint256) private _blacklist;
    
    //transfer fee code
    //
    //
    //
    // Transfer tax rate in basis points. (default 6.66%)
    uint16 public transferTaxRate = 666;
    // Extra transfer tax rate in basis points. (default 10.00%)
    uint16 public extraTransferTaxRate = 1000;
    // Burn rate % of transfer tax. (default 54.95% x 6.66% = 3.660336% of total amount).
    uint32 public constant burnRate = 549549549;
    // Max transfer tax rate: 20.00%.
    uint16 public constant MAXIMUM_TRANSFER_TAX_RATE = 2000;

    // Automatic swap and liquify enabled
    bool public swapAndLiquifyEnabled = true;

    // Min amount to liquify. (default 40 SANDMANs)
    uint256 public constant minSandManAmountToLiquify = 40 * (10 ** 18);
    // Min amount to liquify. (default 100 MATIC)
    uint256 public constant minMaticAmountToLiquify = 100 *  (10 ** 18);

    IUniswapV2Router02 public sandManSwapRouter;
    // The trading pair
    address public sandManSwapPair;
    // In swap and liquify
    bool private _inSwapAndLiquify;

    // SandMan Treasury
    TreasuryDAO public treasuryDAO;
    // The Endless Token
    address public TheEndless;

    mapping(address => bool) public extraFeeAddresses;

    event TransferFeeChanged(uint256 txnFee, uint256 extraTxnFee);
    event SetSandManRouter(address sandManSwapRouter, address sandManSwapPair);
    //
    //
    //
    ////////


    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    // operator role
    address internal _operator;

    // MODIFIERS
    modifier antiBot(address _sender, address _recipient, uint256 _amount) { 
        //check blacklist
        require(!_blacklistCheck(_sender), "ERR1");
        require(!_blacklistCheck(_recipient), "ERR2");

        // This code will be disabled after launch and before farming
        if (antiBotWorking){
            // check  if sender|recipient has a tx amount is within the allowed limits
            if (_isNotOperatorExcluded(_sender)){
                if(_isNotOperatorExcluded(_recipient))
                    require(_amount <= _maxUserTransferAmount(), "ERR3");
            }
        }
        _;
    }

    modifier onlyOperator() {
        require(_operator == _msgSender(), "ERR4");
        _;
    }

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    modifier transferTaxFree {
        uint16 _transferTaxRate = transferTaxRate;
        uint16 _extraTransferTaxRate = extraTransferTaxRate;
        transferTaxRate = 0;
        extraTransferTaxRate = 0;
        _;
        transferTaxRate = _transferTaxRate;
        extraTransferTaxRate = _extraTransferTaxRate;
    }
    
    constructor(TreasuryDAO _treasuryDAO) 
        ERC20('SANDMAN V2', 'SANDMAN')
    {
      // Exclude operator addresses, lps, etc from antibot system
        _excludedOperators[msg.sender] = true;
        _excludedOperators[address(0)] = true;
        _excludedOperators[address(this)] = true;
        _excludedOperators[BURN_ADDRESS] = true;

        treasuryDAO = _treasuryDAO;
        _operator = _msgSender();
    }
    

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function burn(uint256 _amount) external onlyOwner {
        _burn(msg.sender, _amount);
    }
    
    //INTERNALS
    /// @dev overrides transfer function to meet tokenomics of SANDMAN
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiBot(sender, recipient, amount) {
        // Autodetect is sender is a BOT
        // This code will be disabled after launch and before farming
        if (antiBotWorking){
            // check  if sender|recipient has a tx amount is within the allowed limits
            if (_isNotHolderExcluded(sender)){
                if(_isNotOperatorExcluded(sender)){
                    if (balanceOf(sender) > _maxUserHoldAmount()) {
                        _addBotAddressToBlackList(sender, type(uint256).max);
                        return;
                    }
                }
            }
        }
        //transfer fee
        bool toFromtreasuryDAO = (sender == address(treasuryDAO) || recipient == address(treasuryDAO));
        // swap and liquify
        if (
            swapAndLiquifyEnabled == true
            && _inSwapAndLiquify == false
            && address(sandManSwapRouter) != address(0)
            && !toFromtreasuryDAO
            && _isNotOperatorExcluded(sender)
            && sender != sandManSwapPair
            && sender != owner()
        ) {
            swapAndLiquify();
        }

        if (toFromtreasuryDAO ||
            recipient == BURN_ADDRESS ||
            (transferTaxRate == 0 && extraTransferTaxRate == 0) ||
            _excludedOperators[sender] || _excludedOperators[recipient]) {
            super._transfer(sender, recipient, amount);
        } else {
            // default tax is 6.66% of every transfer, but extra 2% for dumping tax
            uint256 taxAmount = (amount * (transferTaxRate +
                ((extraFeeAddresses[sender]) ? extraTransferTaxRate : 0))) / 10000;

            uint256 burnAmount = (taxAmount * burnRate) / 1000000000;
            uint256 liquidityAmount = taxAmount - burnAmount;

            // default 93.34% of transfer sent to recipient
            uint256 sendAmount = amount - taxAmount;

            require(amount == sendAmount + taxAmount &&
                        taxAmount == burnAmount + liquidityAmount, "sum error");

            super._transfer(sender, BURN_ADDRESS, burnAmount);
            super._transfer(sender, address(treasuryDAO), liquidityAmount);
            super._transfer(sender, recipient, sendAmount);
            amount = sendAmount;
        }
    }

    /// @dev Swap and liquify
    function swapAndLiquify() private lockTheSwap transferTaxFree {
        uint256 contractTokenBalance = ERC20(address(this)).balanceOf(address(treasuryDAO));

        uint256 WETHbalance = IERC20(sandManSwapRouter.WETH()).balanceOf(address(treasuryDAO));

        // IWETH(sandManSwapRouter.WETH()).withdraw(WETHbalance);

        // if (WETHbalance >= minMaticAmountToLiquify || contractTokenBalance >= minSandManAmountToLiquify) {
            treasuryDAO.autoLiquidity();
        // }
    }

    /// @dev internal function to add address to blacklist.
    function _addBotAddressToBlackList(address _botAddress, uint256 _expirationTime) internal {
        require(_isNotHolderExcluded(_botAddress), "ERR5");
        require(_isNotOperatorExcluded(_botAddress), "ERR5");
        require(_blacklist[_botAddress] == 0, "ERR6");
        require(_expirationTime > 0, "ERR7");

        _blacklist[_botAddress] = _expirationTime;
        blacklistLength = blacklistLength.add(1);

        emit AddBotAddress(_botAddress);
    }
    
    ///@dev internal function to remove address from blacklist.
    function _removeBotAddressToBlackList(address _botAddress) internal {
        require(_blacklist[_botAddress] > 0, "ERR8");

        delete _blacklist[_botAddress];
        blacklistLength = blacklistLength.sub(1);

        emit RemoveBotAddress(_botAddress);
    }

    ///@dev Check if the address is excluded from antibot system.
    function _isNotHolderExcluded(address _userAddress) internal view returns(bool) {
        return(!_excludedHoldersFromAntiBot[_userAddress]);
    }

    ///@dev Check if the address is excluded from antibot system.
    function _isNotOperatorExcluded(address _userAddress) internal view returns(bool) {
        return(!_excludedOperators[_userAddress]);
    }

    ///@dev Max user transfer allowed
    function _maxUserTransferAmount() internal view returns (uint256) {
        return totalSupply().mul(maxUserTransferAmountRate).div(10000);
    }

    ///@dev Max user Holding allowed
    function _maxUserHoldAmount() internal view returns (uint256) {
        return totalSupply().mul(maxUserHoldAmountRate).div(10000);
    }

    ///@dev check if the address is in the blacklist or expired
    function _blacklistCheck(address _botAddress) internal view returns(bool) {
        if(_blacklist[_botAddress] > 0)
            return _blacklist[_botAddress] > block.timestamp;
        else 
            return false;
    }

    // PUBLICS
 
    ///@dev Max user transfer allowed
    function maxUserTransferAmount() external view returns (uint256) {
        return _maxUserTransferAmount();
    }

    ///@dev Max user Holding allowed
    function maxUserHoldAmount() external view returns (uint256) {
        return _maxUserHoldAmount();
    }

     ///@dev check if the address is in the blacklist or expired
    function blacklistCheck(address _botAddress) external view returns(bool) {
        return _blacklistCheck(_botAddress);     
    }
    
    ///@dev check if the address is in the blacklist or not
    function blacklistCheckExpirationTime(address _botAddress) external view returns(uint256){
        return _blacklist[_botAddress];
    }


    // EXTERNALS

    ///@dev Update operator address status
    function updateOperatorsFromAntiBot(address _operatorAddress, bool _status) external onlyOwner {
        require(_operatorAddress != address(0), "ERR9");

        emit ExcludedOperatorsUpdated(_operatorAddress, _excludedOperators[_operatorAddress], _status);

        _excludedOperators[_operatorAddress] = _status;
    }

    ///@dev Update operator address status
    function updateHoldersFromAntiBot(address _holderAddress, bool _status) external onlyOwner {
        require(_holderAddress != address(0), "ERR9");

        emit ExcludedHoldersUpdated(_holderAddress, _excludedHoldersFromAntiBot[_holderAddress], _status);

        _excludedHoldersFromAntiBot[_holderAddress] = _status;
    }


    ///@dev Update operator address
    function transferOperator(address newOperator) external onlyOperator {
        require(newOperator != address(0), "ERR9");
        
        emit OperatorTransferred(_operator, newOperator);

        _operator = newOperator;
    }

    function operator() external view returns (address) {
        return _operator;
    }

     ///@dev Updates the max holding amount. 
    function updateMaxUserHoldAmountRate(uint16 _maxUserHoldAmountRate) external onlyOwner {
        require(_maxUserHoldAmountRate >= 500);
        require(_maxUserHoldAmountRate <= 10000);
        
        emit TransferTaxRateUpdated(_msgSender(), maxUserHoldAmountRate, _maxUserHoldAmountRate);

        maxUserHoldAmountRate = _maxUserHoldAmountRate;
    }

    ///@dev Updates the max user transfer amount. 
    function updateMaxUserTransferAmountRate(uint16 _maxUserTransferAmountRate) external onlyOwner {
        require(_maxUserTransferAmountRate >= 50);
        require(_maxUserTransferAmountRate <= 10000);
        
        emit HoldingAmountRateUpdated(_msgSender(), maxUserHoldAmountRate, _maxUserTransferAmountRate);

        maxUserTransferAmountRate = _maxUserTransferAmountRate;
    }

    
    ///@dev Update the antiBotWorking status: ENABLE|DISABLE.
    function updateStatusAntiBotWorking(bool _status) external onlyOwner {
        emit AntiBotWorkingStatus(_msgSender(), antiBotWorking, _status);

        antiBotWorking = _status;
    }

     ///@dev Add an address to the blacklist. Only the owner can add. Owner is the address of the Governance contract.
    function addBotAddress(address _botAddress, uint256 _expirationTime) external onlyOwner {
        _addBotAddressToBlackList(_botAddress, _expirationTime);
    }
    
    ///@dev Remove an address from the blacklist. Only the owner can remove. Owner is the address of the Governance contract.
    function removeBotAddress(address botAddress) external onlyOperator {
        _removeBotAddressToBlackList(botAddress);
    }
    
    ///@dev Add multi address to the blacklist. Only the owner can add. Owner is the address of the Governance contract.
    function addBotAddressBatch(address[] memory _addresses, uint256 _expirationTime) external onlyOwner {
        require(_addresses.length > 0);

        for(uint i=0;i<_addresses.length;i++){
            _addBotAddressToBlackList(_addresses[i], _expirationTime);
        }
    }
    
    ///@dev Remove multi address from the blacklist. Only the owner can remove. Owner is the address of the Governance contract.
    function removeBotAddressBatch(address[] memory _addresses) external onlyOperator {
        require(_addresses.length > 0);

        for(uint i=0;i<_addresses.length;i++){
            _removeBotAddressToBlackList(_addresses[i]);
        }
    }

    ///@dev Check if the address is excluded from antibot system.
    function isExcludedOperatorFromAntiBot(address _userAddress) external view returns(bool) {
        return(_excludedOperators[_userAddress]);
    }

    ///@dev Check if the address is excluded from antibot system.
    function isExcludedHolderFromAntiBot(address _userAddress) external view returns(bool) {
        return(_excludedHoldersFromAntiBot[_userAddress]);
    }

        /**
     * @dev Update the transfer tax rate.
     * Can only be called by the current operator.
     */
    function updateTransferTaxRate(uint16 _transferTaxRate, uint16 _extraTransferTaxRate) external onlyOperator {
        require(_transferTaxRate + _extraTransferTaxRate  <= MAXIMUM_TRANSFER_TAX_RATE,
            "!valid");
        transferTaxRate = _transferTaxRate;
        extraTransferTaxRate = _extraTransferTaxRate;

        emit TransferFeeChanged(transferTaxRate, extraTransferTaxRate);
    }

    /**
     * @dev Update updateFeeExcludes
     * Can only be called by the current operator.
     */
    function updateExtraFee(address _contract, bool _status) external onlyOperator {
        extraFeeAddresses[_contract] = _status;
    }

    /**
     * @dev Update the swap router.
     * Can only be called by the current operator.
     */
    function updateSandManSwapRouter(address _router) external onlyOperator {
        require(_router != address(0), "!!0");
        require(address(sandManSwapRouter) == address(0), "!unset");

        sandManSwapRouter = IUniswapV2Router02(_router);
        sandManSwapPair = IUniswapV2Factory(sandManSwapRouter.factory()).getPair(address(this), sandManSwapRouter.WETH());

        require(address(sandManSwapPair) != address(0), "!matic pair");

        emit SetSandManRouter(address(sandManSwapRouter), sandManSwapPair);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract TheEndlessToken is Ownable, ERC20("TheEndless Owernship", "TheEndless") {

    constructor() {
        _mint(address(this), 40 * (10 ** 3) * (10 ** 18));
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function burn(uint256 _amount) external onlyOwner {
        _burn(msg.sender, _amount);
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

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract TreasuryDAO is ReentrancyGuard, AccessControl {
    using SafeERC20 for ERC20;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");

    address public sandManAddress;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    IERC20 public usdCurrency;
    IERC20 public wnativeToken;
    IUniswapV2Router02 public sandManSwapRouter;
    // The trading pair
    address public sandManSwapPair;

    // default to two weeks
    uint256 public distributionTimeFrame = 100;
    uint256 public lastUSDDistroTime;
    uint256 public constant usdSwapThreshold = 20 * (10 ** 6);
    uint256 public pendingUSD = 0;

    // To receive ETH when swapping
    receive() external payable {}

    event SetSandManAddresses(address sandManAddress, address sandManSwapPair);
    event DistributeTheEndless(address recipient, uint256 TheEndlessAmount);
    event DepositFeeConvertedToUSD(address indexed inputToken, uint256 inputAmount, uint256 usdOutput);
    event USDTransferredToUser(address recipient, uint256 usdAmount);
    event SandManSwapRouterUpdated(address indexed operator, address indexed router);
    event SetUSDDistributionTimeFrame(uint256 distributionTimeFrameBlocks);

    /**
     * @notice Constructs the SandManToken contract.
     */
    constructor(address _wnativeToken, address _usdCurrency, IUniswapV2Router02 _sandManSwapRouter, uint256 startTime) {
        sandManSwapRouter = _sandManSwapRouter;
        usdCurrency = IERC20(_usdCurrency);
        wnativeToken = IERC20(_wnativeToken);

        lastUSDDistroTime = startTime;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
    }

    function convertToTargetValueFromPair(IUniswapV2Pair pair, uint256 sourceTokenAmount, address targetAddress) public view returns (uint256) {
        require(pair.token0() == targetAddress || pair.token1() == targetAddress, "one of the pairs must be the targetAddress");
        if (sourceTokenAmount == 0)
            return 0;

        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (res0 == 0 || res1 == 0)
            return 0;

        if (pair.token0() == targetAddress)
            return (res0 * sourceTokenAmount) / res1;
        else
            return (res1 * sourceTokenAmount) / res0;
    }

    function getTokenUSDValue(uint256 tokenBalance, address token, uint256 tokenType, bool viaMaticUSD, address usdAddress) public view returns (uint256) {
        require(tokenType == 0 || tokenType == 1, "invalid token type provided");
        if (token == address(usdAddress))
            return tokenBalance;

        // lp type
        if (tokenType == 1) {
            IUniswapV2Pair lpToken = IUniswapV2Pair(token);
            if (lpToken.totalSupply() == 0)
                return 0;
            // If lp contains usd, we can take a short-cut
            if (lpToken.token0() == address(usdAddress)) {
                return (IERC20(lpToken.token0()).balanceOf(address(lpToken)) * tokenBalance * 2) / lpToken.totalSupply();
            } else if (lpToken.token1() == address(usdAddress)){
                return (IERC20(lpToken.token1()).balanceOf(address(lpToken)) * tokenBalance * 2) / lpToken.totalSupply();
            }
        }

        // Only used for lp type tokens.
        address lpTokenAddress = token;
        // If token0 or token1 is matic, use that, else use token0.
        if (tokenType == 1) {
            token = IUniswapV2Pair(token).token0() == sandManSwapRouter.WETH() ? sandManSwapRouter.WETH() :
                        (IUniswapV2Pair(token).token1() == sandManSwapRouter.WETH() ? sandManSwapRouter.WETH() : IUniswapV2Pair(token).token0());
        }

        // if it is an LP token we work with all of the reserve in the LP address to scale down later.
        uint256 tokenAmount = (tokenType == 1) ? IERC20(token).balanceOf(lpTokenAddress) : tokenBalance;

        uint256 usdEquivalentAmount = 0;

        if (viaMaticUSD) {
            uint256 maticAmount = 0;

            if (token == sandManSwapRouter.WETH()) {
                maticAmount = tokenAmount;
            } else {

                // As we arent working with usd at this point (early return), this is okay.
                IUniswapV2Pair maticPair = IUniswapV2Pair(IUniswapV2Factory(sandManSwapRouter.factory()).getPair(sandManSwapRouter.WETH(), token));

                if (address(maticPair) == address(0))
                    return 0;

                maticAmount = convertToTargetValueFromPair(maticPair, tokenAmount, sandManSwapRouter.WETH());
            }

            // As we arent working with usd at this point (early return), this is okay.
            IUniswapV2Pair usdmaticPair = IUniswapV2Pair(IUniswapV2Factory(sandManSwapRouter.factory()).getPair(sandManSwapRouter.WETH(), address(usdAddress)));

            if (address(usdmaticPair) == address(0))
                return 0;

            usdEquivalentAmount = convertToTargetValueFromPair(usdmaticPair, maticAmount, usdAddress);
        } else {
            // As we arent working with usd at this point (early return), this is okay.
            IUniswapV2Pair usdPair = IUniswapV2Pair(IUniswapV2Factory(sandManSwapRouter.factory()).getPair(address(usdAddress), token));

            if (address(usdPair) == address(0))
                return 0;

            usdEquivalentAmount = convertToTargetValueFromPair(usdPair, tokenAmount, usdAddress);
        }

        // for the tokenType == 1 path usdEquivalentAmount is the USD value of all the tokens in the parent LP contract.

        if (tokenType == 1)
            return (usdEquivalentAmount * tokenBalance * 2) / IUniswapV2Pair(lpTokenAddress).totalSupply();
        else
            return usdEquivalentAmount;
    }

    function autoLiquidity() external nonReentrant {
        // require(msg.sender == sandManAddress, "can only be used by the sandMan token!");

        (uint256 res0, uint256 res1, ) = IUniswapV2Pair(sandManSwapPair).getReserves();

        if (res0 != 0 && res1 != 0) {
            // making weth res0
            if (IUniswapV2Pair(sandManSwapPair).token0() == sandManAddress)
                (res1, res0) = (res0, res1);

            uint256 contractTokenBalance = ERC20(sandManAddress).balanceOf(address(this));

            // calculate how much eth is needed to use all of contractTokenBalance
            // also boost precision a tad.
            uint256 totalETHNeeded = (res0 * contractTokenBalance) / res1;

            uint256 existingETH = address(this).balance;

            uint256 unmatchedSandMan = 0;

            if (existingETH < totalETHNeeded) {
                // calculate how much sandMan will match up with our existing eth.
                uint256 matchedSandMan = (res1 * existingETH) / res0;
                if (contractTokenBalance >= matchedSandMan)
                    unmatchedSandMan = contractTokenBalance - matchedSandMan;
            } else if (existingETH > totalETHNeeded) {
                // use excess eth for sandMan buy back
                uint256 excessETH = existingETH - totalETHNeeded;

                if (excessETH / 2 > 0) {
                    // swap half of the excess eth for lp to be balanced
                    _swapETHForTokens(excessETH / 2, sandManAddress);
                }
            }

            uint256 unmatchedSandManToSwap = unmatchedSandMan / 2;

            // swap tokens for ETH
            if (unmatchedSandManToSwap > 0)
                _swapTokensForEth(sandManAddress, unmatchedSandManToSwap);

            uint256 sandManBalance = ERC20(sandManAddress).balanceOf(address(this));

            // approve token transfer to cover all possible scenarios
            ERC20(sandManAddress).approve(address(sandManSwapRouter), sandManBalance);

            // add the liquidity
            sandManSwapRouter.addLiquidityETH{value: address(this).balance}(
                sandManAddress,
                sandManBalance,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                BURN_ADDRESS,
                block.timestamp
            );

        }
    }

    /// @dev Swap tokens for eth
    function _swapTokensForEth(address saleTokenAddress, uint256 tokenAmount) internal {
        // generate the sandManSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = saleTokenAddress;
        path[1] = sandManSwapRouter.WETH();

        ERC20(saleTokenAddress).approve(address(sandManSwapRouter), tokenAmount);

        // make the swap
        sandManSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }


    function _swapETHForTokens(uint256 ethAmount, address wantedTokenAddress) internal {
        require(address(this).balance >= ethAmount, "insufficient matic provided!");
        require(wantedTokenAddress != address(0), "wanted token address can't be the zero address!");

        // generate the sandManSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = sandManSwapRouter.WETH();
        path[1] = wantedTokenAddress;

        // make the swap
        sandManSwapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0,
            path,
            // cannot send tokens to the token contract of the same type as the output token
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev set the sandMan address.
     * Can only be called by the current owner.
     */
    function setSandManAddress(address _sandManAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_sandManAddress != address(0), "_sandManAddress is the zero address");
        require(sandManAddress == address(0), "sandManAddress already set!");

        sandManAddress = _sandManAddress;

        sandManSwapPair = IUniswapV2Factory(sandManSwapRouter.factory()).getPair(sandManAddress, sandManSwapRouter.WETH());

        require(address(sandManSwapPair) != address(0), "matic pair !exist");

        emit SetSandManAddresses(sandManAddress, sandManSwapPair);
    }

    /**
     * @dev sell all of a current type of token for usd. and distribute on a drip.
     * Can only be called by the current owner.
     */
    function getUSDDripRate() external view returns (uint256) {
        return usdCurrency.balanceOf(address(this)) / distributionTimeFrame;
    }

    /**
     * @dev sell all of a current type of token for usd. and distribute on a drip.
     * Can only be called by the current owner.
     */
    function getUSDDrip(uint256 totalUsdLockup) external onlyRole(OPERATOR_ROLE) returns (uint256) {
        uint256 usdBalance = usdCurrency.balanceOf(address(this));
        if (pendingUSD + totalUsdLockup > usdBalance)
            return 0;

        uint256 usdAvailable = usdBalance - pendingUSD - totalUsdLockup;

        // only provide a drip if there has been some blocks passed since the last drip
        uint256 timeSinceLastDistro = block.timestamp > lastUSDDistroTime ? block.timestamp - lastUSDDistroTime : 0;

        // We distribute the usd assuming the old usd balance wanted to be distributed over distributionTimeFrame blocks.
        uint256 usdRelease = (timeSinceLastDistro * usdAvailable) / distributionTimeFrame;

        usdRelease = usdRelease > usdAvailable ? usdAvailable : usdRelease;

        lastUSDDistroTime = block.timestamp;
        pendingUSD += usdRelease;

        return usdRelease;
    }

    /**
     * @dev sell all of a current type of token for usd.
     */
    function convertDepositFeesToUSD(address token, uint256 tokenType, uint256 amount) public  onlyRole(OPERATOR_ROLE) {
        //tokenType = 0 from here
        if (amount == 0)
            return;

        if (tokenType == 1) {
            _removeLiquidity(token);
            convertDepositFeesToUSD(IUniswapV2Pair(token).token0(), 0, amount / 2 );
            convertDepositFeesToUSD(IUniswapV2Pair(token).token1(), 0, amount / 2);
            return;
        }

        //split 75% owner 25% for autoliquidity
        uint256 holdingLiquidity = amount * 2500 / 10000;
        uint256 holdingOwnership = amount * 7500 / 10000;

        // just swap liquidy holding
        if (token == address(usdCurrency)) {
            _swapTokensForEth(token, holdingLiquidity);
            return;
        }

        // just swap ownership holding
        if (token == address(wnativeToken)) {
            _swapETHForTokens(holdingOwnership, address(usdCurrency));
            return;
        }
         
        // generate the sandManSwap pair path of token -> usd.
        address[] memory path = new address[](3);
        path[0] = token;
        path[1] = address(wnativeToken);
        path[2] = address(usdCurrency);

        require(IERC20(token).approve(address(sandManSwapRouter), holdingOwnership), 'approval failed');

        try
            // make the swap
            sandManSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                holdingOwnership,
                0, // accept any amount of USD
                path,
                address(this),
                block.timestamp
            )
        { /* suceeded */ } catch { /* failed, but we avoided reverting */ }

        _swapTokensForEth(token, holdingLiquidity);
        
        // emit DepositFeeConvertedToUSD(token, totalTokenBalance, usdProfit);
    }

    function _removeLiquidity(address token) internal {
        uint256 amount = IERC20(token).balanceOf(address(this));

        require(IERC20(token).approve(address(sandManSwapRouter), amount), '!approved');

        IUniswapV2Pair lpToken = IUniswapV2Pair(token);

        // make the swap
        sandManSwapRouter.removeLiquidity(
            lpToken.token0(),
            lpToken.token1(),
            amount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function claim(IERC20 token, address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token.transfer(to, token.balanceOf(address(this)));
    }

    function updateSandManSwapRouter(address _router) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_router != address(0), "updateSandManSwapRouter: new _router is the zero address");
        require(address(sandManSwapRouter) == address(0), "router already set!");

        sandManSwapRouter = IUniswapV2Router02(_router);
        emit SandManSwapRouterUpdated(msg.sender, address(sandManSwapRouter));
    }

    function setUSDDistributionTimeFrame(uint256 _usdDistributionTimeFrame) external onlyRole(DEFAULT_ADMIN_ROLE) {
        distributionTimeFrame = _usdDistributionTimeFrame;

        emit SetUSDDistributionTimeFrame(distributionTimeFrame);
    }

    function transferUSDToOwner(address ownerAddress, uint256 amount) external onlyRole(OPERATOR_ROLE) {
       uint256 usdBalance = usdCurrency.balanceOf(address(this));
       if (usdBalance < amount)
           amount = usdBalance;

       require(usdCurrency.transfer(ownerAddress, amount), "transfer failed!");

       pendingUSD -= amount;

        emit USDTransferredToUser(ownerAddress, amount);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}