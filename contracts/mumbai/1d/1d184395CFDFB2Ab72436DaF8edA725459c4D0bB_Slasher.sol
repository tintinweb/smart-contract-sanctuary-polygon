// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import '../interfaces/ISlasher.sol';

/// @dev Slasher contract
/// @author Alexandas
contract Slasher is ISlasher, OwnableUpgradeable {

	/// @dev governance address
	address public governance;

	/// @dev return `Stake` contract address
	IStake public override stake;

	/// @dev return `MajorCandidates` contract address
	IMajorCandidates public override majorCandidates;

	/// @dev return default slash amount
	uint256 public override defaultSlashAmount;

	/// @dev return public notice period
	uint256 public override publicNoticePeriod;

	/// @dev return current slash nonce
	uint256 public override nonce;

	/// @dev return max coefficient
	uint64 public override MAXCOEF;

	/// @dev return drafter slash reward coefficient
	uint64 public override drafterCoef;

	/// @dev return validator slash reward coefficient
	uint64 public override validatorCoef;

	/// @dev return executor slash reward coefficient
	uint64 public override executorCoef;

	mapping(uint256 => Types.SlashInfo) internal slashes;

	mapping(address => uint256) internal nonces;

	modifier onlyGovernance() {
		require(msg.sender == governance, 'Slasher: caller must be the Governace');
		_;
	}

	/// @dev proxy initialize function
	/// @param newOwner contract owner
	/// @param _governance governance address
	/// @param _stake `Stake` contract
	/// @param _majorCandidates `MajorCandidates` contract
	/// @param _defaultSlashAmount default slash amount
	/// @param _publicNoticePeriod public notice period
	/// @param maxCoef max coefficient
	/// @param _drafterCoef drafter slash reward coefficient
	/// @param _validatorCoef validator slash reward coefficient
	/// @param _executorCoef executor slash reward coefficient
	function initialize(
		address newOwner,
		address _governance,
		IStake _stake,
		IMajorCandidates _majorCandidates,
		uint256 _defaultSlashAmount,
		uint256 _publicNoticePeriod,
		uint64 maxCoef,
		uint64 _drafterCoef,
		uint64 _validatorCoef,
		uint64 _executorCoef
	) external initializer {
		_transferOwnership(newOwner);
		_setGovernance(_governance);
		_setStake(_stake);
		_setMajorCandidates(_majorCandidates);
		_setDefaultSlashAmount(_defaultSlashAmount);
		_setPublicNoticePeriod(_publicNoticePeriod);
		_setMaxCoef(maxCoef);
		_setDrafterCoef(_drafterCoef);
		_setValidatorCoef(_validatorCoef);
		_setExecutorCoef(_executorCoef);
		nonce = 1;
	}

	/// @dev draft a slash
	/// @param slashBlock slashed block in posc
	/// @param manifest node manifest
	/// @param accuracy posc accuracy
	/// @param signatures major candidates signatures
	function draft(
		uint64 slashBlock,
		string memory manifest,
		uint64 accuracy,
		bytes[] memory signatures
	) external override {
		address candidate = stake.manifestMap(manifest);
		require(candidate != address(0), 'Slasher: nonexistent candidate');
		require(!slashExists(candidate), 'Slasher: candidate is in slash');
		bytes memory raw = abi.encode(nonce, slashBlock, manifest, accuracy);
		bytes memory messsage = abi.encodePacked(bytes('\x19Ethereum Signed Message:\n'), bytes(Strings.toString(raw.length)), raw);
		address[] memory validators = checkNSignatures(keccak256(messsage), signatures);
		stake.draftSlash(candidate, defaultSlashAmount);
		slashes[nonce] = Types.SlashInfo({
			candidate: candidate,
			drafter: msg.sender,
			validators: validators,
			amount: defaultSlashAmount,
			timestamp: block.timestamp,
			status: Types.SlashStatus.Drafted
		});
		nonces[candidate] = nonce;
		emit DraftSlash(nonce, candidate, slashBlock, manifest, accuracy);
		nonce++;
	}

	/// @dev reject a slash
	/// @param manifest node manifest
	function reject(string memory manifest) external override onlyGovernance {
		address candidate = stake.manifestMap(manifest);
		require(candidate != address(0), 'Slasher: nonexistent candidate');
		uint256 _nonce = nonces[candidate];
		require(slashes[_nonce].timestamp > 0, 'Slasher: nonexistent slash');
		require(slashes[_nonce].status == Types.SlashStatus.Drafted, 'Slasher: slash status is not drafted');
		require(block.timestamp <= slashes[_nonce].timestamp + publicNoticePeriod, 'Slasher: slash is not in public notice period');
		slashes[_nonce].status = Types.SlashStatus.Rejected;
		stake.rejectSlash(candidate, slashes[_nonce].amount);
		delete nonces[candidate];
		emit RejectSlash(_nonce);
	}

	/// @dev execute a slash
	/// @param manifest node manifest
	function execute(string memory manifest) external override onlyGovernance {
		address candidate = stake.manifestMap(manifest);
		require(candidate != address(0), 'Slasher: nonexistent candidate');
		uint256 _nonce = nonceOf(candidate);
		require(slashes[_nonce].timestamp > 0, 'Slasher: nonexistent slash');
		require(slashes[_nonce].status == Types.SlashStatus.Drafted, 'Slasher: slash status is not drafted');
		require(block.timestamp > slashes[_nonce].timestamp + publicNoticePeriod, 'Slasher: slash is in public notice period');
		slashes[nonce].status = Types.SlashStatus.Executed;
		uint256 amount = slashes[_nonce].amount;
		address[] memory validators = slashes[_nonce].validators;
		uint256 validatorLen = validators.length;
		address[] memory beneficiaries = new address[](validatorLen + 2);
		uint256[] memory amounts = new uint256[](validatorLen + 2);
		uint256 validatorAmount = (amount * validatorCoef) / MAXCOEF;
		uint256 drafterAmount = (amount * drafterCoef) / MAXCOEF;
		uint256 executorAmount = (amount * executorCoef) / MAXCOEF;
		uint256 burned = amount - drafterAmount - validatorAmount - executorAmount;
		uint256 averageValidatorAmount = validatorAmount / validatorLen;
		for (uint256 i = 0; i < validators.length; i++) {
			beneficiaries[i] = validators[i];
			amounts[i] = averageValidatorAmount;
		}
		beneficiaries[validatorLen] = slashes[_nonce].drafter;
		amounts[validatorLen] = drafterAmount;
		beneficiaries[validatorLen + 1] = msg.sender;
		amounts[validatorLen + 1] = executorAmount;

		stake.executeSlash(candidate, amount, beneficiaries, amounts, burned);
		delete nonces[candidate];

		emit ExecuteSlash(_nonce, msg.sender);
	}

	/// @dev return whether candidate is in slashing
	/// @param candidate candidate address
	/// @return whether candidate is in slashing
	function slashExists(address candidate) public view override returns (bool) {
		return nonces[candidate] > 0;
	}

	/// @dev check whether signatures is valid
	/// @param hash message hash
	/// @param signatures signatures for major candidates
	/// @param signers major candidate signers
	function checkNSignatures(bytes32 hash, bytes[] memory signatures) public view override returns (address[] memory signers) {
		require(signatures.length >= majorCandidates.MAX_MAJOR_CANDIDATES() * 2 / 3, 'Slasher: signature length is not enough');
		signers = new address[](signatures.length);
		for (uint8 i = 0; i < signatures.length; i++) {
			(address recovered, ECDSAUpgradeable.RecoverError err) = ECDSAUpgradeable.tryRecover(hash, signatures[i]);
			require(err == ECDSAUpgradeable.RecoverError.NoError, 'Slasher: invalid signature');
			if (i > 0) {
				require(recovered > signers[i-1], 'Slasher: incorrect signature order');
			}
			require(majorCandidates.isMajor(recovered), 'Slasher: signer is not the major candidate');
			signers[i] = recovered;
		}
	}

	function getSlashAt(uint256 _nonce) public view override returns (Types.SlashInfo memory) {
		return slashes[_nonce];
	}

	function nonceOf(address candidate) public view override returns (uint256) {
		require(slashExists(candidate), 'Slasher: nonexistent slash');
		return nonces[candidate];
	}

	function endOf(uint256 _nonce) public view returns (uint256) {
		require(_nonce > 0 && _nonce < nonce, 'Slasher: invalid nonce');
		return slashes[_nonce].timestamp + publicNoticePeriod;
	}

	/// @dev set drafter slash reward coefficient
	/// @param _drafterCoef drafter slash reward coefficient
	function setDrafterCoef(uint64 _drafterCoef) external override onlyOwner onlyInitializing {
		_setDrafterCoef(_drafterCoef);
	}

	/// @dev set validator slash reward coefficient
	/// @param _validatorCoef validator slash reward coefficient
	function setValidatorCoef(uint64 _validatorCoef) external override onlyOwner onlyInitializing {
		_setValidatorCoef(_validatorCoef);
	}

	/// @dev set executor slash reward coefficient
	/// @param _executorCoef executor slash reward coefficient
	function setExecutorCoef(uint64 _executorCoef) external override onlyOwner onlyInitializing {
		_setExecutorCoef(_executorCoef);
	}

	function _setMaxCoef(uint64 maxCoef) internal {
		MAXCOEF = maxCoef;
		emit MaxCoefUpdated(maxCoef);
	}

	function _setDrafterCoef(uint64 _drafterCoef) internal {
		require(_drafterCoef + validatorCoef + executorCoef <= MAXCOEF, 'Slasher: invalid coefficient');
		drafterCoef = _drafterCoef;
		emit DrafterCoefUpdated(_drafterCoef);
	}

	function _setValidatorCoef(uint64 _validatorCoef) internal {
		require(drafterCoef + _validatorCoef + executorCoef <= MAXCOEF, 'Slasher: invalid coefficient');
		validatorCoef = _validatorCoef;
		emit ValidatorCoefUpdated(_validatorCoef);
	}

	function _setExecutorCoef(uint64 _executorCoef) internal {
		require(drafterCoef + validatorCoef + _executorCoef <= MAXCOEF, 'Slasher: invalid coefficient');
		executorCoef = _executorCoef;
		emit ExecutorCoefUpdated(_executorCoef);
	}

	function _setGovernance(address _governance) internal {
		governance = _governance;
		emit GovernanceUpdated(_governance);
	}

	function _setStake(IStake _stake) internal {
		stake = _stake;
		emit StakeUpdated(_stake);
	}

	function _setMajorCandidates(IMajorCandidates _majorCandidates) internal {
		majorCandidates = _majorCandidates;
		emit MajorCandidatesUpdated(_majorCandidates);
	}

	function _setDefaultSlashAmount(uint256 amount) internal {
		defaultSlashAmount = amount;
		emit DefaultSlashAmountUpdated(amount);
	}

	function _setPublicNoticePeriod(uint256 period) internal {
		publicNoticePeriod = period;
		emit PublicNoticePeriodUpdated(period);
	}

	function changeGovernance(address newGovernance) external onlyGovernance onlyInitializing {
		_setGovernance(newGovernance);
	}
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '../libraries/Types.sol';
import './IMajorCandidates.sol';
import './IStake.sol';

/// @dev Slasher interface
/// @author Alexandas
interface ISlasher {

	/// @dev emit when governance address updated
	/// @param governance governance address
	event GovernanceUpdated(address governance);

	/// @dev emit when `Stake` contract updated
	/// @param stake `Stake` contract 
	event StakeUpdated(IStake stake);

	/// @dev emit when `MajorCandidates` contract updated
	/// @param majorCandidates `MajorCandidates` contract 
	event MajorCandidatesUpdated(IMajorCandidates majorCandidates);

	/// @dev emit when default slash amount updated
	/// @param amount slash amount
	event DefaultSlashAmountUpdated(uint256 amount);

	/// @dev emit when public notice period updated
	/// @param period public notice period
	event PublicNoticePeriodUpdated(uint256 period);

	/// @dev emit when max coefficient updated
	/// @param maxCoef max coefficient
	event MaxCoefUpdated(uint256 maxCoef);

	/// @dev emit when drafter slash reward coefficient updated
	/// @param drafterCoef drafter slash reward coefficient
	event DrafterCoefUpdated(uint64 drafterCoef);

	/// @dev emit when validator slash reward coefficient updated
	/// @param validatorCoef validator slash reward coefficient
	event ValidatorCoefUpdated(uint256 validatorCoef);

	/// @dev emit when executor slash reward coefficient updated
	/// @param executorCoef executor slash reward coefficient
	event ExecutorCoefUpdated(uint256 executorCoef);

	/// @dev emit when slash drafted
	/// @param nonce slash number
	/// @param candidate candidate address
	/// @param slashBlock slashed block in posc
	/// @param manifest node manifest
	/// @param accuracy posc accuracy
	event DraftSlash(uint256 nonce, address candidate, uint64 slashBlock, string manifest, uint64 accuracy);

	/// @dev emit when slash drafted
	/// @param nonce slash number
	event RejectSlash(uint256 nonce);

	/// @dev emit when slash drafted
	/// @param nonce slash number
	event ExecuteSlash(uint256 nonce, address executor);

	/// @dev return `Stake` contract address
	function stake() external view returns(IStake);

	/// @dev return `MajorCandidates` contract address
	function majorCandidates() external view returns(IMajorCandidates);

	/// @dev return default slash amount
	function defaultSlashAmount() external view returns(uint256);

	/// @dev return public notice period
	function publicNoticePeriod() external view returns(uint256);

	/// @dev return current slash nonce
	function nonce() external view returns(uint256);

	/// @dev return max coefficient
	function MAXCOEF() external view returns(uint64);

	/// @dev return drafter slash reward coefficient
	function drafterCoef() external view returns(uint64);

	/// @dev return validator slash reward coefficient
	function validatorCoef() external view returns(uint64);

	/// @dev return executor slash reward coefficient
	function executorCoef() external view returns(uint64);

	/// @dev return slash information at a specific nonce
	/// @param _nonce nonce number
	/// @return slash information
	function getSlashAt(uint256 _nonce) external view returns(Types.SlashInfo memory);

	/// @dev return nonce given a candidate if the candidate is in slashing
	/// @param candidate candidate address
	/// @return nonce number
	function nonceOf(address candidate) external view returns(uint256);

	/// @dev set drafter slash reward coefficient
	/// @param _drafterCoef drafter slash reward coefficient
	function setDrafterCoef(uint64 _drafterCoef) external;

	/// @dev set validator slash reward coefficient
	/// @param _validatorCoef validator slash reward coefficient
	function setValidatorCoef(uint64 _validatorCoef) external;

	/// @dev set executor slash reward coefficient
	/// @param _executorCoef executor slash reward coefficient
	function setExecutorCoef(uint64 _executorCoef) external;

	/// @dev draft a slash
	/// @param slashBlock slashed block in posc
	/// @param manifest node manifest
	/// @param accuracy posc accuracy
	/// @param signatures major candidates signatures
	function draft(uint64 slashBlock, string memory manifest, uint64 accuracy, bytes[] memory signatures) external;

	/// @dev reject a slash
	/// @param manifest node manifest
	function reject(string memory manifest) external;

	/// @dev execute a slash
	/// @param manifest node manifest
	function execute(string memory manifest) external;

	/// @dev return whether candidate is in slashing
	/// @param candidate candidate address
	/// @return whether candidate is in slashing
	function slashExists(address candidate) external view returns(bool);

	/// @dev check whether signatures is valid
	/// @param hash message hash
	/// @param signatures signatures for major candidates
	/// @param signers major candidate signers
	function checkNSignatures(bytes32 hash, bytes[] memory signatures) external view returns(address[] memory signers);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

library Types {

	enum Grade {
		Null,
		Major,
		Secondary
	}

	struct CandidateApplyInfo {
		bool waitQuit;
		uint256 amount;
		uint256 endTime;
	}

	struct CandidateInfo {
		Grade grade;
		uint256 amount;
		int256 rewardDebt;
		uint256 allocation;
		uint256 locked;
		uint256 slash;
		string manifest;
	}

	struct PoolInfo {
		uint256 accPerShare;
		uint256 lastRewardTime;
		uint256 allocPoint;
	}

	enum SlashStatus {
		Drafted,
		Rejected,
		Executed
	}

	struct SlashInfo {
		address candidate;
		address drafter;
		address[] validators;
		uint256 amount;
		uint256 timestamp;
		SlashStatus status;
	}

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import './IElection.sol';
import './IStake.sol';

/// @dev MajorCandidates interface
/// @author Alexandas
interface IMajorCandidates {

	/// @dev emit when max major candidates changed
	/// @param max max major candidates
	event MaxMajorCandidateUpdated(uint256 max);

	/// @dev emit when `Election` contract changed
	/// @param election `Election` contract address
	event ElectionUpdated(IElection election);

	/// @dev emit when `Stake` contract updated
	/// @param stake `Stake` contract 
	event StakeUpdated(IStake stake);

	/// @dev emit when a candidate insert or update in the sorted list
	/// @param candidate candidate address
	/// @param amount candidate votes
	event UpsetCandidate(address candidate, uint256 amount);

	/// @dev emit when a candidate removed from the sorted list
	/// @param candidate candidate address
	event RemoveCandidate(address candidate);

	/// @dev insert or update a candidate in the sorted list
	/// @param candidate candidate address
	/// @param amount candidate votes
	/// @param anchor anchor candidate address
	/// @param maxSlippage maximum rank change value for the candidate from the anchor candidate
	function upsetCandidateWithAnchor(
		address candidate,
		uint256 amount,
		address anchor,
		uint256 maxSlippage
	) external;

	/// @dev emit removed a candidate from the sorted list
	/// @param candidate candidate address
	function remove(address candidate) external;

	/// @dev return max major candidates
	function MAX_MAJOR_CANDIDATES() external view returns(uint256);

	/// @dev return `Election` contract address
	function election() external view returns(IElection);

	/// @dev return `Stake` contract address
	function stake() external view returns(IStake);

	/// @dev return whether a candidate is existed in the sorted list
	/// @param candidate candidate address
	/// @return whether the candidate is existed in the sorted list
	function exists(address candidate) external view returns (bool);

	/// @dev return whether a candidate is a major candidate
	/// @param candidate candidate address
	/// @return existed the candidate is a major candidate
	function isMajor(address candidate) external view returns(bool existed);

	/// @dev return all major candidates
	/// @return majors all major candidates
	function majorCandidateList() external view returns(address[] memory majors);


}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import './IElection.sol';
import './IMajorCandidates.sol';
import './ISlasher.sol';
import './IPools.sol';
import './ICandidateRegistry.sol';

/// @dev Stake interface
/// @author Alexandas
interface IStake is IPools, ICandidateRegistry {

	/// @dev emit when `Election` contract changed
	/// @param election `Election` contract address
	event ElectionUpdated(IElection election);

	/// @dev emit when `MajorCandidates` contract updated
	/// @param majorCandidates `MajorCandidates` contract 
	event IMajorCandidatesUpdated(IMajorCandidates majorCandidates);

	/// @dev emit when `Slasher` contract updated
	/// @param slasher `Slasher` contract 
	event SlasherUpdated(ISlasher slasher);

	/// @dev emit when minimum stake updated
	/// @param amount minimum stake
	event MinStakeUpdated(uint256 amount);

	/// @dev emit when stake frozen period updated
	/// @param period stake frozen period
	event StakeFrozenPeriodUpdated(uint256 period);

	/// @dev emit when a candidate upgraded
	/// @param candidate candidate address
	/// @param fromGrade from grade
	/// @param toGrade to grade
	event Upgrade(address candidate, Types.Grade fromGrade, Types.Grade toGrade);

	/// @dev emit when a candidate downgraded
	/// @param candidate candidate address
	/// @param fromGrade from grade
	/// @param toGrade to grade
	event Downgrade(address candidate, Types.Grade fromGrade, Types.Grade toGrade);

	/// @dev emit when a candidate staked tokens
	/// @param from token consumer
	/// @param candidate candidate address
	/// @param amount token amount
	event Stake(address from, address candidate, uint256 amount);

	event ApplyWithdrawn(address candidate, uint256 amount);

	event ApplyQuit(address candidate);

	/// @dev emit when a candidate withdraw tokens
	/// @param candidate candidate address
	/// @param to token receiver
	/// @param amount token amount
	event Withdrawn(address candidate, address to, uint256 amount);

	/// @dev emit when a candidate claimed reward
	/// @param candidate candidate address
	/// @param to token receiver
	/// @param amount token amount
	event Claimed(address candidate, address to, uint256 amount);

	/// @dev emit when a candidate allocate reward for the voters
	/// @param candidate candidate address
	/// @param amount token amount
	event VoterAllocated(address candidate, uint256 amount);

	/// @dev emit when the reward for a candidate
	/// @param candidate candidate address
	/// @param amount token amount
	event CandidateAllocated(address candidate, uint256 amount);

	/// @dev emit when the vote reward coefficient updated
	/// @param coef vote reward coefficient
	event VoteRewardCoefUpdated(uint256 coef);

	/// @dev emit when drafted a slash
	/// @param candidate candidate address
	/// @param pendingSlash pending slash amount
	event DraftSlash(address candidate, uint256 pendingSlash);

	/// @dev emit when rejected a slash
	/// @param candidate candidate address
	/// @param pendingSlash pending slash amount
	event RejectSlash(address candidate, uint256 pendingSlash);

	/// @dev emit when executed a slash
	/// @param candidate candidate address
	/// @param pendingSlash pending slash amount
	/// @param beneficiaries slash reward beneficiaries
	/// @param amounts slash reward amounts
	/// @param burned burned amount
	event ExcuteSlash(address candidate, uint256 pendingSlash, address[] beneficiaries, uint256[] amounts, uint256 burned);

	/// @dev return `Election` contract
	function election() external view returns(IElection);

	/// @dev return `MajorCandidates` contract
	function majorCandidates() external view returns(IMajorCandidates);

	/// @dev return `Slasher` contract
	function slasher() external returns(ISlasher);

	/// @dev candidate stake tokens
	/// @param amount token amount
	function stake(uint256 amount) external;

	/// @dev candidate apply to quit
	function applyQuit() external;

	/// @dev register a candidate and stake tokens
	/// @param amount token amount
	/// @param manifest node manifest
	function registerAndStake(uint256 amount, string memory manifest) external;

	/// @dev candidate quit from the protocol
	/// @param to token receiver
	function quit(address to) external;

	/// @dev candidate claim reward from the protocol
	/// @param to token receiver
	function claim(address to) external;

	/// @dev candidate withdraw the tokens and claim reward from the protocol
	/// @param amount token amount
	/// @param to token receiver
	// function withdrawAndClaim(uint256 amount, address to) external;

	/// @dev return pending reward for a specific candidate
	/// @param candidate candidate address
	/// @return pending reward for the candidate
	function pendingReward(address candidate) external view returns (uint256 pending);

	/// @dev set voter slash reward coefficient
	/// @param coef voter reward coefficient
	function setVoteRewardCoef(uint256 coef) external;

	/// @dev set allocate the reward to voters from the candidate
	/// @param candidate candidate address
	function voterAllocate(address candidate) external;

	/// @dev return voter reward coefficient for a specific candidate
	/// @param candidate candidate address
	/// @return coef voter reward coefficient
	function voteRewardCoef(address candidate) external view returns (uint256 coef);

	/// @dev return pending voters allocation for a specific candidate
	/// @param candidate candidate address
	/// @return pending pending voters allocation
	function pendingVoterAllocation(address candidate) external view returns (uint256 pending);

	/// @dev return pending candidate allocation
	/// @param candidate candidate address
	/// @return pending pending candidate allocation
	function pendingCandidateAllocation(address candidate) external view returns (uint256 pending);

	/// @dev upgrade a candidate
	/// @param candidate candidate address
	function upgrade(address candidate) external;

	/// @dev downgrade a candidate
	/// @param candidate candidate address
	function downgrade(address candidate) external;

	/// @dev draft a slash for a candidate
	/// @param candidate candidate address
	/// @param amount slash amount
	function draftSlash(address candidate, uint256 amount) external;

	/// @dev reject a slash for a candidate
	/// @param candidate candidate address
	/// @param pendingSlash real slash amount
	function rejectSlash(address candidate, uint256 pendingSlash) external;

	/// @dev executed a slash for a candiate
	/// @param candidate candidate address
	/// @param slash slash amount
	/// @param beneficiaries slash reward beneficiaries
	/// @param amounts slash reward amounts
	/// @param burned burned amount
	function executeSlash(
		address candidate, 
		uint256 slash,
		address[] memory beneficiaries, 
		uint256[] memory amounts,
		uint256 burned
	) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import './IRewarder.sol';
import './IStake.sol';
import './IMajorCandidates.sol';
import './IERC20.sol';

/// @dev Election contract interface
/// @author Alexandas
interface IElection {

	/// @dev emit when ERC20 token address updated
	/// @param token ERC20 token address
	event TokenUpdated(IERC20 token);

	/// @dev emit when `Rewarder` contract updated
	/// @param rewarder `Rewarder` contract 
	event RewarderUpdated(IRewarder rewarder);

	/// @dev emit when `Stake` contract updated
	/// @param stake `Stake` contract 
	event StakeUpdated(IStake stake);

	/// @dev emit when `MajorCandidates` contract updated
	/// @param majorCandidates `MajorCandidates` contract 
	event MajorCandidatesUpdated(IMajorCandidates majorCandidates);

	/// @dev emit when vote frozen period updated
	/// @param period vote frozen period
	event VoteFrozenPeriodUpdated(uint256 period);

	/// @dev emit when shares updated for a specific candidate
	/// @param candidate candidate address
	event ShareUpdated(address candidate);

	/// @dev emit when voter voted for a candidate
	/// @param candidate candidate address
	/// @param voter voter address
	/// @param amount token amount
	event Vote(address candidate, address voter, uint256 amount);

	/// @dev emit when voter claimed the reward
	/// @param candidate candidate address
	/// @param voter voter address
	/// @param to receiver address
	/// @param amount reward amount
	event Claimed(address candidate, address voter, address to, uint256 amount);

	/// @dev emit when voter apply withdrawn the votes
	/// @param candidate candidate address
	/// @param voter voter address
	/// @param nonce withdraw nonce
	/// @param amount reward amount
	event ApplyWithdrawn(uint256 nonce, address candidate, address voter, uint256 amount);

	/// @dev emit when voter withdrawn the votes
	/// @param nonce withdraw nonce
	/// @param voter voter address
	/// @param to receiver address
	/// @param amount reward amount
	event Withdrawn( uint256 nonce, address voter, address to, uint256 amount);

	/// @dev voter vote a specific candidate
	/// @param candidate candidate address
	/// @param voter voter address
	/// @param amount reward amount
	/// @param anchor anchor candidate address
	/// @param maxSlippage maximum rank change value for the candidate from the anchor candidate
	function vote(
		address candidate,
		address voter,
		uint256 amount,
		address anchor,
		uint256 maxSlippage
	) external;

	/// @dev voter claim reward for a specific candidate
	/// @param candidate candidate address
	/// @param to receiver address
	function claim(address candidate, address to) external;

	/// @dev voter apply withdraw reward for a specific candidate
	/// @param candidate candidate address
	/// @param amount reward amount
	/// @param anchor anchor candidate address
	/// @param maxSlippage maximum rank change value for the candidate from the anchor candidate
	function applyWithdraw(
		address candidate,
		uint256 amount,
		address anchor,
		uint256 maxSlippage
	) external;

	/// @dev voter withdraw votes and reward
	/// @param nonce withdraw nonce
	/// @param to receiver address
	/// @param amount reward amount
	function withdraw(uint256 nonce, address to, uint256 amount) external;

	/// @dev candidate allocate reward for the voters
	/// @param candidate candidate address
	/// @param amount reward amount
	function onAllocate(address candidate, uint256 amount) external;

	/// @dev return ERC20 token address
	function token() external view returns(IERC20);

	/// @dev return `Rewarder` contract address
	function rewarder() external view returns(IRewarder);

	/// @dev return `Stake` contract address
	function stake() external view returns(IStake);

	/// @dev return `MajorCandidates` contract address
	function majorCandidates() external view returns(IMajorCandidates);

	/// @dev return precision for shares
	function ACC_PRECISION() external view returns(uint256);

	/// @dev return votes for a specific candidate
	/// @param candidate candidate address
	/// @return votes for a specific candidate
	function voteSupply(address candidate) external view returns(uint256);

	/// @dev pending reward for a voter given a candidate
	/// @param candidate candidate address
	/// @param voter voter address
	/// @return pending pending reward
	function pendingReward(address candidate, address voter) external view returns (uint256 pending);

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

/// @dev Burnable ERC20 Token interface
/// @author Alexandas
interface IERC20 is IERC20Upgradeable {

	/// @dev burn tokens
	/// @param amount token amount
	function burn(uint256 amount) external;

	/// @dev burn tokens
	/// @param account user address
	/// @param amount token amount
	function burnFrom(address account, uint256 amount) external;

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import './IERC20.sol';

/// @dev Rewarder interface
/// @author Alexandas
interface IRewarder {

	/// @dev emit when ERC20 token address updated
	/// @param token ERC20 token address
	event TokenUpdated(IERC20 token);

	/// @dev emit when auth address updated
	/// @param auth authorized address
	event AuthUpdated(address auth);

	/// @dev emit when reward minted
	/// @param from authorized address
	/// @param to receiver address
	/// @param amount token amount
	event Minted(address from, address to, uint256 amount);

	/// @dev return ERC20 token address
	function token() external view returns(IERC20);

	/// @dev mint reward to receiver
	/// @param to receiver address
	/// @param amount token amount
	function mint(address to, uint256 amount) external;

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '../libraries/Types.sol';

/// @dev Candidate registry interface
/// @author Alexandas
interface ICandidateRegistry {

	/// @dev emit when candidate registered
	/// @param candidate candidate address
	event Register(address candidate);

	/// @dev register a candidate with node manifest
	/// @param manifest node manifest
	function register(string memory manifest) external;

	/// @dev return a candidate
	/// @param candidate candidate address
	/// @return candidate information
	function candidateInfo(address candidate) external view returns(Types.CandidateInfo memory);

	/// @dev return a candidate address for a specific node manifest
	/// @param manifest node manifest
	/// @return candidate address
	function manifestMap(string memory manifest) external view returns(address);

	/// @dev return whether a candidate is registered
	/// @param candidate candidate address
	/// @return whether the candidate is registered
	function isCandidateRegistered(address candidate) external view returns (bool);

	/// @dev return grade of a candidate
	/// @param candidate candidate address
	/// @return candidate grade
	function gradeOf(address candidate) external view returns (Types.Grade);

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import './IERC20.sol';
import './IRewarder.sol';
import '../libraries/Types.sol';

/// @dev Pools interface
/// @author Alexandas
interface IPools {

	/// @dev emit when ERC20 Token contract updated
	/// @param token ERC20 Token contract
	event TokenUpdated(IERC20 token);

	/// @dev emit when `Rewarder` contract updated
	/// @param rewarder `Rewarder` contract 
	event RewarderUpdated(IRewarder rewarder);

	/// @dev emit when `rewardPerSecond` updated
	/// @param rewardPerSecond reward generated for per second
	event RewardPerSecondUpdated(uint256 rewardPerSecond);

	/// @dev emit when shares precision updated
	/// @param precision shares precision
	event PrecisionUpdated(uint256 precision);

	/// @dev emit when max coefficient updated
	/// @param maxCoef max coefficient
	event MaxCoefUpdated(uint256 maxCoef);

	/// @dev emit when add a pool
	/// @param grade pool grade
	event AddPool(Types.Grade grade);

	/// @dev emit when pool updated
	/// @param grade pool grade
	event PoolUpdated(Types.Grade grade);

	/// @dev return ERC20 token address
	function token() external view returns(IERC20);

	/// @dev return `Rewarder` contract address
	function rewarder() external view returns(IRewarder);

	/// @dev return precision for shares
	function ACC_PRECISION() external view returns(uint256);

	/// @dev return max coefficient
	function MAXCOEF() external view returns(uint256);

	/// @dev return total pools allocation points
	function totalAllocPoint() external view returns(uint256);

	/// @dev return reward generated for per second
	function rewardPerSecond() external view returns(uint256);

	/// @dev update a specific pool
	/// @param grade pool grade
	/// @return pool pool info
	function updatePool(Types.Grade grade) external returns (Types.PoolInfo memory pool);

	/// @dev return a specific pool
	/// @param grade pool grade
	/// @return pool pool info
	function poolInfo(Types.Grade grade) external view returns(Types.PoolInfo memory);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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