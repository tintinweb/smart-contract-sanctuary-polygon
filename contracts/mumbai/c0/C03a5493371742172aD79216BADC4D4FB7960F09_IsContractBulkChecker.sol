/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


/// @title IsContractBulkChecker
/// @author Dispatch.xyz
/// @dev for dispatch.xyz dev purposes
contract IsContractBulkChecker {
  /*
        AddressType Mapping:
        WALLET                   = 0
        CONTRACT                 = 1
        CONTRACT_CAN_RECEIVE_NFT = 2
    */
  enum AddressType {
    WALLET,
    CONTRACT,
    CONTRACT_CAN_RECEIVE_NFT
  }

  function isContract(address acc) internal view returns (bool) {
    return acc.code.length > 0;
  }

  function canReceiveNft(address acc) internal returns (bool) {
    address dummyAddress = 0xFB37c2FCca2F8b61429247844ADEe1BB8f9FF224;
    try IERC1155Receiver(acc).onERC1155Received(dummyAddress, dummyAddress, 1, 1, "") returns (bytes4 result) {
      // true when `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`, i.e. 0xf23a6e61
      return result == 0xf23a6e61;
    } catch {
      return false;
    }
  }

  function checkAddresses(address[] calldata addresses) external returns (AddressType[] memory addressTypes) {
    addressTypes = new AddressType[](addresses.length);
    for (uint i = 0; i < addresses.length; i++) {
      address a = addresses[i];
      if (isContract(a)) {
        addressTypes[i] = canReceiveNft(a) ? AddressType.CONTRACT_CAN_RECEIVE_NFT : AddressType.CONTRACT;
      } else {
        addressTypes[i] = AddressType.WALLET;
      }
    }
    return addressTypes;
  }
}