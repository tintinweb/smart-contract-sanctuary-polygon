// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface HRTToken {
  function transfer(address recipient, uint256 amount) external returns(bool);
  function balanceOf(address account) external view returns (uint256);
}

contract Distribution {
  uint256 public constant DENOMINATOR = 10000;
  uint256 public lastDistributeDate;

  uint32 public burnPc = 2000; // 20%
  uint32 public teamPc = 2000; // 20%
  uint32 public rewardPc = 4000; // 20%
  uint32 public reservePc = 2000; // 20%

  address public burnAddr = 0x000000000000000000000000000000000000dEaD;
  address public teamAddr = 0x000000000000000000000000000000000000dEaD;
  address public rewardAddr = 0x000000000000000000000000000000000000dEaD;
  address public reserveAddr = 0x000000000000000000000000000000000000dEaD;
  address public admin;

  HRTToken public hrtToken;

  event DistributeToken(
    uint256 burnAmount,
    uint256 teamAmount,
    uint256 rewardAmount,
    uint256 reserveAmount,
    uint256 sendDate
  );

  modifier onlyAdmin {
    require(msg.sender == admin, "caller is not admin");
    _;
  }

  constructor(address _hrt) {
    require(_hrt != address(0), "can't be zero address");
    hrtToken = HRTToken(_hrt);
    admin = msg.sender;
  }

  function tokenBalance() external view returns (uint256) {
    return hrtToken.balanceOf(address(this));
  }

  function distributeToken() external onlyAdmin {
    uint256 _tokenBalance = hrtToken.balanceOf(address(this));
    require(_tokenBalance > 0, "no balance");

    uint256 _burnAmount = _tokenBalance * burnPc / DENOMINATOR;
    uint256 _teamAmount = _tokenBalance * teamPc / DENOMINATOR;
    uint256 _rewardAmount = _tokenBalance * rewardPc / DENOMINATOR;
    uint256 _reserveAmount = _tokenBalance * reservePc / DENOMINATOR;

    hrtToken.transfer(burnAddr, _burnAmount);
    hrtToken.transfer(teamAddr, _teamAmount);
    hrtToken.transfer(rewardAddr, _rewardAmount);
    hrtToken.transfer(reserveAddr, _reserveAmount);

    lastDistributeDate = block.timestamp;

    emit DistributeToken(_burnAmount, _teamAmount, _rewardAmount, _reserveAmount, block.timestamp);
  }

  function changeTokenAddr(address _newToken) external onlyAdmin {
    hrtToken = HRTToken(_newToken);
  }

  function changePc(uint32 _burnPc, uint32 _teamPc, uint32 _rewardPc, uint32 _reservePc) external onlyAdmin {
    require(_burnPc + _teamPc + _rewardPc + _reservePc == 10000, "total percent should be 10000");
    burnPc = _burnPc;
    teamPc = _teamPc;
    rewardPc = _rewardPc;
    reservePc = _reservePc;
  }

  function changeTeamPoolAddr(address _team) external onlyAdmin {
    require(_team != address(0), "zero address");
    teamAddr = _team;
  }

  function changeRewardPoolAddr(address _reward) external onlyAdmin {
    require(_reward != address(0), "zero address");
    rewardAddr = _reward;
  }

  function changeReservePoolAddr(address _reserve) external onlyAdmin {
    require(_reserve != address(0), "zero address");
    reserveAddr = _reserve;
  }

  function changeAdmin(address _newAdmin) external onlyAdmin {
    require(_newAdmin != address(0), "zero address");
    admin = _newAdmin;
  }
}