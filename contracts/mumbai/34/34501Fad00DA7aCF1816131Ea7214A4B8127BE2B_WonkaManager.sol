// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LoteryStructs.sol";
import "./ILoteryWeb3.sol";

contract WonkaManager is Ownable {

    mapping (uint => address[]) public _loteryAddresses;
    mapping (uint => address[]) public _loteryWinners;
    mapping (uint => LoterySettings) public _loterySettings;
    mapping (uint => LoteryNFTPrize[]) public _loteryNFTPrizes;
    mapping (address => mapping(uint => bool)) public _addressInLottery;
    mapping (address => mapping(uint => bool)) public _addressAlreadyAddedToLottery;
    mapping (uint => address[]) public _loteryTicketsContainer;
    mapping (uint => mapping(uint => bool)) public _loteryTicketIndexAlreadyWon;
    mapping (uint => uint) public _loteryAddressIndex;

    uint public _currentLoteryId;
    bool public _isPaused;
    bool public _pausedForLottery;

    uint[] private _winnerTicketTokens = [1111111, 2222222, 3333333];

    address WONKA_ERC_1155 = 0x6AE391f84bcE3808b5a750D9DF067183198cffEa;

    function setLoterySettings(
        uint _loteryId,
        uint _loteryTicketQuantity,
        uint _loteryTicketPrize,
        uint _loteryTicketMaxMintQuantity,
        uint _loteryTicketMaxMintQuanittyPerTxn,
        uint _lastLoteryTicketDiscount,
        bool _acceptWhiteTicket
    ) external onlyOwner {
        require(_currentLoteryId <= _loteryId, "Cannot modify settings of a previous lottery.");
        require(_loteryTicketQuantity > 0 && _loteryTicketPrize > 0 && _loteryTicketMaxMintQuantity > 0 && _loteryTicketMaxMintQuanittyPerTxn > 0, "Lottery Settings cannot be 0 or empty.");

        _loterySettings[_loteryId] = LoterySettings("", _loteryTicketQuantity, _loteryTicketPrize, _loteryTicketMaxMintQuantity, _loteryTicketMaxMintQuanittyPerTxn, _lastLoteryTicketDiscount, _acceptWhiteTicket);
    }

    function addLoteryNFTPrize(
        uint _loteryId,
        bool _isERC721,
        address _contractAddress,
        address _tokenOwner,
        uint _tokenId 
    ) external onlyOwner {
        require(_loteryId >= _currentLoteryId, "Cannot add prizes to a prevous lottery.");
        require(_loteryNFTPrizes[_loteryId].length < 3, "Prizes cannot be greater than 3.");

        if (_isERC721) {
            require(IERC721(_contractAddress).getApproved(_tokenId) == address(this), "Contract is not approved to send this token.");
            require(IERC721(_contractAddress).ownerOf(_tokenId) == _tokenOwner, "Token owner is not the owner of the token.");
        } else {
            require(IERC1155(_contractAddress).isApprovedForAll(_tokenOwner, address(this)), "Contract is not approved to send this token.");
            require(IERC1155(_contractAddress).balanceOf(_tokenOwner, _tokenId) > 0, "Token owner has not enought token balance.");
        }

        _loteryNFTPrizes[_loteryId].push(LoteryNFTPrize(_isERC721, _contractAddress, _tokenOwner, _tokenId));
    }

    function updateLoteryNFTPrize (
        uint _loteryId,
        bool _isERC721,
        address _contractAddress,
        address _tokenOwner,
        uint _tokenId,
        uint position
    ) external onlyOwner {
        require(_loteryId >= _currentLoteryId, "Cannot modify prizes to a prevous lottery.");
        require(position < _loteryNFTPrizes[_loteryId].length, "Position must be lower than the current lotery prizes length.");

        if (_isERC721) {
            require(IERC721(_contractAddress).getApproved(_tokenId) == address(this), "Contract is not approved to send this token.");
            require(IERC721(_contractAddress).ownerOf(_tokenId) == _tokenOwner, "Token owner is not the owner of the token.");
        } else {
            require(IERC1155(_contractAddress).isApprovedForAll(_tokenOwner, address(this)), "Contract is not approved to send this token.");
            require(IERC1155(_contractAddress).balanceOf(_tokenOwner, _tokenId) > 0, "Token owner has not enought token balance.");
        }

        _loteryNFTPrizes[_loteryId][position] = LoteryNFTPrize(_isERC721, _contractAddress, _tokenOwner, _tokenId);
    }

    function setLoteryPhrase(
        uint _loteryId,
        string memory _loteryPhrase
    ) external onlyOwner {
        require(_loteryId == _currentLoteryId, "Cannot set phrase to a non current lotery.");

        _loterySettings[_loteryId].phrase = _loteryPhrase;
    }

    function generateNewLotery() external onlyOwner {
        require(_loterySettings[_currentLoteryId+1].ticketQuantity > 0, "New lottery must has non zero/empty settings.");
        require(_loterySettings[_currentLoteryId+1].ticketPrice > 0, "New lottery must has non zero/empty settings.");
        require(_loterySettings[_currentLoteryId+1].ticketMaxMintQuantity > 0, "New lottery must has non zero/empty settings.");
        require(_loterySettings[_currentLoteryId+1].ticketMaxMintQuantityPerTxn > 0, "New lottery must has non zero/empty settings.");
        require(_loteryNFTPrizes[_currentLoteryId+1].length > 0, "New lottery must has non zero/empty settings.");
        require(_loteryWinners[_currentLoteryId].length > 0, "Cannot move to next lottery if winners of the current lottery have not been selected yet.");

        _currentLoteryId++;
    }

    function generateLoteryTicketsContainer(
        uint _loteryId,
        uint _lastIdx
    ) external onlyOwner {
        require(_loteryId == _currentLoteryId, "Cannot generate tickets container for a non current lotery.");
        require(_loteryWinners[_loteryId].length == 0, "Winners have already been selected");
        require(_loteryTicketsContainer[_loteryId].length < ILoteryWeb3(WONKA_ERC_1155).tokenTotalSupply(_loteryId), "Already added all ticket owners.");
        require(_lastIdx <= _loteryAddresses[_loteryId].length - _loteryAddressIndex[_loteryId], "_lastIdx would exceed the current lottery addresses length.");
        require(_pausedForLottery, "Remember to pause for lottery first.");

        for (uint i = _loteryAddressIndex[_loteryId]; i < _loteryAddressIndex[_loteryId] + _lastIdx; i++) {
            for (uint j = 0; j < ILoteryWeb3(WONKA_ERC_1155).tokenBalanceOf(_loteryAddresses[_loteryId][i], _loteryId); j++) {
                _loteryTicketsContainer[_loteryId].push(_loteryAddresses[_loteryId][i]);
            }
        }

        _loteryAddressIndex[_loteryId] += _lastIdx;
    }

    function generateLoteryRandomWinners(
        uint _loteryId
    ) external onlyOwner {
        require(_loteryId == _currentLoteryId, "Cannot generate random winners for a non current lottery.");
        require(_loteryWinners[_loteryId].length == 0, "Winners have already been selected.");
        require(_loteryTicketsContainer[_loteryId].length == ILoteryWeb3(WONKA_ERC_1155).tokenTotalSupply(_loteryId), "Tickets Container is not full of all the possible tickets yet.");

        uint _auxCounter = 0;
        for (uint i = 0; i < 7; i++) {
            bool _again = true;
            while (_again) {
                uint idx = _generateRandomNumber(_loteryTicketsContainer[_loteryId].length, _auxCounter, _loterySettings[_loteryId].phrase);
                if (!_loteryTicketIndexAlreadyWon[_loteryId][idx]) {
                    _loteryWinners[_loteryId].push(_loteryTicketsContainer[_loteryId][idx]);
                    _loteryTicketIndexAlreadyWon[_loteryId][idx] = true;
                    _auxCounter++;
                    _again = false;
                }
                _auxCounter++;
            }
        }
    }

    function sendPrizesToLoteryWinners(
        uint _loteryId
    ) external onlyOwner {
        require(_loteryId == _currentLoteryId, "Cannot send prizes of a non current lottery.");
        require(_loteryWinners[_loteryId].length == 7, "Winners have not been selected yet.");

        for (uint i = 0; i < 7; i++) {
            if (i < _loteryNFTPrizes[_loteryId].length) {
                _sendPrize(_loteryNFTPrizes[_loteryId][i], _loteryWinners[_loteryId][i]);
                ILoteryWeb3(WONKA_ERC_1155).mintWinnerToken(_loteryWinners[_loteryId][i], _winnerTicketTokens[i]);
            } else {
                ILoteryWeb3(WONKA_ERC_1155).mintWinnerToken(_loteryWinners[_loteryId][i], 4444444);
            }
        }
    }

    function _sendPrize(LoteryNFTPrize memory _loteryNFTPrize, address _winner) internal {
        if (_loteryNFTPrize.isERC721) {
            IERC721(_loteryNFTPrize.contractAddress).safeTransferFrom(_loteryNFTPrize.tokenOwner, _winner, _loteryNFTPrize.tokenId);
        } else {
            IERC1155(_loteryNFTPrize.contractAddress).safeTransferFrom(_loteryNFTPrize.tokenOwner, _winner, _loteryNFTPrize.tokenId, 1, "");
        }
    }

    function switchIsPaused() external onlyOwner {
        _isPaused = !_isPaused;
    }

    function switchPauseForLottery() external onlyOwner {
        _pausedForLottery = !_pausedForLottery;
    }

    // FUNCTIONS FOR INTERFACE

    function getAddressInLottery(uint _loteryId, address _adr) external view returns (bool) {
        return _addressInLottery[_adr][_loteryId];
    }

    function getAddressAlreadyAddedToLottery(uint _loteryId, address _adr) external view returns (bool) {
        return _addressAlreadyAddedToLottery[_adr][_loteryId];
    }

    function pushToLoteryAddresses(uint _loteryId, address _adr) external {
        require(msg.sender == WONKA_ERC_1155, "Can only be called by the Wonka Manager.");
        _loteryAddresses[_loteryId].push(_adr);
        _addressInLottery[_adr][_loteryId] = true;
        _addressAlreadyAddedToLottery[_adr][_loteryId] = true;
    }

    function removeFromLoteryAddresses(uint _loteryId, address _adr) external {
        require(msg.sender == WONKA_ERC_1155, "Can only be called by the Wonka Manager.");
        _addressInLottery[_adr][_loteryId] = false;
    }

    // RANDOM NUMBER GEN

    function _generateRandomNumber(
        uint _limit, 
        uint _counter, 
        string memory _phrase
    ) internal view returns(uint){
        return uint(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,  
                    msg.sender,
                    _counter,
                    _phrase
                )
            )
        ) % _limit;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ILoteryWeb3 {
    function tokenTotalSupply(uint) external view returns (uint);
    function tokenBalanceOf(address, uint) external view returns (uint);
    function mintWinnerToken(address _winner, uint _tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

struct LoteryNFTPrize {
    bool isERC721; // false if is ERC1155
    address contractAddress;
    address tokenOwner;
    uint tokenId;
}

struct LoterySettings {
    string phrase;
    uint ticketQuantity;
    uint ticketPrice;
    uint ticketMaxMintQuantity;
    uint ticketMaxMintQuantityPerTxn;
    uint lastLoteryTicketDiscount;
    bool acceptWhiteTicket;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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