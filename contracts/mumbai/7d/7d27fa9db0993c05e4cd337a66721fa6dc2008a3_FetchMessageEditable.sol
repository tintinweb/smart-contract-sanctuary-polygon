// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IFetch.sol";

import "../IMessageEditable.sol";

contract FetchMessageEditable is IFetch {
  bytes4 public constant interfaceId = type(IMessageEditable).interfaceId;
  uint256 public constant propertyCount = 2;

  function properties(address item) external view returns(Property[] memory out) {
    out = new Property[](propertyCount);
    IMessageEditable instance = IMessageEditable(item);

    out[0].key = "lastEdited";
    out[0].valueType = "uint256";
    out[0].value = abi.encodePacked(instance.lastEdited());
    out[1].key = "owner";
    out[1].valueType = "address";
    out[1].value = abi.encodePacked(instance.owner());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IFetch {
  struct Property {
    string key;
    bytes value;
    string valueType;
  }
  function interfaceId() external pure returns(bytes4);
  function propertyCount() external pure returns(uint256);
  function properties(address item) external view returns(Property[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IMessage.sol";
import "./IOwnable.sol";

interface IMessageEditable is IMessage, IOwnable {
  event MessageChanged(string oldValue, string newValue);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function lastEdited() external view returns(uint256);
  function editMessage(string memory newValue) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IMessage is IERC165 {
  function message() external view returns(string memory);
  function created() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IOwnable {
  function owner() external view returns(address);
  function transferOwnership(address newOwner) external;
  function renounceOwnership() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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