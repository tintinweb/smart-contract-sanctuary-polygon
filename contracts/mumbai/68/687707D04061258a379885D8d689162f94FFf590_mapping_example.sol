/**
 *Submitted for verification at polygonscan.com on 2023-02-03
*/

pragma solidity ^0.6.0; 
   
// Defining contract 
contract mapping_example {
      
      bytes32 public hash;
      string public cid;
      
      mapping(string => string) public hash_to_cid;
     // mapping(string => string) cid_to_hash; 

      address owner ;
      
    constructor () public {

        owner = msg.sender ; 
    }
    modifier onlyOwner() {
        require(owner==msg.sender) ;
        _;
    }

  function get_cid(string memory hash_sha) public view returns (string memory) {
    
    return hash_to_cid[hash_sha];
   }
   
  /*function get_hash(string memory cid_ipfs) public view returns (string memory) {

    return cid_to_hash[cid_ipfs];
   }*/

   function set(string memory hash_sha, string memory cid_ipfs) public {
   	// Update the value at this address
    hash_to_cid[hash_sha] = cid_ipfs;
   }
}