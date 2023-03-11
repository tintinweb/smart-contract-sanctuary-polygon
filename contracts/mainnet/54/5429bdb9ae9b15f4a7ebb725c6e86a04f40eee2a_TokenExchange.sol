/**
 *Submitted for verification at polygonscan.com on 2023-03-10
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: GetDarkx.sol

pragma solidity ^0.8.0;


// Declare the interface for the ERC20 token contracts
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

// Declare the interface for the price oracle
interface IPriceOracle {
    function consult(address token, uint amount) external view returns (uint144);

}

contract TokenExchange is Ownable {
    // Declare the addresses of the ERC20 tokens and the price oracle
    address public constant MATIC_ADDRESS = 0x0000000000000000000000000000000000001010;
    address public constant DARKX_ADDRESS = 0x267676A178Ea90a6dde08D09094aA95EECc3fa59;
    address public constant PRICE_ORACLE_ADDRESS = 0x1609E455b0Dcd82b2aBDc5d2D761a1251802B6f4;

    // Declare the function for exchanging tokens
    function exchangeTokens() external payable {
        // Require that the user sends at least 0.3 MATIC
        require(msg.value >= 0.3 ether, "Insufficient MATIC sent");

        // Create instances of the ERC20 token contracts and the price oracle
        IERC20 matic = IERC20(MATIC_ADDRESS);
        IERC20 darkx = IERC20(DARKX_ADDRESS);
        IPriceOracle priceOracle = IPriceOracle(PRICE_ORACLE_ADDRESS);

        // Get the current DARKX price from the price oracle
        IPriceOracle oracle = IPriceOracle(PRICE_ORACLE_ADDRESS);
        uint256 darkxPrice = oracle.consult(DARKX_ADDRESS, 1e18);
        

        // Calculate the amount of DARKX tokens to send back to the user
        uint256 darkxAmount = (msg.value * 10**18) / darkxPrice;

        // Transfer the MATIC tokens from the user to the contract
        require(matic.transferFrom(msg.sender, address(this), msg.value), "MATIC transfer failed");

        // Transfer the DARKX tokens from the contract to the user
        require(darkx.transfer(msg.sender, darkxAmount), "DARKX transfer failed");
    }

    // Declare the function for the owner to withdraw DARKX tokens
    function withdrawDarkx(uint256 amount) external onlyOwner {
        // Create an instance of the DARKX token contract
        IERC20 darkx = IERC20(DARKX_ADDRESS);

        // Transfer the specified amount of DARKX tokens from the contract to the owner
        require(darkx.transfer(owner(), amount), "DARKX transfer failed");
    }

    // Declare the function for the owner to withdraw MATIC tokens
    function withdrawMatic(uint256 amount) external onlyOwner {
        // Create an instance of the MATIC token contract
        IERC20 matic = IERC20(MATIC_ADDRESS);

        // Transfer the specified amount of MATIC tokens from the contract to the owner
        require(matic.transfer(owner(), amount), "MATIC transfer failed");
    }
}