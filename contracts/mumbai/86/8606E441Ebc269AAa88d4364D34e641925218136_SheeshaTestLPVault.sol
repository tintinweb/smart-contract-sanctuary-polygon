//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/ISheeshaRetroLPVault.sol";

contract SheeshaTestLPVault is ISheeshaRetroLPVault {
    address public override sheesha;

    constructor(address sheesha_) {
        sheesha = sheesha_;
    }

    function userInfo(
        uint256 /*id*/,
        address user
    ) external pure override returns (uint256, uint256, uint256, bool) {
        return (user != 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199) ?
            (1, 1, 1, true) : (0, 0, 0, false);
    }

    function userList(uint256) external pure override returns (address) {
        return 0xbDA5747bFD65F08deb54cb465eB87D40e51B197E;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISheeshaRetroLPVault {
    function sheesha() external view returns (address);
    function userInfo(uint256 id, address user) external view returns (uint256, uint256, uint256, bool);
    function userList(uint256) external view returns (address);
}