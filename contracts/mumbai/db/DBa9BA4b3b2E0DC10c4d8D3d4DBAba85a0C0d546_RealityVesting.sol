// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RealityVesting is Ownable{
    event PoolInitialized(uint256 startTimestamp, uint256 poolSize);
    event AllocationModified(address indexed to, int256 value);
    event Withdraw(address indexed to, uint256 value);
    event EmergencyWithdraw(address indexed to, uint256 value);

    uint256 private constant SECONDS_IN_MONTH = 30 days;

    uint256 public immutable poolSize;
    uint256 public immutable initialDelay;
    uint256 public immutable stepsCount;
    uint256 public immutable stepLength;
    
    /// @dev We are going to use RLTM token which total supply is under 2^128. 
    /// This is a specific token, transfers return true or revert, no need for safeTransfer.
    IERC20 public immutable erc20Contract;

    uint256 public startTimestamp;
    bool public isActive;
    uint256 private allocationsSum;
    uint256 private withdrawsSum;
    mapping(address => uint256) public vestedToAllocation;
    mapping(address => uint256) public vestedToWithdrawn;
    
    error CannotRenounce();

    /**
     * @notice Contract's vesting strategy is parameterized with: initialDelay, stepsCount, stepLength. 
     * @param _erc20Contract Address of token contract which will be vested.
     * @param _poolSize Size of the token pool that the contract should own to initialize it. Must be greater than 0.
     * @param _initialDelay Delay expressed in months after which first tokens are released. 
     * @param _stepsCount Number of steps in which tokens should be released. Minimum is 1.
     * @param _stepLength Length of each release steps expressed in months. Minimum is 1.
     */
    constructor(
        IERC20 _erc20Contract, 
        uint256 _poolSize, 
        uint256 _initialDelay, 
        uint256 _stepsCount, 
        uint256 _stepLength
    ) Ownable() {
        require(address(_erc20Contract) != address(0), "Zero address provided as ERC20 contract");
        require(_poolSize != 0, "Pool size must be greater than 0");
        require(_stepsCount > 0, "Steps count must be at least 1");
        require(_stepLength > 0, "Step length must be at least 1");
        erc20Contract = _erc20Contract;
        poolSize = _poolSize;
        initialDelay = _initialDelay;
        stepsCount = _stepsCount;
        stepLength = _stepLength;
    }

    modifier onlyWhenActive() {
        require(isActive, "Contract is inactive");
        _;
    }

    /**
     * @notice This function should be called after the contract owns at least 'poolSize' of tokens.
     * It makes the contract active.
     * @param _startTimestamp The DateTime from which contract starts vesting strategy calculation. 
     * Can be set to future or past, not lower than Unix epoch though.
     */
    function initialize(uint256 _startTimestamp) external onlyOwner{
        require(!isActive, "Contract already initialized");
        require(_startTimestamp > 0, "Start timestamp is not set or too old");
        require(erc20Contract.balanceOf(address(this)) >= poolSize, "Wrong token balance for contract");

        startTimestamp = _startTimestamp;
        isActive = true;
        emit PoolInitialized(startTimestamp, poolSize);
    }

    /**
     * @notice Owner can call this function to add allocation for particular address. 
     * Cannot revoke already given allocations. Can raise on top of current allocation.
     * Contract has to be active at the time of calling.
     * @param to Address for which allocation is set.
     * @param value Amount of tokens to allocate.
     */
    function allocate(address to, uint256 value) external onlyOwner onlyWhenActive{
        require(to != address(0), "Allocation to zero address");
        require(value > 0, "Allocation of zero value");
        require(allocationsSum + value <= poolSize, "Cannot allocate more than the pool size");

        vestedToAllocation[to] += value;
        allocationsSum += value;
        emit AllocationModified(to, int256(value)); //This cast is safe. No overflow possible.
    }

    /**
     * @notice By calling this function the user can resign from his allocation for whatever reason.
     * Contract has to be active at the time of calling.
     */
    function waive() external onlyWhenActive{
        address sender = msg.sender;
        uint256 senderRemainingAllocation = vestedToAllocation[sender] - vestedToWithdrawn[sender];
        require(senderRemainingAllocation > 0, "No allocation to waive");

        allocationsSum -= senderRemainingAllocation;
        vestedToAllocation[sender] -= senderRemainingAllocation;
        emit AllocationModified(sender, -int256(senderRemainingAllocation));
    }

    /**
     * @notice Owner can withdraw excess tokens if contract owns more than it needs to cover poolSize.
     * Contract has to be active at the time of calling.
     * @param to Address for which allocation is set.
     */ 
    function emergencyWithdraw(address to) external onlyOwner onlyWhenActive{
        uint256 contractErc20Balance = erc20Contract.balanceOf(address(this));
        uint256 tokensExcess = contractErc20Balance + withdrawsSum - poolSize;
        require(tokensExcess > 0, "No excess tokens to withdraw");

        emit EmergencyWithdraw(to, tokensExcess);

        erc20Contract.transfer(to, tokensExcess);
    }
    
    /// @notice Renouncing is not possible
    function renounceOwnership() public override view onlyOwner {
        revert CannotRenounce();
    }

    /**
     * @notice User can withdraw all the tokens that are due at the moment of calling this function.
     * Tokens are send to the address of the function caller.
     * Contract has to be active at the time of calling.
     */
    function withdraw() external onlyWhenActive{
        address sender = msg.sender;
        uint256 toWithdraw = getWithdrawValueForAddress(sender);
        require(toWithdraw > 0, "Nothing to withdraw");
        
        vestedToWithdrawn[sender] += toWithdraw;
        withdrawsSum += toWithdraw;
        emit Withdraw(sender, toWithdraw);

        erc20Contract.transfer(sender, toWithdraw);
    }
    
    /**
     * @notice With this function anyone can check how much any address can withdraw at the moment.
     * @param _to Address for which withdraw amount is calculated.
     */
    function getWithdrawValueForAddress(address _to) public view returns (uint256){
        uint256 due = _calculateDue(_to);
        // There are cases where due is smaller than already withdrawn amount because of waive function
        if (due <= vestedToWithdrawn[_to]){
            return 0;
        } else{
            return due - vestedToWithdrawn[_to];
        }
    }

    /**
     * @dev Function responsible for vesting strategy.
     * Releasing tokens based on few parameters set during contract deployment: delay, step count, and step length
     */
    function _calculateDue(address _to) internal view returns (uint256){      
        uint256 monthsSinceStart = 0;
        if (block.timestamp > startTimestamp){
            monthsSinceStart = (block.timestamp - startTimestamp) / SECONDS_IN_MONTH;
        } 
        uint256 monthsToFullRelease = initialDelay + stepsCount * (stepLength > 1 ? stepLength - 1 : stepLength);
        if (stepLength == 1){
            monthsToFullRelease -= 1;
        }

        if (monthsSinceStart < initialDelay){
            return 0;
        }
        else if (monthsSinceStart < monthsToFullRelease){
            uint256 stepNumber = ((monthsSinceStart - initialDelay) / stepLength) + 1;
            return vestedToAllocation[_to] * stepNumber / stepsCount ;
        }
        else{
            return vestedToAllocation[_to];
        }
    }
}