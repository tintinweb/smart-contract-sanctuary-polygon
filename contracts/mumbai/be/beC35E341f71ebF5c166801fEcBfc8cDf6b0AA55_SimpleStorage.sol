// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;  // here we have told which version we want. If we wrote ^0.8.7 that means that any version above 0.8.7 is ok
                       // or we can give a range of version >=0.8.7 <0.9.0 
// contract SimpleStorage {
//     // types of data types
//     bool hasfavoriteNum = true;
//     uint256 FavNum = 5;             // only positive int
//     string Favstring = "this";
//     int256 favint = -5;             // both pos and neg
//     address myadd = ;    // address of metamask
//     bytes32 favbyte = "cat";

// }

contract SimpleStorage{
    // THIS GET INITIALIZED TO ZERO
   uint256 favNum;
    
   mapping(string => uint256) public nameToFavNum;

   struct People{
       uint256 favNum;
       string name;
   }

    People[] public people;

   function store(uint256 _favNum) public virtual {
       favNum = _favNum;
   }

   function retrieve() public view returns(uint256){
       return favNum;
   }
   function addPerson(string memory _name,uint256 _favNum) public {
       people.push(People(_favNum,_name));
       nameToFavNum[_name] = _favNum;
   }
}