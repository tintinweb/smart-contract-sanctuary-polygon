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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IFSetting.sol";
import "./IFDFERC20.sol";


contract FECO is Ownable{

    // tax
    address[] private ecoSystemAccount = [
    0xf48c06D60814d6452C54EBF84F4F91a99D8f9322,
    0x8d79b154E31A0097032BaebEdd7CdbDfB2c3347a,
    0x51853EFCB0e2D3c40c3a1e125B02C1C96B70C284];

    address private setting;

    constructor(address _setting){
        require(_setting != address(0),"setting is zero");
        setting = _setting;
        IFSetting(setting).setInit(9,address(this));

        _transferOwnership(IFSetting(setting).safeAdmin());
    }

    function setSetting(address setting_) external onlyOwner{
        setting = setting_;
    }

    function getEco() public view returns(address[] memory) {
        return ecoSystemAccount;
    }

    function withdraw() external {
        IFDFERC20 fdf = IFDFERC20(IFSetting(setting).fdf());
        uint256 balanceFDF = fdf.balanceOf(address(this));
        if (balanceFDF >0) {
            uint256 avg = balanceFDF / ecoSystemAccount.length;
            for (uint i=0; i< ecoSystemAccount.length; i++) {
                fdf.transfer(ecoSystemAccount[i],avg);
            }
        }

        IERC20 usdt = IERC20(IFSetting(setting).usdt());
        uint256 balanceUSDT = usdt.balanceOf(address(this));
        if (balanceUSDT >0){
            uint256 avg = balanceUSDT / ecoSystemAccount.length;
            for (uint i=0; i< ecoSystemAccount.length; i++) {
                usdt.transfer(ecoSystemAccount[i],avg);
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFDFERC20 is IERC20{
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFSetting {
    function setInit(uint256 index,address addr) external;
    function usdt() external view returns(address);
    function fnft() external view returns(address);
    function fdf() external view returns(address);
    function pairAddr() external view returns(address);
    function bento() external view returns(address);
    function getLPPool() external view returns(address);
    function getPath2() external view returns(address[] memory);
    function routerAddr() external view returns(address);
    function FDFStaking() external view returns(address);
    function FNFTPool() external view returns(address);
    function mintOwner() external view returns(address);
    function safeAdmin() external view returns(address);
    function defaultRefer() external view returns(address);
    function usdtInAddr() external view returns(address);
    function marketReceiver() external view returns(address);
    function isExcluded(address ex_) external view returns(bool);
    function isTaxExcluded(address tax_) external view returns(bool);
    function getFeeReceiver() external view returns(address);
    function getEcoSystemAccount() external view returns(address);
    function USDTToFDFAmount(uint256 _amount) external view returns(uint256);
    function FDFToUSDTAmount(uint256 _amount) external view returns(uint256);
}