// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.9;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Dbanta {
    using SafeMath for uint256;
    address public owner; //Owner is also a maintainer
    bool public stopped = false;
    uint256 public bantCount = 0;

    struct User {
        uint256 id;
        address ethAddress;
        string username;
        string name;
        string profileImgHash;
        string profileCoverImgHash;
        string bio;
        accountStatus status; // Account Banned or Not
    }

    struct Bant {
        uint256 bantId;
        address payable author;
        string hashtag;
        string content;
        string imgHash;
        uint256 timestamp;
        uint256 likeCount;
        uint256 reportCount;
        uint256 tipVote;
        cdStatus status; // Bant Active-Deleted-Banned
    }

    struct Comment {
        uint256 commentId;
        address payable author;
        uint256 bantId;
        string content;
        uint256 likeCount;
        uint256 timestamp;
        cdStatus status;
    }

    uint256 public totalBants = 0;
    uint256 public totalComments = 0;
    uint256 public totalUsers = 0;

    enum accountStatus {
        Active,
        inActive,
        Deactivated
    }

    enum cdStatus {
        Active,
        inActive,
        Deleted
    }

    //Comment-Bant status
    // enum BantStatus{NP,Active, Banned, Deleted}

    mapping(address => User) private users; //mapping to get user details from user address
    mapping(string => address) private userAddressFromUsername; //to get user address from username
    // mapping(address=>bool) private registeredUser; //mapping to get user details from user address
    mapping(string => bool) private usernames; //To check which username is taken taken=>true, not taken=>false

    mapping(uint256 => Bant) private Bants; // mapping to get bant from Id
    mapping(address => uint256[]) private userBants; // Array to store bants(Id) done by user
    // mapping(uint=>address[]) private bantLikersList;
    mapping(uint256 => mapping(address => bool)) private bantLikers; // Mapping to track who liked which bant

    mapping(uint256 => Comment) private comments; //Mapping to get comment from comment Id
    mapping(address => uint256[]) private userComments; // Mapping to track user comments from there address
    // mapping(uint=>mapping(address=>bool)) private commentReporters; // Mapping to track who reported which comment
    // mapping(uint=>mapping(address=>bool)) private commentLikers; // Mapping to track who liked on which comment
    mapping(uint256 => uint256[]) private bantComments; // Getting comments for a specific bant

    modifier stopInEmergency() {
        require(!stopped, 'Dapp has been stopped!');
        _;
    }
    modifier onlyInEmergency() {
        require(stopped);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'You are not owner!');
        _;
    }
    modifier onlyBantAuthor(uint256 id) {
        require(msg.sender == Bants[id].author, 'You are not Author!');
        _;
    }
    modifier onlyCommentAuthor(uint256 id) {
        require(msg.sender == comments[id].author, 'You are not Author!');
        _;
    }
    modifier onlyAllowedUser(address user) {
        require(
            users[user].status == accountStatus.Active,
            'Not a Registered User!'
        );
        _;
    }
    modifier onlyActiveBant(uint256 id) {
        require(Bants[id].status == cdStatus.Active, 'Not a active Bant');
        _;
    }
    modifier onlyActiveComment(uint256 id) {
        require(comments[id].status == cdStatus.Active, 'Not a active comment');
        _;
    }
    modifier usernameTaken(string memory username) {
        require(!usernames[username], 'Username already taken');
        _;
    }
    // modifier checkUserExists(){require(registeredUser[msg.sender]); _;}
    modifier checkUserNotExists(address user) {
        require(
            users[user].status == accountStatus.Active,
            'User already registered'
        );
        _;
    }

    event logRegisterUser(address user, uint256 id);
    event logUserBanned(address user, uint256 id);
    event logBantCreated(
        address payable author,
        uint256 userid,
        uint256 bantid,
        string hashtag,
        uint256 tipVote
    );
    event logBantDeleted(uint256 id, string hashtag);
    event bantVoted(
        address payable author,
        uint256 userid,
        uint256 bantid,
        uint256 tipVote
    );

    constructor() {
        owner = msg.sender;
        registerUser('owner', 'owner', '', '', 'owner');
    }

    fallback() external {
        revert();
    }

    //User Details
    function usernameAvailable(string memory _username)
        public
        view
        returns (bool status)
    {
        return !usernames[_username];
    }

    /// @notice Register a new user
    /// @param  _username username of username
    /// @param _name name of person
    /// @param _imgHash Ipfs Hash of users Profile Image
    /// @param _coverHash Ipfs Hash of user cover Image
    /// @param _bio Biography of user

    function registerUser(
        string memory _username,
        string memory _name,
        string memory _imgHash,
        string memory _coverHash,
        string memory _bio
    )
        public
        stopInEmergency
        checkUserNotExists(msg.sender)
        usernameTaken(_username)
    {
        usernames[_username] = true;
        totalUsers = totalUsers.add(1);
        uint256 id = totalUsers;
        users[msg.sender] = User(
            id,
            msg.sender,
            _username,
            _name,
            _imgHash,
            _coverHash,
            _bio,
            accountStatus.Active
        );
        userAddressFromUsername[_username] = msg.sender;
        emit logRegisterUser(msg.sender, totalUsers);
    }

    /// @notice Check accountStatus of user-Registered, Banned or Deleted
    /// @return status NP, Active, Banned or Deleted
    function userStatus(address _useraddr) public view returns (accountStatus status) {
        return users[_useraddr].status;
    }

    /// @notice Change username of a user
    /// @param _username New username of user
    function changeUsername(string memory _username)
        public
        stopInEmergency
        onlyAllowedUser(msg.sender)
        usernameTaken(_username)
    {
        users[msg.sender].username = _username;
    }

    function getTotalUserBants() public view returns(uint256){

        return(userBants [msg.sender].length);
    }

    /// @notice Get user details
    /// @param _user address of user
    /// @return id Id of user
    /// @return username username of person
    /// @return name Name of user
    /// @return imghash user profile image ipfs hash
    /// @return coverhash usercCover image ipfs hash
    /// @return bio Biography of user
    function getUser(address _user)
        public
        view
        returns (
            uint256 id,
            string memory username,
            string memory name,
            string memory imghash,
            string memory coverhash,
            string memory bio
        )
    {
        return (
            users[_user].id,
            users[_user].username,
            users[_user].name,
            users[_user].profileImgHash,
            users[_user].profileCoverImgHash,
            users[_user].bio
        );
    }

    function createBant(
        string memory _hashtag,
        string memory _content,
        string memory _imghash
    ) public stopInEmergency onlyAllowedUser(msg.sender) {
        totalBants = totalBants.add(1);
        uint256 id = totalBants;
        require(bytes(_content).length > 0);
        bantCount++;
        Bants[id] = Bant(
            id,
            payable(msg.sender),
            _hashtag,
            _content,
            _imghash,
            block.timestamp,
            0,
            0,
            0,
            cdStatus.Active
        );
        userBants[msg.sender].push(totalBants);
        emit logBantCreated(
            payable(msg.sender),
            users[msg.sender].id,
            totalBants,
            _hashtag,
            0
        );
    }

    function tipPost(uint256 _id) public payable {
        // Make sure the id is valid
        require(_id > 0 && _id <= bantCount);
        // Fetch the post
        Bant memory _bant = Bants[_id];
        User memory _user = users[msg.sender];
        // Fetch the author
        address payable _author = _bant.author;
        // Pay the author by sending them tokens
        payable(_author).transfer(msg.value);
        // Incremet the tip amount
        _bant.tipVote = _bant.tipVote + msg.value;
        // Update the post
        Bants[_id] = _bant;
        // Trigger an event
        //address payable author, uint256 userid, uint256 bantid, uint tipVote
        emit bantVoted(_author, _bant.bantId, _user.id, _bant.tipVote);
    }

    /// @notice Edit a bant
    /// @param  _id Id of bant
    /// @param  _hashtag New tag of bant
    /// @param  _content New content of bant
    /// @param  _imghash Hash of new image content
    function editBant(
        uint256 _id,
        string memory _hashtag,
        string memory _content,
        string memory _imghash
    )
        public
        stopInEmergency
        onlyActiveBant(_id)
        onlyAllowedUser(msg.sender)
        onlyBantAuthor(_id)
    {
        Bants[_id].hashtag = _hashtag;
        Bants[_id].content = _content;
        Bants[_id].imgHash = _imghash;
    }

    /// @notice Delete a bant
    /// @param  _id Id of bant
    function deleteBant(uint256 _id)
        public
        onlyActiveBant(_id)
        onlyAllowedUser(msg.sender)
        stopInEmergency
        onlyBantAuthor(_id)
    {
        emit logBantDeleted(_id, Bants[_id].hashtag);
        delete Bants[_id];
        Bants[_id].status = cdStatus.Deleted;
        for (uint256 i = 0; i < bantComments[_id].length; i++) {
            delete bantComments[_id][i];
        }
        delete bantComments[_id];
    }

    /// @notice Get a Bant
    /// @param  _id Id of bant
    /// @return author Bant author address
    /// @return  hashtag Tag of bant
    /// @return  content Content of bant
    /// @return  imgHash Hash of image content
    /// @return  timestamp Bant creation timestamp
    /// @return  likeCount No of likes on bant
    function getBant(uint256 _id)
        public
        view
        onlyAllowedUser(msg.sender)
        onlyActiveBant(_id)
        returns (
            address author,
            string memory hashtag,
            string memory content,
            string memory imgHash,
            uint256 timestamp,
            uint256 likeCount
        )
    {
        return (
            Bants[_id].author,
            Bants[_id].hashtag,
            Bants[_id].content,
            Bants[_id].imgHash,
            Bants[_id].timestamp,
            Bants[_id].likeCount
        );
    }

    /// @notice Like a bants
    /// @param _id Id of bant to be likeBant
    function likeBant(uint256 _id)
        public
        onlyAllowedUser(msg.sender)
        onlyActiveBant(_id)
    {
        require(!bantLikers[_id][msg.sender]);
        Bants[_id].likeCount = Bants[_id].likeCount.add(1);
        bantLikers[_id][msg.sender] = true;
    }

    /// @notice Get list of bants done by a user
    /// @return bantList Array of bant ids
    function getUserBants()
        public
        view
        onlyAllowedUser(msg.sender)
        returns (uint256[] memory bantList)
    {
        return userBants[msg.sender];
    }

    /// @notice Get list of bants done by a user
    /// @param _user User address
    /// @return bantList Array of dweet ids
    function getUserBants(address _user)
        public
        view
        onlyAllowedUser(msg.sender)
        returns (uint256[] memory bantList)
    {
        return userBants[_user];
    }

    /// @notice Create a comment on bant
    /// @param  _bantid Id of bantList
    /// @param  _comment content of comment
    function createComment(uint256 _bantid, string memory _comment)
        public
        stopInEmergency
        onlyAllowedUser(msg.sender)
        onlyActiveBant(_bantid)
    {
        totalComments = totalComments.add(1);
        uint256 id = totalComments;
        comments[id] = Comment(
            id,
            payable(msg.sender),
            _bantid,
            _comment,
            0,
            block.timestamp,
            cdStatus.Active
        );
        userComments[msg.sender].push(totalComments);
        bantComments[_bantid].push(totalComments);
    }

    function editComment(uint256 _commentid, string memory _comment)
        public
        stopInEmergency
        onlyAllowedUser(msg.sender)
        onlyActiveComment(_commentid)
        onlyCommentAuthor(_commentid)
    {
        comments[_commentid].content = _comment;
    }

    /// @notice Delete a comment
    /// @param _id Id of comment to be Deleted
    function deleteComment(uint256 _id)
        public
        stopInEmergency
        onlyActiveComment(_id)
        onlyAllowedUser(msg.sender)
        onlyCommentAuthor(_id)
    {
        delete comments[_id];
        comments[_id].status = cdStatus.Deleted;
    }

    /// @notice Get a comment
    /// @param  _id Id of comment
    /// @return author Address of author
    /// @return bantId Id of bant
    /// @return content content of comment
    /// @return likeCount Likes on commment
    /// @return timestamp Comment creation timestamp
    /// @return status status of Comment active-banned-deleted
    function getComment(uint256 _id)
        public
        view
        onlyAllowedUser(msg.sender)
        onlyActiveComment(_id)
        returns (
            address author,
            uint256 bantId,
            string memory content,
            uint256 likeCount,
            uint256 timestamp,
            cdStatus status
        )
    {
        return (
            comments[_id].author,
            comments[_id].bantId,
            comments[_id].content,
            comments[_id].likeCount,
            comments[_id].timestamp,
            comments[_id].status
        );
    }

    /// @notice Get comments done by user
    /// @return commentList Array of comment ids
    /// @dev Though onlyAllowedUser can be bypassed easily but still keeping for calls from frontend
    function getUserComments()
        public
        view
        onlyAllowedUser(msg.sender)
        returns (uint256[] memory commentList)
    {
        return userComments[msg.sender];
    }

    /// @notice Get comments done by user
    /// @param _user address of user
    /// @return commentList Array of comment ids
    function getUserComments(address _user)
        public
        view
        onlyAllowedUser(msg.sender)
        returns (uint256[] memory commentList)
    {
        return userComments[_user];
    }

    /// @notice Get comments on a dweet
    /// @return list Array of comment ids
    function getBantComments(uint256 _id)
        public
        view
        onlyAllowedUser(msg.sender)
        onlyActiveBant(_id)
        returns (uint256[] memory list)
    {
        return (bantComments[_id]);
    }

    /*
     ****************************************Owner Admin ******************************************************************************************
     */
    /// @notice Get balance of contract
    /// @return balance balance of contract
    function getBalance() public view onlyOwner returns (uint256 balance) {
        return address(this).balance;
    }

    /// @notice Withdraw contract funds to owner
    /// @param _amount Amount to be withdrawn
    function transferContractBalance(uint256 _amount) public onlyOwner {
        require(
            _amount <= address(this).balance,
            'Withdraw amount greater than balance'
        );
        payable(msg.sender).transfer(_amount);
    }

    function stopDapp() public onlyOwner {
        require(!stopped, 'Already stopped');
        stopped = true;
    }

    function startDapp() public onlyOwner {
        require(stopped, 'Already started');
        stopped = false;
    }

    function changeOwner(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}