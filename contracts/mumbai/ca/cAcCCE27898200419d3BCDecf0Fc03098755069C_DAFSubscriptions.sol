// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./DAFactoryI.sol";
import "./PreviousDAFactoryContractI.sol";
import "./PreviousDAFSubscriptionsContractI.sol";
import "./DAFLib.sol";

/// @title DAF (Decentralized Autonomous Factory) subscription token contract.
/// @notice This token is an NFT, and its possession is payable. The token corresponds to a subscription to the DAF and allows its holder to access the results of the curation actions performed by the DAF contributors.
contract DAFSubscriptions is ERC721, Ownable, Pausable {
    using SafeERC20 for IERC20;

    /// @notice Emitted when a new subscription token is minted.
    /// @param senderAddress Address of the new holder.
    /// @param tokenId ID of the token minted.
    event DAFSubscriptionTokenEmitted(address senderAddress, uint256 tokenId);

    /// @notice Emitted when a subscription token add subscription time on his token.
    /// @param senderAddress Address of the new holder.
    /// @param tokenId ID of the subscriber token.
    event DAFSubscriptionTokenAddSubscriptionTime(
        address senderAddress,
        uint256 tokenId
    );

    /// @notice Emitted when a subscription token is destroyed.
    /// @param punisherAddress Address address of a contributor token owner that invokes the operation.
    /// @param punishedTokenId ID of the subscription token to destroy.
    /// @param punisherTokenId ID of the contributor token to reward.
    event DestroyedDAFSubscriptionToken(
        address indexed punisherAddress,
        address senderContractAddress,
        uint256 indexed punishedTokenId,
        uint256 indexed punisherTokenId,
        uint256 rewardPointDeltaForDestruction
    );

    /// @notice Token maximum supply
    uint256 public immutable tokenMaxSupply;

    string public constant TOKEN_SCORE_IS_NOT_NULL = "TokenScoreIsNotNull";
    string public constant INVOKER_IS_NOT_TOKEN_OWNER =
        "Invoker is not token owner";
    string public constant INVOKER_MUST_BE_DAF_CONTRACT =
        "Invoker must be DAF contract";
    string public constant TOKEN_IS_NOT_IN_DEATH_STAGE =
        "The token is not in the death stage";
    string public constant ACCOUNT_MUST_HAVE_TOKEN =
        "AccountMustHaveSubscriptionToken";
    string public constant NUMBER_OF_TIME_ADDED_CANT_BE_ZERO =
        "CantAddZeroTime";

    /// @dev Holds the ID of the next token to be minted
    uint256 public nextId = 0;
    /// @notice Price for minting or adding time to a token
    uint256 public price;
    //// @notice The duration of a unit of subscription time, in seconds. It is the duration of the subscription of a new token.
    uint256 public subscriptionTimePeriodInSeconds;
    /// @notice Address of DAFactory contract
    DAFactoryContract public dafContract;
    DAFSubscriptionToken[] public dafSubscriberTokens;
    IERC20 private paymentTokenContract;
    /// @notice Owner to token mapping
    mapping(address => uint256) public ownerToToken;
    /// @notice Address of a previous or future version of the contract to use in an eventual migration process
    address public migrationVersionAddress;
    /// @notice Contract Migration state, if the contract should migrate
    MigrationState public migrationState;
    /// @notice Migration start time
    uint256 public pauseStartTime;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _price,
        uint256 _subscriptionTimePeriodInSeconds,
        uint256 _numberMaxOfTokens,
        address _paymentTokenContractAddress
    ) ERC721(_name, _symbol) Ownable() {
        price = _price;
        subscriptionTimePeriodInSeconds = _subscriptionTimePeriodInSeconds;
        tokenMaxSupply = _numberMaxOfTokens;
        require(
            _paymentTokenContractAddress != address(0),
            "PaymentContractAdressCantBeNull"
        );
        paymentTokenContract = IERC20(_paymentTokenContractAddress);
    }

    /// @notice Pause the contract
    function pause() external onlyOwner {
        pauseStartTime = block.timestamp;
        _pause();
    }

    /// @notice Unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Get the token ID of a token owner
    /// @param owner expected to be a token owner
    function getTokenIdOf(address owner) external view returns (uint256) {
        require(balanceOf(owner) > 0, DAFLib.ACCOUNT_MUST_HAVE_TOKEN);
        return ownerToToken[owner];
    }

    /// @notice Get the info of a token
    /// @param tokenId ID of the token
    /// @return Info of a token, of type `DAFSubscriptionToken`
    function getToken(uint256 tokenId)
        external
        view
        returns (DAFSubscriptionToken memory)
    {
        _requireMinted(tokenId);
        return dafSubscriberTokens[tokenId];
    }

    /// @notice Get the number of active tokens.
    /// @return The number of active tokens.
    function getTokensCount() external view returns (uint256) {
        uint256 tokenNumber = 0;
        for (uint256 i = 0; i < dafSubscriberTokens.length; i++) {
            if (_exists(i)) {
                tokenNumber++;
            }
        }
        return tokenNumber;
    }

    /// @notice Indicates whether or not an address has a valid token. An expired token is not considered as valid.
    /// @param _owner An address
    /// @return true if the address has a valid token, false else
    function isNftOwnerOfValidToken(address _owner) public view returns (bool) {
        if (
            _owner == address(0) ||
            balanceOf(_owner) == 0 ||
            !_exists(ownerToToken[_owner])
        ) {
            return false;
        }

        return !dateIsOver(ownerToToken[_owner]);
    }

    /// @notice Check in the current contract and in the previous version of the contract - if it exists, following an eventual migration -if an address has a valid token.
    /// An expired token is not considered as valid.
    /// @return true if the address has a valid token, false else.
    function isNftOwnerOfValidTokenFromCurrentOrMigratedVersion(address account)
        external
        view
        returns (bool)
    {
        // Check first in the current contract
        if (isNftOwnerOfValidToken(account)) {
            return true;
        }

        if (
            migrationVersionAddress == address(0) ||
            migrationState != MigrationState.Started
        ) {
            return false;
        }
        PreviousDAFSubscriptionsContractI migratedVersion = PreviousDAFSubscriptionsContractI(
                migrationVersionAddress
            );
        return migratedVersion.isNftOwnerOfValidToken(account);
    }

    /// @notice Returns the number of token left to mint. We have a total of `tokenMaxSupply` tokens.
    /// @return numberOfNFTsLeft The number of token left  to mint.
    function getNumberOfNFTsLeft()
        public
        view
        returns (uint256 numberOfNFTsLeft)
    {
        return tokenMaxSupply - this.getTokensCount();
    }

    /// @notice Mint a DAF subscriber token for the invoker of the function. This invocation is not free (`price` ).
    /// @notice A subscriber token gives access to the result of the curations performed by the DAF contributors on the information submitted by the core contributors.
    //slither-disable-next-line external-function https://github.com/crytic/slither/wiki/Detector-Documentation#public-function-that-could-be-declared-external
    function mint() public payable {
        require(
            address(dafContract) != address(0),
            "dafContractContractCantBeNull"
        );
        DAFLib.requireAccountNotToHaveToken(
            msg.sender,
            dafContract,
            DAFSubscriptionsContract(address(this))
        );
        require(getNumberOfNFTsLeft() > 0, DAFLib.TOKEN_MAX_SUPPLY_REACHED);

        // Get tokens from sender to the main contract
        paymentTokenContract.safeTransferFrom(
            msg.sender,
            address(dafContract),
            price
        );

        ownerToToken[msg.sender] = nextId;
        DAFSubscriptionToken memory newToken = DAFSubscriptionToken(
            msg.sender,
            block.timestamp + subscriptionTimePeriodInSeconds
        );
        if (nextId >= dafSubscriberTokens.length) {
            dafSubscriberTokens.push(newToken);
        } else {
            dafSubscriberTokens[nextId] = newToken;
        }
        _mint(msg.sender, nextId);
        emit DAFSubscriptionTokenEmitted(msg.sender, nextId);
        // compute nextId from actual array to fill the gaps
        uint256 newNextId = dafSubscriberTokens.length;
        for (uint256 i = 0; i < dafSubscriberTokens.length; i++) {
            if (!_exists(i)) {
                newNextId = i;
                break;
            }
        }
        nextId = newNextId;
    }

    /// @notice Allows you to add a subscription time unit to the token's subscription duration (`subscriptionTimePeriodInSeconds`).
    /// The function is not free (`price`).
    function addTime(uint256 numberOfDurationToAdd)
        external
        payable
        whenNotPaused
    {
        require(balanceOf(msg.sender) > 0, INVOKER_IS_NOT_TOKEN_OWNER);
        require(numberOfDurationToAdd > 0, NUMBER_OF_TIME_ADDED_CANT_BE_ZERO);

        uint256 newDateByAddition = dafSubscriberTokens[
            ownerToToken[msg.sender]
        ].dateOfDeath + numberOfDurationToAdd * subscriptionTimePeriodInSeconds;
        uint256 newDateFromNow = block.timestamp +
            numberOfDurationToAdd *
            subscriptionTimePeriodInSeconds;
        //slither-disable-next-line timestamp
        if (newDateFromNow > newDateByAddition) {
            dafSubscriberTokens[ownerToToken[msg.sender]]
                .dateOfDeath = newDateFromNow;
        } else {
            dafSubscriberTokens[ownerToToken[msg.sender]]
                .dateOfDeath = newDateByAddition;
        }
        emit DAFSubscriptionTokenAddSubscriptionTime(
            msg.sender,
            ownerToToken[msg.sender]
        );

        paymentTokenContract.safeTransferFrom(
            msg.sender,
            address(dafContract),
            price * numberOfDurationToAdd
        );
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setSubscriptionTimePeriodInSeconds(uint256 _time)
        external
        onlyOwner
    {
        subscriptionTimePeriodInSeconds = _time;
    }

    //// @dev Set the reference to the application main contract, DAFactory.
    /// @param _dafContract The address of DAFactory contract.
    function setDAFContract(address _dafContract) external onlyOwner {
        require(_dafContract != address(0), DAFLib.ZERO_ADDRESS_IS_FORBIDDEN);
        dafContract = DAFactoryContract(_dafContract);
    }

    //// @notice Allows to know if a token has expired.
    /// @param _tokenId ID of the subscription token.
    function dateIsOver(uint256 _tokenId) public view returns (bool) {
        //slither-disable-next-line timestamp
        return dafSubscriberTokens[_tokenId].dateOfDeath < block.timestamp;
    }

    /// @notice Burn a token that has expired.
    /// @param punishedTokenId ID of the token to burn
    function burnToken(
        address punisherAddress,
        uint256 punisherTokenId,
        uint256 punishedTokenId,
        uint256 rewardPointDeltaForDestruction
    ) external whenNotPaused {
        //slither-disable-next-line incorrect-equality: https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities
        require(
            msg.sender == address(dafContract),
            INVOKER_MUST_BE_DAF_CONTRACT
        );
        _requireMinted(punishedTokenId);
        require(dateIsOver(punishedTokenId), TOKEN_IS_NOT_IN_DEATH_STAGE);
        ownerToToken[ERC721.ownerOf(punishedTokenId)] = 0;
        _burn(punishedTokenId);
        nextId = punishedTokenId;
        delete dafSubscriberTokens[punishedTokenId];
        emit DestroyedDAFSubscriptionToken(
            punisherAddress,
            msg.sender,
            punishedTokenId,
            punisherTokenId,
            rewardPointDeltaForDestruction
        );
    }

    function getTimeLeftAsAString(uint256 _dateOfDeath)
        internal
        view
        returns (string memory)
    {
        uint256 numberOfDays = 0;
        uint256 numberOfHoursLeft = 0;
        //slither-disable-next-line timestamp
        if (_dateOfDeath > block.timestamp) {
            numberOfDays = ((_dateOfDeath - block.timestamp) / 86400);
            //slither-disable-next-line weak-prng: https://github.com/crytic/slither/wiki/Detector-Documentation#weak-prng
            numberOfHoursLeft =
                ((_dateOfDeath - block.timestamp) % 86400) /
                3600;
        }

        return
            string(
                abi.encodePacked(
                    numberOfDays >= 1
                        ? Strings.toString(numberOfDays)
                        : Strings.toString(numberOfHoursLeft),
                    numberOfDays >= 1 ? " Days" : " Hours"
                )
            );
    }

    function getImageURI(uint256 _dateOfDeath)
        internal
        view
        returns (string memory)
    {
        string memory svg = string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' width='50px' height='50px'><path fill='#fff' d='M1 1h350v300H1z'/><text x='50%' y='40%' text-anchor='middle' font-size='9' fill='#000'>",
                getTimeLeftAsAString(_dateOfDeath),
                "<tspan x='50%' y='70%'>Left</tspan></text></svg>"
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(string(abi.encodePacked(svg))))
                )
            );
    }

    /// @notice Overriding of ERC721 tokenURI function.
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(_tokenId);
        /* solhint-disable quotes */
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "TAF Subscriber","description": "thealphafactory.xyz", "image":"',
                                getImageURI(
                                    dafSubscriberTokens[_tokenId].dateOfDeath
                                ),
                                '","attributes": [{"trait_type": "time left", "value":"',
                                getTimeLeftAsAString(
                                    dafSubscriberTokens[_tokenId].dateOfDeath
                                ),
                                '"}]}'
                            )
                        )
                    )
                )
            );
        /* solhint-enable quotes */
    }

    /// @dev Know if a token exists
    /// @param tokenId ID of the token
    /// @return true if the token exists, false.
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /// @dev Implement _beforeTokenTransfer function from {ERC721URIStorage}
    /// @param from adress to transfer token from
    /// @param to adress to transfer token to
    /// @param tokenId ID of the token
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) internal override whenNotPaused {
        ownerToToken[to] = tokenId;
        ownerToToken[from] = 0;

        // In case of burn, we don't want to check
        if (to != address(0)) {
            DAFLib.requireAccountNotToHaveToken(
                to,
                dafContract,
                DAFSubscriptionsContract(address(this))
            );
        }
    }

    ///************************** Migration functions ***********************

    /**
     * @dev Override _requireNotPaused from {Pausable} with a more instructive message for the user.
     * Throws if the contract is paused.
     */
    function _requireNotPaused() internal view override(Pausable) {
        DAFLib.requireNotPaused(paused());
    }

    /// @notice Validates that all the conditions are met to perform a migration operation.
    modifier onlyIfMigrationStateIsValid() {
        //slither-disable-next-line incorrect-equality https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities
        bool migrationStarted = migrationState == MigrationState.Started;
        require(migrationStarted, DAFLib.MIGRATION_NOT_STARTED);
        bool newVersionAddressDefined = migrationVersionAddress != address(0);
        require(newVersionAddressDefined, DAFLib.MIGRATION_CONTRACT_UNDEFINED);
        _;
    }

    /// @notice Requires migration to be explicitly started
    modifier onlyWhenMigrationStarted() {
        //slither-disable-next-line incorrect-equality https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities
        bool migrationStarted = migrationState == MigrationState.Started;
        require(migrationStarted, DAFLib.MIGRATION_NOT_STARTED);
        _;
    }

    /// @notice Explicitly put the contract in migration state. Migration functions can only be invoked in this state.
    function startMigration() external onlyOwner {
        migrationState = MigrationState.Started;
    }

    /// @notice Ending the migration
    function finishMigration() external onlyOwner onlyWhenMigrationStarted {
        migrationState = MigrationState.Ended;
        migrationVersionAddress = address(0);
    }

    /// @notice Set the address of the new of previous version of the contract.
    /// @param _migrationVersionAddress Contract new or previous version address, in the context of a migration
    function setContractMigrationVersionAddress(
        address _migrationVersionAddress
    ) external onlyOwner {
        require(
            _migrationVersionAddress != address(0),
            DAFLib.ZERO_ADDRESS_IS_FORBIDDEN
        );
        //slither-disable-next-line events-access https://github.com/crytic/slither/wiki/Detector-Documentation#missing-events-access-control
        migrationVersionAddress = _migrationVersionAddress;
    }

    /// @notice Migrates the subscriber's token from the previous version of the contract being migrated to this new version, keeping the token data.
    function migrateTokenFromPreviousVersion()
        external
        onlyIfMigrationStateIsValid
    {
        DAFLib.requireAccountNotToHaveToken(
            msg.sender,
            dafContract,
            DAFSubscriptionsContract(address(this))
        );

        PreviousDAFSubscriptionsContractI previousVersion = PreviousDAFSubscriptionsContractI(
                migrationVersionAddress
            );

        // If the invoker is not a token  owner, this next call is supposed to fail
        uint256 tokenId = previousVersion.getTokenIdOf(msg.sender);
        DAFSubscriptionToken memory token = previousVersion.getToken(tokenId);

        ownerToToken[msg.sender] = nextId;

        if (nextId >= dafSubscriberTokens.length) {
            dafSubscriberTokens.push(token);
        } else {
            dafSubscriberTokens[nextId] = token;
        }

        // New date of death
        uint256 currentVersionPauseStartTime = previousVersion.pauseStartTime();
        uint256 dateOfDeathUpdated = token.dateOfDeath;
        int256 tokenTimeRemaining = int256(token.dateOfDeath) -
            int256(currentVersionPauseStartTime);
        if (tokenTimeRemaining > 0) {
            dateOfDeathUpdated = block.timestamp + uint256(tokenTimeRemaining);
        }

        _mint(msg.sender, nextId);
        // Update new token minted with migrated token info
        dafSubscriberTokens[nextId].dateOfDeath = dateOfDeathUpdated;

        emit DAFSubscriptionTokenEmitted(msg.sender, nextId);

        // compute nextId from actual array to fill the gaps
        uint256 newNextId = dafSubscriberTokens.length;
        for (uint256 i = 0; i < dafSubscriberTokens.length; i++) {
            if (!_exists(i)) {
                newNextId = i;
                break;
            }
        }
        nextId = newNextId;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.13;

/// @title Interface specifying the functions of DAFactory contract used in external invocations.
interface DAFactoryContract {
    /// @dev See {IERC721-balanceOf}.
    function balanceOf(address) external view returns (uint256);

    /// @dev See {DAFactory-getBalance}.
    function getBalance() external view returns (uint256);

    /// @dev See {DAFactory-isNftOwnerOfValidToken}.
    function isNftOwnerOfValidToken(address wallet)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.13;

import "./DAFLib.sol";

/// @title Interface specifying some functions of the previous deployed version of DAFSubscriptions contract,with possible differences with the new version to be deployed.
/// This interface is intended to be used mainly in the context of a migration operation.
interface PreviousDAFSubscriptionsContractI {
    /// @dev See {DAFSubscriptions-balanceOf}.
    function balanceOf(address) external view returns (uint256);

    /// @dev See {DAFSubscriptions-mint}.
    function mint() external;

    /// @dev See {DAFSubscriptions-setDAFContract}.
    function setDAFContract(address _dafContract) external;

    /// @dev See {DAFSubscriptions-isNftOwnerOfValidToken}.
    function isNftOwnerOfValidToken(address wallet)
        external
        view
        returns (bool);

    /// @dev See {DAFSubscriptions-exists}.
    function exists(uint256 tokenId) external view returns (bool);

    /// @dev See {DAFSubscriptions-burnToken}.
    function burnToken(
        address punisherAddress,
        uint256 _tokenId,
        uint256 rewardPointDeltaForDestruction
    ) external;

    /// @dev See {DAFSubscriptions-setContractMigrationVersionAddress}.
    function setContractMigrationVersionAddress(address newVersionAddress)
        external;

    /// @dev See {DAFSubscriptions-getTokenIdOf}.
    function getTokenIdOf(address owner) external view returns (uint256);

    /// @dev See {DAFSubscriptions-getToken}.
    function getToken(uint256 tokenId)
        external
        view
        returns (DAFSubscriptionToken memory);

    /// @dev See {DAFSubscriptions-startMigration}.
    function startMigration() external;

    /// @dev See {DAFSubscriptions-finishMigration}.
    function finishMigration() external;

    /// @dev See {DAFSubscriptions-migrationState}.
    function migrationState() external view returns (MigrationState);

    /// @dev See {DAFSubscriptions-pauseStartTime}.
    function pauseStartTime() external view returns (uint256);

    /// @dev See {DAFSubscriptions-paused}.
    function paused() external view returns (bool);

    /// @dev See {DAFSubscriptions-pause}.
    function pause() external;

    /// @dev See {DAFSubscriptions-unpause}.
    function unpause() external;

    /// @dev See {DAFSubscriptions-addTime}.
    function addTime(uint256 numberOfDurationToAdd) external;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.13;

import "./DAFLib.sol";

/// @title Interface specifying some functions of the previous deployed version of DAFactory contract,with possible differences with the new version to be deployed.
/// This interface is intended to be used mainly in the context of a migration operation.
interface PreviousDAFactoryContractI {
    /// @dev See {DAFactory-setDAFSubscriptionsContract}.
    function setDAFSubscriptionsContract(
        address dafSubscriptionsContractAddress
    ) external;

    /// @dev See {DAFactory-getQuestion}.
    function getQuestion(string calldata id)
        external
        view
        returns (GetQuestionPageItemQueryResult memory);

    /// @dev See {DAFactory-mint}.
    function mint() external;

    /// @dev See {DAFactory-createQuestion}.
    function createQuestion(
        string calldata questionId,
        string[] calldata answersIds,
        uint256 timeToVote
    ) external;

    /// @dev See {DAFactory-vote}.
    function vote(string calldata questionId, uint256 answerIdIndex) external;

    /// @dev See {DAFactory-vote}.
    function totalOfPoints() external view returns (uint256);

    /// @dev See {IERC721-balanceOf}.
    function balanceOf(address) external view returns (uint256);

    /// @dev See {DAFactory-getBalance}.
    function getBalance() external view returns (uint256);

    /// @dev See {DAFactory-isNftOwnerOfValidToken}.
    function isNftOwnerOfValidToken(address wallet)
        external
        view
        returns (bool);

    /// @dev See {DAFactory-exists}.
    function exists(uint256 tokenId) external view returns (bool);

    /// @dev See {DAFactory-isCoreMember}.
    function isCoreMember(address account) external view returns (bool);

    /// @dev See {DAFactory-getTokenIdOf}.
    function getTokenIdOf(address owner) external view returns (uint256);

    /// @dev See {DAFactory-getToken}.
    function getToken(uint256 tokenId)
        external
        view
        returns (DAFContributorToken memory);

    function punishInactiveToken(
        uint256 punishedTokenId,
        string calldata questionId
    ) external;

    /// @dev See {DAFactory-burnContributorTokenForMigration}.
    function burnContributorTokenForMigration(uint256 tokenId) external;

    /// @dev See {DAFactory-burnExpiredSubscriptionToken}.
    function burnExpiredSubscriptionToken(uint256 _subscribedTokenId) external;

    /// @dev See {DAFactory-startMigration}.
    function startMigration() external;

    /// @dev See {DAFactory-finishMigration}.
    function finishMigration() external;

    /// @notice Set the address of the new version of the contract.
    /// @param newVersionAddress Contract new version address
    function setContractMigrationVersionAddress(address newVersionAddress)
        external;

    /// @dev See {DAFactory-getNewVersionAddress}.
    function getNewVersionAddress() external view returns (address);

    /// @dev See {DAFactory-migrationState}.
    function migrationState() external view returns (MigrationState);

    /// @dev See {DAFactory-pauseStartTime}.
    function pauseStartTime() external view returns (uint256);

    /// @dev See {DAFactory-paused}.
    function paused() external view returns (bool);

    /// @dev See {DAFactory-pause}.
    function pause() external;

    /// @dev See {DAFactory-unpause}.
    function unpause() external;

    /// @dev See {DAFactory-upgrade}.
    function upgrade() external;

    /// @dev See {DAFactory-gracefulTokenPunishmentTimePeriod}.
    function gracefulTokenPunishmentTimePeriod()
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IntegerWrapper.sol";
import "./DAFactoryI.sol";
import "./DAFSubscriptionsI.sol";

/// @dev Possible roles of DAF tokens.
enum Role {
    Contributor,
    Core
}

/// @dev Possible states of a token in a voting process
enum TokenVotingState {
    Pending,
    Voted,
    Punished
}

/// @dev Data structure of a question
struct QuestionStruct {
    string baseQuestion;
    string id;
    string[] answersIds;
    uint256[] votesOfEachAnswers;
    uint256 dateOfCreation;
    uint256 timeToVote;
    uint256[] bestAnswers;
    uint256 minimumVotesForConsensus;
    bool reachedConsensus;
}

enum MigrationState {
    NotStarted,
    Started,
    Ended
}

/// @dev Data structure containing all state variables of DAFactory contract.
/// It is an approach inspired by the AppStorage pattern
struct DAFStorage {
    /// @notice Reference to DAFSubscriptions external interface
    DAFSubscriptionsContract dafSubscriptionsContract;
    /// @notice Starting score (number of points) of a new token. Also score assigned to a dead token revived (against payment)
    uint256 startScore;
    /// @notice Holds the ID of the next token to be minted
    uint256 nextId;
    /// @notice Price for reviving a token that has no more points (in wei)
    uint256 revivePrice;
    /// @notice Grace period (in second)  granted to a token which has just had zero point before authorizing its destruction by other tokens.
    uint256 gracefulTokenPunishmentTimePeriod;
    /// @notice Number of points required to upgrade a contributor token to core contributor
    uint256 scoreToUpgrade;
    /// @notice Holds the total number of points generated by the efforts of the DAF contributors
    IntegerWrapper.Integer totalOfPoints;
    /// @notice List of information for each contributor token
    DAFContributorToken[] dafContributorTokens;
    /// @notice Owner to token mapping
    mapping(address => uint256) ownerToToken;
    /// @notice Number of penalty points for a punished token
    uint256 punishmentPointDelta;
    /// @notice Reward in points of a token for a voting action
    uint256 rewardPointDeltaForVoting;
    /// @notice Reward in number of points of a token for a punishment action on another token
    uint256 rewardPointDeltaForPunishment;
    /// @notice Reward in points of a token for the destruction of a token which does not have any more points
    uint256 rewardPointDeltaForDestruction;
    /// @notice Minimum time required between the creation of a new question and the end of the vote. Expressed in seconds.
    uint256 minimumTimeToVote;
    /// @notice The generic question used to introduce the subject of each vote
    string baseQuestion;
    /// @notice The generic choices proposed as possible answers to the voting questions. For now: yes and no
    string[] baseAnswers;
    /// @notice The IDs of all the questions created
    string[] allQuestionIds;
    /// @notice Question info by question ID mapping
    mapping(string => QuestionStruct) questionsById;
    /// @notice Tokens voting states for a question  by the question ID
    mapping(string => mapping(uint256 => TokenVotingState)) tokensState;
    /// @notice Address of a previous or future version of the contract to use in an eventual migration process
    address migrationVersionAddress;
    /// @notice Contract Migration state, if the contract should migrate
    MigrationState migrationState;
    /// @notice Contract pause start time
    uint256 pauseStartTime;
}

/// @dev Result of getQuestionsPage function
struct GetQuestionPageResult {
    GetQuestionPageItemQueryResult[] items;
    uint256 numberOfPages;
}

/// @dev Structure containing the result of a query for questions
struct GetQuestionPageItemQueryResult {
    QuestionStruct question;
    bool invokerVotedOn;
}

/// @dev Structure containing the information of a contributor token
struct DAFContributorToken {
    uint256 id;
    address owner;
    uint256 score;
    uint256 dateOfCreation;
    uint256 dateOfDeath;
    Role role;
}

struct DAFSubscriptionToken {
    address owner;
    uint256 dateOfDeath;
}

/// @title  DAF library.
library DAFLib {
    using IntegerWrapper for IntegerWrapper.Integer;
    using SafeERC20 for IERC20;

    string public constant TOKEN_SCORE_MUST_NOT_BE_NULL =
        "TokenScoreMustNotBeNull";
    string public constant TOKEN_MUST_NOT_HAVE_VOTED_YET =
        "TokenMustNotHaveVotedYet";
    string public constant TOKEN_OWNER_CANNOT_PUNISH_HIMSELF =
        "TokenOwnerCannotPunishHimself";
    string public constant NEED_VALID_TOKEN = "NeedValidToken";
    string public constant TOKEN_CREATED_AFTER_QUESTION_CREATION =
        "TokenCreatedAfterQuestionCreation";
    string public constant QUESTION_VOTING_TIME_IS_NOT_OVER =
        "QuestionVotingTimeIsNotOver";
    string public constant QUESTION_VOTING_TIME_IS_OVER =
        "QuestionVotingTimeIsOver";
    string public constant QUESTION_DOES_NOT_EXIST = "QuestionDoesNotExist";
    string public constant QUESTION_ALREADY_EXISTS = "QuestionAlreadyExists";

    string public constant ACCOUNT_MUST_HAVE_TOKEN = "AccountMustHaveToken";
    string public constant TOKEN_SCORE_IS_NOT_NULL = "TokenScoreIsNotNull";
    string public constant NOT_ENOUGH_FUNDS_TO_REVIVE_TOKEN =
        "NotEnoughFundsToReviveToken";
    string public constant TOKEN_REVIVE_TIME_IS_OVER = "TokenReviveTimeIsOver";
    string public constant TOKEN_MAX_SUPPLY_REACHED = "TokenMaxSupplyReached";

    string public constant ACCOUNT_MUST_NOT_HAVE_CONTRIBUTOR_TOKEN =
        "AccountMustNotHaveContributorToken";
    string public constant ACCOUNT_MUST_NOT_HAVE_SUBSCRIBER_TOKEN =
        "AccountMustNotHaveSubscriberToken";
    string public constant INVALID_START_SCORE_VALUE = "InvalidStartScoreValue";
    string public constant INVALID_UPGRADE_SCORE = "InvalidUpgradeScore";
    string public constant CORE_MEMBER_CANT_UPGRADE =
        "CoreMemberCantUpgradeAgain";
    string public constant VOTING_TIME_LIMIT_LT_MIN_TIME_REQUIRED =
        "TheVotingTimeLimitIsLessThanTheMinimumRequired";
    string public constant RESTRICTED_TO_QUESTION_PUBLISHERS =
        "RestrictedToQuestionPublishers";
    string public constant AT_LEAST_ONE_ANSWER_IS_REQUIRED =
        "AtLeastOneAnswerRequired";

    string public constant TOKEN_IS_NOT_IN_DEATH_STAGE =
        "TokenIsNotInDeathStage";
    string public constant ZERO_ADDRESS_IS_FORBIDDEN = "ZeroAddressIsForbidden";
    string public constant INSUFFICIENT_SCORE_TO_PROCEED_WITH_UPGRADE =
        "InsufficientScoreToUpgrade";
    string public constant INVOKER_IS_NOT_TOKEN_OWNER =
        "InvokerIsNotTokenOwner";
    string public constant INVALID_TOKEN_ID = "ERC721: invalid token ID";

    string public constant NOT_ENOUGH_POINTS = "NotEnoughPoints";
    string public constant CANT_WITHDRAW_NEGATIVE_OR_ZERO =
        "CantWithdrawInvalidAmount";
    string public constant CANT_WITHDRAW_LESS_MIN_SCORE =
        "CantWithdrawLessThanTheMinimumScore";
    string public constant SUBSCRIBERS_SHOULD_GET_QUESTIONS_FROM_BACKEND =
        "SubscribersGetQuestionsFromBackend";

    string public constant MIGRATION_INVOKER_IS_NOT_NEW_VERSION =
        "InvokerIsNotNewVersion";
    string public constant MIGRATION_CONTRACT_UNDEFINED =
        "MigrationContractUndefined";
    string public constant MIGRATION_NOT_STARTED = "MigrationNotStarted";

    string public constant CONTRACT_PAUSED =
        "The contract is paused, either for an emergency procedure or for a planned operation. Please contact the authors of the contract for more information";

    // Sharing event with DAFactory here in order to emit event from DAFLib
    // https://blog.aragon.org/library-driven-development-in-solidity-2bebcaf88736/#events-and-libraries
    event ConsensusReached(string questionId, string consensusAnswerId);

    function getCurrentMinimumVoteNumberToShowToSubscriber(
        uint256 validTokensNumber
    ) public pure returns (uint256 voteNumber) {
        uint256 halfInt = validTokensNumber / 2;

        return halfInt + 1;
    }

    /// @notice Get a question from its id.
    /// @dev The other arguments come from the contract that invokes this library.
    /// @return result The question whose index is passed as argument.
    function getQuestion(
        QuestionStruct storage question,
        bool isValidContributor,
        bool isValidSubscriber,
        uint256 tokenId,
        mapping(string => mapping(uint256 => TokenVotingState))
            storage tokensState
    ) public view returns (GetQuestionPageItemQueryResult memory result) {
        require(bytes(question.id).length != 0, QUESTION_DOES_NOT_EXIST);
        result.invokerVotedOn =
            isValidContributor &&
            tokensState[question.id][tokenId] == TokenVotingState.Voted;

        // slither-disable-next-line timestamp
        bool isAllowedToSeeVotes = isValidContributor &&
            (question.dateOfCreation + question.timeToVote < block.timestamp || // Voting is over
                tokensState[question.id][tokenId] == TokenVotingState.Voted || // Has voted
                tokensState[question.id][tokenId] == TokenVotingState.Punished);
        // Has been punished

        if (isValidSubscriber || isAllowedToSeeVotes) {
            result.question = question;
        } else {
            result.question = QuestionStruct(
                question.baseQuestion,
                question.id,
                question.answersIds,
                new uint256[](question.answersIds.length),
                question.dateOfCreation,
                question.timeToVote,
                new uint256[](question.answersIds.length),
                question.minimumVotesForConsensus,
                question.reachedConsensus
            );
        }
    }

    /// @notice See {DAFactory-getTokensState}.
    function getTokensState(
        DAFContributorToken[] storage dafContributorTokens,
        mapping(string => mapping(uint256 => TokenVotingState))
            storage tokensState,
        string calldata questionId
    ) external view returns (TokenVotingState[] memory states) {
        states = new TokenVotingState[](dafContributorTokens.length);
        for (uint256 i = 0; i < dafContributorTokens.length; i++) {
            states[i] = tokensState[questionId][i];
        }
        return states;
    }

    function addPoints(
        DAFContributorToken storage token,
        uint256 _nbOfPoints,
        IntegerWrapper.Integer storage totalOfPoints
    ) public {
        token.score = token.score + _nbOfPoints;
        totalOfPoints.increment(_nbOfPoints);
    }

    function addPoints(DAFContributorToken storage token, uint256 _nbOfPoints)
        public
    {
        token.score = token.score + _nbOfPoints;
    }

    /// @notice See {DAFactory-burnContributorToken}.
    function burnContributorToken(
        DAFContributorToken storage targetToken,
        DAFContributorToken storage invokerToken,
        uint256 gracefulTokenPunishmentTimePeriod,
        uint256 rewardPointDeltaForDestruction,
        IntegerWrapper.Integer storage totalOfPoints,
        mapping(address => uint256) storage ownerToToken,
        MigrationState migrationState
    ) public {
        if (migrationState != MigrationState.Started) {
            require(targetToken.score == 0, DAFLib.TOKEN_SCORE_IS_NOT_NULL);
            // slither-disable-next-line timestamp
            require(
                targetToken.dateOfDeath + gracefulTokenPunishmentTimePeriod <
                    block.timestamp,
                DAFLib.TOKEN_IS_NOT_IN_DEATH_STAGE
            );
        }
        require(
            targetToken.owner != address(0),
            DAFLib.ZERO_ADDRESS_IS_FORBIDDEN
        );
        ownerToToken[targetToken.owner] = 0;
        targetToken.owner = address(0);
        addPoints(invokerToken, rewardPointDeltaForDestruction, totalOfPoints);
    }

    /// @notice See {DAFactory-burnExpiredSubscriptionToken}.
    function burnExpiredSubscriptionToken(
        address punisherAddress,
        DAFContributorToken[] storage dafContributorTokens,
        uint256 punisherTokenId,
        uint256 subscribedTokenId,
        IntegerWrapper.Integer storage totalOfPoints,
        uint256 rewardPointDeltaForDestruction,
        DAFSubscriptionsContract dafSubscriptionsContract
    ) external {
        requireTokenToBeAlive(dafContributorTokens[punisherTokenId]);
        addPoints(
            dafContributorTokens[punisherTokenId],
            rewardPointDeltaForDestruction,
            totalOfPoints
        );
        dafSubscriptionsContract.burnToken(
            punisherAddress,
            punisherTokenId,
            subscribedTokenId,
            rewardPointDeltaForDestruction
        );
    }

    /// @notice See {DAFactory-createQuestion and DAFactory-createQuestionAsOwner}.
    function createQuestion(
        // slither-disable-next-line timestamp
        string memory baseQuestionToSave,
        string memory questionId,
        string[] calldata answersIds,
        uint256 timeToVote,
        uint256 minimumTimeToVote,
        mapping(string => QuestionStruct) storage questionsById,
        DAFContributorToken[] storage dafContributorTokens,
        string[] storage allQuestions
    ) internal {
        // slither-disable-next-line timestamp
        require(
            bytes(questionsById[questionId].id).length == 0,
            QUESTION_ALREADY_EXISTS
        );
        require(
            timeToVote >= minimumTimeToVote,
            DAFLib.VOTING_TIME_LIMIT_LT_MIN_TIME_REQUIRED
        );
        require(answersIds.length > 1, DAFLib.AT_LEAST_ONE_ANSWER_IS_REQUIRED);

        uint256 numberOfValidTokens = 0;
        for (uint256 i = 0; i < dafContributorTokens.length; i++) {
            if (dafContributorTokens[i].score > 0) {
                numberOfValidTokens += 1;
            }
        }

        // solhint-disable not-rely-on-time
        questionsById[questionId] = QuestionStruct(
            baseQuestionToSave,
            questionId,
            answersIds,
            new uint256[](answersIds.length),
            block.timestamp,
            timeToVote,
            new uint256[](answersIds.length),
            getCurrentMinimumVoteNumberToShowToSubscriber(numberOfValidTokens),
            false
        );
        allQuestions.push(questionId);
    }

    /// @notice To know if an address has or not a token, of contributor or subscriber type
    /// @param _account An Address
    /// @param daFactoryContract DAFactoryContract reference
    /// @param dafSubscriptionsContract DAFSubscriptionsContract reference
    function requireAccountNotToHaveToken(
        address _account,
        DAFactoryContract daFactoryContract,
        DAFSubscriptionsContract dafSubscriptionsContract
    ) external view {
        // slither-disable-next-line incorrect-equality: https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities
        require(
            daFactoryContract.balanceOf(_account) == 0,
            ACCOUNT_MUST_NOT_HAVE_CONTRIBUTOR_TOKEN
        );
        // slither-disable-next-line incorrect-equality: https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities
        require(
            dafSubscriptionsContract.balanceOf(_account) == 0,
            ACCOUNT_MUST_NOT_HAVE_SUBSCRIBER_TOKEN
        );
    }

    function getQuestionPageArgs(
        uint256 pageNumber,
        uint256 pageSize,
        uint256 numberOfQuestions
    ) public pure returns (uint256 lowIndex, uint256 highIndex) {
        highIndex = 0;
        if (numberOfQuestions > 0) {
            highIndex = numberOfQuestions;
        }

        if (pageNumber > 0) {
            if (highIndex < pageNumber * pageSize) {
                highIndex = 0;
            } else {
                highIndex = highIndex - pageNumber * pageSize;
            }
        }

        lowIndex = 0;
        // Testing (highIndex - pageSize > 0) without
        // calculating potentially negative number
        if (highIndex > pageSize) {
            lowIndex = highIndex - pageSize;
        }

        return (lowIndex, highIndex);
    }

    /// @notice See {DAFactory-getQuestionsPage}.
    function getQuestionsPage(
        address wallet,
        uint256 pageNumber,
        uint256 pageSize,
        string[] storage questionsIds,
        mapping(string => QuestionStruct) storage questionsById,
        DAFactoryContract daFactoryContract,
        DAFSubscriptionsContract dafSubscriptionsContract,
        uint256 tokenId,
        mapping(string => mapping(uint256 => TokenVotingState))
            storage tokensState
    ) external view returns (GetQuestionPageResult memory pageResult) {
        (uint256 lowIndex, uint256 highIndex) = getQuestionPageArgs(
            pageNumber,
            pageSize,
            questionsIds.length
        );

        bool isValidContributor = daFactoryContract.isNftOwnerOfValidToken(
            wallet
        );
        bool isValidSubscriber = dafSubscriptionsContract
            .isNftOwnerOfValidToken(wallet);

        require(
            !isValidSubscriber,
            SUBSCRIBERS_SHOULD_GET_QUESTIONS_FROM_BACKEND
        );

        pageResult.numberOfPages =
            (questionsIds.length / pageSize) +
            (questionsIds.length % pageSize != 0 ? 1 : 0);
        pageResult.items = new GetQuestionPageItemQueryResult[](
            highIndex - lowIndex
        );

        if (highIndex == 0) {
            return pageResult;
        }

        // int / uint conversion needed here for the evaluation of i-- >= 0
        // (it does need to compute i = -1 before evaluating i >= lowIndex)
        uint256 indexToSet = 0;
        for (int256 i = int256(highIndex - 1); i >= int256(lowIndex); i--) {
            pageResult.items[indexToSet] = getQuestion(
                questionsById[questionsIds[uint256(i)]],
                isValidContributor,
                isValidSubscriber,
                tokenId,
                tokensState
            );
            indexToSet++;
        }

        return pageResult;
    }

    /// @notice See {DAFactory-vote}.
    function vote(
        uint256 tokenId,
        QuestionStruct storage question,
        DAFContributorToken[] storage dafContributorTokens,
        IntegerWrapper.Integer storage totalOfPoints,
        uint256 answerIdIndex,
        uint256 rewardPointDeltaForVoting,
        mapping(string => mapping(uint256 => TokenVotingState))
            storage tokensState
    ) public returns (bool justReachedConsensus) {
        require(bytes(question.id).length != 0, QUESTION_DOES_NOT_EXIST);
        require(
            !isVotingTimeOverForQuestion(question),
            QUESTION_VOTING_TIME_IS_OVER
        );
        requireTokenNotToHaveVoted(tokensState[question.id], tokenId);
        requireTokenToBeAlive(dafContributorTokens[tokenId]);

        question.votesOfEachAnswers[answerIdIndex] =
            question.votesOfEachAnswers[answerIdIndex] +
            1;
        tokensState[question.id][tokenId] = TokenVotingState.Voted;

        uint256 bestAnswer = question.bestAnswers[0];
        if (bestAnswer != answerIdIndex) {
            if (
                question.votesOfEachAnswers[bestAnswer] ==
                question.votesOfEachAnswers[answerIdIndex]
            ) {
                question.bestAnswers.push(answerIdIndex);
            } else if (
                question.votesOfEachAnswers[bestAnswer] <
                question.votesOfEachAnswers[answerIdIndex]
            ) {
                question.bestAnswers = [answerIdIndex];
            }
        } else {
            question.bestAnswers = [answerIdIndex];
        }

        uint256 maxNumberOfVotes = question.votesOfEachAnswers[
            question.bestAnswers[0]
        ];
        if (
            question.bestAnswers.length == 1 &&
            maxNumberOfVotes >= question.minimumVotesForConsensus
        ) {
            justReachedConsensus = !question.reachedConsensus;
            question.reachedConsensus = true;
        }

        addPoints(
            dafContributorTokens[tokenId],
            rewardPointDeltaForVoting,
            totalOfPoints
        );

        return justReachedConsensus;
    }

    function emitConsensusIfNeeded(
        bool justReachedConsensus,
        QuestionStruct storage question
    ) external {
        if (justReachedConsensus) {
            string memory consensusAnswerId = question.answersIds[
                question.bestAnswers[0]
            ];

            emit ConsensusReached(question.id, consensusAnswerId);
        }
    }

    /// @notice See {DAFactory-revive}.
    function revive(
        DAFContributorToken[] storage dafContributorTokens,
        uint256 tokenId,
        uint256 timeToRevive,
        uint256 startScore
    ) external {
        require(
            dafContributorTokens[tokenId].score == 0,
            TOKEN_SCORE_IS_NOT_NULL
        );
        // solhint-disable not-rely-on-time
        // slither-disable-next-line timestamp
        require(
            block.timestamp < block.timestamp + timeToRevive,
            TOKEN_REVIVE_TIME_IS_OVER
        );
        dafContributorTokens[tokenId].score = startScore;
        dafContributorTokens[tokenId].role = Role.Contributor;
    }

    function isTimeOverForVoting(QuestionStruct storage question)
        external
        view
        returns (bool)
    {
        // solhint-disable not-rely-on-time
        // slither-disable-next-line timestamp
        bool timeIsOver = (question.dateOfCreation + question.timeToVote) <
            block.timestamp;

        return timeIsOver;
    }

    /// @notice See {DAFactory-punishInactiveToken}.
    function punishInactiveToken(
        DAFContributorToken storage punishedToken,
        DAFContributorToken storage ownerToken,
        QuestionStruct storage question,
        uint256 punishedTokenId,
        uint256 punishmentPointDelta,
        uint256 rewardPointDeltaForPunishment,
        uint256 startScore,
        IntegerWrapper.Integer storage totalOfPoints,
        mapping(string => mapping(uint256 => TokenVotingState))
            storage tokensState
    ) public returns (bool justReachedConsensus) {
        require(bytes(question.id).length != 0, QUESTION_DOES_NOT_EXIST);
        require(
            punishedToken.owner != ownerToken.owner,
            TOKEN_OWNER_CANNOT_PUNISH_HIMSELF
        );
        requireTokenNotToHaveVoted(tokensState[question.id], punishedTokenId);
        requireTokenToBeAlive(punishedToken);
        bool tokenCreatedBeforeVoteEvent = punishedToken.dateOfCreation <
            question.dateOfCreation;
        require(
            tokenCreatedBeforeVoteEvent,
            TOKEN_CREATED_AFTER_QUESTION_CREATION
        );
        bool votingTimeIsOver = isVotingTimeOverForQuestion(question);
        // slither-disable-next-line timestamp
        require(votingTimeIsOver, QUESTION_VOTING_TIME_IS_NOT_OVER);
        tokensState[question.id][punishedTokenId] = TokenVotingState.Punished;

        addPoints(ownerToken, rewardPointDeltaForPunishment);
        int256 diffToApplyToTotalPoints = int256(rewardPointDeltaForPunishment);

        // if punishedToken.score <= startScore,
        // there's no redeemable points to get on punished token
        // means nothing to remove from totalOfPoints
        if (punishedToken.score > startScore) {
            uint256 removableRedeemablePoints = punishedToken.score -
                startScore;
            if (removableRedeemablePoints < punishmentPointDelta) {
                diffToApplyToTotalPoints -= int256(removableRedeemablePoints);
            } else {
                diffToApplyToTotalPoints -= int256(punishmentPointDelta);
            }
        }

        removePointsOnlyFromToken(punishedToken, punishmentPointDelta);

        if (diffToApplyToTotalPoints < 0) {
            if (int256(totalOfPoints.current()) <= -diffToApplyToTotalPoints) {
                totalOfPoints.reset();
            } else {
                totalOfPoints.decrement(uint256(diffToApplyToTotalPoints));
            }
        } else {
            totalOfPoints.increment(uint256(diffToApplyToTotalPoints));
        }

        // Handle consensus modification on question, considering the number of voter changed
        // (punished token cannot vote anymore), we should update the necessary vote count and consensus status
        if (question.minimumVotesForConsensus >= 1) {
            question.minimumVotesForConsensus -= 1;
        }

        uint256 maxNumberOfVotes = question.votesOfEachAnswers[
            question.bestAnswers[0]
        ];
        if (
            question.bestAnswers.length == 1 &&
            maxNumberOfVotes > question.minimumVotesForConsensus
        ) {
            justReachedConsensus = !question.reachedConsensus;
            question.reachedConsensus = true;
        }

        return justReachedConsensus;
    }

    function removePoints(
        DAFContributorToken storage token,
        IntegerWrapper.Integer storage totalOfPoints,
        uint256 nbOfPoints
    ) public {
        if (token.score <= nbOfPoints) {
            // solhint-disable not-rely-on-time
            token.dateOfDeath = block.timestamp;
            if (totalOfPoints.current() <= nbOfPoints) {
                totalOfPoints.reset();
            } else {
                totalOfPoints.decrement(nbOfPoints);
            }
            token.score = 0;
            token.role = Role.Contributor;
        } else {
            token.score = token.score - nbOfPoints;
            if (totalOfPoints.current() <= nbOfPoints) {
                totalOfPoints.reset();
            } else {
                totalOfPoints.decrement(nbOfPoints);
            }
        }
    }

    function removePointsOnlyFromToken(
        DAFContributorToken storage token,
        uint256 nbOfPoints
    ) internal {
        if (token.score <= nbOfPoints) {
            // solhint-disable not-rely-on-time
            token.dateOfDeath = block.timestamp;
            token.score = 0;
            token.role = Role.Contributor;
        } else {
            token.score = token.score - nbOfPoints;
        }
    }

    function getTokenURI(
        uint256 _score,
        bool _isAlive,
        Role _role
    ) external pure returns (string memory) {
        /* solhint-disable quotes */
        string memory svg = string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' width='50px' height='50px'><path fill='",
                _isAlive
                    ? (_role == Role.Contributor ? "#fff" : "#32CD32")
                    : "#000",
                "' d='M1 1h350v300H1z'/><text x='50%' y='55%' text-anchor='middle' font-size='9' fill='",
                _isAlive ? "#000" : "#fff",
                "'>",
                Strings.toString(_score),
                " POINTS</text></svg>"
            )
        );

        string memory encodedSvg = string(
            abi.encodePacked(
                '"data:image/svg+xml;base64,',
                Base64.encode(bytes(string(abi.encodePacked(svg))))
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "TAF ',
                                _role == Role.Contributor
                                    ? "Contributor"
                                    : "Core contributor",
                                '","description": "thealphafactory.xyz"',
                                ', "image": ',
                                encodedSvg,
                                '","attributes": [{"trait_type": "score", "value":',
                                Strings.toString(_score),
                                "}]}"
                            )
                        )
                    )
                )
            );
        /* solhint-enable quotes */
    }

    function requireTokenToBeAlive(DAFContributorToken storage token)
        public
        view
    {
        require(token.score > 0, TOKEN_SCORE_MUST_NOT_BE_NULL);
    }

    function requireTokenNotToHaveVoted(
        mapping(uint256 => TokenVotingState) storage tokensState,
        uint256 tokenId
    ) private view {
        require(
            tokensState[tokenId] == TokenVotingState.Pending,
            TOKEN_MUST_NOT_HAVE_VOTED_YET
        );
    }

    function isVotingTimeOverForQuestion(QuestionStruct storage question)
        private
        view
        returns (bool)
    {
        // slither-disable-next-line timestamp
        return
            (question.dateOfCreation + question.timeToVote) < block.timestamp;
    }

    function transfer(
        address from,
        address to,
        uint256 tokenId,
        mapping(address => uint256) storage ownerToToken,
        DAFContributorToken[] storage dafContributorTokens,
        uint256 startScore
    ) public {
        ownerToToken[to] = tokenId;
        dafContributorTokens[ownerToToken[to]].owner = to;
        ownerToToken[from] = 0;
        dafContributorTokens[ownerToToken[to]].score = startScore;
        dafContributorTokens[ownerToToken[to]].role = Role.Contributor;
    }

    /// @notice See {DAFactory-withdraw}.
    function withdraw(
        DAFContributorToken storage token,
        uint256 points,
        uint256 startScore,
        IntegerWrapper.Integer storage totalOfPoints,
        DAFactoryContract daFactoryContract
    ) external returns (uint256 amountToWithdraw) {
        require(token.score >= points, DAFLib.NOT_ENOUGH_POINTS);
        // solhint-disable-next-line reason-string
        require(
            token.score - points >= startScore,
            DAFLib.CANT_WITHDRAW_LESS_MIN_SCORE
        );
        amountToWithdraw = calculateWithdrawalAmount(
            points,
            totalOfPoints,
            daFactoryContract
        );
        removePoints(token, totalOfPoints, points);
        return amountToWithdraw;
    }

    /// @notice Calculate how many payment tokens the user is able to withdraw
    /// @param points Points owned by the user
    /// @param totalOfPoints Total redeemable points
    /// @param daFactoryContract DAFactoryContract reference
    function calculateWithdrawalAmount(
        uint256 points,
        IntegerWrapper.Integer storage totalOfPoints,
        DAFactoryContract daFactoryContract
    ) internal view returns (uint256 amountToWithdraw) {
        amountToWithdraw =
            (daFactoryContract.getBalance() * points) /
            totalOfPoints.current();
    }

    /**
    /// @notice See {DAFactory-requireNotPaused}.
     */
    function requireNotPaused(bool paused) external pure {
        require(!paused, DAFLib.CONTRACT_PAUSED);
    }

    /// @notice Force Upgrade the sent contributor token to a core contributor token. This is only possible to be done by the owner
    function upgrade(
        uint256 tokenId,
        DAFStorage storage dafStorage,
        bool checkScore
    ) external {
        DAFContributorToken storage token = dafStorage.dafContributorTokens[
            tokenId
        ];
        require(token.role != Role.Core, DAFLib.CORE_MEMBER_CANT_UPGRADE);
        if (checkScore) {
            require(
                token.score >= dafStorage.scoreToUpgrade,
                DAFLib.INSUFFICIENT_SCORE_TO_PROCEED_WITH_UPGRADE
            );
        }
        token.role = Role.Core;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.13;

/// @title Interface specifying the functions of DAFSubscriptions contract used in external invocations.
interface DAFSubscriptionsContract {
    /// @dev See {IERC721-balanceOf}.
    function balanceOf(address) external view returns (uint256);

    /// @dev See {DAFSubscriptions-isNftOwnerOfValidToken}.
    function isNftOwnerOfValidToken(address wallet)
        external
        view
        returns (bool);

    /// @dev See {DAFSubscriptions-isNftOwnerOfValidTokenFromCurrentOrMigratedVersion}.
    function isNftOwnerOfValidTokenFromCurrentOrMigratedVersion(address _owner)
        external
        view
        returns (bool);

    /// @dev See {DAFSubscriptions-burnToken}.
    function burnToken(
        address punisherAddress,
        uint256 punisherTokenId,
        uint256 punishedTokenId,
        uint256 rewardPointDeltaForDestruction
    ) external;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.13;

/// @title A wrapper that allows, among other things, to transmit an integer by reference to functions.
library IntegerWrapper {
    /// @notice The structure containing the integer value, initially at zero.
    struct Integer {
        uint256 _value; // default: 0
    }

    /// @notice Get the value of the wrapped integer.
    /// @param integer The integer wrapper.
    /// @return The value of the wrapped integer.
    function current(Integer storage integer) internal view returns (uint256) {
        return integer._value;
    }

    /// @notice Increment the value of the wrapped integer by the increment value.
    /// @param integer The integer wrapper.
    /// @param incrementValue The increment value.
    function increment(Integer storage integer, uint256 incrementValue)
        internal
    {
        integer._value += incrementValue;
    }

    /// @notice Decrement the value of the wrapped integer by the decrement value.
    /// @param integer The integer wrapper.
    /// @param decrementValue The decrement value.
    function decrement(Integer storage integer, uint256 decrementValue)
        internal
    {
        uint256 value = integer._value;
        require(value >= decrementValue, "Counter: decrement overflow");
        integer._value -= decrementValue;
    }

    /// @notice Reset the value the wrapped integer to zero.
    /// @param integer The integer wrapper.
    function reset(Integer storage integer) internal {
        integer._value = 0;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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