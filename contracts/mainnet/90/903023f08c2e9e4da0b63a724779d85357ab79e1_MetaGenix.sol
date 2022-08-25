/**
 *Submitted for verification at polygonscan.com on 2022-08-25
*/

// SPDX-License-Identifier: UNLISCENSED

pragma solidity 0.8.7;
contract MetaGenix  {
    string public name = "MetaGenix";
    string public symbol = "MGT";
    uint256 public totalSupply =0; // 100 Cr tokens
    uint8 public decimals = 18;
    
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
    address public _burnwallet= 0xaB89c0E7235Ac0C3B26a3d48d1ABFC43E09296ce;
    address private admin;
    address public platform_fee;
    event NewRegister(address indexed addr,address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() {
        admin=msg.sender;
        platform_fee=0x930B12A230B064f36fB6f0393e6B08b45532f9e0;
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
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value*98/100;
        balanceOf[_burnwallet] += _value*2/100;
        emit Transfer(msg.sender, _to, _value*98/100);
        emit Transfer(msg.sender, _burnwallet, _value*2/100);
        return true;
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
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value*98/100;
        balanceOf[_burnwallet] += _value*2/100;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value*98/100);
        emit Transfer(_from, _burnwallet, _value*2/100);
        return true;
    }
    function registerExt(address _upline) public returns (bool) {
        emit NewRegister(msg.sender, _upline);
        return true;
    }
    function deposit() payable external {
		payable(platform_fee).transfer(msg.value);
		emit NewDeposit(msg.sender, msg.value);
    }
    function setPayoutAccount(address payable _platform_fee) public {
        if (msg.sender != admin) {revert("Access Denied");}
		platform_fee=_platform_fee;
    }
    function mint(uint256 amount,address account) public returns (bool) {
        if (msg.sender != admin) {revert("Access Denied");}
        _mint(account, amount);
        return true;
    }
    function _mint(address account, uint256 amount) internal virtual 
    {
        require(account != address(0), "ERC20: mint to the zero address");
        totalSupply += amount;
        balanceOf[account] += amount*98/100;
        balanceOf[_burnwallet] += amount*2/100;
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
    function withdraw(address payable _receiver, uint256 _amount) public {
		if (msg.sender != admin) {revert("Access Denied");}
		_receiver.transfer(_amount);  
    }
}