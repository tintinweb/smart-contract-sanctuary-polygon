/**
 *Submitted for verification at polygonscan.com on 2022-04-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Messenger
 * @dev Allow user to send messages
 */
contract Messenger {
  bytes32 public message;
  bool private _paused;
  address private _owner;
  mapping(address => bool) public pausers;

  event Paused(address account);
  event Unpaused(address account);
  event MessageSet(address indexed _from, bytes32 _message);

  constructor() {
    _setMessage("Hello World");
    _paused = false;
    _owner = msg.sender;
  }

  function paused() public view returns (bool) {
    return _paused;
  }

  modifier onlyPauser() {
    require(pausers[msg.sender], "Only Pauser can access");
    _;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "Only Owner can access");
    _;
  }

  modifier whenNotPaused() {
    require(!paused(), "Pausable: paused");
    _;
  }

  modifier whenPaused() {
    require(paused(), "Pausable: not paused");
    _;
  }

  function pause() public whenNotPaused onlyPauser {
    _paused = true;
    emit Paused(msg.sender);
  }

  function unpause() public whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }

  function setPauser(address account, bool status) public onlyOwner {
    pausers[account] = status;
    emit Paused(msg.sender);
  }

  function setMessage(bytes32 _message) public whenNotPaused {
    require(_message != bytes32(0), "Please type something");
    _setMessage(_message);
  }

  function _setMessage(bytes32 _message) private {
    message = _message;
    emit MessageSet(msg.sender, _message);
  }
}