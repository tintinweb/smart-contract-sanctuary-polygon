// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './interfaces/IReferral.sol';
import './interfaces/IPOLKANFT.sol';
import './interfaces/IWBNB.sol';
import './interfaces/IPolkaMarket.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Manager is Ownable, Pausable {
	using SafeERC20 for IERC20;
	address public referralContract;

	// FEE
	//uint256 public xUser = 250; // 2.5%
	// uint256 public xCreator = 1500;
	uint256 public yRefRate = 5000; // 50%
	// uint256 public zProfitToCreator = 5000; // 10% profit

	mapping(address => bool) public paymentMethod;
	mapping(address => bool) public isPOLKANFTs;
	mapping(address => bool) public isFarmingNFTs;
	mapping(address => bool) public isOperator;
	mapping(address => bool) public isRetailer;

	modifier onlyOperator() {
		require(isOperator[msg.sender], 'Only-operator');
		_;
	}

	constructor() {
		isOperator[msg.sender] = true;
		//		oldMarket = _oldMarket;
	}

	receive() external payable {}

	function whiteListOperator(address _operator, bool _whitelist) external onlyOwner {
		isOperator[_operator] = _whitelist;
	}

	function whiteListRetailer(address _retailer, bool _whitelist) external onlyOwner {
		isRetailer[_retailer] = _whitelist;
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unPause() public onlyOwner {
		_unpause();
	}

	function setSystemFee(uint256 _yRefRate) external onlyOwner {
		_setSystemFee(_yRefRate);
	}

	function _setSystemFee(uint256 _yRefRate) internal {
		yRefRate = _yRefRate;
	}

	function addPOLKANFTs(
		address _polkaNFT,
		bool _isPOLKANFT,
		bool _isFarming
	) external onlyOperator returns (bool) {
		isPOLKANFTs[_polkaNFT] = _isPOLKANFT;
		if (_isFarming) {
			isFarmingNFTs[_polkaNFT] = true;
		}
		return true;
	}

	function setReferralContract(address _referralContract) public onlyOwner returns (bool) {
		referralContract = _referralContract;
		return true;
	}

	function setPaymentMethod(address _token, bool _status) public onlyOwner returns (bool) {
		paymentMethod[_token] = _status;
		if (_token != address(0)) {
			IERC20(_token).safeApprove(msg.sender, (2**256 - 1));
			IERC20(_token).safeApprove(address(this), (2**256 - 1));
		}
		return true;
	}

	/**
	 * @notice withdrawFunds
	 */
	function withdrawFunds(address payable _beneficiary, address _tokenAddress) external onlyOwner whenPaused {
		uint256 _withdrawAmount;
		if (_tokenAddress == address(0)) {
			_beneficiary.transfer(address(this).balance);
			_withdrawAmount = address(this).balance;
		} else {
			_withdrawAmount = IERC20(_tokenAddress).balanceOf(address(this));
			IERC20(_tokenAddress).safeTransfer(_beneficiary, _withdrawAmount);
		}
	}
}

contract MarketV3 is Manager, ERC1155Holder, ERC721Holder, ReentrancyGuard {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	using Address for address payable;

	//	uint256 public constant ZOOM_POLKA = 10**18;
	uint256 public constant ZOOM_USDT = 10**6;
	uint256 public constant ZOOM_FEE = 10**4;
	uint256 public totalOrders;
	uint256 public totalBids;
	bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
	bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

	struct Order {
		address owner;
		address tokenAddress;
		address paymentToken;
		uint256 tokenId;
		uint256 quantity;
		uint256 price; // price of 1 NFT in paymentToken
		bool isOnsale; // true: on sale, false: cancel
		bool isERC721;
	}

	struct Bid {
		address bidder;
		address paymentToken;
		address tokenAddress;
		uint256 tokenId;
		uint256 bidPrice;
		uint256 quantity;
		uint256 expTime;
		bool status;
	}

	mapping(uint256 => Order) public orders;
	mapping(bytes32 => uint256) private orderID;
	mapping(uint256 => Bid) public bids;

	//hold: createBid
	mapping(address => uint256) public adminHoldPayment;

	event OrderCreated(uint256 _orderId, address _tokenAddress, uint256 _tokenId, uint256 _quantity, uint256 _price);
	event Buy(uint256 _itemId, uint256 _quantity, address _paymentToken, uint256 _paymentAmount);
	event OrderCancelled(uint256 indexed _orderId);
	event OrderUpdated(uint256 indexed _orderId);
	event BidCreated(
		uint256 indexed _bidId,
		address _tokenAddress,
		uint256 indexed _tokenId,
		uint256 indexed _quantity,
		uint256 _price,
		address _paymentToken
	);
	event AcceptBid(uint256 indexed _bidId);
	event BidUpdated(uint256 indexed _bidId);
	event BidCancelled(uint256 indexed _bidId);

	constructor() Manager() {}

	function getRefData(address _user) private view returns (address payable) {
		address payable userRef = IReferral(referralContract).getReferral(_user);
		return userRef;
	}

	function _paid(
		address _token,
		address _to,
		uint256 _amount
	) private {
		require(_to != address(0), 'Invalid-address');
		if (_token == address(0)) {
			payable(_to).sendValue(_amount);
		} else {
			IERC20(_token).safeTransfer(_to, _amount);
		}
	}

	function _updateBid(uint256 _bidId, uint256 _quantity) private returns (bool) {
		Bid memory bid = bids[_bidId];
		bid.quantity = bid.quantity.sub(_quantity);
		bid.status = false;
		bids[_bidId] = bid;
		return true;
	}

	function _updateOrder(
		address _buyer,
		address _paymentToken,
		uint256 _orderId,
		uint256 _quantity,
		bytes32 _id
	) private returns (bool) {
		Order memory order = orders[_orderId];
		if (order.isERC721) {
			IERC721(order.tokenAddress).safeTransferFrom(address(this), _buyer, order.tokenId);
		} else {
			IERC1155(order.tokenAddress).safeTransferFrom(
				address(this),
				_buyer,
				order.tokenId,
				_quantity,
				abi.encodePacked(keccak256('onERC1155Received(address,address,uint256,uint256,bytes)'))
			);
		}
		order.quantity = order.quantity.sub(_quantity);
		orders[_orderId].quantity = order.quantity;

		return true;
	}

	/**
	 * @dev Matching order mechanism
	 * @param _buyer is address of buyer
	 * @param _orderId is id of order
	 * @param _quantity is total amount to buy
	 * @param _paymentToken is payment method (USDT, ETH, ...)
	 */

	function _match(
		address _buyer,
		address _paymentToken,
		uint256 _orderId,
		uint256 _quantity,
		uint256 orderAmount,
		address payable sellerRef,
		address payable buyerRef
	) private returns (bool) {
		Order memory order = orders[_orderId];
		address payable creator = payable(IPOLKANFT(order.tokenAddress).getCreator(order.tokenId));
		uint256 loyaltyFee = IPOLKANFT(order.tokenAddress).getLoyaltyFee(order.tokenId);
		uint256 nftXUserFee = IPOLKANFT(order.tokenAddress).getXUserFee(order.tokenId);

		if (buyerRef != address(0)) {
			uint256 amountToBuyerRef = orderAmount.mul(nftXUserFee).mul(ZOOM_FEE - yRefRate).div(ZOOM_FEE**2); // 1.25
			_paid(_paymentToken, buyerRef, amountToBuyerRef);
		}

		if (creator != address(0)) {
			_paid(
				_paymentToken,
				creator,
				orderAmount.mul(loyaltyFee).div(ZOOM_FEE) // take retailFee for retailer
			);
		}

		_paid(_paymentToken, order.owner, orderAmount);

		return
			_updateOrder(
				_buyer,
				_paymentToken,
				_orderId,
				_quantity,
				keccak256(abi.encodePacked(order.tokenAddress, order.tokenId))
			);
	}

	/**
	 * @dev Allow user create order on market
	 * @param _tokenAddress is address of NFTs
	 * @param _tokenId is id of NFTs
	 * @param _quantity is total amount for sale
	 * @param _price is price per item in payment method (example 50 USDT)
	 * @param _paymentToken is payment method (USDT, ETH, ...)
	 * @return _orderId uint256 for _orderId
	 */
	function createOrder(
		address _tokenAddress,
		address _paymentToken,
		uint256 _tokenId,
		uint256 _quantity,
		uint256 _price
	) external whenNotPaused returns (uint256) {
		require(paymentMethod[_paymentToken], 'Payment-method-does-not-support');
		bool isERC721 = IERC721(_tokenAddress).supportsInterface(_INTERFACE_ID_ERC721);
		uint256 balance;

		uint256 _orderId = totalOrders;

		if (isERC721) {
			balance = (IERC721(_tokenAddress).ownerOf(_tokenId) == msg.sender) ? 1 : 0;
			require(balance >= _quantity, 'Insufficient-token-balance');
		} else {
			balance = IERC1155(_tokenAddress).balanceOf(msg.sender, _tokenId);
			require(balance >= _quantity, 'Insufficient-token-balance');
		}

		if (isERC721) {
			IERC721(_tokenAddress).safeTransferFrom(msg.sender, address(this), _tokenId);
		} else {
			IERC1155(_tokenAddress).safeTransferFrom(msg.sender, address(this), _tokenId, _quantity, '0x');
		}

		Order memory newOrder;
		newOrder.isOnsale = true;
		newOrder.owner = msg.sender;
		newOrder.price = _price;
		newOrder.quantity = _quantity;
		newOrder.tokenId = _tokenId;
		newOrder.isERC721 = isERC721;
		newOrder.tokenAddress = _tokenAddress;
		newOrder.paymentToken = _paymentToken;

		orders[_orderId] = newOrder;

		totalOrders = totalOrders.add(1);

		emit OrderCreated(_orderId, _tokenAddress, _tokenId, _quantity, _price);

		return _orderId;
	}

	function buy(
		uint256 _orderId,
		uint256 _quantity,
		address _paymentToken
	) external payable whenNotPaused returns (bool) {
		Order memory order = orders[_orderId];
		require(order.owner != address(0), 'Invalid-order-id');
		require(paymentMethod[_paymentToken], 'Payment-method-does-not-support');
		require(_paymentToken == order.paymentToken, 'Payment-token-invalid');
		require(order.isOnsale && order.quantity >= _quantity, 'Not-available-to-buy');

		uint256 orderAmount = order.price.mul(_quantity);
		uint256 exactPaymentAmount;
		uint256 loyaltyFee = IPOLKANFT(order.tokenAddress).getLoyaltyFee(order.tokenId);
		uint256 nftXUserFee = IPOLKANFT(order.tokenAddress).getXUserFee(order.tokenId);

		exactPaymentAmount = orderAmount.mul(ZOOM_FEE + nftXUserFee + loyaltyFee).div(ZOOM_FEE);

		if (_paymentToken == address(0) && msg.value > 0) {
			require(msg.value >= exactPaymentAmount, 'Payment-value-invalid');
		} else {
			IERC20(_paymentToken).safeTransferFrom(msg.sender, address(this), exactPaymentAmount);
		}
		emit Buy(_orderId, _quantity, _paymentToken, exactPaymentAmount);
		return
			_match(
				msg.sender,
				_paymentToken,
				_orderId,
				_quantity,
				orderAmount,
				getRefData(order.owner),
				getRefData(msg.sender)
			);
	}

	function createBid(
		address _tokenAddress,
		address _paymentToken, // payment method
		uint256 _tokenId,
		uint256 _quantity, // total amount want to buy
		uint256 _price, // price of 1 nft
		uint256 _expTime
	) external payable whenNotPaused returns (uint256 _bidId) {
		require(_quantity > 0, 'Invalid-quantity');
		require(paymentMethod[_paymentToken], 'Payment-method-does-not-support');

		Bid memory newBid;
		newBid.bidder = msg.sender;
		newBid.bidPrice = _price;
		newBid.quantity = _quantity;
		newBid.tokenId = _tokenId;
		newBid.tokenAddress = _tokenAddress;

		if (msg.value > 0) {
			require(msg.value >= _quantity.mul(_price), 'Invalid-amount');
			newBid.paymentToken = address(0);
		} else {
			newBid.paymentToken = _paymentToken;
		}

		if (newBid.paymentToken != address(0)) {
			IERC20(newBid.paymentToken).safeTransferFrom(newBid.bidder, address(this), _quantity.mul(_price));
		}
		adminHoldPayment[_paymentToken] = adminHoldPayment[_paymentToken].add(_quantity.mul(_price));

		newBid.status = true;
		newBid.expTime = _expTime;
		bids[totalBids] = newBid;

		_bidId = totalBids;
		totalBids = totalBids.add(1);
		emit BidCreated(_bidId, _tokenAddress, _tokenId, _quantity, _price, _paymentToken);
		return _bidId;
	}

	function acceptBid(
		uint256 _bidId,
		uint256 _quantity,
		uint256 _orderId
	) external whenNotPaused returns (bool) {
		Bid memory bid = bids[_bidId];
		Order memory order = orders[_orderId];
		require(order.owner == msg.sender && order.isOnsale, 'Oops!Wrong-order-owner-or-cancelled');
		require(bid.paymentToken == order.paymentToken, 'Payment-token-invalid');
		require(bid.tokenAddress == order.tokenAddress && bid.tokenId == order.tokenId, 'Wrong-token');
		require(
			order.quantity >= _quantity && _quantity <= bid.quantity && bid.status,
			'Invalid-quantity-or-bid-cancelled'
		);

		uint256 orderAmount = bid.bidPrice.mul(_quantity);
		uint256 loyaltyFee = IPOLKANFT(order.tokenAddress).getLoyaltyFee(order.tokenId);
		uint256 nftXUserFee = IPOLKANFT(order.tokenAddress).getXUserFee(order.tokenId);

		adminHoldPayment[bid.paymentToken] = adminHoldPayment[bid.paymentToken].sub(orderAmount);

		_match(
			bid.bidder,
			bid.paymentToken,
			_orderId,
			_quantity,
			orderAmount.mul(ZOOM_FEE).div(ZOOM_FEE.add(nftXUserFee).add(loyaltyFee)),
			getRefData(msg.sender),
			getRefData(bid.bidder)
		);
		emit AcceptBid(_bidId);
		return _updateBid(_bidId, _quantity);
	}

	function cancelOrder(uint256 _orderId) external whenNotPaused {
		Order memory order = orders[_orderId];
		require(order.owner == msg.sender && order.isOnsale, 'Oops!Wrong-order-owner-or-cancelled');
		require(order.quantity > 0, 'Order-sold-out');

		if (order.isERC721) {
			IERC721(order.tokenAddress).safeTransferFrom(address(this), order.owner, order.tokenId);
		} else {
			IERC1155(order.tokenAddress).safeTransferFrom(
				address(this),
				order.owner,
				order.tokenId,
				order.quantity,
				abi.encodePacked(keccak256('onERC1155Received(address,address,uint256,uint256,bytes)'))
			);
		}
		order.isOnsale = false;
		order.quantity = 0;

		orders[_orderId] = order;

		emit OrderCancelled(_orderId);
	}

	function cancelBid(uint256 _bidId) external whenNotPaused nonReentrant {
		Bid memory bid = bids[_bidId];
		require(bid.bidder == msg.sender && bid.status, 'Invalid-bidder');
		if (bid.paymentToken == address(0)) {
			uint256 payBackAmount = bid.quantity.mul(bid.bidPrice);
			payable(msg.sender).sendValue(payBackAmount);
		} else {
			IERC20(bid.paymentToken).safeTransferFrom(address(this), bid.bidder, bid.quantity.mul(bid.bidPrice));
		}

		adminHoldPayment[bid.paymentToken] = adminHoldPayment[bid.paymentToken].sub(bid.quantity.mul(bid.bidPrice));

		bid.status = false;
		bid.quantity = 0;
		bids[_bidId] = bid;
		emit BidCancelled(_bidId);
	}

	function adminMigrateOrders(
		address oldMarket,
		uint256 startId,
		uint256 endId
	) external onlyOwner {
		totalOrders = IPolkaMarket(oldMarket).totalOrders();

		require(startId < totalOrders, 'StartId-more-than-maxid');
		if (endId > totalOrders - 1) {
			endId = totalOrders - 1;
		}
		for (uint256 i = startId; i <= endId; i++) {
			(
				address owner,
				address tokenAddress,
				address paymentToken,
				uint256 tokenId,
				uint256 quantity,
				uint256 price,
				bool isOnsale,
				bool isERC721,
				uint256 fromVersion,
				uint256 toVersion
			) = IPolkaMarket(oldMarket).orders(i);

			if (quantity > 0) {
				Order memory newOrder;
				newOrder.isOnsale = isOnsale;
				newOrder.isERC721 = isERC721;
				newOrder.owner = owner;
				newOrder.price = price;
				newOrder.quantity = quantity;
				newOrder.tokenId = tokenId;
				newOrder.tokenAddress = tokenAddress;
				newOrder.paymentToken = paymentToken;
				orders[i] = newOrder;
			}
		}
	}

	function adminMigratePushNFT(
		address newMarket,
		uint256 startId,
		uint256 endId
	) external onlyOwner {
		//totalOrders = IPolkaMarket(oldMarket).totalOrders();
		require(startId < totalOrders, 'StartId-more-than-maxid');
		if (endId > totalOrders - 1) {
			endId = totalOrders - 1;
		}
		for (uint256 i = startId; i <= endId; i++) {
			Order memory order = orders[i];

			if (order.quantity > 0) {
				if (order.isERC721) {
					if (IERC721(order.tokenAddress).ownerOf(order.tokenId) == address(this)) {
						IERC721(order.tokenAddress).safeTransferFrom(address(this), newMarket, order.tokenId);
					}
				} else {
					uint256 quantityOf = IERC1155(order.tokenAddress).balanceOf(address(this), order.tokenId);
					if (quantityOf > 0) {
						IERC1155(order.tokenAddress).safeTransferFrom(
							address(this),
							newMarket,
							order.tokenId,
							quantityOf,
							abi.encodePacked(keccak256('onERC1155Received(address,address,uint256,uint256,bytes)'))
						);
					}
				}
			}
		}
	}

	function adminMigrateBids(
		address oldMarket,
		uint256 startId,
		uint256 endId
	) external onlyOwner {
		totalBids = IPolkaMarket(oldMarket).totalBids();

		require(startId < totalBids, 'StartId-more-than-maxid');
		if (endId > totalBids - 1) {
			endId = totalBids - 1;
		}

		for (uint256 j = startId; j <= endId; j++) {
			(
				address bidder,
				address paymentToken,
				address tokenAddress,
				uint256 tokenId,
				uint256 bidPrice,
				uint256 quantity,
				uint256 expTime,
				bool status,
				uint256 version
			) = IPolkaMarket(oldMarket).bids(j);
			if (quantity > 0) {
				Bid memory newBid;
				newBid.bidder = bidder;
				newBid.paymentToken = paymentToken;
				newBid.tokenAddress = tokenAddress;
				newBid.tokenId = tokenId;
				newBid.bidPrice = bidPrice;
				newBid.quantity = quantity;
				newBid.expTime = expTime;
				newBid.status = status;
				bids[j] = newBid;

				if (status) {
					adminHoldPayment[paymentToken] = adminHoldPayment[paymentToken].add(quantity.mul(bidPrice));
				}
			}
		}
	}

	function sendPaymentToNewContract(address _token, address _newContract) external onlyOwner {
		require(_newContract != address(0), 'Invalid-address');
		if (_token == address(0)) {
			payable(_newContract).sendValue(adminHoldPayment[_token]);
		} else {
			IERC20(_token).safeTransfer(_newContract, adminHoldPayment[_token]);
		}
	}

	function setApproveForAll(address _token, address _spender) external onlyOwner {
		IERC1155(_token).setApprovalForAll(_spender, true);
	}

	function setApproveForAllERC721(address _token, address _spender) external onlyOwner {
		IERC721(_token).setApprovalForAll(_spender, true);
	}
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IReferral {
	function getReferral(address user) external view returns (address payable);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IPOLKANFT {
	function getCreator(uint256 _id) external view returns (address);

	function getLoyaltyFee(uint256 _id) external view returns (uint256);

	function getXUserFee(uint256 _id) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IWBNB {
	function deposit() external payable returns (bool);

	function withdraw(uint256 _id) external returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IPolkaMarket {
	function orders(uint256 id)
		external
		view
		returns (
			address,
            address,
            address,
            uint256,
            uint256,
            uint256,
            bool,
            bool,
            uint256,
            uint256
		);

    function bids(uint256 id)
		external
		view
		returns (
			address,
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
		);

    function totalOrders() external view returns(uint256);
    function totalBids() external view returns(uint256);

    function setApproveForAll(address _token, address _spender) external;
    function setApproveForAllERC721(address _token, address _spender) external;

    function nftVersion(address _tokenAddress, uint256 _tokenId, uint256 _version) external view returns(address);
    function nftVersionOnSale(address _tokenAddress, uint256 _tokenId, uint256 _version) external view returns(bool);
    function orderIdByVersion(address _tokenAddress, uint256 _tokenId, uint256 _version) external view returns(uint256);

    function createVersionNFT(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _fromVersion,
        uint256 _toVersion,
        address _owner
    ) external;


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
	/**
	 * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
	 */
	event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

	/**
	 * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
	 * transfers.
	 */
	event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

	/**
	 * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
	 * `approved`.
	 */
	event ApprovalForAll(address indexed account, address indexed operator, bool approved);

	/**
	 * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
	 *
	 * If an {URI} event was emitted for `id`, the standard
	 * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
	 * returned by {IERC1155MetadataURI-uri}.
	 */
	event URI(string value, uint256 indexed id);

	/**
	 * @dev Returns the amount of tokens of token type `id` owned by `account`.
	 *
	 * Requirements:
	 *
	 * - `account` cannot be the zero address.
	 */
	function balanceOf(address account, uint256 id) external view returns (uint256);

	/**
	 * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
	 *
	 * Requirements:
	 *
	 * - `accounts` and `ids` must have the same length.
	 */
	function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

	/**
	 * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
	 *
	 * Emits an {ApprovalForAll} event.
	 *
	 * Requirements:
	 *
	 * - `operator` cannot be the caller.
	 */
	function setApprovalForAll(address operator, bool approved) external;

	/**
	 * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
	 *
	 * See {setApprovalForAll}.
	 */
	function isApprovedForAll(address account, address operator) external view returns (bool);

	/**
	 * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
	 *
	 * Emits a {TransferSingle} event.
	 *
	 * Requirements:
	 *
	 * - `to` cannot be the zero address.
	 * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
	 * - `from` must have a balance of tokens of type `id` of at least `amount`.
	 * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
	 * acceptance magic value.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes calldata data
	) external;

	/**
	 * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
	 *
	 * Emits a {TransferBatch} event.
	 *
	 * Requirements:
	 *
	 * - `ids` and `amounts` must have the same length.
	 * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
	 * acceptance magic value.
	 */
	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] calldata ids,
		uint256[] calldata amounts,
		bytes calldata data
	) external;

	function getCreator(uint256 _id) external view returns (address);

	function getLoyaltyFee(uint256 _id) external view returns (uint256);

	function nftOwnVersion(uint256 _tokenId, uint256 _version) external view returns (address);
    function nftOnSaleVersion(uint256 _tokenId, uint256 _version) external view returns (bool);
    function setNftOwnVersion(uint256 _tokenId, uint256 _version, address _owner) external;
    function setNftOnSaleVersion(uint256 _tokenId, uint256 _version, bool _isOnSale) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/utils/ERC721Holder.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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