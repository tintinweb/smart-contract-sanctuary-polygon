/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

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

// File: presale.sol


pragma solidity ^0.8.0;



contract TokenHolder is Ownable {
    struct VestingSchedule {
        uint256 amount;
        uint256 start;
        uint256 duration;
        uint256 claimed;
    }

    IERC20 public busd;
    IERC20 public projectToken;
    address public beneficiary;
    uint256 public releaseTime;
    uint256 public minContribution;
    uint256 public maxContribution;
    uint256 public totalContributed;
    mapping(address => VestingSchedule) public vestingSchedules;

    constructor(
        address _busd,
        address _projectToken,
        address _beneficiary,
        uint256 _releaseTime,
        uint256 _minContribution,
        uint256 _maxContribution
    ) {
        require(_busd != address(0), "TokenHolder: BUSD token address cannot be zero");
        require(_projectToken != address(0), "TokenHolder: project token address cannot be zero");
        require(_beneficiary != address(0), "TokenHolder: beneficiary address cannot be zero");
        require(_releaseTime > block.timestamp, "TokenHolder: release time must be in the future");
        require(_minContribution > 0, "TokenHolder: minimum contribution amount must be greater than zero");
        require(_maxContribution > _minContribution, "TokenHolder: maximum contribution amount must be greater than minimum contribution amount");

        busd = IERC20(_busd);
        projectToken = IERC20(_projectToken);
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
        minContribution = _minContribution;
        maxContribution = _maxContribution;
    }

    function contribute(uint256 amount) external {
        require(block.timestamp < releaseTime, "TokenHolder: release time has passed");
        require(amount >= minContribution && amount <= maxContribution, "TokenHolder: invalid contribution amount");

        VestingSchedule storage vestingSchedule = vestingSchedules[msg.sender];
        vestingSchedule.amount += amount;
        totalContributed += amount;

        require(busd.transferFrom(msg.sender, address(this), amount), "TokenHolder: failed to transfer BUSD tokens");
    }

    function claimTokens() external {
        VestingSchedule storage vestingSchedule = vestingSchedules[msg.sender];
        require(vestingSchedule.amount > 0, "TokenHolder: no tokens to claim");
        require(block.timestamp >= vestingSchedule.start, "TokenHolder: vesting period has not started");
        require(vestingSchedule.claimed < vestingSchedule.amount, "TokenHolder: all tokens claimed");

        uint256 claimable = vestingSchedule.amount * (block.timestamp - vestingSchedule.start) / vestingSchedule.duration - vestingSchedule.claimed;
        uint256 available = projectToken.balanceOf(address(this)) - totalClaimed();
        uint256 claimAmount = claimable > available ? available : claimable;

        require(claimAmount > 0, "TokenHolder: no tokens available to claim");

        vestingSchedule.claimed += claimAmount;
        projectToken.transfer(msg.sender, claimAmount);
    }

    function totalClaimed() public view returns (uint256) {
            uint256 claimed = 0;
            for (uint256 i = 0; i < totalContributed; i++) {
                VestingSchedule storage vestingSchedule = vestingSchedules[address(uint160(i))];
                claimed += vestingSchedule.claimed;
            }
            return claimed;
    }
        function setBeneficiary(address _beneficiary) external onlyOwner {
            require(_beneficiary != address(0), "TokenHolder: beneficiary address cannot be zero");
            beneficiary = _beneficiary;
        }

        function withdrawBusd(uint256 amount) external onlyOwner {
            require(busd.balanceOf(address(this)) >= amount, "TokenHolder: insufficient BUSD balance");
            require(busd.transfer(owner(), amount), "TokenHolder: failed to transfer BUSD tokens");
        }
        }