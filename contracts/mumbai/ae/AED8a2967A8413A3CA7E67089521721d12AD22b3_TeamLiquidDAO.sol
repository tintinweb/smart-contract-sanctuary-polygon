// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TeamLiquidNFTsInterface.sol";

contract TeamLiquidDAO is Ownable {

  constructor() {
    proposalCount = 0;
    teamLiquidNFTs = TeamLiquidNFTsInterface(0x63B7eeaD4d9F0c99e1F8Bd2D4763c61B6acee5f3);
  }

  TeamLiquidNFTsInterface teamLiquidNFTs;

  struct Proposal {
    string question;
    uint256 deadline;
    string optionA;
    string optionB;
    string optionC;
    string optionD;
    uint256 votesA;
    uint256 votesB;
    uint256 votesC;
    uint256 votesD;
    mapping(address => bool) voters;
  }

  enum Vote {
    A,
    B,
    C,
    D
  }


  mapping(uint256 => Proposal) public proposals;
  uint256 public proposalCount;


  function createProposal(
    string memory question, 
    string memory optionA,
    string memory optionB,
    string memory optionC,
    string memory optionD
    ) public onlyOwner {

    Proposal storage newProposal = proposals[proposalCount];

    newProposal.question = question;
    newProposal.deadline = block.timestamp + 5 days;
    newProposal.optionA = optionA;
    newProposal.optionB = optionB;
    newProposal.optionC = optionC;
    newProposal.optionD = optionD;

    proposalCount++;
  }


  function voteOnActiveProposal(Vote vote) external onlyNftHolder voteOnlyOnce {

    Proposal storage activeProposal = proposals[proposalCount - 1];
    uint256 voteWeight = teamLiquidNFTs.balanceOf(msg.sender);

    if(vote == Vote.A) {
      activeProposal.votesA += voteWeight;

    } else if(vote == Vote.B) {
      activeProposal.votesB += voteWeight;

    } else if(vote == Vote.C) {
      activeProposal.votesC += voteWeight;

    } else if(vote == Vote.D) {
      activeProposal.votesD += voteWeight;
    }
  }

  // ------------------------------------------------------------
  //                         MODIFIERS 
  // ------------------------------------------------------------

  modifier onlyNftHolder() {
    require(teamLiquidNFTs.balanceOf(msg.sender) > 0, "Not an NFT holder");
    _;
  }

  modifier voteOnlyOnce() {
    require(proposals[proposalCount - 1].voters[msg.sender] != true, "Already voted");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface TeamLiquidNFTsInterface {
  function balanceOf(address owner) external view returns (uint256);
}