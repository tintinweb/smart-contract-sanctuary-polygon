// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import
    "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./Interfaces/ISleep.sol";
import "./Interfaces/IHealth.sol";
import "./Interfaces/IBedroomNft.sol";
import "./Interfaces/IUpgradeNft.sol";
import "./Interfaces/ITracker.sol";
import "./Interfaces/IUpgrader.sol";

/// @title GetSleepn Decentralized Exchange Contract
/// @author Sleepn
/// @notice This contract can be use to mint and upgrade a Bedroom NFT
contract Dex is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Sleep Token Contract
    ISleep public sleepTokenInstance;

    /// @notice Health Token Contract
    IHealth public healthTokenInstance;

    /// @notice Bedroom NFT Contract
    IBedroomNft public bedroomNftInstance;

    /// @notice UpgradeNFT Contract
    IUpgradeNft public upgradeNftInstance;

    /// @notice Tracker Contract
    ITracker public trackerInstance;

    /// @notice Upgrader Contract
    IUpgrader public upgraderInstance;

    /// @notice Dex Contract address
    address public teamWallet;

    /// @dev Dev Wallet
    address private devWallet;

    /// @notice Payment Token
    IERC20Upgradeable public paymentToken;

    /// @notice Bedroom NFT Purchase cost
    uint256 public bedroomNftPurchaseCost;

    /// @notice Packs costs
    struct Pack {
        string designURI; // Design Id
        uint256 price; // Price
        uint256[] upgradeIds; // UpgradeIds
    }

    /// @notice Upgrade Nft Buying Data
    struct UpgradeNft {
        bool isAvailable; // Is available ?
        uint256 cost; // Cost
        uint256 amountAvailable; // Amount available
    }

    /// @notice Upgrade Nft Buying Data depending on the id of the Upgrade Nft
    mapping(uint256 => UpgradeNft) private upgradeNftBuyingData;

    /// @notice Pack costs depending on the Pack ID
    mapping(uint256 => Pack) private packCosts;

    /// @notice Bedroom NFT Purchased Event
    event BedroomNftPurchased(
        address indexed owner, uint256 indexed bedroomNftId, uint256 price
    );
    /// @notice Upgrade NFT Purchased Event
    event UpgradeNftPurchased(
        address indexed owner, uint256 indexed upgradeNftId, uint256 price
    );
    /// @notice Pack Purchased Event
    event PackPurchased(
        address indexed owner,
        uint256 indexed packId,
        uint256 bedroomNftId,
        uint256 price
    );
    /// @notice Withdraw Money Event
    event WithdrawMoney(address indexed receiver, uint256 price);
    /// @notice Bedroom NFT Purchase Cost Setted Event
    event BedroomNftPurchaseCostSetted(uint256 price);
    /// @notice Pack Cost Setted Event
    event PackCostSetted(uint256 packId, uint256 price);
    /// @notice Upgrade NFT Data Setted Event
    event UpgradeNftBuyingDataSetted(
        uint256 upgradeNftId, uint256 amountAvailable, bool isAvailable
    );
    /// @notice Upgrade Nft linked to a Bedroom Nft Event
    event UpgradeNftLinkedToBedroomNft(
        uint256 indexed bedroomNftId,
        uint256 indexed upgradeNftId,
        string designURI
    );
    /// @notice Upgrade Nft unlinked from a Bedroom Nft Event
    event UpgradeNftUnlinkedFromBedroomNft(
        uint256 indexed bedroomNftId,
        uint256 indexed upgradeNftId,
        string designURI
    );

    /// @notice Restricted Access Error - Wrong caller
    error RestrictedAccess(address caller);
    /// @notice Upgrade Nft not available Error - Upgrade Nft is not available
    error UpgradeNftNotAvailable(uint256 tokenId);

    /// @dev Constructor
    /// @param _teamWallet Team Wallet address
    function initialize(address _teamWallet) public initializer {
        __Ownable_init();
        teamWallet = _teamWallet;
    }

    /// @notice Settles contracts addresses
    /// @param _sleepToken Address of the Sleep Token contract
    /// @param _healthToken Address of the Health Token contract
    /// @param _bedroomNft Address of the Bedroom NFT contract
    /// @param _upgradeNft Address of the Upgrade NFT contract
    /// @param _tracker Address of the Tracker contract
    /// @param _upgrader Address of the Upgrader contract
    /// @param _teamWallet New Team Wallet address
    /// @param _devWallet New Dev Wallet address
    /// @param _tokenAddress New Payment Token contract address
    /// @dev This function can only be called by the owner of the contract
    function setAddresses(
        ISleep _sleepToken,
        IHealth _healthToken,
        IBedroomNft _bedroomNft,
        IUpgradeNft _upgradeNft,
        ITracker _tracker,
        IUpgrader _upgrader,
        address _teamWallet,
        address _devWallet,
        IERC20Upgradeable _tokenAddress
    ) external onlyOwner {
        sleepTokenInstance = _sleepToken;
        bedroomNftInstance = _bedroomNft;
        upgradeNftInstance = _upgradeNft;
        trackerInstance = _tracker;
        upgraderInstance = _upgrader;
        teamWallet = _teamWallet;
        devWallet = _devWallet;
        paymentToken = _tokenAddress;
        healthTokenInstance = _healthToken;
    }

    /// @notice Settles NFTs purchase price
    /// @param _price Purchase price of the NFT
    /// @dev This function can only be called by the owner of the contract
    function setBuyingPrice(uint256 _price) external onlyOwner {
        bedroomNftPurchaseCost = _price;
        emit BedroomNftPurchaseCostSetted(_price);
    }

    /// @notice Settles Packs data
    /// @param _upgradeIds Ids of the Upgrade Nfts
    /// @param _designURI Bedroom NFT Design URI
    /// @param _price Purchase price of the Pack
    /// @param _packId Pack ID
    /// @dev This function can only be called by the owner of the contract or the dev wallet
    function setPackPrice(
        uint256[] calldata _upgradeIds,
        string calldata _designURI,
        uint256 _price,
        uint256 _packId
    ) external {
        if (msg.sender != owner() && msg.sender != devWallet) {
            revert RestrictedAccess(msg.sender);
        }
        packCosts[_packId] = Pack(_designURI, _price, _upgradeIds);
        emit PackCostSetted(_packId, _price);
    }

    /// @notice Settles Upgrade NFTs purchase price
    /// @param _upgradeId Id of the Upgrade Nft
    /// @param _price Purchase price of the Upgrade Nft
    /// @param _amountAvailable Amount available of the Upgrade Nft
    /// @param _isAvailable Is the Upgrade Nft available ?
    /// @dev This function can only be called by the owner of the contract or the dev wallet
    function setUpgradeBuyingData(
        uint256 _upgradeId,
        uint256 _price,
        uint256 _amountAvailable,
        bool _isAvailable
    ) external {
        if (msg.sender != owner() && msg.sender != devWallet) {
            revert RestrictedAccess(msg.sender);
        }
        upgradeNftBuyingData[_upgradeId] =
            UpgradeNft(_isAvailable, _price, _amountAvailable);
        emit UpgradeNftBuyingDataSetted(
            _upgradeId, _amountAvailable, _isAvailable
            );
    }

    /// @notice Settles Upgrade NFTs purchase price - Batch Transaction
    /// @param _upgradeIds IDs of the Upgrade NFTs
    /// @param _prices Purchase prices of the Upgrade NFTs
    /// @param _amountsAvailable Amounts available of the Upgrade NFTs
    /// @param _isAvailable Are the Upgrade NFTs available ?
    /// @dev This function can only be called by the owner of the contract or the dev wallet
    function setUpgradePriceBatch(
        uint256[] calldata _upgradeIds,
        uint256[] calldata _prices,
        uint256[] calldata _amountsAvailable,
        bool[] calldata _isAvailable
    ) external {
        if (msg.sender != owner() && msg.sender != devWallet) {
            revert RestrictedAccess(msg.sender);
        }
        for (uint256 i = 0; i < _upgradeIds.length; ++i) {
            upgradeNftBuyingData[_upgradeIds[i]] =
                UpgradeNft(_isAvailable[i], _prices[i], _amountsAvailable[i]);
            emit UpgradeNftBuyingDataSetted(
                _prices[i], _amountsAvailable[i], _isAvailable[i]
                );
        }
    }

    /// @notice Returns the data of a Pack
    /// @param _packId Id of the Pack
    /// @return _designURI Upgrade Nft URI
    /// @return _price Purchase price of the Upgrade NFT
    /// @return _upgradeIds Upgrade Nfts ID
    function getPackData(uint256 _packId)
        external
        view
        returns (
            string memory _designURI, // Design URI
            uint256 _price, // Price
            uint256[] memory _upgradeIds // UpgradeIds
        )
    {
        Pack memory spec = packCosts[_packId];
        _designURI = spec.designURI;
        _price = spec.price;
        _upgradeIds = spec.upgradeIds;
    }

    /// @notice Returns the price of an Upgrade Nft
    /// @param _upgradeId Id of the upgrade
    /// @return _price Purchase price of the Upgrade NFT
    /// @return _amountAvailable Amount of Upgrade NFTs available
    /// @return _isAvailable If the Upgrade NFT is available
    function getUpgradeNftBuyingData(uint256 _upgradeId)
        external
        view
        returns (uint256 _price, uint256 _amountAvailable, bool _isAvailable)
    {
        _price = upgradeNftBuyingData[_upgradeId].cost;
        _amountAvailable = upgradeNftBuyingData[_upgradeId].amountAvailable;
        _isAvailable = upgradeNftBuyingData[_upgradeId].isAvailable;
    }

    /// @notice Withdraws the money from the contract
    /// @param _token Address of the token to withdraw
    /// @dev This function can only be called by the owner or the dev Wallet
    function withdrawMoney(IERC20Upgradeable _token) external {
        if (msg.sender != owner() && msg.sender != devWallet) {
            revert RestrictedAccess(msg.sender);
        }
        uint256 balance = _token.balanceOf(address(this));
        _token.safeTransfer(teamWallet, balance);
        emit WithdrawMoney(teamWallet, balance);
    }

    /// @notice Launches the mint procedure of a Bedroom NFT
    function buyBedroomNft() external nonReentrant {
        // Token Transfer
        paymentToken.safeTransferFrom(
            msg.sender, address(this), bedroomNftPurchaseCost
        );

        // NFT Minting
        uint256 tokenId = bedroomNftInstance.mintBedroomNft(msg.sender);

        emit BedroomNftPurchased(msg.sender, tokenId, bedroomNftPurchaseCost);
    }

    /// @notice Buy an Upgrade Nft
    /// @param _upgradeId Id of the Upgrade Nft
    function buyUpgradeNft(uint256 _upgradeId) external nonReentrant {
        // Verifies that the Nft is available
        UpgradeNft memory upgradeNft = upgradeNftBuyingData[_upgradeId];
        if (!upgradeNft.isAvailable || upgradeNft.amountAvailable == 0) {
            revert UpgradeNftNotAvailable(_upgradeId);
        }

        // Burns tokens
        sleepTokenInstance.burnFrom(msg.sender, upgradeNft.cost);

        // Mints Upgrade NFT
        upgradeNftInstance.mint(_upgradeId, 1, msg.sender);

        // Decreases the amount of Upgrade NFTs available
        upgradeNftBuyingData[_upgradeId].amountAvailable -= 1;

        emit UpgradeNftPurchased(msg.sender, _upgradeId, upgradeNft.cost);
    }

    /// @notice Buy a Pack
    /// @param _packId Id of the Pack
    function buyPack(uint256 _packId) external nonReentrant {
        // Gets Pack data
        Pack memory spec = packCosts[_packId];

        // Token Transfer
        paymentToken.safeTransferFrom(msg.sender, address(this), spec.price);

        // NFT Minting
        uint256 bedroomNftId = bedroomNftInstance.mintBedroomNft(msg.sender);

        for (uint256 i = 0; i < spec.upgradeIds.length; ++i) {
            // NFT Minting
            upgradeNftInstance.mint(spec.upgradeIds[i], 1, msg.sender);

            upgraderInstance.linkUpgradeNft(
                msg.sender, bedroomNftId, spec.upgradeIds[i], spec.designURI
            );
        }

        emit PackPurchased(msg.sender, _packId, bedroomNftId, spec.price);
    }

    /// @notice Links an Upgrade Nft
    /// @param _upgradeNftId Id of the Upgrade NFT
    /// @param _bedroomNftId Id of the Bedroom NFT
    /// @param _newDesignURI New Design URI of the Bedroom NFT
    function linkUpgradeNft(
        uint256 _upgradeNftId,
        uint256 _bedroomNftId,
        string calldata _newDesignURI
    ) external nonReentrant {
        upgraderInstance.linkUpgradeNft(
            msg.sender, _bedroomNftId, _upgradeNftId, _newDesignURI
        );
        emit UpgradeNftLinkedToBedroomNft(
            _bedroomNftId, _upgradeNftId, _newDesignURI
            );
    }

    /// @notice Links an Upgrade Nft - Batch transaction
    /// @param _upgradeNftIds IDs of the Upgrade NFTs
    /// @param _bedroomNftId Id of the Bedroom NFT
    /// @param _newDesignURI New Design URI of the Bedroom NFT
    function linkUpgradeNftBatch(
        uint256[] calldata _upgradeNftIds,
        uint256 _bedroomNftId,
        string calldata _newDesignURI
    ) external nonReentrant {
        for (uint256 i = 0; i < _upgradeNftIds.length; ++i) {
            upgraderInstance.linkUpgradeNft(
                msg.sender, _upgradeNftIds[i], _bedroomNftId, _newDesignURI
            );
            emit UpgradeNftLinkedToBedroomNft(
                _bedroomNftId, _upgradeNftIds[i], _newDesignURI
                );
        }
    }

    /// @notice Unlinks an Upgrade Nft
    /// @param _upgradeNftId Id of the Upgrade NFT
    /// @param _bedroomNftId Id of the Bedroom NFT
    /// @param _newDesignURI New Design URI of the Bedroom NFT
    function unlinkUpgradeNft(
        uint256 _upgradeNftId,
        uint256 _bedroomNftId,
        string calldata _newDesignURI
    ) external nonReentrant {
        upgraderInstance.unlinkUpgradeNft(
            msg.sender, _bedroomNftId, _upgradeNftId, _newDesignURI
        );
        emit UpgradeNftUnlinkedFromBedroomNft(
            _bedroomNftId, _upgradeNftId, _newDesignURI
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface of $Sleep Contract
/// @author Sleepn
/// @notice $Sleep is the official token of Sleepn
interface ISleep is IERC20 {
    /// @notice Stops the contract
    /// @dev This function can only be called by the owner of the contract
    function pause() external;

    /// @notice Starts the contract
    /// @dev This function can only be called by the owner of the contract
    function unpause() external;

    /// @notice Mints tokens
    /// @param _amount Amount of tokens to mint
    /// @dev This function can only be called by the owner
    function mint(uint256 _amount) external;

    /// @notice Burns tokens
    /// @param _account Tokens owner address
    /// @param _amount Tokens amount to burn
    function burnFrom(address _account, uint256 _amount) external;

    /// @notice Burns tokens
    /// @param _amount Tokens amount to burn
    function burn(uint256 _amount) external;
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface of $Health Contract
/// @author Sleepn
/// @notice $Health is the governance token of Sleepn
interface IHealth is IERC20 {
    /// @notice Stops the contract
    /// @dev This function can only be called by the owner of the contract
    function pause() external;

    /// @notice Starts the contract
    /// @dev This function can only be called by the owner of the contract
    function unpause() external;

    /// @notice Mints tokens
    /// @param _to Tokens receiver address
    /// @param _amount Amount of tokens to mint
    /// @dev This function can only be called by the owner
    function mint(address _to, uint256 _amount) external;

    /// @notice Burns tokens
    /// @param _account Tokens owner address
    /// @param _amount Tokens amount to burn
    function burnFrom(address _account, uint256 _amount) external;

    /// @notice Burns tokens
    /// @param _amount Tokens amount to burn
    function burn(uint256 _amount) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
interface IERC20PermitUpgradeable {
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