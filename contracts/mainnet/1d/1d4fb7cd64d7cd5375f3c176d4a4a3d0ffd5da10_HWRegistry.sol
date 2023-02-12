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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "../Registry/IHWRegistry.sol";

interface IHonestPayLock {
    enum Status {
        OfferInitiated,
        JobCompleted,
        JobCancelled
    }
    struct Deal {
        address recruiter;
        address creator;
        address paymentToken;
        uint256 totalPayment;
        uint256 successFee;
        uint256 paidAmount;
        uint256 claimablePayment;
        Status status;
        uint128[] recruiterRating;
        uint128[] creatorRating;
    }

    function createDealSignature(
        address _recruiter,
        address _creator,
        address _paymentToken,
        uint256 _totalPayment,
        uint256 _downPayment,
        uint256 _recruiterNFTId,
        bytes memory _signature
    ) external payable returns (uint256);

    function createDeal(
        address _recruiter,
        address _creator,
        address _paymentToken,
        uint256 _totalPayment,
        uint256 _downPayment,
        uint256 _recruiterNFTId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable returns (uint256);

    function unlockPayment(
        uint256 _dealId,
        uint256 _paymentAmount,
        uint128 _rating,
        uint256 _recruiterNFT
    ) external;

    function withdrawPayment(uint256 _dealId) external;

    function claimPayment(
        uint256 _dealId,
        uint256 _withdrawAmount,
        uint128 _rating,
        uint256 _creatorNFT
    ) external;

    function additionalPayment(
        uint256 _dealId,
        uint256 _payment,
        uint256 _recruiterNFT,
        uint128 _rating
    ) external payable;

    function getDeal(uint256 _dealId) external view returns (Deal memory);

    function getCreator(uint256 _dealId) external view returns (address);

    function getRecruiter(uint256 _dealId) external view returns (address);

    function getPaymentToken(uint256 _dealId) external view returns (address);

    function getPaidAmount(uint256 _dealId) external view returns (uint256);

    function getclaimablePayment(
        uint256 _dealId
    ) external view returns (uint256);

    function getJobCompletionRate(
        uint256 _dealId
    ) external view returns (uint256);

    function getTotalPayment(uint256 _dealId) external view returns (uint256);

    function getRecruiterRating(
        uint256 _dealId
    ) external view returns (uint128[] memory);

    function getCreatorRating(
        uint256 _dealId
    ) external view returns (uint128[] memory);

    function getAvgCreatorRating(
        uint256 _dealId
    ) external view returns (uint256);

    function getAvgRecruiterRating(
        uint256 _dealId
    ) external view returns (uint256);

    function getTotalSuccessFee() external view returns (uint256);

    function getDealSuccessFee(uint256 _dealId) external view returns (uint256);

    function getDealStatus(uint256 _dealId) external view returns (uint256);

    function getAdditionalPaymentLimit(
        uint256 _dealId
    ) external view returns (uint256);

    function getDealsOfAnAddress(
        address _address
    ) external view returns (uint256[] memory);

    function changeSuccessFee(uint128 _fee) external;

    function changeRegistry(IHWRegistry _registry) external;

    function claimSuccessFee(uint256 _dealId, address _feeCollector) external;

    function claimSuccessFeeAll(address _feeCollector) external;

    function changeExtraPaymentLimit(uint64 _limit) external;

    function allowNativePayment(bool _bool) external;

    function getBnbPrice(uint256 _amount) external view returns (uint256);

    function getNFTGrossRevenue(
        uint256 _tokenId
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../Payments/IHonestPayLock.sol";

contract HWRegistry is Ownable {
    struct Whitelist {
        address token;
        uint256 maxAllowed;
    }

    Counters.Counter public counter;
    IHonestPayLock public honestPayLock;

    mapping(uint256 => Whitelist) public whitelisted;
    mapping(uint256 => uint256) public nftGrossRevenue;

    event WhitelistedAdded(address indexed _address, uint256 _maxAllowed);
    event WhitelistedRemoved(address indexed _address);
    event WhitelistedUpdated(address indexed _address, uint256 _maxAllowed);

    function addWhitelisted(
        address _address,
        uint256 _maxAllowed
    ) external onlyOwner returns (bool) {
        whitelisted[Counters.current(counter)] = Whitelist({
            token: _address,
            maxAllowed: _maxAllowed
        });
        Counters.increment(counter);
        emit WhitelistedAdded(_address, _maxAllowed);
        return true;
    }

    function removeWhitelisted(
        address _address
    ) external onlyOwner returns (bool) {
        uint256 _id = getWhitelistedID(_address);
        whitelisted[_id] = Whitelist({token: address(0), maxAllowed: 0});
        emit WhitelistedRemoved(_address);
        return true;
    }

    function updateWhitelisted(
        address _address,
        uint256 _maxAllowed
    ) external onlyOwner returns (bool) {
        whitelisted[getWhitelistedID(_address)].maxAllowed = _maxAllowed;
        emit WhitelistedUpdated(_address, _maxAllowed);
        return true;
    }

    function getWhitelistedID(address _address) private view returns (uint256) {
        uint256 token_id;
        for (uint256 i = 0; i < Counters.current(counter); i++) {
            if (whitelisted[i].token == _address) {
                token_id = i;
            }
        }
        return token_id;
    }

    function isWhitelisted(address _address) external view returns (bool) {
        bool isWhitelisted_;
        for (uint256 i = 0; i < Counters.current(counter); i++) {
            if (whitelisted[i].token == _address) {
                isWhitelisted_ = true;
            }
        }
        return isWhitelisted_;
    }

    function isAllowedAmount(
        address _address,
        uint256 _amount
    ) public view returns (bool) {
        bool isAllowedAmount_;
        for (uint256 i = 0; i < Counters.current(counter); i++) {
            if (whitelisted[i].token == _address) {
                if (whitelisted[i].maxAllowed >= _amount) {
                    isAllowedAmount_ = true;
                }
            }
        }
        return isAllowedAmount_;
    }

    function allWhitelisted() external view returns (Whitelist[] memory) {
        Whitelist[] memory whitelisted_ = new Whitelist[](
            Counters.current(counter)
        );
        for (uint256 i = 0; i < Counters.current(counter); i++) {
            whitelisted_[i] = whitelisted[i];
        }
        return whitelisted_;
    }

    function setHonestPayLock(
        address _address
    ) external onlyOwner returns (bool) {
        honestPayLock = IHonestPayLock(_address);
        return true;
    }

    function setNFTGrossRevenue(
        uint256 _id,
        uint256 _amount
    ) external onlyHonestPayLock {
        nftGrossRevenue[_id] += _amount;
    }

    modifier onlyHonestPayLock() {
        require(
            msg.sender == address(honestPayLock),
            "HWRegistry: Only HonestPayLock can call this function"
        );
        _;
    }

    function getNFTGrossRevenue(uint256 _id) external view returns (uint256) {
        return nftGrossRevenue[_id];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IHWRegistry {
    struct Whitelist {
        address token;
        uint256 maxAllowed;
    }

    function isWhitelisted(address _address) external view returns (bool);

    function isAllowedAmount(
        address _address,
        uint256 _amount
    ) external view returns (bool);

    function allWhitelisted() external view returns (Whitelist[] memory);

    function counter() external view returns (uint256);

    function setNFTGrossRevenue(uint256 _id, uint256 _amount) external;

    function getNFTGrossRevenue(uint256 _id) external view returns (uint256);
}