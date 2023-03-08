/**
 *Submitted for verification at polygonscan.com on 2023-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
    function renounceOwnership() external virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract TokenStakingTLT is Ownable, ReentrancyGuard {
    uint256 private constant _dailyUnixTime = 86400;
    uint256 private constant _monthlyUnixTime = 2629743;
    uint256 private constant _yearlyUnixTime = 31556926;

    IERC20 public tokenAddress;
    uint8 private constant _decimals = 18;
    uint256 private _totalBalanceTLT = 0;
    uint16 public annualPercentageRateAPR = 300;
    uint256 public constant claimDurationForRewards = _dailyUnixTime;
    uint256 public constant lockDurationForRewards = _monthlyUnixTime;
    uint256 public referrerCommissionTokenAmount = 100 * 10 ** _decimals; // 100TLT = 10USD at 0.10USD/TLT
    uint256 public minimumStakedTokenAmountForReferral = 500 * 10 ** _decimals; // 500TLT = 50USD at 0.10USD/TLT

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _stakedTime;
    mapping(address => uint256) private _lastClaimTime;

    event StakedTLT(address beneficiary, uint256 amount);
    event UnstakedTLT(address beneficiary, uint256 amount);
    event ReferrerCommissionSent(address, uint256);
    event ReferrerCommissionTokenAmountChanged(uint256);
    event ClaimedTLT(address beneficiary, uint256 amount);
    event MinimumStakedTokenAmountForReferralChanged(uint256);
    event AnnualPercentageRateAPRChanged(uint16, uint16);
    event TotalTLTUpdated(uint256 amount);
    event UserTLTUpdated(uint256 amount);

    modifier ifStakeExists(address beneficiary) {
        require(
            balanceOf(beneficiary) > 0,
            "TokenStakingTLT: no staked amount exists for respective beneficiary"
        );
        _;
    }

    constructor(address _tokenAddress) {
        require(
            _tokenAddress != address(0x0),
            "TokenPresaleTLT: token contract address must not be null"
        );
        tokenAddress = IERC20(_tokenAddress);
    }

    function changeReferrerCommissionTokenAmount(
        uint256 _referrerCommissionTokenAmount
    ) external onlyOwner returns (bool) {
        referrerCommissionTokenAmount = _referrerCommissionTokenAmount;

        emit ReferrerCommissionTokenAmountChanged(
            referrerCommissionTokenAmount
        );
        return true;
    }

    function changeMinimumStakedTokenAmountForReferral(
        uint256 _minimumStakedTokenAmountForReferral
    ) external onlyOwner returns (bool) {
        minimumStakedTokenAmountForReferral = _minimumStakedTokenAmountForReferral;

        emit MinimumStakedTokenAmountForReferralChanged(
            minimumStakedTokenAmountForReferral
        );
        return true;
    }

    function changeAnnualPercentageRateAPR(
        uint16 _annualPercentageRateAPR
    ) external onlyOwner returns (bool) {
        uint16 oldValue = annualPercentageRateAPR;
        annualPercentageRateAPR = _annualPercentageRateAPR;

        emit AnnualPercentageRateAPRChanged(oldValue, annualPercentageRateAPR);
        return true;
    }

    function name() external pure returns (string memory) {
        return "Staked TLT";
    }

    function symbol() external pure returns (string memory) {
        return "sTLT";
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalBalanceTLT;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stakeTokens(
        uint256 amount,
        address referrerAddress
    ) external returns (bool) {
        address from = _msgSender();
        _stakeTokens(from, amount, referrerAddress);

        emit StakedTLT(from, amount);
        emit TotalTLTUpdated(_totalBalanceTLT);
        emit UserTLTUpdated(_balances[from]);
        return true;
    }

    function _stakeTokens(
        address from,
        uint256 amount,
        address referrerAddress
    ) private {
        address to = address(this);
        _balances[from] += amount;
        _totalBalanceTLT += amount;
        _stakedTime[from] = block.timestamp;
        _lastClaimTime[from] = block.timestamp;

        require(
            tokenAddress.transferFrom(from, to, amount),
            "TokenStakingTLT: token TLT transferFrom not succeeded"
        );

        if (
            referrerAddress != address(0) &&
            referrerCommissionTokenAmount > 0 &&
            amount >= minimumStakedTokenAmountForReferral &&
            referrerCommissionTokenAmount <= totalRewardsBalanceTLT()
        ) {
            require(
                tokenAddress.transfer(
                    referrerAddress,
                    referrerCommissionTokenAmount
                ),
                "TokenStakingTLT: token TLT commission transfer not succeeded"
            );
            emit ReferrerCommissionSent(
                referrerAddress,
                referrerCommissionTokenAmount
            );
        }
    }

    function unstakeTokens() external ifStakeExists(msg.sender) nonReentrant {
        address to = _msgSender();
        uint256 amount = _balances[to];

        _unstakeTokens(to, amount);
    }

    function _unstakeTokens(address to, uint256 amount) private {
        require(
            block.timestamp >= _stakedTime[to] + lockDurationForRewards,
            "TokenStakingTLT: stake locked until lock duration completion"
        );
        _balances[to] -= amount;
        _totalBalanceTLT -= amount;
        _stakedTime[to] = 0;
        _lastClaimTime[to] = 0;

        require(
            tokenAddress.transfer(to, amount),
            "TokenStakingTLT: token TLT transfer not succeeded"
        );

        emit UnstakedTLT(to, amount);
        emit TotalTLTUpdated(_totalBalanceTLT);
        emit UserTLTUpdated(_balances[to]);
    }

    function claimRewards() external ifStakeExists(msg.sender) nonReentrant {
        address beneficiary = _msgSender();
        uint256 claimableRewards = _claimRewards(beneficiary);
        emit ClaimedTLT(beneficiary, claimableRewards);

        if (
            block.timestamp >= _stakedTime[beneficiary] + lockDurationForRewards
        ) {
            _unstakeTokens(beneficiary, _balances[beneficiary]);
        }
    }

    function _claimRewards(address beneficiary) private returns (uint256) {
        require(
            block.timestamp >=
                _lastClaimTime[beneficiary] + claimDurationForRewards,
            "TokenStakingTLT: rewards could be claimed only once every 24 hours"
        );
        uint256 claimableRewards = _viewClaimableRewards(beneficiary);

        require(
            claimableRewards <= totalRewardsBalanceTLT(),
            "TokenStakingTLT: not sufficient TLT rewards balance in reward contract"
        );
        require(
            tokenAddress.transfer(beneficiary, claimableRewards),
            "TokenStakingTLT: token TLT rewards transfer not succeeded"
        );

        _lastClaimTime[beneficiary] = block.timestamp;

        return claimableRewards;
    }

    function _viewClaimableRewards(
        address beneficiary
    ) private view returns (uint256) {
        uint256 stakedAmount = _balances[beneficiary];
        uint256 timePassed = block.timestamp - _lastClaimTime[beneficiary];
        uint256 yearlyReward = (stakedAmount * annualPercentageRateAPR) / 100;
        uint256 timePassedReward = (yearlyReward * timePassed) /
            _yearlyUnixTime;

        return timePassedReward;
    }

    function viewClaimableRewardsAndReleaseTimeAndUnlockTime(
        address beneficiary
    ) external view returns (uint256, uint256, uint256) {
        if (_stakedTime[beneficiary] == 0) {
            return (0, 0, 0);
        }

        return (
            _viewClaimableRewards(beneficiary),
            _lastClaimTime[beneficiary] + claimDurationForRewards,
            _stakedTime[beneficiary] + lockDurationForRewards
        );
    }

    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    function totalRewardsBalanceTLT() public view returns (uint256) {
        return (tokenAddress.balanceOf(address(this)) - _totalBalanceTLT);
    }
}