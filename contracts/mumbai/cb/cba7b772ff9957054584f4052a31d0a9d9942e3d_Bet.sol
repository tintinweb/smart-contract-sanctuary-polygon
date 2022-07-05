/**
 *Submitted for verification at polygonscan.com on 2022-07-04
*/

// File: contracts/IGameRewardController.sol


pragma solidity ^0.8.0;

interface IGameRewardsController {

    function getCost() external view returns(uint);
    function getNftAddress() external view returns(address);
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Match.sol


pragma solidity ^0.8.0;







contract Bet is ERC1155Holder, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _matchId;
    uint public fee = 0.1 ether;

    struct Match {
        address gameRewardControllerPlayerA;
        address gameRewardControllerPlayerB;
        uint price;
        address playerA;
        address playerB;
        uint tokenIdOfPlayerA;
        uint tokenIdOfPlayerB;
        bool playerAReady;
        bool playerBReady;
        bool canceled;
        bool finished;
        address winner;
    }

    mapping(uint=>Match) private _matchIdToMatch;
    mapping(address=>bool) private _matchAlreadyCreated;
    mapping(address=>uint) private _addressToMatchId;

    constructor() {
    }

    function checkMatchInfo(uint matchId) external view returns(Match memory) {
        return _matchIdToMatch[matchId];
    }

    function checkMatchAlreadyCreated() external view returns(bool) {
        return _matchAlreadyCreated[msg.sender];
    }

    function checkAddressMatch(address _user) external view returns(Match memory) {
        uint id = _addressToMatchId[_user];
        return _matchIdToMatch[id];
    }

    function createMatch(address _playerB, address _gameRewardController, uint _tokenId) external payable returns(uint) {
        require(msg.value >= fee, "please pay the fee");
        require(_playerB != address(0), "players can't br zero address");
        require(_matchAlreadyCreated[msg.sender] != true, "a match already exists");

        IGameRewardsController _controller = IGameRewardsController(_gameRewardController);
        address _returnNftAddress = _controller.getNftAddress();
        IERC1155 _nftAddress = IERC1155(_returnNftAddress);
        uint _price = _controller.getCost();
        require(_nftAddress.balanceOf(msg.sender, _tokenId) > 0, "not enough token balance");
        require(_nftAddress.isApprovedForAll(msg.sender, address(this)) == true, "token not approved");
        _nftAddress.safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
        _matchId.increment();
        uint256 newMatchId = _matchId.current();
        Match memory _newMatch = Match(_gameRewardController, address(0), _price, msg.sender, _playerB, _tokenId, 0, true, false, false, false, address(0));
        _matchIdToMatch[newMatchId] = _newMatch;
        _matchAlreadyCreated[msg.sender] = true;
        _addressToMatchId[msg.sender] = newMatchId;
        (bool os, ) = payable(owner()).call{value: msg.value}("");
        require(os);
        return newMatchId;
    }

    function joinMatch(uint matchId, address _gameRewardController, uint _tokenId) external {
        Match memory _match = _matchIdToMatch[matchId];
        require(_match.playerA != address(0), "match doesn't exist!");
        require(_match.playerB == msg.sender, "not playerB");
        require(_match.canceled != true, "this match had been canceled!");
        require(_match.finished != true, "match has  already finished!");
        IGameRewardsController _controller = IGameRewardsController(_gameRewardController);
        address _returnNftAddress = _controller.getNftAddress();
        IERC1155 _nftAddress = IERC1155(_returnNftAddress);
        uint _price = _controller.getCost();
        require(_match.price == _price, "prices are not same for the nfts");
        require(_nftAddress.balanceOf(msg.sender, _tokenId) > 0, "not enough token balance");
        require(_nftAddress.isApprovedForAll(msg.sender, address(this)) == true, "token not approved");
        _nftAddress.safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
        _match.gameRewardControllerPlayerB = _gameRewardController;
        _match.tokenIdOfPlayerB = _tokenId;
        _match.playerBReady = true;
        _matchIdToMatch[matchId] = _match;



    }

    function startMatch(uint matchId, address _winner) external onlyOwner {
        Match memory _match = _matchIdToMatch[matchId];
        require(_match.canceled != true, "this match had been canceled!");
        require(_match.finished != true, "match had already finished!");
        require(_match.playerBReady == true, "playerB is not ready yet!");
        require(_winner == _match.playerA || _winner == _match.playerB, "the winner address doesn't match both player addresses");

        _match.winner = _winner;
        _match.finished = true;
        _matchIdToMatch[matchId] = _match;
        _matchAlreadyCreated[_match.playerA] = false;

        address _gameRewardController1 = _match.gameRewardControllerPlayerA;
        IGameRewardsController _controller1 = IGameRewardsController(_gameRewardController1);
        address _nft1 = _controller1.getNftAddress();
        address _gameRewardController2 = _match.gameRewardControllerPlayerB;
        IGameRewardsController _controller2 = IGameRewardsController(_gameRewardController2);
        address _nft2 = _controller2.getNftAddress();
        
        IERC1155 _nftAddress1 = IERC1155(_nft1);
        IERC1155 _nftAddress2 = IERC1155(_nft2);

        _nftAddress1.safeTransferFrom(address(this), _winner, _match.tokenIdOfPlayerA, 1, "");
        _nftAddress2.safeTransferFrom(address(this), _winner, _match.tokenIdOfPlayerB, 1, "");
    }

    function withdrawCanceledMatchNFT(uint matchId) external {
        Match memory _match = _matchIdToMatch[matchId];
        require(msg.sender == _match.playerA, "not the owner");
        require(_match.finished != true, "can't withdraw now, match finished, and winner had been announced");
        require(_match.canceled != true, "already withdrawn");
        require(_match.playerBReady != true, "match in session");

        address _gameRewardController = _match.gameRewardControllerPlayerA;
        IGameRewardsController _controller = IGameRewardsController(_gameRewardController);
        address _returnNftAddress = _controller.getNftAddress();
        IERC1155 _nftAddress = IERC1155(_returnNftAddress);
        uint _tokenId = _match.tokenIdOfPlayerA;
        _match.canceled = true;
        _matchIdToMatch[matchId] = _match;
        _matchAlreadyCreated[msg.sender] = false;

        _nftAddress.safeTransferFrom(address(this), msg.sender, _tokenId, 1, "");

        

    }
}