// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "../interfaces/ISELLER.sol";
import "../interfaces/IVESTING.sol";

contract Seller is ISeller, ReentrancyGuardUpgradeable {
    //////////////////////////////////////////////////////////////////////////////////////////////////
    // State
    ////////////////////////////////////////////////////////////////////////////////////////////////// 

    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    // Contract to manage account permissions (roles)
    address public s_manager;

    // Sales variables
    uint256 public s_price;
    uint256 public s_maxTime;
    uint256 public s_minStableCoin;

    // ERC20 token (StableCoin) to sale
    IERC20Metadata public s_stableCoin;

    // Currency/Token of payment and beneficiary address
    IERC20Metadata public s_coinPayments;
    address public s_beneficiaryPaymets;

    // Vesting contract
    address public s_vesting;

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Initialization
    //////////////////////////////////////////////////////////////////////////////////////////////////

    /*
        * @title Initialize function.
        * @dev Initializes the Seller smart contract with the provided parameters.
        *
        * @param p_stableCoin: The address of the stablecoin to be sold.
        * @param p_coinPayments: The address of the ERC20 token used for payment.
        * @param p_beneficiaryPaymets: The address where the payment tokens will be sent.
        * @param p_manager: The address of the contract managing account permissions (roles).
    */

    function initialize(
        address p_stableCoin, 
        address p_coinPayments, 
        address p_beneficiaryPaymets, 
        address p_manager
    ) public initializer {
        __ReentrancyGuard_init();

        require(p_stableCoin != address(0), "Seller: Invalid stableCoin address");
        require(p_coinPayments != address(0), "Seller: Invalid stableCoinPayments address");
        require(p_beneficiaryPaymets != address(0), "Seller: Invalid beneficiaryPaymets address");
        require(p_manager != address(0), "Seller: Invalid manager address");

        s_stableCoin = IERC20Metadata(p_stableCoin);
        s_coinPayments = IERC20Metadata(p_coinPayments);
        s_beneficiaryPaymets = p_beneficiaryPaymets;
        s_manager = p_manager;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Public functions
    ////////////////////////////////////////////////////////////////////////////////////////////////// 

    // => View functions

    /*
        * @title Calculate Payment Amount.
        * @dev Calculates the amount of payment tokens required for a given amount of stablecoin.
        *
        * @param p_amountStableCoin: The amount of stablecoin desired.
        *
        * @return The calculated amount of payment tokens required.
    */
    function priceAmountStableCoin(uint256 p_amountStableCoin) public view override returns(uint256) { 
        return (p_amountStableCoin * s_price ) / (1 * 10 ** s_stableCoin.decimals());
    }

    /*
        * @title Get Maximum Amount to Buy.
        * @dev Returns the maximum amount of stablecoin that can be purchased.
        *
        * @return The maximum amount of stablecoin that can be bought.
    */
    function maxAmountToBuy() public view override returns(uint256) { 
        return s_stableCoin.balanceOf(address(this));
    }

    /*
        * @title Get Minimum Amount to Buy.
        * @dev Returns the minimum amount of stablecoin that can be purchased.
        *
        * @return The minimum amount of stablecoin that can be bought.
    */
    function minAmountToBuy() public view override returns(uint256) {
        return _minAmountToBuy();
    }

    /*
        * @title Get Stablecoin Information.
        * @dev Returns information about the stablecoin being sold.
        *
        * @return The address, name, symbol, total supply, and decimals of the stablecoin.
    */
    function stableCoin() public view override returns(address, string memory, string memory, uint256, uint256) {
        return (address(s_stableCoin), s_stableCoin.name(), s_stableCoin.symbol(), s_stableCoin.totalSupply(), s_stableCoin.decimals()); 
    }

    /*
        * @title Get Payment Token Information.
        * @dev Returns information about the payment token used to purchase the stablecoin.
        *
        * @return The address, name, symbol, and decimals of the payment token.
    */
    function coinPayments() public view override returns(address, string memory, string memory, uint256) {
        return (address(s_coinPayments), s_coinPayments.name(), s_coinPayments.symbol(), s_coinPayments.decimals()); 
    }

    // => Set functions

    /*
        * @title Set Manager.
        * @dev This function allows changing the manager address.
        *
        * @param p_manager: The new manager address with administrative permissions.
        *
        * Requirements:
        * - The caller must have the ADMIN_ROLE to execute the function.
    */
    function setManager(address p_manager) public override {
        require(IAccessControlUpgradeable(s_manager).hasRole(ADMIN_ROLE, msg.sender), "Seller: without permission");  
        s_manager = p_manager;
    }

    /*
        * @title Set Beneficiary Payments.
        * @dev This function allows changing the beneficiary address for receiving payments.
        *
        * @param p_beneficiaryPaymets: The new beneficiary address for receiving payments.
        *
        * Requirements:
        * - The caller must have the ADMIN_ROLE to execute the function.
    */
    function setBeneficiaryPaymets(address p_beneficiaryPaymets) public override {
        require(IAccessControlUpgradeable(s_manager).hasRole(ADMIN_ROLE, msg.sender), "Seller: without permission");
        s_beneficiaryPaymets = p_beneficiaryPaymets;
    }

    /*
        * @title Set Payment Token.
        * @dev This function allows changing the payment token used to buy stablecoin.
        *
        * @param p_coinPayments: The new payment token address.
        *
        * Requirements:
        * - The caller must have the ADMIN_ROLE to execute the function.
    */
    function setCoinPayments(address p_coinPayments) public override {
        require(IAccessControlUpgradeable(s_manager).hasRole(ADMIN_ROLE, msg.sender), "Seller: without permission");
        s_coinPayments = IERC20Metadata(p_coinPayments);
    }

    /*
        * @title Set Vesting contract.
        * @dev This function allows changing the vesting contract.
        *
        * @param p_coinPayments: The new payment token address. If it is a zero address (by default), there is no vesting.
        *
        * Requirements:
        * - The caller must have the ADMIN_ROLE to execute the function.
    */
    function setVesting(address p_vesting) public override {
        require(IAccessControlUpgradeable(s_manager).hasRole(ADMIN_ROLE, msg.sender), "Seller: without permission");  
        s_vesting = p_vesting;
    } 
    
    /*
        * @title Buy with Signature.
        * @dev This function allows the purchase of stablecoins using a signed message.
        * The buyer sends the payment in the form of a token (s_coinPayments) to the beneficiary (s_beneficiaryPaymets).
        * The stablecoins are then transferred to the buyer.
        *
        * @param p_amountStableCoin: The amount of stablecoins to buy.
        * @param p_signature: The signed message containing the buyer's address, the amount of stablecoins to buy, and the contract address.
        *
        * Requirements:
        * - The buyer must have enough tokens (s_coinPayments) to make the purchase.
        * - The signer of the message must have the ADMIN_ROLE.
        * - The signature does not have to be expired.
        * - The amount of stablecoins to buy must be between 1 and 100,000,000 tokens (in wei).
        * - The total payment in s_coinPayments must be greater than or equal to 1 * 10 ** s_stableCoin.decimals().
        * - The function must not be called in a reentrant manner.
        * 
        * Emits a newPurchase event with the buyer's address, the amount of stablecoins purchased, the payment token address, and the total payment made.
    */
    function buyWithSignature(uint256 p_amountStableCoin, uint256 p_maxTimeStamp, bytes memory p_signature) public nonReentrant override {
        _requerimentsBuyChecking(p_amountStableCoin); 

        address signer = _recoverSigner(keccak256(abi.encodePacked(msg.sender, p_amountStableCoin, p_maxTimeStamp, address(this))), p_signature);
        require(IAccessControlUpgradeable(s_manager).hasRole(ADMIN_ROLE, signer), "Seller: without permission");

        require(block.timestamp <= p_maxTimeStamp, "Seller: signature expired");
        require(p_amountStableCoin >= 1 && p_amountStableCoin <= 100000000 * 1 ether, "Seller: calculation error");
        require(p_amountStableCoin * s_price >= 1 * 10 ** s_stableCoin.decimals(), "Seller: calculation error");
        uint256 totalToPay = (p_amountStableCoin * s_price) / (1 * 10 ** s_stableCoin.decimals());

        require(s_coinPayments.transferFrom(msg.sender, s_beneficiaryPaymets, totalToPay), "Seller: error transfer payment");

        if (s_vesting == address(0)) {
            require(s_stableCoin.transfer(msg.sender, p_amountStableCoin), "Seller: error transfer stablecoin");
        } else {
            require(s_stableCoin.transfer(s_vesting, p_amountStableCoin), "Seller: error transfer stablecoin");
            require(IVesting(s_vesting).addPurchase(msg.sender, p_amountStableCoin), "Seller: error transfer to vesting contract");
        }

        emit newPurchase(msg.sender, p_amountStableCoin, address(s_coinPayments), totalToPay);
    }

    /*
        * @title Activate Sales.
        * @dev This function activates or updates the sale of stablecoins with new parameters.
        *
        * @param p_priceOneStableCoin: The price of one stablecoin in the payment token.
        * @param p_maxTimeHours: The maximum duration of the sale in hours.
        * @param p_minStableCoin: The minimum amount of stablecoin required for purchase.
        *
        * Requirements:
        * - The caller must have the ADMIN_ROLE to execute the function.
        * - The price, maximum time, and minimum stablecoin must be valid.
        *
        * Events:
        * - Emits an "activatedSale" event if it's the first time the sale is activated.
        * - Emits an "updatedSale" event if the sale is already active and updated.
    */
    function activateSales(uint256 p_priceOneStableCoin, uint256 p_maxTimeHours, uint256 p_minStableCoin) public override { 
        require(IAccessControlUpgradeable(s_manager).hasRole(ADMIN_ROLE, msg.sender), "Whitelist: without permission");

        uint256 balance = s_stableCoin.balanceOf(address(this));

        require(p_priceOneStableCoin > 0, "Seller: insufficient price");
        require(p_maxTimeHours >= 1, "Seller: insufficient time");
        require(p_minStableCoin > 0 && p_minStableCoin <= balance && balance > 0, "Seller: error amount tokens");

        uint256 lastPrice = s_price;

        s_price = p_priceOneStableCoin;
        s_minStableCoin = p_minStableCoin; 
        s_maxTime = block.timestamp + (p_maxTimeHours * 1 hours);         

        if (lastPrice == 0) { emit activatedSale(msg.sender, s_stableCoin.balanceOf(address(this)), s_price, s_maxTime, s_minStableCoin); }
        if (lastPrice > 0) { emit updatedSale(msg.sender, s_stableCoin.balanceOf(address(this)), s_price, s_maxTime, s_minStableCoin); }
    }

    /*
        * @title Set Price of One Token.
        * @dev This function allows changing the price of one stablecoin in the payment token.
        *
        * @param p_priceOneStableCoin: The new price of one stablecoin in the payment token.
        *
        * Requirements:
        * - The caller must have the ADMIN_ROLE to execute the function.
        * - The new price must be valid.
        *
        * Events:
        * - Emits an "updatedSale" event after updating the price.
    */
    function setPriceOneToken(uint256 p_priceOneStableCoin) public override { 
        require(IAccessControlUpgradeable(s_manager).hasRole(ADMIN_ROLE, msg.sender), "Seller: without permission");
        require(p_priceOneStableCoin > 0, "Seller: insufficient price");
        
        s_price = p_priceOneStableCoin;

        emit updatedSale(msg.sender, s_stableCoin.balanceOf(address(this)), s_price, s_maxTime, s_minStableCoin);
    }

    /*
        * @title Set Max Time.
        * @dev This function allows changing the maximum duration of the sale in hours.
        *
        * @param p_maxTimeHours: The new maximum duration of the sale in hours.
        *
        * Requirements:
        * - The caller must have the ADMIN_ROLE to execute the function.
        * - The new maximum time must be valid.
        *
        * Events:
        * - Emits an "updatedSale" event after updating the maximum time.
    */
    function setMaxTime(uint256 p_maxTimeHours) public override {
        require(IAccessControlUpgradeable(s_manager).hasRole(ADMIN_ROLE, msg.sender), "Seller: without permission");
        require(p_maxTimeHours >= 1, "Seller: insufficient time");
        
        s_maxTime = block.timestamp + (p_maxTimeHours * 1 hours);

        emit updatedSale(msg.sender, s_stableCoin.balanceOf(address(this)), s_price, s_maxTime, s_minStableCoin);  
    }

    /*
        * @title Set Min Stablecoin.
        * @dev This function allows changing the minimum amount of stablecoin required for purchase.
        *
        * @param p_minStableCoin: The new minimum amount of stablecoin required for purchase.
        *
        * Requirements:
        * - The caller must have the ADMIN_ROLE to execute the function.
        * - The new minimum stablecoin must be valid.
        *
        * Events:
        * - Emits an "updatedSale" event after updating the minimum stablecoin.
    */
    function setMinStableCoin(uint256 p_minStableCoin) public override {
        require(IAccessControlUpgradeable(s_manager).hasRole(ADMIN_ROLE, msg.sender), "Seller: without permission");

        uint256 balance = s_stableCoin.balanceOf(address(this));
        require(p_minStableCoin > 0 && p_minStableCoin <= balance && balance > 0, "Seller: error amount stablecoin");
        
        s_minStableCoin = p_minStableCoin;

        emit updatedSale(msg.sender, s_stableCoin.balanceOf(address(this)), s_price, s_maxTime, s_minStableCoin);
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Internal functions
    //////////////////////////////////////////////////////////////////////////////////////////////////

    function _minAmountToBuy() private view returns(uint256) { 
        uint256 balance = s_stableCoin.balanceOf(address(this));

        if (balance < s_minStableCoin) {
            return balance;
        }

        return s_minStableCoin;
    }

    function _requerimentsBuyChecking(uint256 p_amountToken) private view {
        uint256 balance = s_stableCoin.balanceOf(address(this));

        require(s_maxTime >= block.timestamp, "Sales closed");
        require(s_price > 0, "Error price");
        require(p_amountToken <= balance && balance > 0, "Contract has insufficient balance to sell");
        require(p_amountToken >= _minAmountToBuy(), "Buy below the minimum");
    }

    function _recoverSigner(bytes32 p_message, bytes memory p_signature) private pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = _splitSignature(p_signature);

        return ecrecover(p_message, v, r, s);
    }

    function _splitSignature(bytes memory p_signature) private pure returns (uint8, bytes32, bytes32) {
        require(p_signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(p_signature, 32))
            s := mload(add(p_signature, 64))
            v := byte(0, mload(add(p_signature, 96)))
        }
    
        return (v, r, s);
    }
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVesting {
    // EVENTS 
    event PurchaseAdded(address indexed e_buyer, uint256 e_amount);
    event stableCoinClaimed(address indexed e_buyer, uint256 e_amount);

    // STRUCTS
    struct Purchase {
        uint256 amount;
        uint256 timestamp;
        uint256 amountClaimed;
    }
    
    // VIEW FUNCTIONS
    function calculateClaimable(address p_buyer) external view returns(uint256);

    // SET FUNCTIONS
    function setManager(address p_manager) external;
    function setSaleContract(address p_saleContract) external;
    function addPurchase(address p_buyer, uint256 p_amount) external returns(bool);
    function claim() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISeller {
    // EVENTS
    event newPurchase(address e_buyerAddress, uint256 e_amountStableCoin, address e_coinPayment, uint256 e_amountPayment);
    event activatedSale(address e_sellerAddress, uint256 e_amountStableCoin, uint256 e_priceOneStableCoin, uint256 e_maxTimeHours, uint256 e_minSableCoin);
    event updatedSale(address e_sellerAddress, uint256 e_amountStableCoin, uint256 e_priceOneStableCoin, uint256 e_maxTimeHours, uint256 e_minSableCoin);

    // VIEW FUNCTIONS
    function priceAmountStableCoin(uint256 p_amountStableCoin) external view returns(uint256);
    function maxAmountToBuy() external view returns(uint256);
    function minAmountToBuy() external view returns(uint256);
    function stableCoin() external view returns(address, string memory, string memory, uint256, uint256);
    function coinPayments() external view returns(address, string memory, string memory, uint256);

    // SET FUNCTIONS
    function setManager(address p_manager) external;
    function setBeneficiaryPaymets(address p_beneficiaryPaymets) external;
    function setCoinPayments(address p_coinPayments) external;
    function setVesting(address p_vesting) external;
    function buyWithSignature(uint256 p_amountStableCoin, uint256 p_maxTimeStamp, bytes memory p_signature) external;
    function activateSales(uint256 p_priceOneStableCoin, uint256 p_maxTimeHours, uint256 p_minStableCoin) external;
    function setPriceOneToken(uint256 p_priceOneStableCoin) external;
    function setMaxTime(uint256 p_maxTimeHours) external;
    function setMinStableCoin(uint256 p_minStableCoin) external;
}