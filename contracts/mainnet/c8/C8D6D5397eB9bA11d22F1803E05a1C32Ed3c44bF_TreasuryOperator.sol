// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "ITreasury.sol";
import "Operator.sol";


contract TreasuryOperator is Operator {

    address[] public _treasury;

    function initialize(
        address treasury,
        address token,
        address share,
        address oracle,
        address boardroom,
        uint256 start_time
    ) internal {
        ITreasury(treasury).initialize(token, share, oracle, boardroom, start_time);
    }

    function doubleInitialize(
        address treasury1,
        address treasury2,

        address token1,
        address token2,

        address oracle1,
        address oracle2,

        address boardroom1,
        address boardroom2,

        address share,
        uint256 start_time
    ) external {
        initialize(treasury1, token1, share, oracle1, boardroom1, start_time);
        initialize(treasury2, token2, share, oracle2, boardroom2, start_time);
    }

    function addTreasury(address[] memory _address) external onlyOperator {
        for(uint i = 0; i < _address.length; i++){
            require(_address[i] != address(0),'0 address');
            _treasury.push(_address[i]);
        }
    }

    function allocate() external {
        for(uint i = 0; i < _treasury.length; i++){
            try ITreasury(_treasury[i]).allocateSeigniorage() {
            }catch{}
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ITreasury {
    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);

    function transferOperator(address newOperator_) external;

    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getTokenPrice() external view returns (uint256);

    function getRealtimeTokenIndexPrice() external view returns (uint256);

    function initialize(address token, address share, address oracle, address boardroom, uint256 start_time) external;

    function allocateSeigniorage() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "Context.sol";
import "Ownable.sol";

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() internal {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}