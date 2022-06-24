/**
 *Submitted for verification at polygonscan.com on 2022-06-24
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165.
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others.
 *
 * For an implementation, see {ERC165}.
 *
 * Note: Name adjusted to BSC network.
 */
interface IBEP165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}




// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)


/**
 * Note: Ripped out of OpenZeppelin ECDSA library
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

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
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
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
}





/**
 * @title ERC1363Receiver interface
 * @dev Interface for any contract that wants to support `transferAndCall` or `transferFromAndCall`
 *  from ERC1363 token contracts.
 */
interface IBEP1363Receiver {
    /*
     * Note: the ERC-165 identifier for this interface is 0x88a7ca5c.
     * 0x88a7ca5c === bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
     */

    /**
     * @notice Handle the receipt of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param from address The address which are token transferred from
     * @param value uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
     *  unless throwing
     */
    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes memory data
    ) external returns (bytes4);
}


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is are multiple accounts that can be granted exclusive access to
 * specific functions.
 */
contract Operatable is Context, Ownable {
    mapping(address => bool) private _operators;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _operators[msgSender] = true;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function isOperator(address addr) public view returns (bool) {
        return _operators[addr];
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function setIsOperator(address addr, bool state) public onlyOwner {
        _operators[addr] = state;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOperators() {
        require(
            isOperator(_msgSender()),
            "Operatable: caller is not an operator"
        );
        _;
    }
}

/**
 * Note: no need to import the entire IBEP20 when these are the only
 * functions we need.
 */
interface IToken {
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

/**
 * This contract implements EIP-712 for verifying signed messages
 */
contract Swap is Context, Ownable, Operatable, IBEP165, IBEP1363Receiver {
    mapping(uint256 => uint256) _nonces;
    mapping(uint256 => mapping(uint256 => bool)) _usedNonces;

    address _kenshiAddr;
    IToken private _kenshi;

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct SwapRequest {
        uint256 fromChain;
        uint256 toChain;
        address operator;
        address recipient;
        uint256 amount;
        uint256 nonce;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 constant SWAPREQUEST_TYPEHASH =
        keccak256(
            "SwapRequest(uint256 fromChain,uint256 toChain,address operator,address recipient,uint256 amount,uint256 nonce)"
        );

    bytes32 DOMAIN_SEPARATOR;

    constructor() {
        DOMAIN_SEPARATOR = hash(
            EIP712Domain({
                name: "Kenshi PegSwap Router",
                version: "1",
                chainId: getChainId(),
                verifyingContract: address(this)
            })
        );
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function hash(EIP712Domain memory eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }

    function hash(SwapRequest memory swapRequest)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    SWAPREQUEST_TYPEHASH,
                    swapRequest.fromChain,
                    swapRequest.toChain,
                    swapRequest.operator,
                    swapRequest.recipient,
                    swapRequest.amount,
                    swapRequest.nonce
                )
            );
    }

    function verify(
        SwapRequest memory swapRequest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash(swapRequest))
        );
        return ECDSA.recover(digest, v, r, s) == swapRequest.operator;
    }

    event Claimed(
        uint256 fromChain,
        uint256 toChain,
        address operator,
        address recipient,
        uint256 amount
    );

    function claim(
        SwapRequest memory swapRequest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bool isValid = verify(swapRequest, v, r, s);
        require(isValid, "PegSwap: Signature is not valid");

        bool isFromValidOperator = isOperator(swapRequest.operator);
        require(isFromValidOperator, "PegSwap: Operator not valid");

        bool claimed = _usedNonces[swapRequest.fromChain][swapRequest.nonce];
        require(!claimed, "PegSwap: Already claimed");

        _usedNonces[swapRequest.fromChain][swapRequest.nonce] = true;

        bool success = _kenshi.transfer(
            swapRequest.recipient,
            swapRequest.amount
        );

        require(success, "PegSwap: TransferFrom failed");

        emit Claimed(
            swapRequest.fromChain,
            swapRequest.toChain,
            swapRequest.operator,
            swapRequest.recipient,
            swapRequest.amount
        );
    }

    function isClaimed(uint256 fromChain, uint256 nonce)
        external
        view
        returns (bool)
    {
        return _usedNonces[fromChain][nonce];
    }

    /**
     * @dev Sets `kenshi` contract address.
     *
     * Requirements:
     *
     * - `kenshi` should not be address(0)
     */
    function setKenshiAddr(address kenshi) external onlyOwner {
        require(kenshi != address(0), "PegSwap: Cannot set Kenshi to 0x0");
        _kenshiAddr = kenshi;
        _kenshi = IToken(_kenshiAddr);
    }

    event SwapRequested(
        uint256 toChain,
        address toAddress,
        uint256 amount,
        address requestedFrom,
        address operator,
        uint256 nonce
    );

    function onTransferReceived(
        address requestedFrom,
        address from,
        uint256 value,
        bytes memory data
    ) external returns (bytes4) {
        require(
            _msgSender() == address(_kenshiAddr),
            "PegSwap: Message sender is not the Kenshi token"
        );

        (uint256 toChain, address operator) = abi.decode(
            data,
            (uint256, address)
        );

        uint256 nonce = _nonces[toChain];
        _nonces[toChain] = _nonces[toChain] + 1;

        emit SwapRequested(
            toChain,
            from,
            value,
            requestedFrom,
            operator,
            nonce
        );

        return IBEP1363Receiver(this).onTransferReceived.selector;
    }

    /* ERC165 methods */

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IBEP1363Receiver).interfaceId;
    }

    /**
     * @dev Sends `amount` of `token` from contract address to `recipient`
     *
     * Useful if someone sent bep20 tokens to the contract address by mistake.
     */
    function recoverTokens(
        address token,
        address recipient,
        uint256 amount
    ) external onlyOwner returns (bool) {
        return IToken(token).transfer(recipient, amount);
    }
}