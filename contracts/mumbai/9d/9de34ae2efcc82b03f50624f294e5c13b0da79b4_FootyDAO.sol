//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title FootyDAO simple stake contract
 * @author Carlos Ramos
 * @notice simple smart contract to keep track of the stakes of each individual
 */
contract FootyDAO is Ownable {
    event Stake(uint256 indexed userId, uint256 indexed gameId, uint256 amount);
    event GameAdded(uint256 indexed gameId, uint256 minStake);

    error StakeAmountTooLow();
    error GameDoesNotExist();
    error TransferFailed();

    mapping(bytes32 => uint256) public minStakePerGame;

    /**
     * @param gameId - hash of the gameId from db
     * @param userId - hash of the userId from db
     * @param amount - amount of playes the user wants to stake for
     */
    function stake(
        bytes32 gameId,
        bytes32 userId,
        uint256 amount
    ) external payable {
        //game exists
        if (minStakePerGame[gameId] == 0) {
            revert GameDoesNotExist();
        }
        if (amount * minStakePerGame[gameId] > msg.value) {
            revert StakeAmountTooLow();
        }
        emit Stake(uint256(userId), uint256(gameId), amount);
    }

    /**
     * @notice set the minimum stake for a game
     * @param gameId - hash of the gameId from db
     */
    function addGame(bytes32 gameId, uint256 minStake) external onlyOwner {
        minStakePerGame[gameId] = minStake;
        emit GameAdded(uint256(gameId), minStake);
    }

    /**
     * @notice withdraw all the funds from the contract
     * @dev it is guaranteed that owner is an EOA
     */
    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!success) {
            revert TransferFailed();
        }
    }
}

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