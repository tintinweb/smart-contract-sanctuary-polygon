/**
 *Submitted for verification at polygonscan.com on 2022-07-27
*/

/**
 *Submitted for verification at polygonscan.com on 2022-07-08
*/

// SPDX-License-Identifier: UNLICENSED    
    pragma solidity ^0.8.0;

    /**
    * @dev Required interface of an ERC721 compliant contract.
    */
    interface IERC721 {
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


    abstract contract Context {
        function _msgSender() internal view virtual returns (address) {
            return msg.sender;
        }

        function _msgData() internal view virtual returns (bytes calldata) {
            return msg.data;
        }
    }
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

    contract HFRental is Ownable {
        using SafeMath for uint256;
        IERC721 public nftContract;
        
        struct RentOffer{
            uint256 tokenId;
            uint256 offerId;
            address owner;
            address borrower;
            uint256 price;
            uint256 endTime;
            bool confirmed;
        }
 
        

 
        uint256 totalOfferred;

        mapping(address=>uint256) public revenue;
        mapping(uint256=>RentOffer) public rentOffer;
        mapping(uint256=>uint256[]) public totalOffers;
        mapping(address=>uint256[]) public gotOffer;
        event OfferCreated(uint256 indexed tokenId, uint256 offerId);
        event OfferAccepted(uint256 indexed tokenId, uint256 offerId);
        event OfferClosed(uint256 indexed tokenId, address indexed bidder, uint256 bidId);
        mapping(address=>uint256) public pendingDeposit;

        constructor(IERC721 nft) {
            nftContract = nft;
        }

        function checkLatest(uint256 tokenId) public view returns(RentOffer memory){
            return rentOffer[totalOffers[tokenId][totalOffers[tokenId].length - 1]];
        }

        function isLive(uint256 tokenId) public view returns(bool){
            if(totalOffers[tokenId].length>0){
            uint256 endTime = checkLatest(tokenId).endTime;
            bool accepted = checkLatest(tokenId).confirmed;
            if(endTime>block.timestamp && accepted){
                return true;
            } else {
                return false;
            }        
            } else{
                return false;
            }
        }

        function askOffer(uint256 tokenId, uint256 price, uint256 endTime) external payable {
            require(!isLive(tokenId), "Already Rented");
            require(endTime > block.timestamp, "End time should be of future"); 
            require(msg.value == price, "Send proper msg value");
            totalOfferred++;
            rentOffer[totalOfferred] = RentOffer(tokenId, totalOfferred,
                 IERC721(nftContract).ownerOf(tokenId), 
                msg.sender, 
                price, endTime, false);
            totalOffers[tokenId].push(totalOfferred);
            pendingDeposit[msg.sender] += msg.value;
            emit OfferCreated(tokenId, totalOfferred);
        }

        function listOffer(uint256 tokenId, uint256 price, uint256 endTime) external {
            require(msg.sender == IERC721(nftContract).ownerOf(tokenId), "You are not the owner");
            require(endTime > block.timestamp, "End time should be of future"); 
            totalOfferred++;
            rentOffer[totalOfferred] = RentOffer(tokenId, totalOfferred,
                 IERC721(nftContract).ownerOf(tokenId), 
                 address(0), 
                price, endTime, false);
            totalOffers[tokenId].push(totalOfferred);
            emit OfferCreated(tokenId, totalOfferred);
        }

        function matchOffer(uint256 tokenId) external payable {
            RentOffer memory offer = checkLatest(tokenId);
            require(msg.value == offer.price, "Send proper msg value");
            require(offer.endTime>block.timestamp, "Offer Expired");
            rentOffer[offer.offerId].confirmed = true;
            rentOffer[offer.offerId].borrower = msg.sender;
            revenue[offer.owner] += offer.price;
            emit OfferAccepted(tokenId, offer.offerId);
        }


        function acceptOffer(uint256 tokenId) external payable {
            require(msg.sender == IERC721(nftContract).ownerOf(tokenId), "You are not the owner");
            require(!isLive(tokenId), "Already Live");
            RentOffer memory offer = checkLatest(tokenId);
            require(pendingDeposit[offer.borrower]>=offer.price, "Borrower Withdrawn the amount");
            require(msg.sender == offer.owner, "Offer Expired");
            payable(msg.sender).transfer(offer.price);
            rentOffer[offer.offerId].confirmed = true;
            gotOffer[offer.borrower].push(tokenId);
            revenue[msg.sender]+=offer.price;
            pendingDeposit[offer.borrower] -= offer.price;
            emit OfferAccepted(tokenId, offer.offerId);
        }
        
        function getRefund(uint256 amount) external payable {
            require(amount<=pendingDeposit[msg.sender], "You dont have this much amount");
            payable(msg.sender).transfer(amount);
        }

        function checkCurrentHolding(address wallet) public view returns(uint256[] memory){
            uint256[] memory tuple = gotOffer[wallet];
            uint256[] memory finaltuple = new uint[](tuple.length);

            for(uint256 i = 0; i<tuple.length; i++){
                RentOffer memory trial = checkLatest(tuple[i]);
                if (
                    trial.endTime > block.timestamp
                ) {
                    finaltuple[finaltuple.length] = trial.tokenId;
                }
            }
            return finaltuple;
        }
       
    }