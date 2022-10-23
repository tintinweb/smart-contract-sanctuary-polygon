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
    /// @notice Wrong Amount Error - The user does not have enough NFT
    error WrongAmount(uint256 upgradeNftId, uint256 amount);

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

    /// @notice Upgrade NFT Data
    struct UpgradeNftData {
        uint8 _attributeIndex;
        uint8 _valueToAdd;
        uint8 _typeNft;
        uint16 _level;
        uint16 _levelMin;
        uint16 _value;
        uint256 amountOwned;
        uint256 amountLinked;
    }

    /// @notice Links an upgrade NFT to a Bedroom NFT
    /// @param _owner The owner of the upgrade NFT
    /// @param _bedroomNftId The ID of the bedroom NFT
    /// @param _upgradeNftId The ID of the upgrade NFT
    /// @param _amount Amount of upgrade NFTs
    /// @param _designURI The new design URI of the bedroom NFT
    function linkUpgradeNft(
        address _owner,
        uint256 _bedroomNftId,
        uint256 _upgradeNftId,
        uint256 _amount,
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
        ) {
            revert NftNotOwned(_upgradeNftId, _owner);
        }

        /// @dev Memory allocation for the upgrade NFT data
        UpgradeNftData memory upgradeNftData;

        /// @dev Checks if the upgrade NFT is already linked to a Bedroom NFT
        (upgradeNftData.amountOwned, upgradeNftData.amountLinked) =
            trackerInstance.getUpgradeNftAmounts(_owner, _upgradeNftId);
        if (_amount > (upgradeNftData.amountOwned - upgradeNftData.amountLinked)) {
            revert IsAlreadyLinked(_upgradeNftId);
        }

        /// @dev Returns the data of the upgrade NFT
        (
            ,
            upgradeNftData._level,
            upgradeNftData._levelMin,
            upgradeNftData._value,
            upgradeNftData._attributeIndex,
            upgradeNftData._valueToAdd,
            upgradeNftData._typeNft
        ) = upgradeNftContract.getData(_upgradeNftId);

        /// @dev Checks the level of the Bedroom NFT
        if (nftSpecifications.level < upgradeNftData._levelMin) {
            revert LevelTooLow(upgradeNftData._levelMin, nftSpecifications.level);
        }

        if (upgradeNftData._typeNft < 4) {
            /// @dev Checks if the NFT is level up
            nftSpecifications.level = upgradeNftData._level == 0
                ? nftSpecifications.level
                : upgradeNftData._level + uint16(nftSpecifications.level);
            /// @dev Checks if the NFT is value up
            nftSpecifications.value = upgradeNftData._value == 0
                ? nftSpecifications.value
                : upgradeNftData._value + uint16(nftSpecifications.value);
            /// @dev Checks if the NFT is attribute up
            if (upgradeNftData._typeNft == 2) {
                uint16[4] memory scores = [
                    uint16(nftSpecifications.scores),
                    uint16(nftSpecifications.scores >> 16),
                    uint16(nftSpecifications.scores >> 32),
                    uint16(nftSpecifications.scores >> 48)
                ];
                scores[upgradeNftData._attributeIndex] = (
                    scores[upgradeNftData._attributeIndex] + upgradeNftData._valueToAdd
                ) > 100 ? 100 : scores[upgradeNftData._attributeIndex] + upgradeNftData._valueToAdd;
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
                _owner, 
                _bedroomNftId, 
                _upgradeNftId, 
                _amount
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
    /// @param _amount Amount of upgrade NFTs
    /// @param _designURI The new design URI of the bedroom NFT
    function unlinkUpgradeNft(
        address _owner,
        uint256 _bedroomNftId,
        uint256 _upgradeNftId,
        uint256 _amount,
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

        /// @dev Memory allocation for the upgrade NFT data
        UpgradeNftData memory upgradeNftData;

        /// @dev Checks if the upgrade NFT is linked to the Bedroom NFT
        (upgradeNftData.amountOwned, upgradeNftData.amountLinked) =
            trackerInstance.getUpgradeNftAmounts(_owner, _upgradeNftId);
        if (_amount > upgradeNftData.amountOwned) {
            revert WrongAmount(_upgradeNftId, _amount);
        }
        if (_amount > upgradeNftData.amountLinked) {
            revert IsNotLinked(_upgradeNftId);
        }

        /// @dev Returns the data of the Bedroom NFT
        IBedroomNft.NftSpecifications memory nftSpecifications =
            bedroomNftContract.getSpecifications(_bedroomNftId);

        /// @dev Returns the data of the upgrade NFT
        (
            ,
            upgradeNftData._level,
            ,
            upgradeNftData._value,
            upgradeNftData._attributeIndex,
            upgradeNftData._valueToAdd,
            upgradeNftData._typeNft
        ) = upgradeNftContract.getData(_upgradeNftId);

        if (upgradeNftData._typeNft < 4) {
            /// @dev Checks if the NFT is level up
            nftSpecifications.level = upgradeNftData._level == 0
                ? nftSpecifications.level
                : uint16(nftSpecifications.level) - upgradeNftData._level;
            /// @dev Checks if the NFT is value up
            nftSpecifications.value = upgradeNftData._value == 0
                ? nftSpecifications.value
                : uint16(nftSpecifications.value) - upgradeNftData._value;
            /// @dev Checks if the NFT is attribute up
            if (upgradeNftData._typeNft == 2) {
                uint16[4] memory scores = [
                    uint16(nftSpecifications.scores),
                    uint16(nftSpecifications.scores >> 16),
                    uint16(nftSpecifications.scores >> 32),
                    uint16(nftSpecifications.scores >> 48)
                ];
                scores[upgradeNftData._attributeIndex] -= upgradeNftData._valueToAdd;
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
                _owner, 
                _bedroomNftId,
                _upgradeNftId, 
                _amount
            )
        ) {
            revert StateNotUpdated();
        }
        emit UpgradeNftUnlinked(_bedroomNftId, _upgradeNftId, _owner);
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
        address indexed owner,
        uint256 indexed upgradeNftId,
        uint256 amount
    );
    /// @notice UpgradeNft ID Unlinked From Wallet Event
    event UpgradeNftUnlinkedFromWallet(
        address indexed owner,
        uint256 indexed upgradeNftId,
        uint256 amount
    );
    /// @notice UpgradeNft ID Linked To BedroomNft ID Event
    event UpgradeNftLinkedToBedroomNft(
        uint256 indexed upgradeNftId,
        uint256 indexed bedroomNftId,
        uint256 amount
    );
    /// @notice UpgradeNft ID Unlinked From BedroomNft ID Event
    event UpgradeNftUnlinkedFromBedroomNft(
        uint256 indexed upgradeNftId,
        uint256 indexed bedroomNftId,
        uint256 amount
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
            uint256 amount = upgradeNftsOwned[upgradeNftId][_owner].amountOwned;
            bool isRemoved = removeUpgradeNft(_owner, upgradeNftId, amount);
            bool idAdded = addUpgradeNft(_newOwner, upgradeNftId, amount);
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
    /// @param _amount Amount of upgrade NFTs
    /// @return stateUpdated Returns true if the update worked
    function addUpgradeNft(
        address _owner, 
        uint256 _tokenId, 
        uint256 _amount
    )
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
        upgradeNftsOwned[_tokenId][_owner].amountOwned += _amount;
        emit UpgradeNftLinkedToWallet(_owner, _tokenId, _amount);
        return true;
    }

    /// @notice Removes an upgrade NFT from the tracker
    /// @param _owner The owner of the upgrade NFT
    /// @param _tokenId The ID of the upgrade NFT
    /// @param _amount Amount of upgrade NFTs
    /// @return stateUpdated Returns true if the update worked
    function removeUpgradeNft(
        address _owner, 
        uint256 _tokenId, 
        uint256 _amount
    )
        public
        returns (bool)
    {
        if (
            msg.sender != upgradeNftContract
                && msg.sender != bedroomNftContract
        ) {
            revert RestrictedAccess(msg.sender);
        }
        upgradeNftsOwned[_tokenId][_owner].amountOwned -= _amount;
        if (upgradeNftsOwned[_tokenId][_owner].amountOwned == 0) {
            bool isRemoved1 =
                ownerToNftsID[_owner].upgradeNfts.remove(_tokenId);
            bool isRemoved2 = upgradeNftToOwners[_tokenId].remove(_owner);
            if (!isRemoved1 || !isRemoved2) {
                return false;
            }
        }
        emit UpgradeNftUnlinkedFromWallet(_owner, _tokenId, _amount);
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
    /// @param _amount Amount of upgrade NFTs
    /// @return stateUpdated Returns true if the update worked
    function linkUpgradeNft(
        address _owner,
        uint256 _bedroomNftId,
        uint256 _upgradeNftId,
        uint256 _amount
    ) external returns (bool) {
        if (msg.sender != upgraderContract) {
            revert RestrictedAccess(msg.sender);
        }
        bedroomNftToUpgradeNfts[_bedroomNftId].add(_upgradeNftId);
        upgradeNftsOwned[_upgradeNftId][_owner].amountUsed += _amount;
        emit UpgradeNftLinkedToBedroomNft(_upgradeNftId, _bedroomNftId, _amount);
        return true;
    }

    /// @notice Unlinks an upgrade NFT to a Bedroom NFT
    /// @param _owner The owner of the upgrade NFT
    /// @param _bedroomNftId The ID of the bedroom NFT
    /// @param _upgradeNftId The ID of the upgrade NFT
    /// @param _amount Amount of upgrade NFTs
    /// @return stateUpdated Returns true if the update worked
    function unlinkUpgradeNft(
        address _owner,
        uint256 _bedroomNftId,
        uint256 _upgradeNftId,
        uint256 _amount
    ) external returns (bool) {
        if (msg.sender != upgraderContract) {
            revert RestrictedAccess(msg.sender);
        }
        upgradeNftsOwned[_upgradeNftId][_owner].amountUsed -= _amount;
        if (upgradeNftsOwned[_upgradeNftId][_owner].amountUsed == 0) {
            if (!bedroomNftToUpgradeNfts[_bedroomNftId].remove(_upgradeNftId))
            {
                return false;
            }
        }
        emit UpgradeNftUnlinkedFromBedroomNft(_upgradeNftId, _bedroomNftId, _amount);
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