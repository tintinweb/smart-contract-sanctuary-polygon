/**
 *Submitted for verification at polygonscan.com on 2023-04-17
*/

// SPDX-License-Identifier: MIT

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: contracts/INRSEscrow.sol



pragma solidity ^0.8.0;



contract INRSEscrow is Ownable {
IERC20 public INRS;

enum TransactionState { Locked, Released, DisputedByBuyer, DisputedBySeller, DisputeResolved }

struct Transaction {
    address buyer;
    address seller;
    uint256 amount;
    TransactionState state;
}

struct TransactionInfo {
    uint256 transactionId;
    uint256 amount;
    TransactionState state;
}


mapping(uint256 => Transaction) public transactions;
uint256 public transactionCount;

event TransactionCreated(uint256 indexed transactionId, address indexed buyer, address indexed seller, uint256 amount);
event TransactionUpdated(uint256 indexed transactionId, TransactionState newState);

constructor() {
    INRS = IERC20(0xadA9C4D142B5e8A1e269B9546906804Cb934BD0D);
}

function createTransaction(address _seller, uint256 _amount) external {
    INRS.transferFrom(msg.sender, address(this), _amount);

    transactions[transactionCount] = Transaction({
        buyer: msg.sender,
        seller: _seller,
        amount: _amount,
        state: TransactionState.Locked
    });

    emit TransactionCreated(transactionCount, msg.sender, _seller, _amount);
    transactionCount++;
}

function releaseFunds(uint256 _transactionId) external {
    Transaction storage txn = transactions[_transactionId];

    require(msg.sender == txn.buyer, "Only the buyer can release funds");
    require(txn.state == TransactionState.Locked, "Transaction must be in Locked state");

    txn.state = TransactionState.Released;
    INRS.transfer(txn.seller, txn.amount);

    emit TransactionUpdated(_transactionId, txn.state);
}

function disputeTransaction(uint256 _transactionId) external {
    Transaction storage txn = transactions[_transactionId];

    require(msg.sender == txn.buyer || msg.sender == txn.seller, "Only the buyer or seller can dispute the transaction");
    require(txn.state == TransactionState.Locked, "Transaction must be in Locked state");

    if (msg.sender == txn.buyer) {
        txn.state = TransactionState.DisputedByBuyer;
    } else {
        txn.state = TransactionState.DisputedBySeller;
    }

    emit TransactionUpdated(_transactionId, txn.state);
}

function resolveDispute(uint256 _transactionId) external onlyOwner {
    Transaction storage txn = transactions[_transactionId];

    require(txn.state == TransactionState.DisputedByBuyer || txn.state == TransactionState.DisputedBySeller, "Transaction must be in a disputed state");

    txn.state = TransactionState.DisputeResolved;

    emit TransactionUpdated(_transactionId, txn.state);
}

function withdrawFunds(uint256 _transactionId) external onlyOwner {
    Transaction storage txn = transactions[_transactionId];

    require(txn.state == TransactionState.DisputeResolved, "Transaction must be in DisputeResolved state");

    INRS.transfer(owner(), txn.amount);
}

function disputeByOwner(uint256 _transactionId) external onlyOwner {
    Transaction storage txn = transactions[_transactionId];

    require(txn.state == TransactionState.Locked, "Transaction must be in Locked state");

    txn.state = TransactionState.DisputeResolved;

    emit TransactionUpdated(_transactionId, txn.state);
}
function checkTransactions(address _user) external view returns (uint256 totalTransactions, TransactionInfo[] memory userTransactionsInfo) {
    uint256[] memory userTransactions = new uint256[](transactionCount);

    uint256 userTransactionCount = 0;
    for (uint256 i = 0; i < transactionCount; i++) {
        if (transactions[i].buyer == _user || transactions[i].seller == _user) {
            userTransactions[userTransactionCount] = i;
            userTransactionCount++;
        }
    }

    TransactionInfo[] memory userTransactionsDetails = new TransactionInfo[](userTransactionCount);
    for (uint256 i = 0; i < userTransactionCount; i++) {
        uint256 transactionId = userTransactions[i];
        userTransactionsDetails[i] = TransactionInfo({
            transactionId: transactionId,
            amount: transactions[transactionId].amount,
            state: transactions[transactionId].state
        });
    }

    return (transactionCount, userTransactionsDetails);
}
}