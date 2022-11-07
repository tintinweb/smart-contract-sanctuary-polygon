// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SocialMedia is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tagId;
    Counters.Counter private _reportId;

    string public name="SocialMedia Database";
    string public symbol="SocialMedia";

    string private _youtubeSymbol="youtube";
    string private _twitchSymbol="twitch";
    string private _twitterSymbol="twitter";
    string private _instagramSymbol="instagram";

    address private company;
    
    mapping(uint256 => ReportItem) private idToReportItem;
    mapping(uint256 => TagItem) private idToTagItem;

    struct BurnedLicenseInfo {
        string ownerAddress;
        string sellerAddress;
        string licenseName;
        string artistName;
        string price;
    }

    struct ReportItem {
        string claimId;
        string contentId;
        string userId;
        string licenseName;
        string creatorName;
        string decisionOfRuling;
        BurnedLicenseInfo burnedLicense;
        string socialMediaType;
        uint256 active; // 0 - default, if social media reported the inappropriate, should be 1, again if they reported the appeal, should be 2
        uint256 storedTime;
    }

    event ReportItemCreated (
        string claimId,
        string contentId,
        string userId,
        string licenseName,
        string creatorName,
        string decisionOfRuling,
        BurnedLicenseInfo burnedLicense,
        string socialMediaType,
        uint256 active,
        uint256 storedTime
    );

    struct TagItem {
        string contentId;
        string licenseName;
        string socialMediaType;
        bool isSafe;
    }

    event TagItemCreated (
        string contentId,
        string licenseName,
        string socialMediaType,
        bool isSafe
    );

    constructor() {
    }
    
    receive() external payable {
    }

    modifier onlyDev() {
      require(msg.sender == owner() || msg.sender == company , "Error: Require developer or Owner");
      _;
    }

    function setCompanyAddress(address _company) external onlyOwner{
        company = _company;
    }

    // socialmedia database
    function createSocialMediaDatabase(
        string memory _claimId, 
        string memory _contentId, 
        string memory _userId, 
        string memory _licenseName, 
        string memory _creatorName, 
        string memory _socialMediaType,
        string memory _decisionOfRuling,
        BurnedLicenseInfo memory _burnedLicense,
        uint256 _active
    ) external payable nonReentrant returns (
        ReportItem memory
    )   {
        _reportId.increment();

        uint256 _itemId = _reportId.current();
        idToReportItem[_itemId] = ReportItem(
            _claimId,
            _contentId,
            _userId,
            _licenseName,
            _creatorName,
            _decisionOfRuling,
            _burnedLicense,
            _socialMediaType,
            _active,
            block.timestamp
        );

        emit ReportItemCreated(
            _claimId,
            _contentId,
            _userId,
            _licenseName,
            _creatorName,
            _decisionOfRuling,
            _burnedLicense,
            _socialMediaType,
            _active,
            block.timestamp
        );

        return idToReportItem[_itemId];
    }

    function fetchReportItemsByUserId(string memory _userId, string  memory _socialMediaType) external view returns (
        ReportItem[] memory
    ){
        uint256 reportCount = _reportId.current();
        uint256 currentIndex = 0;

        ReportItem[] memory reportItems = new ReportItem[](reportCount);

        for (uint256 j = 0; j < reportCount; j++) {
            uint256 currentReportId = j + 1;
            ReportItem memory currentReportItem = idToReportItem[currentReportId];
            if(
                keccak256(bytes(currentReportItem.userId)) == keccak256(bytes(_userId)) &&
                keccak256(bytes(currentReportItem.socialMediaType)) == keccak256(bytes(_socialMediaType))
            ){
                reportItems[currentIndex] = currentReportItem;
                currentIndex++;
            }
        }
        return reportItems;
    }

    function fetchReportItems() external view returns (
        ReportItem[] memory
    ){
        uint256 reportCount = _reportId.current();
        uint256 currentIndex = 0;

        ReportItem[] memory reportItems = new ReportItem[](reportCount);

        for (uint256 j = 0; j < reportCount; j++) {
            uint256 currentReportId = j + 1;
            ReportItem memory currentReportItem = idToReportItem[currentReportId];
            reportItems[currentIndex] = currentReportItem;
            currentIndex++;
        }
        return reportItems;
    }

    function checkTagItem(
        string memory _contentId, 
        string memory _socialMediaType,
        string memory _licenseName
    ) external view returns (
        bool contentExisted,
        bool licenseExisted,
        bool isSafe
    ){
        uint256 tagCount = _tagId.current();

        for (uint256 j = 0; j < tagCount; j++) {
            uint256 currentTagId = j + 1;
            TagItem memory currentTagItem = idToTagItem[currentTagId];
            if(
                keccak256(bytes(_contentId)) == keccak256(bytes(currentTagItem.contentId)) && 
                keccak256(bytes(_socialMediaType)) == keccak256(bytes(currentTagItem.socialMediaType))
            ){
                contentExisted = true;
                if(
                    keccak256(bytes(_licenseName)) == keccak256(bytes(currentTagItem.licenseName))
                ){
                    licenseExisted = true;
                    isSafe = currentTagItem.isSafe;
                }
            }
        }
        return (contentExisted, licenseExisted, isSafe);
    }

    function getReportItem(
        string memory _contentId, 
        string memory _socialMediaType
    ) external view returns (
        ReportItem memory, TagItem[] memory, bool isReported
    ){
        uint256 mediaCount = _reportId.current();
        uint256 tagCount = _tagId.current();
        uint256 currentIndex = 0;

        ReportItem memory reportItem;
        TagItem[] memory tagItems = new TagItem[](tagCount);

        for (uint256 i = 0; i < mediaCount; i++) {
            uint256 currentReportId = i + 1;
            ReportItem memory currentreportItem = idToReportItem[currentReportId];
            if(keccak256(bytes(_contentId)) == keccak256(bytes(currentreportItem.contentId)) && keccak256(bytes(_socialMediaType)) == keccak256(bytes(currentreportItem.socialMediaType))){
                reportItem = currentreportItem;
                if(currentreportItem.storedTime + 7 days > block.timestamp){
                    isReported = true;
                }
            }
        }

        for (uint256 j = 0; j < tagCount; j++) {
            uint256 currentTagId = j + 1;
            TagItem memory currentTagItem = idToTagItem[currentTagId];
            if(
                keccak256(bytes(_contentId)) == keccak256(bytes(currentTagItem.contentId)) && 
                keccak256(bytes(_socialMediaType)) == keccak256(bytes(currentTagItem.socialMediaType))
            ){
                tagItems[currentIndex] = currentTagItem;
            }
            currentIndex++;
        }

        return (reportItem, tagItems, isReported);
    }

    function createEmptyTag(
        string memory _contentId, 
        string memory _socialMediaType
    ) external {
        _tagId.increment();
        uint256 tagCount = _tagId.current();
        
        idToTagItem[tagCount] = TagItem(
            _contentId,
            "",
            _socialMediaType,
            false
        );

        emit TagItemCreated(
            _contentId,
            "",
            _socialMediaType,
            false
        );
    }
    
    function fetchTagItems() external view returns (
        TagItem[] memory
    ){
        uint256 tagCount = _tagId.current();
        uint256 currentIndex = 0;

        TagItem[] memory tagItems = new TagItem[](tagCount);

        for (uint256 j = 0; j < tagCount; j++) {
            uint256 currentTagId = j + 1;
            TagItem memory currentTagItem = idToTagItem[currentTagId];
            tagItems[currentIndex] = currentTagItem;
            currentIndex++;
        }
        return tagItems;
    }

    function addTag(
        string memory _contentId, 
        string memory _socialMediaType, 
        string memory _licenseName, 
        bool _isSafe
    ) external {
        uint256 tagCount = _tagId.current();
        uint256 currentId = 1;

        while(currentId <= tagCount) {
            if(
                keccak256(bytes(_contentId)) == keccak256(bytes(idToTagItem[currentId].contentId)) && 
                keccak256(bytes(_socialMediaType)) == keccak256(bytes(idToTagItem[currentId].socialMediaType)) &&
                keccak256(bytes("")) == keccak256(bytes(idToTagItem[currentId].licenseName))
            ){
                idToTagItem[currentId].licenseName = _licenseName;
                idToTagItem[currentId].isSafe = _isSafe;
                break;
            }
            currentId++;
        }
    }

    function setStatusOfTag(
        string memory _contentId, 
        string memory _socialMediaType, 
        string memory _licenseName, 
        bool _isSafe
    ) external {
        uint256 tagCount = _tagId.current();

        for (uint256 i = 0; i < tagCount; i++) {
            uint256 currentId = i + 1;
            if(
                keccak256(bytes(_contentId)) == keccak256(bytes(idToTagItem[currentId].contentId)) && 
                keccak256(bytes(_socialMediaType)) == keccak256(bytes(idToTagItem[currentId].socialMediaType)) &&
                keccak256(bytes(_licenseName)) == keccak256(bytes(idToTagItem[currentId].licenseName))
            ){
                idToTagItem[currentId].isSafe = _isSafe;
            }
        }
    }

    function setStatusOfReportItem(
        string memory _contentId, 
        string memory _socialMediaType, 
        uint256 _active
    ) external {
        uint256 itemCount = _reportId.current();
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < itemCount; i++) {
            uint256 currentId = i + 1;
            if(
                keccak256(bytes(_contentId)) == keccak256(bytes(idToReportItem[currentId].contentId)) && 
                keccak256(bytes(_socialMediaType)) == keccak256(bytes(idToReportItem[currentId].socialMediaType))
            ){
                idToReportItem[currentId].active = _active;
            }
            currentIndex += 1;
        }
    }

    function setDecisionOfRulingOfReportItem(
        string memory _contentId, 
        string memory _socialMediaType, 
        string memory _decisionOfRuling
    ) external {
        uint256 itemCount = _reportId.current();
        for (uint256 i = 0; i < itemCount; i++) {
            uint256 currentId = i + 1;
            if(
                keccak256(bytes(_contentId)) == keccak256(bytes(idToReportItem[currentId].contentId)) && 
                keccak256(bytes(_socialMediaType)) == keccak256(bytes(idToReportItem[currentId].socialMediaType))
            ){
                idToReportItem[currentId].decisionOfRuling = _decisionOfRuling;
            }
        }
    }

    function setBurnedLicenseOfReportItem(
        string memory _contentId, 
        string memory _socialMediaType, 
        BurnedLicenseInfo memory _burnedLicense
    ) external {
        uint256 itemCount = _reportId.current();
        for (uint256 i = 0; i < itemCount; i++) {
            uint256 currentId = i + 1;
            if(
                keccak256(bytes(_contentId)) == keccak256(bytes(idToReportItem[currentId].contentId)) && 
                keccak256(bytes(_socialMediaType)) == keccak256(bytes(idToReportItem[currentId].socialMediaType))
            ){
                idToReportItem[currentId].burnedLicense = _burnedLicense;
            }
        }
    }

    function withdrawFee(address to, uint256 amount) external {
        uint256 balance = address(this).balance;
        require(balance < amount, "Error: dont have enough fund");
        payable(address(to)).transfer(amount.mul(25).div(1000));
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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