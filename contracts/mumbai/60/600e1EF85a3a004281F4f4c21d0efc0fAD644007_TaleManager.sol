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
    /// @param class type of tale i.e between a manga/comic - true or a story - false
    /// @param creator the authors address
    struct TailDetails {
        string name;
        string author;
        string imageCover;
        uint256 createdAt;
        uint256 interval;
        uint8 Genre;
        bool class;
        address creator;
    }

    // emits when a new tale is created
    event TaleCreated(
        string name,
        string author,
        string imageCover,
        uint256 indexed timeCreated,
        uint256 indexed genre,
        bool indexed class,
        address taleContract,
        address creator
    );

    // emits when someone adds the tale as favorites
    event Favorite(address taleAddress, address user, bool status);

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
    /// @param _class the classs of your tale, true for manga/comic and false for story
    function createYourTale(
        string memory _name,
        string memory _imageCover,
        string memory _description,
        uint256 _interval,
        uint8 _genre,
        bool _class
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
            _interval,
            _genre,
            _class,
            msg.sender
        );

        tales.push(address(taleContract));

        _tailDetails[address(taleContract)] = TailDetails({
            name: _name,
            author: getAuthorByAddress(msg.sender),
            imageCover: _imageCover,
            createdAt: block.timestamp,
            interval: _interval,
            Genre: _genre,
            class: _class,
            creator: msg.sender
        });

        emit TaleCreated(
            _name,
            getAuthorByAddress(msg.sender),
            _imageCover,
            block.timestamp,
            _genre,
            _class,
            address(taleContract),
            msg.sender
        );
    }

    /// @notice add a tale as favorites
    /// @param _taleAddress the address of the tale you wish to add as a favorite
    function addToFavorites(address _taleAddress) public {
        emit Favorite(_taleAddress, msg.sender, true);
    }

    /// @notice add a tale as favorites
    /// @param _taleAddress the address of the tale you wish to add as a favorite
    function removeFromFavorites(address _taleAddress) public {
        emit Favorite(_taleAddress, msg.sender, false);
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

import {ChapterContract} from "ChapterContract.sol";

contract TaleContract {
    /// @notice the name of the tale
    string public taleName;
    /// @notice the image cover URI for the tale
    string public imageCover;
    /// @notice the tale description
    string public taleDescription;
    /// @notice the author of the tale
    string public author;

    /// @notice the class of the tale, true for manga/comic and false for story
    bool public class;

    /// @notice the address of the author
    address public authorAddress;
    /// @notice the list of contract addresses for each deployed chapter
    address[] public chapters;

    /// @notice the time the tale was created
    uint256 public taleCreationTime;
    /// @notice the time the next chapter drops
    uint256 public expectedDropInterval;

    /// @notice the latest chapter
    uint256 public chapterCount;
    /// @notice the total number of users who'v rated the tale
    uint256 public raters;
    /// @notice the current rating by users for this tale
    uint256 public currentRating;
    /// @notice the total number of subscribers for this tale
    uint256 public subscriberCount;
    /// @notice the total minters for the tale accross all chapters
    uint256 public totalMintersAcrossChapters;
    /// @notice the genre for the tale
    uint8 public genre;
    ///@notice the list of ratings
    uint8[] public ratingsList;

    mapping(address => bool) public _subscribed;

    event ChapterCreated(
        string chapterURI,
        string chapterName,
        uint256 chapterNumber,
        string chapterImageCover,
        uint256 chapterCreationTime,
        address chapterContractAddress,
        address tale
    );

    constructor(
        string memory _name,
        string memory _description,
        string memory _author,
        string memory _imageCover,
        uint256 _createdAt,
        uint256 _interval,
        uint8 _genre,
        bool _class,
        address _creator
    ) {
        authorAddress = _creator;
        author = _author;

        taleName = _name;
        imageCover = _imageCover;
        taleCreationTime = _createdAt;
        taleDescription = _description;
        expectedDropInterval = _interval;
        genre = _genre;
        class = _class;
    }

    /// @notice allows the author to drop new chapter for the tale
    /// @dev deploys a new contract for the chapter
    /// @param _chapterName the name of the chapter
    /// @param _chapterImageCover the URI for the chapter cover
    /// @param _costInUsd the cost in USD i.e will be multiplied by 8 decimals in client
    /// @param _chapterURI the encrypted link for the tale chapter
    function dropNewChapter(
        string memory _chapterName,
        string memory _chapterDescription,
        string memory _chapterImageCover,
        uint256 _costInUsd,
        string memory _chapterURI,
        address _priceFeedAddress
    ) public {
        if (msg.sender != authorAddress) {
            revert("!author");
        }
        chapterCount++;
        ChapterContract chapterContract = new ChapterContract(
            _chapterName,
            _chapterDescription,
            chapterCount,
            _costInUsd,
            address(this),
            _chapterURI,
            authorAddress,
            _priceFeedAddress
        );

        chapters.push(address(chapterContract));

        emit ChapterCreated(
            _chapterURI,
            _chapterName,
            chapterCount,
            _chapterImageCover,
            block.timestamp,
            address(chapterContract),
            address(this)
        );
    }

    /// @notice increments the total minters accross all the chapters of the tale
    /// @dev only callable by the chapters(contracts) of the tale
    function incrementTotalMintersAcrossChapters() public {
        for (
            uint chapterAddress = 0;
            chapterAddress < chapters.length;
            chapterAddress++
        ) {
            if (chapters[chapterAddress] == msg.sender) {
                totalMintersAcrossChapters++;
            } else {
                revert("TYT#3");
            }
        }
    }

    /// @notice allows the user to rate the tale
    /// @dev sets the updated rating for the tale
    /// @param _rating a rating number from 1 to 10 left for the user to choose
    function rateTale(uint8 _rating) public {
        require(_rating < 10, "TYT#4");
        raters++;
        ratingsList.push(_rating);
        currentRating = getCurrentRating();
    }

    ///@notice allows a user subscribe to a tale
    function subscribe() public {
        require(!_subscribed[msg.sender], "already subscribed");
        subscriberCount++;
        _subscribed[msg.sender] = true;
    }

    /// @notice gets the current rating for the tale
    /// @dev calculates the ratings by all the users to get the current rating
    function getCurrentRating() public view returns (uint256) {
        uint8[] memory _ratingsList = ratingsList;
        uint256 totalCount;
        for (
            uint individualRating = 0;
            individualRating < _ratingsList.length;
            individualRating++
        ) {
            totalCount += _ratingsList[individualRating];
        }
        return totalCount / raters;
    }

    ///@notice gets all teh chapter contract addresses for a tale
    function getChapter() public view returns (address[] memory) {
        return chapters;
    }

    ///@notice gets the total num of subscribers
    function getSubscribers() public view returns (uint256) {
        return subscriberCount;
    }

    ///@notice chedcks if teh useris subscribed
    /// @param user the address of teh user
    function getSubscribers(address user) public view returns (bool) {
        return _subscribed[user];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {AggregatorV3Interface} from "AggregatorV3Interface.sol";
import {TaleContract} from "TaleContract.sol";

contract ChapterContract {
    /// @notice the name of the chapter
    string public name;
    /// @notice the encrypted chapter URI
    string public chapterURI;
    ///@notice the description of the chapter
    string public description;
    /// @notice the chapter number for the contract
    uint256 public chapter;
    /// @notice the total minters for this chapter
    uint256 public minters;
    /// @notice the cost in USD required for the chapter
    uint256 public costInUSD;
    /// @notice the core tale contract address
    address public taleContract;
    /// @notice the author address
    address public authorAddress;

    /// @notice chainlink price feed
    AggregatorV3Interface public priceFeed;

    // keeping track of users who have minted
    mapping(address => bool) public _minted;
    // keeping track of the authors balance
    mapping(address => uint256) public _authorBalance;

    constructor(
        string memory _name,
        string memory _description,
        uint256 _chapter,
        uint256 _costInUSD,
        address _taleContract,
        string memory _chapterURI,
        address _authorAddress,
        address _priceFeedAddress
    ) {
        name = _name;
        chapter = _chapter;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        costInUSD = _costInUSD;
        taleContract = _taleContract;
        chapterURI = _chapterURI;
        authorAddress = _authorAddress;
        description = _description;
    }

    /// @notice mints the chapter for the user
    /// @dev gives the user the access to decrypt the chapter of the tale
    function mintChapter() public payable {
        require(msg.value >= costInNativeAsset(), "Not enough asset");
        require(!_minted[msg.sender], "already minted");
        minters++;
        _minted[msg.sender] = true;
        uint256 amountGivenToAuthor = (90 * msg.value) / 100;
        // uint256 amountForBiconomy = (10 * msg.value) / 100; WIP
        _authorBalance[authorAddress] += amountGivenToAuthor;
        TaleContract(taleContract).incrementTotalMintersAcrossChapters();
    }

    /// @notice Allow the author to withdraw a certain amount of funds locked in his chapter
    /// @param amount The amount the author wishes to withdraw
    function withdrawFunds(uint256 amount) public {
        require(msg.sender == authorAddress, "!author");
        require(_authorBalance[msg.sender] >= amount, "insufficent");

        (bool ok, ) = authorAddress.call{value: amount}("");
        require(ok, "!ok");
    }

    /// @notice core function for the lit protocol nodes to use to decrypt
    /// @dev only allows users who have minted in the past to decrypt
    /// @param _user teh address of the user trying to decrypt
    function isAllowedToViewChapter(address _user) public view returns (bool) {
        bool minted = _minted[_user];
        return minted;
    }

    ///@notice checks if the user has minted
    ///@param _user the address of the user
    function hasMinted(address _user) public view returns (bool) {
        return _minted[_user];
    }

    /// @notice gets the price of the asset using chainlinks price feed
    /// @return returns the price of the asset
    function getPrice() public view returns (uint256) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    /// @notice returns the amount in native asset needed to satisfy teh usd required amount
    function costInNativeAsset() public view returns (uint256) {
        return (costInUSD * 10**18) / getPrice();
    }

    /// @notice returns the name of the chapter
    function getName() public view returns (string memory) {
        return name;
    }

    /// @notice returns the encrypted chapter URI
    function getChapterUri() public view returns (string memory) {
        return chapterURI;
    }

    /// @notice returns the chapter number
    function getChapterNumber() public view returns (uint256) {
        return chapter;
    }

    /// @notice returns the chapter total minters
    function getTotalMinters() public view returns (uint256) {
        return minters;
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