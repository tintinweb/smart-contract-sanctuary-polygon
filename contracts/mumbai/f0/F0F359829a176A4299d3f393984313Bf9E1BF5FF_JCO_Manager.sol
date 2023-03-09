// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
pragma solidity >=0.8.0 <0.9.0;
/**
 * @title Treasury MultiSignature Contract
 * @dev Will call the functions from the treasury
 * -- #3 -- Deployed after the token contract
 */

import "./JCO.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"]
contract Fundraising {
    IERC20 private token;
    address public manager;

    event Transfer_JCO(address from, address to, uint256 amount);
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex, address msg_sender) {
        require(!isConfirmed[_txIndex][msg_sender], "tx already confirmed");
        _;
    }
    modifier onlyManager() {
        require(msg.sender == manager, "Not owner");
        _;
    }
    constructor(
        address[] memory _owners,
        uint256 _numConfirmationsRequired,
        address _token,
        address _manager
    ) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        token = IERC20(_token);
        manager = _manager;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyManager {
        uint256 txIndex = transactions.length;
        require(_value > 0, "Value must be greater than zero");

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txIndex, address msg_sender)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex, msg_sender)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg_sender] = true;

        emit ConfirmTransaction(msg_sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
        uint256 amount = transaction.value * (10**18);
        uint256 token_balance = token.balanceOf(address(this));
        require(amount <= token_balance, "token balance is low");

        address from = address(this);
        address to = transaction.to;

        // bool success = token.transferFrom(from, transaction.to, amount);
        // require(success, "tx failed");
        require(token.transfer(transaction.to, amount), "tx failed");
        transaction.executed = true;

        emit Transfer_JCO(from, to, amount);
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex, address msg_sender)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg_sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg_sender] = false;

        emit RevokeConfirmation(msg_sender, _txIndex);
    }

    function getOwners() external onlyManager view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external onlyManager view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex)
        external onlyManager
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    function getContractAddress() public view returns (address) {
        return address(this);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
/**
 * @title Treasury MultiSignature Contract
 * @dev Will call the functions from the treasury
 * -- #3 -- Deployed after the token contract
 */

import "./JCO.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]
contract Rewards {
    IERC20 private token;
    address public manager;

    event Transfer_JCO(address from, address to, uint256 amount);
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex, address msg_sender) {
        require(!isConfirmed[_txIndex][msg_sender], "tx already confirmed");
        _;
    }
    modifier onlyManager() {
        require(msg.sender == manager, "Not owner");
        _;
    }
    constructor(
        address[] memory _owners,
        uint256 _numConfirmationsRequired,
        address _token,
        address _manager
    ) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        token = IERC20(_token);
        manager = _manager;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyManager {
        uint256 txIndex = transactions.length;
        require(_value > 0, "Value must be greater than zero");

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txIndex, address msg_sender)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex, msg_sender)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg_sender] = true;

        emit ConfirmTransaction(msg_sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
        uint256 amount = transaction.value * (10**18);
        uint256 token_balance = token.balanceOf(address(this));
        require(amount <= token_balance, "token balance is low");

        address from = address(this);
        address to = transaction.to;

        // bool success = token.transferFrom(from, transaction.to, amount);
        // require(success, "tx failed");
        require(token.transfer(transaction.to, amount), "tx failed");
        transaction.executed = true;

        emit Transfer_JCO(from, to, amount);
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex, address msg_sender)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg_sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg_sender] = false;

        emit RevokeConfirmation(msg_sender, _txIndex);
    }

    function getOwners() external onlyManager view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external onlyManager view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex)
        external onlyManager
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
/**
 * @title Treasury MultiSignature Contract
 * @dev Will call the functions from the treasury
 * -- #3 -- Deployed after the token contract
 */

import "./JCO.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"]
contract Team {
    IERC20 private token;
    address public manager;

    event Transfer_JCO(address from, address to, uint256 amount);
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex, address msg_sender) {
        require(!isConfirmed[_txIndex][msg_sender], "tx already confirmed");
        _;
    }
    modifier onlyManager() {
        require(msg.sender == manager, "Not owner");
        _;
    }
    constructor(
        address[] memory _owners,
        uint256 _numConfirmationsRequired,
        address _token,
        address _manager
    ) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        token = IERC20(_token);
        manager = _manager;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyManager {
        uint256 txIndex = transactions.length;
        require(_value > 0, "Value must be greater than zero");

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txIndex, address msg_sender)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex, msg_sender)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg_sender] = true;

        emit ConfirmTransaction(msg_sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        address from = address(this);
        address to = transaction.to;
        uint256 amount = transaction.value;

        // token.transferFrom(, transaction.to, amount);

        bool success = token.transfer(transaction.to, amount);
        require(success, "tx failed");
        emit Transfer_JCO(from, to, amount);
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex, address msg_sender)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg_sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg_sender] = false;

        emit RevokeConfirmation(msg_sender, _txIndex);
    }

    function getOwners() external onlyManager view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external onlyManager view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex)
        external onlyManager
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    function getContractAddress() public view returns (address) {
        return address(this);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
/**
 * @title Treasury MultiSignature Contract
 * @dev Will call the functions from the treasury
 * -- #3 -- Deployed after the token contract
 */

import "./JCO.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"]
contract Advisors {
    IERC20 private token;
    address public manager;

    event Transfer_JCO(address from, address to, uint256 amount);
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex, address msg_sender) {
        require(!isConfirmed[_txIndex][msg_sender], "tx already confirmed");
        _;
    }
    modifier onlyManager() {
        require(msg.sender == manager, "Not owner");
        _;
    }
    constructor(
        address[] memory _owners,
        uint256 _numConfirmationsRequired,
        address _token,
        address _manager
    ) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        token = IERC20(_token);
        manager = _manager;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyManager {
        uint256 txIndex = transactions.length;
        require(_value > 0, "Value must be greater than zero");

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txIndex, address msg_sender)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex, msg_sender)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg_sender] = true;

        emit ConfirmTransaction(msg_sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
        uint256 amount = transaction.value * (10**18);
        uint256 token_balance = token.balanceOf(address(this));
        require(amount <= token_balance, "token balance is low");

        address from = address(this);
        address to = transaction.to;

        // bool success = token.transferFrom(from, transaction.to, amount);
        // require(success, "tx failed");
        require(token.transfer(transaction.to, amount), "tx failed");
        transaction.executed = true;

        emit Transfer_JCO(from, to, amount);
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex, address msg_sender)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg_sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg_sender] = false;

        emit RevokeConfirmation(msg_sender, _txIndex);
    }

    function getOwners() external onlyManager view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external onlyManager view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex)
        external onlyManager
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
/**
 * @title Treasury MultiSignature Contract
 * @dev Will call the functions from the treasury
 * -- #3 -- Deployed after the token contract
 */

import "./JCO.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]
contract Marketing {
    IERC20 private token;
    address public manager;
    
    event Transfer_JCO(address from, address to, uint256 amount);
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex, address msg_sender) {
        require(!isConfirmed[_txIndex][msg_sender], "tx already confirmed");
        _;
    }
    modifier onlyManager() {
        require(msg.sender == manager, "Not owner");
        _;
    }
    constructor(
        address[] memory _owners,
        uint256 _numConfirmationsRequired,
        address _token,
        address _manager
    ) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        token = IERC20(_token);
        manager = _manager;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyManager {
        uint256 txIndex = transactions.length;
        require(_value > 0, "Value must be greater than zero");

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txIndex, address msg_sender)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex, msg_sender)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg_sender] = true;

        emit ConfirmTransaction(msg_sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
        uint256 amount = transaction.value * (10**18);
        uint256 token_balance = token.balanceOf(address(this));
        require(amount <= token_balance, "token balance is low");

        address from = address(this);
        address to = transaction.to;

        // bool success = token.transferFrom(from, transaction.to, amount);
        // require(success, "tx failed");
        require(token.transfer(transaction.to, amount), "tx failed");
        transaction.executed = true;

        emit Transfer_JCO(from, to, amount);
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex, address msg_sender)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg_sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg_sender] = false;

        emit RevokeConfirmation(msg_sender, _txIndex);
    }

    function getOwners() external onlyManager view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external onlyManager view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex)
        external onlyManager
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
/**
 * @title Treasury MultiSignature Contract
 * @dev Will call the functions from the treasury
 * -- #3 -- Deployed after the token contract
 */

import "./JCO.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]
contract Exchange {
    IERC20 private token;
    address public manager;

    event Transfer_JCO(address from, address to, uint256 amount);
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex, address msg_sender) {
        require(!isConfirmed[_txIndex][msg_sender], "tx already confirmed");
        _;
    }
    modifier onlyManager() {
        require(msg.sender == manager, "Not owner");
        _;
    }
    constructor(
        address[] memory _owners,
        uint256 _numConfirmationsRequired,
        address _token,
        address _manager
    ) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        token = IERC20(_token);
        manager = _manager;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyManager {
        uint256 txIndex = transactions.length;
        require(_value > 0, "Value must be greater than zero");

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txIndex, address msg_sender)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex, msg_sender)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg_sender] = true;

        emit ConfirmTransaction(msg_sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
        uint256 amount = transaction.value * (10**18);
        uint256 token_balance = token.balanceOf(address(this));
        require(amount <= token_balance, "token balance is low");

        address from = address(this);
        address to = transaction.to;

        // bool success = token.transferFrom(from, transaction.to, amount);
        // require(success, "tx failed");
        require(token.transfer(transaction.to, amount), "tx failed");
        transaction.executed = true;

        emit Transfer_JCO(from, to, amount);
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex, address msg_sender)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg_sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg_sender] = false;

        emit RevokeConfirmation(msg_sender, _txIndex);
    }

    function getOwners() external onlyManager view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external onlyManager view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex)
        external onlyManager
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
/**
 * @title Treasury MultiSignature Contract
 * @dev Will call the functions from the treasury
 * -- #3 -- Deployed after the token contract
 */

import "./JCO.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]
contract Foundation {
    IERC20 private token;
    address public manager;
    
    event Transfer_JCO(address from, address to, uint256 amount);
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex, address msg_sender) {
        require(!isConfirmed[_txIndex][msg_sender], "tx already confirmed");
        _;
    }
    modifier onlyManager() {
        require(msg.sender == manager, "Not owner");
        _;
    }
    constructor(
        address[] memory _owners,
        uint256 _numConfirmationsRequired,
        address _token,
        address _manager
    ) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        token = IERC20(_token);
        manager = _manager;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyManager {
        uint256 txIndex = transactions.length;
        require(_value > 0, "Value must be greater than zero");

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txIndex, address msg_sender)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex, msg_sender)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg_sender] = true;

        emit ConfirmTransaction(msg_sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
        uint256 amount = transaction.value * (10**18);
        uint256 token_balance = token.balanceOf(address(this));
        require(amount <= token_balance, "token balance is low");

        address from = address(this);
        address to = transaction.to;

        // bool success = token.transferFrom(from, transaction.to, amount);
        // require(success, "tx failed");
        require(token.transfer(transaction.to, amount), "tx failed");
        transaction.executed = true;

        emit Transfer_JCO(from, to, amount);
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex, address msg_sender)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg_sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg_sender] = false;

        emit RevokeConfirmation(msg_sender, _txIndex);
    }

    function getOwners() external onlyManager view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external onlyManager view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex)
        external onlyManager
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
/**
 * @title Treasury MultiSignature Contract
 * @dev Will call the functions from the treasury
 * -- #3 -- Deployed after the token contract
 */

import "./JCO.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"]
contract Staking {
    IERC20 private token;
    address public manager;

    event Transfer_JCO(address from, address to, uint256 amount);
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex, address msg_sender) {
        require(!isConfirmed[_txIndex][msg_sender], "tx already confirmed");
        _;
    }
    modifier onlyManager() {
        require(msg.sender == manager, "Not owner");
        _;
    }
    constructor(
        address[] memory _owners,
        uint256 _numConfirmationsRequired,
        address _token,
        address _manager
    ) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        token = IERC20(_token);
        manager = _manager;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyManager {
        uint256 txIndex = transactions.length;
        require(_value > 0, "Value must be greater than zero");

        if (_value <= 1000) {
            uint256 amount = _value * (10**18);
            uint256 token_balance = token.balanceOf(address(this));
            require(amount <= token_balance, "token balance is low");

            address from = address(this);
            address to = _to;

            // bool success = token.transferFrom(from, transaction.to, amount);
            // require(success, "tx failed");
            require(token.transfer(_to, amount), "tx failed");
            transactions.push(
                Transaction({
                    to: _to,
                    value: _value,
                    data: _data,
                    executed: true,
                    numConfirmations: 0
                })
            );
            emit Transfer_JCO(from, to, amount);
        } else {
            transactions.push(
                Transaction({
                    to: _to,
                    value: _value,
                    data: _data,
                    executed: false,
                    numConfirmations: 0
                })
            );

            emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
        }
    }

    function confirmTransaction(uint256 _txIndex, address msg_sender)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex, msg_sender)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg_sender] = true;

        emit ConfirmTransaction(msg_sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
        uint256 amount = transaction.value * (10**18);
        uint256 token_balance = token.balanceOf(address(this));
        require(amount <= token_balance, "token balance is low");

        address from = address(this);
        address to = transaction.to;

        // bool success = token.transferFrom(from, transaction.to, amount);
        // require(success, "tx failed");
        require(token.transfer(transaction.to, amount), "tx failed");
        transaction.executed = true;

        emit Transfer_JCO(from, to, amount);
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex, address msg_sender)
        external onlyManager
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg_sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg_sender] = false;

        emit RevokeConfirmation(msg_sender, _txIndex);
    }

    function getOwners() external onlyManager view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external onlyManager view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex)
        external onlyManager
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title JCO Token
 * @dev JennyCO ERC20 standard token contract
 * -- #2 -- To be deployed after the treasury contract
 */

/**
 * Pass three arguments while deploying
 */
contract JCO is ERC20 {
    constructor(address _treasury, string memory tokenName, string memory tokenSymbol) ERC20(tokenName, tokenSymbol) {
        _mint(_treasury, 250000000 * (10 ** uint256(decimals())));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./JCO.sol";
import "./MultiSig_Treasury.sol";
import "./1_Fundraising.sol";
import "./2_Rewards.sol";
import "./3_Team.sol";
import "./4_Advisors.sol";
import "./5_Marketing.sol";
import "./6_Exchange.sol";
import "./7_Foundation.sol";
import "./8_Staking.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// 0x617F2E2fD72FD9D5503197092aC168c91465E7f2
contract JCO_Manager {
    address public sender;
    address treasury;
    IERC20 private tokenContract;
    MultiSig_Treasury multi_treasuryContract;
    Fundraising fundContract;
    Rewards rewardsContract;
    Team teamContract;
    Advisors advisorContract;
    Marketing marketingContract;
    Exchange exchangeContract;
    Foundation foundationContract;
    Staking stakingContract;

    address[] public owners_TGW;
    address[] public owners_OW;
    mapping(address => bool) public isOwner_TGW;
    mapping(address => bool) public isOwner_OW;

    constructor(address _token) {
        sender = msg.sender;
        tokenContract = IERC20(_token);
    }

    modifier onlyOwner() {
        require(msg.sender == sender, "Not owner");
        _;
    }

    function addWallets(
        address _treasury,
        address payable _multi,
        address payable _funding,
        address payable _rewards,
        address payable _team,
        address payable _advisors,
        address payable _marketing,
        address payable _exchange,
        address payable _foundation,
        address payable _staking
    ) public onlyOwner returns (bool) {
        treasury = _treasury;

        multi_treasuryContract = MultiSig_Treasury(_multi);
        owners_TGW = getOwners_TGW();

        for (uint256 i = 0; i < owners_TGW.length; i++) {
            address owner = owners_TGW[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner_TGW[owner], "owner not unique");

            isOwner_TGW[owner] = true;
        }

        fundContract = Fundraising(_funding);
        rewardsContract = Rewards(_rewards);
        teamContract = Team(_team);
        advisorContract = Advisors(_advisors);
        marketingContract = Marketing(_marketing);
        exchangeContract = Exchange(_exchange);
        foundationContract = Foundation(_foundation);
        stakingContract = Staking(_staking);
        owners_OW = getOwners_OW();

        for (uint256 i = 0; i < owners_OW.length; i++) {
            address owner = owners_OW[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner_OW[owner], "owner not unique");

            isOwner_OW[owner] = true;
        }
        return true;
    }

    // ****     Multi Sig Contract Functions  *****

    // TGW - Token Generation Wallet functions
    modifier onlyOwner_TGW() {
        require(isOwner_TGW[msg.sender], "not owner");
        _;
    }

    function getOwners_TGW() public view returns (address[] memory) {
        return multi_treasuryContract.getOwners();
    }

    // function submitTxn_TGW(
    //     address _to,
    //     uint256 _value,
    //     bytes memory _data
    // ) public onlyOwner_TGW {
    //     return multi_treasuryContract.submitTransaction(_to, _value, _data);
    // }

    function confirmTxn_TGW(address _beneficiary, uint256 _txIndex)
        public
        onlyOwner_TGW
    {
        return
            multi_treasuryContract.confirmTransaction(
                _beneficiary,
                _txIndex,
                msg.sender
            );
    }

    function executeTxn_TGW(address _beneficiary, uint256 _txIndex)
        public
        onlyOwner_TGW
    {
        return
            multi_treasuryContract.executeTransaction(
                _beneficiary,
                _txIndex,
                msg.sender
            );
    }

    function revokeConfirmation_TGW(address _beneficiary, uint256 _txIndex)
        public
        onlyOwner_TGW
    {
        return
            multi_treasuryContract.revokeConfirmation(
                _beneficiary,
                _txIndex,
                msg.sender
            );
    }

    function getTransactionCount_TGW(address _beneficiary)
        public
        view
        returns (uint256)
    {
        return multi_treasuryContract.getTransactionCount(_beneficiary);
    }

    function getVestingSchedule_TGW(address _beneficiary, uint256 _txIndex)
        public
        view
        returns (
            uint256 releaseTime,
            uint256 releaseAmount,
            bool released,
            uint256 numConfirmations
        )
    {
        return
            multi_treasuryContract.getVestingSchedule(_beneficiary, _txIndex);
    }

    // function addVestingSchedule(
    //     address beneficiary,
    //     uint256 releaseTime,
    //     uint256 releaseAmount
    // ) internal onlyOwner_TGW {
    //     // require(msg.sender == msg.owner, "Only owner can add vesting schedule");
    //     // IERC20 token = IERC20(tokenAddress);
    //     uint256 amount = releaseAmount * (10**18);
    //     require(
    //         tokenContract.balanceOf(treasury) >= amount,
    //         "Insufficient balance to add vesting schedule"
    //     );
    //     // require(token.transferFrom(treasury, address(this), amount), "Transfer failed");
    //     vestingSchedules[beneficiary].push(
    //         VestingSchedule(releaseTime, amount, false)
    //     );
    // }

    // function release(address beneficiary, uint256 index)
    //     external
    //     onlyOwner_TGW
    //     returns (bool)
    // {
    //     // require(msg.sender == owner, "Only owner can release tokens");
    //     // IERC20 token = IERC20(tokenAddress);
    //     uint256 numSchedules = vestingSchedules[beneficiary].length;
    //     require(index < numSchedules, "Invalid index");
    //     VestingSchedule storage schedule = vestingSchedules[beneficiary][index];
    //     require(!schedule.released, "Tokens already released");
    //     require(
    //         block.timestamp >= schedule.releaseTime,
    //         "Release time not reached"
    //     );
    //     require(
    //         tokenContract.transferFrom(
    //             treasury,
    //             beneficiary,
    //             schedule.releaseAmount
    //         ),
    //         "Transfer failed"
    //     );
    //     schedule.released = true;
    //     return true;
    // }

    // function releaseFunds(address _beneficiary, uint256 index)
    //     public
    //     onlyOwner_TGW
    //     returns (bool)
    // {
    //     return multi_treasuryContract.release(_beneficiary, index);
    // }

    // Fundraising/ Seed-IDO Wallet functions

    // OP - Operation Wallets
    modifier onlyOwner_OW() {
        require(isOwner_OW[msg.sender], "not owner");
        _;
    }

    function getOwners_OW() public view returns (address[] memory) {
        return fundContract.getOwners();
    }

    function submitTxn_Fund(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner_OW {
        return fundContract.submitTransaction(_to, _value, _data);
    }

    function confirmTxn_Fund(uint256 _txIndex) public onlyOwner_OW {
        return fundContract.confirmTransaction(_txIndex, msg.sender);
    }

    function executeTxn_Fund(uint256 _txIndex) public onlyOwner_OW {
        return fundContract.executeTransaction(_txIndex);
    }

    function revokeConfirmation_Fund(uint256 _txIndex) public onlyOwner_OW {
        return fundContract.revokeConfirmation(_txIndex, msg.sender);
    }

    function getTransactionCount_Fund() public view returns (uint256) {
        return fundContract.getTransactionCount();
    }

    function getTxn_Fund(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        return fundContract.getTransaction(_txIndex);
    }

    // Rewards Wallet functions

    function submitTxn_Rewards(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner_OW {
        return rewardsContract.submitTransaction(_to, _value, _data);
    }

    function confirmTxn_Rewards(uint256 _txIndex) public onlyOwner_OW {
        return rewardsContract.confirmTransaction(_txIndex, msg.sender);
    }

    function executeTxn_Rewards(uint256 _txIndex) public onlyOwner_OW {
        return rewardsContract.executeTransaction(_txIndex);
    }

    function revokeConfirmation_Rewards(uint256 _txIndex) public onlyOwner_OW {
        return rewardsContract.revokeConfirmation(_txIndex, msg.sender);
    }

    function getTransactionCount_Rewards() public view returns (uint256) {
        return rewardsContract.getTransactionCount();
    }

    function getTxn_Rewards(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        return rewardsContract.getTransaction(_txIndex);
    }

    // Team Wallet functions

    function submitTxn_Team(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner_OW {
        return teamContract.submitTransaction(_to, _value, _data);
    }

    function confirmTxn_Team(uint256 _txIndex) public onlyOwner_OW {
        return teamContract.confirmTransaction(_txIndex, msg.sender);
    }

    function executeTxn_Team(uint256 _txIndex) public onlyOwner_OW {
        return teamContract.executeTransaction(_txIndex);
    }

    function revokeConfirmation_Team(uint256 _txIndex) public onlyOwner_OW {
        return teamContract.revokeConfirmation(_txIndex, msg.sender);
    }

    function getTransactionCount_Team() public view returns (uint256) {
        return teamContract.getTransactionCount();
    }

    function getTxn_Team(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        return teamContract.getTransaction(_txIndex);
    }

    // Advisor Wallet functions

    function submitTxn_Advisor(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner_OW {
        return advisorContract.submitTransaction(_to, _value, _data);
    }

    function confirmTxn_Advisor(uint256 _txIndex) public onlyOwner_OW {
        return advisorContract.confirmTransaction(_txIndex, msg.sender);
    }

    function executeTxn_Advisor(uint256 _txIndex) public onlyOwner_OW {
        return advisorContract.executeTransaction(_txIndex);
    }

    function revokeConfirmation_Advisor(uint256 _txIndex) public onlyOwner_OW {
        return advisorContract.revokeConfirmation(_txIndex, msg.sender);
    }

    function getTransactionCount_Advisor() public view returns (uint256) {
        return advisorContract.getTransactionCount();
    }

    function getTxn_Advisor(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        return advisorContract.getTransaction(_txIndex);
    }

    // Marketing Wallet functions

    function submitTxn_Marketing(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner_OW {
        return marketingContract.submitTransaction(_to, _value, _data);
    }

    function confirmTxn_Marketing(uint256 _txIndex) public onlyOwner_OW {
        return marketingContract.confirmTransaction(_txIndex, msg.sender);
    }

    function executeTxn_Marketing(uint256 _txIndex) public onlyOwner_OW {
        return marketingContract.executeTransaction(_txIndex);
    }

    function revokeConfirmation_Marketing(uint256 _txIndex)
        public
        onlyOwner_OW
    {
        return marketingContract.revokeConfirmation(_txIndex, msg.sender);
    }

    function getTransactionCount_Marketing() public view returns (uint256) {
        return marketingContract.getTransactionCount();
    }

    function getTxn_Marketing(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        return marketingContract.getTransaction(_txIndex);
    }

    // Exchange Wallet functions

    function submitTxn_Exchange(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner_OW {
        return exchangeContract.submitTransaction(_to, _value, _data);
    }

    function confirmTxn_Exchange(uint256 _txIndex) public onlyOwner_OW {
        return exchangeContract.confirmTransaction(_txIndex, msg.sender);
    }

    function executeTxn_Exchange(uint256 _txIndex) public onlyOwner_OW {
        return exchangeContract.executeTransaction(_txIndex);
    }

    function revokeConfirmation_Exchange(uint256 _txIndex) public onlyOwner_OW {
        return exchangeContract.revokeConfirmation(_txIndex, msg.sender);
    }

    function getTransactionCount_Exchange() public view returns (uint256) {
        return exchangeContract.getTransactionCount();
    }

    function getTxn_Exchange(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        return exchangeContract.getTransaction(_txIndex);
    }

    // Foundation Wallet functions

    function submitTxn_Foundation(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner_OW {
        return foundationContract.submitTransaction(_to, _value, _data);
    }

    function confirmTxn_Foundation(uint256 _txIndex) public onlyOwner_OW {
        return foundationContract.confirmTransaction(_txIndex, msg.sender);
    }

    function executeTxn_Foundation(uint256 _txIndex) public onlyOwner_OW {
        return foundationContract.executeTransaction(_txIndex);
    }

    function revokeConfirmation_Foundation(uint256 _txIndex)
        public
        onlyOwner_OW
    {
        return foundationContract.revokeConfirmation(_txIndex, msg.sender);
    }

    function getTransactionCount_Foundation() public view returns (uint256) {
        return foundationContract.getTransactionCount();
    }

    function getTxn_Foundation(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        return foundationContract.getTransaction(_txIndex);
    }

    // Staking Wallet functions
    function submitTxn_Staking(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner_OW {
        return stakingContract.submitTransaction(_to, _value, _data);
    }

    function confirmTxn_Staking(uint256 _txIndex) public onlyOwner_OW {
        return stakingContract.confirmTransaction(_txIndex, msg.sender);
    }

    function executeTxn_Staking(uint256 _txIndex) public onlyOwner_OW {
        return stakingContract.executeTransaction(_txIndex);
    }

    function revokeConfirmation_Staking(uint256 _txIndex) public onlyOwner_OW {
        return stakingContract.revokeConfirmation(_txIndex, msg.sender);
    }

    function getTransactionCount_Staking() public view returns (uint256) {
        return stakingContract.getTransactionCount();
    }

    function getTxn_Staking(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        return stakingContract.getTransaction(_txIndex);
    }

    function getsender() public view returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
/**
 * @title Treasury MultiSignature Contract
 * @dev Will call the functions from the treasury
 * -- #3 -- Deployed after the token contract
 */

import "./JCO.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ["0xf8e81D47203A594245E36C48e151709F0C19fBe8", "0xD7ACd2a9FD159E69Bb102A1ca21C9a3e3A5F771B","0x7EF2e0048f5bAeDe046f6BF797943daF4ED8CB47","0xDA0bab807633f07f013f94DD0E6A4F96F8742B53","0x358AA13c52544ECCEF6B0ADD0f801012ADAD5eE3","0x9D7f74d0C41E726EC95884E0e97Fa6129e3b5E99","0x9D7f74d0C41E726EC95884E0e97Fa6129e3b5E99","0xddaAd340b0f1Ef65169Ae5E41A8b10776a75482d"]

// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]
contract MultiSig_Treasury {
    IERC20 private token;
    address treasury;
    address public manager;

    event Transfer_JCO(address from, address to, uint256 amount);
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    address[] owners;
    mapping(address => bool) isOwner;
    uint256 numConfirmationsRequired;

    struct VestingSchedule {
        uint256 releaseTime;
        uint256 releaseAmount;
        bool released;
        uint256 numConfirmations;
    }

    struct Time {
        uint256 current_time;
        uint256 month3;
        uint256 month6;
        uint256 month9;
        uint256 month12;
        uint256 month15;
        uint256 month18;
        uint256 month24;
        uint256 month36;
    }
    mapping(address => mapping(uint256 => mapping(address => bool)))
        public isConfirmed;

    mapping(address => VestingSchedule[]) vestingSchedules;

    modifier txExists(address _beneficiary, uint256 _txIndex) {
        require(
            _txIndex < vestingSchedules[_beneficiary].length,
            "tx does not exist"
        );
        _;
    }

    modifier notExecuted(address _beneficiary, uint256 _txIndex) {
        require(
            !vestingSchedules[_beneficiary][_txIndex].released,
            "tx already executed"
        );
        _;
    }

    modifier notConfirmed(
        address _beneficiary,
        uint256 _txIndex,
        address msg_sender
    ) {
        require(
            !isConfirmed[_beneficiary][_txIndex][msg_sender],
            "tx already confirmed"
        );
        _;
    }
    modifier onlyManager() {
        require(msg.sender == manager, "Not owner");
        _;
    }
    struct Wallets {
        address payable _funding;
        address payable _rewards;
        address payable _team;
        address payable _advisors;
        address payable _marketing;
        address payable _exchange;
        address payable _foundation;
        address payable _staking;
    }

    constructor(
        address[] memory _owners,
        uint256 _numConfirmationsRequired,
        address _token,
        address _treasury,
        address _manager,
        Wallets memory _wallets
    ) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        numConfirmationsRequired = _numConfirmationsRequired;
        token = IERC20(_token);
        treasury = _treasury;
        manager = _manager;
        Time memory time;

        // Timestamps

        // For testing with shorter time
        time.month3 = block.timestamp + 200 minutes;
        time.month6 = block.timestamp + 400 minutes;
        time.month9 = block.timestamp + 600 minutes;
        time.month12 = block.timestamp + 900 minutes;
        time.month15 = block.timestamp + 1100 minutes;
        time.month18 = block.timestamp + 1600 minutes;
        time.month24 = block.timestamp + 2100 minutes;
        time.month36 = block.timestamp + 3000 minutes;

        // function addVestingSchedule(address beneficiary, uint256 releaseTime, uint256 releaseAmount) external{
        addVestingSchedule(_wallets._funding, time.current_time, 5960000);
        addVestingSchedule(_wallets._funding, time.month3, 3960000);
        addVestingSchedule(_wallets._funding, time.month6, 5710000);
        addVestingSchedule(_wallets._funding, time.month9, 3960000);
        addVestingSchedule(_wallets._funding, time.month12, 5710000);
        addVestingSchedule(_wallets._funding, time.month15, 5710000);
        addVestingSchedule(_wallets._funding, time.month18, 5710000);

        addVestingSchedule(_wallets._rewards, time.current_time, 1150000);
        addVestingSchedule(_wallets._rewards, time.month3, 1150000);
        addVestingSchedule(_wallets._rewards, time.month6, 1150000);
        addVestingSchedule(_wallets._rewards, time.month9, 1150000);

        addVestingSchedule(_wallets._team, time.month12, 6000000);
        addVestingSchedule(_wallets._team, time.month18, 6000000);
        addVestingSchedule(_wallets._team, time.month24, 8000000);

        addVestingSchedule(_wallets._advisors, time.month12, 15000000);
        addVestingSchedule(_wallets._advisors, time.month24, 15000000);
        addVestingSchedule(_wallets._advisors, time.month36, 125000000);

        addVestingSchedule(_wallets._marketing, time.current_time, 15000000);
        addVestingSchedule(_wallets._marketing, time.month6, 15000000);
        addVestingSchedule(_wallets._marketing, time.month18, 125000000);

        addVestingSchedule(_wallets._staking, time.current_time, 15000000);
        addVestingSchedule(_wallets._staking, time.month3, 15000000);
        addVestingSchedule(_wallets._staking, time.month6, 15000000);
        addVestingSchedule(_wallets._staking, time.month9, 15000000);
        addVestingSchedule(_wallets._staking, time.month12, 15000000);
        addVestingSchedule(_wallets._staking, time.month18, 15000000);
        addVestingSchedule(_wallets._staking, time.month24, 15000000);

        addVestingSchedule(_wallets._exchange, time.current_time, 15000000);

        addVestingSchedule(_wallets._foundation, time.month6, 15000000);
        addVestingSchedule(_wallets._foundation, time.month12, 15000000);
        addVestingSchedule(_wallets._foundation, time.month18, 125000000);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function addVestingSchedule(
        address beneficiary,
        uint256 releaseTime,
        uint256 releaseAmount
    ) internal {
        // require(msg.sender == msg.owner, "Only owner can add vesting schedule");
        // IERC20 token = IERC20(tokenAddress);
        uint256 amount = releaseAmount * (10**18);
        require(
            token.balanceOf(treasury) >= amount,
            "Insufficient balance to add vesting schedule"
        );
        // require(token.transferFrom(treasury, address(this), amount), "Transfer failed");
        vestingSchedules[beneficiary].push(
            VestingSchedule(releaseTime, amount, false, 0)
        );
    }

    function confirmTransaction(
        address _beneficiary,
        uint256 _txIndex,
        address msg_sender
    )
        external onlyManager
        txExists(_beneficiary, _txIndex)
        notExecuted(_beneficiary, _txIndex)
        notConfirmed(_beneficiary, _txIndex, msg_sender)
    {
        VestingSchedule storage schedule = vestingSchedules[_beneficiary][
            _txIndex
        ];

        require(
            block.timestamp >= schedule.releaseTime,
            "Release time not reached"
        );
        // Transaction storage transaction = transactions[_txIndex];
        schedule.numConfirmations += 1;
        isConfirmed[_beneficiary][_txIndex][msg_sender] = true;
        emit ConfirmTransaction(msg_sender, _txIndex);
    }

    function executeTransaction(
        address _beneficiary,
        uint256 _txIndex,
        address msg_sender
    )
        external onlyManager
        txExists(_beneficiary, _txIndex)
        notExecuted(_beneficiary, _txIndex)
    {
        VestingSchedule storage schedule = vestingSchedules[_beneficiary][
            _txIndex
        ];

        // Transaction storage transaction = transactions[_txIndex];

        require(
            schedule.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
        uint256 amount = schedule.releaseAmount;
        uint256 token_balance = token.balanceOf(treasury);
        require(amount <= token_balance, "token balance is low");

        address from = treasury;
        address to = _beneficiary;

        // bool success = token.transferFrom(from, transaction.to, amount);
        // require(success, "tx failed");
        require(token.transferFrom(from, to, amount), "tx failed");
        schedule.released = true;

        emit Transfer_JCO(from, to, amount);
        emit ExecuteTransaction(msg_sender, _txIndex);
    }

    function revokeConfirmation(
        address _beneficiary,
        uint256 _txIndex,
        address msg_sender
    )
        external onlyManager
        txExists(_beneficiary, _txIndex)
        notExecuted(_beneficiary, _txIndex)
    {
        VestingSchedule storage schedule = vestingSchedules[_beneficiary][
            _txIndex
        ];
        // Transaction storage transaction = transactions[_txIndex];

        require(
            isConfirmed[_beneficiary][_txIndex][msg_sender],
            "tx not confirmed"
        );

        schedule.numConfirmations += 1;
        isConfirmed[_beneficiary][_txIndex][msg_sender] = false;
        emit RevokeConfirmation(msg_sender, _txIndex);
    }

    function getOwners() onlyManager external view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount(address _beneficiary)
        external
        view onlyManager
        returns (uint256)
    {
        return vestingSchedules[_beneficiary].length;
    }

    function getVestingSchedule(address _beneficiary, uint256 _txIndex)
        external onlyManager
        view
        returns (
            uint256 releaseTime,
            uint256 releaseAmount,
            bool released,
            uint256 numConfirmations
        )
    {
        VestingSchedule storage schedule = vestingSchedules[_beneficiary][
            _txIndex
        ];
        // Transaction storage transaction = transactions[_txIndex];

        return (
            schedule.releaseTime,
            schedule.releaseAmount,
            schedule.released,
            schedule.numConfirmations
        );
    }
}