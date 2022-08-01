//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "../../satellite/pToken/PToken.sol";
import "../../satellite/pToken/PTokenAdmin.sol";
import "../../satellite/pToken/PTokenMessageHandler.sol";
import "../../satellite/pToken/interfaces/IPToken.sol";
import "../../satellite/pToken/interfaces/IPTokenMessageHandler.sol";
import "../../satellite/pToken/PTokenStorage.sol";
import "../interfaces/IDelegator.sol";
import "./events/PTokenDelegatorEvents.sol";

contract PTokenDelegator is
    IPToken,
    IPTokenMessageHandler,
    PTokenStorage,
    PTokenDelegatorEvents,
    IDelegator
{

    constructor(
        address _delegateeAddress,
        address _underlying,
        uint8 decimals_,
        address middleLayer_,
        address eccAddress
    ) {
        admin = delegatorAdmin = payable(msg.sender);

        setDelegateeAddress(_delegateeAddress);

        _delegatecall(abi.encodeWithSelector(
            PToken.initialize.selector,
            _underlying,
            decimals_,
            middleLayer_,
            eccAddress
        ));
    }

    function totalSupply() external view override returns(uint256 supply) {
        bytes memory data = _staticcall(abi.encodeWithSelector(
            PToken.totalSupply.selector
        ));

        (supply) = abi.decode(data, (uint256));
    }

    function balanceOf(address account) external view override returns (uint256 balance) {
        bytes memory data = _staticcall(abi.encodeWithSelector(
            PToken.balanceOf.selector,
            account
        ));

        (balance) = abi.decode(data, (uint256));
    }

    function mint(uint256 amount, address route) external override payable {
        _delegatecall(abi.encodeWithSelector(
            PToken.mint.selector,
            amount,
            route
        ));
    }

    function redeemUnderlying(uint256 redeemAmount, address route) external override payable {
        _delegatecall(abi.encodeWithSelector(
            PToken.redeemUnderlying.selector,
            redeemAmount,
            route
        ));
    }

    function setMidLayer(address newMiddleLayer) external override {
        _delegatecall(abi.encodeWithSelector(
            PTokenAdmin.setMidLayer.selector,
            newMiddleLayer
        ));
    }

    function setMasterCID(uint256 newChainId) external override {
        _delegatecall(abi.encodeWithSelector(
            PTokenAdmin.setMasterCID.selector,
            newChainId
        ));
    }

    function changeOwner(address payable _newOwner) external override {
        _delegatecall(abi.encodeWithSelector(
            PTokenAdmin.changeOwner.selector,
            _newOwner
        ));
    }

    function completeRedeem(
        IHelper.FBRedeem memory params,
        bytes32 metadata
    ) external override {
        _delegatecall(abi.encodeWithSelector(
            PTokenMessageHandler.completeRedeem.selector,
            params,
            metadata
        ));
    }

    function seize(
        IHelper.SLiquidateBorrow memory params,
        bytes32 metadata
    ) external override {
        _delegatecall(abi.encodeWithSelector(
            PTokenMessageHandler.seize.selector,
            params,
            metadata
        ));
    }

    function pauseMarket(bool pause) external override {
        _delegatecall(abi.encodeWithSelector(
            PTokenAdmin.pauseMarket.selector,
            pause
        ));
    }

    // ? Controlled delegate call is a misdetection here as the address is controlled by the contract
    // ? The only options the user is in controll of here is the function selector and params,
    // ? both of which are safe for the user to controll given that the implmentation is addressing msg.sender and
    // ? admin when in context of admin functions.
    // controlled-delegatecall,low-level-call
    // slither-disable-next-line all
    fallback() external payable {
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PTokenInternals.sol";
import "./PTokenEvents.sol";
import "./PTokenMessageHandler.sol";
import "./PTokenAdmin.sol";

contract PToken is
    IPTokenInternals,
    PTokenInternals,
    PTokenEvents,
    PTokenMessageHandler,
    PTokenAdmin
{
    function initialize(
        address _underlying,
        uint8 decimals_,
        address newMiddleLayer,
        address eccAddress
    ) external payable onlyOwner() {
        // if(address(_underlying) == address(0)) revert AddressExpected();
        if(address(newMiddleLayer) == address(0)) revert AddressExpected();
        if(address(eccAddress) == address(0)) revert AddressExpected();
        require(address(middleLayer) == address(0), "INITIALIZE_CALLED_TWICE");
        underlying = _underlying;
        decimals = decimals_;
        middleLayer = IMiddleLayer(newMiddleLayer);
        ecc = IECC(eccAddress);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external virtual override view returns (uint256) {
        return accountTokens[account];
    }

    function mint(
        uint256 amount,
        address route
    ) external override payable {
        if (isPaused) revert MarketIsPaused();

        uint256 actualMintAmount = _doTransferIn(amount);

        /*
         * We get the current exchange rate and calculate the number of pTokens to be minted:
         *  mintTokens = actualMintAmount / exchangeRate
         */
        _sendMint(
            actualMintAmount,
            route,
            underlying == address(0)
                ? msg.value - actualMintAmount
                : msg.value
        );

        _totalSupply += actualMintAmount;
        accountTokens[msg.sender] += actualMintAmount;

        /* We emit a Mint event, and a Transfer event */
        // emit Transfer(address(this), msg.sender, actualMintAmount);
    }

    /**
    * @notice Sender redeems pTokens in exchange for a specified amount of underlying asset
    * @dev Accrues interest whether or not the operation succeeds, unless reverted
    * @param redeemAmount The amount of underlying to receive from redeeming pTokens
    */
    function redeemUnderlying(
        uint256 redeemAmount,
        address route
    ) external override payable nonReentrant() {
        _redeemAllowed(msg.sender, redeemAmount, route);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/IPToken.sol";
import "./PTokenModifiers.sol";
import "./PTokenEvents.sol";

abstract contract PTokenAdmin is IPToken, PTokenModifiers, PTokenEvents {
    function setMidLayer(
        address newMiddleLayer
    ) external override onlyOwner() {
        if(newMiddleLayer == address(0)) revert AddressExpected();
        middleLayer = IMiddleLayer(newMiddleLayer);

        emit SetMidLayer(newMiddleLayer);
    }

    function setMasterCID(
        uint256 newChainId
    ) external override onlyOwner() {
        masterCID = newChainId;

        emit SetMasterCID(newChainId);
    }

    function pauseMarket(
        bool pause
    ) external override onlyOwner() {
        isPaused = pause;

        emit MarketPaused(pause);
    }

    function changeOwner(
        address payable newOwner
    ) external override onlyOwner() {
        if(newOwner == address(0)) revert AddressExpected();
        admin = newOwner;

        emit ChangeOwner(newOwner);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./PTokenStorage.sol";
import "./PTokenInternals.sol";
import "./PTokenModifiers.sol";
import "./PTokenEvents.sol";
import "../../interfaces/IHelper.sol";
import "./interfaces/IPTokenMessageHandler.sol";
import "../../util/CommonModifiers.sol";

abstract contract PTokenMessageHandler is
    IPTokenInternals,
    IPTokenMessageHandler,
    PTokenModifiers,
    PTokenEvents,
    CommonModifiers
{
    // slither-disable-next-line assembly
    function _redeemAllowed(
        address user,
        uint256 redeemAmount,
        address route
    ) internal virtual override {
        if (redeemAmount == 0) revert ExpectedRedeemAmount();
        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.MRedeemAllowed(
                IHelper.Selector.MASTER_REDEEM_ALLOWED,
                address(this),
                user,
                redeemAmount
            )
        );

        bytes32 metadata = ecc.preRegMsg(payload, msg.sender);
        assembly {
            mstore(add(payload, 0x20), metadata)
        }

        middleLayer.msend{value: msg.value}(
            masterCID,
            payload, // bytes payload
            payable(msg.sender), // refund address
            route
        );

        emit RedeemSent(
            user,
            address(this),
            accountTokens[msg.sender],
            redeemAmount
        );
    }

    // slither-disable-next-line assembly
    function _sendMint(
        uint256 mintTokens,
        address route,
        uint256 gas
    ) internal virtual override {

        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.MDeposit({
                selector: IHelper.Selector.MASTER_DEPOSIT,
                user: msg.sender,
                pToken: address(this),
                previousAmount: accountTokens[msg.sender],
                amountIncreased: mintTokens
            })
        );

        bytes32 metadata = ecc.preRegMsg(payload, msg.sender);
        assembly {
            mstore(add(payload, 0x20), metadata)
        }

        middleLayer.msend{ value: gas }(
            masterCID,
            payload,
            payable(msg.sender),
            route
        );

        emit MintSent(
            msg.sender,
            address(this),
            mintTokens
        );
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another CToken.
     *  Its absolutely critical to use msg.sender as the seizer pToken and not a parameter.
     */
    function seize(
        IHelper.SLiquidateBorrow memory params,
        bytes32 metadata
    ) external override /*nonReentrant()*/ onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) revert EccMessageAlreadyProcessed();

        if (!ecc.flagMsgValidated(abi.encode(params), metadata)) revert EccFailedToValidate();

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)
        accountTokens[params.borrower] = accountTokens[params.borrower] - params.seizeTokens;
        _doTransferOut(params.liquidator, params.seizeTokens);

        // emit Transfer(params.borrower, params.liquidator, params.seizeTokens);
    }

    function completeRedeem(
        IHelper.FBRedeem memory params,
        bytes32 metadata
    ) external override onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) revert EccMessageAlreadyProcessed();

        if (!ecc.flagMsgValidated(abi.encode(params), metadata)) revert EccFailedToValidate();

        // /* Verify market's block number equals current block number */
        emit RedeemApproved(
            params.user,
            address(this),
            params.redeemAmount,
            true
        );

        /*
        * We calculate the new total supply and redeemer balance, checking for underflow:
        *  totalSupplyNew = totalSupply - redeemTokens
        *  accountTokensNew = accountTokens[redeemer] - redeemTokens
        */

        if (accountTokens[params.user] < params.redeemAmount) revert RedeemTooMuch();

        // TODO: make sure we cannot exploit this by having an exchange rate difference in redeem and complete redeem functions

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
        * We invoke doTransferOut for the redeemer and the redeemAmount.
        *  Note: The pToken must handle variations between ERC-20 and ETH underlying.
        *  On success, the pToken has redeemAmount less of cash.
        *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
        */
        _doTransferOut(params.user, params.redeemAmount);

        _totalSupply -= params.redeemAmount;
        accountTokens[params.user] -= params.redeemAmount;

        /* We emit a Transfer event, and a Redeem event */
        // emit Transfer(params.user, address(this), params.redeemAmount);

        // TODO: Figure out why this was necessary
        // /* We call the defense hook */
        // riskEngine.redeemVerify(
        //   address(this),
        //   redeemer,
        //   vars.redeemAmount,
        //   vars.redeemTokens
        // );

    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract IPToken {

    function mint(uint256 amount, address route) external virtual payable;

    function redeemUnderlying(uint256 redeemAmount, address route) external virtual payable;

    function balanceOf(address account) external view virtual returns (uint256);

    function totalSupply() external view virtual returns (uint256);

    function setMidLayer(address newMiddleLayer) external virtual;

    function setMasterCID(uint256 newChainId) external virtual;

    function changeOwner(address payable _newOwner) external virtual;

    function pauseMarket(bool pause) external virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../../interfaces/IHelper.sol";

abstract contract IPTokenMessageHandler {

    function completeRedeem(
        IHelper.FBRedeem memory params,
        bytes32 metadata
    ) external virtual;

    function seize(
        IHelper.SLiquidateBorrow memory params,
        bytes32 metadata
    ) external virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../middleLayer/interfaces/IMiddleLayer.sol";
import "../../ecc/interfaces/IECC.sol";
import "../../master/irm/interfaces/IIRM.sol";
import "../../master/crm/interfaces/ICRM.sol";

abstract contract PTokenStorage {
    // slither-disable-next-line unused-state
    uint256 internal masterCID;

    // slither-disable-next-line unused-state
    IECC internal ecc;

    // slither-disable-next-line unused-state
    IMiddleLayer internal middleLayer;

    /**
    * @notice EIP-20 token for this PToken
    */
    address public underlying;

    /**
    * @notice Administrator for this contract
    */
    address payable public admin;

    bool public isPaused;

    /**
    * @notice Pending administrator for this contract
    */
    // Currently not in use, may add in future
    // address payable public pendingAdmin;

    /**
    * @notice Model which tells what the current interest rate should be
    */
    IIRM public interestRateModel;

    /**
    * @notice Model which tells whether a user may withdraw collateral or take on additional debt
    */
    ICRM public initialCollateralRatioModel;

    /**
    * @notice EIP-20 token decimals for this token
    */
    uint8 public decimals;

    /**
    * @notice Official record of token balances for each account
    */
    // slither-disable-next-line unused-state
    mapping(address => uint256) internal accountTokens;

    /**
    * @notice Approved token transfer amounts on behalf of others
    */
    // slither-disable-next-line unused-state
    mapping(address => mapping(address => uint256)) internal transferAllowances;

    // slither-disable-next-line unused-state
    uint256 internal _totalSupply;
}

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "../common/DelegatorModifiers.sol";
import "../common/DelegatorErrors.sol";
import "../common/DelegatorEvents.sol";
import "../common/DelegatorStorage.sol";

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

abstract contract PTokenDelegatorEvents {

    event ExchangeRateStored(uint256 rate);
    event BalanceOf(uint256 balance);
    event Allowance(uint256 allowance);
    event ApproveDelegator(bool success);
    event TransferFrom(bool success);
    event TotalSupply(uint256 total);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/IPTokenInternals.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../util/CommonErrors.sol";

abstract contract PTokenInternals is IPTokenInternals, CommonErrors {

    // slither-disable-next-line assembly
    function _doTransferIn(
        uint256 amount
    ) internal virtual override returns (uint256) {
        address pTokenContract = address(this);
        if (underlying == address(0)) {
            require(msg.value >= amount, "TOKEN_TRANSFER_IN_FAILED");
            return amount;
        }
        IERC20 token = IERC20(underlying);
        uint256 balanceBefore = IERC20(underlying).balanceOf(pTokenContract);
        // ? We are checking the transfer, but since we are doing so in an assembly block
        // ? Slither does not pick up on that and results in a hit
        // slither-disable-next-line unchecked-transfer
        token.transferFrom(msg.sender, pTokenContract, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := 1 // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                success := 0
            }
        }
        if (!success) revert TransferFailed(msg.sender, address(this));

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(underlying).balanceOf(pTokenContract);

        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    function _getCashPrior() internal virtual override view returns (uint256) {
        if (underlying == address(0)) return address(this).balance;
        IERC20 token = IERC20(underlying);
        return token.balanceOf(address(this));
    }

    // slither-disable-next-line assembly
    function _doTransferOut(
        address to,
        uint256 amount
    ) internal virtual override {
        if (underlying == address(0)) {
            require(address(this).balance >= amount, "TOKEN_TRANSFER_OUT_FAILED");
            payable(to).transfer(amount);
            return;
        }
        IERC20 token = IERC20(underlying);
        // ? We are checking the transfer, but since we are doing so in an assembly block
        // ? Slither does not pick up on that and results in a hit
        // slither-disable-next-line unchecked-transfer
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := 1 // set success to true
            }
            case 32 {
                // This is a complaint ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                success := 0
            }
        }
        if (!success) revert TransferFailed(address(this), msg.sender);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../master/irm/interfaces/IIRM.sol";

abstract contract PTokenEvents {

    event MintSent(
        address indexed user,
        address indexed pToken,
        uint256 amount
    );

    event RedeemSent(
        address indexed user,
        address indexed pToken,
        uint256 accountTokens,
        uint256 redeemAmount
    );

     event RedeemApproved(
         address indexed user,
         address indexed pToken,
         uint256 redeemAmount,
         bool isRedeemAllowed
     );

    /*** Admin Events ***/

    event SetMidLayer(
        address middleLayer
    );

    event SetMasterCID(
        uint256 cid
    );

    event ChangeOwner(
        address newOwner
    );

    event MarketPaused(
        bool isPaused
    );
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../PTokenStorage.sol";

abstract contract IPTokenInternals is PTokenStorage {//is IERC20 {

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function _doTransferIn(
        uint256 amount
    ) internal virtual returns (uint256);

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    function _getCashPrior() internal virtual view returns (uint256);


    /**
    * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
    *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
    *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
    *      it is >= amount, this should not revert in normal conditions.
    *
    *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
    *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
    */
    function _doTransferOut(
        address to,
        uint256 amount
    ) internal virtual;

    function _sendMint(uint256 mintTokens, address route, uint256 gas) internal virtual;

    function _redeemAllowed(
        address user,
        uint256 redeemAmount,
        address route
    ) internal virtual;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract CommonErrors {
    error AccountNoAssets(address account);
    error AddressExpected();
    error EccMessageAlreadyProcessed();
    error EccFailedToValidate();
    error ExpectedRedeemAmount();
    error ExpectedRepayAmount();
    error InsufficientReserves();
    error InvalidPayload();
    error InvalidPrice();
    error MarketExists();
    error MarketIsPaused();
    error NotInMarket(uint256 chainId, address token);
    error OnlyAuth();
    error OnlyGateway();
    error OnlyMiddleLayer();
    error OnlyOwner();
    error OnlyRoute();
    error Reentrancy();
    error RepayTooMuch(uint256 repayAmount, uint256 maxAmount);
    error RedeemTooMuch();
    error NotEnoughBalance(address token, address who);
    error LiquidateDisallowed();
    error SeizeTooMuch();
    error RouteNotSupported(address route);
    error TransferFailed(address from, address dest);
    error TransferPaused();
    error UnknownRevert();
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract IMiddleLayer {
    /**
     * @notice routes and encodes messages for you
     * @param params - abi.encode() of the struct related to the selector, used to generate _payload
     * all params starting with '_' are directly sent to the lz 'send()' function
     */
    function msend(
        uint256 _dstChainId,
        bytes memory params,
        address payable _refundAddress,
        address fallbackAddress
    ) external payable virtual;

    function mreceive(
        uint256 _srcChainId,
        bytes memory payload
    ) external virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IECC {
    struct Metadata {
        bytes5 soph; // start of payload hash
        uint40 creation;
        uint16 nonce; // in case the same exact message is sent multiple times the same block, we increase the nonce in metadata
        address sender;
    }

    function preRegMsg(
        bytes memory payload,
        address instigator
    ) external returns (bytes32 metadata);

    function preProcessingValidation(
        bytes memory payload,
        bytes32 metadata
    ) external view returns (bool allowed);

    function flagMsgValidated(
        bytes memory payload,
        bytes32 metadata
    ) external returns (bool);

    // function rsm(uint256 messagePtr) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IIRM {
    function setBasisPointsTickSize(uint256 price) external returns (uint256 tickSize);
    function setBasisPointsUpperTick(uint256 upperTick) external returns (uint256 tick);
    function setBasisPointsLowerTick(uint256 lowerTick) external returns (uint256 tick);
    function setPusdLowerTargetPrice(uint256 lowerPrice) external returns (uint256 price);
    function setPusdUpperTargetPrice(uint256 upperPrice) external returns (uint256 price);
    function setBorrowRate() external returns (uint256 rate);
    function setMasterState(address newMasterState) external returns (address);
    function setObservationPeriod(uint256 obsPeriod) external returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ICRM {
    function setPusdPriceCeiling(uint256 price) external returns (uint256 ceiling);
    function setPusdPriceFloor(uint256 price) external returns (uint256 floor);
    function setAbsMaxLtvRatio(uint256 chainId, address market, uint256 _maxLtvRatio) external;
    function setCollateralRatioModel(uint256 chainId, address markets, ICRM collateralRatioModel) external;

    //TODO: put in separate interface
    function getCurrentMaxLtvRatio(uint256 chainId, address asset) external view returns (uint256 ratio);
    function getAbsMaxLtvRatio(uint256 chainId, address asset) external view returns (uint256);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./PTokenStorage.sol";
import "../../util/CommonErrors.sol";

abstract contract PTokenModifiers is PTokenStorage, CommonErrors {
    modifier onlyOwner() {
        if(msg.sender != admin) revert OnlyOwner();
        _;
    }

    modifier onlyMid() {
        if (msg.sender != address(middleLayer)) revert OnlyMiddleLayer();
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface IHelper {
    enum Selector {
        MASTER_DEPOSIT,
        MASTER_REDEEM_ALLOWED,
        FB_REDEEM,
        MASTER_REPAY,
        MASTER_BORROW_ALLOWED,
        FB_BORROW,
        SATELLITE_LIQUIDATE_BORROW,
        PUSD_BRIDGE
    }

    // !!!!
    // @dev
    // an artificial uint256 param for metadata should be added
    // after packing the payload
    // metadata can be generated via call to ecc.preRegMsg()

    struct MDeposit {
        Selector selector; // = Selector.MASTER_DEPOSIT
        address user;
        address pToken;
        uint256 previousAmount;
        uint256 amountIncreased;
    }

    struct MRedeemAllowed {
        Selector selector; // = Selector.MASTER_REDEEM_ALLOWED
        address pToken;
        address user;
        uint256 amount;
    }

    struct FBRedeem {
        Selector selector; // = Selector.FB_REDEEM
        address pToken;
        address user;
        uint256 redeemAmount;
    }

    struct MRepay {
        Selector selector; // = Selector.MASTER_REPAY
        address borrower;
        uint256 amountRepaid;
        address loanMarketAsset;
    }

    struct MBorrowAllowed {
        Selector selector; // = Selector.MASTER_BORROW_ALLOWED
        address user;
        uint256 borrowAmount;
        address loanMarketAsset;
    }

    struct FBBorrow {
        Selector selector; // = Selector.FB_BORROW
        address user;
        uint256 borrowAmount;
        address loanMarketAsset;
    }

    struct SLiquidateBorrow {
        Selector selector; // = Selector.SATELLITE_LIQUIDATE_BORROW
        address borrower;
        address liquidator;
        uint256 seizeTokens;
        address pTokenCollateral;
    }


    struct PUSDBridge {
        uint8 selector; // = Selector.PUSD_BRIDGE
        address minter;
        uint256 amount;
    }
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