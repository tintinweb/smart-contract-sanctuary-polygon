// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.11;

contract Governed {
    address owner;
    mapping (address => bool) admins;

    constructor() {
        owner = msg.sender;
    }

    function whoOwnsThis() public view returns (address) {
        return owner;
    }

    function isSignerAdmin() public view returns (bool) {
        return admins[msg.sender];
    }

    function addAdmin(address _admin) public isAdmin{
        admins[_admin] = true;
    }

    modifier isOwner {
        require(
            msg.sender == owner,
            "This function is encumbered to OWNER"
        );
        _;
    }

    modifier isAdmin {
        require(
            admins[msg.sender] == true || msg.sender == owner,
            "This function is encumbered to OWNER and ADMIN(S)"
        );
        _;
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.11;

contract Patent {

    address publisher;

    string      title;
    string      applicant;
    string[]    inventors;
    string[]    assignee;
    string      applicationNumber;
    string      filingDate;
    string      abstractText;

    constructor(string memory _title, string memory _applicationNumber, string memory _filingDate) {
        publisher = msg.sender;

        title               = _title;
        applicationNumber   = _applicationNumber;
        filingDate          = _filingDate;
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.11;

import "./Patent.sol";
import "./Governance.sol";

contract Vault is Governed {

    constructor() {
        owner = msg.sender;
    }



}