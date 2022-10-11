// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC4671.sol";
import "./IRegistry.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/**
 * @notice Identity NTT - Non-Tradable Tokens Standard, aka badges or souldbound NFTs (EIP-4671)
 * A non-tradable token, or NTT, represents inherently personal possessions (material or immaterial),
 * such as university diplomas, online training certificates, government issued documents (national id,
 * driving license, visa, wedding, etc.), labels, and so on.
 *
 * @dev A NTT contract is seen as representing one type of certificate delivered by one authority.
 * For instance, one NTT contract for the French National Id, another for Ethereum EIP creators, and so on…
 *
 */
contract IdentityNTT is ERC4671 {
    // Create a new role identifier for the manager role
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");
    // Create a new role identifier for the team role
    bytes32 public constant TEAM_ROLE = keccak256("TEAM");
    IRegistry private _issuerRegistry;

    modifier onlyValidIssuer() {
        require(
            _issuerRegistry.isValid(msg.sender),
            "Unauthorized. Only registered issuers can execute this operation"
        );
        _;
    }

    constructor(
        IRegistry issuerRegistryAddress_,
        string memory name_,
        string memory symbol_
    ) ERC4671(name_, symbol_) {
        //TODO: invocar supportsInterface pra validar que endereço é um IRegistry
        _issuerRegistry = issuerRegistryAddress_;
        // // Grant the admin role to the publisher account
        // _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // // Grant the manager role to the informed manager account
        // _setupRole(MANAGER_ROLE, manager_);
        // // Sets MANAGER_ROLE as TEAM_ROLE's admin role.
        // _setRoleAdmin(TEAM_ROLE, MANAGER_ROLE);
    }

    /**
     * @notice Mint a new NTT credential
     * @param holder Address for whom to assign the token
     * @param data JSON with credential data in the format {atribute: "issuerSignedData",...}
     * @return tokenId Identifier of the minted token
     */
    function mint(address holder, string calldata data)
        external
        virtual
        onlyValidIssuer
        returns (TokenID tokenId)
    {
        //TODO: Se os dados das credenciais forem passados via JSON,
        // inviabiliza fazer uma validação no smart contract contra os subjects autorizados para o Issuer
        return _mint(holder, data);
    }

    /// @notice Mark the credential token as revoked
    /// @param tokenId Identifier of the token
    function revoke(TokenID tokenId) external virtual onlyValidIssuer {
        Token storage token = _getTokenOrRevert(tokenId);
        require(
            token.issuer == msg.sender,
            "Unauthorized. Only the token's Issuer is able to revoke it"
        );
        _revoke(token);
        emit Revoked(token.owner, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC4671)
        returns (bool)
    {
        return
            interfaceId == type(ERC4671).interfaceId ||
            interfaceId == type(IRegistry).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * Gets the credential metadata
     *
     * @param tokenId credential ID which metadata will be returned
     */
    function getCredential(TokenID tokenId)
        external
        view
        returns (Token memory)
    {
        return _getTokenOrRevert(tokenId);
    }

    /**
     * Return a list of owner's NTTs crendetial metadata
     *
     * @param owner  Address of owner/holder of NTTs
     * @return array of all owner's NTTs metadata
     */
    function getCredentials(address owner)
        external
        view
        returns (Token[] memory)
    {
        TokenID[] memory ownersTokensId = _indexedTokenIds[owner];
        Token[] memory result = new Token[](ownersTokensId.length);
        for (uint256 i = 0; i < ownersTokensId.length; i++) {
            result[i] = _tokens[ownersTokensId[i]];
        }
        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IRegistry {
    function isValid(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./IERC4671.sol";
import "./IERC4671Metadata.sol";
import "./IERC4671Enumerable.sol";

abstract contract ERC4671 is
    IERC4671,
    IERC4671Metadata,
    IERC4671Enumerable,
    ERC165
{
    // Token data
    struct Token {
        address issuer;
        address owner;
        string data;
        bool valid;
    }

    // Mapping from tokenId to token
    mapping(TokenID => Token) internal _tokens;

    // Mapping from owner to token ids
    mapping(address => TokenID[]) internal _indexedTokenIds;

    // Mapping from token id to index
    mapping(address => mapping(TokenID => uint256)) private _tokenIdIndex;

    // Mapping from owner to number of valid tokens
    mapping(address => uint256) private _numberOfValidTokens;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Total number of tokens emitted
    uint256 private _emittedCount;

    // Total number of token holders
    uint256 private _holdersCount;

    // Contract creator
    address private _creator;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _creator = msg.sender;
    }

    /// @notice Count all tokens assigned to an owner
    /// @param owner Address for whom to query the balance
    /// @return Number of tokens owned by `owner`
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC4671: address zero is not a valid owner"
        );
        return _indexedTokenIds[owner].length;
    }

    /// @notice Get owner of a token
    /// @param tokenId Identifier of the token
    /// @return Address of the owner of `tokenId`
    function ownerOf(TokenID tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return _getTokenOrRevert(tokenId).owner;
    }

    /// @notice Check if a token hasn't been revoked
    /// @param tokenId Identifier of the token
    /// @return True if the token is valid, false otherwise
    function isValid(TokenID tokenId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _getTokenOrRevert(tokenId).valid;
    }

    /// @notice Check if an address owns a valid token in the contract
    /// @param owner Address for whom to check the ownership
    /// @return True if `owner` has a valid token, false otherwise
    function hasValid(address owner)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _numberOfValidTokens[owner] > 0;
    }

    /// @return Descriptive name of the tokens in this contract
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @return An abbreviated name of the tokens in this contract
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /// @notice URI to query to get the token's metadata
    /// @param tokenId Identifier of the token
    /// @return URI for the token
    function tokenURI(TokenID tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        Token storage token = _getTokenOrRevert(tokenId);
        bytes memory baseURI = bytes(_baseURI());
        if (baseURI.length > 0) {
            return string(abi.encodePacked(baseURI, token.data));
        }
        return "";
    }

    /// @return emittedCount Number of tokens emitted
    function emittedCount() public view override returns (uint256) {
        return _emittedCount;
    }

    /// @return holdersCount Number of token holders
    function holdersCount() public view override returns (uint256) {
        return _holdersCount;
    }

    /// @notice Get the tokenId of a token using its position in the owner's list
    /// @param owner Address for whom to get the token
    /// @param index Index of the token
    /// @return tokenId of the token
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (TokenID)
    {
        TokenID[] storage ids = _indexedTokenIds[owner];
        require(index < ids.length, "ERC4671: Token does not exist");
        return ids[index];
    }

    /// @notice Get a tokenId by it's index, where 0 <= index < total()
    /// @param index Index of the token
    /// @return tokenId of the token
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (TokenID)
    {
        return TokenID.wrap(index);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC4671).interfaceId ||
            interfaceId == type(IERC4671Metadata).interfaceId ||
            interfaceId == type(IERC4671Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Prefix for all calls to tokenURI
    /// @return Common base URI for all token
    function _baseURI() internal pure virtual returns (string memory) {
        return "data:application/json;base64,";
    }

    /// @notice Mark the token as revoked
    /// @param token Token struct instance
    function _revoke(Token storage token) internal virtual {
        require(token.valid, "Token is already invalid");
        token.valid = false;
        assert(_numberOfValidTokens[token.owner] > 0);
        _numberOfValidTokens[token.owner] -= 1;
    }

    /// @notice Mint a new token
    /// @param owner Address for whom to assign the token
    /// @param data JSON with credential data in the format {atribute: "issuerSignedData",...}
    /// @return tokenId Identifier of the minted token
    function _mint(address owner, string calldata data)
        internal
        virtual
        returns (TokenID tokenId)
    {
        tokenId = TokenID.wrap(_emittedCount);
        _mintUnsafe(owner, tokenId, data, true);
        emit Minted(owner, tokenId);
        _emittedCount += 1;
    }

    /// @notice Mint a given tokenId
    /// @param owner Address for whom to assign the token
    /// @param tokenId Token identifier to assign to the owner
    /// @param data JSON with credential data in the format {atribute: "issuerSignedData",...}
    /// @param valid Boolean to assert of the validity of the token
    function _mintUnsafe(
        address owner,
        TokenID tokenId,
        string calldata data,
        bool valid
    ) internal {
        require(owner != address(0), "ERC4671: mint to the zero address");
        require(
            _tokens[tokenId].owner == address(0),
            "Cannot mint an assigned token"
        );
        if (_indexedTokenIds[owner].length == 0) {
            _holdersCount += 1;
        }
        _tokens[tokenId] = Token({
            issuer: msg.sender,
            owner: owner,
            data: data,
            valid: valid
        });
        _tokenIdIndex[owner][tokenId] = _indexedTokenIds[owner].length;
        _indexedTokenIds[owner].push(tokenId);
        if (valid) {
            _numberOfValidTokens[owner] += 1;
        }
    }

    /// @return True if the caller is the contract's creator, false otherwise
    function _isCreator() internal view virtual returns (bool) {
        return msg.sender == _creator;
    }

    /// @notice Retrieve a token or revert if it does not exist
    /// @param tokenId Identifier of the token
    /// @return The Token struct
    function _getTokenOrRevert(TokenID tokenId)
        internal
        view
        virtual
        returns (Token storage)
    {
        Token storage token = _tokens[tokenId];
        require(token.owner != address(0), "ERC4671: Token does not exist");
        return token;
    }

    /// @notice Remove a token
    /// @param tokenId Token identifier to remove
    function _removeToken(TokenID tokenId) internal virtual {
        Token storage token = _getTokenOrRevert(tokenId);
        _removeFromUnorderedArray(
            _indexedTokenIds[token.owner],
            _tokenIdIndex[token.owner][tokenId]
        );
        if (_indexedTokenIds[token.owner].length == 0) {
            assert(_holdersCount > 0);
            _holdersCount -= 1;
        }
        if (token.valid) {
            assert(_numberOfValidTokens[token.owner] > 0);
            _numberOfValidTokens[token.owner] -= 1;
        }
        delete _tokens[tokenId];
    }

    /// @notice Removes an entry in an array by its index
    /// @param array Array for which to remove the entry
    /// @param index Index of the entry to remove
    function _removeFromUnorderedArray(TokenID[] storage array, uint256 index)
        internal
    {
        require(index < array.length, "Trying to delete out of bound index");
        if (index != array.length - 1) {
            array[index] = array[array.length - 1];
        }
        array.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC4671 is IERC165 {

    type TokenID is uint256;


    /// Event emitted when a token `tokenId` is minted for `owner`
    event Minted(address owner, TokenID tokenId);

    /// Event emitted when token `tokenId` of `owner` is revoked
    event Revoked(address owner, TokenID tokenId);

    /// @notice Count all tokens assigned to an owner
    /// @param owner Address for whom to query the balance
    /// @return Number of tokens owned by `owner`
    function balanceOf(address owner) external view returns (uint256);

    /// @notice Get owner of a token
    /// @param tokenId Identifier of the token
    /// @return Address of the owner of `tokenId`
    function ownerOf(TokenID tokenId) external view returns (address);

    /// @notice Check if a token hasn't been revoked
    /// @param tokenId Identifier of the token
    /// @return True if the token is valid, false otherwise
    function isValid(TokenID tokenId) external view returns (bool);

    /// @notice Check if an address owns a valid token in the contract
    /// @param owner Address for whom to check the ownership
    /// @return True if `owner` has a valid token, false otherwise
    function hasValid(address owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC4671.sol";

interface IERC4671Metadata is IERC4671 {
    /// @return Descriptive name of the tokens in this contract
    function name() external view returns (string memory);

    /// @return An abbreviated name of the tokens in this contract
    function symbol() external view returns (string memory);

    /// @notice URI to query to get the token's metadata
    /// @param tokenId Identifier of the token
    /// @return URI for the token
    function tokenURI(TokenID tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC4671.sol";

interface IERC4671Enumerable is IERC4671 {
    /// @return emittedCount Number of tokens emitted
    function emittedCount() external view returns (uint256);

    /// @return holdersCount Number of token holders
    function holdersCount() external view returns (uint256);

    /// @notice Get the tokenId of a token using its position in the owner's list
    /// @param owner Address for whom to get the token
    /// @param index Index of the token
    /// @return tokenId of the token
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (TokenID);

    /// @notice Get a tokenId by it's index, where 0 <= index < total()
    /// @param index Index of the token
    /// @return tokenId of the token
    function tokenByIndex(uint256 index) external view returns (TokenID);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}