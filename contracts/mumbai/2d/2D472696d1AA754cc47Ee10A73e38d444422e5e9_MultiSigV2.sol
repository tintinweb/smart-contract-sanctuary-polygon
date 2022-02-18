/**
 *Submitted for verification at polygonscan.com on 2022-02-18
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File: contracts/MultiSigV2.sol


pragma solidity ^0.8.6;




contract MultiSigV2 is ReentrancyGuard {

    using SafeERC20 for IERC20;

    enum TransactionType{ ETHER, TOKEN }

    /*
     *  Constants
     */
    uint constant MIN_REQUIRED = 1;
    uint constant DEV_OWNER_CLASS = 1;
    uint constant A_OWNER_CLASS = 2;
    uint constant B_OWNER_CLASS = 3;



    /*
     *  Events
     */
    event Confirmation(address indexed sender, uint indexed transactionId);
    event OwnerConfirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId, TransactionType indexed tx);
    event DevOwnerSubmission(uint indexed transactionId);
    event AOwnerSubmission(uint indexed transactionId);
    event BOwnerSubmission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event DevOwnerAddition(address indexed owner);
    event AOwnerAddition(address indexed owner);
    event BOwnerAddition(address indexed owner);



    /*
     *  Storage
     */  
    mapping(uint => Transaction) public transactions;
    mapping(uint => OwnerTransaction) public ownerTransactions;

    mapping(uint => mapping(address => bool)) public confirmations;
    mapping(uint => mapping(address => bool)) public ownerConfirmations;

    mapping (address => bool) public isDevOwner;
    mapping (address => bool) public isAOwner;
    mapping (address => bool) public isBOwner;

    address[] public devOwners;
    address[] public aOwners;
    address[] public bOwners;

    uint public required;
    uint public transactionCount;
    uint public ownerTransactionCount;
    uint requiredFromEachGroup;

    struct Transaction {
        TransactionType txType;
        IERC20 token;
        address payable destination;
        uint value;
        bool executed;
    }

    struct OwnerTransaction {
        address owner;
        uint class;
        bool executed;
    }


    // Modifiers
    
    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!(isAOwner[owner] || isBOwner[owner] || isDevOwner[owner]));
        _;
    }

    modifier ownerExists(address owner) {
        require(isAOwner[owner] || isBOwner[owner] || isDevOwner[owner]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != address(0));
        _;
    }

    modifier ownerTransactionExists(uint transactionId) {
        require(ownerTransactions[transactionId].owner != address(0));
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier ownerConfirmed(uint transactionId, address owner) {
        require(ownerConfirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier ownerNotConfirmed(uint transactionId, address owner) {
        require(!ownerConfirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier ownerNotExecuted(uint transactionId) {
        require(!ownerTransactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }

    modifier validRequirement(
        uint _devOwnerCount,
        uint _aOwnerCount,
        uint _bOwnerCount,
        uint _requiredFromEachGroup
    ) {
        require(
            _devOwnerCount > 1 &&
            _aOwnerCount > 1 &&
            _bOwnerCount > 1 &&
            requiredFromEachGroup >= MIN_REQUIRED
        );
        _;
    }


    constructor(
        address[] memory _devOwners, 
        address[] memory _aOwners,
        address[] memory _bOwners,
        uint _requiredFromEachGroup
    )
    {
        requiredFromEachGroup = _requiredFromEachGroup;

        uint i;
        for (i=0; i < _devOwners.length; i++) {
            require(!isDevOwner[_devOwners[i]] && _devOwners[i] != address(0));
            isDevOwner[_devOwners[i]] = true;
        }
        for (i=0; i < _aOwners.length; i++) {
            require(!isAOwner[_aOwners[i]] && _aOwners[i] != address(0));
            isAOwner[_aOwners[i]] = true;
        }
        for (i=0; i < _bOwners.length; i++) {
            require(!isBOwner[_bOwners[i]] && _bOwners[i] != address(0));
            isBOwner[_bOwners[i]] = true;
        }
        aOwners = _aOwners;
        bOwners = _bOwners;
        devOwners = _devOwners;
    }

    receive() payable external {
        require(msg.value > 0);
        
        emit Deposit(msg.sender, msg.value);
    }


    /*
     * Public functions
     */

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addDevOwner(address owner)
        external
        ownerDoesNotExist(owner)
        notNull(owner)
        returns (uint ownerTransactionId)
    {
        ownerTransactionId = addDevOwnerTransaction(owner);
        _confirmOwnerTransaction(ownerTransactionId);
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addAOwner(address owner)
        external
        ownerDoesNotExist(owner)
        notNull(owner)
        returns (uint ownerTransactionId)
    {
        ownerTransactionId = addAOwnerTransaction(owner);
        _confirmOwnerTransaction(ownerTransactionId);
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addBOwner(address owner)
        external
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        returns (uint ownerTransactionId)
    {
        ownerTransactionId = addBOwnerTransaction(owner);
        _confirmOwnerTransaction(ownerTransactionId);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @return transactionId Returns transaction ID.
    function submitTransaction(address payable destination, uint value)
        external
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value);
        _confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @return transactionId Returns transaction ID.
    function submitERC20Transaction(IERC20 token, address payable destination, uint value)
        external
        returns (uint transactionId)
    {
        transactionId = addERC20Transaction(token, destination, value);
        _confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        external
        nonReentrant
    {
        _confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param ownerTransactionId Transaction ID.
    function confirmOwnerTransaction(uint ownerTransactionId)
        external
        nonReentrant
    {
        _confirmOwnerTransaction(ownerTransactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        external
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /*
     * Internal functions
     */

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function _confirmTransaction(uint transactionId)
        internal
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        internal
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if(isConfirmed(transactionId)){
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if(txn.txType == TransactionType.ETHER){
                (bool success, ) = txn.destination.call{value:txn.value}("");
                if (success)
                    emit Execution(transactionId);
                else {
                    emit ExecutionFailure(transactionId);
                    txn.executed = false;
                }
            }

            if(txn.txType == TransactionType.TOKEN){
                address destination = txn.destination;
                uint value = txn.value;
                bool success = txn.token.transfer(destination, value);

                if (success)
                    emit Execution(transactionId);
                else {
                    emit ExecutionFailure(transactionId);
                    txn.executed = false;
                }
            }

        }
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        internal
        view
        returns (bool)
    {
        uint countDev = 0;
        uint countA = 0;
        uint countB = 0;
        uint i = 0;
        for (i=0; i < devOwners.length; i++)
            if (confirmations[transactionId][devOwners[i]])
                countDev += 1;
        for (i=0; i < aOwners.length; i++)
            if (confirmations[transactionId][aOwners[i]])
                countA += 1;
        for (i=0; i < bOwners.length; i++)
            if (confirmations[transactionId][bOwners[i]])
                countB += 1;
        return(
            countDev >= requiredFromEachGroup &&
            countA >= requiredFromEachGroup &&
            countB >= requiredFromEachGroup
        );
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @return transactionId Returns transaction ID.
    function addTransaction(address payable destination, uint value)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            txType: TransactionType.ETHER, 
            token: IERC20(address(0)),
            destination: destination,
            value: value,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId, TransactionType.ETHER);
    }

    /// @dev Adds a new ERC20 transaction to the transaction mapping, if transaction does not exist yet.
    /// @param token Token contract address.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @return transactionId Returns transaction ID.
    function addERC20Transaction(IERC20 token, address payable destination, uint value)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            txType: TransactionType.TOKEN, 
            token: IERC20(token),
            destination: destination,
            value: value,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId, TransactionType.TOKEN);
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param owner Transaction target address.
    /// @return transactionId Returns transaction ID.
    function addDevOwnerTransaction(address owner)
        internal
        notNull(owner)
        returns (uint transactionId)
    {
        transactionId = ownerTransactionCount;
        ownerTransactions[transactionId] = OwnerTransaction({
            owner: owner,
            class: DEV_OWNER_CLASS,
            executed: false
        });
        ownerTransactionCount += 1;
        emit DevOwnerSubmission(transactionId);
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param owner Transaction target address.
    /// @return transactionId Returns transaction ID.
    function addAOwnerTransaction(address owner)
        internal
        notNull(owner)
        returns (uint transactionId)
    {
        transactionId = ownerTransactionCount;
        ownerTransactions[transactionId] = OwnerTransaction({
            owner: owner,
            class: A_OWNER_CLASS,
            executed: false
        });
        ownerTransactionCount += 1;
        emit AOwnerSubmission(transactionId);
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param owner Transaction target address.
    /// @return transactionId Returns transaction ID.
    function addBOwnerTransaction(address owner)
        internal
        notNull(owner)
        returns (uint transactionId)
    {
        transactionId = ownerTransactionCount;
        ownerTransactions[transactionId] = OwnerTransaction({
            owner: owner,
            class: B_OWNER_CLASS,
            executed: false
        });
        ownerTransactionCount += 1;
        emit BOwnerSubmission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return count Number of confirmations.
    function getConfirmationCount(uint transactionId)
        external
        view
        returns (uint count)
    {
        uint i;
        for (i=0; i<devOwners.length; i++)
            if (confirmations[transactionId][devOwners[i]])
                count += 1;
        for (i=0; i<aOwners.length; i++)
            if (confirmations[transactionId][aOwners[i]])
                count += 1;
        for (i=0; i<bOwners.length; i++)
            if (confirmations[transactionId][bOwners[i]])
                count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return count Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        external
        view
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return _confirmations Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        external
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](devOwners.length + aOwners.length + bOwners.length);
        uint count = 0;
        uint i;
        for (i=0; i<devOwners.length; i++)
            if (confirmations[transactionId][devOwners[i]]) {
                confirmationsTemp[count] = devOwners[i];
                count += 1;
            }
        for (i=0; i<aOwners.length; i++)
            if (confirmations[transactionId][aOwners[i]]) {
                confirmationsTemp[count] = aOwners[i];
                count += 1;
            }
        for (i=0; i<bOwners.length; i++)
            if (confirmations[transactionId][bOwners[i]]) {
                confirmationsTemp[count] = bOwners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return _transactionIds Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        external
        view
        returns (uint[] memory _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return _ownerTransactionIds Returns array of transaction IDs.
    function getOwnerTransactionIds(uint from, uint to, bool pending, bool executed)
        external
        view
        returns (uint[] memory _ownerTransactionIds)
    {
        uint[] memory ownerTransactionIdsTemp = new uint[](ownerTransactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !ownerTransactions[i].executed
                || executed && ownerTransactions[i].executed)
            {
                ownerTransactionIdsTemp[count] = i;
                count += 1;
            }
        _ownerTransactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _ownerTransactionIds[i - from] = ownerTransactionIdsTemp[i];
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function _confirmOwnerTransaction(uint transactionId)
        internal
        ownerExists(msg.sender)
        ownerTransactionExists(transactionId)
        ownerNotConfirmed(transactionId, msg.sender)
    {
        ownerConfirmations[transactionId][msg.sender] = true;
        emit OwnerConfirmation(msg.sender, transactionId);
        executeOwnerTransaction(transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param ownerTransactionId Transaction ID.
    function executeOwnerTransaction(uint ownerTransactionId)
        internal
        ownerExists(msg.sender)
        ownerConfirmed(ownerTransactionId, msg.sender)
        ownerNotExecuted(ownerTransactionId)
    {
        if (isOwnerConfirmed(ownerTransactionId)) {
            OwnerTransaction storage ownerTransaction = ownerTransactions[ownerTransactionId];
            if (ownerTransaction.class == DEV_OWNER_CLASS) {
                isDevOwner[ownerTransaction.owner] = true;
                devOwners.push(ownerTransaction.owner);
                ownerTransaction.executed = true;
                emit DevOwnerAddition(ownerTransaction.owner);
            }
            if (ownerTransaction.class == A_OWNER_CLASS) {
                isAOwner[ownerTransaction.owner] = true;
                aOwners.push(ownerTransaction.owner);
                ownerTransaction.executed = true;
                emit AOwnerAddition(ownerTransaction.owner);
            }
            if (ownerTransaction.class == B_OWNER_CLASS) {
                isBOwner[ownerTransaction.owner] = true;
                bOwners.push(ownerTransaction.owner);
                ownerTransaction.executed = true;
                emit BOwnerAddition(ownerTransaction.owner);
            }
        }
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isOwnerConfirmed(uint transactionId)
        internal
        view
        returns (bool)
    {
        uint countDev = 0;
        uint countA = 0;
        uint countB = 0;
        uint i = 0;
        for (i=0; i < devOwners.length; i++)
            if (ownerConfirmations[transactionId][devOwners[i]])
                countDev += 1;
        for (i=0; i < aOwners.length; i++)
            if (ownerConfirmations[transactionId][aOwners[i]])
                countA += 1;
        for (i=0; i < bOwners.length; i++)
            if (ownerConfirmations[transactionId][bOwners[i]])
                countB += 1;
        return(
            countDev >= requiredFromEachGroup &&
            countA >= requiredFromEachGroup &&
            countB >= requiredFromEachGroup
        );
    }








}