//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

/**
@title - FreechainNFTArtist 
@notice - This contract is used to manage the artist signup and artist profile.
@dev - The artist can signup and update their profile.
@author - FrankUdoags https://github.com/frankudoags [email protected]
 */

contract FreechainArtist {
    ///@notice - Raised when an address is already an artist.
    error Freechain__AlreadyAnArtist();
    ///@notice - Raised when a non-artist address tries to call an artist-gated function.
    error Freechain__OnlyArtists();

    /**
      @notice - Artist ID counter
    */
    uint public artistCount = 0;

    /**
      @notice - id of the creator of the day.
    */
    uint randomArtistID;

    /**
   @dev - Mapping to check if an address is an artist
    */
    mapping(address => bool) public isArtist;

    /**
      @notice - Mapping of artist address to Artist
    */
    mapping(address => Artist) public artistByAddress;

    /**
      @notice - Structure of an Artist
      @param - id: Id for each artist
      @param - dateJoined: Date artist joined platform
      @param - artistAddress: address of the artist
      @param - artistDetails: Artist details
     */
    struct Artist {
        uint id;
        uint dateJoined;
        address artistAddress;
        string artistDetails;
    }
    /**
    @notice - Event for new artist sign-up
     */
    event newArtistJoined(
        uint id,
        uint dateJoined,
        address artistAddress,
        string artistDetails
    );

    /**
   @notice - Array to store all artists
    */
    Artist[] public artists;

    /**
   @notice - Function for new artist sign-up
   @param _artistDetails - HASH of artist details
    */

    function newArtistSignup(string memory _artistDetails)
        external
        onlyNonArtists
    {
        require(bytes(_artistDetails).length > 0);
        artistCount++;
        Artist memory newArtist = Artist({
            id: artistCount,
            dateJoined: block.timestamp,
            artistAddress: msg.sender,
            artistDetails: _artistDetails
        });
        isArtist[msg.sender] = true;
        artists.push(newArtist);
        artistByAddress[msg.sender] = newArtist;
        emit newArtistJoined(
            artistCount,
            block.timestamp,
            msg.sender,
            _artistDetails
        );
    }

    /**
    @notice - Function for artist to update artist details
    @param _artistDetails - HASH of artist details
    @param _artistid - id of specific artist
    */
    function updateArtistDetails(
        string memory _artistDetails,
        uint256 _artistid
    ) external onlyArtists {
        require(artists[_artistid].artistAddress == msg.sender);
        artists[_artistid].artistDetails = _artistDetails;
    }

    /**
    @notice - Function to get all artists
    */
    function getAllArtists() external view returns (Artist[] memory) {
        return artists;
    }
    /**
    @notice - Function to get a random artist
     */
    function getCreatorofTheDay() external view returns (Artist memory) {
        return artists[randomArtistID];
    }
    










    ///MODIFIERS

    ///@notice - Modifier to check if an address is an artist
    modifier onlyArtists() {
        if (isArtist[msg.sender] == false) {
            revert Freechain__OnlyArtists();
        }
        _;
    }
    ///@notice - Modifier to check if an address is not an artist
    modifier onlyNonArtists() {
        if (isArtist[msg.sender] == true) {
            revert Freechain__AlreadyAnArtist();
        }
        _;
    }
}