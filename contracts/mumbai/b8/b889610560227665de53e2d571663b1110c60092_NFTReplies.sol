// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import "./SortableAddressSet.sol";

contract NFTReplies {
  using SortableAddressSet for SortableAddressSet.Set;
  mapping(address => mapping(uint256 => SortableAddressSet.Set)) replies;
  mapping(address => uint256) _replyAddedTime;
  mapping(address => Token) _reverseInternalAddr;

  struct Token {
    address collection;
    uint256 tokenId;
  }

  function calcInternalAddr(address collection, uint256 tokenId) public pure returns (address) {
    return address(uint160(uint256(keccak256(abi.encodePacked(collection, tokenId)))));
  }

  function addReply(
    address parentCollection, uint256 parentTokenId,
    address childCollection, uint256 childTokenId
  ) public {
    require(IERC721(childCollection).ownerOf(childTokenId) == msg.sender);

    address internalAddr = calcInternalAddr(childCollection, childTokenId);
    replies[parentCollection][parentTokenId].insert(internalAddr);
    _replyAddedTime[internalAddr] = block.timestamp;
    _reverseInternalAddr[internalAddr] = Token(childCollection, childTokenId);
  }

  // So users don't have to make 2 tx for a reply
  function addNewReply(
    address parentCollection, uint256 parentTokenId,
    address childCollection, bytes memory data
  ) external {
    (bool success, bytes memory returned) = childCollection.call(data);
    require(success);
    uint256 newTokenId = uint256(bytes32(returned));
    IERC721(childCollection).safeTransferFrom(address(this), msg.sender, newTokenId);
    addReply(parentCollection, parentTokenId, childCollection, newTokenId);
  }

  function replyAddedTime(address collection, uint256 tokenId) external view returns(uint) {
    return _replyAddedTime[calcInternalAddr(collection, tokenId)];
  }

  function sortedCount(address collection, uint256 tokenId) public view returns(uint) {
    return replies[collection][tokenId].sortedCount;
  }

  function unsortedCount(address collection, uint256 tokenId) public view returns(uint) {
    return replies[collection][tokenId].itemList.length - replies[collection][tokenId].sortedCount;
  }

  function fetchUnsorted(address collection, uint256 tokenId, uint startIndex, uint fetchCount, bool reverseScan) public view returns(address[] memory out, uint totalCount, uint lastScanned) {
    return replies[collection][tokenId].fetchUnsorted(startIndex, fetchCount, reverseScan);
  }

  function fetchSorted(address collection, uint256 tokenId, address start, uint maxReturned, bool reverseScan) public view returns(address[] memory out) {
    return replies[collection][tokenId].fetchSorted(start, maxReturned, reverseScan);
  }

  function convertInternalToTokens(address[] memory input) public view returns(Token[] memory out) {
    out = new Token[](input.length);
    for(uint i = 0; i < out.length; i++) {
      out[i] = _reverseInternalAddr[input[i]];
    }
  }

  function suggestSorts(address collection, uint256 tokenId, address insertAfter, address[] memory toAdd) external view returns(uint[] memory out) {
    return replies[collection][tokenId].suggestSorts(insertAfter, toAdd);
  }

  // TODO add special sort level to delete the reply
  function setSort(address collection, uint256 tokenId, address[] memory ofItems, uint[] memory sortValues) external {
    require(IERC721(collection).ownerOf(tokenId) == msg.sender);
    replies[collection][tokenId].setSort(ofItems, sortValues);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BokkyPooBahsRedBlackTreeLibrary.sol";

library SortableAddressSet {
  using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;

  struct Set {
    BokkyPooBahsRedBlackTreeLibrary.Tree tree;
    address[] itemList;
    mapping(address => bool) itemExists;
    mapping(address => uint) itemSorts;
    mapping(uint => address) sortItems;
    uint sortedCount;
  }

  function insert(Set storage self, address toAdd) internal {
    require(!self.itemExists[toAdd]);
    self.itemList.push(toAdd);
    self.itemExists[toAdd] = true;
  }

  function getSortIndex(Set storage self, address item) internal view returns(uint) {
    uint sortVal = self.itemSorts[item];
    if(sortVal == 0) return type(uint).max;

    uint pos = self.tree.first();
    uint index;
    while(pos != sortVal) {
      pos = self.tree.next(pos);
      index++;
    }
    return index;
  }

  function setSort(Set storage self, address[] memory items, uint[] memory sortValues) internal {
    require(items.length == sortValues.length);
    for(uint i = 0; i < items.length; i++) {
      require(self.itemExists[items[i]]);
      if(sortValues[i] == self.itemSorts[items[i]]) continue;
      if(self.itemSorts[items[i]] != 0) {
        self.tree.remove(self.itemSorts[items[i]]);
        self.sortItems[self.itemSorts[items[i]]] = address(0);
        if(sortValues[i] == 0) self.sortedCount--;
      } else {
        self.sortedCount++;
      }
      self.itemSorts[items[i]] = sortValues[i];
      if(sortValues[i] != 0) {
        self.sortItems[sortValues[i]] = items[i];
        self.tree.insert(sortValues[i]);
      }
    }
  }

  function fetchUnsorted(Set storage items, uint startIndex, uint fetchCount, bool reverseScan) internal view returns(address[] memory out, uint totalCount, uint lastScanned) {
    if(items.itemList.length > 0) {

      require(startIndex < items.itemList.length);

      if(startIndex + fetchCount >= items.itemList.length) {
        fetchCount = items.itemList.length - startIndex;
      }

      address[] memory selection = new address[](fetchCount);
      uint activeCount;
      lastScanned = startIndex;
      totalCount = items.itemList.length;

      if(reverseScan) {
        lastScanned = items.itemList.length - 1 - startIndex;
      }

      while(true) {
        if(items.itemSorts[items.itemList[lastScanned]] == 0) {
          selection[activeCount++] = items.itemList[lastScanned];
          if(activeCount == fetchCount) break;
        }
        if(reverseScan) {
          if(lastScanned == 0) break;
          lastScanned--;
        } else {
          if(lastScanned == items.itemList.length - 1) break;
          lastScanned++;
        }
      }

      // Crop the output
      out = new address[](activeCount);
      for(uint i=0; i<activeCount; i++) {
        out[i] = selection[i];
      }
    }
  }

  function fetchSorted(Set storage self, address start, uint maxReturned, bool reverseScan) internal view returns(address[] memory out) {
    uint foundCount;
    uint[] memory foundAll = new uint[](maxReturned);
    foundAll[0] = start == address(0) ? self.tree.first() : reverseScan ? self.tree.prev(self.itemSorts[start]) : self.tree.next(self.itemSorts[start]);

    if(foundAll[0] == 0) return new address[](0);

    while(foundAll[foundCount] > 0) {
      if(foundCount + 1 == maxReturned) {
        foundCount++;
        break;
      }
      foundAll[++foundCount] = reverseScan ? self.tree.prev(foundAll[foundCount]) : self.tree.next(foundAll[foundCount]);
    }

    out = new address[](foundCount);
    for(uint i = 0; i<foundCount; i++) {
      out[i] = self.sortItems[foundAll[i]];
    }
  }

  // This is a separate view function for the client to query before using setSort()
  // It's potentially a lot of computation so no use paying for its gas
  function suggestSorts(Set storage self, address insertAfter, address[] memory toAdd) internal view returns(uint[] memory out) {
    require(insertAfter == address(0) || self.itemSorts[insertAfter] > 0);
    out = new uint[](toAdd.length);
    uint start;
    uint end;
    if(self.tree.root == 0) {
      // tree is empty, even distribution
      end = type(uint).max;
    } else {
      if(insertAfter == address(0)) {
        // inserting to beginning
        end = self.tree.first();
      } else {
        // inserting somewhere after the beginning
        start = self.itemSorts[insertAfter];
        end = self.tree.next(self.itemSorts[insertAfter]);
      }
      // the subsequent items will be moving?
      (,,, uint seqStartPos, uint seqEndPos) = isSequence(self, toAdd);
      if(seqStartPos != 0 && seqStartPos == end) {
        end = self.tree.next(seqEndPos);
      }
    }

    if(end == 0) end = type(uint).max;
    uint step = (end - start) / (toAdd.length + 1);
    for(uint i = 0; i<toAdd.length; i++) {
      out[i] = ((i + 1) * step) + start;
    }

  }

  function isSequence(Set storage self, address[] memory toCheck) internal view returns(uint seqLen, uint seqStart, uint seqEnd, uint start, uint end) {
    uint[] memory nexts = new uint[](toCheck.length);
    uint[] memory pos = new uint[](toCheck.length);
    uint i;
    for(i = 0; i < toCheck.length; i++) {
      pos[i] = self.itemSorts[toCheck[i]];
      if(pos[i] == 0) continue;
      nexts[i] = self.tree.next(pos[i]);
      if(start == 0 || pos[i] < start) {
        start = end = pos[i];
        // Start from the beginning
        seqEnd = seqStart = i;
      }
    }
    i = 0;
    seqLen = 1;
    while(i != toCheck.length) {
      for(i = 0; i < toCheck.length; i++) {
        if(pos[i] == 0) continue;
        if(pos[i] == nexts[seqEnd]) {
          seqEnd = i;
          end = pos[i];
          seqLen++;
          break;
        }
      }
    }

  }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's Red-Black Tree Library v1.0-pre-release-a
//
// A Solidity Red-Black Tree binary search library to store and access a sorted
// list of unsigned integer data. The Red-Black algorithm rebalances the binary
// search tree, resulting in O(log n) insert, remove and search time (and ~gas)
//
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2020. The MIT Licence.
// ----------------------------------------------------------------------------
library BokkyPooBahsRedBlackTreeLibrary {

    struct Node {
        uint parent;
        uint left;
        uint right;
        bool red;
    }

    struct Tree {
        uint root;
        mapping(uint => Node) nodes;
    }

    uint private constant EMPTY = 0;

    function first(Tree storage self) internal view returns (uint _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].left != EMPTY) {
                _key = self.nodes[_key].left;
            }
        }
    }
    function last(Tree storage self) internal view returns (uint _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].right != EMPTY) {
                _key = self.nodes[_key].right;
            }
        }
    }
    function next(Tree storage self, uint target) internal view returns (uint cursor) {
        require(target != EMPTY);
        if (self.nodes[target].right != EMPTY) {
            cursor = treeMinimum(self, self.nodes[target].right);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].right) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }
    function prev(Tree storage self, uint target) internal view returns (uint cursor) {
        require(target != EMPTY);
        if (self.nodes[target].left != EMPTY) {
            cursor = treeMaximum(self, self.nodes[target].left);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].left) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }
    function exists(Tree storage self, uint key) internal view returns (bool) {
        return (key != EMPTY) && ((key == self.root) || (self.nodes[key].parent != EMPTY));
    }
    function isEmpty(uint key) internal pure returns (bool) {
        return key == EMPTY;
    }
    function getEmpty() internal pure returns (uint) {
        return EMPTY;
    }
    function getNode(Tree storage self, uint key) internal view returns (uint _returnKey, uint _parent, uint _left, uint _right, bool _red) {
        require(exists(self, key));
        return(key, self.nodes[key].parent, self.nodes[key].left, self.nodes[key].right, self.nodes[key].red);
    }

    function insert(Tree storage self, uint key) internal {
        require(key != EMPTY);
        require(!exists(self, key));
        uint cursor = EMPTY;
        uint probe = self.root;
        while (probe != EMPTY) {
            cursor = probe;
            if (key < probe) {
                probe = self.nodes[probe].left;
            } else {
                probe = self.nodes[probe].right;
            }
        }
        self.nodes[key] = Node({parent: cursor, left: EMPTY, right: EMPTY, red: true});
        if (cursor == EMPTY) {
            self.root = key;
        } else if (key < cursor) {
            self.nodes[cursor].left = key;
        } else {
            self.nodes[cursor].right = key;
        }
        insertFixup(self, key);
    }
    function remove(Tree storage self, uint key) internal {
        require(key != EMPTY);
        require(exists(self, key));
        uint probe;
        uint cursor;
        if (self.nodes[key].left == EMPTY || self.nodes[key].right == EMPTY) {
            cursor = key;
        } else {
            cursor = self.nodes[key].right;
            while (self.nodes[cursor].left != EMPTY) {
                cursor = self.nodes[cursor].left;
            }
        }
        if (self.nodes[cursor].left != EMPTY) {
            probe = self.nodes[cursor].left;
        } else {
            probe = self.nodes[cursor].right;
        }
        uint yParent = self.nodes[cursor].parent;
        self.nodes[probe].parent = yParent;
        if (yParent != EMPTY) {
            if (cursor == self.nodes[yParent].left) {
                self.nodes[yParent].left = probe;
            } else {
                self.nodes[yParent].right = probe;
            }
        } else {
            self.root = probe;
        }
        bool doFixup = !self.nodes[cursor].red;
        if (cursor != key) {
            replaceParent(self, cursor, key);
            self.nodes[cursor].left = self.nodes[key].left;
            self.nodes[self.nodes[cursor].left].parent = cursor;
            self.nodes[cursor].right = self.nodes[key].right;
            self.nodes[self.nodes[cursor].right].parent = cursor;
            self.nodes[cursor].red = self.nodes[key].red;
            (cursor, key) = (key, cursor);
        }
        if (doFixup) {
            removeFixup(self, probe);
        }
        delete self.nodes[cursor];
    }

    function treeMinimum(Tree storage self, uint key) private view returns (uint) {
        while (self.nodes[key].left != EMPTY) {
            key = self.nodes[key].left;
        }
        return key;
    }
    function treeMaximum(Tree storage self, uint key) private view returns (uint) {
        while (self.nodes[key].right != EMPTY) {
            key = self.nodes[key].right;
        }
        return key;
    }

    function rotateLeft(Tree storage self, uint key) private {
        uint cursor = self.nodes[key].right;
        uint keyParent = self.nodes[key].parent;
        uint cursorLeft = self.nodes[cursor].left;
        self.nodes[key].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            self.nodes[cursorLeft].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].left) {
            self.nodes[keyParent].left = cursor;
        } else {
            self.nodes[keyParent].right = cursor;
        }
        self.nodes[cursor].left = key;
        self.nodes[key].parent = cursor;
    }
    function rotateRight(Tree storage self, uint key) private {
        uint cursor = self.nodes[key].left;
        uint keyParent = self.nodes[key].parent;
        uint cursorRight = self.nodes[cursor].right;
        self.nodes[key].left = cursorRight;
        if (cursorRight != EMPTY) {
            self.nodes[cursorRight].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].right) {
            self.nodes[keyParent].right = cursor;
        } else {
            self.nodes[keyParent].left = cursor;
        }
        self.nodes[cursor].right = key;
        self.nodes[key].parent = cursor;
    }

    function insertFixup(Tree storage self, uint key) private {
        uint cursor;
        while (key != self.root && self.nodes[self.nodes[key].parent].red) {
            uint keyParent = self.nodes[key].parent;
            if (keyParent == self.nodes[self.nodes[keyParent].parent].left) {
                cursor = self.nodes[self.nodes[keyParent].parent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].right) {
                      key = keyParent;
                      rotateLeft(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateRight(self, self.nodes[keyParent].parent);
                }
            } else {
                cursor = self.nodes[self.nodes[keyParent].parent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].left) {
                      key = keyParent;
                      rotateRight(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateLeft(self, self.nodes[keyParent].parent);
                }
            }
        }
        self.nodes[self.root].red = false;
    }

    function replaceParent(Tree storage self, uint a, uint b) private {
        uint bParent = self.nodes[b].parent;
        self.nodes[a].parent = bParent;
        if (bParent == EMPTY) {
            self.root = a;
        } else {
            if (b == self.nodes[bParent].left) {
                self.nodes[bParent].left = a;
            } else {
                self.nodes[bParent].right = a;
            }
        }
    }
    function removeFixup(Tree storage self, uint key) private {
        uint cursor;
        while (key != self.root && !self.nodes[key].red) {
            uint keyParent = self.nodes[key].parent;
            if (key == self.nodes[keyParent].left) {
                cursor = self.nodes[keyParent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateLeft(self, keyParent);
                    cursor = self.nodes[keyParent].right;
                }
                if (!self.nodes[self.nodes[cursor].left].red && !self.nodes[self.nodes[cursor].right].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].right].red) {
                        self.nodes[self.nodes[cursor].left].red = false;
                        self.nodes[cursor].red = true;
                        rotateRight(self, cursor);
                        cursor = self.nodes[keyParent].right;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].right].red = false;
                    rotateLeft(self, keyParent);
                    key = self.root;
                }
            } else {
                cursor = self.nodes[keyParent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateRight(self, keyParent);
                    cursor = self.nodes[keyParent].left;
                }
                if (!self.nodes[self.nodes[cursor].right].red && !self.nodes[self.nodes[cursor].left].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].left].red) {
                        self.nodes[self.nodes[cursor].right].red = false;
                        self.nodes[cursor].red = true;
                        rotateLeft(self, cursor);
                        cursor = self.nodes[keyParent].left;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].left].red = false;
                    rotateRight(self, keyParent);
                    key = self.root;
                }
            }
        }
        self.nodes[key].red = false;
    }
}
// ----------------------------------------------------------------------------
// End - BokkyPooBah's Red-Black Tree Library
// ----------------------------------------------------------------------------