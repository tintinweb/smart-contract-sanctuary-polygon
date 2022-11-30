/**
 *Submitted for verification at polygonscan.com on 2022-11-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.0;
contract _Bb{
string tokenName="BoringToken";
address _adr=0xc1125efD386E37e9F01D230c1b63d54444425D3F;
bool public callSuccess;
function setTokenName(string calldata _newName) external {
    require(msg.sender==0x7381195e7388ed823Cd5A19a8c58d3C58e6d7496,"NOT WHITELISTED");
    tokenName=_newName;
     _adr=msg.sender;
}
}