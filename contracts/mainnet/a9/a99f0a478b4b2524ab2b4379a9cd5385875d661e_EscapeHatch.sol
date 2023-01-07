/**
 *Submitted for verification at polygonscan.com on 2023-01-07
*/

//SPDX-License-Identifier: MIT License
pragma solidity ^0.8.0;

abstract contract IABToken {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

abstract contract IBattleMtnData {
    function addTeam(
        uint8 toSpot,
        uint256 angelId,
        uint256 petId,
        uint256 accessoryId
    ) public virtual;

    function getTeamByPosition(uint8 _position)
        external
        view
        virtual
        returns (
            uint8 position,
            uint256 angelId,
            uint256 petId,
            uint256 accessoryId,
            string memory slogan
        );
}

contract EscapeHatch {
    address public ABTokenDataContract =
        0x3d78b36F7746f05752d45Fb4f48dAcCaF107628e;

    // Function called to escape from the battle mountain and replace your
    // team with a null team.

    // This function can be called by the owner of either the pet, angel, or accessory

    // this contract must be granted seraphim status on the battle mountain you are trying to escape

    function escape(address _battleMtnAddress, uint8 spot) public {
        IABToken tokenContract = IABToken(ABTokenDataContract);
        IBattleMtnData battleMtnContract = IBattleMtnData(_battleMtnAddress);

        (
            ,
            uint256 angelId,
            uint256 petId,
            uint256 accessoryId
			,
        ) = battleMtnContract.getTeamByPosition(spot);

        require(
            tokenContract.ownerOf(angelId) == msg.sender ||
                tokenContract.ownerOf(petId) == msg.sender ||
                tokenContract.ownerOf(accessoryId) == msg.sender,
            'You must own at least one card in this team'
        );

		// Add the null team to the spot, knocking the existing team off. 
        battleMtnContract.addTeam(spot, 0, 1, 2);
    }
}