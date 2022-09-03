//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
                 _   _         _____      _ _ _     _               ______ _____ _____
     /\         | | (_)       / ____|    | | (_)   (_)             |  ____/ ____/ ____|
    /  \   _ __ | |_ _ ______| |     ___ | | |_ ___ _  ___  _ __   | |__ | |   | |
   / /\ \ | '_ \| __| |______| |    / _ \| | | / __| |/ _ \| '_ \  |  __|| |   | |
  / ____ \| | | | |_| |      | |___| (_) | | | \__ \ | (_) | | | | | |___| |___| |____
 /_/    \_\_| |_|\__|_|       \_____\___/|_|_|_|___/_|\___/|_| |_| |______\_____\_____|

         n                                                                 :.
         E%                                                                :"5
        z  %                                                              :" `
        K   ":                                                           z   R
        ?     %.                                                       :^    J
         ".    ^s                                                     f     :~
          '+.    #L                                                 z"    .*
            '+     %L                                             z"    .~
              ":    '%.                                         .#     +
                ":    ^%.                                     .#`    +"
                  #:    "n                                  .+`   .z"
                    #:    ":                               z`    +"
                      %:   `*L                           z"    z"
                        *:   ^*L                       z*   .+"
                          "s   ^*L                   z#   .*"
                            #s   ^%L               z#   .*"
                              #s   ^%L           z#   .r"
                                #s   ^%.       u#   .r"
                                  #i   '%.   u#   [email protected]"
                                    #s   ^%u#   [email protected]"
                                      #s x#   .*"
                                       x#`  [email protected]%.
                                     x#`  .d"  "%.
                                   xf~  .r" #s   "%.
                             u   x*`  .r"     #s   "%.  x.
                             %Mu*`  x*"         #m.  "%zX"
                             :R(h x*              "h..*dN.
                           [email protected]#>                 7?dMRMh.
                         [email protected]@$#"#"                 *""*@MM$hL
                       [email protected]@MM8*                          "*[email protected]
                     z$RRM8F"                             "[email protected]$bL
                    5`RM$#                                  'R88f)R
                    'h.$"                                     #$x*

This contract is made to allow for the resending of cross chain messages
E.g. Axelar or LayerZero as a protection measure on the off chance that a message gets
lost in transit by a protocol. As a further protection measure it implements security
features such as anti-collision and message expiriy. This is to ensure that it should
be impossible to have a message failure so bad that it cannot be recovered from,
while ensuring that an intentional collision to corrupt data cannot cause unexpected
behaviour other than that of what the original message would have created.

The implementation of this contract can cause vulnurablities, any development with or
around this should follow suite with a guideline paper published here: [], along with
general security audits and proper implementation on all fronts.
*/

import "./interfaces/IECC.sol";
import "../util/CommonErrors.sol";
import "../middleLayer/interfaces/IMiddleLayer.sol";

contract ECC is IECC, CommonErrors {
    uint256 internal maxSize = 8;
    uint256 internal metadataSize = 2;
    uint256 internal usableSize = 6;

    IMiddleLayer internal middleLayer;
    address internal admin;
    mapping(address => bool) internal authContracts;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) revert OnlyAdmin();
        _;
    }

    function setMidLayer(
        address newMiddleLayer
    ) external onlyAdmin() {
        middleLayer = IMiddleLayer(newMiddleLayer);
    }

    function roundPtr(
        bytes32 ptr
    ) internal view returns (bytes32 /* ptr */) {
        assembly {
            let msze := sload(maxSize.slot)
            let delta := mod(ptr, msze)
            if gt(delta, 0) {
                let halfmsze := div(msze, 2)
                // round down at half
                if iszero(gt(delta, halfmsze)) { ptr := sub(ptr, delta) }
                if gt(delta, halfmsze) { ptr := add(ptr, delta) }
            }
        }
        return ptr;
    }

    function noCollision(
        bytes32 ptr,
        bytes32 searchExp
    ) internal view returns (bytes32 /* ptr */, uint256 steps, bool found) {
        assembly {
            let msze := sload(maxSize.slot)

            // if there is no search expression, find the closest zero slot
            if iszero(searchExp) {
                for {} gt(sload(ptr), 0) {
                    ptr := add(ptr, msze)
                    steps := add(steps, 1)
                } {}
                found := 1
            }

            if iszero(found) {
                // if there is a search expression read nonzero slots until either slot is zero, or is search expression
                for {} and(gt(sload(ptr), 0), iszero(eq(sload(ptr), searchExp))) {
                    ptr := add(ptr, msze)
                    steps := add(steps, 1)
                } {}

                found := eq(sload(ptr), searchExp)
            }
        }
        return (ptr, steps, found);
    }

    function changeAuth(
        address _contract,
        bool authStatus
    ) external onlyAdmin() {
        bytes32 ptr;
        assembly {
            mstore(0x00, _contract)
            mstore(0x20, authContracts.slot)
            ptr := keccak256(0x00, 0x40)
        }
        ptr = roundPtr(ptr);
        bool found;
        // lmfao
        (ptr, /* uint256 steps */, found) = noCollision(ptr, bytes32(uint256(uint160(_contract))));

        assembly {
            if iszero(found) { sstore(ptr, _contract) }
            sstore(add(ptr, 1), authStatus)
        }
    }

    modifier onlyAuth() {
        bytes32 ptr;
        assembly {
            mstore(0x00, caller())
            mstore(0x20, authContracts.slot)
            ptr := keccak256(0x00, 0x40)
        }
        ptr = roundPtr(ptr);
        bool found;
        (ptr, /* uint256 steps */, found) = noCollision(ptr, bytes32(uint256(uint160(msg.sender))));

        if (!found) revert OnlyAuth();

        bool auth;
        assembly {
            auth := sload(add(ptr, 1))
        }
        if (!auth) revert OnlyAuth();
        _;
    }

    function preRegMsg(
        bytes memory payload,
        address instigator,
        uint256 dstChainId,
        IHelper.Selector selector
    ) external onlyAuth() returns (bytes32 metadata) {
        if (payload.length % 32 != 0) revert InvalidPayload();
        // minus 2 as payload has 2 slots that are not stored by ecc
        uint256 dataLen = (payload.length / 32) - 2;
        if (dataLen > usableSize) revert InvalidPayload();
        dataLen = payload.length;

        bytes32 payloadHash = keccak256(payload);
        bytes32 ptr = keccak256(abi.encode(
            instigator,
            block.timestamp,
            payloadHash
        ));

        ptr = roundPtr(ptr);

        uint256 steps;
        (ptr, steps, /* found */) = noCollision(ptr, bytes32(0));

        assembly {
            { // write metadata
                metadata := or(shl(160, or(shl(16, or(shl(40, shr(216, payloadHash)), timestamp())), steps)), instigator)
                sstore(ptr, metadata)
                sstore(add(ptr, 1), or(shl(248, selector), dstChainId))
            }

            for {
                let ptrOffset := sload(metadataSize.slot)
                // skip 3 words of the payload,
                // length, metadata, selector
                let payloadOffset := 0x40
            } gt(dataLen, payloadOffset) {
                payloadOffset := add(payloadOffset, 0x20)
                sstore(add(ptr, ptrOffset), mload(add(payload, payloadOffset)))
                ptrOffset := add(ptrOffset, 1)
            } {}
        }

        emit MessageRegisteredForSend(ptr, metadata, payloadHash);
    }

    function preProcessingValidation(
        bytes32 payloadHash,
        bytes32 metadata
    ) external view returns (bool) {
        bytes32 ptr = roundPtr(metadata);
        bool found;
        (ptr, /* uint256 steps */, found) = noCollision(ptr, payloadHash);
        return (!found);
    }

    function flagMsgValidated(
        bytes32 payloadHash,
        bytes32 metadata
    ) external onlyAuth() returns (bool) {
        bytes32 ptr = roundPtr(metadata);
        (ptr, /* uint256 steps */, /* bool found */) = noCollision(ptr, bytes32(0));

        assembly {
            sstore(ptr, payloadHash)
            sstore(add(ptr, 1), metadata)
        }
        return true;
    }

    // resend message
    function resendMessage(
        bytes32 ptr,
        bytes32 metadata
    ) external override payable returns (bool /* success */) {
        uint256 _dstChainId;
        bytes memory params = new bytes(256);
        address payable _refundAddress;
        address fallbackAddress;

        /*
         * TODO:
         *       Is it safe to assume the ptr being passed in is round?
         *       possible attact vector maby?e
         *       rounding was causing issues where delta was non-zero on pre rounded ptrs...
         *
         *
         * ptr = roundPtr(ptr);
         * uint256 steps;
         * bool found;
         * (ptr, steps, found) = noCollision(ptr, metadata);

         * if (!found) {
         *     bytes32 data;
         *     assembly {
         *         data := sload(ptr)
         *     }
         *     revert("rsm not found");
         * }
        **/

        assembly {
            // validate the ptr provided is correct and matches the metadata provided
            if iszero(eq(sload(ptr), metadata)) {
                return(0, 64)
            }

            let _buffr := sload(add(ptr, 1))
            let selector := shr(0xF8, _buffr)
            _dstChainId := and(_buffr, 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)

            // we are storing the bytes starting at 64, and at the end will calculate the
            // size based on the modified _payload as that will track the size while contructing
            let _payload := add(params, 0x20)
            for {
                let word := add(ptr, sload(metadataSize.slot))

                // write metadata to 1st word of params
                mstore(_payload, metadata)
                _payload := add(_payload, 0x20)

                // write function selector to second word of params
                mstore(_payload, selector)
                _payload := add(_payload, 0x20)
            } gt(sload(word), 0) {
                // write nth stored param to 3+ith word of params
                mstore(_payload, sload(word))
                word := add(word, 1)
                _payload := add(_payload, 0x20)
            } {}
            mstore(params, sub(sub(_payload, params), 0x20))
        }

        middleLayer.msend{ value: msg.value }(
            _dstChainId,
            params,
            _refundAddress,
            fallbackAddress,
            true // TODO: Should they pay gas on this call?
        );

        return true;
    }
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../interfaces/IHelper.sol";

interface IECC {
    struct Metadata {
        bytes5 soph; // start of payload hash
        uint40 creation;
        uint16 nonce; // in case the same exact message is sent multiple times the same block, we increase the nonce in metadata
        address sender;
    }

    function preRegMsg(
        bytes memory payload,
        address instigator,
        uint256 dstChainId,
        IHelper.Selector selector
    ) external returns (bytes32 metadata);

    function preProcessingValidation(
        bytes32 payloadHash,
        bytes32 metadata
    ) external view returns (bool allowed);

    function flagMsgValidated(
        bytes32 payloadHash,
        bytes32 metadata
    ) external returns (bool);

    function resendMessage(
        bytes32 ptr,
        bytes32 metadata
    ) external payable returns (bool /* success */);

    event MessageRegisteredForSend(
        bytes32 ptr,
        bytes32 metadata,
        bytes32 payloadHash
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract CommonErrors {
    error AccountNoAssets(address account);
    error AddressExpected();
    error AlreadyInitialized();
    error EccMessageAlreadyProcessed();
    error EccFailedToValidate();
    error ExpectedMintAmount();
    error ExpectedBridgeAmount();
    error ExpectedBorrowAmount();
    error ExpectedWithdrawAmount();
    error ExpectedRepayAmount();
    error ExpectedTradeAmount();
    error ExpectedDepositAmount();
    error ExpectedTransferAmount();
    error InsufficientReserves();
    error InvalidPayload();
    error InvalidPrice();
    error InvalidPrecision();
    error InvalidSelector();
    error MarketExists();
    error LoanMarketIsListed(bool status);
    error MarketIsPaused();
    error MarketNotListed();
    error MsgDataExpected();
    error NameExpected();
    error NothingToWithdraw();
    error NotInMarket(uint256 chainId, address token);
    error OnlyAdmin();
    error OnlyAuth();
    error OnlyGateway();
    error OnlyMiddleLayer();
    error OnlyMintAuth();
    error OnlyRoute();
    error OnlyRouter();
    error OnlyMasterState();
    error ParamOutOfBounds();
    error RouteExists();
    error Reentrancy();
    error EnterLoanMarketFailed();
    error EnterCollMarketFailed();
    error ExitLoanMarketFailed();
    error ExitCollMarketFailed();
    error RepayTooMuch(uint256 repayAmount, uint256 maxAmount);
    error WithdrawTooMuch();
    error NotEnoughBalance(address token, address who);
    error LiquidateDisallowed();
    error SeizeTooMuch();
    error SymbolExpected();
    error RouteNotSupported(address route);
    error MiddleLayerPaused();
    error PairNotSupported(address loanAsset, address tradeAsset);
    error TransferFailed(address from, address dest);
    error TransferPaused();
    error UnknownRevert();
    error UnexpectedValueDelta();
    error ExpectedValue();
    error UnexpectedDelta();
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract IMiddleLayer {
    /**
     * @notice routes and encodes messages for you
     * @param _params - abi.encode() of the struct related to the selector, used to generate _payload
     * all params starting with '_' are directly sent to the 'send()' function
     */
    function msend(
        uint256 _dstChainId,
        bytes memory _params,
        address payable _refundAddress,
        address _fallbackAddress,
        bool _shouldPayGas
    ) external payable virtual;

    function mreceive(
        uint256 _srcChainId,
        bytes memory _payload
    ) external virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface IHelper {
    enum Selector {
        MASTER_DEPOSIT,
        MASTER_WITHDRAW_ALLOWED,
        FB_WITHDRAW,
        MASTER_REPAY,
        MASTER_BORROW_ALLOWED,
        FB_BORROW,
        SATELLITE_LIQUIDATE_BORROW,
        LOAN_ASSET_BRIDGE
    }

    // !!!!
    // @dev
    // an artificial uint256 param for metadata should be added
    // after packing the payload
    // metadata can be generated via call to ecc.preRegMsg()

    struct MDeposit {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.MASTER_DEPOSIT
        address user;
        address pToken;
        uint256 exchangeRate;
        uint256 depositAmount;
    }

    struct MWithdrawAllowed {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.MASTER_WITHDRAW_ALLOWED
        address pToken;
        address user;
        uint256 withdrawAmount;
        uint256 exchangeRate;
    }

    struct FBWithdraw {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.FB_WITHDRAW
        address pToken;
        address user;
        uint256 withdrawAmount;
        uint256 exchangeRate;
    }

    struct MRepay {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.MASTER_REPAY
        address borrower;
        uint256 amountRepaid;
        address loanMarketAsset;
    }

    struct MBorrowAllowed {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.MASTER_BORROW_ALLOWED
        address user;
        uint256 borrowAmount;
        address loanMarketAsset;
    }

    struct FBBorrow {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.FB_BORROW
        address user;
        uint256 borrowAmount;
        address loanMarketAsset;
    }

    struct SLiquidateBorrow {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.SATELLITE_LIQUIDATE_BORROW
        address borrower;
        address liquidator;
        uint256 seizeTokens;
        address pToken;
    }


    struct LoanAssetBridge {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.LOAN_ASSET_BRIDGE
        address minter;
        bytes32 loanAssetNameHash;
        uint256 amount;
    }
}