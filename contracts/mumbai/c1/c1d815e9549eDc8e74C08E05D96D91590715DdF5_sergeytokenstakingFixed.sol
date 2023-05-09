/**
 *Submitted for verification at polygonscan.com on 2023-05-09
*/

// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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

// File: contracts/sergeytokenstakingFixed.sol


pragma solidity ^0.8.0;




contract sergeytokenstakingFixed is Ownable {
    using Counters for Counters.Counter;

    IERC20 private stakingToken;

    constructor(address _stakingToken, address adminRole) {
        stakingToken = IERC20(_stakingToken);
        admin = adminRole;
    }

    uint256 private _shouldPaidAmount;
    uint256 private lastUpdatedTime;
    address public admin;

    enum TariffPlane {
        Days90,
        Days180,
        Days360,
        Days720
    }

    struct Rate {
        address owner;
        uint256 amount;
        uint256 rate;
        uint256 expiredTime;
        bool isClaimed;
        TariffPlane daysPlane;
    }

    mapping(address => mapping(uint256 => Rate)) private _rates;
    mapping(address => Counters.Counter) private _ratesId;
    mapping(address => uint256) private _balances;
    address[] private receivers;

    event Staked(
        uint256 id,
        address indexed owner,
        uint256 amount,
        uint256 rate,
        uint256 expiredTime
    );
    event Claimed(address indexed receiver, uint256 amount, uint256 id);
    event TokenAddressChanged(address oldAddress, address changeAddress);

    modifier amountNot0(uint256 _amount) {
        require(_amount > 0, "The amount must be greater than 0");
        _;
    }

    modifier checkTime(uint256 id, address receiver) {
        timeUpdate();
        require(
            stakingEndTime(receiver, id) < lastUpdatedTime,
            "Token lock time has not yet expired or Id isn't correct"
        );
        _;
    }

    modifier dayIsCorrect(uint256 day) {
        require(
            day == 90 || day == 180 || day == 360 || day == 720,
            "Choose correct plane: 90/180/360/720 days"
        );
        _;
    }

    function getMyLastStakedId(address user) public view returns (uint256) {
        return _ratesId[user].current() - 1;
    }

    function calculateTime(uint256 day) internal view returns (uint256) {
        return (block.timestamp + day * 1 * 1);
    }

    function getStakingToken() external view returns (IERC20) {
        return stakingToken;
    }

    function getReceiversLength() public view returns (uint256) {
        return receivers.length;
    }

    function getTotalSupply() public view returns (uint256) {
        return stakingToken.balanceOf(address(this)); // (10**stakingToken.decimals());
    }

    function allTokensBalanceOf(address _account)
        external
        view
        returns (uint256)
    {
        return _balances[_account];
    }

    function stakingEndTime(address _account, uint256 id)
        public
        view
        returns (uint256)
    {
        return _rates[_account][id].expiredTime;
    }

    function getLastUpdatedTime() external view returns (uint256) {
        return lastUpdatedTime;
    }

    function earned(address receiver, uint256 id)
        private
        view
        returns (uint256)
    {
        return (_rates[receiver][id].amount * _rates[receiver][id].rate) / 1000;
    }

    function stake(
        address receiver,
        uint256 _amount,
        uint256 day
    ) external amountNot0(_amount) dayIsCorrect(day) {
        require(admin == msg.sender, "only admin can stake");
        uint256 id = _ratesId[receiver].current();
        uint256 expiredTime = calculateTime(day);
        uint256 rate = checkPlane(day);

        uint256 totalSupply = getTotalSupply();

        require(
            (_amount * rate) / 1000 <= totalSupply - _shouldPaidAmount,
            "Fund is not enough."
        );

        _rates[receiver][id] = Rate(
            receiver,
            _amount,
            rate,
            expiredTime,
            false,
            getDaysPlane(day)
        );

        receivers.push(receiver);

        uint256 reward = earned(receiver, id) + _amount;
        _shouldPaidAmount += reward;
        _balances[receiver] += reward;
        _ratesId[receiver].increment();

        stakingToken.transferFrom(
            msg.sender,
            address(this),
            _amount //* (10**stakingToken.decimals())
        );
        emit Staked(id, receiver, _amount, rate, expiredTime);
    }

    function claim(uint256 id, address receiver) external checkTime(id, receiver) {
        require(!_rates[receiver][id].isClaimed, "Reward already claimed!");

        _rates[receiver][id].isClaimed = true;

        uint256 amount = _rates[receiver][id].amount;
        uint256 reward = earned(receiver, id) + amount;

        _shouldPaidAmount -= reward;
        _balances[receiver] -= reward;

        stakingToken.transfer(
            receiver,
            reward //* (10**stakingToken.decimals())
        );
        emit Claimed(receiver, reward, id);
    }

    function claimAll() external {
        require(admin == msg.sender, "only admin can execute the function");
        for (uint256 i; i < receivers.length; i++) {
            for (uint256 j; j < getMyLastStakedId(receivers[i]) + 1; j++) {
                if (
                    !_rates[receivers[i]][j].isClaimed &&
                    stakingEndTime(receivers[i], j) < block.timestamp
                ) {
                    _rates[receivers[i]][j].isClaimed = true;

                    uint256 amount = _rates[receivers[i]][j].amount;
                    uint256 reward = earned(receivers[i], j) + amount;

                    _shouldPaidAmount -= reward;
                    _balances[receivers[i]] -= reward;

                    stakingToken.transfer(
                        receivers[i],
                        reward //* (10**stakingToken.decimals())
                    );
                    emit Claimed(receivers[i], reward, j);
                }
            }
        }
    }

    function setAdmin(address newAdmin) external onlyOwner {
        admin = newAdmin;
    }

    function checkPlane(uint256 day) internal pure returns (uint256) {
        if (day == 90) {
            return 60;
        } else if (day == 180) {
            return 150;
        } else if (day == 360) {
            return 380;
        }
        return 1000;
    }

    function getDaysPlane(uint256 day) internal pure returns (TariffPlane) {
        if (day == 90) {
            return TariffPlane.Days90;
        } else if (day == 180) {
            return TariffPlane.Days180;
        } else if (day == 360) {
            return TariffPlane.Days360;
        }
        return TariffPlane.Days720;
    }

    function timeUpdate() internal {
        lastUpdatedTime = block.timestamp;
    }

    function setTokenAddress(address changeAddress) external onlyOwner {
        emit TokenAddressChanged(address(stakingToken), changeAddress);
        stakingToken = IERC20(changeAddress);
    }
}