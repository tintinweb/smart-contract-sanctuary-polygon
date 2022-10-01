// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import '@opengsn/contracts/src/ERC2771Recipient.sol';

//--------------------------------------------------------------------------------//

                  /*╔═══════════════════════════════════════╗
                    ║ *******  WELLCOME TO POLLYA!  ******* ║
                    ╚═══════════════════════════════════════╝*/

//----------------------------------------------------------------------------------//

/*╔═════════════════════════════╗
  ║        CUSTOM ERRORS        ║
  ╚═════════════════════════════╝*/

error Unauthorized();
error PollOwnerNotAllowed();
error NotAPollOwner();
error InvalidPoll();
error PollExpired();
error PollIsLive();
error InvalidUser();
error UserAlreadyExists();
error DuplicateVoter();
error NotEmpty();
error InvalidAge(uint8 given, uint8 mustBeAbove, uint8 mustBeBelow);
error MisMatch(string required, string given);

contract PollyaDev is ERC2771Recipient {
    address Owner;
    uint8 MaxPollOptionCount = 10;

    constructor(address _trustedForwarder) {
        _setTrustedForwarder(_trustedForwarder);
        Owner = _msgSender();
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
        if (polls[_pollId].creator != _msgSender()) revert NotAPollOwner();
        _;
    }

    modifier _isNotCreator(bytes32 _pollId) {
        if (polls[_pollId].creator == _msgSender())
            revert PollOwnerNotAllowed();
        _;
    }

    modifier OnlyOwner() {
        if (_msgSender() != Owner) revert Unauthorized();
        _;
    }

    modifier _isPollLive(bytes32 _pollId) {
        if (polls[_pollId].endTime < block.timestamp) revert PollExpired();
        _;
    }

    modifier _isPollExpired(bytes32 _pollId) {
        if (polls[_pollId].endTime > block.timestamp) revert PollIsLive();
        _;
    }

    modifier _userExists() {
        if (!users[_msgSender()].created) revert InvalidUser();
        _;
    }

    modifier _userNotExists() {
        if (users[_msgSender()].created) revert UserAlreadyExists();
        _;
    }

    modifier _checkPollExistance(bytes32 _pollId) {
        if (pollIdToUser[_pollId] == address(0)) revert InvalidPoll();
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
                'Invalid option!'
            );
        }
        _;
    }

    modifier _checkDuplicateVote(bytes32 _pollId) {
        if (voteByUserWithPollId[_msgSender()][_pollId] != 0)
            revert DuplicateVoter();
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
        uint8 income;
        uint256 pollCount;
        bool created;
    }

    struct Criteria {
        string occupation;
        string location;
        string gender;
        string maritalStatus;
        uint8 income;
        uint8 minAge;
        uint8 maxAge;
    }

    struct Poll {
        bool multiplePoll;
        bool restricted;
        address creator;
        string title;
        uint256 startTime;
        uint256 endTime;
        uint256 totalVotesCasted;
        uint8 pollOptionCount;
        Criteria criterias;
    }

    struct PollOption {
        string content;
        uint256 voteCount;
    }

    /*╔═════════════════════════════╗
      ║           MAPPINGS          ║
      ╚═════════════════════════════╝*/

    mapping(address => User) users;
    mapping(bytes32 => Poll) polls;
    mapping(bytes32 => address) pollIdToUser;
    mapping(address => mapping(bytes32 => uint8)) voteByUserWithPollId;
    mapping(bytes32 => mapping(uint8 => PollOption)) pollOptions;

    /*╔═════════════════════════════╗
      ║      INTERNAL FUNCTIONS     ║
      ╚═════════════════════════════╝*/

    // To check the user met the criteria of poll to perform vote
    function _doesMeetCriteria(bytes32 _pollId) internal view returns (bool) {
        Criteria memory cri = polls[_pollId].criterias;
        User memory _user = users[_msgSender()];
        bool result;
        if (
            (_isEmpty(cri.occupation) ||
                _isMatch(cri.occupation, _user.occupation)) &&
            (_isEmpty(cri.location) ||
                _isMatch(cri.location, _user.location)) &&
            (_isEmpty(cri.gender) || 
                _isMatch(cri.gender, _user.gender)) &&
            (_isEmpty(cri.maritalStatus) ||
                _isMatch(cri.maritalStatus, _user.maritalStatus))
        ) {
            if (!(cri.minAge == 0 && cri.maxAge == 0)) {
                if (!(cri.minAge <= _user.age && cri.maxAge >= _user.age)) {
                    revert InvalidAge({
                        given: _user.age,
                        mustBeAbove: cri.minAge - 1,
                        mustBeBelow: cri.maxAge + 1
                    });
                }
            }
            if (cri.income != 10) {
                require(_user.income == cri.income, 'income mismatch');
            }
            result = true;
        }
        return result;
    }

    // Internal function to check the strings was Not Empty.
    function _isNotEmpty(string memory _data) internal pure returns (bool) {
        bool result;
        if (
            keccak256(abi.encodePacked((_data))) !=
            keccak256(abi.encodePacked(('')))
        ) {
            result = true;
        }
        return result;
    }

    // Internal function to check the strings was Empty.
    function _isEmpty(string memory _data) internal pure returns (bool) {
        bool result;
        if (
            keccak256(abi.encodePacked((_data))) ==
            keccak256(abi.encodePacked(('')))
        ) {
            result = true;
        }
        return result;
    }

    // Internal function to check the two strings are same.
    function _isMatch(string memory _in, string memory _out)
        internal
        pure
        returns (bool)
    {
        if (
            keccak256(abi.encodePacked((_in))) !=
            keccak256(abi.encodePacked((_out)))
        ) revert MisMatch({required: _in, given: _out});
        return true;
    }

    // Internal function to add Poll options
    function _addPollOption(
        string[] memory _data,
        uint8 _count,
        bytes32 _pollId
    ) internal returns (bool) {
        require(_count != 0 && _data.length == _count, 'invalid count');
        for (uint8 i = 0; i < _count; i++) {
            PollOption memory pollOption;
            pollOption.content = _data[i];
            pollOptions[_pollId][i] = pollOption;
        }
        return true;
    }

    // Internal function to add User data
    function _addUser(
        string memory _name,
        string memory _occupation,
        string memory _location,
        string memory _gender,
        string memory _maritalStatus,
        uint8 _age,
        uint8 _income
    ) internal returns (bool) {
        User memory _user;
        _user.user = _msgSender();
        if (
            _isNotEmpty(_name) &&
            _isNotEmpty(_occupation) &&
            _isNotEmpty(_location) &&
            _isNotEmpty(_gender) &&
            _isNotEmpty(_maritalStatus)
        ) {
            _user.name = _name;
            _user.occupation = _occupation;
            _user.location = _location;
            _user.gender = _gender;
            _user.maritalStatus = _maritalStatus;
            _user.income = _income;
        } else revert NotEmpty();

        if (_age >= 16 && _age < 100) {
            _user.age = _age;
        } else
            revert InvalidAge({given: _age, mustBeAbove: 15, mustBeBelow: 100});

        _user.created = true;
        users[_msgSender()] = _user;
        return true;
    }

    // Internal function to add Poll data
    function _addPoll(
        bool _multiplePoll,
        bool _restricted,
        string memory _title,
        uint8 _optionCount,
        string[4] memory criteria,
        uint8 _income,
        uint8[2] memory _age,
        uint256 _endTime,
        bytes32 pollId
    ) internal returns (bool) {
        Poll memory poll;
        if (_restricted) {
            Criteria memory _criteria;
            _criteria.occupation = criteria[0];
            _criteria.location = criteria[1];
            _criteria.gender = criteria[2];
            _criteria.maritalStatus = criteria[3];
            _criteria.income = _income;
            _criteria.minAge = _age[0];
            _criteria.maxAge = _age[1];
            poll.criterias = _criteria;
        }

        poll.multiplePoll = _multiplePoll;
        poll.restricted = _restricted;
        poll.creator = _msgSender();
        if (_isEmpty(_title)) {
            revert NotEmpty();
        }
        poll.title = _title;
        poll.startTime = block.timestamp;
        poll.endTime = _endTime;
        poll.pollOptionCount = _optionCount;
        polls[pollId] = poll;
        return true;
    }

    /*╔═════════════════════════════╗
      ║        WRITE FUNCTIONS      ║
      ╚═════════════════════════════╝*/

    // To set TrustForwarder in later (ADMIN CALL ONLY)
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
        uint8 _age,
        uint8 _income
    ) external _userNotExists returns (bool) {
        _addUser(
            _name,
            _occupation,
            _location,
            _gender,
            _maritalStatus,
            _age,
            _income
        );
        emit UserCreated(_msgSender());
        return true;
    }

    // To Create Poll.
    function CreatePoll(
        bool _multiplePoll,
        bool _restricted,
        string memory _title,
        uint8 _optionCount,
        string[] memory _options,
        string[4] memory criteria,
        uint8 _income,
        uint8[2] memory _age,
        uint256 _endTime
    ) external _userExists returns (bytes32) {
        bytes32 pollId = keccak256(
            abi.encodePacked(_title, _msgSender(), block.timestamp)
        );
        require(
            _optionCount <= MaxPollOptionCount && _optionCount != 0,
            'must be below or equal to 10'
        );
        _addPoll(
            _multiplePoll,
            _restricted,
            _title,
            _optionCount,
            criteria,
            _income,
            _age,
            _endTime,
            pollId
        );
        _addPollOption(_options, _optionCount, pollId);
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
        Poll memory _poll = polls[_pollId];
        require(!_poll.multiplePoll, "It's a Single Option Poll");
        if (_poll.restricted) {
            require(_doesMeetCriteria(_pollId));
        }
        pollOptions[_pollId][_option].voteCount++;
        voteByUserWithPollId[_msgSender()][_pollId] = 1;
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
        Poll memory _poll = polls[_pollId];
        require(_poll.multiplePoll, "It's a Single Option Poll");
        if (_poll.restricted) {
            require(_doesMeetCriteria(_pollId));
        }
        voteByUserWithPollId[_msgSender()][_pollId] = 1;
        for (uint8 i = 0; i < _option.length; i++) {
            pollOptions[_pollId][i].voteCount++;
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
            data[i] = pollOptions[_pollId][i].content;
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
            data[i] = pollOptions[_pollId][i].voteCount;
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
        uint8 k = polls[_pollId].pollOptionCount;
        uint256 data = 0;
        for (uint8 i = 0; i < k; i++) {
            data += pollOptions[_pollId][i].voteCount;
        }
        return data;
    }

    // Added check for poll activation
    function isPollActive(bytes32 _pollId) public view returns (bool) {
        return
            polls[_pollId].startTime <= block.timestamp &&
            polls[_pollId].endTime > block.timestamp;
    }

    // To Get Poll Data by PollId
    function getPollData(bytes32 _pollId) public view returns (Poll memory) {
        return polls[_pollId];
    }

    // To Get User Data by UserId
    function getUserData(address _user) public view returns (User memory) {
        return users[_user];
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