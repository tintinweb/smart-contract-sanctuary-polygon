// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@opengsn/contracts/src/ERC2771Recipient.sol";
contract Polling is ERC2771Recipient {
    address payable public author;
    uint8 maxPollOptionCount;

    struct PollOption {
        string content;
        uint256 voteCount;
    }

    struct Poll {
        address creator;
        string title;
        uint256 startTimeStamp;
        uint256 endTimeStamp;
        uint256 totalVotesCasted;
        uint8 pollOptionCount;
        mapping(uint8 => PollOption)  pollOptions;
        mapping(address => uint8)  votes;
    }

    struct User {
        string name;
        bool created;
        uint256 pollCount;
        mapping(uint256 => bytes32) ids;
    }

    mapping(address => User) public  users;
    address[] userAddresses;

    mapping(bytes32 => Poll) public polls;
    mapping(bytes32 => address) public pollIdToUser;
    bytes32[] pollIds;

    event UserCreated(string name, address identifier);
    event PollIsLive(string name, address identifier, bytes32 pollId);
    event PollResult(
        address identifier,
        bytes32 pollId,
        uint8 winningOptionIndex,
        uint256 winningOptionVoteCount,
        uint256 totalVotesCasted
    );

    constructor(address _trustedForwarder) public{
        _setTrustedForwarder(_trustedForwarder);
        author = msg.sender;
        maxPollOptionCount = 2;
    }

    modifier onlyAuthor() {
        require(author == msg.sender, "You're not author !");
        _;
    }

    modifier isValidMaxPollOptionCount(uint8 count) {
        require(
            count >= 2 && count <= 16,
            "Max poll option count out of range !"
        );
        _;
    }

    function setTrustForwarder(address _trustedForwarder) public onlyAuthor {
        _setTrustedForwarder(_trustedForwarder);
    }

    /**
     * Override this function.
     * This version is to keep track of BaseRelayRecipient you are using
     * in your contract.
     */
  

    function setMaxPollOptionCount(uint8 count)
        external
        onlyAuthor
        isValidMaxPollOptionCount(count)
    {
        maxPollOptionCount = count;
    }

    // returns maximum poll option count, allowed to be set as of now
    function getMaxPollOptionCount() public view returns (uint8) {
        return maxPollOptionCount;
    }

    modifier canCreateAccount() {
        require(!users[msg.sender].created, "User already exists !");
        _;
    }

    function createUser(string memory _name) public canCreateAccount {
        User memory user;

        user.name = _name;
        user.created = true;

        users[msg.sender] = user;
        userAddresses.push(msg.sender);

        emit UserCreated(_name, msg.sender);
    }

    modifier canCreatePoll() {
        require(users[msg.sender].created, "User account doesn't exist !");
        _;
    }

    function createPoll(string memory _title)
        public
        canCreatePoll
        returns (bytes32)
    {
        bytes32 pollId = keccak256(
            abi.encodePacked(_title, msg.sender, users[msg.sender].pollCount)
        );
        Poll memory poll;

        poll.creator = msg.sender;
        poll.title = _title;

        users[msg.sender].ids[users[msg.sender].pollCount] = pollId;
        users[msg.sender].pollCount++;

        polls[pollId] = poll;
        pollIdToUser[pollId] = msg.sender;
        pollIds.push(pollId);

        return pollId;
    }

    modifier didYouCreatePoll(bytes32 _pollId) {
        require(pollIdToUser[_pollId] == msg.sender, "You're not allowed !");
        _;
    }

    modifier canAddPollOption(bytes32 _pollId) {
        require(
            polls[_pollId].pollOptionCount < maxPollOptionCount,
            "Reached max poll option count !"
        );
        _;
    }

    function addPollOption(bytes32 _pollId, string memory _pollOption)
        public
        didYouCreatePoll(_pollId)
        isPollAlreadyLive(_pollId)
        canAddPollOption(_pollId)
    {
        PollOption memory pollOption;

        pollOption.content = _pollOption;

        Poll storage poll = polls[_pollId];
        poll.pollOptions[poll.pollOptionCount] = pollOption;
        poll.pollOptionCount++;
    }

    modifier isPollAlreadyLive(bytes32 _pollId) {
        require(
            polls[_pollId].startTimeStamp == 0 &&
                polls[_pollId].endTimeStamp == 0,
            "Poll already live !"
        );
        _;
    }

    modifier areEnoughPollOptionsSet(bytes32 _pollId) {
        require(
            polls[_pollId].pollOptionCount >= 2,
            "Atleast 2 options required !"
        );
        _;
    }

    modifier isPollEndTimeValid(bytes32 _pollId, uint8 _hours) {
        require(
            _hours > 0 && _hours <= 72,
            "Poll can be live for >= 1 hour && <= 72 hours"
        );
        _;
    }

    function makePollLive(bytes32 _pollId, uint8 _activeForHours)
        public
        didYouCreatePoll(_pollId)
        isPollAlreadyLive(_pollId)
        areEnoughPollOptionsSet(_pollId)
        isPollEndTimeValid(_pollId, _activeForHours)
    {
        polls[_pollId].startTimeStamp = now;
        polls[_pollId].endTimeStamp = now + (_activeForHours * 1 hours);

        emit PollIsLive(users[msg.sender].name, msg.sender, _pollId);
    }

    modifier checkPollExistance(bytes32 _pollId) {
        require(pollIdToUser[_pollId] != address(0), "Poll doesn't exist !");
        _;
    }

    modifier isPollLive(bytes32 _pollId) {
        require(
            polls[_pollId].startTimeStamp <= now &&
                polls[_pollId].endTimeStamp > now,
            "Poll not live !"
        );
        _;
    }

    modifier checkDuplicateVote(bytes32 _pollId) {
        require(
            polls[_pollId].votes[msg.sender] == 0,
            "Attempt to cast duplicate vote !"
        );
        _;
    }

    modifier isValidOptionToCastVote(bytes32 _pollId, uint8 _option) {
        require(
            _option >= 0 && _option < polls[_pollId].pollOptionCount,
            "Invalid option, can't cast vote !"
        );
        _;
    }

    function castVote(bytes32 _pollId, uint8 _option)
        public
        checkPollExistance(_pollId)
        isPollLive(_pollId)
        checkDuplicateVote(_pollId)
        isValidOptionToCastVote(_pollId, _option)
    {
        Poll storage poll = polls[_pollId];
        poll.totalVotesCasted++;
        poll.pollOptions[_option].voteCount++;
        poll.votes[msg.sender] = _option + 1;
    }

    // Added check for poll activation
    function isPollActive(bytes32 _pollId) public view returns (bool) {
        return
            polls[_pollId].startTimeStamp <= now &&
            polls[_pollId].endTimeStamp > now;
    }

    // Given number of recent active polls required, returns a list of them
    function getRecentXActivePolls(uint8 x)
        public
        view
        returns (bytes32[] memory)
    {
        require(x > 0, "Can't return 0 recent polls !");

        bytes32[] memory recentPolls = new bytes32[](x);
        uint8 idx = 0;

        for (uint256 i = pollIds.length - 1; i >= 0 && idx < x; i--) {
            if (isPollActive(pollIds[i])) {
                recentPolls[idx] = pollIds[i];
                idx++;
            }
        }

        return recentPolls;
    }

    // Checks whether given address has account or not ( in this platform )
    // if yes, they are allowed to proceed further
    modifier accountCreated(address _addr) {
        require(users[_addr].created, "Account not found !");
        _;
    }

    // Returns person name at account in given address
    function getAccountNameByAddress(address _addr)
        public
        view
        accountCreated(_addr)
        returns (string memory)
    {
        return users[_addr].name;
    }

    // Get person name of invoker account
    function getMyAccountName() public view returns (string memory) {
        return getAccountNameByAddress(msg.sender);
    }

    // Returns number of polls created by given address
    function getAccountPollCountByAddress(address _addr)
        public
        view
        accountCreated(_addr)
        returns (uint256)
    {
        return users[_addr].pollCount;
    }

    // Returns number of poll created by this account
    function getMyPollCount() public view returns (uint256) {
        return getAccountPollCountByAddress(msg.sender);
    }

    // Returns unique pollId, given creator address & index of
    // poll ( >= 0 && < #-of all polls created by creator )
    function getPollIdByAddressAndIndex(address _addr, uint256 index)
        public
        view
        accountCreated(_addr)
        returns (bytes32)
    {
        require(
            index < users[_addr].pollCount,
            "Invalid index for looking up PollId !"
        );

        return users[_addr].ids[index];
    }

    // Given poll index ( < number of polls created by msg.sender ),
    // it'll lookup pollId from my account
    function getMyPollIdByIndex(uint256 index) public view returns (bytes32) {
        return getPollIdByAddressAndIndex(msg.sender, index);
    }

    // Given pollId, returns account which created this poll
    function getCreatorAddressByPollId(bytes32 _pollId)
        public
        view
        checkPollExistance(_pollId)
        returns (address)
    {
        return pollIdToUser[_pollId];
    }

    // Returns title of poll, by given pollId
    function getTitleByPollId(bytes32 _pollId)
        public
        view
        checkPollExistance(_pollId)
        returns (string memory)
    {
        return polls[_pollId].title;
    }

    // Get timestamp when poll was set active
    function getStartTimeByPollId(bytes32 _pollId)
        public
        view
        checkPollExistance(_pollId)
        returns (uint256)
    {
        return polls[_pollId].startTimeStamp;
    }

    // Get timestamp when poll will go deactive
    function getEndTimeByPollId(bytes32 _pollId)
        public
        view
        checkPollExistance(_pollId)
        returns (uint256)
    {
        return polls[_pollId].endTimeStamp;
    }

    // Given pollId, looks up total #-of votes casted
    function getTotalVotesCastedByPollId(bytes32 _pollId)
        public
        view
        checkPollExistance(_pollId)
        returns (uint256)
    {
        return polls[_pollId].totalVotesCasted;
    }

    // Given pollId, returns number of options present
    function getPollOptionCountByPollId(bytes32 _pollId)
        public
        view
        checkPollExistance(_pollId)
        returns (uint8)
    {
        return polls[_pollId].pollOptionCount;
    }

    // checks whether address has voted in specified poll ( by pollId ) or not
    modifier votedYet(bytes32 _pollId, address _addr) {
        require(polls[_pollId].votes[_addr] != 0, "Not voted yet !");
        _;
    }

    // Given target pollId & voter's unique address, it'll lookup
    // pollOptionIndex ( >=0 && < #-of-options ) choice made by voter
    //
    // If voter hasn't yet participated in this poll, it'll fail
    function getVoteByPollIdAndAddress(bytes32 _pollId, address _addr)
        public
        view
        checkPollExistance(_pollId)
        isPollAlreadyLive(_pollId)
        votedYet(_pollId, msg.sender)
        returns (uint8)
    {
        return polls[_pollId].votes[_addr] - 1;
    }

    // Looks up vote choice made by function invoker in specified poll,
    // given that user has already voted or fails
    function getMyVoteByPollId(bytes32 _pollId) public view returns (uint8) {
        return getVoteByPollIdAndAddress(_pollId, msg.sender);
    }

    // Given pollId & option index, returns content of that option
    function getPollOptionContentByPollIdAndIndex(bytes32 _pollId, uint8 index)
        public
        view
        checkPollExistance(_pollId)
        returns (string memory)
    {
        require(
            index < polls[_pollId].pollOptionCount,
            "Invalid index for looking up PollOption !"
        );

        return polls[_pollId].pollOptions[index].content;
    }

    // Given pollId & option index, returns votes casted on that option
    function getPollOptionVoteCountByPollIdAndIndex(
        bytes32 _pollId,
        uint8 index
    ) public view checkPollExistance(_pollId) returns (uint256) {
        require(
            index < polls[_pollId].pollOptionCount,
            "Invalid index for looking up PollOption !"
        );

        return polls[_pollId].pollOptions[index].voteCount;
    }

    // Given pollId, checks what's current status of poll i.e.
    // which is winning option upto this point, returns index & vote count of winning option
    //
    // poll must be started before invoking this function, otherwise fails
    function getWinningOptionIndexAndVotesByPollId(bytes32 _pollId)
        public
        view
        checkPollExistance(_pollId)
        isPollAlreadyLive(_pollId)
        votedYet(_pollId, msg.sender)
        returns (uint8, uint256)
    {
        uint8 count = getPollOptionCountByPollId(_pollId);

        uint8 maxVoteIndex = 0;
        uint256 maxVoteCount = getPollOptionVoteCountByPollIdAndIndex(
            _pollId,
            maxVoteIndex
        );

        for (uint8 i = 1; i < count; i++) {
            uint256 _tmp = getPollOptionVoteCountByPollIdAndIndex(_pollId, i);
            if (_tmp > maxVoteCount) {
                maxVoteIndex = i;
                maxVoteCount = _tmp;
            }
        }

        return (maxVoteIndex, maxVoteCount);
    }

    // Given pollId, and poll creator is invoking this function,
    // it'll announce that poll has ended with result, where result is event emitted
    //
    // Make sure poll has ended, before invoking this function, otherwise it'll fail
    function announcePollResult(bytes32 _pollId)
        public
        didYouCreatePoll(_pollId)
    {
        require(polls[_pollId].endTimeStamp <= now, "Poll not ended yet !");

        (
            uint8 winningIndex,
            uint256 winningVotes
        ) = getWinningOptionIndexAndVotesByPollId(_pollId);

        emit PollResult(
            msg.sender,
            _pollId,
            winningIndex,
            winningVotes,
            getTotalVotesCastedByPollId(_pollId)
        );
    }

    // Given pollid, checks whether poll has ended or not
    function hasPollEnded(bytes32 _pollId)
        public
        view
        checkPollExistance(_pollId)
        returns (bool)
    {
        return polls[_pollId].endTimeStamp <= now;
    }

    // given address of user account, checks existence,
    // only author of smart contract can do so
    function userAccountExists(address _addr)
        public
        view
        onlyAuthor
        returns (bool)
    {
        return users[_addr].created;
    }

    // checks for existence of account of this function invoker ( msg.sender )
    function amIRegistered() public view returns (bool) {
        return users[msg.sender].created;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}