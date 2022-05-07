/**
 *Submitted for verification at polygonscan.com on 2022-05-06
*/

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    mapping(address => string) dataStore;

    function getData() public view returns(string memory) {
        return dataStore[msg.sender];
    }
    function setData( string memory rawString ) public  {
        dataStore[msg.sender] = rawString;
    }

}