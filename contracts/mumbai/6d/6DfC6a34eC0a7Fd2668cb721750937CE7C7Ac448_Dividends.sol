// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IDIVIDENDS.sol";
import "../interfaces/ISELLER.sol";
import "../interfaces/ITOKENHOLDINGS.sol";

contract Dividends is IDIVIDENDS, Pausable, Ownable {
    //////////////////////////////////////////////////////////////////////////////////////////////////
    // State
    ////////////////////////////////////////////////////////////////////////////////////////////////// 

    // addressHoldings => Bool
    mapping(address => bool) private s_authorized;

    // addressUser => addressHoldings => claimed amount
    mapping(address => mapping(address => uint256)) private s_claimedDividends;
    mapping(address => mapping(address => uint256)) private s_claimedRealDividends;

    // addressUser => addressHoldings => to claim (transfers)
    mapping(address => mapping(address => uint256)) private s_toClaim;
    
    // addressHoldings => amount dividends per stock
    mapping(address => uint256) private s_amountDividendsStock;

    // Signatures
    mapping(bytes => bool) private s_signatures;
    address private s_signer;

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Constructor
    ////////////////////////////////////////////////////////////////////////////////////////////////// 

    constructor(address p_addressManager) {
        _transferOwnership(p_addressManager);
        s_signer = msg.sender;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Public functions
    //////////////////////////////////////////////////////////////////////////////////////////////////

    // => View functions

    function signer() public view override returns(address) { 
        return s_signer;
    }

    function authorized(address p_contractHoldings) public view override returns(bool) { 
        return s_authorized[p_contractHoldings];
    }

    function amountStock(address p_contractHoldings) public view override returns(uint256) { 
        return s_amountDividendsStock[p_contractHoldings];
    }

    function infoClaimDividends(address p_contractHoldings, address p_addressHolder) public view override returns(uint256) {
        return _infoClaimDividends(p_contractHoldings, p_addressHolder);
    }

    function infoClaimedDividends(address p_contractHoldings, address p_addressHolder) public view override returns(uint256) {
        return s_claimedRealDividends[p_addressHolder][p_contractHoldings];
    }

    function numberStocksSoldDirectlyAndCompany(address p_contractHoldings) public view override returns(uint256, uint256) {
        uint256 company = ISELLER(ITOKENHOLDINGS(p_contractHoldings).seller()).throughCompany(); 
        uint256 direct = IERC20(p_contractHoldings).totalSupply() - company;
        return (direct, company);
    }

    // => Set functions

    function setSigner(address p_signer) public onlyOwner override {
        s_signer = p_signer;
    }

    function setPause(bool p_pause) public onlyOwner override { 
        if (p_pause) {
            _pause();
        } else {
            _unpause();
        }
    } 

    function addDividends(address p_origin, address p_contractHoldings, uint256 p_amountIncrementDividends) public onlyOwner override {
        (uint256 stocks, ) = numberStocksSoldDirectlyAndCompany(p_contractHoldings);

        require(p_amountIncrementDividends >= stocks, "Error values");

        uint256 incrementStock = p_amountIncrementDividends / stocks;
        s_amountDividendsStock[p_contractHoldings] += incrementStock;

        (address addressStableCoin, , ) = ISELLER(ITOKENHOLDINGS(p_contractHoldings).seller()).stableCoin(); 
        require(
            IERC20(addressStableCoin).transferFrom(p_origin, address(this), incrementStock * stocks),
            "Error transfer from origin"
        );

        emit AddDividends(incrementStock * stocks, incrementStock); 
    }

    function claimDividendsWidthSignature(
        address p_contractHoldings, 
        address p_holder,
        uint256 p_amountClaim,
        address p_contractSeller, 
        uint256 p_amountReinvest,
        uint256 p_timeStamp,
        bytes memory signature
    ) public whenNotPaused override { 
        require(!s_signatures[signature], "Signature already exists"); 
        require(p_holder == msg.sender, "Error origin address");
        require(p_timeStamp + 10 minutes <= block.timestamp, "Error time");

        bytes32 message = keccak256(abi.encodePacked( 
            p_contractHoldings, 
            p_holder, 
            p_amountClaim,
            p_contractSeller,
            p_amountReinvest,
            p_timeStamp,
            address(this)
        ));
        require(_recoverSigner(message, signature) == s_signer, "Error signature");

        s_signatures[signature] = true;

        uint256 amountToClaim = _infoClaimDividends(p_contractHoldings, p_holder);
        require(amountToClaim > 0 && amountToClaim >= p_amountClaim, "Error amount claim");

        s_claimedDividends[p_holder][p_contractHoldings] += amountToClaim;
        s_claimedRealDividends[p_holder][p_contractHoldings] += amountToClaim;

        (address addressStableCoin, , ) = ISELLER(ITOKENHOLDINGS(p_contractHoldings).seller()).stableCoin();
        
        if (p_contractSeller == address(0)) {
            require(IERC20(addressStableCoin).transfer(p_holder, p_amountClaim), "Error transfer dividends");
        } 
        
        if (p_contractSeller != address(0)) {
            require(p_amountClaim >= p_amountReinvest && p_amountReinvest > 0, "Error reinvest amount");

            (address addressStableCoinReinvest, , ) = ISELLER(p_contractSeller).stableCoin();
            require(addressStableCoin == addressStableCoinReinvest, "Different stable coins");
            
            if (p_amountClaim > p_amountReinvest) {
                require(IERC20(addressStableCoin).transfer(p_holder, p_amountClaim - p_amountReinvest), "Error transfer dividends");
            }

            require(
                ISELLER(p_contractSeller).buy(p_amountReinvest, p_holder), 
                "Error reinvest"
            );
        }

        emit ClaimDividends(p_holder, amountToClaim); 
    }

    function addHoldingsAddress(address p_contractHoldings) public onlyOwner override { 
        s_authorized[p_contractHoldings] = true; 
    }

    function addToClaim(address p_holder, uint256 p_amountDividends) public override {
        require(s_authorized[msg.sender], "Error origin");

        s_toClaim[p_holder][msg.sender] += p_amountDividends;
    }

    function addClaimedDividends(address p_holder, uint256 p_amountDividends) public override { 
        require(s_authorized[msg.sender], "Error origin");

        s_claimedDividends[p_holder][msg.sender] += p_amountDividends;
    } 

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Internal functions
    //////////////////////////////////////////////////////////////////////////////////////////////////

    function _infoClaimDividends(address p_contractHoldings, address p_holder) internal view returns(uint256) {
        uint256 stoksHolder = IERC20(p_contractHoldings).balanceOf(p_holder);
        uint256 amountDividendsStock = s_amountDividendsStock[p_contractHoldings];
        uint256 amountPending = s_toClaim[p_holder][p_contractHoldings];

        if ((stoksHolder == 0 && amountPending == 0) || amountDividendsStock == 0) { return 0; }
        
        uint256 claimTotal;
        if (stoksHolder > 0) {
            claimTotal = (stoksHolder * amountDividendsStock) + amountPending;
        } else if (amountPending > 0) {
            claimTotal = amountPending;
        }
        
        uint256 claimed = s_claimedDividends[p_holder][p_contractHoldings];

        if (claimTotal > claimed) {
            return claimTotal - claimed;
        }

        return 0;
    }

    function _recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = _splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function _splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    
        return (v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITOKENHOLDINGS {
    // EVENTS
    event ForcedTransferStocks(address e_from, address e_to); 

    // PUBLIC FUNCTIONS

        // View functions

        function seller() external view returns(address);

        // Set functions

        function setPause(bool p_pause) external;
        function forcedTransferStocks(address p_from, address p_to) external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISELLER {
    // EVENTS

    event Sale(address indexed e_client, uint256 e_amount);
    event toSell(uint256 e_tokenAmount, uint256 e_price);
    
    // PUBLIC FUNCTIONS

        // View functions
        function getMaxTime() external view returns(uint256);
        function priceAmountToken(uint256 p_amountToken) external view returns(uint256, uint256);
        function minAmountToBuy() external view returns(uint256);
        function tokenAmountSold() external view returns(uint256);
        function balanceSeller() external view returns(uint256);
        function stableCoin() external view returns(address, string memory, string memory);
        function holdingsAddress() external view returns(address);
        function beneficiary() external view returns(address);
        function canTransferHoldings() external view returns(bool);
        function status(address p_holder) external view returns(bool);
        function throughCompany() external view returns(uint256);
        function addressesThroughCompany() external view returns(address[] memory);
        function balanceAddress(address p_address) external view returns(uint256);
        function canRevertPayments() external view returns(bool);

        // Set functions

        function setHoldingsAddress(address p_erc20) external;
        function buy(uint256 p_amountToken, address p_buyer) external returns(bool);
        function buyThroughCompany(uint256 p_amountToken, address p_buyer) external returns(bool);
        function setThroughCompany(uint256 p_amountToken, bool p_inOut) external returns(bool);
        function sell(uint256 p_price, uint256 p_maxTime, uint256 p_minTokensBuy) external;
        function setPrice(uint256 p_price) external;
        function setMaxTime(uint256 p_maxTime) external;
        function setMinTokensBuy(uint256 p_minTokensBuy) external;
        function activeRevertPayments(uint256 p_amountStableCoin, address p_origin) external returns(bool);
        function revertPayments() external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDIVIDENDS {
    // EVENTS 

    event AddDividends(
        uint256 e_total, 
        uint256 e_totalPerStock
    ); 

    event ClaimDividends(address e_investor, uint256 e_claimAmount);

    // PUBLIC FUNCTIONS

        // View functions

        function signer() external view returns(address);
        function authorized(address p_contractHoldings) external view returns(bool);
        function amountStock(address p_contractHoldings) external view returns(uint256);
        function infoClaimDividends(address p_contractHoldings, address p_addressHolder) external view returns(uint256);
        function infoClaimedDividends(address p_contractHoldings, address p_addressHolder) external view returns(uint256);
        function numberStocksSoldDirectlyAndCompany(address p_contractHoldings)external view returns(uint256, uint256);

        // Set functions

        function setSigner(address p_signer) external;
        function setPause(bool p_pause) external; 
        function addDividends(address p_origin, address p_contractHoldings, uint256 p_amountIncrementDividends) external;
        function claimDividendsWidthSignature(
            address p_contractHoldings, 
            address p_holder, 
            uint256 p_amountClaim,
            address p_contractReinvest, 
            uint256 p_amountReinvest,
            uint256 p_timeStamp,
            bytes memory signature
        ) external;
        function addHoldingsAddress(address p_contractHoldings) external;
        function addToClaim(address p_holder, uint256 p_amountDividends) external;
        function addClaimedDividends(address p_holder, uint256 p_amountDividends) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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