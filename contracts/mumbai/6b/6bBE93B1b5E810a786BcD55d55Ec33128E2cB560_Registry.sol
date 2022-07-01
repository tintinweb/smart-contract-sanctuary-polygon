//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "contracts/HDBLeaseAgreement.sol";

contract Registry {
    address private owner;
    mapping (string => address) private agreements;

    constructor() {
        owner = msg.sender;
    }

    modifier ownerOnly(){
        require(msg.sender == owner);
        _;
    }
    modifier isNewAgreement(string memory key){
        require(agreements[key] == address(0));
        _;
    }
    modifier agreementExist(string memory key){
        require(agreements[key] != address(0));
        _;
    }

    event Created(string key);
    event Updated(string key);
    event Saved(string key);
    
    function createHDBLeaseAgreement(string memory key, string memory agreement, uint timestamp) ownerOnly isNewAgreement(key) public {
        address addr = address(new HDBLeaseAgreement(agreement, timestamp));
        agreements[key] = addr;
        emit Created(key);
    }

    function getAgreement(string memory key, string memory name) ownerOnly agreementExist(key) public view returns (string memory) {
        HDBLeaseAgreement agreement = HDBLeaseAgreement(agreements[key]);
        return agreement.get(name);
    }

    function updateAgreement(string memory key, string memory _agreement, uint timestamp) ownerOnly agreementExist(key) public {
        HDBLeaseAgreement agreement = HDBLeaseAgreement(agreements[key]);
        agreement.save('main', _agreement, timestamp);
        emit Updated(key);
    }

    function saveAsDraft(string memory key, string memory _agreement, string memory name, uint timestamp) ownerOnly public {
        if(agreements[key] == address(0)){
            createHDBLeaseAgreement(key, _agreement, timestamp);
        } else{
        HDBLeaseAgreement agreement = HDBLeaseAgreement(agreements[key]);
        agreement.save(name, _agreement, timestamp);
        }
        emit Saved(key);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract  HDBLeaseAgreement {
    struct Agreement {
        string details;
        uint timestamp;
    }

    mapping(string => Agreement) agreements;

    constructor(string memory agreement, uint timestamp) {
        agreements['main'] = Agreement(agreement, timestamp);
    }

    modifier agreementExist(string memory name){
        require(agreements[name].timestamp != 0 || agreements['main'].timestamp != 0);
       _; 
    }

    function get(string memory name) agreementExist(name) view public returns(string memory) {
        if(agreements[name].timestamp > agreements['main'].timestamp){
            return agreements[name].details;
        }else{
            return agreements['main'].details;
        }
    }

    function save(string memory name, string memory agreement, uint timestamp) agreementExist(name) public {
        agreements[name] = Agreement(agreement, timestamp);
    }
}