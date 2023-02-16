// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.4;

import 'openzeppelin-contracts/contracts/utils/Strings.sol';
import {ISVGRaffle} from '../interfaces/ISVGRaffle.sol';

contract SVGRaffle is ISVGRaffle {
  function _getInitial() internal pure returns (string memory) {
    return
      '<?xml version="1.0" encoding="utf-8"?><svg viewBox="0 0 631 1014" fill="none" xmlns="http://www.w3.org/2000/svg"><defs><clipPath id="clip0_322_158"><rect width="631" height="1014" rx="50" fill="white"/></clipPath><filter id="filter0_f_322_158" x="-71.8157" y="-39.7104" width="1113.87" height="1108.2" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="197" result="effect1_foregroundBlur_322_158"/></filter><linearGradient id="paint0_linear_322_158" x1="405.075" y1="404.757" x2="799.7" y2="636.567" gradientUnits="userSpaceOnUse"><stop stop-color="#7BA49A"/><stop offset="1" stop-color="#159777"/></linearGradient><filter id="filter1_f_322_158" x="-286.441" y="-258.346" width="692.91" height="687.817" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="100" result="effect1_foregroundBlur_322_158"/></filter><linearGradient id="paint1_linear_322_158" x1="-11.9329" y1="-12.9826" x2="342.783" y2="195.384" gradientUnits="userSpaceOnUse"><stop stop-color="#7BA49A"/><stop offset="1" stop-color="#159777"/></linearGradient><clipPath id="clip1_322_158"><rect width="631" height="1014" fill="white"/></clipPath></defs><g clip-path="url(#clip0_322_158)"><rect width="631" height="1014" rx="50" fill="#040914"/><g filter="url(#filter0_f_322_158)"><ellipse cx="485.117" cy="514.389" rx="162.935" ry="160.093" transform="rotate(177.742 485.117 514.389)" fill="url(#paint0_linear_322_158)"/></g><g filter="url(#filter1_f_322_158)"><ellipse cx="60.0141" cy="85.5623" rx="146.457" ry="143.903" transform="rotate(177.742 60.0141 85.5623)" fill="url(#paint1_linear_322_158)"/></g><g style="mix-blend-mode:overlay" opacity="0.85" clip-path="url(#clip1_322_158)"/><rect x="78" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="78" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="78" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="78" y="110" width="11.25" height="11.25" fill="white"/><rect x="89.25" y="110" width="11.25" height="11.25" fill="white"/><rect x="89.25" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="100.5" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="100.5" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="117.375" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="117.375" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="117.375" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="117.375" y="110" width="11.25" height="11.25" fill="white"/><rect x="128.625" y="110" width="11.25" height="11.25" fill="white"/><rect x="128.625" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="139.875" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="139.875" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="139.875" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="139.875" y="110" width="11.25" height="11.25" fill="white"/><rect x="156.75" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="156.75" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="156.75" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="156.75" y="110" width="11.25" height="11.25" fill="white"/><rect x="168" y="110" width="11.25" height="11.25" fill="white"/><rect x="168" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="179.25" y="110" width="11.25" height="11.25" fill="white"/><rect x="196.125" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="196.125" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="196.125" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="196.125" y="110" width="11.25" height="11.25" fill="white"/><rect x="207.375" y="110" width="11.25" height="11.25" fill="white"/><rect x="207.375" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="218.625" y="110" width="11.25" height="11.25" fill="white"/><rect width="11.25" height="11.25" transform="matrix(1 0 0 -1 235.5 121.25)" fill="white"/><rect width="11.25" height="11.25" transform="matrix(1 0 0 -1 235.5 132.5)" fill="white"/><rect width="11.25" height="11.25" transform="matrix(1 0 0 -1 235.5 143.75)" fill="white"/><rect width="11.25" height="11.25" transform="matrix(1 0 0 -1 235.5 155)" fill="white"/><rect width="11.25" height="11.25" transform="matrix(1 0 0 -1 246.75 155)" fill="white"/><rect width="11.25" height="11.25" transform="matrix(1 0 0 -1 258 155)" fill="white"/><rect x="274.875" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="274.875" y="110" width="11.25" height="11.25" fill="white"/><rect x="286.125" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="286.125" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="297.375" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="297.375" y="110" width="11.25" height="11.25" fill="white"/><path style="mix-blend-mode:overlay"/><g style="mix-blend-mode:overlay"><rect x="74" y="196" width="140" height="40" rx="15" fill="black" fill-opacity="0.6"/></g><g style="mix-blend-mode:overlay"><rect x="74" y="333" width="140" height="40" rx="15" fill="black" fill-opacity="0.6"/></g><g style="mix-blend-mode:overlay"><rect x="74" y="471" width="245" height="40" rx="15" fill="black" fill-opacity="0.6"/></g><g style="mix-blend-mode:overlay"><rect x="74" y="580" width="213" height="40" rx="15" fill="black" fill-opacity="0.6"/></g><g style="mix-blend-mode:overlay"><rect x="74" y="689" width="88" height="40" rx="15" fill="black" fill-opacity="0.6"/></g><rect x="41.5" y="41.5" width="548" height="931" rx="48.5" stroke="white" stroke-width="3"/><text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 20.2px; font-weight: 700; white-space: pre;" x="85.211" y="222.372">MAX PRICE</text><text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 20.2px; font-weight: 700; white-space: pre;" x="85.388" y="361.031">MIN PRICE</text><text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 20.2px; font-weight: 700; white-space: pre;" x="88.705" y="499.553">NUMBER </text><text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 20.2px; font-weight: 700; white-space: pre;" x="85.388" y="361.031" transform="matrix(1, 0, 0, 1, 0.279685, 244.843087)">EXPIRATION DATE</text><text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 34px; white-space: pre;" x="82.438" y="295.936">';
  }

  // https://github.com/RollaProject/solidity-datetime#timestamptodatetime
  function getSvg(
    uint256 raffleId,
    uint256 maxPrice,
    uint256 minPrice,
    uint256 numberTickets,
    uint256 expiration
  ) external pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          _getInitial(),
          Strings.toString(maxPrice),
          ' </text><text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 34px; white-space: pre;" x="82.438" y="435.529"> ',
          Strings.toString(minPrice),
          ' </text><text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 42px; white-space: pre;" x="82.438" y="558.104"> ',
          Strings.toString(numberTickets),
          ' </text><text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 42px; white-space: pre;" x="82.438" y="671.562"> ',
          Strings.toString(expiration),
          ' </text><text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 42px; white-space: pre;" x="76.843" y="776.286"> Active',
          ' </text><circle cx="224.347" cy="764.03" r="7" style="fill: rgb(255, 0, 0);"/>',
          ' <text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 21px; white-space: pre;" x="242.803" y="1002.084">RAFFLE #',
          Strings.toString(raffleId),
          '</text></g></svg>'
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

interface ISVGRaffle {
  function getSvg(
    uint256 raffleId,
    uint256 maxPrice,
    uint256 minPrice,
    uint256 numberTickets,
    uint256 expiration
  ) external view returns (string memory);
}