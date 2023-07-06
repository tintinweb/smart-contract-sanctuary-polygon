// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Setting.sol";
import "./IZBC.sol";

interface IZBCNFT {
    function totalSupply() external view returns (uint256);
}

contract ZBCNFTPool is Setting {
    using SafeMath for uint256;

    uint private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'FDFStaking: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    struct UserInfo {
        address addr;
        uint256 nftNums;
        uint256 bonus;
        bool isPooler;
    }
    uint256 private settleTotal;
    uint256 private debtTotal;

    uint256 private constant timeStep = 60 * 60;

    mapping(address => UserInfo) private users;
    address[] private userArr;

    uint256 public constant ZBCBalance = 100000e18;
    uint256 public constant ZBCMarketValueUSDT = 1000e6;

    struct Sys {
        uint256  totalNFT;
        uint256  amount;
        uint256  startTime;
        uint256  lastTime;
        uint256  nextTime;
        uint256  balanceUSDT;
    }

    Sys private sys;

    event WithdrawToken(address _user,uint256 amount);
    event DistributePoolRewards(uint256 day, uint256 time);

    constructor() {
        sys.startTime = block.timestamp;
        sys.lastTime = sys.startTime;
    }

    function withdrawToken() external lock {
        updatePool();
        UserInfo storage userInfo = users[msg.sender];
        uint256 amountWith = userInfo.bonus;
        debtTotal += amountWith;
        userInfo.bonus = 0;
        IERC20(sysAddr.usdt).transfer(msg.sender,amountWith);
        emit WithdrawToken(msg.sender,amountWith);
    }

    function withdrawBySafe(address addr,address to) external {
        require(msg.sender == sysAddr.mutual,"not safe");
        updatePool();
        UserInfo storage userInfo = users[addr];
        uint256 amountWith = userInfo.bonus;
        if (amountWith == 0) {
            return;
        }
        debtTotal += amountWith;
        userInfo.bonus = 0;
        IERC20(sysAddr.usdt).transfer(to,amountWith);
        emit WithdrawToken(addr,amountWith);
    }

    function updateUserNFT(address from, address to) external {

        updatePool();

        if (from != address(0)) {
            users[from].nftNums = IERC721(sysAddr.nft).balanceOf(from);
            _add(from);
            _remove(from);
        }
        if (to != address(0)) {
            users[to].nftNums = IERC721(sysAddr.nft).balanceOf(to);
            _add(to);
            _remove(to);
        }

        if (from == address(0)) {
            sys.totalNFT = IZBCNFT(sysAddr.nft).totalSupply();
        }
    }

    function _add(address addr) private {
        if (users[addr].nftNums == 0) {
            return;
        }
        (bool isExit,) = findArrAddr(userArr,addr);
        if (!isExit) {
            userArr.push(addr);
        }
    }
    function _remove(address addr) private {
        if (users[addr].nftNums > 0) {
            return;
        }
        (bool isExit,uint256 index) = findArrAddr(userArr,addr);
        if (isExit) {
            userArr[index] = userArr[userArr.length - 1];
            userArr.pop();
        }
    }

    function updatePool() public {
        (uint256 avgAmount,uint256 lastTime,uint256 pendingAmount,UserInfo[] memory userInfos) = _pendingAvgAmount();
        if (sys.lastTime == lastTime) {
            return;
        }
        sys.lastTime = lastTime;
        if (avgAmount > 0) {
            settleTotal = settleTotal.add(pendingAmount);
            for (uint256 i = 0; i < userInfos.length; i++) {
                if (userInfos[i].addr == address(0) || userInfos[i].nftNums == 0 || !userInfos[i].isPooler) {
                    continue;
                }
                users[userInfos[i].addr].bonus += avgAmount.mul(userInfos[i].nftNums);
            }
        }
    }

    function _pendingAvgAmount() private view returns(uint256 avgAmount,uint256 lastTime,uint256 pendingAmount,UserInfo[] memory userInfos) {
        lastTime = getLastTime(sys.startTime,block.timestamp);
        if (sys.lastTime == lastTime) {
            return (0,lastTime,0,userInfos);
        }

        uint256 total = 0;
        userInfos = new UserInfo[](userArr.length);
        for (uint i=0; i<userArr.length; i++) {
            (bool isL, uint256 numsN) = _isLender(userArr[i]);
            if (!isL) {
                continue;
            }
            userInfos[i].isPooler = true;
            userInfos[i].addr = userArr[i];
            userInfos[i].nftNums = numsN;
            total += numsN;
        }

        uint256 balance = IERC20(sysAddr.usdt).balanceOf(address(this));
        pendingAmount = balance.add(debtTotal).sub(settleTotal);

        if (balance == 0 || total == 0) {
            return(0,lastTime,0,userInfos);
        }

        return (pendingAmount.div(total), lastTime, pendingAmount, userInfos);
    }

    function _isLender(address addr) private view returns(bool,uint256) {
        if (addr == address(0)) {
            return (false,0);
        }
        uint256 zbcNFT = IZBC(sysAddr.nft).balanceOf(addr);
        if (zbcNFT == 0) {
            return (false,0);
        }
        uint256 zbcAmt = IZBC(sysAddr.zbc).balanceOf(addr);
        if (zbcAmt < ZBCBalance) {
            return (false,0);
        }
        uint256 zbcMarketAmt = ZBCATOUSDTmount(zbcAmt);
        if (zbcMarketAmt < ZBCMarketValueUSDT) {
            return (false,0);
        }
        uint256 nums = zbcMarketAmt / ZBCMarketValueUSDT;

        return (true, nums > zbcNFT ? zbcNFT : nums);
    }

    function pendingReward(address addr) external view returns(uint256) {
        (uint256 avgAmount,,,UserInfo[] memory userInfos) = _pendingAvgAmount();
        for (uint i=0; i<userInfos.length; i++) {
            if (userInfos[i].addr == addr) {
                return users[addr].bonus.add(avgAmount.mul(userInfos[i].nftNums));
            }
        }
        return users[addr].bonus;
    }

    function ZBCATOUSDTmount(uint256 _amount) public view returns(uint256){
        address[] memory path = new address[](2);
        path[0] = sysAddr.zbc;
        path[1] = sysAddr.usdt;
        return IZBC(sysAddr.v2Router).getAmountsOut(_amount,path)[1];
    }

    function getLastTime(uint256 startTime,uint256 nowTime) public pure returns(uint256) {
        return (nowTime - startTime) / timeStep * timeStep + startTime;
    }

    function getSys() public view returns(Sys memory) {
        Sys memory sy = sys;
        sy.nextTime = getLastTime(sy.startTime,block.timestamp) + timeStep;
        uint256 balance = IERC20(sysAddr.usdt).balanceOf(address(this));
        (,,uint256 pendingAmount,) = _pendingAvgAmount();
        sy.balanceUSDT = balance.add(debtTotal).sub(settleTotal).sub(pendingAmount);
        return sy;
    }

    function getUser(address addr) external view returns(UserInfo memory) {
        return users[addr];
    }

    function findArrAddr(
        address[] memory arr,
        address addr
    ) private pure returns (bool,uint256) {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == addr) {
                return (true,i);
            }
        }
        return (false,0);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IZBC {
    function burnFrom(address from,uint256 amount) external;
    function getAmountsOut( uint256 amountIn,address[] memory path ) external view returns (uint256[] memory amounts);
    function balanceOf(address owner) external view returns (uint256 balance);
    function withdraw(address token, address to, uint256 amount) external;
    function mintOfOwner(address addr, uint256 amount) external;

    function withdrawBySafe(address addr,address to) external;
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