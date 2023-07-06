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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Staking is Ownable, Pausable {
    uint256 public planId;
    IERC20 public token;

    struct Plan {
        uint256 minAmount;
        uint256 maxAmount;
        uint256 startTime;
        uint256 endTime;
        uint256 minLock;
        bool isActive;
    }

    struct UserStake {
        uint256 amount;
        uint256 planNo;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(uint256 => Plan) public plan;
    mapping(address => uint256) public userId;
    mapping(address => mapping(uint256 => UserStake)) public userStake;

    event StakePlanUpdated(uint256 _planId, Plan _plan, uint256 timestamp);
    event StakeCreated(
        address user,
        uint256 _userId,
        uint256 amount,
        uint256 _planId,
        uint256 endTime
    );
    event StakeRemoved(address user, uint256 _userId);

    constructor(address _token) {
        require(_token != address(0), "Zero token address");

        token = IERC20(_token);
    }

    function createStakePlans(
        Plan[] calldata _plans
    ) external onlyOwner returns (bool) {
        require(_plans.length > 0, "Zero plans");
        for (uint i; i < _plans.length; ) {
            require(
                _plans[i].maxAmount > _plans[i].minAmount &&
                    _plans[i].minAmount >= 0,
                "Invalid min and max stake values"
            );

            require(
                _plans[i].endTime > _plans[i].startTime &&
                    _plans[i].startTime > block.timestamp,
                "Invalid start and end times"
            );

            plan[planId] = _plans[i];

            emit StakePlanUpdated(planId, _plans[i], block.timestamp);

            unchecked {
                ++planId;
                ++i;
            }
        }

        return true;
    }

    function updateStakePlans(
        uint256[] calldata _planIds,
        Plan[] calldata _plans
    ) external onlyOwner returns (bool) {
        for (uint i; i < _plans.length; ) {
            require(_planIds[i] < planId, "Invalid Plan Id");
            require(
                _plans[i].maxAmount > _plans[i].minAmount &&
                    _plans[i].minAmount >= 0,
                "Invalid min and max stake values"
            );

            plan[_planIds[i]] = _plans[i];

            emit StakePlanUpdated(_planIds[i], _plans[i], block.timestamp);

            unchecked {
                ++i;
            }
        }

        return true;
    }

    function updateStakePlanStatus(
        uint256[] calldata _planIds,
        bool[] calldata _status
    ) external onlyOwner returns (bool) {
        for (uint i; i < _planIds.length; ) {
            require(_planIds[i] < planId, "Invalid Plan Id");
            plan[_planIds[i]].isActive = _status[i];

            emit StakePlanUpdated(
                _planIds[i],
                plan[_planIds[i]],
                block.timestamp
            );

            unchecked {
                ++i;
            }
        }

        return true;
    }

    function createStake(
        uint256 _planId,
        uint256 amount
    ) external returns (bool) {
        require(_planId < planId, "Invalid Plan Id");
        Plan memory _plan = plan[_planId];
        require(_plan.isActive, "Plan disabled");
        require(
            amount <= _plan.maxAmount && amount >= _plan.minAmount,
            "Invalid stake amount"
        );
        require(
            block.timestamp >= _plan.startTime &&
                block.timestamp <= _plan.endTime,
            "Invalid stake time for this plan"
        );

        userStake[msg.sender][userId[msg.sender]] = UserStake(
            amount,
            _planId,
            block.timestamp,
            block.timestamp + _plan.minLock
        );
        userId[msg.sender]++;
        token.transferFrom(msg.sender, address(this), amount);
        emit StakeCreated(
            msg.sender,
            userId[msg.sender],
            amount,
            _planId,
            block.timestamp + _plan.minLock
        );
        return true;
    }

    function removeStake(uint256 _userId) external returns (bool) {
        require(_userId < userId[msg.sender], "Invalid user Id");
        UserStake memory _userStake = userStake[msg.sender][_userId];
        require(_userStake.amount > 0, "Invalid user stake Id");
        require(block.timestamp >= _userStake.endTime, "Can't withdraw early");
        token.transfer(msg.sender, _userStake.amount);
        delete userStake[msg.sender][_userId];
        emit StakeRemoved(msg.sender, _userId);
        return true;
    }

    function userAllStakes(
        address _user
    ) external view returns (UserStake[] memory) {
        UserStake[] memory _userStakes = new UserStake[](userId[_user]);
        for (uint i; i < userId[_user]; ) {
            _userStakes[i] = userStake[_user][i];
            unchecked {
                ++i;
            }
        }
        return _userStakes;
    }

    function userStakes(
        address _user,
        uint256[] memory _userStakeIds
    ) external view returns (UserStake[] memory) {
        require(_userStakeIds.length > 0, "Zero array length");
        UserStake[] memory _userStakes = new UserStake[](_userStakeIds.length);
        for (uint i; i < _userStakeIds.length; ) {
            _userStakes[i] = userStake[_user][_userStakeIds[i]];
            unchecked {
                ++i;
            }
        }
        return _userStakes;
    }

    function userActiveStakesIds(
        address _user
    ) external view returns (uint256[] memory, uint256) {
        uint256[] memory _userIds = new uint256[](userId[_user]);
        uint256 j;
        for (uint i; i < userId[_user]; ) {
            if (userStake[_user][i].amount > 0) {
                _userIds[j] = i;
                j++;
            }
            unchecked {
                ++i;
            }
        }
        return (_userIds, j);
    }
}