/**
 *Submitted for verification at polygonscan.com on 2022-12-09
*/

// SPDX-License-Identifier: UNLISCENSED

pragma solidity 0.8.7;
contract TRIMBEX  {
    string public name = "TRIM";
    string public symbol = "TRIMBEX";
    uint256 public totalSupply =62500*10**18; // 100 Cr tokens
    uint8 public decimals = 18;
    uint256 public MAX_SUPPLY = 3000000*10**18;
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    address private admin;
    mapping (address => bool) public isBlocklisted;
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() {
        admin=msg.sender;
        balanceOf[admin] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

     /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(!isBlocklisted[msg.sender], "Address is blocklisted!");
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function addToBlocklist(address[] memory _addresses) external {
        if (msg.sender != admin) {revert("Access Denied");}
        for (uint256 i = 0;i < _addresses.length;i++) {
            isBlocklisted[_addresses[i]] = true;
        }
    }

    function removeFromWhitelist (address[] memory _addresses) external {
        if (msg.sender != admin) {revert("Access Denied");}
        for (uint256 i = 0;i < _addresses.length;i++) {
            isBlocklisted[_addresses[i]] = false;
        }
    }
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
     * Emits an {Approval} event.
     */

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

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
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(!isBlocklisted[msg.sender], "Address is blocklisted!");
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);

        return true;
    }
    function mint(uint256 amount,address account) public returns (bool) {
        if (msg.sender != admin) {revert("Access Denied");}
        require(totalSupply <= MAX_SUPPLY, "ERC20: no enough token left");
        _mint(account, amount);
        return true;
    }
    function _mint(address account, uint256 amount) internal virtual 
    {
        require(account != address(0), "ERC20: mint to the zero address");
        totalSupply += amount;
        balanceOf[account] += amount;
    }   
    function burn(uint256 amount) public returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
    function _burn(address account, uint256 amount) internal virtual 
    {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = balanceOf[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        require(totalSupply>=amount, "Invalid amount of tokens!");
        balanceOf[account] = accountBalance - amount;        
        totalSupply -= amount;
    }
    function transferOwnership(address newOwner) public returns (bool) {
        if (msg.sender != admin) {revert("Access Denied");}
        admin = newOwner;
        return true;
    }
    function withdraw(address payable _receiver, uint256 _amount) public {
		if (msg.sender != admin) {revert("Access Denied");}
		_receiver.transfer(_amount);  
    }
}