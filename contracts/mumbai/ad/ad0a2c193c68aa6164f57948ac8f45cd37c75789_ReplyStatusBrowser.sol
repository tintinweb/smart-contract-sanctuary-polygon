// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IAllowRepliesStatus.sol";

contract ReplyStatusBrowser {
  struct ReplyDetails {
    address item;
    int32 status;
  }

  struct RepliesResponse {
    ReplyDetails[] items;
    uint totalCount;
    uint lastScanned;
  }

  // Sorting must happen on the client
  function fetchReplies(
    IAllowRepliesStatus post,
    int32 minStatus,
    uint startIndex,
    uint fetchCount,
    bool reverseScan
  ) external view returns(RepliesResponse memory) {
    if(post.replyCount() == 0) return RepliesResponse(new ReplyDetails[](0), 0, 0);
    require(startIndex < post.replyCount());
    if(startIndex + fetchCount >= post.replyCount()) {
      fetchCount = post.replyCount() - startIndex;
    }
    address[] memory selection = new address[](fetchCount);
    uint activeCount;
    uint i;
    uint replyIndex = startIndex;
    if(reverseScan) {
      replyIndex = post.replyCount() - 1 - startIndex;
    }
    while(true) {
      selection[i] = post.replies(replyIndex);
      if(post.replyStatus(selection[i]) >= minStatus) activeCount++;
      if(activeCount == fetchCount) break;
      if(reverseScan) {
        if(replyIndex == 0) break;
        replyIndex--;
      } else {
        if(replyIndex == post.replyCount() - 1) break;
        replyIndex++;
      }
      i++;
    }

    ReplyDetails[] memory out = new ReplyDetails[](activeCount);
    uint j;
    for(i=0; i<fetchCount; i++) {
      if(post.replyStatus(selection[i]) >= minStatus) {
        out[j++] = ReplyDetails(
          selection[i],
          post.replyStatus(selection[i])
        );
      }
    }
    return RepliesResponse(out, post.replyCount(), replyIndex);
  }
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