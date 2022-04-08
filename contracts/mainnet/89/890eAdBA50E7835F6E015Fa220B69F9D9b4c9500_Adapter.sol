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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import './IPegdex.sol';

contract Adapter is Ownable {
  IPegdex public pegdex = IPegdex(0xeF67c05fB5D282A382d03d30cf7a127cD81094cf);

  function getDetails(address user)
    external
    view
    returns (
      uint256 periodSellLimit,
      uint256 salesInPeriod,
      uint256 slotAmount,
      int256 getCopPrice,
      uint256 slotAvailable,
      uint256 slotMinimum
    )
  {
    periodSellLimit = pegdex.periodSellLimit();
    (salesInPeriod, ) = pegdex.salesInPeriod(user);
    getCopPrice = pegdex.getCopPrice();
    slotAmount = pegdex.slotAmount();
    slotAvailable = pegdex.slotAvailable();
    slotMinimum = pegdex.slotMinimum();
  }

  function updatePegdex(IPegdex _pegdex) external onlyOwner {
    pegdex = _pegdex;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPegdex {
  function swapCOPForTokens(
    address token,
    uint256 amountIn,
    uint256 minAmountOut,
    uint256 deadline
  ) external returns (uint256 amountOut);

  function periodSellLimit() external view returns (uint256 limit);

  function salesInPeriod(address user)
    external
    view
    returns (uint256 amount, uint256 startOfPeriod);

  function fee() external view returns (uint16);

  function artificialPrice() external view returns (int256);

  function getCopPrice() external view returns (int256);

  function slotAmount() external view returns (uint256);

  function slotAvailable() external view returns (uint256);

  function slotMinimum() external view returns (uint256);
}