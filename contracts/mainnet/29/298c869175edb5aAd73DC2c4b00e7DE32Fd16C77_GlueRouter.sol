// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./helpers/Errors.sol";
import "./helpers/TransferHelper.sol";
import "./BridgeBase.sol";
import "./SwapBase.sol";

contract GlueRouter is Ownable, ReentrancyGuard, EIP712 {
    using ECDSA for bytes32;
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    address public feeAddress;
    string public name;
    string public symbol;

    string private constant SIGNING_DOMAIN = "Glue";
    string private constant SIGNATURE_VERSION = "1";

    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        name = "Glue Router";
        symbol = "GLUE";
    }


    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Glue: EXPIRED");
        _;
    }

    struct SwapBridgeDex {
        address dex;
        bool isEnabled;
    }

    SwapBridgeDex[] public swapDexs;
    SwapBridgeDex[] public bridgeDexs;

    receive() external payable {}

    event NewSwapDexAdded(address dex, bool isEnabled);
    event NewBridgeDexAdded(address dex, bool isEnabled);
    event SwapDexDisabled(uint256 dexID);
    event BridgeDexDisabled(uint256 dexID);
    event SetFeeAddress(address feeAddress);
    event WithdrawETH(uint256 amount);
    event Withdraw(address token, uint256 amount);
    
    struct SwapBridgeRequest {
        uint256 id;
        uint256 nativeAmount;
        address inputToken;
        bytes data;
    }

    // **** USER REQUEST ****
    struct UserSwapRequest {
        address receiverAddress;
        uint256 amount;
        SwapBridgeRequest swapRequest;
        uint256 deadline;
    }

    struct UserBridgeRequest {
        address receiverAddress;
        uint256 toChainId;
        uint256 amount;
        SwapBridgeRequest bridgeRequest;
        uint256 deadline;
    }

    struct UserSwapBridgeRequest {
        address receiverAddress;
        uint256 toChainId;
        uint256 amount;
        SwapBridgeRequest swapRequest;
        SwapBridgeRequest bridgeRequest;
        uint256 deadline;
    }

    bytes32 private constant SWAP_REQUEST_TYPE =
        keccak256(
            "UserSwapRequest(address receiverAddress,uint256 amount,SwapBridgeRequest swapRequest,uint256 deadline)SwapBridgeRequest(uint256 id,uint256 nativeAmount,address inputToken,bytes data)"
        );
    bytes32 private constant BRIDGE_REQUEST_TYPE =
        keccak256(
            "UserBridgeRequest(address receiverAddress,uint256 toChainId,uint256 amount,SwapBridgeRequest bridgeRequest,uint256 deadline)SwapBridgeRequest(uint256 id,uint256 nativeAmount,address inputToken,bytes data)"
        );
    bytes32 private constant SWAP_AND_BRIDGE_REQUEST_TYPE =
        keccak256(
            "UserSwapBridgeRequest(address receiverAddress,uint256 toChainId,uint256 amount,SwapBridgeRequest swapRequest,SwapBridgeRequest bridgeRequest,uint256 deadline)SwapBridgeRequest(uint256 id,uint256 nativeAmount,address inputToken,bytes data)"
        );
    bytes32 private constant REQUEST_TYPE =
        keccak256(
            "SwapBridgeRequest(uint256 id,uint256 nativeAmount,address inputToken,bytes data)"
        );

    function _hashSwapRequest(UserSwapRequest memory _userRequest) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    SWAP_REQUEST_TYPE,
                    _userRequest.receiverAddress,
                    _userRequest.amount,
                    keccak256(abi.encode(REQUEST_TYPE, _userRequest.swapRequest.id, _userRequest.swapRequest.nativeAmount, _userRequest.swapRequest.inputToken, keccak256(_userRequest.swapRequest.data))),
                    _userRequest.deadline
                )
            );
    }
    function _hashBridgeRequest(UserBridgeRequest memory _userRequest) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BRIDGE_REQUEST_TYPE,
                    _userRequest.receiverAddress,
                    _userRequest.toChainId,
                    _userRequest.amount,
                    keccak256(abi.encode(REQUEST_TYPE, _userRequest.bridgeRequest.id, _userRequest.bridgeRequest.nativeAmount, _userRequest.bridgeRequest.inputToken, _userRequest.bridgeRequest.data)),
                    _userRequest.deadline
                )
            );
    }
    function _hashSwapAndBridgeRequest(UserSwapBridgeRequest memory _userRequest) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    SWAP_AND_BRIDGE_REQUEST_TYPE,
                    _userRequest.receiverAddress,
                    _userRequest.toChainId,
                    _userRequest.amount,
                    keccak256(abi.encode(REQUEST_TYPE, _userRequest.swapRequest.id, _userRequest.swapRequest.nativeAmount, _userRequest.swapRequest.inputToken, _userRequest.swapRequest.data)),
                    keccak256(abi.encode(REQUEST_TYPE, _userRequest.bridgeRequest.id, _userRequest.bridgeRequest.nativeAmount, _userRequest.bridgeRequest.inputToken, _userRequest.bridgeRequest.data)),
                    _userRequest.deadline
                )
            );
    }

    // **** SWAP ****
    function swap(UserSwapRequest calldata _userRequest, bytes memory _sign)
        external
        payable
        ensure(_userRequest.deadline)
        nonReentrant
    {
        require(
            owner() == _hashTypedDataV4(_hashSwapRequest(_userRequest)).recover(_sign),
            Errors.CALL_DATA_MUST_SIGNED_BY_OWNER
        );
        require(
            _userRequest.receiverAddress != address(0),
            Errors.ADDRESS_0_PROVIDED
        );
        require(_userRequest.amount != 0, Errors.INVALID_AMT);
        require(
            _userRequest.swapRequest.inputToken != address(0),
            Errors.ADDRESS_0_PROVIDED
        );

        SwapBridgeDex memory swapInfo = swapDexs[_userRequest.swapRequest.id];

        require(
            swapInfo.dex != address(0) && swapInfo.isEnabled,
            Errors.DEX_NOT_ALLOWED
        );
        uint256 nativeSwapAmount = _userRequest.swapRequest.inputToken ==
            NATIVE_TOKEN_ADDRESS
            ? _userRequest.amount + _userRequest.swapRequest.nativeAmount
            : _userRequest.swapRequest.nativeAmount;
        require(
            msg.value == nativeSwapAmount,
            Errors.VALUE_NOT_EQUAL_TO_AMOUNT
        );

        // swap
        SwapBase(swapInfo.dex).swap{value: nativeSwapAmount}(
            msg.sender,
            _userRequest.swapRequest.inputToken,
            _userRequest.amount,
            _userRequest.receiverAddress,
            _userRequest.swapRequest.data,
            feeAddress
        );
    }

    // **** BRIDGE ****
    function bridge(UserBridgeRequest calldata _userRequest, bytes memory _sign)
        external
        payable
        ensure(_userRequest.deadline)
        nonReentrant
    {
        require(
            owner() == _hashTypedDataV4(_hashBridgeRequest(_userRequest)).recover(_sign),
            Errors.CALL_DATA_MUST_SIGNED_BY_OWNER
        );
        require(
            _userRequest.receiverAddress != address(0),
            Errors.ADDRESS_0_PROVIDED
        );
        require(_userRequest.amount != 0, Errors.INVALID_AMT);
        require(
            _userRequest.bridgeRequest.inputToken != address(0),
            Errors.ADDRESS_0_PROVIDED
        );

        SwapBridgeDex memory bridgeInfo = bridgeDexs[
            _userRequest.bridgeRequest.id
        ];

        require(
            bridgeInfo.dex != address(0) && bridgeInfo.isEnabled,
            Errors.DEX_NOT_ALLOWED
        );

        // bridge
        BridgeBase(bridgeInfo.dex).bridge{value: msg.value}(
            msg.sender,
            _userRequest.bridgeRequest.inputToken,
            _userRequest.amount,
            _userRequest.receiverAddress,
            _userRequest.toChainId,
            _userRequest.bridgeRequest.data,
            feeAddress
        );
    }

    // **** SWAP AND BRIDGE ****
    function swapAndBridge(UserSwapBridgeRequest calldata _userRequest, bytes memory _sign)
        external
        payable
        ensure(_userRequest.deadline)
        nonReentrant
    {
        require(
            owner() == _hashTypedDataV4(_hashSwapAndBridgeRequest(_userRequest)).recover(_sign),
            Errors.CALL_DATA_MUST_SIGNED_BY_OWNER
        );
        require(
            _userRequest.receiverAddress != address(0),
            Errors.ADDRESS_0_PROVIDED
        );
        require(_userRequest.amount != 0, Errors.INVALID_AMT);

        require(
            _userRequest.swapRequest.inputToken != address(0),
            Errors.ADDRESS_0_PROVIDED
        );

        require(
            _userRequest.bridgeRequest.inputToken != address(0),
            Errors.ADDRESS_0_PROVIDED
        );

        SwapBridgeDex memory swapInfo = swapDexs[_userRequest.swapRequest.id];

        require(
            swapInfo.dex != address(0) && swapInfo.isEnabled,
            Errors.DEX_NOT_ALLOWED
        );

        SwapBridgeDex memory bridgeInfo = bridgeDexs[
            _userRequest.bridgeRequest.id
        ];
        require(
            bridgeInfo.dex != address(0) && bridgeInfo.isEnabled,
            Errors.DEX_NOT_ALLOWED
        );

        uint256 nativeSwapAmount = _userRequest.swapRequest.inputToken ==
            NATIVE_TOKEN_ADDRESS
            ? _userRequest.amount + _userRequest.swapRequest.nativeAmount
            : _userRequest.swapRequest.nativeAmount;
        uint256 _amountOut = SwapBase(swapInfo.dex).swap{
            value: nativeSwapAmount
        }(
            msg.sender,
            _userRequest.swapRequest.inputToken,
            _userRequest.amount,
            address(this),
            _userRequest.swapRequest.data,
            feeAddress
        );

        uint256 nativeInput = _userRequest.bridgeRequest.nativeAmount;

        if (_userRequest.bridgeRequest.inputToken != NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeApprove(
                _userRequest.bridgeRequest.inputToken,
                bridgeInfo.dex,
                _amountOut
            );
        } else {
            nativeInput = _amountOut + _userRequest.bridgeRequest.nativeAmount;
        }

        BridgeBase(bridgeInfo.dex).bridge{value: nativeInput}(
            address(this),
            _userRequest.bridgeRequest.inputToken,
            _amountOut,
            _userRequest.receiverAddress,
            _userRequest.toChainId,
            _userRequest.bridgeRequest.data,
            feeAddress
        );
    }

    // **** ONLY OWNER ****
    function addSwapDexs(SwapBridgeDex calldata _dex) external onlyOwner {
        require(_dex.dex != address(0), Errors.ADDRESS_0_PROVIDED);
        swapDexs.push(_dex);
        emit NewSwapDexAdded(_dex.dex, _dex.isEnabled);
    }

    function addBridgeDexs(SwapBridgeDex calldata _dex) external onlyOwner {
        require(_dex.dex != address(0), Errors.ADDRESS_0_PROVIDED);
        bridgeDexs.push(_dex);
        emit NewBridgeDexAdded(_dex.dex, _dex.isEnabled);
    }

    function disableSwapDex(uint256 _dexId) external onlyOwner {
        swapDexs[_dexId].isEnabled = false;
        emit SwapDexDisabled(_dexId);
    }

    function disableBridgeDex(uint256 _dexId) external onlyOwner {
        bridgeDexs[_dexId].isEnabled = false;
        emit BridgeDexDisabled(_dexId);
    }

    function setFeeAddress(address _newFeeAddress) external onlyOwner {
        feeAddress = _newFeeAddress;
        emit SetFeeAddress(_newFeeAddress);
    }

    function withdraw(
        address _token,
        address _receiverAddress,
        uint256 _amount
    ) external onlyOwner {
        require(_receiverAddress != address(0), Errors.ADDRESS_0_PROVIDED);
        TransferHelper.safeTransfer(_token, _receiverAddress, _amount);
        emit Withdraw(_token, _amount);
    }

    function withdrawETH(address _receiverAddress, uint256 _amount)
        external
        onlyOwner
    {
        require(_receiverAddress != address(0), Errors.ADDRESS_0_PROVIDED);
        TransferHelper.safeTransferETH(_receiverAddress, _amount);
        emit WithdrawETH(_amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Errors {
    string internal constant ADDRESS_0_PROVIDED = "ADDRESS_0_PROVIDED";
    string internal constant DEX_NOT_ALLOWED = "DEX_NOT_ALLOWED";
    string internal constant TOKEN_NOT_SUPPORTED = "TOKEN_NOT_SUPPORTED";
    string internal constant SWAP_FAILED = "SWAP_FAILED";
    string internal constant VALUE_SHOULD_BE_ZERO = "VALUE_SHOULD_BE_ZERO";
    string internal constant VALUE_SHOULD_NOT_BE_ZERO = "VALUE_SHOULD_NOT_BE_ZERO";
    string internal constant VALUE_NOT_EQUAL_TO_AMOUNT = "VALUE_NOT_EQUAL_TO_AMOUNT";

    string internal constant INVALID_AMT = "INVALID_AMT";
    string internal constant INVALID_ADDRESS = "INVALID_ADDRESS";
    string internal constant INVALID_SENDER = "INVALID_SENDER";

    string internal constant UNKNOWN_TRANSFER_ID = "UNKNOWN_TRANSFER_ID";
    string internal constant CALL_DATA_MUST_SIGNED_BY_OWNER = "CALL_DATA_MUST_SIGNED_BY_OWNER";

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./helpers/Errors.sol";
import "./helpers/TransferHelper.sol";


abstract contract SwapBase is Ownable {
    address public immutable router;

    constructor(address _router) Ownable() {
        router = _router;
    }

    event WithdrawETH(uint256 amount);

    event Withdraw(address token, uint256 amount);

    modifier onlyRouter {
        require(msg.sender == router, Errors.INVALID_SENDER);
        _;
    }

    function swap(
        address _fromAddress,
        address _fromToken,
        uint256 _amount,
        address _receiverAddress,
        bytes memory _extraData,
        address feeAddress
    ) external payable virtual returns (uint256);

    function withdraw(address _token, address _receiverAddress, uint256 _amount) external onlyOwner {
        require(_receiverAddress != address(0), Errors.ADDRESS_0_PROVIDED);
        TransferHelper.safeTransfer(_token, _receiverAddress, _amount);
        emit Withdraw(_token, _amount);
    }

    function withdrawETH(address _receiverAddress, uint256 _amount) external onlyOwner {
        require(_receiverAddress != address(0), Errors.ADDRESS_0_PROVIDED);
        TransferHelper.safeTransferETH(_receiverAddress, _amount);
        emit WithdrawETH(_amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./helpers/Errors.sol";
import "./helpers/TransferHelper.sol";


abstract contract BridgeBase is Ownable {
    address public router;
    address public constant NATIVE_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    

    constructor(address _router) Ownable() {
        router = _router;
    }

    event UpdateRouterAddress(address indexed routerAddress);

    event WithdrawETH(uint256 amount);

    event Withdraw(address token, uint256 amount);

    modifier onlyRouter() {
        require(msg.sender == router, Errors.INVALID_SENDER);
        _;
    }

    function updateRouterAddress(address newRouter) external onlyOwner {
        router = newRouter;
        emit UpdateRouterAddress(newRouter);
    }

    function bridge(
        address _fromAddress,
        address _fromToken,
        uint256 _amount,
        address _receiverAddress,
        uint256 _toChainId,
        bytes memory _extraData,
        address feeAddress
    ) external payable virtual;


    function withdraw(address _token, address _receiverAddress, uint256 _amount) external onlyOwner {
        require(_receiverAddress != address(0), Errors.ADDRESS_0_PROVIDED);
        TransferHelper.safeTransfer(_token, _receiverAddress, _amount);
        emit Withdraw(_token, _amount);
    }

    function withdrawETH(address _receiverAddress, uint256 _amount) external onlyOwner {
        require(_receiverAddress != address(0), Errors.ADDRESS_0_PROVIDED);
        TransferHelper.safeTransferETH(_receiverAddress, _amount);
        emit WithdrawETH(_amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}