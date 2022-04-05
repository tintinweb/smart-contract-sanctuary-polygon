/**
 *Submitted for verification at polygonscan.com on 2022-04-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface PrevAdmin {
    function bamm() external view returns(address);
    function transferBAMMOwnership() external;
    function transferOwnership(address newOwner) external;
}

interface BAMMLikeInterface {
    function removeCollateral(address ctoken) external;
    function transferOwnership(address _newOwner) external;
}

contract DesliterAdmin {
    PrevAdmin[] public prevAdmins;
    address[] public htokensToDelist;

    constructor(PrevAdmin[] memory _prevAdmin, address[] memory _htokensToDelist) public {
        prevAdmins = _prevAdmin;
        htokensToDelist = _htokensToDelist;
    }

    // callable by anyone
    function execute() public {
        for(uint a = 0 ; a < prevAdmins.length ; a++) {
            BAMMLikeInterface bamm = BAMMLikeInterface(prevAdmins[a].bamm());
            prevAdmins[a].transferBAMMOwnership(); // this will make `this` the admin of the bamm, and it will revert if not
            for(uint h = 0 ; h < htokensToDelist.length ; h++) {
                bamm.removeCollateral(htokensToDelist[h]);
            }

            bamm.transferOwnership(address(prevAdmins[a]));
            prevAdmins[a].transferOwnership(0xf7D44D5a28d5AF27a7F9c8fc6eFe0129e554d7c4);
        }
    }

    function getPrevAdmins() public view returns(PrevAdmin[] memory) {
        return prevAdmins;
    }

    function getHTokensToDelist() public view returns(address[] memory) {
        return htokensToDelist;
    }
}