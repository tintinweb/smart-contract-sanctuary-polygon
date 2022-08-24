//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "contracts/Agreements.sol";

contract Registry {
    address private immutable owner;
    address private secondaryOwner;
    mapping (string => address) private collection;

    constructor() {
        owner = msg.sender;
    }

    modifier ownerOnly(){
        require(msg.sender == owner || msg.sender == secondaryOwner);
        _;
    }

        modifier secondaryDontExist(){
        require(secondaryOwner == address(0));
        _;
    }

    modifier agreementExist(string memory key){
        require(collection[key] != address(0));
        _;
    }

    modifier agreementDontExist(string memory key){
        require(collection[key] == address(0));
        _;
    }

    modifier agreementIsNotEmpty(string memory agreement){
        bytes memory _agreement = bytes(agreement);
        require(_agreement.length != 0);
        _;
    }

    event Updated(string key);

    function setSecondaryOwner(string memory _secondaryOwner) ownerOnly secondaryDontExist external {
         secondaryOwner = address(uint160(uint256(keccak256(bytes(_secondaryOwner)))));
    }

    function getAgreement(string memory key) ownerOnly agreementExist(key) external view returns (string memory) {
        Agreement agreement = Agreement(collection[key]);
        return agreement.get();
    }

    function addAgreement(string memory key, string memory agreement) ownerOnly agreementIsNotEmpty(agreement) agreementDontExist(key) external {
        address addr = address(new Agreement(agreement));
        collection[key] = addr;
        emit Updated(key);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

contract Agreement {
     string private agreement;

    constructor(string memory _agreement) {
     agreement = _agreement;
    }

    modifier agreementExist(){
        bytes memory _agreement = bytes(agreement);
        require(_agreement.length != 0);
        _;
    }

    function get() agreementExist view external returns(string memory) {
      return agreement;
    }
}