//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "contracts/Agreements.sol";

contract Registry {
    address private immutable owner;
    address private immutable secondaryOwner;
    mapping (string => address) private collection;

    constructor(bytes memory _secondaryOwner) {
        owner = msg.sender;
        secondaryOwner = bytesToAddress(_secondaryOwner);
    }

    modifier ownerOnly(){
        require(msg.sender == owner || msg.sender == secondaryOwner, "Unauthorized");
        _;
    }

    modifier agreementExist(string memory key){
        require(collection[key] != address(0), "Key Don't Exist");
        _;
    }

    modifier agreementDontExist(string memory key){
        require(collection[key] == address(0), "Existing Key");
        _;
    }

    modifier valueIsNotEmpty(bytes memory value){
        require(value.length != 0, "Invalid Value");
        _;
    }

    event Updated(string key);

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        } 
    }

    function getContract(string memory key) ownerOnly agreementExist(key) external view returns (bytes memory) {
        Agreement agreement = Agreement(collection[key]);
        return agreement.get();
    }

    function addAgreement(string memory key, bytes memory agreement) ownerOnly valueIsNotEmpty(agreement) agreementDontExist(key) external {
        address addr = address(new Agreement(agreement));
        collection[key] = addr;
        emit Updated(key);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

contract Agreement {
  address private immutable owner;
  bytes private agreement;
     

  constructor(bytes memory _agreement) {
    owner = msg.sender;
    agreement = _agreement;
  }

  modifier ownerOnly(){
    require(msg.sender == owner, "Unauthorized");
        _;
  }

  modifier validAgreement(){
    require(agreement.length != 0, "Invalid Agreement");
    _;
  }

  function get() ownerOnly validAgreement external view returns (bytes memory) {
    return agreement;
  }
}