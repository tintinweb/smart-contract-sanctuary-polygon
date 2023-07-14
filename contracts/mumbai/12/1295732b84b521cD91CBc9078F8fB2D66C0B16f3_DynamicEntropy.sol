/**
 *Submitted for verification at polygonscan.com on 2023-07-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract DynamicEntropy {

  uint256 constant _D = 52;
  uint256 constant _P = 87;
  uint256 constant _G = 73;

  struct Player {
    uint256 baseKey; // b(i,0)
    uint256 index; 
    mapping(address => uint256) sideKey; // b(i,j)
  }

  struct ElGamal {
    uint256 a;
    uint256 b;
  }

  mapping(address => Player) private _players;
  mapping(address => ElGamal) private _cards;
  mapping(uint256 => address) private _playerAddress;

  uint256 private _currentRandomic;
  uint256 public _betPlayerCount = 0;
  uint256 public _totalPlayerCount = 0;

  function random() private view returns (uint) {
    uint hashNumber =  uint(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, msg.sender)));
    return hashNumber % _P;
  }

  function pow(uint256 value, uint256 size, uint256 divider) private pure returns (uint256){
    uint256 result = 1;
    for (uint256 i = 0; i < size; i ++) {
      result = result * value % divider;
    }

    return result;
  }

  function calculateB(address i, address j) 
    public 
    view 
    returns (uint256) 
  {
    uint256 userOp;
    if (i == j) {
      userOp = _players[i].baseKey;
    } else {
      userOp = _players[i].sideKey[j];
    }

    return pow(_G, userOp, _P);
  }

  function calculateFx(address i, uint256 x) 
    public 
    view 
    returns (uint256) 
  {
    uint256 result = _players[i].baseKey;
    uint256 _m = 1;
    for (uint256 j = 0; j < _totalPlayerCount; j ++) {
      address key = _playerAddress[j];
      if (key == i) continue;

      result = result + _players[i].sideKey[key] * (x ** _m);
      _m ++;
    }

    return result;
  }

  function validateUser(address addr) public view returns (bool) {
    for (uint256 index = 1; index <= _totalPlayerCount; index ++) {
      if (addr == _playerAddress[index - 1]) {
        continue;
      }
      uint256 _fx = calculateFx(addr, index);
      uint256 _userOp = 1;
      uint256 _m = 1;
      for (uint256 j = 0; j < _totalPlayerCount; j ++) {
        address bKey = _playerAddress[j];
        uint256 _b_ = calculateB(addr, bKey);
        if (bKey != addr) {
          _b_ = pow(_b_, index ** _m, _P);
          _m ++;
        }
        _userOp = (_userOp * _b_) % _P;
      }

      if (pow(_G, _fx, _P) != _userOp) return false;
    }

    return true;
  }

  function isUserExist(address account) public view returns (bool) {
    if (_players[account].baseKey != 0) return true;
    return false;
  }

  function isUserAlreadyBet(address account) public view returns (bool) {
    if (_cards[account].a != 0) return true;
    return false;
  }

  function resetBetting() public {
    for (uint256 i = 0; i < _totalPlayerCount; i ++) {
      address key = _playerAddress[i];
      if (_cards[key].a != 0) {
        delete _cards[key];
      }
    }
    _betPlayerCount = 0;
  }

  function getKeyPair(address account) 
    public view returns (uint256, uint256)
  {
    require(_players[account].baseKey != 0, "User does not exist");
    require(validateUser(account), "User is a faker");

    uint256 pubKey = 1;
    uint256 privKey = 0;
    for (uint256 i = 0; i < _totalPlayerCount; i ++) {
      address bKey = _playerAddress[i];
      pubKey = pubKey * pow(_G, _players[bKey].baseKey, _P);
      pubKey = pubKey % _P;
      privKey = privKey + _players[bKey].baseKey;
      privKey = privKey % (_P - 1);
    }

    return (privKey, pubKey);
  }

  function joinGame(uint256 baseKey) 
    public 
  {
    require(_players[msg.sender].baseKey == 0, "User already joined");

    _players[msg.sender].baseKey = baseKey;
    _players[msg.sender].index = _totalPlayerCount;

    for (uint256 i = 0; i < _totalPlayerCount; i ++) {
      address key = _playerAddress[i];
      _players[key].sideKey[msg.sender] = random();
      _players[msg.sender].sideKey[key] = random();
    }

    _playerAddress[_totalPlayerCount] = msg.sender;

    _totalPlayerCount ++;
  }

  function betRound(uint256 seed, uint256 publicKey) public {
    require(_players[msg.sender].baseKey != 0, "User does not exist");
    require(_cards[msg.sender].a == 0, "User already bet");
    require(publicKey != 0, "Invalid Public Key");

    uint256 _e = random();
    uint256 cardB = seed;
    cardB = cardB * pow(publicKey, _e, _P);
    uint256 cardA = pow(_G, _e, _P);

    _cards[msg.sender].a = cardA;
    _cards[msg.sender].b = cardB;
    _betPlayerCount ++;
  }

  function openRoundCard(uint256 privateKey) 
    public 
    view 
    returns (uint256, uint256, uint256)
  {
    uint256 a = 1;
    uint256 b = 1;
    for (uint256 i = 0; i < _totalPlayerCount; i ++) {
      address key = _playerAddress[i];
      if (_cards[key].a != 0) {
        a = a * _cards[key].a % _P;
        b = b * _cards[key].b % _P;
      }
    }
    uint256 R = 0;
    uint256 a_x = pow(a, privateKey, _P);
    for (; R < _P; R ++) {
      if (b == (a_x * R) % _P) break;
    }
    return (a,b,R);
  }
}