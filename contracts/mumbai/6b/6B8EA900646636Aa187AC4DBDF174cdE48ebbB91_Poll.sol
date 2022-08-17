// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@opengsn/contracts/src/ERC2771Recipient.sol";

contract Poll is ERC2771Recipient{
    event PollCreated (address creator, bytes32 pollId);
    event voteCasted (address voter, bytes32 pollID, bool vote);
    address private Owner;
    modifier onlyAuthor() {
        require(Owner == msg.sender, "You're not author !");
        _;
    }
    struct PollData{
        address pollOwner;
        string pollQues;
        string option1;
        string option2;
        uint option1votes;
        uint option2votes;
    }
    mapping (address => uint256) public pollCount;
    // mapping (bytes32 => )
    mapping(bytes32 => PollData) public polls;
    constructor(address _trustedForwarder) {
        _setTrustedForwarder(_trustedForwarder);
        Owner = msg.sender;
    }
    function setTrustForwarder(address _trustedForwarder) public onlyAuthor {
        _setTrustedForwarder(_trustedForwarder);
    }

    function createPoll (string memory _pollQues, string memory _option1, string memory _option2) public returns (bytes32) {
        bytes32 pollId = keccak256(
            abi.encodePacked(_pollQues, msg.sender, block.timestamp)
        );
        PollData memory _poll;
        _poll.pollOwner = msg.sender;
        _poll.pollQues = _pollQues;
        _poll.option1 = _option1;
        _poll.option2 = _option2;
        _poll.option1votes = 0;
        _poll.option2votes = 0;
        polls[pollId] = _poll;
        pollCount[msg.sender]++;
        emit PollCreated(msg.sender, pollId);
        return (pollId);
    }
    
    function getPolldata(bytes32 _pollId) public view returns (PollData memory){
        return polls[_pollId];
    }

    function castVote (bytes32 _pollId, bool _option) public returns (bool){
        PollData storage poll = polls[_pollId];
        require (msg.sender != poll.pollOwner, "you cant allowed");
        if(_option){
            poll.option1votes +=1;
        }
        else{
            poll.option2votes +=1;
        }
        emit voteCasted(msg.sender, _pollId, _option);
        return true;
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