/**
 *Submitted for verification at polygonscan.com on 2023-04-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
      return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

    constructor() {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
      return _owner;
    }

    modifier onlyOwner() {
      require( _owner == _msgSender());
      _;
    }

    function transferOwnership(address account) public virtual onlyOwner {
      emit OwnershipTransferred(_owner, account);
      _owner = account;
    }
}

contract onchainWallet is Context, Ownable {

    address public host;

    constructor() {
      host = msg.sender;
    }

    function updateHost(address adr) public onlyOwner returns (bool) {
      host = adr;
      return true;
    }

    function processETH2Host() public returns (bool) {
      (bool success,) = host.call{ value: address(this).balance }("");
      require(success, "Failed to send ETH");
      return true;
    }

    function processToken2Host(address _token) public returns (bool) {
      uint256 balance = IERC20(_token).balanceOf(address(this));
      IERC20(_token).transfer(host,balance);
      return true;
    }
}