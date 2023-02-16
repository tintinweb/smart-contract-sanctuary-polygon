// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.4;

import 'openzeppelin-contracts/contracts/utils/Strings.sol';
import {ISVGRaffle, IRaffle} from '../interfaces/ISVGRaffle.sol';
import {ParseUtils} from '../libs/ParseUtils.sol';

contract SVGRaffle is ISVGRaffle {
  function _getInitial() internal pure returns (string memory) {
    return
      '<?xml version="1.0" encoding="utf-8"?><svg viewBox="0 0 631 1014" fill="none" xmlns="http://www.w3.org/2000/svg"><defs><clipPath id="clip0_322_158"><rect width="631" height="1014" rx="50" fill="white"/></clipPath><filter id="filter0_f_322_158" x="-71.8157" y="-39.7104" width="1113.87" height="1108.2" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="197" result="effect1_foregroundBlur_322_158"/></filter><linearGradient id="paint0_linear_322_158" x1="405.075" y1="404.757" x2="799.7" y2="636.567" gradientUnits="userSpaceOnUse"><stop stop-color="#7BA49A"/><stop offset="1" stop-color="#159777"/></linearGradient><filter id="filter1_f_322_158" x="-286.441" y="-258.346" width="692.91" height="687.817" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="100" result="effect1_foregroundBlur_322_158"/></filter><linearGradient id="paint1_linear_322_158" x1="-11.9329" y1="-12.9826" x2="342.783" y2="195.384" gradientUnits="userSpaceOnUse"><stop stop-color="#7BA49A"/><stop offset="1" stop-color="#159777"/></linearGradient><clipPath id="clip1_322_158"><rect width="631" height="1014" fill="white"/></clipPath></defs><g clip-path="url(#clip0_322_158)"><rect width="631" height="1014" rx="50" fill="#040914"/><g filter="url(#filter0_f_322_158)"><ellipse cx="485.117" cy="514.389" rx="162.935" ry="160.093" transform="rotate(177.742 485.117 514.389)" fill="url(#paint0_linear_322_158)"/></g><g filter="url(#filter1_f_322_158)"><ellipse cx="60.0141" cy="85.5623" rx="146.457" ry="143.903" transform="rotate(177.742 60.0141 85.5623)" fill="url(#paint1_linear_322_158)"/></g><g style="mix-blend-mode:overlay" opacity="0.85" clip-path="url(#clip1_322_158)"/><rect x="78" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="78" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="78" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="78" y="110" width="11.25" height="11.25" fill="white"/><rect x="89.25" y="110" width="11.25" height="11.25" fill="white"/><rect x="89.25" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="100.5" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="100.5" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="117.375" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="117.375" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="117.375" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="117.375" y="110" width="11.25" height="11.25" fill="white"/><rect x="128.625" y="110" width="11.25" height="11.25" fill="white"/><rect x="128.625" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="139.875" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="139.875" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="139.875" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="139.875" y="110" width="11.25" height="11.25" fill="white"/><rect x="156.75" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="156.75" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="156.75" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="156.75" y="110" width="11.25" height="11.25" fill="white"/><rect x="168" y="110" width="11.25" height="11.25" fill="white"/><rect x="168" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="179.25" y="110" width="11.25" height="11.25" fill="white"/><rect x="196.125" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="196.125" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="196.125" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="196.125" y="110" width="11.25" height="11.25" fill="white"/><rect x="207.375" y="110" width="11.25" height="11.25" fill="white"/><rect x="207.375" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="218.625" y="110" width="11.25" height="11.25" fill="white"/><rect width="11.25" height="11.25" transform="matrix(1 0 0 -1 235.5 121.25)" fill="white"/><rect width="11.25" height="11.25" transform="matrix(1 0 0 -1 235.5 132.5)" fill="white"/><rect width="11.25" height="11.25" transform="matrix(1 0 0 -1 235.5 143.75)" fill="white"/><rect width="11.25" height="11.25" transform="matrix(1 0 0 -1 235.5 155)" fill="white"/><rect width="11.25" height="11.25" transform="matrix(1 0 0 -1 246.75 155)" fill="white"/><rect width="11.25" height="11.25" transform="matrix(1 0 0 -1 258 155)" fill="white"/><rect x="274.875" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="274.875" y="110" width="11.25" height="11.25" fill="white"/><rect x="286.125" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="286.125" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="297.375" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="297.375" y="110" width="11.25" height="11.25" fill="white"/><path style="mix-blend-mode:overlay"/><g style="mix-blend-mode:overlay"><rect x="74" y="196" width="140" height="40" rx="15" fill="black" fill-opacity="0.6"/></g><g style="mix-blend-mode:overlay"><rect x="74" y="333" width="140" height="40" rx="15" fill="black" fill-opacity="0.6"/></g><g style="mix-blend-mode:overlay"><rect x="74" y="471" width="245" height="40" rx="15" fill="black" fill-opacity="0.6"/></g><g style="mix-blend-mode:overlay"><rect x="74" y="580" width="213" height="40" rx="15" fill="black" fill-opacity="0.6"/></g><g style="mix-blend-mode:overlay"><rect x="74" y="689" width="88" height="40" rx="15" fill="black" fill-opacity="0.6"/></g><rect x="41.5" y="41.5" width="548" height="931" rx="48.5" stroke="white" stroke-width="3"/><text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 20.2px; font-weight: 700; white-space: pre;" x="85.211" y="222.372">MAX PRICE</text><text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 20.2px; font-weight: 700; white-space: pre;" x="85.211" y="359.031">MIN PRICE</text><text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 20.2px; font-weight: 700; white-space: pre;" x="85.211" y="499.553">NUMBER OF TICKETS</text><text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 20.2px; font-weight: 700; white-space: pre;" x="85.211" y="606.873">EXPIRATION DATE</text><text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 20.2px; font-weight: 700; white-space: pre;" x="85.211" y="716.11">STATE</text>';
  }

  function _getText(
    string memory x,
    string memory y,
    string memory value
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 34px; white-space: pre;" x="',
          x,
          '" y="',
          y,
          '">',
          value,
          '</text>'
        )
      );
  }

  function _getBubble(IRaffle.RaffleStates _state)
    internal
    pure
    returns (string memory)
  {
    return
      IRaffle.RaffleStates.ACTIVE == _state
        ? ' <circle cx="205.017" cy="763.741" r="7" fill="#8FFF00"/>'
        : ' <circle cx="224.347" cy="764.03" r="7" style="fill: rgb(255, 0, 0);"/>';
  }

  function _getBody(
    uint256 _raffleId,
    uint256 _maxPrice,
    uint256 _minPrice,
    uint256 _numberTickets,
    uint256 _expiration,
    IRaffle.RaffleStates _state
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          _getText('82.438', '295.936', Strings.toString(_maxPrice)),
          _getText('82.438', '435.529', Strings.toString(_minPrice)),
          _getText('82.438', '558.104', string(abi.encode(_numberTickets))),
          _getText(
            '82.438',
            '671.562',
            ParseUtils._parseTimestamp(_expiration)
          ),
          _getText('82.438', '776.286', ParseUtils._parseState(_state)),
          _getBubble(_state),
          _getText('82.438', '1002.084', string(abi.encode(_raffleId)))
        )
      );
  }

  function getSvg(
    uint256 _raffleId,
    uint256 _maxPrice,
    uint256 _minPrice,
    uint256 _numberTickets,
    uint256 _expiration,
    IRaffle.RaffleStates _state
  ) external pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          _getInitial(),
          _getBody(
            _raffleId,
            _maxPrice,
            _minPrice,
            _numberTickets,
            _expiration,
            _state
          ),
          '</g></svg>'
        )
      );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = 1;

            // compute log10(value), and add it to length
            uint256 valueCopy = value;
            if (valueCopy >= 10**64) {
                valueCopy /= 10**64;
                length += 64;
            }
            if (valueCopy >= 10**32) {
                valueCopy /= 10**32;
                length += 32;
            }
            if (valueCopy >= 10**16) {
                valueCopy /= 10**16;
                length += 16;
            }
            if (valueCopy >= 10**8) {
                valueCopy /= 10**8;
                length += 8;
            }
            if (valueCopy >= 10**4) {
                valueCopy /= 10**4;
                length += 4;
            }
            if (valueCopy >= 10**2) {
                valueCopy /= 10**2;
                length += 2;
            }
            if (valueCopy >= 10**1) {
                length += 1;
            }
            // now, length is log10(value) + 1

            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = 1;

            // compute log256(value), and add it to length
            uint256 valueCopy = value;
            if (valueCopy >= 1 << 128) {
                valueCopy >>= 128;
                length += 16;
            }
            if (valueCopy >= 1 << 64) {
                valueCopy >>= 64;
                length += 8;
            }
            if (valueCopy >= 1 << 32) {
                valueCopy >>= 32;
                length += 4;
            }
            if (valueCopy >= 1 << 16) {
                valueCopy >>= 16;
                length += 2;
            }
            if (valueCopy >= 1 << 8) {
                valueCopy >>= 8;
                length += 1;
            }
            // now, length is log256(value) + 1

            return toHexString(value, length);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

pragma solidity ^0.8.8;

import {IRaffle} from './IRaffle.sol';

interface ISVGRaffle {
  function getSvg(
    uint256 raffleId,
    uint256 maxPrice,
    uint256 minPrice,
    uint256 numberTickets,
    uint256 expiration,
    IRaffle.RaffleStates state
  ) external view returns (string memory);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.4;

import {IRaffle} from '../interfaces/IRaffle.sol';
import 'solidity-datetime.git/contracts/DateTime.sol';

library ParseUtils {
  using DateTime for uint256;

  function _parseTimestamp(uint256 _timestamp)
    internal
    pure
    returns (string memory)
  {
    (
      uint256 year,
      uint256 month,
      uint256 day,
      uint256 hour,
      uint256 minute,
      uint256 second
    ) = _timestamp.timestampToDateTime();
    return
      string(
        abi.encodePacked(
          month,
          '/',
          day,
          '/',
          year,
          ' ',
          hour,
          ':',
          minute,
          ':',
          second
        )
      );
  }

  function _parseState(IRaffle.RaffleStates state)
    internal
    pure
    returns (string memory)
  {
    if (IRaffle.RaffleStates.ACTIVE == state) return 'ACTIVE';
    if (IRaffle.RaffleStates.RAFFLE_SUCCESSFUL == state) return 'SUCESS';
    if (IRaffle.RaffleStates.FINISHED == state) return 'FINISHED';
    return 'EXPIRED';
  }

  function _parseWeiToEth(uint256 _value) internal pure returns (uint256) {
    return _value / (10**18);
  }
}

pragma solidity ^0.8.8;

import {VRFCoordinatorV2Interface} from 'chainlink/interfaces/VRFCoordinatorV2Interface.sol';

interface IRaffle {
  struct RaffleConfiguration {
    uint256 raffleId;
    uint256 priceNFTId;
    address priceNFTAddress;
    uint256 expirationDate;
    uint256 fullSellPrice;
    uint256 discountedSellPrice;
    uint256 maxTickets;
    address ticketTracker;
    address winner;
    uint256 vrfRequestId;
  }

  enum RaffleStates {
    ACTIVE, // in process
    RAFFLE_SUCCESSFUL, // ready to execute random number to choose winner
    EXPIRED, // not reached soft cap and has expired
    FINISHED // winner has been chosen,
  }

  event RaffleCreated(
    uint256 indexed raffleId,
    address indexed creator,
    address indexed ticketTracker,
    uint256 priceNFTId,
    address priceNFTAddress,
    uint256 expirationDate,
    uint256 fullSellPrice,
    uint256 discountedSellPrice,
    uint256 maxTickets
  );

  event NewTicket(
    uint256 indexed raffleId,
    uint256 indexed amount,
    address buyer
  );

  event Winner(
    uint256 indexed raffleId,
    uint256 indexed winnerTicketId,
    address indexed winner
  );
  event RedeemNFT(uint256 indexed raffleId, RaffleStates state, address user);
  event AmountBack(
    uint256 indexed raffleId,
    uint256 indexed amount,
    address indexed buyer
  );

  event NFTBack(uint256 indexed raffleId, RaffleStates state, address user);

  function getRaffleConfiguration(uint256 raffleId)
    external
    view
    returns (RaffleConfiguration memory);

  function getVRFRequestIdForRaffleNftId(uint256 raffleId)
    external
    view
    returns (uint256);

  function cancelSubscription(address receivingWallet) external;

  function create(
    uint256 _priceNFTId,
    address _priceNFTAddress,
    uint256 _expirationDate,
    uint256 _sellPrice,
    uint256 _discountPrice,
    uint256 _maxTickets
  ) external returns (uint256);

  function getRaffleState(RaffleConfiguration memory raffleConfig)
    external
    view
    returns (RaffleStates);

  function getRaisedAmount(RaffleConfiguration memory raffleConfig)
    external
    view
    returns (uint256);

  function buyTickets(uint256 raffleNftId, uint256 ticketsAmount)
    external
    payable;

  function claimNFTBack(uint256 raffleNftId) external;

  function claimAmountTicketBack(uint256 raffleNftId, uint256[] memory tokensId)
    external;

  function redeemPriceNft(uint256 raffleNftId) external;

  function chooseWinner(uint256 raffleNftId) external;

  function emergencyStop(uint256 raffleId) external;

  function stopAllProtocol() external;

  function VRF_NUM_WORDS() external view returns (uint32);

  function VRF_CALLBACK_GAS_LIMIT() external view returns (uint32);

  function VRF_REQUEST_CONFIRMATIONS() external view returns (uint16);

  function tokenIdCounter() external view returns (uint256);

  function vrfKeyHash() external view returns (bytes32);

  function raffleFee() external view returns (uint256);

  function feeCollector() external view returns (address);

  function raffleUri() external view returns (string memory);

  function CHAINLINK_COORDINATOR()
    external
    view
    returns (VRFCoordinatorV2Interface);

  function clSubscriptionId() external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// DateTime Library v2.0
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day - 32075 + (1461 * (_year + 4800 + (_month - 14) / 12)) / 4
            + (367 * (_month - 2 - ((_month - 14) / 12) * 12)) / 12
            - (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) / 4 - OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            int256 __days = int256(_days);

            int256 L = __days + 68569 + OFFSET19700101;
            int256 N = (4 * L) / 146097;
            L = L - (146097 * N + 3) / 4;
            int256 _year = (4000 * (L + 1)) / 1461001;
            L = L - (1461 * _year) / 4 + 31;
            int256 _month = (80 * L) / 2447;
            int256 _day = L - (2447 * _month) / 80;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            year = uint256(_year);
            month = uint256(_month);
            day = uint256(_day);
        }
    }

    function timestampFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    )
        internal
        pure
        returns (uint256 timestamp)
    {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR
            + minute * SECONDS_PER_MINUTE + second;
    }

    function timestampToDate(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        }
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
            uint256 secs = timestamp % SECONDS_PER_DAY;
            hour = secs / SECONDS_PER_HOUR;
            secs = secs % SECONDS_PER_HOUR;
            minute = secs / SECONDS_PER_MINUTE;
            second = secs % SECONDS_PER_MINUTE;
        }
    }

    function isValidDate(uint256 year, uint256 month, uint256 day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
        internal
        pure
        returns (bool valid)
    {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
        (uint256 year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
        (uint256 year, uint256 month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (,, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, uint256 fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, uint256 toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}