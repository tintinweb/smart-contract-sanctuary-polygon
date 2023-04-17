// SPDX-License-Identifier: MIT

//   _ _ _                            _                            _                     _ ____
//  | (_) |                          | |                          | |                   | |  _ \
//  | |_| |__  _ __ __ _ _ __ _   _  | |     __ _ _   _ _ __   ___| |__  _ __   __ _  __| | |_) |_   _ _   _
//  | | | '_ \| '__/ _` | '__| | | | | |    / _` | | | | '_ \ / __| '_ \| '_ \ / _` |/ _` |  _ <| | | | | | |
//  | | | |_) | | | (_| | |  | |_| | | |___| (_| | |_| | | | | (__| | | | |_) | (_| | (_| | |_) | |_| | |_| |
//  |_|_|_.__/|_|  \__,_|_|   \__, | |______\__,_|\__,_|_| |_|\___|_| |_| .__/ \__,_|\__,_|____/ \__,_|\__, |
//                             __/ |                                    | |                             __/ |
//                            |___/                                     |_|                            |___/

pragma solidity ^0.8.16;

import "../data/DataType.sol";
import "../enum/LaunchpadProxyEnums.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library LaunchpadBuy {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    function processBuy(
        DataType.Launchpad storage lpad,
        DataType.AccountRoundsStats storage accountStats,
        uint256 roundsIdx,
        address sender,
        uint256 whiteListBuyNum,
        uint256 quantity,
        bytes memory signature,
        address signer
    ) public returns (uint256) {
        string memory ret = checkLaunchpadBuy(
            lpad,
            accountStats,
            roundsIdx,
            sender,
            quantity,
            whiteListBuyNum,
            signer,
            signature,
            sender
        );

        if (keccak256(bytes(ret)) != keccak256(bytes(LaunchpadProxyEnums.OK))) {
            revert(ret);
        }
        uint256 shouldPay = lpad.roundss[roundsIdx].price * quantity;
        uint256 nftType = lpad.nftType;
        address sourceAddress = lpad.sourceAddress;
        if (lpad.roundss[roundsIdx].price > 0) {
            transferIncomes(
                lpad,
                sender,
                lpad.roundss[roundsIdx].buyToken,
                shouldPay
            );
        }
        {
            uint32 totalBuyQty = accountStats.totalBuyQty;
            accountStats.totalBuyQty = totalBuyQty + uint32(quantity);
            accountStats.lastBuyTime = uint32(block.timestamp);

            if (
                roundsIdx != 0 &&
                lpad.roundss[roundsIdx - 1].saleQuantity !=
                lpad.roundss[roundsIdx - 1].maxSupply
            ) {
                lpad.roundss[roundsIdx].startTokenId =
                    lpad.roundss[roundsIdx - 1].saleQuantity +
                    lpad.roundss[roundsIdx - 1].startTokenId;
                lpad.roundss[roundsIdx].maxSupply =
                    lpad.roundss[roundsIdx].maxSupply +
                    lpad.roundss[roundsIdx - 1].maxSupply -
                    lpad.roundss[roundsIdx - 1].saleQuantity;
                lpad.roundss[roundsIdx - 1].maxSupply = lpad
                    .roundss[roundsIdx - 1]
                    .saleQuantity;
            }
        }
        transitCall(nftType, lpad, roundsIdx, sender, quantity, sourceAddress);
        return shouldPay;
    }

    function transitCall(
        uint256 nftType,
        DataType.Launchpad storage lpad,
        uint256 roundsIdx,
        address sender,
        uint256 quantity,
        address sourceAddress
    ) public {
        if (nftType == 0) {
            uint256 saleQuantity = lpad.roundss[roundsIdx].saleQuantity;
            DataType.LaunchpadRounds memory lpadRounds = lpad.roundss[
                roundsIdx
            ];
            for (uint256 i = 0; i < quantity; i++) {
                uint256 tokenId = lpadRounds.startTokenId + saleQuantity;
                callLaunchpadBuy(
                    lpad,
                    sender,
                    quantity,
                    sourceAddress,
                    tokenId
                );
                saleQuantity = saleQuantity + 1;
            }
            lpad.roundss[roundsIdx].saleQuantity = uint32(saleQuantity);
        } else {
            uint256 saleQuantity = lpad.roundss[roundsIdx].saleQuantity;
            DataType.LaunchpadRounds memory lpadRounds = lpad.roundss[
                roundsIdx
            ];
            for (uint256 i = 0; i < quantity; i++) {
                uint256 tokenId = lpadRounds.startTokenId + saleQuantity;
                uint256 perIdQuantity = lpad.roundss[roundsIdx].perIdQuantity;
                callLaunchpadBuy(
                    lpad,
                    sender,
                    perIdQuantity,
                    sourceAddress,
                    tokenId
                );
                saleQuantity = saleQuantity + 1;
            }
            lpad.roundss[roundsIdx].saleQuantity = uint32(saleQuantity);
        }
    }

    function callLaunchpadBuy(
        DataType.Launchpad storage lpad,
        address sender,
        uint256 quantity,
        address sourceAddress,
        uint256 tokenId
    ) public {
        // example bytes4(keccak256("safeMint(address,uint256)")),
        bytes4 selector = lpad.abiSelectorAndParam[
            DataType.ABI_IDX_BUY_SELECTOR
        ];
        bytes4 paramTable = lpad.abiSelectorAndParam[
            DataType.ABI_IDX_BUY_PARAM_TABLE
        ];
        bytes memory proxyCallData;
        if (paramTable == bytes4(0x00000000)) {
            proxyCallData = abi.encodeWithSelector(selector, sender, tokenId);
        } else if (paramTable == bytes4(0x00000001)) {
            proxyCallData = abi.encodeWithSelector(
                selector,
                sender,
                tokenId,
                quantity
            );
        } else if (paramTable == bytes4(0x00000002)) {
            proxyCallData = abi.encodeWithSelector(
                selector,
                sourceAddress,
                sender,
                tokenId
            );
        } else if (paramTable == bytes4(0x00000003)) {
            proxyCallData = abi.encodeWithSelector(
                selector,
                sourceAddress,
                sender,
                tokenId,
                quantity
            );
        }
        require(
            proxyCallData.length > 0,
            LaunchpadProxyEnums.LPD_ROUNDS_ABI_NOT_FOUND
        );
        (bool didSucceed, bytes memory returnData) = lpad.targetContract.call(
            proxyCallData
        );
        if (!didSucceed) {
            revert(
                string(
                    abi.encodePacked(
                        LaunchpadProxyEnums.LPD_ROUNDS_CALL_BUY_CONTRACT_FAILED,
                        LaunchpadProxyEnums.LPD_SEPARATOR,
                        returnData
                    )
                )
            );
        }
    }

    function checkLaunchpadBuy(
        DataType.Launchpad memory lpad,
        DataType.AccountRoundsStats memory accStats,
        uint256 roundsIdx,
        address sender,
        uint256 quantity,
        uint256 wlMaxBuyQuantity,
        address signer,
        bytes memory signature,
        address msgSender
    ) public returns (string memory) {
        if (lpad.id == 0) return LaunchpadProxyEnums.LPD_INVALID_ID;
        if (!lpad.enable) return LaunchpadProxyEnums.LPD_NOT_ENABLE;
        if (roundsIdx >= lpad.roundss.length)
            return LaunchpadProxyEnums.LPD_ROUNDS_IDX_INVALID;
        DataType.LaunchpadRounds memory lpadRounds = lpad.roundss[roundsIdx];
        if (isContract(sender))
            return LaunchpadProxyEnums.LPD_ROUNDS_BUY_FROM_CONTRACT_NOT_ALLOWED;
        if ((quantity + lpadRounds.saleQuantity) > lpadRounds.maxSupply)
            return LaunchpadProxyEnums.LPD_ROUNDS_QTY_NOT_ENOUGH_TO_BUY;
        if (lpadRounds.price > 0) {
            uint256 paymentNeeded = quantity * lpadRounds.price;
            if (lpadRounds.buyToken != address(0)) {
                if (
                    paymentNeeded >
                    IERC20(lpadRounds.buyToken).balanceOf(sender)
                ) return LaunchpadProxyEnums.LPD_ROUNDS_ERC20_BLC_NOT_ENOUGH;
                if (
                    paymentNeeded >
                    IERC20(lpadRounds.buyToken).allowance(sender, address(this))
                )
                    return
                        LaunchpadProxyEnums
                            .LPD_ROUNDS_PAYMENT_ALLOWANCE_NOT_ENOUGH;
                if (msg.value > 0)
                    return LaunchpadProxyEnums.LPD_ROUNDS_PAY_VALUE_NOT_NEED;
            } else {
                if (paymentNeeded > (sender.balance + msg.value))
                    return LaunchpadProxyEnums.LPD_ROUNDS_PAYMENT_NOT_ENOUGH;
                if (paymentNeeded > msg.value)
                    return LaunchpadProxyEnums.LPD_ROUNDS_PAY_VALUE_NOT_ENOUGH;
                if (msg.value > paymentNeeded)
                    return LaunchpadProxyEnums.LPD_ROUNDS_PAY_VALUE_UPPER_NEED;
            }
        }
        if (quantity > lpadRounds.maxBuyNumOnce)
            return LaunchpadProxyEnums.LPD_ROUNDS_MAX_BUY_QTY_PER_TX_LIMIT;
        if ((quantity + accStats.totalBuyQty) > lpadRounds.maxBuyQtyPerAccount)
            return LaunchpadProxyEnums.LPD_ROUNDS_ACCOUNT_MAX_BUY_LIMIT;
        if (block.timestamp - accStats.lastBuyTime < lpadRounds.buyInterval)
            return LaunchpadProxyEnums.LPD_ROUNDS_ACCOUNT_BUY_INTERVAL_LIMIT;
        if (lpadRounds.saleEnd > 0 && block.timestamp > lpadRounds.saleEnd)
            return LaunchpadProxyEnums.LPD_ROUNDS_SALE_END;
        if (lpadRounds.whiteListModel != DataType.WhiteListModel.NONE) {
            return
                checkWhitelistBuy(
                    lpad,
                    roundsIdx,
                    quantity,
                    accStats.totalBuyQty,
                    wlMaxBuyQuantity,
                    signer,
                    signature,
                    msgSender
                );
        } else {
            if (block.timestamp < lpadRounds.saleStart)
                return LaunchpadProxyEnums.LPD_ROUNDS_SALE_NOT_START;
        }
        return LaunchpadProxyEnums.OK;
    }

    function transferIncomes(
        DataType.Launchpad memory lpad,
        address sender,
        address buyToken,
        uint256 shouldPay
    ) public {
        if (shouldPay == 0) {
            return;
        }
        if (buyToken == address(0)) {
            payable(lpad.receipts).transfer(shouldPay);
        } else {
            IERC20 token = IERC20(buyToken);
            token.safeTransferFrom(sender, lpad.receipts, shouldPay);
        }
    }

    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    //                     [whitelist sale]                  [public sale]
    //  | whiteListSaleStart ---------- saleStart | saleStart ---------- saleEnd |
    function checkWhitelistBuy(
        DataType.Launchpad memory lpad,
        uint256 roundsIdx,
        uint256 quantity,
        uint256 alreadyBuy,
        uint256 maxWhitelistBuy,
        address signer,
        bytes memory signature,
        address msgSender
    ) public view returns (string memory) {
        DataType.LaunchpadRounds memory lpadRounds = lpad.roundss[roundsIdx];
        if (lpadRounds.whiteListSaleStart != 0) {
            if (lpadRounds.saleStart < block.timestamp) {
                return LaunchpadProxyEnums.OK;
            }
            if (block.timestamp < lpadRounds.whiteListSaleStart)
                return LaunchpadProxyEnums.LPD_ROUNDS_WHITELIST_SALE_NOT_START;
        } else {
            if (block.timestamp < lpadRounds.saleStart)
                return LaunchpadProxyEnums.LPD_ROUNDS_WHITELIST_SALE_NOT_START;
        }
        if (!signVerify(lpad.id, roundsIdx, signer, signature, msgSender))
            return LaunchpadProxyEnums.LPD_ROUNDS_ACCOUNT_NOT_IN_WHITELIST;
        if (maxWhitelistBuy == 0)
            return LaunchpadProxyEnums.LPD_ROUNDS_MAX_WHITELIST_BUY_ZERO;
        if ((quantity + alreadyBuy) > maxWhitelistBuy)
            return LaunchpadProxyEnums.LPD_ROUNDS_WHITELIST_BUY_NUM_LIMIT;
        return LaunchpadProxyEnums.OK;
    }

    // sign verify
    function signVerify(
        bytes4 launchpadId,
        uint256 roundsIdx,
        address signer,
        bytes memory signature,
        address msgSender
    ) public pure returns (bool) {
        bytes32 shash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(msgSender, launchpadId, roundsIdx))
            )
        );
        return signer == shash.recover(signature);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library LaunchpadProxyEnums {
    // 'ok'
    string public constant OK = "0";
    // 'only collaborator,owner can call'
    string public constant LPD_ONLY_COLLABORATOR_OWNER = "1";
    // 'only controller,collaborator,owner'
    string public constant LPD_ONLY_CONTROLLER_COLLABORATOR_OWNER = "2";
    // 'only authorities can call'
    string public constant LPD_ONLY_AUTHORITIES_ADDRESS = "3";
    // seprator err
    string public constant LPD_SEPARATOR = "4";
    // 'sender must transaction caller'
    string public constant SENDER_MUST_TX_CALLER = "5";
    // 'launchpad invalid id'
    string public constant LPD_INVALID_ID = "6";
    // 'launchpadId exists'
    string public constant LPD_ID_EXISTS = "7";
    // 'launchpad not enable'
    string public constant LPD_NOT_ENABLE = "8";
    // 'input array len not match'
    string public constant LPD_INPUT_ARRAY_LEN_NOT_MATCH = "9";
    // 'launchpad param locked'
    string public constant LPD_PARAM_LOCKED = "10";
    // 'launchpad rounds idx invalid'
    string public constant LPD_ROUNDS_IDX_INVALID = "11";
    // "rounds target contract address not valid"
    string public constant LPD_ROUNDS_TARGET_CONTRACT_INVALID = "12";
    // "invalid abi selector array not equal max"
    string public constant LPD_ROUNDS_ABI_ARRAY_LEN = "13";
    // 'buy from contract address not allowed'
    string public constant LPD_ROUNDS_BUY_FROM_CONTRACT_NOT_ALLOWED = "14";
    // 'sale not start yet'
    string public constant LPD_ROUNDS_SALE_NOT_START = "15";
    // 'max buy quantity one transaction limit'
    string public constant LPD_ROUNDS_MAX_BUY_QTY_PER_TX_LIMIT = "16";
    // 'quantity not enough to buy'
    string public constant LPD_ROUNDS_QTY_NOT_ENOUGH_TO_BUY = "17";
    // "payment not enough"
    string public constant LPD_ROUNDS_PAYMENT_NOT_ENOUGH = "18";
    // 'allowance not enough'
    string public constant LPD_ROUNDS_PAYMENT_ALLOWANCE_NOT_ENOUGH = "19";
    // "account max buy num limit"
    string public constant LPD_ROUNDS_ACCOUNT_MAX_BUY_LIMIT = "20";
    // 'account buy interval limit'
    string public constant LPD_ROUNDS_ACCOUNT_BUY_INTERVAL_LIMIT = "21";
    // 'not in whitelist'
    string public constant LPD_ROUNDS_ACCOUNT_NOT_IN_WHITELIST = "22";
    // 'buy selector invalid '
    string public constant LPD_ROUNDS_ABI_BUY_SELECTOR_INVALID = "23";
    // 'call buy contract fail'
    string public constant LPD_ROUNDS_CALL_BUY_CONTRACT_FAILED = "24";
    // 'call open contract fail'
    string public constant LPD_ROUNDS_CALL_OPEN_CONTRACT_FAILED = "25";
    // "erc20 balance not enough"
    string public constant LPD_ROUNDS_ERC20_BLC_NOT_ENOUGH = "26";
    // "eth send value not enough"
    string public constant LPD_ROUNDS_PAY_VALUE_NOT_ENOUGH = "27";
    // 'eth send value not need'
    string public constant LPD_ROUNDS_PAY_VALUE_NOT_NEED = "28";
    // 'eth send value upper need value'
    string public constant LPD_ROUNDS_PAY_VALUE_UPPER_NEED = "29";
    // 'not found abi to encode'
    string public constant LPD_ROUNDS_ABI_NOT_FOUND = "30";
    // 'sale end'
    string public constant LPD_ROUNDS_SALE_END = "31";
    // 'whitelist buy number limit'
    string public constant LPD_ROUNDS_WHITELIST_BUY_NUM_LIMIT = "32";
    // 'whitelist sale not start yet'
    string public constant LPD_ROUNDS_WHITELIST_SALE_NOT_START = "33";
    // 'maxWhitelistBuy 0'
    string public constant LPD_ROUNDS_MAX_WHITELIST_BUY_ZERO = "34";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library DataType {
    // example: bytes4(keccak256("safeMint(address,uint256)"))
    uint256 internal constant ABI_IDX_BUY_SELECTOR = 0;
    // buy param example:
    // 0x00000000 - (address sender, uint256 tokenId),
    // 0x00000001 - (address sender, uint256 tokenId, uint256 quantity)
    // 0x00000002 - (address sourceAddress, address sender, uint256 tokenId)
    // 0x00000003 - (address sourceAddress, address sender, uint256 tokenId, uint256 quantity)
    uint256 internal constant ABI_IDX_BUY_PARAM_TABLE = 1;
    // example: bytes4(keccak256("setBaseURI(uint256)"))
    uint256 internal constant ABI_IDX_BASEURI_SELECTOR = 2;
    // setBaseURI param example:
    // 0x00000000 - (uint256 baseURI), default setBaseURI(uint256)
    uint256 internal constant ABI_IDX_BASEURI_PARAM_TABLE = 3;
    uint256 internal constant ABI_IDX_MAX = 4;
    // whiteListModel
    enum WhiteListModel {
        NONE, // 0 - No White List
        CHECK // 1 - Check address
    }

    // launchpad 1
    struct Launchpad {
        // id of launchpad
        bytes4 id;
        // target contract of 3rd project,
        address targetContract;
        // 0-buy abi, 1-buy param, 2-setBaseURI abi, 3-setBaseURI param
        bytes4[ABI_IDX_MAX] abiSelectorAndParam;
        // enable
        bool enable;
        // lock the launchpad param, can't change except owner
        bool lockParam;
        // admin to config this launchpad params
        address controllerAdmin;
        // receipts address
        address receipts;
        // launchpad rounds info detail
        LaunchpadRounds[] roundss;
        // launchpad nftType 0:721/ 1:1155
        uint256 nftType;
        // launchpad sourceAddress transfer use
        address sourceAddress;
    }

    // 1 launchpad have N rounds
    struct LaunchpadRounds {
        // price of normal user account, > 8888 * 10**18 means
        uint128 price;
        // start token id, most from 0
        uint128 startTokenId;
        // buy token
        address buyToken;
        // white list model
        WhiteListModel whiteListModel;
        // buy start time, seconds UTC±0
        uint32 saleStart;
        // buy end time, seconds UTC±0
        uint32 saleEnd;
        // whitelist start time, seconds UTC±0
        uint32 whiteListSaleStart;
        // perIdQuantity 721:1 , 1155:n
        uint32 perIdQuantity;
        // max supply of this rounds
        uint32 maxSupply;
        // current sale number, must from 0
        uint32 saleQuantity;
        // max buy qty per address
        uint32 maxBuyQtyPerAccount;
        // max buy num one tx
        uint32 maxBuyNumOnce;
        // next buy time till last buy, seconds
        uint32 buyInterval;
        // number can buy of whitelist
        uint32 whiteListBuyNum;
    }

    // stats info for buyer account
    struct AccountRoundsStats {
        // last buy seconds,
        uint32 lastBuyTime;
        // total buy num already
        uint32 totalBuyQty;
    }

    // status info for launchpad
    struct LaunchpadVar {
        // account<->rounds stats； key: roundsIdx(96) + address(160), use genRoundsAddressKey()
        mapping(uint256 => AccountRoundsStats) accountRoundsStats;
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