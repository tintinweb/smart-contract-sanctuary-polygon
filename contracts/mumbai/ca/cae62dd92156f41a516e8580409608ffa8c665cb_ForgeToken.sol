/**
 *Submitted for verification at polygonscan.com on 2023-04-18
*/

// File: Forge_ERC721.sol

// Contract based on https://docs.openzeppelin.com/contracts/4.x/erc721

pragma solidity ^0.8.4;

interface IERC721Receiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) external returns(bytes4);
}


//=============================================================================
/// @title Forge_ERC721
/// @dev Implementation of the ERC-721 Non-Fungible Token Standard.
///  - This implementation was created to support giving tokens attribute data
///  without increasing the gas cost of minting.
///  - This implementation also enables tokenOfOwnerByIndex and totalSupply.
/// @author Forge Inc.
//=============================================================================
abstract contract Forge_ERC721 {
    //-------------------------------------------------------------------------
    /// @title TokenData
    /// @dev A data structure containing information about a specific token ID.
    ///  - Initializing TokenData costs the same amount of gas as initializing
    ///  _owners for the token ID in the OpenZeppelin ERC721 implementation.
    //-------------------------------------------------------------------------
    struct TokenData {
        // The owner of this token. An address takes up 20 bytes.
        address tokenOwner;
        // The index of this token in OwnerData's tokensOwned array. Max value 65536.
        uint16 tokenIndex;
        // Leftover to fill with arbitrary data by the implementation contract.
        uint80 extraData;
    }

    //-------------------------------------------------------------------------
    /// @title OwnerData
    /// @dev A data structure containing information about a specific address.
    ///  - Initialized the first time an owner either receives a token or sets
    ///  an address approved operator. The expected-case is that OwnerData is
    ///  initialized when an owner mints their first token. 
    ///  - Initializing OwnerData costs the same amount of gas as initializing
    ///  _balances for the owner in the OpenZeppelin ERC721 implementation.
    //-------------------------------------------------------------------------
    struct OwnerData {
        // An array containing the token ids of all tokens owned by this owner
        uint24[] tokensOwned;
        // A mapping of addresses to if they are approved operators for this owner
        mapping (address=>bool) operatorApprovals;
    }

    // Token name
    string public name;
    // Token symbol
    string public symbol;

    // An array containing TokenData for all tokens ever minted.
    // A token's identifier is used to index directly to its data, so the
    // order of _tokenData must never be modified.
    TokenData[] internal _tokenData;
    // A mapping containing OwnerData for all addresses
    mapping (address=>OwnerData) internal _ownerData;
    // A mapping containing approved addresses for each token ID
    mapping (uint=>address) private _tokenApprovals;
    // Number of burned tokens, used to calculate total supply
    uint internal _burnedTokens;

    //-------------------------------------------------------------------------
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event also emits when NFTs are created (`from` == 0) and
    ///  destroyed (`to` == 0). Also indicates that the approved address for
    ///  the NFT is reset to none.
    //-------------------------------------------------------------------------
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    
    //-------------------------------------------------------------------------
    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    //-------------------------------------------------------------------------
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    //-------------------------------------------------------------------------
    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can transfer all NFTs of the owner.
    //-------------------------------------------------------------------------
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    //-------------------------------------------------------------------------
    /// @dev Throws if a token does not exist or has been burned
    //-------------------------------------------------------------------------
    modifier exists(uint _tokenId) {
        require(
            _tokenId < _tokenData.length && 
            _tokenData[_tokenId].tokenOwner != address(0),
            "ERC721: Token with this ID does not exist"
        );
        _;
    }
    
    //-------------------------------------------------------------------------
    /// @dev Initializes the contract, setting the token collection's `name`
    ///  and `symbol`.
    //-------------------------------------------------------------------------
    constructor(string memory _name, string memory _symbol) {
        _tokenData.push(TokenData(address(0),0,0));
        name = _name;
        symbol = _symbol;
    }


    //=========================================================================
    // PUBLIC FUNCTIONS
    //=========================================================================
    //-------------------------------------------------------------------------
    /// @notice Transfers the ownership of an NFT from one address to another
    ///  -- THE CALLER IS RESPONSIBLE TO CONFIRM THAT `_to` IS CAPABLE OF 
    ///  RECEIVING NFTS OR ELSE THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    //-------------------------------------------------------------------------
    function transferFrom(address _from, address _to, uint _tokenId)
        public
        exists(_tokenId)
    {
        address tokenOwner = _tokenData[_tokenId].tokenOwner;
        require(
            msg.sender == tokenOwner ||
            msg.sender == _tokenApprovals[_tokenId] ||
            _ownerData[tokenOwner].operatorApprovals[msg.sender],
            "ERC721: Sender not owner or approved operator for this token"
        );
        require(
            _from == tokenOwner,
            "ERC721: _from parameter is not the owner of this token"
        );

        _transfer(_to, _tokenId);
    }
    
    function safeTransferFrom(address _from, address _to, uint _tokenId)
        external
    {
        safeTransferFrom(_from, _to, _tokenId, "");
    }
    
    //-------------------------------------------------------------------------
    /// @notice Transfers the ownership of an NFT from one address to another
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param _data Additional data with no specified format, sent to `_to`
    //-------------------------------------------------------------------------
    function safeTransferFrom(
        address _from,
        address _to,
        uint _tokenId,
        bytes memory _data
    )
        public
        exists(_tokenId)
    {
        address tokenOwner = _tokenData[_tokenId].tokenOwner;
        require(
            msg.sender == tokenOwner ||
            msg.sender == _tokenApprovals[_tokenId] ||
            _ownerData[tokenOwner].operatorApprovals[msg.sender],
            "ERC721: Sender not owner or approved operator for this token"
        );
        require(
            _from == tokenOwner,
            "ERC721: _from parameter is not the owner of this token"
        );

        _transfer(_to, _tokenId);

        require(
            _checkOnERC721Received(address(0), _to, _tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    //-------------------------------------------------------------------------
    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an
    ///  authorized operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    //-------------------------------------------------------------------------
    function approve(address _approved, uint256 _tokenId)
        public
        exists(_tokenId)
    {
        address tokenOwner = _tokenData[_tokenId].tokenOwner;
        require(
            msg.sender == tokenOwner ||
            _ownerData[tokenOwner].operatorApprovals[msg.sender],
            "ERC721: Sender does not own this token"
        );
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(_tokenData[_tokenId].tokenOwner, _approved, _tokenId);
    }

    //-------------------------------------------------------------------------
    /// @notice Enable or disable approval for a third party ("operator") to
    ///  manage all of `msg.sender`'s tokens
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    //-------------------------------------------------------------------------
    function setApprovalForAll(address _operator, bool _approved) external {
        _ownerData[msg.sender].operatorApprovals[_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    //-------------------------------------------------------------------------
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return bool True if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff
    //-------------------------------------------------------------------------
    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return (
            interfaceID == 0x01ffc9a7 || // ERC165
            interfaceID == 0x80ac58cd || // ERC721
            interfaceID == 0x5b5e139f // ERC721Metadata
        );
    }


    //=========================================================================
    // PUBLIC VIEW FUNCTIONS
    //=========================================================================
    //-------------------------------------------------------------------------
    /// @notice Get the number of valid NFTs tracked by this contract, where
    ///  each one of them has an assigned and queryable owner not equal to
    ///  the zero address.
    /// @return uint Total number of valid NFTs tracked by this contract.
    //-------------------------------------------------------------------------
    function totalSupply() external view returns (uint) {
        return _tokenData.length - _burnedTokens - 1;
    }

    //-------------------------------------------------------------------------
    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return address The address of the owner of the NFT
    //-------------------------------------------------------------------------
    function ownerOf(uint _tokenId)
        external
        view
        exists(_tokenId)
        returns (address)
    {
        return _tokenData[_tokenId].tokenOwner;
    }

    //-------------------------------------------------------------------------
    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and
    ///  this function throws for queries about the zero address.
    /// @param _owner The address of the owner to query
    /// @return uint The number of NFTs owned by `_owner`, possibly zero
    //-------------------------------------------------------------------------
    function balanceOf(address _owner) external view returns (uint) {
        require (_owner != address(0), "Invalid balance query");
        return _ownerData[_owner].tokensOwned.length;
    }

    //-------------------------------------------------------------------------
    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner  The address of the owner to query
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to
    ///  `_owner`, (sort order not specified)
    //-------------------------------------------------------------------------
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint24)
    {
        require (
            _owner != address(0),
            "ERC721Enumerable: Invalid owner address"
        );
        require (
            _index < _ownerData[_owner].tokensOwned.length,
            "ERC721Enumerable: Invalid index"
        );
        return _ownerData[_owner].tokensOwned[_index];
    }

    //-------------------------------------------------------------------------
    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner  The address of the owner to query
    /// @return uint24[] The token identifiers for the tokens owned by `_owner`,
    ///   (sort order not specified)
    //-------------------------------------------------------------------------
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint24[] memory)
    {
        require (
            _owner != address(0),
            "ERC721Enumerable: Invalid owner address"
        );
        return _ownerData[_owner].tokensOwned;
    }

    //-------------------------------------------------------------------------
    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return address The approved address for this NFT, or the zero address
    ///  if there is none
    //-------------------------------------------------------------------------
    function getApproved(uint _tokenId)
        external
        view
        exists(_tokenId)
        returns (address)
    {
        return _tokenApprovals[_tokenId];
    }

    //-------------------------------------------------------------------------
    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return bool True if `_operator` is an approved operator for `_owner`
    //-------------------------------------------------------------------------
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool)
    {
        return _ownerData[_owner].operatorApprovals[_operator];
    }
    
    //-------------------------------------------------------------------------
    /// @notice A distinct Uniform Resource Identifier (URI) for a given token.
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The identifier for an NFT
    /// @return string The URI of the specified token
    //-------------------------------------------------------------------------
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        returns (string memory);


    //=========================================================================
    // INTERNAL / PRIVATE FUNCTIONS
    //=========================================================================
    function _transfer(address _to, uint _tokenId) private {
        TokenData storage tokenData = _tokenData[_tokenId];
        address from = tokenData.tokenOwner;
        
        // modify `from` owner data
        OwnerData storage ownerData = _ownerData[from];
        uint numberOfTokensOwned = ownerData.tokensOwned.length;
        if (tokenData.tokenIndex < numberOfTokensOwned - 1) {
            uint24 lastOwnedToken = ownerData.tokensOwned[numberOfTokensOwned - 1];
            // swap token to transfer with last owned token in ownerData array
            ownerData.tokensOwned[tokenData.tokenIndex] = lastOwnedToken;
            // set index of last owned token to the swapped index
            _tokenData[lastOwnedToken].tokenIndex = tokenData.tokenIndex;
        }
        // pop the owned token array
        ownerData.tokensOwned.pop();

        // modify `to` owner data
        if (_to != address(0)) {
            // set token index to the new owner's token position
            tokenData.tokenIndex = uint16(_ownerData[_to].tokensOwned.length);
            // add token to new owner's owned token array
            _ownerData[_to].tokensOwned.push(uint24(_tokenId));
        }
        
        // set the ownership of the token
        tokenData.tokenOwner = _to;

        // reset approval
        _tokenApprovals[_tokenId] = address(0);

        // emit transfer event
        emit Transfer(from, _to, _tokenId);
    }

    //-------------------------------------------------------------------------
    /// @dev Safely mints a new token and transfers it to `to`. If `to` refers
    ///  to a smart contract, it must implement {IERC721Receiver-onERC721Received},
    ///  which is called upon a safe transfer. Emits a {Transfer} event.
    /// @param _to target address that will receive the token
    /// @param _extraData arbitrary data to be handled by the
    ///  implementation contract.
    /// @param _data arbitrary data to be handled by the receiver.
    //-------------------------------------------------------------------------
    function _safeMint(address _to, uint80 _extraData, bytes memory _data)
        internal
    {
        uint24 tokenId = uint24(_tokenData.length);
        uint16 tokenIndex = uint16(_ownerData[_to].tokensOwned.length);
        _tokenData.push(TokenData(_to, tokenIndex, _extraData));
        
        // add token to new owner's owned token array
        _ownerData[_to].tokensOwned.push(tokenId);

        // emit transfer event
        emit Transfer(address(0), _to, tokenId);

        require(
            _checkOnERC721Received(address(0), _to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }    

    //-------------------------------------------------------------------------
    /// @dev Equivalent to `_safeMint(to, quantity, '')`.
    //-------------------------------------------------------------------------
    function _safeMint(address _to, uint80 _extraData) internal {
        _safeMint(_to, _extraData, "");
    }

    //-------------------------------------------------------------------------
    /// @dev Destroys `tokenId`. The approval is cleared when the token is
    ///  burned. This is an internal function that does not check if the sender
    ///  is authorized to operate on the token. Throws if `tokenId` does not
    ///  exist. Emits a {Transfer} event.
    /// @param _tokenId The token to burn
    //-------------------------------------------------------------------------
    function _burn(uint _tokenId) internal exists(_tokenId) {
        _tokenApprovals[_tokenId] = address(0);
        _transfer(address(0), _tokenId);
        ++_burnedTokens;
    }

    //-------------------------------------------------------------------------
    /// @dev Internal function to invoke {IERC721Receiver-onERC721Received} on
    /// a target address.
    /// @param _from address representing the previous owner of the given token ID
    /// @param _to target address that will receive the token
    /// @param _tokenId uint256 ID of the token to be transferred
    /// @param _data bytes optional data to send along with the call
    /// @return bool whether the call correctly returned the expected magic value
    //-------------------------------------------------------------------------
    function _checkOnERC721Received(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (_to.code.length > 0) {
            try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}
// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/utils/Base64.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: ForgeTokenV5.sol

// Contract based on https://docs.openzeppelin.com/contracts/4.x/erc721

pragma solidity ^0.8.4;





//-----------------------------------------------------------------------------
/// @title FORGE LAUNCH TOKEN
//-----------------------------------------------------------------------------
contract ForgeToken is Forge_ERC721, Ownable {

    struct TokenAttributes {
        uint16 xp;
        bool isSpecialVariant;
    }

    uint private constant _NUM_XP_VALUES = 10;
    // [0064 = 100, 01F4 = 500, 03E8 = 1000, 1388 = 5000, 1D4C = 7500, 2710 = 10000, 3A98 = 15000, 4E20 = 20000, 61A8 = 25000, 7FF8 = 32760]
    bytes32 private constant _XP_VALUES = 0x006401F403E813881D4C27103A984E2061A87FF8000000000000000000000000;
    // 02 = ~1%, 05 = ~2%, 0D = ~5%, 1A = ~10%, 33 = ~20%
    bytes32 private constant _XP_OCCURRENCE_RATES = 0x1A3333331A1A0D05050200000000000000000000000000000000000000000000;
    // 13/256 = ~5%
    uint8 private constant _SPECIAL_VARIANT_RATE = 13;

    address public minterAddress = 0xED605eA81904A0D7537767878ef94bFB343Fd8D5;
    string public baseURI = "https://forge.gg/";

    // May 23rd 2023 at 00:00:00 UTC
    uint256 public dropStartTime = 1684800000;
    uint256 public dropDuration = 48 hours;

    uint256 public supplyLimit = 100000;
    uint256 public reservedMints = 1000;

    // In order to ensure each owner only mints once per signature, each mint
    // is assigned a unique nonce. Subsequent mint attempts with the same
    // nonce will fail.
    mapping(uint256 => bool) public usedNonces;

    //-------------------------------------------------------------------------
    /// @dev This emits when XP is burned from a Forge Token
    //-------------------------------------------------------------------------
    event BurnXp(uint _tokenId, uint16 _amountBurned);

    constructor() Forge_ERC721("ForgeToken", "FORGE") {}

    //-------------------------------------------------------------------------
    /// @notice Sets a new address to be the Minter
    /// @dev Throws if sender is not the contract owner
    /// @param _newMinter The new address to be the Minter
    //-------------------------------------------------------------------------
    function setMinterAddress(address _newMinter) external onlyOwner {
        minterAddress = _newMinter;
    }

    //-------------------------------------------------------------------------
    /// @notice Replaces the current baseURL with a new URL
    /// @dev Throws if sender is not the contract owner
    /// @param _newAddress The new baseURL
    //-------------------------------------------------------------------------
    function setBaseURI(string calldata _newAddress) external onlyOwner {
        baseURI = _newAddress;
    }

    //-------------------------------------------------------------------------
    /// @notice Sets the start time where minting is allowed
    /// @dev Throws if sender is not the contract owner
    /// @param _dropStartTime The new timestamp in seconds
    //-------------------------------------------------------------------------
    function setDropStartTime(uint256 _dropStartTime) external onlyOwner {
        require(
            _dropStartTime >= block.timestamp,
            "Drop start time must be later than now"
        );
        dropStartTime = _dropStartTime;
    }

    //-------------------------------------------------------------------------
    /// @notice Sets the duration where minting is allowed
    /// @dev Throws if sender is not the contract owner
    /// @param _dropDuration The new duration in seconds
    //-------------------------------------------------------------------------
    function setDropDuration(uint256 _dropDuration) external onlyOwner {
        require (_dropDuration > 0, "Drop duration must be greater than zero");
        dropDuration = _dropDuration;
    }
    
    //-------------------------------------------------------------------------
    /// @notice Sets the supply limit to a higher number
    /// @dev Throws if `_newSupplyLimit` is less than current supply limit.
    ///  Throws if sender is not the contract owner.
    /// @param _newSupplyLimit The new supply limit
    //-------------------------------------------------------------------------
    function increaseSupplyLimit(uint256 _newSupplyLimit) external onlyOwner {
        require (
            block.timestamp <= dropStartTime + dropDuration,
            "Drop ended, increasing supply limit no longer allowed"
        );
        require (
            _newSupplyLimit > supplyLimit, 
            "New supply limit must be greater than previous supply limit"
        );
        supplyLimit = _newSupplyLimit;
    }

    //-------------------------------------------------------------------------
    /// @notice Mints a new Forge Badge for the sender.
    ///  Validates using a signature signed by the minter
    ///  The token ID of the new badge is determined by the totalSupply when
    ///  minted. Randomly rolls XP and specialVariant value.
    /// @dev Throws if there's a signer address mismatch
    /// @param _nonce A unique ID used to guard against double-mints
    /// @param _sig The signature of the recipient of the minted NFT
    //-------------------------------------------------------------------------
    function safeMint(uint256 _nonce, bytes memory _sig) external {
        require(block.timestamp >= dropStartTime, "Drop not started");
        require(block.timestamp <= dropStartTime + dropDuration, "Drop ended");
        require(
            _tokenData.length < supplyLimit - reservedMints,
            "Collection has minted out"
        );
        require(!usedNonces[_nonce], "Nonce already used");

        // validate message
        bytes32 message = _generateMessage(msg.sender, _nonce, address(this));
        require(
            _recoverSigner(message, _sig) == minterAddress,
            "Signer address mismatch"
        );

        // Roll attributes
        bytes32 randomSeed = keccak256(abi.encodePacked(msg.sender,_sig,_nonce));
        uint16 xpValue = _calculateXpValue(uint8(randomSeed[0]));
        bool isSpecialVariant = uint8(randomSeed[1]) < _SPECIAL_VARIANT_RATE;
        uint40 packedAttributes = (uint24(xpValue) << 8) + (isSpecialVariant ? 1 : 0);

        // mint the new token
        _safeMint(msg.sender, packedAttributes);
        usedNonces[_nonce] = true;
    }

    //-------------------------------------------------------------------------
    /// @notice Mints a new Forge Badge for a given address only by the minter.
    ///  The token ID of the new badge is determined by the totalSupply when
    ///  minted. Randomly rolls XP and specialVariant value.
    /// @dev Throws if there's a signer address mismatch
    /// @param _nonce A unique ID used to guard against double-mints
    /// @param _to address of the recipient of the minted NFT
    //-------------------------------------------------------------------------
    function safeMint(uint256 _nonce, address _to) external {
        require(msg.sender == minterAddress, "Only minterAddress can mint");
        require(reservedMints > 0, "No more tokens in reserve");
        require(!usedNonces[_nonce], "Nonce already used");

        // Roll attributes
        bytes32 randomSeed = keccak256(abi.encodePacked(block.timestamp,_to,_tokenData.length));
        uint16 xpValue = _calculateXpValue(uint8(randomSeed[0]));
        bool isSpecialVariant = uint8(randomSeed[1]) < _SPECIAL_VARIANT_RATE;
        uint40 packedAttributes = (xpValue << 8) + (isSpecialVariant ? 1 : 0);

        // mint the new token
        _safeMint(_to, packedAttributes);
        usedNonces[_nonce] = true;

        // only subtract from reserve if the supply limit has been reached
        if (_tokenData.length == supplyLimit - reservedMints) {
            --reservedMints;
        }
    }

    //-------------------------------------------------------------------------
    /// @notice Burns an existing Forge Badge. Its XP value will be emitted as
    ///  an event.
    /// @dev Throws if sender is not the owner of the specified token.
    /// @param _tokenId The ID of the token to burn
    //-------------------------------------------------------------------------
    function burn(uint _tokenId) external {
        require (
            msg.sender == _tokenData[_tokenId].tokenOwner,
            "Sender must own token to burn"
        );

        TokenAttributes memory attributes = tokenAttributes(_tokenId);

        uint16 amountBurned = attributes.xp;

        _burn(_tokenId);

        emit BurnXp(_tokenId, amountBurned);
    }

    //-------------------------------------------------------------------------
    /// @notice Gets the attributes of a given token
    /// @param _tokenId The ID of the token to query
    //-------------------------------------------------------------------------
    function tokenAttributes(uint _tokenId) 
        public
        view
        returns(TokenAttributes memory attributes)
    {
        uint tokenData = _tokenData[_tokenId].extraData;
        // extraData ends in 1 if the token is a special variant
        attributes.isSpecialVariant = tokenData % 2 == 1;
        attributes.xp = uint16(tokenData >> 8);
    }

    //-------------------------------------------------------------------------
    // Generates a URL containing metadata as data
    /// @dev This is an extremely costly function. Never call this as part of
    ///  a transaction.
    //-------------------------------------------------------------------------
    function tokenURI(uint _tokenId)
        public
        view
        override
        returns (string memory)
    {
        TokenAttributes memory tokenData = tokenAttributes(_tokenId);
        string memory name;
        string memory fireType;
        string memory imgUrl;
        string memory tokenId = Strings.toString(_tokenId);
        if (tokenData.isSpecialVariant) {
            name = "Freezin' Forge Badge";
            fireType = "Freezin'";
            imgUrl = string(abi.encodePacked(baseURI, "cold"));
        }
        else {
            name = "Flamin' Forge Badge";
            fireType = "Flamin'";
            imgUrl = string(abi.encodePacked(baseURI, "hot"));
        }
        bytes memory dataURI = abi.encodePacked(
            "{\n",
                "\t\"name\": \"", name, " #", tokenId, "\",\n",
                "\t\"description\": \"Lorem ipsum dolor sit amet esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat st laborum.\",\n",
                "\t\"image\": \"", imgUrl, "\",\n",
                "\t\"attributes\": [\n",
                    "\t\t{\n",
                        "\t\t\t\"trait_type\": \"Fire Type\",\n",
                        "\t\t\t\"value\":\"", fireType, "\"\n",
                    "\t\t}, {\n",
                        "\t\t\t\"display_type\": \"boost_number\",\n",
                        "\t\t\t\"trait_type\": \"XP\",\n",
                        "\t\t\t\"max_value\": 32760,\n",
                        "\t\t\t\"value\":", Strings.toString(tokenData.xp), "\n",
                    "\t\t}, {\n",
                        "\t\t\t\"display_type\": \"number\",\n",
                        "\t\t\t\"trait_type\": \"Limited Edition Number\",\n",
                        "\t\t\t\"value\":", tokenId, "\n",
                    "\t\t}\n",
                "\t]\n",
            "}"
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    //-------------------------------------------------------------------------
    // Takes a random number from 0 to 255 and returns an xp value
    //-------------------------------------------------------------------------
    function _calculateXpValue(uint8 _rand)
        private
        pure
        returns (uint16)
    {
        // get index from occurrence rates
        uint index;
        for (uint i = 0; i < _NUM_XP_VALUES; ++i) {
            if (_rand < uint8(_XP_OCCURRENCE_RATES[i])) {
                index = i;
                break;
            }
            _rand -= uint8(_XP_OCCURRENCE_RATES[i]);
        }

        // convert index into a bytes16 value
        uint16 xpValue = uint16(uint8(_XP_VALUES[index * 2])) << 8;
        xpValue += uint8(_XP_VALUES[index * 2 + 1]);

        return xpValue;
    }

    //-------------------------------------------------------------------------
    // Takes a message and signature and retrieves the signer address
    //-------------------------------------------------------------------------
    function _recoverSigner(bytes32 _message, bytes memory _sig)
        private
        pure
        returns (address)
    {
        require(_sig.length == 65, "Length of signature must be 65");

        // split signature
        uint8 v;
        bytes32 r;
        bytes32 s;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
            // second 32 bytes
            s := mload(add(_sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }

        // return the address from the given signature by calculating a
        // recovery function of ECDSA
        return ecrecover(_message, v, r, s);
    }

    //-------------------------------------------------------------------------
    // Builds an encoded message with a prefixed hash to mimic the behavior
    // of eth_sign.
    //-------------------------------------------------------------------------
    function _generateMessage(address _sender, uint _nonce, address _contract)
        private
        pure
        returns (bytes32 message)
    {
        message = keccak256(abi.encodePacked(_sender, _nonce, _contract));
        message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
    }
}