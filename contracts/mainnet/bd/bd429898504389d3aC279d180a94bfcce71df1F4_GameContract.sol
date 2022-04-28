/**
 *Submitted for verification at polygonscan.com on 2022-04-28
*/

// File: contracts/VerifySignature.sol


pragma solidity ^0.8.7;

contract VerifySignature {
    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function verify(
        bytes32 _message,
        bytes memory signature,
        address _signer
    ) public pure returns (bool) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(_message);
        address signer = recoverSigner(ethSignedMessageHash, signature);
        return signer == _signer;
    }
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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: contracts/GameContract.sol


pragma solidity ^0.8.2;




contract GameContract is Ownable, VerifySignature {
    address private serverAddress;
    IERC1155 public target;
    struct ClaimStruct {
        bool exists;
    }
    mapping(string => ClaimStruct) private claimedMatchIds;
    event BetClaimed(
        string indexed matchId,
        address indexed playerOne,
        address indexed playerTwo
    );
    event BadBetClaimAttempt(
        address indexed from,
        string matchId,
        uint256[] claimedIds,
        uint256[] claimedQuantities
    );

    constructor(address _collectionAddress) {
        target = IERC1155(_collectionAddress);
    }

    function hasApprovedGameContract() public view returns (bool) {
        return target.isApprovedForAll(msg.sender, address(this));
    }

    modifier hasApproved() {
        require(
            hasApprovedGameContract(),
            string(
                abi.encodePacked(
                    "Need to call setApprovalForAll on ERC1155 at address: ",
                    target
                )
            )
        );
        _;
    }

    function encodeUintArray(uint256[] memory incoming)
        internal
        pure
        returns (bytes memory)
    {
        require(incoming.length > 0, "Cannot convert empty array");
        bytes memory value = abi.encode(incoming[0]);
        for (uint256 i = 1; i < incoming.length; i++) {
            value = abi.encode(value, incoming[i]);
        }
        return value;
    }

    function encodeAddresses(address[] memory incoming)
        internal
        pure
        returns (bytes memory)
    {
        require(incoming.length > 0, "Cannot convert empty array");
        bytes memory value = abi.encode(incoming[0]);
        for (uint256 i = 1; i < incoming.length; i++) {
            value = abi.encode(value, incoming[i]);
        }
        return value;
    }

    function _getBetHash(
        string memory matchId,
        uint256[] memory betTokens,
        uint256[] memory betQuantities,
        address[] memory players
    ) internal pure returns (bytes32) {
        require(
            betTokens.length == betQuantities.length,
            "Array lengths must match"
        );
        return
            keccak256(
                abi.encode(
                    matchId,
                    encodeUintArray(betTokens),
                    encodeUintArray(betQuantities),
                    encodeAddresses(players)
                )
            );
    }

    function getBetHash(
        string memory matchId,
        uint256[] memory betTokens,
        uint256[] memory betQuantities,
        address[] memory players
    ) public view hasApproved returns (bytes32) {
        return _getBetHash(matchId, betTokens, betQuantities, players);
    }

    function _getServerHash(
        string memory matchId,
        address[] memory players,
        address winner
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(matchId, encodeAddresses(players), winner));
    }

    function getServerHash(
        string memory matchId,
        address[] memory players,
        address winner
    ) public pure returns (bytes32) {
        return _getServerHash(matchId, players, winner);
    }

    function setCollectionAddress(address _collectionAddress) public onlyOwner {
        target = IERC1155(_collectionAddress);
    }

    function setServerAddress(address _serverAddress) public onlyOwner {
        serverAddress = _serverAddress;
    }

    function validateOneVsOneResult(
        string memory matchId,
        uint256[] memory betTokens,
        uint256[] memory betQuantities,
        address[] memory players,
        address winner,
        address loser,
        bytes memory betSignature,
        bytes memory serverSignature
    ) internal view returns (bool) {
        require(players.length == 2, "Only one on one bets");
        require(
            players[0] == winner || players[1] == winner,
            "Winner not in players"
        );
        bytes32 serverHash = _getServerHash(matchId, players, winner);

        bool isOponentSignatureValid;

        bytes32 betHash = _getBetHash(
            matchId,
            betTokens,
            betQuantities,
            players
        );
        isOponentSignatureValid = verify(betHash, betSignature, loser);
        bool isServerSignatureValid = verify(
            serverHash,
            serverSignature,
            serverAddress
        );
        return isServerSignatureValid && isOponentSignatureValid;
    }

    function claimPrize(
        string memory matchId,
        uint256[] memory betTokens,
        uint256[] memory betQuantities,
        address[] memory players,
        address winner,
        bytes memory betSignature,
        bytes memory serverSignature
    ) public hasApproved {
        require(!claimedMatchIds[matchId].exists, "Invalid nonce");
        claimedMatchIds[matchId].exists = true;
        require((msg.sender == winner), "Only winner can claim");

        address oponent;
        if (players[0] == winner) oponent = players[1];
        else oponent = players[0];

        bool isRequestValid = validateOneVsOneResult(
            matchId,
            betTokens,
            betQuantities,
            players,
            winner,
            oponent,
            betSignature,
            serverSignature
        );
        if (!isRequestValid) {
            emit BadBetClaimAttempt(
                msg.sender,
                matchId,
                betTokens,
                betQuantities
            );
        }
        require(isRequestValid, "Invalid attempt at claiming.");
        target.safeBatchTransferFrom(
            oponent,
            msg.sender,
            betTokens,
            betQuantities,
            ""
        );
    }
}