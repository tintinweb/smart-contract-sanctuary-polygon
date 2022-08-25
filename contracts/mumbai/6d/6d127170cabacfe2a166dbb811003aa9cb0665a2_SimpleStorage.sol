/**
 *Submitted for verification at polygonscan.com on 2022-08-24
*/

pragma solidity >=0.4.0 <0.8.0;
contract SimpleStorage {
   uint storedData;
   function set(uint input_data) public {
      storedData = input_data;
   }
   function get() public view returns (uint) {
      return storedData;
   }
}