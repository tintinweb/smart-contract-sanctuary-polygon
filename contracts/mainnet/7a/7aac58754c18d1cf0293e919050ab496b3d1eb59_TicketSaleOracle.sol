// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
pragma solidity ^0.8.4;

import "./interfaces/IChamberOfCommerce.sol";

import "./interfaces/ITicketSaleOracle.sol";
import { ITicketSaleOracleEvents } from "./interfaces/IEvents.sol";

/**
 * Contract that acts as permissioned oracle returning how much tickets are sold for a event. 
 * Due to architecture of the current contracts we cannot access this on chain.
 * In this first implementation the DAO governer (and EOA) can fill in any number they want.
 * It would be possilbe to actually call the EventImplementation contract and check if the index/count actually exists.
 * This would cover at least the edge case where the DAO Govenor colludes and registers a too high number in order to increase the performance yield.
 */
contract TicketSaleOracle is ITicketSaleOracle, ITicketSaleOracleEvents{
    address public chamberOfCommerce;
    // eventAddres -> NFT Count
    mapping(address => uint32) public nftsIssuedForEvent;
    // eventAddress -> bool (if event is over or not)
    mapping(address => bool) public isCountFinalized;

    constructor(address _chamberOfCommerce) {
        chamberOfCommerce = _chamberOfCommerce;
    }

    modifier isDAOController() {
        require(
            IChamberOfCommerce(chamberOfCommerce).isDAOController(msg.sender),
            "TicketSaleOracle:Caller not a DAO controller"
        );
        _;
    }

    function setEventCount(
        address _eventAddress,
        uint32 _nftsSold
    ) external isDAOController {
        require(
            !isCountFinalized[_eventAddress], 
            "TicketSaleOracle:Event is already finalized, can't change the ticket sale now"
        ); 
        nftsIssuedForEvent[_eventAddress] = _nftsSold;
        emit EventCountUpdate(
            _eventAddress,
            _nftsSold
        );
    }

    function finalizeEvent(
        address _eventAddress
    ) external isDAOController {
        isCountFinalized[_eventAddress] = true;
        emit EventFinalized(_eventAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ITellerV2DataTypes, IEconomicsDataTypes } from "./IDataTypes.sol";

interface IChamberOfCommerce is ITellerV2DataTypes, IEconomicsDataTypes {
    function bondCouncil() external view returns(address);
    function fuelToken() external returns(address);
    function depositToken() external returns(address);
    function tellerContract() external returns(address);
    function clearingHouse() external returns(address);
    function ticketSaleOracle() external returns(address);
    function economics() external returns(address);
    function palletRegistry() external returns(address);
    function palletMinter() external returns(address);
    function tellerKeeper() external returns(address);
    function returnPalletLocker(address _safeAddress) external view returns(address _palletLocker);
    function isChamberPaused() external view returns (bool);

    function returnIntegratorData(
        uint32 _integratorIndex
    )  external view returns(IntegratorData memory data_);

    function isAddressBorrower(
        address _addressSafeBorrower
    ) external view returns(bool);

    function isAccountWhitelisted(
        address _addressAccount
    ) external view returns(bool);

    function isAccountBlacklisted(
        address _addressAccount
    ) external view returns(bool);

    function returnPalletEvent(
        uint256 _palletIndex
    ) external view returns(address eventAddress_);

    function viewIntegratorUSDBalance(
        uint32 _integratorIndex
    ) external view returns (uint256 balance_);

    function emergencyMultisig() external view returns(address);

    function returnIntegratorIndexByRelayer(
        address _relayerAddress
    ) external view returns(uint32 integratorIndex_);

    function isDAOController(
        address _challenedController
    ) external view returns(bool);

    function isFuelAndCollateralSufficient(
        address _palletIssuerAddress, 
        uint64 _maxAmountInventory, 
        uint64 _averagePriceInventory,
        uint256 _amountPallet) external view returns(bool judgement_);


    function getIntegratorFuelPrice(
        uint32 _integratorIndex
    ) external view returns(uint256 _price);

    function palletIndexToBid(
        uint256 _palletIndex
    ) external view returns(uint256 _bidId);

    // EXTERNALCALL TO ORACLE
    function nftsIssuedForEvent(
        address _eventAddress
    ) external view returns(uint32 _ticketCount);

    // EXTERNALCALL TO ORACLE
    function isCountFinalized(
        address _eventAddress
    ) external view returns(bool _isFinalized);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IChamberOfCommerceDataTypes {

    // ChamberOfCommerce
    enum AccountType {
        NOT_SET,
        BORROWER,
        LENDER
    }

    enum AccountStatus {
        NONE,
        REGISTERED,
        WHITELISTED,
        BLACKLIST
    }

    struct ActorAccount {
        // uint256 actorIndex;
        uint32 integratorIndex;
        AccountStatus status;
        AccountType accountType;
        address palletLocker;
        // address stakeLocker;
        address relayerAddress;
        string nickName;
        string uriGeneral;
        string uriTerms;
    }

    struct CreditScore {
        uint256 minimumDeposit;
        uint24 fuelRequirement; // 100% = 1_000_000 = 1e6
    }
}

interface IEventImplementationDataTypes {

    enum TicketFlags {
        SCANNED, // 0
        CHECKED_IN, // 1
        INVALIDATED, // 2
        CLAIMED // 3
    }

    struct BalanceUpdates {
        address owner;
        uint64 quantity;
    }

    struct TokenData {
        address owner;
        uint40 basePrice;
        uint8 booleanFlags;
    }

    struct AddressData {
        // uint64 more than enough
        uint64 balance;
    }

    struct EventData {
        uint32 index;
        uint64 startTime;
        uint64 endTime;
        int32 latitude;
        int32 longitude;
        string currency;
        string name;
        string shopUrl;
        string imageUrl;
    }

    struct TicketAction {
        uint256 tokenId;
        bytes32 externalId; // sha256 hashed, emitted in event only.
        address to;
        uint64 orderTime;
        uint40 basePrice;
    }

    struct EventFinancing {
        uint64 palletIndex;
        address bondCouncil;
        bool inventoryRegistered;
        bool financingActive;
        bool primaryBlocked;
        bool secondaryBlocked;
        bool scanBlocked;
        bool claimBlocked;
    }
}


interface IBondCouncilDataTypes is IEventImplementationDataTypes {
    /**
     * @notice What happens to the collateral after a certain 'bond state' is a Policy. The Policy struct defines the consequence on the actions of the collateral
     * @param isPolicy bool that tracks 'if a policy exists'. Should always be set to True if a Policy is set
     * @param primaryBlocked if the NFTs can be sold on the primary market if the Policy is active. True means that the NFTs cannot be sold on the primary market.
     * Same principle of True/False relation to possible ticket-actions is the case for the other bools in this struct.
     */
    struct Policy {
        bool isPolicy;
        bool primaryBlocked;
        bool secondaryBlocked;
        bool scanBlocked;
        bool claimBlocked;
    }

    /**
     * @param verified bool indicating if the TB is verified by the DAO
     * @param eventAddress address of the Event (EventImplementation proxy) 
     * @param policyDuringLoan integer of the Policy that will be executed after the offering is ACCEPTED (so during the duration of the loan/bond)
     * @param policyAfterLiquidation integer of the Policy that will be executed if the offering is LIQUIDATED (so this is the consequence of not repaying the loan/bond)
     * @param flushstruct this is a copy of the EventFinancing struct in EventImplementation. 
     * @dev when a configuration is 'flushed' this means that the flushstruct is pushed to the EventImplementation contract. 
     */
    struct InventoryProcedure {
        bool verified;
        address eventAddress;
        uint256 policyDuringLoan;
        uint256 policyAfterLiquidation;
        EventFinancing flushstruct;
    }

    /**
     * XXXX ADD DESCRIPTION
     * @param INACTIVE XXX
     * @param DURING XXX
     * @param LIQUIDATED XXX
     * @param REPAID XXX
     */
    enum CollateralizationStage {
        INACTIVE,
        DURING,
        LIQUIDATED,
        REPAID
    }
}

interface IClearingHouseDataTypes {

    /**
     * Struct encoding the status of the collateral/loan/bid offering.
     * @param NONE offering isn't registered at all (doesn't exist)
     * @param READY the pallet is ready to be used as collateral
     * @param ACTIVE the pallet is being used as collateral
     * @param COMPLETED the pallet is returned to the bond issuer (the offering is completed, loan has been repaid)
     * @param DEFAULTED the pallet is sent to the lender because the loan/bond wasn't repaid. The offering isn't active anymore
     */
    enum OfferingStatus {
        NONE,
        READY,
        ACTIVE,
        COMPLETED,
        DEFAULTED
    }
}

interface IEconomicsDataTypes {
    struct IntegratorData {
        uint32 index;
        uint32 activeTicketCount;
        bool isBillingEnabled;
        bool isConfigured;
        uint256 price;
        uint256 availableFuel;
        uint256 reservedFuel;
        uint256 reservedFuelProtocol;
        string name;
    }

    struct RelayerData {
        uint32 integratorIndex;
    }

    struct DynamicRates {
        uint24 minFeePrimary;
        uint24 maxFeePrimary;
        uint24 primaryRate;
        uint24 minFeeSecondary;
        uint24 maxFeeSecondary;
        uint24 secondaryRate;
        uint24 salesTaxRate;
    }
}

interface PalletRegistryDataTypes {

    enum PalletState {
        NON_EXISTANT,
        UN_REGISTERED, // 'pallet is unregistered to an event'
        REGISTERED, // 'pallet is registered to an event'
        VERIFIED, // pallet is now sealed
        DISCARDED // end state
    }

    struct PalletStruct {
        address depositTokenAddress;
        uint64 maxAmountInventory;
        uint64 averagePriceInventory;
        bool fuelAndCollateralCheck;
        address safeAddressIssuer;
        address palletLocker;
        uint256 depositedDepositTokens;
        PalletState palletState;
        address eventAddress;
    }
}

interface ITellerV2DataTypes {
    enum BidState {
        NONEXISTENT,
        PENDING,
        CANCELLED,
        ACCEPTED,
        PAID,
        LIQUIDATED
    }
    
    struct Payment {
        uint256 principal;
        uint256 interest;
    }

    struct Terms {
        uint256 paymentCycleAmount;
        uint32 paymentCycle;
        uint16 APR;
    }
    
    struct LoanDetails {
        ERC20 lendingToken;
        uint256 principal;
        Payment totalRepaid;
        uint32 timestamp;
        uint32 acceptedTimestamp;
        uint32 lastRepaidTimestamp;
        uint32 loanDuration;
    }

    struct Bid {
        address borrower;
        address receiver;
        address lender;
        uint256 marketplaceId; // TODO should this be uncommented really?
        bytes32 _metadataURI; // DEPRECIATED
        LoanDetails loanDetails;
        Terms terms;
        BidState state;
    }
}

interface ITrancheBucketFactoryDataTypes {

    enum BucketType {
        NONE,
        BACKED,
        UN_BACKED
    }

}

interface ITrancheBucketDataTypes is IEconomicsDataTypes {

    /**
     * @param NONE config doesn't exist
     * @param CONFIGURABLE BUCKET IS CONFIGURABLE. it is possible to change the inv range and the kickback per NFT sold (so the bucket is still configuratable)
     * @param BUCKET_ACTIVE BUCKET IS ACTIVE. the bucket is active / in use (the loan/bond has been issued). The bucket CANNOT be configured anymore
     * @param AT_CHECKOUT BUCKET DEBT IS BEING CALCULATED AND PAID. The bond/loan has been repaid / the ticket sale is completed. In a sense the bucket backer is at the checkout of the process (the total bill is made up, and the payment request/process is being run). Look of it as it as the contract being at the checkout at the supermarket, items bought are scanned, creditbard(Economics contract) is charged.
     * @param REDEEMABLE the proceeds/kickback collected in the bucket can now be claimed from the bucket contract. 
     * @param INVALID_CANCELLED_VOID the bucket is invalid. this can have several reasons. The different reasons are listed below.
     * 
     * We have collapsed all these different reasons in a single state because the purpose of this struct is to tell the market what the shares are worth anything. If the bucket is in this state, the value of the shares are 0 (and they are unmovable).
     */


    // stored in: bucketState
    enum BucketConfiguration {
        NONE,
        CONFIGURABLE,
        BUCKET_ACTIVE,
        AT_CHECKOUT,
        REDEEMABLE,
        INVALID_CANCELLED_VOID
    }

    // stored in backing.verification
    enum BackingVerification {
        NONE,
        INVALIDATED,
        VERIFIED
    }

    // stored in tranche
    struct InventoryTranche {
        uint32 startIndexTranche;
        uint32 stopIndexTranche;
        uint32 averagePriceNFT;
        uint32 totalNFTInventory;
        uint32 usdKickbackPerNft; // 10000 = 1e4 = $1,00 = 1 dollar 
    }

    struct BackingStruct {
        bool relayerAttestation;
        BackingVerification verification;
        IntegratorData integratorData;
        uint32 integratorIndex;
        uint256 timestampBacking; // the moment the bucket was deployed and the backing was configured 
    }

    // struct OfferingBidInfo{
    //     address eventAddress;
    //     uint256 bidId;
    // }

    // struct RepaymentStruct {
    //     uint32 scalingFactor;
    //     uint32 bucketDebt;
    //     uint256 amountReceived;
    //     uint256 totalYieldCollected;
    //     uint256 supplyAtFinalization;
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IClearingHouseDataTypes, ITrancheBucketDataTypes, IBondCouncilDataTypes, ITellerV2DataTypes, ITrancheBucketFactoryDataTypes } from "./IDataTypes.sol";

interface IChamberOfCommerceEvents {


    event DefaultDepositSet(
        uint256 newDefaultDeposit
    );

    event CreditScoreEdit(
        address safeAddress,
        uint256 minimumDeposit,
        uint24 fuelRequirement
    );

    event EconomicsContractChange(
        address economicsContract
    );

    event DepositTokenChange(address newDepositToken);

    event AccountDeleted(
        address accountAddress
    );

    event RegisterySet(
        address palletRegistry
    );

    event ControllerSet(
        address addressController,
        bool setting
    );

    event ChamberPaused();

    event ChamberUnPaused();

    event AccountRegistered(
        address safeAddress,
        // uint256 actorIndex,
        string nickName
    );

    event AccountApproved(
        address safeAddress
    );

    event AccountWhitelisted(
        address safeAddress
    );

    event AccountBlacklisted(
        address safeAddress
    );

    event ContractsConfigured(
        address palletLockerFactory,
        address bondCouncil,
        address ticketSalesOracle,
        address economics,
        address palletRegistry,
        address clearingHouse,
        address tellerKeeper
    );

    event PalletLockerDeployed(
        address safeAddress,
        address palletLockerAddress
    );

    event StakeLockerDeployed(
        address safeAddress,
        address safeLockerAddress
    );
}

interface IClearingHouseEvents is IClearingHouseDataTypes {

    event BucketUpdate();

    event ManualCancel(uint256 palletIndex);

    event OfferingAccepted(
        uint256 palletIndex
    );

    event ContractConfigured(
        address palletRegistry,
        address tellerKeeper,
        address bondCouncil
    );

    event OfferingRegistered(
        uint256 palletIndex,
        uint256 bidId
    );

    event OfferingCancelled(
        uint256 palletIndex
    );

    event OfferingLiquidated(
        uint256 palletIndex,
        address lenderAddress
    );

    event PalletReclaimed(
        uint256 palletIndex
    );

    event OfferingStatusChange(
        uint256 palletIndex,
        OfferingStatus _status
    );

}

interface IPalletRegistryEvents {

    event EmergencyWithdraw(
        address tokenAddress,
        address controllerDAO,
        uint256 amountWithdrawn
    );
    
    event BalanceCheck(
        uint256 palletIndex,
        bool rulingBalance
    );

    event DepositTokenChange(address newDepositToken);

    event PalletUnwindLiquidation(
        uint256 palletIndex,
        address liquidatorAddress
    );

    event PalletUnwindIssuer(
        uint256 palletIndex,
        uint256 depositAmount
    );

    event UnwindIssuer(
        uint256 palletIndex
    );

    event UnwindPallet(
        uint256 palletIndex,
        uint256 amountUnwound,
        address recipientDeposit,
        address lockerAddress
    );

    event PalletMinted(
        uint256 palletIndex,
        address safeAddress,
        uint256 tokensDeposited
    );

    event RegisterEventToPallet (
        uint256 palletIndex,
        address eventAddress
    );

    event DepositTokensAdded(
        uint256 palletIndex,
        uint256 extraDepositTokens
    );

    event PalletBurnedManual(
        uint256 palletIndex
    );

    event WithdrawPalletLocker(
        address depositTokenAddress,
        address toAddress,
        uint256 stakeDepositAmount
    );

    event PalletJudged(
        uint256 palletIndex,
        bool ruling
    );

    event PalletDepositClaimed(
        address claimAddress,
        uint256 palletIndex,
        uint256 depositedStateTokens
    );
}

interface ITrancheBucketEvents is ITrancheBucketDataTypes {

    event PaymentApproved();

    event ManualWithdraw(
        address withdrawTokenAddress,
        uint256 amountWithdrawn
    );

    event FunctionNotFullyExecuted();

    event BucketUpdate();

    event ManualCancel();

    event ClaimNotAllowed();

    event ModificationNotAllowed();

    event TrancheFinalized();

    event TrancheFullyRegistered(
        uint32 startIndex,
        uint32 stopIndex,
        uint32 averagePrice,
        uint32 totalInventory
    );

    event AllStaked(
        uint256 stakedAmount,
        uint256 sharesAmount
    );

    event BucketConfigured(
        uint32 integratorIndex
    );

    event RelayerAttestation(
        address attestationAddress
    );

    event BackingVerified(
        bool ruling
    );

    event TrancheShareMint(
        uint256 totalSupply
    );

    event BurnAll();

    event StateChange(
        BucketConfiguration _status
    );

    event InvalidState(
        BucketConfiguration currentState,
        BucketConfiguration requiredState
    );

    event DAOCancel();

    event StateAlreadyInSync();

    event SharesClaimed(
        address claimerAddress,
        uint256 amountClaimed
    );
    
    event UpdateDebt(
        uint256 currentDebt,
        uint256 timestamp
    );

    event BucketCheckedOut(
        uint256 finalDebt
    );

    event ReceivablesUpdated(
        uint256 balanceOf
    );

    event RedemptionUnlocked(
        uint256 balance,
        uint256 atPrice,
        uint256 totalReward
    );

    event Claim(
        uint256 shares,
        uint256 yield
    );

    event ClaimAmount();
}

interface ITellerKeeperEvents is ITellerV2DataTypes {

    event EmergencyWithdraw(
        address tokenAddress,
        address controllerDAO,
        uint256 amountWithdrawn
    );

    error NoOfferingToUpdate(
        uint256 palletIndex,
        string message
    );

    event KeeperUpToDate();

    event NotEnoughFuel();

    event OfferingManualCancel(
        uint256 palletIndex
    );

    event OfferingRegistered(
        uint256 palletIndex
    );

    event TellerLiquidation(
        uint256 palletIndex
    );

    event ContractConfigured(
        address trancheBucketFactory,
        address clearingHouse
    );

    event KeeperReward(
        address rewardRecipient,
        uint256 amountRewarded
    );

    event TellerPaid(
        uint256 palletIndex
    );

    event RewardUpdated(
        uint256 newUpdateReward
    );

    event TellerCancelled(
        uint256 palletIndex
    );

    event TellerAccepted(
        uint256 palletIndex
    );

    event StateUpdateKeeper(
        uint256 bidId,
        uint256 palletIndex,
        BidState currentState
    );
}

interface ITrancheBucketFactoryEvents is ITrancheBucketDataTypes, ITrancheBucketFactoryDataTypes {

    event BucketAlreadyActive();

    event TrancheBucketDeleted(
        uint256 palletIndex,
        address deletedBucket
    );

   event SetTrancheBucketStateManual(
        uint256 palletIndex,
        address bucketAddress
    );

    event TrancheLockerCreated(
        uint256 palletIndex,
        BucketType bucketType,
        address trancheAddress
    );

    event ContractConfigured(
        address clearingHouse
    );

    event RelayChangeToBucket(
        uint256 palletIndex,
        BucketConfiguration newState
    );
}

interface IBondCouncilEvents is IBondCouncilDataTypes {

    event FlushSwitchOff();

    event FlushSwitch(
        bool flushSwitch
    );

    event ImpossibleState();

    event CancelProcedure(
        uint256 palletIndex
    );

    event ManualFS (
        uint256 palletIndex,
        uint256 policyIndex
    );

    event EditProcedure(
        uint256 palletIndex
    );

    event VerifyProcedure(
        uint256 palletIndex
    );

    event PalletCancellation(
        uint256 palletIndex
    );

    event PalletCollateralization(
        uint256 palletIndex
    );

    event PolicyAdded(
        uint256 policyIndex,
        Policy newpolicy
    );

    event ManualFlush(
        uint256 palletIndex
    );

    event PalletRegistered(
        uint256 palletIndex
    );

    event Flush(
        uint256 palletIndex
    );

    event ContractsConfigured(
        address clearingHouse,
        address palletRegistry
    );

    event ChamberSet(
        address chamberOfCommerce
    );

    event Liquidation(
        uint256 palletIndex
    );

    event Repayment(
        uint256 palletIndex
    );
}

interface IStakeLockerFactoryEvents {

    event StakeLockerDeployed(
        address safeAddress
    );

    event TokensAdded(
        address stakeLocker,
        uint256 tokensAdded
    );

    event BalanceUpdated(
        address stakeLocker,
        uint256 newBalance
    );
    
    event UnstakeRequest(
        address safeAddress,
        address lockerAddress,
        uint256 requestAmount
    );

    event UnstakeRequestExecuted(
        address lockerAddress,
        uint256 requestAmount
    );

    event UnstakeRequestRejected(
        address lockerAddress,
        uint256 rejectedAmount
    );

    event EmergencyWithdrawAll(
        address lockerAddress,
        uint256 withdrawAmount
    );

    event LockerSlashed(
        address lockerAddress,
        uint256 slashAmount
    );
}


interface IStakeLockerEvents {

}

interface ITicketSaleOracleEvents {

    event EventCountUpdate(
        address eventAddress,
        uint32 nftsSold
    );

    event EventFinalized(
        address eventAddress
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITicketSaleOracle {

    function nftsIssuedForEvent(
        address _eventAddress
    ) external view returns(uint32 _ticketCount);

    function isCountFinalized(
        address _eventAddress
    ) external view returns(bool _isFinalized);
}