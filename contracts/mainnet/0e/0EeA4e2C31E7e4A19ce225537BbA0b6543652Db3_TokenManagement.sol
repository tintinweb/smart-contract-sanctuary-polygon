/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;



// File: TokenManagement.sol

library TokenManagement {
    struct TokenManager {
        // Mapping from owner to list of owned token IDs
        mapping(address => mapping(uint256 => uint256)) ownedTokens;

        // Mapping from token ID to index of the owner tokens list
        mapping(uint256 => uint256) ownedTokensIndex;

        // Array with all token ids, used for enumeration
        uint256[] allTokens;

        // Mapping from token id to position in the allTokens array
        mapping(uint256 => uint256) allTokensIndex;

        // Mapping owner address to token count
        mapping(address => uint256) balances;
    }

    /**
     * @dev Returns the number of tokens in ``_owner``'s account.
     */
    function balanceOf(TokenManager storage _mgr, address _owner) external view returns (uint256 balance) {
        require(
            _owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _mgr.balances[_owner];
    }

    /**
     * @dev returns the current number of tokens that have been minted.
     */
    function totalSupply(TokenManager storage _mgr) public view returns (uint256) {
        return _mgr.allTokens.length;
    }

    /**
     * @dev Returns a token ID owned by `_owner` at a given `_index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``_owner``'s tokens.
     */
    function tokenOfOwnerByIndex(TokenManager storage _mgr, address _owner, uint256 _index)
        public
        view
        returns (uint256)
    {
        require(
            _index < _mgr.balances[_owner],
            "ERC721Enumerable: _owner index out of bounds"
        );
        return _mgr.ownedTokens[_owner][_index];
    }

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(TokenManager storage _mgr, uint256 index) public view returns (uint256) {
        require(
            index < _mgr.allTokens.length,
            "ERC721Enumerable: global index out of bounds"
        );
        return _mgr.allTokens[index];
    }

    /**
     * @notice Returns a list of all the token ids owned by an address.
     */
    function userWallet(TokenManager storage _mgr, address _user) public view returns (uint256[] memory) {
        uint256 userTokenCount = _mgr.balances[_user];
        uint256[] memory ownedTokenIds = new uint256[](userTokenCount);
        for (uint256 i = 0; i < userTokenCount; i++) {
            ownedTokenIds[i] = _mgr.ownedTokens[_user][i];
        }

        return ownedTokenIds;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     */
    function beforeTokenTransfer(
        TokenManager storage _mgr, 
        address _fromAddress,
        address _toAddress,
        uint256 _tokenId
    ) external {
        _beforeTokenTransfer(_mgr, _fromAddress, _toAddress, _tokenId);
    }

    function _beforeTokenTransfer(
        TokenManager storage _mgr, 
        address _fromAddress,
        address _toAddress,
        uint256 _tokenId
    ) private {
        if (_fromAddress == address(0)) {
            _addTokenToAllTokensEnumeration(_mgr, _tokenId);
        } else if (_fromAddress != _toAddress) {
            _removeTokenFromOwnerEnumeration(_mgr, _fromAddress, _tokenId);
            _mgr.balances[_fromAddress] -= 1;
        }
        if (_toAddress == address(0)) {
            _removeTokenFromAllTokensEnumeration(_mgr, _tokenId);
        } else if (_toAddress != _fromAddress) {
            _addTokenToOwnerEnumeration(_mgr, _toAddress, _tokenId);
            _mgr.balances[_toAddress] += 1;
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param _toAddress address representing the new owner of the given token ID
     * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(TokenManager storage _mgr, address _toAddress, uint256 _tokenId)
        private
    {
        uint256 length = _mgr.balances[_toAddress];
        _mgr.ownedTokens[_toAddress][length] = _tokenId;
        _mgr.ownedTokensIndex[_tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param _tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(TokenManager storage _mgr, uint256 _tokenId) private {
        _mgr.allTokensIndex[_tokenId] = _mgr.allTokens.length;
        _mgr.allTokens.push(_tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the ownedTokens array.
     * @param _fromAddress address representing the previous owner of the given token ID
     * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(
        TokenManager storage _mgr, 
        address _fromAddress,
        uint256 _tokenId
    ) private {
        // To prevent a gap in _fromAddress's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _mgr.balances[_fromAddress] - 1;
        uint256 tokenIndex = _mgr.ownedTokensIndex[_tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _mgr.ownedTokens[_fromAddress][lastTokenIndex];

            _mgr.ownedTokens[_fromAddress][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _mgr.ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _mgr.ownedTokensIndex[_tokenId];
        delete _mgr.ownedTokens[_fromAddress][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the allTokens array.
     * @param _tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(TokenManager storage _mgr, uint256 _tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _mgr.allTokens.length - 1;
        uint256 tokenIndex = _mgr.allTokensIndex[_tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _mgr.allTokens[lastTokenIndex];

        _mgr.allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _mgr.allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _mgr.allTokensIndex[_tokenId];
        _mgr.allTokens.pop();
    }
}