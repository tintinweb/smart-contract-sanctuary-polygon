// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "./EIP712MetaTransaction.sol";
import "./interfaces/IDbiliaToken.sol";
import "./interfaces/IPriceCalculation.sol";

//import "hardhat/console.sol";

contract Marketplace is EIP712MetaTransaction, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 public weth;
  IDbiliaToken public dbiliaToken;
  IPriceCalculation public priceCalc;

  // tokenId => price in fiat (USD)
  mapping(uint256 => uint256) public tokenPriceFiat;
  // whether token is on auction for w2user
  mapping(uint256 => bool) public tokenOnAuction;

  // protect public function
  bytes32 internal passcode = "protected";

  // Events
  event SetForSale(
    uint256 _tokenId,
    uint256 _priceFiat,
    bool _auction,
    address indexed _seller,
    uint256 _timestamp
  );

  event RemoveSetForSale(
    uint256 _tokenId,
    address indexed _seller,
    bool _wasOnAuction,
    uint256 _timestamp
  );

  event PurchaseWithFiat(
    uint256 _tokenId,
    address indexed _buyer,
    string _buyerId,
    bool _isW3user,
    address _w3owner,
    string _w2owner,
    uint256 _timestamp
  );

  event PurchaseWithETH(
    uint256 _tokenId,
    address indexed _buyer,
    bool _isW3user,
    address _w3owner,
    string _w2owner,
    uint256 _fee,
    uint256 _creatorReceives,
    uint256 _sellerReceives,
    uint256 _timestamp
  );

  event BiddingWithETH(
    uint256 _tokenId,
    address indexed _bidder,
    uint256 _fee,
    uint256 _creatorReceives,
    uint256 _sellerReceives,
    uint256 _timestamp
  );

  event ClaimAuctionWinner(
    uint256 _tokenId,
    address indexed _receiver,
    string _receiverId,
    uint256 _timestamp
  );

  modifier isActive() {
    require(!dbiliaToken.isMaintaining());
    _;
  }

  modifier onlyDbilia() {
    require(
      msgSender() == dbiliaToken.owner() ||
        dbiliaToken.isAuthorizedAddress(msgSender()),
      "caller is not one of dbilia accounts"
    );
    _;
  }

  // Protect public function with passcode
  modifier verifyPasscode(bytes32 _passcode) {
    require(
      _passcode ==
        keccak256(bytes.concat(passcode, bytes20(address(msgSender())))),
      "invalid passcode"
    );
    _;
  }

  constructor(
    address _tokenAddress,
    address _wethAddress,
    address _priceAddress
  ) EIP712Base(DOMAIN_NAME, DOMAIN_VERSION, block.chainid) {
    dbiliaToken = IDbiliaToken(_tokenAddress);
    weth = IERC20(_wethAddress);
    priceCalc = IPriceCalculation(_priceAddress);
  }

  /**
        SET FOR SALE FUNCTIONS
        - When w2 or w3user wants to put it up for sale
        - trigger getTokenOwnership() by passing in tokenId and find if it belongs to w2 or w3user
        - if w2 or w3user wants to pay in USD, they pay gas fee to Dbilia first
        - then Dbilia triggers setForSaleWithFiat for them
        - if w3user wants to pay in ETH they can trigger setForSaleWithETH,
        - but msgSender() must have the ownership of token
     */

  /**
   * w2, w3user selling a token in USD
   *
   * Preconditions
   * 1. before we make this contract go live,
   * 2. trigger setApprovalForAll() from Dbilia EOA to approve this contract
   * 3. seller pays gas fee in USD
   * 4. trigger getTokenOwnership() and if tokenId belongs to w3user,
   * 5. call isApprovedForAll() first to check whether w3user has approved the contract on his behalf
   * 6. if not, w3user has to trigger setApprovalForAll() with his ETH to trigger setForSaleWithFiat()
   *
   * @param _tokenId token id to sell
   * @param _priceFiat price in USD or in EURto sell
   * @param _auction on auction or not
   */
  function setForSaleWithFiat(
    uint256 _tokenId,
    uint256 _priceFiat,
    bool _auction
  ) external isActive onlyDbilia {
    require(_tokenId > 0, "token id is zero or lower");
    require(
      tokenPriceFiat[_tokenId] == 0,
      "token has already been set for sale"
    );
    require(_priceFiat > 0, "price is zero or lower");
    require(
      dbiliaToken.isApprovedForAll(dbiliaToken.dbiliaTrust(), address(this)),
      "Dbilia did not approve Marketplace contract"
    );
    _addTokenStatus(_tokenId, _priceFiat, _auction);
    emit SetForSale(
      _tokenId,
      _priceFiat,
      _auction,
      msgSender(),
      block.timestamp
    );
  }

  /**
   * w3user selling a token in ETH
   *
   * Preconditions
   * 1. call isApprovedForAll() to check w3user has approved the contract on his behalf
   * 2. if not, trigger setApprovalForAll() from w3user
   *
   * @param _tokenId token id to sell
   * @param _priceFiat price in USD to sell
   * @param _auction on auction or not
   */
  function setForSaleWithETH(
    uint256 _tokenId,
    uint256 _priceFiat,
    bool _auction,
    bytes32 _passcode
  ) external isActive nonReentrant verifyPasscode(_passcode) {
    require(_tokenId > 0, "token id is zero or lower");
    require(
      tokenPriceFiat[_tokenId] == 0,
      "token has already been set for sale"
    );
    require(_priceFiat > 0, "price is zero or lower");
    address owner = dbiliaToken.ownerOf(_tokenId);
    require(owner == msgSender(), "caller is not a token owner");
    require(
      dbiliaToken.isApprovedForAll(msgSender(), address(this)),
      "token owner did not approve Marketplace contract"
    );
    _addTokenStatus(_tokenId, _priceFiat, _auction);
    emit SetForSale(
      _tokenId,
      _priceFiat,
      _auction,
      msgSender(),
      block.timestamp
    );
  }

  /**
   * w2, w3user removing a token in USD
   *
   * @param _tokenId token id to remove
   */
  function removeSetForSaleFiat(uint256 _tokenId) external isActive onlyDbilia {
    require(_tokenId > 0, "token id is zero or lower");
    require(tokenPriceFiat[_tokenId] > 0, "token has not set for sale");
    require(
      dbiliaToken.isApprovedForAll(dbiliaToken.dbiliaTrust(), address(this)),
      "Dbilia did not approve Marketplace contract"
    );
    bool onAuction = tokenOnAuction[_tokenId];
    _resetTokenStatus(_tokenId);
    emit RemoveSetForSale(_tokenId, msgSender(), onAuction, block.timestamp);
  }

  /**
   * w3user removing a token in USD
   *
   * @param _tokenId token id to remove
   */
  function removeSetForSaleETH(uint256 _tokenId, bytes32 _passcode)
    external
    isActive
    nonReentrant
    verifyPasscode(_passcode)
  {
    require(_tokenId > 0, "token id is zero or lower");
    require(tokenPriceFiat[_tokenId] > 0, "token has not set for sale");
    address owner = dbiliaToken.ownerOf(_tokenId);
    require(owner == msgSender(), "caller is not a token owner");
    require(
      dbiliaToken.isApprovedForAll(msgSender(), address(this)),
      "token owner did not approve Marketplace contract"
    );
    bool onAuction = tokenOnAuction[_tokenId];
    _resetTokenStatus(_tokenId);
    emit RemoveSetForSale(_tokenId, msgSender(), onAuction, block.timestamp);
  }

  /**
   * w3user purchasing in USD
   * function triggered by Dbilia
   *
   * Preconditions
   * For NON-AUCTION
   * 1. call getTokenOwnership() to check whether seller is w2 or w3user holding the token
   * 2. if seller is w3user, call ownerOf() to check seller still holds the token
   * 3. call tokenPriceFiat() to get the price of token
   * 4. buyer pays 2.5% fee
   * 5. buyer pays gas fee
   * 6. check buyer paid in correct amount of USD (NFT price + 2.5% fee + gas fee)
   *
   * After purchase
   * 1. increase the seller's internal USD wallet balance
   *    - seller receives = (tokenPriceFiat - seller 2.5% fee - royalty)
   *    - for royalty, use royaltyReceivers(tokenId)
   * 2. increase the royalty receiver's internal USD wallet balance
   *    - for royalty, use royaltyReceivers(tokenId)
   *
   * @param _tokenId token id to buy
   * @param _buyer buyer's w3user id
   */
  function purchaseWithFiatw3user(uint256 _tokenId, address _buyer)
    external
    isActive
    onlyDbilia
  {
    require(tokenPriceFiat[_tokenId] > 0, "seller is not selling this token");
    require(_buyer != address(0), "buyer address is empty");

    address owner = dbiliaToken.ownerOf(_tokenId);
    (bool isW3user, address w3owner, string memory w2owner) = dbiliaToken
      .getTokenOwnership(_tokenId);

    if (isW3user) {
      require(owner == w3owner, "wrong owner");
      require(w3owner != address(0), "w3owner is empty");
      dbiliaToken.safeTransferFrom(w3owner, _buyer, _tokenId);
    } else {
      require(owner == dbiliaToken.dbiliaTrust(), "wrong owner");
      require(bytes(w2owner).length > 0, "w2owner is empty");
      dbiliaToken.safeTransferFrom(dbiliaToken.dbiliaTrust(), _buyer, _tokenId);
    }

    dbiliaToken.changeTokenOwnership(_tokenId, _buyer, "");
    _resetTokenStatus(_tokenId);

    emit PurchaseWithFiat(
      _tokenId,
      _buyer,
      "",
      isW3user,
      w3owner,
      w2owner,
      block.timestamp
    );
  }

  /**
   * w3user purchasing in ETH
   * function triggered by w3user
   *
   * Preconditions
   * For NON-AUCTION
   * 1. call getTokenOwnership() to check whether seller is w2 or w3user holding the token
   * 2. if seller is w3user, call ownerOf() to check seller still holds the token
   * 3. call tokenPriceFiat() to get the price of token
   * 4. do conversion and calculate how much buyer needs to pay in ETH
   * 5. add up buyer fee 2.5% in msg.value
   *
   * After purchase
   * 1. check if seller is a w2user from getTokenOwnership(tokenId)
   * 2. if w2user, increase the seller's internal ETH wallet balance
   *    - use sellerReceiveAmount from the event
   * 3. increase the royalty receiver's internal ETH wallet balance
   *    - use royaltyReceivers(tokenId) to get the in-app address
   *    - use royaltyAmount from the event
   *
   * @param _tokenId token id to buy
   */
  function purchaseWithETHw3user(
    uint256 _tokenId,
    uint256 _wethAmount,
    bytes32 _passcode
  ) external isActive nonReentrant verifyPasscode(_passcode) {
    require(tokenPriceFiat[_tokenId] > 0, "seller is not selling this token");
    // only non-auction items can be purchased from w3user
    require(tokenOnAuction[_tokenId] == false, "this token is on auction");

    priceCalc.validateAmount(tokenPriceFiat[_tokenId], _wethAmount);

    weth.safeTransferFrom(msgSender(), address(this), _wethAmount);

    address owner = dbiliaToken.ownerOf(_tokenId);
    (bool isW3user, address w3owner, string memory w2owner) = dbiliaToken
      .getTokenOwnership(_tokenId);

    if (isW3user) {
      require(owner == w3owner, "wrong owner");
      require(w3owner != address(0), "w3owner is empty");
      dbiliaToken.safeTransferFrom(w3owner, msgSender(), _tokenId);
    } else {
      require(owner == dbiliaToken.dbiliaTrust(), "wrong owner");
      require(bytes(w2owner).length > 0, "w2owner is empty");
      dbiliaToken.safeTransferFrom(
        dbiliaToken.dbiliaTrust(),
        msgSender(),
        _tokenId
      );
    }

    dbiliaToken.changeTokenOwnership(_tokenId, msgSender(), "");

    // calculate buyer, seller fee and send to fee account
    uint256 fee = priceCalc.calcBuyerSellerFee(_wethAmount);
    _send(fee, dbiliaToken.dbiliaFee());

    // calculate royalty amount and send to creator
    (uint256 royaltyAmount, address receiver) = priceCalc.calcRoyalty(
      _tokenId,
      _wethAmount
    );
    _send(royaltyAmount, receiver);

    // calculate seller amount and send
    uint256 sellerAmount = _wethAmount.sub(fee.add(royaltyAmount));
    _send(sellerAmount, isW3user ? w3owner : dbiliaToken.dbiliaTrust());

    _resetTokenStatus(_tokenId);

    emit PurchaseWithETH(
      _tokenId,
      msgSender(),
      isW3user,
      w3owner,
      w2owner,
      fee,
      royaltyAmount,
      sellerAmount,
      block.timestamp
    );
  }

  /**
   * w3user bidding in ETH
   * function triggered by w3user
   *
   * Preconditions
   * For AUCTION
   * 1. call getTokenOwnership() to check whether seller is w2 or w3user holding the token
   * 2. if seller is w3user, call ownerOf() to check seller still holds the token
   * 3. call tokenPriceFiat() to get the price of token
   * 4. buyer pays 2.5% fee
   * 5. buyer pays gas fee
   * 6. check buyer paid in correct amount of USD (NFT price + 2.5% fee + gas fee)
   *
   * After bidding
   * 1. auction history records bidAmount, creatorReceives and sellerReceives
   *
   * @param _tokenId token id to buy
   * @param _bidPriceFiat bid amount in USD or in EUR
   */
  function placeBidWithETHw3user(
    uint256 _tokenId,
    uint256 _bidPriceFiat,
    uint256 _wethAmount,
    bytes32 _passcode
  ) external isActive nonReentrant verifyPasscode(_passcode) {
    require(tokenPriceFiat[_tokenId] > 0, "seller is not selling this token");
    // only non-auction items can be purchased from w3user
    require(tokenOnAuction[_tokenId] == true, "this token is not on auction");

    priceCalc.validateAmount(_bidPriceFiat, _wethAmount);

    weth.safeTransferFrom(msgSender(), address(this), _wethAmount);

    // calculate buyer seller fee 5% and send to fee account
    uint256 fee = priceCalc.calcBuyerSellerFee(_wethAmount);
    _send(fee, dbiliaToken.dbiliaFee());

    // calculate royalty amount and send to dbilia account
    (uint256 royaltyAmount, ) = priceCalc.calcRoyalty(_tokenId, _wethAmount);
    _send(royaltyAmount, dbiliaToken.dbiliaTrust());

    // calculate seller receive amount and send
    uint256 sellerAmount = _wethAmount.sub(fee.add(royaltyAmount));
    _send(sellerAmount, dbiliaToken.dbiliaTrust());

    emit BiddingWithETH(
      _tokenId,
      msgSender(),
      fee,
      royaltyAmount,
      sellerAmount,
      block.timestamp
    );
  }

  /**
   * send token to auction winner
   * function triggered by Dbilia
   *
   * Preconditions
   * For AUCTION
   * 1. call getTokenOwnership() to check whether seller is w2 or w3user holding the token
   * 2. if seller is w3user, call ownerOf() to check seller still holds the token
   *
   * After purchase
   * 1. increase the seller's internal wallet balance either in USD or ETH
   * 2. increase the royalty receiver's internal wallet balance either in USD or ETH
   *
   * @param _tokenId token id to buy
   * @param _receiver receiver address
   * @param _receiverId receiver's w2user internal id
   */
  function claimAuctionWinner(
    uint256 _tokenId,
    address _receiver,
    string memory _receiverId
  ) external isActive onlyDbilia {
    require(tokenPriceFiat[_tokenId] > 0, "seller is not selling this token");
    // only non-auction items can be purchased from w3user
    require(tokenOnAuction[_tokenId] == true, "this token is not on auction");
    require(
      _receiver != address(0) || bytes(_receiverId).length > 0,
      "either one of receivers should be passed in"
    );
    require(
      !(_receiver != address(0) && bytes(_receiverId).length > 0),
      "cannot pass in both receiver info"
    );

    address owner = dbiliaToken.ownerOf(_tokenId);
    (bool isW3user, address w3owner, string memory w2owner) = dbiliaToken
      .getTokenOwnership(_tokenId);
    bool w3user = _receiver != address(0) ? true : false; // check token buyer is w3user

    // token seller is a w3user
    if (isW3user) {
      require(owner == w3owner, "wrong owner");
      require(w3owner != address(0), "w3owner is empty");
      dbiliaToken.safeTransferFrom(
        w3owner,
        w3user ? _receiver : dbiliaToken.dbiliaTrust(),
        _tokenId
      );
      // w2user
    } else {
      require(owner == dbiliaToken.dbiliaTrust(), "wrong owner");
      require(bytes(w2owner).length > 0, "w2owner is empty");
      if (w3user) {
        dbiliaToken.safeTransferFrom(
          dbiliaToken.dbiliaTrust(),
          _receiver,
          _tokenId
        );
      }
    }

    dbiliaToken.changeTokenOwnership(
      _tokenId,
      w3user ? _receiver : address(0),
      w3user ? "" : _receiverId
    );

    _resetTokenStatus(_tokenId);

    emit ClaimAuctionWinner(_tokenId, _receiver, _receiverId, block.timestamp);
  }

  /**
   * Transfer weth to an address
   *
   * @param _amount amount in ETH
   * @param _to receiver
   */
  function _send(uint256 _amount, address _to) private {
    weth.safeTransfer(_to, _amount);
  }

  /**
   * Add token status
   *
   * @param _tokenId token id
   * @param _priceFiat price in fiat
   * @param _auction auction status
   */
  function _addTokenStatus(
    uint256 _tokenId,
    uint256 _priceFiat,
    bool _auction
  ) private {
    tokenPriceFiat[_tokenId] = _priceFiat;
    tokenOnAuction[_tokenId] = _auction;
  }

  /**
   * Reset token status
   *
   * @param _tokenId token id
   */
  function _resetTokenStatus(uint256 _tokenId) private {
    tokenPriceFiat[_tokenId] = 0;
    tokenOnAuction[_tokenId] = false;
  }

  /**
   * Set passcode for marketplace contract
   *
   * @param passcode_ passcode
   */
  function setPasscode(bytes32 passcode_) external {
    require(msgSender() == address(dbiliaToken), "wrong caller");
    passcode = passcode_;
  }

  function setDbiliaToken(address _newDbiliaToken) external {
    require(msgSender() == dbiliaToken.owner(), "wrong owner");
    dbiliaToken = IDbiliaToken(_newDbiliaToken);
  }

  /////// Data migration section //////////
  /**
   * Set price fiat info for a given tokenId
   *
   * @param _tokenId token id
   * @param _priceFiat priceFiat
   */
  function setTokenPriceFiat(uint256 _tokenId, uint256 _priceFiat) external onlyDbilia {
    tokenPriceFiat[_tokenId] = _priceFiat;
  }

  /**
   * Set price fiat info for a given tokenId
   *
   * @param _tokenId token id
   * @param _onAuction onAuction
   */
  function setTokenOnAuction(uint256 _tokenId, bool _onAuction) external onlyDbilia {
    tokenOnAuction[_tokenId] = _onAuction;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * by making the `nonReentrant` function external, and make it call a
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "./EIP712Base.sol";

abstract contract EIP712MetaTransaction is EIP712Base {
  using SafeMath for uint256;

  string internal constant DOMAIN_NAME = "dbilia.app";
  string internal constant DOMAIN_VERSION = "1";

  bytes32 private constant META_TRANSACTION_TYPEHASH =
    keccak256(
      bytes(
        "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
      )
    );

  event MetaTransactionExecuted(
    address userAddress,
    address payable relayerAddress,
    bytes functionSignature
  );

  mapping(address => uint256) nonces;

  /*
   * Meta transaction structure.
   * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
   * He should call the desired function directly in that case.
   */
  struct MetaTransaction {
    uint256 nonce;
    address from;
    bytes functionSignature;
  }

  function executeMetaTransaction(
    address userAddress,
    bytes memory functionSignature,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) public payable returns (bytes memory) {
    MetaTransaction memory metaTx = MetaTransaction({
      nonce: nonces[userAddress],
      from: userAddress,
      functionSignature: functionSignature
    });

    require(
      verify(userAddress, metaTx, sigR, sigS, sigV),
      "Signer and signature do not match"
    );

    // increase nonce for user (to avoid re-use)
    nonces[userAddress] = nonces[userAddress].add(1);

    emit MetaTransactionExecuted(
      userAddress,
      payable(msg.sender),
      functionSignature
    );

    // Append userAddress and relayer address at the end to extract it from calling context
    (bool success, bytes memory returnData) = address(this).call(
      abi.encodePacked(functionSignature, userAddress)
    );
    require(success, "Function call not successful");

    return returnData;
  }

  function hashMetaTransaction(MetaTransaction memory metaTx)
    internal
    pure
    returns (bytes32)
  {
    return
      keccak256(
        abi.encode(
          META_TRANSACTION_TYPEHASH,
          metaTx.nonce,
          metaTx.from,
          keccak256(metaTx.functionSignature)
        )
      );
  }

  function msgSender() internal view returns (address payable sender) {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(
          mload(add(array, index)),
          0xffffffffffffffffffffffffffffffffffffffff
        )
      }
    } else {
      sender = payable(msg.sender);
    }

    return sender;
  }

  function getNonce(address user) public view returns (uint256 nonce) {
    nonce = nonces[user];
  }

  function verify(
    address signer,
    MetaTransaction memory metaTx,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) internal view returns (bool) {
    require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
    return
      signer ==
      ecrecover(
        toTypedMessageHash(hashMetaTransaction(metaTx)),
        sigV,
        sigR,
        sigS
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAccessControl.sol";

interface IDbiliaToken is IAccessControl {
  function feePercent() external view returns (uint256);

  function getRoyaltyReceiver(uint256) external view returns (address, uint16);

  function getTokenOwnership(uint256)
    external
    view
    returns (
      bool,
      address,
      string memory
    );

  function changeTokenOwnership(
    uint256,
    address,
    string memory
  ) external;

  function ownerOf(uint256) external view returns (address);

  function isApprovedForAll(address, address) external view returns (bool);

  function safeTransferFrom(
    address,
    address,
    uint256
  ) external;

  function mintWithFiatw3user(
    address,
    uint16,
    address,
    string memory,
    uint256,
    string memory
  ) external;

  function mintWithETHAndPurchase(
    address,
    uint256,
    uint256,
    address,
    uint16,
    string memory,
    uint256,
    string memory
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceCalculation {
  function validateAmount(uint256, uint256) external view;

  function calcBuyerSellerFee(uint256) external view returns (uint256);

  function calcRoyalty(uint256, uint256)
    external
    view
    returns (uint256, address);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EIP712Base {
  bytes32 private domainSeparator;

  struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
  }

  bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
    keccak256(
      bytes(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
      )
    );

  constructor(
    string memory name,
    string memory version,
    uint256 chainId
  ) {
    domainSeparator = keccak256(
      abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256(bytes(name)),
        keccak256(bytes(version)),
        // map Matic testnet ID 80001 to Goerli ID 5
        // map Matic mainnet ID 137 to Ethereum mainnet ID 1
        chainId == 80001 ? 5 : 1,
        address(this)
      )
    );
  }

  function getDomainSeparator() public view returns (bytes32) {
    return domainSeparator;
  }

  /**
   * Accept message hash and returns hash message in EIP712 compatible form
   * So that it can be used to recover signer from signature signed using EIP712 formatted data
   * https://eips.ethereum.org/EIPS/eip-712
   * "\\x19" makes the encoding deterministic
   * "\\x01" is the version byte to make it compatible to EIP-191
   */
  function toTypedMessageHash(bytes32 messageHash)
    internal
    view
    returns (bytes32)
  {
    return
      keccak256(
        abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash)
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccessControl {
  function owner() external view returns (address);

  function dbiliaTrust() external view returns (address);

  function dbiliaFee() external view returns (address);

  function dbiliaAirdrop() external view returns (address);

  function isMaintaining() external view returns (bool);

  function isAuthorizedAddress(address) external view returns (bool);
}