// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

contract Dai {
  // MODEL

  address public owner;
  address public pendingOwner;

  string public constant name = "Dai Stablecoin";
  string public constant symbol = "DAI";
  uint8 public immutable decimals = 18;

  address private constant ZERO = address(type(uint160).min);

  uint256 public totalSupply;
  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  constructor(address _owner) {
    require(_owner != address(0), "Zero");
    owner = _owner;
  }

  // EVENT

  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  // UPDATE

  function approve(address _spender, uint256 _value) external returns (bool) {
    _approve(msg.sender, _spender, _value);
    return true;
  }

  function transfer(address _to, uint256 _value) external returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) external returns (bool) {
    if (
      msg.sender != _from && allowance[_from][msg.sender] != type(uint256).max
    ) {
      allowance[_from][msg.sender] -= _value;

      emit Approval(_from, msg.sender, allowance[_from][msg.sender]);
    }
    _transfer(_from, _to, _value);
    return true;
  }

  function mint() external {
    totalSupply += 1000000000000000000000;
    balanceOf[msg.sender] += 1000000000000000000000;
    emit Transfer(ZERO, msg.sender, 1000000000000000000000);
  }

  function mint(uint256 _value) external {
    require(msg.sender == owner, "Forbidden");
    totalSupply += _value;
    balanceOf[msg.sender] += _value;
    emit Transfer(ZERO, msg.sender, _value);
  }

  // HELPER

  function _approve(
    address _owner,
    address _spender,
    uint256 _value
  ) private {
    allowance[_owner][_spender] = _value;
    emit Approval(_owner, _spender, _value);
  }

  function _transfer(
    address _from,
    address _to,
    uint256 _value
  ) private {
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(_from, _to, _value);
  }

  function setOwner(address _pendingOwner) external {
    require(msg.sender == owner, "Forbidden");
    require(_pendingOwner != address(0), "Zero");
    pendingOwner = _pendingOwner;
  }

  function acceptOwner() external {
    require(msg.sender == pendingOwner, "Forbidden");
    owner = msg.sender;
  }
}