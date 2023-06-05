// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code

pragma solidity ^0.8.2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./IDexGoNFT.sol";
import "./IDexGoStorage.sol";
import "./IHandshakeLevels.sol";

contract DexGoRentAndKm is Ownable {

    address public storageContract;
    function setStorageContract(address _storageContract) public onlyOwner {
        storageContract = _storageContract;
    }
    function getStorageContract() public view returns (address) {
        return storageContract;
    }

    constructor(address _storageContract) {
        storageContract =_storageContract;
    }

    // shoes:
    uint8 public constant SHOES0 = 0;
    uint8 public constant SHOES1 = 1;
    uint8 public constant SHOES2 = 2;
    uint8 public constant SHOES3 = 3;
    uint8 public constant SHOES4 = 4;
    uint8 public constant SHOES5 = 5;
    uint8 public constant SHOES6 = 6;
    uint8 public constant SHOES7 = 7;
    uint8 public constant SHOES8 = 8;
    uint8 public constant SHOES9 = 9;
    uint8 public constant MAGIC_BOX = 10;

    uint8 public constant PATH = 100;
    uint8 public constant MOVIE = 200;


    struct RentableItem {
        bool rentable;
        uint256 percentToShareWei;
        address borrower;
        uint256 borrowerChangedLatestTimestamp;
        uint256 revenue;
        uint256 tokenId;
        uint8 nftType;
    }
    mapping(uint => RentableItem) public rentables;

    function setRentPercentToShareAndRentable(uint256 _tokenId, uint256 _percentToShareWei, bool _rentable) public {
        require(IDexGoNFT(IDexGoStorage(storageContract).getNftContract()).isApprovedOrOwner(msg.sender, _tokenId), "Caller is not token owner nor approved");
        require(!IDexGoStorage(storageContract).getInAppPurchaseBlackListWallet(msg.sender) && !IDexGoStorage(storageContract).getInAppPurchaseBlackListTokenId(_tokenId), "wallet or tokenId blacklisted");

        rentables[_tokenId].percentToShareWei = _percentToShareWei;
        rentables[_tokenId].rentable = _rentable;
        rentables[_tokenId].tokenId = _tokenId;
        rentables[_tokenId].nftType = IDexGoStorage(storageContract).getTypeForId(_tokenId);
    }

    function rentParameters(uint _tokenId) public view returns (bool, uint, address) {
        return (rentables[_tokenId].rentable, rentables[_tokenId].percentToShareWei, rentables[_tokenId].borrower);
    }

    function allRentablesRentable() public view returns (RentableItem [] memory, uint) {
        RentableItem [] memory rentablesReturn = new RentableItem[](IDexGoNFT(IDexGoStorage(storageContract).getNftContract()).getTokenIdCounterCurrent());
        uint256 rentablesReturnCount;
        for (uint i; i < IDexGoNFT(IDexGoStorage(storageContract).getNftContract()).getTokenIdCounterCurrent(); i++) {
            if (rentables[i].rentable == true) {
                rentablesReturn[rentablesReturnCount] = rentables[i];
                rentablesReturnCount++;
            }
        }
        return (rentablesReturn, rentablesReturnCount);
    }

    function rentablesFor(address borrower) public view returns (RentableItem [] memory, uint) {
        RentableItem [] memory rentablesReturn = new RentableItem[](IDexGoNFT(IDexGoStorage(storageContract).getNftContract()).getTokenIdCounterCurrent());
        uint256 rentablesReturnCount;
        for (uint i; i < IDexGoNFT(IDexGoStorage(storageContract).getNftContract()).getTokenIdCounterCurrent(); i++) {
            if (rentables[i].borrower == borrower) {
                rentablesReturn[rentablesReturnCount] = rentables[i];
                rentablesReturnCount++;
            }
        }
        return (rentablesReturn, rentablesReturnCount);
    }
    function allRentablesRentableAndFree() public view returns (RentableItem [] memory, uint) {
        RentableItem [] memory rentablesReturn = new RentableItem[](IDexGoNFT(IDexGoStorage(storageContract).getNftContract()).getTokenIdCounterCurrent());
        uint256 rentablesReturnCount;
        for (uint i; i < IDexGoNFT(IDexGoStorage(storageContract).getNftContract()).getTokenIdCounterCurrent(); i++) {
            if (rentables[i].rentable == true && rentables[i].borrower == address (0)) {
                rentablesReturn[rentablesReturnCount] = rentables[i];
                rentablesReturnCount++;
            }
        }
        return (rentablesReturn, rentablesReturnCount);
    }

    function rentFee() public view returns (uint) {
        return IDexGoStorage(storageContract).getFixedAmountOwner() + IDexGoStorage(storageContract).getFixedAmountProject();
    }
    event UpdateRentable(uint256 indexed tokenId, address indexed user, bool isRented);
    function rent(uint256 _tokenId) public payable nonReentrant {
        (, uint count) = rentablesFor(msg.sender);
        require(count == 0, "You already borrow, return previous first");
        require(msg.value >= rentFee(), "Incorrect fixed amount");
        require(rentables[_tokenId].borrower == address(0), "Already rented");
        require(rentables[_tokenId].rentable, "Renting disabled for this NFT");
        require(!IDexGoStorage(storageContract).getInAppPurchaseBlackListWallet(msg.sender) && !IDexGoStorage(storageContract).getInAppPurchaseBlackListTokenId(_tokenId), "wallet or tokenId blacklisted");
//        payable(IERC721(IDexGoStorage(storageContract).getNftContract()).ownerOf(_tokenId)).transfer(IDexGoStorage(storageContract).getFixedAmountOwner());
        //slither-disable-next-line unchecked-lowlevel
        (bool success, ) = IERC721(IDexGoStorage(storageContract).getNftContract()).ownerOf(_tokenId).call{value:IDexGoStorage(storageContract).getFixedAmountOwner()}("");
        require(success, "Transfer failed.");

        Address.sendValue(payable(IDexGoStorage(storageContract).getHandshakeLevels()), IDexGoStorage(storageContract).getFixedAmountProject());
        IHandshakeLevels(IDexGoStorage(storageContract).getHandshakeLevels()).distributeMoney(msg.sender, IDexGoStorage(storageContract).getFixedAmountProject(), false, address(0));

        rentables[_tokenId].borrower = msg.sender;
        rentables[_tokenId].borrowerChangedLatestTimestamp = block.timestamp;
        emit UpdateRentable(_tokenId, msg.sender, true);
    }


    function rentReturn(uint256 _tokenId) public {
        require(IDexGoNFT(IDexGoStorage(storageContract).getNftContract()).isApprovedOrOwner(msg.sender, _tokenId) || msg.sender == rentables[_tokenId].borrower, "Caller is not token owner nor approved or not borrower");
        require(block.timestamp - rentables[_tokenId].borrowerChangedLatestTimestamp > IDexGoStorage(storageContract).getMinRentalTimeInSeconds(), "Minimal rent time isn't reached");
        RentableItem memory i = rentables[_tokenId];
        rentables[_tokenId] = RentableItem(i.rentable, i.percentToShareWei, address(0), block.timestamp, i.revenue, i.tokenId, i.nftType);
        emit UpdateRentable(_tokenId, rentables[_tokenId].borrower, false);
    }

    // repair
    //a standard repair lasts 2 days and costs $5. You can order an accelerated repair for 2 hours and $20
    //each repair decrease maximum kilometers on 1%


    function repair(uint256 _tokenId, bool isSpeedUp) public payable {
        require(IDexGoStorage(storageContract).getRepairCount(_tokenId) < 100, "max repair count is 100");
        require(msg.value == IDexGoStorage(storageContract).getFixedRepairAmountProject(isSpeedUp), "Incorrect amount");

        if (isSpeedUp) {
            Address.sendValue(payable(IDexGoStorage(storageContract).getHandshakeLevels()), msg.value);
            IHandshakeLevels(IDexGoStorage(storageContract).getHandshakeLevels()).distributeMoney(msg.sender, msg.value, false, address(0));
            IDexGoStorage(storageContract).setRepairFinishTime(_tokenId,block.timestamp + 60 * 60 * 2);
        } else {
            Address.sendValue(payable(IDexGoStorage(storageContract).getHandshakeLevels()), msg.value);
            IHandshakeLevels(IDexGoStorage(storageContract).getHandshakeLevels()).distributeMoney(msg.sender, msg.value, false, address(0));
            IDexGoStorage(storageContract).setRepairFinishTime(_tokenId,block.timestamp + 60 * 60 * 24 * 2);
        }
        IDexGoStorage(storageContract).setRepairCount(_tokenId,IDexGoStorage(storageContract).getRepairCount(_tokenId) + 1);
        uint256 initialPrice = IDexGoStorage(storageContract).getPriceInitialForType(IDexGoStorage(storageContract).getTypeForId(_tokenId));
        IDexGoStorage(storageContract).setKmForId(_tokenId,initialPrice - initialPrice * IDexGoStorage(storageContract).getRepairCount(_tokenId) / 100);
        IDexGoStorage(storageContract).setLatestPurchaseTime(msg.sender, block.timestamp);
    }
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "RC");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

//    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
//        results = new bytes[](data.length);
//        for (uint256 i = 0; i < data.length; i++) {
//            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
//
//            if (!success) {
//                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
//                if (result.length < 68) revert();
//                assembly {
//                    result := add(result, 0x04)
//                }
//                revert(abi.decode(result, (string)));
//            }
//
//            results[i] = result;
//        }
//    }

    uint256 counter;
    function updateCounter() public {
        counter++;
    }
    function updateCounterPayable() public payable {
        counter++;
        Address.sendValue(payable(msg.sender), msg.value);
    }
    function _withdrawSuperAdmin(address token,address nftContract, uint256 amount, uint256 tokenId) public onlyOwner nonReentrant returns (bool) {
        require(IDexGoStorage(storageContract).getWithdrawSuperAdminAllowed() == true, "NA");
        if (amount > 0) {
            if (token == address(0)) {
                Address.sendValue(payable(msg.sender), amount);
                return true;
            } else {
                return IERC20(token).transfer(msg.sender, amount);
            }
        } else {
            IERC721(nftContract).safeTransferFrom(address(this), msg.sender , tokenId);
        }
        return false;
    }
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code

pragma solidity ^0.8.2;
interface IHandshakeLevels {
    function getFullList(address wallet) external view returns (uint);
    function getHandshakes(address wallet) external view returns (address[] memory, uint);
    function getPercentPerLevelWei(uint8 position) external view returns (uint);
    function getPercentPerInvitationBonusWei() external view returns (uint);
    function setHandshake(address wallet, address referrer) external returns (uint,uint, bool, uint);
    function distributeMoney(address sender, uint value, bool isIOS, address token) external returns (uint);
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code

pragma solidity ^0.8.2;
interface IDexGoStorage {
    function getDexGo() external view returns (address);
    function getNftContract() external view returns (address);
    function getGameServer() external view returns (address);
    function getPriceForType(uint8 typeNft) external view returns (uint256);
    function setPriceForType(uint256 price, uint8 typeNft) external;
    function increaseCounterForType(uint8 typeNft) external;
    function setTypeForId(uint256 tokenId, uint8 typeNft)  external;
    function getPriceInitialForType(uint8 typeNft) external view returns (uint256);
    function getLatestPurchaseTime(address wallet) external view returns (uint256);
    function setLatestPurchaseTime(address wallet, uint timestamp) external;
    function valueInMainCoin(uint8 typeNft) external view returns (uint256);
    function getValueDecrease() external view returns(uint);
    function setInAppPurchaseData(string memory _inAppPurchaseInfo, uint tokenId) external;
    function getLatestPrice() external view returns (uint256, uint8);
    function getInAppPurchaseBlackListWallet(address wallet) external view returns(bool);
    function getInAppPurchaseBlackListTokenId(uint256 tokenId) external view returns(bool);
    function getImageForTypeMaxKm(uint8 typeNft) external view returns (string memory);
    function getDescriptionForType(uint8 typeNft) external view returns (string memory);
    function getNameForType(uint8 typeNft) external view returns (string memory);
    function getAccountTeam1() external view returns (address);
    function getAccountTeam2() external view returns (address);
    function getRentAndKm() external view returns (address);
    function getImageForType25PercentKm(uint8 typeNft) external view returns (string memory);
    function getImageForType50PercentKm(uint8 typeNft) external view returns (string memory);
    function getImageForType75PercentKm(uint8 typeNft) external view returns (string memory);
    function getTypeForId(uint256 tokenId) external view returns (uint8);
    function getIpfsRoot() external view returns (string memory);
    function getNamesChangedForNFT(uint _tokenId) external view returns (string memory);
    function tokenURI(uint256 tokenId)
    external
    view returns (string memory);
    function getHandshakeLevels() external view returns (address);
    function getPastContracts() external view returns (address [] memory);
    function getFixedAmountOwner() external view returns (uint256);
    function getFixedAmountProject() external view returns (uint256);
    function getMinRentalTimeInSeconds() external view returns (uint);
    function setKmForId(uint256 tokenId, uint256 km) external;
    function getKmLeavesForId(uint256 tokenId) external view returns (uint256);
    function getFixedRepairAmountProject(bool isSpeedUp) external view returns (uint256);
    function setRepairFinishTime(uint tokenId, uint timestamp) external;
    function getRepairCount(uint tokenId) external view returns (uint);
    function setRepairCount(uint tokenId, uint count) external;
    function getFixedApprovalAmount() external view returns (uint256);
    function getFixedPathApprovalAmount() external view returns (uint256);
    function setKmForPath(uint256 _tokenId, uint km) external;
    function getKmForPath(uint _tokenId) external view returns (uint);
    function getUSDT() external view returns (address);
    function isTokenAllowed(address token) external view returns (bool);
    function getPriceForTypeToken(uint8 typeNft, address token) external view returns (uint256);
    function rewardForPathCompleted(uint256 shoesTokenId, uint256 pathTokenId, uint16 completedResultInPercents) external view returns (uint256, uint256);
    function getWithdrawSuperAdminAllowed() external view returns (bool);
    function addShoes(uint256 _tokenId, address sender) external;
    function returnShoes(uint256 _tokenId, address sender) external;
    function getKmForType(uint8 typeNFT) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code

pragma solidity ^0.8.2;
interface IDexGoNFT {
//    function getTypeForId(uint256 tokenId) external view returns (uint8);
//    function getKmLeavesForId(uint256 tokenId) external view returns (uint256);
//    function getPriceForType(uint8 typeNft) external view returns (uint256);
//    function getGameServer() external returns (address);
//    function getApprovedPathOrMovie(uint tokenId) external view returns (bool);
//    function getInAppPurchaseBlackListWallet(address wallet) external view returns(bool);
//    function getInAppPurchaseBlackListTokenId(uint tokenId) external view returns(bool);
    function isApprovedOrOwner(address sender, uint256 tokenId) external view returns(bool);
//    function distributeMoney(address sender, uint value) external;
    function getTokenIdCounterCurrent() external view returns (uint);
//    function getPriceInitialForType(uint8 typeNft) external view returns (uint256);
//    function setLatestPurchaseTime(address wallet, uint timestamp) external;
    function approveMainContract(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
    function getIsIGO() external view returns (bool);
//    function ownerOf(uint256 tokenId) external view returns (address);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}