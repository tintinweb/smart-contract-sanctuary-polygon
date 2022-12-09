// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IOriumFactory } from "./interface/IOriumFactory.sol";
import { INftVaultPlatform, NftState, IOriumNftVault } from "./interface/IOriumNftVault.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Orium Scholarships Manager
 * @dev This contract is used to manage scholarships for Orium NFT Vault
 * @author Orium Network Team - [email protected]
 */
contract OriumScholarshipManager is Initializable, OwnableUpgradeable {
    address public operator;
    IOriumFactory public factory;

    // Platform control variables
    mapping(uint256 => uint256[]) internal platformToScholarshipPrograms;

    // Programs control variables
    uint256[] public programs;

    // Ownership
    mapping(uint256 => address) internal programToGuildOwner;
    mapping(address => uint256[]) internal userToScholarshipPrograms;

    // Helpers
    mapping(uint256 => mapping(uint256 => uint256[])) internal programToEventIdToShares;
    mapping(uint256 => uint256) internal programToPlatform;
    mapping(uint256 => bool) public isValidScholarshipProgram;

    //Vault auxiliar variables
    mapping(uint256 => mapping(address => uint256[])) internal _programToTokenToIds;
    mapping(address => mapping(uint256 => uint256)) internal _delegatedTokenToIdToIndex;

    mapping(address => mapping(uint256 => uint256)) internal _delegatedTokenToIdToProgramId;
    mapping(address => mapping(uint256 => address)) internal _delegatedTokenToIdToVault;
    mapping(address => mapping(uint256 => bool)) internal _pausedNfts;

    // Events
    event ScholarshipProgramCreated(
        uint256 indexed programId,
        uint256 platform,
        EventShares[] shares,
        address indexed owner
    );

    event PausedNft(
        address indexed owner,
        address vault,
        address indexed nftAddress,
        uint256 indexed tokenId
    );
    event UnPausedNft(
        address indexed owner,
        address vault,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event DelegatedScholarshipProgram(
        address owner,
        address vaultAddress,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 indexed programId,
        uint256 maxAllowedPeriod
    );
    event UnDelegatedScholarshipProgram(
        address owner,
        address vaultAddress,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    struct EventShares {
        uint256 eventId;
        uint256[] shares;
    }

    event RentalOfferCreated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed vaultAddress,
        uint256 programId,
        bytes data
    );

    event RentalOfferCancelled(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed vaultAddress,
        uint256 programId
    );
    event RentalEnded(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed vaultAddress,
        uint256 programId
    );

    modifier onlyTrustedNft(address _nftAddress) {
        require(factory.isTrustedNft(_nftAddress), "OriumScholarshipManager:: NFT is not trusted");
        _;
    }

    modifier onlyNotPausedNft(address _nftAddress, uint256 _tokenId) {
        require(
            _pausedNfts[_nftAddress][_tokenId] == false,
            "OriumScholarshipManager:: NFT is paused"
        );
        _;
    }

    modifier onlyGuildOwner(uint256 _programId) {
        require(
            msg.sender == programToGuildOwner[_programId],
            "OriumScholarshipManager:: Only guild owner can call this function"
        );
        _;
    }

    modifier onlyNftVault() {
        require(
            factory.isNftVault(msg.sender),
            "OriumFactory: Only OriumNftVault can call this function"
        );
        _;
    }

    /**
     * @dev Initialize the contract
     * @param _operator The operator address
     * @param _factory Orium Factory address
     */
    function initialize(address _operator, address _factory) public initializer {
        require(_operator != address(0), "OriumScholarshipManager: Invalid operator");
        require(_factory != address(0), "OriumScholarshipManager: Invalid factory");

        operator = _operator;
        factory = IOriumFactory(_factory);

        programs.push(0); // 0 is not a valid program id

        __Ownable_init();
        transferOwnership(_operator);
    }

    /**
     * @notice Create a scholarship program
     * @dev each index of shares config will be used as event id
     * @param _platform The platform id
     * @param _sharesConfig The shares for each event
     */
    function createScholarshipProgram(uint256 _platform, uint256[][] memory _sharesConfig)
        external
    {
        require(
            factory.isSupportedPlatform(_platform),
            "OriumScholarshipManager:: Platform not supported"
        );
        uint256 _programId = _addScholarshipProgram(_platform);
        EventShares[] memory _eventShares = new EventShares[](_sharesConfig.length);

        for (uint256 i = 0; i < _sharesConfig.length; i++) {
            require(_isValidShares(_sharesConfig[i]), "OriumScholarshipManager: Invalid shares");

            uint256 eventId = i + 1;
            programToEventIdToShares[_programId][eventId] = _sharesConfig[i];
            _eventShares[i] = EventShares(eventId, _sharesConfig[i]);
            programToPlatform[_programId] = _platform;
            programToGuildOwner[_programId] = msg.sender;
        }

        emit ScholarshipProgramCreated(_programId, _platform, _eventShares, msg.sender);
    }

    function _addScholarshipProgram(uint256 _platform) internal returns (uint256 _programId) {
        _programId = programs.length;

        programs.push(_programId);

        platformToScholarshipPrograms[_platform].push(_programId);
        userToScholarshipPrograms[msg.sender].push(_programId);

        isValidScholarshipProgram[_programId] = true;
    }

    function _isValidShares(uint256[] memory _shares) internal pure returns (bool) {
        uint256 sum = 0;
        for (uint256 i = 0; i < _shares.length; i++) {
            sum += _shares[i];
        }
        return sum == 100 ether;
    }

    /**
     * @notice Create Rental Offers
     * @dev This function is called by guild owner
     * @param _tokenIds The token ids
     * @param _nftAddresses The nft addresses
     * @param _programIds The program ids
     * @param data bytes to create auxilary rental structs
     */
    function createRentalOffers(
        uint256[] memory _tokenIds,
        address[] memory _nftAddresses,
        uint256[] memory _programIds,
        bytes[] memory data
    ) external {
        require(
            _tokenIds.length == _nftAddresses.length &&
                _tokenIds.length == data.length &&
                _tokenIds.length == _programIds.length,
            "OriumScholarshipManager:: Array lengths are not equal"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _createRentalOffer(_tokenIds[i], _nftAddresses[i], _programIds[i], data[i]);
        }
    }

    function _createRentalOffer(
        uint256 _tokenId,
        address _nftAddress,
        uint256 _programId,
        bytes memory data
    )
        internal
        onlyTrustedNft(_nftAddress)
        onlyGuildOwner(_programId)
        onlyNotPausedNft(_nftAddress, _tokenId)
    {
        address _nftVault = _getVerifiedVault(_nftAddress, _tokenId, _programId);
        INftVaultPlatform(_nftVault).createRentalOffer(_tokenId, _nftAddress, data);
        emit RentalOfferCreated(_nftAddress, _tokenId, _nftVault, _programId, data);
    }

    /**
     * @notice Cancel Rental Offers
     * @dev This function is called by guild owner
     * @param _tokenIds The token ids
     * @param _nftAddresses The nft addresses
     * @param _programIds The program ids
     */
    function cancelRentalOffers(
        uint256[] memory _tokenIds,
        address[] memory _nftAddresses,
        uint256[] memory _programIds
    ) external {
        require(
            _tokenIds.length == _nftAddresses.length && _tokenIds.length == _programIds.length,
            "OriumScholarshipManager:: Array lengths are not equal"
        );

        for (uint256 i = 0; i < _nftAddresses.length; i++) {
            _cancelRentalOffer(_tokenIds[i], _nftAddresses[i], _programIds[i]);
        }
    }

    function _cancelRentalOffer(
        uint256 _tokenId,
        address _nftAddress,
        uint256 _programId
    ) internal onlyTrustedNft(_nftAddress) onlyGuildOwner(_programId) {
        address _nftVault = _getVerifiedVault(_nftAddress, _tokenId, _programId);
        INftVaultPlatform(_nftVault).cancelRentalOffer(_tokenId, _nftAddress);
        emit RentalOfferCancelled(_nftAddress, _tokenId, _nftVault, _programId);
    }

    /**
     * @notice End Rental Offers
     * @dev This function is called by guild owner
     * @param _tokenIds The token ids
     * @param _nftAddresses The nft addresses
     * @param _nftVaults The nft vaults
     * @param _programIds The program ids
     */
    function endRentals(
        uint256[] memory _tokenIds,
        address[] memory _nftAddresses,
        address[] memory _nftVaults,
        uint256[] memory _programIds
    ) external {
        require(
            _tokenIds.length == _nftAddresses.length &&
                _tokenIds.length == _nftVaults.length &&
                _tokenIds.length == _programIds.length,
            "OriumScholarshipManager:: Array lengths are not equal"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _endRental(_tokenIds[i], _nftAddresses[i], _nftVaults[i], _programIds[i]);
        }
    }

    function _endRental(
        uint256 _tokenId,
        address _nftAddress,
        address _nftVault,
        uint256 _programId
    ) internal onlyTrustedNft(_nftAddress) onlyGuildOwner(_programId) {
        require(factory.isNftVault(_nftVault), "OriumScholarshipManager:: Invalid vault");
        require(
            INftVaultPlatform(_nftVault).platform() == programToPlatform[_programId],
            "OriumScholarshipManager:: Vault and scholarship program platform are not the same"
        );
        require(
            IOriumNftVault(_nftVault).programOf(_nftAddress, _tokenId) == _programId,
            "OriumScholarshipManager:: NFT is not delegated to this program"
        );

        INftVaultPlatform(_nftVault).endRental(_nftAddress, uint32(_tokenId));
        emit RentalEnded(_nftAddress, _tokenId, _nftVault, _programId);
    }

    /**
     * @notice End Rentals and Relist
     * @dev This function is called by guild owner
     * @param _tokenIds The token ids
     * @param _nftAddresses The nft addresses
     * @param _nftVaults The nft vaults
     * @param _programIds The program ids
     */
    function endRentalsAndRelist(
        uint256[] memory _tokenIds,
        address[] memory _nftAddresses,
        address[] memory _nftVaults,
        uint256[] memory _programIds,
        bytes[] memory _datas
    ) external {
        require(
            _tokenIds.length == _nftAddresses.length &&
                _tokenIds.length == _nftVaults.length &&
                _tokenIds.length == _programIds.length &&
                _tokenIds.length == _datas.length,
            "OriumScholarshipManager:: Array lengths are not equal"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _endRentalAndRelist(
                _nftAddresses[i],
                _tokenIds[i],
                _nftVaults[i],
                _programIds[i],
                _datas[i]
            );
        }
    }

    function _endRentalAndRelist(
        address _nftAddress,
        uint256 _tokenId,
        address _nftVault,
        uint256 _programId,
        bytes memory data
    ) internal onlyTrustedNft(_nftAddress) onlyGuildOwner(_programId) {
        require(factory.isNftVault(_nftVault), "OriumScholarshipManager:: Invalid vault");
        require(
            INftVaultPlatform(_nftVault).platform() == programToPlatform[_programId],
            "OriumScholarshipManager:: Vault and scholarship program platform are not the same"
        );
        require(
            IOriumNftVault(_nftVault).programOf(_nftAddress, _tokenId) == _programId,
            "OriumScholarshipManager:: NFT is not delegated to this program"
        );

        INftVaultPlatform(_nftVault).endRentalAndRelist(_nftAddress, uint32(_tokenId), data);
        emit RentalEnded(_nftAddress, _tokenId, _nftVault, _programId);
        emit RentalOfferCreated(_nftAddress, _tokenId, _nftVault, _programId, data);
    }

    // Nft's Managing
    function _getVerifiedVault(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _programId
    ) internal view returns (address _nftVault) {
        _nftVault = _delegatedTokenToIdToVault[_nftAddress][_tokenId];
        require(
            _nftVault != address(0),
            "OriumScholarshipManager:: NFT is not delegated to any program"
        );
        require(
            INftVaultPlatform(_nftVault).platform() == programToPlatform[_programId],
            "OriumScholarshipManager:: Vault and scholarship program platform are not the same"
        );
        require(
            _delegatedTokenToIdToProgramId[_nftAddress][_tokenId] == _programId,
            "OriumScholarshipManager:: NFT is not delegated to this program"
        );
    }

    //Getters
    /**
     * @notice Get scholarships programs of an platform
     * @param _platform The platform id
     * @return ids of the programs
     */
    function programsOfPlatform(uint256 _platform) external view returns (uint256[] memory) {
        return platformToScholarshipPrograms[_platform];
    }

    /**
     * @notice Verify if a program is valid
     * @param _programId The program id
     * @return true if the program is valid
     */
    function isProgram(uint256 _programId) external view returns (bool) {
        return isValidScholarshipProgram[_programId];
    }

    /**
     * @notice Get scholarship programs of an guild owner
     * @param _guildOwner The guild owner address
     * @return ids of the programs
     */
    function programsOfOwner(address _guildOwner) external view returns (uint256[] memory) {
        return userToScholarshipPrograms[_guildOwner];
    }

    /**
     * @notice Get shares of a program by event
     * @param _programId The program id
     * @param _eventId The event id
     * @return shares of the program for an event
     */
    function sharesOf(uint256 _programId, uint256 _eventId)
        external
        view
        returns (uint256[] memory)
    {
        return programToEventIdToShares[_programId][_eventId];
    }

    /**
     * @notice Get a guild owner of a program
     * @param _programId The program id
     * @return guild owner address
     */
    function ownerOf(uint256 _programId) external view returns (address) {
        return programToGuildOwner[_programId];
    }

    /**
     * @notice Get a platform of a program
     * @param _programId The program id
     * @return platform id
     */
    function platformOf(uint256 _programId) external view returns (uint256) {
        return programToPlatform[_programId];
    }

    /**
     * @notice Get a vault of an nft
     * @param _nftAddress The nft address
     * @param _tokenId The token id
     * @return _nftVault address
     */
    function vaultOfDelegatedToken(address _nftAddress, uint256 _tokenId)
        public
        view
        onlyTrustedNft(_nftAddress)
        returns (address _nftVault)
    {
        _nftVault = _delegatedTokenToIdToVault[_nftAddress][_tokenId];
    }

    /**
     * @notice Get all scholarships programs
     * @return ids of the programs
     */
    function getAllScholarshipPrograms() external view returns (uint256[] memory) {
        return programs;
    }

    /**
     * @notice Get all tokens ids delegated to a scholarship program
     * @param _nftAddress The nft address
     * @param _programId The program id
     * @return ids of the tokens
     */
    function delegatedTokensOf(address _nftAddress, uint256 _programId)
        external
        view
        returns (uint256[] memory)
    {
        return _programToTokenToIds[_programId][_nftAddress];
    }

    /**
     * @notice Get a delegated scholarship program of an nft
     * @param _nftAddress The nft address
     * @param _tokenId The token id
     */
    function programOf(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (uint256 _programId)
    {
        _programId = _delegatedTokenToIdToProgramId[_nftAddress][_tokenId];
    }

    /**
     * @notice Check if an nft is paused
     * @param _nftAddress The nft address
     * @param _tokenId The token id
     * @return true if the nft is paused
     */
    function isNftPaused(address _nftAddress, uint256 _tokenId) external view returns (bool) {
        return _pausedNfts[_nftAddress][_tokenId];
    }

    //Notifiers

    function _addDelegatedToken(
        uint256 _programId,
        address _nftAddress,
        uint256 _tokenId,
        address _vaultAddress
    ) internal {
        if (_programToTokenToIds[_programId][_nftAddress].length == 0) {
            _programToTokenToIds[_programId][_nftAddress].push(0); // 0 is not a valid token index
        }
        _programToTokenToIds[_programId][_nftAddress].push(_tokenId);
        _delegatedTokenToIdToIndex[_nftAddress][_tokenId] =
            _programToTokenToIds[_programId][_nftAddress].length -
            1;
        _delegatedTokenToIdToProgramId[_nftAddress][_tokenId] = _programId;
        _delegatedTokenToIdToVault[_nftAddress][_tokenId] = _vaultAddress;
    }

    function _removeDelegatedToken(address _nftAddress, uint256 _tokenId) internal {
        uint256 _programId = _delegatedTokenToIdToProgramId[_nftAddress][_tokenId];
        uint256[] storage tokenIds = _programToTokenToIds[_programId][_nftAddress];

        uint256 index = _delegatedTokenToIdToIndex[_nftAddress][_tokenId];
        require(index != 0, "OriumScholarshipManager:: Token is not delegated to any program");

        uint256 lastTokenId = tokenIds[tokenIds.length - 1];

        if (lastTokenId != _tokenId) {
            tokenIds[index] = lastTokenId;
            _delegatedTokenToIdToIndex[_nftAddress][lastTokenId] = index;
        }

        tokenIds.pop();
        delete _delegatedTokenToIdToIndex[_nftAddress][_tokenId];
        delete _delegatedTokenToIdToProgramId[_nftAddress][_tokenId];
        delete _delegatedTokenToIdToVault[_nftAddress][_tokenId];
    }

    //Notifiers
    /**
     * @notice Notify when a new program is delegated to an nft in a vault
     * @dev This function is called only by an OriumNftVault
     * @param _owner The owner of the nft
     * @param _nftAddress The nft address
     * @param _tokenId The token id
     */
    function onUnDelegatedScholarshipProgram(
        address _owner,
        address _nftAddress,
        uint256 _tokenId
    ) external onlyNftVault {
        emit UnDelegatedScholarshipProgram(_owner, msg.sender, _nftAddress, _tokenId);
        _removeDelegatedToken(_nftAddress, _tokenId);
    }

    /**
     * @notice Notify when a scholarship program is un delegated to an nft in a vault
     * @dev This function is called only by an OriumNftVault
     * @param _owner The owner of the nft
     * @param _nftAddress The nft address
     * @param _tokenId The token id
     * @param _programId The program id
     * @param _maxAllowedPeriod The max allowed period
     */
    function onDelegatedScholarshipProgram(
        address _owner,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _programId,
        uint256 _maxAllowedPeriod
    ) external onlyNftVault {
        emit DelegatedScholarshipProgram(
            _owner,
            msg.sender,
            _nftAddress,
            _tokenId,
            _programId,
            _maxAllowedPeriod
        );
        _addDelegatedToken(_programId, _nftAddress, _tokenId, msg.sender);
    }

    /**
     * @notice Notify when a nft is paused
     * @dev This function is called only by an OriumNftVault
     * @param _owner The owner of the nft
     * @param _nftAddress The nft address
     * @param _tokenId The token id
     */
    function onPausedNft(
        address _owner,
        address _nftAddress,
        uint256 _tokenId
    ) external onlyNftVault {
        _pausedNfts[_nftAddress][_tokenId] = true;
        emit PausedNft(_owner, msg.sender, _nftAddress, _tokenId);
    }

    /**
     * @notice Notify when a nft is unpaused
     * @dev This function is called only by an OriumNftVault
     * @param _owner The owner of the nft
     * @param _nftAddress The nft address
     * @param _tokenId The token id
     */
    function onUnPausedNft(
        address _owner,
        address _nftAddress,
        uint256 _tokenId
    ) external onlyNftVault {
        delete _pausedNfts[_nftAddress][_tokenId];
        emit UnPausedNft(_owner, msg.sender, _nftAddress, _tokenId);
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

interface IOriumFactory {
    function isTrustedNft(address _nft) external view returns (bool);

    function isPlatformTrustedNft(address _nft, uint256 _platform) external view returns (bool);

    function isNftVault(address _nftVault) external view returns (bool);

    function getPlatformNftType(uint256 _platform, address _nft) external view returns (uint256);

    function rentalImplementationOf(address _nftAddress) external view returns (address);

    function getOriumAavegotchiSplitter() external view returns (address);

    function oriumFee() external view returns (uint256);

    function getPlatformTokens(uint256 _platformId) external view returns (address[] memory);

    function getVaultInfo(address _nftVault)
        external
        view
        returns (uint256 platform, address owner);

    function getScholarshipManagerAddress() external view returns (address);

    function getOriumAavegotchiPettingAddress() external view returns (address);

    function getAavegotchiDiamondAddress() external view returns (address);

    function isSupportedPlatform(uint256 _platform) external view returns (bool);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

enum NftState {
    NOT_DEPOSITED,
    IDLE,
    LISTED,
    BORROWED,
    CLAIMABLE
}

interface IOriumNftVault {
    function initialize(
        address _owner,
        address _factory,
        address _scholarshipManager,
        uint256 _platform
    ) external;

    function getNftState(address _nft, uint256 tokenId) external view returns (NftState _nftState);

    function isPausedForListing(address _nftAddress, uint256 _tokenId) external view returns (bool);

    function pauseListing(address _nftAddress, uint256 _tokenId) external;

    function unPauseListing(address _nftAddress, uint256 _tokenId) external;

    function withdrawNfts(address[] memory _nftAddresses, uint256[] memory _tokenIds) external;

    function maxRentalPeriodAllowedOf(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (uint256);

    function setMaxAllowedRentalPeriod(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _maxAllowedPeriod
    ) external;

    function programOf(address _nftAddress, uint256 _tokenId) external view returns (uint256);
}

interface INftVaultPlatform {
    function platform() external view returns (uint256);

    function owner() external view returns (address);

    function createRentalOffer(
        uint256 _tokenId,
        address _nftAddress,
        bytes memory data
    ) external;

    function cancelRentalOffer(uint256 _tokenId, address _nftAddress) external;

    function endRental(address _nftAddress, uint32 _tokenId) external;

    function endRentalAndRelist(
        address _nftAddress,
        uint32 _tokenId,
        bytes memory data
    ) external;

    function claimTokensOfRental(address _nftAddress, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

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