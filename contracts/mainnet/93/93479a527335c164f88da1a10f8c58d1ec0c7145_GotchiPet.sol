// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface AavegotchiGameFacet {
    function interact(uint256[] calldata _tokenIds) external;
}

contract GotchiPet {
    AavegotchiGameFacet private agf;
    uint256 public lastExecuted;
    address private gotchiOwner;
    uint256[] private gotchiIds;

    constructor(address gotchiDiamond, address _gotchiOwner) {
        agf = AavegotchiGameFacet(gotchiDiamond);
        gotchiOwner = _gotchiOwner;
    }

    function petGotchis() public {
        require(((block.timestamp - lastExecuted) > 43200), "12 hours not elapsed");
        require(gotchiIds.length > 0, "No Gotchis to pet");
        require(msg.sender == gotchiOwner, "Only owner can pet Gotchis");

        agf.interact(gotchiIds);

        lastExecuted = block.timestamp;
    }

    function setGotchiIds(uint256[] calldata _gotchiIds) public {
        require(msg.sender == gotchiOwner, "Only owner can set Gotchi IDs");
        gotchiIds = _gotchiIds;
    }
}