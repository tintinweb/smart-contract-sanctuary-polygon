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

contract TuneAIv2 is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
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
        string songCID,
        string coverCID
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
    New ratiung event
    @param rater: the address that rated
    @param index: the song id
    @param rating: the rating amount
     */

    event Rated(address indexed rater, uint256 indexed index, uint256 rating);

    /*
      Track is a struct that declares the necessary values for a song
      @param owner: the address that uploaded the song
      @param artist: the artist name
      @param title: the song title
      @param ipfsURL: the IPFS url of the audio file 
      @param albumCover: the IPFS url for the album cover art
      @param genre: genre from the enum Genre
      @param totalRatings: the total amount of ratings
      @param numRatings: the value of the ratings
      To get the avg rating, divide totalRatings / numRatings
     */

    struct Track {
        address owner;
        string artist;
        string title;
        string songCID;
        string coverCID;
        uint id;
        Genre genre;
        uint256 totalRatings;
        uint256 numRatings;
        bool highlighted;
    }

    /*
      Enum for Genre type
      @param genres: a list of all the popular genres 
     */

    enum Genre {
        Unknown,
        Pop,
        Rock,
        HipHop,
        Rap,
        Soul,
        EDM,
        Alternative,
        Country,
        Dance,
        Jazz,
        Classical,
        Other
    }

    /* 
    Struct for the rating
    @param index: the song iD
    @param rating: the rating
    */

    struct Rating {
        uint256 index;
        uint256 rating;
    }

    Track[] public tracks; // track all the Track's
    Counters.Counter private _songIds; // private tracker for song ID's
    mapping(address => Rating[]) public _ratings; // tracks ratings
    uint256[] public tracksByGenre; // search tracks by genre
    mapping(string => uint256[]) public tracksByArtist; // search tracks by artist
    mapping(string => uint256[]) public tracksByTitle; // search tracks by title
    mapping(address => uint256[]) public tracksByOwner; // search tracks by owner

    /*
    Function to upload a song
    Checks the keccak256 of the tartist and title to prevent duplicates
    @param _artist: artist name
    @param _title: song title
    @param _ipfsURL: the IPFS url for the song to play
    @param _albumCover: the IPFS url for the album cover
    @param _genre: select the appropriate
   */

    function uploadTrack(
        string memory _artist,
        string memory _title,
        string memory _songCID,
        string memory _coverCID,
        Genre _genre
    ) external {
        for (uint256 i = 0; i < tracks.length; i++) {
            if (
                keccak256(bytes(tracks[i].artist)) ==
                keccak256(bytes(_artist)) &&
                keccak256(bytes(tracks[i].title)) == keccak256(bytes(_title))
            ) {
                revert("Song exists");
            }
        }
        string memory songIPFSURL = string(
            abi.encodePacked("https://ipfs.io/ipfs/", _songCID)
        );
        string memory coverIPFSURL = string(
            abi.encodePacked("https://ipfs.io/ipfs/", _coverCID)
        );
        Track memory newTrack = Track(
            msg.sender,
            _artist,
            _title,
            songIPFSURL,
            coverIPFSURL,
            _songIds.current(),
            _genre,
            0,
            0,
            false
        );
        tracks.push(newTrack);
        tracksByGenre.push(tracks.length - 1);
        tracksByArtist[_artist].push(tracks.length - 1);
        tracksByTitle[_title].push(tracks.length - 1);
        tracksByOwner[msg.sender].push(tracks.length - 1);
        _songIds.increment();
        emit NewSong(msg.sender, _artist, _title, songIPFSURL, coverIPFSURL);
    }

    /*
    Function to rate a track
    @param _index: the song id
    @param _rating: the rating value from 1-5
   */

    function rateTrack(uint256 _index, uint256 _rating) external {
        require(_index < tracks.length, "Invalid ID");
        require(_rating >= 1 && _rating <= 5, "Invalid rating");
        Track storage track = tracks[_index];
        require(track.owner != address(0), "Invalid track");
        require(msg.sender != track.owner, "Cannot rate own track");
        // find the rating for the given track ID
        Rating[] storage ratings = _ratings[track.owner];
        bool ratingFound = false;
        for (uint i = 0; i < ratings.length; i++) {
            if (ratings[i].index == _index) {
                ratingFound = true;
                ratings[i].rating = _rating;
                track.totalRatings += _rating - ratings[i].rating;
                break;
            }
        }
        if (!ratingFound) {
            // user has not rated this track before
            ratings.push(Rating(_index, _rating));
            track.totalRatings += _rating;
            track.numRatings++;
        }

        emit Rated(msg.sender, _index, _rating);
    }

    /* 
    Function to donate to the artist that created the song
    @param _index: the song ID
    Takes the OpenZeppelin nonReentrant modifier to prevent attacks
    */

    function donateToArtist(uint256 _index) external payable nonReentrant {
        require(_index < tracks.length, "Invalid ID");
        require(msg.value > 0, "Amount must be > 0");
        address payable owner = payable(tracks[_index].owner);
        owner.transfer(msg.value);
        emit Donated(msg.sender, _index, msg.value);
    }

    /*
    Function to highlight a song based on their rating
    @param _index: the song ID
        Takes the OpenZeppelin nonReentrant modifier to prevent attacks
    */
    function highlightSong(uint256 _index) external payable nonReentrant {
        require(_index < tracks.length, "Invalid ID");
        require(msg.value == 100 ether, "Invalid amount");
        Track storage track = tracks[_index];
        require(track.totalRatings > 5, "5 or more ratings required");
        require(
            track.totalRatings / track.numRatings >= 4,
            "Need avg rating of 4 or more"
        );
        require(!track.highlighted, "Already highlighted");
        track.highlighted = true;
    }

    /*
    UPDATE FUNCTIONS
     */

    /*
    Function to update title
    @param _index: the song ID
    @param _title: the new title
   */

    function updateTitle(uint256 _index, string memory _title) external {
        require(_index < tracks.length, "Invalid ID");
        require(
            msg.sender == tracks[_index].owner,
            "Only the owner can update the title"
        );
        tracks[_index].title = _title;
    }

    /*
    Function to update artist
    @param _index: the song ID
    @param _title: the new artist
   */

    function updateArtist(uint256 _index, string memory _artist) external {
        require(_index < tracks.length, "Invalid ID");
        require(
            msg.sender == tracks[_index].owner,
            "Only the owner can update the arist"
        );
        tracks[_index].artist = _artist;
    }

    /*
    Function to update genre
    @param _index: the song ID
    @param _genre: the new genre
   */

    function updateGenre(uint256 _index, Genre _genre) external {
        require(_index < tracks.length, "Invalid ID");
        require(
            msg.sender == tracks[_index].owner,
            "Only the owner can update the genre"
        );
        tracks[_index].genre = _genre;
    }

    /*
    Function to update song CID
    @param _index: the song ID
    @param _songCID: the new CID 
   */

    function updateSongCID(uint256 _index, string memory _songCID) external {
        require(_index < tracks.length, "Invalid ID");
        require(
            msg.sender == tracks[_index].owner,
            "Only the owner can update the songCID"
        );
        string memory songIPFSURL = string(
            abi.encodePacked("https://ipfs.io/ipfs/", _songCID)
        );
        tracks[_index].songCID = songIPFSURL;
    }

    /*
    Function to update album cover CID
    @param _index: the song ID
    @param _coverCID: the new album cover CID
   */

    function updateCoverCID(uint256 _index, string memory _coverCID) external {
        require(_index < tracks.length, "Invalid ID");
        require(
            msg.sender == tracks[_index].owner,
            "Only the owner can update the coverCID"
        );
        string memory coverIPFSURL = string(
            abi.encodePacked("https://ipfs.io/ipfs/", _coverCID)
        );
        tracks[_index].coverCID = coverIPFSURL;
    }

    /*
    Function to withdraw funds from the contract    
    Only the contract owner can call this function
    */
    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available");
        payable(owner()).transfer(balance);
    }
}