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

    event Updated(string key, uint64 timestamp);
    
    function createHDBLeaseAgreement(string memory key, string memory agreement, uint64 timestamp) ownerOnly isNewAgreement(key) public {
        address addr = address(new HDBLeaseAgreement(agreement, timestamp));
        agreements[key] = addr;
        emit Updated(key, timestamp);
    }

    function getAgreement(string memory key, string memory role) ownerOnly agreementExist(key) public view returns (string memory, uint64) {
        HDBLeaseAgreement agreement = HDBLeaseAgreement(agreements[key]);
        (string memory value, uint64 timestamp) = agreement.get(role);
        return (value, timestamp);
    }

    function updateAgreement(string memory key, string memory _agreement, uint64 timestamp) ownerOnly agreementExist(key) public {
        HDBLeaseAgreement agreement = HDBLeaseAgreement(agreements[key]);
        agreement.save('main', _agreement, timestamp);
        emit Updated(key, timestamp);
    }

    function saveAsDraft(string memory key, string memory _agreement, string memory role, uint64 timestamp) ownerOnly public {
        if(agreements[key] == address(0)){
            createHDBLeaseAgreement(key, _agreement, timestamp);
        } else{
        HDBLeaseAgreement agreement = HDBLeaseAgreement(agreements[key]);
        agreement.save(role, _agreement, timestamp);
        }
        emit Updated(key, timestamp);
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

    modifier agreementExist(string memory role){
        require(agreements[role].timestamp != 0 || agreements['main'].timestamp != 0);
       _; 
    }

    function get(string memory role) agreementExist(role) view public returns(string memory, uint64) {
        if(agreements[role].timestamp > agreements['main'].timestamp){
            return (agreements[role].details, agreements[role].timestamp);
        }else{
            return (agreements['main'].details, agreements['main'].timestamp);
        }
    }

    function save(string memory role, string memory agreement, uint64 timestamp) agreementExist(role) public {
        agreements[role] = Agreement(agreement, timestamp);
    }
}