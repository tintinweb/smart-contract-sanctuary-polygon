pragma solidity 0.8.11;

import './Auction.sol';
import "@openzeppelin/contracts/security/Pausable.sol";

contract AuctionFactory is Pausable {

    address public addrAdmin;
    address[] private addrPayTokens;
    address[] private _auctions;
    address public commissionWallet;
	mapping(address=>bool) public acceptableNfts;
    mapping(address=>uint256) public commissions; // part of 1000: example 2.5% => value 25

    event AuctionCreated(address auctionContract, address owner, uint256 startPrice, Type auctionType, uint256 numAuctions);
    event AdminChanged(address newAdmin);
    event CommissionWalletChanged(address newWallet);

    constructor(
        address _admin,
        address[] memory _payTokens,
        uint256[] memory _commissionPercents,
        address[] memory _acceptableNfts,
		address _commissionWallet
    ) {
        require(_payTokens.length == _commissionPercents.length, "Arrays payTokens and commissionPercents must be same length");
        addrAdmin = _admin;
        addrPayTokens = _payTokens;
		commissionWallet = _commissionWallet;
		for (uint256 i=0; i<_acceptableNfts.length; i++){
			address nftAddr = _acceptableNfts[i];
			acceptableNfts[nftAddr] = true;
		}
        for (uint256 j = 0; j < _payTokens.length; j++) {
            address payAddr = _payTokens[j];
            require(_commissionPercents[j] < 1000, "Only 100% + 1 decimal char");
            commissions[payAddr] = _commissionPercents[j];
        }
    }

    function changeAdmin(address newAdminAddress) external onlyAdmin {
        require(newAdminAddress != address(0), "No zero address");
        addrAdmin = newAdminAddress;
        emit AdminChanged(addrAdmin);
    }

	function changeCommissionWallet(address _newWallet) external onlyAdmin {
        require(_newWallet != address(0), "No zero address");
        commissionWallet = _newWallet;
        emit CommissionWalletChanged(commissionWallet);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function addAcceptableNft(address acceptableNft) external onlyAdmin {
        acceptableNfts[acceptableNft] = true;
    }

    function removeAcceptableNft(address acceptableNft) external onlyAdmin {
        require(isAcceptableNft(acceptableNft), "ERROR_NOT_ACCEPTABLE_NFT");
		acceptableNfts[acceptableNft] = false;
    }

    function isAcceptableNft(address acceptableNft) internal view returns(bool) {
        return acceptableNfts[acceptableNft];
    }

    function setPayToken(address payToken, uint256 commissionPercent) external onlyAdmin {
        if(!isPayToken(payToken)) {
            addrPayTokens.push(payToken);
        }
        commissions[payToken] = commissionPercent;
    }

    function removePayToken(address payToken) external onlyAdmin {
        require(isPayToken(payToken), "ERROR_NOT_ACCEPTABLE_TOKEN");

        for(uint256 i = 0; i < addrPayTokens.length; i++) {
            if(payToken == addrPayTokens[i]) {
				addrPayTokens[i] = addrPayTokens[addrPayTokens.length-1];
				addrPayTokens.pop();
            }
        }
    }

    function isPayToken(address payToken) internal view returns(bool) {
        for(uint256 i = 0; i < addrPayTokens.length; i++) {
            if(payToken == addrPayTokens[i]) {
                return true;
            }
        }

        return false;
    }

    function getPayTokens() external view returns(address[] memory) {
        return addrPayTokens;
    }

    function createAuction(
        uint256 duration, // seconds
        uint256 buyValue, // start/sell price
        address payToken,
        address nftToken,
        uint256 nftId,
        Type _type
    )
    external
    whenNotPaused
    {
        require(!paused(), "ERROR_PAUSE");
        require(isPayToken(payToken), "ERROR_NOT_ACCEPTABLE_TOKEN");
        require(isAcceptableNft(nftToken), "ERROR_NOT_ACCEPTABLE_NFT");

        Auction newAuction = new Auction(
            _msgSender(),
            addrAdmin,
            duration,
            nftToken,
            nftId,
            payToken,
            buyValue,
            _type,
			commissionWallet,
			commissions[payToken]
        );
        _auctions.push(address(newAuction));

        emit AuctionCreated(address(newAuction), _msgSender(), buyValue, _type, _auctions.length);
    }

    function allAuctions() public view returns (address[] memory auctions) {
        return auctions = _auctions;
    }

    modifier onlyAdmin {
        require(_msgSender() == addrAdmin, "Only admin");
        _;
    }

}

enum Type{
        Auction,
        Trade
    }

    enum States{
        Initialize,
        ClaimToken,
        StartAuction,
        EndAuction,
        CancelAuction
    }

pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./auctionHelpers/TypeSupport.sol";

contract Auction is IERC721Receiver, Context, ReentrancyGuard {
    using SafeMath for uint256;

    struct BidInfo {
        address bidder;
        uint256 bid;
        uint256 timestamp;
    }

    struct Info {
        address owner;
        address admin;
        uint256 duration;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 tokenId;
        uint256 buyValue;
        address erc721Instance;
        address payTokenInstance;
        Type auctionType;
        States auctionState;
        uint256 highestBindingBid;
        address highestBidder;
        uint256 currentBid;
        bool erc721present;
    }

    // static
    address public owner;            // auction owner
    address public admin;            // can change admin and contractFeeAddresses
    uint256 public duration;
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    uint256 public tokenId;
    uint256 public buyValue;
    IERC721 public erc721Instance;
    IERC20  public payTokenInstance;
    Type    public auctionType;

    // state
    BidInfo[] public bids;
    States public auctionState;
    uint256 public highestBindingBid;
    address public highestBidder;
    mapping(address => uint256) public fundsByBidder;
    uint256 public currentBid;
	uint256 private commissionPercent; // part of 1000: example 2.5% => value 25
	address private commissionWallet;
    bool public erc721present;


    event LogStartAuction(address indexed erc721address, uint256 tokenId, uint256 startTimestamp, uint256 endTimestamp);
    event LogBid(address indexed auction, address indexed bidder, uint256 bid, uint256 endTimestamp);
    event LogWithdrawal(address indexed withdrawer, address indexed withdrawalAccount, uint256 amount);
    event LogTokenClaimed(address indexed receiver, address indexed tokenAddress, uint256 tokenId);
    event LogCanceled(address indexed auctionAddr);
    event LogBuy(address indexed buyer, uint256 price);
    event LogSetTimestamp(uint256 newEndTimestamp);

    constructor(
        address _owner,
        address _admin,
        uint256 _duration,
        address nftToken,
        uint256 nftId,
        address _payTokenAddress,
        uint256 _buyValue,
        Type _auctionType,
		address _commissionWallet,
		uint256 _commissionPercent
    ) {
        require(_commissionPercent < 1000, "Only 100% + 1 decimals");
        owner = _owner;
        admin = _admin;
        erc721Instance = IERC721(nftToken);
        tokenId = nftId;
        duration = _duration;
        payTokenInstance = IERC20(_payTokenAddress);
        buyValue = _buyValue;
        currentBid = _buyValue;
        auctionType = _auctionType;
        auctionState = States.Initialize;
		commissionPercent = _commissionPercent;
		commissionWallet = _commissionWallet;
    }

    function getBidInfo() external view returns(BidInfo[] memory) {
        return bids;
    }

    function getInfo() external view returns (Info memory){
        Info memory data;
        data.owner = owner;
        data.admin = admin;
        data.duration = duration;
        data.startTimestamp = startTimestamp;
        data.endTimestamp = endTimestamp;
        data.tokenId = tokenId;
        data.buyValue = buyValue;
        data.erc721Instance = address(erc721Instance);
        data.payTokenInstance = address(payTokenInstance);
        data.auctionState = auctionState;
        data.auctionType = auctionType;
        data.highestBidder = highestBidder;
        data.highestBindingBid = highestBindingBid;
        data.currentBid = currentBid;
        data.erc721present = erc721present;
        return data;
    }

    function checkVisible(address forAddress) internal view returns (bool){
        if (auctionState == States.StartAuction) {
            if (forAddress == owner) {
                // is Owner
                if (highestBidder == address(0)) {
                    // no bids
                    if (erc721present == true) {
                        return true;
                    }
                } else if (fundsByBidder[highestBidder] > 0) {
                    // any bids present and not withdrawn
                    return true;
                }
            } else if (forAddress == highestBidder) {
                // winner
                if (erc721present == true) {
                    // NFT not withdrawn
                    return true;
                }
            } else if (fundsByBidder[forAddress] > 0) {
                // just partisipant, not withdrawn
                return true;
            } else if (block.timestamp < endTimestamp) {
                // visible until end time
                return true;
            }
        }
        return false;
    }

    function isVisible() public view returns (bool) {
        return checkVisible(_msgSender());
    }

    function getTime() external view returns (uint256) {
        return block.timestamp;
    }

    function setTimestampAdmin(uint256 _endTimestamp) external onlyAdmin {
        endTimestamp = _endTimestamp;
        emit LogSetTimestamp(endTimestamp);
    }

    /**
    * @dev The first transaction only initialize auction(buy, placeBid)
	*/

    function setNewCurrentBid() private {
        uint256 increase = currentBid.div(10);
        currentBid += increase;
    }

    function getNeededAllowancePaytoken() external view returns (uint256){
        return currentBid.sub(fundsByBidder[_msgSender()]);
    }

    function placeBid()
    	external
    	onlyStarted
    	onlyBeforeEnd
    	onlyNotOwner
    returns (bool success)
    {
        uint256 needAmount = currentBid.sub(fundsByBidder[_msgSender()]);
        highestBidder = _msgSender();
		BidInfo memory oneBidInfo = BidInfo(_msgSender(), currentBid, block.timestamp);
        bids.push(oneBidInfo);

        if (auctionType == Type.Auction) {
            highestBindingBid = fundsByBidder[highestBidder] + needAmount;
            fundsByBidder[highestBidder] = highestBindingBid;
            require(payTokenInstance.transferFrom(_msgSender(), address(this), needAmount));
            setNewCurrentBid();
            emit LogBid(
				address(this),
                _msgSender(),
                highestBindingBid,
                endTimestamp
            );
			if (endTimestamp - block.timestamp < 3600) {
                endTimestamp += 600;
            }
        } else {
			uint256 _commission;
            uint256 _remain;
            (_commission, _remain) = _calculateFee(needAmount);
			erc721Instance.safeTransferFrom(address(this), _msgSender(), tokenId);
			require(payTokenInstance.transferFrom(_msgSender(), address(commissionWallet), _commission));
            require(payTokenInstance.transferFrom(_msgSender(), address(owner), _remain));
            erc721present = false;
            auctionState = States.EndAuction;
			endTimestamp = block.timestamp;
			highestBidder = _msgSender();
            emit LogBuy( _msgSender(), needAmount);
        }
        return true;
    }

    function cancelAuction()
    external
    onlyOwner
    onlyNotCancelled
    onlyBeforeStartOrOnlyTrade
    returns (bool success)
    {
        auctionState = States.CancelAuction;
        erc721Instance.safeTransferFrom(address(this), owner, tokenId);
        erc721present = false;
        emit LogCanceled(address(this));
        return true;
    }

	function _calculateFee(uint256 _amount) internal view returns (uint256 _commission, uint256 _remain)
    {
        uint256 temp;
        bool b;

		// commission percent
        (b, temp) = SafeMath.tryMul(_amount, commissionPercent);
        require(b, "ERROR_SAFEMATH");
        (b, _commission) = SafeMath.tryDiv(temp, 1000);
        require(b, "ERROR_SAFEMATH");

		// remaining part
        (b, _remain) = SafeMath.trySub(_amount, _commission);
        require(b, "ERROR_SAFEMATH");
    }

    function withdraw()
    external
    onlyNotCancelled
    onlyEndedTime
	nonReentrant
    returns (bool success)
    {
        require(_msgSender() != address(0), "Sender should not be zero.");
        uint256 withdrawalAmount;
        auctionState = States.EndAuction;
        if (_msgSender() == owner) {
            // the auction's owner should be allowed to withdraw the highestBindingBid
            withdrawalAmount = fundsByBidder[highestBidder];
            require(withdrawalAmount > 0, "Already withdrawn.");
			unchecked {
				fundsByBidder[highestBidder] -= withdrawalAmount;
			}

			uint256 _commission;
            uint256 _remain;
            (_commission, _remain) = _calculateFee(withdrawalAmount);
			require(payTokenInstance.transfer(address(commissionWallet), _commission));
			require(payTokenInstance.transfer(owner, _remain));

            emit LogWithdrawal(_msgSender(), highestBidder, withdrawalAmount);
        } else if (_msgSender() == highestBidder) {
            require(erc721Instance.ownerOf(tokenId) == address(this), "NFT already withdrawn.");
            erc721Instance.safeTransferFrom(address(this), highestBidder, tokenId);
            erc721present = false;
            emit LogTokenClaimed(_msgSender(), address(erc721Instance), tokenId);
        } else {
            // anyone who participated but did not win the auction should be allowed to withdraw
            // the full amount of their funds
            withdrawalAmount = fundsByBidder[_msgSender()];
            require(withdrawalAmount > 0, "Already withdrawn");
            require(payTokenInstance.transfer(_msgSender(), withdrawalAmount));
        unchecked {
            fundsByBidder[_msgSender()] -= withdrawalAmount;
        }
            emit LogWithdrawal(_msgSender(), _msgSender(), withdrawalAmount);
        }
        return true;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external override returns (bytes4)
    {
        //Here we check that owner of auction can`t change nft when auction starts
        require(auctionState == States.Initialize, "Should be in init state.");
        require(_from != address(0), "Should be not zero address.");
        require(_msgSender() == address(erc721Instance) && _tokenId == tokenId, "Wrong NFT");
        require(erc721Instance.ownerOf(tokenId) == address(this), "NFT not transferred.");

        erc721present = true;

        auctionState = States.StartAuction;
        startTimestamp = block.timestamp;
        endTimestamp = startTimestamp + duration;

        emit LogStartAuction(_msgSender(), _tokenId, startTimestamp, endTimestamp);

        return this.onERC721Received.selector;
    }

    modifier onlyOwner {
        require(_msgSender() == owner, "Only owner");
        _;
    }

    modifier onlyAdmin {
        require(_msgSender() == admin, "Only admin");
        _;
    }

    modifier onlyNotOwner {
        require(_msgSender() != owner, "Only not owner");
        _;
    }

    modifier onlyStarted {
        require(auctionState == States.StartAuction, "Only after started");
        _;
    }

    modifier onlyEndedTime {
        require(block.timestamp >= endTimestamp, "Only ended");
        _;
    }

    modifier onlyBeforeEnd {
        require(block.timestamp < endTimestamp, "Only before end");
        _;
    }

    modifier onlyNotCancelled {
        require(auctionState != States.CancelAuction, "Only not canceled");
        _;
    }

    modifier onlyBeforeStartOrOnlyTrade {
        if (highestBidder != address(0) && auctionType != Type.Trade) {
            revert("Only before start or only trade");
        }
        _;
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}