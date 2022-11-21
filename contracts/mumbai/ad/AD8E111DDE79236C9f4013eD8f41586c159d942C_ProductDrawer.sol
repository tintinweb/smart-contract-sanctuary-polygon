// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IWhitelist.sol";
import "./interfaces/IProductStore.sol";


contract ProductDrawer is Ownable, Pausable {
    IWhitelist whitelist;
    IProductStore productStore;
    uint256 public drawFee;
    address cashier;
    uint256[] public productIds;
    // productId to quota
    mapping(uint256 => uint256) public productQuotas;
    uint256 public totalQuota;
    bool public isWhitelistMint = false;
    bool public isPublicMint = false;

    event WhitelistUpdated(address oldWhitelist, address newWhitelist);
    event DrawFeeUpdated(uint256 newFee);
    event CashierUpdated(address oldCashier, address newCashier);
    event ProductStoreUpdated(address oldProductStore, address newProductStore);
    event Drawn(address user, uint256 productId);

    modifier onlyWhitelistMint() {
        require(isWhitelistMint, "ProductDrawer: whitelist mint not started");
        _;
    }

    modifier onlyPublicMint() {
        require(isPublicMint, "ProductDrawer: public mint not started");
        _;
    }

    modifier canDraw(uint256 amount) {
        require(totalQuota > 0, "ProductDrawer: zero draw quota");
        require(amount <= getMaxDraw(), "ProductDrawer: exceeds max draw");
        require(amount <= totalQuota, "ProductDrawer: exceeds total quota");
        require(msg.value >= amount * drawFee, "ProductDrawer: insufficient fee");
        _;
    }

    constructor (
        address _whitelist,
        address _productStore,
        uint256 _drawFee,
        address _cashier
    ) {
        whitelist = IWhitelist(_whitelist);
        productStore = IProductStore(_productStore);
        drawFee = _drawFee;
        cashier = _cashier;
    }

    function setWhitelist(address _whitelist) public onlyOwner {
        require(_whitelist != address(0), "ProductDrawer: zero address");
        address oldWhitelist = address(whitelist);
        whitelist = IWhitelist(_whitelist);

        emit WhitelistUpdated(oldWhitelist, _whitelist);
    }

    function setDrawFee(uint256 _drawFee) public onlyOwner {
        require(_drawFee > 0, "ProductDrawer: zero draw fee");
        drawFee = _drawFee;

        emit DrawFeeUpdated(_drawFee);
    }

    function setCashier(address _cashier) public onlyOwner {
        require(_cashier != address(0), "ProductDrawer: zero address");
        address oldCashier = cashier;
        cashier = _cashier;

        emit CashierUpdated(oldCashier, _cashier);
    }

    function setProductStore(address _productStore) public onlyOwner {
        require(_productStore != address(0), "ProductDrawer: zero address");
        address oldProductStore = address(productStore);
        productStore = IProductStore(_productStore);

        emit ProductStoreUpdated(oldProductStore, _productStore);
    }

    function setProductQuotas(uint256[] calldata _productIds, uint256[] calldata quotas) public onlyOwner {
        require(_productIds.length == quotas.length, "ProductDrawer: product and quota length mismatch");
        delete productIds;
        totalQuota = 0;
        for (uint256 i = 0; i < _productIds.length; i++) {
            uint256 id = _productIds[i];

            productIds.push(id);
            productQuotas[id] = quotas[i];
            totalQuota += quotas[i];
        }
    }

    function setWhitelistMint(bool isLive) external onlyOwner {
        if (isLive) {
            require(!isPublicMint, "ProductDrawer: public mint is live");
        }
        isWhitelistMint = isLive;
    }

    function setPublicMint(bool isLive) external onlyOwner {
        if (isLive) {
            require(!isWhitelistMint, "ProductDrawer: whitelist mint is live");
        }
        isPublicMint = isLive;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getMaxDraw() public view returns (uint256) {
        return productStore.getMaxMint();
    }

    function whitelistMint() public payable onlyWhitelistMint canDraw(1) {
        require(
            whitelist.isWhitelist(msg.sender),
            "ProductDrawer: not in whitelist"
        );

        _draw(1);
        whitelist.removeFromList(msg.sender);
    }

    function mint(uint256 amount) public payable onlyPublicMint canDraw(amount) {
        _draw(amount);
    }

    function _draw(uint256 amount) internal {
        payable(cashier).transfer(payable(address(this)).balance);
        
        for (uint256 i = 0; i < amount; i ++) {
            uint256 index = uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        block.coinbase,
                        block.difficulty,
                        block.gaslimit,
                        block.timestamp + i + 1
                    )
                )
            ) % productIds.length;

            uint256 productId = productIds[index];

            productStore.getDrawnNFT(productId, msg.sender);

            totalQuota -= 1;
            productQuotas[productId] -= 1;
            if (productQuotas[productId] == 0) {
                productIds[index] = productIds[productIds.length - 1];
                productIds.pop();
            }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IWhitelist {
    function isWhitelist(address addr) external returns (bool);

    function removeFromList(address addr) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IProductStore {
    function getMaxMint() external view returns (uint256);
    function getDrawnNFT(uint256 productId, address to) external;
}

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