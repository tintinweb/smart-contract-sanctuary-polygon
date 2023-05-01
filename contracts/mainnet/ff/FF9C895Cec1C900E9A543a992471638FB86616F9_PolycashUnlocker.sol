/**
 *Submitted for verification at polygonscan.com on 2023-04-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPLCv2 {
    function changeLevelWithPermit(address addr,uint256 level) external returns (bool);
    function updateUserWithPermit(address addr,uint256[] memory values,address referral,bool flag) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender());
        _;
    }

    function transferOwnership(address account) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, account);
        _owner = account;
    }

}

contract PolycashUnlocker is Context, Ownable {

  address PLCv2 = 0xfE74Be25FF81B2857983150fbAA5cb626efa13Dd;

  constructor() {}

  function unlocker(address addr) public payable returns (bool) {
    require(msg.value==150 ether,"!Error On Deposit Value");
    (bool success,) = PLCv2.call{ value: address(this).balance }("");
    require(success, "!fail to send eth");
    IPLCv2(PLCv2).changeLevelWithPermit(addr,30);
    return true;
  }

  function withdrawStuckNative(uint256 amount) public onlyOwner returns (bool) {
    (bool success,) = msg.sender.call{ value: amount }("");
    require(success, "!fail to send eth");
    return true;
  }

}