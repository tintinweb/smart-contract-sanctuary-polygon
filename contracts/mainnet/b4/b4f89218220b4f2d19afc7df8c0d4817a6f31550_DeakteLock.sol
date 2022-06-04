/**
 *Submitted for verification at polygonscan.com on 2022-06-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface Token {
    function transfer(address, uint) external returns (bool);
}
interface LegacyToken {
    function transfer(address, uint) external;
}
contract DeakteLock is Ownable {
    using SafeMath for uint;
    
    uint public unlockTime;
    uint public constant MAX_EXTENSION_ALLOWED = 30 days;
    
    constructor(uint initialUnlockTime) {
        require(initialUnlockTime > block.timestamp, "Cannot set an unlock time in past!");
        unlockTime = initialUnlockTime;
    }
    
    function isUnlocked() public view returns (bool) {
        return block.timestamp > unlockTime;
    }
    
    function extendLock(uint extendedUnlockTimestamp) external onlyOwner {
        require(extendedUnlockTimestamp > block.timestamp && extendedUnlockTimestamp > unlockTime , "Cannot set an unlock time in past!");
        require(extendedUnlockTimestamp.sub(block.timestamp) <= MAX_EXTENSION_ALLOWED, "Cannot extend beyond MAX_EXTENSION_ALLOWED period!");
        unlockTime = extendedUnlockTimestamp;
    }
    
    function claim(address tokenAddress, address recipient, uint amount) external onlyOwner {
        require(isUnlocked(), "Not Unlocked Yet!");
        require(Token(tokenAddress).transfer(recipient, amount), "Transfer Failed!");
    }

    function claimLegacyToken(address tokenAddress, address recipient, uint amount) external onlyOwner {
        require(isUnlocked(), "Not Unlocked Yet!");
        LegacyToken(tokenAddress).transfer(recipient, amount);
    }
}