//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "contracts/Agreements.sol";

contract Registry {
    address private owner;
    mapping (string => address) private collection;

    constructor() {
        owner = msg.sender;
    }

    modifier ownerOnly(){
        require(msg.sender == owner);
        _;
    }

    modifier agreementExist(string memory key){
        require(collection[key] != address(0));
        _;
    }

    event Updated(string key, uint64 timestamp);
    
    function createAgreement(string memory key, string memory agreement, uint64 timestamp) ownerOnly private {
        address addr = address(new Agreements(agreement, timestamp));
        collection[key] = addr;
        emit Updated(key, timestamp);
    }

    function getAgreement(string memory key, string memory role) ownerOnly agreementExist(key) public view returns (string memory, uint64) {
        Agreements agreements = Agreements(collection[key]);
        string memory value;
        uint64 timestamp; 
        (value, timestamp) = agreements.get(role);
        return (value, timestamp);
    }

    function updateAgreement(string memory key, string memory _agreement, uint64 timestamp) ownerOnly public {
        if(collection[key] == address(0)){
            createAgreement(key, _agreement, timestamp);
        } else{
        Agreements agreements = Agreements(collection[key]);
        agreements.save('main', _agreement, timestamp);
        }
        emit Updated(key, timestamp);
    }

    function saveAsDraft(string memory key, string memory _agreement, string memory role, uint64 timestamp) ownerOnly public {
        if(collection[key] == address(0)){
            createAgreement(key, _agreement, timestamp);
        } else{
        Agreements agreement = Agreements(collection[key]);
        agreement.save(role, _agreement, timestamp);
        }
        emit Updated(key, timestamp);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

contract Agreements {
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