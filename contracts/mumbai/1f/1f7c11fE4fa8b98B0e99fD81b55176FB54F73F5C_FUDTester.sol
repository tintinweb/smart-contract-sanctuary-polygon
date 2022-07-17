/**
 *Submitted for verification at polygonscan.com on 2022-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract FUDTester   {

    uint256 public Power = 13;
    uint256[] public SavedPower;

    constructor() 
    {  
          
    }    

    function TestFunction( uint256 num ) public payable returns ( uint256 ) 
    {
        uint256 _num = num += Power;

        SavedPower.push( _num );

        return _num;
    }

    function SavedPowerCount() public view returns ( uint256 ) 
    {
        return SavedPower.length;
    }

    function ReadValueAtIndex( uint256 index ) public view returns ( uint256 ) 
    {
        return SavedPower[ index ];
    }
}