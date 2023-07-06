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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ERC20Purchase, EthPurchase } from "./marketplace/MarketplaceStructs.sol";
import "./marketplace/Signatures/ERC20Signature.sol";
import "./marketplace/Signatures/EthSignature.sol";


contract LisMarketplace is Ownable, ERC20Signature, EthSignature {
    using SafeMath for uint256;

    address public adminBuyer;
    address public admin;
    address payable public feeReceiver;
    /**
     * @dev Stores fee percents of nft contracts: fees[nftContract][fee]
     */
    mapping(address => uint256) public fees;

    /**
     * @dev Stores listed nft prices: tokensPrices[nftContract][token][tokenId]
     */
    mapping(address => mapping(address => mapping(uint256 => uint256))) public tokensPrices;

    event Purchase(address indexed seller, address indexed buyer, address nftContract, uint256 tokenId, address currency, uint256 indexed fee, uint256 price);
    event List(address indexed seller, address indexed nftContract, uint256 indexed tokenId, address currency, uint256 price);
    event Unlist(address indexed nftContract, address indexed currency, uint256 indexed tokenId);
    event FeeSet(address indexed token, uint256 indexed fee);

    constructor(address _adminBuyer, address payable _feeReceiver) {
        setAdminBuyer(_adminBuyer);
        setFeeReceiver(_feeReceiver);
    }

    function setFeeReceiver(address payable _feeReceiver) public onlyOwner {
        feeReceiver = _feeReceiver;
    }

    /** @notice Admin - wallet which can unlist tokens from marketplace
     * 
     */
    function setAdmin(address newAdmin) external onlyOwner {
        admin = newAdmin;
    }

    /**
     * @dev Set fee on every purchase on nft contract.
     */
    function setFee(address nftContract, uint256 fee) external onlyOwner {
        fees[nftContract] = fee;
        emit FeeSet(nftContract, fee);
    }

    function setAdminBuyer(address newBuyer) public onlyOwner {
        adminBuyer = newBuyer;
    }

    function placeOnMarketplace(address nftContract, address token, uint256 tokenId, uint256 price) external {
        IERC721 erc721 = IERC721(nftContract);
        require(
            erc721.getApproved(tokenId) == address(this),
            "Contract must be approved for nft transfer."
        );
        tokensPrices[nftContract][token][tokenId] = price;    
        emit List(msg.sender, nftContract, tokenId, token, price);
    }

    function unlistFromMarketplace(address nftContract, address token, uint256 tokenId) external {
        IERC721 erc721 = IERC721(nftContract);
        require(
            msg.sender == admin || erc721.ownerOf(tokenId) == msg.sender,
            "Invalid sender."
            );
        tokensPrices[nftContract][token][tokenId] = 0;
        emit Unlist(nftContract, token, tokenId);
    }

    function purchaseByERC20(ERC20Purchase calldata args) external {
        _purchaseByERC20(args, msg.sender, msg.sender);
    }

    function _purchaseByERC20(ERC20Purchase calldata args, address buyer, address receiver) private {
        require(tokensPrices[args.nftContract][args.token][args.tokenId] > 0, "This token is not supported for purchase.");
        IERC20 erc20 = IERC20(args.token);
        require(
            erc20.allowance(buyer, address(this)) >= tokensPrices[args.nftContract][args.token][args.tokenId],
            "Insufficient allowance."
        );
        require(
            erc20.balanceOf(buyer) >= tokensPrices[args.nftContract][args.token][args.tokenId],
            "Insufficient balance."
        );
        erc20.transferFrom(buyer, address(this), tokensPrices[args.nftContract][args.token][args.tokenId]);
        IERC721 erc721 = IERC721(args.nftContract);
        address seller = erc721.ownerOf(args.tokenId);
        erc721.transferFrom(seller, receiver, args.tokenId);
        uint256 fee = tokensPrices[args.nftContract][args.token][args.tokenId].mul(fees[args.nftContract]).div(100);
        erc20.transfer(feeReceiver, fee);
        erc20.transfer(seller, tokensPrices[args.nftContract][args.token][args.tokenId].sub(fee));
        emit Purchase(
            seller,
            receiver,
            args.nftContract,
            args.tokenId,
            args.token,
            fee,
            tokensPrices[args.nftContract][args.token][args.tokenId]
        );
        tokensPrices[args.nftContract][args.token][args.tokenId] = 0;
    }

    function purchaseByEth(EthPurchase calldata args) external payable {
        _purchaseByEth(args, msg.sender);
    }

    function _purchaseByEth(EthPurchase calldata args, address receiver) private {
        require(tokensPrices[args.nftContract][address(0)][args.tokenId] > 0, "This token is not supported for purchase.");
        require(msg.value == tokensPrices[args.nftContract][address(0)][args.tokenId], "Wrong amount sent.");
        IERC721 erc721 = IERC721(args.nftContract);
        address payable seller = payable(erc721.ownerOf(args.tokenId));
        erc721.transferFrom(seller, receiver, args.tokenId);
        uint256 fee = tokensPrices[args.nftContract][address(0)][args.tokenId].mul(fees[args.nftContract]).div(100);
        feeReceiver.transfer(fee);
        seller.transfer(msg.value.sub(fee));
        emit Purchase(
            seller,
            receiver,
            args.nftContract,
            args.tokenId,
            address(0),
            fee,
            tokensPrices[args.nftContract][address(0)][args.tokenId]
        );
        tokensPrices[args.nftContract][address(0)][args.tokenId] = 0;
    }

    /**
     * @dev Using for pay for purchase for another wallet by ERC20 tokens.
     *
     * @param args The arguments struct.
     * @param signature Signature from wallet 'buyer', who need to be payed for.
     * @param receiver Address of wallet who need to be payed for.
     */
    function purchaseByERC20WithSignature(ERC20Purchase calldata args, bytes memory signature, address receiver) external {
        require(msg.sender == adminBuyer, "Invalid sender.");
        require(verifySignatureERC20(args, signature, receiver), "Invalid signature.");
        _purchaseByERC20(args, msg.sender, receiver);
    }

    /**
     * @dev Using for pay for purchase for another wallet by ETH.
     *
     * @param args The arguments struct.
     * @param signature Signature from wallet 'buyer', who need to be payed for.
     * @param receiver Address of wallet who need to be payed for.
     */
    function purchaseByEthWithSignature(EthPurchase calldata args, bytes memory signature, address receiver) external payable {
        require(msg.sender == adminBuyer, "Invalid sender.");
        require(verifySignatureEth(args, signature, receiver), "Invalid signature.");
        _purchaseByEth(args, receiver);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @notice A struct defining arguments of purchaseByERC20.
 *         Designed to fit efficiently in one storage slot.
 * 
 * @param nftContract Address of nft contract
 * @param token Address of purchase currency: erc20 token or zero address if eth.
 * @param tokenId Id of nft from nftContract
 */
struct ERC20Purchase {
    address nftContract;
    address token;
    uint256 tokenId;
}

/**
 * @notice A struct defining arguments of purchaseByEth.
 *         Designed to fit efficiently in one storage slot.
 * 
 * @param nftContract Address of nft contract
 * @param tokenId Id of nft from nftContract
 */
struct EthPurchase {
    address nftContract;
    uint256 tokenId;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20Purchase } from "../MarketplaceStructs.sol";
import "./SignatureBase.sol";

contract ERC20Signature is SignatureBase {

    function verifySignatureERC20(
        ERC20Purchase calldata args,
        bytes memory signature,
        address receiver
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHashERC20(args);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == receiver;
    }

    function getMessageHashERC20(ERC20Purchase calldata args)
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                args.nftContract,
                args.token,
                args.tokenId
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { EthPurchase } from "../MarketplaceStructs.sol";
import "./SignatureBase.sol";

contract EthSignature is SignatureBase {
    function verifySignatureEth(
        EthPurchase calldata args,
        bytes memory signature,
        address receiver
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHashETH(args);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == receiver;
    }

    function getMessageHashETH(EthPurchase calldata args)
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                args.nftContract,
                args.tokenId
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SignatureBase {
    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public virtual pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) public virtual pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function getEthSignedMessageHash(bytes32 messageHash)
        internal
        virtual
        pure
        returns (bytes32)
    {
        bytes32 ethMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        return ethMessageHash;
    }
}