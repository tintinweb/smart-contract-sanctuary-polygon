/**
 *Submitted for verification at polygonscan.com on 2022-04-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IGolfclub {
    function issue(address to, uint16 golfclubId) external returns(uint256);
    function balanceOf(address owner) external returns(uint);
    function getGolfclubSupply(uint16 golfclubId) external returns(uint);
    function getMaxSupply(uint16 golfclubId) external returns(uint);
}

contract GolfclubBulk {
    IGolfclub public golfclub;
    address public admin;

    constructor(){
        admin = address(msg.sender);
    }

    function setAdmin(address newAdmin) public {
        require(msg.sender == admin, "protected");
        admin = newAdmin;
    }

    function setContract(IGolfclub _contract) public {
        require(msg.sender == admin, "protected");
        golfclub = _contract;
    }

    function bulkIssue(address to, uint16 golfClubId, uint8 amount) public {
        require(msg.sender == admin, "protected");
        require(golfclub.getMaxSupply(golfClubId) > golfclub.getGolfclubSupply(golfClubId), "not enough");
        for(uint c = 0; c < amount; c++){
            golfclub.issue(to, golfClubId);
        }
    }
}