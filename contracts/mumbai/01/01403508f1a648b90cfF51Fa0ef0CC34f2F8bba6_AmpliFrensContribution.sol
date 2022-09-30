// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IAmpliFrensContribution} from "./interfaces/IAmpliFrensContribution.sol";
import {DataTypes} from "./libraries/types/DataTypes.sol";
import {PseudoModifier} from "./libraries/guards/PseudoModifier.sol";
import {ContributionLogic} from "./libraries/logic/ContributionLogic.sol";

/**
 * @title AmpliFrensContribution
 * @author Lucien Akchoté
 *
 * @notice Handle the different contributions interactions
 * @custom:security-contact [email protected]
 */
contract AmpliFrensContribution is IERC165, IAmpliFrensContribution {
    using Counters for Counters.Counter;

    Counters.Counter private _contributionsCounter;

    DataTypes.Contributions internal contributions;

    address public immutable facadeProxy;

    /// @dev Contract initialization with facade's proxy address precomputed
    constructor(address _facadeProxy) {
        facadeProxy = _facadeProxy;
        contributions.adminAddress = _facadeProxy;
    }

    /// @inheritdoc IAmpliFrensContribution
    function upvote(uint256 contributionId) external {
        PseudoModifier.isNotOutOfBounds(contributionId, _contributionsCounter);
        ContributionLogic.upvote(contributionId, contributions);
    }

    /// @inheritdoc IAmpliFrensContribution
    function downvote(uint256 contributionId) external {
        PseudoModifier.isNotOutOfBounds(contributionId, _contributionsCounter);
        ContributionLogic.downvote(contributionId, contributions);
    }

    /// @inheritdoc IAmpliFrensContribution
    function remove(uint256 contributionId) external {
        PseudoModifier.isNotOutOfBounds(contributionId, _contributionsCounter);
        ContributionLogic.remove(contributionId, contributions, _contributionsCounter);
    }

    /// @inheritdoc IAmpliFrensContribution
    function update(
        uint256 contributionId,
        DataTypes.ContributionCategory category,
        bytes32 title,
        string calldata url
    ) external {
        PseudoModifier.isNotOutOfBounds(contributionId, _contributionsCounter);
        ContributionLogic.update(contributionId, category, title, url, contributions);
    }

    /// @inheritdoc IAmpliFrensContribution
    function create(
        DataTypes.ContributionCategory category,
        bytes32 title,
        string calldata url
    ) external {
        ContributionLogic.create(category, title, url, contributions, _contributionsCounter);
    }

    /// @inheritdoc IAmpliFrensContribution
    function reset() external {
        PseudoModifier.addressEq(facadeProxy, msg.sender);
        ContributionLogic.reset(contributions, _contributionsCounter);
    }

    /// @inheritdoc IAmpliFrensContribution
    function getContributions() external view returns (DataTypes.Contribution[] memory) {
        return ContributionLogic.getContributions(contributions, _contributionsCounter);
    }

    /// @inheritdoc IAmpliFrensContribution
    function getContribution(uint256 contributionId) external view returns (DataTypes.Contribution memory) {
        PseudoModifier.isNotOutOfBounds(contributionId, _contributionsCounter);
        return ContributionLogic.getContribution(contributionId, contributions);
    }

    /// @inheritdoc IAmpliFrensContribution
    function topContribution() external view returns (DataTypes.Contribution memory) {
        return ContributionLogic.topContribution(contributions, _contributionsCounter);
    }

    /// @inheritdoc IAmpliFrensContribution
    function contributionsCount() external view returns (uint256) {
        return _contributionsCounter.current();
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure override(IERC165) returns (bool) {
        return type(IAmpliFrensContribution).interfaceId == interfaceId || type(IERC165).interfaceId == interfaceId;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {DataTypes} from "../libraries/types/DataTypes.sol";

/**
 * @title IAmpliFrensContribution
 * @author Lucien Akchoté
 *
 * @notice Handles the day to day operations for interacting with contributions
 */
interface IAmpliFrensContribution {
    /// @dev Events related to contributions interaction
    event Upvoted(address indexed from, uint256 indexed contributionId, uint256 timestamp);
    event Downvoted(address indexed from, uint256 indexed contributionId, uint256 timestamp);
    event Updated(address indexed from, uint256 indexed contributionId, uint256 timestamp);

    /**
     * @notice Upvote the contribution with id `contributionId`
     *
     * @param contributionId The contribution to upvote
     */
    function upvote(uint256 contributionId) external;

    /**
     * @notice Downvote the contribution with id `contributionId`
     *
     * @param contributionId The contribution id to downvote
     */
    function downvote(uint256 contributionId) external;

    /**
     * @notice Remove the contribution with id `contributionId`
     *
     * @param contributionId The contribution id to delete
     */
    function remove(uint256 contributionId) external;

    /**
     * @notice Update the contribution with id `contributionId`
     *
     * @param contributionId The contribution id to update
     * @param category The contribution's updated category
     * @param title The contribution's updated title
     * @param url The contribution's updated url
     */
    function update(
        uint256 contributionId,
        DataTypes.ContributionCategory category,
        bytes32 title,
        string calldata url
    ) external;

    /**
     * @notice Create a contribution
     *
     * @param category The contribution's category
     * @param title The contribution's title
     * @param url The contribution's url
     */
    function create(
        DataTypes.ContributionCategory category,
        bytes32 title,
        string calldata url
    ) external;

    /// @notice Reset the contributions
    function reset() external;

    /**
     * @notice Get the total contributions
     *
     * @return Total contributions of type `DataTypes.Contribution`
     */
    function getContributions() external view returns (DataTypes.Contribution[] memory);

    /**
     * @notice Get the contribution with id `contributionId`
     *
     * @param contributionId The id of the contribution to retrieve
     * @return Contribution with id `contributionId` of type `DataTypes.Contribution`
     */
    function getContribution(uint256 contributionId) external view returns (DataTypes.Contribution memory);

    /**
     * @notice Get the most upvoted contribution
     *
     * @return `DataTypes.Contribution`
     */
    function topContribution() external view returns (DataTypes.Contribution memory);

    /**
     * @notice Return the total number of contributions
     *
     * @return Number of contributions
     */
    function contributionsCount() external view returns (uint256);
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {Errors} from "../helpers/Errors.sol";

/**
 * @title ContributionLogic
 * @author Lucien Akchoté
 *
 * @notice A library that implements the logic of contribution related functions
 */
library ContributionLogic {
    using Counters for Counters.Counter;

    /**
     * @notice Ensure that `msg.sender` is the contribution's author or he's the admin
     *
     * @param admin The admin's address
     * @param author The contribution's author address
     */
    modifier isAuthorOrAdmin(address admin, address author) {
        if (author != msg.sender && admin != msg.sender) revert Errors.Unauthorized();
        _;
    }

    /**
     * @notice Ensure that `msg.sender` is not the contribution's author
     *
     *
     * @dev Prevent own upvoting/downvoting use cases
     * @param author The contribution's author address
     */
    modifier isNotAuthor(address author) {
        if (author == msg.sender) revert Errors.Unauthorized();
        _;
    }

    /**
     * @notice Ensure that `msg.sender` has not voted already for a contribution
     *
     * @dev Prevent botting contributions score
     * @param hasVoted Boolean that indicates if `msg.sender` has already voted or not
     */
    modifier hasNotVotedAlready(bool hasVoted) {
        if (hasVoted) revert Errors.AlreadyVoted();
        _;
    }

    /**
     * @notice Upvote the contribution with id `contributionId`
     *
     * @param contributionId The contribution's id
     * @param container Total contributions data
     */
    function upvote(uint256 contributionId, DataTypes.Contributions storage container)
        external
        isNotAuthor(container.contribution[contributionId].author)
        hasNotVotedAlready(container.upvoted[contributionId][msg.sender])
    {
        DataTypes.Contribution storage contribution = container.contribution[contributionId];
        contribution.votes++;
        container.upvoted[contributionId][msg.sender] = true;
        container.upvoterAddresses.push(msg.sender);
        container.upvotedIds.push(contributionId);
    }

    /**
     * @notice Downvote the contribution with id `contributionId`
     *
     * @param contributionId The contribution's id
     * @param container Total contributions data
     */
    function downvote(uint256 contributionId, DataTypes.Contributions storage container)
        external
        isNotAuthor(container.contribution[contributionId].author)
        hasNotVotedAlready(container.downvoted[contributionId][msg.sender])
    {
        DataTypes.Contribution storage contribution = container.contribution[contributionId];
        contribution.votes--;
        container.downvoted[contributionId][msg.sender] = true;
        container.downvoterAddresses.push(msg.sender);
        container.downvotedIds.push(contributionId);
    }

    /**
     * @notice Remove the contribution with id `contributionId`
     *
     * @param contributionId The contribution's id
     * @param container Total contributions data
     * @param _contributionsCounter Number of tokens emitted
     */
    function remove(
        uint256 contributionId,
        DataTypes.Contributions storage container,
        Counters.Counter storage _contributionsCounter
    ) external isAuthorOrAdmin(container.adminAddress, container.contribution[contributionId].author) {
        delete (container.contribution[contributionId]);
        _contributionsCounter.decrement();
    }

    /**
     * @notice Update the contribution with id `contributionId`
     *
     * @param contributionId The contribution's id
     * @param category The contribution's category
     * @param title The contribution's title
     * @param url The contribution's url
     * @param container Total contributions data
     */
    function update(
        uint256 contributionId,
        DataTypes.ContributionCategory category,
        bytes32 title,
        string calldata url,
        DataTypes.Contributions storage container
    ) external isAuthorOrAdmin(container.adminAddress, container.contribution[contributionId].author) {
        DataTypes.Contribution storage contribution = container.contribution[contributionId];

        contribution.category = category;
        if (bytes1(title) != 0x00) {
            contribution.title = title;
        }
        if (bytes(url).length > 0) {
            contribution.url = url;
        }
    }

    /**
     * @notice Create a contribution of type `DataTypes.Contribution`
     *
     * @param category The contribution's category
     * @param title The contribution's title
     * @param url The contribution's url
     * @param container Total contributions data
     * @param _contributionsCounter Number of tokens emitted
     */
    function create(
        DataTypes.ContributionCategory category,
        bytes32 title,
        string calldata url,
        DataTypes.Contributions storage container,
        Counters.Counter storage _contributionsCounter
    ) external {
        _contributionsCounter.increment();
        DataTypes.Contribution memory contribution = DataTypes.Contribution(
            msg.sender,
            category,
            true,
            uint64(block.timestamp),
            0,
            title,
            url
        );
        container.contribution[_contributionsCounter.current()] = contribution;
    }

    /**
     * @notice Get all the contributions
     *
     * @param container Total contributions data
     * @param _contributionsCounter Number of tokens emitted
     * @return Total contributions of type `DataTypes.Contribution`
     */
    function getContributions(DataTypes.Contributions storage container, Counters.Counter storage _contributionsCounter)
        external
        view
        returns (DataTypes.Contribution[] memory)
    {
        uint256 contributionsLength = _contributionsCounter.current();
        DataTypes.Contribution[] memory contributions = new DataTypes.Contribution[](contributionsLength);

        for (uint256 i = 0; i < contributionsLength; ++i) {
            contributions[i] = container.contribution[i];
        }

        return contributions;
    }

    /**
     * @notice Get the contribution with id `contributionId`
     *
     * @param contributionId The contribution's id
     * @param container Total contributions data
     * @return Contribution of type `DataTypes.Contribution`
     */
    function getContribution(uint256 contributionId, DataTypes.Contributions storage container)
        external
        view
        returns (DataTypes.Contribution memory)
    {
        return container.contribution[contributionId];
    }

    /**
     * @notice Get the most upvoted contribution
     *
     * @param container Total contributions data
     * @param _contributionsCounter Number of tokens emitted
     * @return Contribution of type `DataTypes.Contribution`
     */
    function topContribution(DataTypes.Contributions storage container, Counters.Counter storage _contributionsCounter)
        external
        view
        returns (DataTypes.Contribution memory)
    {
        int256 topVotes = 0;
        uint256 topContributionId = 0;
        uint256 contributionsLength = _contributionsCounter.current();

        for (uint256 i = 1; i <= contributionsLength; ++i) {
            if (int256(container.contribution[i].votes) > topVotes) {
                topContributionId = i;
                topVotes = container.contribution[i].votes;
            }
        }

        return container.contribution[topContributionId];
    }

    /**
     * @notice Reset all the contributions data
     *
     * @param container Total contributions data
     * @param _contributionsCounter Number of tokens emitted
     */
    function reset(DataTypes.Contributions storage container, Counters.Counter storage _contributionsCounter) external {
        uint256 contributionsLength = _contributionsCounter.current();
        uint256 upvotedIds = container.upvotedIds.length;
        uint256 downvotedIds = container.downvotedIds.length;
        uint256 upvoterAddresses = container.upvoterAddresses.length;
        uint256 downvoterAddresses = container.downvoterAddresses.length;

        for (uint256 i = 1; i <= contributionsLength; ++i) {
            delete container.contribution[i];
        }

        for (uint256 i = 1; i <= upvotedIds; ++i) {
            for (uint256 a = 0; a < upvoterAddresses; ++a) {
                if (container.upvoted[i][container.upvoterAddresses[a]]) {
                    delete container.upvoted[i][container.upvoterAddresses[a]];
                }
            }
        }
        for (uint256 i = 1; i <= downvotedIds; ++i) {
            for (uint256 a = 0; a < downvoterAddresses; ++a) {
                if (container.downvoted[i][container.downvoterAddresses[a]]) {
                    delete container.downvoted[i][container.downvoterAddresses[a]];
                }
            }
        }

        delete container.upvotedIds;
        delete container.upvoterAddresses;
        delete container.downvotedIds;
        delete container.downvoterAddresses;
        _contributionsCounter.reset();
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