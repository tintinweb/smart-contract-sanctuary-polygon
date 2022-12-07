/**
 *Submitted for verification at polygonscan.com on 2022-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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

pragma solidity 0.8.7;

abstract contract Signatures is Ownable {

    string proxyPrepend = "Welcome to W3 Mail!\n\nSign this message to set up your account on the platform.\n\nThis request will not trigger a blockchain transaction from your wallet or cost any gas fees.\n\nParameters: ";
    string emailPrepend = "Welcome to W3 Mail!\n\nSign this message to set up your account on the platform.\n\nThis request will not trigger a blockchain transaction from your wallet or cost any gas fees.\n\nParameters: ";

    function changePrependString(string memory _proxyPrepend, string memory _emailPrepend) public onlyOwner {
        proxyPrepend = _proxyPrepend;
        emailPrepend = _emailPrepend;
    }

    function getProxySigner(string memory publicKey, bytes memory sig) public view returns(address) {
        bytes memory message = abi.encodePacked(proxyPrepend, publicKey);
        bytes32 signedMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", uint2str(message.length), proxyPrepend, publicKey));
        return recoverSigner(signedMessage, sig);
   }

   function getEmailSigner(string memory emailHash, bytes memory sig) public view returns(address) {
        bytes memory message = abi.encodePacked(emailPrepend, emailHash);
        bytes32 signedMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", uint2str(message.length), emailPrepend, emailHash));
        return recoverSigner(signedMessage, sig);
   }

   function recoverSigner(bytes32 message, bytes memory sig)
       internal
       pure
       returns (address)
     {
       uint8 v;
       bytes32 r;
       bytes32 s;
       (v, r, s) = splitSignature(sig);
       return ecrecover(message, v, r, s);
   }

   function splitSignature(bytes memory sig)
       internal
       pure
       returns (uint8, bytes32, bytes32)
     {
       require(sig.length == 65);

       bytes32 r;
       bytes32 s;
       uint8 v;

       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }
 
       return (v, r, s);
   }

   function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }
}

pragma solidity 0.8.7;

contract w3Mail is Signatures {

    mapping(address => string) private proxyKeys;

    uint256 emailsIndex = 0;

    event emailTransfers(address indexed from, address indexed to, string emailHash, bytes32 id);

    function sendEmail(address from, address to, string memory emailHash, bytes memory signature) public {
        require(from == getEmailSigner(emailHash, signature), "Not authorized from sender.");
        require(bytes(proxyKeys[from]).length != 0, "From address not registered.");
        require(bytes(proxyKeys[to]).length != 0, "To address not registered.");
        bytes32 id = getUniqueHash(from, to, emailHash, signature);
        emit emailTransfers(from, to, emailHash, id);
    }

    function setProxyKey(string memory proxyKey, bytes memory signature) public {
        address signer = getProxySigner(proxyKey, signature);
        proxyKeys[signer] = proxyKey;
    }

    function getProxyKey(address _user) public view returns (string memory) {
        return proxyKeys[_user];
    }

    function getUniqueHash(address from, address to, string memory emailHash, bytes memory signature) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(from, to, emailHash, signature, block.timestamp, block.difficulty));
    }
}