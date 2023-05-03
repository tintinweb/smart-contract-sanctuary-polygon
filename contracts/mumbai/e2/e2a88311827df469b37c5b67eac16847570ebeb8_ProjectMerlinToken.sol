/**
 *Submitted for verification at polygonscan.com on 2023-05-03
*/

/**
 *Submitted for verification at BscScan.com on 2023-03-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

/**
 * @title ProjectMerlinToken
 * @dev Implementation of the ERC20 token standard with metadata.
 */
contract ProjectMerlinToken is Context, IERC20Metadata {
    mapping(address => uint256) private _balances; // Mapping of each address's token balance.

    mapping(address => mapping(address => uint256)) private _allowances; // Mapping of each address's allowance.

    uint256 private _totalSupply; // Total supply of the token.

    string private _name; // Name of the token.
    string private _symbol; // Symbol of the token.
    uint8 private constant _decimals = 18; // Number of decimal places for the token.
    uint256 public constant supply = 900_000_000 * (10**_decimals); // Total supply of the token, fixed and declared.


    constructor(
        string memory name_,
        string memory symbol_,
        address _to
    ) {
        _name = name_;
        _symbol = symbol_;
        _mint(_to, supply);
    }

    /**
     * @dev Returns the name of the token.
     * @return The name of the token.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token.
     * @return The symbol of the token.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimal places for the token.
     * @return The number of decimal places for the token.
     */
    function decimals() external view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the total supply of the token.
     * @return The total supply of the token.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the token balance of a given address.
     * @param account The address for which to retrieve the token balance.
     * @return The token balance of the given address.
     */
    function balanceOf(address account)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev Transfers tokens from the sender's account to the recipient's account.
     * @param recipient The address to which the tokens are to be transferred.
     * @param amount The amount of tokens to be transferred.
     * @return A boolean indicating whether the transfer was successful.
     */
    function transfer(address recipient, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Returns the amount of tokens that the spender is allowed to spend on behalf of the owner.
     * @param from The address of the owner of the tokens.
     * @param to The address of the spender.
     * @return The amount of tokens that the spender is allowed to spend on behalf of the owner.
     */
    function allowance(address from, address to)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[from][to];
    }

    /**
     * @dev Approves `amount` to be spent on behalf of the caller.
     * Emits an {Approval} event.
     * @param to The address which will spend the funds.
     * @param amount The amount of tokens to be spent.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function approve(address to, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), to, amount);
        return true;
    }

    /**
     * @dev Transfers `amount` tokens from `sender` to `recipient`.
     * Emits a {Transfer} event.
     * Throws an error if the transfer exceeds the approved allowance.
     * @param sender The address which owns the tokens to be transferred.
     * @param recipient The address which will receive the tokens.
     * @param amount The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Increases the allowance of `to` to be able to transfer `addedValue` tokens on behalf of the caller.
     * Emits an {Approval} event.
     * @param to The address which will spend the increased funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function increaseAllowance(address to, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(_msgSender(), to, _allowances[_msgSender()][to] + addedValue);
        return true;
    }

    /**
     * @dev Decreases the allowance of `to` to be able to transfer `subtractedValue` tokens on behalf of the caller.
     * Emits an {Approval} event.
     * Throws an error if the decreased allowance is below zero.
     * @param to The address which had the allowance decreased.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function decreaseAllowance(address to, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][to];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), to, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Transfers `amount` tokens from the caller's account to `recipient`.
     * Emits a {Transfer} event.
     * Throws an error if the transfer amount is zero, the sender or recipient address is zero,
     * or the transfer amount exceeds the sender's balance.
     * @param sender The address which owns the tokens to be transferred.
     * @param recipient The address which will receive the tokens.
     * @param amount The amount of tokens to be transferred.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(amount > 0, "ERC20: transfer amount is zero");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`.
     * Emits a {Transfer} event with `from` set to the zero address.
     * Throws an error if the account address is zero.
     * @param account The address which will receive the tokens.
     * @param amount The amount of tokens to be minted.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.
     * Emits a {Transfer} event with `to` set to the zero address.
     * Throws an error if the account address is zero or the account balance is less than the amount being burned.
     * @param account The address which owns the tokens to be burned.
     * @param amount The amount of tokens to be burned.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Burns a specific amount of tokens from the caller's account.
     * @param amount The amount of token to be burned.
     */
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `to` over the caller's tokens.
     * Emits an {Approval} event.
     * @param from The address approving the allowance.
     * @param to The address being approved for the allowance.
     * @param amount The allowance amount to be approved.
     */
    function _approve(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: approve from the zero address");
        require(to != address(0), "ERC20: approve to the zero address");

        _allowances[from][to] = amount;
        emit Approval(from, to, amount);
    }
}