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
pragma solidity ^0.8.9;

interface IJackpot {
    function drawJackpot(address _player) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMeteor {
    function setupMeteor(
        uint256 _startAt,
        uint256 _fallingAmount,
        uint256 _shootingAmount,
        uint256 _falls,
        uint256 _maxIdle
    ) external payable;
    function getShootingInfo() external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IMeteor.sol";
import "./interfaces/IJackpot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Jackpot is Ownable, Pausable, IJackpot {

    address public tickets;

    uint256 public jackpotBalance;

    event TicketsUpdated(address oldTickets, address newTickets);
    event JackpotDeposited(uint256 amount);
    event JackpotDrawn(address _meteor, uint256 amount);

    modifier onlyTickets() {
        require(msg.sender == tickets, "Jackpot: tickets only");
        _;
    }

    constructor(address _tickets) {
        tickets = _tickets;
    }

    receive() external payable {
        jackpotBalance += msg.value;
        emit JackpotDeposited(msg.value);
    }

    function setTickets(address _tickets) public onlyOwner {
        require(_tickets != address(0), "Jackpot: zero address");
        address oldTickets = tickets;
        tickets = _tickets;

        emit TicketsUpdated(oldTickets, _tickets);
    }

    function drawJackpot(address _player) override external onlyTickets {
        if (paused()) {
            emit JackpotDrawn(_player, 0);
            return;
        }
        // FIXME: 10%, 1%, 0.1%
        uint16[3] memory max = [1000, 100, 10]; 

        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.coinbase,
                    block.difficulty + jackpotBalance,
                    block.gaslimit,
                    block.timestamp
                )
            )
        ) % max.length;

        uint256 maxDrawPortion = max[index];

        uint256 ratio = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.coinbase,
                    block.difficulty,
                    block.gaslimit,
                    block.timestamp + jackpotBalance
                )
            )
        ) % maxDrawPortion + 1;

        uint256 prize = jackpotBalance * ratio / 10000;
        require(payable(_player).send(prize), "Jackpot: claim jackpot prize failed");

        jackpotBalance -= prize;

        emit JackpotDrawn(_player, prize);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function rescueFund() public onlyOwner whenPaused {
        uint256 balance = address(this).balance;
        require(payable(owner()).send(balance), "Jackpot: rescue failed");
    }
}