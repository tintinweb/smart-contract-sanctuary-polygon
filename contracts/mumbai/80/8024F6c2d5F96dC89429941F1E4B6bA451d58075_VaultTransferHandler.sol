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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVaultTransferHandler {
    function isValidTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external returns (bool);

    function setTokenLockTime(uint256 _tokenId, uint256 time) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IVaultTransferHandler.sol";

contract VaultTransferHandler is IVaultTransferHandler, Ownable {
    //todo handle token lock (here? in marketplace contract? in token vault contract?)

    address public minter;
    bool public transfersAllowed;
    bool public mintingAllowed;
    mapping(address => bool) public blacklistTo;
    mapping(address => bool) public blacklistFrom;
    mapping(uint256 => uint256) public tokenTimeLock;
    address public marketplace;

    constructor(address _marketplace) {
        marketplace = _marketplace;
        transfersAllowed = true;
        mintingAllowed = true;
    }

    modifier ownerOrMarketplace() {
        require(
            msg.sender == owner() || msg.sender == marketplace,
            "invalid role"
        );
        _;
    }

    function isValidTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external view override returns (bool) {
        // minting
        if (from == address(0)) return mintingAllowed;

        //prevent all transfers, EXCLUDING MINT
        if (!transfersAllowed) return false;

        if (blacklistFrom[from]) return false;
        if (blacklistTo[to]) return false;
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 time = tokenTimeLock[ids[i]];
            if (time != 0 && time < block.timestamp) return false;
        }

        return true;
    }

    function setTransfersAllowed(bool _transfersAllowed) external onlyOwner {
        transfersAllowed = _transfersAllowed;
    }

    function setMintingAllowed(bool _mintingAllowed) external onlyOwner {
        mintingAllowed = _mintingAllowed;
    }

    function setMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    //prevent someone from receiving tokens
    function setBlacklistTo(address _address, bool _permission)
        public
        onlyOwner
    {
        blacklistTo[_address] = _permission;
    }

    //prevent someone from sending tokens
    function setBlacklistFrom(address _address, bool _permission)
        public
        onlyOwner
    {
        blacklistFrom[_address] = _permission;
    }

    //prevent someone from sending and receiving tokens
    function setBlacklist(address _address, bool _permission) public onlyOwner {
        setBlacklistFrom(_address, _permission);
        setBlacklistTo(_address, _permission);
    }

    //set time when token transfers are locked, 0 means always alloed
    function setTokenLockTime(uint256 _tokenId, uint256 time)
        external
        override
        ownerOrMarketplace
    {
        tokenTimeLock[_tokenId] = time;
    }

    function setMinter(address _minter) public onlyOwner {
        minter = _minter;
    }
}