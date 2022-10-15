// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@0xsequence/erc-1155/contracts/utils/SafeMath.sol";
import "@0xsequence/erc-1155/contracts/utils/Ownable.sol";
import "./library/MinterRole.sol";
import "./library/PERC20.sol";


contract PostringsPlatformToken is PERC20, Ownable, MinterRole {
    uint constant private INITIAL_SUPPLY = 2E14;
    string constant private NAME = "PostringsPlatformToken";
    string constant private SYMBOL = "PPT";
    uint8 constant private DECIMALS = 6;

    address constant internal ZERO_ADDRESS = address(0);

    constructor()
    PERC20(NAME, SYMBOL, DECIMALS)
    {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        _mint(to, value);
        return true;
    }

    function burn(address to, uint256 value) public onlyOwner returns (bool){
        _burn(to, value);
        return true;
    }

    function transfer(address to, uint256 value) public override(PERC20) returns (bool) {
        bool transferAllowed;
        transferAllowed = _canTransfer(msg.sender, value);
        if (transferAllowed) {
            _transfer(msg.sender, to, value);
        }
        return transferAllowed;
    }

    function freeze(address account, uint256 value) public onlyMinter returns (bool){
        _freeze(account, value);
        return true;
    }

    function unfreeze(address account, uint256 value) public onlyMinter returns (bool){
        _unfreeze(account, value);
        return true;
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

pragma solidity >=0.5.0;

import "@0xsequence/erc-1155/contracts/utils/SafeMath.sol";

interface PIERC20 {
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

contract PERC20 is PIERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => uint256) private _freezeBalances;

    mapping(address => mapping(address => uint256)) private _allowed;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory NAME, string memory SYMBOL, uint8 DECIMALS)  {
        _name = NAME;
        _symbol = SYMBOL;
        _decimals = DECIMALS;
    }


    function name() public view returns (string memory) {
        return _name;
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function decimals() public view returns (uint8) {
        return _decimals;
    }

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

    function transfer(address to, uint256 value) public virtual override(PIERC20) returns (bool) {
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

pragma solidity >=0.5.0;

import "@0xsequence/erc-1155/contracts/utils/Ownable.sol";
import "./Roles.sol";

contract MinterRole is Ownable {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () {
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

pragma solidity 0.7.4;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }
}

pragma solidity 0.7.4;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner_;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor () {
    _owner_ = msg.sender;
    emit OwnershipTransferred(address(0), _owner_);
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == _owner_, "Ownable#onlyOwner: SENDER_IS_NOT_OWNER");
    _;
  }

  /**
   * @notice Transfers the ownership of the contract to new address
   * @param _newOwner Address of the new owner
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0), "Ownable#transferOwnership: INVALID_ADDRESS");
    emit OwnershipTransferred(_owner_, _newOwner);
    _owner_ = _newOwner;
  }

  /**
   * @notice Returns the address of the owner.
   */
  function owner() public view returns (address) {
    return _owner_;
  }
}