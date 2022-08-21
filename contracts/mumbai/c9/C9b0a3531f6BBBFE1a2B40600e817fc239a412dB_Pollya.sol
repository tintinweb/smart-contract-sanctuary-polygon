// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@opengsn/contracts/src/ERC2771Recipient.sol";

contract Pollya is ERC2771Recipient {
    address Owner;
    uint8 MaxPollOptionCount = 10;

    constructor(address _trustedForwarder) {
        _setTrustedForwarder(_trustedForwarder);
        Owner = msg.sender;
    }

    /*╔═════════════════════════════╗
      ║           EVENTS            ║
      ╚═════════════════════════════╝*/

    event UserCreated(address user);
    event PollCreated(address creator, bytes32 pollId);
    event PollVoteCasted(address voter, bytes32 pollId);

    /*╔═════════════════════════════╗
      ║          MODIFIERS          ║
      ╚═════════════════════════════╝*/

    modifier _isCreator(bytes32 _pollId) {
        require(polls[_pollId].creator == _msgSender(), "Not a Poll Owner");
        _;
    }

    modifier _isNotCreator(bytes32 _pollId) {
        require(
            polls[_pollId].creator != _msgSender(),
            "Poll Owner not Allowed"
        );
        _;
    }

    modifier OnlyOwner() {
        require(msg.sender == Owner, "Not a Owner");
        _;
    }

    modifier _isPollLive(bytes32 _pollId) {
        require(polls[_pollId].endTime >= block.timestamp, "Poll Expired");
        _;
    }

    modifier _isPollExpired(bytes32 _pollId) {
        require(polls[_pollId].endTime < block.timestamp, "Poll is Live");
        _;
    }

    modifier _userExists() {
        require(users[_msgSender()].created, "not exists");
        _;
    }

    modifier _userNotExists() {
        require(users[_msgSender()].created != true, "already exists");
        _;
    }

    modifier _checkPollExistance(bytes32 _pollId) {
        require(pollIdToUser[_pollId] != address(0), "Poll doesn't exist !");
        _;
    }

    modifier _isValidOptionToCastVote(bytes32 _pollId, uint8 _option) {
        require(
            _option >= 0 && _option < polls[_pollId].pollOptionCount,
            "Invalid option, can't cast vote !"
        );
        _;
    }

    modifier _isValidMultipleOptionToCastVote(
        bytes32 _pollId,
        uint8[] memory _option
    ) {
        for (uint8 i = 0; i < _option.length; i++) {
            require(
                _option[i] >= 0 && _option[i] < polls[_pollId].pollOptionCount,
                "Invalid option, can't cast vote !"
            );
        }

        _;
    }

    modifier _checkDuplicateVote(bytes32 _pollId) {
        require(
            polls[_pollId].votes[msg.sender] == 0,
            "Attempt to cast duplicate vote !"
        );
        _;
    }

    /*╔═════════════════════════════╗
      ║            STRUCTS          ║
      ╚═════════════════════════════╝*/

    struct User {
        address user;
        string name;
        string occupation;
        string location;
        string gender;
        string maritalStatus;
        uint8 age;
        uint256 pollCount;
        bool created;
        mapping(uint256 => bytes32) ids;
    }

    struct Criteria {
        string occupation;
        string location;
        string gender;
        string maritalStatus;
        uint8 minAge;
        uint8 maxAge;
    }

    struct Poll {
        bool multiplePoll;
        bool privatePoll;
        bool restricted;
        address[] whitelistedUsers;
        address creator;
        string title;
        uint256 startTime;
        uint256 endTime;
        uint16 totalVotesCasted;
        uint8 pollOptionCount;
        Criteria criterias;
        mapping(uint8 => PollOption) pollOptions;
        mapping(address => uint8) votes;
    }

    struct PollOption {
        string content;
        uint256 voteCount;
    }

    /*╔═════════════════════════════╗
      ║           MAPPINGS          ║
      ╚═════════════════════════════╝*/

    mapping(address => User) public users;
    mapping(bytes32 => Poll) public polls;
    mapping(bytes32 => address) public pollIdToUser;

    /*╔═════════════════════════════╗
      ║      INTERNAL FUNCTIONS     ║
      ╚═════════════════════════════╝*/
    // To check the user met the criteria of poll to perf
    function _doesMeetCriteria(bytes32 _pollId) internal view returns (bool) {
        Criteria memory cri = polls[_pollId].criterias;
        User storage _user = users[_msgSender()];
        require(
            keccak256(abi.encodePacked((cri.occupation))) ==
                keccak256(abi.encodePacked((_user.occupation))) ||
                keccak256(abi.encodePacked((cri.occupation))) ==
                keccak256(abi.encodePacked((""))),
            "Occupation not match"
        );
        require(
            keccak256(abi.encodePacked((cri.location))) ==
                keccak256(abi.encodePacked((_user.location))) ||
                keccak256(abi.encodePacked((cri.location))) ==
                keccak256(abi.encodePacked((""))),
            "Location not match"
        );
        require(
            keccak256(abi.encodePacked((cri.gender))) ==
                keccak256(abi.encodePacked((_user.gender))) ||
                keccak256(abi.encodePacked((cri.gender))) ==
                keccak256(abi.encodePacked((""))),
            "Gender not match"
        );
        require(
            keccak256(abi.encodePacked((cri.maritalStatus))) ==
                keccak256(abi.encodePacked((_user.maritalStatus))) ||
                keccak256(abi.encodePacked((cri.maritalStatus))) ==
                keccak256(abi.encodePacked((""))),
            "MaritalStatus not match"
        );
        require(
            (cri.minAge <= _user.age && cri.maxAge >= _user.age) ||
                (cri.minAge == 0 && cri.maxAge == 0),
            "age mismatch"
        );
        return true;
    }

    // check if the user is an whitelistedUsers.
    function _allowedUsers(bytes32 _pollId) internal view returns (bool) {
        bool result;
        address[] memory whiteListers = polls[_pollId].whitelistedUsers;
        for (uint8 i = 0; i < whiteListers.length; i++) {
            if (whiteListers[i] == _msgSender()) {
                result = true;
                break;
            }
        }
        return result;
    }

    /*╔═════════════════════════════╗
      ║        WRITE FUNCTIONS      ║
      ╚═════════════════════════════╝*/

    function setTrustForwarder(address _trustedForwarder) public OnlyOwner {
        _setTrustedForwarder(_trustedForwarder);
    }

    // To create user.
    function CreateUser(
        string memory _name,
        string memory _occupation,
        string memory _location,
        string memory _gender,
        string memory _maritalStatus,
        uint8 _age
    ) external _userNotExists returns (bool) {
        User storage _user = users[_msgSender()];
        _user.user = _msgSender();
        _user.name = _name;
        _user.occupation = _occupation;
        _user.location = _location;
        _user.gender = _gender;
        _user.maritalStatus = _maritalStatus;
        _user.age = _age;
        _user.created = true;
        emit UserCreated(_msgSender());
        return true;
    }

    // To Create Poll.
    function CreatePoll(
        bool _multiplePoll,
        bool _privatePoll,
        bool _restricted,
        string memory _title,
        uint8 _optionCount,
        string[] memory _options,
        address[] memory _whiteListed,
        string[4] memory criteria,
        uint8[2] memory _age,
        uint256 _endTime
    ) external _userExists returns (bytes32) {
        bytes32 pollId = keccak256(
            abi.encodePacked(_title, _msgSender(), block.timestamp)
        );
        require(
            _optionCount <= MaxPollOptionCount && _optionCount != 0,
            "must be below or equal to 10"
        );
        Poll storage poll = polls[pollId];
        Criteria memory _criteria;

        _criteria.occupation = criteria[0];
        _criteria.location = criteria[1];
        _criteria.gender = criteria[2];
        _criteria.maritalStatus = criteria[3];
        _criteria.minAge = _age[0];
        _criteria.maxAge = _age[1];
        poll.criterias = _criteria;
        poll.multiplePoll = _multiplePoll;
        poll.privatePoll = _privatePoll;
        poll.restricted = _restricted;
        poll.creator = _msgSender();
        poll.title = _title;
        poll.startTime = block.timestamp;
        poll.endTime = _endTime;
        poll.whitelistedUsers = _whiteListed;
        poll.pollOptionCount = _optionCount;

        for (uint8 i = 0; i < _optionCount; i++) {
            PollOption memory pollOption;
            pollOption.content = _options[i];
            poll.pollOptions[i] = pollOption;
        }
        users[_msgSender()].ids[users[_msgSender()].pollCount] = pollId;
        users[_msgSender()].pollCount++;
        pollIdToUser[pollId] = _msgSender();

        emit PollCreated(_msgSender(), pollId);
        return pollId;
    }

    // To cast Vote with single option!
    function CastSingleVote(bytes32 _pollId, uint8 _option)
        external
        _checkPollExistance(_pollId)
        _userExists
        _isNotCreator(_pollId)
        _checkDuplicateVote(_pollId)
        _isPollLive(_pollId)
        _isValidOptionToCastVote(_pollId, _option)
        returns (bool)
    {
        Poll storage _poll = polls[_pollId];
        require(!_poll.multiplePoll, "It's a Single Option Poll");
        if (_poll.restricted) {
            require(_doesMeetCriteria(_pollId));
        }
        if (_poll.privatePoll) {
            require(_allowedUsers(_pollId));
        }
        _poll.totalVotesCasted++;
        _poll.pollOptions[_option].voteCount++;
        _poll.votes[_msgSender()] = _option + 1;
        emit PollVoteCasted(_msgSender(), _pollId);
        return true;
    }

    // To cast Vote with multiple options!
    function CastMultipleVote(bytes32 _pollId, uint8[] memory _option)
        external
        _checkPollExistance(_pollId)
        _userExists
        _isNotCreator(_pollId)
        _checkDuplicateVote(_pollId)
        _isPollLive(_pollId)
        _isValidMultipleOptionToCastVote(_pollId, _option)
        returns (bool)
    {
        Poll storage _poll = polls[_pollId];
        require(_poll.multiplePoll, "It's a Single Option Poll");
        if (_poll.restricted) {
            require(_doesMeetCriteria(_pollId));
        }
        if (_poll.privatePoll) {
            require(_allowedUsers(_pollId));
        }
        _poll.totalVotesCasted++;
        for (uint8 i = 0; i < _option.length; i++) {
            _poll.pollOptions[_option[i]].voteCount++;
        }
        emit PollVoteCasted(_msgSender(), _pollId);
        return true;
    }

    /*╔═════════════════════════════╗
      ║         READ FUNCTIONS      ║
      ╚═════════════════════════════╝*/

    // To get poll options of poll id.
    function getPollOptionsByPollId(bytes32 _pollId)
        public
        view
        returns (string[] memory)
    {
        uint8 k = polls[_pollId].pollOptionCount;
        string[] memory data = new string[](k);
        for (uint8 i = 0; i < k; i++) {
            data[i] = polls[_pollId].pollOptions[i].content;
        }
        return data;
    }

    // To get poll options vote counts of poll id.
    function getPollOptionsCountByPollID(bytes32 _pollId)
        public
        view
        returns (uint256[] memory)
    {
        uint8 k = polls[_pollId].pollOptionCount;
        uint256[] memory data = new uint256[](k);
        for (uint8 i = 0; i < k; i++) {
            data[i] = polls[_pollId].pollOptions[i].voteCount;
        }
        return data;
    }

    // Given pollId, looks up total #-of votes casted
    function getTotalVotesCastedByPollId(bytes32 _pollId)
        public
        view
        _checkPollExistance(_pollId)
        returns (uint256)
    {
        return polls[_pollId].totalVotesCasted;
    }

    // Returns person name at account in given address
    function getAccountNameByAddress(address _addr)
        public
        view
        returns (string memory)
    {
        return users[_addr].name;
    }

    // To check User exists or Not!
    function userAccountExists(address _addr) public view returns (bool) {
        return users[_addr].created;
    }

    // To check poll ended or Not!
    function hasPollEnded(bytes32 _pollId)
        public
        view
        _checkPollExistance(_pollId)
        returns (bool)
    {
        return polls[_pollId].endTime <= block.timestamp;
    }

    // Given pollId, returns number of options present
    function getPollOptionCountByPollId(bytes32 _pollId)
        public
        view
        _checkPollExistance(_pollId)
        returns (uint8)
    {
        return polls[_pollId].pollOptionCount;
    }

    // Get timestamp when poll will go deactive
    function getEndTimeByPollId(bytes32 _pollId)
        public
        view
        _checkPollExistance(_pollId)
        returns (uint256)
    {
        return polls[_pollId].endTime;
    }

    // Get timestamp when poll was set active
    function getStartTimeByPollId(bytes32 _pollId)
        public
        view
        _checkPollExistance(_pollId)
        returns (uint256)
    {
        return polls[_pollId].startTime;
    }

    // Returns title of poll, by given pollId
    function getTitleByPollId(bytes32 _pollId)
        public
        view
        _checkPollExistance(_pollId)
        returns (string memory)
    {
        return polls[_pollId].title;
    }

    // Given pollId, returns account which created this poll
    function getCreatorAddressByPollId(bytes32 _pollId)
        public
        view
        _checkPollExistance(_pollId)
        returns (address)
    {
        return pollIdToUser[_pollId];
    }

    // Returns unique pollId, given creator address & index of
    function getPollIdByAddressAndIndex(address _addr, uint256 index)
        public
        view
        returns (bytes32)
    {
        require(userAccountExists(_addr));
        require(
            index < users[_addr].pollCount,
            "Invalid index for looking up PollId !"
        );

        return users[_addr].ids[index];
    }

    // Returns number of polls created by given address
    function getAccountPollCountByAddress(address _addr)
        public
        view
        returns (uint256)
    {
        require(userAccountExists(_addr));

        return users[_addr].pollCount;
    }

    // Added check for poll activation
    function isPollActive(bytes32 _pollId) public view returns (bool) {
        return
            polls[_pollId].startTime <= block.timestamp &&
            polls[_pollId].endTime > block.timestamp;
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