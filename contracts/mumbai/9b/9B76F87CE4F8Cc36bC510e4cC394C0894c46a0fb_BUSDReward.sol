// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.16;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

// contract BUSDReward is Ownable, ReentrancyGuard {
//     /**
//      * @dev Struct contains all the details about Investors.
//      * @param walletAddress: The public address of the Investor.
//      * @param balance: The total deposited balance of the Investor
//      * @param withdrawableRewardBalance: The reward balance which can be withdrawn.
//      * @param maxReward: The max reward user will get (balance x5).
//      * @param rewardsCollected: The collected rewards.
//      * @param depositIds: The number of deposits.
//      * @param depositsData: An array which contains all the deposited transactions.
//      * @param referralAddresses: The array of addresses to whom investor refers.
//      */
//     struct InvestorMetadata {
//         address walletAddress;
//         uint256 balance;
//         uint256 withdrawableRewardBalance;
//         uint256 maxReward;
//         uint256 rewardsCollected;
//         uint256 depositIds;
//         DepositMetadata[] depositsDatas;
//         address[] referralAddresses;
//     }

//     /**
//      * @dev Struct contains all the details about deposits.
//      * @param walletAddress: The public address of the Investor.
//      * @param id: The transaction id.
//      * @param depositAmount: The amount deposited by the Investor.
//      * @param depositTime: The unix time when the first amount deposited.
//      * @param previousClaimed: The unix time of the last reward claimed.
//      * @param nextClaim: The unix time of the next reward claimed.
//      * @param rewardClaimed: The total reward claimed by the Investor.
//      */
//     struct DepositMetadata {
//         address walletAddress;
//         uint256 id;
//         uint256 depositAmount;
//         uint256 depositTime;
//         uint256 previousClaimed;
//         uint256 nextClaim;
//         uint256 rewardClaimed;
//     }

//     /**
//      * @dev Creating immutable BUSD token contract address.
//      * Meanwhile you can't change the address.
//      */
//     address immutable private _busdTokenAddress;

//     /**
//      * @dev Tracking minimum deposit token amount.
//      */
//     uint256 public minimumTokenToSent = 100 ether;

//     /**
//      * @dev Tracking the reward percentage.
//      */
//     uint256 public dailyRewardPercentage = 2;

//     /**
//      * @dev Tracking the waiting time to claim rewards.
//      * Please change this to `0` while you are testing.
//      * rest requirement is `1 days`.
//      * 
//      * `uint256 private waitingPeriod = 0` // for testing
//      * `uint256 private waitingPeriod = 1 days` // requirement.
//      */
//     uint256 private waitingPeriod = 1 days;

//     /**
//      * @dev Tracking referral reward percentage.
//      */
//     uint256 public referralRewardPercentage = 2;

//     /**
//      * @dev Mapping between Investor address to `InvestorMetadata`
//      */
//     mapping (address => InvestorMetadata) private _investorAddressToMetadata;

//     /**
//      * @dev Mapping between Investor address to boolean to track whether he is an investor.
//      */
//     mapping(address => bool) private _isInvestor;

//     /**
//      * @dev Mapping between Referee to Referrer.
//      * To give referral percentage while referee stake BUSD.
//      */
//     mapping(address => address) private _refereeToReferrer;

//     /**
//      * @dev Mapping between user to  boolean to track whether he is referred or not.
//      */
//     mapping(address => bool) private _isReferred;

//     /**
//      * @dev Modifier to check if the number is greater than zero or not
//      * @param _amount: The price which you want to check
//      */
//     modifier AmountMoreThanZero(uint256 _amount) {
//         require(_amount >0, "AmountMoreThanZero: The amount should be more than zero");
//         _;
//     }

//     /**
//      * @dev Modifier to check if the sender is an Investor
//      */
//     modifier IsInvestor() {
//         require(_isInvestor[msg.sender], "IsInvestor: You are not an Investor.");
//         _;
//     }

//     /**
//      * @dev Modifier to check if the passed address is zero address.
//      * @param _investorAddress: The investor address.
//      */
//     modifier AddressShouldNotBeZero(address _investorAddress) {
//         require(_investorAddress != address(0), "AddressShouldNotBeZero: Passed address is zero address");
//         _;
//     }

//     /**
//      * @dev Modifier to check referrer and referee address are not same.
//      * @param _referrer: The referrer account address.
//      * @param _referee: The referee account address.
//      */
//     modifier BothAddressAreNotSame(address _referrer, address _referee) {
//         require(_referrer != _referee, "BothAddressAreSame: referrer and referee cann't be same.");
//         _;
//     }

//     /**
//      * @dev Modifier to check referee whether already refered.
//      * @param _referee: The referee account address.
//      */
//     modifier NotReferred(address _referee) {
//         require(!_isReferred[_referee], "AlreadyReferred: Referee address are already referred.");
//         _;
//     }

//     /**
//      * @dev Modifier to check whether referee is already an investor ot not.
//      * @param _referee: The referee address.
//      */
//     modifier NotInvestor(address _referee) {
//         require(!_isInvestor[_referee], "AlreadyAnInvestor: Referee is already an Investor.");
//         _;
//     }

//     /**
//      * @dev Modifier to check whether msg.sender is the investor.
//      * @param _investorAddress: The investor address.
//      */
//     modifier OnlyInvestor(address _investorAddress) {
//         require(
//             _investorAddressToMetadata[_investorAddress].walletAddress == msg.sender,
//             "SenderIsNotInvestor: Sender is not the provided investor address."
//         );
//         _;
//     }

//     /**
//      * @dev Event to track minimum value changed.
//      * @param lastValue: The previous minimum value.
//      * @param newValue: The new minimum value.
//      */
//     event MinimumTokenDeposit(
//         uint256 lastValue,
//         uint256 newValue
//     );

//     /**
//      * @dev Event to track reward percentage changed.
//      * @param lastPercentage: The previous percentage.
//      * @param newPercentage: The new percentage.
//      */
//     event DailyRewardPercentageUpdated(
//         uint256 lastPercentage,
//         uint256 newPercentage
//     );

//     /**
//      * @dev Event to track referral reward percentage changed.
//      * @param lastPercentage: The previous percentage.
//      * @param newPercentage: The new percentage.
//      */
//     event ReferralRewardPercentageUpdated(
//         uint256 lastPercentage,
//         uint256 newPercentage
//     );

//     /**
//      * @dev Event to track when Investor deposited.
//      * @param walletAddress: The address of the Investor.
//      * @param amount: The amount deposited.
//      * @param time: The unix time when Investor deposited.
//      */
//     event AmountDeposited(
//         address walletAddress,
//         uint256 amount,
//         uint256 time
//     );

//     /**
//      * @dev Event to track when Investor rewards claimed.
//      * @param walletAddress: The address of the Investor.
//      * @param amount: The amount deposited.
//      * @param time: The unix time when Investor deposited.
//      */
//     event DailyRewardsClaimed(
//         address walletAddress,
//         uint256 amount,
//         uint256 time
//     );

//     /**
//      * @dev Event to track when Investor rewards withdrawn.
//      * @param walletAddress: The address of the Investor.
//      * @param amount: The amount deposited.
//      * @param time: The unix time when Investor deposited.
//      */
//     event RewardWithdrawn(
//         address walletAddress,
//         uint256 amount,
//         uint256 time
//     );

//     /**
//      * @dev Event to track when Referrer referred.
//      * @param referrer: The address who is referring.
//      * @param referee: The address to whom is referring.
//      * @param time: The unix time when Investor deposited.
//      */
//     event Referred(
//         address referrer,
//         address referee,
//         uint256 time
//     );

//     /**
//      * @dev Event to track when Investor withdrawn.
//      * @param walletAddress: The address of the Investor.
//      * @param amount: The amount withdrawn.
//      * @param time: The unix time when Investor withdrawn.
//      */
//     event AmountWithdrawn(
//         address walletAddress,
//         uint256 amount,
//         uint256 time
//     );

//     /**
//      * @dev Initilizing `_busdTokenAddress` by using constructor.
//      * @param _tokenAddress: The BUSD Token address.
//      */
//     constructor(address _tokenAddress){
//         _busdTokenAddress = _tokenAddress;
//     }

//     /**
//      * @dev Getter function to get details about Investor metadata
//      * @param _investorAddress: The investor wallet address.
//      * @return InvestorMetadata struct
//      */
//     function getInvestorMetadata(address _investorAddress) external view returns(InvestorMetadata memory){
//         return _investorAddressToMetadata[_investorAddress];
//     }

//     /**
//      * @dev Updating the `minimumTokenToSent` with new value and emit the 
//      * `MinimumTokenDeposit` event to track.
//      * @param _newMinimumValue: The new minimum value to sent.
//      */
//     function updateMinimumTokenToSent(uint256 _newMinimumValue)
//         external onlyOwner AmountMoreThanZero(_newMinimumValue) nonReentrant {
//         uint256 prevValue = minimumTokenToSent;
//         minimumTokenToSent = _newMinimumValue;

//         emit MinimumTokenDeposit(prevValue, _newMinimumValue);
//     }

//     /**
//      * @dev Updating the `dailyRewardPercentage` with new reward percentage and emit the
//      * `DailyRewardPercentageUpdated` event to track.
//      * @param _newDailyRewardPercentage: The new reward percentage.
//      */
//     function updateDailyRewardPercentage(uint256 _newDailyRewardPercentage)
//         external onlyOwner AmountMoreThanZero(_newDailyRewardPercentage) nonReentrant {
//         uint256 prevPercentage = dailyRewardPercentage;
//         dailyRewardPercentage = _newDailyRewardPercentage;

//         emit DailyRewardPercentageUpdated(prevPercentage, _newDailyRewardPercentage);
//     }

//     /**
//      * @dev Updating the `referralRewardPercentage` with the new referral percentage and emit the
//      * `` event to track.
//      * @param _newReferralRewardPercentage: The new referral reward percentage.
//      */
//     function updateReferralRewardPercentage(uint256 _newReferralRewardPercentage)
//         external onlyOwner AmountMoreThanZero(_newReferralRewardPercentage) nonReentrant {
//         uint256 prevPercentage = referralRewardPercentage;
//         referralRewardPercentage = _newReferralRewardPercentage;

//         emit ReferralRewardPercentageUpdated(prevPercentage, _newReferralRewardPercentage);
//     }

//     /**
//      * @dev Depositing BUSD Tokens into the contract. Creating a `DepositMetadata` struct and pushing
//      * into `depositsDatas`. Updating the ids, new balance, max reward.
//      * @param _tokenAmount: The amount in wei Investor wants to deposit.
//      */
//     function stake(uint256 _tokenAmount)
//         external AmountMoreThanZero(_tokenAmount) nonReentrant {
//         require(minimumTokenToSent <= _tokenAmount, "MinimumTokenToSent: You have to sent more than or equal to minimum value.");

//         IERC20(_busdTokenAddress).transferFrom(msg.sender, address(this), _tokenAmount);

//         InvestorMetadata storage investorMetadata = _investorAddressToMetadata[msg.sender];
//         investorMetadata.depositIds += 1;

//         DepositMetadata memory depositMetadata = DepositMetadata(
//             msg.sender, investorMetadata.depositIds, _tokenAmount, block.timestamp,
//             0, block.timestamp + waitingPeriod, 0
//         );

//         investorMetadata.walletAddress = msg.sender;
//         investorMetadata.balance += _tokenAmount;
//         investorMetadata.maxReward = investorMetadata.balance * 5;
//         investorMetadata.depositsDatas.push(depositMetadata);

//         _isInvestor[msg.sender] = true;

//         /** Giving percentage as a referral reward whenever referee stakes */
//         address referrer = _refereeToReferrer[msg.sender];
//         if(referrer != address(0)){
//             uint256 referralBonus = (_tokenAmount * referralRewardPercentage) / 100;
//             _investorAddressToMetadata[referrer].withdrawableRewardBalance += referralBonus;
//         }

//         emit AmountDeposited(msg.sender, _tokenAmount, block.timestamp);
//     }

//     /**
//      * @dev Claiming the reward generated by the contract. Updating the `depositMetadata` from
//      * `depositsDatas`.
//      * @param _investorAddress: The wallet address of the investor.
//      */
//     function claimDailyRewards(address _investorAddress)
//         external IsInvestor AddressShouldNotBeZero(_investorAddress) OnlyInvestor(_investorAddress)  nonReentrant {
//         InvestorMetadata storage investorMetadata = _investorAddressToMetadata[_investorAddress];
//         require(investorMetadata.balance > 0, "AccountBalanceNull: Your account balance is nil");

//         require(
//             investorMetadata.rewardsCollected != investorMetadata.maxReward,
//             "MaximumRewardsReached: You claimed all the x5 reward on your investment."
//         );

//         uint256 rewardsToSent;
//         uint256 totalTransactions = investorMetadata.depositIds;
//         int256 investorBalance = int256(investorMetadata.balance);

//         for(uint256 loopIndex = 0; loopIndex < totalTransactions; loopIndex++){
//             DepositMetadata storage depositMetadata = investorMetadata.depositsDatas[loopIndex];

//             if(depositMetadata.nextClaim <= block.timestamp && investorBalance >= int(depositMetadata.depositAmount)){
//                 uint256 rewardClaimed = (depositMetadata.depositAmount * dailyRewardPercentage) / 100;
//                 depositMetadata.previousClaimed = block.timestamp;
//                 depositMetadata.nextClaim = block.timestamp + waitingPeriod;
//                 depositMetadata.rewardClaimed += rewardClaimed;
//                 rewardsToSent += rewardClaimed;

//                 investorBalance -= int256(depositMetadata.depositAmount);
//             }else{
//                 uint256 rewardClaimed = (uint(investorBalance) * dailyRewardPercentage) / 100;
//                 depositMetadata.previousClaimed = block.timestamp;
//                 depositMetadata.nextClaim = block.timestamp + waitingPeriod;
//                 depositMetadata.rewardClaimed += rewardClaimed;
//                 rewardsToSent += rewardClaimed;
//                 break;
//             }
//         }


//         if(rewardsToSent == 0){
//             revert("NoRewardAvailable: There is no rewards to be claimed");
//         }

//         investorMetadata.withdrawableRewardBalance += rewardsToSent;
//             investorMetadata.rewardsCollected += rewardsToSent;

//         emit DailyRewardsClaimed(investorMetadata.walletAddress, rewardsToSent, block.timestamp);
//     }

//     /**
//      * @dev Withdrawing the rewards from the `withdrawableRewardBalance`. Also updating the Investor
//      * `InvestorMetadata`.
//      * @param _investorAddress: The wallet address of the investor.
//      * @param _amount: The amount Invester wants to withdraw.
//      * It should be less than equals to 50%
//      */
//     function withdrawRewards(address _investorAddress, uint256 _amount)
//         external IsInvestor AddressShouldNotBeZero(_investorAddress) AmountMoreThanZero(_amount)
//         OnlyInvestor(_investorAddress) nonReentrant {

//         InvestorMetadata storage investorMetadata = _investorAddressToMetadata[_investorAddress];

//         uint256 sevenTimesReward = (investorMetadata.balance * dailyRewardPercentage * 7) / 100;
//         uint256 halfOfRewardBalance = investorMetadata.withdrawableRewardBalance / 2;

//         require(
//             investorMetadata.withdrawableRewardBalance >= sevenTimesReward,
//             "SevenTimesReward: You can't withdraw rewards now."
//         );
//         require(
//             _amount <= halfOfRewardBalance,
//             "MoreThan50PercentAmount: You can withdraw only 50% of withdrawable reward amount."
//         );
//         investorMetadata.withdrawableRewardBalance -= _amount;

//         IERC20(_busdTokenAddress).transfer(_investorAddress, _amount);

//         emit RewardWithdrawn(_investorAddress, _amount, block.timestamp);
//     }

//     /**
//      * @dev Refer to another investor. Also updates the referrer's `referralAddress` array.
//      * Assiging `_refereeToReferrer` and mark both address as referred.
//      * @param _referrer: The referrer address who is referring.
//      * @param _referee: The referee address to whom he is referring.
//      */
//     function refer(address _referrer, address _referee)
//         external BothAddressAreNotSame(_referrer, _referee) NotReferred(_referee) NotInvestor(_referee) nonReentrant {
        
//         _investorAddressToMetadata[_referrer].referralAddresses.push(_referee);
//         _isReferred[_referrer] = true;
//         _isReferred[_referee] = true;
//         _refereeToReferrer[_referee] = _referrer;

//         emit Referred(_referrer, _referee, block.timestamp);
//     }

//     /**
//      * @dev Ustaking pricipal amount. Checking `_amount` should not be zero.
//      * @param _investorAddress: The investor address who want to withdraw.
//      * @param _amount: The BUSD amount which he wants to withdraw.
//      */

//     function unstake(address _investorAddress, uint256 _amount)
//         external nonReentrant IsInvestor OnlyInvestor(_investorAddress) AmountMoreThanZero(_amount) {
//         InvestorMetadata storage _investorMetadata = _investorAddressToMetadata[_investorAddress];

//         require(_amount <= _investorMetadata.balance, "MoreThanBalance: Amount should be less then or equals to balance.");

//         require(
//             _investorMetadata.rewardsCollected <= (_investorMetadata.balance/2),
//             "AlreadyGot50PercentReward: You already got 50% reward of your pricipal, so you can't withdraw."
//         );


//         uint256 totalWithdrawableAmount;
//         uint256 totalTnxs = _investorMetadata.depositIds;

//         for(uint256 loopIndex = 0; loopIndex < totalTnxs; loopIndex++){
//             uint256 withdrawTime = _investorMetadata.depositsDatas[loopIndex].depositTime + waitingPeriod;

//             if(block.timestamp < withdrawTime){
//                 totalWithdrawableAmount += (_investorMetadata.depositsDatas[loopIndex].depositAmount / 2);
//             }else{
//                 totalWithdrawableAmount += _investorMetadata.depositsDatas[loopIndex].depositAmount;
//             }
//         }

//         require(_amount <= totalWithdrawableAmount, "HaveToWait: You are not eligible for withdrawing some this amount. You have to wait for 1 day.");

//         _investorMetadata.balance -= _amount;
//         _investorMetadata.maxReward = _investorMetadata.balance * 5;
        
//         IERC20(_busdTokenAddress).transfer(_investorAddress, _amount);

//         emit AmountWithdrawn(_investorAddress, _amount, block.timestamp);
//     }
// }








// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/BUSDReward.sol


pragma solidity ^0.8.16;




contract BUSDReward is Ownable, ReentrancyGuard {
    /**
     * @dev Struct contains all the details about Investors.
     * @param walletAddress: The public address of the Investor.
     * @param balance: The total deposited balance of the Investor
     * @param withdrawableRewardBalance: The reward balance which can be withdrawn.
     * @param maxReward: The max reward user will get (balance x5).
     * @param rewardsCollected: The collected rewards.
     * @param depositIds: The number of deposits.
     * @param depositsData: An array which contains all the deposited transactions.
     * @param referralAddresses: The array of addresses to whom investor refers.
     */
    struct InvestorMetadata {
        address walletAddress;
        uint256 balance;
        uint256 withdrawableRewardBalance;
        uint256 maxReward;
        uint256 rewardsCollected;
        uint256 depositIds;
        DepositMetadata[] depositsDatas;
        address[] referralAddresses;
    }

    /**
     * @dev Struct contains all the details about deposits.
     * @param walletAddress: The public address of the Investor.
     * @param id: The transaction id.
     * @param depositAmount: The amount deposited by the Investor.
     * @param depositTime: The unix time when the first amount deposited.
     * @param previousClaimed: The unix time of the last reward claimed.
     * @param nextClaim: The unix time of the next reward claimed.
     * @param rewardClaimed: The total reward claimed by the Investor.
     */
    struct DepositMetadata {
        address walletAddress;
        uint256 id;
        uint256 depositAmount;
        uint256 depositTime;
        uint256 previousClaimed;
        uint256 nextClaim;
        uint256 rewardClaimed;
    }

    /**
     * @dev Creating immutable BUSD token contract address.
     * Meanwhile you can't change the address.
     */
    address immutable private _busdTokenAddress;

    /**
     * @dev Tracking minimum deposit token amount.
     */
    uint256 public minimumTokenToSent = 100 ether;

    /**
     * @dev Tracking the reward percentage.
     */
    uint256 public dailyRewardPercentage = 2;

    /**
     * @dev Tracking the waiting time to claim rewards.
     * Please change this to `0` while you are testing.
     * rest requirement is `1 days`.
     * 
     * `uint256 private waitingPeriod = 0` // for testing
     * `uint256 private waitingPeriod = 1 days` // requirement.
     */
    uint256 private waitingPeriod = 300;

    /**
     * @dev Tracking referral reward percentage.
     */
    uint256 public referralRewardPercentage = 2;

    /**
     * @dev Mapping between Investor address to `InvestorMetadata`
     */
    mapping (address => InvestorMetadata) private _investorAddressToMetadata;

    /**
     * @dev Mapping between Investor address to boolean to track whether he is an investor.
     */
    mapping(address => bool) private _isInvestor;

    /**
     * @dev Mapping between Referee to Referrer.
     * To give referral percentage while referee stake BUSD.
     */
    mapping(address => address) private _refereeToReferrer;

    /**
     * @dev Mapping between user to  boolean to track whether he is referred or not.
     */
    mapping(address => bool) private _isReferred;

    /**
     * @dev Modifier to check if the number is greater than zero or not
     * @param _amount: The price which you want to check
     */
    modifier AmountMoreThanZero(uint256 _amount) {
        require(_amount >0, "AmountMoreThanZero: The amount should be more than zero");
        _;
    }

    /**
     * @dev Modifier to check if the sender is an Investor
     */
    modifier IsInvestor() {
        require(_isInvestor[msg.sender], "IsInvestor: You are not an Investor.");
        _;
    }

    /**
     * @dev Modifier to check if the passed address is zero address.
     * @param _investorAddress: The investor address.
     */
    modifier AddressShouldNotBeZero(address _investorAddress) {
        require(_investorAddress != address(0), "AddressShouldNotBeZero: Passed address is zero address");
        _;
    }

    /**
     * @dev Modifier to check referrer and referee address are not same.
     * @param _referrer: The referrer account address.
     * @param _referee: The referee account address.
     */
    modifier BothAddressAreNotSame(address _referrer, address _referee) {
        require(_referrer != _referee, "BothAddressAreSame: referrer and referee cann't be same.");
        _;
    }

    /**
     * @dev Modifier to check referee whether already refered.
     * @param _referee: The referee account address.
     */
    modifier NotReferred(address _referee) {
        require(!_isReferred[_referee], "AlreadyReferred: Referee address are already referred.");
        _;
    }

    /**
     * @dev Modifier to check whether referee is already an investor ot not.
     * @param _referee: The referee address.
     */
    modifier NotInvestor(address _referee) {
        require(!_isInvestor[_referee], "AlreadyAnInvestor: Referee is already an Investor.");
        _;
    }

    /**
     * @dev Modifier to check whether msg.sender is the investor.
     * @param _investorAddress: The investor address.
     */
    modifier OnlyInvestor(address _investorAddress) {
        require(
            _investorAddressToMetadata[_investorAddress].walletAddress == msg.sender,
            "SenderIsNotInvestor: Sender is not the provided investor address."
        );
        _;
    }

    /**
     * @dev Event to track minimum value changed.
     * @param lastValue: The previous minimum value.
     * @param newValue: The new minimum value.
     */
    event MinimumTokenDeposit(
        uint256 lastValue,
        uint256 newValue
    );

    /**
     * @dev Event to track reward percentage changed.
     * @param lastPercentage: The previous percentage.
     * @param newPercentage: The new percentage.
     */
    event DailyRewardPercentageUpdated(
        uint256 lastPercentage,
        uint256 newPercentage
    );

    /**
     * @dev Event to track referral reward percentage changed.
     * @param lastPercentage: The previous percentage.
     * @param newPercentage: The new percentage.
     */
    event ReferralRewardPercentageUpdated(
        uint256 lastPercentage,
        uint256 newPercentage
    );

    /**
     * @dev Event to track when Investor deposited.
     * @param walletAddress: The address of the Investor.
     * @param amount: The amount deposited.
     * @param time: The unix time when Investor deposited.
     */
    event AmountDeposited(
        address walletAddress,
        uint256 amount,
        uint256 time
    );

    /**
     * @dev Event to track when Investor rewards claimed.
     * @param walletAddress: The address of the Investor.
     * @param amount: The amount deposited.
     * @param time: The unix time when Investor deposited.
     */
    event DailyRewardsClaimed(
        address walletAddress,
        uint256 amount,
        uint256 time
    );

    /**
     * @dev Event to track when Investor rewards withdrawn.
     * @param walletAddress: The address of the Investor.
     * @param amount: The amount deposited.
     * @param time: The unix time when Investor deposited.
     */
    event RewardWithdrawn(
        address walletAddress,
        uint256 amount,
        uint256 time
    );

    /**
     * @dev Event to track when Referrer referred.
     * @param referrer: The address who is referring.
     * @param referee: The address to whom is referring.
     * @param time: The unix time when Investor deposited.
     */
    event Referred(
        address referrer,
        address referee,
        uint256 time
    );

    /**
     * @dev Event to track when Investor withdrawn.
     * @param walletAddress: The address of the Investor.
     * @param amount: The amount withdrawn.
     * @param time: The unix time when Investor withdrawn.
     */
    event AmountWithdrawn(
        address walletAddress,
        uint256 amount,
        uint256 time
    );

    /**
     * @dev Initilizing `_busdTokenAddress` by using constructor.
     * @param _tokenAddress: The BUSD Token address.
     */
    constructor(address _tokenAddress){
        _busdTokenAddress = _tokenAddress;
    }

    /**
     * @dev Getter function to get details about Investor metadata
     * @param _investorAddress: The investor wallet address.
     * @return InvestorMetadata struct
     */
    function getInvestorMetadata(address _investorAddress) external view returns(InvestorMetadata memory){
        return _investorAddressToMetadata[_investorAddress];
    }

    /**
     * @dev Updating the `minimumTokenToSent` with new value and emit the 
     * `MinimumTokenDeposit` event to track.
     * @param _newMinimumValue: The new minimum value to sent.
     */
    function updateMinimumTokenToSent(uint256 _newMinimumValue)
        external onlyOwner AmountMoreThanZero(_newMinimumValue) nonReentrant {
        uint256 prevValue = minimumTokenToSent;
        minimumTokenToSent = _newMinimumValue;

        emit MinimumTokenDeposit(prevValue, _newMinimumValue);
    }

    /**
     * @dev Updating the `dailyRewardPercentage` with new reward percentage and emit the
     * `DailyRewardPercentageUpdated` event to track.
     * @param _newDailyRewardPercentage: The new reward percentage.
     */
    function updateDailyRewardPercentage(uint256 _newDailyRewardPercentage)
        external onlyOwner AmountMoreThanZero(_newDailyRewardPercentage) nonReentrant {
        uint256 prevPercentage = dailyRewardPercentage;
        dailyRewardPercentage = _newDailyRewardPercentage;

        emit DailyRewardPercentageUpdated(prevPercentage, _newDailyRewardPercentage);
    }

    /**
     * @dev Updating the `referralRewardPercentage` with the new referral percentage and emit the
     * `` event to track.
     * @param _newReferralRewardPercentage: The new referral reward percentage.
     */
    function updateReferralRewardPercentage(uint256 _newReferralRewardPercentage)
        external onlyOwner AmountMoreThanZero(_newReferralRewardPercentage) nonReentrant {
        uint256 prevPercentage = referralRewardPercentage;
        referralRewardPercentage = _newReferralRewardPercentage;

        emit ReferralRewardPercentageUpdated(prevPercentage, _newReferralRewardPercentage);
    }

    /**
     * @dev Depositing BUSD Tokens into the contract. Creating a `DepositMetadata` struct and pushing
     * into `depositsDatas`. Updating the ids, new balance, max reward.
     * @param _tokenAmount: The amount in wei Investor wants to deposit.
     */
    function stake(uint256 _tokenAmount)
        external AmountMoreThanZero(_tokenAmount) nonReentrant {
        require(minimumTokenToSent <= _tokenAmount, "MinimumTokenToSent: You have to sent more than or equal to minimum value.");

        IERC20(_busdTokenAddress).transferFrom(msg.sender, address(this), _tokenAmount);

        InvestorMetadata storage investorMetadata = _investorAddressToMetadata[msg.sender];
        investorMetadata.depositIds += 1;

        DepositMetadata memory depositMetadata = DepositMetadata(
            msg.sender, investorMetadata.depositIds, _tokenAmount, block.timestamp,
            0, block.timestamp + waitingPeriod, 0
        );

        investorMetadata.walletAddress = msg.sender;
        investorMetadata.balance += _tokenAmount;
        investorMetadata.maxReward = investorMetadata.balance * 5;
        investorMetadata.depositsDatas.push(depositMetadata);

        _isInvestor[msg.sender] = true;

        /** Giving percentage as a referral reward whenever referee stakes */
        address referrer = _refereeToReferrer[msg.sender];
        if(referrer != address(0)){
            uint256 referralBonus = (_tokenAmount * referralRewardPercentage) / 100;
            _investorAddressToMetadata[referrer].withdrawableRewardBalance += referralBonus;
        }

        emit AmountDeposited(msg.sender, _tokenAmount, block.timestamp);
    }

    /**
     * @dev Claiming the reward generated by the contract. Updating the `depositMetadata` from
     * `depositsDatas`.
     * @param _investorAddress: The wallet address of the investor.
     */
    function claimDailyRewards(address _investorAddress)
        external IsInvestor AddressShouldNotBeZero(_investorAddress) OnlyInvestor(_investorAddress)  nonReentrant {
        InvestorMetadata storage investorMetadata = _investorAddressToMetadata[_investorAddress];
        require(investorMetadata.balance > 0, "AccountBalanceNull: Your account balance is nil");

        require(
            investorMetadata.rewardsCollected != investorMetadata.maxReward,
            "MaximumRewardsReached: You claimed all the x5 reward on your investment."
        );

        uint256 rewardsToSent;
        uint256 totalTransactions = investorMetadata.depositIds;
        int256 investorBalance = int256(investorMetadata.balance);

        for(uint256 loopIndex = 0; loopIndex < totalTransactions; loopIndex++){
            DepositMetadata storage depositMetadata = investorMetadata.depositsDatas[loopIndex];

            if(depositMetadata.nextClaim <= block.timestamp && investorBalance >= int(depositMetadata.depositAmount)){
                uint256 rewardClaimed = (depositMetadata.depositAmount * dailyRewardPercentage) / 100;
                depositMetadata.previousClaimed = block.timestamp;
                depositMetadata.nextClaim = block.timestamp + waitingPeriod;
                depositMetadata.rewardClaimed += rewardClaimed;
                rewardsToSent += rewardClaimed;

                investorBalance -= int256(depositMetadata.depositAmount);
            }else{
                uint256 rewardClaimed = (uint(investorBalance) * dailyRewardPercentage) / 100;
                depositMetadata.previousClaimed = block.timestamp;
                depositMetadata.nextClaim = block.timestamp + waitingPeriod;
                depositMetadata.rewardClaimed += rewardClaimed;
                rewardsToSent += rewardClaimed;
                break;
            }
        }


        if(rewardsToSent == 0){
            revert("NoRewardAvailable: There is no rewards to be claimed");
        }

        investorMetadata.withdrawableRewardBalance += rewardsToSent;
            investorMetadata.rewardsCollected += rewardsToSent;

        emit DailyRewardsClaimed(investorMetadata.walletAddress, rewardsToSent, block.timestamp);
    }

    /**
     * @dev Withdrawing the rewards from the `withdrawableRewardBalance`. Also updating the Investor
     * `InvestorMetadata`.
     * @param _investorAddress: The wallet address of the investor.
     * @param _amount: The amount Invester wants to withdraw.
     * It should be less than equals to 50%
     */
    function withdrawRewards(address _investorAddress, uint256 _amount)
        external IsInvestor AddressShouldNotBeZero(_investorAddress) AmountMoreThanZero(_amount)
        OnlyInvestor(_investorAddress) nonReentrant {

        InvestorMetadata storage investorMetadata = _investorAddressToMetadata[_investorAddress];

        uint256 sevenTimesReward = (investorMetadata.balance * dailyRewardPercentage * 7) / 100;
        uint256 halfOfRewardBalance = investorMetadata.withdrawableRewardBalance / 2;

        require(
            investorMetadata.withdrawableRewardBalance >= sevenTimesReward,
            "SevenTimesReward: You can't withdraw rewards now."
        );
        require(
            _amount <= halfOfRewardBalance,
            "MoreThan50PercentAmount: You can withdraw only 50% of withdrawable reward amount."
        );
        investorMetadata.withdrawableRewardBalance -= _amount;

        IERC20(_busdTokenAddress).transfer(_investorAddress, _amount);

        emit RewardWithdrawn(_investorAddress, _amount, block.timestamp);
    }

    /**
     * @dev Refer to another investor. Also updates the referrer's `referralAddress` array.
     * Assiging `_refereeToReferrer` and mark both address as referred.
     * @param _referrer: The referrer address who is referring.
     * @param _referee: The referee address to whom he is referring.
     */
    function refer(address _referrer, address _referee)
        external BothAddressAreNotSame(_referrer, _referee) NotReferred(_referee) NotInvestor(_referee) nonReentrant {
        
        _investorAddressToMetadata[_referrer].referralAddresses.push(_referee);
        _isReferred[_referrer] = true;
        _isReferred[_referee] = true;
        _refereeToReferrer[_referee] = _referrer;

        emit Referred(_referrer, _referee, block.timestamp);
    }

    /**
     * @dev Ustaking pricipal amount. Checking `_amount` should not be zero.
     * @param _investorAddress: The investor address who want to withdraw.
     * @param _amount: The BUSD amount which he wants to withdraw.
     */

    function unstake(address _investorAddress, uint256 _amount)
        external nonReentrant IsInvestor OnlyInvestor(_investorAddress) AmountMoreThanZero(_amount) {
        InvestorMetadata storage _investorMetadata = _investorAddressToMetadata[_investorAddress];

        require(_amount <= _investorMetadata.balance, "MoreThanBalance: Amount should be less then or equals to balance.");

        require(
            _investorMetadata.rewardsCollected <= (_investorMetadata.balance/2),
            "AlreadyGot50PercentReward: You already got 50% reward of your pricipal, so you can't withdraw."
        );


        uint256 totalWithdrawableAmount;
        uint256 totalTnxs = _investorMetadata.depositIds;

        for(uint256 loopIndex = 0; loopIndex < totalTnxs; loopIndex++){
            uint256 withdrawTime = _investorMetadata.depositsDatas[loopIndex].depositTime + waitingPeriod;

            if(block.timestamp < withdrawTime){
                totalWithdrawableAmount += (_investorMetadata.depositsDatas[loopIndex].depositAmount / 2);
            }else{
                totalWithdrawableAmount += _investorMetadata.depositsDatas[loopIndex].depositAmount;
            }
        }

        require(_amount <= totalWithdrawableAmount, "HaveToWait: You are not eligible for withdrawing some this amount. You have to wait for 1 day.");

        _investorMetadata.balance -= _amount;
        _investorMetadata.maxReward = _investorMetadata.balance * 5;
        
        IERC20(_busdTokenAddress).transfer(_investorAddress, _amount);

        emit AmountWithdrawn(_investorAddress, _amount, block.timestamp);
    }
}