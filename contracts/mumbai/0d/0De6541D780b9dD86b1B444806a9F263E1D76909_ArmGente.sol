/**
 *Submitted for verification at polygonscan.com on 2022-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

struct Gente {
  string nomalias;
}

contract ArmGente {
  address public owner = msg.sender;

  mapping (address => Gente) public genteAddr;
  mapping (string => Gente) public genteAlias;

  event Log(address indexed sender, string indexed message);
    constructor() {
        owner = msg.sender;
    }

  function assign(string memory _nomalias ) public {
    Gente memory oGente = Gente(_nomalias);  
    genteAddr[msg.sender] = oGente;
    genteAlias[_nomalias] = oGente;

    emit Log(msg.sender, _nomalias);
  }

  function FindByAddr(address _addr) public view returns(string memory) {
    return genteAddr[_addr].nomalias;
  }

  function FindByAlias(string memory _nomalias ) public view returns(string memory) {
    return genteAlias[_nomalias].nomalias;
  }


}