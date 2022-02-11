pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract YourContract {
    event LogTweet(string, address, uint256);

    struct tweet {
        string message;
        address owner;
        uint256 numberOfLikes;
        mapping(address => bool) isLiker;
        mapping(uint256 => address) idToLikerAddress;
    }
    struct user {
        string name;
        uint256 numberOfTweets;
        uint256 numberOfFollowers;
        uint256[] tweetsList;
        mapping(address => bool) isFollower;
        mapping(uint256 => address) idToFollowerAddress;
    }
    mapping(address => user) public addressToUser;
    mapping(uint256 => tweet) public tweetsList;
    uint256 public numberOfTweets;

    /** 
     * @dev Function to tweet, called by user only
     * @param _message tweet message
     */
    function Tweet(string calldata _message) external {
        tweet storage t = tweetsList[numberOfTweets];
        t.message = _message;
        t.owner = msg.sender;
        user storage u = addressToUser[msg.sender];
        u.numberOfTweets += 1;
        u.tweetsList.push(numberOfTweets);
        numberOfTweets += 1;
        emit LogTweet(_message, msg.sender, numberOfTweets-1);
    }
    /** 
     * @dev set user profile name, called by user only
     * @param _name user profile name
     */
    function CreateUserName(string memory _name) public {
        addressToUser[msg.sender].name = _name;
    }

    /** 
     * @dev follow another user, called by user only
     * @param _dest follow user address
     */
    function FollowUser(address _dest) external {
        user storage u = addressToUser[_dest];
        require(u.isFollower[msg.sender] == false, "Already Following");
        u.isFollower[msg.sender] = true;
        u.idToFollowerAddress[u.numberOfFollowers] = msg.sender;
        u.numberOfFollowers += 1;
    }
    /** 
     * @dev like tweet, called by user only
     * @param _index tweet index
     */
    function LikeTweet(uint256 _index) external {
        tweet storage t = tweetsList[_index];
        require(t.isLiker[msg.sender] == false, "Already Liked");
        t.isLiker[msg.sender] = true;
        t.idToLikerAddress[t.numberOfLikes] = msg.sender;
        t.numberOfLikes += 1;
    }
    /** 
     * @dev get followers for a user, anyone can call
     * @param _addr user address
     */
    function getFollowersList(address _addr) external view returns(address[] memory) {
        user storage u = addressToUser[_addr];
        uint256 len = u.numberOfFollowers;
        address[] memory a = new address[](len);
        for(uint256 i=0; i < len; i++) {
            a[i] = u.idToFollowerAddress[i];
        }
        return a;
    }
    /** 
     * @dev get followers count for a user, anyone can call
     * @param _addr user address
     */
    function getFollowersCount(address _addr) external view returns(uint256) {
        return addressToUser[_addr].numberOfFollowers;
    }
    /** 
     * @dev get likers address list for a tweet, anyone can call
     * @param _index tweet index
     */
    function getLikersAddressList(uint256 _index) external view returns(address[] memory) {
        require(_index < numberOfTweets, "invalid Tweet id");
        tweet storage t = tweetsList[_index];
        uint256 len = t.numberOfLikes;
        address[] memory a = new address[](len);
        for(uint256 i=0; i < len; i++) {
            a[i] = t.idToLikerAddress[i];
        }
        return a;
    }
    /** 
     * @dev get likes count for a tweet, anyone can call
     * @param _index tweet index
     */
    function getLikesCount(uint256 _index) external view returns(uint256) {
        require(_index < numberOfTweets, "invalid Tweet id");
        return tweetsList[_index].numberOfLikes;
    }
    /** 
     * @dev get number of tweets for a user, anyone can call
     * @param _addr address of user
     */
    function getNumberOfTweetsbyUser(address _addr) external view returns(uint256) {
        return addressToUser[_addr].numberOfTweets;
    }
}