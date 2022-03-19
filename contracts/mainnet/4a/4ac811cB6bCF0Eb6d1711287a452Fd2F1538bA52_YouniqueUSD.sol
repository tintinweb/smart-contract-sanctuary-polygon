/**
 *Submitted for verification at polygonscan.com on 2022-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);

        return a % b;
    }
}

library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event FreezeBalance(address account, uint256 value);

    event UnfreezeBalance(address account, uint256 value);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => uint256) private _freezeBalances;

    mapping(address => mapping(address => uint256)) private _allowed;

    uint256 private _totalSupply;

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public override view returns (uint256) {
        return _balances[owner];
    }

    function freezeBalanceOf(address owner) public view returns (uint256) {
        return _freezeBalances[owner];
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public virtual override(IERC20) returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _freeze(address account, uint256 value) internal {
        require(account != address(0));

        _freezeBalances[account] = _freezeBalances[account].add(value);
        emit FreezeBalance(account, value);
    }

    function _unfreeze(address account, uint256 value) internal {
        require(account != address(0));

        _freezeBalances[account] = _freezeBalances[account].sub(value);
        emit UnfreezeBalance(account, value);
    }

    function _canTransfer(address from, uint256 value) internal view returns (bool) {
        if (_freezeBalances[from] >= _balances[from]) {
            return false;
        }

        if (_freezeBalances[from] < _balances[from] && _balances[from].sub(_freezeBalances[from]) < value) {
            return false;
        }

        return true;
    }

}
//参数
abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory NAME, string memory SYMBOL, uint8 DECIMALS)  {
        _name = NAME;
        _symbol = SYMBOL;
        _decimals = DECIMALS;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20Burnable is ERC20, Ownable {
    function burn(address to, uint256 value) public onlyOwner returns (bool){
        _burn(to, value);
        return true;
    }
}

contract ERC20Mintable is ERC20, Ownable {
    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        _mint(to, value);
        return true;
    }
}

contract MinterRole is Ownable {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor ()  {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyOwner {
        _addMinter(account);
    }

    function removeMinter(address account) public onlyOwner {
        _removeMinter(account);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

contract ERC20Freeze is ERC20, MinterRole {

    function freeze(address account, uint256 value) public onlyMinter returns (bool){
        _freeze(account, value);
        return true;
    }

    function unfreeze(address account, uint256 value) public onlyMinter returns (bool){
        _unfreeze(account, value);
        return true;
    }

}

contract YouniqueUSD is ERC20, Ownable, ERC20Detailed, ERC20Mintable, ERC20Burnable, ERC20Freeze {
    uint constant private INITIAL_SUPPLY = 2E14;
    string constant private NAME = "YouniqueUSD";
    string constant private SYMBOL = "YUSD";
    uint8 constant private DECIMALS = 6;

    address constant internal ZERO_ADDRESS = address(0);

    constructor()
    ERC20()
    ERC20Detailed(NAME, SYMBOL, DECIMALS)
    ERC20Mintable()
    ERC20Burnable()
    ERC20Freeze()
    Ownable() 
    {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function transfer(address to, uint256 value) public override(ERC20, IERC20) returns (bool) {
        bool transferAllowed;
        transferAllowed = _canTransfer(msg.sender, value);
        if (transferAllowed) {
            _transfer(msg.sender, to, value);
        }
        return transferAllowed;
    }

}