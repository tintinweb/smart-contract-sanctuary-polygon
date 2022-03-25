//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/ISheeshaRetroSHVault.sol";

contract SheeshaTestSHVault is ISheeshaRetroSHVault {
    address public override sheesha;

    constructor(address sheesha_) {
        sheesha = sheesha_;
    }

    function userInfo(
        uint256 /*id*/,
        address user
    ) external pure override returns (uint256, uint256) {
        return (user != 0xdD2FD4581271e230360230F9337D5c0430Bf44C0) ?
            (1, 1) : (0, 0);
    }

    function userList(uint256) external pure override returns (address) {
        return 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISheeshaRetroSHVault {
    function sheesha() external view returns (address);
    function userInfo(uint256 id, address user) external view returns (uint256, uint256);
    function userList(uint256) external view returns (address);
}