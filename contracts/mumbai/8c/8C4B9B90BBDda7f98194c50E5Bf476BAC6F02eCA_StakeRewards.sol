// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./../utils/DepositWithdraw.sol";
import "./IZizyCompetitionStaking.sol";

// Stake Rewards Contract
contract StakeRewards is DepositWithdraw {
    uint constant MAX_UINT = (2 ** 256) - 1;


    event AccountVestingRewardCreate(uint rewardId, uint vestingIndex, uint chainId, RewardType rewardType, address contractAddress, address indexed account, uint amount);
    event RewardClaimDiffChain(uint rewardId, uint vestingIndex, uint chainId, RewardType rewardType, address contractAddress, address indexed account, uint baseAmount, uint boostedAmount);
    event RewardClaimSameChain(uint rewardId, uint vestingIndex, uint chainId, RewardType rewardType, address contractAddress, address indexed account, uint baseAmount, uint boostedAmount);
    event RewardUpdated(uint rewardId, uint chainId, RewardType rewardType, address contractAddress, uint totalDistribution);
    event RewardConfigUpdated(uint rewardId, bool vestingEnabled, uint snapshotMin, uint snapshotMax, uint vestingDayInterval);
    event RewardClear(uint rewardId);



    // Reward Type
    enum RewardType {
        Token,
        Native,
        ZizyStakingPercentage
    }

    // Reward Booster Type
    enum BoosterType {
        HoldingNFT,
        ERC20Balance,
        StakingBalance
    }

    // Reward Booster
    struct Booster {
        BoosterType boosterType;
        address contractAddress; // Booster target contract
        uint amount; // Only for ERC20Balance & StakeBalance boosters
        uint boostPercentage; // Boost percentage
        bool _exist;
    }

    // Reward Tier
    struct RewardTier {
        uint stakeMin;
        uint stakeMax;
        uint rewardAmount;
    }

    // Reward Struct
    struct Reward {
        uint chainId;
        RewardType rewardType;
        address contractAddress; // Only token rewards
        uint amount;
        uint totalDistributed;
        uint percentage;
        bool _exist;
    }

    // Account Reward Struct
    struct AccountReward {
        uint chainId;
        RewardType rewardType;
        address contractAddress; // Only token rewards
        uint amount;
        bool isClaimed;
        bool _exist;
    }

    // Reward Config
    struct RewardConfig {
        bool vestingEnabled;
        uint vestingInterval; // 7 days
        uint vestingPeriodCount; // 10 vesting period [10 * 7 days]
        uint vestingStartDate; // Vesting start date
        uint snapshotMin;
        uint snapshotMax;
        bool _exist;
    }

    // Cache average
    struct CacheAverage {
        uint average;
        bool _exist;
    }

    // Account base reward
    struct AccBaseReward {
        uint baseReward;
        bool _exist;
    }

    // Reward definer account
    address public rewardDefiner;

    // Booster ids for iteration
    uint16[] private _boosterIds;

    // Reward boosters [boosterId > Booster]
    mapping(uint16 => Booster) private _boosters;

    // Reward configs [rewardId > RewardConfig]
    mapping(uint => RewardConfig) public rewardConfig;

    // Reward tiers [rewardId > RewardTier[]]
    mapping(uint => RewardTier[]) private _rewardTiers;

    // Rewards [rewardId > Reward]
    mapping(uint => Reward) private _rewards;

    // Account rewards [rewardId > address > vestingIndex > Reward]
    mapping(uint => mapping(address => mapping(uint => AccountReward))) private _accountRewards;

    // Account reward vesting periods defined [rewardId > address > bool]
    mapping(uint => mapping(address => bool)) private _accountRewardVestingPrepare;

    // Account average cache. Gas save for same snapshot range average calculations
    mapping(address => mapping(bytes32 => CacheAverage)) private _accountAverageCache;

    // Account total base reward (Sum of vestings) [address > rewardId > allocation]
    mapping(address => mapping(uint => AccBaseReward)) private _accountBaseReward;

    // Reward claim state for rewardId [Using for clear rewards] [rewardId > bool]
    mapping(uint => bool) private _isRewardClaimed;

    // Staking contract
    IZizyCompetitionStaking private stakingContract;



    // Only reward definer modifier
    modifier onlyRewardDefiner() {
        require(_msgSender() == rewardDefiner, "Only call from reward definer address");
        _;
    }

    // Only accept staking contract is defined
    modifier stakingContractIsSet() {
        require(address(stakingContract) != address(0), "Staking contract address must be defined");
        _;
    }

    // Initializer
    function initialize(address stakingContract_, address rewardDefiner_) external initializer {
        __Ownable_init();

        setStakingContract(stakingContract_);
        setRewardDefiner(rewardDefiner_);
    }

    // Get chainId
    function chainId() public view returns (uint) {
        return block.chainid;
    }

    // Get cache key for snapshot range calculation
    function _cacheKey(uint min_, uint max_) internal pure returns (bytes32) {
        return keccak256(abi.encode(min_, max_));
    }

    // Set average calculation
    function _setAverageCalculation(address account_, uint min_, uint max_, uint average_) internal {
        _accountAverageCache[account_][_cacheKey(min_, max_)] = CacheAverage(average_, true);
    }

    // Get booster
    function getBooster(uint16 boosterId_) public view returns (Booster memory) {
        return _boosters[boosterId_];
    }

    // Get booster index
    function getBoosterIndex(uint16 boosterId_) public view returns (uint) {
        require(_boosters[boosterId_]._exist == true, "Booster is not exist");
        uint boosterCount = getBoosterCount();
        uint16[] memory ids = _boosterIds;

        for (uint i = 0; i < boosterCount; ++i) {
            if (ids[i] == boosterId_) {
                return i;
            }
        }
        revert("Booster index not found !");
    }

    // Get boosters count
    function getBoosterCount() public view returns (uint) {
        return _boosterIds.length;
    }

    // Set & Update booster
    function setBooster(uint16 boosterId_, BoosterType type_, address contractAddress_, uint amount_, uint boostPercentage_) public onlyRewardDefiner {
        // Validate
        if (type_ == BoosterType.ERC20Balance || type_ == BoosterType.StakingBalance) {
            require(amount_ > 0, "Amount should be higher than zero");
        }
        if (type_ == BoosterType.ERC20Balance || type_ == BoosterType.HoldingNFT) {
            require(contractAddress_ != address(0), "Contract address cant be zero address");
        }

        // Format
        if (type_ == BoosterType.HoldingNFT) {
            amount_ = 0;
        } else if (type_ == BoosterType.StakingBalance) {
            contractAddress_ = address(0);
        }

        if (_boosters[boosterId_]._exist == false) {
            _boosterIds.push(boosterId_);
        }

        _boosters[boosterId_] = Booster(type_, contractAddress_, amount_, boostPercentage_, true);
    }

    // Remove booster
    function removeBooster(uint16 boosterId_) public onlyRewardDefiner {
        Booster memory booster = getBooster(boosterId_);
        require(booster._exist == true, "Booster does not exist");

        uint boosterCount = getBoosterCount();

        booster._exist = false;
        booster.boostPercentage = 0;
        booster.amount = 0;
        booster.contractAddress = address(0);

        for (uint i = 0; i < boosterCount; ++i) {
            uint16 indexBoosterId = _boosterIds[i];
            if (indexBoosterId == boosterId_) {
                _boosterIds[i] = _boosterIds[boosterCount - 1];
                _boosterIds.pop();
                _boosters[boosterId_] = booster;
                break;
            }
        }
    }

    // Get account reward booster percentage
    function getAccountBoostPercentage(address account_) public view returns (uint) {
        uint percentage = 0;
        uint boosterCount = getBoosterCount();
        uint16[] memory ids = _boosterIds;

        for (uint i = 0; i < boosterCount; i++) {
            uint16 boosterId = ids[i];
            Booster memory booster = _boosters[boosterId];
            if (booster._exist == false) {
                continue;
            }

            if (booster.boosterType == BoosterType.StakingBalance) {
                // Add additional boost percentage if stake balance is higher than given balance condition
                if (stakingContract.balanceOf(account_) >= booster.amount) {
                    percentage += booster.boostPercentage;
                }
            } else if (booster.boosterType == BoosterType.ERC20Balance) {
                // Add additional boost percentage if erc20 balance is higher than given balance condition
                if (IERC20Upgradeable(booster.contractAddress).balanceOf(account_) >= booster.amount) {
                    percentage += booster.boostPercentage;
                }
            } else if (booster.boosterType == BoosterType.HoldingNFT) {
                // Add additional boost percentage if account is given NFT holder
                if (IERC721Upgradeable(booster.contractAddress).balanceOf(account_) >= 1) {
                    percentage += booster.boostPercentage;
                }
            }
        }

        return percentage;
    }

    // Get average calculation
    function getSnapshotsAverageCalculation(address account_, uint min_, uint max_) public view returns (CacheAverage memory) {
        return _getAccountSnapshotsAverage(account_, min_, max_);
    }

    // Set staking contract address
    function setStakingContract(address contract_) public onlyOwner {
        require(contract_ != address(0), "Contract address cant be zero address");
        stakingContract = IZizyCompetitionStaking(contract_);
    }

    // Set reward definer address
    function setRewardDefiner(address rewardDefiner_) public onlyOwner {
        require(rewardDefiner_ != address(0), "Reward definer address cant be zero address");
        rewardDefiner = rewardDefiner_;
    }

    /**
     * @dev Validate reward type
     */
    function _validateReward(Reward memory reward_) internal pure returns (bool) {
        if (reward_.amount == 0) {
            return false;
        }
        if (reward_.rewardType == RewardType.Native && reward_.contractAddress != address(0)) {
            return false;
        }
        if (reward_.rewardType == RewardType.Token && reward_.contractAddress == address(0)) {
            return false;
        }
        if (reward_.rewardType == RewardType.ZizyStakingPercentage && reward_.contractAddress == address(0)) {
            return false;
        }

        return true;
    }

    // Check reward configs
    function isRewardConfigsCompleted(uint rewardId_) public view returns (bool) {
        RewardConfig memory config = rewardConfig[rewardId_];
        Reward memory reward = _rewards[rewardId_];

        if (!config._exist) {
            return false;
        }
        if (reward.rewardType != RewardType.ZizyStakingPercentage) {
            // Zizy staking percentage reward doesn't required tier list
            if (_rewardTiers[rewardId_].length <= 0) {
                return false;
            }
        }
        if (config.snapshotMin <= 0 || config.snapshotMax <= 0 || config.snapshotMin > config.snapshotMax) {
            return false;
        }
        if (config.vestingEnabled && config.vestingInterval == 0 && config.vestingStartDate == 0) {
            return false;
        }

        return true;
    }

    // Set & Update reward config
    function setRewardConfig(uint rewardId_, bool vestingEnabled_, uint vestingStartDate_, uint vestingDayInterval_, uint vestingPeriodCount_, uint snapshotMin_, uint snapshotMax_) public onlyRewardDefiner stakingContractIsSet {
        RewardConfig memory config = rewardConfig[rewardId_];
        require(_isRewardClaimed[rewardId_] == false, "This rewardId has claimed reward. Cant update");

        uint currentSnapshot = stakingContract.getSnapshotId();

        require(snapshotMin_ < currentSnapshot && snapshotMax_ < currentSnapshot, "Snapshot ranges is not correct");

        // Check vesting day
        if (vestingEnabled_) {
            require(vestingDayInterval_ > 0, "Vesting day cant be zero");
            require(vestingPeriodCount_ > 0, "Vesting period count cant be zero");
            require(vestingStartDate_ > 0, "Vesting start date cant be zero");
        }

        config.vestingEnabled = vestingEnabled_;
        config.vestingInterval = (vestingEnabled_ == true ? (vestingDayInterval_ * (1 days)) : 0);
        config.vestingPeriodCount = (vestingEnabled_ == true ? vestingPeriodCount_ : 1);
        config.vestingStartDate = (vestingEnabled_ == true ? vestingStartDate_ : 0);
        config.snapshotMin = snapshotMin_;
        config.snapshotMax = snapshotMax_;
        config._exist = true;

        rewardConfig[rewardId_] = config;

        emit RewardConfigUpdated(rewardId_, vestingEnabled_, snapshotMin_, snapshotMax_, vestingDayInterval_);
    }

    // Get reward tiers count
    function getRewardTierCount(uint rewardId_) public view returns (uint) {
        return _rewardTiers[rewardId_].length;
    }

    // Get reward tier
    function getRewardTier(uint rewardId_, uint index_) public view returns (RewardTier memory) {
        uint tierLength = getRewardTierCount(rewardId_);
        require(index_ < tierLength, "Tier index out of boundaries");

        return _rewardTiers[rewardId_][index_];
    }

    // Set & Update reward tiers
    function setRewardTiers(uint rewardId_, RewardTier[] calldata tiers_) public onlyRewardDefiner {
        require(_isRewardClaimed[rewardId_] == false, "This rewardId has claimed reward. Cant update");

        uint tierLength = tiers_.length;
        require(tierLength > 1, "Tier length should be higher than 1");

        uint prevMax = 0;

        // Clear old tiers
        delete _rewardTiers[rewardId_];

        for (uint i = 0; i < tierLength; ++i) {
            RewardTier memory tier_ = tiers_[i];

            bool isFirst = (i == 0);
            bool isLast = (i == (tierLength - 1));

            tier_.stakeMax = (isLast ? (MAX_UINT) : tier_.stakeMax);

            if (!isFirst) {
                require(tier_.stakeMin > prevMax, "Range collision");
            }
            _rewardTiers[rewardId_].push(tier_);

            prevMax = tier_.stakeMax;
        }
    }

    // Set & Update reward
    function _setReward(uint rewardId_, uint chainId_, RewardType rewardType_, address contractAddress_, uint amount_, uint percentage_) internal {
        require(_isRewardClaimed[rewardId_] == false, "This rewardId has claimed reward. Cant update");
        Reward memory currentReward = _rewards[rewardId_];
        Reward memory reward = Reward(chainId_, rewardType_, contractAddress_, amount_, 0, percentage_, false);
        require(_validateReward(reward) == true, "Reward data is not correct");

        if (currentReward._exist == true && _isRewardClaimed[rewardId_] == true) {
            revert("Cant set/update claimed reward");
        }

        _rewards[rewardId_] = reward;

        emit RewardUpdated(rewardId_, chainId_, rewardType_, contractAddress_, amount_);
    }

    // Set native reward
    function setNativeReward(uint rewardId_, uint chainId_, uint amount_) public onlyRewardDefiner {
        _setReward(rewardId_, chainId_, RewardType.Native, address(0), amount_, 0);
    }

    // Set token reward
    function setTokenReward(uint rewardId_, uint chainId_, address contractAddress_, uint amount_) public onlyRewardDefiner {
        _setReward(rewardId_, chainId_, RewardType.Token, contractAddress_, amount_, 0);
    }

    // Set zizy stake percentage reward
    function setZizyStakePercentageReward(uint rewardId_, address contractAddress_, uint amount_, uint percentage_) public onlyRewardDefiner {
        _setReward(rewardId_, chainId(), RewardType.ZizyStakingPercentage, contractAddress_, amount_, percentage_);
    }

    // Get reward
    function getReward(uint rewardId_) public view returns (Reward memory) {
        return _rewards[rewardId_];
    }

    // Get account reward
    function getAccountReward(address account_, uint rewardId_, uint index_) public view returns (AccountReward memory) {
        return _accountRewards[rewardId_][account_][index_];
    }

    // Claim rewards
    function _claimReward(address account_, uint rewardId_, uint vestingIndex_) internal {
        AccountReward memory reward = _accountRewards[rewardId_][account_][vestingIndex_];
        require(isRewardClaimable(account_, rewardId_, vestingIndex_) == true, "Reward isnt claimable");

        // Set claim state first [Reentrancy ? :)]
        _accountRewards[rewardId_][account_][vestingIndex_].isClaimed = true;

        // Disable reward & reward config update
        _isRewardClaimed[rewardId_] = true;

        uint boosterPercentage = getAccountBoostPercentage(account_);
        uint boostedAmount = (reward.amount * (100 + boosterPercentage)) / 100;

        Reward memory baseReward = getReward(rewardId_);
        require(baseReward.amount >= (baseReward.totalDistributed + boostedAmount), "Not enough balance in the pool allocated for the reward");

        // Update total distributed amount of base reward
        _rewards[rewardId_].totalDistributed += boostedAmount;

        if (reward.chainId == chainId()) {
            if (reward.rewardType == RewardType.Native) {
                _sendNativeCoin(payable(account_), boostedAmount);
            } else if (reward.rewardType == RewardType.Token || reward.rewardType == RewardType.ZizyStakingPercentage) {
                _sendToken(account_, reward.contractAddress, boostedAmount);
            }
            emit RewardClaimSameChain(rewardId_, vestingIndex_, reward.chainId, reward.rewardType, reward.contractAddress, account_, reward.amount, boostedAmount);
        } else {
            // Emit event for message relay
            emit RewardClaimDiffChain(rewardId_, vestingIndex_, reward.chainId, reward.rewardType, reward.contractAddress, account_, reward.amount, boostedAmount);
        }
    }

    // Check reward is claimable for public view
    function isRewardClaimable(address account_, uint rewardId_, uint vestingIndex_) public view returns (bool) {
        // Check reward configs
        if (isRewardConfigsCompleted(rewardId_) == false) {
            return false;
        }

        RewardConfig memory config = rewardConfig[rewardId_];
        AccountReward memory reward = _accountRewards[rewardId_][account_][vestingIndex_];

        (AccBaseReward memory baseReward, , ) = getAccountRewardDetails(account_, rewardId_, config.snapshotMin, config.snapshotMax);
        uint ts = block.timestamp;

        if (_isVestingPeriodsPrepared(account_, rewardId_) == true) {
            if (reward._exist == false || reward.isClaimed == true) {
                return false;
            }
        } else {
            // No allocation for this reward
            if (baseReward.baseReward <= 0) {
                return false;
            }
        }

        // Check vesting dates
        if (config.vestingEnabled) {
            if (ts < ((vestingIndex_ * config.vestingInterval) + config.vestingStartDate)) {
                return false;
            }
        }

        return true;
    }

    // Claim single reward with vesting index
    function claimReward(uint rewardId_, uint vestingIndex_) external nonReentrant {
        // Prepare vesting periods
        _prepareRewardVestingPeriods(_msgSender(), rewardId_);
        _claimReward(_msgSender(), rewardId_, vestingIndex_);
    }

    // Check is vesting periods prepared before
    function _isVestingPeriodsPrepared(address account_, uint rewardId_) internal view returns (bool) {
        return _accountRewardVestingPrepare[rewardId_][account_];
    }

    // Get account snapshots average
    function _getAccountSnapshotsAverage(address account_, uint snapshotMin_, uint snapshotMax_) internal view returns (CacheAverage memory) {
        CacheAverage memory accAverage = _accountAverageCache[account_][_cacheKey(snapshotMin_, snapshotMax_)];
        if (accAverage._exist == false) {
            accAverage.average = stakingContract.getSnapshotAverage(account_, snapshotMin_, snapshotMax_);
        }
        return accAverage;
    }

    // Get account reward details
    function getAccountRewardDetails(address account_, uint rewardId_, uint snapshotMin_, uint snapshotMax_) public view returns (AccBaseReward memory, CacheAverage memory, uint) {
        AccBaseReward memory baseReward = _accountBaseReward[account_][rewardId_];
        CacheAverage memory accAverage = _getAccountSnapshotsAverage(account_, snapshotMin_, snapshotMax_);
        RewardTier[] memory tiers = _rewardTiers[rewardId_];
        Reward memory reward = _rewards[rewardId_];
        uint tierLength = tiers.length;

        // Return if calculations already exist
        if (baseReward._exist) {
            return (baseReward, accAverage, tierLength);
        }

        if (reward.rewardType == RewardType.ZizyStakingPercentage) {
            // Staking percentage rewards doesn't required tier list
            baseReward.baseReward = (accAverage.average) * reward.percentage / 100;
        } else {
            // Find account tier range
            for (uint i = 0; i < tierLength; ++i) {
                RewardTier memory tier = tiers[i];

                if (i == 0 && accAverage.average < tier.stakeMin) {
                    break;
                }

                if (accAverage.average >= tier.stakeMin && accAverage.average <= tier.stakeMax) {
                    baseReward.baseReward = tier.rewardAmount;
                    break;
                }
            }
        }

        return (baseReward, accAverage, tierLength);
    }

    // Prepare account reward vesting periods
    function _prepareRewardVestingPeriods(address account_, uint rewardId_) internal {
        // Check prepared before for gas cost
        if (_isVestingPeriodsPrepared(account_, rewardId_) == true) {
            return;
        }

        RewardConfig memory config = rewardConfig[rewardId_];
        Reward memory reward = _rewards[rewardId_];

        (AccBaseReward memory baseReward, CacheAverage memory accAverage, ) = getAccountRewardDetails(account_, rewardId_, config.snapshotMin, config.snapshotMax);

        // Write account average in cache if not exist
        if (accAverage._exist == false) {
            _setAverageCalculation(account_, config.snapshotMin, config.snapshotMax, accAverage.average);
        }

        // Write account base reward in state variable if not exist
        if (baseReward._exist == false) {
            baseReward._exist = true;
            _accountBaseReward[account_][rewardId_] = baseReward;
        }

        uint rewardPerVestingPeriod = (baseReward.baseReward / config.vestingPeriodCount);

        // Create vesting periods
        for (uint i = 0; i < config.vestingPeriodCount; ++i) {
            _accountRewards[rewardId_][account_][i] = AccountReward(reward.chainId, reward.rewardType, reward.contractAddress, rewardPerVestingPeriod, false, true);
            emit AccountVestingRewardCreate(rewardId_, i, reward.chainId, reward.rewardType, reward.contractAddress, account_, rewardPerVestingPeriod);
        }

        // Set vesting periods prepare state
        _accountRewardVestingPrepare[rewardId_][account_] = true;
    }

    // TODO: Get UnClaimed reward count method
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @dev Initializes the contract setting the deployer as the initial owner.
 */
contract DepositWithdraw is OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC721HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Deposit native coin on contract
    function deposit() public payable {
    }

    // Withdraw native coin
    function _sendNativeCoin(address payable to_, uint amount) internal {
        require(address(this).balance >= amount, "Insufficient native balance");
        (bool sent,) = to_.call{value : amount}("");
        require(sent, "Native coin transfer failed");
    }

    // Withdraw ERC20-Standards token
    function _sendToken(address to_, address token_, uint amount) internal {
        IERC20Upgradeable token = IERC20Upgradeable(token_);
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");
        token.safeTransfer(to_, amount);
    }

    // Withdraw ERC721-Standard token
    function _sendNFT(address to_, address token_, uint tokenId_) internal {
        IERC721Upgradeable nft = IERC721Upgradeable(token_);
        require(nft.ownerOf(tokenId_) == address(this), "Rewards hub contract is not owner of this nft");
        nft.safeTransferFrom(address(this), to_, tokenId_);
    }

    // Withdraw native coin from contract
    function withdraw(uint amount) external nonReentrant onlyOwner {
        address payable to_ = payable(owner());
        _sendNativeCoin(to_, amount);
    }

    // Withdraw native coin from contract to address
    function withdrawTo(address payable to_, uint amount) external nonReentrant onlyOwner {
        _sendNativeCoin(to_, amount);
    }

    // Deposit reward tokens to contract
    function depositToken(address token_, uint amount) external onlyOwner {
        IERC20Upgradeable token = IERC20Upgradeable(token_);
        require(token.allowance(_msgSender(), address(this)) >= amount, "Insufficient allowance");
        token.safeTransferFrom(_msgSender(), address(this), amount);
    }

    // Withdraw token from contract
    function withdrawToken(address token_, uint amount) external onlyOwner {
        _sendToken(owner(), token_, amount);
    }

    // Withdraw token from contract to address
    function withdrawTokenTo(address to_, address token_, uint amount) external onlyOwner {
        _sendToken(to_, token_, amount);
    }

    // Deposit reward NFT's to contract
    function depositNFT(address token_, uint tokenId_) external onlyOwner {
        IERC721Upgradeable nft = IERC721Upgradeable(token_);
        nft.safeTransferFrom(_msgSender(), address(this), tokenId_);
    }

    // Withdraw NFT from contract
    function withdrawNFT(address token_, uint tokenId_) external onlyOwner {
        _sendNFT(owner(), token_, tokenId_);
    }

    // Withdraw NFT from contract to address
    function withdrawNFTTo(address to_, address token_, uint tokenId_) external onlyOwner {
        _sendNFT(to_, token_, tokenId_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IZizyCompetitionStaking {
    function getSnapshotAverage(address account, uint256 min, uint256 max) external view returns (uint);
    function getPeriodSnapshotsAverage(address account, uint256 periodId, uint256 min, uint256 max) external view returns (uint256, bool);
    function getPeriodStakeAverage(address account, uint256 periodId) external view returns (uint256, bool);
    function getPeriodSnapshotRange(uint256 periodId) external view returns (uint, uint);
    function setPeriodId(uint256 period) external returns (uint256);
    function getSnapshotId() external view returns (uint256);
    function stake(uint256 amount_) external;
    function balanceOf(address account) external view returns (uint256);
    function getPeriod(uint256 periodId_) external view returns (uint, uint, uint, uint, uint16, bool);
    function unStake(uint256 amount_) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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