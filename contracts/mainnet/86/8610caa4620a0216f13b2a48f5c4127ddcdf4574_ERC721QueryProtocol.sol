// SPDX-License-Identifier: MIT
// Creator: https://twitter.com/marcelc63

pragma solidity ^0.8.12;

/**
 * ERC721QueryProtocol
 *
 * The motivation for this contract is to provide a way to query the state of an ERC721 token.
 * Implementation is based on ERC721AQueryable
 *
 * Implementing ERC721Enumerable is not encourage due to its gas cost, and ERC-165 stop advertising ERC721Enumerable.
 * While it results in more optimized contract, front-end developers loose the ability to enumerate over the token.
 *
 * ERC721QueryProtocol allows front-end developers to query the state of any ERC721 token.
 * Especially for contracts that does not implement ERC721Enumerable.
 */

error TokenIndexOutOfBounds();
error InvalidQueryRange();
error TotalSupplyNotFound();

interface IERC721 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function ownerOf(uint256 tokenId) external view returns (address);
}

contract ERC721QueryProtocol {
  constructor() {}

  /**
   * @dev Returns an array of token IDs owned by `owner`.
   *
   * This function scans the ownership mapping and is O(totalSupply) in complexity.
   * It is meant to be called off-chain.
   *
   * See {ERC721QueryProtocol-tokensOfOwnerIn} for splitting the scan into
   * multiple smaller scans if the collection is large enough to cause
   * an out-of-gas error (10K pfp collections should be fine).
   *
   * Modified from ERC721AQueryable
   */
  function tokensOfOwner(address contractAddress, address owner)
    external
    view
    returns (uint256[] memory)
  {
    unchecked {
      uint256 tokenIdsIdx;
      uint256 tokenIdsLength = IERC721(contractAddress).balanceOf(owner);
      uint256[] memory tokenIds = new uint256[](tokenIdsLength);

      // Index starts at 0. Try/catch will skip over index 0 for contracts starting with index 1.
      for (uint256 i = 0; tokenIdsIdx != tokenIdsLength; ++i) {
        // Try get token owner. Skip if token doesn't exist.
        try IERC721(contractAddress).ownerOf(i) returns (address tokenOwner) {
          if (tokenOwner == owner) {
            tokenIds[tokenIdsIdx++] = i;
          }
        } catch {
          continue;
        }
      }

      return tokenIds;
    }
  }

  /**
   * @dev Returns an array of token IDs owned by `owner`,
   * in the range [`start`, `stop`)
   * (i.e. `start <= tokenId < stop`).
   *
   * This function allows for tokens to be queried if the collection
   * grows too big for a single call of {ERC721QueryProtocol-tokensOfOwner}.
   *
   * Requirements:
   *
   * - `start` < `stop`
   *
   * Modified from ERC721AQueryable
   */
  function tokensOfOwnerIn(
    address contractAddress,
    address owner,
    uint256 start,
    uint256 stop
  ) external view returns (uint256[] memory) {
    unchecked {
      if (start >= stop) revert InvalidQueryRange();

      // Try get token totalSupply. Fail if contract doesn't implement totalSupply.
      try IERC721(contractAddress).totalSupply() returns (uint256 stopLimit) {
        uint256 tokenIdsIdx;

        // Set `start = max(start, _startTokenId())`.
        if (start < 0) {
          start = 0;
        }
        // Set `stop = min(stop, _currentIndex)`.
        if (stop > stopLimit) {
          stop = stopLimit;
        }
        uint256 tokenIdsMaxLength = IERC721(contractAddress).balanceOf(owner);
        // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
        // to cater for cases where `balanceOf(owner)` is too big.
        if (start < stop) {
          uint256 rangeLength = stop - start;
          if (rangeLength < tokenIdsMaxLength) {
            tokenIdsMaxLength = rangeLength;
          }
        } else {
          tokenIdsMaxLength = 0;
        }
        uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
        if (tokenIdsMaxLength == 0) {
          return tokenIds;
        }

        for (
          uint256 i = start;
          i != stop && tokenIdsIdx != tokenIdsMaxLength;
          ++i
        ) {
          // Try get token owner. Skip if token doesn't exist.
          try IERC721(contractAddress).ownerOf(i) returns (address tokenOwner) {
            if (tokenOwner == owner) {
              tokenIds[tokenIdsIdx++] = i;
            }
          } catch {
            continue;
          }
        }
        // Downsize the array to fit.
        assembly {
          mstore(tokenIds, tokenIdsIdx)
        }
        return tokenIds;
      } catch {
        revert TotalSupplyNotFound();
      }
    }
  }
}