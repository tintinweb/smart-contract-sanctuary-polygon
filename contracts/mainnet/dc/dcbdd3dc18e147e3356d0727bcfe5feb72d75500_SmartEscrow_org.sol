/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

//SPDX-License-Identifier: MIT

/**
*   For SmartEscrow.org USD (SEUSD) - Know more about the project at SmartEscrow.org
*
*   This contract will act as a central Escrow contract for all transactions on the SmartEscrow.org
*
*/


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

// File: contracts/SmartEscrow_org.sol



/**
 *   For SmartEscrow.org USD (SEUSD) - Know more about the project at SmartEscrow.org
 *
 *   This contract will act as a central Escrow contract for all transactions on the SmartEscrow.org
 *
 */

pragma solidity ^0.8.0;



contract SmartEscrow_org is Ownable {
    IERC20 public SEUSD;

    enum TransactionState { Locked, Delivered, Released, DisputedByBuyer, DisputedBySeller, DisputeResolved }

    struct Transaction {
        address buyer;
        address seller;
        uint256 amount;
        TransactionState state;
        string optionalMessage;
        uint256 optionalTimeInDays;
        uint256 createdAt;
        uint256 deliveredAt;
        uint256 releasedAt;
        uint256 disputedByBuyerAt;
        uint256 disputedBySellerAt;
        uint256 disputeResolvedAt;
    }

    struct TransactionInfo {
        

        uint256 transactionId;
        uint256 amount;
        TransactionState state;
        string optionalMessage;
        uint256 optionalTimeInDays;

        address buyer;
        address seller;
        
        uint256 deliveredAt;
        uint256 releasedAt;
        uint256 disputedByBuyerAt;
        uint256 disputedBySellerAt;
        uint256 disputeResolvedAt;
    }

    mapping(uint256 => Transaction) public transactions;
    uint256 public transactionCount;

    event TransactionCreated(
        uint256 indexed transactionId,
        address indexed buyer,
        address indexed seller,
        uint256 amount,
        string optionalMessage,
        uint256 optionalTimeInDays
    );

    event TransactionUpdated(uint256 indexed transactionId, TransactionState newState);
    event DisputeResolved(uint256 indexed transactionId);
    event FundsWithdrawn(uint256 indexed transactionId, uint256 amount);

    constructor() {
        SEUSD = IERC20(0x1Ae55197895ef0c09F3268320C6dceB2F2F17349);
    }

    function createTransaction(
        address _seller,
        uint256 _amount,
        string calldata _optionalMessage,
        uint256 _optionalTimeInDays
    ) external {
        require(_seller != address(0), "Invalid seller address");
        require(_amount > 0, "Amount must be greater than 0");
        require(_optionalTimeInDays <= 365, "Optional time in days must not exceed 365 days");

        SEUSD.transferFrom(msg.sender, address(this), _amount);

        transactions[transactionCount] = Transaction({
            buyer: msg.sender,
            seller: _seller,
            amount: _amount,
            state: TransactionState.Locked,
            optionalMessage: _optionalMessage,
            optionalTimeInDays: _optionalTimeInDays,
            createdAt: block.timestamp,
            deliveredAt: 0,
            releasedAt: 0,
            disputedByBuyerAt: 0,
            disputedBySellerAt: 0,
            disputeResolvedAt: 0
        });

        emit TransactionCreated(transactionCount, msg.sender, _seller, _amount, _optionalMessage, _optionalTimeInDays);
        transactionCount++;
    }

    function deliver(uint256 _transactionId) external {
        Transaction storage txn = transactions[_transactionId];

        require(msg.sender == txn.seller, "Only the seller can deliver the product/service");
        require(txn.state == TransactionState.Locked, "Transaction must be in Locked state");

        txn.state = TransactionState.Delivered;
        txn.deliveredAt = block.timestamp;

        emit TransactionUpdated(_transactionId, txn.state);
    }

    function releaseFunds(uint256 _transactionId) external {
        Transaction storage txn = transactions[_transactionId];

        require(msg.sender == txn.buyer, "Only the buyer can release funds");
        require(txn.state == TransactionState.Delivered, "Transaction must be in Delivered state");

        txn.state = TransactionState.Released;
        txn.releasedAt = block.timestamp;
        SEUSD.transfer(txn.seller, txn.amount);

        emit TransactionUpdated(_transactionId, txn.state);
    }

    function disputeTransaction(uint256 _transactionId) external {
        Transaction storage txn = transactions[_transactionId];

        require(msg.sender == txn.buyer || msg.sender == txn.seller, "Only the buyer or seller can dispute the transaction");
        require(txn.state == TransactionState.Locked || txn.state == TransactionState.Delivered, "Transaction must be in Locked or Delivered state");

        if (msg.sender == txn.buyer) {
            txn.state = TransactionState.DisputedByBuyer;
            txn.disputedByBuyerAt = block.timestamp;
        } else {
            txn.state = TransactionState.DisputedBySeller;
            txn.disputedBySellerAt = block.timestamp;
        }

        emit TransactionUpdated(_transactionId, txn.state);
    }

    function resolveDispute(uint256 _transactionId) external onlyOwner {
        Transaction storage txn = transactions[_transactionId];

        require(txn.state == TransactionState.DisputedByBuyer || txn.state == TransactionState.DisputedBySeller, "Transaction must be in a disputed state");

        txn.state = TransactionState.DisputeResolved;
        txn.disputeResolvedAt = block.timestamp;

        emit TransactionUpdated(_transactionId, txn.state);
        emit DisputeResolved(_transactionId);
    }

    function withdrawFunds(uint256 _transactionId) external onlyOwner {
        Transaction storage txn = transactions[_transactionId];

        require(txn.state == TransactionState.DisputeResolved, "Transaction must be in DisputeResolved state");

        uint256 amountToWithdraw = txn.amount;
        txn.amount = 0;

        SEUSD.transfer(owner(), amountToWithdraw);

        emit FundsWithdrawn(_transactionId, amountToWithdraw);
    }

    function disputeByOwner(uint256 _transactionId) external onlyOwner {
        Transaction storage txn = transactions[_transactionId];

        require(txn.state == TransactionState.Locked, "Transaction must be in Locked state");

        txn.state = TransactionState.DisputeResolved;
        txn.disputeResolvedAt = block.timestamp;

        emit TransactionUpdated(_transactionId, txn.state);
    }

    modifier onlyBuyerOrSeller(uint256 _transactionId) {
        require(
            msg.sender == transactions[_transactionId].buyer || msg.sender == transactions[_transactionId].seller,
            "Only the buyer or seller can call this function"
        );
        _;
    }

    function releaseFundsAfterOptionalTime(uint256 _transactionId) external onlyBuyerOrSeller(_transactionId) {
        Transaction storage txn = transactions[_transactionId];

        require(txn.state == TransactionState.Delivered, "Transaction must be in Delivered state");
        require(txn.optionalTimeInDays > 0, "Optional time must be greater than 0");

        uint256 timePassedInDays = (block.timestamp - txn.createdAt) / 1 days;
        require(timePassedInDays >= txn.optionalTimeInDays, "Optional time has not yet passed");

        txn.state = TransactionState.Released;
        txn.releasedAt = block.timestamp;
        SEUSD.transfer(txn.seller, txn.amount);

        emit TransactionUpdated(_transactionId, txn.state);
    }

    function checkTransactions(address _user)
        external
        view
        returns (uint256 totalTransactions, TransactionInfo[] memory userTransactionsInfo)
    {
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
                state: transactions[transactionId].state,
                optionalMessage: transactions[transactionId].optionalMessage,
                optionalTimeInDays: transactions[transactionId].optionalTimeInDays,
                buyer: transactions[transactionId].buyer,
                seller: transactions[transactionId].seller,
                deliveredAt: transactions[transactionId].deliveredAt,
                releasedAt: transactions[transactionId].releasedAt,
                disputedByBuyerAt: transactions[transactionId].disputedByBuyerAt,
                disputedBySellerAt: transactions[transactionId].disputedBySellerAt,
                disputeResolvedAt: transactions[transactionId].disputeResolvedAt
            });
        }

        return (transactionCount, userTransactionsDetails);
    }
}