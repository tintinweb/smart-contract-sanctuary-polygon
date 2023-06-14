// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

contract CustomRoyaltyContract {
    address private AdminAddress;

    constructor(
        address _adminAddress
    )
    {
        AdminAddress = _adminAddress;
    }

    function setAdminAddress(address _adminAddress) external {
        require(msg.sender == AdminAddress, "Only Owner can update Admin!");
        AdminAddress = _adminAddress;
    }

    function getAdminAddress() public view returns (address) {
        return AdminAddress;
    }

    // function _canSetRoyaltyInfo()
    //     internal
    //     view
    //     virtual
    //     override
    //     returns (bool)
    // {
    //     return msg.sender == SONC_WALLET_ROLE;
    // }
}