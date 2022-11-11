// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./Roles.sol";

contract Manager is Roles, Pausable {
    
    address private flokiTokenAddress;
    address private songNFTAddress;
    address private marketPlaceAddress;

    uint256 private artistFirstReward;
    uint256 private artistRepeatReward;
    uint256 private listenerFirstReward;
    uint256 private listenerRepeatReward;
    uint256 private exclusiveSongReward;
    uint8 private decimals;

    bool private ERC20openForAll; //default - false
    bool private NFTopenForAll; //default - false

    struct Song {
        string songID;
        string artistID; //=userID in struct Artist
        string albumID;
        string songName;
        bool mintedNFT;
    }

    struct Artist {
        string userID;
        address userWalletAddress;
        string[] songIDs;
        uint256 totalFlokiToken;
    }

    mapping(string => Artist) artistIDToData;
    mapping(string => Song) songIDToData;

    constructor() Roles(msg.sender) {}

    modifier artistExists(string memory _ID) {
        require(
            keccak256(abi.encodePacked(artistIDToData[_ID].userID)) ==
                keccak256(abi.encodePacked(_ID)),
            "Manager: Artist with such ID does not exist"
        );
        _;
    }

    modifier songExists(string memory _ID) {
        require(
            keccak256(abi.encodePacked(songIDToData[_ID].songID)) ==
                keccak256(abi.encodePacked(_ID)),
            "Manager: Song with such ID does not exist"
        );
        _;
    }

    //External functions
    function pauseManager() external onlySuperAdmin returns (bool) {
        _pause();
        return true;
    }

    function unpauseManager() external onlySuperAdmin returns (bool) {
        _unpause();
        return true;
    }

    function setFlokiTokenAddress(address _address)
        external
        onlyManager
        returns (bool)
    {
        flokiTokenAddress = _address;
        return true;
    }

    function setSongNFTAddress(address _address)
        external
        onlyManager
        returns (bool)
    {
        songNFTAddress = _address;
        return true;
    }

    function setMarketPlaceAddress(address _address)
        external
        onlyManager
        returns (bool)
    {
        marketPlaceAddress = _address;
        return true;
    }

    function toggleERC20openForAll(bool _isOpened)
        external
        onlyManager
        returns (bool)
    {
        ERC20openForAll = _isOpened;
        return ERC20openForAll;
    }

    function toggleNFTopenForAll(bool _isOpened)
        external
        onlyManager
        returns (bool)
    {
        NFTopenForAll = _isOpened;
        return NFTopenForAll;
    }

    function setArtistRewards(
        uint256 _artistFirstReward,
        uint256 _artistRepeatReward
    ) external onlyManager returns (uint256, uint256) {
        artistFirstReward = _artistFirstReward;
        artistRepeatReward = _artistRepeatReward;
        return (artistFirstReward, artistRepeatReward);
    }

    function setListenerRewards(
        uint256 _listenerFirstReward,
        uint256 _listenerRepeatReward
    ) external onlyManager returns (uint256, uint256) {
        listenerFirstReward = _listenerFirstReward;
        listenerRepeatReward = _listenerRepeatReward;
        return (listenerFirstReward, listenerRepeatReward);
    }

    function setExclusiveSongReward(uint256 _exclusiveSongReward)
        external
        onlyManager
        returns (uint256)
    {
        exclusiveSongReward = _exclusiveSongReward;
        return exclusiveSongReward;
    }

    function registerArtist(string memory _userID, address _userWalletAddress)
        external
        onlyArtistManager
        returns (bool)
    {
        require(
            bytes(_userID).length > 0,
            "Manager: `_userID` can not be empty string"
        );
        require(
            keccak256(abi.encode(artistIDToData[_userID].userID)) !=
                keccak256(abi.encode(_userID)),
            "Manager: Artist with such `_userID` already exists"
        );
        require(
            _userWalletAddress != address(0),
            "Manager: `_userWalletAddress` can not be zero-address"
        );

        Artist storage a = artistIDToData[_userID];
        a.userID = _userID;
        a.userWalletAddress = _userWalletAddress;
        a.totalFlokiToken = 0;
        return true;
    }

    function updateArtist(string memory _userID, address _userWalletAddress)
        external
        onlyArtistManager
        artistExists(_userID)
        returns (bool)
    {
        require(
            _userWalletAddress != address(0),
            "Manager: `_userWalletAddress` can not be zero-address"
        );
        artistIDToData[_userID].userWalletAddress = _userWalletAddress;
        return true;
    }

    function updateArtist(string memory _userID, string[] memory _songIDs)
        external
        onlyArtist
        artistExists(_userID)
        returns (bool)
    {
        artistIDToData[_userID].songIDs = _songIDs;
        return true;
    }

    function updateArtist(string memory _userID, uint256 _totalFlokiToken)
        external
        onlyArtistManager
        artistExists(_userID)
        returns (bool)
    {
        artistIDToData[_userID].totalFlokiToken = _totalFlokiToken;
        return true;
    }

    function updateArtist(
        string memory _userID,
        address _userWalletAddress,
        string[] memory _songIDs,
        uint256 _totalFlokiToken
    ) external onlyArtistManager artistExists(_userID) returns (bool) {
        require(
            _userWalletAddress != address(0),
            "Manager: `_userWalletAddress` can not be zero-address"
        );
        artistIDToData[_userID].userWalletAddress = _userWalletAddress;
        artistIDToData[_userID].songIDs = _songIDs;
        artistIDToData[_userID].totalFlokiToken = _totalFlokiToken;
        return true;
    }

    function deleteArtist(string memory _userID)
        external
        onlyArtistManager
        artistExists(_userID)
        returns (bool)
    {
        delete artistIDToData[_userID];
        return true;
    }

    function addSong(
        string memory _songID,
        string memory _artistID,
        string memory _albumID,
        string memory _songName
    ) external onlyArtist artistExists(_artistID) returns (bool) {
        require(
            bytes(_songID).length > 0,
            "Manager: `_songID` can not be empty string"
        );
        require(
            keccak256(abi.encodePacked(songIDToData[_songID].songID)) !=
                keccak256(abi.encodePacked(_songID)),
            "Manager: Song with such `_songID` already exists"
        );

        Song storage s = songIDToData[_songID];
        s.songID = _songID;
        s.artistID = _artistID;
        s.albumID = _albumID;
        s.songName = _songName;
        s.mintedNFT = false;

        artistIDToData[_artistID].songIDs.push() = _songID;
        return true;
    }

    function updateSong(string memory _songID, string memory _songName)
        external
        onlyArtist
        songExists(_songID)
        returns (bool)
    {
        songIDToData[_songID].songName = _songName;
        return true;
    }

    function updateSong(string memory _songID, bool _mintedNFT)
        external
        onlyArtist
        songExists(_songID)
        returns (bool)
    {
        songIDToData[_songID].mintedNFT = _mintedNFT;
        return true;
    }

    function updateSong(
        string memory _songID,
        string memory _songName,
        bool _mintedNFT
    ) external onlyArtist songExists(_songID) returns (bool) {
        songIDToData[_songID].songName = _songName;
        songIDToData[_songID].mintedNFT = _mintedNFT;
        return true;
    }

    function deleteSong(string memory _songID)
        external
        onlyArtist
        songExists(_songID)
        returns (bool)
    {
        delete songIDToData[_songID];
        return true;
    }

    //Public functions

    function getFlokiTokenAddress() public view returns (address) {
        return flokiTokenAddress;
    }

    function getSongNFTAddress() public view returns (address) {
        return songNFTAddress;
    }

    function getMarketPlaceAddress() public view returns (address) {
        return marketPlaceAddress;
    }

    function isERC20openForAll() public view returns (bool) {
        return ERC20openForAll;
    }

    function isNFTopenForAll() public view returns (bool) {
        return NFTopenForAll;
    }

    function getArtistFirstReward() public view returns (uint256) {
        return artistFirstReward;
    }

    function getArtistRepeatReward() public view returns (uint256) {
        return artistRepeatReward;
    }

    function getListenerFirstReward() public view returns (uint256) {
        return listenerFirstReward;
    }

    function getListenerRepeatReward() public view returns (uint256) {
        return listenerRepeatReward;
    }

    function getExclusiveSongReward() public view returns (uint256) {
        return exclusiveSongReward;
    }

    function getDecimals() public view returns (uint256) {
        return decimals;
    }

    function getArtistData(string memory _userID)
        public
        view
        artistExists(_userID)
        returns (Artist memory)
    {
        return artistIDToData[_userID];
    }

    function getSongData(string memory _songID)
        public
        view
        songExists(_songID)
        returns (Song memory)
    {
        return songIDToData[_songID];
    }

    //Internal functions

    //Private functions
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Roles is AccessControl {    
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant ARTIST_MANAGER_ROLE = keccak256("ARTIST_MANAGER_ROLE");
    bytes32 public constant NFT_MANAGER_ROLE = keccak256("NFT_MANAGER_ROLE");
    bytes32 public constant ERC20_MANAGER_ROLE = keccak256("ERC20_MANAGER_ROLE");
    bytes32 public constant MARKETPLACE_MANAGER_ROLE = keccak256("MARKETPLACE_MANAGER_ROLE");
    bytes32 public constant ARTIST_ROLE = keccak256("ARTIST_ROLE");

    constructor(address _SuperAdmin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _SuperAdmin);   
        _setRoleAdmin(MANAGER_ROLE, DEFAULT_ADMIN_ROLE);    
        _setRoleAdmin(ARTIST_MANAGER_ROLE, MANAGER_ROLE);
        _setRoleAdmin(NFT_MANAGER_ROLE, MANAGER_ROLE);
        _setRoleAdmin(ERC20_MANAGER_ROLE, MANAGER_ROLE);
        _setRoleAdmin(MARKETPLACE_MANAGER_ROLE, MANAGER_ROLE);
        _setRoleAdmin(ARTIST_ROLE, ARTIST_MANAGER_ROLE);
    }

    //Modifiers
    modifier onlySuperAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 
        "Roles: Only SuperAdmin has access");
        _;
    }

    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), 
        "Roles: Only Manager has access");
        _;
    }

    modifier onlyArtistManager() {
        require(hasRole(ARTIST_MANAGER_ROLE, msg.sender), 
        "Roles: Only ArtistManager has access");
        _;
    }

    modifier onlyNFTManager() {
        require(hasRole(NFT_MANAGER_ROLE, msg.sender), 
        "Roles: Only NFTManager has access");
        _;
    }

    modifier onlyERC20Manager() {
        require(hasRole(ERC20_MANAGER_ROLE, msg.sender), 
        "Roles: Only ERC20Manager has access");
        _;
    }

    modifier onlyMarketPlaceManager() {
        require(hasRole(MARKETPLACE_MANAGER_ROLE, msg.sender), 
        "Roles: Only MarketPlaceManager has access");
        _;
    }

    modifier onlyArtist() {
        require(hasRole(ARTIST_ROLE, msg.sender), 
        "Roles: Only Artist has access");
        _;
    }

    //Functions to check if `address` has proper role    

    /// @notice Checks if `_address` has SuperAdmin role   
    /// @param _address address to check if it has SuperAdmin role
    /// @return true if checking was successful, otherwise revert with expression:
    /// /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
    function isSuperAdmin(address _address) public view returns (bool) { 
        _checkRole(DEFAULT_ADMIN_ROLE, _address);
        return true; 
    }

    /// @notice Checks if `_address` has Manager role   
    /// @param _address address to check if it has Manager role
    /// @return true if checking was successful, otherwise revert with expression:
    /// /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
    function isManager(address _address) public view returns (bool) { 
        _checkRole(MANAGER_ROLE, _address);
        return true; 
    }

    /// @notice Checks if `_address` has ArtistManager role   
    /// @param _address address to check if it has ArtistManager role
    /// @return true if checking was successful, otherwise revert with expression:
    /// /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
    function isArtistManager(address _address) public view returns (bool) { 
        _checkRole(ARTIST_MANAGER_ROLE, _address);
        return true; 
    }

    /// @notice Checks if `_address` has NFTManager role   
    /// @param _address address to check if it has NFTManager role
    /// @return true if checking was successful, otherwise revert with expression:
    /// /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
    function isNFTManager(address _address) public view returns (bool) { 
        _checkRole(NFT_MANAGER_ROLE, _address);
        return true; 
    }

    /// @notice Checks if `_address` has ERC20Manager role   
    /// @param _address address to check if it has ERC20Manager role
    /// @return true if checking was successful, otherwise revert with expression:
    /// /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
    function isERC20Manager(address _address) public view returns (bool) { 
        _checkRole(ERC20_MANAGER_ROLE, _address);
        return true; 
    }

    /// @notice Checks if `_address` has MarketPlaceManager role   
    /// @param _address address to check if it has MarketPlaceManager role
    /// @return true if checking was successful, otherwise revert with expression:
    /// /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
    function isMarketPlaceManager(address _address) public view returns (bool) { 
        _checkRole(MARKETPLACE_MANAGER_ROLE, _address);
        return true; 
    }

    /// @notice Checks if `_address` has Artist role   
    /// @param _address address to check if it has Artist role
    /// @return true if checking was successful, otherwise revert with expression:
    /// /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
    function isArtist(address _address) public view returns (bool) { 
        _checkRole(ARTIST_ROLE, _address);
        return true; 
    }

    //Functions to add proper role to `address` 

    /// @notice Grant SuperAdmin role to `_address`    
    /// @dev Requirements:caller must have SuperAdmin role
    ///      May emit a {RoleGranted} event
    /// @param _address address to grant SuperAdmin role
    /// @return true if the role was successfully granted    
    function addSuperAdmin(address _address) external onlySuperAdmin returns (bool) { 
        _grantRole(DEFAULT_ADMIN_ROLE, _address);
        return true; 
    }

    /// @notice Grant Manager role to `_address`    
    /// @dev Requirements:caller must have SuperAdmin role
    ///      May emit a {RoleGranted} event
    /// @param _address address to grant Manager role
    /// @return true if the role was successfully granted
    function addManager(address _address) external onlySuperAdmin returns (bool) { 
        _grantRole(MANAGER_ROLE, _address);
        return true; 
    }

    /// @notice Grant ArtistManager role to `_address`    
    /// @dev Requirements:caller must have Manager role
    ///      May emit a {RoleGranted} event
    /// @param _address address to grant ArtistManager role
    /// @return true if the role was successfully granted
    function addArtistManager(address _address) external onlyManager returns (bool) { 
        _grantRole(ARTIST_MANAGER_ROLE, _address);
        return true; 
    }

    /// @notice Grant NFTManager role to `_address`    
    /// @dev Requirements:caller must have Manager role
    ///      May emit a {RoleGranted} event
    /// @param _address address to grant NFTManager role
    /// @return true if the role was successfully granted
    function addNFTManager(address _address) external onlyManager returns (bool) { 
        _grantRole(NFT_MANAGER_ROLE, _address);
        return true; 
    }

    /// @notice Grant ERC20tManager role to `_address`    
    /// @dev Requirements:caller must have Manager role
    ///      May emit a {RoleGranted} event
    /// @param _address address to grant ERC20Manager role
    /// @return true if the role was successfully granted
    function addERC20Manager(address _address) external onlyManager returns (bool) { 
        _grantRole(ERC20_MANAGER_ROLE, _address);
        return true; 
    }

    /// @notice Grant MarketPlaceManager role to `_address`    
    /// @dev Requirements:caller must have Manager role
    ///      May emit a {RoleGranted} event
    /// @param _address address to grant MarketPlaceManager role
    /// @return true if the role was successfully granted
    function addMarketPlaceManager(address _address) external onlyManager returns (bool) { 
        _grantRole(MARKETPLACE_MANAGER_ROLE, _address);
        return true; 
    }

    /// @notice Grant Artist role to `_address`    
    /// @dev Requirements:caller must have ArtistManager role
    ///      May emit a {RoleGranted} event
    /// @param _address address to grant Artist role
    /// @return true if the role was successfully granted
    function addArtist(address _address) external onlyArtistManager returns (bool) { 
        _grantRole(ARTIST_ROLE, _address);
        return true; 
    }

    //Functions to remove proper role from `address`

    /// @notice Revokes SuperAdmin role from the calling account
    /// @dev If the calling account had been revoked SuperAdmin role, 
    ///      emits a {RoleRevoked} event
    ///      Requirements: the caller must be SuperAdmin    
    /// @return true if the role was successfully revoked
    function renounceSuperAdmin() external onlySuperAdmin returns (bool) { 
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        return true; 
    }

    /// @notice Revokes Manager role from `_address`
    /// @dev If `_address` had been revoked Manager role, emits a {RoleRevoked} event
    ///      Requirements:the caller must have SuperAdmin role
    /// @param _address address to revoke Manager role from it
    /// @return true if the role was successfully revoked
    function removeManager(address _address) external onlySuperAdmin returns (bool) { 
        _revokeRole(MANAGER_ROLE, _address);
        return true; 
    }

    /// @notice Revokes ArtistManager role from `_address`
    /// @dev If `_address` had been revoked ArtistManager role, emits a {RoleRevoked} event
    ///      Requirements:the caller must have Manager role
    /// @param _address address to revoke ArtistManager role from it
    /// @return true if the role was successfully revoked
    function removeArtistManager(address _address) external onlyManager returns (bool) { 
        _revokeRole(ARTIST_MANAGER_ROLE, _address);
        return true; 
    }

    /// @notice Revokes NFTManager role from `_address`
    /// @dev If `_address` had been revoked NFTManager role, emits a {RoleRevoked} event
    ///      Requirements:the caller must have Manager role
    /// @param _address address to revoke NFTManager role from it
    /// @return true if the role was successfully revoked
    function removeNFTManager(address _address) external onlyManager returns (bool) { 
        _revokeRole(NFT_MANAGER_ROLE, _address);
        return true; 
    }

    /// @notice Revokes ERC20Manager role from `_address`
    /// @dev If `_address` had been revoked ERC20Manager role, emits a {RoleRevoked} event
    ///      Requirements:the caller must have Manager role
    /// @param _address address to revoke ERC20Manager role from it
    /// @return true if the role was successfully revoked
    function removeERC20Manager(address _address) external onlyManager returns (bool) { 
        _revokeRole(ERC20_MANAGER_ROLE, _address);
        return true; 
    }

    /// @notice Revokes MarketPlaceManager role from `_address`
    /// @dev If `_address` had been revoked MarketPlaceManager role, emits a {RoleRevoked} event
    ///      Requirements:the caller must have Manager role
    /// @param _address address to revoke MarketPlaceManager role from it
    /// @return true if the role was successfully revoked
    function removeMarketPlaceManager(address _address) external onlyManager returns (bool) { 
        _revokeRole(MARKETPLACE_MANAGER_ROLE, _address);
        return true; 
    }

    /// @notice Revokes Artist role from `_address`
    /// @dev If `_address` had been revoked Artist role, emits a {RoleRevoked} event
    ///      Requirements:the caller must have ArtistManager role
    /// @param _address address to revoke Artist role from it
    /// @return true if the role was successfully revoked
    function removeArtist(address _address) external onlyArtistManager returns (bool) { 
        _revokeRole(ARTIST_ROLE, _address);
        return true; 
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}