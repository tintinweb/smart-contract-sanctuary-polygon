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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
pragma solidity ^0.8.18;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

interface IOracle {

    event Subscribed(address indexed subscriber);
    event Unsubscribed(address indexed subscriber);
    event AllUpdated(address[] subscribers);
    
    function setEthPrice(uint ethPriceInPenny) external;

    function getWeiRatio() external view returns (uint);

    function subscribe(address subscriber) external;

    function unsubscribe(address subscriber) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

interface IOracleConsumer {

    event Updated(uint indexed timestamp, uint oldSupply, uint newSupply);
    
    function update(uint weisPerPenny) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStableCoin is IERC20 {
    function mint(address to, uint amount) external;
    
    function burn(address from, uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IOracleConsumer.sol";
import "./IStableCoin.sol";
import "./IOracle.sol";

contract Rebase is IOracleConsumer, Ownable, Pausable {
    address public oracle;
    address public stablecoin;
    uint public lastUpdate = 0; //timestamp em segundos
    uint private updateTolerance = 300; //segundos

    mapping(address => uint) public ethBalance; //customer => saldo em wei

    constructor(address oracleAddress, address stablecoinAddress) {
        oracle = oracleAddress;
        stablecoin = stablecoinAddress;
    }

    function initialize(uint weisPerPenny) external payable onlyOwner {
        require(weisPerPenny > 0, "Wei ratio cannot be zero");
        require(
            msg.value >= weisPerPenny,
            "Value cannot be less than wei ratio"
        );

        ethBalance[msg.sender] = msg.value;
        IStableCoin(stablecoin).mint(msg.sender, msg.value / weisPerPenny);
        lastUpdate = block.timestamp;
    }

    function setOracle(address newOracle) external onlyOwner {
        require(newOracle != address(0), "Oracle address cannot be zero");
        oracle = newOracle;
    }

    function setUpdateTolerance(uint toleranceInSeconds) external onlyOwner {
        require(toleranceInSeconds > 0, "toleranceInSeconds cannot be zero");
        updateTolerance = toleranceInSeconds;
    }

    function update(uint weisPerPenny) external {
        require(msg.sender == oracle, "Only the oracle can make this call");
        uint oldSupply = IStableCoin(stablecoin).totalSupply();
        uint newSupply = adjustSupply(weisPerPenny);

        if(newSupply != 0){
            lastUpdate = block.timestamp;
            emit Updated(lastUpdate, oldSupply, newSupply);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //100 = 1:1, 97 = 0.97, 104 = 1.04
    function getParity(uint weisPerPenny) public view returns (uint) {
        if (weisPerPenny == 0) weisPerPenny = IOracle(oracle).getWeiRatio();
        return
            (IStableCoin(stablecoin).totalSupply() * 100) /
            (address(this).balance / weisPerPenny);
    }

    function deposit() external payable whenNotPaused whenNotOutdated {
        uint weisPerPenny = IOracle(oracle).getWeiRatio();
        require(msg.value >= weisPerPenny, "Insufficient deposit");

        ethBalance[msg.sender] = msg.value;
        uint tokens = msg.value / weisPerPenny;
        IStableCoin(stablecoin).mint(msg.sender, tokens);
    }

    function withdrawEth(
        uint amountEth
    ) external whenNotPaused whenNotOutdated {
        require(
            ethBalance[msg.sender] >= amountEth,
            "Insufficient ETH balance"
        );

        ethBalance[msg.sender] -= amountEth;
        uint weisPerPenny = IOracle(oracle).getWeiRatio();
        IStableCoin(stablecoin).burn(msg.sender, amountEth / weisPerPenny);
        payable(msg.sender).transfer(amountEth);
    }

    function withdrawUsda(
        uint amountUsda
    ) external whenNotPaused whenNotOutdated {
        require(
            IStableCoin(stablecoin).balanceOf(msg.sender) >= amountUsda,
            "Insufficient USDA balance"
        );
        IStableCoin(stablecoin).burn(msg.sender, amountUsda);

        uint weisPerPenny = IOracle(oracle).getWeiRatio();
        uint amountEth = amountUsda * weisPerPenny;
        ethBalance[msg.sender] -= amountEth;

        payable(msg.sender).transfer(amountEth);
    }

    function adjustSupply(uint weisPerPenny) internal returns (uint) {
        uint parity = getParity(weisPerPenny);

        if (parity == 0) {
            _pause();
            return 0;
        }

        IStableCoin algoDollar = IStableCoin(stablecoin);
        uint totalSupply = algoDollar.totalSupply();

        if (parity == 100) return totalSupply;
        if (parity > 100) {
            algoDollar.burn(owner(), (totalSupply * (parity - 100)) / 100);
        } else if (parity < 100) {
            algoDollar.mint(owner(), (totalSupply * (100 - parity)) / 100);
        }

        return algoDollar.totalSupply();
    }

    modifier whenNotOutdated() {
        require(
            lastUpdate >= (block.timestamp - updateTolerance),
            "Rebase contract is paused. Try again later or contact the admin"
        );
        _;
    }
}