/**
 *Submitted for verification at polygonscan.com on 2023-05-09
*/

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/escrow.sol


pragma solidity ^0.8.7;



contract EscrowWallet {
    struct Transaction {
    address payer;
    address serviceProvider;
    uint256 originalAmount;
    uint256 remainingBalance;
    uint256 timestamp;
    uint256 lockPeriod;
    uint256 lockTimestamp;
    bool locked;
    bool completed;
    bool cancelled;
    string additionalInfo;
    address nativeToken;

    }

    struct DisputeInfo {
    uint256 txnId;
    string socialHandle;
    string serviceProvided;
    string disputeInformation;
    }

    struct Disputestatement {
    uint256 txnId;
    string socialHandleServiceProvider;
    string disputeInformationServiceProvider;

    }
    

struct Serviceproviderposting {
    address servicepostingadress;
    string socialhandleposting;
    string servicetitle;
    string servicedescription;
    uint256 price;
    uint256 postingid;
}

    mapping(uint256 => uint256) public nativeTokenBalances;
    mapping(uint256 => Transaction) public transactions;
    mapping (uint256 => DisputeInfo) public disputes;
    mapping (uint256 => Disputestatement) public disputesstatement;
    mapping(uint256 => Serviceproviderposting) public serviceposting;
    uint256 public nextPostingId = 0;
    mapping(address => uint256[]) public serviceProviderTransactions;
    uint256 public transactionCount;
    uint256 public feePercent = 4;
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function addTransaction(address _serviceProvider, string memory _additionalInfo, address _token, uint256 _amount) public payable {
    if (_token == address(0)) {
        require(msg.value > 0, "Invalid amount");
        _amount = msg.value;
        feePercent = 4;
    } else if (_token == 0xE08553A7aB8c6dEEfc742c2AEE18e9526973CFc0) {
        require(_amount > 0, "Invalid amount");
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        feePercent = 2;
    } else {
        revert("Invalid token"); // revert the transaction if token address is not valid
    }

    uint256 txnId = transactionCount++;
    uint256 fee = (_amount * feePercent) / 100;
    uint256 amountToLock = _amount - fee;
    uint256 lockPeriod = 2592000; // 30 days
    uint256 lockTimestamp = block.timestamp;
    transactions[txnId] = Transaction(msg.sender, _serviceProvider, amountToLock, amountToLock, block.timestamp, lockPeriod, lockTimestamp, true, false, false, _additionalInfo, _token);
    serviceProviderTransactions[_serviceProvider].push(txnId);

    if (_token == address(0)) {
        nativeTokenBalances[txnId] = amountToLock;
    }
}





    function dispute(uint256 _txnId, string memory socialhandle, string memory serviceprovided, string memory disputeinformation) public {
    require(msg.sender == admin || msg.sender == transactions[_txnId].payer || msg.sender == transactions[_txnId].serviceProvider, "Unauthorized");
    require(transactions[_txnId].locked == true, "Transaction not locked");
    transactions[_txnId].locked = false;
    transactions[_txnId].cancelled = true;

    disputes[_txnId] = DisputeInfo(_txnId, socialhandle, serviceprovided, disputeinformation);
}

function giveStatement(uint256 _txnId, string memory _socialHandleServiceProvider, string memory _disputeInformationServiceProvider) public {
    require(msg.sender == admin || msg.sender == transactions[_txnId].payer || msg.sender == transactions[_txnId].serviceProvider, "Unauthorized");
    require(transactions[_txnId].locked == false && transactions[_txnId].cancelled == true, "Invalid transaction");
    disputesstatement[_txnId] = Disputestatement(_txnId, _socialHandleServiceProvider, _disputeInformationServiceProvider);
}

function addServicePosting(string memory _socialhandleposting, string memory _servicedescription, string memory _servicetitle, uint256 _price) public {
    serviceposting[nextPostingId] = Serviceproviderposting(msg.sender, _socialhandleposting, _servicetitle, _servicedescription, _price, nextPostingId);
    nextPostingId++;
}


    function resolveDispute(uint256 _txnId, bool _sendToServiceProvider) public {
    require(msg.sender == admin, "Unauthorized");
    require(transactions[_txnId].cancelled == true, "Transaction not locked");
    transactions[_txnId].cancelled = false;
    address tokenAddr = transactions[_txnId].nativeToken;
    if (tokenAddr == address(0)) {
        if (_sendToServiceProvider) {
            uint256 amountToSend = transactions[_txnId].remainingBalance;
            payable(transactions[_txnId].serviceProvider).transfer(amountToSend);
            transactions[_txnId].completed = true;
            transactions[_txnId].remainingBalance = 0;
        } else {
            payable(transactions[_txnId].payer).transfer(transactions[_txnId].remainingBalance);
            transactions[_txnId].completed = true;
            transactions[_txnId].remainingBalance = 0;

        }
    } else {
        if (_sendToServiceProvider) {
            uint256 amountToSend = transactions[_txnId].remainingBalance;
            require(IERC20(tokenAddr).transfer(transactions[_txnId].serviceProvider, amountToSend), "Token transfer failed");
            transactions[_txnId].completed = true;
            transactions[_txnId].remainingBalance = 0;

        } else {
            require(IERC20(tokenAddr).transfer(transactions[_txnId].payer, transactions[_txnId].remainingBalance), "Token transfer failed");
            transactions[_txnId].completed = true;
            transactions[_txnId].remainingBalance = 0;
        }
    }
}




    function getTransactionsids(address _address) public view returns (uint256[] memory) {
    uint256[] memory txnIds = serviceProviderTransactions[_address];
    uint256[] memory payerTxnIds = new uint256[](transactionCount);
    uint256 count = 0;
    
    for (uint256 i = 0; i < transactionCount; i++) {
        if (transactions[i].payer == _address) {
            payerTxnIds[count] = i;
            count++;
        }
    }

 
    
    uint256[] memory allTxnIds = new uint256[](count + txnIds.length);
    uint256 index = 0;
    
    for (uint256 i = 0; i < txnIds.length; i++) {
        allTxnIds[index] = txnIds[i];
        index++;
    }
    
    for (uint256 i = 0; i < count; i++) {
        if (!contains(allTxnIds, payerTxnIds[i])) {
            allTxnIds[index] = payerTxnIds[i];
            index++;
        }
    }
    
    return allTxnIds;
}

function contains(uint256[] memory arr, uint256 val) internal pure returns (bool) {
    for (uint256 i = 0; i < arr.length; i++) {
        if (arr[i] == val) {
            return true;
        }
    }
    return false;
}




    function getServiceProviderTransactions(address _serviceProvider) public view returns (uint256[] memory) {
        return serviceProviderTransactions[_serviceProvider];
    }

    function getTransaction(uint256 _txnId) public view returns (address, uint256, bool, bool, bool, uint256, uint256) {
    return (
        transactions[_txnId].serviceProvider,
        transactions[_txnId].timestamp,
        transactions[_txnId].locked,
        transactions[_txnId].completed,
        transactions[_txnId].cancelled,
        transactions[_txnId].originalAmount,
        transactions[_txnId].remainingBalance
    );
}

 
function getPaymentsSent(address _payer) public view returns (uint256) {
    uint256 count = 0;
    for (uint256 i = 0; i < transactionCount; i++) {
        if (transactions[i].payer == _payer) {
            count++;
        }
    }
    return count;
}


function getPayersAndTimeLeft(address _serviceProvider) public view returns (address[] memory, uint256[] memory, uint256[] memory) {
    uint256[] memory txnIds = serviceProviderTransactions[_serviceProvider];
    address[] memory payers = new address[](txnIds.length);
    uint256[] memory timeLeft = new uint256[](txnIds.length);

    for (uint256 i = 0; i < txnIds.length; i++) {
        uint256 txnId = txnIds[i];
        Transaction storage txn = transactions[txnId];
        payers[i] = txn.payer;
        uint256 timeSinceLock = block.timestamp - txn.lockTimestamp;
        uint256 timeLeftInLockPeriod = (timeSinceLock >= txn.lockPeriod) ? 0 : (txn.lockPeriod - timeSinceLock);
        timeLeft[i] = (timeLeftInLockPeriod > 0) ? timeLeftInLockPeriod : 0;
    }
    
    uint256 completedOrCancelledCount = 0;
    for (uint256 i = 0; i < txnIds.length; i++) {
        uint256 txnId = txnIds[i];
        Transaction storage txn = transactions[txnId];
        if (txn.completed || txn.cancelled) {
            payers[i] = address(0);
            timeLeft[i] = 0;
            completedOrCancelledCount++;
        }
    }

    if (completedOrCancelledCount > 0) {
        uint256[] memory newTxnIds = new uint256[](txnIds.length - completedOrCancelledCount);
        address[] memory newPayers = new address[](txnIds.length - completedOrCancelledCount);
        uint256[] memory newTimeLeft = new uint256[](txnIds.length - completedOrCancelledCount);
        uint256 j = 0;
        for (uint256 i = 0; i < txnIds.length; i++) {
            if (payers[i] != address(0)) {
                newTxnIds[j] = txnIds[i];
                newPayers[j] = payers[i];
                newTimeLeft[j] = timeLeft[i];
                j++;
            }
        }
        txnIds = newTxnIds;
        payers = newPayers;
        timeLeft = newTimeLeft;
    }

    return (payers, timeLeft, txnIds);
}

function getServicePostings() public view returns (Serviceproviderposting[] memory) {
    Serviceproviderposting[] memory postings = new Serviceproviderposting[](nextPostingId);
    for (uint256 i = 0; i < nextPostingId; i++) {
        postings[i] = serviceposting[i];
    }
    return postings;
}




function getDisputeInfo(uint256 _txnId) public view returns (uint256, string memory, string memory, string memory) {
    require(msg.sender == admin, "Unauthorized");
    require(disputes[_txnId].txnId != 0, "No dispute for this transaction");
    return (disputes[_txnId].txnId, disputes[_txnId].socialHandle, disputes[_txnId].serviceProvided, disputes[_txnId].disputeInformation);
}


function getDisputeStatement(uint256 _txnId) public view returns (string memory, string memory) {
    require(msg.sender == admin, "Unauthorized");
    require(disputesstatement[_txnId].txnId != 0, "Dispute statement not found");
    return (disputesstatement[_txnId].socialHandleServiceProvider, disputesstatement[_txnId].disputeInformationServiceProvider);
}

function getCancelledTransactions() public view returns (uint256[] memory) {
    require(msg.sender == admin, "Unauthorized");
    uint256[] memory cancelledTxnIds = new uint256[](transactionCount);
    uint256 count = 0;
    
    for (uint256 i = 0; i < transactionCount; i++) {
        if (transactions[i].cancelled) {
            cancelledTxnIds[count] = i;
            count++;
        }
    }
    
    uint256[] memory result = new uint256[](count);
    
    for (uint256 i = 0; i < count; i++) {
        result[i] = cancelledTxnIds[i];
    }
    
    return result;
}

    function getServiceProvidersOpenDisputes(address _serviceProvider) public view returns (uint256) {
    uint256 count = 0;
    for (uint256 i = 0; i < transactionCount; i++) {
        if (transactions[i].serviceProvider == _serviceProvider && transactions[i].cancelled) {
            count++;
        }
    }
    return count;
    }

function editServicePosting(uint256 _postingId, string memory _socialhandleposting, string memory _servicedescription, string memory _servicetitle, uint256 _price) public {
    require(serviceposting[_postingId].servicepostingadress == msg.sender, "Unauthorized");
    serviceposting[_postingId] = Serviceproviderposting(msg.sender, _socialhandleposting, _servicetitle, _servicedescription, _price, _postingId);
}

function deleteServicePosting(uint256 _postingId) public {
    require(serviceposting[_postingId].servicepostingadress == msg.sender || msg.sender == admin, "Unauthorized");
    delete serviceposting[_postingId];
}



    function getWithdrawableAmountETH() public view returns (uint256) {
    uint256 totalAmount = 0;
    uint256[] memory txnIds = serviceProviderTransactions[msg.sender];
    for (uint256 i = 0; i < txnIds.length; i++) {
        uint256 txnId = txnIds[i];
        if (block.timestamp >= transactions[txnId].lockTimestamp + transactions[txnId].lockPeriod && transactions[txnId].cancelled == false && transactions[txnId].nativeToken == address(0)){
            totalAmount += transactions[txnId].remainingBalance;
        }
    }
    return totalAmount;
}

function getWithdrawableAmountNativeToken() public view returns (uint256) {
    uint256 totalAmount = 0;
    uint256[] memory txnIds = serviceProviderTransactions[msg.sender];
    
    for (uint256 i = 0; i < txnIds.length; i++) {
        uint256 txnId = txnIds[i];
        if (block.timestamp >= transactions[txnId].lockTimestamp + transactions[txnId].lockPeriod && transactions[txnId].cancelled == false && transactions[txnId].nativeToken == 0x97C0e83A1F23797434B4E68d9dabc11302C4a292){
            totalAmount += transactions[txnId].remainingBalance;
        }
    }
    
    return totalAmount;
}


    function withdrawETH() public {
uint256 withdrawableAmount = getWithdrawableAmountETH();
require(withdrawableAmount > 0, "No withdrawable amount");

uint256[] storage txnIds = serviceProviderTransactions[msg.sender];
for (uint256 i = 0; i < txnIds.length; i++) {
    uint256 txnId = txnIds[i];
    if (transactions[txnId].locked && !transactions[txnId].completed && !transactions[txnId].cancelled && transactions[txnId].nativeToken == address(0)) {
        transactions[txnId].completed = true;
        transactions[txnId].locked = false;
        transactions[txnId].remainingBalance = 0;

    }
}

payable(msg.sender).transfer(withdrawableAmount);

}

function withdrawNativeToken() public {
uint256 withdrawableAmount = getWithdrawableAmountNativeToken();
require(withdrawableAmount > 0, "No withdrawable amount");

uint256[] storage txnIds = serviceProviderTransactions[msg.sender];
for (uint256 i = 0; i < txnIds.length; i++) {
    uint256 txnId = txnIds[i];
    if (transactions[txnId].locked && !transactions[txnId].completed && !transactions[txnId].cancelled && transactions[txnId].nativeToken == 0x97C0e83A1F23797434B4E68d9dabc11302C4a292) {
        transactions[txnId].completed = true;
        transactions[txnId].locked = false;
        transactions[txnId].remainingBalance = 0;
    }
}
IERC20(0x97C0e83A1F23797434B4E68d9dabc11302C4a292).transfer(msg.sender, withdrawableAmount);
}

    function setFeePercent(uint256 _feePercent) public {
        require(msg.sender == admin, "Unauthorized");
        feePercent = _feePercent;
    }

    function withdrawFee(address payable _admin) public {
        require(msg.sender == admin, "Unauthorized");
        uint256 balance = address(this).balance;
        uint256 fee = (balance * feePercent) / 100;
        _admin.transfer(fee);
    }
}