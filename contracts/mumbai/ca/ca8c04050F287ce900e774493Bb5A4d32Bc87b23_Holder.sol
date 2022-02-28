pragma solidity ^0.8.6;

import {ERC20} from "./openzeppelin-contracts-master/contracts/token/ERC20/ERC20.sol";

contract Holder {

    address public owner;
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    function changeOwner(address nw) public onlyOwner returns (bool){
        owner = nw;
        return true;
    }

    bool public paused;

    function changePause(bool nw) public onlyOwner returns (bool){
        paused = nw;
        return true;
    }
    modifier notPaused(){
        require(!paused);
        _;
    }

    uint public fee_per;
    uint public fee_100;

    function changeFee(uint num, uint den) public onlyOwner returns (bool){
        fee_per = num;
        fee_100 = den;
        return true;
    }

    struct addressInfo {
        uint size;
        mapping(uint => uint) transactions;
    }

    mapping(address => addressInfo) receivers;
    mapping(address => addressInfo) senders;

    struct transactionsInfo {
        uint startDate;
        uint period;

        ERC20 tokenAddress;
        uint quantity;
        uint maxTransactions;

        address from;
        address to;

        uint currentTransaction;
        
    }

    mapping(uint => transactionsInfo) transactionsHolder;


    struct history{
        mapping(uint => uint) previousTransactionsTimes;
    }   
    mapping(uint => history) transactionsHistory;

    uint transactionHolderSize;

    mapping(ERC20 => bool) tokenAllowance;

    function changeTokenAllowance(ERC20 nw, bool alw) public onlyOwner returns (bool){
        tokenAllowance[nw] = alw;
        return true;
    }

    constructor(){
        owner = msg.sender;
        paused = false;
        transactionHolderSize = 0;
        fee_100 = 10000;
        fee_per = 50;
    }

    function createTransaction(ERC20 token, uint quantity, uint maxTransactions, address to, uint period)
    public notPaused returns (bool){
        require(tokenAllowance[token], 'Token is not allowed yet');

        transactionsHolder[transactionHolderSize].startDate = block.timestamp;
        transactionsHolder[transactionHolderSize].period = period;

        transactionsHolder[transactionHolderSize].tokenAddress = token;
        transactionsHolder[transactionHolderSize].quantity = quantity;

        transactionsHolder[transactionHolderSize].from = msg.sender;
        transactionsHolder[transactionHolderSize].to = to;

        transactionsHolder[transactionHolderSize].currentTransaction = 0;
        transactionsHolder[transactionHolderSize].maxTransactions = maxTransactions;

        receivers[to].transactions[receivers[to].size] = transactionHolderSize;
        receivers[to].size += 1;

        senders[msg.sender].transactions[senders[msg.sender].size] = transactionHolderSize;
        senders[msg.sender].size += 1;

        transactionHolderSize += 1;

        return true;

    }

    function pendTransaction(uint ind) public notPaused returns (bool){
        require(ind < transactionHolderSize,
            'Recurrent transaction index does not exist');
        require(
            transactionsHolder[ind].maxTransactions == 0 ||
            transactionsHolder[ind].maxTransactions > transactionsHolder[ind].currentTransaction,
            'Recurrent transaction is already fully paid'
        );
        require(
            transactionsHolder[ind].currentTransaction * transactionsHolder[ind].period < block.timestamp - transactionsHolder[ind].startDate,
            'Recurrent transaction is paid up till now'
        );
        require(
            transactionsHolder[ind].tokenAddress.allowance(transactionsHolder[ind].from, address(this)) >= transactionsHolder[ind].quantity,
            'Current allowance of the payer is below the needed quantity'
        );

        require(
            transactionsHolder[ind].tokenAddress.balanceOf(transactionsHolder[ind].from) >= transactionsHolder[ind].quantity,
            'Current balance of the payer is below the needed quantity'
        );

        transactionsHistory[ind].previousTransactionsTimes[transactionsHolder[ind].currentTransaction] = block.timestamp;
        transactionsHolder[ind].currentTransaction += 1;

        uint fee = transactionsHolder[ind].quantity * fee_per / fee_100;

        require(transactionsHolder[ind].tokenAddress.transferFrom(
                transactionsHolder[ind].from,
                owner,
                fee
            ),
            'Payment of the fee failed'
        );

        require(transactionsHolder[ind].tokenAddress.transferFrom(
                transactionsHolder[ind].from,
                transactionsHolder[ind].to,
                transactionsHolder[ind].quantity - fee
            ),
            'Transfer from payer to receiver failed'
        );

        return true;

    }

    function parseReceiver(address adr, uint page, uint size) public view returns (uint[] memory){
        uint[] memory toReturn = new uint[](size);
        if (receivers[adr].size < page * size) {
            return toReturn;
        }
        uint end = receivers[adr].size - page * size;
        uint start = (end > size) ? (end - size) : 0;
        for (uint i = start; i < end; i++) {
            toReturn[i] = receivers[adr].transactions[i];
        }
        return toReturn;


    }

    function parseSender(address adr, uint page, uint size) public view returns (uint[] memory){
        uint[] memory toReturn = new uint[](size);
        if (senders[adr].size < page * size) {
            return toReturn;
        }
        uint end = senders[adr].size - page * size;
        uint start = (end > size) ? (end - size) : 0;
        for (uint i = start; i < end; i++) {
            toReturn[i] = senders[adr].transactions[i];
        }
        return toReturn;

    }

    function parseTransactions(uint[] memory txnIds) public view returns (transactionsInfo[] memory){
        transactionsInfo[] memory toReturn = new transactionsInfo[](txnIds.length);

        for (uint i = 0; i < txnIds.length; i++) {
            toReturn[i] = transactionsHolder[txnIds[i]];
        }
        return toReturn;

    }

    function parsePreviousTransactionsTimestamps(uint txnId, uint page, uint size) public view returns (uint[] memory){

        uint[] memory toReturn = new uint[](size);
        if (txnId >= transactionHolderSize || transactionsHolder[txnId].currentTransaction < page * size) {
            return toReturn;
        }
        uint end = transactionsHolder[txnId].currentTransaction - page * size;
        uint start = (end > size) ? (end - size) : 0;
        for (uint i = start; i < end; i++) {
            toReturn[i] = transactionsHistory[txnId].previousTransactionsTimes[i];
        }
        return toReturn;
    }


    function parseReadyOnes(uint[] memory txnIds) public view returns (uint[] memory){
        uint[] memory toReturn = new uint[](txnIds.length);

        uint ind;
        for (uint i = 0; i < txnIds.length; i++) {
            ind = txnIds[i];
            if (transactionsHolder[ind].maxTransactions != 0 && transactionsHolder[ind].maxTransactions == transactionsHolder[ind].currentTransaction) {
                // already fully paid
                toReturn[ind] = 0;
            }
            else if (transactionsHolder[ind].currentTransaction * transactionsHolder[ind].period >= block.timestamp - transactionsHolder[ind].startDate) {
                // fully paid till now
                toReturn[ind] = 1;
            }
            else if (transactionsHolder[ind].tokenAddress.allowance(transactionsHolder[ind].from, address(this)) < transactionsHolder[ind].quantity) {
                // not enough allowance to pay
                toReturn[ind] = 2;

            }
            else if (transactionsHolder[ind].tokenAddress.balanceOf(transactionsHolder[ind].from) < transactionsHolder[ind].quantity) {
                // not enough balance to pay
                toReturn[ind] = 3;
            }
            else {
                // transaction is ready
                toReturn[ind] = 4;
            }
        }
        return toReturn;

    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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