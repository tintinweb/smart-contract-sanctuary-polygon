//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC721.sol";
import "Ownable.sol";

/**
    @title BlockMail Contract
    @author Francis Egboluche
    @notice A contract for sending and receiving mails on a public data network like IPFS
 */
contract BlockMail is Ownable {
    //state variables
    uint256 public blockMailFeeAmount;
    uint256 public mailId;
    struct blockMail {
        uint256 mailId;
        string message;
        address receiver;
        uint256 nativeAsset;
        address token;
        uint256 tokenAmount;
        address nftContract;
        uint256 tokenId;
    }

    mapping(address => mapping(address => bool)) public allowedMailers;
    mapping(uint256 => address) public mailIdToAddress;

    //events
    event MailSent(
        uint256 indexed mailID,
        string message,
        string title,
        address indexed receiver,
        address from,
        uint256 nativeAsset,
        address token,
        uint256 tokenAmount,
        address nftContract,
        uint256 tokenId
    );
    //MailSent(uint256,string,address,uint256,address,uint256,address,uint256);

    //ERRORS
    error BlockMail__NotAllowedToMailUser();
    error BlockMail__InsufficientFeeAmount();
    error BlockMail__FailedToSendNativeAsset();

    /**
        @notice initializes the pricefeed for matic/usd via chainlink data feeds
        @dev To avoid scenarios where price of matic increases an users pay higher
        @param _blockMailFeeAmount fee amount in usd (18 decimals)
        @param _priceFeedAddress pricefeed address from chainlink for network
     */

    //external fuctions

    /**
        @notice For sending mails with values from on user to another e.g tokens and nfts.
        @dev checks if all those values exists to decide what event to emit.
        @param _message Encrypted Message Link on a distributed storage system like IPFS.
        @param _title Title for message.
        @param _receiver The receiver of the mail and the tokens and nfts if exists.
        @param _token The token address for the erc20 token user wishes to send user.
        @param _tokenAmount The token amount for the erc20 token specified by user
        @param _nftContract The contract address for the NFT specified by user
        @param _tokenId The token Id for the nft contract address
     */
    function sendBlockMail(
        string memory _message,
        string memory _title,
        address _receiver,
        address _token,
        uint256 _tokenAmount,
        address _nftContract,
        uint256 _tokenId
    ) external payable {
        require(allowedToSendMail(_receiver), "Not allowed to mail user");
        //send native asset if there is any
        mailId++;
        if (msg.value > 0) {
            (bool success, ) = _receiver.call{value: msg.value}("");
            if (!success) {
                revert BlockMail__FailedToSendNativeAsset();
            }
        }
        //only when theres a token and amount you should send
        if (_token != address(0) && _tokenAmount > 0) {
            IERC20(_token).transferFrom(msg.sender, _receiver, _tokenAmount);
        }
        //if theres an nft also send!
        if (_nftContract != address(0)) {
            IERC721(_nftContract).transferFrom(msg.sender, _receiver, _tokenId);
        }
        mailIdToAddress[mailId] = _receiver;
        emit MailSent(
            mailId,
            _message,
            _title,
            _receiver,
            msg.sender,
            msg.value,
            _token,
            _tokenAmount,
            _nftContract,
            _tokenId
        );
    }

    /**
        @notice allows an address to send mail to the user.
        @dev A nice way of making a contacts list to avoid spamming.
        @param _addressToAllow The address the user wishes to receive mails from
     */
    function allowSender(address _addressToAllow) external {
        allowedMailers[msg.sender][_addressToAllow] = true;
    }

    /**
        @notice disallows an address from sending auser mail
        @dev Incase a user decides to no longer see mails from a user.
        @param _addressToDisallow The address the user wishes to stop receiving mails from
     */
    function disallowSender(address _addressToDisallow) external {
        allowedMailers[msg.sender][_addressToDisallow] = false;
    }

    /**
        @notice checks if a certain user is allowed to mail another user
        @param receiver the user being mailed.
        @return bool returns true or false
     */
    function allowedToSendMail(address receiver) private view returns (bool) {
        if (allowedMailers[receiver][msg.sender]) {
            return true;
        } else {
            return false;
        }
    }

    /**
        @notice fucntion for lit protocol to ascertain if the user can decrypt a message
        @param _mailId the user being mailed.
        @param _addressForMailId the address of the user trying to decrypt.
        @return bool returns true or false
     */
    function canUserDecrypt(uint256 _mailId, address _addressForMailId)
        public
        view
        returns (bool)
    {
        if (mailIdToAddress[_mailId] == _addressForMailId) {
            return true;
        } else {
            return false;
        }
    }

    /**
        @notice fucntion for lit protocol to ascertain if the user can decrypt a message
        @return mailId returns the current mail count
     */
    function getMailId() public view returns (uint256) {
        return mailId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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