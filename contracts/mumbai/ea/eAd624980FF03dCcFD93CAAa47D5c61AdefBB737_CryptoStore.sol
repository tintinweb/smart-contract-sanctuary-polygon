// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
pragma solidity 0.8.17;

import "./TokenManager.sol";
import "./FeesTaker.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CryptoStore is TokenManager, FeesTaker {
    using Counters for Counters.Counter;

    uint256 private _balance;
    Counters.Counter private _productIdCounter;

    mapping(uint256 => uint256) public productPrices;
    mapping(string => uint256) public txInAmounts;
    mapping(string => address) public txInAddresses;

    constructor() {
        _balance = 0;
        _productIdCounter.increment();
    }

    function AddProduct(uint256 productId, uint256 price) public OnlyOwner {
        require(price > 0, "Price should be greater than 0");
        require(productPrices[productId] == 0, "Product ID already in use");
        _productIdCounter.increment();
        productPrices[productId] = price;
    }

    function GetProductID() public OnlyOwner view returns (uint256) {
        return _productIdCounter.current();
    }

    function GetPriceWithFees(uint256 productId) public view returns (uint256) {
        require(productPrices[productId] > 0, "Invalid product ID");
        return (productPrices[productId] * (100 + TotalFees)) / 100;
    }

    function MakePayment(
        uint256 productId,
        uint256 amount,
        string memory txId
    ) public {
        uint256 fullPrice = GetPriceWithFees(productId);
        uint256 price = productPrices[productId];
        require(fullPrice == amount, "Wrong amount sent");
        require(txInAmounts[txId] == 0, "transacion ID already exists");
        require(
            txInAddresses[txId] == address(0),
            "transacion ID already exists"
        );
        txInAmounts[txId] = amount;
        txInAddresses[txId] = msg.sender;
        _distributeFees(msg.sender, price);
    }

    function _distributeFees(address sender, uint256 price) internal {
        _takeFees(_token, sender, price);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract FeesTaker is Ownable {

    address payable public Dev3Wallet = payable(0);
    address payable public Dev2Wallet = payable(0);
    address payable public Dev1Wallet = payable(0);
    address payable public FNXWallet = payable(0);
    address payable public RWOWallet = payable(0);
    address public contractAddress = address(this);

    uint256 public TotalFees;
    uint256 public Dev3Fee;
    uint256 public Dev2Fee;
    uint256 public Dev1Fee;
    uint256 public FNXFee;
    uint256 public RWOFee;

    event Dev1WalletUpdated(address indexed newWallet, address indexed oldWallet);
    event Dev2WalletUpdated(address indexed newWallet, address indexed oldWallet);
    event Dev3WalletUpdated(address indexed newWallet, address indexed oldWallet);
    event RWOWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event FNXWalletUpdated(address indexed newWallet, address indexed oldWallet);

    constructor() {
        uint256 _FNXFee = 2;
        uint256 _RWOFee = 2;
        uint256 _Dev1Fee = 1;
        uint256 _Dev2Fee = 1;
        uint256 _Dev3Fee = 1;

        FNXFee = _FNXFee;
        RWOFee = _RWOFee;
        Dev1Fee = _Dev1Fee;
        Dev2Fee = _Dev2Fee;
        Dev3Fee = _Dev3Fee;
        TotalFees = FNXFee + FNXFee + Dev1Fee + Dev2Fee + Dev3Fee;
    }

    function UpdateFees(
        uint256 _RWOFee, uint256 _FNXFee,
        uint256 _Dev1Fee, uint256 _Dev2Fee, uint256 _Dev3Fee) external OnlyOwner {
        FNXFee = _FNXFee;
        RWOFee = _RWOFee;
        Dev1Fee = _Dev1Fee;
        Dev2Fee = _Dev2Fee;
        Dev3Fee = _Dev3Fee;

        TotalFees = TotalFees = FNXFee + FNXFee + Dev1Fee + Dev2Fee + Dev3Fee;
        require(TotalFees <= 10, "Must keep fees at 10% or less");
    }

    function UpdateDev1Wallet(address dev1) external OnlyOwner {
        require(dev1 != address(0), "Zero address");
        require(dev1 != address(Dev1Wallet), "Same dev1 wallet");
        Dev1Wallet = payable(dev1);
    }

    function UpdateDev2Wallet(address dev2) external OnlyOwner {
        require(dev2 != address(0), "Zero address");
        require(dev2 != address(Dev2Wallet), "Same dev2 wallet");
        Dev2Wallet = payable(dev2);
    }

    function UpdateDev3Wallet(address dev3) external OnlyOwner {
        require(dev3 != address(0), "Zero address");
        require(dev3 != address(Dev3Wallet), "Same dev3 wallet");
        Dev3Wallet = payable(dev3);
    }

    function UpdateRWOWallet(address rwo) external OnlyOwner {
        require(rwo != address(0), "Zero address");
        require(rwo != address(RWOWallet), "Same rwo wallet");
        RWOWallet = payable(rwo);
    }

    function UpdateFNXWallet(address fnx) external OnlyOwner {
        require(fnx != address(0), "Zero address");
        require(fnx != address(FNXWallet), "Same fnx wallet");
        FNXWallet = payable(fnx);
    }

    function _takeFees(IERC20Metadata token, address sender, uint256 price) internal {
        uint256 dev1Amount = Dev1Fee * price / 100;
        uint256 dev2Amount = Dev2Fee * price / 100;
        uint256 dev3Amount = Dev3Fee * price / 100;
        uint256 rwoAmount = price + RWOFee * price / 100;
        uint256 fnxAmount = FNXFee * price / 100;
        token.transferFrom(sender, Dev1Wallet, dev1Amount);
        token.transferFrom(sender, Dev2Wallet, dev2Amount);
        token.transferFrom(sender, Dev3Wallet, dev3Amount);
        token.transferFrom(sender, RWOWallet, rwoAmount);
        token.transferFrom(sender, FNXWallet, fnxAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Ownable {
    address public owner; 

    constructor() {
        owner = msg.sender;
    }

    modifier OnlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./Ownable.sol";

contract TokenManager is Ownable {
    IERC20Metadata _token;

    constructor() {
        _token = IERC20Metadata(address(0));
    }

    function SetTokenAddress(address tokenAddress) external OnlyOwner {
        require(address(_token) == address(0), "Token address already set");
        _token = IERC20Metadata(tokenAddress);
    }

    function GetContractTokenBalance() public view OnlyOwner returns (uint256) {
        return _token.balanceOf(address(this));
    }

    function GetAllowance() public view returns (uint256) {
        return _token.allowance(msg.sender, address(this));
    }

    function GetTokenDecimals() public view returns (uint8) {
        return _token.decimals();
    }

    function GetTokenName() public view returns (string memory) {
        return _token.name();
    }

    function GetTokenSymbol() public view returns (string memory) {
        return _token.symbol();
    }
}