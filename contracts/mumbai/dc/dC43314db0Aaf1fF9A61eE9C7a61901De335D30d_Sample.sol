pragma solidity 0.6.12;

contract Sample {
  address owner;
  mapping(address => uint256) public power;

  constructor() public {
    owner = msg.sender;
  }

  function setPower(address _addr, uint256 _point) public {
    power[_addr] = _point;
  }

  function test(uint256 _a, address _addr) public view returns (uint256) {
    uint256 num = 1e17;
    if (_a < 1) {
      return power[_addr];
    }
    return num;
  }
}