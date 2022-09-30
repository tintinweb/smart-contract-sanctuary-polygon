// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import {SBTLogic} from "./libraries/logic/SBTLogic.sol";
import {PseudoModifier} from "./libraries/guards/PseudoModifier.sol";
import {IAmpliFrensSBT} from "./interfaces/IAmpliFrensSBT.sol";
import {DataTypes} from "./libraries/types/DataTypes.sol";
import {TokenURI} from "./libraries/helpers/TokenURI.sol";
import {Status} from "./libraries/helpers/Status.sol";

/**
 * @title AmpliFrensSBT
 * @author Lucien Akchoté
 *
 * @notice This is the smart contract that handles the Soulbound Token minting
 * @dev Implements the EIP-4671 standard which is subject to change
 * @custom:security-contact [email protected]
 * @custom:oz-upgrades-unsafe-allow external-library-linking
 */
contract AmpliFrensSBT is IERC165, IAmpliFrensSBT {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /// @dev See struct's description above
    DataTypes.MintingInterval public mintingParams;

    /// @dev Number of tokens emitted
    Counters.Counter private _tokenIdCounter;
    /// @dev Number of unique holders of the token
    Counters.Counter private _holdersCount;

    /// @dev Maps token ids with the most upvoted contributions
    mapping(uint256 => DataTypes.Contribution) private _tokens;
    /// @dev Maps an EOA address with its contributions tokens
    mapping(address => uint256[]) private _tokensForAddress;
    /// @dev Counter for valid tokens for addresses
    mapping(address => uint256) private _validTokensForAddress;

    /// @dev Base Token URI for metadata
    string public baseURI;
    string public constant SBT_TOKEN_NAME = "AmpliFrens Contribution Award";
    string public constant SBT_TOKEN_SYMBOL = "AFRENCONTRIBUTION";

    address public immutable facadeProxy;

    /// @dev Contract initialization with facade's proxy address precomputed
    constructor(address _facadeProxy) {
        mintingParams.lastBlockTimestamp = block.timestamp;
        mintingParams.mintInterval = 1 days;
        facadeProxy = _facadeProxy;
    }

    /// @inheritdoc IAmpliFrensSBT
    function mint(DataTypes.Contribution calldata contribution) external {
        PseudoModifier.addressEq(facadeProxy, msg.sender);
        SBTLogic.mint(
            contribution,
            _tokens,
            _tokensForAddress,
            _validTokensForAddress,
            mintingParams,
            _tokenIdCounter,
            _holdersCount
        );
    }

    /// @inheritdoc IAmpliFrensSBT
    function revoke(uint256 tokenId) external {
        PseudoModifier.addressEq(facadeProxy, msg.sender);
        PseudoModifier.isNotOutOfBounds(tokenId, _tokenIdCounter);
        SBTLogic.revoke(tokenId, _tokens, _validTokensForAddress);
    }

    /**
     * @notice Sets the base URI `uri` for tokens, it should end with a "/"
     *
     * @param uri The base URI
     */
    function setBaseURI(string calldata uri) external {
        PseudoModifier.addressEq(facadeProxy, msg.sender);
        baseURI = uri;
    }

    /// @inheritdoc IAmpliFrensSBT
    function isMintingIntervalMet() external view returns (bool) {
        return SBTLogic.isMintingIntervalMet(mintingParams.lastBlockTimestamp, mintingParams.mintInterval);
    }

    /// @inheritdoc IAmpliFrensSBT
    function balanceOf(address owner) external view returns (uint256 balance) {
        return _validTokensForAddress[owner];
    }

    /// @inheritdoc IAmpliFrensSBT
    function ownerOf(uint256 tokenId) external view returns (address owner) {
        PseudoModifier.isNotOutOfBounds(tokenId, _tokenIdCounter);

        return SBTLogic.ownerOf(tokenId, _tokens);
    }

    /// @inheritdoc IAmpliFrensSBT
    function isValid(uint256 tokenId) external view returns (bool) {
        PseudoModifier.isNotOutOfBounds(tokenId, _tokenIdCounter);

        return SBTLogic.isValid(tokenId, _tokens);
    }

    /// @inheritdoc IAmpliFrensSBT
    function hasValid(address owner) external view returns (bool) {
        return _validTokensForAddress[owner] > 0;
    }

    /// @inheritdoc IAmpliFrensSBT
    function emittedCount() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /// @inheritdoc IAmpliFrensSBT
    function holdersCount() external view returns (uint256) {
        return _holdersCount.current();
    }

    /// @inheritdoc IAmpliFrensSBT
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        PseudoModifier.isNotOutOfBounds(index, _tokenIdCounter);

        return SBTLogic.tokenOfOwnerByIndex(owner, index, _tokensForAddress);
    }

    /// @inheritdoc IAmpliFrensSBT
    function tokenById(uint256 id) external view returns (DataTypes.Contribution memory) {
        PseudoModifier.isNotOutOfBounds(id, _tokenIdCounter);

        return SBTLogic.tokenById(id, _tokens);
    }

    /// @inheritdoc IAmpliFrensSBT
    function getStatus(address _address) external view returns (DataTypes.FrenStatus) {
        return Status.getStatus(_validTokensForAddress[_address]);
    }

    /**
     *  @notice Get the last block timestamp when minting occured
     * (if minting happened at least once, otherwise it is the contract's initialization timestamp)
     */
    function lastBlockTimestamp() external view returns (uint256) {
        return mintingParams.lastBlockTimestamp;
    }

    /**
     * @notice Gets the token URI for token with id `tokenId`
     *
     * @param tokenId The token id to retrieve the URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory uri) {
        PseudoModifier.isNotOutOfBounds(tokenId, _tokenIdCounter);

        uri = TokenURI.concatBaseURITokenIdJsonExt(tokenId, baseURI);
    }

    /// @inheritdoc IAmpliFrensSBT
    function name() external pure returns (string memory) {
        return SBT_TOKEN_NAME;
    }

    /// @inheritdoc IAmpliFrensSBT
    function symbol() external pure returns (string memory) {
        return SBT_TOKEN_SYMBOL;
    }

    /// @inheritdoc IAmpliFrensSBT
    function tokenByIndex(uint256 index) external pure returns (uint256) {
        return index; /// @dev index == tokenId
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure override(IERC165) returns (bool) {
        return type(IAmpliFrensSBT).interfaceId == interfaceId || type(IERC165).interfaceId == interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {Errors} from "../helpers/Errors.sol";

/**
 * @title SBTLogic
 * @author Lucien Akchoté
 *
 * @notice A library that implements the logic of soulbound token (SBT) related functions
 */
library SBTLogic {
    using Counters for Counters.Counter;

    /// @dev See `IAmpliFrensSBT` for descriptions
    event Minted(address indexed owner, uint256 indexed tokenId, uint256 timestamp);
    event Revoked(address indexed owner, uint256 indexed tokenId, uint256 timestamp);

    /**
     * @notice Mints the Soulbound Token to recipient `DataTypes.Contribution.author`
     *
     * @param contribution Contribution of the day data contained in struct `DataTypes.Contribution`
     * @param _tokens The total soulbound tokens mapped to contributions
     * @param _tokensForAddress The total tokens by addresses
     * @param _validTokensForAddress Counter of valid tokens for addresses
     * @param mintingParams Container with related minting parameters to comply with
     * @param _tokenIdCounter Number of tokens emitted
     * @param _holdersCounter Number of different token holders
     */
    function mint(
        DataTypes.Contribution calldata contribution,
        mapping(uint256 => DataTypes.Contribution) storage _tokens,
        mapping(address => uint256[]) storage _tokensForAddress,
        mapping(address => uint256) storage _validTokensForAddress,
        DataTypes.MintingInterval storage mintingParams,
        Counters.Counter storage _tokenIdCounter,
        Counters.Counter storage _holdersCounter
    ) external {
        if (!isMintingIntervalMet(mintingParams.lastBlockTimestamp, mintingParams.mintInterval)) {
            revert Errors.MintingIntervalNotMet();
        }

        _tokenIdCounter.increment();
        uint256 currentTokenId = _tokenIdCounter.current();
        _tokens[currentTokenId] = DataTypes.Contribution(
            contribution.author,
            contribution.category,
            true, /// @dev contribution is valid by default
            contribution.timestamp,
            contribution.votes,
            contribution.title,
            contribution.url
        );

        if (_tokensForAddress[contribution.author].length == 0) {
            _holdersCounter.increment();
        }

        _tokensForAddress[contribution.author].push(currentTokenId);
        _validTokensForAddress[contribution.author] += 1;
        mintingParams.lastBlockTimestamp = block.timestamp;

        emit Minted(contribution.author, currentTokenId, block.timestamp);
    }

    /**
     * @notice Revoke the token id `tokenId` in case of abuse or error
     *
     * @param tokenId The token ID to revoke
     * @param _tokens The total soulbound tokens mapped to contributions
     * @param _validTokensForAddress Counter of valid tokens for addresses
     */
    function revoke(
        uint256 tokenId,
        mapping(uint256 => DataTypes.Contribution) storage _tokens,
        mapping(address => uint256) storage _validTokensForAddress
    ) external {
        _tokens[tokenId].valid = false;
        _validTokensForAddress[_tokens[tokenId].author] -= 1;
        emit Revoked(_tokens[tokenId].author, tokenId, block.timestamp);
    }

    /**
     * @notice Get the corresponding token id at index `index` for address `owner`
     *
     * @param owner The address to query the token id for
     * @param index The index to retrieve
     * @param _tokensForAddress The total tokens by addresses
     * @return The token id
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index,
        mapping(address => uint256[]) storage _tokensForAddress
    ) external view returns (uint256) {
        uint256[] memory tokenIds = _tokensForAddress[owner];

        return tokenIds[index];
    }

    /**
     * @notice Get the owner of the token with id `tokenId`
     *
     * @param tokenId Identifier of the token
     * @param _tokens The total soulbound tokens mapped to contributions
     * @return Address of the owner of `tokenId`
     */
    function ownerOf(uint256 tokenId, mapping(uint256 => DataTypes.Contribution) storage _tokens)
        external
        view
        returns (address)
    {
        return _tokens[tokenId].author;
    }

    function isMintingIntervalMet(uint256 lastBlockTimestamp, uint256 mintInterval) internal view returns (bool) {
        return block.timestamp - lastBlockTimestamp > mintInterval;
    }

    /**
     * @notice Check if the token with id `tokenId` hasn't been revoked
     *
     * @param tokenId Identifier of the token
     * @param _tokens The total soulbound tokens mapped to contributions
     * @return True if the token is valid, false otherwise
     */
    function isValid(uint256 tokenId, mapping(uint256 => DataTypes.Contribution) storage _tokens)
        external
        view
        returns (bool)
    {
        return _tokens[tokenId].valid;
    }

    /**
     * @notice Get the contribution associated with the token of id `tokenId`
     *
     * @param tokenId Identifier of the token
     * @param _tokens The total soulbound tokens mapped to contributions
     * @return Contribution of type `DataTypes.Contribution`
     */
    function tokenById(uint256 tokenId, mapping(uint256 => DataTypes.Contribution) storage _tokens)
        external
        view
        returns (DataTypes.Contribution memory)
    {
        return _tokens[tokenId];
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import {Errors} from "../helpers/Errors.sol";

/**
 * @title PseudoModifier
 * @author Lucien Akchoté
 *
 * @notice Implements the (currently) unsupported functionality of using modifiers in libraries
 * @dev see https://github.com/ethereum/solidity/issues/12807
 */
library PseudoModifier {
    using Counters for Counters.Counter;

    /**
     * @notice Check address `expected` is equal to address `actual`
     *
     * @param expected The expected address
     * @param actual The actual address
     */
    function addressEq(address expected, address actual) external pure {
        if (expected != actual) revert Errors.Unauthorized();
    }

    /**
     * @dev Check if the index requested exist in counter
     *
     * @param index The id to verify existence for
     * @param counter The counter that holds enumeration
     */
    function isNotOutOfBounds(uint256 index, Counters.Counter storage counter) external view {
        if (index > counter.current() || index == 0) revert Errors.OutOfBounds();
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {DataTypes} from "../libraries/types/DataTypes.sol";

/**
 * @title IAmpliFrensSBT
 * @author Lucien Akchoté
 *
 * @notice Base interface for EIP-4671 Metadata
 *
 * More details on https://eips.ethereum.org/EIPS/eip-4671
 */
interface IAmpliFrensSBT {
    /**
     *  @notice Event emitted when a token `tokenId` is minted for `owner`
     */
    event Minted(address indexed owner, uint256 indexed tokenId, uint256 timestamp);

    /**
     *  @notice Event emitted when token `tokenId` of `owner` is revoked
     */
    event Revoked(address indexed owner, uint256 indexed tokenId, uint256 timestamp);

    /**
     * @notice Mints the Soulbound Token to recipient `DataTypes.Contribution.author`
     *
     * @param contribution Contribution of the day data contained in struct `DataTypes.Contribution`
     */
    function mint(DataTypes.Contribution calldata contribution) external;

    /**
     * @notice Revoke the token id `tokenId` in case of abuse or error
     *
     * @param tokenId The token ID to revoke
     */
    function revoke(uint256 tokenId) external;

    /**
     * @notice Count all valid tokens assigned to an owner
     *
     * @param owner Address for whom to query the balance
     * @return Number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Check if minting interval has been met
     *
     * @return True or false
     */
    function isMintingIntervalMet() external view returns (bool);

    /**
     * @notice Get the owner of the token with id `tokenId`
     *
     * @param tokenId Identifier of the token
     * @return Address of the owner of `tokenId`
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @notice Check if the token with id `tokenId` hasn't been revoked
     *
     * @param tokenId Identifier of the token
     * @return True if the token is valid, false otherwise
     */
    function isValid(uint256 tokenId) external view returns (bool);

    /**
     * @notice Check if an address owns a valid token in the contract
     *
     * @param owner Address for whom to check the ownership
     * @return True if `owner` has a valid token, false otherwise
     */
    function hasValid(address owner) external view returns (bool);

    /// @return emittedCount Number of tokens emitted
    function emittedCount() external view returns (uint256);

    /// @return holdersCount Number of token holders
    function holdersCount() external view returns (uint256);

    /**
     * @notice Get the id of a token using its position in the owner's list
     *
     * @param owner Address for whom to get the token
     * @param index Index of the token
     * @return tokenId of the token
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @notice Get the contribution associated with token of id `id`
     *
     * @param id The token id
     * @return Contribution of type `DataTypes.Contribution`
     */
    function tokenById(uint256 id) external view returns (DataTypes.Contribution memory);

    /**
     * @notice Get a tokenId by it's index, where 0 <= index < total()
     *
     * @param index Index of the token
     * @return tokenId of the token
     */
    function tokenByIndex(uint256 index) external view returns (uint256);

    /// @return Descriptive name of the tokens in this contract
    function name() external view returns (string memory);

    /// @return An abbreviated name of the tokens in this contract
    function symbol() external view returns (string memory);

    /**
     * @notice URI to query to get the token's metadata
     *
     * @param tokenId Identifier of the token
     * @return URI for the token
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @notice Get the contribution status for address `_address`
     *
     * @param _address The address to retrieve contribution status
     */
    function getStatus(address _address) external view returns (DataTypes.FrenStatus);

    /**
     * @notice Set the base URI `uri` for tokens, it should end with a "/"
     *
     * @param uri The base URI
     */
    function setBaseURI(string calldata uri) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title DataTypes
 * @author Lucien Akchoté
 *
 * @notice A standard library of data types used throughout AmpliFrens
 */
library DataTypes {
    /// @notice Contain the different statuses depending on tokens earnt
    enum FrenStatus {
        Anon,
        Degen,
        Pepe,
        Contributoor,
        Aggregatoor,
        Oracle
    }

    /// @notice Contain the different contributions categories
    enum ContributionCategory {
        NFT,
        Article,
        DeFi,
        Security,
        Thread,
        GameFi,
        Video,
        Misc
    }

    /**
     *  @notice Contain the basic information of a contribution
     *
     *  @dev Use tight packing to save up on storage cost
     *  4 storage slots used (string takes up 64 bytes or 2 slots in the storage)
     */
    struct Contribution {
        address author; /// @dev 20 bytes
        ContributionCategory category; /// @dev 1 byte
        bool valid; /// @dev 1 byte
        uint64 timestamp; /// @dev 8 bytes
        int16 votes; /// @dev 2 bytes
        bytes32 title; /// @dev 32 bytes
        string url; /// @dev 64 bytes
    }

    /// @notice Contain the basic information of a profile
    struct Profile {
        bytes32 lensHandle;
        bytes32 discordHandle;
        bytes32 twitterHandle;
        bytes32 username;
        bytes32 email;
        string websiteUrl;
        bool valid;
    }

    /// @notice These time-related variables are used in conjunction to determine when minting function can be called
    struct MintingInterval {
        uint256 lastBlockTimestamp;
        uint256 mintInterval;
    }

    /// @notice Contain contributions data
    struct Contributions {
        mapping(uint256 => DataTypes.Contribution) contribution;
        mapping(uint256 => mapping(address => bool)) upvoted;
        mapping(uint256 => mapping(address => bool)) downvoted;
        address[] upvoterAddresses;
        address[] downvoterAddresses;
        uint256[] upvotedIds;
        uint256[] downvotedIds;
        address adminAddress;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title TokenURI
 * @author Lucien Akchoté
 *
 * @notice A library that is used for reusable functions related to Token URI
 */
library TokenURI {
    using Strings for uint256;
    using Counters for Counters.Counter;

    /**
     * @notice Concatenate `baseURI` with the `tokenId` and ".json" string
     *
     * @param tokenId The token's id
     * @param baseURI The base URI to concatenate with
     * @return A string containing `baseURI` with the `tokenId` and ".json" as URI extension
     */
    function concatBaseURITokenIdJsonExt(uint256 tokenId, string calldata baseURI)
        external
        pure
        returns (string memory)
    {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"))
                : string(abi.encodePacked(Strings.toString(tokenId), ".json"));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title Statuses
 * @author Lucien Akchoté
 *
 * @notice Handles the statuses calculation
 */
library Status {
    function getStatus(uint256 totalTokens) external pure returns (DataTypes.FrenStatus) {
        if (totalTokens >= 34) {
            return DataTypes.FrenStatus.Oracle;
        }
        if (totalTokens >= 21) {
            return DataTypes.FrenStatus.Aggregatoor;
        }
        if (totalTokens >= 13) {
            return DataTypes.FrenStatus.Contributoor;
        }
        if (totalTokens >= 5) {
            return DataTypes.FrenStatus.Pepe;
        }
        if (totalTokens == 1) {
            return DataTypes.FrenStatus.Degen;
        }

        return DataTypes.FrenStatus.Anon;
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Errors
 * @author Lucien Akchoté
 *
 * @notice Regroup all the different errors used throughout AmpliFrens
 * @dev Use custom errors to save gas
 */
library Errors {
    /// @dev Generic errors
    error Unauthorized();
    error OutOfBounds();
    error NotImplemented();
    error AddressNull();

    /// @dev Profile errors
    error NoProfileWithAddress();
    error NoProfileWithSocialHandle();
    error EmptyUsername();
    error UsernameExist();
    error NotBlacklisted();

    /// @dev Contribution errors
    error AlreadyVoted();
    error NotAuthorOrAdmin();
    error NotAuthor();

    /// @dev NFT errors
    error MaxSupplyReached();
    error AlreadyOwnNft();

    /// @dev SBT errors
    error MintingIntervalNotMet();
}