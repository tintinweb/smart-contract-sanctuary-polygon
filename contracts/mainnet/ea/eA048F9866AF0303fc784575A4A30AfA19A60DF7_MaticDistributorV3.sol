/**
 *Submitted for verification at polygonscan.com on 2023-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IBurnt {
    function buyBurnPLG() external payable returns (bool);
}

interface IAllSale {
    function addMaticReward() external payable returns (bool);
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

library SafeMath {
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract MaticDistributorV3 is Context, Ownable {
  using SafeMath for uint256;

  constructor() {}
    
  function distribute() public payable returns (bool) {
    address marketing = 0xecbD0f18fAD82304F1328d045E6BcB7dFCAF215b;
    address reserve = 0xf81790B4fE34077d87358005Ee8DAf67D395d25e;
    address treasury = 0x72431f437C85CbCc4980f891117d409941ADa207;
    address rewardpool = 0x9aCCd8D9D0DDc42cB2DDad985B0Fdf0e0bFB81fC;
    address owner = 0xFDC1aA0440E4Fe98a270C797ED00CEA6A9497BC5;
    (bool success0,) = marketing.call{ value: msg.value * 20 / 150 }("");
    (bool success1,) = reserve.call{ value: msg.value * 20 / 150 }("");
    (bool success2,) = treasury.call{ value: msg.value * 20 / 150 }("");
    (bool success3,) = rewardpool.call{ value: msg.value * 10 / 150 }("");
    (bool success4,) = owner.call{ value: msg.value * 10 / 150 }("");
    require(success0&&success1&&success2&&success3&&success4, "Failed to send ETH");
    IBurnt(0xB7411694baf8DA10803a464ebE9a3f979344f908).buyBurnPLG{ value: msg.value * 10 / 150 }();
    IAllSale(0x5c114e877F5C5fbb692a386029d7858C95139383).addMaticReward{ value: address(this).balance }();
    return true;
  }

}