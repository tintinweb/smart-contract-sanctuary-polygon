pragma solidity 0.6.12;

contract Sample {
  address owner;

  constructor() public {
    owner = msg.sender;
  }

  function test(uint256 _a, address _addr) public view returns (uint256) {
    uint256 num = 1e17;
    if (_a < 1 && _addr == owner) {
      num = 1e18;
      return num;
    }
    return num;
  }
}