// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165Checker.sol";
import "./Address.sol";

/**
 * @title DelegatorForApproval
 * @author DarkCenobyte
 * @notice Use for reduce transactions amount for allowing ERC1155 with some implementations
 */
 contract DelegatorForApproval {
    using Address for address;

    bytes4 private constant _ERC1155_INTERFACE = 0xd9b67a26;

    /**
    * @notice Same as {_setApprovalForAllDelegated(address,address,bool,bool,uint256,uint256)}.
    */
    function setApprovalForAllDelegated(address targetContract, address operator, bool approved) external {
        _setApprovalForAllDelegated(targetContract, operator, approved, false, 0, 0);
    }

    /**
    * @notice Same as {_setApprovalForAllDelegated(address,address,bool,bool,uint256,uint256)}.
    */
    function setApprovalForAllDelegated(address targetContract, address operator, bool approved, bool requireMinting, uint256 tokenId, uint256 mintableAmount) external {
        _setApprovalForAllDelegated(targetContract, operator, approved, requireMinting, tokenId, mintableAmount);
    }

    /**
    * @notice Allow ERC1155 seller to perform the "setApprovalForAll" call and in the same call an eventual "supplyToBalance" action by asking the owner to mint remaining supply
    * @param targetContract The contract of the ERC1155 NFT we will delegatecall for set authorization
    * @param operator The contract operator we want to approved or disapproved in setApprovalForAll call
    * @param approved Set if we want to give (true) or remove (false) approval to the operator contract
    * @param requireMinting Set if we want to perform a mint() with the specified mintableAmount
    * @param tokenId In order to be able to perform the requireMinting action, we need the tokenId concerned
    * @param mintableAmount The amount we want to mint, this should be calculated with this rule: maxSupply(_id) - totalSupply(_id)
    * @dev The purpose of performing this mint is that on contract like the ERC1155 from OpenSea, it's required to move all the "supply" to the true balance amount before acting outside of OpenSea-ecosystem
    */
    function _setApprovalForAllDelegated(address targetContract, address operator, bool approved, bool requireMinting, uint256 tokenId, uint256 mintableAmount) private {
        if (ERC165Checker.supportsInterface(targetContract, _ERC1155_INTERFACE)) {
            if (requireMinting) {
                Address.functionDelegateCall(
                    targetContract,
                    abi.encodeWithSignature(
                        "mint(address,uint256,uint256,bytes)",
                        msg.sender,
                        tokenId,
                        mintableAmount,
                        ""
                    )
                );
            }
            Address.functionDelegateCall(
                targetContract,
                abi.encodeWithSignature(
                    "setApprovalForAll(address,bool)",
                    operator,
                    approved
                )
            );
         }
     }
 }