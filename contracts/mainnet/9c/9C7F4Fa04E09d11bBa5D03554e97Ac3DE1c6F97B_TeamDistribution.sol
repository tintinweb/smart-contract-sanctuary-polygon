// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface TOKEN {
  function balanceOf(address account) external view returns(uint256);
  function transfer(address recipient, uint256 amount) external returns(bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}

contract TeamDistribution {
  address public admin;
  address[] private members;

  TOKEN public hrtToken;

  uint256 public constant DENOMINATOR = 1000;

  mapping (address => uint256) public percent;

  event Withdraw(
    address indexed caller,
    uint256 amount,
    uint256 withdrawDate
  );

  modifier onlyAdmin {
    require(msg.sender == admin, "caller is not admin");
    _;
  }

  constructor(address _hrtToken) {
    hrtToken = TOKEN(_hrtToken);
    admin = msg.sender;
  }

  function withdraw() external {
    uint256 denominator_ = DENOMINATOR;
    uint256 balance_ = hrtToken.balanceOf(address(this));
    require(balance_ > 0, "empty pool");

    for (uint256 i = 0; i < members.length; i++) {
      address member = members[i];
      uint256 amount_ = balance_ * percent[member] / denominator_;
      if (amount_ > 0) {
        hrtToken.transfer(member, amount_);
      }
    }

    emit Withdraw(msg.sender, balance_, block.timestamp);
  }

  function balanceOf() public view returns (uint256) {
    return hrtToken.balanceOf(address(this));
  }

  function changeAdmin(address _newAdmin) external onlyAdmin {
    require(_newAdmin != address(0), "can't be zero address");
    admin = _newAdmin;
  }

  function changeHrtAddr(address _new) external onlyAdmin {
    require(_new != address(0), "can't be zero address");
    hrtToken = TOKEN(_new);
  }

  function getPercents() external view returns (uint256[] memory) {
    uint256[] memory pcs_;
    for (uint256 i = 0; i < members.length; i++) {
      pcs_[i] = percent[members[i]];
    }

    return pcs_;
  }

  function getMembers() external view returns (address[] memory) {
    return members;
  }

  function removeHolders(uint256 _index) external onlyAdmin {
    require(_index < members.length, "invalid index");
    for (uint256 i = _index; i < members.length - 1; i++) {
      members[i] = members[i + 1];
    }
    members.pop();
  }

  function setHolders(address[] memory _newMembers, uint256[] memory _pc) external onlyAdmin {
    uint256 count_ = members.length;
    require(count_ + _newMembers.length == _pc.length, "not matched percent");

    uint256 totalSum_ = 0;
    for (uint256 i = 0; i < members.length; i++) {
      totalSum_ += _pc[i];
      percent[members[i]] = _pc[i];
    }

    for (uint256 i = 0; i < _newMembers.length; i++) {
      totalSum_+= _pc[i + count_];
      members.push(_newMembers[i]);
      percent[_newMembers[i]] = _pc[i + count_];
    }

    require(totalSum_ <= DENOMINATOR, "invalid pcs");
  }
}