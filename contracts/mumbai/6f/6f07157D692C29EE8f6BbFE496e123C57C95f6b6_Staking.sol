/**
 *Submitted for verification at polygonscan.com on 2022-12-13
*/

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

// File: contracts/StakingPeriods.sol



pragma solidity ^0.8.7;


contract Staking is ReentrancyGuard{
    IERC20 public immutable token;
    address public owner;
    bool started;
    uint public EARLY_WITHDRAWAL_FEE = 10000000000000000;



    struct Position {
        uint positionId;
        address walletAddress;
        uint createDate;
        uint unlockDate;
        uint percentInterest;
        uint amountStaked;
        uint amountInterest;
        bool open;
    }
    Position position;
    uint public currentPositionId;
    mapping(uint => Position) public positions;
    mapping(address => uint[]) public positionIdsByAddress;
    mapping(uint => uint) public tiers;
    uint[] public lockPeriods;
    uint public RewardsTotal;
    uint public TotalRewardsToDistribute;
    constructor(address _token, uint _rewardsTotal) {
        owner = msg.sender;
        token = IERC20(_token);
        RewardsTotal = _rewardsTotal;
        currentPositionId = 0;
        TotalRewardsToDistribute=0;
        tiers[30] = 700;
        tiers[90] = 1000;
        tiers[120] = 1200;

        lockPeriods.push(30);
        lockPeriods.push(90);
        lockPeriods.push(120);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
    modifier active(){
        require(started==true,"Staking pool is not active");
        _;
    }

    function StartStakingPool() onlyOwner external{
        require(started==false,"Period Already started");
        require(getBalance()==RewardsTotal);
        started=true;
    }
    function addFunds(uint amount) onlyOwner external{
        require(amount > 0, "Amount cannot be zero");
        token.transferFrom(msg.sender,address(this),amount);
        RewardsTotal += amount;
    }

    function getBalance() internal returns(uint) {
        return token.balanceOf(address(this));
    } 

    function stake(uint _amount, uint numDays) nonReentrant active external{

        require(tiers[numDays] > 0, "Tier not found");
        uint interest = calculateInterest(tiers[numDays], _amount);
        require(TotalRewardsToDistribute + interest  <= RewardsTotal,"Insufficient reward token for this position");

        token.transferFrom(msg.sender, address(this),_amount);

        positions[currentPositionId] = Position(
            currentPositionId,
            msg.sender,
            block.timestamp,
            block.timestamp + (numDays * 1 days),
            tiers[numDays],
            _amount,
            interest,
            true   
        );

        positionIdsByAddress[msg.sender].push(currentPositionId);
        TotalRewardsToDistribute += interest;
        currentPositionId += 1;
    }

    function calculateInterest(uint basisPoint, uint _amount) internal pure returns(uint){
        return (basisPoint / 10000) * _amount;
    }

    function modifyLockPeriods(uint numDays, uint basisPoints) onlyOwner external {

        tiers[numDays] = basisPoints;
        lockPeriods.push(numDays);
    }

    function getLockPeriods() external view returns(uint[] memory){
        return lockPeriods;
    }

    function getInterestRate(uint numDays) external view returns(uint){
        return tiers[numDays];
    }

    function getPositionById(uint positionId) external view returns(Position memory){
        return positions[positionId];
    }

        function getPositionIdsForAddress(address _account) external view returns(uint[] memory){
            return positionIdsByAddress[_account];
    }

    function changeUnlockDate(uint positionId, uint newUnlockDate) onlyOwner external {
        positions[positionId].unlockDate = newUnlockDate;
    }

    function closePosition(uint positionId) active nonReentrant external {
        require(positions[positionId].walletAddress == msg.sender, "Only staker may modifiy position");
        require(positions[positionId].open == true, "Position is already closed");

        if(block.timestamp > positions[positionId].unlockDate){
            uint amount = positions[positionId].amountStaked + positions[positionId].amountInterest;
            RewardsTotal -= positions[positionId].amountInterest;
            TotalRewardsToDistribute -= positions[positionId].amountInterest;
            token.transfer(msg.sender, amount);
        } else {
            TotalRewardsToDistribute -= positions[positionId].amountInterest;
            token.transfer(msg.sender, (positions[positionId].amountStaked - EARLY_WITHDRAWAL_FEE));
        }
    }

    function _validateBeforeStake() internal{

    }


}