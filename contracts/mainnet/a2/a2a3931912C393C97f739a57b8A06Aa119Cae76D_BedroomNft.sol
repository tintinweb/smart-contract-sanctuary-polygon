// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "../Interfaces/ITracker.sol";
import "../Interfaces/IUpgrader.sol";

import "./UpgradeNft.sol";

/// @title Bedroom NFT Contract
/// @author Sleepn
/// @notice Bedroom NFT is the main NFT of Sleepn app
contract BedroomNft is
    VRFConsumerBaseV2,
    ERC1155,
    Ownable,
    ERC1155URIStorage
{
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    /// @dev Dex Contract address
    address public immutable dexAddress;

    /// @dev Upgrade NFT Contract address
    UpgradeNft public immutable upgradeNftInstance;

    /// @dev Tracker Contract address
    ITracker public immutable trackerInstance;

    /// @dev Upgrader Contract address
    IUpgrader public immutable upgraderInstance;

    /// @dev Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable COORDINATOR;
    uint32 private numWords;
    uint32 private callbackGasLimit;
    uint16 private requestConfirmations;
    uint64 private subscriptionId;
    bytes32 private keyHash;

    /// @notice Scores of a Bedroom NFT
    struct NftSpecifications {
        address owner;
        uint64 scores;
        uint256 level;
        uint256 value;
    }

    /// @dev initial NFT design URI
    string private initialURI;

    /// @notice Number of NFT
    Counters.Counter private tokenId;

    /// @dev Maps Chainlink VRF Random Number Request Id to NFT Id
    mapping(uint256 => uint256) public requestIdToTokenId;

    /// @dev Maps NFT Scores to NFT Id
    mapping(uint256 => NftSpecifications) private tokenIdToNftSpecifications;

    /// @notice Emits an event when a Bedroom NFT is minted
    event BedroomNftMinted(
        address indexed owner,
        uint256 indexed requestID,
        uint256 tokenId,
        uint16 ambiance,
        uint16 quality,
        uint16 luck,
        uint16 comfortability
    );
    /// @notice Emits an event when a Bedroom NFT Score is updated
    event BedroomNftUpdated(
        address indexed owner, uint256 indexed tokenId, uint256 timestamp
    );
    /// @notice Returned Request ID, Invoker and Token ID
    event RequestedRandomness(
        uint256 indexed requestId, address invoker, uint256 indexed tokenId
    );
    /// @notice Returned Random Numbers Event, Invoker and Token ID
    event ReturnedRandomness(
        uint256[] randomWords,
        uint256 indexed requestId,
        uint256 indexed tokenId
    );
    /// @notice Base URI Changed Event
    event BaseURIChanged(string baseURI);
    /// @notice Chainlink Data Updated Event
    event ChainlinkDataUpdated(
        uint32 callbackGasLimit,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint16 requestConfirmations
    );
    /// @notice Withdraw Money Event
    event WithdrawMoney(address indexed owner, uint256 amount);

    /// @notice Restricted Access Error - Wrong caller
    error RestrictedAccess(address caller);

    /// @dev Constructor
    /// @param _subscriptionId Chainlink VRF Id Subscription
    /// @param _vrfCoordinator Address of the Coordinator Contract
    /// @param _dexAddress Dex Contract Address
    /// @param _devWallet Dev Wallet Address
    /// @param _keyHash Chainlink VRF key hash
    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        address _dexAddress,
        address _devWallet,
        bytes32 _keyHash
    ) ERC1155("Bedroom") VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        callbackGasLimit = 200000;
        requestConfirmations = 3;
        numWords = 4;
        dexAddress = _dexAddress;

        // Deploys Upgrade NFT contract and transfers ownership
        upgradeNftInstance = new UpgradeNft(
            _dexAddress,
            _devWallet
        );
        upgradeNftInstance.transferOwnership(msg.sender);

        // Connects to Tracker and Upgrader contracts
        trackerInstance =
            ITracker(address(upgradeNftInstance.trackerInstance()));
        upgraderInstance =
            IUpgrader(address(upgradeNftInstance.upgraderInstance()));
    }

    /// @notice Returns the number of Bedroom NFTs in existence
    /// @return nftsNumber Representing the number of Bedroom NFTs in existence
    function getNftsNumber() external view returns (uint256 nftsNumber) {
        nftsNumber = tokenId.current();
    }

    /// @notice Returns the specifications of a Bedroom NFT
    /// @param _tokenId Id of the Bedroom NFT
    /// @return nftSpecifications Specifications of the Bedroom NFT
    function getSpecifications(uint256 _tokenId)
        external
        view
        returns (NftSpecifications memory nftSpecifications)
    {
        nftSpecifications = tokenIdToNftSpecifications[_tokenId];
    }

    /// @notice Returns the specifications of some Bedroom NFTs
    /// @param _tokenIds Ids of the Bedroom NFTs
    /// @return nftSpecifications Specifications of the Bedroom NFTs
    function getSpecificationsBatch(uint256[] calldata _tokenIds)
        external
        view
        returns (NftSpecifications[] memory nftSpecifications)
    {
        nftSpecifications = new NftSpecifications[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            nftSpecifications[i] = tokenIdToNftSpecifications[_tokenIds[i]];
        }
    }

    /// @notice Returns the data of a NFT
    /// @param _tokenId The id of the NFT
    /// @return _ambiance Ambiance Score
    /// @return _quality Quality Score
    /// @return _luck Luck Score
    /// @return _comfortability Comfortability Score
    /// @return _owner NFT owner address
    /// @return _level NFT level
    /// @return _value NFT value
    function getData(uint256 _tokenId)
        external
        view
        returns (
            uint16 _ambiance,
            uint16 _quality,
            uint16 _luck,
            uint16 _comfortability,
            address _owner,
            uint256 _level,
            uint256 _value
        )
    {
        NftSpecifications memory spec = tokenIdToNftSpecifications[_tokenId];
        _ambiance = uint16(spec.scores);
        _quality = uint16(spec.scores >> 16);
        _luck = uint16(spec.scores >> 32);
        _comfortability = uint16(spec.scores >> 48);
        _owner = spec.owner;
        _level = spec.level;
        _value = spec.value;
    }

    /// @notice Returns the data of some Bedroom NFTs
    /// @param _tokenIds Nfts IDs
    /// @return _ambiance Ambiance Score
    /// @return _quality Quality Score
    /// @return _luck Luck Score
    /// @return _comfortability Comfortability Score
    /// @return _owners NFT owner address
    /// @return _levels NFT level
    /// @return _values NFT value
    function getDataBatch(uint256[] calldata _tokenIds)
        external
        view
        returns (
            uint16[] memory _ambiance,
            uint16[] memory _quality,
            uint16[] memory _luck,
            uint16[] memory _comfortability,
            address[] memory _owners,
            uint256[] memory _levels,
            uint256[] memory _values
        )
    {
        _ambiance = new uint16[](_tokenIds.length);
        _quality = new uint16[](_tokenIds.length);
        _luck = new uint16[](_tokenIds.length);
        _comfortability = new uint16[](_tokenIds.length);
        _owners = new address[](_tokenIds.length);
        _levels = new uint256[](_tokenIds.length);
        _values = new uint256[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            NftSpecifications memory spec =
                tokenIdToNftSpecifications[_tokenIds[i]];
            _ambiance[i] = uint16(spec.scores);
            _quality[i] = uint16(spec.scores >> 16);
            _luck[i] = uint16(spec.scores >> 32);
            _comfortability[i] = uint16(spec.scores >> 48);
            _owners[i] = spec.owner;
            _levels[i] = spec.level;
            _values[i] = spec.value;
        }
    }

    /// @notice Returns the concatenation of the _baseURI and the token-specific uri if the latter is set
    /// @param _tokenId Id of the NFT
    function uri(uint256 _tokenId)
        public
        view
        override (ERC1155, ERC1155URIStorage)
        returns (string memory)
    {
        return super.uri(_tokenId);
    }

    /// @notice Updates chainlink variables
    /// @param _callbackGasLimit Callback Gas Limit
    /// @param _subscriptionId Chainlink subscription Id
    /// @param _keyHash Chainlink Key Hash
    /// @param _requestConfirmations Number of request confirmations
    /// @dev This function can only be called by the owner of the contract
    function updateChainlink(
        uint32 _callbackGasLimit,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint16 _requestConfirmations
    ) external onlyOwner {
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        emit ChainlinkDataUpdated(
            _callbackGasLimit, _subscriptionId, _keyHash, _requestConfirmations
            );
    }

    /// @notice Settles initial NFT Design URI
    /// @param _initialURI New URI
    /// @dev This function can only be called by the owner of the contract
    function setInitialDesignURI(string calldata _initialURI)
        external
        onlyOwner
    {
        initialURI = _initialURI;
    }

    /// @notice Settles the URI of a NFT
    /// @param _tokenId Id of the NFT
    /// @param _tokenURI Uri of the NFT
    /// @dev This function can only be called by the owner of the contract
    function setTokenURI(uint256 _tokenId, string memory _tokenURI)
        external
        onlyOwner
    {
        _setURI(_tokenId, _tokenURI);
    }

    /// Settles baseURI as the _baseURI for all tokens
    /// @param _baseURI Base URI of NFTs
    /// @dev This function can only be called by the owner of the contract
    function setBaseURI(string memory _baseURI) external onlyOwner {
        _setBaseURI(_baseURI);
        emit BaseURIChanged(_baseURI);
    }

    /// @notice Withdraws the money from the contract
    /// @param _token Address of the token to withdraw
    /// @dev This function can only be called by the owner or the dev Wallet
    function withdrawMoney(IERC20 _token) external {
        if (msg.sender != owner()) {
            revert RestrictedAccess(msg.sender);
        }
        uint256 balance = _token.balanceOf(address(this));
        _token.safeTransfer(msg.sender, balance);
        emit WithdrawMoney(msg.sender, balance);
    }

    /// @notice Launches the procedure to create an NFT
    /// @param _owner Owner of the NFT
    /// @return _tokenId NFT ID
    /// @dev This function can only be called by Dex Contract
    function mintBedroomNft(address _owner)
        external
        returns (uint256 _tokenId)
    {
        if (msg.sender != owner() && msg.sender != dexAddress) {
            revert RestrictedAccess(msg.sender);
        }

        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        _tokenId = tokenId.current();

        tokenId.increment();

        requestIdToTokenId[requestId] = _tokenId;

        tokenIdToNftSpecifications[_tokenId] =
            NftSpecifications(_owner, 0, 1, 0);

        trackerInstance.addBedroomNft(_owner, _tokenId);

        emit RequestedRandomness(requestId, msg.sender, _tokenId);
    }

    /// @notice Launches the procedure to create an NFT - Batch Transaction
    /// @param _owners Nfts Owners
    /// @return _tokenIds NFT IDs
    /// @dev This function can only be called by Dex Contract
    function mintBedroomNfts(address[] calldata _owners)
        external
        returns (uint256[] memory _tokenIds)
    {
        if (msg.sender != owner() && msg.sender != dexAddress) {
            revert RestrictedAccess(msg.sender);
        }

        _tokenIds = new uint256[](_owners.length);

        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        for (uint256 i = 0; i < _owners.length; ++i) {
            _tokenIds[i] = tokenId.current();

            tokenId.increment();

            tokenIdToNftSpecifications[_tokenIds[i]] =
                NftSpecifications(_owners[i], 0, 1, 0);

            trackerInstance.addBedroomNft(_owners[i], _tokenIds[i]);

            emit RequestedRandomness(requestId, msg.sender, _tokenIds[i]);
        }
    }

    /// @dev Callback function with the requested random numbers
    /// @param requestId Chainlink VRF Random Number Request Id
    /// @param randomWords List of random words
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 _tokenId = requestIdToTokenId[requestId];
        emit ReturnedRandomness(randomWords, requestId, _tokenId);

        // Create new Bedroom
        uint64 score1 = uint64((randomWords[0] % 100) + 1); // Ambiance
        uint64 score2 = uint64((randomWords[1] % 100) + 1); // Quality
        uint64 score3 = uint64((randomWords[2] % 100) + 1); // Luck
        uint64 score4 = uint64((randomWords[3] % 100) + 1); // comfortability
        tokenIdToNftSpecifications[_tokenId].scores =
            score1 + (score2 << 16) + (score3 << 32) + (score4 << 48);
        tokenIdToNftSpecifications[_tokenId].value =
            uint256(score1 + score2 + score3 + score4);

        // Minting of the new Bedroom NFT
        address nftOwner = tokenIdToNftSpecifications[_tokenId].owner;
        _mint(nftOwner, _tokenId, 1, "");

        _setURI(_tokenId, initialURI);

        emit BedroomNftMinted(
            nftOwner,
            requestId,
            _tokenId,
            uint16(score1),
            uint16(score2),
            uint16(score3),
            uint16(score4)
            );
    }

    /// @notice Updates a Bedroom NFT
    /// @param _tokenId Id of the NFT
    /// @param _newValue value of the NFT
    /// @param _newLevel level of the NFT
    /// @param _newScores Scores of the NFT
    /// @param _newDesignURI Design URI of the NFT
    function updateBedroomNft(
        uint256 _tokenId,
        uint256 _newValue,
        uint256 _newLevel,
        uint64 _newScores,
        string memory _newDesignURI
    ) external {
        if (msg.sender != address(upgraderInstance)) {
            revert RestrictedAccess(msg.sender);
        }
        /// Gets current NFT data
        NftSpecifications memory spec = tokenIdToNftSpecifications[_tokenId];
        /// Updates the level if it is different than the current one
        if (spec.level != _newLevel) {
            tokenIdToNftSpecifications[_tokenId].level = _newLevel;
        }
        /// Updates the value if it is different than the current one
        if (spec.value != _newValue) {
            tokenIdToNftSpecifications[_tokenId].value = _newValue;
        }
        /// Updates the scores if it is different than the current one
        if (spec.scores != _newScores) {
            tokenIdToNftSpecifications[_tokenId].scores = _newScores;
        }
        /// Updates the design URI if it is different than the current one
        if (bytes(_newDesignURI).length != 0) {
            _setURI(_tokenId, _newDesignURI);
        }
        emit BedroomNftUpdated(spec.owner, _tokenId, block.timestamp);
    }

    /// @notice Safe Transfer From
    /// @param _from Owner address
    /// @param _to Receiver address
    /// @param _id NFT Id
    /// @param _amount Amount to mint
    /// @param _data Data
    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal virtual override {
        tokenIdToNftSpecifications[_id].owner = _to;
        trackerInstance.removeBedroomNft(_from, _to, _id);
        trackerInstance.addBedroomNft(_to, _id);
        super._safeTransferFrom(_from, _to, _id, _amount, _data);
    }

    /// @notice Safe Batch Transfer From
    /// @param _from Owner address
    /// @param _to Receiver address
    /// @param _ids NFT Ids
    /// @param _amounts Amounts to mint
    /// @param _data Data
    function _safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal virtual override {
        for (uint256 i = 0; i < _ids.length; ++i) {
            tokenIdToNftSpecifications[_ids[i]].owner = _to;
            trackerInstance.removeBedroomNft(_from, _to, _ids[i]);
            trackerInstance.addBedroomNft(_to, _ids[i]);
        }
        super._safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Interface of the Tracker Contract
/// @author Sleepn
/// @notice The Tracker Contract is used to track the NFTs

interface ITracker {
    /// @dev Struct to store the NFT IDs of a user
    struct NftsID {
        EnumerableSet.UintSet bedroomNfts;
        EnumerableSet.UintSet upgradeNfts;
    }
    /// @dev Struct to store the amounts owned of a NFT ID
    struct UpgradeNft {
        uint256 amountOwned;
        uint256 amountUsed;
        EnumerableSet.UintSet bedroomNftIds;
    }

    /// @notice Restricted Access Error - Wrong caller
    error RestrictedAccess(address caller);
    /// @notice Invalid NFT ID Error - NFT ID is invalid
    error IdAlreadyUsed(uint256 tokenId);

    /// @notice BedroomNft ID Linked To Wallet Event
    event BedroomNftLinkedToWallet(
        uint256 indexed bedroomNftId,
        address indexed owner
    );
    /// @notice BedroomNft ID Unlinked From Wallet Event
    event BedroomNftUnlinkedFromWallet(
        uint256 indexed bedroomNftId,
        address indexed owner
    );
    /// @notice UpgradeNft ID Linked To Wallet Event
    event UpgradeNftLinkedToWallet(
        uint256 indexed upgradeNftId,
        address indexed owner
    );
    /// @notice UpgradeNft ID Unlinked From Wallet Event
    event UpgradeNftUnlinkedFromWallet(
        uint256 indexed upgradeNftId,
        address indexed owner
    );
    /// @notice UpgradeNft ID Linked To BedroomNft ID Event
    event UpgradeNftLinkedToBedroomNft(
        uint256 indexed upgradeNftId,
        uint256 indexed bedroomNftId
    );
    /// @notice UpgradeNft ID Unlinked From BedroomNft ID Event
    event UpgradeNftUnlinkedFromBedroomNft(
        uint256 indexed upgradeNftId,
        uint256 indexed bedroomNftId
    );

    /// @notice Gets the NFTs owned by an address
    /// @param _owner The address of the owner
    /// @return _bedroomNfts The Bedroom NFTs owned by the address
    /// @return _upgradeNfts The Upgrade NFTs owned by the address
    function getNftsID(address _owner)
        external
        view
        returns (uint256[] memory _bedroomNfts, uint256[] memory _upgradeNfts);

    /// @notice Adds a Bedroom NFT ID to the tracker
    /// @param _owner The owner of the NFT
    /// @param _tokenId The NFT ID
    /// @return stateUpdated Returns true if the update worked
    function addBedroomNft(address _owner, uint256 _tokenId)
        external
        returns (bool);

    /// @notice Remove a Bedroom NFT from the tracker
    /// @param _owner The owner of the Bedroom NFT
    /// @param _newOwner The new owner of the Bedroom NFT
    /// @param _tokenId The ID of the Bedroom NFT
    /// @return stateUpdated Returns true if the update worked
    function removeBedroomNft(
        address _owner,
        address _newOwner,
        uint256 _tokenId
    ) external returns (bool);

    /// @notice Returns true if the owner of the bedroom NFT is the wallet address
    /// @param _tokenId The ID of the bedroom NFT
    /// @param _wallet The wallet address of the owner
    /// @return isOwner True if the owner of the bedroom NFT is the wallet address
    function isBedroomNftOwner(uint256 _tokenId, address _wallet)
        external
        view
        returns (bool isOwner);

    /// @notice Returns the amount of bedroom NFTs owned by an owner
    /// @param _owner The owner of the bedroom NFTs
    /// @return nftsAmount The amount of bedroom NFTs owned by the owner
    function getBedroomNftsAmount(address _owner)
        external
        view
        returns (uint256 nftsAmount);

    /// @notice Adds an upgrade NFT ID to the settled upgrade NFT IDs
    /// @param _tokenId The ID of the upgrade NFT
    function settleUpgradeNftData(uint256 _tokenId) external;

    /// @notice Returns the upgrade NFT IDs that have been settled
    /// @return nftIdsSettled The upgrade NFT IDs that have been settled
    function getUpgradeNftSettled()
        external
        view
        returns (uint256[] memory nftIdsSettled);

    /// @notice Returns true if the Upgrade NFT ID is settled
    /// @param _tokenId The ID of the Upgrade NFT
    /// @return isSettled True if the Upgrade NFT ID is settled
    function isIdSettled(uint256 _tokenId)
        external
        view
        returns (bool isSettled);

    /// @notice Adds an upgrade NFT to the tracker
    /// @param _owner The owner of the upgrade NFT
    /// @param _tokenId The ID of the upgrade NFT
    /// @return stateUpdated Returns true if the update worked
    function addUpgradeNft(address _owner, uint256 _tokenId)
        external
        returns (bool);

    /// @notice Removes an upgrade NFT from the tracker
    /// @param _owner The owner of the upgrade NFT
    /// @param _tokenId The ID of the upgrade NFT
    /// @return stateUpdated Returns true if the update worked
    function removeUpgradeNft(address _owner, uint256 _tokenId)
        external
        returns (bool);

    /// @notice Returns true if the given address is the owner of the given Upgrade NFT
    /// @param _tokenId The ID of the Upgrade NFT to check
    /// @param _wallet The address to check
    /// @return isOwner True if the given address is the owner of the given Upgrade NFT
    function isUpgradeNftOwner(uint256 _tokenId, address _wallet)
        external
        view
        returns (bool isOwner);

    /// @notice Returns the amount of Upgrade NFTs owned by a wallet
    /// @param _owner The owner wallet address
    /// @return nftsAmount The amount of Upgrade NFTs owned by the wallet
    function getUpgradeNftsAmount(address _owner)
        external
        view
        returns (uint256 nftsAmount);

    /// @notice Returns the amounts of a specific Upgrade NFT owned by a specific wallet
    /// @param _owner The owner wallet address
    /// @param _tokenId The ID of the Upgrade NFT
    /// @return amountOwned The amount of Upgrade NFTs owned by the wallet
    /// @return amountUsed The amount of Upgrade NFTs used by the wallet
    function getUpgradeNftAmounts(address _owner, uint256 _tokenId)
        external
        view
        returns (uint256 amountOwned, uint256 amountUsed);

    /// @notice Returns the owners of a specified Upgrade NFT
    /// @param _tokenId The upgrade NFT ID
    /// @return owners Owners of the specified Upgrade NFT
    function getUpgradeNftOwners(uint256 _tokenId)
        external
        view
        returns (address[] memory owners);

    /// @notice Links an upgrade NFT to a Bedroom NFT
    /// @param _owner The owner of the upgrade NFT
    /// @param _bedroomNftId The ID of the bedroom NFT
    /// @param _upgradeNftId The ID of the upgrade NFT
    /// @return stateUpdated Returns true if the update worked
    function linkUpgradeNft(
        address _owner,
        uint256 _bedroomNftId,
        uint256 _upgradeNftId
    ) external returns (bool);

    /// @notice Unlinks an upgrade NFT to a Bedroom NFT
    /// @param _owner The owner of the upgrade NFT
    /// @param _bedroomNftId The ID of the bedroom NFT
    /// @param _upgradeNftId The ID of the upgrade NFT
    /// @return stateUpdated Returns true if the update worked
    function unlinkUpgradeNft(
        address _owner,
        uint256 _bedroomNftId,
        uint256 _upgradeNftId
    ) external returns (bool);

    /// @notice Returns the upgrade NFTs linked to a Bedroom NFT
    /// @param _bedroomNftId The ID of the bedroom NFT
    /// @return upgradeNfts The upgrade NFTs linked to the Bedroom NFT
    function getUpgradeNfts(uint256 _bedroomNftId)
        external
        view
        returns (uint256[] memory upgradeNfts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../Interfaces/ITracker.sol";

import "./BedroomNft.sol";
import "../Utils/Upgrader.sol";

/// @title Upgrade Nft Contract
/// @author Sleepn
/// @notice An update NFT is used to upgrade a Bedroom NFT
contract UpgradeNft is ERC1155, Ownable, ERC1155URIStorage, ERC1155Supply {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    /// @dev Dex Contract address
    address public immutable dexAddress;

    /// @dev Dev Wallet
    address private devWallet;

    /// @dev Bedroom NFT Contract address
    BedroomNft public immutable bedroomNftInstance;

    /// @dev Tracker Contract address
    ITracker public immutable trackerInstance;

    /// @dev Upgrader Contract address
    Upgrader public immutable upgraderInstance;

    /// @dev Maps the Upgrade NFT Data to an NFT ID
    mapping(uint256 => uint96) private tokenIdToUpgradeNftData;

    /// @notice Upgrade NFT Minted Event
    event UpgradeNftMinted(
        address indexed owner, uint256 tokenId, uint256 amount
    );
    /// @notice Upgrade NFT Data Settled Event
    event UpgradeNftDataSettled(
        uint256 indexed tokenId,
        string _designURI,
        uint24 _data,
        uint16 _level,
        uint16 _levelMin,
        uint16 _value,
        uint8 _attributeIndex,
        uint8 _valueToAdd,
        uint8 _typeNft
    );
    /// @notice Withdraw Money Event
    event WithdrawMoney(address indexed owner, uint256 amount);

    /// @notice Restricted Access Error - Wrong caller
    error RestrictedAccess(address caller);
    /// @notice Different Length Error - Arrays length
    error DifferentLength();
    /// @notice Upgrade Nft already linked Error - Upgrade NFTs have to be unlinked before any transfer
    error UpgradeNftAlreadyLinked(uint256 tokenId);
    /// @notice State not updated Error - State is not updated in tracker contract
    error StateNotUpdated();

    /// @dev Constructor
    constructor(address _dexAddress, address _devWallet) ERC1155("") {
        dexAddress = _dexAddress;
        devWallet = _devWallet;
        bedroomNftInstance = BedroomNft(msg.sender);

        // Deploys Tracker and Upgrader contracts
        upgraderInstance = new Upgrader(
            msg.sender,
            _dexAddress
        );

        trackerInstance = ITracker(address(upgraderInstance.trackerInstance()));
    }

    /// @notice Returns the  data of a NFT
    /// @param _tokenId NFT ID
    /// @return _data NFT additionnal data
    /// @return _level NFT level
    /// @return _levelMin NFT level min required
    /// @return _value NFT value
    /// @return _attributeIndex Score attribute index
    /// @return _valueToAdd Value to add to the score
    /// @return _typeNft NFT Type
    function getData(uint256 _tokenId)
        external
        view
        returns (
            uint24 _data,
            uint16 _level,
            uint16 _levelMin,
            uint16 _value,
            uint8 _attributeIndex,
            uint8 _valueToAdd,
            uint8 _typeNft
        )
    {
        uint96 data = tokenIdToUpgradeNftData[_tokenId];
        _data = uint24(data);
        _level = uint16(data >> 24);
        _levelMin = uint16(data >> 40);
        _value = uint16(data >> 56);
        _attributeIndex = uint8(data >> 64);
        _valueToAdd = uint8(data >> 72);
        _typeNft = uint8(data >> 80);
    }

    /// @notice Returns the concatenation of the _baseURI and the token-specific uri if the latter is set
    /// @param _tokenId Id of the NFT
    function uri(uint256 _tokenId)
        public
        view
        override (ERC1155, ERC1155URIStorage)
        returns (string memory)
    {
        return super.uri(_tokenId);
    }

    /// @notice Settles the URI of a NFT
    /// @param _tokenId Id of the NFT
    /// @param _tokenURI Uri of the NFT
    /// @dev This function can only be called by the owner of the contract
    function setTokenURI(uint256 _tokenId, string memory _tokenURI)
        external
        onlyOwner
    {
        _setURI(_tokenId, _tokenURI);
    }

    /// @notice Settles baseURI as the _baseURI for all tokens
    /// @param _baseURI Base URI of NFTs
    /// @dev This function can only be called by the owner of the contract
    function setBaseURI(string memory _baseURI) external onlyOwner {
        _setBaseURI(_baseURI);
    }

    /// @notice Settles dev wallet address
    /// @param _newDevWalletAddress New dev wallet address
    /// @dev This function can only be called by the owner of the contract
    function setDevAddress(address _newDevWalletAddress) external onlyOwner {
        devWallet = _newDevWalletAddress;
    }

    /// @notice Settles the data of a NFT
    /// @param _tokenId NFT ID
    /// @param _designURI Upgrade Nft URI
    /// @param _data Additionnal data (optionnal)
    /// @param _level Level to add to the Bedroom Nft
    /// @param _levelMin Bedroom Nft Level min required
    /// @param _value Upgrade Nft value
    /// @param _attributeIndex Score involved (optionnal)
    /// @param _valueToAdd Value to add to the score (optionnal)
    /// @param _typeNft NFT Type
    /// @dev This function can only be called by the owner or the dev Wallet
    function setData(
        uint256 _tokenId,
        string memory _designURI,
        uint96 _data,
        uint96 _level,
        uint96 _levelMin,
        uint96 _value,
        uint96 _attributeIndex,
        uint96 _valueToAdd,
        uint96 _typeNft
    ) external {
        if (msg.sender != owner() && msg.sender != devWallet) {
            revert RestrictedAccess(msg.sender);
        }
        tokenIdToUpgradeNftData[_tokenId] = _data + (_level << 24)
            + (_levelMin << 40) + (_value << 56) + (_attributeIndex << 64)
            + (_valueToAdd << 72) + (_typeNft << 80);
        _setURI(_tokenId, _designURI);
        trackerInstance.settleUpgradeNftData(_tokenId);
        emit UpgradeNftDataSettled(
            _tokenId,
            _designURI,
            uint24(_data),
            uint16(_level),
            uint16(_levelMin),
            uint16(_value),
            uint8(_attributeIndex),
            uint8(_valueToAdd),
            uint8(_typeNft)
            );
    }

    /// @notice Withdraws the money from the contract
    /// @param _token Address of the token to withdraw
    /// @dev This function can only be called by the owner or the dev Wallet
    function withdrawMoney(IERC20 _token) external {
        if (msg.sender != owner()) {
            revert RestrictedAccess(msg.sender);
        }
        uint256 balance = _token.balanceOf(address(this));
        _token.safeTransfer(msg.sender, balance);
        emit WithdrawMoney(msg.sender, balance);
    }

    /// @notice Mints a new Upgrade Nft
    /// @param _tokenId NFT ID
    /// @param _amount Amount of tokens
    /// @param _account Upgrade Nft Owner
    /// @dev This function can only be called by the owner or the dev Wallet or the Dex contract
    function mint(uint256 _tokenId, uint256 _amount, address _account)
        external
    {
        if (
            msg.sender != owner() && msg.sender != dexAddress
                && msg.sender != devWallet
        ) {
            revert RestrictedAccess(msg.sender);
        }
        if (!trackerInstance.addUpgradeNft(_account, _tokenId)) {
            revert StateNotUpdated();
        }
        _mint(_account, _tokenId, _amount, "");
        emit UpgradeNftMinted(_account, _tokenId, _amount);
    }

    /// @notice Mints Upgrade Nfts per batch
    /// @param _tokenIds NFT IDs
    /// @param _amounts Amount of tokens
    /// @param _accounts Upgrade Nft Owners
    /// @dev This function can only be called by the owner or the dev Wallet or the Dex contract
    function mintBatch(
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        address[] calldata _accounts
    ) external {
        if (
            msg.sender != owner() && msg.sender != dexAddress
                && msg.sender != devWallet
        ) {
            revert RestrictedAccess(msg.sender);
        }
        if (
            _tokenIds.length != _amounts.length
                && _amounts.length != _accounts.length
        ) {
            revert DifferentLength();
        }
        for (uint256 i = 0; i < _accounts.length; ++i) {
            // Mints a Nft
            if (!trackerInstance.addUpgradeNft(_accounts[i], _tokenIds[i])) {
                revert StateNotUpdated();
            }
            _mint(_accounts[i], _tokenIds[i], _amounts[i], "");
            emit UpgradeNftMinted(_accounts[i], _tokenIds[i], _amounts[i]);
        }
    }

    /// @notice Safe Transfer From
    /// @param _from Owner address
    /// @param _to Receiver address
    /// @param _id NFT Id
    /// @param _amount Amount to mint
    /// @param _data Data
    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal virtual override {
        (uint256 amountOwned, uint256 amountUsed) =
            trackerInstance.getUpgradeNftAmounts(_from, _id);
        if (_amount > amountOwned - amountUsed) {
            revert UpgradeNftAlreadyLinked(_id);
        }
        if (!trackerInstance.removeUpgradeNft(_from, _id)) {
            revert StateNotUpdated();
        }
        if (!trackerInstance.addUpgradeNft(_to, _id)) {
            revert StateNotUpdated();
        }
        super._safeTransferFrom(_from, _to, _id, _amount, _data);
    }

    /// @notice Safe Batch Transfer From
    /// @param _from Owner address
    /// @param _to Receiver address
    /// @param _ids NFT Ids
    /// @param _amounts Amounts to mint
    /// @param _data Data
    function _safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal virtual override {
        for (uint256 i = 0; i < _ids.length; ++i) {
            (uint256 amountOwned, uint256 amountUsed) =
                trackerInstance.getUpgradeNftAmounts(_from, _ids[i]);
            if (_amounts[i] > amountOwned - amountUsed) {
                revert UpgradeNftAlreadyLinked(_ids[i]);
            }
            if (!trackerInstance.removeUpgradeNft(_from, _ids[i])) {
                revert StateNotUpdated();
            }
            if (!trackerInstance.addUpgradeNft(_to, _ids[i])) {
                revert StateNotUpdated();
            }
        }
        super._safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }

    /// @notice Before token transfer hook
    /// @param _operator Operator address
    /// @param _from Owner address
    /// @param _to Receiver address
    /// @param _ids NFT Ids
    /// @param _amounts Amounts to mint
    /// @param _data Data
    function _beforeTokenTransfer(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal override (ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(
            _operator, _from, _to, _ids, _amounts, _data
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/// @title Interface of the Upgrader Contract
/// @author Sleepn
/// @notice The Upgrader Contract is used to upgrade a Bedroom NFT
interface IUpgrader {
    /// @notice Upgrade NFT linked to a Bedroom NFT Event
    event UpgradeNftLinked(
        uint256 indexed bedroomNftId,
        uint256 indexed upgradeNftId,
        address owner
    );
    /// @notice Upgrade NFT unlinked from a Bedroom NFT Event
    event UpgradeNftUnlinked(
        uint256 indexed bedroomNftId,
        uint256 indexed upgradeNftId,
        address owner
    );

    /// @notice Score cannot be upgraded Error - Score cannot be greater than 100
    error ScoreCannotBeGreaterThan100(uint16 valueToAdd);
    /// @notice NFT not owned Error - Upgrade NFT is not owned by the user
    error NftNotOwned(uint256 tokenId, address caller);
    /// @notice Upgrade NFT already linked Error - Upgrade NFT is already linked to a Bedroom NFT
    error IsAlreadyLinked(uint256 tokenId);
    /// @notice Upgrade NFT is not linked Error - Upgrade NFT is not linked to a Bedroom NFT
    error IsNotLinked(uint256 tokenId);
    /// @notice Restricted Access Error - Wrong caller
    error RestrictedAccess(address caller);
    /// @notice Level too low Error - Level is too low to upgrade
    error LevelTooLow(uint16 levelMin, uint256 bedroomNftLevel);
    /// @notice State not updated Error - State is not updated in tracker contract
    error StateNotUpdated();

    /// @notice Links an upgrade NFT to a Bedroom NFT
    /// @param _owner The owner of the upgrade NFT
    /// @param _bedroomNftId The ID of the bedroom NFT
    /// @param _upgradeNftId The ID of the upgrade NFT
    /// @param _designURI The new design URI of the bedroom NFT
    function linkUpgradeNft(
        address _owner,
        uint256 _bedroomNftId,
        uint256 _upgradeNftId,
        string memory _designURI
    ) external;

    /// @notice Uninks an upgrade NFT from a Bedroom NFT
    /// @param _owner The owner of the upgrade NFT
    /// @param _bedroomNftId The ID of the bedroom NFT
    /// @param _upgradeNftId The ID of the upgrade NFT
    /// @param _designURI The new design URI of the bedroom NFT
    function unlinkUpgradeNft(
        address _owner,
        uint256 _bedroomNftId,
        uint256 _upgradeNftId,
        string memory _designURI
    ) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155URIStorage.sol)

pragma solidity ^0.8.0;

import "../../../utils/Strings.sol";
import "../ERC1155.sol";

/**
 * @dev ERC1155 token with storage based token URI management.
 * Inspired by the ERC721URIStorage extension
 *
 * _Available since v4.6._
 */
abstract contract ERC1155URIStorage is ERC1155 {
    using Strings for uint256;

    // Optional base URI
    string private _baseURI = "";

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the concatenation of the `_baseURI`
     * and the token-specific uri if the latter is set
     *
     * This enables the following behaviors:
     *
     * - if `_tokenURIs[tokenId]` is set, then the result is the concatenation
     *   of `_baseURI` and `_tokenURIs[tokenId]` (keep in mind that `_baseURI`
     *   is empty per default);
     *
     * - if `_tokenURIs[tokenId]` is NOT set then we fallback to `super.uri()`
     *   which in most cases will contain `ERC1155._uri`;
     *
     * - if `_tokenURIs[tokenId]` is NOT set, and if the parents do not have a
     *   uri value set, then the result is empty.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];

        // If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
        return bytes(tokenURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenURI)) : super.uri(tokenId);
    }

    /**
     * @dev Sets `tokenURI` as the tokenURI of `tokenId`.
     */
    function _setURI(uint256 tokenId, string memory tokenURI) internal virtual {
        _tokenURIs[tokenId] = tokenURI;
        emit URI(uri(tokenId), tokenId);
    }

    /**
     * @dev Sets `baseURI` as the `_baseURI` for all tokens
     */
    function _setBaseURI(string memory baseURI) internal virtual {
        _baseURI = baseURI;
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
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
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
pragma solidity ^0.8.0;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Utils/Tracker.sol";

import "../Interfaces/IUpgradeNft.sol";
import "../Interfaces/IBedroomNft.sol";

/// @title Upgrader Contract
/// @author Sleepn
/// @notice The Upgrader Contract is used to upgrade a Bedroom NFT
contract Upgrader {
    /// @notice Bedroom NFT Contract address
    IBedroomNft public immutable bedroomNftContract;
    /// @notice Upgrade NFT Contract address
    IUpgradeNft public immutable upgradeNftContract;
    /// @notice Tracker Contract address
    Tracker public immutable trackerInstance;
    /// @notice Dex Contract address
    address public immutable dexAddress;

    /// @notice Upgrade NFT linked to a Bedroom NFT Event
    event UpgradeNftLinked(
        uint256 indexed bedroomNftId,
        uint256 indexed upgradeNftId,
        address owner
    );
    /// @notice Upgrade NFT unlinked from a Bedroom NFT Event
    event UpgradeNftUnlinked(
        uint256 indexed bedroomNftId,
        uint256 indexed upgradeNftId,
        address owner
    );

    /// @notice Score cannot be upgraded Error - Score cannot be greater than 100
    error ScoreCannotBeGreaterThan100(uint16 valueToAdd);
    /// @notice NFT not owned Error - Upgrade NFT is not owned by the user
    error NftNotOwned(uint256 tokenId, address caller);
    /// @notice Upgrade NFT already linked Error - Upgrade NFT is already linked to a Bedroom NFT
    error IsAlreadyLinked(uint256 tokenId);
    /// @notice Upgrade NFT is not linked Error - Upgrade NFT is not linked to a Bedroom NFT
    error IsNotLinked(uint256 tokenId);
    /// @notice Restricted Access Error - Wrong caller
    error RestrictedAccess(address caller);
    /// @notice Level too low Error - Level is too low to upgrade
    error LevelTooLow(uint16 levelMin, uint256 bedroomNftLevel);
    /// @notice State not updated Error - State is not updated in tracker contract
    error StateNotUpdated();

    /// @notice Initializer
    /// @param _bedroomNftContractAddr Bedroom NFT Contract address
    /// @param _dexAddress Dex Contract address
    constructor(address _bedroomNftContractAddr, address _dexAddress) {
        upgradeNftContract = IUpgradeNft(msg.sender);
        bedroomNftContract = IBedroomNft(_bedroomNftContractAddr);
        trackerInstance = new Tracker(
            _bedroomNftContractAddr,
            msg.sender
        );
        dexAddress = _dexAddress;
    }

    /// @notice Links an upgrade NFT to a Bedroom NFT
    /// @param _owner The owner of the upgrade NFT
    /// @param _bedroomNftId The ID of the bedroom NFT
    /// @param _upgradeNftId The ID of the upgrade NFT
    /// @param _designURI The new design URI of the bedroom NFT
    function linkUpgradeNft(
        address _owner,
        uint256 _bedroomNftId,
        uint256 _upgradeNftId,
        string memory _designURI
    ) external {
        /// @dev Checks who is calling the function
        if (msg.sender != dexAddress) {
            revert RestrictedAccess(msg.sender);
        }

        /// @dev Returns the data of the Bedroom NFT
        IBedroomNft.NftSpecifications memory nftSpecifications =
            bedroomNftContract.getSpecifications(_bedroomNftId);

        /// @dev Checks if the upgrade NFT is owned by the user
        if (
            nftSpecifications.owner != _owner
                || !trackerInstance.isUpgradeNftOwner(_upgradeNftId, _owner)
        ) {
            revert NftNotOwned(_upgradeNftId, _owner);
        }

        /// @dev Checks if the upgrade NFT is already linked to a Bedroom NFT
        (uint256 amountOwned, uint256 amountLinked) =
            trackerInstance.getUpgradeNftAmounts(_owner, _upgradeNftId);
        if (amountOwned == amountLinked) {
            revert IsAlreadyLinked(_upgradeNftId);
        }

        /// @dev Returns the data of the upgrade NFT
        (
            ,
            uint16 _level,
            uint16 _levelMin,
            uint16 _value,
            uint8 _attributeIndex,
            uint8 _valueToAdd,
            uint8 _typeNft
        ) = upgradeNftContract.getData(_upgradeNftId);

        /// @dev Checks the level of the Bedroom NFT
        if (nftSpecifications.level < _levelMin) {
            revert LevelTooLow(_levelMin, nftSpecifications.level);
        }

        if (_typeNft < 4) {
            /// @dev Checks if the NFT is level up
            nftSpecifications.level = _level == 0
                ? nftSpecifications.level
                : _level + uint16(nftSpecifications.level);
            /// @dev Checks if the NFT is value up
            nftSpecifications.value = _value == 0
                ? nftSpecifications.value
                : _value + uint16(nftSpecifications.value);
            /// @dev Checks if the NFT is attribute up
            if (_typeNft == 2) {
                uint16[4] memory scores = [
                    uint16(nftSpecifications.scores),
                    uint16(nftSpecifications.scores >> 16),
                    uint16(nftSpecifications.scores >> 32),
                    uint16(nftSpecifications.scores >> 48)
                ];
                if (scores[_attributeIndex] > 100) {
                    revert ScoreCannotBeGreaterThan100(_valueToAdd);
                }
                scores[_attributeIndex] = (
                    scores[_attributeIndex] + _valueToAdd
                ) > 100 ? 100 : scores[_attributeIndex] + _valueToAdd;
                nftSpecifications.scores = uint64(scores[0])
                    + (uint64(scores[1]) << 16) + (uint64(scores[2]) << 32)
                    + (uint64(scores[3]) << 48);
            }
            /// @dev Updates the Bedroom NFT
            bedroomNftContract.updateBedroomNft(
                _bedroomNftId,
                nftSpecifications.value,
                nftSpecifications.level,
                nftSpecifications.scores,
                _designURI
            );
        }
        /// @dev Links the upgrade NFT to the Bedroom NFT
        if (
            !trackerInstance.linkUpgradeNft(
                _owner, _bedroomNftId, _upgradeNftId
            )
        ) {
            revert StateNotUpdated();
        }
        emit UpgradeNftLinked(_bedroomNftId, _upgradeNftId, _owner);
    }

    /// @notice Uninks an upgrade NFT from a Bedroom NFT
    /// @param _owner The owner of the upgrade NFT
    /// @param _bedroomNftId The ID of the bedroom NFT
    /// @param _upgradeNftId The ID of the upgrade NFT
    /// @param _designURI The new design URI of the bedroom NFT
    function unlinkUpgradeNft(
        address _owner,
        uint256 _bedroomNftId,
        uint256 _upgradeNftId,
        string memory _designURI
    ) external {
        /// @dev Checks who is calling the function
        if (msg.sender != dexAddress && msg.sender != address(trackerInstance))
        {
            revert RestrictedAccess(msg.sender);
        }

        /// @dev Checks if the upgrade NFT is owned by the user
        if (!trackerInstance.isUpgradeNftOwner(_upgradeNftId, _owner)) {
            revert NftNotOwned(_upgradeNftId, _owner);
        }

        /// @dev Checks if the upgrade NFT is linked to the Bedroom NFT
        (, uint256 amountLinked) =
            trackerInstance.getUpgradeNftAmounts(_owner, _upgradeNftId);
        if (amountLinked == 0) {
            revert IsNotLinked(_upgradeNftId);
        }

        /// @dev Returns the data of the Bedroom NFT
        IBedroomNft.NftSpecifications memory nftSpecifications =
            bedroomNftContract.getSpecifications(_bedroomNftId);

        /// @dev Returns the data of the upgrade NFT
        (
            ,
            uint16 _level,
            ,
            uint16 _value,
            uint8 _attributeIndex,
            uint8 _valueToAdd,
            uint8 _typeNft
        ) = upgradeNftContract.getData(_upgradeNftId);

        if (_typeNft < 4) {
            /// @dev Checks if the NFT is level up
            nftSpecifications.level = _level == 0
                ? nftSpecifications.level
                : uint16(nftSpecifications.level) - _level;
            /// @dev Checks if the NFT is value up
            nftSpecifications.value = _value == 0
                ? nftSpecifications.value
                : uint16(nftSpecifications.value) - _value;
            /// @dev Checks if the NFT is attribute up
            if (_typeNft == 2) {
                uint16[4] memory scores = [
                    uint16(nftSpecifications.scores),
                    uint16(nftSpecifications.scores >> 16),
                    uint16(nftSpecifications.scores >> 32),
                    uint16(nftSpecifications.scores >> 48)
                ];
                scores[_attributeIndex] -= _valueToAdd;
                nftSpecifications.scores = uint64(scores[0])
                    + (uint64(scores[1]) << 16) + (uint64(scores[2]) << 32)
                    + (uint64(scores[3]) << 48);
            }
            /// @dev Updates the Bedroom NFT
            bedroomNftContract.updateBedroomNft(
                _bedroomNftId,
                nftSpecifications.value,
                nftSpecifications.level,
                nftSpecifications.scores,
                _designURI
            );
        }
        if (
            !trackerInstance.unlinkUpgradeNft(
                _owner, _bedroomNftId, _upgradeNftId
            )
        ) {
            revert StateNotUpdated();
        }
        emit UpgradeNftUnlinked(_bedroomNftId, _upgradeNftId, _owner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Tracker Contract
/// @author Sleepn
/// @notice The Tracker Contract is used to track the NFTs
contract Tracker {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev Struct to store the NFT IDs of a user
    struct NftsID {
        EnumerableSet.UintSet bedroomNfts;
        EnumerableSet.UintSet upgradeNfts;
    }
    /// @dev Struct to store the amounts owned of a NFT ID
    struct UpgradeNft {
        uint256 amountOwned;
        uint256 amountUsed;
        EnumerableSet.UintSet bedroomNftIds;
    }

    /// @dev Set of Upgrade NFTs ID settled
    EnumerableSet.UintSet private upgradeNftIdsSettled;

    /// @dev Maps the NFTs ID Sets to an owner
    mapping(address => NftsID) private ownerToNftsID;
    /// @dev Maps the Upgrade NFTs amounts to an owner and an NFT ID
    mapping(uint256 => mapping(address => UpgradeNft)) private upgradeNftsOwned;
    /// @dev Maps a set of owners to an Upgrade NFT ID
    mapping(uint256 => EnumerableSet.AddressSet) private upgradeNftToOwners;
    /// @dev Maps a set of Upgrade NFT IDs to a Bedroom NFT ID
    mapping(uint256 => EnumerableSet.UintSet) private bedroomNftToUpgradeNfts;

    /// @notice Bedroom NFT Contract address
    address public immutable bedroomNftContract;
    /// @notice Upgrade NFT Contract address
    address public immutable upgradeNftContract;
    /// @notice Upgrader Contract address
    address public immutable upgraderContract;

    /// @notice Restricted Access Error - Wrong caller
    error RestrictedAccess(address caller);
    /// @notice Invalid NFT ID Error - NFT ID is invalid
    error IdAlreadyUsed(uint256 tokenId);

    /// @notice BedroomNft ID Linked To Wallet Event
    event BedroomNftLinkedToWallet(
        uint256 indexed bedroomNftId,
        address indexed owner
    );
    /// @notice BedroomNft ID Unlinked From Wallet Event
    event BedroomNftUnlinkedFromWallet(
        uint256 indexed bedroomNftId,
        address indexed owner
    );
    /// @notice UpgradeNft ID Linked To Wallet Event
    event UpgradeNftLinkedToWallet(
        uint256 indexed upgradeNftId,
        address indexed owner
    );
    /// @notice UpgradeNft ID Unlinked From Wallet Event
    event UpgradeNftUnlinkedFromWallet(
        uint256 indexed upgradeNftId,
        address indexed owner
    );
    /// @notice UpgradeNft ID Linked To BedroomNft ID Event
    event UpgradeNftLinkedToBedroomNft(
        uint256 indexed upgradeNftId,
        uint256 indexed bedroomNftId
    );
    /// @notice UpgradeNft ID Unlinked From BedroomNft ID Event
    event UpgradeNftUnlinkedFromBedroomNft(
        uint256 indexed upgradeNftId,
        uint256 indexed bedroomNftId
    );

    /// @notice Constructor
    /// @param _bedroomNftAddress Bedroom NFT Contract address
    /// @param _upgradeNftAddress Upgrade NFT Contract address
    constructor(address _bedroomNftAddress, address _upgradeNftAddress) {
        bedroomNftContract = _bedroomNftAddress;
        upgradeNftContract = _upgradeNftAddress;
        upgraderContract = msg.sender;
    }

    /// @notice Gets the NFTs owned by an address
    /// @param _owner The address of the owner
    /// @return _bedroomNfts The Bedroom NFTs owned by the address
    /// @return _upgradeNfts The Upgrade NFTs owned by the address
    function getNftsID(address _owner)
        external
        view
        returns (uint256[] memory _bedroomNfts, uint256[] memory _upgradeNfts)
    {
        _bedroomNfts = ownerToNftsID[_owner].bedroomNfts.values();
        _upgradeNfts = ownerToNftsID[_owner].upgradeNfts.values();
    }

    /// @notice Adds a Bedroom NFT ID to the tracker
    /// @param _owner The owner of the NFT
    /// @param _tokenId The NFT ID
    /// @return stateUpdated Returns true if the update worked
    function addBedroomNft(address _owner, uint256 _tokenId)
        external
        returns (bool)
    {
        if (msg.sender != bedroomNftContract) {
            revert RestrictedAccess(msg.sender);
        }
        emit BedroomNftLinkedToWallet(_tokenId, _owner);
        return ownerToNftsID[_owner].bedroomNfts.add(_tokenId);
    }

    /// @notice Remove a Bedroom NFT from the tracker
    /// @param _owner The owner of the Bedroom NFT
    /// @param _newOwner The new owner of the Bedroom NFT
    /// @param _tokenId The ID of the Bedroom NFT
    /// @return stateUpdated Returns true if the update worked
    function removeBedroomNft(
        address _owner,
        address _newOwner,
        uint256 _tokenId
    ) external returns (bool) {
        if (msg.sender != bedroomNftContract) {
            revert RestrictedAccess(msg.sender);
        }
        for (
            uint256 i = 0; i < bedroomNftToUpgradeNfts[_tokenId].length(); i++
        ) {
            uint256 upgradeNftId = bedroomNftToUpgradeNfts[_tokenId].at(i);
            bool isRemoved = removeUpgradeNft(_owner, upgradeNftId);
            bool idAdded = addUpgradeNft(_newOwner, upgradeNftId);
            if (!isRemoved || !idAdded) {
                return false;
            }
        }
        if (ownerToNftsID[_owner].bedroomNfts.remove(_tokenId)) {
            emit BedroomNftUnlinkedFromWallet(_tokenId, _owner);
            return true;
        }
        return false;
    }

    /// @notice Returns true if the owner of the bedroom NFT is the wallet address
    /// @param _tokenId The ID of the bedroom NFT
    /// @param _wallet The wallet address of the owner
    /// @return isOwner True if the owner of the bedroom NFT is the wallet address
    function isBedroomNftOwner(uint256 _tokenId, address _wallet)
        external
        view
        returns (bool isOwner)
    {
        isOwner = ownerToNftsID[_wallet].bedroomNfts.contains(_tokenId);
    }

    /// @notice Returns the amount of bedroom NFTs owned by an owner
    /// @param _owner The owner of the bedroom NFTs
    /// @return nftsAmount The amount of bedroom NFTs owned by the owner
    function getBedroomNftsAmount(address _owner)
        external
        view
        returns (uint256 nftsAmount)
    {
        nftsAmount = ownerToNftsID[_owner].bedroomNfts.length();
    }

    /// @notice Adds an upgrade NFT ID to the settled upgrade NFT IDs
    /// @param _tokenId The ID of the upgrade NFT
    function settleUpgradeNftData(uint256 _tokenId) external {
        if (msg.sender != upgradeNftContract) {
            revert RestrictedAccess(msg.sender);
        }
        if (upgradeNftIdsSettled.contains(_tokenId)) {
            revert IdAlreadyUsed(_tokenId);
        }
        upgradeNftIdsSettled.add(_tokenId);
    }

    /// @notice Returns the upgrade NFT IDs that have been settled
    /// @return nftIdsSettled The upgrade NFT IDs that have been settled
    function getUpgradeNftSettled()
        external
        view
        returns (uint256[] memory nftIdsSettled)
    {
        nftIdsSettled = upgradeNftIdsSettled.values();
    }

    /// @notice Returns true if the Upgrade NFT ID is settled
    /// @param _tokenId The ID of the Upgrade NFT
    /// @return isSettled True if the Upgrade NFT ID is settled
    function isIdSettled(uint256 _tokenId)
        external
        view
        returns (bool isSettled)
    {
        isSettled = upgradeNftIdsSettled.contains(_tokenId);
    }

    /// @notice Adds an upgrade NFT to the tracker
    /// @param _owner The owner of the upgrade NFT
    /// @param _tokenId The ID of the upgrade NFT
    /// @return stateUpdated Returns true if the update worked
    function addUpgradeNft(address _owner, uint256 _tokenId)
        public
        returns (bool)
    {
        if (
            msg.sender != upgradeNftContract
                && msg.sender != bedroomNftContract
        ) {
            revert RestrictedAccess(msg.sender);
        }
        ownerToNftsID[_owner].upgradeNfts.add(_tokenId);
        upgradeNftToOwners[_tokenId].add(_owner);
        ++upgradeNftsOwned[_tokenId][_owner].amountOwned;
        emit UpgradeNftLinkedToWallet(_tokenId, _owner);
        return true;
    }

    /// @notice Removes an upgrade NFT from the tracker
    /// @param _owner The owner of the upgrade NFT
    /// @param _tokenId The ID of the upgrade NFT
    /// @return stateUpdated Returns true if the update worked
    function removeUpgradeNft(address _owner, uint256 _tokenId)
        public
        returns (bool)
    {
        if (
            msg.sender != upgradeNftContract
                && msg.sender != bedroomNftContract
        ) {
            revert RestrictedAccess(msg.sender);
        }
        --upgradeNftsOwned[_tokenId][_owner].amountOwned;
        if (upgradeNftsOwned[_tokenId][_owner].amountOwned == 0) {
            bool isRemoved1 =
                ownerToNftsID[_owner].upgradeNfts.remove(_tokenId);
            bool isRemoved2 = upgradeNftToOwners[_tokenId].remove(_owner);
            if (!isRemoved1 || !isRemoved2) {
                return false;
            }
        }
        emit UpgradeNftUnlinkedFromWallet(_tokenId, _owner);
        return true;
    }

    /// @notice Returns true if the given address is the owner of the given Upgrade NFT
    /// @param _tokenId The ID of the Upgrade NFT to check
    /// @param _wallet The address to check
    /// @return isOwner True if the given address is the owner of the given Upgrade NFT
    function isUpgradeNftOwner(uint256 _tokenId, address _wallet)
        external
        view
        returns (bool isOwner)
    {
        isOwner = ownerToNftsID[_wallet].upgradeNfts.contains(_tokenId);
    }

    /// @notice Returns the amount of Upgrade NFTs owned by a wallet
    /// @param _owner The owner wallet address
    /// @return nftsAmount The amount of Upgrade NFTs owned by the wallet
    function getUpgradeNftsAmount(address _owner)
        external
        view
        returns (uint256 nftsAmount)
    {
        EnumerableSet.UintSet storage set = ownerToNftsID[_owner].upgradeNfts;
        for (uint256 i = 0; i < set.length(); ++i) {
            uint256 tokenId = set.at(i);
            nftsAmount += upgradeNftsOwned[tokenId][_owner].amountOwned;
        }
    }

    /// @notice Returns the amounts of a specific Upgrade NFT owned by a specific wallet
    /// @param _owner The owner wallet address
    /// @param _tokenId The ID of the Upgrade NFT
    /// @return amountOwned The amount of Upgrade NFTs owned by the wallet
    /// @return amountUsed The amount of Upgrade NFTs used by the wallet
    function getUpgradeNftAmounts(address _owner, uint256 _tokenId)
        external
        view
        returns (uint256 amountOwned, uint256 amountUsed)
    {
        amountOwned = upgradeNftsOwned[_tokenId][_owner].amountOwned;
        amountUsed = upgradeNftsOwned[_tokenId][_owner].amountUsed;
    }

    /// @notice Returns the owners of a specified Upgrade NFT
    /// @param _tokenId The upgrade NFT ID
    /// @return owners Owners of the specified Upgrade NFT
    function getUpgradeNftOwners(uint256 _tokenId)
        external
        view
        returns (address[] memory owners)
    {
        owners = upgradeNftToOwners[_tokenId].values();
    }

    /// @notice Links an upgrade NFT to a Bedroom NFT
    /// @param _owner The owner of the upgrade NFT
    /// @param _bedroomNftId The ID of the bedroom NFT
    /// @param _upgradeNftId The ID of the upgrade NFT
    /// @return stateUpdated Returns true if the update worked
    function linkUpgradeNft(
        address _owner,
        uint256 _bedroomNftId,
        uint256 _upgradeNftId
    ) external returns (bool) {
        if (msg.sender != upgraderContract) {
            revert RestrictedAccess(msg.sender);
        }
        bedroomNftToUpgradeNfts[_bedroomNftId].add(_upgradeNftId);
        ++upgradeNftsOwned[_upgradeNftId][_owner].amountUsed;
        emit UpgradeNftLinkedToBedroomNft(_upgradeNftId, _bedroomNftId);
        return true;
    }

    /// @notice Unlinks an upgrade NFT to a Bedroom NFT
    /// @param _owner The owner of the upgrade NFT
    /// @param _bedroomNftId The ID of the bedroom NFT
    /// @param _upgradeNftId The ID of the upgrade NFT
    /// @return stateUpdated Returns true if the update worked
    function unlinkUpgradeNft(
        address _owner,
        uint256 _bedroomNftId,
        uint256 _upgradeNftId
    ) external returns (bool) {
        if (msg.sender != upgraderContract) {
            revert RestrictedAccess(msg.sender);
        }
        --upgradeNftsOwned[_upgradeNftId][_owner].amountUsed;
        if (upgradeNftsOwned[_upgradeNftId][_owner].amountUsed == 0) {
            if (!bedroomNftToUpgradeNfts[_bedroomNftId].remove(_upgradeNftId))
            {
                return false;
            }
        }
        emit UpgradeNftUnlinkedFromBedroomNft(_upgradeNftId, _bedroomNftId);
        return true;
    }

    /// @notice Returns the upgrade NFTs linked to a Bedroom NFT
    /// @param _bedroomNftId The ID of the bedroom NFT
    /// @return upgradeNfts The upgrade NFTs linked to the Bedroom NFT
    function getUpgradeNfts(uint256 _bedroomNftId)
        external
        view
        returns (uint256[] memory upgradeNfts)
    {
        upgradeNfts = bedroomNftToUpgradeNfts[_bedroomNftId].values();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IBedroomNft.sol";

/// @title Interface of the Upgrade Nft Contract
/// @author Sleepn
/// @notice An update NFT is used to upgrade a Bedroom NFT
interface IUpgradeNft is IERC1155 {
    //// @notice Upgrade NFT Minted Event
    event UpgradeNftMinted(
        address indexed owner, uint256 tokenId, uint256 amount
    );
    /// @notice Upgrade NFT Data Settled Event
    event UpgradeNftDataSettled(
        uint256 indexed tokenId,
        string _designURI,
        uint24 _data,
        uint16 _level,
        uint16 _levelMin,
        uint16 _value,
        uint8 _attributeIndex,
        uint8 _valueToAdd,
        uint8 _typeNft
    );
    /// @notice Withdraw Money Event
    event WithdrawMoney(address indexed owner, uint256 amount);

    /// @notice Restricted Access Error - Wrong caller
    error RestrictedAccess(address caller);
    /// @notice Different Length Error - Arrays length
    error DifferentLength();
    /// @notice Upgrade Nft already linked Error - Upgrade NFTs have to be unlinked before any transfer
    error UpgradeNftAlreadyLinked(uint256 tokenId);
    /// @notice State not updated Error - State is not updated in tracker contract
    error StateNotUpdated();

    /// @notice Returns the  data of a NFT
    /// @param _tokenId NFT ID
    /// @return _data NFT additionnal data
    /// @return _level NFT level
    /// @return _levelMin NFT level min required
    /// @return _value NFT value
    /// @return _attributeIndex Score attribute index
    /// @return _valueToAdd Value to add to the score
    /// @return _typeNft NFT Type
    function getData(uint256 _tokenId)
        external
        view
        returns (
            uint24 _data,
            uint16 _level,
            uint16 _levelMin,
            uint16 _value,
            uint8 _attributeIndex,
            uint8 _valueToAdd,
            uint8 _typeNft
        );

    /// @notice Settles the URI of a NFT
    /// @param _tokenId Id of the NFT
    /// @param _tokenURI Uri of the NFT
    /// @dev This function can only be called by the owner of the contract
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external;

    /// @notice Settles baseURI as the _baseURI for all tokens
    /// @param _baseURI Base URI of NFTs
    /// @dev This function can only be called by the owner of the contract
    function setBaseURI(string memory _baseURI) external;

    /// @notice Settles dev wallet address
    /// @param _newDevWalletAddress New dev wallet address
    /// @dev This function can only be called by the owner of the contract
    function setDevAddress(address _newDevWalletAddress) external;

    /// @notice Settles the data of a NFT
    /// @param _tokenId NFT ID
    /// @param _designURI Upgrade Nft URI
    /// @param _data Additionnal data (optionnal)
    /// @param _level Level to add to the Bedroom Nft
    /// @param _levelMin Bedroom Nft Level min required
    /// @param _value Upgrade Nft value
    /// @param _attributeIndex Score involved (optionnal)
    /// @param _valueToAdd Value to add to the score (optionnal)
    /// @param _typeNft NFT Type
    /// @dev This function can only be called by the owner or the dev Wallet
    function setData(
        uint256 _tokenId,
        string memory _designURI,
        uint96 _data,
        uint96 _level,
        uint96 _levelMin,
        uint96 _value,
        uint96 _attributeIndex,
        uint96 _valueToAdd,
        uint96 _typeNft
    ) external;

    /// @notice Mints a new Upgrade Nft
    /// @param _tokenId NFT ID
    /// @param _amount Amount of tokens
    /// @param _account Upgrade Nft Owner
    /// @dev This function can only be called by the owner or the dev Wallet or the Dex contract
    function mint(uint256 _tokenId, uint256 _amount, address _account)
        external;

    /// @notice Mints Upgrade Nfts per batch
    /// @param _tokenIds NFT IDs
    /// @param _amounts Amount of tokens
    /// @param _accounts Upgrade Nft Owners
    /// @dev This function can only be called by the owner or the dev Wallet or the Dex contract
    function mintBatch(
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        address[] calldata _accounts
    ) external;

    /// @notice Withdraws the money from the contract
    /// @param _token Address of the token to withdraw
    /// @dev This function can only be called by the owner or the dev Wallet
    function withdrawMoney(IERC20 _token) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IUpgradeNft.sol";

/// @title Interface of the Bedroom NFT Contract
/// @author Sleepn
/// @notice Bedroom NFT is the main NFT of Sleepn app
interface IBedroomNft is IERC1155 {
    /// @notice Scores of a Bedroom NFT
    struct NftSpecifications {
        address owner;
        uint64 scores;
        uint256 level;
        uint256 value;
    }

    /// @notice Emits an event when a Bedroom NFT is minted
    event BedroomNftMinted(
        address indexed owner,
        uint256 indexed requestID,
        uint256 tokenId,
        uint16 ambiance,
        uint16 quality,
        uint16 luck,
        uint16 comfortability
    );
    /// @notice Emits an event when a Bedroom NFT Score is updated
    event BedroomNftUpdated(
        address indexed owner, uint256 indexed tokenId, uint256 timestamp
    );
    /// @notice Returned Request ID, Invoker and Token ID
    event RequestedRandomness(
        uint256 indexed requestId, address invoker, uint256 indexed tokenId
    );
    /// @notice Returned Random Numbers Event, Invoker and Token ID
    event ReturnedRandomness(
        uint256[] randomWords,
        uint256 indexed requestId,
        uint256 indexed tokenId
    );
    /// @notice Base URI Changed Event
    event BaseURIChanged(string baseURI);
    /// @notice Chainlink Data Updated Event
    event ChainlinkDataUpdated(
        uint32 callbackGasLimit,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint16 requestConfirmations
    );
    /// @notice Withdraw Money Event
    event WithdrawMoney(address indexed owner, uint256 amount);

    /// @notice Restricted Access Error - Wrong caller
    error RestrictedAccess(address caller);

    /// @notice Returns the number of Bedroom NFTs in existence
    /// @return nftsNumber Representing the number of Bedroom NFTs in existence
    function getNftsNumber() external view returns (uint256 nftsNumber);

    /// @notice Returns the specifications of a Bedroom NFT
    /// @param _tokenId Id of the Bedroom NFT
    /// @return nftSpecifications Specifications of the Bedroom NFT
    function getSpecifications(uint256 _tokenId)
        external
        view
        returns (NftSpecifications memory nftSpecifications);

    /// @notice Returns the specifications of some Bedroom NFTs
    /// @param _tokenIds Ids of the Bedroom NFTs
    /// @return nftSpecifications Specifications of the Bedroom NFTs
    function getSpecificationsBatch(uint256[] calldata _tokenIds)
        external
        view
        returns (NftSpecifications[] memory nftSpecifications);

    /// @notice Returns the data of a NFT
    /// @param _tokenId The id of the NFT
    /// @return _ambiance Ambiance Score
    /// @return _quality Quality Score
    /// @return _luck Luck Score
    /// @return _comfortability Comfortability Score
    /// @return _owner NFT owner address
    /// @return _level NFT level
    /// @return _value NFT value
    function getData(uint256 _tokenId)
        external
        view
        returns (
            uint16 _ambiance,
            uint16 _quality,
            uint16 _luck,
            uint16 _comfortability,
            address _owner,
            uint256 _level,
            uint256 _value
        );

    /// @notice Returns the data of some Bedroom NFTs
    /// @param _tokenIds Nfts IDs
    /// @return _ambiance Ambiance Score
    /// @return _quality Quality Score
    /// @return _luck Luck Score
    /// @return _comfortability Comfortability Score
    /// @return _owners NFT owner address
    /// @return _levels NFT level
    /// @return _values NFT value
    function getDataBatch(uint256[] calldata _tokenIds)
        external
        view
        returns (
            uint16[] memory _ambiance,
            uint16[] memory _quality,
            uint16[] memory _luck,
            uint16[] memory _comfortability,
            address[] memory _owners,
            uint256[] memory _levels,
            uint256[] memory _values
        );

    /// @notice Updates chainlink variables
    /// @param _callbackGasLimit Callback Gas Limit
    /// @param _subscriptionId Chainlink subscription Id
    /// @param _keyHash Chainlink Key Hash
    /// @param _requestConfirmations Number of request confirmations
    /// @dev This function can only be called by the owner of the contract
    function updateChainlink(
        uint32 _callbackGasLimit,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint16 _requestConfirmations
    ) external;

    /// @notice Settles initial NFT Design URI
    /// @param _initialURI New URI
    /// @dev This function can only be called by the owner of the contract
    function setInitialDesignURI(string calldata _initialURI)
        external;

    /// @notice Settles the URI of a NFT
    /// @param _tokenId Id of the NFT
    /// @param _tokenURI Uri of the NFT
    /// @dev This function can only be called by the owner of the contract
    function setTokenURI(uint256 _tokenId, string memory _tokenURI)
        external;

    /// Settles baseURI as the _baseURI for all tokens
    /// @param _baseURI Base URI of NFTs
    /// @dev This function can only be called by the owner of the contract
    function setBaseURI(string memory _baseURI) external;

    /// @notice Withdraws the money from the contract
    /// @param _token Address of the token to withdraw
    /// @dev This function can only be called by the owner or the dev Wallet
    function withdrawMoney(IERC20 _token) external;

    /// @notice Launches the procedure to create an NFT
    /// @param _owner Owner of the NFT
    /// @return _tokenId NFT ID
    /// @dev This function can only be called by Dex Contract
    function mintBedroomNft(address _owner)
        external
        returns (uint256 _tokenId);

    /// @notice Launches the procedure to create an NFT - Batch Transaction
    /// @param _owners Nfts Owners
    /// @return _tokenIds NFT IDs
    /// @dev This function can only be called by Dex Contract
    function mintBedroomNfts(address[] calldata _owners)
        external
        returns (uint256[] memory _tokenIds);

    /// @notice Updates a Bedroom NFT
    /// @param _tokenId Id of the NFT
    /// @param _newValue value of the NFT
    /// @param _newLevel level of the NFT
    /// @param _newScores Scores of the NFT
    /// @param _newDesignURI Design URI of the NFT
    function updateBedroomNft(
        uint256 _tokenId,
        uint256 _newValue,
        uint256 _newLevel,
        uint64 _newScores,
        string memory _newDesignURI
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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