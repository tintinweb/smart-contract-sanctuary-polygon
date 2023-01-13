/**
 *Submitted for verification at polygonscan.com on 2023-01-12
*/

// File: contracts/ConfidentialStorage.sol


pragma solidity 0.8.17;

contract ConfidentialStorage {
    
    struct ConfidentialEntry {
        string key1;      
        string value1;
        string key2;
        string value2;
        string key3;
        string value3;
        string key4;
        string value4;
    }

    event LogStoreEntry(ConfidentialEntry confidentialEntry);

    function StoreEntry(ConfidentialEntry calldata confidentialEntry) public  {
      emit LogStoreEntry(confidentialEntry);
    }

}