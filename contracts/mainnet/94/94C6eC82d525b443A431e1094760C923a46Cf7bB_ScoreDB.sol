// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../interfaces/ScoreDBInterface.sol";
import "../libraries/Structs.sol";
import {AddressHandler} from "../utilities/AddressHandler.sol";
import {IAddressBook} from "../interfaces/IAddressBook.sol";
import {Errors} from "../libraries/Errors.sol";
import {ROLE_PAUSER, ROLE_ADMIN} from "../Globals.sol";

/**
 * @title ScoreDB
 * @author RociFi Labs
 * @notice A contract responsible for fetching scores from off chain and executing lending logic leveraging Openzeppelin for upgradability (UUPS).
 */

contract ScoreDB is Pausable, AddressHandler, ScoreDBInterface {
    struct Config {
        uint256 LTV;
        uint256 LT;
    }
    using ECDSA for bytes32;

    // Mapping TokenId to Score
    mapping(uint256 => Structs.Score) private scoreCache;
    // Stores the address of the private key which signs the scores
    address public ROCI_ADDRESS;

    event ScoreUpdated(uint256 timestamp, uint256 indexed tokenId, uint16 indexed score);
    event RociAddressChanged(uint256 timestamp, address indexed _rociAddress);

    mapping(address => mapping(uint16 => Config)) private _scoreConfigs;

    constructor(address _addressBook) AddressHandler(IAddressBook(_addressBook)) {}

    function updateScore(
        uint256 tokenId,
        uint16 score,
        uint256 timestamp,
        bytes memory sig
    ) public whenNotPaused {
        // Reostruct the score object
        Structs.Score memory thisScore = Structs.Score(tokenId, timestamp, score);
        // Require that signer is ROCI
        require(verify(thisScore, sig), Errors.SCORE_DB_VERIFICATION);
        // Store the score
        scoreCache[thisScore.tokenId] = thisScore;
        // Emit score updated event
        emit ScoreUpdated(block.timestamp, tokenId, score);
    }

    /**
     * @notice returns the score of a tokenId from the cache
     */
    function getScore(uint256 tokenId) public view override returns (Structs.Score memory) {
        return scoreCache[tokenId];
    }

    /**
     * @notice returns true if the _signer is ROCI
     */
    function verify(Structs.Score memory _score, bytes memory _sig) internal view returns (bool) {
        require(
            _score.creditScore != addressBook.notGenerated(),
            Errors.SCORE_DB_SCORE_NOT_GENERATED
        );
        require(
            _score.creditScore != addressBook.generationError(),
            Errors.SCORE_DB_SCORE_GENERATING
        );
        require(
            _score.creditScore < addressBook.maxScore() &&
                _score.creditScore >= addressBook.minScore(),
            Errors.SCORE_DB_UNKNOW_FETCHING_SCORE
        );

        // Recreate msg hash from inputs
        bytes32 objectHash = getObjectHash(_score);
        return objectHash.toEthSignedMessageHash().recover(_sig) == ROCI_ADDRESS;
    }

    /**
     * @notice returns the keccak256 hash of the score object
     */
    function getObjectHash(Structs.Score memory score) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(score.tokenId, score.creditScore, score.timestamp));
    }

    function setRociAddress(address _addr) public onlyRole(ROLE_ADMIN) {
        ROCI_ADDRESS = _addr;
        emit RociAddressChanged(block.timestamp, _addr);
    }

    /**
     * @notice Pauses the whole contract; used as emergency response in case a bug is detected. [OWNER_ONLY]
     */
    function pause() public override onlyRole(ROLE_PAUSER) {
        _pause();
    }

    /**
     * @notice unpauses the contract; resumes functionality. [OWNER_ONLY]
     */
    function unpause() public override onlyRole(ROLE_PAUSER) {
        _unpause();
    }

    /**
     * @dev owner function to set the _LTV mapping
     * matching indexes in the array are mapped together,
     * EX.
     * _tokens[2] = 0xabcdef
     * _scores[2] = 3
     * _LTVs[2] = 120%
     * _LVs[2] = 100%
     * will result in a loan with token 0xabcdef at a score of 2 to have a 120% LTV and 100% LV
     */
    function setConfig(
        address[] memory _tokens,
        uint16[] memory _scores,
        uint256[] memory _LTVs,
        uint256[] memory _LTs
    ) external onlyRole(ROLE_ADMIN) {
        require(
            _tokens.length == _scores.length &&
                _scores.length == _LTVs.length &&
                _LTVs.length == _LTs.length,
            Errors.SCORE_DB_EQUAL_LENGTH
        );

        for (uint256 i = 0; i < _tokens.length; i++) {
            _scoreConfigs[_tokens[i]][_scores[i]] = Config(_LTVs[i], _LTs[i]);
        }
    }

    /**
     * @dev LTV getter
     */
    function LTV(address _token, uint16 _score) external view override returns (uint256) {
        return (_scoreConfigs[_token][_score].LTV);
    }

    /**
     * @dev LV getter
     */

    function LT(address _token, uint16 _score) external view override returns (uint256) {
        return (_scoreConfigs[_token][_score].LT);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libraries/Structs.sol";

/**
 * @title ScoreDBInterface
 * @author RociFI Labs
 * @notice Interface for the ScoreDB contract.
 **/

interface ScoreDBInterface {
    // Returns the current scores for the token from the on-chain storage.
    function getScore(uint256 tokenId) external view returns (Structs.Score memory);

    // Called by the lending contract, initiates logic to update score and fulfill loan.
    function pause() external;

    // UnPauses the contract [OWNER]
    function unpause() external;

    function LTV(address _token, uint16 _score) external view returns (uint256);

    function LT(address _token, uint16 _score) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Structs {
    struct Score {
        uint256 tokenId;
        uint256 timestamp;
        uint16 creditScore;
    }

    /**
        * @param _amount to borrow
        * @param _duration of loan in seconds
        * @param _NFCSID is the user's NFCS NFT ID from Roci's Credit scoring system
        * @param _collateralAmount is the amount of collateral to send in
        * @param _collateral is the ERC20 address of the collateral
        * @param _hash is the hash of this address and the loan ID. See Bonds.sol for more info on this @newLoan()
        * @param _signature is the signature of the data hashed for hash
    */
    struct BorrowArgs{
        uint256 _amount;
        uint256 _NFCSID;
        uint256 _collateralAmount;
        address _collateral;
        bytes32 _hash;
        bytes _signature;
    }

    /// @notice collateral info is stored in a struct/mapping pair
    struct collateral {
        uint256 creationTimestamp;
        address ERC20Contract;
        uint256 amount;
    }

    // Share struct that decides the share of each address
    struct Share{
        address payee;
        uint share;
    }
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {IAddressBook} from "../interfaces/IAddressBook.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AddressHandler {
    IAddressBook public addressBook;

    constructor(IAddressBook _addressBook) {
        addressBook = _addressBook;
    }

    modifier onlyRole(uint256 _role) {
        require(msg.sender == lookup(_role), addressBook.roleLookupErrorMessage(_role));

        _;
    }

    function lookup(uint256 _role) internal view returns (address contractAddress) {
        contractAddress = addressBook.addressList(_role);

        require(contractAddress != address(0), addressBook.roleLookupErrorMessage(_role));
    }
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IAddressBook{
    function addressList(uint role) external view returns (address);
    function setAddressToRole(uint role, address newAddress) external;
    function roleLookupErrorMessage(uint role) external view returns(string memory);

    function dailyLimit() external  view returns (uint128);
    function globalLimit() external view returns (uint128);
    function setDailyLimit(uint128 newLimit) external;
    function setGlobalLimit(uint128 newLimit) external;
    function getMaturityDate() external view returns (uint256);
    function setLoanDuration(uint256 _newLoanDuration) external;

    function userDailyLimit() external  view returns (uint128);
    function userGlobalLimit() external view returns (uint128);
    function setUserDailyLimit(uint128 newLimit) external;
    function setUserGlobalLimit(uint128 newLimit) external;

    function globalNFCSLimit(uint _nfcsId) external view  returns (uint128);
    function setGlobalNFCSLimit(uint _nfcsId, uint128 newLimit) external;

    function latePenalty() external  view returns (uint);
    function scoreValidityPeriod() external view returns (uint);
    function setLatePenalty(uint newPenalty) external;
    function setScoreValidityPeriod(uint newValidityPeriod) external;

    function minScore() external  view returns (uint16);
    function maxScore() external view returns (uint16);
    function setMinScore(uint16 newScore) external;
    function setMaxScore(uint16 newScore) external;

    function notGenerated() external  view returns (uint16);
    function generationError() external view returns (uint16);
    function setNotGenerated(uint16 newValue) external;
    function setGenerationError(uint16 newValue) external;

    function penaltyAPYMultiplier() external  view returns (uint8);
    function gracePeriod() external view returns (uint128);
    function setPenaltyAPYMultiplier(uint8 newMultiplier) external;
    function setGracePeriod(uint128 newPeriod) external;

    function defaultPoolDailyLimit() external  view returns (uint128);
    function defaultPoolGlobalLimit() external view returns (uint);
    function setDefaultPoolDailyLimit(uint128 newLimit) external;
    function setDefaultPoolGlobalLimit(uint newLimit) external;

    function poolDailyLimit(address pool) external  view returns (uint128);
    function poolGlobalLimit(address pool) external view returns (uint);
    function setPoolDailyLimit(address pool,uint128 newLimit) external;
    function setPoolGlobalLimit(address pool,uint newLimit) external;

    function limitResetTimestamp() external view returns (uint128);
    function updateLimitResetTimestamp() external;
    function setLimitResetTimestamp(uint128 newTimestamp) external;
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author RociFi Labs
 * @notice Defines the error messages emitted by the different contracts of the RociFi protocol
 * @dev Error messages prefix glossary:
 *  - NFCS = NFCS
 *  - BONDS = Bonds
 *  - INVESTOR = Investor
 *  - POOL_INVESTOR = PoolInvestor
 *  - SCORE_DB = ScoreConfigs, ScoreDB
 *  - PAYMENT = ERC20CollateralPayment, ERC20PaymentStandard, RociPayment
 *  - PRICE_FEED = PriceFeed
 *  - REVENUE = PaymentSplitter, RevenueManager
 *  - LOAN = Loan
 *  - VERSION = Version
 */
library Errors {
    string public constant NFCS_TOKEN_MINTED = "0"; //  Token already minted
    string public constant NFCS_TOKEN_NOT_MINTED = "1"; //  No token minted for address
    string public constant NFCS_ADDRESS_BUNDLED = "2"; // Address already bundled
    string public constant NFCS_WALLET_VERIFICATION_FAILED = "3"; //  Wallet verification failed
    string public constant NFCS_NONEXISTENT_TOKEN = "4"; // Nonexistent NFCS token
    string public constant NFCS_TOKEN_HAS_BUNDLE = "5"; //  Token already has an associated bundle
    string public constant NFCS_TOKEN_HAS_NOT_BUNDLE = "6"; //  Token does not have an associated bundle

    string public constant BONDS_HASH_AND_ENCODING = "100"; //  Hash of data signed must be the paymentContractAddress and id encoded in that order
    string public constant BONDS_BORROWER_SIGNATURE = "101"; // Data provided must be signed by the borrower
    string public constant BONDS_NOT_STACKING = "102"; //  Not staking any NFTs
    string public constant BONDS_NOT_STACKING_INDEX = "103"; //  Not staking any tokens at this index
    string public constant BONDS_DELETE_HEAD = "104"; // Cannot delete the head

    string public constant INVESTOR_ISSUE_BONDS = "200"; //  Issue minting bonds
    string public constant INVESTOR_INSUFFICIENT_AMOUNT = "201"; //  Cannot borrow an amount of 0
    string public constant INVESTOR_BORROW_WITH_ANOTHER_SCORE = "202"; //  Cannot borrow if there is active loans with different score or pool does not support the score

    string public constant POOL_INVESTOR_INTEREST_RATE = "300"; // Interest rate has to be greater than zero
    string public constant POOL_INVESTOR_ZERO_POOL_VALUE = "301"; // Pool value is zero
    string public constant POOL_INVESTOR_ZERO_TOTAL_SUPPLY = "302"; // Total supply is zero
    string public constant POOL_INVESTOR_BONDS_LOST = "303"; // Bonds were lost in unstaking
    string public constant POOL_INVESTOR_NOT_ENOUGH_FUNDS = "304"; // Not enough funds to fulfill the loan
    string public constant POOL_INVESTOR_DAILY_LIMIT = "305"; // Exceeds daily deposits limit
    string public constant POOL_INVESTOR_GLOBAL_LIMIT = "306"; // Exceeds total deposits limit

    string public constant MANAGER_COLLATERAL_NOT_ACCEPTED = "400"; // Collateral is not accepted
    string public constant MANAGER_COLLATERAL_INCREASE = "401"; // When increasing collateral, the same ERC20 address should be used
    string public constant MANAGER_ZERO_WITHDRAW = "402"; // Cannot withdrawal zero
    string public constant MANAGER_EXCEEDING_WITHDRAW = "403"; // Requested withdrawal amount is too large

    string public constant SCORE_DB_EQUAL_LENGTH = "501"; // Arrays must be of equal length
    string public constant SCORE_DB_VERIFICATION = "502"; // Unverified score
    string public constant SCORE_DB_SCORE_NOT_GENERATED = "503"; // Score not yet generated.
    string public constant SCORE_DB_SCORE_GENERATING = "504"; // Error generating score.
    string public constant SCORE_DB_UNKNOW_FETCHING_SCORE = "505"; //  Unknown error fetching score.

    string public constant PAYMENT_NFCS_OUTDATED = "600"; // Outdated NFCS score outdated
    string public constant PAYMENT_ZERO_LTV = "601"; // LTV cannot be zero
    string public constant PAYMENT_NOT_ENOUGH_COLLATERAL = "602"; // Not enough collateral to issue a loan
    string public constant PAYMENT_NO_BONDS = "603"; // There is no bonds to liquidate a loan
    string public constant PAYMENT_FULFILLED = "604"; // Contract is paid off
    string public constant PAYMENT_NFCS_OWNERSHIP = "605"; // NFCS ID must belong to the borrower
    string public constant PAYMENT_NON_ISSUED_LOAN = "606"; // Loan has not been issued
    string public constant PAYMENT_WITHDRAWAL_COLLECTION = "607"; // There are not enough payments available for collection
    string public constant PAYMENT_LOAN_NOT_DELINQUENT = "608"; // Loan not delinquent
    string public constant PAYMENT_AMOUNT_TOO_LARGE = "609"; // Payment amount is too large
    string public constant PAYMENT_CLAIM_COLLATERAL = "610"; // Cannot claim collateral if this collateral is necessary for any non Closed/Liquidated loan's delinquency statu

    string public constant PRICE_FEED_TOKEN_NOT_SUPPORTED = "700"; // Token is not supported
    string public constant PRICE_FEED_TOKEN_BELOW_ZERO = "701"; // Token below zero price

    string public constant REVENUE_ADDRESS_TO_SHARE = "800"; // Non-equal length of addresses and shares
    string public constant REVENUE_UNIQUE_INDEXES = "801"; // Indexes in an array must not be duplicate
    string public constant REVENUE_FAILED_ETHER_TX = "802"; // Failed to send Ether
    string public constant REVENUE_UNVERIFIED_INVESTOR = "803"; // Only verified investors may request funds or make a payment
    string public constant REVENUE_NOT_ENOUGH_FUNDS = "804"; // Not enough funds to complete this request

    string public constant LOAN_MIN_PAYMENT = "900"; // Minimal payment should be made
    string public constant LOAN_DAILY_LIMIT = "901"; // Exceeds daily borrow limit
    string public constant LOAN_DAILY_LIMIT_USER = "902"; // Exceeds user daily borrow limit
    string public constant LOAN_TOTAL_LIMIT_USER = "903"; // Exceeds user total borrow limit
    string public constant LOAN_TOTAL_LIMIT = "904"; // Exceeds total borrow limit
    string public constant LOAN_CONFIGURATION = "905"; // Loan that is already issued, or not configured cannot be issued
    string public constant LOAN_TOTAL_LIMIT_NFCS = "906"; // Exceeds total nfcs borrow limit
    string public constant LOAN_DAILY_LIMIT_NFCS = "907"; // Exceeds daily nfcs borrow limit

    string public constant VERSION = "1000"; // Incorrect version of contract

    string public constant ADDRESS_BOOK_SET_MIN_SCORE = "1100"; // New min score must be less then maxScore
    string public constant ADDRESS_BOOK_SET_MAX_SCORE = "1101"; // New max score must be more then minScore

    string public constant ADDRESS_HANDLER_MISSING_ROLE_TOKEN = "1200"; // Lookup failed for role Token
    string public constant ADDRESS_HANDLER_MISSING_ROLE_BONDS = "1201"; // Lookup failed for role Bonds
    string public constant ADDRESS_HANDLER_MISSING_ROLE_INVESTOR = "1202"; // Lookup failed for role Investor
    string public constant ADDRESS_HANDLER_MISSING_ROLE_PAYMENT_CONTRACT = "1203"; // Lookup failed for role Payment Contract
    string public constant ADDRESS_HANDLER_MISSING_ROLE_REV_MANAGER = "1204"; // Lookup failed for role Revenue Manager
    string public constant ADDRESS_HANDLER_MISSING_ROLE_COLLATERAL_MANAGER = "1205"; // Lookup failed for role Collateral Manager
    string public constant ADDRESS_HANDLER_MISSING_ROLE_PRICE_FEED = "1206"; // Lookup failed for role Price Feed
    string public constant ADDRESS_HANDLER_MISSING_ROLE_ORACLE = "1207"; // Lookup failed for role Oracle
    string public constant ADDRESS_HANDLER_MISSING_ROLE_ADMIN = "1208"; // Lookup failed for role Admin
    string public constant ADDRESS_HANDLER_MISSING_ROLE_PAUSER = "1209"; // Lookup failed for role Pauser
    string public constant ADDRESS_HANDLER_MISSING_ROLE_LIQUIDATOR = "1210"; // Lookup failed for role Liquidator
    string public constant ADDRESS_HANDLER_MISSING_ROLE_COLLECTOR = "1211"; // Lookup failed for role Collector
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.4;
uint256 constant ONE_HUNDRED_PERCENT = 100 ether; // NOTE This CAN NOT exceed 2^256/2 -1 as type casting to int occurs

uint256 constant ONE_YEAR = 31556926;
uint256 constant ONE_DAY = ONE_HOUR * 24;
uint256 constant ONE_HOUR = 60 * 60;

uint256 constant APY_CONST = 3000000000 gwei;

uint8 constant CONTRACT_DECIMALS = 18;

address constant DEAD = 0x000000000000000000000000000000000000dEaD;

uint256 constant ROLE_TOKEN = 0;
uint256 constant ROLE_BONDS = 1;
uint256 constant ROLE_PAYMENT_CONTRACT = 2;
uint256 constant ROLE_REV_MANAGER = 3;
uint256 constant ROLE_NFCS = 4;
uint256 constant ROLE_COLLATERAL_MANAGER = 5;
uint256 constant ROLE_PRICE_FEED = 6;
uint256 constant ROLE_ORACLE = 7;
uint256 constant ROLE_ADMIN = 8;
uint256 constant ROLE_PAUSER = 9;
uint256 constant ROLE_LIQUIDATOR = 10;
uint256 constant ROLE_COLLECTOR = 11;

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