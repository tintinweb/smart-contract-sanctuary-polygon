//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NVG8Marketplace is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _dataTokenIdCounter;

    // enlist when a data token created
    // sell/ buy data token
    // rent data token for use
    //
    /*
                     _______________                   
                    /\             /\
                   /  \           /  \
                  /    \         /    \
                 /      \_______/      \
                /  ___            ___   \
               [| / 0 \          / 0 \  |]
               [|                       |]
                \         _  _          /
                 \       | \/ |        /
                  \     ________      /
                   \   /--------\    /
                    \       _       /
                     \_____/ \_____/

*/
    // EVENTS

    // STRUCTS
    struct DataToken {
        address erc721Token;
        address erc20Token;
        address owner;
        string name;
        string symbol;
        uint256 usagePrice;
    }

    // STATE VARIABLES
    mapping(uint256 => DataToken) public dataTokens;
    address public nvg8Factory;

    // MODIFIERS
    modifier onlyFactoryOrOwner() {
        require(msg.sender == nvg8Factory || msg.sender == owner());
        _;
    }

    // CONSTRUCTOR
    constructor() {}

    function enlistDataToken(
        address _erc721Token,
        address _erc20Token,
        address _owner,
        string memory _name,
        string memory _symbol,
        uint256 _usagePrice
    ) public onlyFactoryOrOwner returns (bool _success) {
        // check if the data token is already enlisted
        uint256 _dataTokenId = _dataTokenIdCounter.current();
        _dataTokenIdCounter.increment();
        // enlist data token
        DataToken memory dataToken = DataToken(
            _erc721Token,
            _erc20Token,
            _owner,
            _name,
            _symbol,
            _usagePrice
        );
        dataTokens[_dataTokenId] = dataToken;
        return true;
    }

    // FUCTIONS FOR FACTORY CONTRACT
    function setFactory(address _nvg8Factory) public onlyOwner {
        nvg8Factory = _nvg8Factory;
    }
}


// TO TEST
// factory deploys data token templates (ERC721,ERC20 pair)
// factory deploys marketplace contract
// user calls factory to create and enlist data token
// factory contract calls marketplace contract to enlist data token

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