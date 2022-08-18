// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Multisig {
    struct Transaction {
        uint256 id; // Transaction ID
        address smartContract;
        bytes data; // Data for the external or internal transaction
        address[] approvedBy;
        uint timestamp;
        bool externalTx; // If to call external Smart Contract or local
        bool executed; // Transaction has been executed
        bool declined; // Transaction proposal has been declined
    }

    // Who can submit and sign transactions
    mapping (address => bool) public signers;

    // Size of signers (true)
    uint16 public signersTotal;

    // Minimum number of signatures required to process transactions
    uint16 public immutable signaturesRequired;

    // Transactions
    Transaction[] public transactions;

    modifier onlySigner(){
        require(signers[msg.sender] == true, "Only Signers");
        _;
    }

    modifier onlyMultisig(){
        require(msg.sender == address(this), "Only Multisig");
        _;
    }

    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "Transaction does not exist");
        _;
    }

    modifier txPending(uint256 _txId) {
        require(!transactions[_txId].executed, "Transaction already executed");
        require(!transactions[_txId].declined, "Transaction already declined");
        _;
    }

    event TransactionSumbitted(
        uint256 indexed id,
        address initiatedBy
    );

    event TransactionApproved(
        uint256 id,
        address approvedBy
    );

    event TransactionDeclined(
        uint256 id,
        address approvedBy
    );

    event TransactionExecuted(
        uint256 id,
        address approvedBy
    );

    event CoSignerAdded(
        address account
    );

    event CoSignerRemoved(
        address account
    );

    event Withdrawn(
        address account,
        uint256 amount
    );


    constructor(address[] memory _signers, uint16 _signaturesRequired) {
        require(_signers.length >= _signaturesRequired, "Invalid number of signatures");
        require(_signaturesRequired >= 2, "Invalid number of signatures");

        for (uint16 i = 0; i < _signers.length; i++) {
            require(_signers[i] != address(0), "Invalid signer");
            require(!signers[_signers[i]], "Signer not unique");

            signers[_signers[i]] = true;
        }

        signaturesRequired = _signaturesRequired;
        signersTotal = uint16(_signers.length);
    }


    /// @notice Create transaction proposal
    /// @param _data data for external transaction | method for internal transaction
    /// @return bool
    function submitTransaction(address _smartContract, bytes memory _data, bool _externalTx)
    external
    onlySigner
    returns (uint256)
    {
        // Do not allow internal call through external
        require(!(_externalTx == true && _smartContract == address(this)), "External call can not be made to the Smart Contract");

        address[] memory _approvedBy = new address[](1);
        _approvedBy[0] = msg.sender;

        uint256 txId = transactions.length;

        transactions.push(Transaction({id: txId, smartContract: _smartContract, data: _data, approvedBy: _approvedBy, timestamp: block.timestamp, externalTx: _externalTx, executed: false, declined: false}));

        emit TransactionSumbitted(
            (transactions.length - 1),
            msg.sender
        );

        return transactions.length - 1;
    }

    /// @notice Confirm transaction proposal
    /// @param _txId transaction proposal ID
    /// @return bool
    function confirmTransaction(uint256 _txId)
    external
    onlySigner
    txExists(_txId)
    txPending(_txId)

    returns (bool)
    {
        for (uint16 i = 0; i < transactions[_txId].approvedBy.length; i++) {
            require(transactions[_txId].approvedBy[i] != msg.sender, "Already approved");
        }

        transactions[_txId].approvedBy.push(msg.sender);

        emit TransactionApproved(
            _txId,
            msg.sender
        );

        return true;
    }

    /// @notice Get transactions
    /// @param _start transaction proposal start
    /// @param _total transaction proposal total
    /// @return Transaction memory
    function getTransactions(uint256 _start, uint256 _total) external view returns (Transaction[] memory) {
        require(_total > 0, "Invalid total");
        require((_start + _total) <= transactions.length, "Out of range");

        Transaction[] memory txs = new Transaction[]((_total));
        uint256 counter;

        for (uint256 i = _start; i < (_start + _total); i++) {
            txs[counter] = transactions[i];
            counter ++;
        }

        return txs;
    }

    /// @notice Get transaction details
    /// @param _txId transaction proposal ID
    /// @return Transaction memory
    function getTransaction(uint256 _txId) external view returns (Transaction memory) {
        return transactions[_txId];
    }

    /// @notice Total number of transactions
    /// @return uint256
    function transactionsTotal() external view returns (uint256) {
        return transactions.length;
    }

    /// @notice Decline transaction proposal
    /// @param _txId transaction proposal ID
    /// @return bool
    function declineTransaction(uint256 _txId)
    external
    onlySigner
    txExists(_txId)
    txPending(_txId)

    returns (bool)
    {
        transactions[_txId].declined = true;

        emit TransactionDeclined(
            _txId,
            msg.sender
        );

        return true;
    }

    /// @notice Execute transaction proposal
    /// @param _txId transaction proposal ID
    /// @return bool
    function executeTransaction(uint256 _txId)
    external
    onlySigner
    txExists(_txId)
    txPending(_txId)
    returns (bool)
    {
        require(transactions[_txId].approvedBy.length >= signaturesRequired, "Not enough signatures");

        transactions[_txId].executed = true;

        bool success = false;

        // External transaction
        if (transactions[_txId].externalTx == true) {
            (success, ) = transactions[_txId].smartContract.call(transactions[_txId].data);
        } else { // Internal transaction
            (success, ) = address(this).call(transactions[_txId].data);
        }

        require(success == true, "Transaction Failed");

        emit TransactionExecuted(
            _txId,
            msg.sender
        );

        return true;
    }

    /// Multisig Methods

    /// @notice Add Co Signer
    /// @param _account account
    /// @return bool
    function addCoSigner(address _account)
    external
    onlyMultisig
    returns(bool)
    {
        signers[_account] = true;
        signersTotal += 1;

        emit CoSignerAdded(
            _account
        );

        return true;
    }

    /// @notice Remove Co Signer
    /// @param _account account
    /// @return bool
    function removeCoSigner(address _account)
    external
    onlyMultisig
    returns(bool)
    {
        // Prevent self lock
        require(signersTotal > 3, "Not enough signers");

        signers[_account] = false;
        signersTotal -= 1;

        emit CoSignerRemoved(
            _account
        );

        return true;
    }

    /// @notice Remove Co Signer
    /// @param _token token address
    /// @param _account account to withdraw token to
    /// @return bool
    function withdrawToken(IERC20 _token, address _account)
    external
    onlyMultisig
    returns(bool)
    {
        uint balance = _token.balanceOf(address(this));

        require(balance > 0, "Not enough funds");

        (bool success) = _token.transfer(_account, balance);
        require(success == true, "Transfer Failed");

        emit Withdrawn(
            _account,
            balance
        );

        return true;
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