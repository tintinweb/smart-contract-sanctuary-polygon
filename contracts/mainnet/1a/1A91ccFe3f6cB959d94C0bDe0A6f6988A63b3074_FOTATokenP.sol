// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./libs/zeppelin/token/BEP20/IBEP20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract TokenPAuth is Context {

  address internal backup;
  address internal owner;
  address internal contractAdmin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

  constructor(address _owner) {
    owner = _owner;
    backup = _owner;
    contractAdmin = _owner;
  }

  modifier onlyOwner() {
    require(isOwner(), "onlyOwner");
    _;
  }

  modifier onlyBackup() {
    require(isBackup(), "onlyBackup");
    _;
  }

  modifier onlyContractAdmin() {
    require(isContractAdmin(), "onlyContractAdmin");
    _;
  }

  function transferOwnership(address _newOwner) external onlyBackup {
    require(_newOwner != address(0), "TokenPAuth: invalid new owner");
    owner = _newOwner;
    emit OwnershipTransferred(_msgSender(), _newOwner);
  }

  function updateBackup(address _newBackup) external onlyBackup {
    require(_newBackup != address(0), "TokenPAuth: invalid new backup");
    backup = _newBackup;
  }

  function updateContractAdmin(address _newAdmin) external onlyOwner {
    require(_newAdmin != address(0), "TokenPAuth: invalid new admin");
    contractAdmin = _newAdmin;
  }

  function isOwner() public view returns (bool) {
    return _msgSender() == owner;
  }

  function isBackup() public view returns (bool) {
    return _msgSender() == backup;
  }

  function isContractAdmin() public view returns (bool) {
    return _msgSender() == contractAdmin;
  }
}

contract FOTATokenP is IBEP20, TokenPAuth {
  string public constant name = "Fight Of The Ages";
  string public constant symbol = "FOTA";
  uint public constant decimals = 6;

  uint public constant maxSupply = 700e12;
  uint public totalSupply;
  bool public paused;
  bool public lockingFunctionEnabled = true;

  mapping (address => uint) internal _balances;
  mapping (address => mapping (address => uint)) private _allowed;
  mapping (address => bool) lock;

  constructor() TokenPAuth(msg.sender) {
  }

  function balanceOf(address _owner) override external view returns (uint) {
    return _balances[_owner];
  }

  function allowance(address _owner, address _spender) override external view returns (uint) {
    return _allowed[_owner][_spender];
  }

  function transfer(address _to, uint _value) override external returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function approve(address _spender, uint _value) override external returns (bool) {
    _approve(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) override external returns (bool) {
    _transfer(_from, _to, _value);
    _approve(_from, msg.sender, _allowed[_from][msg.sender] - _value);
    return true;
  }

  function increaseAllowance(address _spender, uint _addedValue) external returns (bool) {
    _approve(msg.sender, _spender, _allowed[msg.sender][_spender] + _addedValue);
    return true;
  }

  function decreaseAllowance(address _spender, uint _subtractedValue) external returns (bool) {
    _approve(msg.sender, _spender, _allowed[msg.sender][_spender] - _subtractedValue);
    return true;
  }

  function mint(address _owner, uint _amount) external onlyContractAdmin {
    _validateAbility(_owner);
    require(totalSupply + _amount <= maxSupply, "Amount invalid");
    _balances[_owner] = _balances[_owner] + _amount;
    totalSupply = totalSupply + _amount;
    emit Transfer(address(0), _owner, _amount);
  }

  function burn(uint _amount) external {
    _balances[msg.sender] = _balances[msg.sender] - _amount;
    totalSupply = totalSupply - _amount;
    emit Transfer(msg.sender, address(0), _amount);
  }

  function updatePauseStatus(bool _paused) onlyOwner external {
    paused = _paused;
  }

  function updateLockStatus(address _address, bool _locked) onlyOwner external {
    require(lockingFunctionEnabled, "Locking function is disabled");
    lock[_address] = _locked;
  }

  function disableLockingFunction() onlyOwner external {
    lockingFunctionEnabled = false;
  }

  function checkLockStatus(address _address) external view returns (bool) {
    return lock[_address];
  }

  function _transfer(address _from, address _to, uint _value) private {
    _validateAbility(_from);
    _balances[_from] = _balances[_from] - _value;
    _balances[_to] = _balances[_to] + _value;
    if (_to == address(0)) {
      totalSupply = totalSupply - _value;
    }
    emit Transfer(_from, _to, _value);
  }

  function _approve(address _owner, address _spender, uint _value) private {
    require(_spender != address(0));
    require(_owner != address(0));

    _allowed[_owner][_spender] = _value;
    emit Approval(_owner, _spender, _value);
  }

  function _validateAbility(address _owner) private view {
    if (lockingFunctionEnabled) {
      require(!lock[_owner] && !paused, "You can not do this at the moment");
    } else {
      require(!paused, "You can not do this at the moment");
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IBEP20 {

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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