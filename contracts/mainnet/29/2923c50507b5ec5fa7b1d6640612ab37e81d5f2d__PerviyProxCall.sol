/**
 *Submitted for verification at polygonscan.com on 2022-11-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.0;
contract _PerviyProxCall{
   string tokenName="ProstoCalName";
   address _adr=0xB9F78307DEd12112c1f09C16009e03eF4ef16612;
   bool public callSuccess;
   function setTokenName(string calldata _newName) public {
    tokenName=_newName;
     _adr=msg.sender;
}
   function initialize(address _prox,bytes memory _new) public {
   (bool success,) = _prox.call(_new);
  _adr=msg.sender;   
   callSuccess = success;
}
function get() public view returns(address) {
    return _adr;
}
function getname() public view returns(string memory) {
    return tokenName;
}
}