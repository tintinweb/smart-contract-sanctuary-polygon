// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@opengsn/contracts/src/BaseRelayRecipient.sol";

contract Liderbords is BaseRelayRecipient {
    struct Score {
        int256 upvotes;
        int256 downvotes;
        uint256 index;
    }
    struct Resource {
        mapping(string => Score) scores;
        string[] liderbords;
        address owner;
    }
    struct Vote {
        int8 side;
        string resource;
    }
    struct Liderbord {
        uint256 length;
        mapping(uint256 => string) resources;
        mapping(address => Vote) voters;
    }
    struct User {
        uint256 happycoins;
        uint256 lastDateClaimed;
    }
    mapping(string => Resource) private resources;
    mapping(string => Liderbord) private liderbords;
    mapping(address => User) private users;
    address public owner;

    modifier onlyOwner() {
        require(owner == _msgSender(), "");
        _;
    }

    constructor(address _trustedForwarder) {
        _setTrustedForwarder(_trustedForwarder);
        owner = _msgSender();
    }

    function getLiderbord(string memory _liderbordName)
        public
        view
        returns (
            string[] memory,
            int256[] memory,
            int256[] memory,
            int256[] memory
        )
    {
        uint256 n = liderbords[_liderbordName].length;
        string[] memory links = new string[](n);
        int256[] memory scores = new int256[](n);
        int256[] memory upvotes = new int256[](n);
        int256[] memory downvotes = new int256[](n);
        for (uint256 i = 0; i < n; i++) {
            Resource storage resource = resources[
                liderbords[_liderbordName].resources[i]
            ];
            links[i] = liderbords[_liderbordName].resources[i];
            upvotes[i] = resource.scores[_liderbordName].upvotes;
            downvotes[i] = resource.scores[_liderbordName].downvotes;
            scores[i] = upvotes[i] - downvotes[i];
        }
        return (links, scores, upvotes, downvotes);
    }

    function addResource(string memory _link, string[] memory _liderbordNames)
        public
    {
        require(
            users[_msgSender()].happycoins > 1,
            "Need 2 HC to add a resource"
        );
        users[_msgSender()].happycoins -= 2;

        // require that the resource does not exist
        Resource storage resource = resources[_link];
        for (uint256 i = 0; i < _liderbordNames.length; i++) {
            string memory liderbordName = _liderbordNames[i];
            resource.liderbords.push(liderbordName);
            Liderbord storage liderbord = liderbords[liderbordName];
            resource.scores[liderbordName] = Score({
                upvotes: 0,
                downvotes: 0,
                index: liderbord.length
            });
            liderbord.resources[liderbord.length] = _link;
            liderbord.length++;
        }
    }

    function getResource(string memory _link)
        public
        view
        returns (string[] memory, Score[] memory)
    {
        Resource storage resource = resources[_link];
        uint256 length = resource.liderbords.length;
        string[] memory liderbordNames = new string[](length);
        Score[] memory scores = new Score[](length);
        for (uint256 i = 0; i < length; i++) {
            liderbordNames[i] = resource.liderbords[i];
            scores[i] = resource.scores[liderbordNames[i]];
        }
        return (liderbordNames, scores);
    }

    function deleteResource(string memory _link) public {
        Resource storage resource = resources[_link];
        for (uint256 i = 0; i < resource.liderbords.length; i++) {
            Liderbord storage liderbord = liderbords[resource.liderbords[i]];
            liderbord.resources[
                resource.scores[resource.liderbords[i]].index
            ] = liderbord.resources[liderbord.length - 1];
            liderbord.length--;
        }
        delete resources[_link];
    }

    function claimHappycoins() public {
        require(
            users[_msgSender()].happycoins < 30,
            "Maximun of 30 happycoins"
        );
        if (
            users[_msgSender()].lastDateClaimed + 86400 > block.timestamp ||
            users[_msgSender()].lastDateClaimed == 0
        ) {
            users[_msgSender()].lastDateClaimed = block.timestamp;
            if (users[_msgSender()].happycoins >= 20) {
                users[_msgSender()].happycoins == 30;
            } else {
                users[_msgSender()].happycoins += 10;
            }
        } else {
            revert("Can't claim happycoins before 24h");
        }
    }

    function getUser(address _user) public view returns (User memory) {
        return users[_user];
    }

    function vote(
        string memory _link,
        string memory _liderbordName,
        int8 _side
    ) public {
        Resource storage resource = resources[_link];
        Liderbord storage liderbord = liderbords[_liderbordName];
        require(
            resource.owner != _msgSender(),
            "Can't vote on your own resource"
        );
        require(_side == 1 || _side == -1, "Vote has to be either 1 or -1");
        require(
            users[_msgSender()].happycoins > 0,
            "Need to have happycoins to vote"
        );
        users[_msgSender()].happycoins--;

        if (liderbord.voters[_msgSender()].side != 0) {
            Resource storage prevResource = resources[
                liderbord.voters[_msgSender()].resource
            ];
            if (_side == 1) {
                prevResource.scores[_liderbordName].downvotes--;
            } else {
                prevResource.scores[_liderbordName].upvotes--;
            }
        }

        if (_side == 1) {
            resource.scores[_liderbordName].upvotes++;
        } else {
            resource.scores[_liderbordName].downvotes++;
        }
        liderbord.voters[_msgSender()] = Vote({side: _side, resource: _link});
    }

    function setTrustForwarder(address _trustedForwarder) public onlyOwner {
        _setTrustedForwarder(_trustedForwarder);
    }

    function versionRecipient() external pure override returns (string memory) {
        return "1";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
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

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}