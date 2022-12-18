/**
 *Submitted for verification at polygonscan.com on 2022-12-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ThreeGram {
    /// @notice Events
    /// @dev Indexing only 3 vars to fufill EVM storage capacity constraints
    event CreateUser(
        address indexed _wallet,
        string indexed _username,
        string _name,
        string indexed _bio,
        string _avatar
    );
    event CreatePost(
        address indexed _author,
        string indexed _title,
        string indexed _media
    );

    /// @notice State to track whether the contract is paused
    bool public paused;

    /// @notice The owner of the contract
    address public owner;

    /// @notice User properties
    struct User {
        address wallet;
        string name;
        string username;
        string bio;
        string avatar;
    }

    /// @notice Post properties
    struct Post {
        string title;
        string author;
        string media;
        uint256 likes;
        uint256 timestamp;
    }

    Post[] public posts;

    /// @dev Mappings to keep track of addresses to usernames to Users.
    mapping(address => string) public usernames;
    mapping(string => User) public users;

    /// @notice modifiers
    modifier newUser(string memory _username) {
        require(bytes(usernames[msg.sender]).length == 0, "Already a user!");
        require(users[_username].wallet == address(0), "Address taken!");
        _;
    }

    modifier onlyUser() {
        require(bytes(usernames[msg.sender]).length > 0, "Must be a user!");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner!");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice creates a new user if they don't exist
     */
    function createUser(
        string memory _username,
        string memory _name,
        string memory _bio,
        string memory _avatar
    ) public newUser(_username) {
        users[_username] = User({
            wallet: msg.sender,
            name: _name,
            username: _username,
            bio: _bio,
            avatar: _avatar
        });
        usernames[msg.sender] = _username;

        emit CreateUser(msg.sender, _username, _name, _bio, _avatar);
    }

    /**
     * @notice creates a new post if a user has signed up
     */
    function createPost(string memory _title, string memory _media)
        public
        onlyUser
    {
        require(bytes(_title).length > 0, "Post can't be empty!");
        require(bytes(_media).length > 0, "Media can't be empty!");

        string memory _username = usernames[msg.sender];
        Post memory _post = Post({
            title: _title,
            author: _username,
            media: _media,
            likes: 0,
            timestamp: block.timestamp
        });
        posts.push(_post);

        emit CreatePost(msg.sender, _title, _media);
    }

    /**
     * @notice Retrieves a wallet's username if it exists
     */
    function getUsername(address _wallet) public view returns (string memory) {
        return bytes(usernames[_wallet]).length > 0 ? usernames[_wallet] : "";
    }

    /**
     * @notice Returns an array of posts
     */
    function getPosts() public view returns (Post[] memory) {
        return posts;
    }

    /**
     * @dev Pauses this contract to prevent minting and burning
     */
    function pause(bool _pause) external onlyOwner {
        paused = _pause;
    }

    /**
     * @dev Sets a new  owner of the contract
     */
    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}