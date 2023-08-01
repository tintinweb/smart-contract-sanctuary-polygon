// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VotingBase is Ownable {
    struct Proposal {
        string id;
        string uri;
        uint256 approvalCount;
        uint256 disapprovalCount;
        uint256 neutralCount;
        uint256 startAt;
        uint256 endAt;
    }

    enum VoteType { Approval, Disapproval, Neutral }

    string public name;
    string public description;
    mapping(string => Proposal) public proposals;
    mapping(address => mapping(string => bool)) public hasVotedForProposal;

    event ProposalAdded(string indexed proposalId, string uri, uint256 startAt, uint256 endAt);
    event VoteCasted(address indexed voter, string indexed proposalId, VoteType voteType);

    constructor(string memory _name, string memory _description) {
        name = _name;
        description = _description;
    }

    function addProposal(string memory _proposalId, string memory _uri, uint256 _startAt, uint256 _endAt) public onlyOwner {
        Proposal memory proposal = Proposal(_proposalId, _uri, 0, 0, 0, _startAt, _endAt);
        proposals[_proposalId] = proposal;

        emit ProposalAdded(_proposalId, _uri,_startAt, _endAt);
    }

    function vote(string memory _proposalId, VoteType _voteType) public virtual {
        require(block.timestamp >= proposals[_proposalId].startAt, "Voting has not started for this proposal.");
        require(block.timestamp <= proposals[_proposalId].endAt, "Voting has ended for this proposal.");
        require(!hasVotedForProposal[msg.sender][_proposalId], "You have already voted for this proposal.");

        hasVotedForProposal[msg.sender][_proposalId] = true;

        if (_voteType == VoteType.Approval) {
            proposals[_proposalId].approvalCount++;
        } else if (_voteType == VoteType.Disapproval) {
            proposals[_proposalId].disapprovalCount++;
        } else if (_voteType == VoteType.Neutral) {
            proposals[_proposalId].neutralCount++;
        }

        emit VoteCasted(msg.sender, _proposalId, _voteType);
    }

    function getVoteCount(string memory _proposalId) public view returns (uint256[3] memory) {
        Proposal memory proposal = proposals[_proposalId];
        uint256[3] memory voteCounts;

        voteCounts[uint8(VoteType.Approval)] = proposal.approvalCount;
        voteCounts[uint8(VoteType.Disapproval)] = proposal.disapprovalCount;
        voteCounts[uint8(VoteType.Neutral)] = proposal.neutralCount;

        return voteCounts;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./VotingBase.sol";

contract VotingPrivate is VotingBase {
  mapping(address => bool) public whitelist;
  mapping(address => uint256) private whitelistIndex; // for more efficient removal
  address[] public whitelistAddresses;

  constructor(string memory _name, string memory _description, address[] memory _whitelist) VotingBase(_name, _description) {
    for (uint256 i = 0; i < _whitelist.length; i++) {
      _addToWhitelist(_whitelist[i]);
    }
  }

  function vote(string memory _proposalId, VotingBase.VoteType _voteType) public override onlyWhitelisted {
    super.vote(_proposalId, _voteType);
  }

  function _addToWhitelist(address _address) private {
    whitelist[_address] = true;
    whitelistAddresses.push(_address);
    whitelistIndex[_address] = whitelistAddresses.length - 1;
  }

  function addToWhitelist(address[] memory _addresses) public onlyOwner {
    for(uint i = 0; i < _addresses.length; i++) {
      // @todo(5): change this with an if because it should not return if one of the addresses is already whitelisted
      // but maybe instead of doing if checks just adding the address is more gas efficient check it
      require(!whitelist[_addresses[i]], "Address already whitelisted");

      _addToWhitelist(_addresses[i]);
    }
  }

  function removeFromWhitelist(address[] memory _addresses) public onlyOwner {
    for(uint i = 0; i < _addresses.length; i++) {
      // @todo(5)
      require(whitelist[_addresses[i]], "Address not whitelisted");

      whitelist[_addresses[i]] = false;

      // find the index of the address, swap it with the last address in the array, update the swapped addresses index, and remove the last address
      uint256 index = whitelistIndex[_addresses[i]];
      whitelistAddresses[index] = whitelistAddresses[whitelistAddresses.length - 1];
      whitelistIndex[whitelistAddresses[index]] = index;
      whitelistAddresses.pop();
    }
  }

  function getWhitelist() public view returns (address[] memory) {
    return whitelistAddresses;
  }

  function getWhitelistCount() public view returns (uint256) {
    return whitelistAddresses.length;
  }

  modifier onlyWhitelisted() {
    require(whitelist[msg.sender], "Only whitelisted addresses allowed.");
    _;
  }
}