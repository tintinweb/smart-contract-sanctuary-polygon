/**
 *Submitted for verification at polygonscan.com on 2023-03-08
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

// File: Precious Capital/StakingToken.sol


pragma solidity >=0.7.0 <0.9.0;




/**
 * @dev Contract for Staking ERC-20 Tokens and pay interest on real time
 */
contract StakeContract is Ownable, ReentrancyGuard {
    
    // the token to be used for staking
    address public token;

    // Annual Percentage Yield
    uint256 public APY;

    // minimum stake time in seconds, if the user withdraws before this time a penalty will be charged
    uint256 public minimumStakeTime;

    // minimum withdraw time in seconds for next allow claim rewards
    uint256 public minimumWithdrawTime;

    // the Stake
    struct Stake {
        // opening timestamp
        uint256 startDate;
        // amount staked
    	uint256 amount;
        // last withdraw date of only rewards
        uint256 lastWithdrawDate;
        // is active or not
    	bool active;
    }

    // stakes that the owner have    
    mapping(address => Stake[50]) public stakesOf;

    event Set_TokenContracts(
        address token
    );

    event Set_APY(
        uint256 APY
    );

    event Set_MST(
        uint256 MST
    );

    event Set_MWT(
        uint256 MWT
    );

    event AddedStake(
        uint256 startDate,
        uint256 amount,
        address indexed ownerStake
    );

    event WithdrawStake(
        uint256 withdrawType,
        uint256 startDate,
        uint256 withdrawDate,
        uint256 interest,
        uint256 amount,
        address indexed ownerStake
    );
    
    // @_token: the ERC20 token to be used
    // @param _apy: Annual Percentage Yield
    // @param _mst: minimum stake time in seconds
    // @param _mwt: minimum withdraw time in seconds for next allow claim rewards
    constructor(address _token ,uint256 _apy, uint256 _mst, uint256 _mwt) {
        setTokenContracts(_token);
        modifyAnnualInterestRatePercentage(_apy);
        modifyMinimumStakeTime(_mst);
        modifyMinimumWithdrawTime(_mwt);
    }
    
    function setTokenContracts(address _token) public onlyOwner {
        token = _token;
        emit Set_TokenContracts(_token);
    }
    function modifyAnnualInterestRatePercentage(uint256 _newVal) public onlyOwner {
        APY = _newVal;
        emit Set_APY(_newVal);
    }
    function modifyMinimumStakeTime(uint256 _newVal) public onlyOwner {
        minimumStakeTime = _newVal;
        emit Set_MST(_newVal);
    }
    function modifyMinimumWithdrawTime(uint256 _newVal) public onlyOwner {
        minimumWithdrawTime = _newVal;
        emit Set_MWT(_newVal);
    }

    function calculateInterest(address _ownerAccount, uint256 i) private view returns (uint256) {

        // APY per year = amount * APY / 100 / seconds of the year
        uint256 interest_per_year = (stakesOf[_ownerAccount][i].amount*APY)/100;

        // number of seconds since opening date
        uint256 num_seconds = block.timestamp-stakesOf[_ownerAccount][i].lastWithdrawDate;

        // calculate interest by a rule of three
        //  seconds of the year: 31536000 = 365*24*60*60
        //  interest_per_year   -   31536000
        //  interest            -   num_seconds
        //  interest = num_seconds * interest_per_year / 31536000
        return (num_seconds*interest_per_year)/31536000;
    }

    function getIndexToCreateStake(address _account) private view returns (uint256) {
        uint256 index = 50;
        for(uint256 i=0; i<stakesOf[_account].length; i++){
            if(!stakesOf[_account][i].active){
                index = i;
            }
        }
        // if (index < 50)  = limit not reached
        // if (index == 50) = limit reached
        return index; 
    }
    
    // anyone can create a stake
    function createStake(uint256 amount) external {
        uint256 index = getIndexToCreateStake(msg.sender);
        require(index < 50, "stakes limit reached");
        // store the tokens of the user in the contract
        // requires approve
		uint balance = IERC20(token).balanceOf(msg.sender);
        require(balance >= amount,"Not Enought Funds");
        require(IERC20(token).transferFrom(msg.sender, address(this), amount),"Transaction Fail");
        // create the stake
        stakesOf[msg.sender][index] = Stake(block.timestamp, amount, block.timestamp, true);

        emit AddedStake(block.timestamp, amount, msg.sender);
    }

    // _arrayIndex: is the id of the stake to be finalized
    function withdrawStake(uint256 _arrayIndex, uint256 _withdrawType) external nonReentrant { // _withdrawType (1=normal withdraw, 2=withdraw only rewards)
        require(_withdrawType>=1 && _withdrawType<=2, "invalid _withdrawType");
        // Stake should exists and opened
        require(_arrayIndex < stakesOf[msg.sender].length, "Stake does not exist");
        Stake memory stk = stakesOf[msg.sender][_arrayIndex];
        require(stk.active, "This stake is not active");

        // get interest
        uint256 interest = calculateInterest(msg.sender, _arrayIndex);
        if(_withdrawType == 1){
            require((block.timestamp - stk.startDate) >= minimumStakeTime, "the minimum stake time has not been completed yet");
            require(IERC20(token).transfer(msg.sender, stk.amount),"Transaction Fail!");
            require(IERC20(token).transferFrom(owner(), msg.sender, interest),"Transaction Fail!");
            // stake closing
            delete stakesOf[msg.sender][_arrayIndex];
        }else{
            require((block.timestamp - stk.lastWithdrawDate) >= minimumWithdrawTime, "the minimum withdraw time has not been completed yet");
            // record the transaction
            stakesOf[msg.sender][_arrayIndex].lastWithdrawDate = block.timestamp;
            IERC20(token).transferFrom(owner(), msg.sender, interest);
        }
        
        // pay interest and rewards
        emit WithdrawStake(_withdrawType, stk.startDate, block.timestamp, interest, stk.amount, msg.sender);
    }

    function getStakesOf(address _account) external view returns(uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, bool[] memory){
        uint256 stakesLength = stakesOf[_account].length;
        uint256[] memory startDateList = new uint256[](stakesLength);
        uint256[] memory amountList = new uint256[](stakesLength);
        uint256[] memory interestList = new uint256[](stakesLength);
        uint256[] memory minimumWithdrawDateList = new uint256[](stakesLength);
        bool[] memory activeList = new bool[](stakesLength);

        for(uint256 i=0; i<stakesLength; i++){
            Stake memory stk = stakesOf[_account][i];
            startDateList[i] = stk.startDate;
            amountList[i] = stk.amount;
            interestList[i] = calculateInterest(_account, i);
            minimumWithdrawDateList[i] = stk.lastWithdrawDate + minimumWithdrawTime;
            activeList[i] = stk.active;
        }

        return (startDateList, amountList, interestList, minimumWithdrawDateList, activeList);
    }
    
}