//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract RahozSC {
  struct Data {
    string s;
    uint[] b;
  }

  mapping(uint256 => Data) private dataAt;

  function set(Data[] calldata data) external {
    for (uint256 i = 0; i < data.length; i++) {
      dataAt[i] = data[i];
    }
  }

  function getData(uint i) public view returns(string memory _s, uint[] memory _b){
    _s = dataAt[i].s;
    _b = dataAt[i].b;
  }
}