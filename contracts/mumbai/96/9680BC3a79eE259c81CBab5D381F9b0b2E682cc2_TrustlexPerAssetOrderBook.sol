/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: contracts/contracts_trustless/IERC20.sol


pragma solidity >=0.4.22 <0.9.0;
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
// File: contracts/contracts_trustless/ISPVChain.sol


pragma solidity >=0.4.22 <0.9.0;

struct BlockHeader {
        bytes32 previousHeaderHash;
        bytes32 merkleRootHash;
        uint256 compactBytes;
}

interface ISPVChain {
      function submitBlock(bytes calldata blockHeaderBytes) external;
      function getTxMerkleRootAtHeight(uint256 height) external view returns (bytes32);
      function getBlockHeader(uint256 height) external view returns (BlockHeader memory);
      function getBlockHeader(bytes32 blockHash) external view returns (BlockHeader memory);
}

interface ITxVerifier {
      function verifyTxInclusionProof(bytes32 txId, uint32 blockHeight, uint256 index, bytes calldata hashes) external view returns (bool result);
}

interface IGov {
      function updateConfirmations(uint32 confirmations, bytes32 currentBlockHash) external;
}

// File: contracts/contracts_trustless/SafeMath.sol

pragma solidity >=0.4.22 <0.9.0;

/*
The MIT License (MIT)
Copyright (c) 2016 Smart Contract Solutions, Inc.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        require(c / _a == _b, "Overflow during multiplication.");
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, "Underflow during subtraction.");
        return _a - _b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        require(c >= _a, "Overflow during addition.");
        return c;
    }
}
// File: contracts/contracts_trustless/BitcoinUtils.sol


pragma solidity >=0.4.22 <0.9.0;


library BitcoinUtils {
  
  using SafeMath for uint256;

  /** Retarget period for Bitcoin Difficulty Adjustment */
  uint256 public constant RETARGET_PERIOD = 2 * 7 * 24 * 60 * 60;  // 2 weeks in seconds

    /**
     input: 0x...01020304....., 3
     output: 0x04030201
   */
  function _leToUint32(bytes calldata bz, uint startIndex) pure public returns (uint32 result) {
    bytes4 v = bytes4(bz[startIndex: startIndex+4]);

    // swap bytes
    v = ((v >> 8) & 0x00FF00FF) |
         ((v & 0x00FF00FF) << 8);
    // swap 2-byte long pairs
    v = ((v >> 16) & 0x0000FFFF) |
         ((v & 0x0000FFFF) << 16);

    result = uint32(v);
  }

  /**
     input: 0x...01020304....., 3
     output: 0x04030201
   */
  function _leToBytes4(bytes calldata bz, uint startIndex) pure public returns (bytes4 result) {

    result = bytes4(bz[startIndex: startIndex+4]);

    // swap bytes
    result = ((result >> 8) & 0x00FF00FF) |
         ((result & 0x00FF00FF) << 8);
    // swap 2-byte long pairs
    result = ((result >> 16) & 0x0000FFFF) |
         ((result & 0x0000FFFF) << 16);

    return result;
  }

  /**
      input: 0x...000102030405060708090A0B0C0D0E0F0102030405060708090A0B0C0D0E0F...., 32
      output: 0x0F0E0D0C0B0A090807060504030201000F0E0D0C0B0A09080706050403020100
   */

  function _leToBytes32(bytes calldata bz, uint startIndex) pure public returns (bytes32 result) {

    result = bytes32(bz[startIndex: startIndex+32]);

    result = swapEndian(result);
  }

  function swapEndian(bytes32 bz) pure internal returns (bytes32 result) {

    result = bz;

    // swap bytes
    result = ((result >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
            ((result & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
    // swap 2-byte long pairs
    result = ((result >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
            ((result & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
    // swap 4-byte long pairs
    result = ((result >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
            ((result & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
    // swap 8-byte long pairs
    result = ((result >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
            ((result & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
    // swap 16-byte long pairs
    result = (result >> 128) | (result << 128);
    return result;
  }

  function _nBitsToTarget(bytes4 nBits) pure internal returns (uint256 target) {
    uint256 _mantissa = uint256(uint32(nBits) & 0x007fffff);
    uint256 _exponent = (uint256(uint32(nBits) & uint32(0xff000000)) >> 24).sub(3);
    return _mantissa.mul(256 ** _exponent);
  }

  function _targetToNBits(uint256 target) pure internal returns (uint32 compact) {
     if (target == 0) {
        return 0;
     }
     // Since the base for the exponent is 256, the exponent can be treated
     // as the number of bytes.  So, shift the number right or left
     // accordingly.  This is equivalent to:
     // mantissa = mantissa / 256^(exponent-3)
	uint32 mantissa;
	uint32 exponent = 0;
        uint256 _target = target;
        while (_target != 0) {
                exponent++;
                _target >>= 8;
        }
        if (exponent <= 3) {
		mantissa = uint32(target & 0xffffffff);
		mantissa <<= 8 * (3 - exponent);
	} else {
		// Use a copy to avoid modifying the caller's original number.
		mantissa = uint32((target >> (8 * (exponent - 3))) & 0xffffffff);
	}

	// When the mantissa already has the sign bit set, the number is too
	// large to fit into the available 23-bits, so divide the number by 256
	// and increment the exponent accordingly.
	if ((mantissa & 0x00800000) != 0) {
		mantissa >>= 8;
		exponent++;
	}

	// Pack the exponent, sign bit, and mantissa into an unsigned 32-bit
	// int and return it.
	compact = uint32(exponent<<24) | mantissa;

	return compact;
  }

  /** 
    Code copied from
    https://github.com/summa-tx/bitcoin-spv/blob/master/solidity/contracts/ViewBTC.sol#L493
   */
  function _retargetAlgorithm(
        uint256 _previousTarget,
        uint256 _firstTimestamp,
        uint256 _secondTimestamp
    ) internal pure returns (uint256) {
        uint256 _elapsedTime = _secondTimestamp.sub(_firstTimestamp);

        // Normalize ratio to factor of 4 if very long or very short
        if (_elapsedTime < RETARGET_PERIOD.div(4)) {
            _elapsedTime = RETARGET_PERIOD.div(4);
        }
        if (_elapsedTime > RETARGET_PERIOD.mul(4)) {
            _elapsedTime = RETARGET_PERIOD.mul(4);
        }

        /*
            NB: high targets e.g. ffff0020 can cause overflows here
                so we divide it by 256**2, then multiply by 256**2 later
                we know the target is evenly divisible by 256**2, so this isn't an issue
        */
        uint256 _adjusted = _previousTarget.div(65536).mul(_elapsedTime);
        return _adjusted.div(RETARGET_PERIOD).mul(65536);
    }
    
}
// File: contracts/contracts_trustless/TrustlexPerAssetOrderBook.sol


pragma solidity >=0.4.22 <0.9.0;






contract TrustlexPerAssetOrderBook is Ownable {
    IERC20 public MyTokenERC20;
    uint32 public fullFillmentExpiryTime;
    struct FulfillmentRequest {
        address fulfillmentBy;
        uint64 quantityRequested;
        uint32 expiryTime;
        uint256 totalCollateralAdded;
        address collateralAddedBy;
        uint32 fulfilledTime;
        bool allowAnyoneToSubmitPaymentProofForFee;
        bool allowAnyoneToAddCollateralForFee;
        bool paymentProofSubmitted;
        bool isExpired;
    }

    struct Offer {
        uint256 offerQuantity;
        address offeredBy;
        uint32 offerValidTill;
        uint32 orderedTime;
        uint32 offeredBlockNumber;
        bytes20 bitcoinAddress;
        uint64 satoshisToReceive;
        uint64 satoshisReceived;
        uint64 satoshisReserved;
        uint8 collateralPer3Hours;
        uint256[] fulfillmentRequests;
    }

    struct ResultOffer {
        uint256 offerId;
        Offer offer;
    }

    struct ResultFulfillmentRequest {
        FulfillmentRequest fulfillmentRequest;
        uint256 fulfillmentRequestId;
    }

    struct CompactMetadata {
        address tokenContract; // 20 bytes
        uint32 totalOrdersInOrderBook; // total orders in order book
    }

    uint256 public orderBookCompactMetadata;

    // mapping(uint256 offerId => mapping(uint256 fullfillmentId => FulfillmentRequest fullfillmentData))
    mapping(uint256 => mapping(uint256 => FulfillmentRequest))
        public initializedFulfillments;

    mapping(uint256 => Offer) public offers;

    event NEW_OFFER(address indexed offeredBy, uint256 indexed offerId);

    event INITIALIZED_FULFILLMENT(
        address indexed claimedBy,
        uint256 indexed offerId,
        uint256 indexed fulfillmentId
    );

    event PAYMENT_SUCCESSFUL(
        address indexed submittedBy,
        uint256 indexed offerId,
        uint256 indexed fulfillmentId
    );

    constructor(address _tokenContract) {
        orderBookCompactMetadata = (uint256(uint160(_tokenContract)) <<
            (12 * 8));
        MyTokenERC20 = IERC20(_tokenContract);
        fullFillmentExpiryTime = 1 * 60;
    }

    function deconstructMetadata()
        public
        view
        returns (CompactMetadata memory result)
    {
        uint256 compactMetadata = orderBookCompactMetadata;
        result.totalOrdersInOrderBook = uint32(
            (compactMetadata >> (8 * 8)) & (0xffffffff)
        );
        result.tokenContract = address(uint160(compactMetadata >> (12 * 8)));
    }

    function updateMetadata(CompactMetadata memory metadata) private {
        uint256 compactMeta = 0;
        compactMeta = (uint256(uint160(metadata.tokenContract)) << (12 * 8));
        compactMeta |= (uint256(metadata.totalOrdersInOrderBook) << (8 * 8));
        orderBookCompactMetadata = compactMeta;
    }

    function setFullFillmentExpiryTime(uint32 expiryTime) public onlyOwner {
        fullFillmentExpiryTime = expiryTime;
    }

    function getTotalOffers() public view returns (uint256) {
        return ((orderBookCompactMetadata >> (8 * 8)) & 0xffffffff);
    }

    // This function will return the full offer details
    function getOffer(
        uint256 offerId
    ) public view returns (Offer memory offer) {
        offer = offers[offerId];
    }

    function getOffers(
        uint256 fromOfferId
    ) public view returns (ResultOffer[50] memory result, uint256 total) {
        uint256 min = 0;
        if (fromOfferId >= 50) {
            min = fromOfferId - 50;
        }
        if (getTotalOffers() < fromOfferId) {
            fromOfferId = getTotalOffers();
        }
        for (uint256 offerId = uint256(fromOfferId); offerId > min; offerId--) {
            result[total++] = ResultOffer({
                offerId: offerId - 1,
                offer: offers[offerId - 1]
            });
        }
    }

    function addOfferWithEth(
        uint256 weieth,
        uint64 satoshis,
        bytes20 bitcoinAddress,
        uint32 offerValidTill
    ) public payable {
        CompactMetadata memory compact = deconstructMetadata();
        require(compact.tokenContract == address(0x0));
        require(msg.value >= weieth, "Please send the correct eth amount!");
        Offer memory offer;
        offer.offeredBy = msg.sender;
        offer.offerQuantity = msg.value;
        offer.satoshisToReceive = satoshis;
        offer.bitcoinAddress = bitcoinAddress;
        offer.offerValidTill = offerValidTill;
        offer.offeredBlockNumber = uint32(block.number);
        offer.orderedTime = uint32(block.timestamp);

        uint256 offerId = compact.totalOrdersInOrderBook;
        offers[offerId] = offer;
        emit NEW_OFFER(msg.sender, offerId);
        compact.totalOrdersInOrderBook = compact.totalOrdersInOrderBook + 1;
        updateMetadata(compact);
    }

    function addOfferWithToken(
        uint256 value,
        uint64 satoshis,
        bytes20 bitcoinAddress,
        uint32 offerValidTill
    ) public {
        require(
            value <= MyTokenERC20.allowance(msg.sender, address(this)),
            "Sender does not have allownace."
        );

        // transfer the tokens
        MyTokenERC20.transferFrom(msg.sender, address(this), value);

        CompactMetadata memory compact = deconstructMetadata();
        require(compact.tokenContract != address(0x0));
        Offer memory offer;
        offer.offeredBy = msg.sender;
        offer.offerQuantity = value;
        offer.satoshisToReceive = satoshis;
        offer.bitcoinAddress = bitcoinAddress;
        offer.offerValidTill = offerValidTill;
        offer.offeredBlockNumber = uint32(block.number);
        uint256 offerId = compact.totalOrdersInOrderBook;
        offers[offerId] = offer;
        emit NEW_OFFER(msg.sender, offerId);
        compact.totalOrdersInOrderBook = compact.totalOrdersInOrderBook + 1;
        updateMetadata(compact);
    }

    function initiateFulfillment(
        uint256 offerId,
        FulfillmentRequest calldata _fulfillment
    ) public payable {
        CompactMetadata memory compact = deconstructMetadata();
        Offer memory offer = offers[offerId];
        uint64 satoshisToReceive = offer.satoshisToReceive;
        uint64 satoshisReserved = offer.satoshisReserved;
        uint64 satoshisReceived = offer.satoshisReceived;

        // if (satoshisToReceive == (satoshisReserved + satoshisReceived)) {
        // Expire older fulfillments
        uint256[] memory fulfillmentIds = offer.fulfillmentRequests;
        for (uint256 index = 0; index < fulfillmentIds.length; index++) {
            FulfillmentRequest
                memory existingFulfillmentRequest = initializedFulfillments[
                    offerId
                ][fulfillmentIds[index]];
            if (
                existingFulfillmentRequest.expiryTime < block.timestamp &&
                existingFulfillmentRequest.isExpired == false
            ) {
                // TODO: Claim any satoshis reserved
                offer.satoshisReserved -= existingFulfillmentRequest
                    .quantityRequested;

                initializedFulfillments[offerId][fulfillmentIds[index]]
                    .isExpired = true;
                // TODO: Claim collateral
            }
        }
        satoshisReserved = offer.satoshisReserved;
        // }

        require(
            satoshisToReceive >=
                (satoshisReserved +
                    satoshisReceived +
                    _fulfillment.quantityRequested),
            "satoshisToReceive is not equal or greater than sum of satoshisReserved amount ,satoshisReceived, current requested quanity"
        );
        FulfillmentRequest memory fulfillment = _fulfillment;
        fulfillment.fulfillmentBy = msg.sender;
        fulfillment.isExpired = false;

        if (satoshisReserved > 0) {
            require(
                fulfillment.totalCollateralAdded > offer.collateralPer3Hours,
                "fulfillment.totalCollateralAdded > offer.collateralPer3Hours condition failed !"
            );
        }
        if (
            fulfillment.totalCollateralAdded > 0 &&
            compact.tokenContract == address(0x0)
        ) {
            fulfillment.totalCollateralAdded = msg.value;
        } else if (fulfillment.totalCollateralAdded > 0) {
            // TODO: Get tokens from tokenContract
            fulfillment.collateralAddedBy = msg.sender;
        }
        fulfillment.expiryTime =
            uint32(block.timestamp) +
            fullFillmentExpiryTime; //Adding 3 hours by Glen
        // uint256 fulfillmentId = uint256(
        //     keccak256(abi.encode(fulfillment, block.timestamp))
        // );
        uint256 fulfillmentId = getOffer(offerId).fulfillmentRequests.length;
        initializedFulfillments[offerId][fulfillmentId] = fulfillment;
        // offers[offerId].satoshisReserved = offer.satoshisReserved;
        offers[offerId].satoshisReserved =
            offer.satoshisReserved +
            _fulfillment.quantityRequested;

        offers[offerId].fulfillmentRequests.push(fulfillmentId);
        emit INITIALIZED_FULFILLMENT(msg.sender, offerId, fulfillmentId);
    }

    // get the initial fullfillments list
    function getInitiateFulfillments(
        uint256 offerId
    ) public view returns (ResultFulfillmentRequest[] memory) {
        uint256[] memory fulfillmentIds = offers[offerId].fulfillmentRequests;
        ResultFulfillmentRequest[]
            memory resultFulfillmentRequest = new ResultFulfillmentRequest[](
                fulfillmentIds.length
            );

        for (uint256 index = 0; index < fulfillmentIds.length; index++) {
            FulfillmentRequest
                memory existingFulfillmentRequest = initializedFulfillments[
                    offerId
                ][fulfillmentIds[index]];
            resultFulfillmentRequest[index] = ResultFulfillmentRequest(
                existingFulfillmentRequest,
                fulfillmentIds[index]
            );
        }

        return resultFulfillmentRequest;
    }

    /*
       validate transaction  and pay all involved parties
    */
    function submitPaymentProof(
        uint256 offerId,
        uint256 fulfillmentId // bytes calldata transaction, // bytes calldata proof, // uint32 blockHeight
    ) public {
        CompactMetadata memory compact = deconstructMetadata();
        // TODO: Validate  transaction here
        require(
            initializedFulfillments[offerId][fulfillmentId].fulfilledTime == 0,
            "fulfilledTime should be 0"
        );
        offers[offerId].satoshisReceived += initializedFulfillments[offerId][
            fulfillmentId
        ].quantityRequested;
        offers[offerId].satoshisReserved -= initializedFulfillments[offerId][
            fulfillmentId
        ].quantityRequested;
        // Send ETH / TOKEN on success
        if (compact.tokenContract == address(0x0)) {
            // (bool success, ) = (
            //     initializedFulfillments[offerId][fulfillmentId].fulfillmentBy
            // ).call{
            //     value: initializedFulfillments[offerId][fulfillmentId]
            //         .quantityRequested
            // }("");
            // calculate the respective eth amount
            uint256 payAmountETh = (
                initializedFulfillments[offerId][fulfillmentId]
                    .quantityRequested
            ) *
                (offers[offerId].offerQuantity /
                    offers[offerId].satoshisToReceive);
            bool success = payable(
                initializedFulfillments[offerId][fulfillmentId].fulfillmentBy
            ).send(payAmountETh);
            require(success, "Transfer failed");
        } else {
            initializedFulfillments[offerId][fulfillmentId]
                .fulfilledTime = uint32(block.timestamp);
            IERC20(compact.tokenContract).transfer(
                initializedFulfillments[offerId][fulfillmentId].fulfillmentBy,
                initializedFulfillments[offerId][fulfillmentId]
                    .quantityRequested
            );
        }
        initializedFulfillments[offerId][fulfillmentId]
            .paymentProofSubmitted = true;
        emit PAYMENT_SUCCESSFUL(msg.sender, offerId, fulfillmentId);
    }

    function addEthCollateral() public payable {}

    function addTokenCollateral() public payable {}

    function extendOffer() public {}

    function liquidateCollateral() public payable {}

    function getBalance() public view returns (uint256 balance) {
        return address(this).balance;
    }
}