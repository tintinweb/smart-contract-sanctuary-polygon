// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./FlokiStorage.sol";
import "./Roles.sol";

contract Manager is Roles, Pausable, FlokiStorage {
    /// @notice Emitted when restriction of who can mint FlokiToken was changed
    event FlokiTokenOpenedForAll(bool isOpened, uint256 timestamp);

    /// @notice Emitted when restriction of who can mint SongNFT was changed
    event SongNFTOpenedForAll(bool isOpened, uint256 timestamp);

    /// @notice Emitted when quantity of reward for Artist was set
    event ArtistRewardSetTo(uint256 valueOfReward, uint256 timestamp);

    /// @notice Emitted when quantity of reward for Listener for first time listening of the song was set
    event FirstRewardOfListenerSetTo(uint256 valueOfReward, uint256 timestamp);

    /// @notice Emitted when quantity of reward for Listener for repeated listening of the song was set
    event RepeatRewardOfListenerSetTo(uint256 valueOfReward, uint256 timestamp);

    /// @notice Emitted when quantity of reward for exclusive song was set
    event ExclusiveSongRewardSetTo(uint256 valueOfReward, uint256 timestamp);

    /// @notice Emitted when new Artist created
    event NewArtist(
        string userID,
        address userWalletAddress,
        uint256 timestamp
    );

    /// @notice Emitted when wallet of Artist was changed
    event UserWalletUpdated(
        string userID,
        address userWalletAddress,
        uint256 timestamp
    );

    /// @notice Emitted when new Song created
    event NewSong(
        address creator,
        string songID,
        string artistID,
        string albumID,
        string songName,
        uint256 timestamp
    );

    /// @notice Emitted when the name of the Song was updated
    event SongNameUpdated(string songID, string newSongName, uint256 timestamp);

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

    constructor() Roles(msg.sender) {}

    /// @notice Pauses main functions of the contract Manager
    /// @dev Only SuperAdmin function
    /// @return True if successful
    function pauseManager() external onlySuperAdmin returns (bool) {
        _pause();
        return true;
    }

    /// @notice Unpauses main functions of the contract Manager
    /// @dev Only SuperAdmin function
    /// @return True if successful
    function unpauseManager() external onlySuperAdmin returns (bool) {
        _unpause();
        return true;
    }

    /// @notice Sets the address of the contract of ERC20 FlokiToken
    /// @dev Only Manager function
    /// @param _address The address of the contract FlokiToken
    /// @return True if successfully set
    function setFlokiTokenAddress(address _address)
        external
        onlyManager
        returns (bool)
    {
        flokiTokenAddress = _address;
        return true;
    }

    /// @notice Sets the address of the contract of ERC721 SongNFT
    /// @dev Only Manager function
    /// @param _address The address of the contract SongNFT
    /// @return True if successfully set
    function setSongNFTAddress(address _address)
        external
        onlyManager
        returns (bool)
    {
        songNFTAddress = _address;
        return true;
    }

    /// @notice Sets the value of decimals to use in contract
    /// @dev Only Manager function
    /// @param _decimals uint value of decmals
    /// @return True if successfully set
    function setDecimals(uint8 _decimals)
        external
        whenNotPaused
        onlyManager
        returns (bool)
    {
        decimals = _decimals;
        return true;
    }

    /// @notice Sets the value of paramentr is ERC20 opened for all users or only for ERC20Manager
    /// @dev Only Manager function. Emits {FlokiTokenOpenedForAll} event.
    /// @param _isOpened true (FlokiToken is avalaible for all users), false - only for ERC20Manager
    /// @return ERC20openForAll, its value which was set
    function toggleERC20openForAll(bool _isOpened)
        external
        onlyManager
        returns (bool)
    {
        ERC20openForAll = _isOpened;
        emit FlokiTokenOpenedForAll(_isOpened, block.timestamp);

        return ERC20openForAll;
    }

    /// @notice Sets the value of paramentr is ERC721 NFT opened for all users or only for NFTManager
    /// @dev Only Manager function. Emits {SongNFTOpenedForAll} event.
    /// @param _isOpened true (SongNFT is avalaible for all users), false - only for NFTManager
    /// @return NFTopenForAll, its value which was set
    function toggleNFTopenForAll(bool _isOpened)
        external
        onlyManager
        returns (bool)
    {
        NFTopenForAll = _isOpened;
        emit SongNFTOpenedForAll(_isOpened, block.timestamp);

        return NFTopenForAll;
    }

    /// @notice Sets the value of reward for Artist
    /// @dev Only Manager function. Emits {ArtistRewardSetTo} event.
    /// @param _artistRepeatReward value to set as the Artist reward
    /// @return artistRepeatReward, its value which was set
    function setArtistReward(uint256 _artistRepeatReward)
        external
        onlyManager
        returns (uint256)
    {
        artistRepeatReward = _artistRepeatReward;
        emit ArtistRewardSetTo(_artistRepeatReward, block.timestamp);

        return artistRepeatReward;
    }

    /// @notice Sets the values of rewards for Listener (First - when he or she listens the song at first
    /// & Repeat - when he or she listens the song all next times)
    /// @dev Only Manager function. Emits {FirstRewardOfListenerSetTo} and {RepeatRewardOfListenerSetTo} events.
    /// @param _listenerFirstReward value to set as the FirstListener reward
    /// @param _listenerRepeatReward value to set as the RepeatListener reward
    /// @return (listenerFirstReward, listenerRepeatReward) - two values which were set
    function setListenerRewards(
        uint256 _listenerFirstReward,
        uint256 _listenerRepeatReward
    ) external onlyManager returns (uint256, uint256) {
        listenerFirstReward = _listenerFirstReward;
        listenerRepeatReward = _listenerRepeatReward;

        emit FirstRewardOfListenerSetTo(_listenerFirstReward, block.timestamp);
        emit RepeatRewardOfListenerSetTo(
            _listenerRepeatReward,
            block.timestamp
        );

        return (listenerFirstReward, listenerRepeatReward);
    }

    /// @notice Sets the value of Exclusive Song reward
    /// @dev Only Manager function. Emits {ExclusiveSongRewardSetTo} event.
    /// @param _exclusiveSongReward value to set as the exclusiveSongReward reward
    /// @return exclusiveSongReward, its value which was set
    function setExclusiveSongReward(uint256 _exclusiveSongReward)
        external
        onlyManager
        returns (uint256)
    {
        exclusiveSongReward = _exclusiveSongReward;
        emit ExclusiveSongRewardSetTo(_exclusiveSongReward, block.timestamp);

        return exclusiveSongReward;
    }

    /// @notice Creates new Artist
    /// @dev Only ArtistManager function. Emits {NewArtist} event.
    /// requires: `_userID` can not be empty string
    ///           `_userWalletAddress` can not be zero-address
    ///           does not allow to create Artist with `_userID` which already exists
    /// @param _userID ID of new Artist
    /// @param _userWalletAddress wallet address of new Artist
    /// @return True if Artist successfully registered
    function registerArtist(string memory _userID, address _userWalletAddress)
        external
        whenNotPaused
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

        emit NewArtist(_userID, _userWalletAddress, block.timestamp);

        return true;
    }

    /// @notice Updates the `_userWalletAddress` of Artist with `_userID`
    /// @dev Only ArtistManager function. Emits {UserWalletUpdated} event.
    /// requires: `_userWalletAddress` can not be zero-address
    /// @param _userID ID of the Artist to update information
    /// @param _userWalletAddress new wallet address
    /// @return True if wallet address successfully updated
    function updateArtist(string memory _userID, address _userWalletAddress)
        external
        whenNotPaused
        onlyArtistManager
        artistExists(_userID)
        returns (bool)
    {
        require(
            _userWalletAddress != address(0),
            "Manager: `_userWalletAddress` can not be zero-address"
        );
        artistIDToData[_userID].userWalletAddress = _userWalletAddress;
        emit UserWalletUpdated(_userID, _userWalletAddress, block.timestamp);

        return true;
    }

    /// @notice Updates the list of songs `_songIDs` of Artist with `_userID`
    /// @dev Only ArtistManager function.
    /// @param _userID ID of the Artist to update information
    /// @param _songIDs new list of artist songs' IDs
    /// @return True if list was successfully updated
    function updateArtist(string memory _userID, string[] memory _songIDs)
        external
        whenNotPaused
        onlyArtist
        artistExists(_userID)
        returns (bool)
    {
        artistIDToData[_userID].songIDs = _songIDs;
        return true;
    }

    /// @notice Updates the amount of FlokiTokens of Artist with `_userID`
    /// @dev Only ArtistManager function.
    /// @param _userID ID of the Artist to update information
    /// @param _totalFlokiToken new amount of FlokiTokens
    /// @return True if amount was successfully updated
    function updateArtist(string memory _userID, uint256 _totalFlokiToken)
        external
        whenNotPaused
        onlyArtistManager
        artistExists(_userID)
        returns (bool)
    {
        artistIDToData[_userID].totalFlokiToken = _totalFlokiToken;
        return true;
    }

    /// @notice Updates all mutable parameters (`_userWalletAddress`, `_songIDs`, `_totalFlokiToken`) of Artist with `_userID`
    /// @dev Only ArtistManager function. Emits {UserWalletUpdated} event.
    /// requires: `_userWalletAddress` can not be zero-address
    /// @param _userID ID of the Artist to update information
    /// @param _userWalletAddress new wallet address
    /// @param _songIDs new list of artist songs' IDs
    /// @param _totalFlokiToken new amount of FlokiTokens
    /// @return True if Artist data successfully updated
    function updateArtist(
        string memory _userID,
        address _userWalletAddress,
        string[] memory _songIDs,
        uint256 _totalFlokiToken
    )
        external
        whenNotPaused
        onlyArtistManager
        artistExists(_userID)
        returns (bool)
    {
        require(
            _userWalletAddress != address(0),
            "Manager: `_userWalletAddress` can not be zero-address"
        );
        artistIDToData[_userID].userWalletAddress = _userWalletAddress;
        artistIDToData[_userID].songIDs = _songIDs;
        artistIDToData[_userID].totalFlokiToken = _totalFlokiToken;

        emit UserWalletUpdated(_userID, _userWalletAddress, block.timestamp);

        return true;
    }

    /// @notice Delete the Artist with `_userID`
    /// @dev Only ArtistManager function. Emits {UserWalletUpdated} event.
    /// @param _userID ID of the Artist to delete
    /// @return True if Artist successfully deleted
    function deleteArtist(string memory _userID)
        external
        onlyArtistManager
        artistExists(_userID)
        returns (bool)
    {
        delete artistIDToData[_userID];

        emit UserWalletUpdated(
            _userID,
            0x0000000000000000000000000000000000000000,
            block.timestamp
        );
        return true;
    }

    /// @notice Adds new Song
    /// @dev Only Artist function. Emits {NewSong} event.
    /// requires: `_songID` can not be empty string
    ///           does not allow to create Song with `_songID` which already exists
    /// @param _songID ID of new Song
    /// @param _artistID userID of the Artist-owner of the song
    /// @param _albumID albumID from which is the new song
    /// @param _songName the name of the new song
    /// @return True if Song was successfully added
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
        emit NewSong(
            msg.sender,
            _songID,
            _artistID,
            _albumID,
            _songName,
            block.timestamp
        );

        return true;
    }

    /// @notice Updates the name of the Song with `_songID`
    /// @dev Only Artist function. Emits {SongNameUpdated} event.
    /// @param _songID ID of the Song to update
    /// @param _songName the new name of the `_songID`
    /// @return True if Song was successfully updated
    function updateSong(string memory _songID, string memory _songName)
        external
        whenNotPaused
        onlyArtist
        songExists(_songID)
        returns (bool)
    {
        songIDToData[_songID].songName = _songName;
        emit SongNameUpdated(_songID, _songName, block.timestamp);

        return true;
    }

    /// @notice Updates the bool parameter of the Song with `_songID` when song's NFT minted
    /// @dev Only Artist function.
    /// @param _songID ID of the Song to update
    /// @param _mintedNFT bool parameter of the `_songID`. Set as `true` when NFT minted
    /// @return True if `_mintedNFT` was successfully updated
    function updateSong(string memory _songID, bool _mintedNFT)
        external
        whenNotPaused
        onlyArtist
        songExists(_songID)
        returns (bool)
    {
        songIDToData[_songID].mintedNFT = _mintedNFT;
        return true;
    }

    /// @notice Updates the data of the Song with `_songID` - `_songName` & `_mintedNFT`
    /// @dev Only Artist function. Emits {SongNameUpdated} event.
    /// @param _songID ID of the Song to update
    /// @param _songName the new name of the `_songID`
    /// @param _mintedNFT bool parameter of the `_songID`. Set as `true` when NFT minted
    /// @return True if Song was successfully updated
    function updateSong(
        string memory _songID,
        string memory _songName,
        bool _mintedNFT
    ) external whenNotPaused onlyArtist songExists(_songID) returns (bool) {
        songIDToData[_songID].songName = _songName;
        songIDToData[_songID].mintedNFT = _mintedNFT;
        emit SongNameUpdated(_songID, _songName, block.timestamp);

        return true;
    }

    /// @notice Delete the Song with `_songID`
    /// @dev Only Artist function. Emits {SongNameUpdated} event.
    /// @param _songID ID of the Song to delete
    /// @return True if Song successfully deleted
    function deleteSong(string memory _songID)
        external
        onlyArtist
        songExists(_songID)
        returns (bool)
    {
        delete songIDToData[_songID];
        emit SongNameUpdated(_songID, "", block.timestamp);
        return true;
    }

    /// @return flokiTokenAddress the address of the Smart Contract ERC20 FlokiToken
    function getFlokiTokenAddress() public view returns (address) {
        return flokiTokenAddress;
    }

    /// @return songNFTAddress the address of the Smart Contract ERC721 SongNFT
    function getSongNFTAddress() public view returns (address) {
        return songNFTAddress;
    }

    /// @return Artist data:(string userID,address userWalletAddress,string[] songIDs,uint256 totalFlokiToken)
    function getArtistData(string memory _userID)
        public
        view
        artistExists(_userID)
        returns (Artist memory)
    {
        return artistIDToData[_userID];
    }

    /// @return Song data:(string songID,string artistID,string albumID,string songName,bool mintedNFT)
    function getSongData(string memory _songID)
        public
        view
        songExists(_songID)
        returns (Song memory)
    {
        return songIDToData[_songID];
    }

    /// @return artistRepeatReward's value
    function getArtistRepeatReward() public view returns (uint256) {
        return artistRepeatReward;
    }

    /// @return listenerFirstReward's value
    function getListenerFirstReward() public view returns (uint256) {
        return listenerFirstReward;
    }

    /// @return listenerRepeatReward's value
    function getListenerRepeatReward() public view returns (uint256) {
        return listenerRepeatReward;
    }

    /// @return exclusiveSongReward's value
    function getExclusiveSongReward() public view returns (uint256) {
        return exclusiveSongReward;
    }

    /// @return decimals' value
    function getDecimals() public view returns (uint256) {
        return decimals;
    }

    /// @return ERC20openForAll true or false value
    function isERC20openForAll() public view returns (bool) {
        return ERC20openForAll;
    }

    /// @return NFTopenForAll true or false value
    function isNFTopenForAll() public view returns (bool) {
        return NFTopenForAll;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Roles is AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant ARTIST_MANAGER_ROLE =
        keccak256("ARTIST_MANAGER_ROLE");
    bytes32 public constant NFT_MANAGER_ROLE = keccak256("NFT_MANAGER_ROLE");
    bytes32 public constant ERC20_MANAGER_ROLE =
        keccak256("ERC20_MANAGER_ROLE");
    bytes32 public constant ARTIST_ROLE = keccak256("ARTIST_ROLE");

    constructor(address _SuperAdmin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _SuperAdmin);
        _setRoleAdmin(MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ARTIST_MANAGER_ROLE, MANAGER_ROLE);
        _setRoleAdmin(NFT_MANAGER_ROLE, MANAGER_ROLE);
        _setRoleAdmin(ERC20_MANAGER_ROLE, MANAGER_ROLE);
        _setRoleAdmin(ARTIST_ROLE, ARTIST_MANAGER_ROLE);
    }

    //Modifiers
    modifier onlySuperAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Roles: Only SuperAdmin has access"
        );
        _;
    }

    modifier onlyManager() {
        require(
            hasRole(MANAGER_ROLE, msg.sender),
            "Roles: Only Manager has access"
        );
        _;
    }

    modifier onlyArtistManager() {
        require(
            hasRole(ARTIST_MANAGER_ROLE, msg.sender),
            "Roles: Only ArtistManager has access"
        );
        _;
    }

    modifier onlyNFTManager() {
        require(
            hasRole(NFT_MANAGER_ROLE, msg.sender),
            "Roles: Only NFTManager has access"
        );
        _;
    }

    modifier onlyERC20Manager() {
        require(
            hasRole(ERC20_MANAGER_ROLE, msg.sender),
            "Roles: Only ERC20Manager has access"
        );
        _;
    }

    modifier onlyArtist() {
        require(
            hasRole(ARTIST_ROLE, msg.sender),
            "Roles: Only Artist has access"
        );
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
    function addSuperAdmin(address _address)
        external
        onlySuperAdmin
        returns (bool)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _address);
        return true;
    }

    /// @notice Grant Manager role to `_address`
    /// @dev Requirements:caller must have SuperAdmin role
    ///      May emit a {RoleGranted} event
    /// @param _address address to grant Manager role
    /// @return true if the role was successfully granted
    function addManager(address _address)
        external
        onlySuperAdmin
        returns (bool)
    {
        _grantRole(MANAGER_ROLE, _address);
        return true;
    }

    /// @notice Grant ArtistManager role to `_address`
    /// @dev Requirements:caller must have Manager role
    ///      May emit a {RoleGranted} event
    /// @param _address address to grant ArtistManager role
    /// @return true if the role was successfully granted
    function addArtistManager(address _address)
        external
        onlyManager
        returns (bool)
    {
        _grantRole(ARTIST_MANAGER_ROLE, _address);
        return true;
    }

    /// @notice Grant NFTManager role to `_address`
    /// @dev Requirements:caller must have Manager role
    ///      May emit a {RoleGranted} event
    /// @param _address address to grant NFTManager role
    /// @return true if the role was successfully granted
    function addNFTManager(address _address)
        external
        onlyManager
        returns (bool)
    {
        _grantRole(NFT_MANAGER_ROLE, _address);
        return true;
    }

    /// @notice Grant ERC20tManager role to `_address`
    /// @dev Requirements:caller must have Manager role
    ///      May emit a {RoleGranted} event
    /// @param _address address to grant ERC20Manager role
    /// @return true if the role was successfully granted
    function addERC20Manager(address _address)
        external
        onlyManager
        returns (bool)
    {
        _grantRole(ERC20_MANAGER_ROLE, _address);
        return true;
    }

    /// @notice Grant Artist role to `_address`
    /// @dev Requirements:caller must have ArtistManager role
    ///      May emit a {RoleGranted} event
    /// @param _address address to grant Artist role
    /// @return true if the role was successfully granted
    function addArtist(address _address)
        external
        onlyArtistManager
        returns (bool)
    {
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
    function removeManager(address _address)
        external
        onlySuperAdmin
        returns (bool)
    {
        _revokeRole(MANAGER_ROLE, _address);
        return true;
    }

    /// @notice Revokes ArtistManager role from `_address`
    /// @dev If `_address` had been revoked ArtistManager role, emits a {RoleRevoked} event
    ///      Requirements:the caller must have Manager role
    /// @param _address address to revoke ArtistManager role from it
    /// @return true if the role was successfully revoked
    function removeArtistManager(address _address)
        external
        onlyManager
        returns (bool)
    {
        _revokeRole(ARTIST_MANAGER_ROLE, _address);
        return true;
    }

    /// @notice Revokes NFTManager role from `_address`
    /// @dev If `_address` had been revoked NFTManager role, emits a {RoleRevoked} event
    ///      Requirements:the caller must have Manager role
    /// @param _address address to revoke NFTManager role from it
    /// @return true if the role was successfully revoked
    function removeNFTManager(address _address)
        external
        onlyManager
        returns (bool)
    {
        _revokeRole(NFT_MANAGER_ROLE, _address);
        return true;
    }

    /// @notice Revokes ERC20Manager role from `_address`
    /// @dev If `_address` had been revoked ERC20Manager role, emits a {RoleRevoked} event
    ///      Requirements:the caller must have Manager role
    /// @param _address address to revoke ERC20Manager role from it
    /// @return true if the role was successfully revoked
    function removeERC20Manager(address _address)
        external
        onlyManager
        returns (bool)
    {
        _revokeRole(ERC20_MANAGER_ROLE, _address);
        return true;
    }

    /// @notice Revokes Artist role from `_address`
    /// @dev If `_address` had been revoked Artist role, emits a {RoleRevoked} event
    ///      Requirements:the caller must have ArtistManager role
    /// @param _address address to revoke Artist role from it
    /// @return true if the role was successfully revoked
    function removeArtist(address _address)
        external
        onlyArtistManager
        returns (bool)
    {
        _revokeRole(ARTIST_ROLE, _address);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FlokiStorage {
    /// @notice address of Smart Contract ERC20 FlokiToken
    address public flokiTokenAddress;

    /// @notice address of Smart Contract ERC721 SongNFT
    address public songNFTAddress;    

    /// @notice value of decimals used in the project
    uint8 public decimals;

    /// @notice bool value which shows if the ERC20-contract opened for any user. Default - false
    bool public ERC20openForAll;

    /// @notice bool value which shows if the ERC721-contract opened for any user. Default - false
    bool public NFTopenForAll;

    /// @notice value of reward for Artist for listening of his/her songs
    uint256 public artistRepeatReward;

    /// @notice value of reward for Listener for first listening of the songs
    uint256 public listenerFirstReward;

    /// @notice value of reward for Listener for next listenings of the songs
    uint256 public listenerRepeatReward;

    /// @notice value of exclusive reward for song
    uint256 public exclusiveSongReward;

    /// @notice All data of the Song
    struct Song {
        //ID of the song
        string songID;
        //ID of the artist who is owner of the song. =userID in struct Artist
        string artistID;
        //ID of the album which includes this song
        string albumID;
        //name of the song
        string songName;
        //`true` - NFT for this song was minted or `false` - not
        bool mintedNFT;
    }

    struct Artist {
        //ID of the Artist
        string userID;
        //official wallet-address of Artist
        address userWalletAddress;
        //the array of IDs of all songs added by this Artist
        string[] songIDs;
        //amount of FlokiTokens Artist earned
        uint256 totalFlokiToken;
    }

    //mapping of (ID of Artist) => (struct Artist)
    mapping(string => Artist) artistIDToData;

    //mapping of (ID of Song) => (struct Song)
    mapping(string => Song) songIDToData;
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