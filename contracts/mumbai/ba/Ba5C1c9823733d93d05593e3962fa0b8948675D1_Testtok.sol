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
        mintkeys[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = true;
        mintkeys[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = true;
        mintkeys[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB] = true;
        mintkeys[0x617F2E2fD72FD9D5503197092aC168c91465E7f2] = true;
        mintkeys[0x17F6AD8Ef982297579C203069C1DbfFE4348c372] = true;
        mintkeys[0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678] = true;
        mintkeys[0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7] = true;
        mintkeys[0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C] = true;
        mintkeys[0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC] = true;
        mintkeypriority[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 0;
        mintkeypriority[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = 1;
        mintkeypriority[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB] = 2;
        mintkeypriority[0x617F2E2fD72FD9D5503197092aC168c91465E7f2] = 3;
        mintkeypriority[0x17F6AD8Ef982297579C203069C1DbfFE4348c372] = 4;
        mintkeypriority[0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678] = 5;
        mintkeypriority[0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7] = 6;
        mintkeypriority[0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C] = 7;
        mintkeypriority[0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC] = 8;
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
                    balanceOf[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = totalamt/9;
                    balanceOf[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = totalamt/9;
                    balanceOf[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB] = totalamt/9;
                    balanceOf[0x617F2E2fD72FD9D5503197092aC168c91465E7f2] = totalamt/9;
                    balanceOf[0x17F6AD8Ef982297579C203069C1DbfFE4348c372] = totalamt/9;
                    balanceOf[0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678] = totalamt/9;
                    balanceOf[0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7] = totalamt/9;
                    balanceOf[0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C] = totalamt/9;
                    balanceOf[0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC] = totalamt/9;
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