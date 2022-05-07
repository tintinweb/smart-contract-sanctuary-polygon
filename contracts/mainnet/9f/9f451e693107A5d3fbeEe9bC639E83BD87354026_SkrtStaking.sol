/**
 *Submitted for verification at polygonscan.com on 2022-05-07
*/

// SPDX-License-Identifier: MIT

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

// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


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
abstract contract Ownable is Pausable {
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

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

pragma solidity 0.8.12;

interface ISkrtAddressVerification {

    /**
     * @dev call to verify wallet address.
     */
    function checkAddress(address _address) external view returns (bool);
}

pragma solidity 0.8.12;


contract SkrtStaking is Ownable {

    struct StakedTokensTimeline {
        uint256 timestamp;
        uint256 amount;
    }

    struct StakingParameters {
        uint256 stakingPoolSize;
        uint256 minimumStakingAmount;
        uint256 maximumStakingAmount;
        uint256 stakingPeriodSeconds;
    }

    struct StakingPenalties {
        uint256 threeMonthsUnStakePenalty;
        uint256 sixMonthsUnStakePenalty;
    }

    struct RewardPercentage {
        uint256 annualMintPercentage;
        uint256 annualAdopterMintPercentage;
        uint256 annualInsiderMintPercentage;
        uint256 annualEvangelistMintPercentage;
        uint256 annualPartnerMintPercentage;
    }

    IERC20 public token;
    ISkrtAddressVerification public skrtAddressVerification;
    RewardPercentage public rewardPercentage;
    StakingPenalties public stakingPenalties;
    StakingParameters public stakingParameters;
    address public skrtVerificationAddress;
    address public tokenAddress;
    address public rewardsAddress;
    uint256 public totalStakedTokens;
    uint256 public totalClaimedRewards;
    uint256 public withdrawStartSeconds;
    uint256 public unStakeStartSeconds;
    uint256 public numberOfStakers;
    bool public verifyAddress;

    mapping(address => uint256) public stakeBalance;
    mapping(address => uint256) public lastStakeClaimed;
    StakedTokensTimeline[] public stakingTimeline;

    event Stake(
        uint256 indexed _stakeTimestamp,
        address indexed _whom,
        uint256 _amount
    );

    event StakeClaimed(
        uint256 indexed _stakeClaimedTimestamp,
        address indexed _whom,
        uint256 _amount
    );

    event UnStake(
        uint256 indexed _unstakeTimestamp,
        address indexed _whom,
        uint256 _amount,
        uint256 _rewards
    );

    event Withdraw(
        uint256 indexed _withdrawTimestamp,
        address indexed _whom,
        uint256 _amount
    );

    event TotalStakedTokens(
        uint256 indexed _timestamp,
        uint256 _amount
    );

    constructor(address _tokenAddress, address _skrtVerificationAddress, address _rewardsAddress, StakingParameters memory _stakingParameters, StakingPenalties memory _stakingPenalties, RewardPercentage memory _rewardPercentage, 
                uint256 _unStakeStartSeconds, uint256 _withdrawStartSeconds) {
        token = IERC20(_tokenAddress);
        tokenAddress = _tokenAddress;
        skrtAddressVerification = ISkrtAddressVerification(_skrtVerificationAddress);
        skrtVerificationAddress = _skrtVerificationAddress;
        rewardsAddress = _rewardsAddress;
        stakingParameters = _stakingParameters;
        stakingPenalties = _stakingPenalties;
        rewardPercentage = _rewardPercentage;
        unStakeStartSeconds = _unStakeStartSeconds;
        withdrawStartSeconds = _withdrawStartSeconds;
        verifyAddress = true;
        numberOfStakers = 0;
    }

    /**
    * @dev stake token
    **/
    function stake(uint256 _amount)
    _correctStakingAmount(_amount)
    whenNotPaused
    external 
    returns (bool) {        
        if (verifyAddress) {
            require(skrtAddressVerification.checkAddress(msg.sender), "Wallet Address not verified by Sekuritance. Please verify your wallet address");
        }

        uint256 _stakeReward = 0;
        if (lastStakeClaimed[msg.sender] == 0) {
            //first time staking.
            require((_amount + totalStakedTokens) <= stakingParameters.stakingPoolSize, "Staking Pool Limit reached");
            lastStakeClaimed[msg.sender] = block.timestamp;
            numberOfStakers = numberOfStakers + 1;
        } else {
            //user already staked - so make sure we add up the accrued rewards
            _stakeReward = _calculateStakeRewards(msg.sender);
            require((_amount + _stakeReward + totalStakedTokens) <= stakingParameters.stakingPoolSize, "Staking Pool Limit reached");
            lastStakeClaimed[msg.sender] = block.timestamp;
            stakeBalance[msg.sender] = stakeBalance[msg.sender] + _stakeReward;
        }

        //add the new amount to stake plus any accrued rewards to the totalStakedTokens bucket.
        totalStakedTokens = totalStakedTokens +  _amount + _stakeReward;
        stakingTimeline.push(StakedTokensTimeline(block.timestamp, totalStakedTokens));
        stakeBalance[msg.sender] = stakeBalance[msg.sender] + _amount;

        //transfer tokens to this contract
        require(token.transferFrom(msg.sender, address(this), _amount), "[Deposit] Something went wrong while transferring your deposit");

        emit Stake(block.timestamp, msg.sender, _amount);
        emit TotalStakedTokens(block.timestamp, totalStakedTokens);
        return true;
    }

    /**
     * @dev unstake token
     **/
    function unStake()
    whenNotPaused
    external 
    returns (bool){
        require(lastStakeClaimed[msg.sender] != 0, "[UnStake] No tokens to unstake");
        uint256 totalStakeSeconds = (block.timestamp - lastStakeClaimed[msg.sender]);
        require(totalStakeSeconds >= unStakeStartSeconds, "[UnStake] Cannot unstake tokens too early");

        //check for early unstake
        uint256 _stakeReward = _calculateStakeRewards(msg.sender);
        uint256 percentagePenalty = _checkForUnStakePenalties(totalStakeSeconds, _stakeReward);
        if (percentagePenalty > 0) {
            //give only such percentage in rewards!
             _stakeReward = (_stakeReward  / 100) * percentagePenalty;
        }
        
        //get user staked balance
        uint256 userTokenBalance = stakeBalance[msg.sender];

        totalStakedTokens = totalStakedTokens - userTokenBalance;
        stakingTimeline.push(StakedTokensTimeline(block.timestamp, totalStakedTokens));
        stakeBalance[msg.sender] = 0;
        lastStakeClaimed[msg.sender] = 0;
        numberOfStakers = numberOfStakers - 1;

        //transfer tokens 
        require(token.transfer(msg.sender, userTokenBalance), "[UnStake] Something went wrong while transferring your initial deposit");

        if (_stakeReward > 0) {
            //transfer rewards tokens 
            require(token.transferFrom(rewardsAddress, msg.sender, _stakeReward), "[UnStake] Something went wrong while transferring your reward");
        }

        emit UnStake(block.timestamp, msg.sender, userTokenBalance, _stakeReward);
        emit TotalStakedTokens(block.timestamp, totalStakedTokens);

        return true;
    }

    /**
     * @dev withdraw token
     **/
    function withdraw() 
    whenNotPaused
    external 
    returns (bool){
        require(lastStakeClaimed[msg.sender] != 0, "[Withdraw] No tokens staked");
        uint256 totalStakeSeconds = (block.timestamp - lastStakeClaimed[msg.sender]);
        require(totalStakeSeconds >= withdrawStartSeconds, "[Withdraw] Cannot withdraw tokens too early");

        uint256 userTokenBalance = stakeBalance[msg.sender];
        require(userTokenBalance > 0, "[Withdraw] Nothing to withdraw");

        stakeBalance[msg.sender] = 0;
        lastStakeClaimed[msg.sender] = 0;
        totalStakedTokens = totalStakedTokens - userTokenBalance;
        stakingTimeline.push(StakedTokensTimeline(block.timestamp, totalStakedTokens));
        numberOfStakers = numberOfStakers - 1;

        //transfer tokens
        require(token.transfer(msg.sender, userTokenBalance), "[Withdraw] Something went wrong while transferring your tokens");

        emit Withdraw(block.timestamp, msg.sender, userTokenBalance);
        emit TotalStakedTokens(block.timestamp, totalStakedTokens);

        return true;
    }

    /**
     * @dev withdraw tokens by owner
     **/
    function withdrawTokens(uint256 _amount) 
    whenPaused
    external 
    onlyOwner() 
    returns (bool) {
        require(_amount <= totalStakedTokens, "[Withdraw] Amount is invalid");
        require(token.transfer(msg.sender, _amount), "[Withdraw] Something went wrong while transferring your tokens");
        return true;
    }

    /**
     * @dev transfer tokens to contract
     **/
    function transferTokens(uint256 _amount) 
    whenPaused
    external onlyOwner() 
    returns (bool) {
        require(token.transferFrom(msg.sender, address(this), _amount), "[Transfer] Something went wrong while transferring tokens");
        return true;
    }

    /**
     * @dev calculate daily basis stake amount
     **/
    function _calculateStakeRewards(address _whom) internal view returns (uint256) {
        uint256 _lastRound = lastStakeClaimed[_whom];
        uint256 totalStakeDays = (block.timestamp - _lastRound) / 86400;
        uint256 userTokenBalance = stakeBalance[_whom];
        if (totalStakeDays > 0) {
            uint256 rewardAnnualPercentage = determineRewardPercentage(userTokenBalance);
            require(rewardAnnualPercentage > 0, "Failed to calculate stake rewards");
            return (userTokenBalance * rewardAnnualPercentage * totalStakeDays) / 3650000;
        }

        return 0;
    }

    /**
     * @dev calculate reward percentage based on staked amount
     **/
    function determineRewardPercentage(uint256 _userTokenBalance) internal view returns (uint256) {
        if (_userTokenBalance < 50000000000000000000000) {
            return rewardPercentage.annualMintPercentage;
        } else if (_userTokenBalance >= 50000000000000000000000 && _userTokenBalance < 500000000000000000000000) {
            return rewardPercentage.annualAdopterMintPercentage;
        } else if (_userTokenBalance >= 500000000000000000000000 && _userTokenBalance < 1500000000000000000000000) {
            return rewardPercentage.annualInsiderMintPercentage;
        } else if (_userTokenBalance >= 1500000000000000000000000 && _userTokenBalance < 3000000000000000000000000) {
            return rewardPercentage.annualEvangelistMintPercentage;
        } else if (_userTokenBalance >= 3000000000000000000000000) {
            return rewardPercentage.annualPartnerMintPercentage;
        }

        return 0;
    }

    /**
     * @dev show stake balance and rewards
     **/
    function balanceOf(address _whom) external view returns (uint256) {
        uint256 _stakeReward = _calculateStakeRewards(_whom);
        return stakeBalance[_whom] + _stakeReward;
    }

    /**
     * @dev show rewards only
     **/
    function getOnlyRewards(address _whom) external view returns (uint256) {
        return _calculateStakeRewards(_whom);
    }

    /**
     * @dev get staking timeline 
     **/
    function getStakingTimeline() external view returns (StakedTokensTimeline[] memory) {
        return stakingTimeline;
    }

    /**
     * @dev get staking timeline length
     **/
    function getStakingTimelineLength() external view returns (uint256) {
        return stakingTimeline.length;
    }

    /**
     * @dev get staking timeline item
     **/
    function getStakingTimelineItem(uint256 index) public view returns(uint256, uint256) {
        return (stakingTimeline[index].timestamp, stakingTimeline[index].amount);
    }

    /**
     * @dev claim only rewards
     **/
    function claimRewards() 
    whenNotPaused
    external 
    returns (bool) {
        require(lastStakeClaimed[msg.sender] != 0, "[Claim] No tokens staked");
        uint256 totalStakeSeconds = (block.timestamp - lastStakeClaimed[msg.sender]);
        require(totalStakeSeconds >= unStakeStartSeconds, "[Claim] Cannot claim tokens too early");

        uint256 _stakeReward = _calculateStakeRewards(msg.sender);
        uint256 percentagePenalty = _checkForUnStakePenalties(totalStakeSeconds, _stakeReward);
        if (percentagePenalty > 0) {
            //give only such percentage in rewards!
            _stakeReward = (_stakeReward  / 100) * percentagePenalty;
        }

        lastStakeClaimed[msg.sender] = block.timestamp;
        totalClaimedRewards = totalClaimedRewards + _stakeReward;

        //transfer tokens
        require(token.transferFrom(rewardsAddress, msg.sender, _stakeReward), "[Claim] Something went wrong while transferring your reward");

        emit StakeClaimed(block.timestamp, msg.sender, _stakeReward);
        return true;
    }

    /**
     * @dev claim only rewards and restake
     **/
    function claimRewardsAndStake() 
    whenNotPaused
    external 
    returns (bool) {
        require(lastStakeClaimed[msg.sender] != 0, "[Withdraw] No tokens staked");
        uint256 _stakeReward = _calculateStakeRewards(msg.sender);
        //check that claim and restake is allowed due to pool size
        require((totalStakedTokens  + _stakeReward) <= stakingParameters.stakingPoolSize, "Staking Pool Limit reached, failed to restake");

        lastStakeClaimed[msg.sender] = block.timestamp;
        stakeBalance[msg.sender] = stakeBalance[msg.sender] + _stakeReward;
        totalStakedTokens = totalStakedTokens + _stakeReward;
        stakingTimeline.push(StakedTokensTimeline(block.timestamp, totalStakedTokens));
        totalClaimedRewards = totalClaimedRewards + _stakeReward;

        emit StakeClaimed(block.timestamp, msg.sender, _stakeReward);
        emit Stake(block.timestamp, msg.sender, stakeBalance[msg.sender]);
        emit TotalStakedTokens(block.timestamp, totalStakedTokens);

        return true;
    }

    /**
     * @dev reset wallet address staking balance
     **/ 
    function resetStakingBalance(address _address) 
    whenPaused
    external onlyOwner() 
    returns (bool) {
        totalStakedTokens = totalStakedTokens - stakeBalance[_address];
        stakingTimeline.push(StakedTokensTimeline(block.timestamp, totalStakedTokens));
        stakeBalance[_address] = 0;

        emit TotalStakedTokens(block.timestamp, totalStakedTokens);

        return true;
    }

    /**
     * @dev set staking parameters
     **/
    function setStakingParameters(StakingParameters memory _stakingParameters) 
    whenPaused
    external onlyOwner() 
    returns (bool) {
        stakingParameters = _stakingParameters;
        return true;
    }

    /**
     * @dev set staking penalties
     **/
    function setStakingPenalties(StakingPenalties memory _stakingPenalties) 
    whenPaused
    external onlyOwner() 
    returns (bool) {
        stakingPenalties = _stakingPenalties;
        return true;
    }

    /**
     * @dev set reward percentage
     **/
    function setRewardPercentage(RewardPercentage memory _rewardPercentage) 
    whenPaused
    external onlyOwner() 
    returns (bool) {
        rewardPercentage = _rewardPercentage;
        return true;
    }

    /**
     * @dev set the rewards wallet address
     **/ 
    function setRewardsAddress(address _rewardsAddress) 
    whenPaused
    external onlyOwner() 
    returns (bool) {
        rewardsAddress = _rewardsAddress;
        return true;
    }

    /**
     * @dev set the unstake start in seconds
     **/ 
    function setUnStakeStartSeconds(uint256 _unStakeStartSeconds) 
    whenPaused
    external onlyOwner() 
    returns (bool) {
        unStakeStartSeconds = _unStakeStartSeconds;
        return true;
    }

    /**
     * @dev set the withdraw start in seconds
     **/ 
    function setWithdrawStartSeconds(uint256 _withdrawStartSeconds) 
    whenPaused
    external onlyOwner() 
    returns (bool) {
        withdrawStartSeconds = _withdrawStartSeconds;
        return true;
    }


    /**
     * @dev set the token address
     **/ 
    function setTokenAddress(address _tokenAddress) 
    whenPaused
    external onlyOwner() 
    returns (bool) {
        require(_tokenAddress != address(0),"[Validation] Invalid token address");
        token = IERC20(_tokenAddress);
        tokenAddress = _tokenAddress;
        return true;
    }

    /**
     * @dev set the skrt verification contract address
     **/ 
    function setSkrtVerificationAddress(address _address) 
    whenPaused
    external onlyOwner() 
    returns (bool) {
        require(_address != address(0),"[Validation] Invalid token address");
        skrtAddressVerification = ISkrtAddressVerification(_address);
        skrtVerificationAddress = _address;
        return true;
    }

    /**
     * @dev enable/disable address verification
     **/ 
    function setVerifyAddress(bool _verifyAddress) 
    whenPaused
    external onlyOwner() 
    returns (bool) {
        verifyAddress = _verifyAddress;
        return true;
    }

    /**
     * @dev pause contract
     **/ 
    function pause()
    external onlyOwner() {
        _pause();
    }

    /**
     * @dev unpause contract
     **/ 
    function unpause()
    external onlyOwner() {
        _unpause();
    }

    /**
     * @dev check the staking amount limit
     **/ 
    modifier _correctStakingAmount(uint256 amount) {
        require(amount >= stakingParameters.minimumStakingAmount && amount <= stakingParameters.maximumStakingAmount, "Staking amount is invalid");
        _;
    }

    /**
     * @dev checks for any penalties and returns the percentage to deduct from the rewards if any otherwise 0
     **/
    function _checkForUnStakePenalties(uint256 _totalStakeSeconds, uint256 _stakeReward) internal view returns (uint256) {
        if (_stakeReward == 0) {return 0;}

        if (_totalStakeSeconds <= 15780000) {
            //first 6 months
            return stakingPenalties.threeMonthsUnStakePenalty;
        } else if (_totalStakeSeconds > 15780000 && _totalStakeSeconds < stakingParameters.stakingPeriodSeconds) {
            //between 6 - 12 months
            return stakingPenalties.sixMonthsUnStakePenalty;
        } else {
            return 0;
        }
    }

}