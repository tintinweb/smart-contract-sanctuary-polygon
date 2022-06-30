//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "contracts/HDBLeaseAgreement.sol";

contract Registry {
    mapping (string => address) private agreements;
    
    function createHDBLeaseAgreement(string memory key, string memory agreement) public {
        address addr = address(new HDBLeaseAgreement(agreement));
        agreements[key] = addr;
    }

    function getAgreement(string memory key) public view returns (string memory) {
        HDBLeaseAgreement agreement = HDBLeaseAgreement(agreements[key]);
        return agreement.getAgreement();
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract  HDBLeaseAgreement {
    string private agreement;

    constructor(string memory _agreement) {
        agreement = _agreement;
    }


    function getAgreement() public view returns (string memory) {
        return agreement;
    }
}