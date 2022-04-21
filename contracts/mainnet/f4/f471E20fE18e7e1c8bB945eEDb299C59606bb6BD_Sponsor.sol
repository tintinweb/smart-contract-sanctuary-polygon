// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.11;

/**
 @title Simple Sponsorship contract that uses Living Asset properties as part of the logic
 @author Freeverse.io, www.freeverse.io
*/

import "./ICertifier.sol";

contract Sponsor {
    address public certifier;
    string public trait;
    address[] sponsors;
    mapping (address => uint256) public sponsorAmount;

    constructor(address certifierAddress) {
        certifier = certifierAddress;
    }

    function setTrait(string calldata newName) public {
        trait = newName;
    }

    function pot() public view returns(uint256) {
        return address(this).balance;
    }

    function addFunds() external payable {
        if (sponsorAmount[msg.sender] == 0) {
            sponsors.push(msg.sender);
            sponsorAmount[msg.sender] = msg.value;
        } else {
            sponsorAmount[msg.sender] += msg.value;
        }
    }

    function withdraw(
        uint256 assetId,
        uint256 traitVal,
        bytes memory proof
    ) external payable {
        uint256 amountToWithdraw = pot();
        require(
            ICertifier(certifier).isCurrentAssetPropsByTraitInt(assetId, trait, traitVal, proof)
        );
        payable(msg.sender).transfer(amountToWithdraw);
    }

    /**
    @dev Returns true only if the provided assetId has the provided props.
    @notice The trait value must be an integer
    */
    function isCurrentAssetPropsByTraitInt(
        uint256 assetId,
        string memory traitName,
        uint256 traitVal,
        bytes memory proof
    ) public view returns (bool) {
        return ICertifier(certifier).isCurrentAssetPropsByTraitInt(assetId, traitName, traitVal, proof);
    }

    /**
    @dev Returns true only if the provided assetId has the provided props.
    @notice The trait value must be a string
    */
    function isCurrentAssetPropsByTraitStr(
        uint256 assetId,
        string memory traitName,
        string memory traitVal,
        bytes memory proof
    ) public view returns (bool) {
        return ICertifier(certifier).isCurrentAssetPropsByTraitStr(assetId, traitName, traitVal, proof);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Interface to the Certify contract
 @author Freeverse.io, www.freeverse.io
*/

interface ICertifier {
    /**
    @dev Returns true only if the provided assetId has the provided props.
    @notice The trait value must be a string
    */
    function isCurrentAssetPropsByTraitStr(
        uint256 assetId,
        string memory traitName,
        string memory traitVal,
        bytes memory proof
    ) external view returns (bool);

    /**
    @dev Returns true only if the provided assetId has the provided props.
    @notice The trait value must be an integer
    */
    function isCurrentAssetPropsByTraitInt(
        uint256 assetId,
        string memory traitName,
        uint256 traitVal,
        bytes memory proof
    ) external view returns (bool);
}