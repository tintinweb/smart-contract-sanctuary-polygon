/**
 *Submitted for verification at polygonscan.com on 2022-08-17
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
library Library {
    enum BetType {
        BACK,
        LAY
    }
    enum Result {
        HAPPENED,
        NOT_HAPPENED,
        NO_RESULT
    }
    struct Order {
        address user;
        BetType betType;
        string eventID;
        string betTeamId; // update with betTeamID
        bool isFilled;
        bool isCancelled;
        uint256 orderID;
        uint256 oddID;
        uint256 date;
        uint256 index;
        uint256 odd;
        uint256 filledWithAmount;
        uint256 betAmountLeft;
        uint256 betAmount;
    }

    struct Odd {
        string eventID;
        address oddCreator;
        uint256 oddID;
        uint256[] backBettorOrders;
        uint256[] layBettorOrders;
        uint256 currentUnfilledBackBet;
        uint256 currentUnfilledLayBet;
        uint256 odd;
        uint256 totalBackBetAmount;
        uint256 totalLayBetAmount;
        uint256 totalBackBettors;
        uint256 totalLayBettors;
    }

    struct Event {
        string eventID;
        uint256 eventStartDate;
        uint256 eventEndDate;
        Result eventResult;
        string eventName;
        string eventExpectedOutcome;
        bool eventEnded;
        bool cancelled;
        bool allowAfterDate;
        uint256 sportID;
    }
}

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)
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

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)
/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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

interface IEscrow {
    function increaseBetAmount(
        address _owner,
        uint256 _amount,
        uint256 _orderID
    ) external;

    function decreaseBetAmount(
        address _owner,
        uint256 _amount,
        uint256 _orderID
    ) external;

    function increaseReturnAmount(
        address _owner,
        uint256 _amount,
        uint256 _orderID
    ) external;

    function decreaseReturnAmount(
        address _owner,
        uint256 _amount,
        uint256 _orderID
    ) external;

    function settlementWinOutcome(address _recipient, uint256 _orderID)
        external;
}

contract FillOrder is Ownable {
    //mapping to manage the order details mapped with the `eventID` and `orderID`
    mapping(string => mapping(uint256 => Library.Order)) public order;

    //mapping to manage the odd details mapped with the `eventID` and `oddID`
    mapping(string => mapping(uint256 => Library.Odd)) public oddDetail;

    //mapping to check whether the given odd is already in use
    mapping(string => mapping(uint256 => bool)) private isOddUsed;

    //mapping to manage the `oddID` mapped with `odd`
    mapping(uint256 => uint256) public oddMappedWithID;

    //order counter
    uint256 public orderCount;

    //event counter
    uint256 public eventCount;

    //odd counter
    uint256 public oddCount;

    //USDC token intsance to interact with the USDC contract
    IERC20 public USDC;

    //Escrow contract instance to interct with the Escrow contract
    IEscrow public EscrowContract;

    // Emitted when the new order is created
    event orderCreated(
        uint256 orderID,
        string indexed eventID,
        uint256 indexed oddID,
        uint256 odd,
        uint256 betAmount,
        uint256 date,
        address indexed user
    );

    //Emitted when the new odd is created
    event oddCreated(
        string indexed eventID,
        uint256 indexed oddID,
        uint256 odd,
        uint256 date,
        address indexed user
    );

    //Emitted when the refund is claimed by the user
    event refundClaimed(
        string indexed eventID,
        uint256 indexed orderID,
        uint256 refundAmount,
        uint256 date,
        address indexed user
    );

    //Emitted when the order is cancelled by the user
    event orderCancelled(
        string indexed eventID,
        uint256 indexed orderID,
        uint256 refundAmount,
        uint256 date,
        address indexed user
    );

    //Emitted when the order if filled by the opponent bet

    event orderFilled(
        string indexed eventID,
        uint256 indexed orderID,
        uint256 filledAmount
    );

    //Emitted when the reward is claimed by the user
    event rewardClaimed(
        string indexed eventID,
        uint256 indexed orderID,
        uint256 rewardAmount,
        uint256 date,
        address indexed user
    );

    constructor(address _USDC, address _escrow) {
        USDC = IERC20(_USDC);
        EscrowContract = IEscrow(_escrow);
    }

    /// -----------------------------------
    /// ----- USER SPEICIFIC FUNCTIONS ----
    /// -----------------------------------

    /**
     *topic: `function createOddandBet
     *
     *@dev Create a new odd if it's not created by another user and place a bet for the same
     *
     */
    function createOddandBet(
        string memory _eventID,
        string memory _betTeamID,
        uint256 _odds,
        uint256 _betAmount,
        uint256 _betType,
        uint256 _eventStartDate
    ) private {
        require(
            !isOddUsed[_eventID][_odds],
            "Create odd and bet: The given odd is already created"
        );

        Library.Odd storage odd = oddDetail[_eventID][oddCount];
        odd.eventID = _eventID;
        odd.odd = _odds;
        odd.oddID = oddCount;
        odd.oddCreator = msg.sender;
        isOddUsed[_eventID][_odds] = true;
        oddMappedWithID[_odds] = oddCount;
        oddCount++;
        emit oddCreated(
            _eventID,
            odd.oddID,
            _odds,
            block.timestamp,
            msg.sender
        );
        _fillOrder(
            _eventID,
            _betTeamID,
            odd.oddID,
            _betAmount,
            _betType,
            _eventStartDate
        );
    }

    /**
     *topic: `function fillOrder`
     *
     *@dev Forward the function call depending on the odd existance, if the given `odd` doesn't exists then it calls `createOddandBet` else it calls `_fillOrder`.
     *
     */
    function fillOrder(
        bytes calldata _signature,
        string memory _eventID,
        string memory _betTeamID,
        uint256 _betAmount,
        uint256 _odd,
        uint256 _betType,
        uint256 _eventStartDate,
        bool _isClosed
    ) public {
        bytes32 message = keccak256(abi.encodePacked(_eventID, ""));
        require(ECDSA.recover(message, _signature) == owner(), "Invalid signature");
        // require(isEventCreated[_eventID], "Fill order: Event ID not found");
        require(
            !_isClosed,
            "Fill order: Event has been ended"
        );
        if (isOddUsed[_eventID][_odd]) {
            _fillOrder(
                _eventID,
                _betTeamID,
                oddMappedWithID[_odd],
                _betAmount,
                _betType,
                _eventStartDate
            );
        } else {
            createOddandBet(
                _eventID,
                _betTeamID,
                _odd,
                _betAmount,
                _betType,
                _eventStartDate
            );
        }
    }

    /**
     *topic: `function _fillOrder`
     *
     *@dev Create a new order and place a bet aginst the counter odd, It's the main function that handles the order matching.
     *
     */
    function _fillOrder(
        string memory _eventID,
        string memory _betTeamID,
        uint256 _oddID,
        uint256 _betAmount,
        uint256 _betType,
        uint256 _eventStartDate
    ) private {
        Library.Order storage ord = order[_eventID][orderCount];
        Library.Odd storage odd = oddDetail[_eventID][_oddID];
        // uint256 counterOddID = oddMappedWithID[
        //   getOddsForOrder(_betAmount, odd.odd)
        // ];
        Library.Odd storage counterOdd = oddDetail[_eventID][
            oddMappedWithID[getOddsForOrder(_betAmount, odd.odd)]
        ];
        ord.betAmountLeft = _betAmount;
        ord.betAmount = _betAmount;
        ord.betTeamId = _betTeamID;

        if (_betType == 0) {
            // uint256 counter = counterOdd.currentUnfilledLayBet;
            for (
                uint256 i = counterOdd.currentUnfilledLayBet;
                i < counterOdd.layBettorOrders.length;
                i++
            ) {
                Library.Order storage layOrd = order[_eventID][
                    counterOdd.layBettorOrders[i]
                ];
                if (
                    (!layOrd.isFilled && !ord.isFilled) &&
                    (layOrd.betAmountLeft > 0 && ord.betAmountLeft > 0) &&
                    (!layOrd.isCancelled)
                ) {
                    if (_eventStartDate < block.timestamp) {
                        if (layOrd.index == counterOdd.currentUnfilledLayBet) {
                            counterOdd.currentUnfilledLayBet = counterOdd
                                .currentUnfilledLayBet +
                                1 <
                                counterOdd.layBettorOrders.length
                                ? counterOdd.currentUnfilledLayBet + 1
                                : counterOdd.currentUnfilledLayBet;
                        }
                        continue;
                    }
                    uint256 layOrdAmountLeft = layOrd.betAmountLeft;
                    uint256 currentOrderAmountLeft = ord.betAmountLeft;
                    uint256 layOrdRewardAmount = getRewardAmount(
                        layOrdAmountLeft,
                        layOrd.odd
                    );
                    uint256 currentOrderRewardAmount = getRewardAmount(
                        currentOrderAmountLeft,
                        odd.odd
                    );

                    if (layOrdAmountLeft > currentOrderRewardAmount) {
                        ord.filledWithAmount += currentOrderRewardAmount;
                        ord.betAmountLeft = 0;
                        layOrd.betAmountLeft = getRefundAmount(
                            layOrd.betAmount,
                            layOrd.filledWithAmount,
                            layOrd.odd
                        );

                        //odd.currentUnfilledBackBet += 1;
                        odd.currentUnfilledBackBet = odd
                            .currentUnfilledBackBet +
                            1 <
                            odd.backBettorOrders.length
                            ? odd.currentUnfilledBackBet + 1
                            : odd.currentUnfilledBackBet;
                        ord.isFilled = true;
                        if (currentOrderAmountLeft > layOrdRewardAmount) {
                            layOrd.filledWithAmount += layOrdRewardAmount;
                            layOrd.betAmountLeft = 0;
                            counterOdd.currentUnfilledLayBet = counterOdd
                                .currentUnfilledLayBet +
                                1 <
                                counterOdd.layBettorOrders.length
                                ? counterOdd.currentUnfilledLayBet + 1
                                : counterOdd.currentUnfilledLayBet;
                            layOrd.isFilled = true;
                            ord.betAmountLeft = getRefundAmount(
                                ord.betAmount,
                                ord.filledWithAmount,
                                odd.odd
                            );
                            EscrowContract.increaseReturnAmount(
                                layOrd.user,
                                layOrdRewardAmount,
                                layOrd.orderID
                            );
                        } else if (
                            currentOrderAmountLeft <= layOrdRewardAmount
                        ) {
                            layOrd.filledWithAmount += currentOrderAmountLeft;
                            layOrd.betAmountLeft = getRefundAmount(
                                layOrd.betAmount,
                                layOrd.filledWithAmount,
                                layOrd.odd
                            );
                            if (
                                layOrd.filledWithAmount ==
                                getRewardAmount(layOrd.betAmount, layOrd.odd)
                            ) {
                                layOrd.isFilled = true;
                                counterOdd.currentUnfilledLayBet = counterOdd
                                    .currentUnfilledLayBet +
                                    1 <
                                    counterOdd.layBettorOrders.length
                                    ? counterOdd.currentUnfilledLayBet + 1
                                    : counterOdd.currentUnfilledLayBet;
                            }
                            ord.betAmountLeft = 0;
                            EscrowContract.increaseReturnAmount(
                                layOrd.user,
                                currentOrderAmountLeft,
                                layOrd.orderID
                            );
                        }
                    } else if (layOrdAmountLeft <= currentOrderRewardAmount) {
                        ord.filledWithAmount += layOrdAmountLeft;

                        ord.betAmountLeft = getRefundAmount(
                            ord.betAmount,
                            ord.filledWithAmount,
                            odd.odd
                        );
                        layOrd.betAmountLeft = 0;
                        if (
                            ord.filledWithAmount ==
                            getRewardAmount(ord.betAmount, odd.odd)
                        ) {
                            ord.isFilled = true;

                            // odd.currentUnfilledBackBet += 1;
                            odd.currentUnfilledBackBet = odd
                                .currentUnfilledBackBet +
                                1 <
                                odd.backBettorOrders.length
                                ? odd.currentUnfilledBackBet + 1
                                : odd.currentUnfilledBackBet;
                        }

                        if (currentOrderAmountLeft > layOrdRewardAmount) {
                            layOrd.filledWithAmount += layOrdRewardAmount;
                            layOrd.betAmountLeft = 0;
                            counterOdd.currentUnfilledLayBet = counterOdd
                                .currentUnfilledLayBet +
                                1 <
                                counterOdd.layBettorOrders.length
                                ? counterOdd.currentUnfilledLayBet + 1
                                : counterOdd.currentUnfilledLayBet;
                            layOrd.isFilled = true;
                            ord.betAmountLeft = getRefundAmount(
                                ord.betAmount,
                                ord.filledWithAmount,
                                odd.odd
                            );
                            EscrowContract.increaseReturnAmount(
                                layOrd.user,
                                layOrdRewardAmount,
                                layOrd.orderID
                            );
                        } else if (
                            currentOrderAmountLeft <= layOrdRewardAmount
                        ) {
                            layOrd.filledWithAmount += currentOrderAmountLeft;
                            layOrd.betAmountLeft = getRefundAmount(
                                layOrd.betAmount,
                                layOrd.filledWithAmount,
                                layOrd.odd
                            );
                            if (
                                layOrd.filledWithAmount ==
                                getRewardAmount(layOrd.betAmount, layOrd.odd)
                            ) {
                                layOrd.isFilled = true;
                                counterOdd.currentUnfilledLayBet = counterOdd
                                    .currentUnfilledLayBet +
                                    1 <
                                    counterOdd.layBettorOrders.length
                                    ? counterOdd.currentUnfilledLayBet + 1
                                    : counterOdd.currentUnfilledLayBet;
                            }
                            ord.betAmountLeft = 0;
                            EscrowContract.increaseReturnAmount(
                                layOrd.user,
                                currentOrderAmountLeft,
                                layOrd.orderID
                            );
                        }
                    }
                    emit orderFilled(
                        _eventID,
                        orderCount,
                        currentOrderAmountLeft - ord.betAmountLeft
                    );
                    emit orderFilled(
                        _eventID,
                        layOrd.orderID,
                        layOrdAmountLeft - layOrd.betAmountLeft
                    );
                }
            }
            if (!ord.isFilled) {
                ord.index = odd.backBettorOrders.length;
                odd.backBettorOrders.push(orderCount);
                uint256 orderID = odd.backBettorOrders[
                    odd.currentUnfilledBackBet
                ];
                if (order[_eventID][orderID].isFilled) {
                    odd.currentUnfilledBackBet = odd.currentUnfilledBackBet +
                        1 <
                        odd.backBettorOrders.length
                        ? odd.currentUnfilledBackBet + 1
                        : odd.currentUnfilledBackBet;
                }
            }
        } else if (_betType == 1) {
            // odd.layBettorOrders.push(orderCount);
            // uint256 counter = counterOdd.currentUnfilledBackBet;
            for (
                uint256 i = counterOdd.currentUnfilledBackBet;
                i < counterOdd.backBettorOrders.length;
                i++
            ) {
                Library.Order storage backOrd = order[_eventID][
                    counterOdd.backBettorOrders[i]
                ];
                if (
                    (!backOrd.isFilled && !ord.isFilled) &&
                    (backOrd.betAmount > 0 && ord.betAmount > 0) &&
                    (!backOrd.isCancelled)
                ) {
                    if (_eventStartDate < block.timestamp) {
                        if (
                            backOrd.index == counterOdd.currentUnfilledBackBet
                        ) {
                            counterOdd.currentUnfilledBackBet = counterOdd
                                .currentUnfilledBackBet +
                                1 <
                                counterOdd.layBettorOrders.length
                                ? counterOdd.currentUnfilledBackBet + 1
                                : counterOdd.currentUnfilledBackBet;
                        }
                        continue;
                    }
                    uint256 backOrdAmountLeft = backOrd.betAmountLeft;
                    uint256 currentOrderAmountLeft = ord.betAmountLeft;
                    uint256 backOrdRewardAmount = getRewardAmount(
                        backOrdAmountLeft,
                        backOrd.odd
                    );
                    uint256 currentOrderRewardAmount = getRewardAmount(
                        currentOrderAmountLeft,
                        odd.odd
                    );
                    if (backOrdAmountLeft > currentOrderRewardAmount) {
                        ord.filledWithAmount += currentOrderRewardAmount;

                        ord.betAmountLeft = 0;
                        backOrd.betAmountLeft = getRefundAmount(
                            backOrd.betAmount,
                            backOrd.filledWithAmount,
                            backOrd.odd
                        );
                        odd.currentUnfilledLayBet = odd.currentUnfilledLayBet +
                            1 <
                            odd.layBettorOrders.length
                            ? odd.currentUnfilledLayBet + 1
                            : odd.currentUnfilledLayBet;
                        // odd.currentUnfilledLayBet += 1;
                        ord.isFilled = true;
                        if (currentOrderAmountLeft > backOrdRewardAmount) {
                            backOrd.filledWithAmount += backOrdRewardAmount;
                            backOrd.betAmountLeft = 0;
                            counterOdd.currentUnfilledBackBet = counterOdd
                                .currentUnfilledBackBet +
                                1 <
                                counterOdd.backBettorOrders.length
                                ? counterOdd.currentUnfilledBackBet + 1
                                : counterOdd.currentUnfilledBackBet;
                            backOrd.isFilled = true;
                            ord.betAmountLeft = getRefundAmount(
                                ord.betAmount,
                                ord.filledWithAmount,
                                odd.odd
                            );
                            EscrowContract.increaseReturnAmount(
                                backOrd.user,
                                backOrdRewardAmount,
                                backOrd.orderID
                            );
                        } else if (
                            currentOrderAmountLeft <= backOrdRewardAmount
                        ) {
                            backOrd.filledWithAmount += currentOrderAmountLeft;
                            backOrd.betAmountLeft = getRefundAmount(
                                backOrd.betAmount,
                                backOrd.filledWithAmount,
                                backOrd.odd
                            );
                            if (
                                backOrd.filledWithAmount ==
                                getRewardAmount(backOrd.betAmount, backOrd.odd)
                            ) {
                                backOrd.isFilled = true;
                                counterOdd.currentUnfilledBackBet = counterOdd
                                    .currentUnfilledBackBet +
                                    1 <
                                    counterOdd.backBettorOrders.length
                                    ? counterOdd.currentUnfilledBackBet + 1
                                    : counterOdd.currentUnfilledBackBet;
                            }
                            ord.betAmountLeft = 0;
                            EscrowContract.increaseReturnAmount(
                                backOrd.user,
                                currentOrderAmountLeft,
                                backOrd.orderID
                            );
                        }
                    } else if (backOrdAmountLeft <= currentOrderRewardAmount) {
                        ord.filledWithAmount += backOrdAmountLeft;
                        ord.betAmountLeft = getRefundAmount(
                            ord.betAmount,
                            ord.filledWithAmount,
                            odd.odd
                        );
                        backOrd.betAmountLeft = 0;
                        if (
                            ord.filledWithAmount ==
                            getRewardAmount(ord.betAmount, odd.odd)
                        ) {
                            ord.isFilled = true;
                            // odd.currentUnfilledLayBet += 1;
                            odd.currentUnfilledLayBet = odd
                                .currentUnfilledLayBet +
                                1 <
                                odd.layBettorOrders.length
                                ? odd.currentUnfilledLayBet + 1
                                : odd.currentUnfilledLayBet;
                        }

                        if (currentOrderAmountLeft > backOrdRewardAmount) {
                            backOrd.filledWithAmount += backOrdRewardAmount;
                            backOrd.betAmountLeft = 0;
                            counterOdd.currentUnfilledBackBet = counterOdd
                                .currentUnfilledBackBet +
                                1 <
                                counterOdd.backBettorOrders.length
                                ? counterOdd.currentUnfilledBackBet + 1
                                : counterOdd.currentUnfilledBackBet;
                            backOrd.isFilled = true;
                            ord.betAmountLeft = getRefundAmount(
                                ord.betAmount,
                                ord.filledWithAmount,
                                odd.odd
                            );
                            EscrowContract.increaseReturnAmount(
                                backOrd.user,
                                backOrdRewardAmount,
                                backOrd.orderID
                            );
                        } else if (
                            currentOrderAmountLeft <= backOrdRewardAmount
                        ) {
                            backOrd.filledWithAmount += currentOrderAmountLeft;
                            backOrd.betAmountLeft = getRefundAmount(
                                backOrd.betAmount,
                                backOrd.filledWithAmount,
                                backOrd.odd
                            );
                            if (
                                backOrd.filledWithAmount ==
                                getRewardAmount(backOrd.betAmount, backOrd.odd)
                            ) {
                                backOrd.isFilled = true;
                                counterOdd.currentUnfilledBackBet = counterOdd
                                    .currentUnfilledBackBet +
                                    1 <
                                    counterOdd.backBettorOrders.length
                                    ? counterOdd.currentUnfilledBackBet + 1
                                    : counterOdd.currentUnfilledBackBet;
                            }
                            ord.betAmountLeft = 0;
                            EscrowContract.increaseReturnAmount(
                                backOrd.user,
                                currentOrderAmountLeft,
                                backOrd.orderID
                            );
                        }
                    }
                    emit orderFilled(
                        _eventID,
                        orderCount,
                        currentOrderAmountLeft - ord.betAmountLeft
                    );
                    emit orderFilled(
                        _eventID,
                        backOrd.orderID,
                        backOrdAmountLeft - backOrd.betAmountLeft
                    );
                }
            }
            if (!ord.isFilled) {
                ord.index = odd.layBettorOrders.length;
                odd.layBettorOrders.push(orderCount);
                uint256 orderID = odd.layBettorOrders[
                    odd.currentUnfilledLayBet
                ];
                if (order[_eventID][orderID].isFilled) {
                    odd.currentUnfilledLayBet = odd.currentUnfilledLayBet + 1 <
                        odd.layBettorOrders.length
                        ? odd.currentUnfilledLayBet + 1
                        : odd.currentUnfilledLayBet;
                }
            }
        }

        odd.totalBackBetAmount = _betType == 0
            ? odd.totalBackBetAmount + _betAmount
            : odd.totalBackBetAmount;
        odd.totalLayBetAmount = _betType == 1
            ? odd.totalLayBetAmount + _betAmount
            : odd.totalLayBetAmount;
        odd.totalBackBettors = _betType == 0
            ? odd.totalBackBettors + 1
            : odd.totalBackBettors;
        odd.totalLayBettors = _betType == 1
            ? odd.totalLayBettors + 1
            : odd.totalLayBettors;
        ord.betType = _betType == 0
            ? Library.BetType.BACK
            : Library.BetType.LAY;
        ord.eventID = _eventID;
        ord.orderID = orderCount;
        ord.betAmount = _betAmount;
        ord.oddID = odd.oddID;
        ord.odd = odd.odd;
        ord.date = block.timestamp;
        ord.user = msg.sender;
        orderCount++;
        emit orderCreated(
            ord.orderID,
            ord.eventID,
            ord.oddID,
            odd.odd,
            ord.betAmount,
            block.timestamp,
            msg.sender
        );
        EscrowContract.increaseBetAmount(
            msg.sender,
            ord.betAmount,
            ord.orderID
        );
        if (ord.filledWithAmount > 0)
            EscrowContract.increaseReturnAmount(
                msg.sender,
                ord.filledWithAmount,
                ord.orderID
            );
    }

    /**
     *topic: `function claimRefund`
     *
     *@dev Allow to claim refund
     *
     */
    function claimRefund(string memory _eventID, uint256 _orderID) public {
        require(
            order[_eventID][_orderID].user == msg.sender,
            "Refund: Not the order creator"
        );
        Library.Order storage ord = order[_eventID][_orderID];
        Library.Odd storage odd = oddDetail[_eventID][ord.oddID];
        uint256 refundAmount;
        // if (eventDetails[_eventID].cancelled) {
        //     // uint256 returnAmount = ord.filledWithAmount;
        //     refundAmount = ord.betAmount;
        //     ord.betAmount = 0;
        //     ord.filledWithAmount = 0;
        //     ord.betAmountLeft = 0;
        //     EscrowContract.decreaseReturnAmount(
        //         msg.sender,
        //         refundAmount,
        //         ord.orderID
        //     );
        // } else {
        refundAmount = ord.betAmountLeft;
        ord.betAmountLeft = 0;
        ord.isFilled = true;
        if (ord.filledWithAmount == 0) {
            ord.isCancelled = true;
        }
        // }
        if (ord.betType == Library.BetType.BACK) {
            odd.totalBackBetAmount -= refundAmount;
            if (ord.index == odd.currentUnfilledBackBet) {
                odd.currentUnfilledBackBet = odd.currentUnfilledBackBet + 1 <
                    odd.backBettorOrders.length
                    ? odd.currentUnfilledBackBet + 1
                    : odd.currentUnfilledBackBet;
            }
        } else {
            odd.totalLayBetAmount -= refundAmount;
            if (ord.index == odd.currentUnfilledLayBet) {
                odd.currentUnfilledLayBet = odd.currentUnfilledLayBet + 1 <
                    odd.layBettorOrders.length
                    ? odd.currentUnfilledLayBet + 1
                    : odd.currentUnfilledLayBet;
            }
        }
        emit refundClaimed(
            _eventID,
            _orderID,
            refundAmount,
            block.timestamp,
            msg.sender
        );
        EscrowContract.decreaseBetAmount(msg.sender, refundAmount, _orderID);
    }

    /**
     *topic: `function claimReward`
     *
     *@dev Allow to claim reward
     *
     */
    function claimReward(
        bytes calldata _signature,
        string memory _eventID,
        string memory _result,
        uint256 _orderID,
        bool _isClosed
    ) public {
        bytes32 message = keccak256(abi.encodePacked(_eventID, _result));
        require(ECDSA.recover(message, _signature) == owner(), "Invalid signature");
        require(
            _isClosed,
            "Reward: Result hasn't been announced yet"
        );
        require(
            checkWinner(_eventID, _result, _orderID),
            "Reward: You haven't won your bet"
        );
        require(
            order[_eventID][_orderID].filledWithAmount > 0,
            "Reward: Insufficient amount"
        );
        require(
            order[_eventID][_orderID].user == msg.sender,
            "Reward: Not the order creator"
        );
        uint256 rewardAmount = order[_eventID][_orderID].filledWithAmount;
        order[_eventID][_orderID].filledWithAmount = 0;
        emit rewardClaimed(
            _eventID,
            _orderID,
            rewardAmount,
            block.timestamp,
            msg.sender
        );
        EscrowContract.settlementWinOutcome(msg.sender, _orderID);
    }

    /**
     *topic: `function getRefundAmount`
     *
     *@dev Calculate and return the refund amount based on the initial deposit by the user, rewards filled by the couter bets and odd
     *
     */
    function getRefundAmount(
        uint256 _initialDeposit,
        uint256 _counterPartyDeposit,
        uint256 _odd
    ) internal pure returns (uint256 refund) {
        return _initialDeposit - ((_counterPartyDeposit * 1e6) / (_odd - 1e6));
    }

    /**
     *topic: `function getRewardAmount`
     *
     *@dev Calculate and return the reward amount based on the bet amount and odd
     *
     */
    function getRewardAmount(uint256 _betAmount, uint256 _odd)
        internal
        pure
        returns (uint256 reward)
    {
        return (((_betAmount * _odd) / 1e6) - _betAmount);
    }

    /**
     *topic: `function getOddsforOrder`
     *
     *@dev Calculate and return the counter odd needed to fill the given order based on the bet amount and odd
     *
     */
    function getOddsForOrder(uint256 _betAmount, uint256 _odd)
        internal
        pure
        returns (uint256)
    {
        uint256 totalAmount = (_betAmount * _odd) / 1e6;
        uint256 totalRewards = totalAmount - _betAmount;
        return ((totalAmount * 1e6) / totalRewards);
    }

    /**
     *topic: `function checkWinner`
     *
     *@dev Check whether the given order has won the bet based on the `eventID` and `orderID`
     *
     */
    function checkWinner(string memory _eventID, string memory _result, uint256 _orderID)
        public
        view
        returns (bool)
    {
        Library.Order memory ord = order[_eventID][_orderID];
        if (keccak256(abi.encodePacked(ord.betTeamId)) == keccak256(abi.encodePacked(""))) {
            return (ord.betType == Library.BetType.BACK && keccak256(abi.encodePacked(_result)) == keccak256(abi.encodePacked("draw")) || ord.betType == Library.BetType.LAY && keccak256(abi.encodePacked(_result)) != keccak256(abi.encodePacked("draw")));
        } else {
            return (ord.betType == Library.BetType.BACK && keccak256(abi.encodePacked(_result)) == keccak256(abi.encodePacked("won")) || ord.betType == Library.BetType.LAY && keccak256(abi.encodePacked(_result)) == keccak256(abi.encodePacked("lost")));
        }
    }

    // /**
    //  *topic: `function getOrderIDArr`
    //  *
    //  *@dev Return the array of the order IDs and its length stored for the given `oddID` and `betType`
    //  *
    //  */
    // function getOrderIDArr(uint256 _oddID, uint256 _betType)
    //     public
    //     view
    //     returns (uint256[] memory arr, uint256 len)
    // {
    //     Library.Odd memory odd = oddDetail[0][_oddID];
    //     if (_betType == 1) {
    //         return (odd.layBettorOrders, odd.layBettorOrders.length);
    //     } else if (_betType == 0) {
    //         return (odd.layBettorOrders, odd.backBettorOrders.length);
    //     }
    // }
}