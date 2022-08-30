/**
 *Submitted for verification at polygonscan.com on 2022-08-29
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract FitWorks1 {

    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    address public owner = msg.sender;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => bool) public frozenAccount;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool frozen);

    modifier onlyOwner {
        require(msg.sender == owner, "You are not eligible to call this");
        _;
    }


    constructor() {
        name = "FitWorks1";
        symbol = "FTW1";
        decimals = 18;
        totalSupply = 10000000000 * 10 ** uint256(decimals);
        //transfer all to handler address
        balances[owner] = totalSupply;
    }


    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns(uint256 balance) {
        return balances[account];
    }
    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address _owner, address spender) public view returns(uint remaining) {
        ///???///
        // require(!frozenAccount[_owner] && !frozenAccount[spender], "ERC20: Address can't be frozenAccount");
        ///???///
        return allowed[_owner][spender];
    }
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */

     ///???///
    // function transfer(address recipient, uint256 amount) public onlyOwner returns(bool success) {
    ///???///
    function transfer(address recipient, uint256 amount) public returns(bool success) {
        // Check whether it is a frozen account 
        require(!frozenAccount[msg.sender] && !frozenAccount[recipient], "ERC20: Address can't be frozenAccount");
        // Check if the recipient address is valid
        require(recipient != address(0), "ERC20: Address can't be zero address");
        // Check if the sender account balance is sufficient
        require(balances[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        ///???///
        require(amount > 0 ,"ERC20: amount can't be zero");
        ///???///
        // Check if overflow occurs
        require(balances[recipient] + amount >= balances[recipient], "ERC20: transfer overflow occurs");
        // Debit sender account balance
        balances[msg.sender] -= amount;
        // Increase recipient account balance
        balances[recipient] += amount;
        // Trigger the corresponding event        
        emit Transfer(msg.sender, recipient, amount);
        return true;
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
    function approve(address spender, uint256 amount) public onlyOwner returns(bool success) {
        require(!frozenAccount[owner] && !frozenAccount[spender], "ERC20: Address can't be frozenAccount");
        require(spender != address(0), "ERC20: Address can't be zero address");
        ///???///
        require((amount == 0) || (allowed[owner][spender] == 0),"ERC20: Address already approve; Call increaseAllowance to increase approval");
        require(amount > 0 ,"ERC20: amount can't be zero");
        ///???///
        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */


    ///???///
    // function transferFrom(address sender, address recipient, uint amount) public returns(bool success) {
    //     // Check whether it is a frozen account 
    //     require(!frozenAccount[sender] && !frozenAccount[recipient], "ERC20: Address can't be frozenAccount");
    //     // Check if the address is valid
    //     require(recipient != address(0) && sender != address(0), "ERC20: Address can't be zero address");
    //     // Check if sender account balance is sufficient
    //     require(balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
    //     // Check if overflow will occur
    //     require(balances[recipient] + amount >= balances[recipient], "ERC20: transfer overflow occurs");
    //     balances[sender] -= amount;
    //     balances[recipient] += amount;
    //     emit Transfer(sender, recipient, amount);
    //     return true;
    // }
    ///???///

    ///???///
    // function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
    ///???///
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
        require(!frozenAccount[sender] && !frozenAccount[recipient], "ERC20: Address can't be frozenAccount");
        require(recipient != address(0), "ERC20: Address can't be zero address");
        require(amount <= balances[sender], "ERC20: transfer amount exceeds balance");
        require(amount <= allowed[sender][msg.sender], "ERC20: transfer amount exceeds balance allowed");
        ///???///
        require(amount > 0 ,"ERC20: amount can't be zero");
        ///???///
        balances[sender] -= amount;
        balances[recipient] += amount;
        allowed[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }


    /** @dev Creates `mint` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    //Token Minting
    function mintTo(address account, uint256 amount) public onlyOwner returns(bool success) {
        require(account != address(0), "ERC20: Address can't be zero address");
        require(!frozenAccount[account], "ERC20: Address can't be frozenAccount");
        ///???///
        require(amount > 0 ,"ERC20: amount can't be zero");
        ///???///
        balances[account] += amount;
        totalSupply += amount;
        emit Transfer(address(0), address(this), amount);
        emit Transfer(address(this), account, amount);
        return true;
    }

    function mint(uint256 amount) public onlyOwner returns(bool success) {
        require(owner != address(0), "ERC20: Address can't be zero address");
        require(!frozenAccount[owner], "ERC20: Address can't be frozenAccount");
        ///???///
        require(amount > 0 ,"ERC20: amount can't be zero");
        ///???///
        balances[owner] += amount;
        totalSupply += amount;
        emit Transfer(address(0), owner, amount);
        return true;
    }
    /**
     * @dev Destroys `amount` tokens from `owner`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `owner` must have at least `amount` tokens.
     */
    //Token Burning
    function burn(uint256 amount) public onlyOwner returns(bool success) {
        require(!frozenAccount[owner], "ERC20: Address can't be frozenAccount");
        require(balances[owner] >= amount, "ERC20: burn amount exceeds balance");
        ///???///
        require(amount > 0 ,"ERC20: amount can't be zero");
        ///???///
        balances[owner] -= amount;
        totalSupply -= amount;
        emit Burn(owner, amount);
        return true;
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
    //Token Burning From 
    function burnFrom(address account, uint256 amount) public onlyOwner returns(bool success) {
        require(!frozenAccount[owner], "ERC20: Address can't be frozenAccount");
        require(account != address(0), "ERC20: Address can't be zero address");
        require(balances[account] >= amount, "ERC20: burn amount exceeds balance");
        ///???///
        require(amount > 0 ,"ERC20: amount can't be zero");
        ///???///
        balances[account] -= amount;
        totalSupply -= amount;
        emit Burn(account, amount);
        return true;
    }
    // allow transfer of ownership to another address in case shit hits the fan.
    function transferOwnership(address newOwner) public onlyOwner {
        require(!frozenAccount[newOwner], "ERC20: Address can't be frozenAccount");
        owner = newOwner;
    }
    //Freeze account tokens 
    function freezeAccount(address target, bool freeze) public onlyOwner {
        ///???///
        require(target != owner, "ERC20: target can't be owner");
        ///???///
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual onlyOwner returns(bool) {
        require(!frozenAccount[spender], "ERC20: Address can't be frozenAccount");
        ///???///
        require(addedValue > 0 ,"ERC20: addedValue can't be zero");
        ///???///
        _approve(owner, spender, allowed[owner][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual onlyOwner returns(bool) {
        require(!frozenAccount[spender], "ERC20: Address can't be frozenAccount");
        uint256 currentAllowance = allowed[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        ///???///
        require(subtractedValue > 0 ,"ERC20: subtractedValue can't be zero");
        ///???///
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    /**
     * @dev Sets `amount` as the allowance of `spender` over the `_owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `_owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address _owner, address spender, uint256 amount) internal virtual onlyOwner {
        require(!frozenAccount[_owner] && !frozenAccount[spender], "ERC20: Address can't be frozenAccount");
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowed[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function bulkTransfer(address[] memory to, uint[] memory value) public onlyOwner returns(bool) {
        require(!frozenAccount[owner], "ERC20: Address can't be frozenAccount");
        uint arrayLength = value.length;
        require(arrayLength == to.length, "Invalid parameters");

        
        uint balance = balances[msg.sender];
        for (uint i = 0; i < arrayLength; i++) {
            balance -= value[i];
            balances[to[i]] += value[i];
            require(!frozenAccount[to[i]], "ERC20: bulkTransfer containing frozenAccount");
            require(to[i] != address(0), "ERC20: Address can't be zero address");
            ///???///
            require(value[i] > 0 ,"ERC20: value can't be zero");
            ///???///
            ///???///
            // require(value[i] <= balances[msg.sender], "ERC20: transfer amount exceeds balance");
            ///???///
            emit Transfer(msg.sender, to[i], value[i]);
        }
        balances[msg.sender] = balance;
        return true;
    }


}