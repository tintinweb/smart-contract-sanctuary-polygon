// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WgldFarm is Ownable {
    string public name = "WgldFarm";

    mapping(address => bool) public isStaking;
    mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public startTime;
    mapping(address => uint256) public wgldBalance;
    // чтобы перебирать все адреса которые ранее стейкались
    mapping(uint256 => address) internal addressOfKey;
    uint256 internal mapSize = 1;
    mapping(address => uint256) internal keyOfAddresses;

    uint256 public totalSupply;

    uint256 public minStakeAmount; // минимальная сумма для стейкинга
    uint256 public percentPerTime; // проценты вознаграждения за время t
    uint256 public stakingTime; // время t стейкинга в секундах
    uint256 public stakingMinTime; // минимальное время стейкинга в секундах
    uint256 public penaltyPercent; // штраф за снятие во время минимального времени стейкинга

    IERC20 public rewardToken;

    event Stake(address indexed from, uint256 amount);
    event Unstake(address indexed from, uint256 amount);
    event YieldWithdraw(address indexed to, uint256 amount, uint256 yieldTime);
    event TransferReward(address indexed to, uint256 amount, uint256 yieldTime);

    constructor(IERC20 _rewardToken) {
        rewardToken = _rewardToken;
        minStakeAmount = 0;
        percentPerTime = 10;
        stakingTime = 2592000; // месяц
        stakingMinTime = 604800; // неделя
        penaltyPercent = 10;
        addressOfKey[0] = address(0);
    }

    function setPercentPerTime(uint256 _percentPerTime, uint256 _stakingTime) public onlyOwner {
        _recalculateByOldPercents();
        percentPerTime = _percentPerTime;
        stakingTime = _stakingTime;
    }

    function setStakingMinTime(uint256 _stakingMinTime) public onlyOwner {
        stakingMinTime = _stakingMinTime;
    }

    function setPenaltyPercent(uint256 _penaltyPercent) public onlyOwner {
        penaltyPercent = _penaltyPercent;
    }

    function setMinStakeAmount(uint256 _minStakeAmount) public onlyOwner {
        minStakeAmount = _minStakeAmount;
    }

    function stake(uint256 amount) public {
        require(amount >= minStakeAmount, string.concat("The minimum amount for staking must be greater than ", Strings.toString(minStakeAmount)));
        require(rewardToken.balanceOf(msg.sender) >= amount, "You don't have enough tokens");

        if (isStaking[msg.sender] == true) {
            uint256 toTransfer = calculateYieldTotal(msg.sender);
            wgldBalance[msg.sender] += toTransfer;
        }

        rewardToken.transferFrom(msg.sender, address(this), amount);
        stakingBalance[msg.sender] += amount;
        totalSupply += amount;
        isStaking[msg.sender] = true;

        _resetStakingTimer(msg.sender);
        _appendAddressKey(msg.sender);

        emit Stake(msg.sender, amount);
    }

    function _appendAddressKey(address user) internal {
        if (keyOfAddresses[user] == 0) {
            addressOfKey[mapSize] = user;
            keyOfAddresses[user] = mapSize;
            mapSize++;
        }
    }

    function unstake(uint256 amount) public {
        require(isStaking[msg.sender] == true && stakingBalance[msg.sender] >= amount && amount > 0, "Nothing to unstake");

        uint256 yieldTransfer = calculateYieldTotal(msg.sender);
        wgldBalance[msg.sender] += yieldTransfer;

        stakingBalance[msg.sender] -= amount;
        totalSupply -= amount;

        uint256 recalculatedAmount = _calculatePenaltyAmount(amount, msg.sender);
        require(rewardToken.balanceOf(address(this)) >= recalculatedAmount, "Nothing to get");
        rewardToken.transfer(msg.sender, recalculatedAmount);

        if (stakingBalance[msg.sender] == 0) {
            isStaking[msg.sender] = false;
        }

        _resetStakingTimer(msg.sender);

        emit Unstake(msg.sender, recalculatedAmount);
    }

    function _calculatePenaltyAmount(uint256 amount, address user) internal view returns (uint256) {
        uint256 yieldTime = calculateYieldTime(user);
        if (yieldTime > stakingMinTime) {
            return amount;
        }
        uint256 savePercent = 100 - penaltyPercent;
        uint256 percentRate = savePercent * 1e18 / 100;
        uint256 rawAmount = amount * percentRate / 1e18;
        return rawAmount;
    }

    function withdrawYield() public {
        uint256 YieldTime = calculateYieldTime(msg.sender);
        uint256 toTransfer = _getReward(msg.sender);
        _resetStakingTimer(msg.sender);

        require(rewardToken.balanceOf(address(this)) >= toTransfer, "Nothing to withdraw");
        rewardToken.transfer(msg.sender, toTransfer);

        emit YieldWithdraw(msg.sender, toTransfer, YieldTime);
    }

    function transferRewardToStake() public {
        uint256 YieldTime = calculateYieldTime(msg.sender);
        uint256 toTransfer = _getReward(msg.sender);

        stakingBalance[msg.sender] += toTransfer;
        totalSupply += toTransfer;

        _resetStakingTimer(msg.sender);

        emit TransferReward(msg.sender, toTransfer, YieldTime);
    }

    function _resetStakingTimer(address user) internal {
        startTime[user] = block.timestamp;
    }

    function _getReward(address user) internal returns (uint256){
        uint256 toTransfer = calculateYieldTotal(user);

        require(toTransfer > 0 || wgldBalance[user] > 0, "no reward");

        if (wgldBalance[user] > 0) {
            uint256 oldBalance = wgldBalance[user];
            wgldBalance[user] = 0;
            toTransfer += oldBalance;
        }
        return toTransfer;
    }

    function calculateYieldTime(address user) public view returns (uint256){
        if (isStaking[user] == false) {
            return 0;
        }
        uint256 end = block.timestamp;
        uint256 totalTime = end - startTime[user];
        return totalTime;
    }

    function calculateYieldTotal(address user) public view returns (uint256) {
        if (isStaking[user] == false) {
            return 0;
        }
        uint256 time = calculateYieldTime(user) * 1e18;
        uint256 timeRate = time / stakingTime;
        uint256 rawYield = (stakingBalance[user] * timeRate * percentPerTime) / (100 * 1e18);
        return rawYield;
    }

    function _recalculateByOldPercents() internal {
        for (uint i = 1; i < mapSize; i++) {
            address user = addressOfKey[i];
            uint256 yieldTransfer = calculateYieldTotal(user);
            wgldBalance[user] += yieldTransfer;
            _resetStakingTimer(user);
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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