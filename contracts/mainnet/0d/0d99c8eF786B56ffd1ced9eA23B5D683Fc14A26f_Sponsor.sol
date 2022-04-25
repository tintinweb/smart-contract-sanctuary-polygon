// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.11;

/**
 @title Simple Sponsorship contract that uses Living Asset properties as part of the logic
 @dev This is just a toy example. Do not use in production.
 @author Freeverse.io, www.freeverse.io
*/

import "./ICertifier.sol";

contract Sponsor {
    address public certifier;
    string public traitName;
    uint256 public traitMinValue;
    uint256 public universeId;
    address[] private _sponsors;
    mapping(address => uint256) public sponsorAmount;

    constructor(
        address _certifier,
        uint256 _universeId,
        string memory _traitName,
        uint256 _traitMinValue
    ) {
        certifier = _certifier;
        configure(_universeId, _traitName, _traitMinValue);
    }

    function configure(
        uint256 _universeId,
        string memory _traitName,
        uint256 _traitMinValue
    ) public {
        universeId = _universeId;
        traitName = _traitName;
        traitMinValue = _traitMinValue;
    }

    function addFunds() external payable {
        if (sponsorAmount[msg.sender] == 0) {
            _sponsors.push(msg.sender);
            sponsorAmount[msg.sender] = msg.value;
        } else {
            sponsorAmount[msg.sender] += msg.value;
        }
    }

    function claimPot(
        uint256 assetId,
        uint256 traitVal,
        bytes memory proof
    ) external {
        require(
            decodeUniverseIdx(assetId) == universeId,
            "asset does not belong to correct universe"
        );
        require(
            traitVal >= traitMinValue,
            "trait value not large enough to claim pot"
        );
        uint256 amountToWithdraw = pot();
        require(
            ICertifier(certifier).isCurrentAssetPropsByTraitInt(
                assetId,
                traitName,
                traitVal,
                proof
            ),
            "asset does not have the correct properties"
        );
        payable(msg.sender).transfer(amountToWithdraw);
    }

    // View functions

    function pot() public view returns (uint256) {
        return address(this).balance;
    }

    function sponsors() public view returns (address[] memory) {
        return _sponsors;
    }

    /**
     @dev Returns true only if the provided assetId has the provided props.
     @notice The trait value must be an integer
    */
    function isCurrentAssetPropsByTraitInt(
        uint256 assetId,
        string memory trait,
        uint256 traitVal,
        bytes memory proof
    ) public view returns (bool) {
        return
            ICertifier(certifier).isCurrentAssetPropsByTraitInt(
                assetId,
                trait,
                traitVal,
                proof
            );
    }

    /**
     @dev Returns true only if the provided assetId has the provided props.
     @notice The trait value must be a string
    */
    function isCurrentAssetPropsByTraitStr(
        uint256 assetId,
        string memory trait,
        string memory traitVal,
        bytes memory proof
    ) public view returns (bool) {
        return
            ICertifier(certifier).isCurrentAssetPropsByTraitStr(
                assetId,
                trait,
                traitVal,
                proof
            );
    }

    // Pure functions

    function decodeUniverseIdx(uint256 assetId)
        private
        pure
        returns (uint256 assetIdx)
    {
        return (assetId >> 224);
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