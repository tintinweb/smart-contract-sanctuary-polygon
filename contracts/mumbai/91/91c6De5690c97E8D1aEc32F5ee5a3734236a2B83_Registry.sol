//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "contracts/HDBLeaseAgreement.sol";

contract Registry {
    mapping (string => address) private agreements;
    
    function createHDBLeaseAgreement(string memory key, string memory agreement, uint timestamp) public {
        address addr = address(new HDBLeaseAgreement(agreement, timestamp));
        agreements[key] = addr;
    }

    function getAgreement(string memory key, string memory name) public view returns (string memory) {
        HDBLeaseAgreement agreement = HDBLeaseAgreement(agreements[key]);
        return agreement.get(name);
    }

    function updateAgreement(string memory key, string memory _agreement, uint timestamp) public {
        HDBLeaseAgreement agreement = HDBLeaseAgreement(agreements[key]);
        agreement.save('main', _agreement, timestamp);
    }

    function saveAsDraft(string memory key, string memory _agreement, string memory name, uint timestamp) public {
        HDBLeaseAgreement agreement = HDBLeaseAgreement(agreements[key]);
        agreement.save(name, _agreement, timestamp);
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

    modifier agreementExist(){
        require(agreements['main'].timestamp != 0);
       _; 
    }

    function get(string memory name) agreementExist view public returns(string memory) {
        if(agreements[name].timestamp > agreements['main'].timestamp){
            return agreements[name].details;
        }else{
            return agreements['main'].details;
        }
    }

    function save(string memory name, string memory agreement, uint timestamp) public {
        agreements[name] = Agreement(agreement, timestamp);
    }
}