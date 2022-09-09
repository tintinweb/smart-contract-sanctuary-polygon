// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Data.sol";
import "./IERC721Saleable.sol";

// ============ Contracts ============

contract JustGemsIndex {
  // ============ Errors ============

  error InvalidCall();

  // ============ Structs ============

  struct Token {
    string uri;
    uint256 price;
    bool minted;
  }

  // ============ Constants ============

  IERC721Data immutable public METADATA;
  IERC721Saleable immutable public SALEABLE;

  // ============ Deploy ============

  constructor(IERC721Data metadata, IERC721Saleable saleable) {
    METADATA = metadata;
    SALEABLE = saleable;
  }

  // ============ Read Methods ============

  function search(
    uint256 fromTokenId,
    uint256 toTokenId,
    string memory trait,
    string memory value
  ) external view returns(Token[] memory) {
    return search(
      fromTokenId, 
      toTokenId, 
      _toArray(trait), 
      _toArray(value)
    );
  }

  function search(
    uint256 fromTokenId,
    uint256 toTokenId,
    string[] memory traits,
    string[] memory values
  ) public view returns(Token[] memory) {
    uint256[] memory tokenIds = _searchResults(
      fromTokenId,
      toTokenId,
      traits,
      values
    );

    //now make an array
    Token[] memory results = new Token[](tokenIds.length);
    for (uint256 i; i < tokenIds.length; i++) {
      results[i] = Token(
        METADATA.tokenURI(tokenIds[i]),
        SALEABLE.priceOf(tokenIds[i]),
        SALEABLE.minted(tokenIds[i]) != address(0)
      );
    }

    return results;
  }

  function search(
    IERC20 token, 
    uint256 fromTokenId,
    uint256 toTokenId,
    string memory trait,
    string memory value
  ) external view returns(Token[] memory) {
    return search(
      token, 
      fromTokenId, 
      toTokenId, 
      _toArray(trait), 
      _toArray(value)
    );
  }

  function search(
    IERC20 token, 
    uint256 fromTokenId,
    uint256 toTokenId,
    string[] memory traits,
    string[] memory values
  ) public view returns(Token[] memory) {
    uint256[] memory tokenIds = _searchResults(
      fromTokenId,
      toTokenId,
      traits,
      values
    );

    //now make an array
    Token[] memory results = new Token[](tokenIds.length);
    for (uint256 i; i < tokenIds.length; i++) {
      results[i] = Token(
        METADATA.tokenURI(tokenIds[i]),
        SALEABLE.priceOf(token, tokenIds[i]),
        SALEABLE.minted(tokenIds[i]) != address(0)
      );
    }

    return results;
  }

  // ============ Internal Methods ============

  /**
   * @dev Returns a set of token ids that match the given criteria
   */
  function _searchResults(
    uint256 fromTokenId,
    uint256 toTokenId,
    string[] memory traits,
    string[] memory values
  ) internal view returns(uint256[] memory) {
    //now make an array
    uint256[] memory results = new uint256[](_searchSize(
      fromTokenId, 
      toTokenId,
      traits,
      values
    ));
    //loop through tokens
    uint256 index;
    for (uint256 tokenId = fromTokenId; tokenId <= toTokenId; tokenId++) {
      uint256 matches;
      for (uint256 i; i < traits.length; i++) {
        if (METADATA.hasTrait(tokenId, traits[i], values[i])) {
          matches++;
        }
      }

      if (matches == traits.length) {
        results[index++] = tokenId;
      }
    }

    return results;
  }

  /**
   * @dev Returns the size of the search
   */
  function _searchSize(
    uint256 fromTokenId,
    uint256 toTokenId,
    string[] memory traits,
    string[] memory values
  ) internal view returns(uint256 size) {
    if (traits.length != values.length) revert InvalidCall();
    //loop through tokens
    for (uint256 tokenId = fromTokenId; tokenId <= toTokenId; tokenId++) {
      uint256 matches;
      for (uint256 i; i < traits.length; i++) {
        if (METADATA.hasTrait(tokenId, traits[i], values[i])) {
          matches++;
        }
      }

      if (matches == traits.length) {
        size++;
      }
    }
  }

  /**
   * @dev Converts a string to an array
   */
  function _toArray(string memory element) private pure returns (string[] memory) {
    string[] memory array = new string[](1);
    array[0] = element;
    return array;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// ============ Interfaces ============

interface IERC721Data {
  /**
   * @dev Returns true if the `tokenId` has the given `trait` `value`
   */
  function hasTrait(
    uint256 tokenId,
    string memory trait,
    string memory value
  ) external view returns(bool);

  /**
   * @dev Returns the URI location of the given `tokenId`
   */
  function tokenURI(
    uint256 tokenId
  ) external view returns(string memory);

  /**
   * @dev Returns the `trait` value of the given `tokenId`
   */
  function traitOf(
    uint256 tokenId,
    string memory trait
  ) external view returns(string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ============ Interfaces ============

interface IERC721Saleable {
  /**
   * @dev Returns who minted if any
   */
  function minted(uint256 tokenId) external view returns(address);

  /**
   * @dev returns the price of `tokenId`
   */
  function priceOf(uint256 tokenId) external view returns(uint256);

  /**
   * @dev returns the price of `tokenId`
   */
  function priceOf(IERC20 token, uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}