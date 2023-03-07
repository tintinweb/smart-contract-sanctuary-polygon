/**
 *Submitted for verification at polygonscan.com on 2023-03-06
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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

// File: contracts/2_Owner.sol



pragma solidity ^0.8.7;



// error Staking__TransferFailed();
// error Withdraw__TransferFailed();
// error Staking__NeedsMoreThanZero();

contract StakeDsync is ReentrancyGuard {
    // IERC20 public s_stakingToken;
    // IERC20 public s_rewardToken;
    IERC20 public cDsync;

    // ============================STAKE========================================
    struct aStake {
        bool initialized;
        // beneficiary of tokens after they are released
        address  beneficiary;
        // date of deposit
        uint256  depositDate;
        // amount of tokens staked
        uint256  value;
        // reward rate: number of tokens earned every day the token value is staked in the contract
        uint256  rewardRate;
        // the date when the user can start claiming rewards
        uint256  rewardStartDate;
        // the date when users can withdraw their tokens
        uint256  withdrawDate;
        // Total value of tokens claimed by user
        uint256  Claimed;
        //nonce: used to count the number of times a user has staked
        uint8  nonce;
    }

    mapping(address => uint8) public mNonces;

    mapping(bytes32 => aStake) public mStakes;
    // ============================OWNER========================================

    struct aOwner {
        address owner;
        uint8  nonce;
        uint balance;
        uint totalClaimed;
        uint totalWithdrawn;
    }

    mapping(address => aOwner) public mOwners;

    // ============================STATE========================================

    uint256 public s_totalSupply;
    uint256 public s_totalClaimed;
    uint public s_totalWithdrawn;
    /** @dev Mapping from address to the amount the user has staked */
    mapping(address => uint256) public s_balances;

    constructor(address _token) {
        cDsync = IERC20(_token);
    }

    function getIndexBytes(address _address, uint8 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address, _nonce));
    }

    function getTokenRewardDay() public pure returns (uint256) {
        //60% APR = 0.016% per day
        //this function returns the reward for 1 token per day
        return 1e18 / 10000 * 16;
    }

    function stake(uint value) external nonReentrant returns (bytes32) {
        require(value > 0, "StakeDsync: Cannot stake 0");
        require(cDsync.transferFrom(msg.sender, address(this), value), "StakeDsync: Transfer failed");

        mNonces[msg.sender] += 1;
        mOwners[msg.sender].owner = msg.sender;
        mOwners[msg.sender].nonce += 1;
        uint8 nonce = mNonces[msg.sender];
        bytes32 index = getIndexBytes(msg.sender, nonce);

        mStakes[index] = aStake({
            initialized: true,
            beneficiary: msg.sender,
            //deposited now
            depositDate: block.timestamp,
            //amount deposited
            value: value,
            //reward rate: number of tokens earned every day the token value is staked in the contract
            rewardRate: getTokenRewardDay() * (value / 1 ether), 
            //the date when the user can start claiming rewards is 4 months
            rewardStartDate: block.timestamp + (4 minutes),
            //the date when users can withdraw their tokens is 6 months
            withdrawDate: block.timestamp + (6 minutes),
            Claimed: 0,
            nonce: nonce
        });

        mOwners[msg.sender].balance += value;
        s_totalSupply += value;

        return index;
    }

    function claimReward(bytes32 index) external nonReentrant {
        require(mStakes[index].initialized, "StakeDsync: Stake not initialized");
        require(mStakes[index].beneficiary == msg.sender, "StakeDsync: Not beneficiary");
        require(block.timestamp >= mStakes[index].rewardStartDate, "StakeDsync: Reward not available yet");
        // require(cDsync.balanceOf(address(this)) >= s_totalSupply, "StakeDsync: Reward Tokens surplus error");

        uint256 reward = getUserReward(index);
        require(cDsync.transfer(msg.sender, reward), "StakeDsync: Transfer failed");
        mStakes[index].Claimed += reward;
        mOwners[msg.sender].totalClaimed += reward;
        s_totalClaimed += reward;
    }

    function getUserReward(bytes32 index) public view returns (uint256) {
        // require(mStakes[index].initialized, "StakeDsync: Stake not initialized");
        // require(mStakes[index].beneficiary == msg.sender, "StakeDsync: Not beneficiary");
        // require(block.timestamp >= mStakes[index].rewardStartDate, "StakeDsync: Reward not available yet");
        // require(cDsync.balanceOf(address(this)) >= s_totalSupply, "StakeDsync: Reward Tokens surplus error");
        uint256 reward = mStakes[index].rewardRate * ((block.timestamp - mStakes[index].depositDate) / 1 days);
        return reward;
    }

    function withdraw(bytes32 index) external nonReentrant {
        require(mStakes[index].initialized, "StakeDsync: Stake not initialized");
        require(mStakes[index].beneficiary == msg.sender, "StakeDsync: Not beneficiary");
        require(block.timestamp >= mStakes[index].withdrawDate, "StakeDsync: Withdraw not available yet");
        require(cDsync.transfer(msg.sender, mStakes[index].value), "StakeDsync: Transfer failed");
        mStakes[index].initialized = false;
        mOwners[msg.sender].balance -= mStakes[index].value;
        s_totalSupply -= mStakes[index].value;
        mOwners[msg.sender].totalWithdrawn += mStakes[index].value;
        s_totalWithdrawn += mStakes[index].value;
    }
}