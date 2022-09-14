// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// imports
import "Ownable.sol";

// ⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⠀⣶⣤⣤⣄⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⡀⢻⣿⣿⣿⣿⣿⣿⣷⣦⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⣠⣾⣿⣿⣿⣇⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣤⣀⠀⠀⠀⠀
// ⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠷⠆⠀⠀
// ⠀⠀⠀⣼⣿⣿⡿⠟⠛⠉⣉⣀⠘⣿⣿⣿⡿⠿⠿⠟⠛⠛⠉⣉⣀⣤⣤⣶⠂⠀
// ⠀⠀⣼⠟⠉⣀⣤⣶⣿⣿⣿⣿⣦⣤⣤⣤⡀⢠⣶⣶⣾⣿⣿⣿⣿⣿⣿⠃⠀⠀
// ⠀⠀⢠⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠈⢿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀
// ⠀⠀⠀⠈⠙⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⠸⣿⣿⣿⣿⣿⡟⠁⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠉⠛⠻⢿⣿⣿⣿⣿⣿⣿⣿⠀⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠛⠿⠿⣿⣿⡇⢻⠿⠋⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

contract SimpleEscrowC is Ownable {
    // escrow contract, sends ether to a beneficiary address.
    // beta version of the decentralized escrow contract.
    // This is still centralized (relies on Oracle).
    // Fully decentralized, zk based contract is in the horizon (<4 weeks)
    // erc-20 and erc-721 support is in the horizon (<4 weeks)

    struct transaction {
        address sender;
        uint256 amount; // amount to send
    }
    transaction[] public transactions; // array of transactions

    // events
    event Deposit(
        address indexed sender,
        uint256 amount,
        uint256 index
    );
    event Withdraw(address indexed recipient, uint256 amount);

    // constructor
    constructor() {}

    // deposit ether to escrow.
    function deposit() external payable returns (uint256) {
        require(msg.value > 0, "deposit must be greater than 0");

        // store new transaction
        transaction memory newTransaction;
        newTransaction.amount = msg.value;
        newTransaction.sender = msg.sender;
        transactions.push(newTransaction);
        emit Deposit(msg.sender, msg.value, transactions.length - 1);
        // return id of new transaction
        return transactions.length - 1;

    }

    // sender can always withdraw deposited assets at any time
    function withdrawSender(uint256 _index) external {
        require(_index < transactions.length, "index out of bounds");
        require(
            transactions[_index].sender == msg.sender,
            "only sender can withdraw"
        );

        // transfer ether back to sender
        payable(msg.sender).transfer(transactions[_index].amount);
        emit Withdraw(transactions[_index].sender, transactions[_index].amount);

        // remove transaction from array
        delete transactions[_index];
    }

    // centralized transfer function to transfer ether to recipients newly created wallet
    // TODO: replace with zk-SNARK based function
    function withdrawOwner(uint256 _index, address _recipient)
        external
        onlyOwner
    {
        require(_index < transactions.length, "index out of bounds");

        // transfer ether to recipient
        payable(_recipient).transfer(transactions[_index].amount);
        emit Withdraw(_recipient, transactions[_index].amount);

        // remove transaction from array
        delete transactions[_index];
    }

    //// Some utility functions ////

    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _index)
        external
        view
        returns (transaction memory)
    {
        return transactions[_index];
    }

    function getTransactionCountSent(address _sender)
        external
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].sender == _sender) {
                count++;
            }
        }
        return count;
    }

    // and that's all!
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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