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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Governance is Ownable {
    uint256 public randomness;
    uint256 public fee;
    uint256 public lottoFundPrice;
    uint256 public lotteryDuration;
    address lottoFund;
    address public admin;

    constructor(
        address _admin,
        uint256 _fee,
        uint256 _lottoFundPrice,
        uint256 _duration
    ) {
        assert(_admin != address(0));
        assert(_fee != 0);
        assert(_lottoFundPrice != 0);
        admin = _admin;
        fee = _fee;
        lottoFundPrice = _lottoFundPrice;
        lotteryDuration = _duration;
    }

    function changeFee(uint256 _fee) external virtual onlyOwner {
        require(_fee < 5 * 10**15, "governance/over-fee"); // 0.5% Max Fee.
        fee = _fee;
    }

    function changelottoFundPrice(uint256 _price) external virtual onlyOwner {
        require(_price < 1 * 10**18, "governance/over-price"); // 1$ Max Price.
        lottoFundPrice = _price;
    }

    function changeDuration(uint256 _time) external virtual onlyOwner {
        require(_time <= 30 days, "governance/over-price"); // 30 days Max duration
        lotteryDuration = _time;
    }

    function changeRandom(uint256 _randomness) external virtual onlyOwner {
        require(
            _randomness != randomness,
            "governance/same-randomnesss-address"
        );
        randomness = _randomness;
    }

    function getAdmin() external view returns (address) {
        return admin;
    }
}