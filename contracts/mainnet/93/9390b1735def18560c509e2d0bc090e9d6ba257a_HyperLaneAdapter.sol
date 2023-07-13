// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';
import {IMessageRecipient} from 'hyperlane-monorepo/interfaces/IMessageRecipient.sol';
import {TypeCasts} from 'hyperlane-monorepo/libs/TypeCasts.sol';

import {BaseAdapter, IBaseAdapter} from '../BaseAdapter.sol';
import {IHyperLaneAdapter, IMailbox, IInterchainGasPaymaster} from './IHyperLaneAdapter.sol';
import {Errors} from '../../libs/Errors.sol';

/**
 * @title HyperLaneAdapter
 * @author BGD Labs
 * @notice HyperLane bridge adapter. Used to send and receive messages cross chain
 * @dev it uses the eth balance of CrossChainController contract to pay for message bridging as the method to bridge
        is called via delegate call
 */
contract HyperLaneAdapter is BaseAdapter, IHyperLaneAdapter, IMessageRecipient {
  /// @inheritdoc IHyperLaneAdapter
  IMailbox public immutable HL_MAIL_BOX;

  /// @inheritdoc IHyperLaneAdapter
  IInterchainGasPaymaster public immutable IGP;

  /// @notice modifier to check that caller is hyper lane mailBox
  modifier onlyMailbox() {
    require(msg.sender == address(HL_MAIL_BOX), Errors.CALLER_NOT_HL_MAILBOX);
    _;
  }

  /**
   * @param crossChainController address of the cross chain controller that will use this bridge adapter
   * @param mailBox HyperLane router contract address to send / receive cross chain messages
   * @param igp HyperLane contract to get the gas estimation to pay for sending messages
   * @param trustedRemotes list of remote configurations to set as trusted
   */
  constructor(
    address crossChainController,
    address mailBox,
    address igp,
    TrustedRemotesConfig[] memory trustedRemotes
  ) BaseAdapter(crossChainController, trustedRemotes) {
    HL_MAIL_BOX = IMailbox(mailBox);
    IGP = IInterchainGasPaymaster(igp);
  }

  /// @inheritdoc IBaseAdapter
  function forwardMessage(
    address receiver,
    uint256 destinationGasLimit,
    uint256 destinationChainId,
    bytes calldata message
  ) external returns (address, uint256) {
    uint32 nativeChainId = SafeCast.toUint32(infraToNativeChainId(destinationChainId));
    require(nativeChainId != uint32(0), Errors.DESTINATION_CHAIN_ID_NOT_SUPPORTED);
    require(receiver != address(0), Errors.RECEIVER_NOT_SET);

    bytes32 messageId = HL_MAIL_BOX.dispatch(
      nativeChainId,
      TypeCasts.addressToBytes32(receiver),
      message
    );

    // Get the required payment from the IGP.
    uint256 quotedPayment = IGP.quoteGasPayment(nativeChainId, destinationGasLimit);

    require(quotedPayment <= address(this).balance, Errors.NOT_ENOUGH_VALUE_TO_PAY_BRIDGE_FEES);

    // Pay from the contract's balance
    IGP.payForGas{value: quotedPayment}(
      messageId, // The ID of the message that was just dispatched
      nativeChainId, // The destination domain of the message
      destinationGasLimit,
      address(this) // refunds go to msg.sender, who paid the msg.value
    );

    return (address(HL_MAIL_BOX), uint256(messageId));
  }

  /// @inheritdoc IMessageRecipient
  function handle(
    uint32 _origin,
    bytes32 _sender,
    bytes calldata _messageBody
  ) external onlyMailbox {
    address srcAddress = TypeCasts.bytes32ToAddress(_sender);

    uint256 originChainId = nativeToInfraChainId(_origin);

    require(
      _trustedRemotes[originChainId] == srcAddress && srcAddress != address(0),
      Errors.REMOTE_NOT_TRUSTED
    );
    _registerReceivedMessage(_messageBody, originChainId);
  }

  /// @inheritdoc IBaseAdapter
  function nativeToInfraChainId(uint256 nativeChainId) public pure override returns (uint256) {
    return nativeChainId;
  }

  /// @inheritdoc IBaseAdapter
  function infraToNativeChainId(uint256 infraChainId) public pure override returns (uint256) {
    return infraChainId;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IMessageRecipient {
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

library TypeCasts {
    // alignment preserving cast
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    // alignment preserving cast
    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IBaseAdapter} from './IBaseAdapter.sol';
import {IBaseCrossChainController} from '../interfaces/IBaseCrossChainController.sol';
import {Errors} from '../libs/Errors.sol';

/**
 * @title BaseAdapter
 * @author BGD Labs
 * @notice base contract implementing the method to route a bridged message to the CrossChainController contract.
 * @dev All bridge adapters must implement this contract
 */
abstract contract BaseAdapter is IBaseAdapter {
  IBaseCrossChainController public immutable CROSS_CHAIN_CONTROLLER;

  // @dev this is the original address of the contract. Required to identify and prevent delegate calls.
  address private immutable _selfAddress;

  // (standard chain id -> origin forwarder address) saves for every chain the address that can forward messages to this adapter
  mapping(uint256 => address) internal _trustedRemotes;

  /**
   * @param crossChainController address of the CrossChainController the bridged messages will be routed to
   */
  constructor(address crossChainController, TrustedRemotesConfig[] memory originConfigs) {
    require(crossChainController != address(0), Errors.INVALID_BASE_ADAPTER_CROSS_CHAIN_CONTROLLER);
    CROSS_CHAIN_CONTROLLER = IBaseCrossChainController(crossChainController);

    _selfAddress = address(this);

    for (uint256 i = 0; i < originConfigs.length; i++) {
      TrustedRemotesConfig memory originConfig = originConfigs[i];
      require(originConfig.originForwarder != address(0), Errors.INVALID_TRUSTED_REMOTE);
      _trustedRemotes[originConfig.originChainId] = originConfig.originForwarder;
      emit SetTrustedRemote(originConfig.originChainId, originConfig.originForwarder);
    }
  }

  /// @inheritdoc IBaseAdapter
  function nativeToInfraChainId(uint256 nativeChainId) public view virtual returns (uint256);

  /// @inheritdoc IBaseAdapter
  function infraToNativeChainId(uint256 infraChainId) public view virtual returns (uint256);

  function setupPayments() external virtual {}

  /// @inheritdoc IBaseAdapter
  function getTrustedRemoteByChainId(uint256 chainId) external view returns (address) {
    return _trustedRemotes[chainId];
  }

  /**
   * @notice calls CrossChainController to register the bridged payload
   * @param _payload bytes containing the bridged message
   * @param originChainId id of the chain where the message originated
   */
  function _registerReceivedMessage(bytes calldata _payload, uint256 originChainId) internal {
    // this method should be always called via call
    require(address(this) == _selfAddress, Errors.DELEGATE_CALL_FORBIDDEN);
    CROSS_CHAIN_CONTROLLER.receiveCrossChainMessage(_payload, originChainId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IMailbox} from 'hyperlane-monorepo/interfaces/IMailbox.sol';
import {IInterchainGasPaymaster} from 'hyperlane-monorepo/interfaces/IInterchainGasPaymaster.sol';

/**
 * @title IHyperLaneAdapter
 * @author BGD Labs
 * @notice interface containing the events, objects and method definitions used in the HyperLane bridge adapter
 */
interface IHyperLaneAdapter {
  /**
   * @notice method to get the current Mail Box address
   * @return the address of the HyperLane Mail Box
   */
  function HL_MAIL_BOX() external view returns (IMailbox);

  /**
   * @notice method to get the current IGP address
   * @return the address of the HyperLane IGP
   */
  function IGP() external view returns (IInterchainGasPaymaster);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author BGD Labs
 * @notice Defines the error messages emitted by the different contracts of the Aave CrossChain Infrastructure
 */
library Errors {
  string public constant ETH_TRANSFER_FAILED = '1'; // failed to transfer eth to destination
  string public constant CALLER_IS_NOT_APPROVED_SENDER = '2'; // caller must be an approved message sender
  string public constant ENVELOPE_NOT_PREVIOUSLY_REGISTERED = '3'; // envelope can only be retried if it has been previously registered
  string public constant CURRENT_OR_DESTINATION_CHAIN_ADAPTER_NOT_SET = '4'; // can not enable bridge adapter if the current or destination chain adapter is 0 address
  string public constant CALLER_NOT_APPROVED_BRIDGE = '5'; // caller must be an approved bridge
  string public constant INVALID_VALIDITY_TIMESTAMP = '6'; // new validity timestamp is not correct (< last validity or in the future
  string public constant CALLER_NOT_CCIP_ROUTER = '7'; // caller must be bridge provider contract
  string public constant CCIP_ROUTER_CANT_BE_ADDRESS_0 = '8'; // CCIP bridge adapters needs a CCIP Router
  string public constant RECEIVER_NOT_SET = '9'; // receiver address on destination chain can not be 0
  string public constant DESTINATION_CHAIN_ID_NOT_SUPPORTED = '10'; // destination chain id must be supported by bridge provider
  string public constant NOT_ENOUGH_VALUE_TO_PAY_BRIDGE_FEES = '11'; // cross chain controller does not have enough funds to forward the message
  string public constant INCORRECT_ORIGIN_CHAIN_ID = '12'; // message origination chain id is not from a supported chain
  string public constant REMOTE_NOT_TRUSTED = '13'; // remote address has not been registered as a trusted origin
  string public constant CALLER_NOT_HL_MAILBOX = '14'; // caller must be the HyperLane Mailbox contract
  string public constant NO_BRIDGE_ADAPTERS_FOR_SPECIFIED_CHAIN = '15'; // no bridge adapters are configured for the specified destination chain
  string public constant ONLY_ONE_EMERGENCY_UPDATE_PER_CHAIN = '16'; // only one emergency update is allowed at the time
  string public constant INVALID_REQUIRED_CONFIRMATIONS = '17'; // required confirmations must be less or equal than allowed adapters or bigger or equal than 1
  string public constant BRIDGE_ADAPTER_NOT_SET_FOR_ANY_CHAIN = '18'; // a bridge adapter must support at least one chain
  string public constant DESTINATION_CHAIN_NOT_SAME_AS_CURRENT_CHAIN = '19'; // destination chain must be the same chain as the current chain where contract is deployed
  string public constant INVALID_BRIDGE_ADAPTER = '20'; // a bridge adapter address can not be the 0 address
  string public constant TRANSACTION_NOT_PREVIOUSLY_FORWARDED = '21'; // to retry sending a transaction, it needs to have been previously sent
  string public constant TRANSACTION_RETRY_FAILED = '22'; // transaction retry has failed (no bridge adapters where able to send)
  string public constant BRIDGE_ADAPTERS_SHOULD_BE_UNIQUE = '23'; // can not use the same bridge adapter twice
  string public constant ENVELOPE_NOT_CONFIRMED_OR_DELIVERED = '24'; // to deliver an envelope, this should have been previously confirmed
  string public constant ENVELOPE_DELIVERY_FAILED = '25'; // envelope has not been delivered
  string public constant INVALID_BASE_ADAPTER_CROSS_CHAIN_CONTROLLER = '27'; // crossChainController address can not be 0
  string public constant DELEGATE_CALL_FORBIDDEN = '28'; // calling this function during delegatecall is forbidden
  string public constant CALLER_NOT_LZ_ENDPOINT = '29'; // caller must be the LayerZero endpoint contract
  string public constant INVALID_LZ_ENDPOINT = '30'; // LayerZero endpoint can't be 0
  string public constant INVALID_TRUSTED_REMOTE = '31'; // trusted remote endpoint can't be 0
  string public constant INVALID_EMERGENCY_ORACLE = '32'; // emergency oracle can not be 0 because if not, system could not be rescued on emergency
  string public constant SYSTEM_NEEDS_AT_LEAST_ONE_CONFIRMATION = '33';
  string public constant INVALID_CONFIRMATIONS_FOR_ALLOWED_ADAPTERS = '34';
  string public constant NOT_IN_EMERGENCY = '35'; // execution can only happen when in an emergency
  string public constant LINK_TOKEN_CANT_BE_ADDRESS_0 = '36'; // link token address should be set
  string public constant CCIP_MESSAGE_IS_INVALID = '37'; // ccip message is not an accepted message
  string public constant ADAPTER_PAYMENT_SETUP_FAILED = '38'; // adapter payment setup failed
  string public constant CHAIN_ID_MISMATCH = '39'; // the message delivered to/from wrong network
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IBaseAdapter
 * @author BGD Labs
 * @notice interface containing the event and method used in all bridge adapters
 */
interface IBaseAdapter {
  /**
   * @notice emitted when a trusted remote is set
   * @param originChainId id of the chain where the trusted remote is from
   * @param originForwarder address of the contract that will send the messages
   */
  event SetTrustedRemote(uint256 originChainId, address originForwarder);

  /**
   * @notice pair of origin address and origin chain
   * @param originForwarder address of the contract that will send the messages
   * @param originChainId id of the chain where the trusted remote is from
   */
  struct TrustedRemotesConfig {
    address originForwarder;
    uint256 originChainId;
  }

  /**
   * @notice method that will bridge the payload to the chain specified
   * @param receiver address of the receiver contract on destination chain
   * @param gasLimit amount of the gas limit in wei to use for bridging on receiver side. Each adapter will manage this
            as needed
   * @param destinationChainId id of the destination chain in the bridge notation
   * @param message to send to the specified chain
   * @return the third-party bridge entrypoint, the third-party bridge message id
   */
  function forwardMessage(
    address receiver,
    uint256 gasLimit,
    uint256 destinationChainId,
    bytes calldata message
  ) external returns (address, uint256);

  /**
   * @notice method used to setup payment, ie grant approvals over tokens used to pay for tx fees
   */
  function setupPayments() external;

  /**
   * @notice method to get the trusted remote address from a specified chain id
   * @param chainId id of the chain from where to get the trusted remote
   * @return address of the trusted remote
   */
  function getTrustedRemoteByChainId(uint256 chainId) external view returns (address);

  /**
   * @notice method to get infrastructure chain id from bridge native chain id
   * @param bridgeChainId bridge native chain id
   */
  function nativeToInfraChainId(uint256 bridgeChainId) external returns (uint256);

  /**
   * @notice method to get bridge native chain id from native bridge chain id
   * @param infraChainId infrastructure chain id
   */
  function infraToNativeChainId(uint256 infraChainId) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ICrossChainForwarder.sol';
import './ICrossChainReceiver.sol';
import {IRescuable} from 'solidity-utils/contracts/utils/interfaces/IRescuable.sol';

/**
 * @title IBaseCrossChainController
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the CrossChainController contract
 */
interface IBaseCrossChainController is IRescuable, ICrossChainForwarder, ICrossChainReceiver {

}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "./IInterchainSecurityModule.sol";

interface IMailbox {
    // ============ Events ============
    /**
     * @notice Emitted when a new message is dispatched via Hyperlane
     * @param sender The address that dispatched the message
     * @param destination The destination domain of the message
     * @param recipient The message recipient address on `destination`
     * @param message Raw bytes of message
     */
    event Dispatch(
        address indexed sender,
        uint32 indexed destination,
        bytes32 indexed recipient,
        bytes message
    );

    /**
     * @notice Emitted when a new message is dispatched via Hyperlane
     * @param messageId The unique message identifier
     */
    event DispatchId(bytes32 indexed messageId);

    /**
     * @notice Emitted when a Hyperlane message is processed
     * @param messageId The unique message identifier
     */
    event ProcessId(bytes32 indexed messageId);

    /**
     * @notice Emitted when a Hyperlane message is delivered
     * @param origin The origin domain of the message
     * @param sender The message sender address on `origin`
     * @param recipient The address that handled the message
     */
    event Process(
        uint32 indexed origin,
        bytes32 indexed sender,
        address indexed recipient
    );

    function localDomain() external view returns (uint32);

    function delivered(bytes32 messageId) external view returns (bool);

    function defaultIsm() external view returns (IInterchainSecurityModule);

    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external returns (bytes32);

    function process(bytes calldata _metadata, bytes calldata _message)
        external;

    function count() external view returns (uint32);

    function root() external view returns (bytes32);

    function latestCheckpoint() external view returns (bytes32, uint32);

    function recipientIsm(address _recipient)
        external
        view
        returns (IInterchainSecurityModule);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/**
 * @title IInterchainGasPaymaster
 * @notice Manages payments on a source chain to cover gas costs of relaying
 * messages to destination chains.
 */
interface IInterchainGasPaymaster {
    /**
     * @notice Emitted when a payment is made for a message's gas costs.
     * @param messageId The ID of the message to pay for.
     * @param gasAmount The amount of destination gas paid for.
     * @param payment The amount of native tokens paid.
     */
    event GasPayment(
        bytes32 indexed messageId,
        uint256 gasAmount,
        uint256 payment
    );

    function payForGas(
        bytes32 _messageId,
        uint32 _destinationDomain,
        uint256 _gasAmount,
        address _refundAddress
    ) external payable;

    function quoteGasPayment(uint32 _destinationDomain, uint256 _gasAmount)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {Transaction, Envelope} from '../libs/EncodingUtils.sol';

/**
 * @title ICrossChainForwarder
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the CrossChainForwarder contract
 */
interface ICrossChainForwarder {
  /**
   * @notice object storing the connected pair of bridge adapters, on current and destination chain
   * @param destinationBridgeAdapter address of the bridge adapter on the destination chain
   * @param currentChainBridgeAdapter address of the bridge adapter deployed on current network
   */
  struct ChainIdBridgeConfig {
    address destinationBridgeAdapter;
    address currentChainBridgeAdapter;
  }

  /**
   * @notice object with the necessary information to remove bridge adapters
   * @param bridgeAdapter address of the bridge adapter to remove
   * @param chainIds array of chain ids where the bridge adapter connects
   */
  struct BridgeAdapterToDisable {
    address bridgeAdapter;
    uint256[] chainIds;
  }

  /**
   * @notice object storing the pair bridgeAdapter (current deployed chain) destination chain bridge adapter configuration
   * @param currentChainBridgeAdapter address of the bridge adapter deployed on current chain
   * @param destinationBridgeAdapter address of the bridge adapter on the destination chain
   * @param destinationChainId id of the destination chain using our own nomenclature
   */
  struct ForwarderBridgeAdapterConfigInput {
    address currentChainBridgeAdapter;
    address destinationBridgeAdapter;
    uint256 destinationChainId;
  }

  /**
   * @notice emitted when a transaction is successfully forwarded through a bridge adapter
   * @param envelopeId internal id of the envelope
   * @param envelope the Envelope type data
   */
  event EnvelopeRegistered(bytes32 indexed envelopeId, Envelope envelope);

  /**
   * @notice emitted when a transaction forwarding is attempted through a bridge adapter
   * @param transactionId id of the forwarded transaction
   * @param envelopeId internal id of the envelope
   * @param encodedTransaction object intended to be bridged
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter that failed (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param adapterSuccessful adapter was able to forward the message
   * @param returnData bytes with error information
   */
  event TransactionForwardingAttempted(
    bytes32 transactionId,
    bytes32 indexed envelopeId,
    bytes encodedTransaction,
    uint256 destinationChainId,
    address indexed bridgeAdapter,
    address destinationBridgeAdapter,
    bool indexed adapterSuccessful,
    bytes returnData
  );

  /**
   * @notice emitted when a bridge adapter has been added to the allowed list
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter added (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param allowed boolean indicating if the bridge adapter is allowed or disallowed
   */
  event BridgeAdapterUpdated(
    uint256 indexed destinationChainId,
    address indexed bridgeAdapter,
    address destinationBridgeAdapter,
    bool indexed allowed
  );

  /**
   * @notice emitted when a sender has been updated
   * @param sender address of the updated sender
   * @param isApproved boolean that indicates if the sender has been approved or removed
   */
  event SenderUpdated(address indexed sender, bool indexed isApproved);

  /**
   * @notice method to get the current valid envelope nonce
   * @return the current valid envelope nonce
   */
  function getCurrentEnvelopeNonce() external view returns (uint256);

  /**
   * @notice method to get the current valid transaction nonce
   * @return the current valid transaction nonce
   */
  function getCurrentTransactionNonce() external view returns (uint256);

  /**
   * @notice method to check if a envelope has been previously forwarded.
   * @param envelope the Envelope type data
   * @return boolean indicating if the envelope has been registered
   */
  function isEnvelopeRegistered(Envelope memory envelope) external view returns (bool);

  /**
   * @notice method to check if a envelope has been previously forwarded.
   * @param envelopeId the hashed id of the envelope
   * @return boolean indicating if the envelope has been registered
   */
  function isEnvelopeRegistered(bytes32 envelopeId) external view returns (bool);

  /**
   * @notice method to get if a transaction has been forwarded
   * @param transaction the Transaction type data
   * @return flag indicating if a transaction has been forwarded
   */
  function isTransactionForwarded(Transaction memory transaction) external view returns (bool);

  /**
   * @notice method to get if a transaction has been forwarded
   * @param transactionId hashed id of the transaction
   * @return flag indicating if a transaction has been forwarded
   */
  function isTransactionForwarded(bytes32 transactionId) external view returns (bool);

  /**
   * @notice method called to initiate message forwarding to other networks.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param destination address where the message is intended for
   * @param gasLimit gas cost on receiving side of the message
   * @param message bytes that need to be bridged
   * @return internal id of the envelope and transaction
   */
  function forwardMessage(
    uint256 destinationChainId,
    address destination,
    uint256 gasLimit,
    bytes memory message
  ) external returns (bytes32, bytes32);

  /**
   * @notice method called to re forward a previously sent envelope.
   * @param envelope the Envelope type data
   * @param gasLimit gas cost on receiving side of the message
   * @return the transaction id that has the retried envelope
   * @dev This method will send an existing Envelope using a new Transaction.
   * @dev This method should be used when the intention is to send the Envelope as if it was a new message. This way on
          the Receiver side it will start from 0 to count for the required confirmations. (usual use case would be for
          when an envelope has been invalidated on Receiver side, and needs to be retried as a new message)
   */
  function retryEnvelope(Envelope memory envelope, uint256 gasLimit) external returns (bytes32);

  /**
   * @notice method to retry forwarding an already forwarded transaction
   * @param encodedTransaction the encoded Transaction data
   * @param gasLimit limit of gas to spend on forwarding per bridge
   * @param bridgeAdaptersToRetry list of bridge adapters to be used for the transaction forwarding retry
   * @dev This method will send an existing Transaction with its Envelope to the specified adapters.
   * @dev Should be used when some of the bridges on the initial forwarding did not work (out of gas),
          and we want the Transaction with Envelope to still account for the required confirmations on the Receiver side
   */
  function retryTransaction(
    bytes memory encodedTransaction,
    uint256 gasLimit,
    address[] memory bridgeAdaptersToRetry
  ) external;

  /**
   * @notice method to enable bridge adapters
   * @param bridgeAdapters array of new bridge adapter configurations
   */
  function enableBridgeAdapters(ForwarderBridgeAdapterConfigInput[] memory bridgeAdapters) external;

  /**
   * @notice method to disable bridge adapters
   * @param bridgeAdapters array of bridge adapter addresses to disable
   */
  function disableBridgeAdapters(BridgeAdapterToDisable[] memory bridgeAdapters) external;

  /**
   * @notice method to remove sender addresses
   * @param senders list of addresses to remove
   */
  function removeSenders(address[] memory senders) external;

  /**
   * @notice method to approve new sender addresses
   * @param senders list of addresses to approve
   */
  function approveSenders(address[] memory senders) external;

  /**
   * @notice method to get all the bridge adapters of a chain
   * @param chainId id of the chain we want to get the adateprs from
   * @return an array of chain configurations where the bridge adapter can communicate
   */
  function getBridgeAdaptersByChain(
    uint256 chainId
  ) external view returns (ChainIdBridgeConfig[] memory);

  /**
   * @notice method to get if a sender is approved
   * @param sender address that we want to check if approved
   * @return boolean indicating if the address has been approved as sender
   */
  function isSenderApproved(address sender) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {EnumerableSet} from 'openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol';
import {Transaction, Envelope} from '../libs/EncodingUtils.sol';

/**
 * @title ICrossChainReceiver
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the CrossChainReceiver contract
 */
interface ICrossChainReceiver {
  /**
   * @notice object with information to set new required confirmations
   * @param chainId id of the origin chain
   * @param requiredConfirmations required confirmations to set a message as confirmed
   */
  struct ConfirmationInput {
    uint256 chainId;
    uint8 requiredConfirmations;
  }

  /**
   * @notice object with information to set new validity timestamp
   * @param chainId id of the origin chain
   * @param validityTimestamp new timestamp in seconds to set as validity point
   */
  struct ValidityTimestampInput {
    uint256 chainId;
    uint120 validityTimestamp;
  }

  /**
   * @notice object with necessary information to allow new bridge adapters
   * @param chainIds array of ids of the chains the adapter will receive messages from
   * @param bridgeAdapter address of the bridge adapter to add
   */
  struct ReceiverBridgeAdapterConfigInput {
    address bridgeAdapter;
    uint256[] chainIds;
  }

  /**
   * @notice object containing the receiver configuration
   * @param requiredConfirmation number of bridges that are needed to make a bridged message valid from origin chain
   * @param validityTimestamp all messages originated but not finally confirmed before this timestamp per origin chain, are invalid
   */
  struct ReceiverConfiguration {
    uint8 requiredConfirmation;
    uint120 validityTimestamp;
  }

  /**
   * @notice object with full information of the receiver configuration for a chain
   * @param configuration object containing the specifications of the receiver for a chain
   * @param allowedBridgeAdapters stores if a bridge adapter is allowed for a chain
   */
  struct ReceiverConfigurationFull {
    ReceiverConfiguration configuration;
    EnumerableSet.AddressSet allowedBridgeAdapters;
  }

  /**
   * @notice object that stores the internal information of the transaction
   * @param confirmations number of times that this transaction has been bridged
   * @param firstBridgedAt timestamp in seconds indicating the first time a transaction was received
   */
  struct TransactionStateWithoutAdapters {
    uint8 confirmations;
    uint120 firstBridgedAt;
  }
  /**
   * @notice object that stores the internal information of the transaction with bridge adapters state
   * @param confirmations number of times that this transactions has been bridged
   * @param firstBridgedAt timestamp in seconds indicating the first time a transaction was received
   * @param bridgedByAdapter list of bridge adapters that have bridged the message
   */
  struct TransactionState {
    uint8 confirmations;
    uint120 firstBridgedAt;
    mapping(address => bool) bridgedByAdapter;
  }

  /**
   * @notice object with the current state of an envelope
   * @param confirmed boolean indicating if the bridged message has been confirmed by the infrastructure
   * @param delivered boolean indicating if the bridged message has been delivered to the destination
   */
  enum EnvelopeState {
    None,
    Confirmed,
    Delivered
  }

  /**
   * @notice emitted when a transaction has been received successfully
   * @param transactionId id of the transaction
   * @param envelopeId id of the envelope
   * @param originChainId id of the chain where the envelope originated
   * @param transaction the Transaction type data
   * @param bridgeAdapter address of the bridge adapter who received the message (deployed on current network)
   * @param confirmations number of current confirmations for this message
   */
  event TransactionReceived(
    bytes32 transactionId,
    bytes32 indexed envelopeId,
    uint256 indexed originChainId,
    Transaction transaction,
    address indexed bridgeAdapter,
    uint8 confirmations
  );

  /**
   * @notice emitted when an envelope has been delivery attempted
   * @param envelopeId id of the envelope
   * @param envelope the Envelope type data
   * @param isDelivered flag indicating if the message has been delivered successfully
   */
  event EnvelopeDeliveryAttempted(bytes32 envelopeId, Envelope envelope, bool isDelivered);

  /**
   * @notice emitted when a bridge adapter gets updated (allowed or disallowed)
   * @param bridgeAdapter address of the updated bridge adapter
   * @param allowed boolean indicating if the bridge adapter has been allowed or disallowed
   * @param chainId id of the chain updated
   */
  event ReceiverBridgeAdaptersUpdated(
    address indexed bridgeAdapter,
    bool indexed allowed,
    uint256 indexed chainId
  );

  /**
   * @notice emitted when number of confirmations needed to validate a message changes
   * @param newConfirmations number of new confirmations needed for a message to be valid
   * @param chainId id of the chain updated
   */
  event ConfirmationsUpdated(uint8 newConfirmations, uint256 indexed chainId);

  /**
   * @notice emitted when a new timestamp for invalidations gets set
   * @param invalidTimestamp timestamp to invalidate previous messages
   * @param chainId id of the chain updated
   */
  event NewInvalidation(uint256 invalidTimestamp, uint256 indexed chainId);

  /**
   * @notice method to get the current allowed bridge adapters for a chain
   * @param chainId id of the chain to get the allowed bridge adapter list
   * @return the list of allowed bridge adapters
   */
  function getAllowedBridgeAdaptersByChain(
    uint256 chainId
  ) external view returns (address[] memory);

  /**
   * @notice method to get the current supported chains (at least one allowed bridge adapter)
   * @return list of supported chains
   */
  function getSupportedChains() external view returns (uint256[] memory);

  /**
   * @notice method to get the current configuration of a chain
   * @param chainId id of the chain to get the configuration from
   * @return the specified chain configuration object
   */
  function getConfigurationByChain(
    uint256 chainId
  ) external view returns (ReceiverConfiguration memory);

  /**
   * @notice method to get if a bridge adapter is allowed
   * @param bridgeAdapter address of the bridge adapter to check
   * @param chainId id of the chain to check
   * @return boolean indicating if bridge adapter is allowed
   */
  function isReceiverBridgeAdapterAllowed(
    address bridgeAdapter,
    uint256 chainId
  ) external view returns (bool);

  /**
   * @notice  method to get the current state of a transaction
   * @param transactionId the id of transaction
   * @return number of confirmations of internal message identified by the transactionId and the updated timestamp
   */
  function getTransactionState(
    bytes32 transactionId
  ) external view returns (TransactionStateWithoutAdapters memory);

  /**
   * @notice  method to get the internal transaction information
   * @param transaction Transaction type data
   * @return number of confirmations of internal message identified by internalId and the updated timestamp
   */
  function getTransactionState(
    Transaction memory transaction
  ) external view returns (TransactionStateWithoutAdapters memory);

  /**
   * @notice method to get the internal state of an envelope
   * @param envelope the Envelope type data
   * @return the envelope current state, containing if it has been confirmed and delivered
   */
  function getEnvelopeState(Envelope memory envelope) external view returns (EnvelopeState);

  /**
   * @notice method to get the internal state of an envelope
   * @param envelopeId id of the envelope
   * @return the envelope current state, containing if it has been confirmed and delivered
   */
  function getEnvelopeState(bytes32 envelopeId) external view returns (EnvelopeState);

  /**
   * @notice method to get if transaction has been received by bridge adapter
   * @param transactionId id of the transaction as stored internally
   * @param bridgeAdapter address of the bridge adapter to check if it has bridged the message
   * @return boolean indicating if the message has been received
   */
  function isTransactionReceivedByAdapter(
    bytes32 transactionId,
    address bridgeAdapter
  ) external view returns (bool);

  /**
   * @notice method to set a new timestamp from where the messages will be valid.
   * @param newValidityTimestamp array of objects containing the chain and timestamp where all the previous unconfirmed
            messages must be invalidated.
   */
  function updateMessagesValidityTimestamp(
    ValidityTimestampInput[] memory newValidityTimestamp
  ) external;

  /**
   * @notice method to update the number of confirmations necessary for the messages to be accepted as valid
   * @param newConfirmations array of objects with the chainId and the new number of needed confirmations
   */
  function updateConfirmations(ConfirmationInput[] memory newConfirmations) external;

  /**
   * @notice method that receives a bridged transaction and tries to deliver the contents to destination if possible
   * @param encodedTransaction bytes containing the bridged information
   * @param originChainId id of the chain where the transaction originated
   */
  function receiveCrossChainMessage(
    bytes memory encodedTransaction,
    uint256 originChainId
  ) external;

  /**
   * @notice method to deliver an envelope to its destination
   * @param envelope the Envelope typed data
   * @dev to deliver an envelope, it needs to have been previously confirmed and not delivered
   */
  function deliverEnvelope(Envelope memory envelope) external;

  /**
   * @notice method to add bridge adapters to the allowed list
   * @param bridgeAdaptersInput array of objects with the new bridge adapters and supported chains
   */
  function allowReceiverBridgeAdapters(
    ReceiverBridgeAdapterConfigInput[] memory bridgeAdaptersInput
  ) external;

  /**
   * @notice method to remove bridge adapters from the allowed list
   * @param bridgeAdaptersInput array of objects with the bridge adapters and supported which should not be supported anymore
   */
  function disallowReceiverBridgeAdapters(
    ReceiverBridgeAdapterConfigInput[] memory bridgeAdaptersInput
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/**
 * @title IRescuable
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the Rescuable contract
 */
interface IRescuable {
  /**
   * @notice emitted when erc20 tokens get rescued
   * @param caller address that triggers the rescue
   * @param token address of the rescued token
   * @param to address that will receive the rescued tokens
   * @param amount quantity of tokens rescued
   */
  event ERC20Rescued(
    address indexed caller,
    address indexed token,
    address indexed to,
    uint256 amount
  );

  /**
   * @notice emitted when native tokens get rescued
   * @param caller address that triggers the rescue
   * @param to address that will receive the rescued tokens
   * @param amount quantity of tokens rescued
   */
  event NativeTokensRescued(address indexed caller, address indexed to, uint256 amount);

  /**
   * @notice method called to rescue tokens sent erroneously to the contract. Only callable by owner
   * @param erc20Token address of the token to rescue
   * @param to address to send the tokens
   * @param amount of tokens to rescue
   */
  function emergencyTokenTransfer(address erc20Token, address to, uint256 amount) external;

  /**
   * @notice method called to rescue ether sent erroneously to the contract. Only callable by owner
   * @param to address to send the eth
   * @param amount of eth to rescue
   */
  function emergencyEtherTransfer(address to, uint256 amount) external;

  /**
   * @notice method that defines the address that is allowed to rescue tokens
   * @return the allowed address
   */
  function whoCanRescue() external view returns (address);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IInterchainSecurityModule {
    enum Types {
        NULL, // used with relayer carrying no metadata
        ROUTING,
        AGGREGATION,
        LEGACY_MULTISIG,
        MERKLE_ROOT_MULTISIG,
        MESSAGE_ID_MULTISIG,
        OPTIMISM
    }

    /**
     * @notice Returns an enum that represents the type of security model
     * encoded by this ISM.
     * @dev Relayers infer how to fetch and format metadata.
     */
    function moduleType() external view returns (uint8);

    /**
     * @notice Defines a security model responsible for verifying interchain
     * messages based on the provided metadata.
     * @param _metadata Off-chain metadata provided by a relayer, specific to
     * the security model encoded by the module (e.g. validator signatures)
     * @param _message Hyperlane encoded interchain message
     * @return True if the message was verified
     */
    function verify(bytes calldata _metadata, bytes calldata _message)
        external
        returns (bool);
}

interface ISpecifiesInterchainSecurityModule {
    function interchainSecurityModule()
        external
        view
        returns (IInterchainSecurityModule);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

using EnvelopeUtils for Envelope global;
using TransactionUtils for Transaction global;

/**
 * @notice Object with the necessary information to define a unique envelope
 * @param nonce sequential (unique) numeric indicator of the Envelope creation
 * @param origin address that originated the bridging of a message
 * @param destination address where the message needs to be sent
 * @param originChainId id of the chain where the message originated
 * @param destinationChainId id of the chain where the message needs to be bridged
 * @param message bytes that needs to be bridged
 */
struct Envelope {
  uint256 nonce;
  address origin;
  address destination;
  uint256 originChainId;
  uint256 destinationChainId;
  bytes message;
}

/**
 * @notice Object containing the information of an envelope for internal usage
 * @param data bytes of the encoded envelope
 * @param id hash of the encoded envelope
 */
struct EncodedEnvelope {
  bytes data;
  bytes32 id;
}

/**
 * @title EnvelopeUtils library
 * @author BGD Labs
 * @notice Defines utility functions for Envelopes
 */
library EnvelopeUtils {
  /**
   * @notice method that encodes an Envelope and generates its id
   * @param envelope object with the routing information necessary to send a message to a destination chain
   * @return object containing the encoded envelope and the envelope id
   */
  function encode(Envelope memory envelope) internal pure returns (EncodedEnvelope memory) {
    EncodedEnvelope memory encodedEnvelope;
    encodedEnvelope.data = abi.encode(envelope);
    encodedEnvelope.id = getId(encodedEnvelope.data);
    return encodedEnvelope;
  }

  /**
   * @notice method to decode and encoded envelope to its raw parameters
   * @param envelope bytes with the encoded envelope data
   * @return object with the decoded envelope information
   */
  function decode(bytes memory envelope) internal pure returns (Envelope memory) {
    return abi.decode(envelope, (Envelope));
  }

  /**
   * @notice method to get an envelope's id
   * @param envelope object with the routing information necessary to send a message to a destination chain
   * @return hash id of the envelope
   */
  function getId(Envelope memory envelope) internal pure returns (bytes32) {
    EncodedEnvelope memory encodedEnvelope = encode(envelope);
    return encodedEnvelope.id;
  }

  /**
   * @notice method to get an envelope's id
   * @param envelope bytes with the encoded envelope data
   * @return hash id of the envelope
   */
  function getId(bytes memory envelope) internal pure returns (bytes32) {
    return keccak256(envelope);
  }
}

/**
 * @notice Object with the necessary information to send an envelope to a bridge
 * @param nonce sequential (unique) numeric indicator of the Transaction creation
 * @param encodedEnvelope bytes of an encoded envelope object
 */
struct Transaction {
  uint256 nonce;
  bytes encodedEnvelope;
}

/**
 * @notice Object containing the information of a transaction for internal usage
 * @param data bytes of the encoded transaction
 * @param id hash of the encoded transaction
 */
struct EncodedTransaction {
  bytes data;
  bytes32 id;
}

/**
 * @title TransactionUtils library
 * @author BGD Labs
 * @notice Defines utility functions for Transactions
 */
library TransactionUtils {
  /**
   * @notice method that encodes a Transaction and generates its id
   * @param transaction object with the information necessary to send an envelope to a bridge
   * @return object containing the encoded transaction and the transaction id
   */
  function encode(
    Transaction memory transaction
  ) internal pure returns (EncodedTransaction memory) {
    EncodedTransaction memory encodedTransaction;
    encodedTransaction.data = abi.encode(transaction);
    encodedTransaction.id = getId(encodedTransaction.data);
    return encodedTransaction;
  }

  /**
   * @notice method that encodes a Transaction and generates its id
   * @param transaction encoded transaction object
   * @return object containing the encoded transaction and the transaction id
   */
  function decode(bytes memory transaction) internal pure returns (Transaction memory) {
    return abi.decode(transaction, (Transaction));
  }

  /**
   * @notice method to get an transaction id
   * @param transaction object with the information necessary to send an envelope to a bridge
   * @return hash id of the transaction
   */
  function getId(Transaction memory transaction) internal pure returns (bytes32) {
    EncodedTransaction memory encodedTransaction = encode(transaction);
    return encodedTransaction.id;
  }

  /**
   * @notice method to get an transaction id
   * @param transaction encoded transaction object
   * @return hash id of the transaction
   */
  function getId(bytes memory transaction) internal pure returns (bytes32) {
    return keccak256(transaction);
  }

  /**
   * @notice method to get the envelope information from the transaction object
   * @param transaction object with the information necessary to send an envelope to a bridge
   * @return object with decoded information of the envelope in the transaction
   */
  function getEnvelope(Transaction memory transaction) internal pure returns (Envelope memory) {
    return EnvelopeUtils.decode(transaction.encodedEnvelope);
  }

  /**
   * @notice method to get the envelope id from the transaction object
   * @param transaction object with the information necessary to send an envelope to a bridge
   * @return hash id of the envelope on a transaction
   */
  function getEnvelopeId(Transaction memory transaction) internal pure returns (bytes32) {
    return EnvelopeUtils.getId(transaction.encodedEnvelope);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}