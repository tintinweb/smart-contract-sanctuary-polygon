//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ERC20PermitGateway} from "@lacrypta/gateway/contracts/ERC20PermitGateway.sol";

contract BarGateway is ERC20PermitGateway {
    constructor(address _peronio) ERC20PermitGateway(_peronio) {}

    // To obtain message to be signed from voucher: stringifyVoucher(voucher)
    //   The signing procedure _should_ sign the _hash_ of this message
    //
    // To serve a voucher (1): serveVoucher(voucher, r, s, v)
    // To serve a voucher (2): serveVoucher(voucher, sig)
    //
    //
    // Vouchers:
    //   PermitVoucher:
    //
    //     Voucher permitVoucher = Voucher(
    //       0x77ed603f,       // tag --- constant (see: ERC20PermitGateway.PERMIT_VOUCHER_TAG)
    //       nonce,            // nonce --- random
    //       deadline,         // voucher deadline
    //       abi.encode(       // payload
    //         PermitVoucher(
    //             owner,      // funds owner
    //             spender,    // funds spender
    //             value,      // funds being permitted
    //             deadline,   // permit deadline
    //             v,          // signature "v"
    //             r,          // signature "r"
    //             s           // signature "s"
    //         )
    //       ),
    //       bytes()           // metadata --- empty
    //     );
    //
    //   TransferFromVoucher:
    //
    //     Voucher transferFromVoucher = Voucher(
    //       0xf7d48c1c,             // tag -- constant (see: ERC20Gateway.TRANSFER_FROM_VOUCHER_TAG)
    //       nonce,                  // nonce --- random
    //       deadline,               // voucher deadline
    //       abi.encode(             // payload
    //         TransferFromVoucher(
    //           from,               // transfer source
    //           to,                 // transfer destination
    //           amount              // transfer amount
    //         )
    //       ),
    //       bytes()                 // metadata --- empty
    //     );
    //
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ERC20Gateway} from "./ERC20Gateway.sol";
import {IERC20PermitGateway} from "./IERC20PermitGateway.sol";

import {ToString} from "./ToString.sol";
import {Epoch} from "./DateTime.sol";

abstract contract ERC20PermitGateway is ERC20Gateway, IERC20PermitGateway {
    using SafeERC20 for IERC20Permit;
    using ToString for Epoch;
    using ToString for address;
    using ToString for bytes32;
    using ToString for uint256;
    using ToString for uint8;

    // Tag associated to the PermitVoucher
    //
    // This is computed using the "encodeType" convention laid out in <https://eips.ethereum.org/EIPS/eip-712#definition-of-encodetype>.
    // Note that it is not REQUIRED to be so computed, but we do so anyways to minimize encoding conventions.
    uint32 public constant override PERMIT_VOUCHER_TAG =
        uint32(bytes4(keccak256("PermitVoucher(address owner,address spender,uint256 value,uint256 deadline,uint8 v,bytes32 r,bytes32 s)")));

    /**
     * Build a new ERC20PermitGateway from the given token address
     *
     * @param _token  Underlying ERC20 token
     */
    constructor(address _token) ERC20Gateway(_token) {
        _addHandler(PERMIT_VOUCHER_TAG, HandlerEntry({
            message: _generatePermitVoucherMessage,
            signer: _extractPermitVoucherSigner,
            execute: _executePermitVoucher
        }));
    }

    /**
     * Implementation of the IERC165 interface
     *
     * @param interfaceId  Interface ID to check against
     * @return  Whether the provided interface ID is supported
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC20PermitGateway).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * Build a PermitVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param deadline  Voucher deadline to use
     * @param owner  Permit owner address to use
     * @param spender  Permit spender address to use
     * @param value  Permit amount to use
     * @param permitDeadline  Permit deadline to use
     * @param v  Permit's signature "v" component to use
     * @param r  Permit's signature "r" component to use
     * @param s  Permit's signature "s" component to use
     * @param metadata  Voucher metadata to use
     * @return voucher  The generated voucher
     */
    function buildPermitVoucher(uint256 nonce, uint256 deadline, address owner, address spender, uint256 value, uint256 permitDeadline, uint8 v, bytes32 r, bytes32 s, bytes calldata metadata) external pure override returns (Voucher memory voucher) {
        voucher = _buildPermitVoucher(nonce, deadline, owner, spender, value, permitDeadline, v, r, s, metadata);
    }

    /**
     * Build a PermitVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param owner  Permit owner address to use
     * @param spender  Permit spender address to use
     * @param value  Permit amount to use
     * @param permitDeadline  Permit deadline to use
     * @param v  Permit's signature "v" component to use
     * @param r  Permit's signature "r" component to use
     * @param s  Permit's signature "s" component to use
     * @param metadata  Voucher metadata to use
     * @return voucher  The generated voucher
     */
    function buildPermitVoucher(uint256 nonce, address owner, address spender, uint256 value, uint256 permitDeadline, uint8 v, bytes32 r, bytes32 s, bytes calldata metadata) external view override returns (Voucher memory voucher) {
        voucher = _buildPermitVoucher(nonce, block.timestamp + 1 hours, owner, spender, value, permitDeadline, v, r, s, metadata);
    }

    /**
     * Build a PermitVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param deadline  Voucher deadline to use
     * @param owner  Permit owner address to use
     * @param spender  Permit spender address to use
     * @param value  Permit amount to use
     * @param permitDeadline  Permit deadline to use
     * @param v  Permit's signature "v" component to use
     * @param r  Permit's signature "r" component to use
     * @param s  Permit's signature "s" component to use
     * @return voucher  The generated voucher
     */
    function buildPermitVoucher(uint256 nonce, uint256 deadline, address owner, address spender, uint256 value, uint256 permitDeadline, uint8 v, bytes32 r, bytes32 s) external pure override returns (Voucher memory voucher) {
        voucher = _buildPermitVoucher(nonce, deadline, owner, spender, value, permitDeadline, v, r, s, bytes(""));
    }

    /**
     * Build a PermitVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param owner  Permit owner address to use
     * @param spender  Permit spender address to use
     * @param value  Permit amount to use
     * @param permitDeadline  Permit deadline to use
     * @param v  Permit's signature "v" component to use
     * @param r  Permit's signature "r" component to use
     * @param s  Permit's signature "s" component to use
     * @return voucher  The generated voucher
     */
    function buildPermitVoucher(uint256 nonce, address owner, address spender, uint256 value, uint256 permitDeadline, uint8 v, bytes32 r, bytes32 s) external view override returns (Voucher memory voucher) {
        voucher = _buildPermitVoucher(nonce, block.timestamp + 1 hours, owner, spender, value, permitDeadline, v, r, s, bytes(""));
    }

    /**
     * Build a PermitVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param deadline  Voucher deadline to use
     * @param owner  Permit owner address to use
     * @param spender  Permit spender address to use
     * @param value  Permit amount to use
     * @param permitDeadline  Permit deadline to use
     * @param v  Permit's signature "v" component to use
     * @param r  Permit's signature "r" component to use
     * @param s  Permit's signature "s" component to use
     * @param metadata  Voucher metadata to use
     * @return voucher  The generated voucher
     */
    function _buildPermitVoucher(uint256 nonce, uint256 deadline, address owner, address spender, uint256 value, uint256 permitDeadline, uint8 v, bytes32 r, bytes32 s, bytes memory metadata) internal pure returns (Voucher memory voucher) {
        voucher = Voucher(
            PERMIT_VOUCHER_TAG,
            nonce,
            deadline,
            abi.encode(PermitVoucher(owner, spender, value, permitDeadline, v, r, s)),
            metadata
        );
    }

    /**
     * Generate the user-readable message from the given voucher
     *
     * @param voucher  Voucher to generate the user-readable message of
     * @return message  The voucher's generated user-readable message
     */
    function _generatePermitVoucherMessage(Voucher calldata voucher) internal view returns (string memory message) {
        PermitVoucher memory decodedVoucher = abi.decode(voucher.payload, (PermitVoucher));
        message = string.concat(
            "Permit\n",
            string.concat("owner: ", decodedVoucher.owner.toString(), "\n"),
            string.concat("spender: ", decodedVoucher.spender.toString(), "\n"),
            string.concat("value: ", IERC20Metadata(token).symbol(), ' ', decodedVoucher.value.toString(IERC20Metadata(token).decimals()), "\n"),
            string.concat("deadline: ", Epoch.wrap(uint40(decodedVoucher.deadline)).toString(), "\n"),
            string.concat("v: ", decodedVoucher.v.toString(), "\n"),
            string.concat("r: ", decodedVoucher.r.toString(), "\n"),
            string.concat("s: ", decodedVoucher.s.toString())
        );
    }

    /**
     * Extract the signer from the given voucher
     *
     * @param voucher  Voucher to extract the signer of
     * @return signer  The voucher's signer
     */
    function _extractPermitVoucherSigner(Voucher calldata voucher) internal pure returns (address signer) {
        PermitVoucher memory decodedVoucher = abi.decode(voucher.payload, (PermitVoucher));
        signer = decodedVoucher.owner;
    }

    /**
     * Execute the given (already validated) voucher
     *
     * @param voucher  The voucher to execute
     */
    function _executePermitVoucher(Voucher calldata voucher) internal {
        _beforePermitWithVoucher(voucher);

        PermitVoucher memory decodedVoucher = abi.decode(voucher.payload, (PermitVoucher));
        IERC20Permit(token).safePermit(
            decodedVoucher.owner,
            decodedVoucher.spender,
            decodedVoucher.value,
            decodedVoucher.deadline,
            decodedVoucher.v,
            decodedVoucher.r,
            decodedVoucher.s
        );

        _afterPermitWithVoucher(voucher);
    }

    /**
     * Hook called before the actual permit() call is executed
     *
     * @param voucher  The voucher being executed
     */
    function _beforePermitWithVoucher(Voucher calldata voucher) internal virtual {}

    /**
     * Hook called after the actual permit() call is executed
     *
     * @param voucher  The voucher being executed
     */
    function _afterPermitWithVoucher(Voucher calldata voucher) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

import {IERC20Gateway} from "./IERC20Gateway.sol";

interface IERC20PermitGateway is IERC20Gateway {
    /**
     * permit() voucher
     *
     * @custom:member owner  The address of the owner of the funds
     * @custom:member spender  The address of the spender being permitted to move the funds
     * @custom:member value  The number of tokens to allow transfer of
     * @custom:member v  The permit's signature "v" value
     * @custom:member r  The permit's signature "r" value
     * @custom:member s  The permit's signature "s" value
     */
    struct PermitVoucher {
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /**
     * Return the tag associated to the PermitVoucher voucher itself
     *
     * @return  The tag associated to the PermitVoucher voucher itself
     */
    function PERMIT_VOUCHER_TAG() external view returns (uint32);

    /**
     * Build a PermitVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param deadline  Voucher deadline to use
     * @param owner  Permit owner address to use
     * @param spender  Permit spender address to use
     * @param value  Permit amount to use
     * @param permitDeadline  Permit deadline to use
     * @param v  Permit's signature "v" component to use
     * @param r  Permit's signature "r" component to use
     * @param s  Permit's signature "s" component to use
     * @param metadata  Voucher metadata to use
     * @return voucher  The generated voucher
     */
    function buildPermitVoucher(uint256 nonce, uint256 deadline, address owner, address spender, uint256 value, uint256 permitDeadline, uint8 v, bytes32 r, bytes32 s, bytes calldata metadata) external view returns (Voucher memory voucher);

    /**
     * Build a PermitVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param owner  Permit owner address to use
     * @param spender  Permit spender address to use
     * @param value  Permit amount to use
     * @param permitDeadline  Permit deadline to use
     * @param v  Permit's signature "v" component to use
     * @param r  Permit's signature "r" component to use
     * @param s  Permit's signature "s" component to use
     * @param metadata  Voucher metadata to use
     * @return voucher  The generated voucher
     */
    function buildPermitVoucher(uint256 nonce, address owner, address spender, uint256 value, uint256 permitDeadline, uint8 v, bytes32 r, bytes32 s, bytes calldata metadata) external view returns (Voucher memory voucher);

    /**
     * Build a PermitVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param deadline  Voucher deadline to use
     * @param owner  Permit owner address to use
     * @param spender  Permit spender address to use
     * @param value  Permit amount to use
     * @param permitDeadline  Permit deadline to use
     * @param v  Permit's signature "v" component to use
     * @param r  Permit's signature "r" component to use
     * @param s  Permit's signature "s" component to use
     * @return voucher  The generated voucher
     */
    function buildPermitVoucher(uint256 nonce, uint256 deadline, address owner, address spender, uint256 value, uint256 permitDeadline, uint8 v, bytes32 r, bytes32 s) external view returns (Voucher memory voucher);

    /**
     * Build a PermitVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param owner  Permit owner address to use
     * @param spender  Permit spender address to use
     * @param value  Permit amount to use
     * @param permitDeadline  Permit deadline to use
     * @param v  Permit's signature "v" component to use
     * @param r  Permit's signature "r" component to use
     * @param s  Permit's signature "s" component to use
     * @return voucher  The generated voucher
     */
    function buildPermitVoucher(uint256 nonce, address owner, address spender, uint256 value, uint256 permitDeadline, uint8 v, bytes32 r, bytes32 s) external view returns (Voucher memory voucher);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Gateway} from "./Gateway.sol";
import {IERC20Gateway} from "./IERC20Gateway.sol";

import {ToString} from "./ToString.sol";

abstract contract ERC20Gateway is Gateway, IERC20Gateway {
    using SafeERC20 for IERC20;
    using ToString for address;
    using ToString for uint256;

    // address of the underlying ERC20 token
    address public immutable override token;

    // Tag associated to the TransferFromVoucher
    //
    // This is computed using the "encodeType" convention laid out in <https://eips.ethereum.org/EIPS/eip-712#definition-of-encodetype>.
    // Note that it is not REQUIRED to be so computed, but we do so anyways to minimize encoding conventions.
    uint32 public constant TRANSFER_FROM_VOUCHER_TAG =
        uint32(bytes4(keccak256("TransferFromVoucher(address from,address to,uint256 amount)")));

    /**
     * Build a new ERC20Gateway from the given token address
     *
     * @param _token  Underlying ERC20 token
     */
    constructor(address _token) {
        token = _token;
        _addHandler(TRANSFER_FROM_VOUCHER_TAG, HandlerEntry({
            message: _generateTransferFromVoucherMessage,
            signer: _extractTransferFromVoucherSigner,
            execute: _executeTransferFromVoucher
        }));
    }

    /**
     * Implementation of the IERC165 interface
     *
     * @param interfaceId  Interface ID to check against
     * @return  Whether the provided interface ID is supported
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC20Gateway).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * Build a TransferFromVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param deadline  Voucher deadline to use
     * @param from  Transfer origin to use
     * @param to  Transfer destination to use
     * @param amount  Transfer amount to use
     * @param metadata  Voucher metadata to use
     * @return voucher  The generated voucher
     */
    function buildTransferFromVoucher(uint256 nonce, uint256 deadline, address from, address to, uint256 amount, bytes calldata metadata) external pure override returns (Voucher memory voucher) {
        voucher = _buildTransferFromVoucher(nonce, deadline, from, to, amount, metadata);
    }

    /**
     * Build a TransferFromVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param from  Transfer origin to use
     * @param to  Transfer destination to use
     * @param amount  Transfer amount to use
     * @param metadata  Voucher metadata to use
     * @return voucher  The generated voucher
     */
    function buildTransferFromVoucher(uint256 nonce, address from, address to, uint256 amount, bytes calldata metadata) external view override returns (Voucher memory voucher) {
        voucher = _buildTransferFromVoucher(nonce, block.timestamp + 1 hours, from, to, amount, metadata);
    }

    /**
     * Build a TransferFromVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param deadline  Voucher deadline to use
     * @param from  Transfer origin to use
     * @param to  Transfer destination to use
     * @param amount  Transfer amount to use
     * @return voucher  The generated voucher
     */
    function buildTransferFromVoucher(uint256 nonce, uint256 deadline, address from, address to, uint256 amount) external pure override returns (Voucher memory voucher) {
        voucher = _buildTransferFromVoucher(nonce, deadline, from, to, amount, bytes(""));
    }

    /**
     * Build a TransferFromVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param from  Transfer origin to use
     * @param to  Transfer destination to use
     * @param amount  Transfer amount to use
     * @return voucher  The generated voucher
     */
    function buildTransferFromVoucher(uint256 nonce, address from, address to, uint256 amount) external view override returns (Voucher memory voucher) {
        voucher = _buildTransferFromVoucher(nonce, block.timestamp + 1 hours, from, to, amount, bytes(""));
    }

    /**
     * Build a Voucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param deadline  Voucher deadline to use
     * @param from  Transfer origin to use
     * @param to  Transfer destination to use
     * @param amount  Transfer amount to use
     * @param metadata  Voucher metadata to use
     * @return voucher  The generated voucher
     */
    function _buildTransferFromVoucher(uint256 nonce, uint256 deadline, address from, address to, uint256 amount, bytes memory metadata) internal pure returns (Voucher memory voucher) {
        voucher = Voucher(
            TRANSFER_FROM_VOUCHER_TAG,
            nonce,
            deadline,
            abi.encode(TransferFromVoucher(from, to, amount)),
            metadata
        );
    }

    /**
     * Generate the user-readable message from the given voucher
     *
     * @param voucher  Voucher to generate the user-readable message of
     * @return message  The voucher's generated user-readable message
     */
    function _generateTransferFromVoucherMessage(Voucher calldata voucher) internal view returns (string memory message) {
        TransferFromVoucher memory decodedVoucher = abi.decode(voucher.payload, (TransferFromVoucher));
        message = string.concat(
            "TransferFrom\n",
            string.concat("from: ", decodedVoucher.from.toString(), "\n"),
            string.concat("to: ", decodedVoucher.to.toString(), "\n"),
            string.concat("amount: ", IERC20Metadata(token).symbol(), ' ', decodedVoucher.amount.toString(IERC20Metadata(token).decimals()))
        );
    }

    /**
     * Extract the signer from the given voucher
     *
     * @param voucher  Voucher to extract the signer of
     * @return signer  The voucher's signer
     */
    function _extractTransferFromVoucherSigner(Voucher calldata voucher) internal pure returns (address signer) {
        TransferFromVoucher memory decodedVoucher = abi.decode(voucher.payload, (TransferFromVoucher));
        signer = decodedVoucher.from;
    }

    /**
     * Execute the given (already validated) voucher
     *
     * @param voucher  The voucher to execute
     */
    function _executeTransferFromVoucher(Voucher calldata voucher) internal {
        _beforeTransferFromWithVoucher(voucher);

        TransferFromVoucher memory decodedVoucher = abi.decode(voucher.payload, (TransferFromVoucher));
        IERC20(token).safeTransferFrom(decodedVoucher.from, decodedVoucher.to, decodedVoucher.amount);

        _afterTransferFromWithVoucher(voucher);
    }

    /**
     * Hook called before the actual transferFrom() call is executed
     *
     * @param voucher  The voucher being executed
     */
    function _beforeTransferFromWithVoucher(Voucher calldata voucher) internal virtual {}

    /**
     * Hook called after the actual transferFrom() call is executed
     *
     * @param voucher  The voucher being executed
     */
    function _afterTransferFromWithVoucher(Voucher calldata voucher) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {DateTimeParts, Epoch, Quarters, dateTimeParts} from "./DateTime.sol";

library ToString {
    /**
     * Convert the given boolean value to string (ie. "true" / "false")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bool value) public pure returns (string memory) {
        return value ? "true" : "false";
    }

    /**
     * Convert the given uint value to string
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(uint256 value) public pure returns (string memory) {
        return toString(value, 0);
    }

    /**
     * Convert the given uint value to string, where as many decimal digits are used as given
     *
     * @param value  The value to convert to string
     * @param decimals  The number of decimal places to use
     * @return  The resulting string
     */
    function toString(uint256 value, uint8 decimals) public pure returns (string memory) {
        unchecked {
            bytes10 DEC_DIGITS = "0123456789";

            bytes memory buffer = "00000000000000000000000000000000000000000000000000000000000000000000000000000.";  // buffer.length = 78
            uint8 i = 78;

            // remove trailing 0s
            while ((0 < decimals) && (value % 10 == 0)) {
                value /= 10;
                decimals--;
            }
            // if there are remaining decimals to write, do so
            if (0 < decimals) {
                while (0 < decimals) {
                    buffer[--i] = DEC_DIGITS[value % 10];
                    value /= 10;
                    decimals--;
                }
                buffer[--i] = '.';
            }
            // output a 0 in case nothing left
            if (value == 0) {
                buffer[--i] = DEC_DIGITS[0];
            } else {
                while (value != 0) {
                    buffer[--i] = DEC_DIGITS[value % 10];
                    value /= 10;
                }
            }
            // transfer result from buffer
            bytes memory result = new bytes(78 - i);
            uint8 j = 0;
            while (i < 78) {
                result[j++] = buffer[i++];
            }
            return string(result);
        }
    }

    /**
     * Convert the given int value to string
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(int256 value) public pure returns (string memory) {
        return toString(value, 0);
    }

    /**
     * Convert the given int value to string, where as many decimal digits are used as given
     *
     * @param value  The value to convert to string
     * @param decimals  The number of decimal places to use
     * @return  The resulting string
     */
    function toString(int256 value, uint8 decimals) public pure returns (string memory) {
        unchecked {
            if (value < 0) {
                return string.concat('-', toString(value == type(int256).min ? 1 + type(uint256).max >> 1 : uint256(-value), decimals));
            } else {
                return toString(uint256(value), decimals);
            }
        }
    }

    /**
     * Convert the given bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes memory value) public pure returns (string memory) {
        unchecked {
            bytes16 HEX_DIGITS = "0123456789abcdef";

            uint256 len = value.length;
            bytes memory buffer = new bytes(len * 2 + 2);

            buffer[0] = '[';
            for ((uint256 i, uint256 j, uint256 k) = (0, 1, 2); i < len; (i, j, k) = (i + 1, j + 2, k + 2)) {
                uint8 val = uint8(value[i]);
                (buffer[j], buffer[k]) = (HEX_DIGITS[val >> 4], HEX_DIGITS[val & 0x0f]);
            }
            buffer[len * 2 + 1] = ']';

            return string(buffer);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes1 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes2 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes3 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes4 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes5 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes6 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes7 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes8 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes9 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes10 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes11 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes12 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes13 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes14 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes15 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes16 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes17 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes18 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes19 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes20 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes21 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes22 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes23 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes24 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes25 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes26 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes27 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes28 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes29 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes30 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes31 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes32 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given address value to string (ie. "<...>")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(address value) public pure returns (string memory) {
        unchecked {
            bytes16 HEX_DIGITS = "0123456789abcdef";

            bytes20 nValue = bytes20(value);
            bytes memory buffer = new bytes(42);
            buffer[0] = '<';
            for ((uint256 i, uint256 j, uint256 k) = (0, 1, 2); i < 20; (i, j, k) = (i + 1, j + 2, k + 2)) {
                uint8 val = uint8(nValue[i]);
                (buffer[j], buffer[k]) = (HEX_DIGITS[val >> 4], HEX_DIGITS[val & 0x0f]);
            }
            buffer[41] = '>';
            return string(buffer);
        }
    }

    /**
     * Convert the given epoch value to ISO8601 format (ie. "0000-00-00T00:00:00Z")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(Epoch value) public pure returns (string memory) {
        return toString(value, Quarters.wrap(0));
    }

    /**
     * Convert the given epoch value to ISO8601 format (ie. "0000-00-00T00:00:00+00:00")
     *
     * @param value  The value to convert to string
     * @param tzOffset  The number of quarters-of-an-hour to offset
     * @return  The resulting string
     */
    function toString(Epoch value, Quarters tzOffset) public pure returns (string memory) {
        unchecked {
            bytes10 DEC_DIGITS = "0123456789";

            DateTimeParts memory parts = dateTimeParts(value, tzOffset);

            bytes memory buffer = "0000-00-00T00:00:00";

            buffer[0] = DEC_DIGITS[(parts.year / 1000) % 10];
            buffer[1] = DEC_DIGITS[(parts.year / 100) % 10];
            buffer[2] = DEC_DIGITS[(parts.year / 10) % 10];
            buffer[3] = DEC_DIGITS[parts.year % 10];
            //
            buffer[5] = DEC_DIGITS[(parts.month / 10) % 10];
            buffer[6] = DEC_DIGITS[parts.month % 10];
            //
            buffer[8] = DEC_DIGITS[(parts.day / 10) % 10];
            buffer[9] = DEC_DIGITS[parts.day % 10];
            //
            buffer[11] = DEC_DIGITS[(parts.hour / 10) % 10];
            buffer[12] = DEC_DIGITS[parts.hour % 10];
            //
            buffer[14] = DEC_DIGITS[(parts.minute / 10) % 10];
            buffer[15] = DEC_DIGITS[parts.minute % 10];
            //
            buffer[17] = DEC_DIGITS[(parts.second / 10) % 10];
            buffer[18] = DEC_DIGITS[parts.second % 10];

            if (Quarters.unwrap(tzOffset) == 0) {
                return string.concat(string(buffer), "Z");
            } else {
                bytes memory tzBuffer = " 00:00";
                uint8 tzh;
                if (Quarters.unwrap(tzOffset) < 0) {
                    tzBuffer[0] = "-";
                    tzh = uint8(-parts.tzHours);
                } else {
                    tzBuffer[0] = "+";
                    tzh = uint8(parts.tzHours);
                }

                tzBuffer[1] = DEC_DIGITS[(tzh / 10) % 10];
                tzBuffer[2] = DEC_DIGITS[tzh % 10];
                //
                tzBuffer[4] = DEC_DIGITS[(parts.tzMinutes / 10) % 10];
                tzBuffer[5] = DEC_DIGITS[parts.tzMinutes % 10];

                return string.concat(string(buffer), string(tzBuffer));
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

// Type used for UNIX epoch quantities
type Epoch is uint40;

// Type used to represent "quarters-of-an-hour" (used for timezone offset specification)
type Quarters is int8;

/**
 * Set of parts of a date/time value encoded by a given epoch
 *
 * @custom:member year  The year the given epoch encodes
 * @custom:member month  The month the given epoch encodes
 * @custom:member day  The day the given epoch encodes
 * @custom:member hour  The hour the given epoch encodes
 * @custom:member minute  The minute the given epoch encodes
 * @custom:member second  The second the given epoch encodes
 * @custom:member tzHours  The timezone offset hours
 * @custom:member tzMinutes  The timezone offset minutes (always multiple of 15)
 */
struct DateTimeParts {
    uint256 year;
    uint256 month;
    uint256 day;
    uint256 hour;
    uint256 minute;
    uint256 second;
    int8 tzHours;
    uint256 tzMinutes;
}

/**
 * Extract the date/time components from the given epoch value
 *
 * @param value  The value to extract components from
 * @return dateTimeParts  The DateTimeParts the given epoch encodes
 */
function dateTimeParts(Epoch value) pure returns (DateTimeParts memory) {
    return dateTimeParts(value, Quarters.wrap(0));
}

/**
 * Extract the date/time components from the given epoch value and timezone offset
 *
 * Mostly taken from: https://howardhinnant.github.io/date_algorithms.html#civil_from_days
 *
 * @param value  The value to extract components from
 * @param tzOffset  The number of quarters-of-an-hour to offset
 * @return dateTimeParts  The DateTimeParts the given epoch encodes
 */
function dateTimeParts(Epoch value, Quarters tzOffset) pure returns (DateTimeParts memory) {
    unchecked {
        require(-48 <= Quarters.unwrap(tzOffset), "Strings: timezone offset too small");
        require(Quarters.unwrap(tzOffset) <= 56, "Strings: timezone offset too big");

        DateTimeParts memory result;

        int256 tzOffsetInSeconds = int256(Quarters.unwrap(tzOffset)) * 900;
        uint256 nValue;
        if (tzOffsetInSeconds < 0) {
            require(uint256(-tzOffsetInSeconds) <= Epoch.unwrap(value), "Strings: epoch time too small for timezone offset");
            nValue = Epoch.unwrap(value) - uint256(-tzOffsetInSeconds);
        } else {
            nValue = Epoch.unwrap(value) + uint256(tzOffsetInSeconds);
        }

        require(nValue <= 253402311599, "Strings: epoch time too big");

        {
            uint256 z = nValue / 86400 + 719468;
            uint256 era = z / 146097;
            uint256 doe = z - era * 146097;
            uint256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
            uint256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
            uint256 mp = (5 * doy + 2) / 153;
            //
            result.year = yoe + era * 400 + (mp == 10 || mp == 11 ? 1 : 0);
            result.month = mp < 10 ? mp + 3 : mp - 9;
            result.day = doy - (153 * mp + 2) / 5 + 1;
        }

        {
            uint256 w = nValue % 86400;
            //
            result.hour = w / 3600;
            result.minute = (w % 3600) / 60;
            result.second = w % 60;
        }

        result.tzHours = int8(tzOffsetInSeconds / 3600);
        result.tzMinutes = uint8((uint256(tzOffsetInSeconds < 0 ? -tzOffsetInSeconds : tzOffsetInSeconds) % 3600) / 60);

        return result;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IGateway} from "./IGateway.sol";

interface IERC20Gateway is IGateway {
    /**
     * Retrieve the address of the underlying ERC20 token
     *
     * @return  The address of the underlying ERC20 token
     */
    function token() external view returns (address);

    /**
     * transferFrom() voucher
     *
     * @custom:member from  The address from which to transfer funds
     * @custom:member to  The address to which to transfer funds
     * @custom:member amount  The number of tokens to transfer
     */
    struct TransferFromVoucher {
        address from;
        address to;
        uint256 amount;
    }

    /**
     * Return the tag associated to the TransferFromVoucher voucher itself
     *
     * @return  The tag associated to the TransferFromVoucher voucher itself
     */
    function TRANSFER_FROM_VOUCHER_TAG() external view returns (uint32);

    /**
     * Build a TransferFromVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param deadline  Voucher deadline to use
     * @param from  Transfer origin to use
     * @param to  Transfer destination to use
     * @param amount  Transfer amount to use
     * @param metadata  Voucher metadata to use
     * @return voucher  The generated voucher
     */
    function buildTransferFromVoucher(uint256 nonce, uint256 deadline, address from, address to, uint256 amount, bytes calldata metadata) external view returns (Voucher memory voucher);

    /**
     * Build a TransferFromVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param from  Transfer origin to use
     * @param to  Transfer destination to use
     * @param amount  Transfer amount to use
     * @param metadata  Voucher metadata to use
     * @return voucher  The generated voucher
     */
    function buildTransferFromVoucher(uint256 nonce, address from, address to, uint256 amount, bytes calldata metadata) external view returns (Voucher memory voucher);

    /**
     * Build a TransferFromVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param deadline  Voucher deadline to use
     * @param from  Transfer origin to use
     * @param to  Transfer destination to use
     * @param amount  Transfer amount to use
     * @return voucher  The generated voucher
     */
    function buildTransferFromVoucher(uint256 nonce, uint256 deadline, address from, address to, uint256 amount) external view returns (Voucher memory voucher);

    /**
     * Build a TransferFromVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param from  Transfer origin to use
     * @param to  Transfer destination to use
     * @param amount  Transfer amount to use
     * @return voucher  The generated voucher
     */
    function buildTransferFromVoucher(uint256 nonce, address from, address to, uint256 amount) external view returns (Voucher memory voucher);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

interface IGateway {
    /**
     * Voucher --- tagged union used for specific vouchers' implementation
     *
     * @custom:member tag  An integer representing the type of voucher this particular voucher is
     * @custom:member nonce  The voucher nonce to use
     * @custom:member deadline  The maximum block timestamp this voucher is valid until
     * @custom:member payload  Actual abi.encode()-ed payload (used for serving the call proper)
     * @custom:member metadata  Additional abi.encode()-ed metadata (used for administrative tasks)
     */
    struct Voucher {
        uint32 tag;
        //
        uint256 nonce;
        uint256 deadline;
        //
        bytes payload;
        bytes metadata;
    }

    /**
     * Emitted upon a voucher being served
     *
     * @param voucherHash  The voucher hash served
     * @param delegate  The delegate serving the voucher
     */
    event VoucherServed(bytes32 indexed voucherHash, address delegate);

    /**
     * Return the typehash associated to the Gateway Voucher itself
     *
     * @return  The typehash associated to the gateway Voucher itself
     */
    function VOUCHER_TYPEHASH() external view returns (bytes32);

    /**
     * Determine whether the given voucher hash has been already served
     *
     * @param voucherHash  The voucher hash to check
     * @return served  True whenever the given voucher hash has already been served
     */
    function voucherServed(bytes32 voucherHash) external view returns (bool served);

    /**
     * Return the voucher hash associated to the given voucher
     *
     * @param voucher  The voucher to retrieve the hash for
     * @return voucherHash  The voucher hash associated to the given voucher
     */
    function hashVoucher(Voucher calldata voucher) external view returns (bytes32 voucherHash);

    /**
     * Return the string representation to be signed for a given Voucher
     *
     * @param voucher  The voucher to stringify
     * @return voucherString  The string representation to be signed of the given voucher
     */
    function stringifyVoucher(Voucher calldata voucher) external view returns (string memory voucherString);

    /**
     * Validate the given voucher against the given signature, by the given signer
     *
     * @param voucher  The voucher to validate
     * @param signature  The associated voucher signature
     */
    function validateVoucher(Voucher calldata voucher, bytes memory signature) external view;

    /**
     * Validate the given voucher against the given signature, by the given signer
     *
     * @param voucher  The voucher to validate
     * @param r  The "r" component of the associated voucher signature
     * @param s  The "s" component of the associated voucher signature
     * @param v  The "v" component of the associated voucher signature
     */
    function validateVoucher(Voucher calldata voucher, bytes32 r, bytes32 s, uint8 v) external view;

    /**
     * Serve the given voucher, by forwarding to the appropriate handler for the voucher's tag
     *
     * @param voucher  The voucher to serve
     * @param signature  The associated voucher signature
     * @custom:emit  VoucherServed
     */
    function serveVoucher(Voucher calldata voucher, bytes calldata signature) external;

    /**
     * Serve the given voucher, by forwarding to the appropriate handler for the voucher's tag
     *
     * @param voucher  The voucher to serve
     * @param r  The "r" component of the associated voucher signature
     * @param s  The "s" component of the associated voucher signature
     * @param v  The "v" component of the associated voucher signature
     * @custom:emit  VoucherServed
     */
    function serveVoucher(Voucher calldata voucher, bytes32 r, bytes32 s, uint8 v) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {ToString} from "./ToString.sol";
import {Epoch} from "./DateTime.sol";

import "./IGateway.sol";

abstract contract Gateway is Context, ERC165, IGateway, Multicall, ReentrancyGuard {
    using ToString for Epoch;
    using ToString for bytes;
    using ToString for uint32;
    using ToString for uint256;

    /**
     * Structure used to keep track of handling functions
     *
     * @custom:member message  The user-readable message-generating function
     * @custom:member signer  The signer-extractor function
     * @custom:member execute  The execution function
     */
    struct HandlerEntry {
        function(Voucher calldata) view returns (string memory) message;
        function(Voucher calldata) view returns (address) signer;
        function(Voucher calldata) execute;
    }

    // Mapping from voucher tag to handling entry
    mapping(uint32 => HandlerEntry) private voucherHandler;

    // typehash associated to the gateway Voucher itself
    //
    // This is computed using the "encodeType" convention laid out in <https://eips.ethereum.org/EIPS/eip-712#definition-of-encodetype>.
    bytes32 public constant override VOUCHER_TYPEHASH =
        keccak256("Voucher(uint32 tag,uint256 nonce,uint256 deadline,bytes payload,bytes metadata)");

    // Set of voucher hashes served
    mapping(bytes32 => bool) public override voucherServed;

    /**
     * Implementation of the IERC165 interface
     *
     * @param interfaceId  Interface ID to check against
     * @return  Whether the provided interface ID is supported
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IGateway).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * Return the voucher hash associated to the given voucher
     *
     * @param voucher  The voucher to retrieve the hash for
     * @return voucherHash  The voucher hash associated to the given voucher
     */
    function hashVoucher(Voucher calldata voucher) external view override returns (bytes32 voucherHash) {
        voucherHash = _hashVoucher(voucher);
    }

    /**
     * Return the string representation to be signed for a given Voucher
     *
     * @param voucher  The voucher to stringify
     * @return voucherString  The string representation to be signed of the given voucher
     */
    function stringifyVoucher(Voucher calldata voucher) external view override returns (string memory voucherString) {
        voucherString = _stringifyVoucher(voucher);
    }

    /**
     * Validate the given voucher against the given signature
     *
     * @param voucher  The voucher to validate
     * @param signature  The associated voucher signature
     */
    function validateVoucher(Voucher calldata voucher, bytes calldata signature) external view override {
        _validateVoucher(voucher, signature);
    }

    /**
     * Validate the given voucher against the given signature, by the given signer
     *
     * @param voucher  The voucher to validate
     * @param r  The "r" component of the associated voucher signature
     * @param s  The "s" component of the associated voucher signature
     * @param v  The "v" component of the associated voucher signature
     */
    function validateVoucher(Voucher calldata voucher, bytes32 r, bytes32 s, uint8 v) external view override {
        _validateVoucher(voucher, _joinSignatureParts(r, s, v));
    }

    /**
     * Serve the given voucher, by forwarding to the appropriate handler for the voucher's tag
     *
     * @param voucher  The voucher to serve
     * @param signature  The associated voucher signature
     * @custom:emit  VoucherServed
     */
    function serveVoucher(Voucher calldata voucher, bytes calldata signature) external override nonReentrant {
        _serveVoucher(voucher, signature);
    }

    /**
     * Serve the given voucher, by forwarding to the appropriate handler for the voucher's tag
     *
     * @param voucher  The voucher to serve
     * @param r  The "r" component of the associated voucher signature
     * @param s  The "s" component of the associated voucher signature
     * @param v  The "v" component of the associated voucher signature
     * @custom:emit  VoucherServed
     */
    function serveVoucher(Voucher calldata voucher, bytes32 r, bytes32 s, uint8 v) external override nonReentrant {
        _serveVoucher(voucher, _joinSignatureParts(r, s, v));
    }

    // --- Protected handling ---------------------------------------------------------------------------------------------------------------------------------

    /**
     * Add the given pair of signer and serving functions to the tag map
     *
     * @param tag  The tag to add the mapping for
     * @param entry  The handling entry instance
     */
    function _addHandler(uint32 tag, HandlerEntry memory entry) internal {
        voucherHandler[tag] = entry;
    }

    /**
     * Add the given pair of signer and serving functions to the tag map
     *
     * @param tag  The tag to remove the mapping for
     * @return entry  The previous entry
     */
    function _removeHandler(uint32 tag) internal returns (HandlerEntry memory entry) {
        entry = voucherHandler[tag];
        delete voucherHandler[tag];
    }

    // --- Protected utilities --------------------------------------------------------------------------------------------------------------------------------

    /**
     * Return the user-readable message for the given voucher
     *
     * @param voucher  Voucher to obtain the user-readable message for
     * @return message  The voucher's user-readable message
     */
    function _message(Voucher calldata voucher) internal view returns (string memory message) {
        message = voucherHandler[voucher.tag].message(voucher);
    }

    /**
     * Retrieve the signer of the given Voucher
     *
     * @param voucher  Voucher to retrieve the signer of
     * @return signer  The voucher's signer
     */
    function _signer(Voucher calldata voucher) internal view returns (address signer) {
        signer = voucherHandler[voucher.tag].signer(voucher);
    }

    /**
     * Execute the given Voucher
     *
     * @param voucher  Voucher to execute
     */
    function _execute(Voucher calldata voucher) internal {
        voucherHandler[voucher.tag].execute(voucher);
    }

    /**
     * Actually return the string representation to be signed for a given Voucher
     *
     * @param voucher  The voucher to stringify
     * @return voucherString  The string representation to be signed of the given voucher
     */
    function _stringifyVoucher(Voucher calldata voucher) internal view returns (string memory voucherString) {
        voucherString = string.concat(
            string.concat(_message(voucher), "\n"),
            "---\n",
            string.concat("tag: ", voucher.tag.toString(), "\n"),
            string.concat("nonce: ", voucher.nonce.toString(), "\n"),
            string.concat("deadline: ", Epoch.wrap(uint40(voucher.deadline)).toString(), "\n"),
            string.concat("payload: ", voucher.payload.toString(), "\n"),
            string.concat("metadata: ", voucher.metadata.toString())
        );
    }

    /**
     * Actually return the voucher hash associated to the given voucher
     *
     * @param voucher  The voucher to retrieve the hash for
     * @return voucherHash  The voucher hash associated to the given voucher
     */
    function _hashVoucher(Voucher calldata voucher) internal view returns (bytes32 voucherHash) {
        voucherHash = keccak256(bytes(_stringifyVoucher(voucher)));
    }

    /**
     * Validate the given voucher against the given signature, by the given signer
     *
     * @param voucher  The voucher to validate
     * @param signature  The associated voucher signature
     */
    function _validateVoucher(Voucher calldata voucher, bytes memory signature) internal view {
        require(SignatureChecker.isValidSignatureNow(_signer(voucher), _hashVoucher(voucher), signature), "Gateway: invalid voucher signature");
        require(block.timestamp <= voucher.deadline, "Gateway: expired deadline");
    }

    /**
     * Mark the given voucher hash as served, and emit the corresponding event
     *
     * @param voucher  The voucher hash to serve
     * @param signature  The associated voucher signature
     * @custom:emit  VoucherServed
     */
    function _serveVoucher(Voucher calldata voucher, bytes memory signature) internal {
        _validateVoucher(voucher, signature);

        bytes32 voucherHash = _hashVoucher(voucher);
        require(voucherServed[voucherHash] == false, "Gateway: voucher already served");
        voucherServed[voucherHash] = true;

        _execute(voucher);

        emit VoucherServed(voucherHash, _msgSender());
    }

    // --- Private Utilities ----------------------------------------------------------------------------------------------------------------------------------

    /**
     * Join the "r", "s", and "v" components of a signature into a single bytes structure
     *
     * @param r  The "r" component of the signature
     * @param s  The "s" component of the signature
     * @param v  The "v" component of the signature
     * @return signature  The joint signature
     */
    function _joinSignatureParts(bytes32 r, bytes32 s, uint8 v) private pure returns (bytes memory signature) {
        signature = bytes.concat(r, s, bytes1(v));
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts (last updated v4.7.1) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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