/**
* ENGA Federation CoreMultisig.
* @author Nikola Madjarevic, Mehdikovic
* Date created: 2022.02.15
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../finance/Vault.sol";
import { Owner } from "../access/MultisigOwner.sol";
import { Utils }  from "../lib/Utils.sol";


abstract contract MemberRegistry is Owner {
    uint256 constant public MAX_UINT = type(uint256).max;

    string constant public ERROR_IS_NOT_A_MEMBER                 = "ERROR_IS_NOT_A_MEMBER";
    string constant public ERROR_INDEX_OUT_OF_RANGE              = "ERROR_INDEX_OUT_OF_RANGE";
    string constant public ERROR_ALREADY_A_MEMEBER_OF_FEDERATION = "ERROR_ALREADY_A_MEMEBER_OF_FEDERATION";
    string constant public ERROR_ONLY_MEMBERS_HAVE_ACCESS        = "ERROR_ONLY_MEMBERS_HAVE_ACCESS";

    /// @notice Event to fire every time someone is added or removed from addr2Member
    event MembershipChanged(address member, bool isMember);

    /// @notice Event to fire every time a member is replaced by another address
    event MembershipSwapped(address from, address to);

    struct Member {
        uint256 index;
        bool isMember;
    }
    
    address[] public members;
    mapping(address => Member) public addr2Member;

    // MODIFIERS

    modifier onlyMember() {
        require(addr2Member[msg.sender].isMember == true, ERROR_ONLY_MEMBERS_HAVE_ACCESS);
        _;
    }

    /* EXTERNAL VIEWS */

    function getNumberOfMembers() external view returns (uint) {
        return members.length;
    }

    function getAllMemberAddresses() external view returns (address[] memory) {
        return members;
    }

    function getMemberInfo(address _member) external view returns (Member memory) {
        require(addr2Member[_member].isMember, ERROR_IS_NOT_A_MEMBER);
        return addr2Member[_member];
    }

    function isMember(address _member) external view returns (bool) {
        return _isMember(_member);
    }

    /* INTERNALS */

    function _removeMember(address _member) internal {
        members[addr2Member[_member].index] = members[members.length - 1];
        members.pop();

        addr2Member[_member].isMember = false;
        addr2Member[_member].index = MAX_UINT;

        emit MembershipChanged(_member, false);
    }

    function _swapMember(address _old, address _new) internal {
        uint256 oldIndex = addr2Member[_old].index;

        addr2Member[_old].isMember = false;
        addr2Member[_old].index = MAX_UINT;

        members[oldIndex] = _new;
        addr2Member[_new].index = oldIndex;
        addr2Member[_new].isMember = true;

        emit MembershipChanged(_old, false);
        emit MembershipChanged(_new, true); // membership is identical
        emit MembershipSwapped(_old, _new);
    }

    function _addMember(address _member) internal {
        addr2Member[_member].index = members.length;
        addr2Member[_member].isMember = true;

        members.push(_member);
        
        emit MembershipChanged(_member, true);
    }

    /* VIEW INTERNALS */

    function _isMember(address _member) internal view returns(bool) {
        return addr2Member[_member].isMember;
    }
}

abstract contract BaseMultisig is MemberRegistry, Vault {
    string constant public ERROR_TRANSACTION_HAS_BEEN_EXECUTED = "ERROR_TRANSACTION_HAS_BEEN_EXECUTED";
    string constant public ERROR_TRANSACTION_HAS_BEEN_CANCELED = "ERROR_TRANSACTION_HAS_BEEN_CANCELED";
    string constant public ERROR_TARGET_IS_NOT_VALID_CONTRACT  = "ERROR_TARGET_IS_NOT_VALID_CONTRACT";
    string constant public ERROR_QUORUM_IS_NOT_REACHED         = "ERROR_QUORUM_IS_NOT_REACHED";
    string constant public ERROR_INVALID_TRANSACTION           = "ERROR_INVALID_TRANSACTION";
    string constant public ERROR_CONFIRMATION_IS_DONE_BEFORE   = "ERROR_CONFIRMATION_IS_DONE_BEFORE";
    
    struct Transaction {
        uint256 id; // Unique id for looking up a transaction
        address target; // the target addresses for calls to be made
        uint256 value; // The value (i.e. msg.value) to be passed to the calls to be made
        string signature; // The function signature to be called
        bytes calldatas; // The calldata to be passed to each call
        bool canceled; // Flag marking whether the transaction has been canceled
        bool executed; // Flag marking whether the transaction has been executed
    }

    uint256 public transactionCount;
    mapping(uint256 => Transaction) public transactions;

    event TransactionCreated(
        uint256 id,
        address indexed sender,
        address indexed target,
        uint256 value,
        string signature,
        bytes calldatas,
        string description
    );
    event TransactionCanceled(uint256 transactionId);
    event TransactionExecuted(
        address indexed target,
        uint256 id,
        uint256 value,
        string signature,
        bytes calldatas,
        bytes returndata
    );
    event TransactionFailed(
        address indexed target,
        uint256 id,
        uint256 value,
        string signature,
        bytes calldatas,
        bytes returndata
    );

    /* EXTERNAL VIEWS */

    function getTransaction(uint256 transactionId) external view returns(Transaction memory) {
        require(transactionId > 0 && transactionId <= transactionCount, ERROR_INVALID_TRANSACTION);
        return transactions[transactionId];
    }

    /* INTERNALS */

    function _createTransaction(
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _calldatas,
        string memory _description
    ) 
        internal 
        returns (uint256)
    {
        transactionCount++;
        Transaction memory newTransaction = Transaction({
            id: transactionCount,
            target: _target,
            value: _value,
            signature: _signature,
            calldatas: _calldatas,
            canceled: false,
            executed: false
        });
        transactions[transactionCount] = newTransaction;

        emit TransactionCreated(
            transactionCount,
            msg.sender,
            _target,
            _value,
            _signature,
            _calldatas,
            _description
        );
        return transactionCount;
    }

    function _execute(Transaction storage transaction) internal {
        transaction.executed = true;

        bytes memory callData;

        if (bytes(transaction.signature).length == 0) {
            callData = transaction.calldatas;
        } else {
            callData = abi.encodePacked(Utils.getSig(transaction.signature), transaction.calldatas);
        }

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory returndata) = transaction.target.call{value: transaction.value}(callData);

        if (success) {
            emit TransactionExecuted(
                transaction.target,
                transaction.id,
                transaction.value,
                transaction.signature,
                transaction.calldatas,
                returndata
            );
        } else {
            transaction.executed = false;
            emit TransactionFailed(
                transaction.target,
                transaction.id,
                transaction.value,
                transaction.signature,
                transaction.calldatas,
                returndata
            );
        }
    }

    function _cancel(Transaction storage transaction) internal {
        transaction.canceled = true;
        emit TransactionCanceled(transaction.id);
    }
}

/* MAIN MULTISIG */

contract CoreMultisig is BaseMultisig {
    
    constructor(address[] memory initialCoreMembers) {
        for(uint256 i = 0; i < initialCoreMembers.length; i++) {
            require(isntZero(initialCoreMembers[i]));
            require(addr2Member[initialCoreMembers[i]].isMember == false, ERROR_ALREADY_A_MEMEBER_OF_FEDERATION);
            _addMember(initialCoreMembers[i]);
        }

        multisig = address(this);
    }

    /* EXTERNALS */
    
    /* BEGIN Member Registry */
    function addMember(address _member) external onlyMultisig {
        require(isntZero(_member), ERROR_INVALID_ADDRESS);
        require(addr2Member[_member].isMember == false, ERROR_ALREADY_A_MEMEBER_OF_FEDERATION);

        _addMember(_member);
    }

    function removeMember(address _member) external onlyMultisig {
        require(addr2Member[_member].isMember == true, ERROR_IS_NOT_A_MEMBER);
        require(addr2Member[_member].index < members.length, ERROR_INDEX_OUT_OF_RANGE);

        _removeMember(_member);
    }

    function swapMember(address _old, address _new) external onlyMultisig {
        require(isntZero(_new), ERROR_INVALID_ADDRESS);
        require(addr2Member[_old].isMember == true, ERROR_IS_NOT_A_MEMBER);
        require(addr2Member[_new].isMember == false, ERROR_IS_NOT_A_MEMBER);
        
        _swapMember(_old, _new);
    }
    /* END Member Registry*/

    /* BEGIN Vault */
    function transfer(address _token, address _to, uint256 _value) 
        external
        onlyMember
        nonReentrant
    {
        _transfer(_token, _to, _value);
    }
    /* END Vault */

    /* BEGIN BaseMultisig */
    function createTransaction(
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _calldatas,
        string memory _description
    ) 
        external 
        onlyMember
        returns (uint256 transactionId) 
    {
        require(isContract(_target), ERROR_TARGET_IS_NOT_VALID_CONTRACT);

        transactionId = _createTransaction(
            _target,
            _value,
            _signature,
            _calldatas,
            _description
        );
    }

    function executeAll(uint256[] calldata transactionIds, bytes[][] calldata signatures) external payable onlyMember nonReentrant {
        require(transactionIds.length > 0 && signatures.length > 0);
        require(transactionIds.length == signatures.length);

        for (uint256 i = 0; i < transactionIds.length; i++) {
            _checkAndExecute(transactionIds[i], signatures[i]);
        }
    }

    function execute(uint256 transactionId, bytes[] calldata signatures) external payable onlyMember nonReentrant {
        _checkAndExecute(transactionId, signatures);
    }

    function cancel(uint256 transactionId) external onlyMember {
        Transaction storage transaction = transactions[transactionId];
        
        require(transactionId > 0 && transactionId <= transactionCount, ERROR_INVALID_TRANSACTION);
        require(transaction.executed == false, ERROR_TRANSACTION_HAS_BEEN_EXECUTED);
        require(transaction.canceled == false, ERROR_TRANSACTION_HAS_BEEN_EXECUTED);

        _cancel(transaction);
    }
    /* END BaseMultisig */

    /* EXTERNAL VIEW */
    function getQuorum() external view returns(uint256) {
        return _getQuorum();
    }

    /* INTERNAL VIEW */
    function _getQuorum() internal view returns(uint256) {
        return (members.length / 2) + 1;
    }

    /* INTERNALS */
    function _checkAndExecute(uint256 transactionId, bytes[] calldata signatures) private {
        Transaction storage transaction = transactions[transactionId];
        uint256 len = signatures.length;
        uint256 quorum = _getQuorum();
        
        require(transactionId > 0 && transactionId <= transactionCount, ERROR_INVALID_TRANSACTION);
        require(transaction.executed == false, ERROR_TRANSACTION_HAS_BEEN_EXECUTED);
        require(transaction.canceled == false, ERROR_TRANSACTION_HAS_BEEN_CANCELED);
        require( len >= quorum, ERROR_QUORUM_IS_NOT_REACHED);

        uint256 currentQuorum = 0;
        address[] memory addrs = new address[](quorum);
        bytes32 message = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(address(this), transactionId)));

        for (uint256 i = 0; i < signatures.length; i++) {
            (address signer, ECDSA.RecoverError err) = ECDSA.tryRecover(message, signatures[i]);
            
            require(err == ECDSA.RecoverError.NoError);
            require(_isMember(signer), ERROR_ONLY_MEMBERS_HAVE_ACCESS);

            for (uint256 j = 0; j < addrs.length; j++) {
                require (addrs[j] != signer, ERROR_CONFIRMATION_IS_DONE_BEFORE);
            }
            
            addrs[i] = signer;
            currentQuorum++;

            if (currentQuorum == quorum) {
                _execute(transaction);
                return;
            }
        }

        revert();
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

/**
* ENGA Federation Vault.
* @author Mehdikovic
* Date created: 2022.03.02
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/finance/IVault.sol";
import "../common/NativeToken.sol";
import "../lib/Utils.sol";

abstract contract Vault is IVault, NativeToken, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event VaultTransfer(address indexed token, address indexed to, uint256 amount);
    event VaultDeposit(address indexed token, address indexed sender, uint256 amount);
    
    /* STATE MODIFIERS */

    receive() external payable {
        _deposit(NATIVE, msg.value);
    }

    function deposit(address _token, uint256 _value) external payable nonReentrant {
        _deposit(_token, _value);
    }

    /* VIEWS */

    function balance(address _token) external view returns (uint256) {
        return _balance(_token);
    }

    /* INTERNALS */

    function _deposit(address _token, uint256 _value) internal {
        require(_value > 0, "ERROR DEPOSIT VALUE ZERO");
        
        if (_token == NATIVE) {
            require(msg.value == _value, "ERROR VALUE MISMATCH");
        } else {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _value);
        }

        emit VaultDeposit(_token, msg.sender, _value);
    }

    function _transfer(address _token, address _to, uint256 _value) internal {
        require(_value > 0, "ERROR TRANSFER VALUE ZERO");

        if (_token == NATIVE) {
            require(Utils.transferNativeToken(_to, _value),  "ERROR SEND REVERTED");
        } else {
            IERC20(_token).safeTransfer(_to, _value);
        }

        emit VaultTransfer(_token, _to, _value);
    }

    /* INTERNAL VIEWS */
    
    function _balance(address _token) internal view returns (uint256) {
        if (_token == NATIVE) {
            return address(this).balance;
        } else {
            return IERC20(_token).balanceOf(address(this));
        }
    }
}

/**
* ENGA Federation Multisig.
* @author Mehdikovic
* Date created: 2022.02.15
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

import "../common/IsContract.sol";
import "../interfaces/access/IERC173.sol";

abstract contract Owner is IERC173, IsContract {
    string constant public ERROR_INVALID_ADDRESS                             = "ERROR_INVALID_ADDRESS";
    string constant public ERROR_ONLY_MULTISIG_HAS_ACCESS                    = "ERROR_ONLY_MULTISIG_HAS_ACCESS";
    string constant public ERROR_NEW_MULTISIG_MUST_BE_DIFFERENT_FROM_OLD_ONE = "ERROR_NEW_MULTISIG_MUST_BE_DIFFERENT_FROM_OLD_ONE";

    /// @notice multisig pointer as the owner
    address public multisig;

    event OwnershipChanged(address indexed oldMultisig, address indexed newMultisig);

    /* STATE MODIFIERS */

    function transferOwnership(address _newMultisig) external onlyMultisig {
        require(_newMultisig != multisig, ERROR_NEW_MULTISIG_MUST_BE_DIFFERENT_FROM_OLD_ONE);
        require(isContract(_newMultisig), ERROR_INVALID_ADDRESS);

        _changeMultisig(_newMultisig);
    }

    /* MODIFIERS */

    modifier onlyMultisig {
        require(msg.sender == multisig, ERROR_ONLY_MULTISIG_HAS_ACCESS);
        _;
    }

    /* PUBLIC VIEWS */

    function owner() external view returns (address _owner) {
        _owner = multisig;
    }

    /* INTERNALS */

    //solhint-disable no-empty-blocks
    function _afterMultisigChanged(address _oldMultisig, address _newMultisig) internal virtual {}

    function _changeMultisig(address _newMultisig) internal {
        address old = multisig;
        multisig = _newMultisig;
        _afterMultisigChanged(old, _newMultisig);
        
        emit OwnershipChanged(old, _newMultisig);
    }
}

abstract contract MultisigOwner is Owner {
    constructor(address _multisig) {
        require(isContract(_multisig), ERROR_INVALID_ADDRESS);
        multisig = _multisig;
    }
}

/**
* ENGA Federation Utility contract.
* @author Mehdikovic
* Date created: 2022.03.01
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

library Utils {
    function getSig(string memory _fullSignature) internal pure returns(bytes4 _sig) {
        _sig = bytes4(keccak256(bytes(_fullSignature)));
    }

    function transferNativeToken(address _to, uint256 _value) internal returns (bool) {
        // solhint-disable avoid-low-level-calls
        (bool sent, ) = payable(_to).call{value: _value}("");
        return sent;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

/**
* ENGA Federation IVault.
* @author Mehdikovic
* Date created: 2022.03.08
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

interface IVault {
    function balance(address _token) external view returns (uint256);
    function deposit(address _token, uint256 _value) external payable;
    function transfer(address _token, address _to, uint256 _value) external;
}

/**
* ENGA Federation Native Token Identifier.
* @author Mehdikovic
* Date created: 2022.03.02
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

contract NativeToken {
    // By convention, address (0) is the native token
    address internal constant NATIVE = address(0);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

/**
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

contract IsContract {
    /**
    * NOTE: this should NEVER be used for authentication
    * (see pitfalls: https://github.com/fergarrui/ethereum-security/tree/master/contracts/extcodesize).
    *
    * This is only intended to be used as a sanity check that an address is actually a contract,
    * RATHER THAN an address not being a contract.
    */
    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        // solhint-disable-next-line
        assembly { size := extcodesize(_target) }
        return size > 0;
    }

    function isntZero(address _target) internal pure returns (bool) {
        return _target != address(0);
    }
}

/**
* ENGA Federation IERC173 contract.
* @author Mehdikovic
* Date created: 2022.04.03
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;


interface IERC173 {
    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}