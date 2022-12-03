// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {ChronicleContract} from "ChronicleContract.sol";

contract ChroniclesCore {
    ///@notice the creator to their details
    mapping(address => CreatorDetails) public _creatorDetails;
    ///@notice gets the creator name from their address
    mapping(address => string) public _creatorFromAddress;
    ///@notice the chronicle address to its details
    mapping(address => ChronicleDetails) public _chronicleDetails;
    ///@notice is a creator
    mapping(address => bool) public _isCreator;
    ///@notice the chapter number for each chapter
    mapping(address => uint256) public _chroniclesChapterCount;
    ///@notice keeps track of the chronicles raters
    mapping(address => uint256) public _chronicleRaters;
    ///@notice keeps track of who has liked a chronicle in the past
    mapping(address => mapping(address => bool)) public _likedChronicle;
    ///@notice keeps track of subscribers
    mapping(address => mapping(address => bool)) public _subscribed;
    ///@notice keep track of who has rated a chronicle
    mapping(address => mapping(address => bool)) public _hasRatedChronicle;
    ///@notice keeps track of creator raters
    mapping(address => uint256) public _creatorRaters;
    ///@notice keeps track of who has rated a creator in the past
    mapping(address => mapping(address => bool)) public _hasRatedCreator;
    ///@notice keeeps track of who has liked a creator
    mapping(address => mapping(address => bool)) public _likedCreator;
    ///@notice the admin of the contract
    address public deployer;
    ///@notice the max rating for a chronicle
    uint8 public constant MAX_RATING = 5;

    ///@notice the details of a creator
    struct CreatorDetails {
        string handle;
        address creatorAddress;
        uint256 chroniclesProduced;
        uint256 rating;
        uint256 earnings;
        uint256 totalLikes;
        uint256 totalSubscribers;
        string profileImageURI;
        string socialURITwitter;
        string socialURILens;
    }

    ///@notice the details of a chronicle
    struct ChronicleDetails {
        string name;
        string creator;
        address creatorAddress;
        string chronicleImageURI;
        string description;
        uint256 subscribers;
        uint256 originalReleaseDate;
        uint8 genre;
        uint8 kind; //novel or comic
        uint256 rating;
        uint256 likes;
    }

    ///@notice the detail of the chapter
    struct ChapterDetail {
        string name;
        string chapterImageURI;
        uint256 chapterNumber;
        uint256 releaseDate;
        uint256 likes;
    }

    // when a new chronicle is uploaded
    event ChronicleUploaded(
        string name,
        string creator,
        string chronicleImageURI,
        string description,
        address chronicleAddress,
        uint256 originalReleaseDate,
        uint8 genre,
        uint8 kind
    );

    // when a new chronicle drops a chapter
    event ChapterDropped(
        string name,
        string chapterImageURI,
        uint256 chapterNumber,
        uint256 releaseDate,
        address chroniclesContract
    );

    // when an admin recommends a chronicle
    event RecommendedChronicle(
        string name,
        string creator,
        string chronicleImageURI,
        string description,
        uint256 originalReleaseDate,
        uint8 genre,
        uint8 kind
    );

    // when an admin pushes a new and trending chronicle
    event NewAndTrendingChronicle(
        string name,
        string creator,
        string chronicleImageURI,
        string description,
        uint256 originalReleaseDate,
        uint8 genre,
        uint8 kind
    );

    //when a user registers as a creator
    event CreatorRegistered(
        string handle,
        string imageURI,
        address creatorAddress
    );

    // when an user adds a chroncile to their favorites
    event AddedToFavorites(address user, address chronicleContract);

    constructor() {
        deployer = msg.sender;
    }

    // CREATOR SPECIFICS

    ///@notice allows any user to register as a creator
    ///@param _handle the handle the creator wishes to use
    ///@param _profileImageURI the profile image uri for the creator
    ///@param _socialURITwitter the Link to the creators twitter page
    ///@param _socialURILens the link to the creators lens profile
    function registerAsCreator(
        string memory _handle,
        string memory _profileImageURI,
        string memory _socialURITwitter,
        string memory _socialURILens
    ) public {
        _creatorDetails[msg.sender] = CreatorDetails({
            handle: _handle,
            creatorAddress: msg.sender,
            chroniclesProduced: 0,
            rating: 0,
            earnings: 0,
            totalLikes: 0,
            totalSubscribers: 0,
            profileImageURI: _profileImageURI,
            socialURITwitter: _socialURITwitter,
            socialURILens: _socialURILens
        });
        _isCreator[msg.sender] = true;
        _creatorFromAddress[msg.sender] = _handle;

        emit CreatorRegistered(_handle, _profileImageURI, msg.sender);
    }

    ///@notice allows users to tip a creator for a job well done
    ///@param _creator the creator address that the user wishes to tip
    function tipCreator(address _creator) public payable {
        require(_isCreator[_creator], "! a creator");
        _creatorDetails[_creator].earnings += msg.value;
    }

    ///@notice allows users to like a creator
    ///@param _creatorAddress the creator addres
    function likeCreator(address _creatorAddress) public {
        bool liked = _likedCreator[msg.sender][_creatorAddress];
        require(!liked, "already liked creator");
        _likedCreator[msg.sender][_creatorAddress] = true;
        _creatorDetails[_creatorAddress].totalLikes++;
    }

    ///@notice allows users to rate a creator
    ///@param _rating the rating the viewer wishes to give the creator
    ///@param _creatorAddress the creator address
    function rateCreator(uint256 _rating, address _creatorAddress) public {
        _creatorRaters[_creatorAddress]++;
        uint256 currentRaters = _creatorRaters[_creatorAddress];
        bool _hasRated = _hasRatedCreator[msg.sender][_creatorAddress];

        require(_rating <= MAX_RATING, "Above max rating");
        require(!_hasRated, "Already rated this chronicle");

        uint256 prevRating = _creatorDetails[_creatorAddress].rating;
        _creatorDetails[_creatorAddress].rating =
            (prevRating + _rating) /
            currentRaters;

        _hasRatedCreator[msg.sender][_creatorAddress] = true;
    }

    ///@notice allows a creator to withdraw his funds
    ///@param _amount the amount requested to be withdrawn by creator
    function withdrawFundsAsCreator(uint256 _amount) public {
        uint256 balance = _creatorDetails[msg.sender].earnings;

        require(_amount <= balance, "amount req. > balance");

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "!successful");
    }

    // CHRONICLE SPECIFICS

    ///@notice create a chronicle that could be one shot or chapter based
    ///@dev creates a chronicle contract that handles all the logic for the chronicles
    ///@param _name the name of the chronicle
    ///@param _chronicleImageURI the background image URI for the chronicle
    ///@param _description the description for the chronicle
    ///@param _genre the genre type
    ///@param _kind the kind of chronicle i.e book or comic
    function uploadChronicle(
        string memory _name,
        string memory _chronicleImageURI,
        string memory _description,
        uint8 _genre,
        uint8 _kind
    ) public {
        require(_isCreator[msg.sender], "! a creator");

        ChronicleContract chronicleContract = new ChronicleContract(
            address(this)
        );

        _chronicleDetails[address(chronicleContract)] = ChronicleDetails({
            name: _name,
            creator: _creatorFromAddress[msg.sender],
            creatorAddress: msg.sender,
            chronicleImageURI: _chronicleImageURI,
            description: _description,
            subscribers: 0,
            originalReleaseDate: block.timestamp,
            genre: _genre,
            kind: _kind,
            rating: 0,
            likes: 0
        });

        emit ChronicleUploaded(
            _name,
            _creatorFromAddress[msg.sender],
            _chronicleImageURI,
            _description,
            address(chronicleContract),
            block.timestamp,
            _genre,
            _kind
        );
    }

    ///@notice allows creators to drop a chapter for their chronicle
    ///@param _name the name of the chapter
    ///@param _chapterImageURI the chapter image URI
    ///@param _chronicleContract the chapter chronicle contract
    ///@param _paidOption the option for a chapter to be paid or free
    ///@param _amount the amount to be paid if not free
    function dropChapter(
        string memory _name,
        string memory _chapterImageURI,
        string memory _encryptedChapterURI,
        address _chronicleContract,
        bool _paidOption,
        uint256 _amount
    ) public {
        address chronicleOwner = getChronicleDetails(_chronicleContract)
            .creatorAddress;
        require(msg.sender == chronicleOwner, "!owner of chronicle");

        _chroniclesChapterCount[_chronicleContract]++;
        ChronicleContract chronicleContract = ChronicleContract(
            _chronicleContract
        );

        chronicleContract.dropChapter(
            _name,
            _chapterImageURI,
            _encryptedChapterURI,
            _chroniclesChapterCount[_chronicleContract],
            _paidOption,
            _amount
        );

        emit ChapterDropped(
            _name,
            _chapterImageURI,
            _chroniclesChapterCount[_chronicleContract],
            block.timestamp,
            _chronicleContract
        );
    }

    ///@notice allows a viewer/user to pay for a chapter they're interested in
    ///@param _chronicleContract the contract address of teh chronicle
    ///@param _chapterNumber the chapter number of the chronicle
    function payForChapter(
        address _chronicleContract,
        uint256 _chapterNumber
    ) public payable {
        ChronicleContract chronicleContract = ChronicleContract(
            _chronicleContract
        );
        chronicleContract.payForChapter(_chapterNumber, msg.value);
        address _creator = _chronicleDetails[_chronicleContract].creatorAddress;
        _creatorDetails[_creator].earnings += msg.value;
    }

    ///@notice allows users to rate a chronicle
    ///@param _rating the rating the viewer wishes to give the chronicle
    ///@param _chronicleContract the chronicle contract address
    function rateChronicle(uint256 _rating, address _chronicleContract) public {
        _chronicleRaters[_chronicleContract]++;
        uint256 currentRaters = _chronicleRaters[_chronicleContract];
        bool _hasRated = _hasRatedChronicle[msg.sender][_chronicleContract];

        require(_rating <= MAX_RATING, "Above max rating");
        require(!_hasRated, "Already rated this chronicle");

        uint256 prevRating = _chronicleDetails[_chronicleContract].rating;
        _chronicleDetails[_chronicleContract].rating =
            (prevRating + _rating) /
            currentRaters;

        _hasRatedChronicle[msg.sender][_chronicleContract] = true;
    }

    ///@notice allows a viewer to like a chronicle
    ///@param _chronicleContract the contract address of the chronicle address
    function likeChronicle(address _chronicleContract) public {
        bool liked = _likedChronicle[msg.sender][_chronicleContract];
        require(!liked, "already liked chronicle");
        _likedChronicle[msg.sender][_chronicleContract] = true;
        _chronicleDetails[_chronicleContract].likes++;
    }

    ///@notice allows a viewer to subscrive to a chronicle
    ///@param _chronicleContract the contract address of the chronicle address
    function subscribeToChronicle(address _chronicleContract) public {
        bool subscribed = _subscribed[msg.sender][_chronicleContract];
        require(!subscribed, "already subscribed");

        _subscribed[msg.sender][_chronicleContract] = true;
        _chronicleDetails[_chronicleContract].subscribers++;
    }

    ///@notice allows a viewer to add a chroncile to their favorites
    ///@param _chronicleContract the contract address of the chronicle address
    function addToFavorites(address _chronicleContract) public {
        emit AddedToFavorites(msg.sender, _chronicleContract);
    }

    // HOME PAGE RECOMMENDATIONS

    ///@notice admin pushes hidden gems to be recommended (will eventually be governance)
    ///@param _chronicleContract the contract address of the chronicle address
    function pushRecommendation(address _chronicleContract) public onlyAdmin {
        ChronicleDetails memory chronicleDetails = _chronicleDetails[
            _chronicleContract
        ];

        emit RecommendedChronicle(
            chronicleDetails.name,
            chronicleDetails.creator,
            chronicleDetails.chronicleImageURI,
            chronicleDetails.description,
            chronicleDetails.originalReleaseDate,
            chronicleDetails.genre,
            chronicleDetails.kind
        );
    }

    ///@notice admin pushes a chroncicle thats new and trending
    ///@param _chronicleContract the contract address of the chronicle address
    function pushNewAndTrending(address _chronicleContract) public onlyAdmin {
        ChronicleDetails memory chronicleDetails = _chronicleDetails[
            _chronicleContract
        ];

        emit NewAndTrendingChronicle(
            chronicleDetails.name,
            chronicleDetails.creator,
            chronicleDetails.chronicleImageURI,
            chronicleDetails.description,
            chronicleDetails.originalReleaseDate,
            chronicleDetails.genre,
            chronicleDetails.kind
        );
    }

    // VIEW FUNCTIONS

    ///@notice checks if the addres is a creator
    function getIsCreator(address _userAddress) public view returns (bool) {
        return _isCreator[_userAddress];
    }

    ///@notice gets the creator name from their address
    function getCreator(address _creator) public view returns (string memory) {
        return _creatorFromAddress[_creator];
    }

    ///@notice gets the creator details from their address
    function getCreatorDetails(
        address _creator
    ) public view returns (CreatorDetails memory) {
        return _creatorDetails[_creator];
    }

    ///@notice gets the chronicle details from its contract address
    function getChronicleDetails(
        address _chronicleAddress
    ) public view returns (ChronicleDetails memory) {
        return _chronicleDetails[_chronicleAddress];
    }

    ///@notice get current chapter count for a chronicle
    function getChronicleChapterCount(
        address _chroniclesChapter
    ) public view returns (uint256) {
        return _chroniclesChapterCount[_chroniclesChapter];
    }

    // get current raters for a chronicle

    modifier onlyAdmin() {
        require(msg.sender == deployer, "!admin");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract ChronicleContract {
    ///@notice the address of the chroniclesCore contract
    address public chroniclesCoreAddress;
    ///@notice the chapter number to details
    mapping(uint256 => ChapterDetail) public _chapterDetails;
    ///@notice chapter number to address to paid
    mapping(uint256 => mapping(address => bool)) public _paid;
    ///@notice keeps track of if a user has liked a chapter
    mapping(address => mapping(uint256 => bool)) public _likedChapter;
    ///@notice chronicles cut
    uint256 public chroniclesCut = 20; // 20%
    ///@notice determines if all chapters should be free or paid
    bool public paidOptiion;

    ///@notice the detail of the chapter
    struct ChapterDetail {
        string name;
        string chapterImageURI;
        string encryptedChapterURI;
        uint256 chapterNumber;
        uint256 releaseDate;
        uint256 amount;
    }

    constructor(address _chroniclesCore) {
        chroniclesCoreAddress = _chroniclesCore;
    }

    ///@notice allows a creator to drop a chapter for a chronicle
    ///@dev only callable by the ChroniclesCore contract
    ///@param _name  the name of the chapter
    ///@param _chapterImageURI  the chapter image URI
    ///@param _chapterNumber the chapter Number
    ///@param _paidOption the option for a chapter to be paid or free
    ///@param _amount the amount to be paid if not free
    function dropChapter(
        string memory _name,
        string memory _chapterImageURI,
        string memory _encryptedChapterURI,
        uint256 _chapterNumber,
        bool _paidOption,
        uint256 _amount
    ) public onlyChroniclesCore {
        _chapterDetails[_chapterNumber] = ChapterDetail({
            name: _name,
            chapterImageURI: _chapterImageURI,
            encryptedChapterURI: _encryptedChapterURI,
            chapterNumber: _chapterNumber,
            releaseDate: block.timestamp,
            amount: _amount
        });

        paidOptiion = _paidOption;
    }

    ///@notice allows viewers/audience to pay for a chapter
    ///@param _chapterNumber the chapter number
    ///@param _amountPaid the msg.value
    function payForChapter(
        uint256 _chapterNumber,
        uint256 _amountPaid
    ) public onlyChroniclesCore {
        uint256 amount = (_chapterDetails[_chapterNumber].amount *
            (100 - chroniclesCut)) / 100;

        require(_amountPaid >= amount, "insufficient amount");

        _paid[_chapterNumber][msg.sender] = true;
    }

    ///@notice checks if a viewer is elligible to view a chapter from the chronicle
    ///@dev the entry point function used by LIT protocol to give access to users
    ///@param _viewer the viewer address
    ///@param _chapterNumber the chapter Number
    function viewChapter(
        address _viewer,
        uint256 _chapterNumber
    ) public view returns (bool) {
        if (!paidOptiion) {
            return true;
        } else if (paidOptiion && _paid[_chapterNumber][_viewer]) {
            return true;
        } else {
            return false;
        }
    }

    ///@notice get the chapter details
    function getChapterDetails(
        uint256 _chapterNumber
    ) public view returns (ChapterDetail memory) {
        return _chapterDetails[_chapterNumber];
    }

    ///@notice requires only the chronicle core contract to be the sender
    modifier onlyChroniclesCore() {
        require(msg.sender == chroniclesCoreAddress, "!chronicles core");
        _;
    }
}