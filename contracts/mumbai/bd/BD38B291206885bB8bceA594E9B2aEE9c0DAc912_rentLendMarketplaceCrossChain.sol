// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from '../interfaces/IAxelarGateway.sol';
import { IAxelarExecutable } from '../interfaces/IAxelarExecutable.sol';

contract AxelarExecutable is IAxelarExecutable {
    IAxelarGateway public immutable gateway;

    constructor(address gateway_) {
        if (gateway_ == address(0)) revert InvalidAddress();

        gateway = IAxelarGateway(gateway_);
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external override {
        bytes32 payloadHash = keccak256(payload);
        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash))
            revert NotApprovedByGateway();
        _execute(sourceChain, sourceAddress, payload);
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external override {
        bytes32 payloadHash = keccak256(payload);
        if (
            !gateway.validateContractCallAndMint(
                commandId,
                sourceChain,
                sourceAddress,
                payloadHash,
                tokenSymbol,
                amount
            )
        ) revert NotApprovedByGateway();

        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from '../interfaces/IAxelarGateway.sol';

interface IAxelarExecutable {
    error InvalidAddress();
    error NotApprovedByGateway();

    function gateway() external view returns (IAxelarGateway);

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external;

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// This should be owned by the microservice that is paying for gas.
interface IAxelarGasService {
    error NothingReceived();
    error TransferFailed();
    error InvalidAddress();

    event GasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, uint256 gasFeeAmount, address refundAddress);

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    function addGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function collectFees(address payable receiver, address[] calldata tokens) external;

    function refund(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetMintLimitsParams();
    error ExceedMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(
        address indexed sender,
        string destinationChain,
        string destinationAddress,
        string symbol,
        uint256 amount
    );

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address);

    function tokenDeployer() external view returns (address);

    function tokenMintLimit(string memory symbol) external view returns (uint256);

    function tokenMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library StringToAddress {
    error InvalidAddressString();

    function toAddress(string memory addressString) internal pure returns (address) {
        bytes memory stringBytes = bytes(addressString);
        uint160 addressNumber = 0;
        uint8 stringByte;

        if (stringBytes.length != 42 || stringBytes[0] != '0' || stringBytes[1] != 'x') revert InvalidAddressString();

        for (uint256 i = 2; i < 42; ++i) {
            stringByte = uint8(stringBytes[i]);

            if ((stringByte >= 97) && (stringByte <= 102)) stringByte -= 87;
            else if ((stringByte >= 65) && (stringByte <= 70)) stringByte -= 55;
            else if ((stringByte >= 48) && (stringByte <= 57)) stringByte -= 48;
            else revert InvalidAddressString();

            addressNumber |= uint160(uint256(stringByte) << ((41 - i) << 2));
        }
        return address(addressNumber);
    }
}

library AddressToString {
    function toString(address addr) internal pure returns (string memory) {
        bytes memory addressBytes = abi.encodePacked(addr);
        uint256 length = addressBytes.length;
        bytes memory characters = '0123456789abcdef';
        bytes memory stringBytes = new bytes(2 + addressBytes.length * 2);

        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        for (uint256 i; i < length; ++i) {
            stringBytes[2 + i * 2] = characters[uint8(addressBytes[i] >> 4)];
            stringBytes[3 + i * 2] = characters[uint8(addressBytes[i] & 0x0f)];
        }
        return string(stringBytes);
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRentLendMarketplace {
    enum NFTStandard {
        E721,
        E1155
    }
    enum RentLendStatus {
        LISTED, // list Item 1 10
        DELISTED, // Delist Item
        RENTED, // 0
        RETURNED //
    }

    struct RentersArrayStruct {
        uint256 listingID;
        address renterAddress;
        uint256 tokenQuantityRented;
        uint256 startTimeStamp;
        uint256 rentedDuration;
        RentLendStatus rentStatus;
    }

    struct tokenRenter {
        address renterAddress;
        uint256 tokenQuantityRented;
        uint256 rentedDuration;
        uint256 startTimeStamp;
    }
    struct tokenSeller {
        uint256 listingID;
        NFTStandard nftStandard;
        address nftAddress;
        uint256 tokenId;
        address payable sellerAddress;
        uint256 tokenQuantity; //listed qty of NFT //7
        uint256 pricePerDay;
        uint256 maxRentDuration;
        uint256 tokenQuantityAlreadyRented; //Already rented //3
        uint256[] renterKeyArray;
        RentLendStatus orderSts;
    }

    error PriceNotMet(uint256 listingID, uint256 price);
    error ItemAlreadyRented();
    //error NotListedForRent(address nftAddress, uint256 tokenId);
    error NoSellersForThisAddressTokenId();
    error AlreadyListedForRent(
        address nftAddress,
        uint256 tokenId,
        uint256 tokenQuantity
    );
    error ItemNotRentedByUser(
        uint256 tokenQuantity,
        address sellerAddress,
        address renterAddress
    );
    error NoRenterWithAddressForNftAndSellerAddress(
        address sellerAddress,
        address renterAddress
    );
    error NFTnotYetListed();
    error PriceMustBeAboveZero();
    error NotOwner();
    error TokenStandardNotSupported();
    error NoSuchListing();
    error rentDurationNotAcceptable(uint256 maxRentDuration);

    error InvalidOrderIdInput(uint256 listingID);
    error InvalidCaller(address sellerAddress, address callerAddress);
    error InvalidNFTStandard(address nftAddress);

    error InvalidInputs(
        uint256 _tokenQtyToAdd,
        uint256 _newPrice,
        uint256 _newMaxRentDuration
    );

    event ItemListedForRent(
        uint256 listingID,
        NFTStandard nftStandard,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 tokenQuantity,
        uint256 pricePerDay,
        uint256 maxRentDuration,
        RentLendStatus orderSts
    );

    event UpdateItemlisted(
        uint256 listingID,
        uint256 indexed tokenQuantity,
        uint256 indexed pricePerDay,
        uint256 indexed maxRentDuration
    );

    event ItemRented(
        uint256 listingID,
        uint256 indexed rentingID,
        address indexed renter,
        uint256 indexed tokenQuantity,
        uint256 timeStamp,
        uint256 duration, //no of days
        RentLendStatus orderSts
    );

    event ItemReturned(
        uint256 listingID,
        uint256 indexed rentingID,
        address indexed renter,
        uint256 indexed tokenQuantity,
        uint256 duration, //no of days
        RentLendStatus orderSts
    );

    event ItemDeListed(
        uint256 indexed listingID,
        RentLendStatus indexed orderSts
    );

    function listItemForRent(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity,
        uint256 _price,
        uint256 _maxRentDuration
    ) external;

    function updateListedItemForRent(
        uint256 _listingID,
        uint256 _tokenQtyToAdd,
        uint256 _newPrice,
        uint256 _newMaxRentDuration
    ) external;

    function delistItemsFromRent(uint256 _listingID) external;

    function rentItem(
        uint256 _listingID,
        uint256 _tokenQuantity,
        uint256 _duration
    ) external payable;

    function returnNftFromRent(
        uint256 _listingID,
        uint256 rentingID,
        uint256 _tokenQuantity
    ) external;

    function setAutomationAddress(address _automation) external;

    function setFeesForAdmin(uint256 _percentFees) external;

    function isERC721(address nftAddress) external view returns (bool output);

    function isERC1155(address nftAddress) external view returns (bool output);

    function withdrawFunds() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./IRentLendMarketplace.sol";
import {AxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarExecutable.sol";
import {IAxelarGasService} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import {StringToAddress, AddressToString} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/StringAddressUtils.sol";

contract rentLendMarketplaceCrossChain is
    Ownable,
    ReentrancyGuard,
    IRentLendMarketplace,
    AxelarExecutable
{
    using ERC165Checker for address;
    using StringToAddress for string;
    using AddressToString for address;

    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;
    bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;

    address payable public adminAddress;
    uint256 public orderCtr;
    uint256 public renterCtr;

    uint256 percentFeesAdmin = 4;
    uint256 public secondsToDay = 86400;
    uint256 public minRentDueSeconds = 86400;
    address public automationAddress;

    //NFTAddress=>TokenID=>UserAddress = Bool
    mapping(address => mapping(uint256 => mapping(address => bool)))
        public addressToTokenIdToListedQty;

    uint256[] public activelistingKeys;
    mapping(uint256 => tokenSeller) listingIDtoTokenSeller; //ListingID

    uint256[] public renterStructKeys; //RentingID
    mapping(uint256 => RentersArrayStruct) public rentingIDwithRenterStruct; // second order book

    modifier onlyAdmin() {
        if (msg.sender != adminAddress) {
            revert InvalidCaller(adminAddress, msg.sender);
        }
        _;
    }

    // ----------------------- AXELAR IMPL --------------------------------------
    error NotEnoughValueForGas();
    event ContractCallSent(
        string destinationChain,
        bytes payload,
        uint256 crossChainChkId
    );

    event FalseAcknowledgment(
        string destinationChain,
        string contractAddress,
        uint256 crossChainChkId
    );

    event CrossChainItemListedForRent(
        uint256 listingID,
        NFTStandard nftStandard,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 tokenQuantity,
        uint256 pricePerDay,
        uint256 maxRentDuration,
        RentLendStatus orderSts
    );

    mapping(uint256 => bool) public executed;
    mapping(uint256 => bool) responses;
    mapping(uint256 => bytes32) public destination;
    IAxelarGasService public immutable gasReceiver;
    string public thisChain;
    uint256 public crossChainChkId;
    string public receiverAddress; //Should be same on every chain - proxy address

    function checkResponse(uint256 _crossChainChkId)
        public
        view
        returns (bool)
    {
        if (executed[_crossChainChkId] == true) {
            return responses[_crossChainChkId];
        } else {
            revert("No response for this ID!");
        }
    }

    constructor(
        address gateway_,
        address gasReceiver_,
        string memory thisChain_,
        string memory _receiverAddress
    ) AxelarExecutable(gateway_) {
        orderCtr = 0;
        renterCtr = 0;
        crossChainChkId = 0;
        thisChain = thisChain_;
        adminAddress = payable(msg.sender);
        require(
            gasReceiver_ != address(0),
            "rentLendMarketplaceCrossChain: gasReceiver can't be null!"
        );
        require(
            _receiverAddress.toAddress() != address(0),
            "rentLendMarketplaceCrossChain: _receiverAddress can't be null!"
        );
        gasReceiver = IAxelarGasService(gasReceiver_);
        receiverAddress = _receiverAddress;
    }

    //@todo remove after same address deployed to every chain
    function changeReceiverAddress(string calldata _receiverAddress)
        external
        onlyAdmin
    {
        require(
            _receiverAddress.toAddress() != address(0),
            "rentLendMarketplaceCrossChain: _receiverAddress can't be null!"
        );
        receiverAddress = _receiverAddress;
    }

    function _getDestinationHash(
        string memory destinationChain,
        string memory contractAddress
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(destinationChain, contractAddress));
    }

    struct CrossChainOrder {
        uint256 id;
        string destinationChain;
        NFTStandard nftStandard; //on the other chain
        address nftAddress; //on the other chain
        uint256 tokenId; //on the other chain
        uint256 tokenQuantity; //on the other chain
        uint256 price;
        uint256 maxRentDuration;
    }
    // crossChainChkId => NFT on the other chain
    mapping(uint256 => CrossChainOrder) public crossChainChkOrder;

    function listCrossChainNFT(
        string calldata destinationChain,
        NFTStandard _nftStandard, //on the other chain
        address _nftAddress, //on the other chain
        uint256 _tokenId, //on the other chain
        uint256 _tokenQuantity, //on the other chain
        uint256 _price,
        uint256 _maxRentDuration,
        uint256 _gasForRemote
    ) external payable {
        // @todo -checks for right destination chain, valid standard, etc
        require(
            _nftStandard == NFTStandard.E721 ||
                _nftStandard == NFTStandard.E1155,
            "Invalid NFT standard input"
        );
        if (_nftStandard == NFTStandard.E721) {
            require(_tokenQuantity == 1, "Invalid quantity input!");
        } else {
            require(_tokenQuantity >= 1, "Invalid quantity input!");
        }
        crossChainChkId++;
        crossChainChkOrder[crossChainChkId] = CrossChainOrder(
            crossChainChkId,
            destinationChain,
            _nftStandard,
            _nftAddress,
            _tokenId,
            _tokenQuantity,
            _price,
            _maxRentDuration
        );
        // make payload
        bytes memory payload = abi.encode(
            msg.sender,
            _nftStandard,
            _nftAddress,
            _tokenId,
            _tokenQuantity
        );
        // encode payload with nonce
        bytes memory modifiedPayload = abi.encode(crossChainChkId, payload);
        if (_gasForRemote > 0) {
            if (_gasForRemote > msg.value) revert NotEnoughValueForGas();
            gasReceiver.payNativeGasForContractCall{value: _gasForRemote}(
                address(this),
                destinationChain,
                receiverAddress,
                modifiedPayload,
                msg.sender
            );
            if (msg.value > _gasForRemote) {
                gasReceiver.payNativeGasForContractCall{
                    value: msg.value - _gasForRemote
                }(
                    receiverAddress.toAddress(),
                    thisChain,
                    address(this).toString(),
                    abi.encode(crossChainChkId),
                    msg.sender
                );
            }
        }

        gateway.callContract(
            destinationChain,
            receiverAddress,
            modifiedPayload
        );
        emit ContractCallSent(destinationChain, payload, crossChainChkId);
        destination[crossChainChkId] = _getDestinationHash(
            destinationChain,
            receiverAddress
        );
    }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override {
        (uint256 _crossChainChkId, bool isOwner) = abi.decode(
            payload,
            (uint256, bool)
        );
        if (
            destination[_crossChainChkId] !=
            _getDestinationHash(sourceChain, sourceAddress)
        ) {
            emit FalseAcknowledgment(
                sourceChain,
                sourceAddress,
                _crossChainChkId
            );
            return;
        }
        executed[_crossChainChkId] = true;
        destination[_crossChainChkId] = 0;
        // store response regarding ownership of NFT from reciever
        responses[_crossChainChkId] = isOwner;
        CrossChainOrder memory _order = crossChainChkOrder[_crossChainChkId];
        if (isOwner) {
            _createNewOrder(
                _order.nftStandard,
                _order.nftAddress,
                _order.tokenId,
                _order.tokenQuantity,
                _order.price,
                _order.maxRentDuration
            );
        }
        // @todo - emit event
    }

    // ------------------------------------------------------------------------------------

    //Changes days
    function listItemForRent(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity,
        uint256 _price,
        uint256 _maxRentDuration
    ) external {
        bool listed = addressToTokenIdToListedQty[_nftAddress][_tokenId][
            msg.sender
        ];

        require(
            listed == false,
            "token ID already listed, Kindly Modify the listing "
        );

        if (_nftStandard == NFTStandard.E721) {
            if (!isERC721(_nftAddress)) {
                revert InvalidNFTStandard(_nftAddress);
            }
            require(
                _tokenQuantity == 1,
                "This NFT standard supports only 1 listing"
            );

            address ownerOf = IERC721(_nftAddress).ownerOf(_tokenId);
            require(ownerOf == msg.sender, "You Do not own the NFT");
        } else if (_nftStandard == NFTStandard.E1155) {
            if (!isERC1155(_nftAddress)) {
                revert InvalidNFTStandard(_nftAddress);
            }

            uint256 ownerAmount = IERC1155(_nftAddress).balanceOf(
                msg.sender,
                _tokenId
            );
            require(
                ownerAmount >= _tokenQuantity,
                "Not enough tokens owned by Address or Tokens already listed"
            );
        }

        if (_price <= 0) {
            revert PriceMustBeAboveZero();
        }
        if (_maxRentDuration < minRentDueSeconds) {
            revert rentDurationNotAcceptable(_maxRentDuration);
        }
        _createNewOrder(
            _nftStandard,
            _nftAddress,
            _tokenId,
            _tokenQuantity,
            _price,
            _maxRentDuration
        );
        emit ItemListedForRent(
            orderCtr,
            _nftStandard,
            _nftAddress,
            _tokenId,
            msg.sender,
            _tokenQuantity,
            _price,
            _maxRentDuration,
            RentLendStatus.LISTED
        );
    }

    function _createNewOrder(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity,
        uint256 _price,
        uint256 _maxRentDuration
    ) internal {
        orderCtr++;

        tokenSeller memory tokenSellerStorage;
        tokenSellerStorage.listingID = orderCtr;
        tokenSellerStorage.nftStandard = _nftStandard;
        tokenSellerStorage.nftAddress = _nftAddress;
        tokenSellerStorage.tokenId = _tokenId;
        tokenSellerStorage.sellerAddress = payable(msg.sender);
        tokenSellerStorage.tokenQuantity = _tokenQuantity;
        tokenSellerStorage.pricePerDay = _price;
        tokenSellerStorage.maxRentDuration = _maxRentDuration;
        tokenSellerStorage.tokenQuantityAlreadyRented = 0;
        tokenSellerStorage.orderSts = RentLendStatus.LISTED;

        listingIDtoTokenSeller[orderCtr] = tokenSellerStorage;
        activelistingKeys.push(orderCtr);

        addressToTokenIdToListedQty[_nftAddress][_tokenId][msg.sender] = true;
    }

    function updateListedItemForRent(
        uint256 _listingID,
        uint256 _tokenQtyToAdd,
        uint256 _newPrice,
        uint256 _newMaxRentDuration
    ) external {
        if (_listingID > orderCtr) {
            revert InvalidOrderIdInput(_listingID);
        }
        tokenSeller storage tokenSellerStorage = listingIDtoTokenSeller[
            _listingID
        ];
        if (tokenSellerStorage.sellerAddress != msg.sender) {
            revert InvalidCaller(tokenSellerStorage.sellerAddress, msg.sender);
        }
        uint256 ownerHas = 1;
        if (tokenSellerStorage.nftStandard == NFTStandard.E1155) {
            IERC1155 nft = IERC1155(tokenSellerStorage.nftAddress);
            ownerHas = nft.balanceOf(msg.sender, tokenSellerStorage.tokenId);
        }

        if (_tokenQtyToAdd > 0) {
            if (_newPrice > 0) {
                if (_newMaxRentDuration > 0) {
                    require(
                        _newMaxRentDuration >= minRentDueSeconds,
                        "Max rent duration should be greater than or equal to 1"
                    );
                    tokenSellerStorage.maxRentDuration = _newMaxRentDuration;
                }
                require(
                    _newPrice > 0,
                    "Price for listing should be greater than Zero"
                );
                tokenSellerStorage.pricePerDay = _newPrice;
            } else {
                if (_newMaxRentDuration > 0) {
                    require(
                        _newMaxRentDuration >= minRentDueSeconds,
                        "Max rent duration should be greater than or equal to 1"
                    );
                    tokenSellerStorage.maxRentDuration = _newMaxRentDuration;
                }
            }
            require(
                ownerHas >=
                    tokenSellerStorage.tokenQuantityAlreadyRented +
                        _tokenQtyToAdd,
                "Not Enough tokens owned by address"
            );
            tokenSellerStorage.tokenQuantity += _tokenQtyToAdd;
        } else {
            if (_newPrice > 0) {
                if (_newMaxRentDuration > 0) {
                    require(
                        _newMaxRentDuration >= minRentDueSeconds,
                        "Max rent duration should be greater than or equal to 1"
                    );
                    tokenSellerStorage.maxRentDuration = _newMaxRentDuration;
                }
                require(
                    _newPrice > 0,
                    "Price for listing should be greater than Zero"
                );
                tokenSellerStorage.pricePerDay = _newPrice;
            } else {
                if (_newMaxRentDuration > 0) {
                    require(
                        _newMaxRentDuration >= minRentDueSeconds,
                        "Max rent duration should be greater than or equal to 1"
                    );
                    tokenSellerStorage.maxRentDuration = _newMaxRentDuration;
                } else {
                    revert InvalidInputs(
                        _tokenQtyToAdd,
                        _newPrice,
                        _newMaxRentDuration
                    );
                }
            }
        }

        emit UpdateItemlisted(
            _listingID,
            tokenSellerStorage.tokenQuantity,
            tokenSellerStorage.pricePerDay,
            tokenSellerStorage.maxRentDuration
        );
    }

    function delistItemsFromRent(uint256 _listingID) external {
        if (_listingID > orderCtr) {
            revert InvalidOrderIdInput(_listingID);
        }
        tokenSeller storage tokenSellerStorage = listingIDtoTokenSeller[
            _listingID
        ];
        if (tokenSellerStorage.sellerAddress != msg.sender) {
            revert InvalidCaller(tokenSellerStorage.sellerAddress, msg.sender);
        }

        if (tokenSellerStorage.nftStandard == NFTStandard.E721) {
            require(
                tokenSellerStorage.tokenQuantityAlreadyRented == 0,
                "Items cannot be delisted as they are currently rented"
            );
        }
        require(
            tokenSellerStorage.orderSts != RentLendStatus.DELISTED,
            "Item with listing Id ia already delisted"
        );

        tokenSellerStorage.tokenQuantity = 0;

        tokenSellerStorage.orderSts = RentLendStatus.DELISTED;
        removeRenterListing(activelistingKeys, _listingID);

        addressToTokenIdToListedQty[tokenSellerStorage.nftAddress][
            tokenSellerStorage.tokenId
        ][msg.sender] = false;

        emit ItemDeListed(_listingID, tokenSellerStorage.orderSts);
    }

    function rentItem(
        uint256 _listingID,
        uint256 _tokenQuantity,
        uint256 _duration
    ) external payable {
        if (_listingID > orderCtr) {
            revert InvalidOrderIdInput(_listingID);
        }
        tokenSeller storage tokenSellerStorage = listingIDtoTokenSeller[
            _listingID
        ];

        require(
            msg.sender != tokenSellerStorage.sellerAddress,
            "Owned NFTs cannot be rented"
        );

        require(
            tokenSellerStorage.orderSts != RentLendStatus.DELISTED,
            "This order is delisted"
        );

        if (tokenSellerStorage.nftStandard == NFTStandard.E721) {
            require(
                _tokenQuantity == 1,
                "Token Quantity cannot be greater than 1 for ERC721 Standard"
            );
        }
        require(
            tokenSellerStorage.tokenQuantity >= _tokenQuantity,
            "Not Enough token available to rent"
        );

        if (
            _duration < minRentDueSeconds ||
            _duration > tokenSellerStorage.maxRentDuration
        ) {
            revert rentDurationNotAcceptable(_duration);
        }
        if (
            msg.value <
            (tokenSellerStorage.pricePerDay * _duration * _tokenQuantity) /
                86400
        ) {
            revert PriceNotMet(_listingID, tokenSellerStorage.pricePerDay);
        }

        updateRentItemStorage(tokenSellerStorage, _tokenQuantity, _duration);

        splitFeesAdminSeller(msg.value, tokenSellerStorage.sellerAddress);

        emit ItemRented(
            _listingID,
            renterCtr,
            msg.sender,
            _tokenQuantity,
            block.timestamp,
            _duration,
            RentLendStatus.RENTED
        );
        renterCtr++;
    }

    //Supporting the rentItem function
    function updateRentItemStorage(
        tokenSeller storage tokenSellerStorage,
        uint256 _tokenQuantity,
        uint256 _duration
    ) internal {
        //tokenSeller storage tokenSellers = tokenSellerStorage;

        tokenSellerStorage.tokenQuantity =
            tokenSellerStorage.tokenQuantity -
            _tokenQuantity;

        tokenSellerStorage.tokenQuantityAlreadyRented =
            tokenSellerStorage.tokenQuantityAlreadyRented +
            _tokenQuantity;

        RentersArrayStruct memory renterDetails;
        renterDetails.listingID = tokenSellerStorage.listingID;
        renterDetails.rentStatus = RentLendStatus.RENTED;

        renterDetails.renterAddress = msg.sender;
        renterDetails.rentedDuration = _duration;
        renterDetails.tokenQuantityRented += _tokenQuantity;
        renterDetails.startTimeStamp = block.timestamp;

        rentingIDwithRenterStruct[renterCtr] = renterDetails;

        tokenSellerStorage.renterKeyArray.push(renterCtr);
        renterStructKeys.push(renterCtr);
    }

    //delete it later

    function returnNftFromRent(
        uint256 _listingID,
        uint256 _rentingID,
        uint256 _tokenQuantity
    ) external {
        if (_listingID > orderCtr) {
            revert InvalidOrderIdInput(_listingID);
        }
        tokenSeller storage tokenSellerStorage = listingIDtoTokenSeller[
            _listingID
        ];
        if (tokenSellerStorage.nftStandard == NFTStandard.E721) {
            require(
                _tokenQuantity == 1,
                "Token Quantity cannot be greater than 1 for ERC721 Standard"
            );
        }
        RentersArrayStruct storage renterDetails = rentingIDwithRenterStruct[
            _rentingID
        ];
        require(
            renterDetails.renterAddress == msg.sender,
            "Unverified caller, only renter can return the NFT"
        );

        require(
            renterDetails.tokenQuantityRented >= _tokenQuantity,
            "Not enough tokens rented"
        );

        tokenSellerStorage.tokenQuantity =
            tokenSellerStorage.tokenQuantity +
            _tokenQuantity;

        tokenSellerStorage.tokenQuantityAlreadyRented =
            tokenSellerStorage.tokenQuantityAlreadyRented -
            _tokenQuantity;

        renterDetails.tokenQuantityRented =
            renterDetails.tokenQuantityRented -
            _tokenQuantity;

        if (renterDetails.tokenQuantityRented == 0) {
            renterDetails.rentStatus = RentLendStatus.RETURNED;
        }

        emit ItemReturned(
            _listingID,
            _rentingID,
            msg.sender,
            _tokenQuantity,
            renterDetails.rentedDuration,
            renterDetails.rentStatus
        );

        removeRenterListing(tokenSellerStorage.renterKeyArray, _rentingID);
        removeRenterFromArray(_rentingID);
    }

    function removeRenterFromArray(uint256 _rentingID) internal {
        uint256 _index;
        for (uint256 i = 0; i < renterStructKeys.length; i++) {
            if (renterStructKeys[i] == _rentingID) {
                _index = i;
                break;
            }
        }
        renterStructKeys[_index] = renterStructKeys[
            renterStructKeys.length - 1
        ];

        renterStructKeys.pop();
    }

    function getIndexOfRenterArray(
        RentersArrayStruct[] storage rentersArray,
        address _renterAddress
    ) internal view returns (uint256) {
        uint256 index;
        bool value = false;
        for (uint256 i = 0; i < rentersArray.length; i++) {
            if (rentersArray[i].renterAddress == _renterAddress) {
                index = i;
                value = true;
                break;
            }
        }
        if (value == false) {
            revert NoSuchListing();
        }
        return index;
    }

    function checkAndReturnRentedNfts() external {
        //UNCOMMENT IT LATER

        require(automationAddress != address(0), " caller cannot be null");
        require(
            msg.sender == automationAddress,
            "Only Authorised address can call this fucntion"
        );
        (
            uint256[] memory getExpired,
            uint256 toupdate
        ) = checkRentingDurationExp();
        if (toupdate > 0) {
            updateRentersDetails(getExpired);
        }
    }

    function removeRenterListing(
        uint256[] storage renterKeyArray,
        uint256 rentingID
    ) internal {
        // uint256 _index;
        for (uint256 i = 0; i < renterKeyArray.length; i++) {
            if (renterKeyArray[i] == rentingID) {
                // _index = i;
                renterKeyArray[i] = renterKeyArray[renterKeyArray.length - 1];
                renterKeyArray.pop();
                break;
            }
        }
    }

    function checkAndDelistOrders() internal {
        require(automationAddress != address(0), " caller cannot be null");
        require(
            msg.sender == automationAddress,
            "Only Authorised address can call this fucntion"
        );
        uint256 arrLength = activelistingKeys.length;
        uint256[] memory tempArray = new uint256[](arrLength);
        uint256 k = 0;
        for (uint256 i = 0; i > arrLength; i++) {
            tokenSeller storage tokenSellerStorage = listingIDtoTokenSeller[i];
            address ownerOf;
            if (tokenSellerStorage.nftStandard == NFTStandard.E721) {
                ownerOf = IERC721(tokenSellerStorage.nftAddress).ownerOf(
                    tokenSellerStorage.tokenId
                );
                if (ownerOf != tokenSellerStorage.sellerAddress) {
                    tokenSellerStorage.orderSts = RentLendStatus.DELISTED;
                    tempArray[k] = i;
                    emit ItemDeListed(
                        tokenSellerStorage.listingID,
                        tokenSellerStorage.orderSts
                    );
                }
            } else {
                uint256 ownerAmount = IERC1155(tokenSellerStorage.nftAddress)
                    .balanceOf(msg.sender, tokenSellerStorage.tokenId);

                if (ownerAmount < tokenSellerStorage.tokenQuantity) {
                    tokenSellerStorage.orderSts = RentLendStatus.DELISTED;
                    tempArray[k] = i;
                    emit ItemDeListed(
                        tokenSellerStorage.listingID,
                        tokenSellerStorage.orderSts
                    );
                }
            }
        }

        for (uint256 i = 0; i < tempArray.length; i++) {
            activelistingKeys[tempArray[i]] = activelistingKeys[
                activelistingKeys.length - 1
            ];
            activelistingKeys.pop();
        }
    }

    function checkRentingDurationExp()
        public
        view
        returns (uint256[] memory, uint256)
    {
        uint256 arrLength = renterStructKeys.length;

        // RentersArrayStruct[] memory tempArray = new RentersArrayStruct[](
        //     arrLength
        // );
        uint256[] memory tempArray = new uint256[](arrLength);
        // uint256[] memory tempArray = new uint256[](arrLength);
        uint256 k = 0;
        for (uint256 i = 0; i < renterStructKeys.length; i++) {
            if (
                block.timestamp >=
                rentingIDwithRenterStruct[i].startTimeStamp +
                    rentingIDwithRenterStruct[i].rentedDuration
            ) {
                tempArray[k] = i;
                k++;
            }
        }
        return (tempArray, k);
    }

    function updateRentersDetails(uint256[] memory _rentingIDs) internal {
        //require(msg.sender == _owner, "onlyOwner can call this function");

        require(_rentingIDs.length != 0, "The renters Array is Empty");

        for (uint256 i = 0; i < _rentingIDs.length; i++) {
            RentersArrayStruct
                storage rentersArrayStruct = rentingIDwithRenterStruct[
                    _rentingIDs[i]
                ];

            tokenSeller storage tokenSellerStorage = listingIDtoTokenSeller[
                rentersArrayStruct.listingID
            ];

            tokenSellerStorage.tokenQuantity += tokenSellerStorage
                .tokenQuantityAlreadyRented;
            tokenSellerStorage.tokenQuantityAlreadyRented = 0;

            emit ItemReturned(
                rentersArrayStruct.listingID,
                _rentingIDs[i],
                rentersArrayStruct.renterAddress,
                rentersArrayStruct.tokenQuantityRented,
                rentersArrayStruct.rentedDuration,
                RentLendStatus.RETURNED
            );

            //remove renter IDs from the renterKeyArray in order
            removeRenterListing(
                tokenSellerStorage.renterKeyArray,
                _rentingIDs[i]
            );

            //remove from renterStructKeys
            removeRenterListing(renterStructKeys, _rentingIDs[i]);
        }
    }

    //@dev functions gives us the data for listing data for
    function getListingdata(uint256 _listingID)
        public
        view
        returns (
            // address _sellerAddress
            tokenSeller memory
        )
    {
        tokenSeller memory listing = listingIDtoTokenSeller[_listingID];
        return listing;
    }

    function setAutomationAddress(address _automation) external onlyOwner {
        require(_automation != address(0), "The caller address cannot be zero");
        automationAddress = _automation;
    }

    // //@dev Fucntion calculates admin fees to be deducted from total amount
    // //and split the totalamout according to fees structure
    function splitFeesAdminSeller(uint256 _totalAmount, address _sellerAddress)
        internal
    {
        require(_totalAmount != 0, "_totalAmount must be greater than 0");
        uint256 amountToSeller = (_totalAmount * (100 - percentFeesAdmin)) /
            100;

        payable(_sellerAddress).transfer(amountToSeller);
    }

    //@dev this fucntion is used to set percent fees for every transaction
    // on the marketpalce
    function setFeesForAdmin(uint256 _percentFees) external onlyOwner {
        require(_percentFees < 100, "Fees cannot exceed 100 %");
        percentFeesAdmin = _percentFees;
    }

    function setMinRentDueSecods(uint256 _minDuration) external onlyOwner {
        require(_minDuration > 1, "Duration should be greater than 1 sec");
        minRentDueSeconds = _minDuration;
    }

    function isERC721(address nftAddress)
        public
        view
        override
        returns (bool output)
    {
        output = nftAddress.supportsInterface(IID_IERC721);
    }

    function isERC1155(address nftAddress)
        public
        view
        override
        returns (bool output)
    {
        output = nftAddress.supportsInterface(IID_IERC1155);
    }

    function withdrawFunds() external override onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    fallback() external payable {}

    receive() external payable {
        // React to receiving ether
    }
}