//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "../../satellite/loanAgent/interfaces/ILoanAgent.sol";
import "../../satellite/loanAgent/LoanAgentStorage.sol";
import "../../satellite/loanAgent/LoanAgent.sol";
import "../../satellite/loanAgent/LoanAgentAdmin.sol";
import "../../satellite/loanAgent/LoanAgentMessageHandler.sol";
import "../interfaces/IDelegator.sol";
import "./events/LoanAgentDelegatorEvents.sol";

contract LoanAgentDelegator is
    LoanAgentStorage,
    ILoanAgent,
    LoanAgentDelegatorEvents,
    IDelegator
{
    constructor(
        address _delegateeAddress,
        uint256 _masterCID
    ) payable {
        admin = delegatorAdmin = payable(msg.sender);

        setDelegateeAddress(_delegateeAddress);

        _delegatecall(abi.encodeWithSelector(
            SatelliteLoanAgent.initialize.selector,
            _masterCID
        ));

        isInitialized = delegateeIsInitialized = true;
    }

    function borrow(
        address route,
        address loanMarketAsset,
        uint256 borrowAmount
    ) external payable override {
        _delegatecall(abi.encodeWithSelector(
            SatelliteLoanAgent.borrow.selector,
            route,
            loanMarketAsset,
            borrowAmount
        ));
    }

    function repayBorrow(
        address route,
        address loanMarketAsset,
        uint256 repayAmount
    ) external payable override returns (uint256 amount) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            SatelliteLoanAgent.repayBorrow.selector,
            route,
            loanMarketAsset,
            repayAmount
        ));

        (amount) = abi.decode(data, (uint256));

        emit RepayBorrow(amount);
    }

    function repayBorrowBehalf(
        address borrower,
        address route,
        address loanMarketAsset,
        uint256 repayAmount
    ) external payable override returns (uint256 amount) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            SatelliteLoanAgent.repayBorrowBehalf.selector,
            borrower,
            route,
            loanMarketAsset,
            repayAmount
        ));

        (amount) = abi.decode(data, (uint256));

        emit RepayBorrowBehalf(amount);
    }

    function borrowApproved(
        IHelper.FBBorrow memory params
    ) external payable override {
        _delegatecall(abi.encodeWithSelector(
            LoanAgentMessageHandler.borrowApproved.selector,
            params
        ));
    }

    function setMidLayer(address newMiddleLayer) external override {
        _delegatecall(abi.encodeWithSelector(
            LoanAgentAdmin.setMidLayer.selector,
            newMiddleLayer
        ));
    }

    function changeAdmin(address payable _newAdmin) external override {
        _delegatecall(abi.encodeWithSelector(
            LoanAgentAdmin.changeAdmin.selector,
            _newAdmin
        ));
    }

    function pauseMarket(bool pause) external override {
        _delegatecall(abi.encodeWithSelector(
            LoanAgentAdmin.pauseMarket.selector,
            pause
        ));
    }

    // ? Controlled delegate call is a misdetection here as the address is controlled by the contract
    // ? The only options the user is in controll of here is the function selector and params,
    // ? both of which are safe for the user to controll given that the implmentation is addressing msg.sender and
    // ? admin when in context of admin functions.
    // controlled-delegatecall,low-level-calls
    // slither-disable-next-line all
    fallback() external {
        /* If a function is not defined above, we can still call it using msg.data. */
        (bool success,) = delegateeAddress.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }
}

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "../LoanAgentStorage.sol";
import "../../../interfaces/IHelper.sol";

abstract contract ILoanAgent is LoanAgentStorage {

    /*** User Functions ***/

    function borrow(
        address route,
        address loanMarketAsset,
        uint256 borrowAmount
    ) external payable virtual;

    function repayBorrow(
        address route,
        address loanMarketAsset,
        uint256 repayAmount
    ) external payable virtual returns (uint256);

    function repayBorrowBehalf(
        address borrower,
        address route,
        address loanMarketAsset,
        uint256 repayAmount
    ) external payable virtual returns (uint256);

    function borrowApproved(
        IHelper.FBBorrow memory params
    ) external payable virtual;

    /*** Admin Functions ***/

    function setMidLayer(address newMiddleLayer) external virtual;

    function changeAdmin(address payable _newAdmin) external virtual;

    function pauseMarket(bool pause) external virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../middleLayer/interfaces/IMiddleLayer.sol";

abstract contract LoanAgentStorage {

    /**
    * @notice Administrator for this contract
    */
    address payable public admin;

    /**
     * @notice Whether or not the delegatee has been initialized or not.
     */
    bool internal isInitialized;

    /**
    * @notice Master ChainId
    */
    // slither-disable-next-line unused-state
    uint256 public masterCID;

    /**
    * @notice Indicates whether the market is accepting new borrows
    */
    bool public isPaused;

    /**
    * @notice MiddleLayer Interface
    */
    // slither-disable-next-line unused-state
    IMiddleLayer internal middleLayer;
}

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "./interfaces/ILoanAgent.sol";
import "./LoanAgentAdmin.sol";
import "./LoanAgentEvents.sol";
import "./LoanAgentMessageHandler.sol";
import "../../util/CommonModifiers.sol";
import "../../util/CommonErrors.sol";

contract SatelliteLoanAgent is
    ILoanAgent,
    LoanAgentAdmin,
    LoanAgentMessageHandler
{
    function initialize(
        uint256 _masterCID
    ) external onlyAdmin() initOnlyOnce() {
        masterCID = _masterCID;
    }

    /**
     * @notice Users borrow assets from a supported loan market
     * @param borrowAmount The amount of the loan market asset to borrow
     * @param loanMarketAsset The asset to borrow
     */
    function borrow(
        address route,
        address loanMarketAsset,
        uint256 borrowAmount
    ) external payable virtual override {
        if (isPaused) revert MarketIsPaused();
        if (loanMarketAsset == address(0)) revert AddressExpected();
        if (borrowAmount == 0) revert ExpectedBorrowAmount();

        _sendBorrow(
            msg.sender, 
            route, 
            loanMarketAsset,
            borrowAmount
        );
    }

    /**
     * @notice Users repay a loan on their own behalf
     * @param repayAmount The amount of the loan market asset to repay
     * @param loanMarketAsset The asset to repay
    */
    function repayBorrow(
        address route,
        address loanMarketAsset,
        uint256 repayAmount
    ) external payable virtual override returns (uint256) {
        if (loanMarketAsset == address(0)) revert AddressExpected();
        if (repayAmount == 0) revert ExpectedRepayAmount();

        return _sendRepay(
            msg.sender, 
            msg.sender, 
            route, 
            loanMarketAsset,
            repayAmount
        );
    }

    /**
     * @notice Users repay a loan on behalf of another
     * @param borrower The person the loan is repaid on behalf of
     * @param repayAmount The amount of the loan market asset to repay
     * @param loanMarketAsset The asset to repay
    */
    function repayBorrowBehalf(
        address borrower,
        address route,
        address loanMarketAsset,
        uint256 repayAmount
    ) external payable virtual override returns (uint256) {
        if (loanMarketAsset == address(0)) revert AddressExpected();
        if (repayAmount == 0) revert ExpectedRepayAmount();

        return _sendRepay(
            msg.sender, 
            borrower,  
            route, 
            loanMarketAsset,
            repayAmount
        );
    }

    fallback() external payable {}

    receive() payable external {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/ILoanAgent.sol";
import "./LoanAgentModifiers.sol";
import "./LoanAgentEvents.sol";

abstract contract LoanAgentAdmin is ILoanAgent, LoanAgentModifiers, LoanAgentEvents {

    function pauseMarket(
        bool pause
    ) external override onlyAdmin() {
        emit MarketPaused(isPaused, pause);

        isPaused = pause;
    }
    function setMidLayer(
        address newMiddleLayer
    ) external override onlyAdmin() {
        if (newMiddleLayer == address(0)) revert AddressExpected();

        emit SetMiddleLayer(address(middleLayer), newMiddleLayer);

        middleLayer = IMiddleLayer(newMiddleLayer);
    }

    function changeAdmin(
        address payable newAdmin
    ) external override onlyAdmin() {
        if (newAdmin == address(0)) revert AddressExpected();

        emit ChangeAdmin(admin, newAdmin);

        admin = newAdmin;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../interfaces/IHelper.sol";
import "./interfaces/ILoanAgent.sol";
import "./interfaces/ILoanAgentInternals.sol";
import "./LoanAgentModifiers.sol";
import "../loanAsset/interfaces/ILoanAsset.sol";
import "./LoanAgentEvents.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract LoanAgentMessageHandler is ILoanAgent, ILoanAgentInternals, LoanAgentModifiers, LoanAgentEvents {

    // slither-disable-next-line assembly
    function _sendBorrow(
        address user,
        address route,
        address loanMarketAsset,
        uint256 borrowAmount
    ) internal virtual override {
        bytes memory payload = abi.encode(
            IHelper.MBorrowAllowed({
                metadata: uint256(0),
                selector: IHelper.Selector.MASTER_BORROW_ALLOWED,
                user: user,
                borrowAmount: borrowAmount,
                loanMarketAsset: loanMarketAsset
            })
        );

        middleLayer.msend{value: msg.value}(
            masterCID,
            payload, // bytes payload
            payable(msg.sender), // refund address
            route,
            true
        );

        emit BorrowSent(
            user,
            address(this),
            loanMarketAsset,
            borrowAmount
        );
    }

    function borrowApproved(
        IHelper.FBBorrow memory params
    ) external payable override virtual onlyMid() {
        if (isPaused) revert MarketIsPaused();

        ILoanAsset(params.loanMarketAsset).mint(params.user, params.borrowAmount);

        emit BorrowComplete(
            params.user,
            address(this),
            params.loanMarketAsset,
            params.borrowAmount
        );
    }

    // slither-disable-next-line assembly
    function _sendRepay(
        address payer,
        address borrower,
        address route,
        address loanMarketAsset,
        uint256 repayAmount
    ) internal virtual override returns (uint256) {

        ERC20Burnable(loanMarketAsset).burnFrom(payer, repayAmount);

        bytes memory payload = abi.encode(
            IHelper.MRepay({
                metadata: uint256(0),
                selector: IHelper.Selector.MASTER_REPAY,
                borrower: borrower,
                amountRepaid: repayAmount,
                loanMarketAsset: loanMarketAsset
            })
        );

        middleLayer.msend{ value: msg.value }(
            masterCID,
            payload,
            payable(msg.sender),
            route,
            true
        );

        emit RepaySent(
            payer,
            borrower,
            address(this),
            loanMarketAsset,
            repayAmount
        );

        return repayAmount;
    }
}

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "../common/DelegatorModifiers.sol";
import "../common/DelegatorErrors.sol";
import "../common/DelegatorEvents.sol";
import "../common/DelegatorStorage.sol";
import "../../util/CommonModifiers.sol";

abstract contract IDelegator is
    DelegatorEvents,
    DelegatorStorage,
    DelegatorUtil,
    DelegatorModifiers,
    DelegatorErrors
{

    function setDelegateeAddress(
        address newDelegateeAddress
    ) public onlyAdmin() {
        if(newDelegateeAddress == address(0)) revert AddressExpected();

        (delegateeAddress, newDelegateeAddress) = (newDelegateeAddress, delegateeAddress);

        emit DelegateeAddressUpdate(newDelegateeAddress, delegateeAddress);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract LoanAgentDelegatorEvents {

    event RepayBorrow(uint256 amount);
    event RepayBorrowBehalf(uint256 amount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface IHelper {
    enum Selector {
        MASTER_DEPOSIT,
        MASTER_WITHDRAW_ALLOWED,
        FB_WITHDRAW,
        MASTER_REPAY,
        MASTER_BORROW_ALLOWED,
        FB_BORROW,
        SATELLITE_LIQUIDATE_BORROW,
        LOAN_ASSET_BRIDGE
    }

    // !!!!
    // @dev
    // an artificial uint256 param for metadata should be added
    // after packing the payload
    // metadata can be generated via call to ecc.preRegMsg()

    struct MDeposit {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.MASTER_DEPOSIT
        address user;
        address pToken;
        uint256 exchangeRate;
        uint256 depositAmount;
    }

    struct MWithdrawAllowed {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.MASTER_WITHDRAW_ALLOWED
        address pToken;
        address user;
        uint256 withdrawAmount;
        uint256 exchangeRate;
    }

    struct FBWithdraw {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.FB_WITHDRAW
        address pToken;
        address user;
        uint256 withdrawAmount;
        uint256 exchangeRate;
    }

    struct MRepay {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.MASTER_REPAY
        address borrower;
        uint256 amountRepaid;
        address loanMarketAsset;
    }

    struct MBorrowAllowed {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.MASTER_BORROW_ALLOWED
        address user;
        uint256 borrowAmount;
        address loanMarketAsset;
    }

    struct FBBorrow {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.FB_BORROW
        address user;
        uint256 borrowAmount;
        address loanMarketAsset;
    }

    struct SLiquidateBorrow {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.SATELLITE_LIQUIDATE_BORROW
        address borrower;
        address liquidator;
        uint256 seizeTokens;
        address pToken;
    }


    struct LoanAssetBridge {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.LOAN_ASSET_BRIDGE
        address minter;
        bytes32 loanAssetNameHash;
        uint256 amount;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract IMiddleLayer {
    /**
     * @notice routes and encodes messages for you
     * @param _params - abi.encode() of the struct related to the selector, used to generate _payload
     * all params starting with '_' are directly sent to the 'send()' function
     */
    function msend(
        uint256 _dstChainId,
        bytes memory _params,
        address payable _refundAddress,
        address _fallbackAddress,
        bool _shouldPayGas
    ) external payable virtual;

    function mreceive(
        uint256 _srcChainId,
        bytes memory _payload
    ) external virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract LoanAgentEvents {
    
    /*** User Events ***/

    event BorrowSent(
        address user,
        address loanAgent,
        address loanMarketAsset,
        uint256 amount
    );

    event RepaySent(
        address payer,
        address borrower,
        address loanAgent,
        address loanMarketAsset,
        uint256 repayAmount
    );

    event BorrowComplete(
        address indexed borrower,
        address loanAgent,
        address loanMarketAsset,
        uint256 borrowAmount
    );

    /*** Admin Events ***/

    event SetMiddleLayer(
        address oldMiddleLayer,
        address newMiddleLayer
    );

    event ChangeAdmin(
        address oldAdmin,
        address newAdmin
    );

    event MarketPaused(
        bool previousStatus,
        bool newStatus
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./CommonErrors.sol";

abstract contract CommonModifiers is CommonErrors {

    /**
    * @dev Guard variable for re-entrancy checks
    */
    bool internal notEntered;

    constructor() {
        notEntered = true;
    }

    /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    */
    modifier nonReentrant() {
        if (!notEntered) revert Reentrancy();
        notEntered = false;
        _;
        notEntered = true; // get a gas-refund post-Istanbul
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract CommonErrors {
    error AccountNoAssets(address account);
    error AddressExpected();
    error AlreadyInitialized();
    error EccMessageAlreadyProcessed();
    error EccFailedToValidate();
    error ExpectedMintAmount();
    error ExpectedBridgeAmount();
    error ExpectedBorrowAmount();
    error ExpectedWithdrawAmount();
    error ExpectedRepayAmount();
    error ExpectedTradeAmount();
    error ExpectedDepositAmount();
    error ExpectedTransferAmount();
    error InsufficientReserves();
    error InvalidPayload();
    error InvalidPrice();
    error InvalidPrecision();
    error InvalidSelector();
    error MarketExists();
    error LoanMarketIsListed(bool status);
    error MarketIsPaused();
    error MarketNotListed();
    error MsgDataExpected();
    error NameExpected();
    error NothingToWithdraw();
    error NotInMarket(uint256 chainId, address token);
    error OnlyAdmin();
    error OnlyAuth();
    error OnlyGateway();
    error OnlyMiddleLayer();
    error OnlyMintAuth();
    error OnlyRoute();
    error OnlyRouter();
    error OnlyMasterState();
    error ParamOutOfBounds();
    error RouteExists();
    error Reentrancy();
    error EnterLoanMarketFailed();
    error EnterCollMarketFailed();
    error ExitLoanMarketFailed();
    error ExitCollMarketFailed();
    error RepayTooMuch(uint256 repayAmount, uint256 maxAmount);
    error WithdrawTooMuch();
    error NotEnoughBalance(address token, address who);
    error LiquidateDisallowed();
    error SeizeTooMuch();
    error SymbolExpected();
    error RouteNotSupported(address route);
    error MiddleLayerPaused();
    error PairNotSupported(address loanAsset, address tradeAsset);
    error TransferFailed(address from, address dest);
    error TransferPaused();
    error UnknownRevert();
    error UnexpectedValueDelta();
    error ExpectedValue();
    error UnexpectedDelta();
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./LoanAgentStorage.sol";
import "../../util/CommonErrors.sol";

abstract contract LoanAgentModifiers is LoanAgentStorage, CommonErrors {

    modifier onlyAdmin() {
        if(msg.sender != admin) revert OnlyAdmin();
        _;
    }

    modifier onlyMid() {
        if (msg.sender != address(middleLayer)) revert OnlyMiddleLayer();
        _;
    }

    modifier initOnlyOnce() {
        if(isInitialized) revert AlreadyInitialized();
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../LoanAgentStorage.sol";

abstract contract ILoanAgentInternals is LoanAgentStorage {

    function _sendBorrow(
        address user,
        address route,
        address loanMarketAsset,
        uint256 borrowAmount
    ) internal virtual;

    function _sendRepay(
        address payer,
        address borrower,
        address route,
        address loanMarketAsset,
        uint256 repayAmount
    ) internal virtual returns (uint256);

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ILoanAsset {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "./DelegatorErrors.sol";
import "./DelegatorStorage.sol";

contract DelegatorModifiers is DelegatorStorage {
    // slither-disable-next-line unused-return
    modifier onlyAdmin() {
        if (msg.sender != delegatorAdmin) revert DelegatorErrors.AdminOnly(msg.sender);
        _;
    }
}

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "./DelegatorUtil.sol";
import "./DelegatorStorage.sol";

contract DelegatorErrors {

    error DelegatecallFailed(address delegateeAddress, bytes selectorAndParams);
    error NoValueToFallback(address msgSender, uint256 msgValue);
    error AdminOnly(address msgSender);
}

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "./DelegatorUtil.sol";
import "./DelegatorStorage.sol";

contract DelegatorEvents {

    event DelegateeAddressUpdate(address oldDelegateeAddress, address newDelegateeAddress);
}

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

contract DelegatorStorage {

    address payable public delegatorAdmin;

    address public delegateeAddress;

    bool internal delegateeIsInitialized = false;
}

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "./DelegatorErrors.sol";
import "./DelegatorStorage.sol";
import "../../util/CommonErrors.sol";

contract DelegatorUtil is DelegatorStorage, CommonErrors {
    // slither-disable-next-line assembly
    function _safeRevert(bool success, bytes memory _returnData) internal pure {
        if (success) return;

        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) revert UnknownRevert();

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        revert(abi.decode(_returnData, (string))); // All that remains is the revert string
    }

    // ? This is safe so long as the implmentation contract does not have any obvious
    // ? vulns around calling functions with raised permissions ie admin function callable by anyone
    // controlled-delegatecall,low-level-calls
    // slither-disable-next-line all
    function _delegatecall(
        bytes memory selector
    ) internal returns (bytes memory) {
        (bool success, bytes memory data) = delegateeAddress.delegatecall(selector);
        assembly {
            if eq(success, 0) {
                revert(add(data, 0x20), returndatasize())
            }
        }
        return data;
    }

    function delegateToImplementation(bytes memory selector) public returns (bytes memory) {
        return _delegatecall(selector);
    }

    function _staticcall(
        bytes memory selector
    ) public view returns (bytes memory) {
        (bool success, bytes memory data) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", selector));
        assembly {
            if eq(success, 0) {
                revert(add(data, 0x20), returndatasize())
            }
        }
        return abi.decode(data, (bytes));
    }
}