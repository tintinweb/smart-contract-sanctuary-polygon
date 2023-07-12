// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ISetting.sol";
import "./IZBC.sol";

interface IIDO {
    function setIDOStop(bool stop_) external;
    function setReceiveStart(bool start_) external;
}

contract ZBCAdmin is Ownable {
    constructor(address owner_) {
        if (owner_ == address(0)) {
            owner_ = 0x2E7595923cdd4429CBF7236c63b8306ABfa4fB88;
        }
        _transferOwnership(owner_);
    }

    function setAdmin(address setting_,address admin_) external onlyOwner {
        ISetting(setting_).setAdmin(admin_);
    }

    function setUSDT(address setting_, address usdt_) external onlyOwner {
        if (usdt_ == address(0)){
            usdt_ = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
        }
        ISetting(setting_).setUSDT(usdt_);
    }

    function setNFTPool(address setting_, address nftPool_) external onlyOwner {
        ISetting(setting_).setNFTPool(nftPool_);
    }

    function setIDO(address setting_, address ido_) external onlyOwner {
        ISetting(setting_).setIDO(ido_);
    }

    function setV2Router(address setting_, address v2Router_) external onlyOwner {
        if (v2Router_ == address(0)) {
            v2Router_ = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
        }
        ISetting(setting_).setV2Router(v2Router_);
    }

    function setMutual(address setting_, address mutual_) external onlyOwner {
        ISetting(setting_).setMutual(mutual_);
    }

    function setZBC(address setting_, address zbc_) external onlyOwner {
        ISetting(setting_).setZBC(zbc_);
    }

    function setNFT(address setting_, address nft_) external onlyOwner {
        ISetting(setting_).setNFT(nft_);
    }

    function mintOfOwner(address setting_, address addr, uint256 amount) external onlyOwner {
        IZBC(setting_).mintOfOwner(addr, amount);
    }

    function addIsTaxExcluded(address setting_, address addr, bool isTax) external onlyOwner {
        IZBC(setting_).addIsTaxExcluded(addr,isTax);
    }

    function setIDOStop(address setting_, bool stop_) external onlyOwner {
        IIDO(setting_).setIDOStop(stop_);
    }

    function setReceiveStart(address setting_, bool start_) external onlyOwner {
        IIDO(setting_).setReceiveStart(start_);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISetting {
    function setAdmin(address admin_) external;
    function setNFTPool(address nftPool_) external;
    function setIDO(address ido_) external;
    function setV2Router(address v2Router_) external;
    function setMutual(address mutual_) external;
    function setZBC(address zbc_) external;
    function setNFT(address nft_) external;
    function setUSDT(address usdt_) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IZBC {
    function burnFrom(address from,uint256 amount) external;
    function getAmountsOut( uint256 amountIn,address[] memory path ) external view returns (uint256[] memory amounts);
    function balanceOf(address owner) external view returns (uint256 balance);
    function withdraw(address token, address to, uint256 amount) external;
    function mintOfOwner(address addr, uint256 amount) external;

    function withdrawBySafe(address addr,address to) external;

    function addIsTaxExcluded(address addr,bool isTax) external;
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