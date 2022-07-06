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

    event Created(string key, uint64 timestamp);
    event Updated(string key, uint64 timestamp);
    event Saved(string key, uint64 timestamp);
    
    function createHDBLeaseAgreement(string memory key, string memory agreement, uint64 timestamp) ownerOnly isNewAgreement(key) public {
        address addr = address(new HDBLeaseAgreement(agreement, timestamp));
        agreements[key] = addr;
        emit Created(key, timestamp);
    }

    function getAgreement(string memory key, string memory name) ownerOnly agreementExist(key) public view returns (string memory, uint64) {
        HDBLeaseAgreement agreement = HDBLeaseAgreement(agreements[key]);
        HDBLeaseAgreement.Agreement memory data = agreement.get(name);
        return (data.details, data.timestamp);
    }

    function updateAgreement(string memory key, string memory _agreement, uint64 timestamp) ownerOnly agreementExist(key) public {
        HDBLeaseAgreement agreement = HDBLeaseAgreement(agreements[key]);
        agreement.save('main', _agreement, timestamp);
        emit Updated(key, timestamp);
    }

    function saveAsDraft(string memory key, string memory _agreement, string memory name, uint64 timestamp) ownerOnly public {
        if(agreements[key] == address(0)){
            createHDBLeaseAgreement(key, _agreement, timestamp);
        } else{
        HDBLeaseAgreement agreement = HDBLeaseAgreement(agreements[key]);
        agreement.save(name, _agreement, timestamp);
        }
        emit Saved(key, timestamp);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract  HDBLeaseAgreement {
    struct Agreement {
        string details;
        uint64 timestamp;
    }

    mapping(string => Agreement) agreements;

    constructor(string memory agreement, uint64 timestamp) {
        agreements['main'] = Agreement(agreement, timestamp);
    }

    modifier agreementExist(string memory name){
        require(agreements[name].timestamp != 0 || agreements['main'].timestamp != 0);
       _; 
    }

    function get(string memory name) agreementExist(name) view public returns(Agreement memory) {
        if(agreements[name].timestamp > agreements['main'].timestamp){
            return agreements[name];
        }else{
            return agreements['main'];
        }
    }

    function save(string memory name, string memory agreement, uint64 timestamp) agreementExist(name) public {
        agreements[name] = Agreement(agreement, timestamp);
    }
}