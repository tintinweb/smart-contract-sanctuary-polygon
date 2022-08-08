// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICryptoDevs.sol";
import "./interfaces/IFakeNFTMarketplace.sol";

contract CryptoDevsDAO is Ownable {
  struct Proposal {
    uint256 nftTokenId;
    uint256 deadline;
    uint256 yayVotes;
    uint256 nayVotes;
    bool executed;
    mapping(uint256 => bool) voters;
  }

  enum Vote {
    YAY,
    NAY
  }

  mapping(uint256 => Proposal) public proposals;
  uint256 public numProposals;

  IFakeNFTMarketplace nftMarketplace;
  ICryptoDevs cryptoDevsNFT;

  constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
    nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
    cryptoDevsNFT = ICryptoDevs(_cryptoDevsNFT);
  }

  modifier nftHolderOnly() {
    require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "Not a DAO member");
    _;
  }

  modifier activeProposalOnly(uint256 proposalId) {
    require(proposals[proposalId].deadline > block.timestamp, "Deadline not exceed");
    require(!proposals[proposalId].executed, "Already executed" );
    _;
  }

  modifier inactiveProposalOnly(uint256 proposalId) {
    require(proposals[proposalId].deadline <= block.timestamp, "Deadline exceed");
    require(!proposals[proposalId].executed, "Already executed" );
    _;
  }

  function createProposal(uint256 _nftTokenId) external nftHolderOnly returns (uint256) {
    require(nftMarketplace.available(_nftTokenId), "NFT not for sale");
    Proposal storage proposal = proposals[numProposals];
    proposal.nftTokenId = _nftTokenId;
    proposal.deadline = block.timestamp + 5 minutes;
    numProposals += 1;
    return numProposals - 1;
  }

  function voteOnProposal(uint256 proposalId, Vote vote) external nftHolderOnly activeProposalOnly(proposalId) {
    Proposal storage proposal = proposals[proposalId];
    uint256 balance = cryptoDevsNFT.balanceOf(msg.sender);
    uint256 countVotes;
    for(uint256 i = 0; i < balance; i++) {
      uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
      if (!proposal.voters[tokenId]) {
        countVotes++;
        proposal.voters[tokenId] = true;
      }
    }
    require(countVotes > 0, "Already voted");
    if (vote == Vote.YAY) {
      proposal.yayVotes += countVotes;
    }
    if (vote == Vote.NAY) {
      proposal.nayVotes += countVotes;
    }
  }

  function executeProposal(uint256 proposalId) external nftHolderOnly inactiveProposalOnly(proposalId) {
    Proposal storage proposal = proposals[proposalId];
    if (proposal.yayVotes > proposal.nayVotes) {
      uint256 nftPrice = nftMarketplace.getPrice();
      require(address(this).balance >= nftPrice, "Not enough funds");
      nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
    }
    proposal.executed = true;
  }

  function withdrawEther() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  receive() external payable {}

  fallback() external payable {}
}

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
pragma solidity ^0.8.0;

interface ICryptoDevs {
  function balanceOf(address owner) external view returns (uint256 balance);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFakeNFTMarketplace {
  function getPrice() external view returns (uint256);
  function available(uint256 _tokenId) external view returns (bool);
  function purchase(uint256 _tokenId) external payable;
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