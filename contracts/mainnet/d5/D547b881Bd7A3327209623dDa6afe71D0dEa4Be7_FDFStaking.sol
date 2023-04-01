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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IFDFERC20.sol";
import "./IFNFT.sol";
import "./IFSetting.sol";

abstract contract FDFIDO is Ownable{
    using SafeMath for uint256;

    uint256 constant private baseAmount = 100e6; //usdt
    uint256 constant private fdfPrice = 100e12;
    uint256 constant private baseInvites = 10;

    bool private IDOStop;
    bool private receiveStart;

    uint256 public nextNFTID;

    event Register(address user, address referral);
    event ReceiveNFT(address user, uint256 nftNums);
    event ReceiveToken(address user, uint256 amount);
    event BuyFDF(address user, uint256 amount);

    struct UserIDO {
        address referrer;
        uint256 amount;
        uint256 invites;
        uint256 inviteAmount;

        uint256 registers;
        uint256 nftNums;
        uint256 fdfAmount;
        bool nftReceived;
        bool fdfReceived;
    }

    struct IDOInfo {
        uint256 totalRegisterUser;
        uint256 totalIDOUser;
        uint256 totalAmount;
        uint256 totalNFTS;
        uint256 totalFDF;
        bool  IDOStop;
        bool receiveStart;
    }

    mapping(address => UserIDO) public userIDO;
    address[] public users;

    uint256 internal totalIDOUser;
    uint256 internal totalAmount;

    modifier onlyRegister() {
        require(userIDO[msg.sender].referrer != address(0), "req register");
        _;
    }

    address internal setting;

    constructor(address setting_) {
        require(setting_ != address(0),"setting is err");
        setting = setting_;
        IFSetting(setting).setInit(6,address(this));
    }

    function setSetting(address setting_) external onlyOwner{
        setting = setting_;
    }

    function setNextNFTID(uint256 _id) external onlyOwner {
        nextNFTID = _id;
    }

    function getUserIDO(address user_) public view returns(UserIDO memory) {
        UserIDO memory userIF = userIDO[user_];

        userIF.nftNums = userNFTNums(user_);
        userIF.fdfAmount = userReceiveFDF(user_);

        return userIF;
    }

    function getIDOInfo() public view returns(IDOInfo memory) {
        (uint256 nfts,uint256 fdfs) = totalNFTSFDFS();
        IDOInfo memory idoInfo =IDOInfo(users.length,totalIDOUser,
        totalAmount,nfts,fdfs,IDOStop,receiveStart);
        return idoInfo;
    }

    function register(address ref_) external  {
        require(msg.sender != getSetting().defaultRefer() &&
            userIDO[msg.sender].referrer == address(0) &&
            (userIDO[ref_].referrer != address(0) || ref_ == getSetting().defaultRefer()) &&
            msg.sender != ref_,"sender err");

        UserIDO storage user = userIDO[msg.sender];
        user.referrer = ref_;
        users.push(msg.sender);

        UserIDO storage userRefe = userIDO[ref_];
        userRefe.registers++;

        emit Register(msg.sender, ref_);
    }

    function buyFDF(uint256 amount) external onlyRegister {
        require(IDOStop, "ido stop");
        require(amount >0,"buyErr: buy amount zero");
        require(amount % baseAmount == 0, "buyErr: Non-integer");

        UserIDO storage user = userIDO[msg.sender];


        bool success = getUSDT().transferFrom(msg.sender,getSetting().usdtInAddr(),amount);
        require(success,"transferFrom failed");

        UserIDO storage refUser = userIDO[user.referrer];
        if (user.amount == 0) {
            refUser.invites = refUser.invites.add(1);
            totalIDOUser++;
        }
        user.amount = user.amount.add(amount);
        refUser.inviteAmount = refUser.inviteAmount.add(amount);
        totalAmount = totalAmount.add(amount);

        emit BuyFDF(msg.sender,amount);
    }

    function receiveNFT() external {
        require(!IDOStop && receiveStart, "off");

        UserIDO storage user = userIDO[msg.sender];
        uint256 nftNums = userNFTNums(msg.sender);
        require(nftNums > 0,"receiveNFT: user nftNums zero");
        user.nftReceived = true;

        for (uint256 i = 0; i < nftNums; i++) {
            IFNFT(IFSetting(setting).fnft()).safeTransferFrom(address(this),msg.sender,nextNFTID);
            nextNFTID = nextNFTID + 1;
        }
        emit ReceiveNFT(msg.sender,nftNums);
    }

    function totalNFTSFDFS() public view returns(uint256,uint256) {
        uint256 totalNFT;
        for (uint256 i; i < users.length; i++) {
            UserIDO memory user = userIDO[users[i]];
            if (user.amount >= baseAmount && user.invites >= baseInvites) {
                totalNFT = totalNFT.add( user.invites.div(baseInvites));
            }
        }
        uint256 totalFDF = totalAmount.mul(fdfPrice);
        return (totalNFT,totalFDF);
    }

    function receiveFDF() external {
        require(!IDOStop && receiveStart, "off");

        UserIDO storage user = userIDO[msg.sender];
        uint256 fdfAmount = userReceiveFDF(msg.sender);
        require(fdfAmount > 0,"receiveFDF: user fdf zero");
        user.fdfReceived = true;
        IFDFERC20(getSetting().fdf()).transfer(msg.sender,fdfAmount);

        emit ReceiveToken(msg.sender,fdfAmount);
    }

    function userReceiveFDF(address user_) public view returns(uint256) {
        UserIDO memory user = userIDO[user_];
        if (user.fdfReceived || user.amount < baseAmount) {
            return 0;
        }
        return user.amount.mul(fdfPrice);
    }

    function userNFTNums(address user_) public view returns(uint256) {
        UserIDO memory user = userIDO[user_];
        if (user.amount < baseAmount || user.invites < baseInvites || user.nftReceived) {
            return 0;
        }
        return user.invites.div(baseInvites);
    }

    function getUSDT() internal view returns(IFDFERC20) {
        return IFDFERC20(getSetting().usdt());
    }

    function getUSDTBalance() internal view returns(uint256) {
        return getUSDT().balanceOf(address(this));
    }

    function getSetting() internal view returns(IFSetting) {
        return IFSetting(setting);
    }

    function setIDOStop() external onlyOwner {
        IDOStop = !IDOStop;
    }

    function setReceiveStart() external onlyOwner {
        receiveStart = !receiveStart;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract FDFRisk {
    uint256 private constant riskBase = 1000e6;

    uint256 public riskLevelPre = 0;

    uint256 private risk70 = 70 * riskBase;
    uint256 private risk40 = 40 * riskBase;
    uint256 private risk100 = 100 * riskBase;
    uint256 private risk150 = 150 * riskBase;

    uint256 private risk200 = 200 * riskBase;
    uint256 private risk300 = 300 * riskBase;

    uint256 private risk500 = 500 * riskBase;
    uint256 private risk1000 = 1000 * riskBase;

    struct Risk {
        uint256 startTime;
        uint256 riskNum;
        uint256 riskPre;
        bool  riskFreeze;
        bool riskLevelNext;
    }

    Risk private risk;

    constructor(){

        risk = Risk(0,0,0,false,false);
    }

    function getRisk() public view returns(Risk memory) {
        return risk;
    }

    function updateRiskLevel(uint256 amount) internal {
        if (amount >= risk1000 && riskLevelPre == 2) {
            riskLevelPre = 3;
            risk.riskPre = 3;
        }
        if (amount >= risk500 && riskLevelPre == 1) {
            riskLevelPre = 2;
            risk.riskPre = 2;
        }
        if (amount >= risk100 && riskLevelPre == 0) {
            riskLevelPre = 1;
            risk.riskPre = 1;
        }

        if (riskLevelPre == 1) {
            if (amount >= risk150) {
                closeRisk();
                return;
            }
            if (amount < risk70 && amount >= risk40) {
                exeRiskLevel1();
            }
            if (amount < risk40) {
                exeRiskLevel2();
            }
        }

        if (riskLevelPre == 2) {
            if (amount >= risk500) {
                closeRisk();
                return;
            }
            if (amount < risk300 && amount >= risk150) {
                exeRiskLevel1();
            }
            if (amount < risk150) {
                exeRiskLevel2();
            }
        }

        if (riskLevelPre == 3) {
            if (amount >= risk1000) {
                closeRisk();
                return;
            }
            if (amount < risk500 && amount >= risk200) {
                exeRiskLevel1();
            }
            if (amount < risk200) {
                exeRiskLevel2();
            }
        }
    }

    function closeRisk() private {
        risk.riskLevelNext = false;
        risk.riskFreeze = false;
        risk.startTime = 0;
    }
    function exeRiskLevel1() private {
        if (risk.startTime == 0) {
            risk.startTime = block.timestamp;
        }
        if (!risk.riskFreeze && !risk.riskLevelNext) {
            risk.riskFreeze = true;
            risk.riskNum = risk.riskNum + 1;
        }
    }
    function exeRiskLevel2() private {
        if (risk.startTime == 0) {
            risk.startTime = block.timestamp;
        }
        if (!risk.riskLevelNext) {
            risk.riskFreeze = true;
            risk.riskLevelNext = true;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import "./FDFIDO.sol";
import "./FDFRisk.sol";
import "./IReceiveUSDT.sol";


contract FDFStaking is IReceiveUSDT,ERC721Holder,FDFIDO, FDFRisk{
    using SafeMath for uint256;

    uint private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'FDFStaking: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    uint256 private constant minDeposit = 100e6; //usdt

    uint256 private constant timeStep = 5760;
    uint256 private dayPerCycle = 15 * timeStep;
    uint256 private maxAddFreeze = 45 * timeStep;
    uint256 private constant referDepth = 15;

    uint256 private constant feePercents = 200;
    uint256 private constant poolPercents = 50;
    uint256 private constant marketPercents = 50;
    uint256 private constant staticPercents = 2250;
    uint256 private constant baseDivider = 10000;

    uint256 private constant realPercents = 70; // / 100
    uint256 private constant splitPercents = 30; // / 100
    uint256 private constant luckPercents = 10; // / 100
    uint256 private constant usdtFdfPercent = 2; // /100

    uint256[15] private invitePercents = [500, 100, 200, 300, 100, 100, 100, 100, 100, 100, 50, 50, 50, 50, 50];

    uint256[5] private levelMaxDeposit = [1000e6,2000e6,3000e6,4000e6,5000e6];
    uint256[5] private levelMinDeposit = [100e6,1000e6,2000e6,3000e6,4000e6];
    uint256[5] private levelTeam = [0, 2, 4, 10, 30];
    uint256[5] private levelInvite = [0, 1000e6, 2000e6, 10000e6, 20000e6];

    struct DisCfg {
        uint256   nftPoolPercent; //= 28; //  /100
        uint256   stakingPoolPercent; //= 72; //  /100
        uint256   baseTransfer; //= //100;

        uint256   ecoTotalPercentSwap; //= 125//; //  / 1000
        uint256   nftPoolPercentSwap; //= 250; //  /1000
        uint256   stakingPoolPercentSwap; //= 625; //  /1000
        uint256   baseSwap; //= 1000;
    }

    DisCfg private cfg;

    struct RewardInfo {
        uint256 freezeCapitals;
        uint256 capitals;
        uint256 riskCapitals;
        bool    isSplitUse;


        uint256 luck;

        uint256 level1;
        uint256 level24;

        uint256 unfreezeLevel510;
        uint256 freezeTotalLevel510;

        uint256 unfreezeLevel1115;
        uint256 freezeTotalLevel1115;

        uint256 transferSplit;

        uint256 debtWithdraw;
        uint256 debtSplit;
    }


    struct UserRewardInfo {
        uint256 totalCapitals;
        uint256 totalStatic;
        uint256 totalLevel1;
        uint256 totalLevel24;
        uint256 totalLevel510;
        uint256 totalLevel1115;
        uint256 totalLuck;
        uint256 totalFreeze;
        uint256 freezeSplit;
        uint256 totalRevenue;
        uint256 pendingSplit;
        uint256 pendingWithdraw;
    }

    struct UserInfo {
        address referrer;
        address addr;
        uint256 startTime;
        uint256 level;
        uint256 maxDeposit;
        uint256 totalHisDeposit;
        uint256 totalTeamDeposit;
        uint256 totalLevel16Deposit;
        uint256 riskNum;
        uint256 unfreezeIndex;

        uint256 teamNum;
        uint256 level1Nums;

        uint256 otherTeamDeposit;
        address maxTeamAddr;
        uint256 maxTeamDeposit;
    }

    struct OrderInfo {
        address addr;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        bool isUnFreeze;
    }

    struct SysInfo{
        uint256  nowDay;
        uint256  stakingPool;
        uint256  startTime;
        uint256  lastDay;
        uint256  lastTime;
        uint256  totalStakingUser;
        uint256  balance;
    }

    SysInfo private sysInfo;

    mapping(address => UserInfo) private userInfo;

    mapping(address=> OrderInfo[]) private orderInfos;

    mapping(address => RewardInfo) private rewardInfo;

    mapping(address => mapping(address => uint256[])) private freezeLevel515;

    mapping(uint256=>address[]) private dayLuckUsers;

    mapping(address => address[]) private downLevel1Users;

    OrderInfo[] private orders;

    event Deposit(address user, uint256 amount);
    event DepositBySplit(address user, uint256 amount);

    constructor(address setting_) FDFIDO(setting_) {
        cfg = DisCfg(28,72,100,125,250,625,1000);
        sysInfo.startTime = block.timestamp;
        sysInfo.lastTime = block.timestamp;

        _transferOwnership(IFSetting(setting).safeAdmin());
    }

    function deposit(uint256 _amount) external onlyRegister {
        require(_amount > 0,"zero amount");
        bool success = getUSDT().transferFrom(msg.sender, address(this), _amount);
        require(success,"transferFrom failed");

        _deposit(msg.sender, _amount);

        emit Deposit(msg.sender, _amount);
    }

    function depositBySplit(uint256 _amount) external onlyRegister {
        require(!rewardInfo[msg.sender].isSplitUse, "used split");

        rewardInfo[msg.sender].isSplitUse = true;

        require(_amount > 0,"zero amount");

        (uint256 pendingSplit,) = userPendingAmount(msg.sender);

        require(pendingSplit >= _amount,"insufficient integral");

        rewardInfo[msg.sender].debtSplit = rewardInfo[msg.sender].debtSplit.add(_amount);

        _deposit(msg.sender, _amount);

        emit DepositBySplit(msg.sender, _amount);
    }

    function withdraw() external lock {
        (,uint256 pendingAmount) = userPendingAmount(msg.sender);
        RewardInfo storage ri = rewardInfo[msg.sender];

        ri.debtWithdraw = ri.debtWithdraw.add(pendingAmount);
        getUSDT().transfer(msg.sender,pendingAmount);
    }

    function transferSplit(address to,uint256 _amount) external lock {
        require(_amount > 0,"zero amount");
        require(to != address(0),"addr is zero");

        RewardInfo storage ri = rewardInfo[msg.sender];
        (uint256 pendingSplit,) = userPendingAmount(msg.sender);
        uint256 newAmount = _amount.add(_amount.mul(luckPercents).div(100));
        require(pendingSplit >= newAmount,"insufficient integral");

        ri.debtSplit = ri.debtSplit.add(newAmount);
        rewardInfo[to].transferSplit = rewardInfo[to].transferSplit.add(_amount);
    }

    function distribute(bool isEco, uint256 amount) external {
        require(msg.sender == getSetting().fdf(),"req fdf");
        if (amount == 0) {
            return;
        }

        IERC20 usdt = getUSDT();

        address nftPoolAccount = getSetting().FNFTPool();

        uint256 ecoTotalAmount;
        uint256 nftPoolAmount;
        uint256 stakingPoolAmount;

        if (isEco) {
            ecoTotalAmount = amount.mul(cfg.ecoTotalPercentSwap).div(cfg.baseSwap);
            nftPoolAmount = amount.mul(cfg.nftPoolPercentSwap).div(cfg.baseSwap);
            stakingPoolAmount = amount.sub(ecoTotalAmount).sub(nftPoolAmount);
        }else {
            nftPoolAmount = amount.mul(cfg.nftPoolPercent).div(cfg.baseTransfer);
            stakingPoolAmount = amount.sub(nftPoolAmount);
        }

        if (stakingPoolAmount >0) {
           sysInfo.stakingPool = sysInfo.stakingPool.add(stakingPoolAmount);
           usdt.transfer(nftPoolAccount,nftPoolAmount);
        }

        if (ecoTotalAmount > 0) {
            address ecoSystemAccount = IFSetting(setting).getEcoSystemAccount();
            usdt.transfer(ecoSystemAccount,ecoTotalAmount);
        }
    }

    function _deposit(address _userAddr, uint256 _amount) private {

        uint256 burnAmount = _amount.mul(usdtFdfPercent).div(100);
        uint256 fdfAmount = getSetting().USDTToFDFAmount(burnAmount);
        IFDFERC20 fdf = IFDFERC20(getSetting().fdf());
        fdf.transferFrom(msg.sender,address(this),fdfAmount);
        fdf.burn(fdfAmount);

        UserInfo memory user = userInfo[_userAddr];

        require(_amount % minDeposit == 0 && _amount >= user.maxDeposit, "amount less or not mod");

        require(_amount >= levelMinDeposit[user.level] &&
            _amount <= levelMaxDeposit[user.level],"amount level err");

        _distributePoolRewards();

        _distributeAmount(_amount);

        _updateLuckUsers(msg.sender);

        (bool isUnFreeze, uint256 newAmount) = _unfreezeCapitalOrReward(msg.sender,_amount);

        _updateLevelReward(msg.sender,_amount,isUnFreeze);

        bool isNew = _updateUserInfo(_userAddr,_amount);

        _updateTeamInfos(msg.sender,newAmount,isNew);

        super.updateRiskLevel(getUSDTBalance());
    }

    function _distributeAmount(uint256 _amount) private {

        IFDFERC20 usdt = getUSDT();

        uint256 feeAmount = _amount.mul(feePercents).div(baseDivider);
        address feeReceiver = getSetting().getFeeReceiver();
        usdt.transfer(feeReceiver,feeAmount);

        uint256 marketAmount = _amount.mul(marketPercents).div(baseDivider);
        usdt.transfer(getSetting().marketReceiver(),marketAmount);

        uint256 poolAmount = _amount.mul(poolPercents).div(baseDivider);
        sysInfo.stakingPool = sysInfo.stakingPool.add(poolAmount);
    }

    function _updateLuckUsers(address account) private {
        uint256 nowDay = getCurDay();
        if (dayLuckUsers[nowDay].length < 10) {
            dayLuckUsers[nowDay].push(account);
        }
    }

    function _distributePoolRewards() private {
        uint256 nowDay = getCurDay();
        if (nowDay > sysInfo.lastDay && sysInfo.stakingPool > 0) {
            if (dayLuckUsers[sysInfo.lastDay].length > 0) {
                uint reward = sysInfo.stakingPool.div(dayLuckUsers[sysInfo.lastDay].length);
                for (uint256 i =0; i< dayLuckUsers[sysInfo.lastDay].length; i++) {
                    RewardInfo storage reInfo = rewardInfo[dayLuckUsers[sysInfo.lastDay][i]];
                    reInfo.luck = reInfo.luck.add(reward);
                }
            }
            sysInfo.lastDay = nowDay;
            sysInfo.lastTime = block.timestamp;
            sysInfo.stakingPool = 0;
        }
    }

    function _updateUserInfo(address _userAddr,uint256 _amount) private returns(bool){
        UserInfo storage user = userInfo[_userAddr];
        bool isNew;
        if(user.maxDeposit == 0) {
            user.startTime = block.timestamp;
            isNew = true;
            sysInfo.totalStakingUser++;
        }

        if (_amount > user.maxDeposit) {
            user.maxDeposit = _amount;
        }

        Risk memory risk = getRisk();

        if (risk.riskFreeze && !risk.riskLevelNext && user.riskNum < risk.riskPre) {
            user.riskNum = user.riskNum.add(1);
        }

        for (uint256 i = levelMinDeposit.length - 1; i >0; i--) {
            if (user.maxDeposit >= levelMinDeposit[i] &&
                user.teamNum >= levelTeam[i] &&
                user.maxTeamDeposit >= levelInvite[i] &&
                user.totalTeamDeposit.sub(user.maxTeamDeposit) >= levelInvite[i]) {

                if (user.level != i) {
                    user.level = i;
                }

                break;
            }
        }
        return isNew;
    }

    function _unfreezeCapitalOrReward(address _userAddr, uint256 _amount) private returns(bool isUnFreeze,uint256 newAmount) {

        RewardInfo storage ri = rewardInfo[_userAddr];
        uint256 addFreeze = dayPerCycle.add((orderInfos[_userAddr].length / 2).mul(timeStep));
        if(addFreeze > maxAddFreeze) {
            addFreeze = maxAddFreeze;
        }
        uint256 unfreezeTime = block.timestamp.add(addFreeze);
        OrderInfo memory orderIn = OrderInfo(_userAddr,_amount, block.timestamp, unfreezeTime, false);
        orderInfos[_userAddr].push(orderIn);
        orders.push(orderIn);
        ri.freezeCapitals = ri.freezeCapitals.add(_amount);

        if (orderInfos[_userAddr].length <= 1) {
            return (false, _amount);
        }

        UserInfo storage user = userInfo[_userAddr];
        OrderInfo storage order = orderInfos[_userAddr][user.unfreezeIndex];

        if (block.timestamp < order.endTime || order.isUnFreeze) {
            return (false, _amount);
        }

        order.isUnFreeze = true;
        user.unfreezeIndex = user.unfreezeIndex.add(1);

        ri.freezeCapitals = ri.freezeCapitals.sub(order.amount);
        newAmount = _amount.sub(order.amount);

        (,,bool isStaticRisk) = userTotalRevenue(_userAddr);
        if (!isStaticRisk) {
            ri.capitals = ri.capitals.add(order.amount);
        }else{
            ri.riskCapitals = ri.riskCapitals.add(order.amount);
        }

        return (true,newAmount);
    }

    function _updateLevelReward(address _userAddr, uint256 _amount, bool _isUnFreeze) private {
        for (uint256 i =0; i < referDepth; i++) {

            address upline = userIDO[_userAddr].referrer;
            if (upline == address(0)) {
                return;
            }

            if (orderInfos[upline].length == 0) {
                continue;
            }

            uint256 newAmount;
            OrderInfo memory latestUpOrder = orderInfos[upline][orderInfos[upline].length.sub(1)];
            uint256 maxFreezing = latestUpOrder.endTime > block.timestamp ? latestUpOrder.amount : 0;
            if(maxFreezing < _amount){
                newAmount = maxFreezing;
            }else{
                newAmount = _amount;
            }

            if (newAmount == 0) {
                continue;
            }

            _updateReward(_userAddr,upline,i,newAmount,_isUnFreeze);
        }
    }

    function _updateReward(address _userAddr,address upline,uint256 i, uint256 newAmount, bool _isUnFreeze) private {

        UserInfo memory upuser = userInfo[upline];

        (, bool isRisk,) = userTotalRevenue(upline);

        RewardInfo storage ri = rewardInfo[upline];

        uint256 reward = newAmount.mul(invitePercents[i]).div(baseDivider);
        if (i == 0) {
            if (!isRisk) {
                ri.level1 = ri.level1.add(reward);
            }
            return;
        }

        if (i < 4 && upuser.level >= i) {
            if (!isRisk) {
                ri.level24 = ri.level24.add(reward);
            }
            return;
        }

        if (upuser.level < 4) {
            return;
        }

        freezeLevel515[upline][_userAddr].push(reward);
        //4 5 6 7 8 9 -> (5,6,7,8,9,10)
        if (i <10) {
            ri.freezeTotalLevel510 = ri.freezeTotalLevel510.add(reward);
        }else{
            ri.freezeTotalLevel1115 = ri.freezeTotalLevel1115.add(reward);
        }

        if (_isUnFreeze) {
            uint256 len = freezeLevel515[upline][_userAddr].length;
            if (len >0) {
                uint256 freeAmount = freezeLevel515[upline][_userAddr][len - 1];
                if (i < 10) {
                    if (!isRisk) {
                        ri.unfreezeLevel510 = ri.unfreezeLevel510.add(freeAmount);
                    }
                    ri.freezeTotalLevel510 = ri.freezeTotalLevel510.sub(freeAmount);
                }else {
                    if (!isRisk) {
                        ri.unfreezeLevel1115 = ri.unfreezeLevel1115.add(freeAmount);
                    }
                    ri.freezeTotalLevel1115 = ri.freezeTotalLevel1115.sub(freeAmount);
                }
            }
        }
    }

    function _updateTeamInfos(address _userAddr, uint256 _amount, bool _isNew) private {

        if (_amount == 0) {
            return;
        }

        address downline = _userAddr;
        address upline = userIDO[_userAddr].referrer;
        if (upline == address(0)) return;
        address defaultRefer = getSetting().defaultRefer();

        if (_isNew) {
            userInfo[upline].level1Nums = userInfo[upline].level1Nums.add(1);
            downLevel1Users[upline].push(msg.sender);
        }

        for(uint256 i = 0; i < referDepth; i++) {
            UserInfo storage downUser = userInfo[downline];
            UserInfo storage upUser = userInfo[upline];

            if (_isNew) {
                upUser.teamNum = upUser.teamNum.add(1);
            }

            RewardInfo memory downReward = rewardInfo[downline];

            upUser.totalTeamDeposit = upUser.totalTeamDeposit.add(_amount);


            if (i == referDepth - 1) {
                upUser.totalLevel16Deposit = upUser.totalLevel16Deposit.add(_amount);
            }

            uint256 downTotalTeamDeposit = downReward.freezeCapitals.add(downUser.totalTeamDeposit);
            downTotalTeamDeposit = downTotalTeamDeposit.sub(downUser.totalLevel16Deposit);

            if (upUser.maxTeamAddr != downline) {
                if (upUser.maxTeamDeposit < downTotalTeamDeposit) {
                    upUser.maxTeamAddr = downline;
                    upUser.maxTeamDeposit = downTotalTeamDeposit;
                }
            }else {
                upUser.maxTeamDeposit = downTotalTeamDeposit;
            }

            for (uint256 lv = levelMinDeposit.length - 1; lv >0; lv--) {
                if (upUser.maxDeposit >= levelMinDeposit[lv] &&
                upUser.teamNum >= levelTeam[lv] &&
                upUser.maxTeamDeposit >= levelInvite[lv] &&
                    upUser.totalTeamDeposit.sub(upUser.maxTeamDeposit) >= levelInvite[lv]) {
                    if (upUser.level != lv) {
                        upUser.level = lv;
                    }
                    break;
                }
            }

            if(upline == defaultRefer) break;
            downline = upline;
            upline = userIDO[upline].referrer;
        }
    }

    function userPendingAmount(address _user) private view returns (uint256, uint256) {
        RewardInfo memory ri = rewardInfo[_user];

        (uint256 totalRevenue,,)= userTotalRevenue(_user);

        return (totalRevenue.mul(splitPercents).div(100).add(ri.transferSplit).sub(ri.debtSplit),
        ri.capitals.add(ri.riskCapitals).add(totalRevenue.mul(realPercents).div(100)).sub(ri.debtWithdraw));
    }

    function userTotalRevenue(address _userAddr) private view returns(uint256 totalRevenue,bool isRisk,bool isStaticRisk) {
        RewardInfo memory ri = rewardInfo[_userAddr];

        uint256 staticReward =  ri.capitals.mul(staticPercents).div(baseDivider);

        totalRevenue = staticReward.add(ri.level1).add(ri.level24)
        .add(ri.unfreezeLevel510).add(ri.unfreezeLevel1115).add(ri.luck);

        Risk memory risk = getRisk();

        UserInfo memory user = userInfo[_userAddr];

        if (!risk.riskFreeze || (risk.startTime != 0 && user.startTime > risk.startTime) ||
        totalRevenue < ri.freezeCapitals || (!risk.riskLevelNext && user.riskNum >= risk.riskNum && !risk.riskLevelNext)) {
            isRisk = false;
        }else {
            isRisk = true;
        }

        if (!risk.riskFreeze || (risk.startTime != 0 && user.startTime > risk.startTime) ||
        totalRevenue < ri.freezeCapitals) {
            isStaticRisk = false;
        }else {
            isStaticRisk = true;
        }

        return (totalRevenue, isRisk ,isStaticRisk);
    }

    function getCurDay() private view returns(uint256) {
        return (block.timestamp.sub(sysInfo.startTime)).div(timeStep);
    }

    function userRewardInfo(address _user) external view returns(UserRewardInfo memory) {
        RewardInfo memory ri = rewardInfo[_user];

        uint256 staticExpect = ri.freezeCapitals.mul(staticPercents).div(baseDivider);

        (uint256 totalRevenue,,)= userTotalRevenue(_user);
        (uint256 pendingSplit,uint256 pendingWithDraw) = userPendingAmount(_user);

        UserRewardInfo memory uri = UserRewardInfo(
            ri.capitals,
            ri.capitals.mul(staticPercents).div(baseDivider).mul(realPercents).div(100),
            ri.level1.mul(realPercents).div(100),
            ri.level24.mul(realPercents).div(100),
            ri.unfreezeLevel510.mul(realPercents).div(100),
            ri.unfreezeLevel1115.mul(realPercents).div(100),
            ri.luck.mul(realPercents).div(100),

            ri.freezeCapitals.add(staticExpect.add(
            ri.freezeTotalLevel510.add(ri.freezeTotalLevel1115)).mul(realPercents).div(100)),

            staticExpect.add(ri.freezeTotalLevel1115).add(ri.freezeTotalLevel510).mul(splitPercents).div(100),

            totalRevenue,
            pendingSplit,
            pendingWithDraw
        );

        return uri;
    }

    function userOrder(address _user,uint256 index) external view returns(OrderInfo memory) {
        return orderInfos[_user][index];
    }

    function userOrders(address _user) external view returns(OrderInfo[] memory) {
        return orderInfos[_user];
    }

    function userOrderLen(address _user) external view returns(uint256) {
        return orderInfos[_user].length;
    }

    function getOrders() external view returns(OrderInfo[] memory) {
        uint256 size;
        if (orders.length > 10) {
            size = 10;
        }else {
            size = orders.length;
        }

        OrderInfo[] memory ors = new OrderInfo[](size);
        for (uint256 i=0; i<size; i++) {
            ors[i] = orders[orders.length - i - 1];
        }
        return ors;
    }

    function downLevel1UserAddrs(address _user) external view returns(address[] memory) {
        return downLevel1Users[_user];
    }

    function userDownLevel1(address _user,uint256 _start,uint256 _nums) external view returns(UserInfo[] memory)  {
        UserInfo[] memory userIn = new  UserInfo[](_nums);
        for (uint256 i = 0; i < _nums; i++) {
            address addr = downLevel1Users[_user][i+_start];
            userIn[i] = userInfoPer(addr);
        }
        return userIn;
    }

    function userInfoPer(address _user) public view returns(UserInfo memory) {
        UserInfo memory user = userInfo[_user];
        RewardInfo memory ri = rewardInfo[_user];

        user.otherTeamDeposit = user.totalTeamDeposit.sub(user.maxTeamDeposit);

        user.totalTeamDeposit = ri.freezeCapitals.add(user.totalTeamDeposit);
        user.addr = _user;
        user.referrer = userIDO[_user].referrer;
        user.totalHisDeposit = ri.freezeCapitals.add(ri.capitals).add(ri.riskCapitals);

        return user;
    }

    function dayLuckUserAddrs(uint256 _nowDay) external view returns(address[] memory) {
        return dayLuckUsers[_nowDay];
    }

    function getSysInfo() external view returns(SysInfo memory) {
        SysInfo memory sys = sysInfo;
        sys.nowDay = getCurDay();
        sys.balance = getUSDTBalance();
        return sys;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFDFERC20 is IERC20{
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IFNFT is IERC721 {
    function totalSupply() external view returns (uint256);
    function startTokenId() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFSetting {
    function setInit(uint256 index,address addr) external;
    function usdt() external view returns(address);
    function fnft() external view returns(address);
    function fdf() external view returns(address);
    function pairAddr() external view returns(address);
    function bento() external view returns(address);
    function getLPPool() external view returns(address);
    function getPath2() external view returns(address[] memory);
    function routerAddr() external view returns(address);
    function FDFStaking() external view returns(address);
    function FNFTPool() external view returns(address);
    function mintOwner() external view returns(address);
    function safeAdmin() external view returns(address);
    function defaultRefer() external view returns(address);
    function usdtInAddr() external view returns(address);
    function marketReceiver() external view returns(address);
    function isExcluded(address ex_) external view returns(bool);
    function isTaxExcluded(address tax_) external view returns(bool);
    function getFeeReceiver() external view returns(address);
    function getEcoSystemAccount() external view returns(address);
    function USDTToFDFAmount(uint256 _amount) external view returns(uint256);
    function FDFToUSDTAmount(uint256 _amount) external view returns(uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IReceiveUSDT {
    function distribute(bool isEco, uint256 amount) external;
}