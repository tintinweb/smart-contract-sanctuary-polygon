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
pragma solidity ^0.8.9;

import "../library/Structures.sol";
import "../modules/Events.sol";
import "../modules/Creation.sol";
import "../modules/Acceptance.sol";
import "../modules/Submission.sol";
import "../modules/Finalization.sol";
import "../modules/Renounce.sol";

import "../modules/Data.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract MecenateFeed is
    Ownable,
    Data,
    Creation,
    Acceptance,
    Renounce,
    Submission,
    Finalization
{
    using Structures for Structures.Post;

    constructor(
        address owner,
        address _usersModuleContract,
        address _identityContract
    ) Data(_usersModuleContract, _identityContract) {
        _transferOwnership(owner);
    }

    function getSeller() public view returns (address) {
        return post.postdata.settings.seller;
    }

    function getBuyer() public view returns (address) {
        return post.postdata.settings.buyer;
    }

    function getBuyerPayment() public view returns (uint256) {
        return post.postdata.escrow.payment;
    }

    function getSellerStake() public view returns (uint256) {
        return post.postdata.escrow.stake;
    }

    function getPostStatus() public view returns (Structures.PostStatus) {
        return post.postdata.settings.status;
    }

    function getPostCount() public view returns (uint256) {
        return postCount;
    }

    function changeUsersModuleContract(
        address _usersModuleContract
    ) external onlyOwner {
        usersModuleContract = _usersModuleContract;
    }

    function changeIdentityContract(
        address _identityContract
    ) external onlyOwner {
        identityContract = _identityContract;
    }
}

pragma solidity 0.8.19;

interface IMecenateFactory {
    function owner() external view returns (address payable);

    function treasuryContract() external view returns (address payable);

    function identityContract() external view returns (address);

    function contractCounter() external view returns (uint256);
}

pragma solidity 0.8.19;

interface IMecenateIdentity {
    function identityByAddress(address user) external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    function getTotalIdentities() external view returns (uint256);

    function getOwnerById(uint256 tokenId) external view returns (address);
}

pragma solidity 0.8.19;

interface IMecenateTreasury {
    function globalFee() external view returns (uint256);

    function fixedFee() external view returns (uint256);
}

pragma solidity 0.8.19;
import "../library/Structures.sol";

interface IMecenateUsers {
    function checkifUserExist(address user) external view returns (bool);

    function getUserData(
        address user
    ) external view returns (Structures.User memory);

    function getUserCount() external view returns (uint256);
}

pragma solidity 0.8.19;

library Structures {
    enum PostStatus {
        Waiting,
        Proposed,
        Accepted,
        Submitted,
        Finalized,
        Punished,
        Revealed,
        Renounced
    }

    enum PostType {
        Text,
        Image,
        Video,
        Audio,
        File
    }

    enum PostDuration {
        OneDay,
        ThreeDays,
        OneWeek,
        TwoWeeks,
        OneMonth
    }

    struct Post {
        User creator;
        PostData postdata;
    }

    struct PostData {
        PostSettings settings;
        PostEscrow escrow;
        PostEncryptedData data;
    }

    struct PostEncryptedData {
        bytes encryptedData;
        bytes encryptedKey;
        bytes decryptedData;
    }

    struct PostSettings {
        PostStatus status;
        PostType postType;
        address buyer;
        bytes buyerPubKey;
        address seller;
        uint256 creationTimeStamp;
        uint256 endTimeStamp;
        uint256 duration;
    }

    struct PostEscrow {
        uint256 stake;
        uint256 payment;
        uint256 punishment;
        uint256 buyerPunishment;
    }

    struct User {
        uint256 mecenateID;
        address wallet;
        bytes publicKey;
    }

    struct UserCentral {
        uint256 mecenateID;
        address wallet;
        bytes publicKey;
        bytes secretKey;
    }

    struct Feed {
        address contractAddress;
        address operator;
        address buyer;
        address seller;
        uint256 sellerStake;
        uint256 buyerStake;
        uint256 totalStake;
        uint256 postCount;
        uint256 buyerPayment;
    }

    struct BayRequest {
        bytes32 request;
        address buyer;
        address seller;
        uint256 payment;
        uint256 stake;
        address postAddress;
        bool accepted;
        uint256 postCount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../library/Structures.sol";
import "./Data.sol";
import "./Events.sol";
import "./Staking.sol";

abstract contract Acceptance is Data, Events, Staking {
    function acceptPost(
        bytes memory publicKey,
        address _buyer
    ) public payable virtual {
        require(
            IMecenateUsers(usersModuleContract).checkifUserExist(_buyer),
            "User does not exist"
        );

        uint256 _payment = _addStake(_buyer, msg.value);

        if (post.postdata.escrow.payment > 0) {
            require(
                _payment >= post.postdata.escrow.payment,
                "Not enough buyer payment"
            );
        } else {
            require(_payment > 0, "Payment is required");
        }

        require(
            post.postdata.settings.status == Structures.PostStatus.Proposed,
            "Post is not Proposed"
        );
        require(_buyer != address(0), "Buyer address cannot be zero");

        post.postdata.settings.buyer = _buyer;
        post.postdata.settings.buyerPubKey = publicKey;
        post.postdata.escrow.payment = _payment;
        post.postdata.settings.status = Structures.PostStatus.Accepted;

        emit Accepted(post);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../library/Structures.sol";
import "./Data.sol";
import "./Events.sol";
import "./Staking.sol";

abstract contract Creation is Data, Events, Staking {
    function createPost(
        bytes memory encryptedHash,
        Structures.PostType postType,
        Structures.PostDuration postDuration,
        address buyer,
        uint256 payment
    ) external payable returns (Structures.Post memory) {
        require(
            IMecenateUsers(usersModuleContract).checkifUserExist(msg.sender),
            "User does not exist"
        );

        if (post.postdata.escrow.stake == 0) {
            require(msg.value > 0, "Stake is required");
        }

        require(
            usersModuleContract != address(0),
            "Users module contract not set"
        );

        require(identityContract != address(0), "Identity contract not set");

        require(
            post.postdata.settings.status == Structures.PostStatus.Waiting ||
                post.postdata.settings.status ==
                Structures.PostStatus.Finalized ||
                post.postdata.settings.status ==
                Structures.PostStatus.Revealed ||
                post.postdata.settings.status ==
                Structures.PostStatus.Punished ||
                post.postdata.settings.status ==
                Structures.PostStatus.Proposed ||
                post.postdata.settings.status ==
                Structures.PostStatus.Renounced,
            "Not Wating or Finalized or Revealed or Proposed"
        );

        uint256 stake = _addStake(msg.sender, msg.value);

        uint256 duration;

        if (
            Structures.PostDuration(postDuration) ==
            Structures.PostDuration.OneDay
        ) {
            duration = 1 days;
        } else if (
            Structures.PostDuration(postDuration) ==
            Structures.PostDuration.ThreeDays
        ) {
            duration = 3 days;
        } else if (
            Structures.PostDuration(postDuration) ==
            Structures.PostDuration.OneWeek
        ) {
            duration = 7 days;
        } else if (
            Structures.PostDuration(postDuration) ==
            Structures.PostDuration.TwoWeeks
        ) {
            duration = 14 days;
        } else if (
            Structures.PostDuration(postDuration) ==
            Structures.PostDuration.OneMonth
        ) {
            duration = 30 days;
        }

        Structures.User memory creator = Structures.User({
            mecenateID: IMecenateIdentity(identityContract).identityByAddress(
                msg.sender
            ),
            wallet: msg.sender,
            publicKey: bytes(
                IMecenateUsers(usersModuleContract)
                    .getUserData(msg.sender)
                    .publicKey
            )
        });

        Structures.PostData memory postdata = Structures.PostData({
            settings: Structures.PostSettings({
                postType: Structures.PostType(postType),
                status: Structures.PostStatus.Proposed,
                buyer: buyer,
                buyerPubKey: "0x00",
                seller: msg.sender,
                creationTimeStamp: block.timestamp,
                endTimeStamp: 0,
                duration: duration
            }),
            escrow: Structures.PostEscrow({
                stake: stake,
                payment: payment,
                punishment: 0,
                buyerPunishment: 0
            }),
            data: Structures.PostEncryptedData({
                encryptedData: encryptedHash,
                encryptedKey: ZEROHASH,
                decryptedData: ZEROHASH
            })
        });

        Structures.Post memory _post = Structures.Post({
            creator: creator,
            postdata: postdata
        });

        post = _post;

        postCount++;

        emit Created(post);

        return Structures.Post({creator: creator, postdata: postdata});
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../library/Structures.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMecenateUsers.sol";
import "../interfaces/IMecenateIdentity.sol";
import "../interfaces/IMecenateTreasury.sol";
import "../interfaces/IMecenateFactory.sol";

contract Data is Ownable {
    uint256 public constant punishmentRatio = 100000000000000000;

    Structures.Post public post;

    uint256 public postCount;

    address public usersModuleContract;

    address public identityContract;

    address public factoryContract;

    bytes public constant ZEROHASH = "0x00";

    constructor(address _usersModuleContract, address _identityContract) {
        usersModuleContract = _usersModuleContract;
        identityContract = _identityContract;
        post.postdata.settings.status = Structures.PostStatus.Waiting;
        factoryContract = msg.sender;
    }
}

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Deposit {
    using SafeMath for uint256;

    mapping(address => uint256) private _deposit;

    event DepositIncreased(address user, uint256 amount, uint256 newDeposit);

    event DepositDecreased(address user, uint256 amount, uint256 newDeposit);

    function _increaseDeposit(
        address user,
        uint256 amountToAdd
    ) internal returns (uint256 newDeposit) {
        newDeposit = _deposit[user].add(amountToAdd);

        _deposit[user] = newDeposit;

        emit DepositIncreased(user, amountToAdd, newDeposit);

        return newDeposit;
    }

    function _decreaseDeposit(
        address user,
        uint256 amountToRemove
    ) internal returns (uint256 newDeposit) {
        uint256 currentDeposit = _deposit[user];

        require(
            currentDeposit >= amountToRemove,
            "insufficient deposit to remove"
        );

        newDeposit = currentDeposit.sub(amountToRemove);

        _deposit[user] = newDeposit;

        emit DepositDecreased(user, amountToRemove, newDeposit);

        return newDeposit;
    }

    function _clearDeposit(
        address user
    ) internal returns (uint256 amountRemoved) {
        uint256 currentDeposit = _deposit[user];

        _decreaseDeposit(user, currentDeposit);

        return currentDeposit;
    }

    function _getDeposit(address user) internal view returns (uint256 deposit) {
        return _deposit[user];
    }
}

pragma solidity 0.8.19;

import "../library/Structures.sol";

abstract contract Events {
    event Created(Structures.Post post);
    event Accepted(Structures.Post post);
    event Valid(Structures.Post post);
    event Invalid(Structures.Post post);
    event Finalized(Structures.Post post);
    event MadePublic(Structures.Post post);
    event Refunded(Structures.Post post);
    event Renounced(Structures.Post post);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../library/Structures.sol";
import "./Data.sol";
import "./Events.sol";
import "./Staking.sol";

abstract contract Finalization is Data, Events, Staking {
    function finalizePost(
        bool valid,
        uint256 punishment
    ) public virtual returns (bool) {
        require(
            post.postdata.settings.status == Structures.PostStatus.Submitted,
            "Post is not Submitted"
        );

        if (post.postdata.settings.endTimeStamp < block.timestamp) {
            post.postdata.settings.status = Structures.PostStatus.Finalized;

            address treasuryContract = IMecenateFactory(factoryContract)
                .treasuryContract();

            uint256 buyerFee = (post.postdata.escrow.payment *
                IMecenateTreasury(treasuryContract).globalFee()) / 10000;

            uint256 amountToAdd = post.postdata.escrow.payment - buyerFee;

            payable(treasuryContract).transfer(buyerFee);

            uint256 buyerStake = _takeStake(
                post.postdata.settings.buyer,
                post.postdata.escrow.payment
            );

            uint256 sellerStake = _addStake(
                post.postdata.settings.seller,
                amountToAdd
            );

            post.postdata.escrow.stake = sellerStake;

            post.postdata.escrow.payment = buyerStake;

            emit Valid(post);
        } else if (post.postdata.settings.endTimeStamp > block.timestamp) {
            require(
                post.postdata.settings.buyer == msg.sender,
                "You are not the buyer"
            );
            if (valid == true) {
                address treasuryContract = IMecenateFactory(factoryContract)
                    .treasuryContract();

                uint256 buyerFee = (post.postdata.escrow.payment *
                    IMecenateTreasury(treasuryContract).globalFee()) / 10000;

                uint256 amountToAdd = post.postdata.escrow.payment - buyerFee;

                payable(treasuryContract).transfer(buyerFee);

                uint256 buyerStake = _takeStake(
                    post.postdata.settings.buyer,
                    post.postdata.escrow.payment
                );

                uint256 sellerStake = _addStake(
                    post.postdata.settings.seller,
                    amountToAdd
                );

                post.postdata.escrow.stake = sellerStake;

                post.postdata.escrow.payment = buyerStake;

                post.postdata.settings.status = Structures.PostStatus.Finalized;

                emit Valid(post);
            } else if (valid == false) {
                require(
                    punishment <= post.postdata.escrow.stake,
                    "Punishment is too high"
                );

                uint256 buyerPunishment = (punishment * punishmentRatio) / 1e18;

                require(punishmentRatio < 1e18, "Punishment ratio is too high");

                post.postdata.escrow.buyerPunishment = buyerPunishment;

                post.postdata.settings.status = Structures.PostStatus.Finalized;

                post.postdata.escrow.punishment = punishment;

                address treasuryContract = IMecenateFactory(factoryContract)
                    .treasuryContract();

                uint256 totalPunishmentFee = buyerPunishment + punishment;

                payable(treasuryContract).transfer(totalPunishmentFee);

                uint256 buyerStake = _burnStake(
                    post.postdata.settings.buyer,
                    buyerPunishment
                );
                uint256 sellerStake = _burnStake(
                    post.postdata.settings.seller,
                    punishment
                );

                emit Invalid(post);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../library/Structures.sol";
import "./Data.sol";
import "./Events.sol";
import "./Staking.sol";

abstract contract Renounce is Data, Events, Staking {
    function renouncePost() public virtual {
        require(
            msg.sender == post.postdata.settings.seller,
            "You are not the seller"
        );

        require(
            post.postdata.settings.status == Structures.PostStatus.Accepted ||
                post.postdata.settings.status ==
                Structures.PostStatus.Submitted,
            "Post is not Accepted or Submitted"
        );

        _refundPost();

        uint256 stake = post.postdata.escrow.stake;

        _takeStake(post.postdata.settings.seller, stake);

        payable(post.postdata.settings.seller).transfer(stake);

        // Reset the post struct
        post.creator = Structures.User(0, address(0), "");
        post.postdata = Structures.PostData(
            Structures.PostSettings(
                Structures.PostStatus.Waiting,
                Structures.PostType.Text,
                address(0),
                "",
                address(0),
                0,
                0,
                0
            ),
            Structures.PostEscrow(0, 0, 0, 0),
            Structures.PostEncryptedData("", "", "")
        );

        // Update the post status and emit an event
        post.postdata.settings.status = Structures.PostStatus.Renounced;
        emit Renounced(post);
    }

    function _refundPost() internal virtual {
        require(
            post.postdata.settings.status == Structures.PostStatus.Accepted,
            "Post is not accepted"
        );

        require(
            post.postdata.settings.seller == msg.sender,
            "Only  Seller can refund the post"
        );

        uint256 payment = post.postdata.escrow.payment;

        require(payment > 0, "Payment is not correct");

        _takeStake(post.postdata.settings.buyer, payment);

        payable(post.postdata.settings.buyer).transfer(payment);

        post.postdata.settings.buyer = address(0);

        post.postdata.settings.buyerPubKey = "";

        post.postdata.escrow.payment = 0;

        post.postdata.settings.status = Structures.PostStatus.Waiting;

        emit Refunded(post);
    }
}

pragma solidity 0.8.19;

import "./Deposit.sol";
import "./Data.sol";

abstract contract Staking is Data, Deposit {
    using SafeMath for uint256;

    event StakeBurned(address staker, uint256 amount);

    // create modifier
    modifier checkStatus() {
        require(
            post.postdata.settings.status == Structures.PostStatus.Waiting ||
                post.postdata.settings.status ==
                Structures.PostStatus.Finalized ||
                post.postdata.settings.status ==
                Structures.PostStatus.Revealed ||
                post.postdata.settings.status ==
                Structures.PostStatus.Punished ||
                post.postdata.settings.status ==
                Structures.PostStatus.Proposed ||
                post.postdata.settings.status ==
                Structures.PostStatus.Renounced,
            "Wrong Status"
        );
        _;
    }

    function _addStake(
        address staker,
        uint256 amountToAdd
    ) internal returns (uint256 newStake) {
        // update deposit
        newStake = Deposit._increaseDeposit(staker, amountToAdd);
        // explicit return
        return newStake;
    }

    function _takeStake(
        address staker,
        uint256 amountToTake
    ) internal returns (uint256 newStake) {
        // update deposit
        newStake = Deposit._decreaseDeposit(staker, amountToTake);
        // explicit return
        return newStake;
    }

    function _takeFullStake(
        address staker
    ) internal returns (uint256 amountTaken) {
        // get deposit
        uint256 currentDeposit = Deposit._getDeposit(staker);

        // take full stake
        _takeStake(staker, currentDeposit);

        // return
        return currentDeposit;
    }

    function _burnStake(
        address staker,
        uint256 amountToBurn
    ) internal returns (uint256 newStake) {
        // update deposit
        uint256 newDeposit = Deposit._decreaseDeposit(staker, amountToBurn);

        // emit event
        emit StakeBurned(staker, amountToBurn);

        // return
        return newDeposit;
    }

    function _burnFullStake(
        address staker
    ) internal returns (uint256 amountBurned) {
        // get deposit
        uint256 currentDeposit = Deposit._getDeposit(staker);

        // burn full stake
        _burnStake(staker, currentDeposit);

        // return
        return currentDeposit;
    }

    function getStake(address staker) public view returns (uint256 amount) {
        // get deposit
        amount = Deposit._getDeposit(staker);
        // explicit return
        return amount;
    }

    function getTotalStaked() public view returns (uint256) {
        uint256 amountSeller = Deposit._getDeposit(
            post.postdata.settings.seller
        );

        uint256 amountBuyer = Deposit._getDeposit(post.postdata.settings.buyer);

        return (amountSeller + amountBuyer);
    }

    function addStake() external payable checkStatus returns (uint256) {
        uint256 stakerBalance;

        if (msg.sender == post.postdata.settings.buyer) {
            stakerBalance = _addStake(msg.sender, msg.value);
            post.postdata.escrow.payment = stakerBalance;
        } else if (msg.sender == post.postdata.settings.seller) {
            stakerBalance = _addStake(msg.sender, msg.value);
            post.postdata.escrow.stake = stakerBalance;
        } else {
            revert("Not buyer or seller");
        }

        return stakerBalance;
    }

    function takeStake(
        uint256 amountToTake
    ) external payable checkStatus returns (uint256) {
        uint256 currentDeposit = Deposit._getDeposit(msg.sender);
        uint256 stakerBalance;

        require(currentDeposit >= amountToTake, "Not enough deposit");

        if (msg.sender == post.postdata.settings.buyer) {
            stakerBalance = _takeStake(msg.sender, amountToTake);
            post.postdata.escrow.payment = stakerBalance;
        } else if (msg.sender == post.postdata.settings.seller) {
            stakerBalance = _takeStake(msg.sender, amountToTake);
            post.postdata.escrow.stake = stakerBalance;
        } else {
            revert("Not buyer or seller");
        }

        payable(msg.sender).transfer(amountToTake);

        return stakerBalance;
    }

    function takeFullStake() external payable checkStatus returns (uint256) {
        uint256 currentDeposit = Deposit._getDeposit(msg.sender);
        uint256 stakerBalance = _takeFullStake(msg.sender);
        payable(msg.sender).transfer(stakerBalance);
        return stakerBalance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../library/Structures.sol";
import "./Data.sol";
import "./Events.sol";

abstract contract Submission is Data, Events {
    function submitHash(bytes memory encryptedKey) public virtual {
        require(
            post.postdata.settings.status == Structures.PostStatus.Accepted ||
                post.postdata.settings.status ==
                Structures.PostStatus.Submitted,
            "Post is not Accepted or Submitted"
        );

        require(
            IMecenateUsers(usersModuleContract).checkifUserExist(msg.sender),
            "User does not exist"
        );

        require(post.creator.wallet == msg.sender, "You are not the creator");

        post.postdata.data.encryptedKey = encryptedKey;
        post.postdata.settings.status = Structures.PostStatus.Submitted;
        post.postdata.settings.endTimeStamp =
            block.timestamp +
            post.postdata.settings.duration;

        emit Valid(post);
    }

    function revealData(
        bytes memory decryptedData
    ) public virtual returns (bytes memory) {
        require(
            post.postdata.settings.status == Structures.PostStatus.Finalized,
            "Post is not Finalized"
        );
        require(
            post.postdata.settings.seller == msg.sender,
            "You are not the buyer"
        );
        post.postdata.data.decryptedData = decryptedData;
        post.postdata.settings.status = Structures.PostStatus.Revealed;
        return post.postdata.data.decryptedData;
    }
}