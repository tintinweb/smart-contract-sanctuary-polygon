// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IMoaAllowSiringV1.sol";
import "./IMoaCultivationV1.sol";
import "./IMoaMarketplaceDonor.sol";

contract MoaMarketplaceDonor is IMoaMarketplaceDonor, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _donateItemIds;
    Counters.Counter private _donateItemsComplete;
    Counters.Counter private _donateItemRevoke;

    address public owner;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor() {
        owner = msg.sender;
    }

    mapping(uint256 => DonateItem) public idToDonorItem;
    mapping(address => mapping(uint256 => uint256)) public getItemIdFromAddress;

    modifier isDonateItemDonor(
        address nftAddress,
        uint256 itemId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address _itemDonor = idToDonorItem[itemId].donor;
        address _owner = nft.ownerOf(idToDonorItem[itemId].tokenId);

        require(_itemDonor == spender);
        require(_owner == spender);
        _;
    }

    //Prevent donate item being duplicate in the donateItem list
    modifier isUnqiueOnDonateItem(address _nftAddress, uint256 _tokenId) {
        uint256 _itemId = getItemIdFromAddress[_nftAddress][_tokenId];
        DonateItem storage _donateItem = idToDonorItem[_itemId];
        require(
            (_donateItem.donateItemId == 0) ||
                (_donateItem.complete != false &&
                    _donateItem.donateItemId != 0) ||
                (_donateItem.revoke != false && _donateItem.donateItemId != 0),
            "already exists"
        );
        _;
    }

    // Check NFT contract implemented royalties
    function checkRoyalties(address _contract) internal view returns (bool) {
        (bool success) = IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
        return success;
    }

    // Below is the function for borrow siring MoA
    function createDonateItem(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price,
        uint _donationDays
    )
        public
        payable
        override
        isUnqiueOnDonateItem(_nftContract, _tokenId)
        nonReentrant
    {
        //check
        require(_price > 0, "Price must be greater than 0");
        require(
            IERC721(_nftContract).ownerOf(_tokenId) == msg.sender,
            "Sender does not own the NFT"
        );
        require(
            IMoaAllowSiringV1(_nftContract).isAllowApproveSiringForAll(msg.sender, address(this)),
            "Marketplace do not have permission to call allowSiring for this owner's collection"
        );
        require(
            IMoaAllowSiringV1(_nftContract).isApprovedCultivationForAll(msg.sender, address(this)),
            "Marketplace do not have permission to call cultivation for this owner's collection"
        );
        require(_donationDays > 0, "Donation item should last at least 1 days");
        require(_donationDays <= 60, "Donation item should last at most 1 days");

        //effect
        _donateItemIds.increment();
        uint256 _donateItemId = _donateItemIds.current();

        idToDonorItem[_donateItemId] = DonateItem({
            donateItemId: _donateItemId,
            nftContract: _nftContract,
            tokenId: _tokenId,
            donor: payable(msg.sender),
            donee: payable(address(0)),
            price: _price,
            complete: false,
            revoke: false,
            donationDays: _donationDays,
            donationFinishTime: uint64(block.timestamp + (_donationDays * 1 days))
        });

        getItemIdFromAddress[_nftContract][_tokenId] = _donateItemId;

        //Set approveSiring to this marketplace
        IMoaAllowSiringV1(_nftContract).approveSiring(address(this), _tokenId);

        emit DonateItemCreated(
            _donateItemId,
            _nftContract,
            _tokenId,
            msg.sender,
            address(0),
            _price,
            false,
            false,
            _donationDays,
            uint64(block.timestamp + (_donationDays * 1 days))
        );
    }

    function createDonateSale(uint256 itemId, uint256 matronId)
        public
        payable
        override
        nonReentrant
    {   
        //check
        require(_exists(itemId) == true, "Invalid donation item.");
        uint256 price = idToDonorItem[itemId].price;
        uint256 tokenId = idToDonorItem[itemId].tokenId;
        address nftContract = idToDonorItem[itemId].nftContract;
        address donor = idToDonorItem[itemId].donor;
        bool complete = idToDonorItem[itemId].complete;
        uint64 donationFinishTime = idToDonorItem[itemId].donationFinishTime;
        require(donationFinishTime >= block.timestamp, "The donation item is no longer available.");
        require(IERC721(nftContract).ownerOf(matronId) == msg.sender, "You do not own the core MoA.");
        require(IERC721(nftContract).ownerOf(tokenId) == donor, "MoA is no longer owned by the donor.");
        uint256 autoBirthFee = IMoaCultivationV1(nftContract).getAutoBirthfee();
        require(msg.value >= (price + autoBirthFee), "Please submit the asking price in order to complete the purchase");
        require(complete != true, "This Sale has alredy finnished");
        require(
            (IMoaAllowSiringV1(nftContract).isApprovedCultivationForAll(msg.sender, address(this)) &&
             IMoaAllowSiringV1(nftContract).isApprovedCultivationForAll(donor, address(this))),
            "Marketplace do not have permission to call cultivation for this owner's collection"
        );

        // Approve the MoA to be sired by sender
        // IMoaAllowSiringV1(nftContract).approveSiring(msg.sender, tokenId);
        uint256 bidAmount = msg.value;

        if (bidAmount >= price + autoBirthFee) {
            bidAmount -= autoBirthFee;
        }

        //@dev before sending value to donor, 
        // Check NFT has royalty implemented.
        // if implmented, royaltyAmount will be transfered to the receiver
        bool hasRoyaltyImplemented = checkRoyalties(nftContract);
        if (hasRoyaltyImplemented==true) {
            (address _receiver, uint256 _royaltyAmount) = IERC2981(nftContract).royaltyInfo(tokenId, price);
            address payable receiver = payable(address(_receiver));
            receiver.transfer(_royaltyAmount);
            idToDonorItem[itemId].donor.transfer(SafeMath.sub(bidAmount, _royaltyAmount));
            emit RoyaltyTransfer(_receiver, _royaltyAmount, address(this));
        } else {
            idToDonorItem[itemId].donor.transfer(bidAmount);
        }
        
        // Call Cultivation and provide autoBirthfee
        IMoaCultivationV1(nftContract).startCultivation{value: autoBirthFee}(matronId, tokenId);

        // Update the donee
        idToDonorItem[itemId].donee = payable(msg.sender);

        // Increase the donateItemComplete counter
        _donateItemsComplete.increment();

        // Update the donateItem to complete true
        idToDonorItem[itemId].complete = true;

        emit DonateItemComplete(itemId, tokenId, price, donor, msg.sender);
    }

    function revokeDonateItem(address _nftContract, uint256 _itemId)
        public
        override
        isDonateItemDonor(_nftContract, _itemId, msg.sender)
        nonReentrant
    {
        require(_exists(_itemId) == true, "Invalid donation item.");
        DonateItem storage _donateItem = idToDonorItem[_itemId];
        // only on-sale item can be de-listing
        require(_donateItem.complete == false);

        // Effect
        uint256 tokenId = _donateItem.tokenId;
        _donateItem.revoke = true;
        _donateItemRevoke.increment();
        IMoaAllowSiringV1(_nftContract).removeApproveSiringAddress(tokenId);

        // Event
        emit DonateItemRevoke(_itemId, tokenId, msg.sender);
    }

    function updateDonateItem(
        address _nftContract,
        uint256 _itemId,
        uint256 _price,
        uint _extraDonationDays
    )
        public
        override
        isDonateItemDonor(_nftContract, _itemId, msg.sender)
        nonReentrant
    {
        require(_exists(_itemId) == true, "Invalid donation item.");
        DonateItem storage _donateItem = idToDonorItem[_itemId];
        // Only on-sale item can be update
        // Check the item is listing on sale
        require(_donateItem.complete == false && _donateItem.revoke == false);
        require(_price > 0, "Price must be greater than 0");
        require(_extraDonationDays + _donateItem.donationDays <= 60, "Each donation item is available at most 60days.");
        // Effect
        uint256 tokenId = _donateItem.tokenId;
        _donateItem.price = _price;
        _donateItem.donationDays += _extraDonationDays;
        _donateItem.donationFinishTime += uint64(_extraDonationDays * 1 days);

        // Event
        emit DonateItemUpdate(_itemId, _price, tokenId, msg.sender, _donateItem.donationDays, _donateItem.donationFinishTime);
    }

    function fetchDonateItems()
        public
        view
        override
        returns (DonateItem[] memory)
    {
        uint256 itemCount = _donateItemIds.current();
        uint256 onDonateItemCount = _donateItemIds.current() -
            _donateItemsComplete.current() -
            _donateItemRevoke.current();
        uint256 currentIndex = 0;

        DonateItem[] memory items = new DonateItem[](onDonateItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            // Check the market item not yet sold and revoke
            if (
                idToDonorItem[i + 1].complete == false &&
                idToDonorItem[i + 1].revoke == false
            ) {
                uint256 currentId = i + 1;
                DonateItem storage currentItem = idToDonorItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchCompleteDonateItems()
        public
        view
        override
        returns (DonateItem[] memory)
    {
        uint256 itemCount = _donateItemIds.current();
        uint256 completeItemCount = _donateItemsComplete.current();
        uint256 currentIndex = 0;

        DonateItem[] memory items = new DonateItem[](completeItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            // Check the market item not yet sold and revoke
            if (
                idToDonorItem[i + 1].complete == true &&
                idToDonorItem[i + 1].donee != address(0)
            ) {
                uint256 currentId = i + 1;
                DonateItem storage currentItem = idToDonorItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchRevokeDonateItems()
        public
        view
        override
        returns (DonateItem[] memory)
    {
        uint256 itemCount = _donateItemIds.current();
        uint256 revokeItemCount = _donateItemRevoke.current();
        uint256 currentIndex = 0;

        DonateItem[] memory items = new DonateItem[](revokeItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            // Check the market item not yet sold and revoke
            if (
                idToDonorItem[i + 1].revoke == true &&
                idToDonorItem[i + 1].donee == address(0)
            ) {
                uint256 currentId = i + 1;
                DonateItem storage currentItem = idToDonorItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getDonateItemByTokenId(address _nftContract, uint256 _tokenId)
        internal
        view
        returns (uint256 donateItemId)
    {
        return getItemIdFromAddress[_nftContract][_tokenId];
    }

    function _exists(uint256 _itemId) internal view virtual returns (bool) {
        return idToDonorItem[_itemId].donor != address(0);
    }
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

interface IMoaMarketplaceDonor {
    event DonateItemCreated(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address donor,
        address donee,
        uint256 price,
        bool complete,
        bool revoke,
        uint donationDays,
        uint64 donationFinishTime
    );

    event DonateItemComplete(uint indexed itemId, uint256 indexed tokenId, uint256 price, address donor, address donee);

    event DonateItemRevoke(uint indexed itemId, uint indexed tokenId, address donor);

    event DonateItemUpdate(uint indexed itemId, uint256 updated, uint indexed tokenId, address donor, uint updatedDonationDays, uint64 updatedDonationFinishTime);

    event RoyaltyTransfer(address indexed receiver, uint256 royaltyFee, address honorContract);

    struct DonateItem {
        uint donateItemId;
        address nftContract;
        uint256 tokenId;
        address payable donor;
        address payable donee;
        uint256 price;
        bool complete;
        bool revoke;
        uint donationDays;
        uint64 donationFinishTime;
    }

    ///@dev Create a donate item on the marketplace 
    function createDonateItem(address _nftContract, uint256 _tokenId, uint256 _price, uint _donationDays ) external payable;

    ///@dev Create a donate item sale on the marketplace.
    /// The process will invloved the marketplace call allowSiring to the message sender
    /// After that, the sender can call cultivation with the allowed MoA 
    function createDonateSale(uint256 itemId, uint256 matronId) external payable;

    ///@dev Revoke a donate item
    function revokeDonateItem(address _nftContract, uint256 _itemId) external; 

    ///@dev Update a donate item
    function updateDonateItem(address _nftContract, uint256 _itemId, uint256 _price, uint _extraDonationDays) external;

    ///@dev Fetch on-donation donate items
    function fetchDonateItems() external view returns (DonateItem[] memory);

    ///@dev Fetch complete donation donate items
    function fetchCompleteDonateItems() external view returns (DonateItem[] memory);

    ///@dev Fetch revoke donation donate item
    function fetchRevokeDonateItems() external view returns (DonateItem[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMoaCultivationV1 {
    event Cultivation(address indexed  owner, uint256 indexed  matronId, uint256 indexed  sireId);
    event CompleteCultivation(address indexed owner, uint256 indexed babyId, uint256 indexed babyGenes);
    event AutoBirth(uint256 indexed matronId, uint256 indexed cooldownEndTime); 

    /// @dev update the autoBirthFee
    function setAutoBirthFee(uint256 _autoBirthFee) external;

    function getAutoBirthfee() external returns (uint256);
    
    function setGeneScienceAddress(address _address) external;

    /// @dev start a Cultivation process between 2 MoA.
    ///  always AutoBirth now
    function startCultivation(uint256 _matronId, uint256 _sireId)
        external
        payable returns (uint64);

    /// @dev end a Cultivation process and a new MoA is born!
    function completeCultivation(uint256 _matronId) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMoaAllowSiringV1 {
    event AllowApproveSiringForAll(address indexed owner, address indexed operator, bool approved);

    event ApproveCultivationForAll(address indexed owner, address indexed operator, bool approved);

    struct sireAllowedToAddress {
        address allowedAddress;
    }

    /// @dev allow token ID to be called siring from the address
    function approveSiring(address _addr, uint256 _sireId) external;

    ///@dev remove approveSiring address
    function removeApproveSiringAddress(uint256 _sireId) external;

    ///@dev return siring information
    function getApproveSiringAddress(uint256 _sireID) external returns (sireAllowedToAddress memory); 

    ///@dev allow token ID to be call approveSiring from the address e.g. 
    // Approve markerplace address to call approveSiring when someone want to 
    // put their MoA to the market place for siring renting
    function allowApproveSiring(address _addr, uint256 _sireId) external;

    ///@dev remove the approved address to call "approve siring" of targeted MoA ID
    function removeAllowApproveSiring(uint256 _sireId) external;

    ///@dev return the approved address to call "aprove siring" of targeted MoA ID
    function getAllowApproveSiring(uint256 _sireId) external returns (address);

    ///@dev allow operator address to call approveSiring for all MoA of the msd.msg.sender
    function allowApproveSiringForAll(address operator, bool _approved) external;

    ///@dev return the approved status of the owner's operator
    function isAllowApproveSiringForAll(address owner, address operator) external returns (bool);

    ///@dev allow operator address to cultivate 
    function setApproveCultivationForAll(address operator, bool approved) external;

    function isApprovedCultivationForAll(address owner, address operator) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}