// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./IRewardNFTV2.sol";

/**
 * @dev Contract mints custom collections and only callable by the Administrator.
 * Factory v2 uses minimal proxy (EIP1167) for deployment.
 */
contract SzeetaCustomRewardFactoryV2{
    /**
     * @dev Address of the organization.
     */
    address public org;

    /**
     * @dev Address of the administration contract.
     */
    address public administration;

    /**
     * @dev Base contract address of the custome NFT collection.
     */
    address private base;

    constructor(address admin, address org_, address base_){
        org = org_;
        base = base_;
        administration = admin;
    }

    /**
     * @dev Function mints a new custom NFT collection for event rewards.
     */
    function mintCollection(
        address eventOwner,
        string memory name, 
        string memory symbol,
        string memory uri
    ) 
        external
        returns(address)
    {
        require(msg.sender == administration, "Unauthorized Call!");
        // deploying the new NFT collection
        address contractAddress = clone(base);
        IRewardNFTV2(contractAddress).initialize(eventOwner, administration, name, symbol, uri);
        return contractAddress;
    }

    /**
     * @dev EIP1167 minimal proxy code snippet from Openzeppalin Clones.
     */
    function clone(address implementation) internal returns (address instance) {
        
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Function to change administration contract
     */
    function changeAdministration(address newAdmin) external {
      require(msg.sender == org, "Unauthorized Call!");
      administration = newAdmin;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IRewardNFTV2{
    function initialize( address eventOwner, address admin, string memory name, string memory symbol, string memory uri) external;
}