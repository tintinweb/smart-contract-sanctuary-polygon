/*

    Copyright 2022 31Third B.V.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;
pragma experimental "ABIEncoderV2";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IExchangeAdapter.sol";
import "./ExchangeAdapterRegistry.sol";

/**
 * @title BatchTrade
 * @author 31Third
 *
 * Provides batch trading functionality
 */
contract BatchTrade is Ownable, Pausable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using ECDSA for bytes32;

  /*** ### Structs ### ***/

  // prettier-ignore
  struct Trade {
    string exchangeName;            // Name of the exchange the trade should be executed
    address from;                   // Address of the token to sell
    uint256 fromAmount;             // Amount of the token to sell
    address to;                     // Address of the token that will be received
    uint256 minToReceiveBeforeFees; // Minimal amount to receive
    bytes data;                     // Arbitrary call data which is sent to the exchange
    bytes signature;                // Signature to verify received trade data
  }

  // prettier-ignore
  struct BatchTradeConfig {
    bool checkFeelessWallets; // Determines if a check for feeless trading should be performed
    bool revertOnError;       // If true, batch trade reverts on error, otherwise execution just stops
  }

  /*** ### Events ### ***/

  event BatchTradeDeployed(
    address exchangeAdapterRegistry,
    address feeRecipient,
    uint16 feeBasisPoints,
    uint16 maxFeeBasisPoints,
    address tradeSigner
  );

  event FeeRecipientUpdated(
    address oldFeeRecipient,
    address newFeeRecipient
  );

  event FeeBasisPointsUpdated(
    uint16 oldFeeBasisPoints,
    uint16 newFeeBasisPoints
  );

  event MaxBasisPointsReduced(
    uint16 oldMaxBasisPoints,
    uint16 newMaxBasisPoints
  );

  event FeelessWalletAdded(
    address indexed addedWallet
  );

  event FeelessWalletRemoved(
    address indexed removedWallet
  );

  event TradeExecuted(
    address indexed trader,
    address indexed from,
    uint256 fromAmount,
    address indexed to,
    uint256 receivedAmount
  );

  event TradeFailedReason(
    address indexed trader,
    address indexed from,
    address indexed to,
    bytes reason
  );

  event FeesPayedOut(
    address indexed feeRecipient,
    address indexed feeToken,
    uint256 amount
  );

  /*** ### Custom Errors ### ***/

  error InvalidAddress(string paramName, address passedAddress);
  error MaxFeeExceeded(uint256 fee, uint256 maxFee);
  error RenounceOwnershipDisabled();
  error NewValueEqualsOld(string paramName);
  error ReducedMaxFeeTooSmall(uint256 maxFee, uint256 fee);
  error FeelessWalletAlreadySet();
  error FeelessWalletNotSet();
  error InvalidSignature(Trade trade);
  error FromEqualsTo(Trade trade);
  error ZeroAmountTrade(Trade trade);
  error MinToReceiveBeforeFeesZero(Trade trade);
  error TradeFailed(Trade trade, uint256 index);
  error ReturnEthFailed();
  error ReceiveEthFeeFailed();
  error NotEnoughClaimed(Trade trade, uint256 expected, uint256 received);
  error IncorrectSellAmount(Trade trade, uint256 expected, uint256 sold);
  error NotEnoughReceived(Trade trade, uint256 minExpected, uint256 received);
  error SoldDespiteTradeFailed(Trade trade);
  error ResetAllowanceFailed();

  /*** ### State Variables ### ***/

  address private constant ETH_ADDRESS =
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  ExchangeAdapterRegistry public immutable exchangeAdapterRegistry;
  address public feeRecipient;
  uint16 public feeBasisPoints;
  uint16 public maxFeeBasisPoints;
  mapping(address => bool) public feelessWallets;
  address public tradeSigner;

  /*** ### Modifiers ### ***/

  /*** ### Constructor ### ***/

  constructor(
    ExchangeAdapterRegistry _exchangeAdapterRegistry,
    address _feeRecipient,
    uint16 _feeBasisPoints,
    uint16 _maxFeeBasisPoints,
    address _tradeSigner
  ) {
    if (address(_exchangeAdapterRegistry) == address(0)) {
      revert InvalidAddress("_exchangeAdapterRegistry", address(_exchangeAdapterRegistry));
    }
    if (address(_feeRecipient) == address(0)) {
      revert InvalidAddress("_feeRecipient", _feeRecipient);
    }
    if (_feeBasisPoints > _maxFeeBasisPoints) {
      revert MaxFeeExceeded(_feeBasisPoints, _maxFeeBasisPoints);
    }
    if (address(_tradeSigner) == address(0)) {
      revert InvalidAddress("_tradeSigner", _tradeSigner);
    }

    exchangeAdapterRegistry = _exchangeAdapterRegistry;
    feeRecipient = _feeRecipient;
    feeBasisPoints = _feeBasisPoints;
    maxFeeBasisPoints = _maxFeeBasisPoints;
    tradeSigner = _tradeSigner;

    emit BatchTradeDeployed(
      address(_exchangeAdapterRegistry),
      _feeRecipient,
      _feeBasisPoints,
      _maxFeeBasisPoints,
      _tradeSigner
    );
  }

  /*** ### External Functions ### ***/

  receive() external payable {}

  /**
   * ONLY OWNER: Override renounceOwnership to disable it
   */
  function renounceOwnership() public override view onlyOwner {
    revert RenounceOwnershipDisabled();
  }

  /**
   * ONLY OWNER: Activates BatchTrade.
   */
  function activate() external onlyOwner {
    _unpause();
  }

  /**
   * ONLY OWNER: Deactivates BatchTrade.
   */
  function deactivate() external onlyOwner {
    _pause();
  }

  /**
   * ONLY OWNER: Updates fee recipient.
   *
   * @param _newFeeRecipient New fee recipient
   */
  function updateFeeRecipient(address _newFeeRecipient) external onlyOwner {
    if (address(_newFeeRecipient) == address(0)) {
      revert InvalidAddress("_newFeeRecipient", _newFeeRecipient);
    }
    if (_newFeeRecipient == feeRecipient) {
      revert NewValueEqualsOld("_newFeeRecipient");
    }

    address oldFeeRecipient = feeRecipient;
    feeRecipient = _newFeeRecipient;
    emit FeeRecipientUpdated(oldFeeRecipient, _newFeeRecipient);
  }

  /**
   * ONLY OWNER: Updates basis points (Must be less than or equal max).
   *
   * @param _newFeeBasisPoints New basis points
   */
  function updateBasisPoints(uint16 _newFeeBasisPoints) external onlyOwner {
    if (_newFeeBasisPoints > maxFeeBasisPoints) {
      revert MaxFeeExceeded(_newFeeBasisPoints, maxFeeBasisPoints);
    }
    if (_newFeeBasisPoints == feeBasisPoints) {
      revert NewValueEqualsOld("_newFeeBasisPoints");
    }

    uint16 oldFeeBasisPoints = feeBasisPoints;
    feeBasisPoints = _newFeeBasisPoints;
    emit FeeBasisPointsUpdated(oldFeeBasisPoints, _newFeeBasisPoints);
  }

  /**
   * ONLY OWNER: Reduces max basis points (Must be less than max and bigger or equal current fee basis points).
   *
   * @param _newMaxFeeBasisPoints New max basis points
   */
  function reduceMaxBasisPoints(uint16 _newMaxFeeBasisPoints) external onlyOwner {
    if (_newMaxFeeBasisPoints >= maxFeeBasisPoints) {
      revert MaxFeeExceeded(_newMaxFeeBasisPoints, maxFeeBasisPoints);
    }
    if (_newMaxFeeBasisPoints < feeBasisPoints) {
      revert ReducedMaxFeeTooSmall(_newMaxFeeBasisPoints, feeBasisPoints);
    }

    uint16 oldMaxFeeBasisPoints = maxFeeBasisPoints;
    maxFeeBasisPoints = _newMaxFeeBasisPoints;
    emit MaxBasisPointsReduced(oldMaxFeeBasisPoints, _newMaxFeeBasisPoints);
  }

  /**
   * ONLY OWNER: Adds wallet that is eligible for feeless batch trading.
   *
   * @param _feelessWallet Wallet address to add
   */
  function addFeelessWallet(address _feelessWallet) public onlyOwner {
    if (address(_feelessWallet) == address(0)) {
      revert InvalidAddress("_feelessWallet", _feelessWallet);
    }
    if (feelessWallets[_feelessWallet]) {
      revert FeelessWalletAlreadySet();
    }

    feelessWallets[_feelessWallet] = true;
    emit FeelessWalletAdded(_feelessWallet);
  }

  /**
   * ONLY OWNER: Adds wallets that are eligible for feeless batch trading.
   *
   * @param _feelessWallets Wallet addresses to add
   */
  function addFeelessWallets(address[] calldata _feelessWallets) external onlyOwner {
    for (uint256 i = 0; i < _feelessWallets.length; i++) {
      addFeelessWallet(_feelessWallets[i]);
    }
  }

  /**
   * ONLY OWNER: Removes wallet that is eligible for feeless batch trading.
   *
   * @param _feelessWallet Wallet address to remove
   */
  function removeFeelessWallet(address _feelessWallet) public onlyOwner {
    if (address(_feelessWallet) == address(0)) {
      revert InvalidAddress("_feelessWallet", _feelessWallet);
    }
    if (!feelessWallets[_feelessWallet]) {
      revert FeelessWalletNotSet();
    }

    feelessWallets[_feelessWallet] = false;
    emit FeelessWalletRemoved(_feelessWallet);
  }

  /**
   * ONLY OWNER: Removes wallets that are eligible for feeless batch trading.
   *
   * @param _feelessWallets Wallet addresses to remove
   */
  function removeFeelessWallets(address[] calldata _feelessWallets) external onlyOwner {
    for (uint256 i = 0; i < _feelessWallets.length; i++) {
      removeFeelessWallet(_feelessWallets[i]);
    }
  }

  /**
   * ONLY OWNER: Updates trade signer.
   * (No event is emitted on purpose)
   *
   * @param _newTradeSigner New trade signer
   */
  function updateTradeSigner(address _newTradeSigner) external onlyOwner {
    if (address(_newTradeSigner) == address(0)) {
      revert InvalidAddress("_newTradeSigner", _newTradeSigner);
    }
    if (_newTradeSigner == tradeSigner) {
      revert NewValueEqualsOld("_newTradeSigner");
    }

    tradeSigner = _newTradeSigner;
  }

  /**
   * WHEN NOT PAUSED, NON REENTRANT: Executes a batch of trades on supported DEXs.
   * If trades fail events will be emitted. Based on the passed batchTradeConfig either the whole batch trade will
   * be reverted or the execution stops at the first failing trade.
   *
   * @param _trades           Struct with information for trades
   * @param _batchTradeConfig Struct that holds batch trade configs
   */
  function batchTrade(
    Trade[] calldata _trades,
    BatchTradeConfig memory _batchTradeConfig
  ) external payable whenNotPaused nonReentrant {
    uint256 value = msg.value;

    for (uint256 i = 0; i < _trades.length; i++) {
      (bool success, uint256 returnValue) = _executeTrade(
        _trades[i],
        value,
        _batchTradeConfig.checkFeelessWallets
      );
      if (success) {
        if (_trades[i].from == ETH_ADDRESS) {
          value -= _trades[i].fromAmount;
        }
        if (_trades[i].to == ETH_ADDRESS) {
          value += returnValue;
        }
      } else {
        // also revert if first trade
        if (_batchTradeConfig.revertOnError || i == 0) {
          revert TradeFailed(_trades[i], i);
        }
        _returnClaimedOnError(_trades[i]);
        break; // break loop and return senders eth
      }
    }

    if (value > 0) {
      bool success = false;
      (success, ) = msg.sender.call{value: value}("");
      if (!success) {
        revert ReturnEthFailed();
      }
    }
  }

  /**
   * Sends accrued fees to fee recipient.
   * (Also supports inflationary and yield generating tokens.)
   *
   * @param _feeTokensToReceive Addresses of the tokens that should be sent to the fee recipient
   */
  function receiveFees(address[] calldata _feeTokensToReceive) external {
    for (uint256 i = 0; i < _feeTokensToReceive.length; i++) {
      uint256 feeAmount = _getBalance(_feeTokensToReceive[i]);

      // if no fees of this specific token are collected jump over this address and proceed with next
      if (feeAmount > 0) {
        if (_feeTokensToReceive[i] != ETH_ADDRESS) {
          IERC20(_feeTokensToReceive[i]).safeTransfer(
            feeRecipient,
            feeAmount
          );
        } else {
          bool success = false;
          // arbitrary-send-eth can be disabled here since feeRecipient can just be set by the owner of the contract
          // slither-disable-next-line arbitrary-send-eth
          (success, ) = feeRecipient.call{value: feeAmount}("");
          if (!success) {
            revert ReceiveEthFeeFailed();
          }
        }
        emit FeesPayedOut(feeRecipient, _feeTokensToReceive[i], feeAmount);
      }
    }
  }

  /*** ### Private Functions ### ***/

  /**
   * Executes a single trade. This process is splitted up in the following steps:
   *  * Get exchange adapter
   *  * Validate and verify trade data
   *  * Get send token from sender
   *  * Invoke trade against DEX
   *  * Claim fees
   *  * Return received tokens to sender
   */
  function _executeTrade(
    Trade memory _trade,
    uint256 _value,
    bool _checkFeelessWallets
  ) private returns (bool success, uint256 returnAmount) {
    IExchangeAdapter exchangeAdapter = IExchangeAdapter(
      _getAndValidateAdapter(_trade.exchangeName)
    );

    _preTradeCheck(_trade, exchangeAdapter.getSpender());

    // prettier-ignore
    (
      address targetExchange,
      uint256 callValue,
      bytes memory data
    ) = _getTradeData(
      exchangeAdapter,
      _trade,
      _trade.from == ETH_ADDRESS ? _value : 0
    );

    _claimAndApproveFromToken(exchangeAdapter, _trade);
    (bool callExchangeSuccess, uint256 receivedAmount) = _callExchange(
      targetExchange,
      callValue,
      data,
      _trade
    );

    success = callExchangeSuccess;
    if (success) {
      uint256 feeAmount = _handleFees(
        receivedAmount,
        _checkFeelessWallets
      );
      returnAmount = receivedAmount - feeAmount;
      _returnToken(_trade, returnAmount);
    } else {
      _resetAllowance(exchangeAdapter, _trade);

      returnAmount = 0;
    }
  }

  /**
   * Validate pre trade data.
   * Check if trade data was signed by a valid account
   * Check if from address != to address
   * Check if fromAmount > 0
   * Check if minToReceiveBeforeFees > 0
   */
  function _preTradeCheck(Trade memory _trade, address spender) private view {
    bytes32 hash = keccak256(abi.encodePacked(spender, _trade.from, _trade.fromAmount, _trade.to, _trade.minToReceiveBeforeFees, _trade.data));
    address recoveredAddress = hash.toEthSignedMessageHash().recover(_trade.signature);
    if (recoveredAddress != tradeSigner) {
      revert InvalidSignature(_trade);
    }

    if (_trade.from == _trade.to) {
      revert FromEqualsTo(_trade);
    }

    if (_trade.fromAmount == 0) {
      revert ZeroAmountTrade(_trade);
    }

    if (_trade.minToReceiveBeforeFees == 0) {
      revert MinToReceiveBeforeFeesZero(_trade);
    }
  }

  /**
   * Gets the adapter with the passed in name. Validates that the address is not empty
   */
  function _getAndValidateAdapter(
    string memory _adapterName
  ) private view returns (address) {
    address adapter = exchangeAdapterRegistry.getAdapter(_adapterName);

    if (address(adapter) == address(0)) {
      revert InvalidAddress("adapter", adapter);
    }
    return adapter;
  }

  /**
   * Get trade data (exchange address, trade value, calldata).
   */
  function _getTradeData(
    IExchangeAdapter _exchangeAdapter,
    Trade memory _trade,
    uint256 _value
  ) private view returns (address, uint256, bytes memory) {
    return
    _exchangeAdapter.getTradeCalldata(
      _trade.from,
      _trade.fromAmount,
      _trade.to,
      _trade.minToReceiveBeforeFees,
      address(this), // taker has to be this, otherwise DEXs like UniswapV3 might send funds directly back to taker
      _value,
      _trade.data
    );
  }

  /**
   * Get from tokens from sender and approve it to exchange/spender.
   */
  function _claimAndApproveFromToken(
    IExchangeAdapter _exchangeAdapter,
    Trade memory _trade
  ) private {
    if (_trade.from != ETH_ADDRESS) {
      uint256 fromBalanceBefore = _getBalance(_trade.from);
      IERC20(_trade.from).safeTransferFrom(
        msg.sender,
        address(this),
        _trade.fromAmount
      );
      uint256 fromBalanceAfter = _getBalance(_trade.from);
      if (fromBalanceAfter < fromBalanceBefore + _trade.fromAmount) {
        revert NotEnoughClaimed(_trade, _trade.fromAmount, fromBalanceAfter - fromBalanceBefore);
      }

      IERC20(_trade.from).safeIncreaseAllowance(
        _exchangeAdapter.getSpender(),
        _trade.fromAmount
      );
    }
  }

  /**
   * Call arbitrary function on target exchange with calldata and value
   */
  function _callExchange(
    address _target,
    uint256 _value,
    bytes memory _data,
    Trade memory _trade
  ) private returns (bool success, uint256 receivedAmount) {
    uint256 fromBalanceBeforeTrade = _getBalance(_trade.from);
    uint256 toBalanceBeforeTrade = _getBalance(_trade.to);

    (bool targetSuccess, bytes memory result) = _target.call{value: _value}(
      _data
    );

    success = targetSuccess;
    if (success) {
      uint256 fromBalanceAfterTrade = _getBalance(_trade.from);
      if (fromBalanceAfterTrade != fromBalanceBeforeTrade - _trade.fromAmount) {
        revert IncorrectSellAmount(_trade, _trade.fromAmount, fromBalanceBeforeTrade - fromBalanceAfterTrade);
      }

      uint256 toBalanceAfterTrade = _getBalance(_trade.to);
      if (toBalanceAfterTrade < toBalanceBeforeTrade + _trade.minToReceiveBeforeFees) {
        revert NotEnoughReceived(_trade, _trade.minToReceiveBeforeFees, toBalanceAfterTrade - toBalanceBeforeTrade);
      }

      receivedAmount = toBalanceAfterTrade - toBalanceBeforeTrade;

      emit TradeExecuted(
        msg.sender,
        _trade.from,
        _trade.fromAmount,
        _trade.to,
        receivedAmount
      );
    } else {
      uint256 fromBalanceAfterTrade = _getBalance(_trade.from);
      if (fromBalanceAfterTrade != fromBalanceBeforeTrade) {
        revert SoldDespiteTradeFailed(_trade);
      }

      receivedAmount = 0;
      emit TradeFailedReason(msg.sender, _trade.from, _trade.to, result);
    }
  }

  function _getBalance(address token) private view returns (uint256) {
    if (token != ETH_ADDRESS) {
      return IERC20(token).balanceOf(address(this));
    } else {
      return address(this).balance;
    }
  }

  /**
   * Calculate fees based on basis points.
   * If _checkFeelessWallets is true and the sender wallet is eligible for feeless trading 0 is returned.
   */
  function _handleFees(
    uint256 _receivedAmount,
    bool _checkFeelessWallets // saves about 3.000 gas units per calculation
  ) private view returns (uint256 feeAmount) {
    if (_checkFeelessWallets && feelessWallets[msg.sender]) {
      return 0;
    }

    feeAmount = (_receivedAmount * feeBasisPoints) / 10000;
  }

  /**
   * Return received token to sender.
   */
  function _returnToken(
    Trade memory _trade,
    uint256 _amount
  ) private {
    if (_trade.to != ETH_ADDRESS && _amount > 0) {
      IERC20(_trade.to).safeTransfer(msg.sender, _amount);
    }
  }

  /**
   * Reset allowance of spender to 0.
   */
  function _resetAllowance(
    IExchangeAdapter _exchangeAdapter,
    Trade memory _trade
  ) private {
    if (_trade.from != ETH_ADDRESS) {
      bool success = IERC20(_trade.from).approve(_exchangeAdapter.getSpender(), 0);
      if (!success) {
        revert ResetAllowanceFailed();
      }
    }
  }

  /**
   * If a trade failed this function is called to return the from tokens to the sender.
   */
  function _returnClaimedOnError(Trade memory _trade) private {
    if (_trade.from != ETH_ADDRESS) {
      IERC20(_trade.from).safeTransfer(
        msg.sender,
        _trade.fromAmount
      );
    }
  }
}

/*

    Copyright 2022 31Third B.V.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ExchangeAdapterRegistry is Ownable {
  /*** ### Events ### ***/

  event AdapterAdded(address indexed adapter, string adapterName);
  event AdapterRemoved(address indexed adapter, string adapterName);
  event AdapterEdited(address indexed newAdapter, string adapterName);

  /*** ### Custom Errors ### ***/

  error RenounceOwnershipDisabled();
  error NameEmptyString();
  error NameAlreadyExists(string name);
  error InvalidAddress(string paramName, address passedAddress);
  error EmptyArray(string name);
  error ArrayLengthMismatch(string name1, string name2);
  error NoAdapterWithName(string name);

  /*** ### State Variables ### ***/

  // Mapping of exchange adapter identifier => adapter address
  mapping(bytes32 => address) private adapters;

  /*** ### External Functions ### ***/

  /**
   * ONLY OWNER: Override renounceOwnership to disable it
   */
  function renounceOwnership() public override view onlyOwner {
    revert RenounceOwnershipDisabled();
  }

  /**
   * ONLY OWNER: Add a new adapter to the registry
   *
   * @param  _name    Human readable string identifying the adapter
   * @param  _adapter Address of the adapter contract to add
   */
  function addAdapter(string memory _name, address _adapter) public onlyOwner {
    if (bytes(_name).length == 0) {
      revert NameEmptyString();
    }

    bytes32 hashedName = _getNameHash(_name);
    if (adapters[hashedName] != address(0)) {
      revert NameAlreadyExists(_name);
    }

    if (_adapter == address(0)) {
      revert InvalidAddress("_adapter", _adapter);
    }

    adapters[hashedName] = _adapter;

    emit AdapterAdded(_adapter, _name);
  }

  /**
   * ONLY OWNER: Batch add new adapters. Reverts if exists on any module and name
   *
   * @param  _names    Array of human readable strings identifying the adapter
   * @param  _adapters Array of addresses of the adapter contracts to add
   */
  function batchAddAdapter(
    string[] memory _names,
    address[] memory _adapters
  ) external onlyOwner {
    // Storing modules count to local variable to save on invocation
    uint256 namesCount = _names.length;

    if (namesCount == 0) {
      revert EmptyArray("_names");
    }
    if (namesCount != _adapters.length) {
      revert ArrayLengthMismatch("_names", "_adapters");
    }

    for (uint256 i = 0; i < namesCount; i++) {
      // Add adapters to the specified module. Will revert if module and name combination exists
      addAdapter(_names[i], _adapters[i]);
    }
  }

  /**
   * ONLY OWNER: Edit an existing adapter on the registry
   *
   * @param  _name    Human readable string identifying the adapter
   * @param  _adapter Address of the adapter contract to edit
   */
  function editAdapter(string memory _name, address _adapter) public onlyOwner {
    bytes32 hashedName = _getNameHash(_name);

    if (adapters[hashedName] == address(0)) {
      revert NoAdapterWithName(_name);
    }
    if (_adapter == address(0)) {
      revert InvalidAddress("_adapter", _adapter);
    }

    adapters[hashedName] = _adapter;

    emit AdapterEdited(_adapter, _name);
  }

  /**
   * ONLY OWNER: Batch edit adapters for modules. Reverts if module and
   * adapter name don't map to an adapter address
   *
   * @param  _names    Array of human readable strings identifying the adapter
   * @param  _adapters Array of addresses of the adapter contracts to add
   */
  function batchEditAdapter(
    string[] memory _names,
    address[] memory _adapters
  ) external onlyOwner {
    // Storing name count to local variable to save on invocation
    uint256 namesCount = _names.length;

    if (namesCount == 0) {
      revert EmptyArray("_names");
    }
    if (namesCount != _adapters.length) {
      revert ArrayLengthMismatch("_names", "_adapters");
    }

    for (uint256 i = 0; i < namesCount; i++) {
      // Edits adapters to the specified module. Will revert if module and name combination does not exist
      editAdapter(_names[i], _adapters[i]);
    }
  }

  /**
   * ONLY OWNER: Remove an existing adapter on the registry
   *
   * @param  _name Human readable string identifying the adapter
   */
  function removeAdapter(string memory _name) external onlyOwner {
    bytes32 hashedName = _getNameHash(_name);
    if (adapters[hashedName] == address(0)) {
      revert NoAdapterWithName(_name);
    }

    address oldAdapter = adapters[hashedName];
    delete adapters[hashedName];

    emit AdapterRemoved(oldAdapter, _name);
  }

  /*** ### External Getter Functions ### ***/

  /**
   * Get adapter adapter address associated with passed human readable name
   *
   * @param  _name Human readable adapter name
   *
   * @return       Address of adapter
   */
  function getAdapter(string memory _name) external view returns (address) {
    return adapters[_getNameHash(_name)];
  }

  /**
   * Get adapter adapter address associated with passed hashed name
   *
   * @param  _nameHash Hash of human readable adapter name
   *
   * @return           Address of adapter
   */
  function getAdapterWithHash(
    bytes32 _nameHash
  ) external view returns (address) {
    return adapters[_nameHash];
  }

  /**
   * Check if adapter name is valid
   *
   * @param  _name Human readable string identifying the adapter
   *
   * @return       Boolean indicating if valid
   */
  function isValidAdapter(string memory _name) external view returns (bool) {
    return adapters[_getNameHash(_name)] != address(0);
  }

  /*** ### Internal Functions ### ***/

  /**
   * Hashes the string and returns a bytes32 value
   */
  function _getNameHash(string memory _name) internal pure returns (bytes32) {
    return keccak256(bytes(_name));
  }
}

/*

    Copyright 2022 31Third B.V.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface IExchangeAdapter {
  /**
   * Returns the address to which from tokens for trading have to be approved.
   */
  function getSpender() external view returns (address);

  /**
   * Returns calldata handler, send value, calldata.
   * Verifies calldata against passed trade infos.
   *
   * @param  _from         Address of the token to sell
   * @param  _fromAmount   Amount of the token to sell
   * @param  _to           Address of the token that will be received
   * @param  _minToReceive Minimal amount to receive
   * @param  _taker        Taker of the received value
   * @param  _value        ETH value for this trade
   * @param  _data         Arbitrary call data which is sent to the exchange
   *
   * @return address       Calldata handler contract address
   * @return uint256       Call value
   * @return bytes         Trade calldata
   */
  function getTradeCalldata(
    address _from,
    uint256 _fromAmount,
    address _to,
    uint256 _minToReceive,
    address _taker,
    uint256 _value,
    bytes memory _data
  ) external view returns (address, uint256, bytes memory);
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}