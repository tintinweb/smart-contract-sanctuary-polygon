// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";

contract Faucets is Ownable {
    event Faucet(address faucet, bool enabled);
    event Period(address faucet, uint256 period);
    event Limit(address faucet, uint256 limit);
    event Claimed(address faucet, address receiver, uint256 amount);
    event Withdrawn(address faucet, address receiver, uint256 amount);

    mapping(address => bool) private _faucets;
    mapping(address => uint256) private _periods;
    mapping(address => uint256) private _limits;
    mapping(address => mapping(address => uint256)) private _lastTimestamps;

    modifier exists(address faucet) {
        require(_faucets[faucet], "Faucets: FAUCET_DOES_NOT_EXIST");
        _;
    }

    function addFaucet(
        address faucet,
        uint256 period,
        uint256 limit
    ) public onlyOwner {
        require(!_faucets[faucet], "Faucets: FAUCET_ALREADY_EXISTS");
        _setFaucet(faucet);
        _setPeriod(faucet, period);
        _setLimit(faucet, limit);
    }

    function _setFaucet(address faucet) internal {
        _faucets[faucet] = true;
        emit Faucet(faucet, true);
    }

    function removeFaucet(address faucet) external onlyOwner exists(faucet) {
        _withdraw(faucet, _msgSender());
        delete _faucets[faucet];
        delete _periods[faucet];
        delete _limits[faucet];
        emit Faucet(faucet, false);
    }

    function getFaucet(address faucet) public view returns (bool) {
        return _faucets[faucet];
    }

    function setPeriod(address faucet, uint256 period) public onlyOwner exists(faucet) {
        _setPeriod(faucet, period);
    }

    function _setPeriod(address faucet, uint256 period) internal {
        _periods[faucet] = period;
        emit Period(faucet, period);
    }

    function getPeriod(address faucet) public view exists(faucet) returns (uint256) {
        return _periods[faucet];
    }

    function setLimit(address faucet, uint256 limit) public onlyOwner exists(faucet) {
        _setLimit(faucet, limit);
    }

    function _setLimit(address faucet, uint256 limit) internal {
        _limits[faucet] = limit;
        emit Limit(faucet, limit);
    }

    function getLimit(address faucet) public view exists(faucet) returns (uint256) {
        return _limits[faucet];
    }

    function getBalance(address faucet) public view exists(faucet) returns (uint256) {
        return IERC20(faucet).balanceOf(address(this));
    }

    function _getBalance(address faucet) internal view exists(faucet) returns (uint256) {
        return IERC20(faucet).balanceOf(address(this));
    }

    function canClaim(address faucet, address walletAddress) external view exists(faucet) returns (bool) {
        return _canClaim(faucet, walletAddress);
    }

    function _canClaim(address faucet, address walletAddress) internal view returns (bool) {
        return _lastTimestamps[faucet][walletAddress] + _periods[faucet] < block.timestamp;
    }

    function withdraw(address faucet, address receiver) external onlyOwner exists(faucet) {
        _withdraw(faucet, receiver);
    }

    function _withdraw(address faucet, address receiver) internal onlyOwner {
        uint256 accountBalance = _getBalance(faucet);
        IERC20(faucet).transfer(receiver, accountBalance);
        emit Withdrawn(faucet, receiver, accountBalance);
    }

    function claimBatch(address[] calldata faucets, uint256[] calldata amounts) public {
        require(faucets.length == amounts.length, "Faucets: ARRAY_LENGTH_MISMATCH");
        for (uint256 i = 0; i < faucets.length; i++) {
            claim(faucets[i], amounts[i]);
        }
    }

    function claim(address faucet, uint256 amount) public exists(faucet) {
        require(amount <= _limits[faucet], "Faucets: AMOUNT_EXCEEDED_LIMIT");
        uint256 accountBalance = _getBalance(faucet);
        require(accountBalance >= amount, "Faucets: FAUCET_INSUFFICIENT_BALANCE");
        require(_canClaim(faucet, msg.sender), "Faucets: FAUCET_PERIOD_COOLDOWN");
        _lastTimestamps[faucet][msg.sender] = block.timestamp;
        IERC20(faucet).transfer(msg.sender, amount);
        emit Claimed(faucet, msg.sender, amount);
    }
}