// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Staking is Ownable {

    IERC20 public token;
    uint256[] public allowedStakingPeriods;
    uint256 public rewardRate;
    uint256 public earlyClaimPenalty;
    uint256 public maxPerWallet;
    uint256 totalStaked;
    mapping(address => uint256) public stakedPerWallet;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
    }

    struct Program {
        uint periodInDays;
        uint256 poolSize;
        uint256 minStakeAmount;
        uint256 maxStakeAmount;
        uint256 rewardRate;
        uint256 earlyClaimPenalty;
        uint256 totalStaked;
        mapping(address => Stake) stakes;
    }
    Program[] public programs;

    event Staked(address indexed staker, uint programIndex, uint256 amount, uint timestamp);
    event Unstaked(
        address indexed staker, uint programIndex, uint256 amount, uint256 reward, uint timestamp
    );
    event Funded(uint256 amount, address wallet);

    constructor(
        address _token,
        uint256 _maxPerWallet
    ) {
        token = IERC20(_token);
        maxPerWallet = _maxPerWallet;
    }

    function stake(uint256 _amount, uint _programIndex) external {
        require(_programIndex < programs.length, "Invalid program index");
        require(programs[_programIndex].stakes[msg.sender].amount == 0, "Already staking in this program");
        require(
            _amount >= programs[_programIndex].minStakeAmount, "Stake amount less than minimum"
        );
        require(
            _amount <= programs[_programIndex].maxStakeAmount, "Stake amount exceeds maximum"
        );
        require(
            _amount + stakedPerWallet[msg.sender] <= maxPerWallet,
            "Max amount staked per wallet reached"
        );
        require(_amount + programs[_programIndex].totalStaked <= programs[_programIndex].poolSize, "Program pool size full");
        token.transferFrom(msg.sender, address(this), _amount);
        programs[_programIndex].stakes[msg.sender] = Stake(_amount, block.timestamp);
        programs[_programIndex].totalStaked += _amount;
        stakedPerWallet[msg.sender] += _amount;
        totalStaked += _amount;
        emit Staked(msg.sender, _programIndex, _amount, block.timestamp);
    }

    function claim(uint _programIndex) external {
        require(programs[_programIndex].stakes[msg.sender].amount > 0, "No stake in this program");
        uint256 _staked = programs[_programIndex].stakes[msg.sender].amount;
        uint256 _reward = _staked * programs[_programIndex].rewardRate / 100;
        uint256 _stakingPeriod = programs[_programIndex].periodInDays * 86400;

        if (block.timestamp < programs[_programIndex].stakes[msg.sender].timestamp + _stakingPeriod) {
            // Apply early claim penalty
            _reward = earlyWithdrawalReward(
                _staked,
                programs[_programIndex].rewardRate,
                block.timestamp - programs[_programIndex].stakes[msg.sender].timestamp,
                _stakingPeriod,
                programs[_programIndex].earlyClaimPenalty
            );
        }
        uint256 _total = _staked + _reward;
        totalStaked -= _staked;

        programs[_programIndex].stakes[msg.sender].amount = 0;
        programs[_programIndex].stakes[msg.sender].timestamp = 0;

        token.transfer(msg.sender, _total);
        emit Unstaked(msg.sender, _programIndex, _total, _reward, block.timestamp);
    }

    function earlyWithdrawalReward(
        uint256 _amount,
        uint256 _rewardPercentage,
        uint256 _completedPeriod,
        uint256 _stakingPeriod,
        uint256 _penalty
    ) public pure returns (uint256) {
        uint256 _totalReward = (_amount * _rewardPercentage) / 100;
        uint256 _rewardForCompletedPeriod = (_totalReward * _completedPeriod) / _stakingPeriod;
        uint256 _earlyWithdrawalReward = (_rewardForCompletedPeriod * _penalty) / 100;
        return _earlyWithdrawalReward;
    }

    function addProgram(
        uint _periodInDays,
        uint256 _poolSize,
        uint256 _minStakeAmount,
        uint256 _maxStakeAmount,
        uint256 _rewardRate,
        uint256 _earlyClaimPenalty
    ) external onlyOwner {
        programs.push();
        uint _newIndex = programs.length - 1;
        programs[_newIndex].periodInDays = _periodInDays;
        programs[_newIndex].poolSize = _poolSize;
        programs[_newIndex].minStakeAmount = _minStakeAmount;
        programs[_newIndex].maxStakeAmount = _maxStakeAmount;
        programs[_newIndex].rewardRate = _rewardRate;
        programs[_newIndex].earlyClaimPenalty = _earlyClaimPenalty;
        programs[_newIndex].totalStaked = 0;
    }

    function adminWithdraw(uint256 _amount) public onlyOwner {
        require(_amount <= token.balanceOf(address(this)) - totalStaked, "Cannot withdraw more than interest");
        token.transfer(msg.sender, _amount);

        // EMIT EVENT
    }
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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