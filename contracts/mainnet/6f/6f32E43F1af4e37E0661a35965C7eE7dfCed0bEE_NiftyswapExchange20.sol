// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;
import "../interfaces/INiftyswapExchange20.sol";
import "../utils/ReentrancyGuard.sol";

import "@0xsequence/erc-1155/contracts/interfaces/IERC20.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC165.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC1155.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC1155TokenReceiver.sol";
import "@0xsequence/erc-1155/contracts/tokens/ERC1155/ERC1155MintBurn.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

interface IMasterchief {
  function timelock() external returns (address);
  function creator() external returns (address);
}

/**
 * This Uniswap-like implementation supports ERC-1155 standard tokens
 * with an ERC-20 based token used as a currency instead of Ether.
 *
 * Liquidity tokens are also ERC-1155 tokens you can find the ERC-1155
 * implementation used here:
 *    https://github.com/horizon-games/multi-token-standard/tree/master/contracts/tokens/ERC1155
 *
 * @dev Like Uniswap, tokens with 0 decimals and low supply are susceptible to significant rounding
 *      errors when it comes to removing liquidity, possibly preventing them to be withdrawn without
 *      some collaboration between liquidity providers.
 */
contract NiftyswapExchange20 is ReentrancyGuard, ERC1155MintBurn, INiftyswapExchange20 {
  using SafeMath for uint256;

  /***********************************|
  |       Variables & Constants       |
  |__________________________________*/

  // Variables
  IERC1155 internal immutable token;              // address of the ERC-1155 token contract
  address internal immutable currency;            // address of the ERC-20 currency used for exchange

  // Royalty variables
  uint256 internal globalRoyaltyFee;        // global royalty fee multiplier
  address internal globalRoyaltyRecipient;  // global royalty fee recipient

  // Mapping variables
  mapping(uint256 => uint256) internal totalSupplies;    // Liquidity pool token supply per Token id
  mapping(uint256 => uint256) internal currencyReserves; // currency Token reserve per Token id
  mapping(address => uint256) internal royalties;        // Mapping tracking how much royalties can be claimed per address

  address public immutable masterchief;

  /***********************************|
  |            Constructor           |
  |__________________________________*/

  /**
   * @notice Create instance of exchange contract with respective token and currency token
   * @dev Royalty fee will need to be manually set by admin.
   * @param _tokenAddr     The address of the ERC-1155 Token
   * @param _currencyAddr  The address of the ERC-20 currency Token
   */
  constructor(address _masterchief, address _tokenAddr, address _currencyAddr, uint256 _globalRoyaltyFee) {
    masterchief = _masterchief;
    globalRoyaltyRecipient = _masterchief;

    token = IERC1155(_tokenAddr);
    currency = _currencyAddr;

    globalRoyaltyFee = _globalRoyaltyFee;
  }

  modifier onlyTimelock {
    require(IMasterchief(masterchief).timelock() == msg.sender); _;
  }

  /***********************************|
  |        Exchange Functions         |
  |__________________________________*/

  /**
   * @notice Convert currency tokens to Tokens _id and transfers Tokens to recipient.
   */
  function _currencyToToken(
    uint256[] memory _tokenIds,
    uint256[] memory _tokensBoughtAmounts,
    uint256 _maxCurrency,
    uint256 _deadline,
    address _recipient
  )
    internal nonReentrant returns (uint256[] memory currencySold)
  {
    // Input validation
    require(_deadline >= block.timestamp, "NiftyswapExchange20#_currencyToToken: DEADLINE_EXCEEDED");

    // Number of Token IDs to deposit
    uint256 nTokens = _tokenIds.length;
    uint256 totalRefundCurrency = _maxCurrency;

    // Initialize variables
    currencySold = new uint256[](nTokens); // Amount of currency tokens sold per ID

    // Get token reserves
    uint256[] memory tokenReserves = _getTokenReserves(_tokenIds);

    // Assumes the currency Tokens are already received by contract, but not
    // the Tokens Ids

    // Remove liquidity for each Token ID in _tokenIds
    for (uint256 i = 0; i < nTokens; i++) {
      // Store current id and amount from argument arrays
      uint256 idBought = _tokenIds[i];
      uint256 amountBought = _tokensBoughtAmounts[i];
      uint256 tokenReserve = tokenReserves[i];

      require(amountBought > 0, "NiftyswapExchange20#_currencyToToken: NULL_TOKENS_BOUGHT");

      // Load currency token and Token _id reserves
      uint256 currencyReserve = currencyReserves[idBought];

      // Get amount of currency tokens to send for purchase
      // Neither reserves amount have been changed so far in this transaction, so
      // no adjustment to the inputs is needed
      uint256 currencyAmount = getBuyPrice(amountBought, currencyReserve, tokenReserve);

      // If royalty, increase amount buyer will need to pay after LP fees were calculated
      // Note: Royalty will be a bit higher since LF fees are added first
      (address royaltyRecipient, uint256 royaltyAmount) = getRoyaltyInfo(currencyAmount);
      if (royaltyAmount > 0) {
        royalties[royaltyRecipient] = royalties[royaltyRecipient].add(royaltyAmount);
      }

      // Calculate currency token amount to refund (if any) where whatever is not used will be returned
      // Will throw if total cost exceeds _maxCurrency
      totalRefundCurrency = totalRefundCurrency.sub(currencyAmount).sub(royaltyAmount);

      // Append Token id, Token id amount and currency token amount to tracking arrays
      currencySold[i] = currencyAmount.add(royaltyAmount);

      // Update individual currency reseve amount (royalty is not added to liquidity)
      currencyReserves[idBought] = currencyReserve.add(currencyAmount);
    }

    // Refund currency token if any
    if (totalRefundCurrency > 0) {
      TransferHelper.safeTransfer(currency, _recipient, totalRefundCurrency);
    }

    // Send Tokens all tokens purchased
    token.safeBatchTransferFrom(address(this), _recipient, _tokenIds, _tokensBoughtAmounts, "");
    return currencySold;
  }

  /**
   * @dev Pricing function used for converting between currency token to Tokens.
   * @param _assetBoughtAmount  Amount of Tokens being bought.
   * @param _assetSoldReserve   Amount of currency tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of Tokens (output type) in exchange reserves.
   * @return price Amount of currency tokens to send to Niftyswap.
   */
  function getBuyPrice(
    uint256 _assetBoughtAmount,
    uint256 _assetSoldReserve,
    uint256 _assetBoughtReserve)
    override public pure returns (uint256 price)
  {
    // Reserves must not be empty
    require(_assetSoldReserve > 0 && _assetBoughtReserve > 0, "NiftyswapExchange20#getBuyPrice: EMPTY_RESERVE");

    // Calculate price with fee
    uint256 numerator = _assetSoldReserve.mul(_assetBoughtAmount);
    uint256 denominator = _assetBoughtReserve.sub(_assetBoughtAmount);
    (price, ) = divRound(numerator, denominator);
    return price; // Will add 1 if rounding error
  }

  /**
   * @dev Pricing function used for converting Tokens to currency token (including royalty fee)
   * @param _assetBoughtAmount  Amount of Tokens being bought.
   * @param _assetSoldReserve   Amount of currency tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of Tokens (output type) in exchange reserves.
   * @return price Amount of currency tokens to send to Niftyswap.
   */
  function getBuyPriceWithRoyalty(
    uint256 _assetBoughtAmount,
    uint256 _assetSoldReserve,
    uint256 _assetBoughtReserve)
    override public view returns (uint256 price)
  {
    uint256 cost = getBuyPrice(_assetBoughtAmount, _assetSoldReserve, _assetBoughtReserve);
    (, uint256 royaltyAmount) = getRoyaltyInfo(cost);
    return cost.add(royaltyAmount);
  }

  /**
   * @notice Convert Tokens _id to currency tokens and transfers Tokens to recipient.
   * @dev User specifies EXACT Tokens _id sold and MINIMUM currency tokens received.
   * @dev Assumes that all trades will be valid, or the whole tx will fail
   * @dev Sorting _tokenIds is mandatory for efficient way of preventing duplicated IDs (which would lead to errors)
   * @param _tokenIds           Array of Token IDs that are sold
   * @param _tokensSoldAmounts  Array of Amount of Tokens sold for each id in _tokenIds.
   * @param _minCurrency        Minimum amount of currency tokens to receive
   * @param _deadline           Timestamp after which this transaction will be reverted
   * @param _recipient          The address that receives output currency tokens.
   * @param _extraFeeRecipients  Array of addresses that will receive extra fee
   * @param _extraFeeAmounts     Array of amounts of currency that will be sent as extra fee
   * @return currencyBought How much currency was actually purchased.
   */
  function _tokenToCurrency(
    uint256[] memory _tokenIds,
    uint256[] memory _tokensSoldAmounts,
    uint256 _minCurrency,
    uint256 _deadline,
    address _recipient,
    address[] memory _extraFeeRecipients,
    uint256[] memory _extraFeeAmounts
  )
    internal nonReentrant returns (uint256[] memory currencyBought)
  {
    // Number of Token IDs to deposit
    uint256 nTokens = _tokenIds.length;

    // Input validation
    require(_deadline >= block.timestamp, "NiftyswapExchange20#_tokenToCurrency: DEADLINE_EXCEEDED");

    // Initialize variables
    uint256 totalCurrency = 0; // Total amount of currency tokens to transfer
    currencyBought = new uint256[](nTokens);

    // Get token reserves
    uint256[] memory tokenReserves = _getTokenReserves(_tokenIds);

    // Assumes the Tokens ids are already received by contract, but not
    // the Tokens Ids. Will return cards not sold if invalid price.

    // Remove liquidity for each Token ID in _tokenIds
    for (uint256 i = 0; i < nTokens; i++) {
      // Store current id and amount from argument arrays
      uint256 idSold = _tokenIds[i];
      uint256 amountSold = _tokensSoldAmounts[i];
      uint256 tokenReserve = tokenReserves[i];

      // If 0 tokens send for this ID, revert
      require(amountSold > 0, "NiftyswapExchange20#_tokenToCurrency: NULL_TOKENS_SOLD");

      // Load currency token and Token _id reserves
      uint256 currencyReserve = currencyReserves[idSold];

      // Get amount of currency that will be received
      // Need to sub amountSold because tokens already added in reserve, which would bias the calculation
      // Don't need to add it for currencyReserve because the amount is added after this calculation
      uint256 currencyAmount = getSellPrice(amountSold, tokenReserve.sub(amountSold), currencyReserve);

      // If royalty, substract amount seller will receive after LP fees were calculated
      // Note: Royalty will be a bit lower since LF fees are substracted first
      (address royaltyRecipient, uint256 royaltyAmount) = getRoyaltyInfo(currencyAmount);
      if (royaltyAmount > 0) {
        royalties[royaltyRecipient] = royalties[royaltyRecipient].add(royaltyAmount);
      }

      // Increase total amount of currency to receive (minus royalty to pay)
      totalCurrency = totalCurrency.add(currencyAmount.sub(royaltyAmount));

      // Update individual currency reseve amount
      currencyReserves[idSold] = currencyReserve.sub(currencyAmount);

      // Append Token id, Token id amount and currency token amount to tracking arrays
      currencyBought[i] = currencyAmount.sub(royaltyAmount);
    }

    // Set the extra fees aside to recipients after sale
    for (uint256 i = 0; i < _extraFeeAmounts.length; i++) {
      if (_extraFeeAmounts[i] > 0) {
        totalCurrency = totalCurrency.sub(_extraFeeAmounts[i]);
        royalties[_extraFeeRecipients[i]] = royalties[_extraFeeRecipients[i]].add(_extraFeeAmounts[i]);
      }
    }

    // If minCurrency is not met
    require(totalCurrency >= _minCurrency, "NiftyswapExchange20#_tokenToCurrency: INSUFFICIENT_CURRENCY_AMOUNT");

    // Transfer currency here
    TransferHelper.safeTransfer(currency, _recipient, totalCurrency);
    return currencyBought;
  }

  /**
   * @dev Pricing function used for converting Tokens to currency token.
   * @param _assetSoldAmount    Amount of Tokens being sold.
   * @param _assetSoldReserve   Amount of Tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of currency tokens in exchange reserves.
   * @return price Amount of currency tokens to receive from Niftyswap.
   */
  function getSellPrice(
    uint256 _assetSoldAmount,
    uint256 _assetSoldReserve,
    uint256 _assetBoughtReserve)
    override public pure returns (uint256 price)
  {
    //Reserves must not be empty
    require(_assetSoldReserve > 0 && _assetBoughtReserve > 0, "NiftyswapExchange20#getSellPrice: EMPTY_RESERVE");

    // Calculate amount to receive before royalty
    uint256 _assetSoldAmount_ = _assetSoldAmount.mul(1000);
    uint256 numerator = _assetSoldAmount_.mul(_assetBoughtReserve);
    uint256 denominator = _assetSoldReserve.mul(1000).add(_assetSoldAmount_);

    return numerator / denominator; // Rounding errors will favor Niftyswap, so nothing to do
  }

  /**
   * @dev Pricing function used for converting Tokens to currency token (including royalty fee)
   * @param _assetSoldAmount    Amount of Tokens being sold.
   * @param _assetSoldReserve   Amount of Tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of currency tokens in exchange reserves.
   * @return price Amount of currency tokens to receive from Niftyswap.
   */
  function getSellPriceWithRoyalty(
    uint256 _assetSoldAmount,
    uint256 _assetSoldReserve,
    uint256 _assetBoughtReserve)
    override public view returns (uint256 price)
  {
    uint256 sellAmount = getSellPrice(_assetSoldAmount, _assetSoldReserve, _assetBoughtReserve);
    (, uint256 royaltyAmount) = getRoyaltyInfo(sellAmount);
    return sellAmount.sub(royaltyAmount);
  }

  /***********************************|
  |        Liquidity Functions        |
  |__________________________________*/

  /**
   * @notice Deposit less than max currency tokens && exact Tokens (token ID) at current ratio to mint liquidity pool tokens.
   * @dev min_liquidity does nothing when total liquidity pool token supply is 0.
   * @dev Assumes that sender approved this contract on the currency
   * @dev Sorting _tokenIds is mandatory for efficient way of preventing duplicated IDs (which would lead to errors)
   * @param _provider      Address that provides liquidity to the reserve
   * @param _tokenIds      Array of Token IDs where liquidity is added
   * @param _tokenAmounts  Array of amount of Tokens deposited corresponding to each ID provided in _tokenIds
   * @param _maxCurrency   Array of maximum number of tokens deposited for each ID provided in _tokenIds.
   *                       Deposits max amount if total liquidity pool token supply is 0.
   * @param _deadline      Timestamp after which this transaction will be reverted
   */
  function _addLiquidity(
    address _provider,
    uint256[] memory _tokenIds,
    uint256[] memory _tokenAmounts,
    uint256[] memory _maxCurrency,
    uint256 _deadline)
    internal nonReentrant
  {
    // Requirements
    require(_deadline >= block.timestamp, "NiftyswapExchange20#_addLiquidity: DEADLINE_EXCEEDED");

    // Initialize variables
    uint256 nTokens = _tokenIds.length; // Number of Token IDs to deposit
    uint256 totalCurrency = 0;          // Total amount of currency tokens to transfer

    // Initialize arrays
    uint256[] memory liquiditiesToMint = new uint256[](nTokens);
    uint256[] memory currencyAmounts = new uint256[](nTokens);

    // Get token reserves
    uint256[] memory tokenReserves = _getTokenReserves(_tokenIds);

    // Assumes tokens _ids are deposited already, but not currency tokens
    // as this is calculated and executed below.

    // Loop over all Token IDs to deposit
    for (uint256 i = 0; i < nTokens; i ++) {
      // Store current id and amount from argument arrays
      uint256 tokenId = _tokenIds[i];
      uint256 amount = _tokenAmounts[i];

      // Check if input values are acceptable
      require(_maxCurrency[i] > 0, "NiftyswapExchange20#_addLiquidity: NULL_MAX_CURRENCY");
      require(amount > 0, "NiftyswapExchange20#_addLiquidity: NULL_TOKENS_AMOUNT");

      // Current total liquidity calculated in currency token
      uint256 totalLiquidity = totalSupplies[tokenId];

      // When reserve for this token already exists
      if (totalLiquidity > 0) {

        // Load currency token and Token reserve's supply of Token id
        uint256 currencyReserve = currencyReserves[tokenId]; // Amount not yet in reserve
        uint256 tokenReserve = tokenReserves[i];

        /**
        * Amount of currency tokens to send to token id reserve:
        * X/Y = dx/dy
        * dx = X*dy/Y
        * where
        *   X:  currency total liquidity
        *   Y:  Token _id total liquidity (before tokens were received)
        *   dy: Amount of token _id deposited
        *   dx: Amount of currency to deposit
        *
        * Adding .add(1) if rounding errors so to not favor users incorrectly
        */
        (uint256 currencyAmount, bool rounded) = divRound(amount.mul(currencyReserve), tokenReserve.sub(amount));
        require(_maxCurrency[i] >= currencyAmount, "NiftyswapExchange20#_addLiquidity: MAX_CURRENCY_AMOUNT_EXCEEDED");

        // Update currency reserve size for Token id before transfer
        currencyReserves[tokenId] = currencyReserve.add(currencyAmount);

        // Update totalCurrency
        totalCurrency = totalCurrency.add(currencyAmount);

        // Proportion of the liquidity pool to give to current liquidity provider
        // If rounding error occured, round down to favor previous liquidity providers
        // See https://github.com/0xsequence/niftyswap/issues/19
        liquiditiesToMint[i] = (currencyAmount.sub(rounded ? 1 : 0)).mul(totalLiquidity) / currencyReserve;
        currencyAmounts[i] = currencyAmount;

        // Mint liquidity ownership tokens and increase liquidity supply accordingly
        totalSupplies[tokenId] = totalLiquidity.add(liquiditiesToMint[i]);

      } else {
        uint256 maxCurrency = _maxCurrency[i];

        // Otherwise rounding error could end up being significant on second deposit
        require(maxCurrency >= 1000000000, "NiftyswapExchange20#_addLiquidity: INVALID_CURRENCY_AMOUNT");

        // Initial liquidity. Check if provider is creator
        require(_provider == IMasterchief(masterchief).creator(), "NiftyswapExchange20#_addLiquidity: INITIAL_LIQUIDITY");

        // Update currency  reserve size for Token id before transfer
        currencyReserves[tokenId] = maxCurrency;

        // Update totalCurrency
        totalCurrency = totalCurrency.add(maxCurrency);

        // Initial liquidity is amount deposited (Incorrect pricing will be arbitraged)
        // uint256 initialLiquidity = _maxCurrency;
        totalSupplies[tokenId] = maxCurrency;

        // Liquidity to mints
        liquiditiesToMint[i] = maxCurrency;
        currencyAmounts[i] = maxCurrency;
      }
    }

    // Mint liquidity pool tokens
    _batchMint(_provider, _tokenIds, liquiditiesToMint, "");

    // Transfer all currency to this contract
    TransferHelper.safeTransferFrom(currency, _provider, address(this), totalCurrency);

    // Emit event
    emit LiquidityAdded(_provider, _tokenIds, _tokenAmounts, currencyAmounts);
  }

  /***********************************|
  |     Receiver Methods Handler      |
  |__________________________________*/

  // Method signatures for onReceive control logic

  // bytes4(keccak256(
  //   "_tokenToCurrency(uint256[],uint256[],uint256,uint256,address,address[],uint256[])"
  // ));
  bytes4 internal constant SELLTOKENS_SIG = 0xade79c7a;

  //  bytes4(keccak256(
  //   "_addLiquidity(address,uint256[],uint256[],uint256[],uint256)"
  // ));
  bytes4 internal constant ADDLIQUIDITY_SIG = 0x82da2b73;

  // bytes4(keccak256(
  //   "DepositTokens()"
  // ));
  bytes4 internal constant DEPOSIT_SIG = 0xc8c323f9;

  /***********************************|
  |           Buying Tokens           |
  |__________________________________*/

  /**
   * @notice Convert currency tokens to Tokens _id and transfers Tokens to recipient.
   * @dev User specifies MAXIMUM inputs (_maxCurrency) and EXACT outputs.
   * @dev Assumes that all trades will be successful, or revert the whole tx
   * @dev Exceeding currency tokens sent will be refunded to recipient
   * @dev Sorting IDs is mandatory for efficient way of preventing duplicated IDs (which would lead to exploit)
   * @param _tokenIds            Array of Tokens ID that are bought
   * @param _tokensBoughtAmounts Amount of Tokens id bought for each corresponding Token id in _tokenIds
   * @param _maxCurrency         Total maximum amount of currency tokens to spend for all Token ids
   * @param _deadline            Timestamp after which this transaction will be reverted
   * @param _recipient           The address that receives output Tokens and refund
   * @param _extraFeeRecipients  Array of addresses that will receive extra fee
   * @param _extraFeeAmounts     Array of amounts of currency that will be sent as extra fee
   * @return currencySold How much currency was actually sold.
   */
  function buyTokens(
    uint256[] memory _tokenIds,
    uint256[] memory _tokensBoughtAmounts,
    uint256 _maxCurrency,
    uint256 _deadline,
    address _recipient,
    address[] memory _extraFeeRecipients,
    uint256[] memory _extraFeeAmounts
  )
    override external returns (uint256[] memory)
  {
    require(_deadline >= block.timestamp, "NiftyswapExchange20#buyTokens: DEADLINE_EXCEEDED");
    require(_tokenIds.length > 0, "NiftyswapExchange20#buyTokens: INVALID_CURRENCY_IDS_AMOUNT");

    // Transfer the tokens for purchase
    TransferHelper.safeTransferFrom(currency, msg.sender, address(this), _maxCurrency);

    address recipient = _recipient == address(0x0) ? msg.sender : _recipient;

    // Set the extra fee aside to recipients ahead of purchase, if any.
    uint256 maxCurrency = _maxCurrency;
    uint256 nExtraFees = _extraFeeRecipients.length;
    require(nExtraFees == _extraFeeAmounts.length, "NiftyswapExchange20#buyTokens: EXTRA_FEES_ARRAYS_ARE_NOT_SAME_LENGTH");

    for (uint256 i = 0; i < nExtraFees; i++) {
      if (_extraFeeAmounts[i] > 0) {
        maxCurrency = maxCurrency.sub(_extraFeeAmounts[i]);
        royalties[_extraFeeRecipients[i]] = royalties[_extraFeeRecipients[i]].add(_extraFeeAmounts[i]);
      }
    }

    // Execute trade and retrieve amount of currency spent
    uint256[] memory currencySold = _currencyToToken(_tokenIds, _tokensBoughtAmounts, maxCurrency, _deadline, recipient);
    emit TokensPurchase(msg.sender, recipient, _tokenIds, _tokensBoughtAmounts, currencySold);

    return currencySold;
  }

  /**
   * @notice Handle which method is being called on transfer
   * @dev `_data` must be encoded as follow: abi.encode(bytes4, MethodObj)
   *   where bytes4 argument is the MethodObj object signature passed as defined
   *   in the `Signatures for onReceive control logic` section above
   * @param _from     The address which previously owned the Token
   * @param _ids      An array containing ids of each Token being transferred
   * @param _amounts  An array containing amounts of each Token being transferred
   * @param _data     Method signature and corresponding encoded arguments for method to call on *this* contract
   * @return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")
   */
  function onERC1155BatchReceived(
    address, // _operator,
    address _from,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data)
    override public returns(bytes4)
  {
    // This function assumes that the ERC-1155 token contract can
    // only call `onERC1155BatchReceived()` via a valid token transfer.
    // Users must be responsible and only use this Niftyswap exchange
    // contract with ERC-1155 compliant token contracts.

    // Obtain method to call via object signature
    bytes4 functionSignature = abi.decode(_data, (bytes4));

    /***********************************|
    |           Selling Tokens          |
    |__________________________________*/

    if (functionSignature == SELLTOKENS_SIG) {

      // Tokens received need to be Token contract
      require(msg.sender == address(token), "NiftyswapExchange20#onERC1155BatchReceived: INVALID_TOKENS_TRANSFERRED");

      // Decode SellTokensObj from _data to call _tokenToCurrency()
      SellTokensObj memory obj;
      (, obj) = abi.decode(_data, (bytes4, SellTokensObj));
      address recipient = obj.recipient == address(0x0) ? _from : obj.recipient;

      // Validate fee arrays
      require(obj.extraFeeRecipients.length == obj.extraFeeAmounts.length, "NiftyswapExchange20#buyTokens: EXTRA_FEES_ARRAYS_ARE_NOT_SAME_LENGTH");

      // Execute trade and retrieve amount of currency received
      uint256[] memory currencyBought = _tokenToCurrency(_ids, _amounts, obj.minCurrency, obj.deadline, recipient, obj.extraFeeRecipients, obj.extraFeeAmounts);
      emit CurrencyPurchase(_from, recipient, _ids, _amounts, currencyBought);

    /***********************************|
    |      Adding Liquidity Tokens      |
    |__________________________________*/

    } else if (functionSignature == ADDLIQUIDITY_SIG) {
      // Only allow to receive ERC-1155 tokens from `token` contract
      require(msg.sender == address(token), "NiftyswapExchange20#onERC1155BatchReceived: INVALID_TOKEN_TRANSFERRED");

      // Decode AddLiquidityObj from _data to call _addLiquidity()
      AddLiquidityObj memory obj;
      (, obj) = abi.decode(_data, (bytes4, AddLiquidityObj));
      _addLiquidity(_from, _ids, _amounts, obj.maxCurrency, obj.deadline);

    /***********************************|
    |      Removing Liquidity Tokens     |
    |__________________________________*/

    } else if (functionSignature == DEPOSIT_SIG) {
      // Do nothing for when contract is self depositing
      // This could be use to deposit currency "by accident", which would be locked
      require(msg.sender == address(currency), "NiftyswapExchange20#onERC1155BatchReceived: INVALID_TOKENS_DEPOSITED");

    } else {
      revert("NiftyswapExchange20#onERC1155BatchReceived: INVALID_METHOD");
    }

    return ERC1155_BATCH_RECEIVED_VALUE;
  }

  /**
   * @dev Will pass to onERC115Batch5Received
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes memory _data)
    override public returns(bytes4)
  {
    uint256[] memory ids = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);

    ids[0] = _id;
    amounts[0] = _amount;

    require(
      ERC1155_BATCH_RECEIVED_VALUE == onERC1155BatchReceived(_operator, _from, ids, amounts, _data),
      "NiftyswapExchange20#onERC1155Received: INVALID_ONRECEIVED_MESSAGE"
    );

    return ERC1155_RECEIVED_VALUE;
  }

  /**
   * @notice Prevents receiving Ether or calls to unsuported methods
   */
  fallback () external {
    revert("NiftyswapExchange20:UNSUPPORTED_METHOD");
  }

  /***********************************|
  |         Royalty Functions         |
  |__________________________________*/

  /**
   * @notice Will set the royalties fees and recipient
   * @param _fee       Fee percentage with a 1000 basis (e.g. 0.3% is 3 and 1% is 10 and 100% is 1000.)
   */
  function setRoyaltyFee(uint256 _fee) onlyTimelock public {
    require(_fee < 1000 && _fee >= 50, "NiftyswapExchange20#setRoyaltyInfo: ROYALTY_FEE_IS_TOO_HIGH");
    globalRoyaltyFee = _fee;
    emit RoyaltyChanged(globalRoyaltyRecipient, _fee);
  }

  /**
   * @notice Will send the royalties that _royaltyRecipient can claim, if any
   * @dev Anyone can call this function such that payout could be distributed
   *      regularly instead of being claimed.
   * @param _royaltyRecipient Address that is able to claim royalties
   */
  function sendRoyalties(address _royaltyRecipient) override external {
    uint256 royaltyAmount = royalties[_royaltyRecipient];
    royalties[_royaltyRecipient] = 0;
    TransferHelper.safeTransfer(currency, _royaltyRecipient, royaltyAmount);
  }

  /**
   * @notice Will return how much of currency need to be paid for the royalty
   * @param _cost    Amount of currency sent/received for the trade
   * @return recipient Address that will be able to claim the royalty
   * @return royalty Amount of currency that will be sent to royalty recipient
   */
  function getRoyaltyInfo(uint256 _cost) public view returns (address recipient, uint256 royalty) {
    return (globalRoyaltyRecipient, (_cost.mul(globalRoyaltyFee)).div(1000));
  }


  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  /**
   * @notice Get amount of currency in reserve for each Token _id in _ids
   * @param _ids Array of ID sto query currency reserve of
   * @return amount of currency in reserve for each Token _id
   */
  function getCurrencyReserves(
    uint256[] calldata _ids)
    override external view returns (uint256[] memory)
  {
    uint256 nIds = _ids.length;
    uint256[] memory currencyReservesReturn = new uint256[](nIds);
    for (uint256 i = 0; i < nIds; i++) {
      currencyReservesReturn[i] = currencyReserves[_ids[i]];
    }
    return currencyReservesReturn;
  }

  /**
   * @notice Return price for `currency => Token _id` trades with an exact token amount.
   * @param _ids           Array of ID of tokens bought.
   * @param _tokensBought Amount of Tokens bought.
   * @return Amount of currency needed to buy Tokens in _ids for amounts in _tokensBought
   */
  function getPrice_currencyToToken(
    uint256[] calldata _ids,
    uint256[] calldata _tokensBought)
    override external view returns (uint256[] memory)
  {
    uint256 nIds = _ids.length;
    uint256[] memory prices = new uint256[](nIds);

    for (uint256 i = 0; i < nIds; i++) {
      // Load Token id reserve
      uint256 tokenReserve = token.balanceOf(address(this), _ids[i]);

      if(currencyReserves[_ids[i]] > 0 && tokenReserve > 1) {
        prices[i] = getBuyPriceWithRoyalty(_tokensBought[i], currencyReserves[_ids[i]], tokenReserve);
      }
    }

    // Return prices
    return prices;
  }

  /**
   * @notice Return price for `Token _id => currency` trades with an exact token amount.
   * @param _ids        Array of IDs  token sold.
   * @param _tokensSold Array of amount of each Token sold.
   * @return Amount of currency that can be bought for Tokens in _ids for amounts in _tokensSold
   */
  function getPrice_tokenToCurrency(
    uint256[] calldata _ids,
    uint256[] calldata _tokensSold)
    override external view returns (uint256[] memory)
  {
    uint256 nIds = _ids.length;
    uint256[] memory prices = new uint256[](nIds);

    for (uint256 i = 0; i < nIds; i++) {
      // Load Token id reserve
      uint256 tokenReserve = token.balanceOf(address(this), _ids[i]);

      if(tokenReserve > 0 && currencyReserves[_ids[i]] > 0) {
        prices[i] = getSellPriceWithRoyalty(_tokensSold[i], tokenReserve, currencyReserves[_ids[i]]);
      }
    }

    // Return price
    return prices;
  }

  /**
   * @return Address of Token that is sold on this exchange.
   */
  function getTokenAddress() override external view returns (address) {
    return address(token);
  }

  /**
   * @return Address of the currency contract that is used as currency
   */
  function getCurrencyInfo() override external view returns (address) {
    return (address(currency));
  }

  /**
   * @notice Get total supply of liquidity tokens
   * @param _ids ID of the Tokens
   * @return The total supply of each liquidity token id provided in _ids
   */
  function getTotalSupply(uint256[] calldata _ids)
    override external view returns (uint256[] memory)
  {
    // Number of ids
    uint256 nIds = _ids.length;

    // Variables
    uint256[] memory batchTotalSupplies = new uint256[](nIds);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < nIds; i++) {
      batchTotalSupplies[i] = totalSupplies[_ids[i]];
    }

    return batchTotalSupplies;
  }

  /**
   * @return Global royalty fee %
   */
  function getGlobalRoyaltyFee() override external view returns (uint256) {
    return globalRoyaltyFee;
  }

  /**
   * @return Global royalty recipient if token not supporting ERC-2981
   */
  function getGlobalRoyaltyRecipient() override external view returns (address) {
    return globalRoyaltyRecipient;
  }

  /**
   * @return Get amount of currency in royalty an address can claim
   * @param _royaltyRecipient Address to check the claimable royalties
   */
  function getRoyalties(address _royaltyRecipient) override external view returns (uint256) {
    return royalties[_royaltyRecipient];
  }


  /***********************************|
  |         Utility Functions         |
  |__________________________________*/

  /**
   * @notice Divides two numbers and add 1 if there is a rounding error
   * @param a Numerator
   * @param b Denominator
   */
  function divRound(uint256 a, uint256 b) internal pure returns (uint256, bool) {
    return a % b == 0 ? (a/b, false) : ((a/b).add(1), true);
  }

  /**
   * @notice Return Token reserves for given Token ids
   * @dev Assumes that ids are sorted from lowest to highest with no duplicates.
   *      This assumption allows for checking the token reserves only once, otherwise
   *      token reserves need to be re-checked individually or would have to do more expensive
   *      duplication checks.
   * @param _tokenIds Array of IDs to query their Reserve balance.
   * @return Array of Token ids' reserves
   */
  function _getTokenReserves(
    uint256[] memory _tokenIds)
    internal view returns (uint256[] memory)
  {
    uint256 nTokens = _tokenIds.length;

    // Regular balance query if only 1 token, otherwise batch query
    if (nTokens == 1) {
      uint256[] memory tokenReserves = new uint256[](1);
      tokenReserves[0] = token.balanceOf(address(this), _tokenIds[0]);
      return tokenReserves;

    } else {
      // Lazy check preventing duplicates & build address array for query
      address[] memory thisAddressArray = new address[](nTokens);
      thisAddressArray[0] = address(this);

      for (uint256 i = 1; i < nTokens; i++) {
        require(_tokenIds[i-1] < _tokenIds[i], "NiftyswapExchange20#_getTokenReserves: UNSORTED_OR_DUPLICATE_TOKEN_IDS");
        thisAddressArray[i] = address(this);
      }
      return token.balanceOfBatch(thisAddressArray, _tokenIds);
    }
  }

  /**
   * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
   * @param  interfaceID The ERC-165 interface ID that is queried for support.s
   * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
   *      This function MUST NOT consume more thsan 5,000 gas.
   * @return Whether a given interface is supported
   */
  function supportsInterface(bytes4 interfaceID) public override pure returns (bool) {
    return interfaceID == type(IERC20).interfaceId ||
      interfaceID == type(IERC165).interfaceId ||
      interfaceID == type(IERC1155).interfaceId ||
      interfaceID == type(IERC1155TokenReceiver).interfaceId;
  }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

interface INiftyswapExchange20 {

  /***********************************|
  |               Events              |
  |__________________________________*/

  event TokensPurchase(
    address indexed buyer,
    address indexed recipient,
    uint256[] tokensBoughtIds,
    uint256[] tokensBoughtAmounts,
    uint256[] currencySoldAmounts
  );

  event CurrencyPurchase(
    address indexed buyer,
    address indexed recipient,
    uint256[] tokensSoldIds,
    uint256[] tokensSoldAmounts,
    uint256[] currencyBoughtAmounts
  );

  event LiquidityAdded(
    address indexed provider,
    uint256[] tokenIds,
    uint256[] tokenAmounts,
    uint256[] currencyAmounts
  );

  event RoyaltyChanged(
    address indexed royaltyRecipient,
    uint256 royaltyFee
  );

  struct SellTokensObj {
    address recipient;            // Who receives the currency
    uint256 minCurrency;          // Total minimum number of currency  expected for all tokens sold
    address[] extraFeeRecipients; // Array of addresses that will receive extra fee
    uint256[] extraFeeAmounts;    // Array of amounts of currency that will be sent as extra fee
    uint256 deadline;             // Timestamp after which the tx isn't valid anymore
  }

  struct AddLiquidityObj {
    uint256[] maxCurrency; // Maximum number of currency to deposit with tokens
    uint256 deadline;      // Timestamp after which the tx isn't valid anymore
  }

  struct RemoveLiquidityObj {
    uint256[] minCurrency; // Minimum number of currency to withdraw
    uint256[] minTokens;   // Minimum number of tokens to withdraw
    uint256 deadline;      // Timestamp after which the tx isn't valid anymore
  }


  /***********************************|
  |        Purchasing Functions       |
  |__________________________________*/

  /**
   * @notice Convert currency tokens to Tokens _id and transfers Tokens to recipient.
   * @dev User specifies MAXIMUM inputs (_maxCurrency) and EXACT outputs.
   * @dev Assumes that all trades will be successful, or revert the whole tx
   * @dev Exceeding currency tokens sent will be refunded to recipient
   * @dev Sorting IDs is mandatory for efficient way of preventing duplicated IDs (which would lead to exploit)
   * @param _tokenIds            Array of Tokens ID that are bought
   * @param _tokensBoughtAmounts Amount of Tokens id bought for each corresponding Token id in _tokenIds
   * @param _maxCurrency         Total maximum amount of currency tokens to spend for all Token ids
   * @param _deadline            Timestamp after which this transaction will be reverted
   * @param _recipient           The address that receives output Tokens and refund
   * @param _extraFeeRecipients  Array of addresses that will receive extra fee
   * @param _extraFeeAmounts     Array of amounts of currency that will be sent as extra fee
   * @return currencySold How much currency was actually sold.
   */
  function buyTokens(
    uint256[] memory _tokenIds,
    uint256[] memory _tokensBoughtAmounts,
    uint256 _maxCurrency,
    uint256 _deadline,
    address _recipient,
    address[] memory _extraFeeRecipients,
    uint256[] memory _extraFeeAmounts
  ) external returns (uint256[] memory);

  /***********************************|
  |         Royalties Functions       |
  |__________________________________*/

  /**
   * @notice Will send the royalties that _royaltyRecipient can claim, if any
   * @dev Anyone can call this function such that payout could be distributed
   *      regularly instead of being claimed.
   * @param _royaltyRecipient Address that is able to claim royalties
   */
  function sendRoyalties(address _royaltyRecipient) external;

  /***********************************|
  |        OnReceive Functions        |
  |__________________________________*/

  /**
   * @notice Handle which method is being called on Token transfer
   * @dev `_data` must be encoded as follow: abi.encode(bytes4, MethodObj)
   *   where bytes4 argument is the MethodObj object signature passed as defined
   *   in the `Signatures for onReceive control logic` section above
   * @param _operator The address which called the `safeTransferFrom` function
   * @param _from     The address which previously owned the token
   * @param _id       The id of the token being transferred
   * @param _amount   The amount of tokens being transferred
   * @param _data     Method signature and corresponding encoded arguments for method to call on *this* contract
   * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Handle which method is being called on transfer
   * @dev `_data` must be encoded as follow: abi.encode(bytes4, MethodObj)
   *   where bytes4 argument is the MethodObj object signature passed as defined
   *   in the `Signatures for onReceive control logic` section above
   * @param _from     The address which previously owned the Token
   * @param _ids      An array containing ids of each Token being transferred
   * @param _amounts  An array containing amounts of each Token being transferred
   * @param _data     Method signature and corresponding encoded arguments for method to call on *this* contract
   * @return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")
   */
  function onERC1155BatchReceived(address, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);


  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  /**
   * @dev Pricing function used for converting between currency token to Tokens.
   * @param _assetBoughtAmount  Amount of Tokens being bought.
   * @param _assetSoldReserve   Amount of currency tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of Tokens (output type) in exchange reserves.
   * @return Amount of currency tokens to send to Niftyswap.
   */
  function getBuyPrice(uint256 _assetBoughtAmount, uint256 _assetSoldReserve, uint256 _assetBoughtReserve) external pure returns (uint256);

  /**
   * @dev Pricing function used for converting Tokens to currency token (including royalty fee)
   * @param _assetBoughtAmount  Amount of Tokens being bought.
   * @param _assetSoldReserve   Amount of currency tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of Tokens (output type) in exchange reserves.
   * @return price Amount of currency tokens to send to Niftyswap.
   */
  function getBuyPriceWithRoyalty(uint256 _assetBoughtAmount, uint256 _assetSoldReserve, uint256 _assetBoughtReserve) external view returns (uint256 price);

  /**
   * @dev Pricing function used for converting Tokens to currency token.
   * @param _assetSoldAmount    Amount of Tokens being sold.
   * @param _assetSoldReserve   Amount of Tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of currency tokens in exchange reserves.
   * @return Amount of currency tokens to receive from Niftyswap.
   */
  function getSellPrice(uint256 _assetSoldAmount,uint256 _assetSoldReserve, uint256 _assetBoughtReserve) external pure returns (uint256);

  /**
   * @dev Pricing function used for converting Tokens to currency token (including royalty fee)
   * @param _assetSoldAmount    Amount of Tokens being sold.
   * @param _assetSoldReserve   Amount of Tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of currency tokens in exchange reserves.
   * @return price Amount of currency tokens to receive from Niftyswap.
   */
  function getSellPriceWithRoyalty(uint256 _assetSoldAmount, uint256 _assetSoldReserve, uint256 _assetBoughtReserve) external view returns (uint256 price);

  /**
   * @notice Get amount of currency in reserve for each Token _id in _ids
   * @param _ids Array of ID sto query currency reserve of
   * @return amount of currency in reserve for each Token _id
   */
  function getCurrencyReserves(uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @notice Return price for `currency => Token _id` trades with an exact token amount.
   * @param _ids          Array of ID of tokens bought.
   * @param _tokensBought Amount of Tokens bought.
   * @return Amount of currency needed to buy Tokens in _ids for amounts in _tokensBought
   */
  function getPrice_currencyToToken(uint256[] calldata _ids, uint256[] calldata _tokensBought) external view returns (uint256[] memory);

  /**
   * @notice Return price for `Token _id => currency` trades with an exact token amount.
   * @param _ids        Array of IDs  token sold.
   * @param _tokensSold Array of amount of each Token sold.
   * @return Amount of currency that can be bought for Tokens in _ids for amounts in _tokensSold
   */
  function getPrice_tokenToCurrency(uint256[] calldata _ids, uint256[] calldata _tokensSold) external view returns (uint256[] memory);

  /**
   * @notice Get total supply of liquidity tokens
   * @param _ids ID of the Tokens
   * @return The total supply of each liquidity token id provided in _ids
   */
  function getTotalSupply(uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @return Address of Token that is sold on this exchange.
   */
  function getTokenAddress() external view returns (address);

  /**
   * @return Address of the currency contract that is used as currency
   */
  function getCurrencyInfo() external view returns (address);

  /**
   * @return Global royalty fee % if not supporting ERC-2981
   */
  function getGlobalRoyaltyFee() external view returns (uint256);

  /**
   * @return Global royalty recipient if token not supporting ERC-2981
   */
  function getGlobalRoyaltyRecipient() external view returns (address);

  /**
   * @return Get amount of currency in royalty an address can claim
   * @param _royaltyRecipient Address to check the claimable royalties
   */
  function getRoyalties(address _royaltyRecipient) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

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
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
  bool private _notEntered;

  constructor () {
    // Storing an initial non-zero value makes deployment a bit more
    // expensive, but in exchange the refund on every call to nonReentrant
    // will be lower in amount. Since refunds are capped to a percetange of
    // the total transaction's gas, it is best to keep them low in cases
    // like this one, to increase the likelihood of the full refund coming
    // into effect.
    _notEntered = true;
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
    require(_notEntered, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _notEntered = false;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _notEntered = true;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import './IERC165.sol';


interface IERC1155 is IERC165 {

  /****************************************|
  |                 Events                 |
  |_______________________________________*/

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);

  /**
   * @dev MUST emit when an approval is updated
   */
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
    * @notice Transfers amount of an _id from the _from address to the _to address specified
    * @dev MUST emit TransferSingle event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    * @param _from    Source address
    * @param _to      Target address
    * @param _id      ID of the token type
    * @param _amount  Transfered amount
    * @param _data    Additional data with no specified format, sent in call to `_to`
    */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

  /**
    * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
    * @dev MUST emit TransferBatch event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if length of `_ids` is not the same as length of `_amounts`
    * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
    * @param _from     Source addresses
    * @param _to       Target addresses
    * @param _ids      IDs of each token type
    * @param _amounts  Transfer amounts per token type
    * @param _data     Additional data with no specified format, sent in call to `_to`
  */
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return        The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @dev MUST emit the ApprovalForAll event on success
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external;

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {

  /**
   * @notice Handle the receipt of a single ERC1155 token type
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value MUST result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _amount    The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Handle the receipt of multiple ERC1155 token types
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value WILL result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _amounts   An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import "./ERC1155.sol";


/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions
 */
contract ERC1155MintBurn is ERC1155 {
  using SafeMath for uint256;

  /****************************************|
  |            Minting Functions           |
  |_______________________________________*/

  /**
   * @notice Mint _amount of tokens of a given id
   * @param _to      The address to mint tokens to
   * @param _id      Token id to mint
   * @param _amount  The amount to be minted
   * @param _data    Data to pass if receiver is contract
   */
  function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    // Add _amount
    balances[_to][_id] = balances[_to][_id].add(_amount);

    // Emit event
    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

    // Calling onReceive method if recipient is contract
    _callonERC1155Received(address(0x0), _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Mint tokens for each ids in _ids
   * @param _to       The address to mint tokens to
   * @param _ids      Array of ids to mint
   * @param _amounts  Array of amount of tokens to mint per id
   * @param _data    Data to pass if receiver is contract
   */
  function _batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155MintBurn#batchMint: INVALID_ARRAYS_LENGTH");

    // Number of mints to execute
    uint256 nMint = _ids.length;

     // Executing all minting
    for (uint256 i = 0; i < nMint; i++) {
      // Update storage balance
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

    // Calling onReceive method if recipient is contract
    _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, gasleft(), _data);
  }


  /****************************************|
  |            Burning Functions           |
  |_______________________________________*/

  /**
   * @notice Burn _amount of tokens of a given token id
   * @param _from    The address to burn tokens from
   * @param _id      Token id to burn
   * @param _amount  The amount to be burned
   */
  function _burn(address _from, uint256 _id, uint256 _amount)
    internal
  {
    //Substract _amount
    balances[_from][_id] = balances[_from][_id].sub(_amount);

    // Emit event
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  /**
   * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
   * @param _from     The address to burn tokens from
   * @param _ids      Array of token ids to burn
   * @param _amounts  Array of the amount to be burned
   */
  function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    // Number of mints to execute
    uint256 nBurn = _ids.length;
    require(nBurn == _amounts.length, "ERC1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH");

    // Executing all minting
    for (uint256 i = 0; i < nBurn; i++) {
      // Update storage balance
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

import "../../utils/SafeMath.sol";
import "../../interfaces/IERC1155TokenReceiver.sol";
import "../../interfaces/IERC1155.sol";
import "../../utils/Address.sol";
import "../../utils/ERC165.sol";


/**
 * @dev Implementation of Multi-Token Standard contract
 */
contract ERC1155 is IERC1155, ERC165 {
  using SafeMath for uint256;
  using Address for address;

  /***********************************|
  |        Variables and Events       |
  |__________________________________*/

  // onReceive function signatures
  bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  // Objects balances
  mapping (address => mapping(uint256 => uint256)) internal balances;

  // Operator Functions
  mapping (address => mapping(address => bool)) internal operators;


  /***********************************|
  |     Public Transfer Functions     |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    public override
  {
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeTransferFrom: INVALID_OPERATOR");
    require(_to != address(0),"ERC1155#safeTransferFrom: INVALID_RECIPIENT");
    // require(_amount <= balances[_from][_id]) is not necessary since checked with safemath operations

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    public override
  {
    // Requirements
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeBatchTransferFrom: INVALID_OPERATOR");
    require(_to != address(0), "ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT");

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);
  }


  /***********************************|
  |    Internal Transfer Functions    |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   */
  function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
    internal
  {
    // Update balances
    balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
    balances[_to][_id] = balances[_to][_id].add(_amount);     // Add amount

    // Emit event
    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
   */
  function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Check if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received{gas: _gasLimit}(msg.sender, _from, _id, _amount, _data);
      require(retval == ERC1155_RECEIVED_VALUE, "ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE");
    }
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   */
  function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

    // Number of transfer to execute
    uint256 nTransfer = _ids.length;

    // Executing all transfers
    for (uint256 i = 0; i < nTransfer; i++) {
      // Update storage balance of previous bin
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit event
    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
   */
  function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived{gas: _gasLimit}(msg.sender, _from, _ids, _amounts, _data);
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
    }
  }


  /***********************************|
  |         Operator Functions        |
  |__________________________________*/

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved)
    external override
  {
    // Update operator status
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
    public override view returns (bool isOperator)
  {
    return operators[_owner][_operator];
  }


  /***********************************|
  |         Balance Functions         |
  |__________________________________*/

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
    public override view returns (uint256)
  {
    return balances[_owner][_id];
  }

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    public override view returns (uint256[] memory)
  {
    require(_owners.length == _ids.length, "ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH");

    // Variables
    uint256[] memory batchBalances = new uint256[](_owners.length);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < _owners.length; i++) {
      batchBalances[i] = balances[_owners[i]][_ids[i]];
    }

    return batchBalances;
  }


  /***********************************|
  |          ERC165 Functions         |
  |__________________________________*/

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override(ERC165, IERC165) virtual pure returns (bool) {
    if (_interfaceID == type(IERC1155).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
}

pragma solidity 0.7.4;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }
}

pragma solidity 0.7.4;


/**
 * Utility library of inline functions on addresses
 */
library Address {

  // Default hash for EOA accounts returned by extcodehash
  bytes32 constant internal ACCOUNT_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract.
   * @param _address address of the account to check
   * @return Whether the target address is a contract
   */
  function isContract(address _address) internal view returns (bool) {
    bytes32 codehash;

    // Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address or if it has a non-zero code hash or account hash
    assembly { codehash := extcodehash(_address) }
    return (codehash != 0x0 && codehash != ACCOUNT_HASH);
  }
}

pragma solidity 0.7.4;
import "../interfaces/IERC165.sol";

abstract contract ERC165 is IERC165 {
  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) virtual override public pure returns (bool) {
    return _interfaceID == this.supportsInterface.selector;
  }
}

pragma solidity 0.7.4;

import "@0xsequence/erc-1155/contracts/interfaces/IERC1155.sol";

interface IERC20Wrapper is IERC1155 {

  /***********************************|
  |         Deposit Functions         |
  |__________________________________*/

  /**
   * Fallback function
   * @dev Deposit ETH in this contract to receive wrapped ETH
   */
  receive () external payable;

  /**
   * @dev Deposit ERC20 tokens or ETH in this contract to receive wrapped ERC20s
   * @param _token     The addess of the token to deposit in this contract
   * @param _recipient Address that will receive the ERC-1155 tokens
   * @param _value     The amount of token to deposit in this contract
   * Note: Users must first approve this contract addres on the contract of the ERC20 to be deposited
   */
  function deposit(address _token, address _recipient, uint256 _value) external payable;


  /***********************************|
  |         Withdraw Functions        |
  |__________________________________*/

  /**
   * @dev Withdraw wrapped ERC20 tokens in this contract to receive the original ERC20s or ETH
   * @param _token The addess of the token to withdrww from this contract
   * @param _to The address where the withdrawn tokens will go to
   * @param _value The amount of tokens to withdraw
   */
  function withdraw(address _token, address payable _to, uint256 _value) external;


  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  /**
   * @notice Return the Meta-ERC20 token ID for the given ERC-20 token address
   * @param _token ERC-20 token address to get the corresponding Meta-ERC20 token ID
   * @return tokenID Meta-ERC20 token ID
   */
  function getTokenID(address _token) external view returns (uint256 tokenID);

  /**
   * @notice Return the ERC-20 token address for the given Meta-ERC20 token ID
   * @param _id Meta-ERC20 token ID to get the corresponding ERC-20 token address
   * @return token ERC-20 token address
   */
  function getIdAddress(uint256 _id) external view returns (address token) ;

  /**
   * @notice Returns number of tokens currently registered
   */
  function getNTokens() external view;


  /***********************************|
  |        OnReceive Functions        |
  |__________________________________*/

  /**
   * @notice Withdraw ERC-20 tokens when receiving their ERC-1155 counterpart
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _value     The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address payable _from, uint256 _id, uint256 _value, bytes calldata _data ) external returns(bytes4);

  /**
   * @notice Withdraw ERC-20 tokens when receiving their ERC-1155 counterpart
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _values    An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(address _operator, address payable _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../interfaces/INiftyswapExchange.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC20.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC1155.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC1155TokenReceiver.sol";
import "@0xsequence/erc20-meta-token/contracts/interfaces/IERC20Wrapper.sol";

/**
 * @notice Will allow users to wrap their  ERC-20 into ERC-1155 tokens
 *         and pass their order to niftyswap. All funds will be returned
 *         to original owner and this contact should never hold any funds
 *         outside of a given wrap transaction.
 * @dev Hardcoding addresses for simplicity, easy to generalize if arguments
 *      are passed in functions, but adds a bit of complexity.
 */
contract WrapAndNiftyswap {

  IERC20Wrapper immutable public tokenWrapper; // ERC-20 to ERC-1155 token wrapper contract
  address immutable public exchange;           // Niftyswap exchange to use
  address immutable public erc20;              // ERC-20 used in niftyswap exchange
  address immutable public erc1155;            // ERC-1155 used in niftyswap exchange

  uint256 immutable internal wrappedTokenID; // ID of the wrapped token
  bool internal isInNiftyswap;               // Whether niftyswap is being called

  /**
   * @notice Registers contract addresses
   */
  constructor(
    address payable _tokenWrapper,
    address _exchange,
    address _erc20,
    address _erc1155
  ) {
    require(
      _tokenWrapper != address(0x0) &&
      _exchange != address(0x0) &&
      _erc20 != address(0x0) &&
      _erc1155 != address(0x0),
      "INVALID CONSTRUCTOR ARGUMENT"
    );

    tokenWrapper = IERC20Wrapper(_tokenWrapper);
    exchange = _exchange;
    erc20 = _erc20;
    erc1155 = _erc1155;

    // Approve wrapper contract for ERC-20
    // NOTE: This could potentially fail in some extreme usage as it's only
    // set once, but can easily redeploy this contract if that's the case.
    IERC20(_erc20).approve(_tokenWrapper, 2**256-1);

    // Store wrapped token ID
    wrappedTokenID = IERC20Wrapper(_tokenWrapper).getTokenID(_erc20);
  }

  /**
   * @notice Wrap ERC-20 to ERC-1155 and swap them
   * @dev User must approve this contract for ERC-20 first
   * @param _maxAmount       Maximum amount of ERC-20 user wants to spend
   * @param _recipient       Address where to send tokens
   * @param _niftyswapOrder  Encoded Niftyswap order passed in data field of safeTransferFrom()
   */
  function wrapAndSwap(
    uint256 _maxAmount,
    address _recipient,
    bytes calldata _niftyswapOrder
  ) external
  {
    // Decode niftyswap order
    INiftyswapExchange.BuyTokensObj memory obj;
    (, obj) = abi.decode(_niftyswapOrder, (bytes4, INiftyswapExchange.BuyTokensObj));

    // Force the recipient to not be set, otherwise wrapped token refunded will be
    // sent to the user and we won't be able to unwrap it.
    require(
      obj.recipient == address(0x0) || obj.recipient == address(this),
      "WrapAndNiftyswap#wrapAndSwap: ORDER RECIPIENT MUST BE THIS CONTRACT"
    );

    // Pull ERC-20 amount specified in order
    IERC20(erc20).transferFrom(msg.sender, address(this), _maxAmount);

    // Wrap ERC-20s
    tokenWrapper.deposit(erc20, address(this), _maxAmount);

    // Swap on Niftyswap
    isInNiftyswap = true;
    tokenWrapper.safeTransferFrom(address(this), exchange, wrappedTokenID, _maxAmount, _niftyswapOrder);
    isInNiftyswap = false;

    // Unwrap ERC-20 and send to receiver, if any received
    uint256 wrapped_token_amount = tokenWrapper.balanceOf(address(this), wrappedTokenID);
    if (wrapped_token_amount > 0) {
      tokenWrapper.withdraw(erc20, payable(_recipient), wrapped_token_amount);
    }

    // Transfer tokens purchased
    IERC1155(erc1155).safeBatchTransferFrom(address(this), _recipient, obj.tokensBoughtIDs, obj.tokensBoughtAmounts, "");
  }

  /**
   * @notice Accepts only tokenWrapper tokens
   * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155Received(address, address, uint256, uint256, bytes calldata)
    external view returns(bytes4)
  {
    if (msg.sender != address(tokenWrapper)) {
      revert("WrapAndNiftyswap#onERC1155Received: INVALID_ERC1155_RECEIVED");
    }
    return IERC1155TokenReceiver.onERC1155Received.selector;
  }

  /**
   * @notice If receives tracked ERC-1155, it will send a sell order to niftyswap and unwrap received
   *         wrapped token. The unwrapped tokens will be sent to the sender.
   * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(
    address,
    address _from,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes calldata _niftyswapOrder
  )
    external returns(bytes4)
  {
    // If coming from niftyswap or wrapped token, ignore
    if (isInNiftyswap || msg.sender == address(tokenWrapper)){
      return IERC1155TokenReceiver.onERC1155BatchReceived.selector;
    } else if (msg.sender != erc1155) {
      revert("WrapAndNiftyswap#onERC1155BatchReceived: INVALID_ERC1155_RECEIVED");
    }

    // Decode transfer data
    INiftyswapExchange.SellTokensObj memory obj;
    (,obj) = abi.decode(_niftyswapOrder, (bytes4, INiftyswapExchange.SellTokensObj));

    require(
      obj.recipient == address(0x0) || obj.recipient == address(this),
      "WrapAndNiftyswap#onERC1155BatchReceived: ORDER RECIPIENT MUST BE THIS CONTRACT"
    );

    // Swap on Niftyswap
    isInNiftyswap = true;
    IERC1155(msg.sender).safeBatchTransferFrom(address(this), exchange, _ids, _amounts, _niftyswapOrder);
    isInNiftyswap = false;

    // Send to recipient the unwrapped ERC-20, if any
    uint256 wrapped_token_amount = tokenWrapper.balanceOf(address(this), wrappedTokenID);
    if (wrapped_token_amount > 0) {
      // Doing it in 2 calls so tx history is more consistent
      tokenWrapper.withdraw(erc20, payable(address(this)), wrapped_token_amount);
      IERC20(erc20).transfer(_from, wrapped_token_amount);
    }

    return IERC1155TokenReceiver.onERC1155BatchReceived.selector;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

interface INiftyswapExchange {

  /***********************************|
  |               Events              |
  |__________________________________*/

  event TokensPurchase(
    address indexed buyer,
    address indexed recipient,
    uint256[] tokensBoughtIds,
    uint256[] tokensBoughtAmounts,
    uint256[] currencySoldAmounts
  );

  event CurrencyPurchase(
    address indexed buyer,
    address indexed recipient,
    uint256[] tokensSoldIds,
    uint256[] tokensSoldAmounts,
    uint256[] currencyBoughtAmounts
  );

  event LiquidityAdded(
    address indexed provider,
    uint256[] tokenIds,
    uint256[] tokenAmounts,
    uint256[] currencyAmounts
  );

  event LiquidityRemoved(
    address indexed provider,
    uint256[] tokenIds,
    uint256[] tokenAmounts,
    uint256[] currencyAmounts
  );

    // OnReceive Objects
  struct BuyTokensObj {
    address recipient;             // Who receives the tokens
    uint256[] tokensBoughtIDs;     // Token IDs to buy
    uint256[] tokensBoughtAmounts; // Amount of token to buy for each ID
    uint256 deadline;              // Timestamp after which the tx isn't valid anymore
  }

  struct SellTokensObj {
    address recipient;   // Who receives the currency
    uint256 minCurrency; // Total minimum number of currency  expected for all tokens sold
    uint256 deadline;    // Timestamp after which the tx isn't valid anymore
  }

  struct AddLiquidityObj {
    uint256[] maxCurrency; // Maximum number of currency to deposit with tokens
    uint256 deadline;      // Timestamp after which the tx isn't valid anymore
  }

  struct RemoveLiquidityObj {
    uint256[] minCurrency; // Minimum number of currency to withdraw
    uint256[] minTokens;   // Minimum number of tokens to withdraw
    uint256 deadline;      // Timestamp after which the tx isn't valid anymore
  }

  /***********************************|
  |        OnReceive Functions        |
  |__________________________________*/

  /**
   * @notice Handle which method is being called on Token transfer
   * @dev `_data` must be encoded as follow: abi.encode(bytes4, MethodObj)
   *   where bytes4 argument is the MethodObj object signature passed as defined
   *   in the `Signatures for onReceive control logic` section above
   * @param _operator The address which called the `safeTransferFrom` function
   * @param _from     The address which previously owned the token
   * @param _id       The id of the token being transferred
   * @param _amount   The amount of tokens being transferred
   * @param _data     Method signature and corresponding encoded arguments for method to call on *this* contract
   * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Handle which method is being called on transfer
   * @dev `_data` must be encoded as follow: abi.encode(bytes4, MethodObj)
   *   where bytes4 argument is the MethodObj object signature passed as defined
   *   in the `Signatures for onReceive control logic` section above
   * @param _from     The address which previously owned the Token
   * @param _ids      An array containing ids of each Token being transferred
   * @param _amounts  An array containing amounts of each Token being transferred
   * @param _data     Method signature and corresponding encoded arguments for method to call on *this* contract
   * @return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")
   */
  function onERC1155BatchReceived(address, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);


  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  /**
   * @dev Pricing function used for converting between currency token to Tokens.
   * @param _assetBoughtAmount  Amount of Tokens being bought.
   * @param _assetSoldReserve   Amount of currency tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of Tokens (output type) in exchange reserves.
   * @return Amount of currency tokens to send to Niftyswap.
   */
  function getBuyPrice(uint256 _assetBoughtAmount, uint256 _assetSoldReserve, uint256 _assetBoughtReserve) external pure returns (uint256);

  /**
   * @dev Pricing function used for converting Tokens to currency token.
   * @param _assetSoldAmount    Amount of Tokens being sold.
   * @param _assetSoldReserve   Amount of Tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of currency tokens in exchange reserves.
   * @return Amount of currency tokens to receive from Niftyswap.
   */
  function getSellPrice(uint256 _assetSoldAmount,uint256 _assetSoldReserve, uint256 _assetBoughtReserve) external pure returns (uint256);

  /**
   * @notice Get amount of currency in reserve for each Token _id in _ids
   * @param _ids Array of ID sto query currency reserve of
   * @return amount of currency in reserve for each Token _id
   */
  function getCurrencyReserves(uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @notice Return price for `currency => Token _id` trades with an exact token amount.
   * @param _ids          Array of ID of tokens bought.
   * @param _tokensBought Amount of Tokens bought.
   * @return Amount of currency needed to buy Tokens in _ids for amounts in _tokensBought
   */
  function getPrice_currencyToToken(uint256[] calldata _ids, uint256[] calldata _tokensBought) external view returns (uint256[] memory);

  /**
   * @notice Return price for `Token _id => currency` trades with an exact token amount.
   * @param _ids        Array of IDs  token sold.
   * @param _tokensSold Array of amount of each Token sold.
   * @return Amount of currency that can be bought for Tokens in _ids for amounts in _tokensSold
   */
  function getPrice_tokenToCurrency(uint256[] calldata _ids, uint256[] calldata _tokensSold) external view returns (uint256[] memory);

  /**
   * @notice Get total supply of liquidity tokens
   * @param _ids ID of the Tokens
   * @return The total supply of each liquidity token id provided in _ids
   */
  function getTotalSupply(uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @return Address of Token that is sold on this exchange.
   */
  function getTokenAddress() external view returns (address);

  /**
   * @return Address of the currency contract that is used as currency and its corresponding id
   */
  function getCurrencyInfo() external view returns (address, uint256);

  /**
   * @return Address of factory that created this exchange.
   */
  function getFactoryAddress() external view returns (address);

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;
import "../interfaces/INiftyswapExchange20.sol";
import "../utils/ReentrancyGuard.sol";
import "../interfaces/IERC2981.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC20.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC165.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC1155.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC1155TokenReceiver.sol";
import "@0xsequence/erc-1155/contracts/tokens/ERC1155/ERC1155MintBurn.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

interface IGalaxyMasterchief {
    function creator() external returns (address);
}

/**
 * This Uniswap-like implementation supports ERC-1155 standard tokens
 * with an ERC-20 based token used as a currency instead of Ether.
 *
 * Liquidity tokens are also ERC-1155 tokens you can find the ERC-1155
 * implementation used here:
 *    https://github.com/horizon-games/multi-token-standard/tree/master/contracts/tokens/ERC1155
 *
 * @dev Like Uniswap, tokens with 0 decimals and low supply are susceptible to significant rounding
 *      errors when it comes to removing liquidity, possibly preventing them to be withdrawn without
 *      some collaboration between liquidity providers.
 */
contract GalaxyNiftyswapExchange20 is ReentrancyGuard, ERC1155MintBurn, INiftyswapExchange20 {
  using SafeMath for uint256;

  /***********************************|
  |       Variables & Constants       |
  |__________________________________*/

  // Variables
  IERC1155 internal immutable token;              // address of the ERC-1155 token contract
  address internal immutable currency;            // address of the ERC-20 currency used for exchange

  uint256 internal constant FEE_MULTIPLIER = 990; // multiplier that calculates the LP fee (1.0%)

  // Royalty variables
  uint256 internal globalRoyaltyFee;        // global royalty fee multiplier
  address internal globalRoyaltyRecipient;  // global royalty fee recipient

  // Mapping variables
  mapping(uint256 => uint256) internal totalSupplies;    // Liquidity pool token supply per Token id
  mapping(uint256 => uint256) internal currencyReserves; // currency Token reserve per Token id
  mapping(address => uint256) internal royalties;        // Mapping tracking how much royalties can be claimed per address

  address public immutable masterchief;

  /***********************************|
  |            Constructor           |
  |__________________________________*/

  /**
   * @notice Create instance of exchange contract with respective token and currency token
   * @dev Royalty fee will need to be manually set by admin.
   * @param _tokenAddr     The address of the ERC-1155 Token
   * @param _currencyAddr  The address of the ERC-20 currency Token
   */
  constructor(address _masterchief, address _tokenVault, address _tokenAddr, address _currencyAddr) {
    require(
      _masterchief != address(0) && _tokenAddr != address(0) && _currencyAddr != address(0),
      "NiftyswapExchange20#constructor:INVALID_INPUT"
    );

    masterchief = _masterchief;
    globalRoyaltyRecipient = _tokenVault;

    token = IERC1155(_tokenAddr);
    currency = _currencyAddr;
  }

  modifier onlyCreator {
    require(IGalaxyMasterchief(masterchief).creator() == msg.sender); _;
  }

  /***********************************|
  |        Exchange Functions         |
  |__________________________________*/

  /**
   * @notice Convert currency tokens to Tokens _id and transfers Tokens to recipient.
   */
  function _currencyToToken(
    uint256[] memory _tokenIds,
    uint256[] memory _tokensBoughtAmounts,
    uint256 _maxCurrency,
    uint256 _deadline,
    address _recipient
  )
    internal nonReentrant() returns (uint256[] memory currencySold)
  {
    // Input validation
    require(_deadline >= block.timestamp, "NiftyswapExchange20#_currencyToToken: DEADLINE_EXCEEDED");

    // Number of Token IDs to deposit
    uint256 nTokens = _tokenIds.length;
    uint256 totalRefundCurrency = _maxCurrency;

    // Initialize variables
    currencySold = new uint256[](nTokens); // Amount of currency tokens sold per ID

    // Get token reserves
    uint256[] memory tokenReserves = _getTokenReserves(_tokenIds);

    // Assumes the currency Tokens are already received by contract, but not
    // the Tokens Ids

    // Remove liquidity for each Token ID in _tokenIds
    for (uint256 i = 0; i < nTokens; i++) {
      // Store current id and amount from argument arrays
      uint256 idBought = _tokenIds[i];
      uint256 amountBought = _tokensBoughtAmounts[i];
      uint256 tokenReserve = tokenReserves[i];

      require(amountBought > 0, "NiftyswapExchange20#_currencyToToken: NULL_TOKENS_BOUGHT");

      // Load currency token and Token _id reserves
      uint256 currencyReserve = currencyReserves[idBought];

      // Get amount of currency tokens to send for purchase
      // Neither reserves amount have been changed so far in this transaction, so
      // no adjustment to the inputs is needed
      uint256 currencyAmount = getBuyPrice(amountBought, currencyReserve, tokenReserve);

      // If royalty, increase amount buyer will need to pay after LP fees were calculated
      // Note: Royalty will be a bit higher since LF fees are added first
      (address royaltyRecipient, uint256 royaltyAmount) = getRoyaltyInfo(currencyAmount);
      if (royaltyAmount > 0) {
        royalties[royaltyRecipient] = royalties[royaltyRecipient].add(royaltyAmount);
      }

      // Calculate currency token amount to refund (if any) where whatever is not used will be returned
      // Will throw if total cost exceeds _maxCurrency
      totalRefundCurrency = totalRefundCurrency.sub(currencyAmount).sub(royaltyAmount);

      // Append Token id, Token id amount and currency token amount to tracking arrays
      currencySold[i] = currencyAmount.add(royaltyAmount);

      // Update individual currency reseve amount (royalty is not added to liquidity)
      currencyReserves[idBought] = currencyReserve.add(currencyAmount);
    }

    // Refund currency token if any
    if (totalRefundCurrency > 0) {
      TransferHelper.safeTransfer(currency, _recipient, totalRefundCurrency);
    }

    // Send Tokens all tokens purchased
    token.safeBatchTransferFrom(address(this), _recipient, _tokenIds, _tokensBoughtAmounts, "");
    return currencySold;
  }

  /**
   * @dev Pricing function used for converting between currency token to Tokens.
   * @param _assetBoughtAmount  Amount of Tokens being bought.
   * @param _assetSoldReserve   Amount of currency tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of Tokens (output type) in exchange reserves.
   * @return price Amount of currency tokens to send to Niftyswap.
   */
  function getBuyPrice(
    uint256 _assetBoughtAmount,
    uint256 _assetSoldReserve,
    uint256 _assetBoughtReserve)
    override public pure returns (uint256 price)
  {
    // Reserves must not be empty
    require(_assetSoldReserve > 0 && _assetBoughtReserve > 0, "NiftyswapExchange20#getBuyPrice: EMPTY_RESERVE");

    // Calculate price with fee
    uint256 numerator = _assetSoldReserve.mul(_assetBoughtAmount).mul(1000);
    uint256 denominator = (_assetBoughtReserve.sub(_assetBoughtAmount)).mul(FEE_MULTIPLIER);
    (price, ) = divRound(numerator, denominator);
    return price; // Will add 1 if rounding error
  }

  /**
   * @dev Pricing function used for converting Tokens to currency token (including royalty fee)
   * @param _assetBoughtAmount  Amount of Tokens being bought.
   * @param _assetSoldReserve   Amount of currency tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of Tokens (output type) in exchange reserves.
   * @return price Amount of currency tokens to send to Niftyswap.
   */
  function getBuyPriceWithRoyalty(
    uint256 _assetBoughtAmount,
    uint256 _assetSoldReserve,
    uint256 _assetBoughtReserve)
    override public view returns (uint256 price)
  {
    uint256 cost = getBuyPrice(_assetBoughtAmount, _assetSoldReserve, _assetBoughtReserve);
    (, uint256 royaltyAmount) = getRoyaltyInfo(cost);
    return cost.add(royaltyAmount);
  }

  /**
   * @notice Convert Tokens _id to currency tokens and transfers Tokens to recipient.
   * @dev User specifies EXACT Tokens _id sold and MINIMUM currency tokens received.
   * @dev Assumes that all trades will be valid, or the whole tx will fail
   * @dev Sorting _tokenIds is mandatory for efficient way of preventing duplicated IDs (which would lead to errors)
   * @param _tokenIds           Array of Token IDs that are sold
   * @param _tokensSoldAmounts  Array of Amount of Tokens sold for each id in _tokenIds.
   * @param _minCurrency        Minimum amount of currency tokens to receive
   * @param _deadline           Timestamp after which this transaction will be reverted
   * @param _recipient          The address that receives output currency tokens.
   * @param _extraFeeRecipients  Array of addresses that will receive extra fee
   * @param _extraFeeAmounts     Array of amounts of currency that will be sent as extra fee
   * @return currencyBought How much currency was actually purchased.
   */
  function _tokenToCurrency(
    uint256[] memory _tokenIds,
    uint256[] memory _tokensSoldAmounts,
    uint256 _minCurrency,
    uint256 _deadline,
    address _recipient,
    address[] memory _extraFeeRecipients,
    uint256[] memory _extraFeeAmounts
  )
    internal nonReentrant() returns (uint256[] memory currencyBought)
  {
    // Number of Token IDs to deposit
    uint256 nTokens = _tokenIds.length;

    // Input validation
    require(_deadline >= block.timestamp, "NiftyswapExchange20#_tokenToCurrency: DEADLINE_EXCEEDED");

    // Initialize variables
    uint256 totalCurrency = 0; // Total amount of currency tokens to transfer
    currencyBought = new uint256[](nTokens);

    // Get token reserves
    uint256[] memory tokenReserves = _getTokenReserves(_tokenIds);

    // Assumes the Tokens ids are already received by contract, but not
    // the Tokens Ids. Will return cards not sold if invalid price.

    // Remove liquidity for each Token ID in _tokenIds
    for (uint256 i = 0; i < nTokens; i++) {
      // Store current id and amount from argument arrays
      uint256 idSold = _tokenIds[i];
      uint256 amountSold = _tokensSoldAmounts[i];
      uint256 tokenReserve = tokenReserves[i];

      // If 0 tokens send for this ID, revert
      require(amountSold > 0, "NiftyswapExchange20#_tokenToCurrency: NULL_TOKENS_SOLD");

      // Load currency token and Token _id reserves
      uint256 currencyReserve = currencyReserves[idSold];

      // Get amount of currency that will be received
      // Need to sub amountSold because tokens already added in reserve, which would bias the calculation
      // Don't need to add it for currencyReserve because the amount is added after this calculation
      uint256 currencyAmount = getSellPrice(amountSold, tokenReserve.sub(amountSold), currencyReserve);

      // If royalty, substract amount seller will receive after LP fees were calculated
      // Note: Royalty will be a bit lower since LF fees are substracted first
      (address royaltyRecipient, uint256 royaltyAmount) = getRoyaltyInfo(currencyAmount);
      if (royaltyAmount > 0) {
        royalties[royaltyRecipient] = royalties[royaltyRecipient].add(royaltyAmount);
      }

      // Increase total amount of currency to receive (minus royalty to pay)
      totalCurrency = totalCurrency.add(currencyAmount.sub(royaltyAmount));

      // Update individual currency reseve amount
      currencyReserves[idSold] = currencyReserve.sub(currencyAmount);

      // Append Token id, Token id amount and currency token amount to tracking arrays
      currencyBought[i] = currencyAmount.sub(royaltyAmount);
    }

    // Set the extra fees aside to recipients after sale
    for (uint256 i = 0; i < _extraFeeAmounts.length; i++) {
      if (_extraFeeAmounts[i] > 0) {
        totalCurrency = totalCurrency.sub(_extraFeeAmounts[i]);
        royalties[_extraFeeRecipients[i]] = royalties[_extraFeeRecipients[i]].add(_extraFeeAmounts[i]);
      }
    }

    // If minCurrency is not met
    require(totalCurrency >= _minCurrency, "NiftyswapExchange20#_tokenToCurrency: INSUFFICIENT_CURRENCY_AMOUNT");

    // Transfer currency here
    TransferHelper.safeTransfer(currency, _recipient, totalCurrency);
    return currencyBought;
  }

  /**
   * @dev Pricing function used for converting Tokens to currency token.
   * @param _assetSoldAmount    Amount of Tokens being sold.
   * @param _assetSoldReserve   Amount of Tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of currency tokens in exchange reserves.
   * @return price Amount of currency tokens to receive from Niftyswap.
   */
  function getSellPrice(
    uint256 _assetSoldAmount,
    uint256 _assetSoldReserve,
    uint256 _assetBoughtReserve)
    override public pure returns (uint256 price)
  {
    //Reserves must not be empty
    require(_assetSoldReserve > 0 && _assetBoughtReserve > 0, "NiftyswapExchange20#getSellPrice: EMPTY_RESERVE");

    // Calculate amount to receive (with fee) before royalty
    uint256 _assetSoldAmount_withFee = _assetSoldAmount.mul(FEE_MULTIPLIER);
    uint256 numerator = _assetSoldAmount_withFee.mul(_assetBoughtReserve);
    uint256 denominator = _assetSoldReserve.mul(1000).add(_assetSoldAmount_withFee);
    return numerator / denominator; //Rounding errors will favor Niftyswap, so nothing to do
  }

  /**
   * @dev Pricing function used for converting Tokens to currency token (including royalty fee)
   * @param _assetSoldAmount    Amount of Tokens being sold.
   * @param _assetSoldReserve   Amount of Tokens in exchange reserves.
   * @param _assetBoughtReserve Amount of currency tokens in exchange reserves.
   * @return price Amount of currency tokens to receive from Niftyswap.
   */
  function getSellPriceWithRoyalty(
    uint256 _assetSoldAmount,
    uint256 _assetSoldReserve,
    uint256 _assetBoughtReserve)
    override public view returns (uint256 price)
  {
    uint256 sellAmount = getSellPrice(_assetSoldAmount, _assetSoldReserve, _assetBoughtReserve);
    (, uint256 royaltyAmount) = getRoyaltyInfo(sellAmount);
    return sellAmount.sub(royaltyAmount);
  }

  /***********************************|
  |        Liquidity Functions        |
  |__________________________________*/

  /**
   * @notice Deposit less than max currency tokens && exact Tokens (token ID) at current ratio to mint liquidity pool tokens.
   * @dev min_liquidity does nothing when total liquidity pool token supply is 0.
   * @dev Assumes that sender approved this contract on the currency
   * @dev Sorting _tokenIds is mandatory for efficient way of preventing duplicated IDs (which would lead to errors)
   * @param _provider      Address that provides liquidity to the reserve
   * @param _tokenIds      Array of Token IDs where liquidity is added
   * @param _tokenAmounts  Array of amount of Tokens deposited corresponding to each ID provided in _tokenIds
   * @param _maxCurrency   Array of maximum number of tokens deposited for each ID provided in _tokenIds.
   *                       Deposits max amount if total liquidity pool token supply is 0.
   * @param _deadline      Timestamp after which this transaction will be reverted
   */
  function _addLiquidity(
    address _provider,
    uint256[] memory _tokenIds,
    uint256[] memory _tokenAmounts,
    uint256[] memory _maxCurrency,
    uint256 _deadline)
    internal nonReentrant()
  {
    // Requirements
    require(_deadline >= block.timestamp, "NiftyswapExchange20#_addLiquidity: DEADLINE_EXCEEDED");

    // Initialize variables
    uint256 nTokens = _tokenIds.length; // Number of Token IDs to deposit
    uint256 totalCurrency = 0;          // Total amount of currency tokens to transfer

    // Initialize arrays
    uint256[] memory liquiditiesToMint = new uint256[](nTokens);
    uint256[] memory currencyAmounts = new uint256[](nTokens);

    // Get token reserves
    uint256[] memory tokenReserves = _getTokenReserves(_tokenIds);

    // Assumes tokens _ids are deposited already, but not currency tokens
    // as this is calculated and executed below.

    // Loop over all Token IDs to deposit
    for (uint256 i = 0; i < nTokens; i ++) {
      // Store current id and amount from argument arrays
      uint256 tokenId = _tokenIds[i];
      uint256 amount = _tokenAmounts[i];

      // Check if input values are acceptable
      require(_maxCurrency[i] > 0, "NiftyswapExchange20#_addLiquidity: NULL_MAX_CURRENCY");
      require(amount > 0, "NiftyswapExchange20#_addLiquidity: NULL_TOKENS_AMOUNT");

      // Current total liquidity calculated in currency token
      uint256 totalLiquidity = totalSupplies[tokenId];

      // When reserve for this token already exists
      if (totalLiquidity > 0) {

        // Load currency token and Token reserve's supply of Token id
        uint256 currencyReserve = currencyReserves[tokenId]; // Amount not yet in reserve
        uint256 tokenReserve = tokenReserves[i];

        /**
        * Amount of currency tokens to send to token id reserve:
        * X/Y = dx/dy
        * dx = X*dy/Y
        * where
        *   X:  currency total liquidity
        *   Y:  Token _id total liquidity (before tokens were received)
        *   dy: Amount of token _id deposited
        *   dx: Amount of currency to deposit
        *
        * Adding .add(1) if rounding errors so to not favor users incorrectly
        */
        (uint256 currencyAmount, bool rounded) = divRound(amount.mul(currencyReserve), tokenReserve.sub(amount));
        require(_maxCurrency[i] >= currencyAmount, "NiftyswapExchange20#_addLiquidity: MAX_CURRENCY_AMOUNT_EXCEEDED");

        // Update currency reserve size for Token id before transfer
        currencyReserves[tokenId] = currencyReserve.add(currencyAmount);

        // Update totalCurrency
        totalCurrency = totalCurrency.add(currencyAmount);

        // Proportion of the liquidity pool to give to current liquidity provider
        // If rounding error occured, round down to favor previous liquidity providers
        // See https://github.com/0xsequence/niftyswap/issues/19
        liquiditiesToMint[i] = (currencyAmount.sub(rounded ? 1 : 0)).mul(totalLiquidity) / currencyReserve;
        currencyAmounts[i] = currencyAmount;

        // Mint liquidity ownership tokens and increase liquidity supply accordingly
        totalSupplies[tokenId] = totalLiquidity.add(liquiditiesToMint[i]);

      } else {
        uint256 maxCurrency = _maxCurrency[i];

        // Otherwise rounding error could end up being significant on second deposit
        require(maxCurrency >= 1000000000, "NiftyswapExchange20#_addLiquidity: INVALID_CURRENCY_AMOUNT");

        // Initial liquidity. Check if provider is creator
        require(_provider == IGalaxyMasterchief(masterchief).creator(), "NiftyswapExchange20#_addLiquidity: INITIAL_LIQUIDITY");

        // Update currency  reserve size for Token id before transfer
        currencyReserves[tokenId] = maxCurrency;

        // Update totalCurrency
        totalCurrency = totalCurrency.add(maxCurrency);

        // Initial liquidity is amount deposited (Incorrect pricing will be arbitraged)
        // uint256 initialLiquidity = _maxCurrency;
        totalSupplies[tokenId] = maxCurrency;

        // Liquidity to mints
        liquiditiesToMint[i] = maxCurrency;
        currencyAmounts[i] = maxCurrency;
      }
    }

    // Mint liquidity pool tokens
    _batchMint(_provider, _tokenIds, liquiditiesToMint, "");

    // Transfer all currency to this contract
    TransferHelper.safeTransferFrom(currency, _provider, address(this), totalCurrency);

    // Emit event
    emit LiquidityAdded(_provider, _tokenIds, _tokenAmounts, currencyAmounts);
  }

  /**
   * @dev Burn liquidity pool tokens to withdraw currency  && Tokens at current ratio.
   * @dev Sorting _tokenIds is mandatory for efficient way of preventing duplicated IDs (which would lead to errors)
   * @param _provider         Address that removes liquidity to the reserve
   * @param _tokenIds         Array of Token IDs where liquidity is removed
   * @param _poolTokenAmounts Array of Amount of liquidity pool tokens burned for each Token id in _tokenIds.
   * @param _minCurrency      Minimum currency withdrawn for each Token id in _tokenIds.
   * @param _minTokens        Minimum Tokens id withdrawn for each Token id in _tokenIds.
   * @param _deadline         Timestamp after which this transaction will be reverted
   */
  function _removeLiquidity(
    address _provider,
    uint256[] memory _tokenIds,
    uint256[] memory _poolTokenAmounts,
    uint256[] memory _minCurrency,
    uint256[] memory _minTokens,
    uint256 _deadline)
    internal nonReentrant()
  {
    // Input validation
    require(_deadline > block.timestamp, "NiftyswapExchange20#_removeLiquidity: DEADLINE_EXCEEDED");

    // Initialize variables
    uint256 nTokens = _tokenIds.length;                        // Number of Token IDs to deposit
    uint256 totalCurrency = 0;                                 // Total amount of currency  to transfer
    uint256[] memory tokenAmounts = new uint256[](nTokens);    // Amount of Tokens to transfer for each id
    uint256[] memory currencyAmounts = new uint256[](nTokens); // Amount of currency to transfer for each id

    // Get token reserves
    uint256[] memory tokenReserves = _getTokenReserves(_tokenIds);

    // Assumes NIFTY liquidity tokens are already received by contract, but not
    // the currency nor the Tokens Ids

    // Remove liquidity for each Token ID in _tokenIds
    for (uint256 i = 0; i < nTokens; i++) {
      // Store current id and amount from argument arrays
      uint256 id = _tokenIds[i];
      uint256 amountPool = _poolTokenAmounts[i];
      uint256 tokenReserve = tokenReserves[i];

      // Load total liquidity pool token supply for Token _id
      uint256 totalLiquidity = totalSupplies[id];
      require(totalLiquidity > 0, "NiftyswapExchange20#_removeLiquidity: NULL_TOTAL_LIQUIDITY");

      // Load currency and Token reserve's supply of Token id
      uint256 currencyReserve = currencyReserves[id];

      // Calculate amount to withdraw for currency and Token _id
      uint256 currencyAmount = amountPool.mul(currencyReserve) / totalLiquidity;
      uint256 tokenAmount = amountPool.mul(tokenReserve) / totalLiquidity;

      // Verify if amounts to withdraw respect minimums specified
      require(currencyAmount >= _minCurrency[i], "NiftyswapExchange20#_removeLiquidity: INSUFFICIENT_CURRENCY_AMOUNT");
      require(tokenAmount >= _minTokens[i], "NiftyswapExchange20#_removeLiquidity: INSUFFICIENT_TOKENS");

      // Update total liquidity pool token supply of Token _id
      totalSupplies[id] = totalLiquidity.sub(amountPool);

      // Update currency reserve size for Token id
      currencyReserves[id] = currencyReserve.sub(currencyAmount);

      // Update totalCurrency and tokenAmounts
      totalCurrency = totalCurrency.add(currencyAmount);
      tokenAmounts[i] = tokenAmount;
      currencyAmounts[i] = currencyAmount;
    }

    // Burn liquidity pool tokens for offchain supplies
    _batchBurn(address(this), _tokenIds, _poolTokenAmounts);

    // Transfer total currency and all Tokens ids
    TransferHelper.safeTransfer(currency, _provider, totalCurrency);
    token.safeBatchTransferFrom(address(this), _provider, _tokenIds, tokenAmounts, "");

    // Emit event
    //emit LiquidityRemoved(_provider, _tokenIds, tokenAmounts, currencyAmounts);
  }

  /***********************************|
  |     Receiver Methods Handler      |
  |__________________________________*/

  // Method signatures for onReceive control logic

  // bytes4(keccak256(
  //   "_tokenToCurrency(uint256[],uint256[],uint256,uint256,address,address[],uint256[])"
  // ));
  bytes4 internal constant SELLTOKENS_SIG = 0xade79c7a;

  //  bytes4(keccak256(
  //   "_addLiquidity(address,uint256[],uint256[],uint256[],uint256)"
  // ));
  bytes4 internal constant ADDLIQUIDITY_SIG = 0x82da2b73;

  // bytes4(keccak256(
  //    "_removeLiquidity(address,uint256[],uint256[],uint256[],uint256[],uint256)"
  // ));
  bytes4 internal constant REMOVELIQUIDITY_SIG = 0x5c0bf259;

  // bytes4(keccak256(
  //   "DepositTokens()"
  // ));
  bytes4 internal constant DEPOSIT_SIG = 0xc8c323f9;

  /***********************************|
  |           Buying Tokens           |
  |__________________________________*/

  /**
   * @notice Convert currency tokens to Tokens _id and transfers Tokens to recipient.
   * @dev User specifies MAXIMUM inputs (_maxCurrency) and EXACT outputs.
   * @dev Assumes that all trades will be successful, or revert the whole tx
   * @dev Exceeding currency tokens sent will be refunded to recipient
   * @dev Sorting IDs is mandatory for efficient way of preventing duplicated IDs (which would lead to exploit)
   * @param _tokenIds            Array of Tokens ID that are bought
   * @param _tokensBoughtAmounts Amount of Tokens id bought for each corresponding Token id in _tokenIds
   * @param _maxCurrency         Total maximum amount of currency tokens to spend for all Token ids
   * @param _deadline            Timestamp after which this transaction will be reverted
   * @param _recipient           The address that receives output Tokens and refund
   * @param _extraFeeRecipients  Array of addresses that will receive extra fee
   * @param _extraFeeAmounts     Array of amounts of currency that will be sent as extra fee
   * @return currencySold How much currency was actually sold.
   */
  function buyTokens(
    uint256[] memory _tokenIds,
    uint256[] memory _tokensBoughtAmounts,
    uint256 _maxCurrency,
    uint256 _deadline,
    address _recipient,
    address[] memory _extraFeeRecipients,
    uint256[] memory _extraFeeAmounts
  )
    override external returns (uint256[] memory)
  {
    require(_deadline >= block.timestamp, "NiftyswapExchange20#buyTokens: DEADLINE_EXCEEDED");
    require(_tokenIds.length > 0, "NiftyswapExchange20#buyTokens: INVALID_CURRENCY_IDS_AMOUNT");

    // Transfer the tokens for purchase
    TransferHelper.safeTransferFrom(currency, msg.sender, address(this), _maxCurrency);

    address recipient = _recipient == address(0x0) ? msg.sender : _recipient;

    // Set the extra fee aside to recipients ahead of purchase, if any.
    uint256 maxCurrency = _maxCurrency;
    uint256 nExtraFees = _extraFeeRecipients.length;
    require(nExtraFees == _extraFeeAmounts.length, "NiftyswapExchange20#buyTokens: EXTRA_FEES_ARRAYS_ARE_NOT_SAME_LENGTH");

    for (uint256 i = 0; i < nExtraFees; i++) {
      if (_extraFeeAmounts[i] > 0) {
        maxCurrency = maxCurrency.sub(_extraFeeAmounts[i]);
        royalties[_extraFeeRecipients[i]] = royalties[_extraFeeRecipients[i]].add(_extraFeeAmounts[i]);
      }
    }

    // Execute trade and retrieve amount of currency spent
    uint256[] memory currencySold = _currencyToToken(_tokenIds, _tokensBoughtAmounts, maxCurrency, _deadline, recipient);
    emit TokensPurchase(msg.sender, recipient, _tokenIds, _tokensBoughtAmounts, currencySold);

    return currencySold;
  }

  /**
   * @notice Handle which method is being called on transfer
   * @dev `_data` must be encoded as follow: abi.encode(bytes4, MethodObj)
   *   where bytes4 argument is the MethodObj object signature passed as defined
   *   in the `Signatures for onReceive control logic` section above
   * @param _from     The address which previously owned the Token
   * @param _ids      An array containing ids of each Token being transferred
   * @param _amounts  An array containing amounts of each Token being transferred
   * @param _data     Method signature and corresponding encoded arguments for method to call on *this* contract
   * @return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")
   */
  function onERC1155BatchReceived(
    address, // _operator,
    address _from,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data)
    override public returns(bytes4)
  {
    // This function assumes that the ERC-1155 token contract can
    // only call `onERC1155BatchReceived()` via a valid token transfer.
    // Users must be responsible and only use this Niftyswap exchange
    // contract with ERC-1155 compliant token contracts.

    // Obtain method to call via object signature
    bytes4 functionSignature = abi.decode(_data, (bytes4));

    /***********************************|
    |           Selling Tokens          |
    |__________________________________*/

    if (functionSignature == SELLTOKENS_SIG) {

      // Tokens received need to be Token contract
      require(msg.sender == address(token), "NiftyswapExchange20#onERC1155BatchReceived: INVALID_TOKENS_TRANSFERRED");

      // Decode SellTokensObj from _data to call _tokenToCurrency()
      SellTokensObj memory obj;
      (, obj) = abi.decode(_data, (bytes4, SellTokensObj));
      address recipient = obj.recipient == address(0x0) ? _from : obj.recipient;

      // Validate fee arrays
      require(obj.extraFeeRecipients.length == obj.extraFeeAmounts.length, "NiftyswapExchange20#buyTokens: EXTRA_FEES_ARRAYS_ARE_NOT_SAME_LENGTH");

      // Execute trade and retrieve amount of currency received
      uint256[] memory currencyBought = _tokenToCurrency(_ids, _amounts, obj.minCurrency, obj.deadline, recipient, obj.extraFeeRecipients, obj.extraFeeAmounts);
      emit CurrencyPurchase(_from, recipient, _ids, _amounts, currencyBought);

    /***********************************|
    |      Adding Liquidity Tokens      |
    |__________________________________*/

    } else if (functionSignature == ADDLIQUIDITY_SIG) {
      // Only allow to receive ERC-1155 tokens from `token` contract
      require(msg.sender == address(token), "NiftyswapExchange20#onERC1155BatchReceived: INVALID_TOKEN_TRANSFERRED");

      // Decode AddLiquidityObj from _data to call _addLiquidity()
      AddLiquidityObj memory obj;
      (, obj) = abi.decode(_data, (bytes4, AddLiquidityObj));
      _addLiquidity(_from, _ids, _amounts, obj.maxCurrency, obj.deadline);

    /***********************************|
    |      Removing iquidity Tokens     |
    |__________________________________*/

    } else if (functionSignature == REMOVELIQUIDITY_SIG) {
      // Tokens received need to be NIFTY-1155 tokens
      require(msg.sender == address(this), "NiftyswapExchange20#onERC1155BatchReceived: INVALID_NIFTY_TOKENS_TRANSFERRED");

      // Decode RemoveLiquidityObj from _data to call _removeLiquidity()
      RemoveLiquidityObj memory obj;
      (, obj) = abi.decode(_data, (bytes4, RemoveLiquidityObj));
      _removeLiquidity(_from, _ids, _amounts, obj.minCurrency, obj.minTokens, obj.deadline);

    /***********************************|
    |      Deposits & Invalid Calls     |
    |__________________________________*/

    } else if (functionSignature == DEPOSIT_SIG) {
      // Do nothing for when contract is self depositing
      // This could be use to deposit currency "by accident", which would be locked
      require(msg.sender == address(currency), "NiftyswapExchange20#onERC1155BatchReceived: INVALID_TOKENS_DEPOSITED");

    } else {
      revert("NiftyswapExchange20#onERC1155BatchReceived: INVALID_METHOD");
    }

    return ERC1155_BATCH_RECEIVED_VALUE;
  }

  /**
   * @dev Will pass to onERC115Batch5Received
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes memory _data)
    override public returns(bytes4)
  {
    uint256[] memory ids = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);

    ids[0] = _id;
    amounts[0] = _amount;

    require(
      ERC1155_BATCH_RECEIVED_VALUE == onERC1155BatchReceived(_operator, _from, ids, amounts, _data),
      "NiftyswapExchange20#onERC1155Received: INVALID_ONRECEIVED_MESSAGE"
    );

    return ERC1155_RECEIVED_VALUE;
  }

  /**
   * @notice Prevents receiving Ether or calls to unsuported methods
   */
  fallback () external {
    revert("NiftyswapExchange20:UNSUPPORTED_METHOD");
  }

  /***********************************|
  |         Royalty Functions         |
  |__________________________________*/

  /**
   * @notice Will set the royalties fees and recipient
   * @param _fee       Fee pourcentage with a 1000 basis (e.g. 0.3% is 3 and 1% is 10 and 100% is 1000. Max 10%)
   */
  function setRoyaltyFee(uint256 _fee) onlyCreator public {
    require(_fee <= 100, "NiftyswapExchange20#setRoyaltyInfo: ROYALTY_FEE_IS_TOO_HIGH");
    globalRoyaltyFee = _fee;
    emit RoyaltyChanged(globalRoyaltyRecipient, _fee);
  }

  /**
   * @notice Will send the royalties that _royaltyRecipient can claim, if any
   * @dev Anyone can call this function such that payout could be distributed
   *      regularly instead of being claimed.
   * @param _royaltyRecipient Address that is able to claim royalties
   */
  function sendRoyalties(address _royaltyRecipient) override external {
    uint256 royaltyAmount = royalties[_royaltyRecipient];
    royalties[_royaltyRecipient] = 0;
    TransferHelper.safeTransfer(currency, _royaltyRecipient, royaltyAmount);
  }

  /**
   * @notice Will return how much of currency need to be paid for the royalty
   * @param _cost    Amount of currency sent/received for the trade
   * @return recipient Address that will be able to claim the royalty
   * @return royalty Amount of currency that will be sent to royalty recipient
   */
  function getRoyaltyInfo(uint256 _cost) public view returns (address recipient, uint256 royalty) {
    return (globalRoyaltyRecipient, (_cost.mul(globalRoyaltyFee)).div(1000));
  }


  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  /**
   * @notice Get amount of currency in reserve for each Token _id in _ids
   * @param _ids Array of ID sto query currency reserve of
   * @return amount of currency in reserve for each Token _id
   */
  function getCurrencyReserves(
    uint256[] calldata _ids)
    override external view returns (uint256[] memory)
  {
    uint256 nIds = _ids.length;
    uint256[] memory currencyReservesReturn = new uint256[](nIds);
    for (uint256 i = 0; i < nIds; i++) {
      currencyReservesReturn[i] = currencyReserves[_ids[i]];
    }
    return currencyReservesReturn;
  }

  /**
   * @notice Return price for `currency => Token _id` trades with an exact token amount.
   * @param _ids           Array of ID of tokens bought.
   * @param _tokensBought Amount of Tokens bought.
   * @return Amount of currency needed to buy Tokens in _ids for amounts in _tokensBought
   */
  function getPrice_currencyToToken(
    uint256[] calldata _ids,
    uint256[] calldata _tokensBought)
    override external view returns (uint256[] memory)
  {
    uint256 nIds = _ids.length;
    uint256[] memory prices = new uint256[](nIds);

    for (uint256 i = 0; i < nIds; i++) {
      // Load Token id reserve
      uint256 tokenReserve = token.balanceOf(address(this), _ids[i]);

      if(currencyReserves[_ids[i]] > 0 && tokenReserve > 0) {
        prices[i] = getBuyPriceWithRoyalty(_tokensBought[i], currencyReserves[_ids[i]], tokenReserve);
      }
    }

    // Return prices
    return prices;
  }

  /**
   * @notice Return price for `Token _id => currency` trades with an exact token amount.
   * @param _ids        Array of IDs  token sold.
   * @param _tokensSold Array of amount of each Token sold.
   * @return Amount of currency that can be bought for Tokens in _ids for amounts in _tokensSold
   */
  function getPrice_tokenToCurrency(
    uint256[] calldata _ids,
    uint256[] calldata _tokensSold)
    override external view returns (uint256[] memory)
  {
    uint256 nIds = _ids.length;
    uint256[] memory prices = new uint256[](nIds);

    for (uint256 i = 0; i < nIds; i++) {
      // Load Token id reserve
      uint256 tokenReserve = token.balanceOf(address(this), _ids[i]);

      if(tokenReserve > 0 && currencyReserves[_ids[i]] > 0) {
        prices[i] = getSellPriceWithRoyalty(_tokensSold[i], tokenReserve, currencyReserves[_ids[i]]);
      }
    }

    // Return price
    return prices;
  }

  /**
   * @return Address of Token that is sold on this exchange.
   */
  function getTokenAddress() override external view returns (address) {
    return address(token);
  }

  /**
   * @return Address of the currency contract that is used as currency
   */
  function getCurrencyInfo() override external view returns (address) {
    return (address(currency));
  }

  /**
   * @notice Get total supply of liquidity tokens
   * @param _ids ID of the Tokens
   * @return The total supply of each liquidity token id provided in _ids
   */
  function getTotalSupply(uint256[] calldata _ids)
    override external view returns (uint256[] memory)
  {
    // Number of ids
    uint256 nIds = _ids.length;

    // Variables
    uint256[] memory batchTotalSupplies = new uint256[](nIds);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < nIds; i++) {
      batchTotalSupplies[i] = totalSupplies[_ids[i]];
    }

    return batchTotalSupplies;
  }

  /**
   * @return Global royalty fee %
   */
  function getGlobalRoyaltyFee() override external view returns (uint256) {
    return globalRoyaltyFee;
  }

  /**
   * @return Global royalty recipient if token not supporting ERC-2981
   */
  function getGlobalRoyaltyRecipient() override external view returns (address) {
    return globalRoyaltyRecipient;
  }

  /**
   * @return Get amount of currency in royalty an address can claim
   * @param _royaltyRecipient Address to check the claimable royalties
   */
  function getRoyalties(address _royaltyRecipient) override external view returns (uint256) {
    return royalties[_royaltyRecipient];
  }


  /***********************************|
  |         Utility Functions         |
  |__________________________________*/

  /**
   * @notice Divides two numbers and add 1 if there is a rounding error
   * @param a Numerator
   * @param b Denominator
   */
  function divRound(uint256 a, uint256 b) internal pure returns (uint256, bool) {
    return a % b == 0 ? (a/b, false) : ((a/b).add(1), true);
  }

  /**
   * @notice Return Token reserves for given Token ids
   * @dev Assumes that ids are sorted from lowest to highest with no duplicates.
   *      This assumption allows for checking the token reserves only once, otherwise
   *      token reserves need to be re-checked individually or would have to do more expensive
   *      duplication checks.
   * @param _tokenIds Array of IDs to query their Reserve balance.
   * @return Array of Token ids' reserves
   */
  function _getTokenReserves(
    uint256[] memory _tokenIds)
    internal view returns (uint256[] memory)
  {
    uint256 nTokens = _tokenIds.length;

    // Regular balance query if only 1 token, otherwise batch query
    if (nTokens == 1) {
      uint256[] memory tokenReserves = new uint256[](1);
      tokenReserves[0] = token.balanceOf(address(this), _tokenIds[0]);
      return tokenReserves;

    } else {
      // Lazy check preventing duplicates & build address array for query
      address[] memory thisAddressArray = new address[](nTokens);
      thisAddressArray[0] = address(this);

      for (uint256 i = 1; i < nTokens; i++) {
        require(_tokenIds[i-1] < _tokenIds[i], "NiftyswapExchange20#_getTokenReserves: UNSORTED_OR_DUPLICATE_TOKEN_IDS");
        thisAddressArray[i] = address(this);
      }
      return token.balanceOfBatch(thisAddressArray, _tokenIds);
    }
  }

  /**
   * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
   * @param  interfaceID The ERC-165 interface ID that is queried for support.s
   * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
   *      This function MUST NOT consume more thsan 5,000 gas.
   * @return Whether a given interface is supported
   */
  function supportsInterface(bytes4 interfaceID) public override pure returns (bool) {
    return interfaceID == type(IERC20).interfaceId ||
      interfaceID == type(IERC165).interfaceId ||
      interfaceID == type(IERC1155).interfaceId ||
      interfaceID == type(IERC1155TokenReceiver).interfaceId;
  }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import "@0xsequence/erc-1155/contracts/interfaces/IERC165.sol";

/** 
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
  /** 
   * @notice Called with the sale price to determine how much royalty
   *         is owed and to whom.
   * @param _tokenId - the NFT asset queried for royalty information
   * @param _salePrice - the sale price of the NFT asset specified by _tokenId
   * @return receiver - address of who should be sent the royalty payment
   * @return royaltyAmount - the royalty payment amount for _salePrice
   */
  function royaltyInfo(
      uint256 _tokenId,
      uint256 _salePrice
  ) external view returns (
      address receiver,
      uint256 royaltyAmount
  );
}