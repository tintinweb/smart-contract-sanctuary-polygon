/**
 *Submitted for verification at polygonscan.com on 2023-01-12
*/

// File: contracts/ConfidentialStorage.sol


pragma solidity 0.8.17;

contract ConfidentialStorage {
    
    struct ConfidentialEntry {       
        string[2] value1;
        string[2] value2;
        string[2] value3;
        string[2] value4;
    }

    event LogStoreEntry(ConfidentialEntry confidentialEntry);

    function StoreEntry(ConfidentialEntry calldata confidentialEntry) public  {
      emit LogStoreEntry(confidentialEntry);
    }

}