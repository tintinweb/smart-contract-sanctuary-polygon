//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

// Defining errors
error AlreadyJoined();
error NotJoined();
error InvalidData();
error NotAuthorised();
error AddressZero();
error AlreadyBlocked();
error AlreadyUnblocked();
error AlreadySet();
error PostDoesNotExist();
error CommentDoesNotExist();
error ReplyDoesNotExist();
error AlreadySubscribed();
error AlreadyUnSubscribed();
error AlreadyLiked();
error AlreadyUnLiked();

contract Mirror is Ownable {
    // State variable
    uint256 public videoId = 0;
    uint256 public userId = 0;

    mapping(uint256 => Video) public videos;
    mapping(address => User) public users;
    mapping(address => bool) public isJoined;
    mapping(address => bool) public isModerator;
    mapping(address => bool) public isVerified;
    mapping(address => bool) public isDeleted;
    mapping(address => bool) public isBanned;

    SubscriptionRanks subscriptionRanksInfo = SubscriptionRanks(1000, 10000, 100000, 1000000);

    struct User {
        uint256 userId;
        address userAddress;
        string username;
        string imageHash;
        string bannerHash;
        string aboutHash;
        uint256 joinedAt;
        uint256 updatedAt;
        uint256[] videos;
        address[] subscribers;
        address[] subscriptions;
        mapping(address => bool) isSubscribed;
        uint256[] liked;
        mapping(uint256 => bool) isLiked;
    }

    struct Video {
        uint256 videoId;
        string videoHash;
        string title;
        string descriptionHash;
        string thumbnailHash;
        uint256 uploadedAt;
        uint256 updatedAt;
        address author;
        uint256 likes;
        Comment[] comments;
        uint256 reports;
        bool isBlocked;
        bool isDeleted;
    }

    struct Comment {
        uint256 id;
        address author;
        string content;
        uint timestamp;
        bool deleted;
        Reply[] replies;
    }

    struct Reply {
        uint256 id;
        address author;
        string content;
        uint timestamp;
        bool deleted;
    }

    struct SubscriptionRanks {
        uint256 WhiteLabel;
        uint256 SilverLabel;
        uint256 GoldLabel;
        uint256 PlatinumLabel;
    }

    enum SubscriptionLabel {
        NoLabel,
        WhiteLabel,
        SilverLabel,
        GoldLabel,
        PlatinumLabel
    }

    event UserJoined(address indexed userAddress);

    event UserUpdated(
        address indexed userAddress,
        string username,
        string imageHash,
        string bannerHash,
        string aboutHash
    );

    event UserDeleted(address indexed userAddress);

    event VideoUploaded(
        uint256 indexed videoId,
        address indexed author,
        string title,
        string descriptionHash,
        string thumbnailHash
    );

    event VideoUpdated(
        uint256 indexed videoId,
        address indexed author,
        string title,
        string descriptionHash,
        string thumbnailHash
    );

    event VideoDeleted(uint256 indexed videoId, address indexed author);

    event Liked(uint256 indexed videoId, address indexed user);
    event UnLiked(uint256 indexed videoId, address indexed user);

    event Subscribed(address indexed subscriber, address indexed subscribedTo);

    event UnSubscribed(address indexed subscriber, address indexed subscribedTo);

    event CommentAdded(
        uint256 indexed videoId,
        uint256 indexed commentId,
        address indexed user,
        string content
    );
    event CommentDeleted(uint256 indexed videoId, uint256 indexed commentId, address indexed user);

    event ReplyAdded(
        uint256 indexed videoId,
        uint256 indexed commentId,
        uint256 indexed replyId,
        address user,
        string content
    );
    event ReplyDeleted(
        uint256 indexed videoId,
        uint256 indexed commentId,
        uint256 indexed replyId,
        address user
    );

    event IsModeratorSet(address indexed userAddress, bool indexed value);
    event IsVerifiedSet(address indexed userAddress, bool indexed value);
    event IsBlockedSet(uint256 indexed videoId, bool indexed value);
    event IsBannedSet(address indexed userAddress, bool indexed value);
    event SubscriptionRanksSet(
        uint256 whiteLabel,
        uint256 silverLabel,
        uint256 goldLabel,
        uint256 platinumLabel
    );

    event Reported(uint256 videoId, address reporter);

    constructor() {
        // subscriptionRanksInfo = SubscriptionRanks(1000, 10000, 100000, 1000000);
    }

    /**
     * @dev Throws if the message sender is not a moderator.
     */
    modifier onlyModerator() {
        if (!isModerator[msg.sender]) {
            revert NotAuthorised();
        }
        _;
    }

    /**
     * @dev Throws if the message sender is not a joined user.
     * @param _address The address of the user.
     */
    modifier onlyJoined(address _address) {
        if (!isJoined[msg.sender]) {
            revert NotJoined();
        }
        _;
    }

    /**
     * @dev Throws if the message sender is banned.
     * @param _address The address of the user.
     */
    modifier onlyNotBanned(address _address) {
        if (isBanned[msg.sender]) {
            revert NotAuthorised();
        }
        _;
    }

    /**
     * @dev Throws if the video post does not exist.
     * @param _videoId The ID of the video.
     */
    modifier onlyExistingPost(uint256 _videoId) {
        if (_videoId >= videoId || videos[_videoId].isDeleted) {
            revert PostDoesNotExist();
        }
        _;
    }

    /**
     * @dev Throws if the comment does not exist.
     * @param _videoId The ID of the video.
     * @param _commentId The ID of the comment.
     */
    modifier onlyExistingComment(uint256 _videoId, uint256 _commentId) {
        if (
            _commentId >= videos[_videoId].comments.length ||
            videos[_videoId].comments[_commentId].deleted
        ) {
            revert CommentDoesNotExist();
        }
        _;
    }

    /**
     * @dev Allows a user to join the platform and become a member.
     * Emits a `UserJoined` event upon success.
     * Requirements:
     * - The caller must not be banned.
     * - The caller must not have already joined.
     */
    function join() external onlyNotBanned(msg.sender) {
        if (isJoined[msg.sender]) {
            revert AlreadyJoined();
        }
        users[msg.sender].userId = userId;
        users[msg.sender].userAddress = msg.sender;
        users[msg.sender].joinedAt = block.timestamp;
        isJoined[msg.sender] = true;
        userId++;

        emit UserJoined(msg.sender);
    }

    /**
     * @dev Allows a user to update their profile with a new username, image hash, banner hash, and about hash.
     * Emits a `UserUpdated` event upon success.
     * Requirements:
     * - The caller must have already joined.
     * - The provided data must not be empty.
     * @param _username The new username of the user.
     * @param _imageHash The new IPFS hash of the user's profile image.
     * @param _bannerHash The new IPFS hash of the user's banner image.
     * @param _aboutHash The new IPFS hash of the user's about section.
     */
    function updateProfile(
        string calldata _username,
        string calldata _imageHash,
        string calldata _bannerHash,
        string calldata _aboutHash
    ) external onlyJoined(msg.sender) {
        if (
            bytes(_username).length == 0 ||
            bytes(_imageHash).length == 0 ||
            bytes(_bannerHash).length == 0 ||
            bytes(_aboutHash).length == 0
        ) {
            revert InvalidData();
        }

        users[msg.sender].username = _username;
        users[msg.sender].imageHash = _imageHash;
        users[msg.sender].bannerHash = _bannerHash;
        users[msg.sender].aboutHash = _aboutHash;
        users[msg.sender].updatedAt = block.timestamp;

        emit UserUpdated(msg.sender, _username, _imageHash, _bannerHash, _aboutHash);
    }

    /**
     * @dev Allows a user to delete their account and become deleted.
     * Emits a `UserDeleted` event upon success.
     * Requirements:
     * - The caller must have already joined.
     */
    function deleteUser() external onlyJoined(msg.sender) {
        isDeleted[msg.sender] = true;
        isJoined[msg.sender] = false;
        emit UserDeleted(msg.sender);
    }

    /**
     * @dev Uploads a video
     * @param _videoHash The IPFS hash of the video
     * @param _title The title of the video
     * @param _descriptionHash The description of the video
     * @param _thumbnailHash The thumbnail of the video
     */
    function uploadVideo(
        string calldata _videoHash,
        string calldata _title,
        string calldata _descriptionHash,
        string calldata _thumbnailHash
    ) external onlyJoined(msg.sender) onlyNotBanned(msg.sender) {
        // Validating
        if (
            bytes(_videoHash).length == 0 ||
            bytes(_title).length == 0 ||
            bytes(_descriptionHash).length == 0 ||
            bytes(_thumbnailHash).length == 0
        ) {
            revert InvalidData();
        }

        uint256 _videoId = videoId;
        videoId++;

        videos[_videoId].videoId = _videoId;
        videos[_videoId].videoHash = _videoHash;
        videos[_videoId].title = _title;
        videos[_videoId].descriptionHash = _descriptionHash;
        videos[_videoId].thumbnailHash = _thumbnailHash;
        videos[_videoId].uploadedAt = block.timestamp;
        videos[_videoId].author = msg.sender;

        users[msg.sender].videos.push(_videoId);
        emit VideoUploaded(_videoId, msg.sender, _title, _descriptionHash, _thumbnailHash);
    }

    /**
     * @dev Updates a video
     * @param _videoId The ID of the video to update
     * @param _title The title of the video to update
     * @param _descriptionHash The description of the video to update
     * @param _thumbnailHash The thumbnail of the video to update
     */
    function updateVideo(
        uint256 _videoId,
        string calldata _title,
        string calldata _descriptionHash,
        string calldata _thumbnailHash
    ) external onlyJoined(msg.sender) {
        // Validating
        if (
            bytes(_title).length == 0 ||
            bytes(_thumbnailHash).length == 0 ||
            bytes(_descriptionHash).length == 0
        ) {
            revert InvalidData();
        }
        if (videos[_videoId].author != msg.sender) {
            revert NotAuthorised();
        }

        videos[_videoId].title = _title;
        videos[_videoId].descriptionHash = _descriptionHash;
        videos[_videoId].thumbnailHash = _thumbnailHash;
        videos[_videoId].updatedAt = block.timestamp;

        emit VideoUpdated(_videoId, msg.sender, _title, _descriptionHash, _thumbnailHash);
    }

    /**
     * @dev Deletes a video
     * @param _videoId The ID of the video to unlike
     */
    function deleteVideo(uint _videoId) external onlyExistingPost(_videoId) {
        if (videos[_videoId].author != msg.sender) {
            revert NotAuthorised();
        }
        videos[_videoId].isDeleted = true;
        emit VideoDeleted(_videoId, msg.sender);
    }

    /**
     * @dev Like a video
     * @param _videoId The ID of the video to like
     */
    function likeVideo(
        uint256 _videoId
    ) external onlyJoined(msg.sender) onlyExistingPost(_videoId) {
        if (users[msg.sender].isLiked[_videoId]) {
            revert AlreadyLiked();
        }
        videos[_videoId].likes++;
        users[msg.sender].isLiked[_videoId] = true;
        users[msg.sender].liked.push(_videoId);
        emit Liked(_videoId, msg.sender);
    }

    /**
     * @dev Unlike a video
     * @param _videoId The ID of the video to unlike
     */
    function unlikeVideo(
        uint256 _videoId
    ) external onlyJoined(msg.sender) onlyExistingPost(_videoId) {
        if (!users[msg.sender].isLiked[_videoId]) {
            revert AlreadyUnLiked();
        }

        users[msg.sender].isLiked[_videoId] = false;
        videos[_videoId].likes -= 1;

        uint256[] memory _liked = users[msg.sender].liked;
        for (uint i = 0; i < _liked.length; i++) {
            if (_liked[i] == _videoId) {
                users[msg.sender].liked[i] = users[msg.sender].liked[_liked.length - 1];
                users[msg.sender].liked.pop();
                break;
            }
        }

        emit UnLiked(_videoId, msg.sender);
    }

    /**
     * @dev Allows a user to subscribe to a channel.
     * @param _subTo The address of the channel being subscribed to.
     */
    function subscribe(address _subTo) external onlyJoined(msg.sender) onlyJoined(_subTo) {
        if (users[msg.sender].isSubscribed[_subTo]) {
            revert AlreadySubscribed();
        }
        users[msg.sender].isSubscribed[_subTo] = true;
        users[msg.sender].subscriptions.push(_subTo);
        users[_subTo].subscribers.push(msg.sender);
        emit Subscribed(msg.sender, _subTo);
    }

    /**
     * @dev Allows a user to unsubscribe from a channel.
     * @param _unsubTo The address of the channel being unsubscribed from.
     */
    function unsubscribe(address _unsubTo) external onlyJoined(msg.sender) onlyJoined(_unsubTo) {
        if (!users[msg.sender].isSubscribed[_unsubTo]) {
            revert AlreadyUnSubscribed();
        }
        users[msg.sender].isSubscribed[_unsubTo] = false;
        address[] memory _subscriptions = users[msg.sender].subscriptions;
        for (uint i = 0; i < _subscriptions.length; i++) {
            if (_subscriptions[i] == _unsubTo) {
                users[msg.sender].subscriptions[i] = users[msg.sender].subscriptions[
                    _subscriptions.length - 1
                ];
                users[msg.sender].subscriptions.pop();
                break;
            }
        }

        address[] memory _subscribers = users[_unsubTo].subscribers;
        for (uint i = 0; i < _subscribers.length; i++) {
            if (_subscribers[i] == msg.sender) {
                users[_unsubTo].subscribers[i] = users[_unsubTo].subscribers[
                    _subscribers.length - 1
                ];
                users[_unsubTo].subscribers.pop();
                break;
            }
        }

        emit UnSubscribed(msg.sender, _unsubTo);
    }

    /**
     * @dev Adds a comment to a video.
     * @param _videoId The ID of the video being commented on.
     * @param _content The content of the comment.
     */
    function addComment(
        uint _videoId,
        string calldata _content
    ) external onlyJoined(msg.sender) onlyNotBanned(msg.sender) onlyExistingPost(_videoId) {
        if (bytes(_content).length == 0) {
            revert InvalidData();
        }

        uint256 _commentId = videos[_videoId].comments.length;

        Comment storage _comment = videos[_videoId].comments.push();

        _comment.id = _commentId;
        _comment.author = msg.sender;
        _comment.content = _content;
        _comment.timestamp = block.timestamp;

        emit CommentAdded(_videoId, _commentId, msg.sender, _content);
    }

    /**
     * @dev Deletes a comment from a video.
     * @param _videoId The ID of the video the comment is on.
     * @param _commentId The ID of the comment being deleted.
     */
    function deleteComment(
        uint _videoId,
        uint _commentId
    )
        external
        onlyJoined(msg.sender)
        onlyExistingPost(_videoId)
        onlyExistingComment(_videoId, _commentId)
    {
        Comment storage comment = videos[_videoId].comments[_commentId];

        if (comment.author != msg.sender && videos[_videoId].author != msg.sender) {
            revert NotAuthorised();
        }
        comment.deleted = true;
        emit CommentDeleted(_videoId, _commentId, msg.sender);
    }

    /**
     * @dev Adds a reply to a comment on a video.
     * @param _videoId The ID of the video the comment is on.
     * @param _commentId The ID of the comment being replied to.
     * @param _content The content of the reply.
     */
    function addReply(
        uint _videoId,
        uint _commentId,
        string calldata _content
    )
        external
        onlyJoined(msg.sender)
        onlyNotBanned(msg.sender)
        onlyExistingPost(_videoId)
        onlyExistingComment(_videoId, _commentId)
    {
        if (bytes(_content).length == 0) {
            revert InvalidData();
        }

        uint256 _replyId = videos[_videoId].comments[_commentId].replies.length;

        Reply storage _reply = videos[_videoId].comments[_commentId].replies.push();

        _reply.id = _replyId;
        _reply.author = msg.sender;
        _reply.content = _content;
        _reply.timestamp = block.timestamp;

        emit ReplyAdded(_videoId, _commentId, _replyId, msg.sender, _content);
    }

    /**
     * @dev Deletes a reply to a comment on a video.
     * @param _videoId The ID of the video the comment is on.
     * @param _commentId The ID of the comment the reply is on.
     * @param _replyId The ID of the reply being deleted.
     */
    function deleteReply(
        uint _videoId,
        uint _commentId,
        uint _replyId
    )
        external
        onlyJoined(msg.sender)
        onlyExistingPost(_videoId)
        onlyExistingComment(_videoId, _commentId)
    {
        if (_replyId >= videos[_videoId].comments[_commentId].replies.length) {
            revert ReplyDoesNotExist();
        }

        Reply storage reply = videos[_videoId].comments[_commentId].replies[_replyId];

        if (reply.author != msg.sender && videos[_videoId].author != msg.sender) {
            revert NotAuthorised();
        }

        reply.deleted = true;

        emit ReplyDeleted(_videoId, _commentId, _replyId, msg.sender);
    }

    /**
     * @dev Sets the moderator status of a user.
     * @param _address The address of the user being modified.
     * @param _value The new value of the moderator status.
     */
    function setIsModerator(address _address, bool _value) external onlyOwner onlyJoined(_address) {
        if (_address == address(0)) {
            revert AddressZero();
        }

        if (isModerator[_address] == _value) {
            revert AlreadySet();
        }

        isModerator[_address] = _value;

        emit IsModeratorSet(_address, _value);
    }

    /**
     * @notice Sets the verification status of a user
     * @param _address The address of the user to set the verification status for
     * @param _value The verification status to set for the user
     */
    function setIsVerified(
        address _address,
        bool _value
    ) external onlyModerator onlyJoined(_address) {
        if (isVerified[_address] == _value) {
            revert AlreadySet();
        }
        isVerified[_address] = _value;

        emit IsVerifiedSet(_address, _value);
    }

    /**
     * @notice Sets the banned status of a user
     * @param _address The address of the user to set the banned status for
     * @param _value The banned status to set for the user
     */
    function setIsBanned(
        address _address,
        bool _value
    ) external onlyModerator onlyJoined(_address) {
        if (isBanned[_address] == _value) {
            revert AlreadySet();
        }
        isBanned[_address] = _value;

        emit IsBannedSet(_address, _value);
    }

    /**
     * @notice Sets the blocked status of a video
     * @param _videoId The ID of the video to set the blocked status for
     * @param _value The blocked status to set for the video
     */
    function setIsBlocked(uint256 _videoId, bool _value) external onlyModerator {
        if (videos[_videoId].isBlocked == _value) {
            revert AlreadySet();
        }
        videos[_videoId].isBlocked = _value;

        if (!_value) {
            videos[_videoId].reports = 0;
        }

        emit IsBlockedSet(_videoId, _value);
    }

    /**
     * @notice Sets the subscription ranks for the platform
     * @param _whiteLabel The number of subscribers required for the White Label rank
     * @param _silverLabel The number of subscribers required for the Silver Label rank
     * @param _goldLabel The number of subscribers required for the Gold Label rank
     * @param _platinumLabel The number of subscribers required for the Platinum Label rank
     */
    function setSubscriptionRanks(
        uint256 _whiteLabel,
        uint256 _silverLabel,
        uint256 _goldLabel,
        uint256 _platinumLabel
    ) external onlyOwner {
        subscriptionRanksInfo = SubscriptionRanks(
            _whiteLabel,
            _silverLabel,
            _goldLabel,
            _platinumLabel
        );

        emit SubscriptionRanksSet(_whiteLabel, _silverLabel, _goldLabel, _platinumLabel);
    }

    /**
     * @notice Gets the subscription rank of a user
     * @param _userAddress The address of the user to get the subscription rank for
     * @return The subscription label of the user
     */
    function getSubscriptionRank(
        address _userAddress
    ) external view onlyJoined(_userAddress) returns (SubscriptionLabel) {
        uint256 _subscribers = users[_userAddress].subscribers.length;

        SubscriptionRanks memory _subscriptionRanksInfo = subscriptionRanksInfo;

        if (_subscribers >= _subscriptionRanksInfo.PlatinumLabel) {
            return SubscriptionLabel.PlatinumLabel;
        } else if (_subscribers >= _subscriptionRanksInfo.GoldLabel) {
            return SubscriptionLabel.GoldLabel;
        } else if (_subscribers >= _subscriptionRanksInfo.SilverLabel) {
            return SubscriptionLabel.SilverLabel;
        } else if (_subscribers >= _subscriptionRanksInfo.WhiteLabel) {
            return SubscriptionLabel.WhiteLabel;
        } else {
            return SubscriptionLabel.NoLabel;
        }
    }

    /**
     * @notice Reports a video for inappropriate content
     * @param _videoId The ID of the video to report
     */
    function reportVideo(
        uint256 _videoId
    ) external onlyJoined(msg.sender) onlyNotBanned(msg.sender) onlyExistingPost(_videoId) {
        videos[_videoId].reports += 1;

        emit Reported(_videoId, msg.sender);
    }

    /**
     * @notice Gets the number of videos a user has uploaded
     * @param _userAddress The address of the user to get the number of videos for
     * @return The number of videos the user has uploaded
     */
    function getVideosLength(address _userAddress) external view returns (uint256) {
        return users[_userAddress].videos.length;
    }

    /**
     * @notice Gets a range of videos uploaded by a user
     * @param _userAddress The address of the user to get the videos for
     * @param _startIndex The index of the first video to get
     * @param _endIndex The index of the last video to get
     * @return An array of video IDs
     */
    function getVideos(
        address _userAddress,
        uint256 _startIndex,
        uint256 _endIndex
    ) external view returns (uint256[] memory) {
        uint256[] storage _videos = users[_userAddress].videos;

        if (_startIndex == 0 && _endIndex == 0) {
            return _videos;
        }

        if (_endIndex <= _startIndex || _endIndex > _videos.length) {
            revert InvalidData();
        }

        uint256[] memory result = new uint[](_endIndex - _startIndex);

        for (uint i = _startIndex; i < _endIndex; i++) {
            result[i - _startIndex] = _videos[i];
        }

        return result;
    }

    /**
     * @notice Gets the number of subscribers a user has
     * @param _userAddress The address of the user to get the number of subscribers for
     * @return The number of subscribers the user has
     */
    function getSubscribersLength(address _userAddress) external view returns (uint256) {
        return users[_userAddress].subscribers.length;
    }

    /**
     * @notice Gets a range of subscribers for a user
     * @param _userAddress The address of the user to get the subscribers for
     * @param _startIndex The index of the first subscriber to get
     * @param _endIndex The index of the last subscriber to get
     * @return An array of subscriber addresses
     */
    function getSubscribers(
        address _userAddress,
        uint256 _startIndex,
        uint256 _endIndex
    ) external view returns (address[] memory) {
        address[] storage subscribers = users[_userAddress].subscribers;

        if (_startIndex == 0 && _endIndex == 0) {
            return subscribers;
        }

        if (_endIndex <= _startIndex || _endIndex > subscribers.length) {
            revert InvalidData();
        }

        address[] memory result = new address[](_endIndex - _startIndex);

        for (uint i = _startIndex; i < _endIndex; i++) {
            result[i - _startIndex] = subscribers[i];
        }

        return result;
    }

    /**
     * @notice Gets the number of subscriptions a user has
     * @param _userAddress The address of the user to get the number of subscriptions for
     * @return The number of subscriptions the user has
     */
    function getSubscriptionsLength(address _userAddress) external view returns (uint256) {
        return users[_userAddress].subscriptions.length;
    }

    /**
     * @notice Gets a range of subscriptions for a user
     * @param _userAddress The address of the user to get the subscriptions for
     * @param _startIndex The index of the first subscriptions to get
     * @param _endIndex The index of the last subscriptions to get
     * @return An array of subscriptions addresses
     */
    function getSubscriptions(
        address _userAddress,
        uint256 _startIndex,
        uint256 _endIndex
    ) external view returns (address[] memory) {
        address[] storage subscriptions = users[_userAddress].subscriptions;

        if (_startIndex == 0 && _endIndex == 0) {
            return subscriptions;
        }

        if (_endIndex <= _startIndex || _endIndex > subscriptions.length) {
            revert InvalidData();
        }

        address[] memory result = new address[](_endIndex - _startIndex);

        for (uint i = _startIndex; i < _endIndex; i++) {
            result[i - _startIndex] = subscriptions[i];
        }

        return result;
    }

    /**
     * @dev Returns whether the given user address is subscribed to the given subscription address.
     * @param _userAddress The address of the user to check.
     * @param _subTo The address of the subscription to check for.
     * @return A boolean indicating whether the user is subscribed to the given subscription.
     */
    function isSubscribed(address _userAddress, address _subTo) external view returns (bool) {
        return users[_userAddress].isSubscribed[_subTo];
    }

    /**
     * @dev Returns the length of the liked videos array of a user
     * @param _userAddress The user's address
     * @return The length of the user's liked videos array
     */
    function getLikedLength(address _userAddress) external view returns (uint256) {
        return users[_userAddress].liked.length;
    }

    /**
     * @dev Returns an array of the video IDs that a user has liked
     * @param _userAddress The user's address
     * @param _startIndex The start index of the range of liked videos to retrieve
     * @param _endIndex The end index of the range of liked videos to retrieve
     * @return An array of the video IDs that the user has liked
     */
    function getLiked(
        address _userAddress,
        uint256 _startIndex,
        uint256 _endIndex
    ) external view returns (uint256[] memory) {
        uint256[] storage liked = users[_userAddress].liked;

        if (_startIndex == 0 && _endIndex == 0) {
            return liked;
        }

        if (_endIndex <= _startIndex || _endIndex > liked.length) {
            revert InvalidData();
        }

        uint256[] memory result = new uint[](_endIndex - _startIndex);

        for (uint i = _startIndex; i < _endIndex; i++) {
            result[i - _startIndex] = liked[i];
        }

        return result;
    }

    /**
     * @dev Returns whether the given user address has liked the given video ID.
     * @param _userAddress The address of the user to check.
     * @param _videoId The ID of the video to check for a like.
     * @return A boolean indicating whether the user has liked the given video.
     */
    function isLiked(address _userAddress, uint256 _videoId) external view returns (bool) {
        return users[_userAddress].isLiked[_videoId];
    }

    /**
     * @dev Returns the length of the 'comments' array for the given video ID.
     * @param _videoId The ID of the video whose 'comments' array length to return.
     * @return The length of the 'comments' array.
     */
    function getCommentsLength(uint256 _videoId) external view returns (uint256) {
        return videos[_videoId].comments.length;
    }

    /**
     * @dev Returns an array of comments for a given video ID within a specified range of indices.
     * @param _videoId The ID of the video to retrieve comments for.
     * @param _startIndex The starting index of the comments array to return.
     * @param _endIndex The ending index of the comments array to return.
     * @return An array of comments for the specified video ID within the given range of indices.
     * @notice If _startIndex and _endIndex are both zero, returns the entire comments array for the specified video ID.
     * @notice Throws an error if the _endIndex is less than or equal to _startIndex, or if the _endIndex is greater than the length of the comments array.
     */
    function getComments(
        uint256 _videoId,
        uint256 _startIndex,
        uint256 _endIndex
    ) external view onlyExistingPost(_videoId) returns (Comment[] memory) {
        Comment[] storage comments = videos[_videoId].comments;

        if (_startIndex == 0 && _endIndex == 0) {
            return comments;
        }

        if (_endIndex <= _startIndex || _endIndex > comments.length) {
            revert InvalidData();
        }

        Comment[] memory result = new Comment[](_endIndex - _startIndex);

        for (uint i = _startIndex; i < _endIndex; i++) {
            result[i - _startIndex] = comments[i];
        }

        return result;
    }

    /**
     * @dev Returns the number of replies for a given comment ID within a given video ID.
     * @param _videoId The ID of the video containing the comment to retrieve replies for.
     * @param _commentId The ID of the comment to retrieve replies for.
     * @return The number of replies for the specified comment ID within the given video ID.
     */
    function getRepliesLength(
        uint256 _videoId,
        uint256 _commentId
    ) external view returns (uint256) {
        return videos[_videoId].comments[_commentId].replies.length;
    }

    /**
     * @dev Retrieves a range of replies to a comment on a video.
     * @param _videoId The ID of the video containing the comment.
     * @param _commentId The ID of the comment to retrieve replies for.
     * @param _startIndex The index of the first reply to retrieve.
     * @param _endIndex The index of the last reply to retrieve.
     * @return An array of Reply objects representing the requested replies.
     */
    function getReplies(
        uint256 _videoId,
        uint256 _commentId,
        uint256 _startIndex,
        uint256 _endIndex
    )
        external
        view
        onlyExistingPost(_videoId)
        onlyExistingComment(_videoId, _commentId)
        returns (Reply[] memory)
    {
        Reply[] storage replies = videos[_videoId].comments[_commentId].replies;

        if (_startIndex == 0 && _endIndex == 0) {
            return replies;
        }

        if (_endIndex <= _startIndex || _endIndex > replies.length) {
            revert InvalidData();
        }

        Reply[] memory result = new Reply[](_endIndex - _startIndex);

        for (uint i = _startIndex; i < _endIndex; i++) {
            result[i - _startIndex] = replies[i];
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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