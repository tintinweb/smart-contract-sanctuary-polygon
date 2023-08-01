// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Setting.sol";

interface IReceive {
    function mint(address to, uint256 tokenId) external;
}

interface IRegister {
    function registerFromIDO(address addr, address ref_) external;
}

contract ZBCIDO is Setting{
    using SafeMath for uint256;

    uint256 constant private baseAmount = 100e6; //usdt
    uint256 constant private zbcPrice = 100e12;
    uint256 constant private baseInvites = 10;

    address public defaultRefer = 0x4D32377062C7b9EF92F4B54E5600f30c8A295fec;

    event Register(address user, address referral);
    event ReceiveNFT(address user, uint256 nftNums);
    event ReceiveToken(address user, uint256 amount);
    event Buy(address user, uint256 amount);

    struct UserIDO {
        address addr;
        address referrer;
        uint256 amount;
        uint256 invites;
        uint256 inviteAmount;

        uint256 nftNums;
        uint256 zbcAmount;
    }

    struct Sys {
        uint256 totalIDOUser;
        uint256 totalAmount;
        uint256 totalNFTS;
        uint256 nextNFTID;
        uint256 totalZBC;
        bool  IDOStop;
        bool receiveStart;
        address usdtInAddr;
        address defualtRefer;
    }

    Sys private sys;

    mapping(address => UserIDO) private userIDO;

    mapping(address => address[]) private refAddrs;

    modifier onlyRegister() {
        require(userIDO[msg.sender].addr == msg.sender, "req register");
        _;
    }

    constructor() {
        sys.defualtRefer = defaultRefer;
        sys.usdtInAddr = 0x8552cF4c9fc08586E72033284d16B6b03a7AB2c7;
    }

    function setIDOStop(bool stop_) external {
        require(msg.sender == sysAddr.admin, "ZBC: admin");
        sys.IDOStop = stop_;
    }
    function setReceiveStart(bool start_) external {
        require(msg.sender == sysAddr.admin, "ZBC: admin");
        sys.receiveStart = start_;
    }

    function register(address ref_) external  {
        require(msg.sender != defaultRefer &&
        userIDO[msg.sender].referrer == address(0) &&
        (userIDO[ref_].referrer != address(0) || ref_ == defaultRefer) &&
        msg.sender != ref_,"sender err");

        IRegister(sysAddr.mutual).registerFromIDO(msg.sender,ref_);

        UserIDO storage user = userIDO[msg.sender];
        user.addr = msg.sender;
        user.referrer = ref_;
        refAddrs[ref_].push(msg.sender);

        emit Register(msg.sender, ref_);
    }

    function buy() external onlyRegister{
        require(!sys.IDOStop, "ido stop");
        UserIDO storage user = userIDO[msg.sender];
        require(user.amount == 0, "Already buy");

        bool success = IERC20(sysAddr.usdt).transferFrom(msg.sender, sys.usdtInAddr, baseAmount);
        require(success, "transferFrom err");

        UserIDO storage refUser = userIDO[user.referrer];
        refUser.invites = refUser.invites.add(1);
        sys.totalIDOUser++;

        user.zbcAmount = baseAmount.mul(zbcPrice);
        user.amount = baseAmount;

        refUser.inviteAmount = refUser.inviteAmount.add(baseAmount);
        sys.totalAmount = sys.totalAmount.add(baseAmount);

        if (sys.totalNFTS < 200) {
            uint256 pendingNums = _userNFTNums(refUser.addr);
            if (pendingNums > refUser.nftNums) {
                refUser.nftNums = pendingNums;
                sys.totalNFTS++;
            }
        }
        emit Buy(msg.sender,baseAmount);
    }

    function receiveNFT() external {
        UserIDO storage user = userIDO[msg.sender];
        require(sys.IDOStop && sys.receiveStart, "off");
        require(user.nftNums > 0,"receiveNFT: user nftNums zero");

        uint256 nftNums = user.nftNums;
        user.nftNums = 0;
        for (uint256 i = 0; i < nftNums; i++) {
            IReceive(sysAddr.nft).mint(msg.sender, sys.nextNFTID);
            sys.nextNFTID++;
        }
        emit ReceiveNFT(msg.sender,nftNums);
    }

    function receiveZBC() external {
        UserIDO storage user = userIDO[msg.sender];
        require(sys.IDOStop && sys.receiveStart, "off");
        require(user.zbcAmount > 0,"receiveZBC: user zbcAmount zero");

        uint256 zbcAmount = user.zbcAmount;
        user.zbcAmount = 0;

        IReceive(sysAddr.zbc).mint(msg.sender, zbcAmount);
    }

    function getSys() external view returns(Sys memory) {
        return sys;
    }

    function getUser(address user_) external view returns(UserIDO memory) {
        UserIDO memory ui = userIDO[user_];
        return ui;
    }

    function _userNFTNums(address user_) private view returns(uint256) {
        UserIDO memory user = userIDO[user_];
        if (user.amount < baseAmount || user.invites < baseInvites) {
            return 0;
        }
        return user.invites.div(baseInvites);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ISetting.sol";

contract Setting is ISetting {
    /**
   * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        require(msg.sender == sysAddr.admin, "Admin: caller is not the admin");
        _;
    }

    struct SysAddr {
        address admin;
        address ido;
        address nftPool;
        address v2Router;
        address mutual;
        address zbc;
        address nft;
        address usdt;
    }
    SysAddr internal sysAddr;

    constructor(){
    }

    function setAdmin(address admin_) external {
        if (sysAddr.admin == address(0)) {
            sysAddr.admin = admin_;
        } else {
            require(msg.sender == sysAddr.admin, "ZBC: admin");
            sysAddr.admin = admin_;
        }
    }
    function setNFTPool(address nftPool_) external onlyAdmin {
        sysAddr.nftPool = nftPool_;
    }
    function setIDO(address ido_) external onlyAdmin {
        sysAddr.ido = ido_;
    }
    function setV2Router(address v2Router_) external onlyAdmin {
        sysAddr.v2Router = v2Router_;
    }
    function setMutual(address mutual_) external onlyAdmin {
        sysAddr.mutual = mutual_;
    }
    function setZBC(address zbc_) external onlyAdmin {
        sysAddr.zbc = zbc_;
    }
    function setNFT(address nft_) external onlyAdmin {
        sysAddr.nft = nft_;
    }
    function setUSDT(address usdt_) external onlyAdmin {
        sysAddr.usdt = usdt_;
    }

    function getSysAddrs() external view returns (SysAddr memory) {
        return sysAddr;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISetting {
    function setAdmin(address admin_) external;
    function setNFTPool(address nftPool_) external;
    function setIDO(address ido_) external;
    function setV2Router(address v2Router_) external;
    function setMutual(address mutual_) external;
    function setZBC(address zbc_) external;
    function setNFT(address nft_) external;
    function setUSDT(address usdt_) external;
}