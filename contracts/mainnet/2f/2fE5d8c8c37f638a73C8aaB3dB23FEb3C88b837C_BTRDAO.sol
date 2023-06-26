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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.19;

interface IBTRNFT {
  function returnTotalSupply() external view returns(uint);
}

contract BTRDAO is Ownable {
    error NFT_BALANCE_EMPTY();
    error CANT_MAKE_PROPOSAL_YET();
    error PROPOSAL_HASNT_BEEN_ACCEPTED();
    error PROPOSAL_DOESNT_EXIST();
    error NOT_AN_OWNER();
    error PROPOSAL_ALREADY_VALIDATED();
    error ALREADY_VOTED();
    error MINIMUM_OF_15_VOTES();
    error NOT_ENOUGH_YES_VOTES();
    error HASNT_BEEN_7_DAYS();
    error DEADLINE_PASSED();

    enum Vote {
    YES, 
    No 
  }

    address public bTRNFTAddress;
    address public secondOwner;
    uint public currentIndex;

    constructor(address _btrNFTAddress) {
       bTRNFTAddress = _btrNFTAddress;
    }

    modifier doYouHoldBTRNFTS {
      bool hasDAONFT = (IERC1155(bTRNFTAddress).balanceOf(msg.sender, 1) > 0) || (IERC1155(bTRNFTAddress).balanceOf(msg.sender, 2) > 0);
        if(hasDAONFT == false) {
          revert NFT_BALANCE_EMPTY();
        }
        _;
    }

     modifier canYouMakeAnotherProposal {
        if(timeToCreateAnotherProposal[msg.sender] > block.timestamp) {
           revert CANT_MAKE_PROPOSAL_YET();
        }
        _;
    }

    modifier hasProposalBeenAccepted(uint index) {
      BTRProposal storage selectedBTRProposal = btrProposals[index];
        if(selectedBTRProposal.proposalAccepted == false) {
           revert PROPOSAL_HASNT_BEEN_ACCEPTED();
        }
        _;
    }

    modifier isProposalStillActive(uint index) {
      BTRProposal storage selectedBTRProposal = btrProposals[index];
      if(block.timestamp > selectedBTRProposal.proposalDeadline) {
        revert DEADLINE_PASSED();
      }
      _;
    }

     modifier canProposalBeAccepted(uint index) {
      address owner = owner();
      BTRProposal storage selectedBTRProposal = btrProposals[index];
      bool isSenderAnOwner = (msg.sender == owner || msg.sender == secondOwner);
        if(selectedBTRProposal.proposalOwner == address(0)) {
           revert PROPOSAL_DOESNT_EXIST();
        }
        if(isSenderAnOwner == false) {
          revert NOT_AN_OWNER();
        }

        if(selectedBTRProposal.proposalAlreadyValidated == true) {
          revert PROPOSAL_ALREADY_VALIDATED();
        }
        _;
    }

    modifier haveYouVotedAlready(uint index) {
       BTRProposal storage selectedBTRProposal = btrProposals[index];
       if(selectedBTRProposal.votedAlready[msg.sender] == true) {
         revert ALREADY_VOTED();
       }
      _;
    }

    modifier canProposalBeExecuted(uint index) {
       address owner = owner();
       uint totalSupply = IBTRNFT(bTRNFTAddress).returnTotalSupply();
       uint possibleTotalVotes = totalSupply > 63 ? totalSupply : 63;
       BTRProposal storage selectedBTRProposal = btrProposals[index];
       bool isSenderAnOwner = (msg.sender == owner || msg.sender == secondOwner);
       bool hasDeadlinePassed = (selectedBTRProposal.proposalDeadline > block.timestamp && selectedBTRProposal.totalVotes != possibleTotalVotes);
       if(selectedBTRProposal.totalVotes < 15) {
         revert MINIMUM_OF_15_VOTES();
       } 

       if(selectedBTRProposal.votedNo >= selectedBTRProposal.votedYes) {
         revert NOT_ENOUGH_YES_VOTES();
       }
        
        if(isSenderAnOwner == false) {
          revert NOT_AN_OWNER();
        }
        
        if(hasDeadlinePassed) {
          revert HASNT_BEEN_7_DAYS();
        }  
       _;
    }
    
    struct BTRProposal {
      bytes title;
      bytes proposal;
      address proposalOwner;
      bool proposalAccepted;
      bool proposalAlreadyValidated;
      bool proposalExecuted;
      uint votedYes;
      uint votedNo;
      uint totalVotes;
      uint proposalDeadline;
      mapping(address => bool) votedAlready;
    }
    
    mapping(uint => BTRProposal) public btrProposals;


    mapping(address => uint) timeToCreateAnotherProposal;


    function createProposal(string calldata _title, string calldata _proposal) external doYouHoldBTRNFTS canYouMakeAnotherProposal {
      BTRProposal storage currentBTRProposal = btrProposals[currentIndex];
      currentBTRProposal.title = abi.encode(_title);
      currentBTRProposal.proposal = abi.encode(_proposal);
      currentBTRProposal.proposalOwner = msg.sender;
      timeToCreateAnotherProposal[msg.sender] = block.timestamp + 24 hours;
      currentIndex++;
    }

    function addSecondDAOOwner(address _secondOwner) external {
      address owner = owner();
      if(msg.sender != owner) revert NOT_AN_OWNER();
      secondOwner = _secondOwner;
    }

    function acceptOrDenyProposal(bool _acceptProposal, uint index) external canProposalBeAccepted(index) {
       BTRProposal storage selectedBTRProposal = btrProposals[index];
       if(_acceptProposal == true) {
        selectedBTRProposal.proposalAccepted = true;
        selectedBTRProposal.proposalDeadline = block.timestamp + 7 days;
       } else {
        selectedBTRProposal.proposalAccepted = false;
       }
       selectedBTRProposal.proposalAlreadyValidated = true;
    }

    function voteOnProposal(Vote vote, uint index) external doYouHoldBTRNFTS haveYouVotedAlready(index) hasProposalBeenAccepted(index) isProposalStillActive(index) {
      BTRProposal storage selectedBTRProposal = btrProposals[index];
      if(vote == Vote.YES) {
        if(IERC1155(bTRNFTAddress).balanceOf(msg.sender, 1) > 0) {
          selectedBTRProposal.votedYes += 200;
        } else if(IERC1155(bTRNFTAddress).balanceOf(msg.sender, 2) > 0) {
          selectedBTRProposal.votedYes += 100;
        }
      } else {
          if(IERC1155(bTRNFTAddress).balanceOf(msg.sender, 1) > 0) {
          selectedBTRProposal.votedNo += 200;
        } else if(IERC1155(bTRNFTAddress).balanceOf(msg.sender, 2) > 0) {
          selectedBTRProposal.votedNo += 100;
        }
      }
      selectedBTRProposal.totalVotes++;
      selectedBTRProposal.votedAlready[msg.sender] = true;
    }

   //Either anybody from the DAO can execute the proposal or only the owners of the DAO can execute the propoosal
    function executeProposal(uint index) external canProposalBeExecuted(index) {
       BTRProposal storage selectedBTRProposal = btrProposals[index];
       selectedBTRProposal.proposalExecuted = true;
    }

    function haveYouVotedThisProposal(uint index) external view returns(bool) {
      BTRProposal storage selectedBTRProposal = btrProposals[index];
      return selectedBTRProposal.votedAlready[msg.sender];
    }

    function canCreateAnotherProposal() external view returns(bool, uint) {
      return (block.timestamp > timeToCreateAnotherProposal[msg.sender], timeToCreateAnotherProposal[msg.sender]);
    } 

     function withdrawAnyFunds() external {
       address owner = owner();
      require(address(this).balance > 0, "NO_BALANCE_TO_WITHDRAW");
      require(msg.sender == owner || msg.sender == secondOwner, "NOT_OWNER");
      (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
      require(success, "TRANSFER_FAILED");
    }

    function viewACreatedProposal(uint index) external view returns(string memory proposal, address proposalOwner, bool proposalAccepted, bool proposalAlreadyValidated, bool proposalExecuted, uint votedYes, uint votedNo, uint totalVotes, uint proposalDeadline) {
       BTRProposal storage selectedBTRProposal = btrProposals[index];
       (proposal) = abi.decode(selectedBTRProposal.proposal, (string));
       return(proposal, selectedBTRProposal.proposalOwner, selectedBTRProposal.proposalAccepted, selectedBTRProposal.proposalAlreadyValidated, selectedBTRProposal.proposalExecuted, selectedBTRProposal.votedYes, selectedBTRProposal.votedNo, selectedBTRProposal.totalVotes, selectedBTRProposal.proposalDeadline);
    }

    receive() external payable {}
    fallback() external payable {}
}