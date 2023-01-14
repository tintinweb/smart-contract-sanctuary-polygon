// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import {SolRsaVerify} from "./SolRsaVerify.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @dev ERC-721 Contract mint functions interface
 */
interface INFT {
    function mintTo(address _beneficiary) external payable returns (uint256);

    function mint() external payable returns (uint256);
}

/**
 * @author test
 * @title RsaWallet
 * @notice Contract wallet that allows the owner to transfer ether by signing a message with a RSA private key
 */
contract RsaWallet is Ownable, IERC721Receiver {
    /**
     * Libraries
     */
    using SolRsaVerify for bytes32;

    /**
     * @dev Public variables
     */
    uint256 public nonce;

    /**
     * @dev Internal variables
     */
    bytes private modulus;
    bytes private exponent;
    INFT private nftContract;

    /**
     * @dev Events
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Mint(uint256 _tokenId);

    /**
     * @dev Errors
     */
    error VerificationFailed(
        bytes32 _hash,
        bytes _signature,
        bytes _exponent,
        bytes _modulus,
        uint256 _ret
    );
    error InsufficientBalance(uint256 _balance, uint256 _amount);
    error EthSendFailed();

    /**
     * @dev Constructor
     * @param _modulus modulus of public key
     * @param _exponent exponent of public key
     * @param _nftContractAddress NFT contract address
     */
    constructor(
        bytes memory _modulus,
        bytes memory _exponent,
        address _nftContractAddress
    ) {
        modulus = _modulus;
        exponent = _exponent;
        nftContract = INFT(_nftContractAddress);
    }

    /**
     * @dev Receive function
     */
    receive() external payable {}

    /**
     * @dev Fallback function
     */
    fallback() external payable {}

    /**
     * @dev Set public key
     * @param _modulus modulus of public key
     * @param _exponent exponent of public key
     */
    function setPublicKey(bytes memory _modulus, bytes memory _exponent)
        external
        onlyOwner
    {
        modulus = _modulus;
        exponent = _exponent;
    }

    /**
     * @dev Transfer ether
     * @param _to recipient
     * @param _amount amount
     * @param _signature signature
     */
    function transfer(
        address _to,
        uint256 _amount,
        bytes memory _signature
    ) external returns (bool) {
        if (_amount <= address(this).balance) {
            revert InsufficientBalance(address(this).balance, _amount);
        }

        bytes memory message = abi.encode(address(this), _to, _amount, nonce);

        bytes32 hash = sha256(message);

        uint256 ret = verify(hash, _signature, exponent, modulus);
        if (ret != 0) {
            revert VerificationFailed(hash, _signature, exponent, modulus, ret);
        }

        incrementNonce();

        (bool sent, ) = _to.call{value: _amount}("");
        if (!sent) {
            revert EthSendFailed();
        }

        emit Transfer(address(this), _to, _amount);

        return true;
    }

    /**
     * @dev Get balance
     * @return balance
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Verify signature
     * @param hash hash
     * @param _signature signature
     * @param _exponent exponent
     * @param _modulus modulus
     * @return ret verification result
     */
    function verify(
        bytes32 hash,
        bytes memory _signature,
        bytes memory _exponent,
        bytes memory _modulus
    ) public view returns (uint256 ret) {
        ret = hash.pkcs1Sha256Verify(_signature, _exponent, _modulus);
    }

    /**
     * @dev Increment nonce
     */
    function incrementNonce() internal {
        nonce++;
    }

    /*
     * @dev ERC721Receiver
     *
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

library SolRsaVerify {
    bytes19 constant sha256Prefix = 0x3031300d060960864801650304020105000420;

    function memcpy(
        uint256 _dest,
        uint256 _src,
        uint256 _len
    ) internal pure {
        // Copy word-length chunks while possible
        for (; _len >= 32; _len -= 32) {
            assembly {
                mstore(_dest, mload(_src))
            }
            _dest += 32;
            _src += 32;
        }

        if (_len > 0) {
            uint256 mask = 256**(32 - _len) - 1;
            assembly {
                let srcpart := and(mload(_src), not(mask))
                let destpart := and(mload(_dest), mask)
                mstore(_dest, or(destpart, srcpart))
            }
        }
    }

    function join(
        bytes memory _s,
        bytes memory _e,
        bytes memory _m
    ) internal pure returns (bytes memory) {
        uint256 slen = _s.length;
        uint256 elen = _e.length;
        uint256 mlen = _m.length;
        uint256 sptr;
        uint256 eptr;
        uint256 mptr;
        uint256 inputPtr;

        bytes memory input = new bytes(0x60 + slen + elen + mlen);
        assembly {
            sptr := add(_s, 0x20)
            eptr := add(_e, 0x20)
            mptr := add(_m, 0x20)
            mstore(add(input, 0x20), slen)
            mstore(add(input, 0x40), elen)
            mstore(add(input, 0x60), mlen)
            inputPtr := add(input, 0x20)
        }

        memcpy(inputPtr + 0x60, sptr, slen);
        memcpy(inputPtr + 0x60 + slen, eptr, elen);
        memcpy(inputPtr + 0x60 + slen + elen, mptr, mlen);

        return input;
    }

    function sliceUint(bytes memory bs, uint256 start)
        internal
        pure
        returns (uint256)
    {
        require(bs.length >= start + 32, "slicing out of range");
        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }
        return x;
    }

    /** @dev Verifies a PKCSv1.5 SHA256 signature
     * @param _sha256 is the sha256 of the data
     * @param _s is the signature
     * @param _e is the exponent
     * @param _m is the modulus
     * @return 0 if success, >0 otherwise
     */
    function pkcs1Sha256Verify(
        bytes32 _sha256,
        bytes memory _s,
        bytes memory _e,
        bytes memory _m
    ) internal view returns (uint256) {
        uint256 decipherlen = _m.length;
        require(decipherlen >= 62); // _m.length >= sha256Prefix.length + _sha256.length + 11 = 19 + 32 + 11 = 62
        // decipher
        bytes memory input = join(_s, _e, _m); //
        // return 0;
        uint256 inputlen = input.length;

        bytes memory decipher = new bytes(decipherlen);

        // cp0;

        assembly {
            pop(
                staticcall(
                    sub(gas(), 2000),
                    0x05,
                    add(input, 0x20),
                    inputlen,
                    add(decipher, 0x20),
                    decipherlen
                )
            )
        }

        // optimized for 1024 bytes

        // or uncomment for other than 1024 (start)
        if (uint8(decipher[0]) != 0 || uint8(decipher[1]) != 1) {
            return 1;
        }

        uint256 i;

        for (i = 2; i < decipherlen - 52; i++) {
            if (decipher[i] != 0xff) {
                return 2;
            }
        }

        if (decipher[decipherlen - 52] != 0) {
            return 3;
        }
        // or uncomment for other than 1024 (end)

        if (
            uint256(bytes32(sha256Prefix)) !=
            sliceUint(decipher, decipherlen - 51) &
                0xffffffffffffffffffffffffffffffffffffff00000000000000000000000000
        ) {
            return 4;
        }

        if (uint256(_sha256) != sliceUint(decipher, decipherlen - 32)) {
            return 5;
        }
        return 0;
    }

    /** @dev Verifies a PKCSv1.5 SHA256 signature
     * @param _data to verify
     * @param _s is the signature
     * @param _e is the exponent
     * @param _m is the modulus
     * @return 0 if success, >0 otherwise
     */
    function pkcs1Sha256VerifyRaw(
        bytes memory _data,
        bytes memory _s,
        bytes memory _e,
        bytes memory _m
    ) internal view returns (uint256) {
        return pkcs1Sha256Verify(sha256(_data), _s, _e, _m);
    }
}