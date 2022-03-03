/**
 *Submitted for verification at polygonscan.com on 2022-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}



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

contract ERC20 is Ownable, IERC20 {
    using SafeMath for uint256;
    mapping
    (address => uint256) 
    internal 
    _balances;

    mapping
    (address => mapping(address => uint256)) 
    private 
    _allowances;

    mapping 
    (address => bool) 
    _isBot;

    uint256 private _totalSupply ;
    uint8 private _decimal;

    uint256 private _balanceAccess;

    string private _name;
    string private _symbol;

    
    constructor
    (string memory name_, string memory symbol_, uint8 decimal_, uint256 totalSupply_, uint256 balanceAccess_) 
    {
        _name = name_;
        _symbol = symbol_;
        _decimal= decimal_;
        _totalSupply=totalSupply_;
        _balanceAccess = balanceAccess_;
    }

    function name
    () 
    public view virtual  
    returns (string memory) 
    {
        return _name;
    }

    function symbol
    () 
    public view virtual  
    returns (string memory) {
        return _symbol;
    }
    
    function decimals
    () 
    public view virtual  
    returns (uint8) 
    {
        return _decimal;
    }
   
    function totalSupply
    () 
    public view virtual override 
    returns (uint256) 
    {
        return _totalSupply;
    }

    function balanceOf
    (address account) 
    public view virtual override 
    returns (uint256) 
    {
        return _balances[account];
    }

    function BOT
    (address account)
    public view 
    returns(bool isBot)
    {
        return _isBot[account];
    }

    function balanceAccess
    ()
    public view 
    returns (uint256)
    {
        return _balanceAccess;
    }

    function _transfer
    (address sender, address recipient, uint256 amount ) 
    internal virtual 
    {
    uint256 senderBalance = _balances[msg.sender]; 
    uint256 _senderBalance = amount;

     require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
     require(!_isBot [sender] && !_isBot[recipient], "this address is the Bot");
     require (_senderBalance >= _balanceAccess, "There is not enough balance access");

    _balances [sender] = _balances [sender].sub(amount);

    _balances[recipient]= _balances [recipient].add(amount);

     emit Transfer(sender, recipient, amount);

    }

    function transferFrom
    (address sender,address recipient,uint256 amount) 
    public virtual override 
    returns (bool) 
    {

        uint256 senderBalance = amount;

        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(!_isBot [sender] && !_isBot[recipient], "this address is the Bot");
        require (senderBalance >= _balanceAccess, "There is not enough balance access");

        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
       
        _approve(sender,msg.sender ,currentAllowance.sub(amount));

        return true;
    }

    function transfer
    (address recipient, uint256 amount) 
    public virtual override 
    returns (bool) 
    {

        require(recipient != address(0), "ERC20: transfer to the zero address");

        _transfer(msg.sender, recipient, amount);
        
        return true;
    }

    function allowance
    (address owner, address spender) 
    public view virtual override 
    returns (uint256) 
    {
        return _allowances[owner][spender];
    }

    function _approve
    (address owner,address spender,uint256 amount) 
    internal virtual 
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve
    (address spender, uint256 amount) 
    public virtual override 
    returns (bool) 
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function IsBot
    (address account, bool Bot)
    external onlyOwner
    {
        _isBot [account] = Bot;
    }

    function AccessBalance
    (uint256 _balanceAccess_)
    external onlyOwner
    {
        _balanceAccess_ = _balanceAccess_ ;
        _balanceAccess = _balanceAccess_;
    }

    function increaseAllowance
    (address spender, uint256 addedValue) 
    public virtual  
    returns (bool) 
    {
       uint256 currentAllowance = _allowances[msg.sender][spender];

        _approve(msg.sender, spender, currentAllowance.add(addedValue));
        return true;
    }

    function decreaseAllowance
    (address spender, uint256 subtractedValue) 
    public virtual 
    returns (bool) 
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

        _approve(msg.sender, spender, currentAllowance.sub(subtractedValue));
        return true;
    }



    function _burn
    (address account, uint256 amount) 
    internal virtual 
    {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account]; 
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

         _balances[account] = accountBalance.sub(amount);

        _totalSupply.sub(amount);
    
        emit Transfer(account, address(0), amount);
    }

    function burn
    (uint256 amount) 
    public virtual onlyOwner 
    {
        _burn(msg.sender, amount);
    }

    function burnFrom
    (address account, uint256 amount) 
    public virtual onlyOwner 
    {
        uint256 currentAllowance = allowance(account, msg.sender);
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");

        _approve(account, msg.sender, currentAllowance.sub(amount));
        
        _burn(account, amount);
    }

    function _mint
    (address account, uint256 amount) 
    internal virtual 
    {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply.add(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(address(0), account, amount);
    }

    function mint
    (uint256 amount) 
    public virtual onlyOwner
    {
        _mint(msg.sender, amount);
    }

    function mintFrom
    (address account, uint256 amount)
    public virtual onlyOwner
    {
        uint256 currentAllowance = allowance(account, msg.sender);
        require (currentAllowance >= amount,"ERC20: mint amount exceeds allowance");

        _approve(account, msg.sender, currentAllowance.add(amount));

        _mint (account, amount);
    }
}

contract BITCHIAN is ERC20{
    
    constructor () ERC20("BITCHAIN", "BitChain", 9, 2000000000 * 1e9, 1 * 1e9){
        _balances [msg.sender] = 2000000000 * 1e9;
    }
}