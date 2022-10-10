/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.6.0;

contract Testtok{
    mapping (address => bool) public mintkeys;
    mapping (address => uint) public mintkeypriority;
    mapping (address => uint256) public balanceOf;
    uint public priviousmintkeysignvalue;
    string public priviousmintkeyhashnvalue;
    string public name = "testcoin31415926";
    string public symbol = "tst31415926";
    uint256 public decimals = 18;
    uint256 public totalsupply = 10000000000000000000;
    event Transfer(address indexed from, address indexed to, uint256 value);
    constructor() public{
        mintkeys[0x00008A25a62B6eB40f357Af911B3E4E5e09d0000] = true;
        mintkeys[0x359ba23236f7127306484C49ba6D8BFc04aB1115] = true;
        mintkeys[0x402b47179C082FC9db24003E97111Cade1535604] = true;
        mintkeys[0xf3A0FA10Cec70111B1402Eb99231B65b3681a65D] = true;
        mintkeys[0x106bf78110757022130B5a6e88786eb05CeA6e90] = true;
        mintkeys[0xAD394d3971CF3fED6C6DC239896529fFF18017A1] = true;
        mintkeys[0x35f372F689E79a07CE7F4a022A5f2703F40fC2C1] = true;
        mintkeys[0xC652F9fF137ff38285498f92a4E908fAD12089e2] = true;
        mintkeys[0xc88f7FA7b3c16dFCD881915d57B841C9F0E92175] = true;
        mintkeypriority[0x00008A25a62B6eB40f357Af911B3E4E5e09d0000] = 0;
        mintkeypriority[0x359ba23236f7127306484C49ba6D8BFc04aB1115] = 1;
        mintkeypriority[0x402b47179C082FC9db24003E97111Cade1535604] = 2;
        mintkeypriority[0xf3A0FA10Cec70111B1402Eb99231B65b3681a65D] = 3;
        mintkeypriority[0x106bf78110757022130B5a6e88786eb05CeA6e90] = 4;
        mintkeypriority[0xAD394d3971CF3fED6C6DC239896529fFF18017A1] = 5;
        mintkeypriority[0x35f372F689E79a07CE7F4a022A5f2703F40fC2C1] = 6;
        mintkeypriority[0xC652F9fF137ff38285498f92a4E908fAD12089e2] = 7;
        mintkeypriority[0xc88f7FA7b3c16dFCD881915d57B841C9F0E92175] = 8;
        priviousmintkeysignvalue = 10;
        balanceOf[msg.sender] = totalsupply;
    }
    function transfer(address _to, uint256 _value) external returns(bool success){
        require(balanceOf[msg.sender]>= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender]-(_value);
        balanceOf[_to] = balanceOf[_to]+(_value);
        emit Transfer(msg.sender,_to,_value);
        return true;
    }

    function minter(address walle) public view returns (bool){
        return mintkeys[walle];
    }
    function mintint(address mind) public view returns (uint){
        return mintkeypriority[mind];
    }
    function mint(uint totalamt) public {
        require (minter(msg.sender)==true);
        if (mintkeypriority[msg.sender] == 0 && priviousmintkeysignvalue == 10){
            priviousmintkeysignvalue = 0;
        }
        else{
            if(mintkeypriority[msg.sender]!= priviousmintkeysignvalue && (mintkeypriority[msg.sender]-1)==priviousmintkeysignvalue){
                if (mintkeypriority[msg.sender] == 8 && priviousmintkeysignvalue == 7){
                    balanceOf[0x00008A25a62B6eB40f357Af911B3E4E5e09d0000] = totalamt/9;
                    balanceOf[0x359ba23236f7127306484C49ba6D8BFc04aB1115] = totalamt/9;
                    balanceOf[0x402b47179C082FC9db24003E97111Cade1535604] = totalamt/9;
                    balanceOf[0xf3A0FA10Cec70111B1402Eb99231B65b3681a65D] = totalamt/9;
                    balanceOf[0x106bf78110757022130B5a6e88786eb05CeA6e90] = totalamt/9;
                    balanceOf[0xAD394d3971CF3fED6C6DC239896529fFF18017A1] = totalamt/9;
                    balanceOf[0x35f372F689E79a07CE7F4a022A5f2703F40fC2C1] = totalamt/9;
                    balanceOf[0xC652F9fF137ff38285498f92a4E908fAD12089e2] = totalamt/9;
                    balanceOf[0xc88f7FA7b3c16dFCD881915d57B841C9F0E92175] = totalamt/9;
                }
                else{
                    priviousmintkeysignvalue= priviousmintkeysignvalue+1;
                }
            }
            else if(priviousmintkeysignvalue==8 && mintkeypriority[msg.sender]==0){
                priviousmintkeysignvalue = 0;
            }
            else{
                priviousmintkeysignvalue = priviousmintkeysignvalue;
            }
        }
    }
}