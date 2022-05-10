// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Auth} from "../utils/Auth.sol";

contract SeedGwit is Auth {
  event Transfer(address indexed from, address indexed to, uint256 amount);

  string public constant name = "SeedGwit";
  string public constant symbol = "sGWIT";
  uint8 public constant decimals = 18;

  uint256 public totalSupply;

  mapping(address => uint256) public balanceOf;

  function mint(address to, uint256 amount) external onlyRole("MINTER") {
    totalSupply += amount;

    unchecked {
      balanceOf[to] += amount;
    }

    emit Transfer(address(0), to, amount);
  }

  function burn(uint256 amount) external whenNotPaused {
    address from = msg.sender;
    balanceOf[from] -= amount;

    unchecked {
      totalSupply -= amount;
    }

    emit Transfer(from, address(0), amount);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

library Strings {
  function toBytes32(string memory text) internal pure returns (bytes32) {
    return bytes32(bytes(text));
  }

  function toString(bytes32 text) internal pure returns (string memory) {
    return string(abi.encodePacked(text));
  }
}

contract Auth {
  //Address of current owner
  address public owner;
  //Address of new owner (Note: new owner must pull to be an owner)
  address public newOwner;
  //If paused or not
  uint256 private _paused;
  //Roles mapping (role => address => has role)
  mapping(bytes32 => mapping(address => bool)) private _roles;

  //Fires when a new owner is pushed
  event OwnerPushed(address indexed pushedOwner);
  //Fires when new owner pulled
  event OwnerPulled(address indexed previousOwner, address indexed newOwner);
  //Fires when account is granted role
  event RoleGranted(string indexed role, address indexed account, address indexed sender);
  //Fires when accoount is revoked role
  event RoleRevoked(string indexed role, address indexed account, address indexed sender);
  //Fires when pause is triggered by account
  event Paused(address account);
  //Fires when pause is lifted by account
  event Unpaused(address account);

  error Unauthorized(string role, address user);
  error IsPaused();
  error NotPaused();

  constructor() {
    owner = msg.sender;
    emit OwnerPulled(address(0), msg.sender);
  }

  modifier whenNotPaused() {
    if (paused()) revert IsPaused();
    _;
  }

  modifier whenPaused() {
    if (!paused()) revert NotPaused();
    _;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) revert Unauthorized("OWNER", msg.sender);
    _;
  }

  modifier onlyRole(string memory role) {
    if (!hasRole(role, msg.sender)) revert Unauthorized(role, msg.sender);
    _;
  }

  function hasRole(string memory role, address account) public view virtual returns (bool) {
    return _roles[Strings.toBytes32(role)][account];
  }

  function paused() public view virtual returns (bool) {
    return _paused == 1 ? true : false;
  }

  function pushOwner(address account) public virtual onlyOwner {
    require(account != address(0), "No address(0)");
    require(account != owner, "Only new owner");
    newOwner = account;
    emit OwnerPushed(account);
  }

  function pullOwner() public virtual {
    if (msg.sender != newOwner) revert Unauthorized("NEW_OWNER", msg.sender);
    address oldOwner = owner;
    owner = msg.sender;
    emit OwnerPulled(oldOwner, msg.sender);
  }

  function grantRole(string memory role, address account) public virtual onlyOwner {
    require(bytes(role).length > 0, "Role not given");
    require(account != address(0), "No address(0)");
    _grantRole(role, account);
  }

  function revokeRole(string memory role, address account) public virtual onlyOwner {
    require(hasRole(role, account), "Role not granted");
    _revokeRole(role, account);
  }

  function renounceRole(string memory role) public virtual {
    require(hasRole(role, msg.sender), "Role not granted");
    _revokeRole(role, msg.sender);
  }

  function pause() public virtual onlyRole("PAUSER") whenNotPaused {
    _paused = 1;
    emit Paused(msg.sender);
  }

  function unpause() public virtual onlyRole("PAUSER") whenPaused {
    _paused = 0;
    emit Unpaused(msg.sender);
  }

  function _grantRole(string memory role, address account) internal virtual {
    if (!hasRole(role, account)) {
      bytes32 encodedRole = Strings.toBytes32(role);
      _roles[encodedRole][account] = true;
      emit RoleGranted(role, account, msg.sender);
    }
  }

  function _revokeRole(string memory role, address account) internal virtual {
    bytes32 encodedRole = Strings.toBytes32(role);
    _roles[encodedRole][account] = false;
    emit RoleRevoked(role, account, msg.sender);
  }
}