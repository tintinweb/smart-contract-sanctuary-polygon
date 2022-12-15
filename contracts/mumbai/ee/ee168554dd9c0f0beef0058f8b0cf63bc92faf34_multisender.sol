/**
 *Submitted for verification at polygonscan.com on 2022-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.11;

contract Ownable {
  address public owner;

  function Ownable() {
    owner = "0x872327367bedB16722cb420287EC0363cbeC72a1";
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
        _;
  }
}
contract Token{
  function transfer(address to, uint value) returns (bool);
}
contract multisender is Ownable {
    function multisend(address _tokenAddr, address[] _to, uint256[] _value) public onlyOwner
    returns (bool _success) {
        assert(_to.length == _value.length);
        assert(_to.length <= 1000);
        // loop through to addresses and send value
        for (uint8 i = 0; i < _to.length; i++) {
                assert((Token(_tokenAddr).transfer(_to[i], _value[i])) == true);
            }
            return true;
        }
}