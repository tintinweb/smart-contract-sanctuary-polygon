// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./interfaces/ISphereSettings.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SphereSettings is Ownable, ISphereSettings {
  using Counters for Counters.Counter;
  Counters.Counter private buyFeeRevision;
  Counters.Counter private sellFeeRevision;
  Counters.Counter private transferFeeRevision;
  Counters.Counter private gameFeeRevision;
  Counters.Counter private feeRevision;

  // *** CONSTANTS ***

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant SPHERE_SETTINGS_VERSION = "1.0.0";
  uint256 private constant MAX_TAX_BRACKET_FEE_RATE = 50;
  uint256 private constant MAX_TOTAL_BUY_FEE_RATE = 250;
  uint256 private constant MAX_TOTAL_SELL_FEE_RATE = 250;
  uint256 private constant MAX_PARTY_ARRAY = 491;

  mapping(uint => BuyFees) public buyFees;
  mapping(uint => SellFees) public sellFees;
  mapping(uint => TransferFees) public transferFees;
  mapping(uint => Fees) public fees;
  mapping(uint => GameFees) public gameFees;

  constructor() {
    setInitialFees();
  }

  function setInitialFees() internal {
    BuyFees memory initialBuyFees = BuyFees({
      liquidityFee: 50,
      treasuryFee: 30,
      riskFreeValueFee: 50,
      totalFees: 0
    });
    setBuyFees(initialBuyFees);

    SellFees memory initialSellFees = SellFees({
      liquidityFee: 50,
      treasuryFee: 50,
      riskFreeValueFee: 100,
      totalFees: 0
    });
    setSellFees(initialSellFees);

    TransferFees memory initialTransferFees = TransferFees({
      liquidityFee: 50,
      treasuryFee: 30,
      riskFreeValueFee: 50,
      totalFees: 0
    });
    setTransferFees(initialTransferFees);

    Fees memory initialFees = Fees({
      burnFee: 0,
      galaxyBondFee: 0,
      realFeePartyArray: 490,
      isTaxBracketEnabledInMoveFee: false
    });
    setFees(initialFees);

    GameFees memory initialGameFees = GameFees({
      stakeFee: 10,
      depositLimit: 200
    });
    setGameFees(initialGameFees);
  }

  function setBuyFees(BuyFees memory _buyFees) public onlyOwner {
    buyFeeRevision.increment();

    buyFees[buyFeeRevision.current()] = BuyFees({
      liquidityFee: _buyFees.liquidityFee,
      treasuryFee: _buyFees.treasuryFee,
      riskFreeValueFee: _buyFees.riskFreeValueFee,
      totalFees: _buyFees.liquidityFee +  _buyFees.treasuryFee + _buyFees.riskFreeValueFee
    });

    require(buyFees[buyFeeRevision.current()].totalFees < MAX_TOTAL_BUY_FEE_RATE, "Max buy fee rate");

    emit SetBuyFees(buyFees[buyFeeRevision.current()]);
  }

  function currentBuyFees() external view override returns (BuyFees memory) {
    return buyFees[buyFeeRevision.current()];
  }

  function setSellFees(SellFees memory _sellFees) public onlyOwner {
    sellFeeRevision.increment();

    sellFees[sellFeeRevision.current()] = SellFees({
      liquidityFee: _sellFees.liquidityFee,
      treasuryFee: _sellFees.treasuryFee,
      riskFreeValueFee: _sellFees.riskFreeValueFee,
      totalFees: _sellFees.liquidityFee + _sellFees.treasuryFee + _sellFees.riskFreeValueFee
    });

    require(sellFees[sellFeeRevision.current()].totalFees < MAX_TOTAL_SELL_FEE_RATE, "Max sell fee rate");

    emit SetSellFees(sellFees[sellFeeRevision.current()]);
  }

  function currentSellFees() external view override returns (SellFees memory) {
    return sellFees[sellFeeRevision.current()];
  }

  function setTransferFees(TransferFees memory _transferFees) public onlyOwner {
    transferFeeRevision.increment();

    transferFees[transferFeeRevision.current()] = TransferFees({
      liquidityFee: _transferFees.liquidityFee,
      treasuryFee: _transferFees.treasuryFee,
      riskFreeValueFee: _transferFees.riskFreeValueFee,
      totalFees: _transferFees.liquidityFee +  _transferFees.treasuryFee + _transferFees.riskFreeValueFee
    });

    emit SetTransferFees(transferFees[transferFeeRevision.current()]);
  }

  function currentTransferFees() external view override returns (TransferFees memory) {
    return transferFees[transferFeeRevision.current()];
  }

  function setGameFees(GameFees memory _gameFees) public onlyOwner {
    gameFeeRevision.increment();

    gameFees[gameFeeRevision.current()] = GameFees({
      stakeFee: _gameFees.stakeFee,
      depositLimit: _gameFees.depositLimit
    });

    emit SetGameFees(gameFees[gameFeeRevision.current()]);
  }

  function currentGameFees() external view override returns (GameFees memory) {
    return gameFees[gameFeeRevision.current()];
  }

  function setFees(Fees memory _fees) public onlyOwner {
    feeRevision.increment();

    fees[feeRevision.current()] = Fees({
      burnFee: _fees.burnFee,
      galaxyBondFee: _fees.galaxyBondFee,
      realFeePartyArray: _fees.realFeePartyArray,
      isTaxBracketEnabledInMoveFee: _fees.isTaxBracketEnabledInMoveFee
    });

    require(fees[feeRevision.current()].realFeePartyArray < MAX_PARTY_ARRAY, "Max party array rate");

    emit SetFees(fees[feeRevision.current()]);
  }

  function currentFees() external view override returns (Fees memory) {
    return fees[feeRevision.current()];
  }

  function allCurrentFees() external view override returns (
    BuyFees memory,
    SellFees memory,
    GameFees memory,
    Fees memory
  ) {
    return (
      buyFees[buyFeeRevision.current()],
      sellFees[sellFeeRevision.current()],
      gameFees[gameFeeRevision.current()],
      fees[feeRevision.current()]
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ISphereSettings {
  struct BuyFees {
    uint liquidityFee;
    uint treasuryFee;
    uint riskFreeValueFee;
    uint totalFees;
  }

  struct SellFees {
    uint liquidityFee;
    uint treasuryFee;
    uint riskFreeValueFee;
    uint totalFees;
  }

  struct TransferFees {
    uint liquidityFee;
    uint treasuryFee;
    uint riskFreeValueFee;
    uint totalFees;
  }

  struct Fees {
    uint burnFee;
    uint galaxyBondFee;
    uint realFeePartyArray;
    bool isTaxBracketEnabledInMoveFee;
  }

  struct GameFees {
    uint stakeFee;
    uint depositLimit;
  }

  function currentBuyFees() external view returns (BuyFees memory);
  function currentSellFees() external view returns (SellFees memory);
  function currentTransferFees() external view returns (TransferFees memory);
  function currentGameFees() external view returns (GameFees memory);
  function currentFees() external view returns (Fees memory);
  function allCurrentFees() external view returns (
    BuyFees memory,
    SellFees memory,
    GameFees memory,
    Fees memory
  );

  event SetBuyFees(BuyFees fees);
  event SetSellFees(SellFees fees);
  event SetTransferFees(TransferFees fees);
  event SetGameFees(GameFees fees);
  event SetFees(Fees fees);
}

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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