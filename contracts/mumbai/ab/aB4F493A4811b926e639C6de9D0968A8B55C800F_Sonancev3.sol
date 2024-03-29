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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Sonancev3 is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // Custom errors for gas saving
    error SongExists();
    error NameTaken();
    error NotOwner();
    error InvalidAmount();
    error InvalidAddress();
    error InvalidID();
    error DoesntExist();
    error AlreadyDeleted();

    /*
    New song event
    @param artist
    @param title
    @param songCID
    @param coverCID
     */
    event NewSong(
        address indexed owner,
        string artist,
        string title,
        string trackIPFS,
        string coverIPFS
    );

    /*
    New donation event
    @param sender: the donator
    @param index: the song id
    @param amount: the donation amount
     */
    event Donated(
        address indexed sender,
        uint256 indexed index,
        uint256 amount
    );

    /*
    New playlist event
    @param owner: owner of the playlist
    @param name: name of the playlist
    @param trackIds: the array of tracks
     */
    event NewPlaylist(address indexed owner, string name, uint256[] trackIds);

    /*
      Track is a struct that declares the necessary values for a song
      @param owner: the address that uploaded the song
      @param artist: the artist name
      @param title: the song title
      @param coverIPFS: the IPFS url for cover art
      @param trackIPFS: the IPFS url for the song
      @param genre: genre from the enum Genre
      @param totalRatings: the total amount of ratings
      @param numRatings: the value of the ratings
      To get the avg rating, divide totalRatings / numRatings
     */
    struct Track {
        address owner;
        string artist;
        string title;
        string coverIPFS;
        string trackIPFS;
        uint songId;
        Genre genre;
    }

    /* 
    Playlist is a struct that takes in the trackIds as an array to build a playlist
    @param trackIds: the array of tracks in the palylist by ID
    @param name: the playlist name
    */
    struct Playlist {
        uint256[] trackIds;
        string name;
        address owner;
        uint playlistId;
    }

    /*
      Enum for Genre type
      @param genres: a list of all the popular genres 0-12
     */
    enum Genre {
        Unknown, // 0
        Pop, // 1
        Rock, // 2
        HipHop, // 3
        Rap, // 4
        Soul, // 5
        EDM, // 6
        Alternative, // 7
        Country, // 8
        Dance, // 9
        Jazz, // 10
        Classical, // 11
        Other // 12
    }

    Track[] public tracks; // reveals property of a track by id
    Playlist[] public playlists; // array of playlists
    Counters.Counter public trackIds; //  tracker for song id's
    Counters.Counter public playlistIds; // tracker for playlist id's
    mapping(uint => uint) public likes; // input songId to see how many likes it has

    /*
    Function to upload a song
    @param _artist: artist name
    @param _title: song title
    @param _coverIPFS: the IPFS url for the song to play
    @param _trackIPFS: the IPFS url for the song to play
    @param _genre: select the appropriate
    NOTE: Checks the keccak256 hash of the artist and title to prevent duplicates
    NOTE: Requires the msg.sender set their artist name first
   */
    function uploadTrack(
        string memory _artist,
        string memory _title,
        string memory _coverIPFS,
        string memory _trackIPFS,
        Genre _genre
    ) external {
        for (uint256 i = 0; i < tracks.length; i++) {
            if (
                keccak256(bytes(tracks[i].artist)) ==
                keccak256(bytes(_artist)) &&
                keccak256(bytes(tracks[i].title)) == keccak256(bytes(_title)) &&
                keccak256(bytes(tracks[i].coverIPFS)) ==
                keccak256(bytes(_coverIPFS)) &&
                keccak256(bytes(tracks[i].trackIPFS)) ==
                keccak256(bytes(_trackIPFS))
            ) {
                revert SongExists();
            }
        }
        Track memory newTrack = Track(
            msg.sender,
            _artist,
            _title,
            _coverIPFS,
            _trackIPFS,
            trackIds.current(),
            _genre
        );
        tracks.push(newTrack);
        trackIds.increment();
        emit NewSong(msg.sender, _artist, _title, _coverIPFS, _trackIPFS);
    }

    /* 
    Function to like a track and add it to a playlist
    @param _songId: the song ID
    @param _playlistID: the playlist to add too
    */
    function likeTrack(uint256 _songId, uint256 _playlistId) external {
        if (_songId >= tracks.length) {
            revert InvalidID();
        }
        likes[_songId]++;
        if (
            _playlistId < playlists.length &&
            playlists[_playlistId].owner == msg.sender
        ) {
            playlists[_playlistId].trackIds.push(_songId);
        }
    }

    /* 
    Function to delete a song
    @param _songId: the song id to delete
    */
    function deleteTrack(uint256 _songId) external {
        if (msg.sender != tracks[_songId].owner) {
            revert NotOwner();
        }
        if (_songId >= tracks.length) {
            revert DoesntExist();
        }
        delete tracks[_songId];
    }

    /* 
    Function to create a new playlist
    @param _name: the playlist name
    @param _trackIds: the tracks they want to add
    */
    function createPlaylist(
        string memory _name,
        uint256[] memory _trackIds
    ) external {
        if (_trackIds.length <= 0) {
            revert InvalidAmount();
        }
        Playlist memory newPlaylist = Playlist(
            _trackIds,
            _name,
            msg.sender,
            playlistIds.current()
        );
        playlists.push(newPlaylist);
        playlistIds.increment();
        emit NewPlaylist(msg.sender, _name, _trackIds);
    }

    /* 
    Function to delete a playlist
    @param _playlistId: the playlist ID to delete
    */
    function deletePlaylist(uint256 _playlistId) external {
        if (msg.sender != playlists[_playlistId].owner) {
            revert NotOwner();
        }
        if (_playlistId >= playlists.length) {
            revert DoesntExist();
        }
        if (playlists[_playlistId].trackIds.length <= 0) {
            revert AlreadyDeleted();
        }
        delete playlists[_playlistId].trackIds; // removes from trackIds array
        delete playlists[_playlistId]; // removes struct
    }

    /* 
    Function to donate to the artist that created the song
    @param _songId: the song ID
    NOTE: Takes the OpenZeppelin nonReentrant modifier to prevent attacks
    */
    function donateToArtist(uint256 _songId) external payable nonReentrant {
        if (msg.value <= 0) {
            revert InvalidAmount();
        }
        if (_songId >= tracks.length) {
            revert InvalidID();
        }
        address payable trackOwner = payable(tracks[_songId].owner);
        trackOwner.transfer(msg.value);
        emit Donated(msg.sender, _songId, msg.value);
    }

    /*
    UPDATE FUNCTIONS
     */

    /*
     Function to update playlist title 
     @param _playlistId: the playlistID
     @param _name: the new name
     */

    function updatePlaylistTitle(
        uint256 _playlistId,
        string memory _name
    ) external {
        if (msg.sender != playlists[_playlistId].owner) {
            revert NotOwner();
        }
        if (_playlistId > playlists.length) {
            revert DoesntExist();
        }
        playlists[_playlistId].name = _name;
    }

    /*
    Function to update artist
    @param _songId: the song ID
    @param _title: the new artist
   */
    function updateArtist(uint256 _songId, string memory _artist) external {
        if (msg.sender != tracks[_songId].owner) {
            revert NotOwner();
        }
        if (_songId > tracks.length) {
            revert InvalidID();
        }
        tracks[_songId].artist = _artist;
    }

    /*
    Function to update title
    @param _songId: the song ID
    @param _title: the new title
   */
    function updateTitle(uint256 _songId, string memory _title) external {
        if (msg.sender != tracks[_songId].owner) {
            revert NotOwner();
        }
        if (_songId > tracks.length) {
            revert InvalidID();
        }
        tracks[_songId].title = _title;
    }

    /*
    Function to update genre
    @param _songId: the song ID
    @param _genre: the new genre
   */
    function updateGenre(uint256 _songId, Genre _genre) external {
        if (msg.sender != tracks[_songId].owner) {
            revert NotOwner();
        }
        if (_songId > tracks.length) {
            revert InvalidID();
        }
        tracks[_songId].genre = _genre;
    }

    /*
    Function to update track IPFS url
    @param _songId: the song ID
    @param _trackIPFS: the new url
   */
    function updateTrackIPFS(
        uint256 _songId,
        string memory _trackIPFS
    ) external {
        if (msg.sender != tracks[_songId].owner) {
            revert NotOwner();
        }
        if (_songId > tracks.length) {
            revert InvalidID();
        }
        tracks[_songId].trackIPFS = _trackIPFS;
    }

    /*
    Function to update cover art
    @param _songId: the song ID
    @param _coverIPFS: the new url 
   */
    function updateCoverIPFS(
        uint256 _songId,
        string memory _coverIPFS
    ) external {
        if (msg.sender != tracks[_songId].owner) {
            revert NotOwner();
        }
        if (_songId > tracks.length) {
            revert InvalidID();
        }
        tracks[_songId].coverIPFS = _coverIPFS;
    }

    /* 
    Admin Only
    */

    /*
    Function to withdraw funds from the contract    
    NOTE: This is only for funds that are accidentally sent to the contract
    NOTE: Only the contract owner can call this function
    NOTE: Takes the OpenZeppellin nonReentrat to prevent attacks
    */
    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available");
        payable(owner()).transfer(balance);
    }

    /* 
    Function to force delete a song that violates rules
    NOTE: This is only for those abusing copyright laws
    NOTE: Only the contract owner can call this function
    NOTE: Takes the OpenZeppellin nonReentrat to prevent attacks
    */

    function deleteAdminTrack(uint256 _songId) external onlyOwner {
        if (_songId >= tracks.length) {
            revert DoesntExist();
        }
        delete tracks[_songId];
    }
}