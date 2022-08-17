//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/ICloudKey.sol";
import "../interfaces/ICloud9Escrow.sol";

contract Cloud9Escrow is ICloud9Escrow, BaseRelayRecipient, Ownable {
    uint256 public maticClaimReleaseAmount;
    mapping(uint256 => bool) public maticClaimedForTokens;

    uint256 public carbonOffsetReleaseAmount;
    mapping(uint256 => bool) public carbonOffsetClaimedForTokens;

    address public carbonReleaseWallet;

    ICloudKey public cloudKey;

    receive() external payable {}

    constructor(
        address _trustedForwarder,
        ICloudKey _cloudKey,
        address _carbonReleaseWallet,
        uint256 _carbonOffsetReleaseAmount,
        uint256 _maticClaimReleaseAmount
    ) {
        // Zero address check all address parameters
        require(
            _trustedForwarder != address(0) &&
                address(_cloudKey) != address(0) &&
                _carbonReleaseWallet != address(0),
            "Cannot deploy with 0 address val"
        );

        cloudKey = _cloudKey;
        carbonReleaseWallet = _carbonReleaseWallet;
        maticClaimReleaseAmount = _maticClaimReleaseAmount;
        carbonOffsetReleaseAmount = _carbonOffsetReleaseAmount;

        _setTrustedForwarder(_trustedForwarder);
    }

    function withdrawMatic() external onlyOwner {
        (bool success, bytes memory returndata) = owner().call{
            value: address(this).balance
        }("");

        require(success, "Withdraw Matic Failed");
    }

    /**
      Setters
    */
    function setTrustedForwarder(address _trustedForwarder) external onlyOwner {
        require(
            _trustedForwarder != address(0),
            "Cannot set the forwarder to the 0 address"
        );
        _setTrustedForwarder(_trustedForwarder);
    }

    function setMaticClaimReleaseAmount(uint256 _newReleaseAmount)
        external
        onlyOwner
    {
        maticClaimReleaseAmount = _newReleaseAmount;

        emit UpdatedMaticClaimReleaseAmount(_msgSender(), _newReleaseAmount);
    }

    function setCarbonOffsetReleaseAmount(uint256 _newReleaseAmount)
        external
        onlyOwner
    {
        carbonOffsetReleaseAmount = _newReleaseAmount;

        emit UpdatedCarbonOffsetReleaseAmount(_msgSender(), _newReleaseAmount);
    }

    function setCarbonReleaseWallet(address _newCarbonReleaseWallet)
        external
        onlyOwner
    {
        require(
            _newCarbonReleaseWallet != address(0),
            "Cannot set the carbon release wallet to the 0 address"
        );

        carbonReleaseWallet = _newCarbonReleaseWallet;

        emit UpdatedCarbonReleaseWallet(_newCarbonReleaseWallet);
    }

    /**
      Functionality
     */
    modifier _validateEscrowClaim(
        uint256 _releaseAmount,
        mapping(uint256 => bool) storage _claimedTokens,
        uint256 _tokenId
    ) {
        require(!_claimedTokens[_tokenId], "CloudKey: Token Claimed");

        require(
            address(this).balance >= _releaseAmount,
            "Not enough contract balance to release funds"
        );

        _;
    }

    // Handler for releasing matic
    function _dispenseMatic(uint256 _amount, address _destination) internal {
        require(
            address(this).balance >= _amount,
            "Not enough contract balance to dispense matic"
        );
        require(
            _destination != address(0),
            "Cannot dispense matic with the 0x0 address"
        );

        (bool success, bytes memory data) = _destination.call{value: _amount}(
            ""
        );
        require(success, "Dispense matic failed");
    }

    function claimCarbonOffset(uint256 _tokenId)
        external
        _validateEscrowClaim(
            carbonOffsetReleaseAmount,
            carbonOffsetClaimedForTokens,
            _tokenId
        )
    {
        address owner = cloudKey.ownerOf(_tokenId);

        carbonOffsetClaimedForTokens[_tokenId] = true;

        emit CarbonOffsetReleased(owner, carbonOffsetReleaseAmount, _tokenId);

        _dispenseMatic(carbonOffsetReleaseAmount, carbonReleaseWallet);
    }

    function claimMatic(uint256 _tokenId)
        external
        _validateEscrowClaim(
            maticClaimReleaseAmount,
            maticClaimedForTokens,
            _tokenId
        )
    {
        address owner = cloudKey.ownerOf(_tokenId);

        maticClaimedForTokens[_tokenId] = true;

        emit MaticClaimed(owner, carbonOffsetReleaseAmount, _tokenId);

        _dispenseMatic(maticClaimReleaseAmount, owner);
    }

    /**
      Required method overrides
     */
    function versionRecipient()
        external
        view
        virtual
        override
        returns (string memory)
    {
        return "1.0.0";
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, BaseRelayRecipient)
        returns (bytes calldata ret)
    {
        return super._msgData();
    }

    function _msgSender()
        internal
        view
        override(Context, BaseRelayRecipient)
        returns (address sender)
    {
        // If the sender is the trusted forwarder then use the logic from the BaseRelayRecipient _msgSender function
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            sender = msg.sender;
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface ICloudKey is IERC721Upgradeable {
    /// Structs
    struct MintArgs {
        address _to;
        string _tokenURI;
    }

    struct ClaimTokenArgs {
        address _to;
        uint256 _tokenId;
    }

    struct SetTokenURIArgs {
        uint256 _tokenId;
        string _tokenURI;
    }

    /// @notice Event emitted when a tokenURI's metadata is updated
    /// @param tokenId  The tokenId that is being updated
    /// @param tokenURI  The updated tokenURI
    event TokenURIUpdated(
        uint256 indexed tokenId,
        string tokenURI,
        address indexed from
    );

    /// @notice Event emitted when a user claims a token
    /// @param tokenId  The tokenId that was claimed
    /// @param to  The user claiming the token
    event TokenClaimed(uint256 indexed tokenId, address indexed to);

    /// @notice Event emitted when a token is invalidated
    /// @param tokenId  The tokenId that was invalidated
    /// @param from  The user who invalidated the token
    /// @param timestamp  When the token was invalidated
    event TokenInvalidated(
        uint256 indexed tokenId,
        address indexed from,
        uint256 timestamp
    );

    /// @notice As the CloudKey contract is an upgradeable contract, this acts as the constructor for the contract
    /// @dev Only callable once, when the contract is being deployed
    /// @dev Assigns all the relevant access controls to the admin address provided
    /// @param _name  The name of the NFT collection
    /// @param _symbol  The symbol of the NFT collection
    /// @param _admin  The admin address to assign access controls to
    /// @param _backendWallet  The wallet that will be executing backend requests
    /// @param _contractURI  The IPFS hash for the contract URI
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _admin,
        address _backendWallet,
        address _trustedForwarder,
        string calldata _contractURI
    ) external;

    /// @notice This function validates a signature that was signed to claim an NFT. It uses the underlying SigRecovery library to recover the address.
    /// @dev This utilises the Access control contract for managing signers
    /// @param _to  The name of the NFT collection
    /// @param _tokenId  The symbol of the NFT collection
    /// @param _signature  The admin address to assign access controls to
    function validateClaimTokenSignature(
        address _to,
        uint256 _tokenId,
        bytes memory _signature
    ) external view returns (bool);

    /// @notice To allow the updating/setting of the forwarder address. This is the forwarding contract in the GSN that will be forwarding the meta transactions to the CloudKey contract
    /// @param _trustedForwarder  The updated forwarding address
    function setTrustedForwarder(address _trustedForwarder) external;

    /// @notice Allows the distribution of pre-minted tokens to users. This function is called directly by users to claim their NFT. The security is guaranteed by a signature that is created with a known wallet.
    /// @dev The signature is created with the tokenId to be claimed and the claiming user's wallet address. The tokenId ensures replay attacks aren't possible and the wallet address ensures the signature can't be stolen.
    /// @param _tokenId  The token Id to distribute
    /// @param _signature  The signature for verification
    function claimToken(
        address _to,
        uint256 _tokenId,
        bytes memory _signature
    ) external;

    /// @notice Allows the minting of tokens
    /// @dev Only callable by a wallet with the MINT_TOKENS role
    /// @param mintArgs  An array of mint arguments, allows the caller to specify a _to address and the tokenURI
    function mint(MintArgs[] calldata mintArgs) external;

    /// @notice Allows updating of a given Token Id's tokenURI
    /// @dev This is to be used when a CloudKey has been used for a subscription purchase and to update the metadata to reflect its invaldation status
    /// @param _tokenId  The token Id to update the metadata for
    /// @param _tokenURI  The new tokenURI
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external;

    /// @notice Allows the emitting of a TokenInvalidated event when the a token's URI is getting updated
    /// @dev This event is strictly to simplify our off-chain analytics on the frontend
    /// @param _tokenId  The tokenId that is being invalidated
    function invalidateCloudKey(uint256 _tokenId, string memory _tokenURI)
        external;

    /// @notice Allows updating multiple tokens URI's in the same transaction
    /// @param setTokenURIArgs  The array of updating arguments
    function batchSetTokenURI(SetTokenURIArgs[] calldata setTokenURIArgs)
        external;

    /// @notice Returns the URL for the contracts URI data
    function contractURI() external returns (string calldata);

    /// @notice Allows updating of the contracts URI
    /// @param _contractURI  The updated contractURI
    function setContractURI(string calldata _contractURI) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface ICloud9Escrow {
    /// @notice Event emitted when the matic claim release amount is updated
    /// @param updatedBy  The admin who updated the value
    /// @param releaseAmount  The updated value
    event UpdatedMaticClaimReleaseAmount(
        address indexed updatedBy,
        uint256 releaseAmount
    );

    /// @notice Event emitted when the carbon offset release amount is updated
    /// @param updatedBy  The admin who updated the value
    /// @param releaseAmount  The updated value
    event UpdatedCarbonOffsetReleaseAmount(
        address indexed updatedBy,
        uint256 releaseAmount
    );

    /// @notice Event emitted when the carbon release wallet is updated
    /// @param carbonReleaseWallet  The address of the new carbon release wallet
    event UpdatedCarbonReleaseWallet(address indexed carbonReleaseWallet);

    /// @notice Event emitted when a user claims their matic for a tokenId
    /// @param _user  The user who claimed the matic
    /// @param _dispensedAmount  The amount released
    /// @param _tokenId  The tokenId used to claim matic
    event MaticClaimed(
        address indexed _user,
        uint256 _dispensedAmount,
        uint256 _tokenId
    );

    /// @notice Event emitted when a user claims the carbon offset amount for a tokenId
    /// @param _user  The user who claimed the carbon offset
    /// @param _dispensedAmount  The amount released
    /// @param _tokenId  The tokenId used to claim the carbon offset
    event CarbonOffsetReleased(
        address indexed _user,
        uint256 _dispensedAmount,
        uint256 _tokenId
    );

    /// @notice This function is used to release matic to the holder of the provided tokenId
    /// @param _tokenId  The tokenId to claim matic for
    function claimMatic(uint256 _tokenId) external;

    /// @notice This function is used to release the carbon offset amount to the Cloud9 wallet, this amount can be released once per tokenId.
    /// @param _tokenId  The tokenId to release the carbon offset amount for
    function claimCarbonOffset(uint256 _tokenId) external;

    /// @notice This function allows the admin to withdraw the remaining matic amount, in-case of issues.
    function withdrawMatic() external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
interface IERC165Upgradeable {
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