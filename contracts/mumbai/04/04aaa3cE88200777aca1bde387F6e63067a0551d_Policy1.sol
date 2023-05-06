// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUserAM {
   
    // Data stored for each user
    struct data {
        string role;
        string department;
        string[] projects;
    }

    function addUser(address _user, string memory _role, string memory _department, string[] memory _projects) external;

    function removeUser(address _user) external;

    function getData(address _user) external view returns (data memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUserAM.sol";
contract Policy1 {
    IUserAM public AM1;

    uint256 nonce = 30;
    constructor(address AM1address) {
        AM1 = IUserAM(AM1address);
    }

    function evaluate(address userAddress) public view returns (bool) {
        IUserAM.data memory userData = AM1.getData(userAddress);

        if(keccak256(abi.encodePacked(userData.role)) == keccak256(abi.encodePacked('Admin'))) {
            return true;
        } 

        return false;
    }
}