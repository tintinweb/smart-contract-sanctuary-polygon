// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import './access-control.sol';

/**
 * @dev Partial interface of the ERC20 standard according to the needs of the e2p contract.
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(
        address recipient, uint256 amount
    ) external returns (bool);
    function transferFrom(
        address sender, address recipient, uint256 amount
    ) external returns (bool);
    function allowance(
        address owner, address spender
    ) external view returns (uint256);
    function decimals() external view returns (uint8);
}

/**
 * @dev Partial interface of the ERC20 standard according to the needs of the e2p contract.
 */
interface IBorrowingLending {
    function getBorrowingProfilesNumber () external view returns (uint256);
    function getTotalLent (
        uint256 borrowingProfileIndex
    ) external view returns (uint256);
    function getUserProfileLent (
        address userAddress, uint256 borrowingProfileIndex
    ) external view returns (uint256);
    function getUsdRate (
        address contractAddress
    ) external view returns (uint256);
}

/**
 * @dev Interface of the Proxy contract.
 */
interface IProxy {
    function getUsdRate (
        address contractAddress
    ) external view returns (uint256);
}


/**
 * @dev Bonus reward based on the lent amount.
 */
contract RewardPerBlock is AccessControl {
    modifier onlyBorrowingLendingContract () {
        require(
            msg.sender == address(_borrowingLendingContract),
                'Caller is not the Borrowing Lending contract'
        );
        _;
    }
    struct Profile {
        uint256 rewardPerToken;
        uint256 lastTimestamp;
        uint256 rewardPercentage; // % * 100
        uint256 lastTotalLentAmount;
    }
    struct User {
        uint256 accumulatedReward;
        uint256 withdrawnReward;
        uint256 rewardPerTokenOffset;
        uint256 lastLentAmount;
        uint256 updatedAt;
    }
    mapping (uint256 => Profile) internal _profiles;
    // profileId => Profile data
    mapping (uint256 => uint256) internal _rewardPaid;
    // profileId => paid reward
    mapping (address => mapping (uint256 => uint256)) internal _userRewardPaid;
    // userAddress => profileId => paid reward
    mapping (address => mapping (uint256 => User)) internal _userProfiles;
    // userAddress => profileId => User data
    IERC20 internal _rewardToken;
    IBorrowingLending internal _borrowingLendingContract;
    IProxy _proxyContract;
    uint256 internal _duration;
    uint256 internal _endTime;
    uint256 internal _rewardPool;
    uint256 internal _blockTime; // in milliseconds
    uint256 internal constant SHIFT = 1 ether;
    uint256 internal constant YEAR = 365 * 24 * 3600;
    // used for exponent shifting for yieldPerToken calculation
    uint256 internal constant DECIMALS = 10000;
    // used for exponent shifting when calculation with decimals

    constructor (
        address newOwner,
        address rewardTokenAddress,
        address blContractAddress,
        address proxyContractAddress,
        uint256 duration,
        uint256 rewardPool,
        uint256 blockTime
    ) {
        require(newOwner != address(0), 'Owner address can not be zero');
        require(
            rewardTokenAddress != address(0),
            'Reward token address can not be zero'
        );
        require(
            blContractAddress != address(0),
            'Borrowing Lending contract address can not be zero'
        );
        require(
            proxyContractAddress != address(0),
            'Proxy contract address can not be zero'
        );
        require(rewardPool > 0, 'Reward pool should be greater than zero');
        require(duration > 0, 'Duration should be greater than zero');
        require(blockTime > 0, 'Block time should be greater than zero');
        addToManagers(newOwner);
        transferOwnership(newOwner);
        _rewardToken = IERC20(rewardTokenAddress);
        _borrowingLendingContract = IBorrowingLending(blContractAddress);
        _proxyContract = IProxy(proxyContractAddress);
        _blockTime = blockTime;
        _rewardPool = rewardPool;
        _duration = duration;
        _endTime = block.timestamp + duration;
        uint256 profilesNumber = _borrowingLendingContract
        .getBorrowingProfilesNumber();
        uint256 totalPercentage;
        for (uint256 i = 1; i <= profilesNumber; i ++) {
            _profiles[i].lastTimestamp = block.timestamp;
            if (i == profilesNumber) {
                _profiles[i].rewardPercentage = DECIMALS - totalPercentage;
                break;
            }
            _profiles[i].rewardPercentage = DECIMALS / profilesNumber;
            totalPercentage += _profiles[i].rewardPercentage;
        }
    }

    function withdrawReward () external returns (bool) {
        uint256 profilesNumber = _borrowingLendingContract
            .getBorrowingProfilesNumber();
        uint256 reward;
        for (uint256 i = 1; i <= profilesNumber; i ++) {
            uint256 lent = _borrowingLendingContract
                .getUserProfileLent(msg.sender, i);
            uint256 totalLent = _borrowingLendingContract
                .getTotalLent(i);
            _updateProfileReward (
                i
            );
            _updateUserProfileReward (
                msg.sender,
                i
            );
            _profiles[i].lastTotalLentAmount = totalLent;
            _userProfiles[msg.sender][i].lastLentAmount = lent;
            uint256 profileReward = _userProfiles[msg.sender][i].accumulatedReward
                - _userProfiles[msg.sender][i].withdrawnReward;
            _userProfiles[msg.sender][i].withdrawnReward
                += profileReward;
            _rewardPaid[i] += profileReward;
            _userRewardPaid[msg.sender][i] += profileReward;
            reward += profileReward;
        }
        _rewardToken.transfer(msg.sender, reward);
        return true;
    }

    // manager function
    function setBlockTime (
        uint256 blockTime
    ) external onlyManager returns (bool) {
        require(blockTime > 0, 'Block time should be greater than zero');
        _blockTime = blockTime;
        return true;
    }

    function setBorrowingContract (
        address blContractAddress
    ) external onlyManager returns (bool) {
        require(
            blContractAddress != address(0),
                'Borrowing Lending contract address can not be zero'
        );
        _borrowingLendingContract = IBorrowingLending(blContractAddress);
        return true;
    }

    function setRewardPercentage (
        uint256[] memory percentage
    ) external onlyManager returns (bool) {
        _updateTotalReward();
        uint256 totalPercentage;
        for (uint256 i; i < percentage.length; i ++) {
            _profiles[i + 1].rewardPercentage = percentage[i];
            totalPercentage += percentage[i];
        }
        require(
            totalPercentage == 10000,
            'Total percentage should be equal 10000 (100%)'
        );
        return true;
    }

    function setRewardData (
        uint256 duration,
        uint256 endTime,
        uint256 rewardPool
    ) external onlyManager returns (bool) {
        _duration = duration;
        _endTime = endTime;
        _rewardPool = rewardPool;
        return true;
    }

    function setProxyContract (
        address proxyContractAddress
    ) external onlyManager returns (bool) {
        _proxyContract = IProxy(proxyContractAddress);
        return true;
    }

    function setProfilesTotalLent () external onlyManager returns (bool) {
        uint256 profilesNumber = _borrowingLendingContract
            .getBorrowingProfilesNumber();
        for (uint256 i = 1; i <= profilesNumber; i ++) {
            uint256 totalLent = _borrowingLendingContract
                .getTotalLent(i);
            _profiles[i].lastTotalLentAmount = totalLent;
            _profiles[i].lastTimestamp = block.timestamp;
        }
        return true;
    }

    function setUserProfilesLent (
        address[] calldata userAddresses
    ) external onlyManager returns (bool) {
        uint256 profilesNumber = _borrowingLendingContract
            .getBorrowingProfilesNumber();
        for (uint256 i = 0; i < userAddresses.length; i ++) {
            for (uint256 j = 1; j <= profilesNumber; j ++) {
                uint256 lent = _borrowingLendingContract
                    .getUserProfileLent(userAddresses[i], j);
                _userProfiles[userAddresses[i]][j].lastLentAmount = lent;
                _userProfiles[userAddresses[i]][j].updatedAt = block.timestamp;
            }
        }
        return true;
    }

    // admin functions
    function adminWithdrawToken (
        uint256 amount, address tokenAddress
    ) external onlyOwner returns (bool) {
        require(tokenAddress != address(0), 'Token address can not be zero');
        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 balance = tokenContract.balanceOf(address(this));
        require(amount <= balance, 'Not enough contract balance');
        tokenContract.transfer(msg.sender, amount);
        return true;
    }

    function _updateTotalReward () internal returns (bool) {
        uint256 profilesNumber = _borrowingLendingContract
            .getBorrowingProfilesNumber();
        for (uint256 i = 1; i <= profilesNumber; i ++) {
            uint256 totalLent = _borrowingLendingContract
                .getTotalLent(i);
            _updateProfileReward(
                i
            );
            _profiles[i].lastTotalLentAmount = totalLent;
        }
        return true;
    }

    function _updateProfileReward (
        uint256 profileId
    ) internal returns (bool) {
        uint256 currentTimestamp = block.timestamp;
        if (currentTimestamp > _endTime) {
            currentTimestamp = _endTime;
        }
        if (_profiles[profileId].lastTimestamp == 0) {
            _profiles[profileId].lastTimestamp = currentTimestamp;
            return true;
        }
        if (_profiles[profileId].lastTotalLentAmount == 0) {
            _profiles[profileId].lastTimestamp = currentTimestamp;
            return true;
        }
        if (_profiles[profileId].rewardPercentage == 0) {
            _profiles[profileId].lastTimestamp = currentTimestamp;
            return true;
        }
        uint256 endTime = currentTimestamp;
        uint256 period = endTime
            - _profiles[profileId].lastTimestamp;
        if (period == 0) return true;

        uint256 profileRewardPerToken = SHIFT
            * _rewardPool
            * period
            * _profiles[profileId].rewardPercentage
            / _duration
            / DECIMALS
            / _profiles[profileId].lastTotalLentAmount;
        _profiles[profileId].rewardPerToken += profileRewardPerToken;
        _profiles[profileId].lastTimestamp = currentTimestamp;
        return true;
    }

    function _updateUserProfileReward (
        address userAddress,
        uint256 profileId
    ) internal returns (bool) {
        if (_profiles[profileId].lastTotalLentAmount == 0) {
            _userProfiles[userAddress][profileId].updatedAt =
                _profiles[profileId].lastTimestamp;
            return true;
        }
        uint256 accumulatedReward = (
            _profiles[profileId].rewardPerToken
                - _userProfiles[userAddress][profileId].rewardPerTokenOffset
        ) * _userProfiles[userAddress][profileId].lastLentAmount / SHIFT;
        _userProfiles[userAddress][profileId].accumulatedReward
            += accumulatedReward;
        _userProfiles[userAddress][profileId].rewardPerTokenOffset
            = _profiles[profileId].rewardPerToken;
        _userProfiles[userAddress][profileId].updatedAt =
            _profiles[profileId].lastTimestamp;
        return true;
    }

    function updateRewardData (
        address userAddress,
        uint256 profileId,
        uint256 lent,
        uint256 totalLent
    ) external onlyBorrowingLendingContract returns (bool) {
        _updateProfileReward (
            profileId
        );
        _updateUserProfileReward(
            userAddress,
            profileId
        );
        _profiles[profileId].lastTotalLentAmount = totalLent;
        _userProfiles[userAddress][profileId].lastLentAmount = lent;
        return true;
    }

    // view functions
    function getTokenBalance (
        address tokenAddress
    ) external view returns (uint256) {
        IERC20 tokenContract = IERC20(tokenAddress);
        return tokenContract.balanceOf(address(this));
    }

    function getRewardToken () external view returns (address) {
        return address(_rewardToken);
    }

    function getProfile (
        uint256 profileId
    ) external view returns (
        uint256 rewardPerToken,
        uint256 lastTimestamp,
        uint256 rewardPercentage,
        uint256 lastTotalLentAmount
    ) {
        return (
            _profiles[profileId].rewardPerToken,
            _profiles[profileId].lastTimestamp,
            _profiles[profileId].rewardPercentage,
            _profiles[profileId].lastTotalLentAmount
        );
    }

    function getUserProfile (
        address userAddress,
        uint256 profileId
    ) external view returns (
        uint256 accumulatedReward,
        uint256 withdrawnReward,
        uint256 rewardPerTokenOffset,
        uint256 lastLentAmount,
        uint256 updatedAt
    ) {
        return (
            _userProfiles[userAddress][profileId].accumulatedReward,
            _userProfiles[userAddress][profileId].withdrawnReward,
            _userProfiles[userAddress][profileId].rewardPerTokenOffset,
            _userProfiles[userAddress][profileId].lastLentAmount,
            _userProfiles[userAddress][profileId].updatedAt
        );
    }

    function getRewardPercentage (
        uint256 profileId
    ) external view returns (uint256) {
        return _profiles[profileId].rewardPercentage;
    }

    function getRewardData () external view returns (
        uint256 duration,
        uint256 endTime,
        uint256 rewardPool
    ) {
        return (_duration, _endTime, _rewardPool);
    }

    function getProxyContractAddress () external view returns (address) {
        return address(_proxyContract);
    }

    function getRewardPaid(
        uint256 profileId
    ) external view returns (uint256) {
        return _rewardPaid[profileId];
    }

    function getUserRewardPaid(
        address userAddress,
        uint256 profileId
    ) external view returns (uint256) {
        return _userRewardPaid[userAddress][profileId];
    }

    function calculateProfileReward (
        address userAddress,
        uint256 profileId,
        bool accumulated
    ) public view returns (uint256) {
        uint256 lent = _borrowingLendingContract
            .getUserProfileLent(userAddress, profileId);
        uint256 totalLent = _borrowingLendingContract
            .getTotalLent(profileId);
        uint256 reward = _calculateProfileReward(
            userAddress, profileId, lent, totalLent
        );
        if (accumulated) {
            reward += (
                _userProfiles[userAddress][profileId].accumulatedReward
                    - _userProfiles[userAddress][profileId].withdrawnReward
            );
        }
        return reward;
    }

    function calculateReward (
        address userAddress, bool accumulated
    ) external view returns (uint256) {
        uint256 profilesNumber = _borrowingLendingContract
            .getBorrowingProfilesNumber();
        uint256 reward;
        for (uint256 i = 1; i <= profilesNumber; i ++) {
            reward += calculateProfileReward(
                userAddress,
                i,
                accumulated
            );
        }
        return reward;
    }

    function _calculateProfileReward (
        address userAddress,
        uint256 profileId,
        uint256 lent,
        uint256 totalLent
    ) internal view returns (uint256) {
        if (_profiles[profileId].rewardPercentage == 0) return 0;
        if (lent == 0) return 0;
        uint256 extraPeriodStartTime
            = _profiles[profileId].lastTimestamp;
        if (
            extraPeriodStartTime <
                _userProfiles[userAddress][profileId].updatedAt
        ) {
            extraPeriodStartTime = _userProfiles[userAddress][profileId].updatedAt;
        }
        uint256 endTime = block.timestamp;
        if (endTime > _endTime) {
            endTime = _endTime;
        }
        uint256 extraPeriod;
        if (endTime > extraPeriodStartTime) {
            extraPeriod = endTime - extraPeriodStartTime;
        }
        uint256 rewardPerToken = _profiles[profileId].rewardPerToken;
        if (extraPeriod > 0) {
            rewardPerToken += SHIFT
                * _rewardPool
                * extraPeriod
                * _profiles[profileId].rewardPercentage
                / _duration
                / totalLent
                / DECIMALS;
        }
        uint256 reward = (
            rewardPerToken - _userProfiles[userAddress][profileId]
                .rewardPerTokenOffset
        ) * lent / SHIFT;
        return reward;
    }

    function getBlockTime() external view returns (uint256) {
        return _blockTime;
    }

    function getBorrowingContract() external view returns (address) {
        return address(_borrowingLendingContract);
    }

    function getTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    /**
     * Calculate current APR (depends on totalLent)
     * uint256 apr = DECIMALS // shift decimals point
     *    * (_rewardPool * rewardTokenUsdRate / SHIFT) // reward amount in USD
     *    * (_profiles[profileId].rewardPercentage / DECIMALS) // exact profile part
     *    / (_duration / YEAR) // duration in years
     *    / totalLent;
     */
    function getProfileApr(
        uint256 profileId
    ) external view returns (uint256) {
        uint256 rewardTokenUsdRate = _proxyContract
            .getUsdRate(address(_rewardToken));
        uint256 totalLent = _borrowingLendingContract
            .getTotalLent(profileId);
        if (totalLent == 0) return 0;
        uint256 apr = _rewardPool
            * rewardTokenUsdRate
            * _profiles[profileId].rewardPercentage
            * YEAR
            / SHIFT
            / _duration
            / totalLent;
        return apr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Access control contract,
 * functions names are self explanatory
 */
abstract contract AccessControl {
    modifier onlyOwner() {
        require(msg.sender == _owner, 'Caller is not the owner');
        _;
    }
    modifier onlyManager() {
        require(_managers[msg.sender], 'Caller is not the manager');
        _;
    }

    mapping (address => bool) private _managers;
    address private _owner;

    constructor () {
        _owner = msg.sender;
        _managers[_owner] = true;
    }

    // admin functions
    function transferOwnership(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0), 'newOwner should not be zero address');
        _owner = newOwner;
        return true;
    }

    function addToManagers (
        address userAddress
    ) public onlyOwner returns (bool) {
        _managers[userAddress] = true;
        return true;
    }

    function removeFromManagers (
        address userAddress
    ) public onlyOwner returns (bool) {
        _managers[userAddress] = false;
        return true;
    }

    /**
     * @dev If true - user has manager role
     */
    function isManager (
        address userAddress
    ) external view returns (bool) {
        return _managers[userAddress];
    }

    /**
     * @dev Owner address getter
     */
    function owner() public view returns (address) {
        return _owner;
    }
}