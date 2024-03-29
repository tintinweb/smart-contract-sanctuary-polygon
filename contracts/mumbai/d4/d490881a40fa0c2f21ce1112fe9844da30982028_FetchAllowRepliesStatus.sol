// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IFetch.sol";

import "../IAllowRepliesStatus.sol";

contract FetchAllowRepliesStatus is IFetch {
  bytes4 public constant interfaceId = type(IAllowRepliesStatus).interfaceId;
  uint256 public constant propertyCount = 2;

  function properties(address item) external view returns(Property[] memory out) {
    out = new Property[](propertyCount);
    IAllowRepliesStatus instance = IAllowRepliesStatus(item);

    out[0].key = "replyCountLTZero";
    out[0].valueType = "uint256";
    out[0].value = abi.encodePacked(instance.replyCountLTZero());
    out[1].key = "replyCountGTEZero";
    out[1].valueType = "uint256";
    out[1].value = abi.encodePacked(instance.replyCountGTEZero());
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

import "./IAllowReplies.sol";

interface IAllowRepliesStatus is IAllowReplies {
  function replyStatus(address item) external view returns(int32);
  function replyCountLTZero() external view returns(uint256);
  function replyCountGTEZero() external view returns(uint256);
  
  struct ReplyStatus {
    address item;
    int32 status;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IAllowReplies is IERC165 {
  function addReply(address reply) external;
  function replyCount() external view returns(uint256);
  function replies(uint256 index) external view returns(address);
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