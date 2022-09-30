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