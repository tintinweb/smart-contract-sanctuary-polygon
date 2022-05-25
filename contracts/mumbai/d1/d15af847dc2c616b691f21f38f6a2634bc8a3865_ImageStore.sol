/**
 *Submitted for verification at polygonscan.com on 2022-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// import "@openzeppelin/contracts/access/Ownable.sol";

contract ImageStore {
//  uint8[][] public images;
 mapping(uint256 => bytes) public images;
    bytes[] public imagesList;

 function storeImage(uint256 _hash, bytes calldata _data) external {
    images[_hash] = _data;
 }
  function storeImage2(bytes calldata _data) external {
    imagesList.push(_data);
 }

 function getImage(uint256 _hash)external view{
        
    }
}