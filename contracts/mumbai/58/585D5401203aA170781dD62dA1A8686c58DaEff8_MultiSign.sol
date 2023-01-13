// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

contract MultiSign is Ownable {
    address g_CheckAddr;

    //events
    event event_updateAddr(address addr);

    constructor(address addr) {
        require(addr != address(0), 'constructor addr can not be zero');

        g_CheckAddr = addr;
        emit event_updateAddr(g_CheckAddr);
    }

    // fallback
    fallback() external payable {
        revert();
    }

    // receive
    receive() external payable {
        revert();
    }

    function getCheckAddr() public view returns (address) {
        return g_CheckAddr;
    }

    function updateCheckAddr(address addr) public onlyOwner {
        require(addr != address(0), 'updateCheckAddr addr can not be zero');

        g_CheckAddr = addr;
        emit event_updateAddr(g_CheckAddr);
    }

    function CheckWitness(bytes32 hashmsg, bytes memory signs)
        public
        view
        returns (bool)
    {
        require(signs.length == 65, 'signs must = 65');

        address tmp = decode(hashmsg, signs);
        if (tmp == g_CheckAddr) {
            return true;
        }
        return false;
    }

    function decode(bytes32 hashmsg, bytes memory signedString)
        private
        pure
        returns (address)
    {
        bytes32 r = bytesToBytes32(slice(signedString, 0, 32));
        bytes32 s = bytesToBytes32(slice(signedString, 32, 32));
        bytes1 v = slice(signedString, 64, 1)[0];
        return ecrecoverDecode(hashmsg, r, s, v);
    }

    function slice(
        bytes memory data,
        uint256 start,
        uint256 len
    ) private pure returns (bytes memory) {
        bytes memory b = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            b[i] = data[i + start];
        }

        return b;
    }

    //浣跨敤ecrecover鎭㈠鍦板潃
    function ecrecoverDecode(
        bytes32 hashmsg,
        bytes32 r,
        bytes32 s,
        bytes1 v1
    ) private pure returns (address addr) {
        uint8 v = uint8(v1);
        if (uint8(v1) == 0 || uint8(v1) == 1) {
            v = uint8(v1) + 27;
        }
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return address(0);
        }
        addr = ecrecover(hashmsg, v, r, s);
    }

    //bytes杞崲涓篵ytes32
    function bytesToBytes32(bytes memory source) private pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }
}