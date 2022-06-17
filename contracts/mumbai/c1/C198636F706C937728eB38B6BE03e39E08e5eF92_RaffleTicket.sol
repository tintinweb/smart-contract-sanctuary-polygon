// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.12;

contract RaffleTicket {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    event MintAccessGranted(address minter);
    event MintAccessRevoked(address minter);
    event BurnAccessGranted(address burner);
    event BurnAccessRevoked(address burner);
    event TransferPaused(address account);
    event TransferUnPaused(address account);

    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string public name;
    string public symbol;
    uint256 public decimals = 0;

    mapping(address => bool) private _owner;

    mapping(address => bool) public MintAccess;
    mapping(address => bool) public BurnAccess;

    bool private _transferPaused;

    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory owner
    ) {
        name = name_;
        symbol = symbol_;
        for (uint256 i = 0; i < owner.length; i++) {
            _owner[owner[i]] = true;
        }
        _transferPaused = true;
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(_msgSender()), " caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if caller is the address of the current owner.
     */
    function isOwner(address caller) public view virtual returns (bool) {
        return _owner[caller];
    }

    /**
     * @dev Modifier to make a function callable only when the transfer is allowed.
     *
     * Requirements:
     *
     * - The transfer must not be paused.
     */
    modifier whenTransferAllowed() {
        require(
            !transferPaused(),
            "RaffleTicket#whenTransferAllowed: Transfer is not allowed"
        );
        _;
    }

    /**
     * @dev Returns true if transfer is paused.
     */
    function transferPaused() public view returns (bool) {
        return _transferPaused;
    }

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal whenTransferAllowed {
        require(
            from != address(0),
            "RaffleTicket: transfer from the zero address"
        );
        require(to != address(0), "RaffleTicket: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "RaffleTicket: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
    function _mint(address account, uint256 amount) internal {
        require(
            account != address(0),
            "RaffleTicket: mint to the zero address"
        );

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
    function _burn(address account, uint256 amount) internal {
        require(
            account != address(0),
            "RaffleTicket: burn from the zero address"
        );

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(
            accountBalance >= amount,
            "RaffleTicket: burn amount exceeds balance"
        );
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    ) internal {}

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
    ) internal {}

    /**
     * @dev Modifier to make a function callable only when the caller has mint access.
     *
     * Requirements:
     *
     * - The caller must either have mint access or has to be owner.
     */
    modifier requiresMintAccess() {
        require(
            isOwner(_msgSender()) || MintAccess[_msgSender()],
            "RaffleTicket#requiresMintAccess: No Mint Access"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the caller has burn access.
     *
     * Requirements:
     *
     * - The caller must either have burn access or has to be owner.
     */
    modifier requiresBurnAccess() {
        require(
            isOwner(_msgSender()) || BurnAccess[_msgSender()],
            "RaffleTicket#requiresBurnAccess: No Burn Access"
        );
        _;
    }

    /**
     * @dev Grants or revokes mint permission to `minter`, according to `val`,
     *
     * Emits {MintAccessGranted} or {MintAccessRevoked} event.
     *
     * Requirements:
     *
     * - `caller` must be owner.
     */
    function setMintAccess(address minter, bool val) external onlyOwner {
        MintAccess[minter] = val;
        if (val) {
            emit MintAccessGranted(minter);
        } else {
            emit MintAccessRevoked(minter);
        }
    }

    /**
     * @dev Grants or revokes burn permission to `burner` address, according to `val`,
     *
     * Emits {BurnAccessGranted} or {BurnAccessRevoked} event.
     *
     * Requirements:
     *
     * - `caller` must be owner.
     */
    function setBurnAccess(address burner, bool val) external onlyOwner {
        BurnAccess[burner] = val;
        if (val) {
            emit BurnAccessGranted(burner);
        } else {
            emit BurnAccessRevoked(burner);
        }
    }

    /**
     * @dev pause transfer of Raffle Tickets.
     *
     * Requirements:
     *
     * - The caller must be owner.
     */
    function pauseTransfer() external onlyOwner {
        _transferPaused = true;
        emit TransferPaused(_msgSender());
    }

    /**
     * @dev unpause transfer of Raffle Tickets.
     *
     * Requirements:
     *
     * - The caller must be owner.
     */
    function unpauseTransfer() external onlyOwner {
        _transferPaused = false;
        emit TransferUnPaused(_msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {_mint}.
     *
     * Requirements:
     *
     * - the caller must have the mint access.
     */
    function mint(address to, uint256 amount)
        external
        requiresMintAccess
        returns (bool)
    {
        require(amount > 0,"RaffleTicket#mint: amount has to be greater than zero");
        _mint(to, amount);
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from `account`
     *
     * See {_burn} 
     *
     * Requirements:
     *
     * - the caller must have burn access
     */
    function burnFrom(address account, uint256 amount)
        external
        requiresBurnAccess
        returns (bool)
    {
        _burn(account, amount);
        return true;
    }
}