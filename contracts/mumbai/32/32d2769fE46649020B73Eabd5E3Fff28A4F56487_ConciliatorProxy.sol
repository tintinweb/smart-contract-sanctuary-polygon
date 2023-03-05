/**
 *Submitted for verification at polygonscan.com on 2023-03-05
*/

// SPDX-License-Identifier: MIT

// File: contracts/lib/Heap.sol



pragma solidity 0.8.19;

library HeapLib {
    struct Heap {
        uint256[] data;
        uint256 size;
    }

    function pop(Heap storage heap) external returns (uint256 _data) {
        require(heap.size > 0, "Heap is empty.");

        _data = heap.data[0];
        heap.size--;
        heap.data[0] = heap.data[heap.size];
        heap.data.pop();

        if (heap.size == 0) {
            return _data;
        }
        
        uint256 j;
        uint256 _pos = 0;
        while ((j = ((_pos + 1) << 1)) <= heap.size) {
            uint256 mci = heap.size > j ? heap.data[j] < heap.data[j-1] ? j : j-1 : j-1;

            if (heap.data[mci] >= heap.data[_pos]) {
                break;
            }

            (heap.data[_pos], heap.data[mci]) = (heap.data[mci], heap.data[_pos]);
            _pos = mci;
        }
    }

    function push(Heap storage heap, uint256 value) external {
        heap.data.push(value);
        uint256 _pos = heap.size;
        heap.size++;
        uint256 _pi;

        while (_pos > 0 && heap.data[_pos] < heap.data[_pi = ((_pos - 1)>>1)]) {
            (heap.data[_pos], heap.data[_pi]) = (heap.data[_pi], value);
            _pos = _pi;
        }
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: contracts/ConciliatorProxy.sol



pragma solidity 0.8.19;




struct Proposal {
    uint256 _blockHeight;
    uint256 _minimumVote;
    address _contract;
    address _from;
    string _name;
    string _description;
    bytes _calldata;
}

struct ProposalResult {
    bool executed;
    bool succeeded;
    uint256 proposalId;
}

contract ConciliatorProxy is Ownable {
    using HeapLib for HeapLib.Heap;

    mapping(uint256 => Proposal) private _proposals;
    mapping(uint256 => mapping(bool => uint256)) private _votes;
    mapping(uint256 => mapping(address => bool)) private _hasVoted;
    mapping(uint256 => uint256[]) private _waitlist;
    HeapLib.Heap private _awaitingBlockHeights;
    address private _accessToken;
    uint256 private _nextProposalId;
    uint256 private _lastSettledAt;

    ProposalResult[] private _lastResult;

    event NewProposal(address indexed _from, uint256 _proposalId);
    event ProposalSettled(uint256 indexed _proposalId, ProposalResult result);
    event ProposalAbandoned(uint256 indexed _proposalId);

    modifier onlyVoter() {
        require(IERC721(_accessToken).balanceOf(msg.sender) > 0, "Not a voter.");
        _;
    }

    function setAccessTokenContract(address _newContract) external onlyOwner {
        _accessToken = _newContract;
    }

    function propose(
        string calldata _name,
        string calldata _description,
        address _contract,
        bytes calldata _calldata,
        uint256 _blockHeight,
        uint256 _minimumVote
    ) external onlyVoter {
        Proposal memory prop;
        prop._name = _name;
        prop._description = _description;
        prop._contract = _contract;
        prop._calldata = _calldata;
        prop._blockHeight = _blockHeight;
        prop._minimumVote = _minimumVote;
        prop._from = msg.sender;

        _proposals[_nextProposalId] = prop;
        _waitlist[_blockHeight].push(_nextProposalId);

        _awaitingBlockHeights.push(_blockHeight);

        emit NewProposal(msg.sender, _nextProposalId);

        _nextProposalId++;
    }

    function abandonProposal(uint256 _proposalId) external {
        Proposal storage prop = _proposals[_proposalId];
        require(msg.sender == prop._from || msg.sender == owner(), "Not a proposer");

        prop._blockHeight = 0;

        emit ProposalAbandoned(_proposalId);
    }

    function execute() external returns (ProposalResult[] memory) {
        _lastSettledAt = block.number;
        while(_awaitingBlockHeights.data[0] >= block.number) {
            uint256 waited = _awaitingBlockHeights.pop();
            for (uint256 i = 0; i < _waitlist[waited].length; i++) {
                uint256 proposalId = _waitlist[waited][i];
                Proposal storage prop = _proposals[proposalId];

                if (prop._blockHeight == 0) {
                    continue;
                }

                ProposalResult memory result;
                result.proposalId = proposalId;

                uint256 upvote = _votes[proposalId][true];
                uint256 downvote = _votes[proposalId][false];

                if (upvote + downvote < prop._minimumVote || upvote <= downvote) {
                    result.executed = false;
                    result.succeeded = true;
                    _lastResult.push(result);
                    emit ProposalSettled(proposalId, result);
                    continue;
                }

                (bool ok, ) = prop._contract.call(prop._calldata);

                result.executed = true;
                result.succeeded = ok;
                _lastResult.push(result);
                emit ProposalSettled(proposalId, result);
            }
        }

        ProposalResult[] memory results = new ProposalResult[](_lastResult.length);

        for (uint256 i = 0; i < _lastResult.length; i++) {
            results[i] = _lastResult[i];
        }

        delete _lastResult;

        return results;
    }

    function proposalData(uint256 _proposalId) external view returns (Proposal memory prop) {
        prop = _proposals[_proposalId];
    }

    function hasVoted(uint256 _proposalId, address voter) public view returns (bool voted) {
        voted = _hasVoted[_proposalId][voter];
    }

    function isSettled(uint256 _proposalId) external view returns (bool settled) {
        settled = _proposals[_proposalId]._blockHeight >= _lastSettledAt;
    }

    function isAbandoned(uint256 _proposalId) external view returns (bool abandoned) {
        abandoned = _proposals[_proposalId]._blockHeight == 0;
    }

    function vote(uint256 _proposalId, bool upvote) external onlyVoter {
        require(_proposals[_proposalId]._blockHeight > block.number, "This proposal is already expired to vote to.");
        require(!hasVoted(_proposalId, msg.sender), "You're already voted to this proposal.");
        _votes[_proposalId][upvote] += 1;
        _hasVoted[_proposalId][msg.sender] = true;
    }
}