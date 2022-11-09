// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {TaleContract} from "TaleContract.sol";

contract TaleManager {
    // TALES
    /// @notice list of all the tale contract addresses
    address[] public tales;
    /// @notice tale contract address to its details
    mapping(address => TailDetails) public _tailDetails;

    // AUTHOR
    /// @notice author address to author name
    mapping(address => string) public _author;
    /// @notice addresses registered as authors
    mapping(address => bool) public _isAuthor;
    /// @notice bytes32 of authors name to availability
    mapping(bytes32 => bool) public _authorNameTaken;

    /// @notice details of each tale contract
    /// @param name teh name of the tale
    /// @param author the author of the tale
    /// @param imageCover the image cover for the tale
    /// @param cretaedAt the time the tale was launched
    /// @param interval the interval at which new chapters drop
    /// @param Genre the type of tale it is using number as representations of different genres
    /// @param creator the authors address
    struct TailDetails {
        string name;
        string author;
        string imageCover;
        string description;
        uint256 createdAt;
        uint256 interval;
        uint8 Genre;
        address creator;
    }

    address public priceFeedAddress;

    // emits when a new tale is created
    event TaleCreated(
        string name,
        string author,
        string imageCover,
        uint256 indexed timeCreated,
        uint256 indexed genre,
        address taleContract,
        address creator
    );

    // emits when someone comments on a chapter for a tale
    event ChapterComment(address taleChapterAddress, string userComment);

    constructor(address _priceFeedAddress) {
        priceFeedAddress = _priceFeedAddress;
    }

    /// @notice registers the address as an author
    /// @dev gives the address priviledge to create a tale
    /// @param _authorName the name the address wishes to go by as an author
    function registerAsAuthor(string memory _authorName) public {
        bytes32 authorInBytes = keccak256(abi.encodePacked(_authorName));
        if (_authorNameTaken[authorInBytes]) {
            revert("TYT#1");
        }
        _author[msg.sender] = _authorName;
        _isAuthor[msg.sender] = true;
        _authorNameTaken[authorInBytes] = true;
    }

    /// @notice creates a tale for the author
    /// @dev this tale would be the entry point to chapter creation
    /// @param _name the name of your tale e.g The flying bear
    /// @param _imageCover the cover image URI for your story e.g an image of a bear flying in the sky
    /// @param _description a short description of what your tale is all about
    /// @param _interval how long it takes for the next chapter to drop
    /// @param _genre genre type of your tale, there is a list from 1 to 12
    function createYourTale(
        string memory _name,
        string memory _imageCover,
        string memory _description,
        uint256 _interval,
        uint8 _genre
    ) public {
        if (!_isAuthor[msg.sender]) {
            revert("TYT#2");
        }

        TaleContract taleContract = new TaleContract(
            _name,
            _description,
            _author[msg.sender],
            _imageCover,
            block.timestamp,
            _genre,
            msg.sender,
            priceFeedAddress
        );

        tales.push(address(taleContract));

        _tailDetails[address(taleContract)] = TailDetails({
            name: _name,
            author: getAuthorByAddress(msg.sender),
            imageCover: _imageCover,
            description: _description,
            createdAt: block.timestamp,
            interval: _interval,
            Genre: _genre,
            creator: msg.sender
        });

        emit TaleCreated(
            _name,
            getAuthorByAddress(msg.sender),
            _imageCover,
            block.timestamp,
            _genre,
            address(taleContract),
            msg.sender
        );
    }

    ///@notice allows users comment on the chapter of a tale
    ///@param _taleChapterAddress the tale chpter address
    ///@param _comment the comment the user wants to leave behind
    function commentOnChapter(
        address _taleChapterAddress,
        string memory _comment
    ) public {
        emit ChapterComment(_taleChapterAddress, _comment);
    }

    /// @notice gets the author from its address
    /// @param _authorAddress the authors address
    /// @return the author
    function getAuthorByAddress(address _authorAddress)
        public
        view
        returns (string memory)
    {
        return _author[_authorAddress];
    }

    /// @notice gets the tale details from its contract address
    /// @param _taleContractAddress the tale contract address
    /// @return the tale details for the specified tale
    function getTaleDetails(address _taleContractAddress)
        public
        view
        returns (TailDetails memory)
    {
        return _tailDetails[_taleContractAddress];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {AggregatorV3Interface} from "AggregatorV3Interface.sol";

contract TaleContract {
    /// @notice the name of the tale
    string public taleName;
    /// @notice the image cover URI for the tale
    string public imageCover;
    /// @notice the tale description
    string public taleDescription;
    /// @notice the author of the tale
    string public author;

    /// @notice the address of the author
    address public authorAddress;

    /// @notice the time the tale was created
    uint256 public taleCreationTime;

    /// @notice the latest chapter
    uint256 public chapterCount;

    /// @notice chainlink price feed
    AggregatorV3Interface public priceFeed;

    /// @notice the genre for the tale
    uint8 public genre;

    struct ChapterDetails {
        string name;
        string description;
        string chapterURI;
        string imageCover;
        string author;
        uint256 genre;
        uint256 costInUsd;
    }

    mapping(uint256 => ChapterDetails) public _chapterToDetails;

    mapping(address => uint256) public _authorBalance;

    mapping(uint256 => mapping(address => bool)) public _minted;

    constructor(
        string memory _name,
        string memory _description,
        string memory _author,
        string memory _imageCover,
        uint256 _createdAt,
        uint8 _genre,
        address _creator,
        address _priceFeedAddress
    ) {
        authorAddress = _creator;
        author = _author;

        taleName = _name;
        imageCover = _imageCover;
        taleCreationTime = _createdAt;
        taleDescription = _description;
        genre = _genre;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    /// @notice allows the author to drop new chapter for the tale
    /// @param _chapterName the name of the chapter
    /// @param _chapterDescription the description of the chapter
    /// @param _chapterImageCover the URI for the chapter cover
    /// @param _costInUsd the cost in USD i.e will be in 8 decimals in client
    /// @param _chapterURI the encrypted link for the tale chapter
    /// @param _genre genre
    function dropNewChapter(
        string memory _chapterName,
        string memory _chapterDescription,
        string memory _chapterImageCover,
        uint256 _costInUsd,
        string memory _chapterURI,
        uint256 _genre
    ) public {
        if (msg.sender != authorAddress) {
            revert("!author");
        }
        chapterCount++;

        _chapterToDetails[chapterCount] = ChapterDetails({
            name: _chapterName,
            description: _chapterDescription,
            chapterURI: _chapterURI,
            imageCover: _chapterImageCover,
            author: author,
            genre: _genre,
            costInUsd: _costInUsd
        });
    }

    /// @notice mints the chapter for the user
    /// @dev gives the user the access to decrypt the chapter of the tale
    function mintChapter(uint256 _chapter) public payable {
        require(msg.value >= costInNativeAsset(_chapter), "Not enough asset");
        require(!_minted[_chapter][msg.sender], "already minted");
        _minted[_chapter][msg.sender] = true;
        uint256 amountGivenToAuthor = msg.value;

        _authorBalance[authorAddress] += amountGivenToAuthor;
    }

    /// @notice core function for the lit protocol nodes to use to decrypt
    /// @dev only allows users who have minted in the past to decrypt
    /// @param _user teh address of the user trying to decrypt
    function isAllowedToViewChapter(address _user, uint256 _chapter)
        public
        view
        returns (bool)
    {
        bool minted = _minted[_chapter][_user];
        return minted;
    }

    function getChapterCostInUSD(uint256 _chapter)
        public
        view
        returns (uint256)
    {
        return _chapterToDetails[_chapter].costInUsd;
    }

    ///@notice get the current chapter
    function getCurrentChapter() public view returns (uint256) {
        return chapterCount;
    }

    ///@notice get the tale chapter details
    function getTaleChapterDetails(uint256 _chapter)
        public
        view
        returns (ChapterDetails memory)
    {
        return _chapterToDetails[_chapter];
    }

    /// @notice gets the price of the asset using chainlinks price feed
    /// @return returns the price of the asset
    function getPrice() public view returns (uint256) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    /// @notice returns the amount in native asset needed to satisfy teh usd required amount
    function costInNativeAsset(uint256 _chapter) public view returns (uint256) {
        return (getChapterCostInUSD(_chapter) * 10**18) / getPrice();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}