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

import "./DelegatorErrors.sol";
import "./DelegatorStorage.sol";

contract DelegatorUtil is DelegatorStorage {
    // slither-disable-next-line assembly
    function _safeRevert(bool success, bytes memory _returnData) internal pure {
        if (success) return;

        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) revert("Transaction reverted silently");

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

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

contract DelegatorStorage {

    address payable public delegatorAdmin;

    address public delegateeAddress;
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
        require(newDelegateeAddress != address(0), "NON_ZEROADDRESS");
        (delegateeAddress, newDelegateeAddress) = (newDelegateeAddress, delegateeAddress);

        emit DelegateeAddressUpdate(newDelegateeAddress, delegateeAddress);
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

contract DelegatorEvents {

    event DelegateeAddressUpdate(address oldDelegateeAddress, address newDelegateeAddress);
}

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "../../satellite/pToken/PToken.sol";
import "../../satellite/pToken/PErc20.sol";
import "../../satellite/pToken/PTokenAdmin.sol";
import "../../satellite/pToken/PTokenMessageHandler.sol";
import "../../satellite/pToken/interfaces/IPToken.sol";
import "../../satellite/pToken/interfaces/IPTokenMessageHandler.sol";
import "../../satellite/pToken/PTokenStorage.sol";
import "../interfaces/IDelegator.sol";
import "./events/PTokenDelegatorEvents.sol";

contract PTokenDelegator is
    IPToken,
    IERC20,
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

    function mint(uint256 amount) external override payable {
        _delegatecall(abi.encodeWithSelector(
            PToken.mint.selector,
            amount
        ));
    }

    function redeemUnderlying(uint256 redeemAmount) external override payable {
        _delegatecall(abi.encodeWithSelector(
            PToken.redeemUnderlying.selector,
            redeemAmount
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

    function balanceOf(address account) external view override returns (uint256 balance) {
        bytes memory data = _staticcall(abi.encodeWithSelector(
            PErc20.balanceOf.selector,
            account
        ));

        (balance) = abi.decode(data, (uint256));
    }

    function transfer(address to, uint256 amount) external override returns (bool success) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            PErc20.transfer.selector,
            to,
            amount
        ));

        (success) = abi.decode(data, (bool));

        emit TransferDelegator(success);
    }

    function allowance(address owner, address spender) external view override returns (uint256 _allowance) {
        bytes memory data = _staticcall(abi.encodeWithSelector(
            PErc20.allowance.selector,
            owner,
            spender
        ));

        (_allowance) = abi.decode(data, (uint256));
    }

    function approve(address spender, uint256 amount) external override returns (bool success) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            PErc20.approve.selector,
            spender,
            amount
        ));

        (success) = abi.decode(data, (bool));

        emit ApproveDelegator(success);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool success) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            PErc20.transferFrom.selector,
            from,
            to,
            amount
        ));

        (success) = abi.decode(data, (bool));

        emit TransferFrom(success);
    }

    function completeTransfer(
        IHelper.FBCompleteTransfer memory params,
        bytes32 metadata
    ) external override {
        _delegatecall(abi.encodeWithSelector(
            PTokenMessageHandler.completeTransfer.selector,
            params,
            metadata
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

    function totalSupply() external view override returns (uint256 total) {
        bytes memory data = _staticcall(abi.encodeWithSelector(
            PErc20.totalSupply.selector
        ));

        (total) = abi.decode(data, (uint256));
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
import "./PErc20.sol";

contract PToken is
    IPTokenInternals,
    PTokenInternals,
    PTokenEvents,
    PTokenMessageHandler,
    PTokenAdmin,
    PErc20
{

    function initialize(
        address _underlying,
        uint8 decimals_,
        address newMiddleLayer,
        address eccAddress
    ) external payable onlyOwner() {
        require(address(_underlying) != address(0), "NON_ZEROADDRESS");
        require(address(newMiddleLayer) != address(0), "NON_ZEROADDRESS");
        require(address(eccAddress) != address(0), "NON_ZEROADDRESS");
        require(address(middleLayer) == address(0), "INITIALIZE_CALLED_TWICE");
        underlying = _underlying;
        decimals = decimals_;
        middleLayer = IMiddleLayer(newMiddleLayer);
        ecc = IECC(eccAddress);
        // owner = msg.sender;
    }

    function totalSupply() external view override (PErc20, IERC20) returns (uint256) {
        return _totalSupply;
    }

    function mint(
        uint256 amount
    ) external override payable {
        require(!isPaused, "MARKET_PAUSED");
        // See: https://github.com/Prime-Protocol/CrossChainContracts/pull/63#issuecomment-1136545501
        uint256 actualMintAmount = _doTransferIn(msg.sender, amount);
        /*
         * We get the current exchange rate and calculate the number of pTokens to be minted:
         *  mintTokens = actualMintAmount / exchangeRate
         */
        _sendMint(actualMintAmount);

        _totalSupply += actualMintAmount;
        accountTokens[msg.sender] += actualMintAmount;

        /* We emit a Mint event, and a Transfer event */
        emit Transfer(address(this), msg.sender, actualMintAmount);
    }

    /**
    * @notice Sender redeems pTokens in exchange for a specified amount of underlying asset
    * @dev Accrues interest whether or not the operation succeeds, unless reverted
    * @param redeemAmount The amount of underlying to receive from redeeming pTokens
    */
    function redeemUnderlying(
        uint256 redeemAmount
    ) external override payable nonReentrant() {
        _redeemAllowed(msg.sender, redeemAmount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./PTokenMessageHandler.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./PTokenModifiers.sol";
import "../../interfaces/IHelper.sol";

abstract contract PErc20 is
    IERC20,
    PTokenModifiers,
    PTokenMessageHandler
{

    function totalSupply() external view virtual override (IERC20) returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external virtual override view returns (uint256) {
        return accountTokens[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transfer(address dst, uint256 amount)
        external
        override
        nonReentrant()
        returns (bool)
    {
        _transferTokens(msg.sender, msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return transferAllowances[owner][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return success Whether or not the call succeeded
     */
    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        transferAllowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external override nonReentrant() returns (bool) {
        _transferTokens(msg.sender, src, dst, amount);
        return false;
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
        require(newMiddleLayer != address(0), "NON_ZEROADDRESS");
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
        require(newOwner != address(0), "NON_ZEROADDRESS");
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
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract PTokenMessageHandler is
    IPTokenInternals,
    IERC20,
    IPTokenMessageHandler,
    PTokenModifiers,
    PTokenEvents,
    CommonModifiers
{
    // slither-disable-next-line assembly
    function _redeemAllowed(
        address user,
        uint256 redeemAmount
    ) internal virtual override {
        require(redeemAmount > 0, "REDEEM_AMOUNT_NON_ZERO");
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
            address(0)
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
        uint256 mintTokens
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

        middleLayer.msend{ value: msg.value }(
            masterCID,
            payload,
            payable(msg.sender),
            address(0)
        );

        emit MintSent(
            msg.sender,
            address(this),
            mintTokens
        );
    }

    // slither-disable-next-line assembly
    function _transferTokens(
        address spender,
        address src,
        address dst,
        uint256 tokens
    ) internal virtual override {
        require(src != dst, "BAD_INPUT | SELF_TRANSFER_NOT_ALLOWED");
        require(tokens <= accountTokens[src], "Requested amount too high");

        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.MTransferAllowed(
                uint8(IHelper.Selector.MASTER_TRANSFER_ALLOWED),
                address(this),
                spender,
                src,
                dst,
                tokens
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
            address(0)
        );

        emit TransferInitiated(src, dst, tokens);
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another CToken.
     *  Its absolutely critical to use msg.sender as the seizer pToken and not a parameter.
     */
    function seize(
        IHelper.SLiquidateBorrow memory params,
        bytes32 metadata
    ) external override nonReentrant() onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) return;

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)
        accountTokens[params.borrower] = accountTokens[params.borrower] - params.seizeTokens;
        _doTransferOut(params.liquidator, params.seizeTokens);

        emit Transfer(params.borrower, params.liquidator, params.seizeTokens);
        require(ecc.flagMsgValidated(abi.encode(params), metadata), "FMV");

    }

    function completeRedeem(
        IHelper.FBRedeem memory params,
        bytes32 metadata
    ) external override onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) return;
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
        require(_totalSupply >= params.redeemAmount, "INSUFFICIENT_LIQUIDITY");

        require(
            accountTokens[params.user] >= params.redeemAmount,
            "Trying to redeem too much"
        );

        // TODO: make sure we cannot exploit this by having an exchange rate difference in redeem and complete redeem functions

        /* Fail gracefully if protocol has insufficient cash */
        require(
            _getCashPrior() >= params.redeemAmount,
            "TOKEN_INSUFFICIENT_CASH | REDEEM_TRANSFER_OUT_NOT_POSSIBLE"
        );

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
        emit Transfer(params.user, address(this), params.redeemAmount);

        // TODO: Figure out why this was necessary
        // /* We call the defense hook */
        // riskEngine.redeemVerify(
        //   address(this),
        //   redeemer,
        //   vars.redeemAmount,
        //   vars.redeemTokens
        // );

        require(ecc.flagMsgValidated(abi.encode(params), metadata), "FMV");
    }

    function completeTransfer(
        IHelper.FBCompleteTransfer memory params,
        bytes32 metadata
    ) external override onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) return;

        /* Get the allowance, infinite for the account owner */
        uint256 startingAllowance = params.spender == params.src
            ? type(uint256).max
            : transferAllowances[params.src][params.spender];

        require(startingAllowance >= params.tokens, "Not enough allowance");

        require(accountTokens[params.src] >= params.tokens, "Not enough tokens");

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        accountTokens[params.src] -= params.tokens;
        accountTokens[params.dst] += params.tokens;

        /* Eat some of the allowance (if necessary) */
        if (startingAllowance != type(uint256).max) {
            transferAllowances[params.src][params.spender] -= params.tokens;
        }

        emit Transfer(params.src, params.dst, params.tokens);

        require(ecc.flagMsgValidated(abi.encode(params), metadata), "FMV");
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract IPToken {

    function mint(uint256 amount) external virtual payable;

    function redeemUnderlying(uint256 redeemAmount) external virtual payable;

    function setMidLayer(address newMiddleLayer) external virtual;

    function setMasterCID(uint256 newChainId) external virtual;

    function changeOwner(address payable _newOwner) external virtual;

    function pauseMarket(bool pause) external virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../../interfaces/IHelper.sol";

abstract contract IPTokenMessageHandler {

    function completeTransfer(
        IHelper.FBCompleteTransfer memory params,
        bytes32 metadata
    ) external virtual;

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract PTokenDelegatorEvents {

    event ExchangeRateStored(uint256 rate);
    event BalanceOf(uint256 balance);
    event TransferDelegator(bool success);
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

abstract contract PTokenInternals is IPTokenInternals, IERC20 {

    // slither-disable-next-line assembly
    function _doTransferIn(
        address from,
        uint256 amount
    ) internal virtual override returns (uint256) {
        address pTokenContract = address(this);
        IERC20 token = IERC20(underlying);
        uint256 balanceBefore = IERC20(underlying).balanceOf(pTokenContract);
        // ? We are checking the transfer, but since we are doing so in an assembly block
        // ? Slither does not pick up on that and results in a hit
        // slither-disable-next-line unchecked-transfer
        token.transferFrom(from, pTokenContract, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(underlying).balanceOf(pTokenContract);
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");

        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    function _getCashPrior() internal virtual override view returns (uint256) {
        IERC20 token = IERC20(underlying);
        return token.balanceOf(address(this));
    }

    // slither-disable-next-line assembly
    function _doTransferOut(
        address to,
        uint256 amount
    ) internal virtual override {
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
                success := not(0) // set success to true
            }
            case 32 {
                // This is a complaint ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
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

    event TransferInitiated(
        address indexed from,
        address indexed to,
        uint256 amount
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
        address from,
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

    function _sendMint(uint256 mintTokens) internal virtual;

    function _redeemAllowed(
        address user,
        uint256 redeemAmount
    ) internal virtual;

    function _transferTokens(
        address spender,
        address src,
        address dst,
        uint256 tokens
    ) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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

    function getBasisPointsTickSize() external returns (uint256 tickSize);
    function getBasisPointsUpperTick() external returns (uint256 tick);
    function getBasisPointsLowerTick() external returns (uint256 tick);
    function setBasisPointsTickSize(uint256 price) external returns (uint256 tickSize);
    function setBasisPointsUpperTick(uint256 upperTick) external returns (uint256 tick);
    function setBasisPointsLowerTick(uint256 lowerTick) external returns (uint256 tick);
    function setPusdLowerTargetPrice(uint256 lowerPrice) external returns (uint256 price);
    function setPusdUpperTargetPrice(uint256 upperPrice) external returns (uint256 price);
    function getBorrowRateDecimals() external view returns (uint8 decimals);
    function getBorrowRate() external view returns (uint256 rate);
    function setBorrowRate() external returns (uint256 rate);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../../satellite/pToken/interfaces/IPToken.sol";

interface ICRM {
    function setPusdPriceCeiling(uint256 price) external returns (uint256 ceiling);
    function setPusdPriceFloor(uint256 price) external returns (uint256 floor);
    function setAbsMaxLtvRatios(uint256[] memory chainIds, IPToken[] memory markets, uint256[] memory _maxLtvRatios) external;
    function setCollateralRatioModels(uint256[] memory chainIds, IPToken[] memory markets, ICRM[] memory collateralRatioModels) external;
    function getCollateralRatioModel(uint256 chainId, IPToken asset) external returns (address model);

    //TODO: put in separate interface
    function getCurrentMaxLtvRatios(uint256[] memory chainIds, IPToken[] memory assets) external returns (uint256[] memory ratios);
    function getCurrentMaxLtvRatio(uint256 chainId, IPToken asset) external returns (uint256 ratio);
    function getAbsMaxLtvRatio(uint256 chainId, IPToken asset) external view returns (uint256);
    function getLtvRatioDecimals() external view returns (uint8 decimals);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./PTokenStorage.sol";

abstract contract PTokenModifiers is PTokenStorage {
    modifier onlyOwner() {
        require(msg.sender == admin, "ONLY_OWNER");
        _;
    }

    modifier onlyMid() {
        require(msg.sender == address(middleLayer), "ONLY_MIDDLE_LAYER");
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
        MASTER_TRANSFER_ALLOWED,
        FB_COMPLETE_TRANSFER,
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
    }

    struct MBorrowAllowed {
        Selector selector; // = Selector.MASTER_BORROW_ALLOWED
        address user;
        uint256 borrowAmount;
    }

    struct FBBorrow {
        Selector selector; // = Selector.FB_BORROW
        address user;
        uint256 borrowAmount;
    }

    struct SLiquidateBorrow {
        Selector selector; // = Selector.SATELLITE_LIQUIDATE_BORROW
        address borrower;
        address liquidator;
        uint256 seizeTokens;
        address pTokenCollateral;
    }

    struct MTransferAllowed {
        uint8 selector; // = Selector.MASTER_TRANSFER_ALLOWED
        address pToken;
        address spender;
        address user;
        address dst;
        uint256 amount;
    }

    struct FBCompleteTransfer {
        uint8 selector; // = Selector.FB_COMPLETE_TRANSFER
        address pToken;
        address spender;
        address src;
        address dst;
        uint256 tokens;
    }

    struct PUSDBridge {
        uint8 selector; // = Selector.PUSD_BRIDGE
        address minter;
        uint256 amount;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract CommonModifiers {

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
        require(notEntered, "re-entered");
        notEntered = false;
        _;
        notEntered = true; // get a gas-refund post-Istanbul
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../../middleLayer/interfaces/IMiddleLayer.sol";
import "../../interfaces/IHelper.sol";
import "./PUSDStorage.sol";
import "./PUSDMessageHandler.sol";
import "./PUSDAdmin.sol";

contract PUSD is PUSDAdmin, PUSDMessageHandler {
        constructor(
        string memory tknName,
        string memory tknSymbol,
        uint256 _chainId,
        address eccAddress,
        uint8 decimals_
    ) ERC20(tknName, tknSymbol) {
        admin = msg.sender;
        chainId = _chainId;
        ecc = IECC(eccAddress);
        _decimals = decimals_;
    }

    function mint(
        address to,
        uint256 amount
    ) external onlyPermissioned() {
        _mint(to, amount);
    }

    /**
     * @notice Burn tokens on the local chain and mint on the destination chain
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param dstChainId Destination chain to mint
     * @param receiver Wallet that is sending/burning PUSD
     * @param amount Amount to burn locally/mint on the destination chain
     */
    function sendTokensToChain(
        uint256 dstChainId,
        address receiver,
        uint256 amount
    ) external payable {
        require(!paused, "PUSD_TRANSFERS_PAUSED");
        _sendTokensToChain(dstChainId, receiver, amount);
    }

    /// @dev Used to estimate the fee of sending cross chain- commented out until we test with network tokens
    // function estimateSendTokensFee(
    //     uint256 _dstChainId,
    //     bytes calldata _toAddress,
    //     bool _useZro,
    //     bytes calldata _txParameters
    // ) external view returns (uint256 nativeFee, uint256 zroFee) {
    //     // mock the payload for sendTokens()
    //     bytes memory payload = abi.encode(_toAddress, 1);
    //     return
    //         lzManager.estimateFees(
    //             _dstChainId,
    //             address(this),
    //             payload,
    //             _useZro,
    //             _txParameters
    //         );
    // }

    fallback() external payable {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../middleLayer/interfaces/IMiddleLayer.sol";
import "../../ecc/interfaces/IECC.sol";

abstract contract PUSDStorage {
    address public admin;

    IMiddleLayer internal middleLayer;
    IECC internal ecc;

    uint8 internal _decimals;

    address internal treasuryAddress;
    address internal loanAgentAddress;
    uint256 internal chainId;
    bool internal paused;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./PUSDStorage.sol";
import "./PUSDAdmin.sol";
import "../../interfaces/IHelper.sol";
import "../../util/CommonModifiers.sol";

abstract contract PUSDMessageHandler is
    PUSDStorage,
    PUSDAdmin,
    ERC20Burnable,
    CommonModifiers
{

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
    
    // slither-disable-next-line assembly
    function _sendTokensToChain(
        uint256 _dstChainId,
        address receiver,
        uint256 amount
    ) internal {
        require(msg.sender == receiver, "X_CHAIN_ADDRESS_MUST_MATCH");
        require(!paused, "PUSD_TRANSFERS_PAUSED");

        uint256 _chainId = chainId;

        require(_dstChainId != _chainId, "DIFFERENT_CHAIN_REQUIRED");

        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.PUSDBridge(
                uint8(IHelper.Selector.PUSD_BRIDGE),
                receiver,
                amount
            )
        );

        bytes32 metadata = ecc.preRegMsg(payload, msg.sender);
        assembly {
            mstore(add(payload, 0x20), metadata)
        }

        // burn senders PUSD locally
        _burn(msg.sender, amount);

        middleLayer.msend{ value: msg.value }(
            _dstChainId,
            payload,
            payable(receiver), // refund address
            address(0)
        );

        emit SentToChain(_chainId, _dstChainId, receiver, amount);
    }

    function mintFromChain(
        IHelper.PUSDBridge memory params,
        bytes32 metadata,
        uint256 srcChain
    ) external onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) return;

        _mint(params.minter, params.amount);

        require(ecc.flagMsgValidated(abi.encode(params), metadata), "FMV");

        emit ReceiveFromChain(srcChain, params.minter, params.amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/IPUSD.sol";
import "./PUSDModifiers.sol";
import "./PUSDEvents.sol";

abstract contract PUSDAdmin is IPUSD, PUSDModifiers, PUSDEvents {

    function setLoanAgent(
        address newLoanAgent
    ) external onlyOwner() {
        require(newLoanAgent != address(0), "NON_ZEROADDRESS");
        loanAgentAddress = newLoanAgent;

        emit SetLoanAgent(newLoanAgent);
    }

    function setOwner(
        address newOwner
    ) external onlyOwner() {
        require(newOwner != address(0), "NON_ZEROADDRESS");
        admin = newOwner;

        emit SetOwner(newOwner);
    }

    function setTreasury(
        address newTreasury
    ) external onlyOwner() {
        require(newTreasury != address(0), "NON_ZEROADDRESS");
        treasuryAddress = newTreasury;

        emit SetTreasury(newTreasury);
    }

    function setMiddleLayer(
        address newMiddleLayer
    ) external onlyOwner() {
        require(newMiddleLayer != address(0), "NON_ZEROADDRESS");
        middleLayer = IMiddleLayer(newMiddleLayer);

        emit SetMiddleLayer(newMiddleLayer);
    }

    function pauseSendTokens(
        bool newPauseStatus
    ) external onlyOwner() {
        paused = newPauseStatus;
        emit Paused(newPauseStatus);
    }
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IPUSD {
    function mint(address to, uint256 amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./PUSDStorage.sol";

abstract contract PUSDModifiers is PUSDStorage {

    modifier onlyPermissioned() {
        require(
            msg.sender == treasuryAddress ||
            msg.sender == loanAgentAddress ||
            msg.sender == admin, // FIXME: Remove
            "Unauthorized minter"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == admin, "ONLY_OWNER");
        _;
    }

    modifier onlyMid() {
        require(msg.sender == address(middleLayer), "ONLY_MIDDLE_LAYER");
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract PUSDEvents {
    /**
     * @notice Event emitted when contract is paused
     */
    event Paused(bool isPaused);

    /**
     * @notice Event emitted when PUSD is sent cross-chain
     */
    event SentToChain(
        uint256 srcChainId,
        uint256 destChainId,
        address toAddress,
        uint256 amount
    );

    /**
     * @notice Event emitted when PUSD is received cross-chain
     */
    event ReceiveFromChain(
        uint256 srcChainId,
        address toAddress,
        uint256 amount
    );

    event SetLoanAgent(
        address loanAgentAddress
    );

    event SetOwner(
        address owner
    );

    event SetTreasury(
        address treasuryAddress
    );

    event SetMiddleLayer(
        address lzManager
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/ITreasury.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../util/CommonModifiers.sol";
import "../pusd/PUSD.sol";

contract Treasury is Ownable, ITreasury, CommonModifiers {
    constructor(
        address payable _pusdAddress,
        address payable _loanAgentAddress,
        uint256 _mintPrice,
        uint256 _burnPrice
    ) {
        require(_pusdAddress != address(0), "NON_ZEROADDRESS");
        require(_loanAgentAddress != address(0), "NON_ZEROADDRESS");
        pusdAddress = _pusdAddress;
        loanAgent = _loanAgentAddress;
        mintPrice = _mintPrice;
        burnPrice = _burnPrice;
    }

    /// @inheritdoc ITreasury
    function mintPUSD(
        address stablecoinAddress,
        uint256 stablecoinAmount
    ) external override nonReentrant() returns (bool) {

        ERC20 stablecoin = ERC20(stablecoinAddress);
        uint8 stablecoinDecimals = stablecoin.decimals();
        uint256 stablecoinPrice = 10**(stablecoinDecimals);

        require(
            stablecoin.balanceOf(msg.sender) >= stablecoinAmount,
            "msg.sender stablecoin balance too low"
        );

        PUSD pusd = PUSD(pusdAddress);
        uint256 pusdPrice = mintPrice;

        uint256 exchangeRate = pusdPrice * 10**stablecoinDecimals / stablecoinPrice;
        uint256 pusdAmount = stablecoinAmount * exchangeRate / (10**stablecoinDecimals);

        stablecoinReserves[stablecoinAddress] += stablecoinAmount;
        stablecoin.transferFrom(msg.sender, address(this), stablecoinAmount);
        pusd.mint(msg.sender, pusdAmount);

        return true;
    }

    /// @inheritdoc ITreasury
    function burnPUSD(
        address stablecoinAddress,
        uint256 pusdAmount
    ) external override nonReentrant() returns (bool) {
        //TODO: check PUSD allowance?
        
        PUSD pusd = PUSD(pusdAddress);
        uint256 pusdPrice = burnPrice;
        uint8 pusdDecimals = pusd.decimals();

        ERC20 stablecoin = ERC20(stablecoinAddress);
        uint8 stablecoinDecimals = stablecoin.decimals();
        uint256 stablecoinPrice = 10**(stablecoinDecimals);

        uint256 exchangeRate = stablecoinPrice * 10**pusdDecimals / pusdPrice;
        uint256 stablecoinAmount = pusdAmount * exchangeRate / (10**pusdDecimals);
        uint256 stablecoinReserve = stablecoinReserves[stablecoinAddress];

        require(
            stablecoinReserve >= stablecoinAmount,
            "Insufficient stablecoin in reserves"
        );

        stablecoinReserves[stablecoinAddress] = stablecoinReserve - stablecoinAmount;
        pusd.burnFrom(msg.sender, pusdAmount);
        require(stablecoin.transfer(msg.sender, stablecoinAmount), "TKN_TRANSFER_FAILED");

        return true;
    }

    /// @inheritdoc ITreasury
    function checkReserves(
        address tokenAddress
    ) external view override returns (uint256) {
        return stablecoinReserves[tokenAddress];
    }

    /// @inheritdoc ITreasury
    function deposit(
        address tokenAddress,
        uint256 amount
    ) external override nonReentrant() {
        IERC20 token = IERC20(tokenAddress);

        stablecoinReserves[tokenAddress] += amount;

        require(token.transferFrom(msg.sender, address(this), amount), "TKN_TRANSFER_FAILED");
    }

    /// @inheritdoc ITreasury
    function withdraw(
        address tokenAddress,
        uint256 amount,
        address recipient
    ) external override onlyOwner() nonReentrant() {
        uint256 stablecoinReserve = stablecoinReserves[tokenAddress];

        require(stablecoinReserve > amount, "not enough reserves");

        IERC20 token = IERC20(tokenAddress);

        stablecoinReserves[tokenAddress] = stablecoinReserve - amount;

        require(token.transfer(recipient, amount), "TKN_TRANSFER_FAILED");
    }

    /// @inheritdoc ITreasury
    function addReserveStablecoin(
        address newStableCoin
    ) external override onlyOwner() {
        require(newStableCoin != address(0), "NON_ZEROADDRESS");
        if (!supportedStablecoins[newStableCoin]) {
            supportedStablecoins[newStableCoin] = true;
            stablecoinReserves[newStableCoin] = 0;
        }
    }

    /// @inheritdoc ITreasury
    function removeReserveStablecoin(
        address stablecoinAddress
    ) external override onlyOwner() {
        require(stablecoinAddress != address(0), "NON_ZEROADDRESS");
        supportedStablecoins[stablecoinAddress] = false;
    }

    /// @inheritdoc ITreasury
    function setPUSDAddress(
        address payable newPUSD
    ) external override onlyOwner() {
        require(newPUSD != address(0), "NON_ZEROADDRESS");
        pusdAddress = newPUSD;
    }

    /// @inheritdoc ITreasury
    function setLoanAgent(
        address payable newLoanAgent
    ) external override onlyOwner() {
        require(newLoanAgent != address(0), "NON_ZEROADDRESS");
        loanAgent = newLoanAgent;
    }

    //transfer funds to the xPrime contract
    function accrueProfit() external override {
        // TODO
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/*
    Tokens in the treasury are divided between three buckets: reserves, insurance, and surplus.

    Reserve tokens accrue from the result of arbitrageurs buying PUSD from the treasury.

    Insurance tokens are held in for the event where a liquidation does not fully cover an outstanding loan.
    If an incomplete liquidation occurs, insurance tokens are transferred to reserves to back the newly outstanding PUSD
    When sufficient insurance tokens are accrued, newly recieved tokens are diverted to surplus.

    Surplus tokens are all remaining tokens that aren't backing or insuring ourstanding PUSD.
    When profit accrues, the value of surplus tokens is distributed to xPrime stakers.
*/

abstract contract ITreasury is Ownable {
    // Address of the PUSD contract on the same blockchain
    address payable public pusdAddress;

    // Address of the loan agent on the same blockchain
    address payable public loanAgent;

    /*
     * Mapping of addesss of accepted stablecoin to amount held in reserve
     */
    mapping(address => uint256) public stablecoinReserves;

    // Addresses of all the tokens in the treasury
    mapping(address => bool) public reserveTypes;

    // Addresses of stablecoins that can be swapped for PUSD at the guaranteed rate
    mapping(address => bool) public supportedStablecoins;

    // Exchange rate at which a trader can mint PUSD via the treasury. Should be more than 1
    uint256 public mintPrice;

    // Exchange rate at which a trader can burn PUSD via the treasury. Should be less than 1
    uint256 public burnPrice;

    /**
     * @notice Mint PUSD from the treasury at the guaranteed exchange rate
     * @dev This is called by an arbitrageur seeking to stabilize the PUSD peg
     * @param stablecoinAddress Address of the stablecoin the user will transfer in
     * @param stablecoinAmount Amount of of the stablecoin the user will transfer in
     * @return (bool, true if completed successfully) Note: should change this so a real error is returned
     */
    function mintPUSD(address stablecoinAddress, uint256 stablecoinAmount)
        external
        virtual
        returns (bool);

    /**
     * @notice Burn PUSD via the treasury at the guaranteed exchange rate
     * @dev This is called by an arbitrageur seeking to stabilize the PUSD peg
     * @param stablecoinAddress Address of the stablecoin given the user will transfer out
     * @param pusdAmount Amount of PUSD to transfer to the user
     * @return (bool, true if completed successfully) Note: should change this so a real error is returned
     */
    function burnPUSD(address stablecoinAddress, uint256 pusdAmount)
        external
        virtual
        returns (bool);

    /**
     * @notice Get the amount of a given token that the treasury holds
     * @dev This is called by a third party applications to analyze treasury holdings
     * @param tokenAddress Address of the coin to check balance of
     * @return The amount of the given token that this deployment of the treasury holds
     */
    function checkReserves(address tokenAddress)
        external
        view
        virtual
        returns (uint256);

    /**
     * @notice Deposit a given ERC20 token into the treasury
     * @dev Msg.sender will be the address used to transfer tokens from
     * @param tokenAddress Address of the coin to deposit
     * @param amount Amount of the token to deposit
     */
    function deposit(address tokenAddress, uint256 amount) external virtual;

    /**
     * @notice Withdraw a given ERC20 token from the treasury
     * @dev Withdrawals should not be allowed to come from reserves
     * @param tokenAddress Address of the coin to withdraw
     * @param amount Amount of the token to withdraw
     * @param recipient Address where tokens are sent to
     */
    function withdraw(
        address tokenAddress,
        uint256 amount,
        address recipient
    ) external virtual;

    /**
     * @notice Add a stablecoin to the list of accepted stablecoins for reserve status
     * @dev Update both the array and mapping
     * @param stablecoinAddress Stablecoin to be added to reserve whitelist
     */
    function addReserveStablecoin(address stablecoinAddress) external virtual;

    /**
     * @notice Remove a stablecoin to the list of accepted reserve stablecoins
     * @dev Update both the array and mapping
     * @param stablecoinAddress Stablecoin to be removed from reserve whitelist
     */
    function removeReserveStablecoin(address stablecoinAddress)
        external
        virtual;

    /**
     * @notice Sets the address of the PUSD contract
     * @param pusd Address of the new PUSD contract
     */
    function setPUSDAddress(address payable pusd) external virtual;

    /**
     * @notice Sets the address of the loan agent contract
     * @param loanAgentAddress Address of the new loan agent contract
     */
    function setLoanAgent(address payable loanAgentAddress) external virtual;

    /**
     * @notice Transfers funds to the xPrime contract
     */
    function accrueProfit() external virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;
pragma abicoder v2;

import "../../../util/CommonModifiers.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "./interfaces/ILayerZeroReceiver.sol";

/*
mocking multi endpoint connection.
- send() will short circuit to lzReceive() directly
- no reentrancy guard. the real LayerZero endpoint on main net has a send and receive guard, respectively.
if we run a ping-pong-like application, the recursive call might use all gas limit in the block.
- not using any messaging library, hence all messaging library func, e.g. estimateFees, version, will not work
*/
// slither-disable-next-line locked-ether
contract LZEndpointMock is ILayerZeroEndpoint, CommonModifiers {
    mapping(address => address) public lzEndpointLookup;

    uint16 public mockChainId;
    // slither-disable-next-line constable-states
    address payable public mockOracle;
    // slither-disable-next-line constable-states
    address payable public mockRelayer;
    // slither-disable-next-line constable-states
    uint256 public mockBlockConfirmations;
    // slither-disable-next-line constable-states
    uint16 public mockLibraryVersion;
    uint256 public mockStaticNativeFee;
    uint16 public mockLayerZeroVersion;
    uint256 public nativeFee;
    uint256 public zroFee;
    bool nextMsgBLocked;

    struct StoredPayload {
        uint64 payloadLength;
        address dstAddress;
        bytes32 payloadHash;
    }

    struct QueuedPayload {
        address dstAddress;
        uint64 nonce;
        bytes payload;
    }

    // inboundNonce = [srcChainId][srcAddress].
    mapping(uint16 => mapping(bytes => uint64)) public inboundNonce;
    // outboundNonce = [dstChainId][srcAddress].
    mapping(uint16 => mapping(address => uint64)) public outboundNonce;
    // storedPayload = [srcChainId][srcAddress]
    mapping(uint16 => mapping(bytes => StoredPayload)) public storedPayload;
    // msgToDeliver = [srcChainId][srcAddress]
    mapping(uint16 => mapping(bytes => QueuedPayload[])) public msgsToDeliver;

    event UaForceResumeReceive(uint16 chainId, bytes srcAddress);
    event PayloadCleared(
        uint16 srcChainId,
        bytes srcAddress,
        uint64 nonce,
        address dstAddress
    );
    event PayloadStored(
        uint16 srcChainId,
        bytes srcAddress,
        address dstAddress,
        uint64 nonce,
        bytes payload,
        bytes reason
    );

    constructor(uint16 _chainId) {
        mockStaticNativeFee = 42;
        mockLayerZeroVersion = 1;
        mockChainId = _chainId;
    }

    // mock helper to set the value returned by `estimateNativeFees`
    function setEstimatedFees(uint256 _nativeFee, uint256 _zroFee) external {
        nativeFee = _nativeFee;
        zroFee = _zroFee;
    }

    function getChainId() external view override returns (uint16) {
        return mockChainId;
    }

    function setDestLzEndpoint(address destAddr, address lzEndpointAddr)
        external
    {
        lzEndpointLookup[destAddr] = lzEndpointAddr;
    }

    // slither-disable-next-line assembly
    function send(
        uint16 _chainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable, // _refundAddress
        address, // _zroPaymentAddress
        bytes memory _adapterParams
    ) external payable override {
        address destAddr = packedBytesToAddr(_destination);
        address lzEndpoint = lzEndpointLookup[destAddr];

        require(
            lzEndpoint != address(0),
            "LayerZeroMock: destination LayerZero Endpoint not found"
        );

        uint64 nonce;
        {
            nonce = ++outboundNonce[_chainId][msg.sender];
        }

        // Mock the relayer paying the dstNativeAddr the amount of extra native token
        {
            uint256 extraGas;
            uint256 dstNative;
            address dstNativeAddr;
            assembly {
                extraGas := mload(add(_adapterParams, 34))
                dstNative := mload(add(_adapterParams, 66))
                dstNativeAddr := mload(add(_adapterParams, 86))
            }

            // to simulate actually sending the ether, add a transfer call and ensure the LZEndpointMock contract has an ether balance
        }

        bytes memory bytesSourceUserApplicationAddr = addrToPackedBytes(
            address(msg.sender)
        ); // cast this address to bytes

        // not using the extra gas parameter because this is a single tx call, not split between different chains
        // LZEndpointMock(lzEndpoint).receivePayload(mockChainId, bytesSourceUserApplicationAddr, destAddr, nonce, extraGas, _payload);
        LZEndpointMock(lzEndpoint).receivePayload(
            mockChainId,
            bytesSourceUserApplicationAddr,
            destAddr,
            nonce,
            0,
            _payload
        );
    }

    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint256, /*_gasLimit*/
        bytes calldata _payload
    ) external override {
        StoredPayload storage sp = storedPayload[_srcChainId][_srcAddress];

        // assert and increment the nonce. no message shuffling
        require(
            _nonce == ++inboundNonce[_srcChainId][_srcAddress],
            "LayerZero: wrong nonce"
        );

        // queue the following msgs inside of a stack to simulate a successful send on src, but not fully delivered on dst
        if (sp.payloadHash != bytes32(0)) {
            QueuedPayload[] storage msgs = msgsToDeliver[_srcChainId][
                _srcAddress
            ];
            QueuedPayload memory newMsg = QueuedPayload(
                _dstAddress,
                _nonce,
                _payload
            );

            // warning, might run into gas issues trying to forward through a bunch of queued msgs
            // shift all the msgs over so we can treat this like a fifo via array.pop()
            if (msgs.length > 0) {
                // extend the array
                msgs.push(newMsg);

                // shift all the indexes up for pop()
                for (uint256 i = 0; i < msgs.length - 1; i++) {
                    msgs[i + 1] = msgs[i];
                }

                // put the newMsg at the bottom of the stack
                msgs[0] = newMsg;
            } else {
                msgs.push(newMsg);
            }
        } else if (nextMsgBLocked) {
            storedPayload[_srcChainId][_srcAddress] = StoredPayload(
                uint64(_payload.length),
                _dstAddress,
                keccak256(_payload)
            );
            emit PayloadStored(
                _srcChainId,
                _srcAddress,
                _dstAddress,
                _nonce,
                _payload,
                bytes("")
            );
            // ensure the next msgs that go through are no longer blocked
            nextMsgBLocked = false;
        } else {
            // we ignore the gas limit because this call is made in one tx due to being "same chain"
            // ILayerZeroReceiver(_dstAddress).lzReceive{gas: _gasLimit}(_srcChainId, _srcAddress, _nonce, _payload); // invoke lzReceive
            ILayerZeroReceiver(_dstAddress).lzReceive(
                _srcChainId,
                _srcAddress,
                _nonce,
                _payload
            ); // invoke lzReceive
        }
    }

    // used to simulate messages received get stored as a payload
    function blockNextMsg() external {
        nextMsgBLocked = true;
    }

    function getLengthOfQueue(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (uint256)
    {
        return msgsToDeliver[_srcChainId][_srcAddress].length;
    }

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16,
        address,
        bytes memory,
        bool,
        bytes memory
    ) external view override returns (uint256 _nativeFee, uint256 _zroFee) {
        _nativeFee = nativeFee;
        _zroFee = zroFee;
    }

    // give 20 bytes, return the decoded address
    // slither-disable-next-line assembly
    function packedBytesToAddr(bytes calldata _b)
        public
        pure
        returns (address)
    {
        address addr;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, sub(_b.offset, 2), add(_b.length, 2))
            addr := mload(sub(ptr, 10))
        }
        return addr;
    }

    // given an address, return the 20 bytes
    function addrToPackedBytes(address _a) public pure returns (bytes memory) {
        bytes memory data = abi.encodePacked(_a);
        return data;
    }

    function setConfig(
        uint16, /*_version*/
        uint16, /*_chainId*/
        uint256, /*_configType*/
        bytes memory /*_config*/
    ) external override {}

    function getConfig(
        uint16, /*_version*/
        uint16, /*_chainId*/
        address, /*_ua*/
        uint256 /*_configType*/
    ) external pure override returns (bytes memory) {
        return "";
    }

    function setSendVersion(
        uint16 /*version*/
    ) external override {}

    function setReceiveVersion(
        uint16 /*version*/
    ) external override {}

    function getSendVersion(
        address /*_userApplication*/
    ) external pure override returns (uint16) {
        return 1;
    }

    function getReceiveVersion(
        address /*_userApplication*/
    ) external pure override returns (uint16) {
        return 1;
    }

    function getInboundNonce(uint16 _chainID, bytes calldata _srcAddress)
        external
        view
        override
        returns (uint64)
    {
        return inboundNonce[_chainID][_srcAddress];
    }

    function getOutboundNonce(uint16 _chainID, address _srcAddress)
        external
        view
        override
        returns (uint64)
    {
        return outboundNonce[_chainID][_srcAddress];
    }

    // simulates the relayer pushing through the rest of the msgs that got delayed due to the stored payload
    function _clearMsgQue(uint16 _srcChainId, bytes calldata _srcAddress)
        internal
    {
        QueuedPayload[] storage msgs = msgsToDeliver[_srcChainId][_srcAddress];

        // warning, might run into gas issues trying to forward through a bunch of queued msgs
        while (msgs.length > 0) {
            QueuedPayload memory payload = msgs[msgs.length - 1];
            ILayerZeroReceiver(payload.dstAddress).lzReceive(
                _srcChainId,
                _srcAddress,
                payload.nonce,
                payload.payload
            );
            msgs.pop();
        }
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        override
    {
        StoredPayload storage sp = storedPayload[_srcChainId][_srcAddress];
        // revert if no messages are cached. safeguard malicious UA behaviour
        require(sp.payloadHash != bytes32(0), "LayerZero: no stored payload");
        require(sp.dstAddress == msg.sender, "LayerZero: invalid caller");

        // empty the storedPayload
        sp.payloadLength = 0;
        sp.dstAddress = address(0);
        sp.payloadHash = bytes32(0);

        emit UaForceResumeReceive(_srcChainId, _srcAddress);

        // resume the receiving of msgs after we force clear the "stuck" msg
        _clearMsgQue(_srcChainId, _srcAddress);
    }

    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external override {
        StoredPayload storage sp = storedPayload[_srcChainId][_srcAddress];
        require(sp.payloadHash != bytes32(0), "LayerZero: no stored payload");
        require(
            _payload.length == sp.payloadLength &&
                keccak256(_payload) == sp.payloadHash,
            "LayerZero: invalid payload"
        );

        address dstAddress = sp.dstAddress;
        // empty the storedPayload
        sp.payloadLength = 0;
        sp.dstAddress = address(0);
        sp.payloadHash = bytes32(0);

        uint64 nonce = inboundNonce[_srcChainId][_srcAddress];

        ILayerZeroReceiver(dstAddress).lzReceive(
            _srcChainId,
            _srcAddress,
            nonce,
            _payload
        );
        emit PayloadCleared(_srcChainId, _srcAddress, nonce, dstAddress);
    }

    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        override
        returns (bool)
    {
        StoredPayload storage sp = storedPayload[_srcChainId][_srcAddress];
        return sp.payloadHash != bytes32(0);
    }

    function isSendingPayload() external view override returns (bool) {
        return !notEntered;
    }

    function isReceivingPayload() external view override returns (bool) {
        return !notEntered;
    }

    function getSendLibraryAddress(address)
        external
        view
        override
        returns (address)
    {
        return address(this);
    }

    function getReceiveLibraryAddress(address)
        external
        view
        override
        returns (address)
    {
        return address(this);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    /// @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    /// @param _dstChainId - the destination chain identifier
    /// @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    /// @param _payload - a custom bytes payload to send to the destination contract
    /// @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    /// @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    /// @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    /// @notice used by the messaging library to publish verified payload
    /// @param _srcChainId - the source chain identifier
    /// @param _srcAddress - the source contract (as bytes) at the source chain
    /// @param _dstAddress - the address on destination chain
    /// @param _nonce - the unbound message ordering nonce
    /// @param _gasLimit - the gas limit for external contract execution
    /// @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    ) external;

    /// @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    /// @param _srcChainId - the source chain identifier
    /// @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (uint64);

    /// @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    /// @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress)
        external
        view
        returns (uint64);

    /// @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    /// @param _dstChainId - the destination chain identifier
    /// @param _userApplication - the user app address on this EVM chain
    /// @param _payload - the custom message to send over LayerZero
    /// @param _payInZRO - if false, user app pays the protocol fee in native token
    /// @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    /// @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    /// @notice the interface to retry failed message on this Endpoint destination
    /// @param _srcChainId - the source chain identifier
    /// @param _srcAddress - the source chain contract address
    /// @param _payload - the payload to be retried
    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external;

    /// @notice query if any STORED payload (message blocking) at the endpoint.
    /// @param _srcChainId - the source chain identifier
    /// @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (bool);

    /// @notice query if the _libraryAddress is valid for sending msgs.
    /// @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication)
        external
        view
        returns (address);

    /// @notice query if the _libraryAddress is valid for receiving msgs.
    /// @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication)
        external
        view
        returns (address);

    /// @notice query if the non-reentrancy guard for send() is on
    /// @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    /// @notice query if the non-reentrancy guard for receive() is on
    /// @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    /// @notice get the configuration of the LayerZero messaging library of the specified version
    /// @param _version - messaging library version
    /// @param _chainId - the chainId for the pending config change
    /// @param _userApplication - the contract address of the user application
    /// @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint256 _configType
    ) external view returns (bytes memory);

    /// @notice get the send() LayerZero messaging library version
    /// @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication)
        external
        view
        returns (uint16);

    /// @notice get the lzReceive() LayerZero messaging library version
    /// @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication)
        external
        view
        returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface ILayerZeroReceiver {
    /// @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    /// @param _srcChainId - the source endpoint identifier
    /// @param _srcAddress - the source sending contract address from the source chain
    /// @param _nonce - the ordered message nonce
    /// @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface ILayerZeroUserApplicationConfig {
    /// @notice set the configuration of the LayerZero messaging library of the specified version
    /// @param _version - messaging library version
    /// @param _chainId - the chainId for the pending config change
    /// @param _configType - type of configuration. every messaging library has its own convention.
    /// @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external;

    /// @notice set the send() LayerZero messaging library version to _version
    /// @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    /// @notice set the lzReceive() LayerZero messaging library version to _version
    /// @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    /// @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    /// @param _srcChainId - the chainId of the source chain
    /// @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/ILayerZeroReceiver.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "../../interfaces/IMiddleLayer.sol";

abstract contract LayerZeroStorage {
    address internal owner;
    IMiddleLayer internal middleLayer;
    ILayerZeroEndpoint internal layerZeroEndpoint;

    // routers to call to on other chain ids
    mapping(uint256 => address) internal srcContracts;
    mapping(uint256 => uint16) internal cids;
    mapping(uint16 => uint256) internal chainIds;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../interfaces/IMiddleLayer.sol";
import "./interfaces/IAxelarGasService.sol";

abstract contract AxelarStorage {
    address internal owner;
    IMiddleLayer internal middleLayer;
    IAxelarGasService internal gasService;

    // routers to call to on other chain ids
    mapping(uint256 => address) internal srcContracts;
    mapping(uint256 => string) internal cids;
    mapping(string => uint256) internal chainIds;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// This should be owned by the microservice that is paying for gas.
interface IAxelarGasService {
    error NothingReceived();
    error TransferFailed();

    event GasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    function collectFees(address payable receiver, address[] calldata tokens) external;

    function refund(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AxelarStorage.sol";
import "./interfaces/IAxelarExecutable.sol";

abstract contract AxelarModifiers is AxelarStorage, IAxelarExecutable {
    modifier onlyAX() {
        require(msg.sender == address(gateway), "ONLY_AX");
        _;
    }

    // slither-disable-next-line assembly
    modifier onlySrc(uint256 srcChain, bytes memory _srcAddr) {
        address srcAddr;
        assembly {
            srcAddr := mload(add(20, _srcAddr))
        }
        require(
            srcContracts[srcChain] == address(srcAddr),
            "UNAUTHORIZED_CONTRACT"
        );
        _;
    }

    modifier onlyMid() {
        require(msg.sender == address(middleLayer), "ONLY_MID");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IAxelarGateway } from "./IAxelarGateway.sol";

abstract contract IAxelarExecutable {
    error NotApprovedByGateway();

    IAxelarGateway public gateway;

    constructor(address gateway_) {
        gateway = IAxelarGateway(gateway_);
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        // bytes32 payloadHash = keccak256(payload);
        // if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash))
        //     revert NotApprovedByGateway();
        _execute(sourceChain, sourceAddress, payload);
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external {
        bytes32 payloadHash = keccak256(payload);
        if (
            !gateway.validateContractCallAndMint(
                commandId,
                sourceChain,
                sourceAddress,
                payloadHash,
                tokenSymbol,
                amount
            )
        ) revert NotApprovedByGateway();

        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    function _execute(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload,
        string memory tokenSymbol,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IAxelarGateway {
    /**********\
    |* Events *|
    \**********/

    event TokenSent(
        address indexed sender,
        string destinationChain,
        string destinationAddress,
        string symbol,
        uint256 amount
    );

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenFrozen(string symbol);

    event TokenUnfrozen(string symbol);

    event AllTokensFrozen();

    event AllTokensUnfrozen();

    event AccountBlacklisted(address indexed account);

    event AccountWhitelisted(address indexed account);

    event Upgraded(address indexed implementation);

    /******************\
    |* Public Methods *|
    \******************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function freezeToken(string calldata symbol) external;

    function unfreezeToken(string calldata symbol) external;

    function freezeAllTokens() external;

    function unfreezeAllTokens() external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AxelarModifiers.sol";
import "./AxelarAdmin.sol";
import "./AxelarEvents.sol";
import "./interfaces/IAxelarExecutable.sol";
import "../interfaces/IRoute.sol";
import "./libraries/StringAddress.sol";

contract AxelarRoute is
    AxelarModifiers,
    AxelarAdmin,
    IRoute
{
    using StringToAddress for string;
    using AddressToString for address;

    constructor(
        IMiddleLayer newMiddleLayer,
        address _gateway,
        IAxelarGasService _gasService
    ) IAxelarExecutable(_gateway) {
        owner = msg.sender;
        middleLayer = newMiddleLayer;
        gasService = _gasService;
    }

    function _translate(
        uint256 chainId
    ) internal view returns (string memory cid) {
        return cids[chainId];
    }

    function _translate(
        string memory cid
    ) internal view returns (uint256 chainId) {
        return chainIds[cid];
    }

    function _execute(
        string memory cid,
        string memory sourceAddress,
        bytes calldata payload
    ) internal virtual override {

        emit Receive(
            "Axelar",
            cid,
            _translate(cid),
            sourceAddress,
            payload
        );

        middleLayer.mreceive(
            _translate(cid),
            payload
        );
    }

    function msend(
        uint256 chainId,
        bytes memory params,
        address payable refundAddress
    ) external override payable onlyMid() {

        emit Send(
            "Axelar",
            _translate(chainId),
            params,
            refundAddress
        );

        if (chainId == 1287 && msg.value > 0) { // sat fuji -> master moonbase
            gasService.payNativeGasForContractCall{value: msg.value}(
                address(this),
                _translate(chainId),
                srcContracts[chainId].toString(),
                params,
                refundAddress
            );

            gateway.callContract(
                _translate(chainId),
                srcContracts[chainId].toString(),
                params
            );
        } else {
            gateway.callContract(
                _translate(chainId),
                srcContracts[chainId].toString(),
                params
            );
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AxelarModifiers.sol";
import "./AxelarEvents.sol";

abstract contract AxelarAdmin is AxelarModifiers, AxelarEvents {
    function addSrc(uint256 srcChain, address newSrcAddress) external onlyOwner() {
        srcContracts[srcChain] = newSrcAddress;

        emit AddSrc(srcChain, newSrcAddress);
    }

    function addTranslation(
        string memory customId, uint256 standardId
    ) external {
        cids[standardId] = customId;
        chainIds[customId] = standardId;

        emit AddTranslation(customId, standardId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract AxelarEvents {

    event Send(
        string router,
        string chainId,
        bytes params,
        address _refundAddress
    );

    event Receive(
        string router,
        string cid,
        uint256 translatedChainId,
        string sourceAddress,
        bytes payload
    );

    event AddSrc(
        uint256 srcChain,
        address newSrcAddr
    );

    event AddTranslation(
        string customId,
        uint256 standardId
    );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRoute {
    function msend(
        uint256 _dstChainId,
        bytes memory params,
        address payable _refundAddress
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library StringToAddress {
    function toAddress(string memory a) internal pure returns (address) {
        bytes memory tmp = bytes(a);
        if (tmp.length != 42) return address(0);
        uint160 iaddr = 0;
        uint8 b;
        for (uint256 i = 2; i < 42; i++) {
            b = uint8(tmp[i]);
            if ((b >= 97) && (b <= 102)) b -= 87;
            else if ((b >= 65) && (b <= 70)) b -= 55;
            else if ((b >= 48) && (b <= 57)) b -= 48;
            else return address(0);
            iaddr |= uint160(uint256(b) << ((41 - i) << 2));
        }
        return address(iaddr);
    }
}

library AddressToString {
    function toString(address a) internal pure returns (string memory) {
        bytes memory data = abi.encodePacked(a);
        bytes memory characters = "0123456789abcdef";
        bytes memory byteString = new bytes(2 + data.length * 2);

        byteString[0] = "0";
        byteString[1] = "x";

        // slither-disable-next-line uninitialized-local
        for (uint256 i; i < data.length; ++i) {
            byteString[2 + i * 2] = characters[uint256(uint8(data[i] >> 4))];
            byteString[3 + i * 2] = characters[uint256(uint8(data[i] & 0x0f))];
        }
        return string(byteString);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./libraries/StringAddress.sol";
import "./interfaces/IAxelarExecutable.sol";
import "./interfaces/IAxelarGateway.sol";

// slither-disable-next-line locked-ether
contract AxelarGatewayMock {
    using StringToAddress for string;
    using AddressToString for address;

    string cid;
    mapping(string => address) mockStringAddresses;
    mapping(address => string) mockAddressStrings;

    constructor(string memory chain) {
        cid = chain;
    }

    function addMock(
        string memory chain, address addr
    ) external {
        mockStringAddresses[chain] = addr;
        mockAddressStrings[addr] = chain;
    }

    // slither-disable-next-line assembly
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function callContract(
        string calldata destinationChain,
        string calldata destinationContractAddress,
        bytes calldata payload
    ) external {
        if (keccak256(abi.encode(destinationChain)) == keccak256(abi.encode(cid))) {
            IAxelarExecutable(destinationContractAddress.toAddress()).execute(
                bytes32(0),
                mockAddressStrings[msg.sender],
                msg.sender.toString(),
                payload
            );
            return;
        }
        IAxelarGateway(mockStringAddresses[destinationChain]).callContract(
            destinationChain,
            destinationContractAddress,
            payload
        );
    }

    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable {
        // require(msg.value > 0, "NO_VALUE");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LayerZeroModifiers.sol";
import "./LayerZeroAdmin.sol";
import "./LayerZeroEvents.sol";
import "../interfaces/IRoute.sol";

contract LayerZeroRoute is
    LayerZeroModifiers,
    LayerZeroAdmin,
    IRoute
{
    constructor(
        IMiddleLayer newMiddleLayer,
        ILayerZeroEndpoint _layerZeroEndpoint
    ) {
        owner = msg.sender;
        middleLayer = newMiddleLayer;
        layerZeroEndpoint = _layerZeroEndpoint;
    }

    function translateToCustom(
        uint256 chainId
    ) internal view returns (uint16 cid) {
        return cids[chainId];
    }

    function translateToStandard(
        uint16 cid
    ) internal view returns (uint256 chainId) {
        return chainIds[cid];
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _fromAddress,
        uint64, /* _nonce */
        bytes memory _payload
    ) external onlyLZ() onlySrc(translateToStandard(_srcChainId), _fromAddress) {

        emit Receive(
            "LayerZero",
            _srcChainId,
            translateToStandard(_srcChainId),
            _fromAddress,
            _payload
        );

        middleLayer.mreceive(
            translateToStandard(_srcChainId),
            _payload
        );
    }

    function msend(
        uint256 _dstChainId,
        bytes memory params,
        address payable _refundAddress
    ) external override payable onlyMid() {

        emit Send(
            "LayerZero",
            translateToCustom(_dstChainId),
            abi.encodePacked(srcContracts[_dstChainId]), // send to this address on the destination
            params, // bytes payload
            _refundAddress, // refund address
            address(0), // future parameter
            new bytes(0)
        );

        layerZeroEndpoint.send{value: msg.value}(
            translateToCustom(_dstChainId),
            abi.encodePacked(srcContracts[_dstChainId]), // send to this address on the destination
            params, // bytes payload
            _refundAddress, // refund address
            address(0), // future parameter
            new bytes(0)
        );
    }

    fallback() external payable {}
    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LayerZeroStorage.sol";

abstract contract LayerZeroModifiers is LayerZeroStorage {
    modifier onlyLZ() {
        require(msg.sender == address(layerZeroEndpoint), "ONLY_LZ");
        _;
    }

    // slither-disable-next-line assembly
    modifier onlySrc(uint256 srcChain, bytes memory _srcAddr) {
        address srcAddr;
        assembly {
            srcAddr := mload(add(20, _srcAddr))
        }
        require(
            srcContracts[srcChain] == address(srcAddr),
            "UNAUTHORIZED_CONTRACT"
        );
        _;
    }

    modifier onlyMid() {
        require(msg.sender == address(middleLayer), "ONLY_MID");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LayerZeroModifiers.sol";
import "./LayerZeroEvents.sol";


abstract contract LayerZeroAdmin is LayerZeroModifiers, LayerZeroEvents {
    function addSrc(uint256 srcChain, address newSrcAddr) external onlyOwner() {
        srcContracts[srcChain] = newSrcAddr;

        emit AddSrc(srcChain, newSrcAddr);
    }

    function addTranslation(
        uint16 customId, uint256 standardId
    ) external onlyOwner() {
        cids[standardId] = customId;
        chainIds[customId] = standardId;

        emit AddTranslation(customId, standardId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract LayerZeroEvents {

    event Receive(
        string router,
        uint16 srcChainId,
        uint256 translatedChainId,
        bytes fromAddress,
        bytes payload
    );

    event Send(
        string router,
        uint16 chainId,
        bytes destination,
        bytes payload,
        address refundAddress,
        address zroPaymentAddress,
        bytes adapterParams
    );

    event AddSrc(
        uint256 srcChain,
        address newSrcAddr
    );

    event AddTranslation(
         uint16 customId,
         uint256 standardId
    );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../master/MasterMessageHandler.sol";
import "../satellite/loanAgent/interfaces/ILoanAgent.sol";
import "../satellite/pusd/PUSDMessageHandler.sol";
import "./routes/interfaces/IRoute.sol";

abstract contract MiddleLayerStorage {
    MasterMessageHandler internal masterState;
    ILoanAgent internal loanAgent;
    PUSDMessageHandler internal pusd;

    uint256 internal cid;

    address internal owner;

    IRoute[] internal routes;

    // addresses allowed to send messages to other chains
    mapping(address => bool) internal authContracts;

    // routes allowed to receive messages
    mapping(address => bool) authRoutes;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IHelper.sol";

import "./interfaces/IMaster.sol";
import "./MasterModifiers.sol";
import "./MasterEvents.sol";

abstract contract MasterMessageHandler is IMaster, MasterModifiers, MasterEvents {
    // slither-disable-next-line assembly
    function satelliteLiquidateBorrow(
        uint256 chainId,
        address borrower,
        address liquidator,
        uint256 seizeTokens,
        address pTokenCollateral
    ) internal virtual override {
        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.SLiquidateBorrow(
                IHelper.Selector.SATELLITE_LIQUIDATE_BORROW,
                borrower,
                liquidator,
                seizeTokens,
                pTokenCollateral
            )
        );

        bytes32 metadata = ecc.preRegMsg(payload, msg.sender);
        assembly {
            mstore(add(payload, 0x20), metadata)
        }

        middleLayer.msend{value: msg.value}(
            chainId,
            payload, // bytes payload
            payable(msg.sender), // refund address
            address(0)
        );
    }

    // pass in the erc20 prevBalance, newBalance
    /// @dev Update the collateral balance for the given arguments
    /// @notice This will come from the satellite chain- the approve models
    function masterDeposit(
        IHelper.MDeposit memory params,
        bytes32 metadata,
        uint256 chainId
    ) external payable onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) {
            emit MessageFailed(abi.encode(0x0000, params, metadata, chainId));
            return;
        }

        if (!_addToMarket(params.pToken, chainId, params.user)) {
            // error
        }

        if (!ecc.flagMsgValidated(abi.encode(params), metadata)) {
            emit MessageFailed(abi.encode(0x0001, params, metadata, chainId));
            return;
        }
        
        // do not accept new deposits on a paused market
        if (markets[chainId][params.pToken].isPaused) {
            emit MessageFailed(abi.encode(0x0002, params, metadata, chainId));
            return;
        }

        if (collateralBalances[chainId][params.user][params.pToken] == 0) {
            _addToMarket(params.pToken, chainId, params.user);

            emit NewCollateralBalance(params.user, chainId, params.pToken);
        }

        collateralBalances[chainId][params.user][params.pToken] += params.amountIncreased;
        markets[chainId][params.pToken].totalSupply += params.amountIncreased;

        emit CollateralDeposited(
            params.user,
            chainId,
            params.pToken,
            collateralBalances[chainId][params.user][params.pToken],
            params.amountIncreased,
            markets[chainId][params.pToken].totalSupply
        );

        // fallback to satellite to report receipt
    }

    // slither-disable-next-line assembly
    function borrowAllowed(
        IHelper.MBorrowAllowed memory params,
        bytes32 metadata,
        uint256 chainId,
        address fallbackAddress
    ) external payable onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) {
            emit MessageFailed(abi.encode(0x0400, params, metadata, chainId, fallbackAddress));
            return;
        }

        // TODO: liquidity calculation
        _accrueInterest();

        (, uint256 shortfall) = _getHypotheticalAccountLiquidity(
            params.user,
            address(0),
            0,
            params.borrowAmount
        );

        //if approved, update the balance and fire off a return message
        // slither-disable-next-line incorrect-equality
        if (shortfall == 0) {
            if (!ecc.flagMsgValidated(abi.encode(params), metadata)) {
                emit MessageFailed(abi.encode(0x0401, params, metadata, chainId, fallbackAddress));
                return;
            }

            (uint256 _accountBorrows, ) = _borrowBalanceStored(params.user);

            /////////////////////////
            // EFFECTS & INTERACTIONS
            // (No safe failures beyond this point)

            accountBorrows[params.user].principal = _accountBorrows + params.borrowAmount;
            accountBorrows[params.user].interestIndex = borrowIndex;

            loansOutstanding[params.user][chainId] += params.borrowAmount;
            totalBorrows += params.borrowAmount;

            bytes memory payload = abi.encode(
                uint256(0),
                IHelper.FBBorrow(
                    IHelper.Selector.FB_BORROW,
                    params.user,
                    params.borrowAmount
                )
            );

            bytes32 _metadata = ecc.preRegMsg(payload, params.user);
            assembly {
                mstore(add(payload, 0x20), _metadata)
            }

            middleLayer.msend{ value: msg.value }(
                chainId,
                payload, // bytes payload
                payable(params.user), // refund address
                fallbackAddress
            );

            emit LoanApproved(
                params.user,
                accountBorrows[params.user].principal,
                params.borrowAmount,
                totalBorrows
            );
        } else {
            emit LoanRejected(
                params.user,
                accountBorrows[params.user].principal,
                params.borrowAmount,
                shortfall
            );
        }
    }

    function masterRepay(
        IHelper.MRepay memory params,
        bytes32 metadata,
        uint256 chainId
    ) external payable onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) {
            emit MessageFailed(abi.encode(0x0300, params, metadata, chainId));
            return;
        }

        if (!ecc.flagMsgValidated(abi.encode(params), metadata)) {
            emit MessageFailed(abi.encode(0x0302, params, metadata, chainId));
            return;
        }

        _accrueInterest();

        if (loansOutstanding[params.borrower][chainId] < params.amountRepaid
        ) {
            emit MessageFailed(abi.encode(0x0301, params, metadata, chainId));
            return;
        }
        (uint256 _accountBorrows,) = _borrowBalanceStored(params.borrower);

        loansOutstanding[params.borrower][chainId] -= params.amountRepaid;
        totalBorrows -= params.amountRepaid;
        accountBorrows[params.borrower].principal = _accountBorrows - params.amountRepaid;

        emit LoanRepaid(
            params.borrower,
            accountBorrows[params.borrower].principal,
            params.amountRepaid,
            totalBorrows
        );

        // TODO: fallback to satellite to report receipt
    }

    // slither-disable-next-line assembly
    function redeemAllowed(
        IHelper.MRedeemAllowed memory params,
        bytes32 metadata,
        uint256 chainId,
        address fallbackAddress
    ) external payable onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) {
            emit MessageFailed(abi.encode(0x0100, params, metadata, chainId, fallbackAddress));
            return;
        }
        _accrueInterest();

        //calculate hypothetical liquidity for the user
        //make sure we also check that the redeem isn't more than what's deposited
        // bool approved = true;

        (, uint256 shortfall) = _getHypotheticalAccountLiquidity(
            params.user,
            params.pToken,
            params.amount,
            0
        );
        //if approved, update the balance and fire off a return message
        // slither-disable-next-line incorrect-equality
        if (shortfall == 0) {
            if (!ecc.flagMsgValidated(abi.encode(params), metadata)) {
                emit MessageFailed(abi.encode(0x0101, params, metadata, chainId, fallbackAddress));
                return;
            }
            if (collateralBalances[chainId][params.user][params.pToken] == params.amount) {
                _exitMarket(chainId, params.pToken, params.user);
            }

            collateralBalances[chainId][params.user][params.pToken] -= params.amount;
            markets[chainId][params.pToken].totalSupply -= params.amount;

            bytes memory payload = abi.encode(
                uint256(0),
                IHelper.FBRedeem(
                    IHelper.Selector.FB_REDEEM,
                    params.pToken,
                    params.user,
                    params.amount
                )
            );

            bytes32 _metadata = ecc.preRegMsg(payload, params.user);
            assembly {
                mstore(add(payload, 0x20), _metadata)
            }

            middleLayer.msend{value: msg.value}(
                chainId,
                payload, // bytes payload
                payable(params.user), // refund address
                fallbackAddress
            );

            emit CollateralWithdrawn(
                params.user,
                chainId,
                params.pToken,
                collateralBalances[chainId][params.user][params.pToken],
                params.amount,
                markets[chainId][params.pToken].totalSupply
            );
        } else {
            emit CollateralWithdrawalRejection(
                params.user,
                chainId,
                params.pToken,
                collateralBalances[chainId][params.user][params.pToken],
                params.amount,
                shortfall
            );

        }
    }

    // slither-disable-next-line assembly
    function transferAllowed(
        IHelper.MTransferAllowed memory params,
        bytes32 metadata,
        uint256 chainId,
        address fallbackAddress
    ) public payable onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) {
            emit MessageFailed(abi.encode(0x0700, params, metadata, chainId, fallbackAddress));
            return;
        }

        _accrueInterest();

        (, uint256 shortfall) = _getHypotheticalAccountLiquidity(
            params.user,
            params.pToken,
            0,
            0
        );

        // slither-disable-next-line incorrect-equality
        if (shortfall == 0) {
            if (!_addToMarket(params.pToken, chainId, params.dst)) {
                // error out
            }
            if (!ecc.flagMsgValidated(abi.encode(params), metadata)) {
                emit MessageFailed(abi.encode(0x0701, params, metadata, chainId, fallbackAddress));
                return;
            }

            collateralBalances[chainId][params.user][params.pToken] -= params.amount;
            collateralBalances[chainId][params.dst][params.pToken] += params.amount;

            bytes memory payload = abi.encode(
                uint256(0),
                IHelper.FBCompleteTransfer(
                    uint8(IHelper.Selector.FB_COMPLETE_TRANSFER),
                    params.pToken,
                    params.spender,
                    params.user, // src
                    params.dst,
                    params.amount // tokens
                )
            );

            bytes32 _metadata = ecc.preRegMsg(payload, params.user);
            assembly {
                mstore(add(payload, 0x20), _metadata)
            }

            middleLayer.msend{value: msg.value}(
                chainId,
                payload, // bytes payload
                payable(params.user), // refund address
                fallbackAddress
            );
        } else {
            // TODO: shortfall > 0
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../LoanAgentStorage.sol";
import "../../../interfaces/IHelper.sol";

abstract contract ILoanAgent is LoanAgentStorage {
    function initialize(address eccAddress) external virtual;

    function borrow(uint256 borrowAmount) external payable virtual;

    // function completeBorrow(
    //     address borrower,
    //     uint borrowAmount
    // ) external virtual;

    function repayBorrow(uint256 repayAmount) external payable virtual returns (bool);

    function repayBorrowBehalf(
        address borrower,
        uint256 repayAmount
    ) external payable virtual returns (bool);

    function borrowApproved(
        IHelper.FBBorrow memory params,
        bytes32 metadata
    ) external payable virtual;

    function setPUSD(address newPUSD) external virtual;

    function setMidLayer(address newMiddleLayer) external virtual;

    function setMasterCID(uint256 newChainId) external virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../MasterStorage.sol";

abstract contract IMaster is MasterStorage {
    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return (error code, the calculated balance or 0 if error code is non-zero)
     */
    function _borrowBalanceStored(address account)
        internal
        view
        virtual
        returns (uint256, uint256);

    function _accrueInterest() internal virtual;

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param token The market to enter
     * @param chainId The chainId
     * @param borrower The address of the account to modify
     */
    function _addToMarket(
        address token,
        uint256 chainId,
        address borrower
    ) internal virtual returns (bool);

    function _exitMarket(
        uint256 chainId, 
        address token, 
        address user
    ) internal virtual returns (bool);

    /**
     * @notice Get a snapshot of the account's balance, and the cached exchange rate
     * @dev This is used by risk engine to more efficiently perform liquidity checks.
     * @param user Address of the account to snapshot
     * @param chainId metadata of the ptoken
     * @param token metadata of the ptoken
     * @return (possible error, token balance, exchange rate)
     */
    function _getAccountSnapshot(
        address user,
        uint256 chainId,
        address token
    ) internal view virtual returns (uint256, uint256);

    function _getHypotheticalAccountLiquidity(
        address account,
        address pTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) internal virtual returns (uint256, uint256);

    /**
     * @notice The liquidator liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this pToken to be liquidated
     * @param pTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function _liquidateBorrow(
        address pTokenCollateral,
        address borrower,
        uint256 chainId,
        uint256 repayAmount
    ) internal virtual returns (bool);

    function _liquidateCalculateSeizeTokens(
        address pTokenCollateral,
        uint256 chainId,
        uint256 actualRepayAmount
    ) internal view virtual returns (uint256);

    function _liquidateBorrowAllowed(
        address pTokenCollateral,
        address borrower,
        uint256 chainId,
        uint256 repayAmount
    ) internal virtual returns (bool);

    function satelliteLiquidateBorrow(
        uint256 chainId,
        address borrower,
        address liquidator,
        uint256 seizeTokens,
        address pTokenCollateral
    ) internal virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MasterStorage.sol";

abstract contract MasterModifiers is MasterStorage {
    modifier onlyOwner() {
        require(msg.sender == admin, "ONLY_OWNER");
        _;
    }

    modifier onlyMid() {
        require(
            IMiddleLayer(msg.sender) == middleLayer,
            "ONLY_MIDDLE_LAYER"
        );
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract MasterEvents {
    event NewCollateralBalance(
        address indexed user,
        uint256 indexed chainId,
        address indexed collateral
    );

    event CollateralDeposited(
        address indexed user,
        uint256 indexed chainId,
        address indexed collateral,
        uint256 balance,
        uint256 amountDeposited,
        uint256 totalSupply
    );

    event CollateralWithdrawn(
        address indexed user,
        uint256 indexed chainId,
        address indexed collateral,
        uint256 balance,
        uint256 amountWithdrawn,
        uint256 totalSupply
    );

    event CollateralWithdrawalRejection(
        address indexed user,
        uint256 indexed chainId,
        address indexed collateral,
        uint256 balance,
        uint256 amount,
        uint256 shortfall
    );

    event LoanApproved(
        address indexed user,
        uint256 balance, 
        uint256 amount,
        uint256 totalBorrows
    );

    event LoanRejected(
        address indexed user,
        uint256 balance,
        uint256 amount,
        uint256 shortfall
    );

    event LoanRepaid(
        address indexed user,
        uint256 balance, 
        uint256 amountRepaid,
        uint256 totalBorrows
    );

    /// @notice Emitted when an account enters a deposit market
    event MarketEntered(uint256 chainId, address token, address borrower);

    event MarketExited(uint256 chainId, address token, address user);

    event ReceiveFromChain(uint256 _srcChainId, address _fromAddress);

    /// @notice Event emitted when a borrow is liquidated
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral,
        uint256 seizeTokens
    );

    // Master Admin Events

    event MarketPaused(uint256 chainId, address token, bool isPaused);

    event AddChain(uint256 chainId);

    event ChangeOwner(address newOwner);

    event ChangeMiddleLayer(address oldMid, address newMid);

    event MarketListed(address token);

    event ChangeLiqIncentive(uint256 newLiqIncentive);

    event ChangeCloseFactor(uint256 newCloseFactor);
    
    event ChangeFactorDecimals(uint8 newFactorDecimals);

    event ChangeCollateralFactor(uint256 newCollateralFactor);

    event ChangeProtocolSeizeShare(uint256 newProtocolSeizeShare);

    event SetPUSD(address newPUSD);

    event AccountLiquidity(uint256 collateral, uint256 borrowPlusEffects);

    event MessageFailed(bytes data);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// TODO: Change this import to somewhere else probably
import "../master/oracle/interfaces/IPrimeOracle.sol";
import "../middleLayer/interfaces/IMiddleLayer.sol";
import "../ecc/interfaces/IECC.sol";
import "../master/irm/interfaces/IIRM.sol";
import "../master/crm/interfaces/ICRM.sol";

abstract contract MasterStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    // slither-disable-next-line unused-state
    IMiddleLayer internal middleLayer;

    // slither-disable-next-line unused-state
    IECC internal ecc;

    // slither-disable-next-line unused-state
    address internal pusd;

    IPrimeOracle oracle;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint256 public accrualBlockNumber;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint256 public totalBorrows;

    /**
    * @notice Total amount of reserves of the underlying held in this market
    */
    uint256 public totalReserves;

    ICRM collateralRatioModel;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    
    uint256 public borrowIndex; // TODO - needs initialized
    IIRM public interestRateModel;
    uint8 public factorDecimals = 8;
    uint256 public liquidityIncentive = 5e6; // 5%
    uint256 public closeFactor = 50e6; // 50%
    uint256 public protocolSeizeShare = 5e6; // 5%
    uint256 public reserveFactor = 80e6; // 80%

    /**
     * @notice Maximum borrow rate that can ever be applied (.0005% / block)
     */
    // slither-disable-next-line unused-state
    uint256 internal constant BORROW_RATE_MAX = 0.0005e16;

    // chainid => user => token => token balance
    mapping(uint256 => mapping(address => mapping(address => uint256)))
        public collateralBalances;

    // user => chainId => token balance
    mapping(address => mapping(uint256 => uint256)) public loansOutstanding;

    struct Market {
        uint256 initialExchangeRate;
        uint256 totalSupply;
        string name; // 256
        string symbol; // 256
        address underlying; // 20
        bool isListed; // 8
        bool isPaused;
        uint8 decimals;
        mapping(address => bool) accountMembership;
    }

    /**
     * @notice Official mapping of pTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    // chain => ptoken address => market
    mapping(uint256 => mapping(address => Market)) public markets;

    struct InterestSnapshot {
        uint256 interestAccrued;
        uint256 interestIndex;
    }

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) public accountBorrows;

    struct CollateralMarket {
        address token;
        uint256 chainId;
        uint8 decimals;
    }

    /// @notice A list of all deposit markets
    CollateralMarket[] public allMarkets;

    // user => interest index
    mapping(address => CollateralMarket[]) public accountAssets;

    uint256[] public chains;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IPrimeOracleGetter.sol";

/**
 * @title IPrimeOracle
 * @author Prime
 * @notice The core interface for the Prime Oracle
 */
interface IPrimeOracle {

    /**
     * @dev Emitted after the price data feed of an asset is updated
     * @param asset The address of the asset
     * @param chainId The chainId of the asset
     * @param feed The price feed of the asset
     */
    event PrimaryFeedUpdated(uint256 chainId, address indexed asset, address indexed feed);

    /**
     * @dev Emitted after the price data feed of an asset is updated
     * @param asset The address of the asset
     * @param feed The price feed of the asset
     */
    event SecondaryFeedUpdated(uint256 chainId, address indexed asset, address indexed feed);

    /**
     * @notice Sets or replaces price feeds of assets
     * @param assets The addresses of the assets
     * @param feeds The addresses of the price feeds
     */
    function setPrimaryFeeds(uint256[] calldata chainIds, address[] calldata assets, IPrimeOracleGetter[] calldata feeds) external;

    /**
     * @notice Sets or replaces price feeds of assets
     * @param assets The addresses of the assets
     * @param feeds The addresses of the price feeds
     */
    function setSecondaryFeeds(uint256[] calldata chainIds, address[] calldata assets, IPrimeOracleGetter[] calldata feeds) external;

    /**
     * @notice Returns a list of prices from a list of assets addresses
     * @param assets The list of assets addresses
     * @return The prices of the given assets
     */
    function getAssetPrices(uint256[] calldata chainIds, address[] calldata assets) external view returns (uint256[] memory, uint256[] memory);

    /**
     * @notice Returns the address of the primary price feed for an asset address
     * @param asset The address of the asset
     * @return The address of the price feed
     */
    function getPrimaryFeedOfAsset(uint256 chainId, address asset) external view returns (address);

    /**
     * @notice Returns the address of the secondary price feed for an asset address
     * @param asset The address of the asset
     * @return The address of the price feed
     */
    function getSecondaryFeedOfAsset(uint256 chainId, address asset) external view returns (address);

    /**
     * @return Returns the price of PUSD
     **/
    function getPusdPrice() external view returns (uint256, uint256);

    /**
     * @return Returns the address of PUSD
     **/
    function getPusdAddress() external view returns (address);

    /**
     * @notice Get the underlying price of a cToken asset
     * @param asset The PToken collateral to get the sasset price of
     * @param chainId the chainId to get an asset price for
     * @return The underlying asset price.
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(uint256 chainId, address asset) external view returns (uint256, uint256);

    /**
     * @notice Get the underlying borrow price of PUSD
     * @return The underlying borrow price
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPriceBorrow() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/**
 * @title IPrimeOracleGetter
 * @author Prime
 * @notice Interface for the Prime price oracle.
 **/
interface IPrimeOracleGetter {

  /**
    * @dev Emitted after the price data feed of an asset is updated
    * @param asset The address of the asset
    * @param feed The price feed of the asset
  */
  event AssetFeedUpdated(uint256 chainId, address indexed asset, address indexed feed);

  /**
   * @notice Gets the price feed of an asset
   * @param asset The addresses of the asset
   * @return address of asset feed
  */
  function getAssetFeed(uint256 chainId, address asset) external view returns (address);

    /**
   * @notice Sets or replaces price feeds of assets
   * @param assets The addresses of the assets
   * @param feeds The addresses of the price feeds
   */
  function setAssetFeeds(uint256[] calldata chainIds, address[] calldata assets, address[] calldata feeds) external;

  /**
   * @notice Returns the price data in the denom currency
   * @param quoteToken A token to return price data for
   * @param denomToken A token to price quoteToken against
   * @return return price of the asset from the oracle
   **/
  function getAssetPrice(uint256 chainId, address quoteToken, address denomToken) external view returns (uint256);

  /**
   * @notice Returns the price data in the denom currency
   * @param quoteToken A token to return price data for
   * @param denomToken A token to price quoteToken against
   * @return return price of the asset from the oracle
   **/
  function getPriceDecimals(uint256 chainId, address quoteToken, address denomToken) external view returns (uint256);

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../middleLayer/interfaces/IMiddleLayer.sol";
import "../../ecc/interfaces/IECC.sol";

abstract contract LoanAgentStorage {
    /**
    * @notice Administrator for this contract
    */
    address payable public admin;

    // slither-disable-next-line unused-state
    address internal PUSD;

    // slither-disable-next-line unused-state
    IMiddleLayer internal middleLayer;

    // slither-disable-next-line unused-state
    IECC internal ecc;

    // slither-disable-next-line unused-state
    uint256 internal masterCID;

    uint256 public borrowIndex;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
                 _   _         _____      _ _ _     _               ______ _____ _____
     /\         | | (_)       / ____|    | | (_)   (_)             |  ____/ ____/ ____|
    /  \   _ __ | |_ _ ______| |     ___ | | |_ ___ _  ___  _ __   | |__ | |   | |
   / /\ \ | '_ \| __| |______| |    / _ \| | | / __| |/ _ \| '_ \  |  __|| |   | |
  / ____ \| | | | |_| |      | |___| (_) | | | \__ \ | (_) | | | | | |___| |___| |____
 /_/    \_\_| |_|\__|_|       \_____\___/|_|_|_|___/_|\___/|_| |_| |______\_____\_____|

         n                                                                 :.
         E%                                                                :"5
        z  %                                                              :" `
        K   ":                                                           z   R
        ?     %.                                                       :^    J
         ".    ^s                                                     f     :~
          '+.    #L                                                 z"    .*
            '+     %L                                             z"    .~
              ":    '%.                                         .#     +
                ":    ^%.                                     .#`    +"
                  #:    "n                                  .+`   .z"
                    #:    ":                               z`    +"
                      %:   `*L                           z"    z"
                        *:   ^*L                       z*   .+"
                          "s   ^*L                   z#   .*"
                            #s   ^%L               z#   .*"
                              #s   ^%L           z#   .r"
                                #s   ^%.       u#   .r"
                                  #i   '%.   u#   [email protected]"
                                    #s   ^%u#   [email protected]"
                                      #s x#   .*"
                                       x#`  [email protected]%.
                                     x#`  .d"  "%.
                                   xf~  .r" #s   "%.
                             u   x*`  .r"     #s   "%.  x.
                             %Mu*`  x*"         #m.  "%zX"
                             :R(h x*              "h..*dN.
                           [email protected]#>                 7?dMRMh.
                         [email protected]@$#"#"                 *""*@MM$hL
                       [email protected]@MM8*                          "*[email protected]
                     z$RRM8F"                             "[email protected]$bL
                    5`RM$#                                  'R88f)R
                    'h.$"                                     #$x*

This contract is made to allow for the resending of cross chain messages
I.E. Layer Zero/Axelar as a protection measure on the off chance that a message gets
lost in transit by a protocol. As a further protection measure it implements security
features such as anti-collision and message expiriy. This is to ensure that it should
be impossible to have a message failure so bad that it cannot be recovered from,
while ensuring that an intentional collision to corrupt data cannot cause unexpected
behaviour other than that of what the original message would have created.

The implementation of this contract can cause vulnurablities, any development with or
around this should follow suite with a guideline paper published here: [], along with
general security audits and proper implementation on all fronts.
*/

import "../interfaces/IHelper.sol";
import "./interfaces/IECC.sol";

// slither-disable-next-line unimplemented-functions
contract ECC is IECC {
    // ? These vars are not marked as constant because inline yul does not support loading
    // ? constant vars from state...
    // max 16 slots
    // constable-states,unused-state
    // slither-disable-next-line all
    uint256 internal mSize = 16;
    // Must account for metadata
    // constable-states,unused-state
    // slither-disable-next-line all
    uint256 internal metadataSize = 1;
    // constable-states,unused-state
    // slither-disable-next-line all
    uint256 internal usableSize = 15;

    // pre register message
    // used when sending a message i.e. lzSend
    // slither-disable-next-line assembly
    function preRegMsg(
        bytes memory payload,
        address instigator
    ) external override returns (bytes32 metadata) {
        require(payload.length / 32 <= usableSize, "PAYLOAD_TOO_BIG");
        require(payload.length % 32 == 0, "PAYLOAD_NONDIVISABLE_BY_32");

        bytes32 payloadHash = keccak256(payload);

        bytes32 ptr = keccak256(abi.encode(
            instigator,
            block.timestamp,
            payloadHash
        ));

        assembly {
            let nonce
            { // modify ptr to have an consistent starting point
                let msze := sload(mSize.slot)
                let delta := mod(ptr, msze)
                let halfmsze := div(msze, 2)
                // round down at half
                if iszero(gt(delta, halfmsze)) { ptr := sub(ptr, delta) }
                if gt(delta, halfmsze) { ptr := add(ptr, delta) }

                // anti-collision logic
                for {} gt(sload(ptr), 0) {
                    ptr := add(ptr, msze)
                    nonce := add(nonce, 1)
                } {
                    // empty block to optimize away 2 jump opcodes every iteration
                }
            }

            { // write metadata
                // packing the struct tightly instead of loose packing
                metadata := or(shl(160, or(shl(16, or(shl(40, shr(216, payloadHash)), timestamp())), nonce)), instigator)
                sstore(ptr, metadata)
            }

            for { // write payload directly after metadata
                let l := div(mload(payload), 0x20)
                let i := sload(metadataSize.slot)
            } gt(l, 0) {
                sstore(add(ptr, i), mload(add(1, add(payload, i))))

                i := add(i, 1)
                l := sub(l, 1)
            } {
                // empty block to optimize away 2 jump opcodes every iteration
            }
        }

        // emit ptr
    }

    // pre processing validation
    // used prior to processing a message
    // checks if message has already been processed or is allowed to be processed
    function preProcessingValidation(bytes memory payload, bytes32 metadata) external override view returns (bool allowed) {
        return _preProcessingValidation(payload, metadata);
    }

    // slither-disable-next-line assembly
    function _preProcessingValidation(bytes memory payload, bytes32 metadata) internal view returns (bool) {
        bytes32 ptr = metadata;

        bytes32 payloadHash = keccak256(payload);

        assembly {
            // modify ptr to have an consistent starting point
            let msze := sload(mSize.slot)
            let delta := mod(ptr, msze)
            let halfmsze := div(msze, 2)
            // round down at half
            if iszero(gt(delta, halfmsze)) { ptr := sub(ptr, delta) }
            if gt(delta, halfmsze) { ptr := add(ptr, delta) }

            // anti-collision logic
            for {} gt(sload(ptr), 0) {
                if eq(sload(ptr), payloadHash) {
                    if eq(sload(add(ptr, 1)), metadata) {
                        mstore(0, 0)
                        return(0, 32)
                    }
                }
                ptr := add(ptr, msze)
            } {
                // empty block to optimize away 2 jump opcodes every iteration
            }

            mstore(0, 1)
            return(0, 32)
        }
    }

    // flag message as validate
    // slither-disable-next-line assembly
    function flagMsgValidated(bytes memory payload, bytes32 metadata) external override returns (bool) {
        // if (!_preProcessingValidation(payload, metadata)) return false;

        bytes32 ptr = metadata;

        bytes32 payloadHash = keccak256(payload);

        assembly {
            // modify ptr to have an consistent starting point
            let msze := sload(mSize.slot)
            let delta := mod(ptr, msze)
            let halfmsze := div(msze, 2)
            // round down at half
            if iszero(gt(delta, halfmsze)) { ptr := sub(ptr, delta) }
            if gt(delta, halfmsze) { ptr := add(ptr, delta) }

            { // anti-collision logic
                // we first check if ptr is empty
                if iszero(sload(ptr)) {
                    sstore(ptr, payloadHash)
                    sstore(add(ptr, 1), metadata)
                    mstore(0, 1)
                    return(0, 32)
                }
                // otherwise find non-collision slot
                for {} gt(sload(ptr), 0) {
                    if eq(sload(ptr), payloadHash) {
                        if eq(sload(add(ptr, 1)), metadata) {
                            mstore(0, 0)
                            return (0, 32)
                        }
                    }
                    ptr := add(ptr, msze)
                } {
                    // empty block to optimize away 2 jump opcodes every iteration
                }

                if iszero(sload(ptr)) {
                    sstore(ptr, payloadHash)
                    sstore(add(ptr, 1), metadata)
                    mstore(0, 1)
                    return(0, 32)
                }
            }
        }

        return false;
    }

    // resend message
    // checks expiry, allows to resend the data given nothing is corrupted
    // function rsm(uint256 messagePtr) external returns (bool) {
        // TODO: Is this needed?
    // }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../LoanAgentStorage.sol";

abstract contract ILoanAgentInternals is LoanAgentStorage {

    function _repayBorrowFresh(
        address payer,
        address borrower,
        uint256 repayAmount
    ) internal virtual returns (uint256);

    function _sendBorrow(address user, uint256 amount) internal virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/ILoanAgentInternals.sol";
import "../../interfaces/IHelper.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

abstract contract LoanAgentInternals is ILoanAgentInternals {

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, ERC20Burnable, Ownable {

    uint8 _decimals;
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 decimals_
    ) ERC20(tokenName, tokenSymbol) {
        _decimals = decimals_;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UniswapV2PairMock is IUniswapV2Pair {

    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    constructor(
        address _token0,
        address _token1,
        uint112 _reserve0,
        uint112 _reserve1,
        uint8 token0Decimals,
        uint8 token1Decimals
    ) {
        token0 = _token0;
        token1 = _token1;
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        price0CumulativeLast = reserve1 * 10 ** token0Decimals / reserve0;
        price1CumulativeLast = reserve0 * 10 ** token1Decimals / reserve1;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Oracle.sol";

/**
 * @title UniswapTwapPriceOracleV2Root
 * @notice Stores cumulative prices and returns TWAPs for assets on Uniswap V2 pairs.
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 */
contract MasterUniswapV2Oracle is IUniswapV2Oracle {
    //TODO: should this be updated to the token on the master chain?
    // should each chain have its own preferred denomination?
    /**
     * @dev Wrapped network token contract address.
     */
    address public immutable wrappedNetworkToken;

    constructor(address wrappedNetworkTokenParam) {
        require(wrappedNetworkTokenParam != address(0), "NON_ZEROADDRESS");
        wrappedNetworkToken = wrappedNetworkTokenParam;
    }

    /**
     * @dev Minimum TWAP interval.
     */
    uint256 public constant MIN_TWAP_TIME = 15 minutes;

    /**
     * @dev Return the TWAP value price0. Revert if TWAP time range is not within the threshold.
     * Copied from: https://github.com/AlphaFinanceLab/homora-v2/blob/master/contracts/oracle/BaseKP3ROracle.sol
     * @param pair The pair to query for price0.
     */
    function getPrice0TWAP(address pair) internal view returns (uint256) {
        uint256 length = observationCount[pair];
        require(length > 0, "No length-1 TWAP observation.");
        Observation memory lastObservation = observations[pair][
            (length - 1) % OBSERVATION_BUFFER
        ];
        if (lastObservation.timestamp > block.timestamp - MIN_TWAP_TIME) {
            require(length > 1, "No length-2 TWAP observation.");
            lastObservation = observations[pair][
                (length - 2) % OBSERVATION_BUFFER
            ];
        }
        uint256 elapsedTime = block.timestamp - lastObservation.timestamp;
        require(elapsedTime >= MIN_TWAP_TIME, "Bad TWAP time.");
        uint256 currPx0Cumu = getCurrentPx0Cumu(pair);
        return
            (currPx0Cumu - lastObservation.price0Cumulative) /
            (block.timestamp - lastObservation.timestamp); // overflow is desired
    }

    /**
     * @dev Return the TWAP value price1. Revert if TWAP time range is not within the threshold.
     * Copied from: https://github.com/AlphaFinanceLab/homora-v2/blob/master/contracts/oracle/BaseKP3ROracle.sol
     * @param pair The pair to query for price1.
     */
    function getPrice1TWAP(address pair) internal view returns (uint256) {
        uint256 length = observationCount[pair];
        require(length > 0, "No length-1 TWAP observation.");
        Observation memory lastObservation = observations[pair][
            (length - 1) % OBSERVATION_BUFFER
        ];
        if (lastObservation.timestamp > block.timestamp - MIN_TWAP_TIME) {
            require(length > 1, "No length-2 TWAP observation.");
            lastObservation = observations[pair][
                (length - 2) % OBSERVATION_BUFFER
            ];
        }
        uint256 elapsedTime = block.timestamp - lastObservation.timestamp;
        require(elapsedTime >= MIN_TWAP_TIME, "Bad TWAP time.");
        uint256 currPx1Cumu = getCurrentPx1Cumu(pair);
        return
            (currPx1Cumu - lastObservation.price1Cumulative) /
            (block.timestamp - lastObservation.timestamp); // overflow is desired
    }

    /**
     * @dev Return the current price0 cumulative value on Uniswap.
     * Copied from: https://github.com/AlphaFinanceLab/homora-v2/blob/master/contracts/oracle/BaseKP3ROracle.sol
     * @param pair The uniswap pair to query for price0 cumulative value.
     */
    function getCurrentPx0Cumu(address pair)
        internal
        view
        returns (uint256 px0Cumu)
    {
        uint32 currTime = uint32(block.timestamp);
        px0Cumu = IUniswapV2Pair(pair).price0CumulativeLast();
        (uint256 reserve0, uint256 reserve1, uint32 lastTime) = IUniswapV2Pair(
            pair
        ).getReserves();
        if (lastTime != block.timestamp) {
            uint32 timeElapsed = currTime - lastTime; // overflow is desired
            px0Cumu += uint256((reserve1 << 112) / reserve0) * timeElapsed; // overflow is desired
        }
    }

    /**
     * @dev Return the current price1 cumulative value on Uniswap.
     * Copied from: https://github.com/AlphaFinanceLab/homora-v2/blob/master/contracts/oracle/BaseKP3ROracle.sol
     * @param pair The uniswap pair to query for price1 cumulative value.
     */
    function getCurrentPx1Cumu(address pair)
        internal
        view
        returns (uint256 px1Cumu)
    {
        uint32 currTime = uint32(block.timestamp);
        px1Cumu = IUniswapV2Pair(pair).price1CumulativeLast();
        (uint256 reserve0, uint256 reserve1, uint32 lastTime) = IUniswapV2Pair(
            pair
        ).getReserves();
        if (lastTime != currTime) {
            uint32 timeElapsed = currTime - lastTime; // overflow is desired
            px1Cumu += uint256((reserve0 << 112) / reserve1) * timeElapsed; // overflow is desired
        }
    }

    /**
     * @dev Returns the price of `underlying` in terms of `baseToken` given `factory`.
     */
    function getPairTwapPrice(
        address underlying,
        address baseToken,
        address factory
    ) external view override returns (uint256) {
        // Return ERC20/ETH TWAP
        address pair = IUniswapV2Factory(factory).getPair(
            underlying,
            baseToken
        );
        uint256 baseUnit = 10**uint256(ERC20Upgradeable(underlying).decimals());
        return
            (((
                underlying < baseToken
                    ? getPrice0TWAP(pair)
                    : getPrice1TWAP(pair)
            ) / (2**56)) * (baseUnit)) / (2**56); // Scaled by 1e18, not 2 ** 112
    }

    /**
     * @dev Length after which observations roll over to index 0.
     */
    uint8 public constant OBSERVATION_BUFFER = 4;

    /**
     * @dev Total observation count for each pair.
     */
    mapping(address => uint256) public observationCount;

    /**
     * @dev Array of cumulative price observations for each pair.
     */
    mapping(address => Observation[OBSERVATION_BUFFER]) public observations;

    /// @notice Get pairs for token combinations.
    function getPairsForTokens(
        address[] calldata tokenA,
        address[] calldata tokenB,
        address factory
    ) external view override returns (address[] memory) {
        require(
            tokenA.length > 0 && tokenA.length == tokenB.length,
            "Token array lengths must be equal and greater than 0."
        );
        address[] memory pairs = new address[](tokenA.length);
        // slither-disable-next-line uninitialized-local
        for (uint256 i; i < tokenA.length; i++)
            pairs[i] = IUniswapV2Factory(factory).getPair(tokenA[i], tokenB[i]);
        return pairs;
    }

    /// @notice Check which of multiple pairs are workable/updatable.
    function isPairUpdatable(
        address[] calldata pairs,
        address[] calldata baseTokens,
        uint256[] calldata minPeriods,
        uint256[] calldata deviationThresholds
    ) external view override returns (bool[] memory) {
        require(
            pairs.length > 0 &&
                pairs.length == baseTokens.length &&
                pairs.length == minPeriods.length &&
                pairs.length == deviationThresholds.length,
            "Array lengths must be equal and greater than 0."
        );
        bool[] memory answers = new bool[](pairs.length);
        // slither-disable-next-line uninitialized-local
        for (uint256 i; i < pairs.length; i++)
            answers[i] = _isPairUpdatable(
                pairs[i],
                baseTokens[i],
                minPeriods[i],
                deviationThresholds[i]
            );
        return answers;
    }

    /// @dev Internal function to check if a pair is workable (updatable AND reserves have changed AND deviation threshold is satisfied).
    function _isPairUpdatable(
        address pair,
        address baseToken,
        uint256 minPeriod,
        uint256 deviationThreshold
    ) internal view returns (bool) {
        if (observationCount[pair] <= 0) return true;
        (, , uint32 lastTime) = IUniswapV2Pair(pair).getReserves();
        uint256 lastObservationTimestamp = observations[pair][
                    (observationCount[pair] - 1) % OBSERVATION_BUFFER
                ].timestamp;

        uint256 minimumPeriod = (minPeriod >= MIN_TWAP_TIME ? minPeriod : MIN_TWAP_TIME);

        bool gteMinPeriod = (block.timestamp - lastObservationTimestamp) >= minimumPeriod;
        bool notEqLastTime = lastTime != lastObservationTimestamp;
        bool gteDeviation = _getDeviation(pair, baseToken) >= deviationThreshold;

        return
            gteMinPeriod
         && notEqLastTime 
         && gteDeviation;
            
    }

    ///TODO: should this be an external view function for the LZ oracle or is workable okay?
    /// @dev Internal function to check if a pair"s spot price"s deviation from its TWAP price as a ratio scaled by 1e18
    function _getDeviation(
        address pair,
        address baseToken
    ) internal view returns (uint256) {
        // Get token base unit
        address token0 = IUniswapV2Pair(pair).token0();
        bool useToken0Price = token0 != baseToken;
        address underlying = useToken0Price
            ? token0
            : IUniswapV2Pair(pair).token1();
        uint256 baseUnit = 10**uint256(ERC20Upgradeable(underlying).decimals());

        // Get TWAP price
        uint256 twapPrice = (((
            useToken0Price ? getPrice0TWAP(pair) : getPrice1TWAP(pair)
        ) / (2**56)) * (baseUnit)) / (2**56); // Scaled by 1e18, not 2 ** 112


        // Get spot price
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(pair).getReserves();
        uint256 spotPrice = useToken0Price ? reserve1 * baseUnit / reserve0 : reserve0 * baseUnit / reserve1;
        // Get ratio and return deviation
        uint256 ratio = (spotPrice * (1e18)) / (twapPrice);
        return ratio >= 1e18 ? ratio - 1e18 : 1e18 - ratio;
    }

    /// @dev Internal function to check if a pair is updatable at all.
    function _isUpdateable(address pair) internal view returns (bool) {
        // Updateable if:
        // 1) We have no observations
        // 2) The elapsed time since the last observation is > MIN_TWAP_TIME
        // Note that we loop observationCount[pair] around OBSERVATION_BUFFER so we don"t waste gas on new storage slots
        return
            observationCount[pair] <= 0 ||
            (block.timestamp -
                observations[pair][
                    (observationCount[pair] - 1) % OBSERVATION_BUFFER
                ].timestamp) >
            MIN_TWAP_TIME;
    }

    /// @notice Update one pair.
    function updatePair(address pair) external override returns (address) {
        require(_update(pair), "Failed to update pair.");
        return pair;
    }

    /// @notice Update multiple pairs at once.
    function updatePairs(address[] calldata pairs)
        external
        override
        returns (address[] memory)
    {
        bool worked = false;
        // slither-disable-next-line uninitialized-local
        for (uint256 i; i < pairs.length; i++) {
            if (_update(pairs[i])) worked = true;
        }
        require(worked, "No pairs can be updated (yet).");
        return pairs;
    }

    /// @dev Internal function to update a single pair.
    function _update(address pair) internal returns (bool) {
        // Check if workable
        if (!_isUpdateable(pair)) return false;

        // Get cumulative price(s)
        uint256 price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        uint256 price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // Loop observationCount[pair] around OBSERVATION_BUFFER so we don"t waste gas on new storage slots
        (, , uint32 lastTime) = IUniswapV2Pair(pair).getReserves();
        observations[pair][
            observationCount[pair] % OBSERVATION_BUFFER
        ] = Observation(lastTime, price0Cumulative, price1Cumulative);
        observationCount[pair]++;
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IUniswapV2Oracle {

    struct Observation {
        uint32 timestamp;
        uint256 price0Cumulative;
        uint256 price1Cumulative;
    }

    function getPairTwapPrice(
        address underlying,
        address baseToken,
        address factory
    ) external view returns (uint256);

    /// @notice Get pairs for token combinations.
    function getPairsForTokens(
        address[] calldata tokenA,
        address[] calldata tokenB,
        address factory
    ) external view returns (address[] memory);

    /// @notice Check which of multiple pairs are workable/updatable.
    function isPairUpdatable(
        address[] calldata pairs,
        address[] calldata baseTokens,
        uint256[] calldata minPeriods,
        uint256[] calldata deviationThresholds
    ) external view returns (bool[] memory);

    function updatePair(address pair) external returns (address);

    function updatePairs(address[] calldata pairs)
        external
        returns (address[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../oracle/interfaces/IPrimeOracle.sol";
import "../oracle/interfaces/IPrimeOracleGetter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Oracle.sol";

contract UniswapV2OracleGetter is IPrimeOracleGetter {

    // Map of asset price feeds (asset => priceSource)
    mapping(uint256 => mapping(address => AggregatorV3Interface)) private assetFeeds;

    IUniswapV2Factory public immutable uniV2Factory;
    IUniswapV2Oracle public immutable masterUniswapV2Oracle;

    //TODO: allow transfer of ownership
    address public admin;

    /**
    * @dev Only the admin can call functions marked by this modifier.
    **/
    modifier onlyAdmin {
        require(msg.sender == admin, "Unauthorized use of function");
        _;
    }


    /// @notice constructor
    /// @param assets list of addresses of the assets
    /// @param feeds The address of the feed of each asset
    constructor(
        uint256[] memory chainIds,
        address[] memory assets,
        address[] memory feeds,
        address uniV2FactoryParam,
        address masterUniswapV2OracleParam
    ) {
        require(uniV2FactoryParam != address(0), "NON_ZEROADDRESS");
        require(masterUniswapV2OracleParam != address(0), "NON_ZEROADDRESS");
        admin = msg.sender;
        _setAssetFeeds(chainIds, assets, feeds);
        uniV2Factory = IUniswapV2Factory(uniV2FactoryParam);
        masterUniswapV2Oracle = IUniswapV2Oracle(masterUniswapV2OracleParam);
    }

    /// @inheritdoc IPrimeOracleGetter
    function getAssetPrice(uint256, address quoteToken, address denomToken) external view override returns (uint256) {
        //TODO: implelement cross-chain functionality
        //8 decimal precision for USD prices
        uint256 price = masterUniswapV2Oracle.getPairTwapPrice(address(quoteToken), address(denomToken), address(uniV2Factory));
        return uint256(price);
    }

     function getPriceDecimals(uint256, address quoteToken, address denomToken) external view override returns (uint256) {
        //TODO: implelement cross-chain functionality
        return 18;
    }

    function _getAssetFeed(uint256 chainId, address asset) internal view returns (address){
        return address(assetFeeds[chainId][asset]);
    }

    /// @inheritdoc IPrimeOracleGetter
    function getAssetFeed(uint256 chainId, address asset) external view override returns (address){
        return _getAssetFeed(chainId, asset);
    }

    /// @inheritdoc IPrimeOracleGetter
    function setAssetFeeds(uint256[] calldata chainIds, address[] calldata assets, address[] calldata feeds)
        external
        override
        onlyAdmin()
    {
        _setAssetFeeds(chainIds, assets, feeds);
    }

    /**
    * @notice Internal function to set the feeds for each asset
    * @param assets The addresses of the assets
    * @param feeds The address of the feed of each asset
    */
    function _setAssetFeeds(uint256[] memory chainIds, address[] memory assets, address[] memory feeds) internal {
        require(chainIds.length == assets.length && assets.length == feeds.length, "ERROR: Length mismatch between 'assets' 'feeds' and/or 'chainIds'");
        // slither-disable-next-line uninitialized-local
        for (uint256 i; i < assets.length; i++) {
            assetFeeds[chainIds[i]][assets[i]] = AggregatorV3Interface(feeds[i]);
            emit AssetFeedUpdated(chainIds[i], assets[i], feeds[i]);
        }
    }

    function getUniswapV2Factory() external view returns (address) {
        return address(uniV2Factory);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Pair.sol";

contract UniswapV2FactoryMock is IUniswapV2Factory {

    address token0;
    address token1;
    IUniswapV2Pair mockPair;

    constructor(
        address token0Param,
        address token1Param,
        address mockPairParam
    ){
        token0 = token0Param;
        token1 = token1Param;
        mockPair = IUniswapV2Pair(mockPairParam);
    }

    function getPair(address tokenA, address tokenB) public view override returns (address pair) {
        if(tokenA == token0 && tokenB == token1) {
            return address(mockPair);
        }
        else if(tokenA == token1 && tokenB == token0) {
            return address(mockPair);
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../oracle/interfaces/IPrimeOracle.sol";
import "../oracle/interfaces/IPrimeOracleGetter.sol";
import "../../satellite/pToken/interfaces/IPToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../satellite/loanAgent/interfaces/ILoanAgent.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PrimeOracle is IPrimeOracle {

    // Map of asset price feeds (chainasset => priceSource)
    mapping(uint256 => mapping(address => IPrimeOracleGetter)) private primaryFeeds;
    mapping(uint256 => mapping(address => IPrimeOracleGetter)) private secondaryFeeds;

    address public immutable pusdAddress;
    address public immutable usdcAddress;

    //TODO: allow transfer of ownership
    address public admin;

    /**
    * @dev Only the admin can call functions marked by this modifier.
    **/
    modifier onlyAdmin {
        require(msg.sender == admin, "Unauthorized use of function");
        _;
    }

    constructor(
        address pusdAddressParam,
        address usdcAddressParam
    ) {
        require(pusdAddressParam != address(0), "ERROR: zero address provided for PUSD.");
        require(usdcAddressParam != address(0), "ERROR: zero address provided for USDC.");
        admin = msg.sender;
        pusdAddress = pusdAddressParam;
        usdcAddress = usdcAddressParam;
    }

    function _getAssetPrices(uint256[] memory chainIds, address[] memory assets)
        internal
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory prices = new uint256[](assets.length);
        uint256[] memory decimals = new uint256[](assets.length);

        // slither-disable-next-line uninitialized-local
        for (uint256 i; i < assets.length; i++) {
            IPrimeOracleGetter primaryFeed =  primaryFeeds[chainIds[i]][assets[i]];
            require(address(primaryFeed) != address(0), "ERROR: missing primary feed for asset");
            prices[i] = primaryFeed.getAssetPrice(chainIds[i], assets[i], usdcAddress);
            decimals[i] = primaryFeed.getPriceDecimals(chainIds[i], assets[i], usdcAddress);
            if (prices[i] == 0){
                IPrimeOracleGetter secondaryFeed = secondaryFeeds[chainIds[i]][assets[i]];
                require(address(secondaryFeed) != address(0), "ERROR: missing secondary feed for asset");
                prices[i] = secondaryFeed.getAssetPrice(chainIds[i], assets[i], usdcAddress);
                decimals[i] = secondaryFeed.getPriceDecimals(chainIds[i], assets[i], usdcAddress);
            }
        }
        return (prices, decimals);
    }

    function _getAssetPrice(uint256 chainId, address asset)
        internal
        view
        returns (uint256, uint256)
    {
        // slither-disable-next-line uninitialized-local   
        IPrimeOracleGetter primaryFeed =  primaryFeeds[chainId][asset];
        require(address(primaryFeed) != address(0), "ERROR: missing primary feed for asset");
        uint256 price = primaryFeed.getAssetPrice(chainId, asset, usdcAddress);
        uint256 decimal = primaryFeed.getPriceDecimals(chainId, asset, usdcAddress);
        if (price == 0){
            IPrimeOracleGetter secondaryFeed = secondaryFeeds[chainId][asset];
            require(address(secondaryFeed) != address(0), "ERROR: missing secondary feed for asset");
            price = secondaryFeed.getAssetPrice(chainId, asset, usdcAddress);
            decimal = secondaryFeed.getPriceDecimals(chainId, asset, usdcAddress);
        }
        return (price, decimal);
    }

    /// @inheritdoc IPrimeOracle
    function getAssetPrices(uint256[] calldata chainIds, address[] calldata assets)
        external
        view
        override
        returns (uint256[] memory, uint256[] memory)
    {
        return _getAssetPrices(chainIds, assets);
    }

    /// @inheritdoc IPrimeOracle
    function getPrimaryFeedOfAsset(uint256 chainId, address asset) external view override returns (address) {
        return address(primaryFeeds[chainId][asset]);
    }

    /// @inheritdoc IPrimeOracle
    function getSecondaryFeedOfAsset(uint256 chainId, address asset) external view override returns (address) {
        return address(secondaryFeeds[chainId][asset]);
    }

    function getPusdAddress() external view override returns(address) {
        return pusdAddress;
    }

    function getPusdPrice() external view override returns (uint256, uint256) {
        return _getAssetPrice(block.chainid, pusdAddress);
    }

    /// @inheritdoc IPrimeOracle
    function setPrimaryFeeds(uint256[] calldata chainIds, address[] calldata assets, IPrimeOracleGetter[] calldata feeds)
        external
        override
        onlyAdmin()
    {
        _setPrimaryFeeds(chainIds, assets, feeds);
    }

    /// @inheritdoc IPrimeOracle
    function setSecondaryFeeds(uint256[] calldata chainIds, address[] calldata assets, IPrimeOracleGetter[] calldata feeds)
        external
        override
        onlyAdmin()
    {
        _setSecondaryFeeds(chainIds, assets, feeds);
    }

    /**
    * @notice Internal function to set the feeds for each asset
    * @param assets The addresses of the assets
    * @param feeds The address of the feed of each asset
    */
    function _setPrimaryFeeds(uint256[] memory chainIds, address[] memory assets, IPrimeOracleGetter[] memory feeds) internal {
        require(chainIds.length == assets.length && assets.length == feeds.length, "ERROR: Length mismatch between 'chainIds' 'assets' and 'feeds'");
        // slither-disable-next-line uninitialized-local
        for (uint256 i; i < assets.length; i++) {
            primaryFeeds[chainIds[i]][assets[i]] = IPrimeOracleGetter(feeds[i]);
            emit PrimaryFeedUpdated(chainIds[i], assets[i], address(primaryFeeds[chainIds[i]][assets[i]]));
        }
    }

    /**
    * @notice Internal function to set the feeds for each asset
    * @param assets The addresses of the assets
    * @param feeds The address of the feed of each asset
    */
    function _setSecondaryFeeds(uint256[] memory chainIds, address[] memory assets, IPrimeOracleGetter[] memory feeds) internal {
        require(chainIds.length == assets.length && assets.length == feeds.length, "ERROR: Length mismatch between 'chainIds' 'assets' and 'feeds'");
        // slither-disable-next-line uninitialized-local
        for (uint256 i; i < assets.length; i++) {
            secondaryFeeds[chainIds[i]][assets[i]] = IPrimeOracleGetter(feeds[i]);
            emit SecondaryFeedUpdated(chainIds[i], assets[i], address(secondaryFeeds[chainIds[i]][assets[i]]));
        }
    }

    function getUnderlyingPrice(uint256 chainId, address asset) external view override returns (uint256, uint256) {
        return _getAssetPrice(chainId, asset);
    }

    function getUnderlyingPriceBorrow() external view override returns (uint256) {
        return 10**ERC20(pusdAddress).decimals();
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../interfaces/IHelper.sol";
import "./interfaces/ILoanAgent.sol";
import "./interfaces/ILoanAgentInternals.sol";
import "./LoanAgentModifiers.sol";
import "../pusd/interfaces/IPUSD.sol";
import "./LoanAgentEvents.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

abstract contract LoanAgentMessageHandler is ILoanAgent, ILoanAgentInternals, LoanAgentModifiers, LoanAgentEvents {
    // slither-disable-next-line assembly
    function _sendBorrow(
        address user,
        uint256 amount
    ) internal virtual override {
        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.MBorrowAllowed(
                IHelper.Selector.MASTER_BORROW_ALLOWED,
                user,
                amount
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
            address(0)
        );

        emit BorrowSent(
            user, 
            address(this), 
            amount
        );
    }

    function borrowApproved(
        IHelper.FBBorrow memory params,
        bytes32 metadata
    ) external payable override virtual onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) {
            // this message has already been processed
            return;
        }

        emit BorrowApproved(
            params.user, 
            params.borrowAmount, 
            true
        );

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We invoke doTransferOut for the borrower and the borrowAmount.
         *  Note: The pToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the pToken borrowAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        // This can be easily simplified because we are only issuing one token - PuSD
        // doTransferOut(borrower, borrowAmount);
        // might need a safe transfer of sorts

        IPUSD(PUSD).mint(params.user, params.borrowAmount);

        // /* We write the previously calculated values into storage */
        // accountBorrows[params.user] = borrowBalanceStored(params.user) + params.borrowAmount;
        // //accountBorrows[params.user].interestIndex = borrowIndex;
        // totalBorrows += params.borrowAmount;

        /* We emit a Borrow event */
        emit BorrowComplete(
            params.user,
            address(this),
            params.borrowAmount
        );
        /* We call the defense hook */
        // unused function
        // comptroller.borrowVerify(address(this), borrower, borrowAmount);

        require(ecc.flagMsgValidated(abi.encode(params), metadata), "FMV");
    }

    // slither-disable-next-line assembly
    function _repayBorrowFresh(
        address payer,
        address borrower,
        uint256 repayAmount
    ) internal virtual override returns (uint256) {
        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
        * We call doTransferIn for the payer and the repayAmount
        *  Note: The pToken must handle variations between ERC-20 and ETH underlying.
        *  On success, the pToken holds an additional repayAmount of cash.
        *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
        *   it returns the amount actually transferred, in case of a fee.
        */
        ERC20Burnable(PUSD).burnFrom(payer, repayAmount);

        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.MRepay({
                selector: IHelper.Selector.MASTER_REPAY,
                borrower: borrower,
                amountRepaid: repayAmount
            })
        );

        bytes32 metadata = ecc.preRegMsg(payload, msg.sender);
        assembly {
            mstore(add(payload, 0x20), metadata)
        }

        middleLayer.msend{ value: msg.value }(
            masterCID,
            payload,
            payable(msg.sender),
            address(0)
        );

        emit RepaySent(
            payer,
            borrower,
            address(this),
            repayAmount
        );

        return repayAmount;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./LoanAgentStorage.sol";

abstract contract LoanAgentModifiers is LoanAgentStorage {

    modifier onlyOwner() {
        require(msg.sender == admin, "ONLY_OWNER");
        _;
    }

    modifier onlyMid() {
        require(msg.sender == address(middleLayer), "ONLY_MIDDLE_LAYER");
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract LoanAgentEvents {
    event BorrowSent(
        address user, 
        address loanAgent, 
        uint256 amount
    );

     event BorrowApproved(
         address indexed borrower,
         uint256 borrowAmount,
         bool isBorrowAllowed
     );
    
    event BorrowComplete(
        address indexed borrower,
        address loanAgent,
        uint256 borrowAmount
    );

    event RepaySent(
        address payer,
        address borrower,
        address loanAgent,
        uint256 repayAmount
    );

    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral,
        uint256 seizeTokens
    );

    event SetPUSD(
        address newPUSD
    );

    event SetMidLayer(
        address middleLayer
    );

    event SetMasterCID(
        uint256 newChainId
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/ILoanAgent.sol";
import "./LoanAgentModifiers.sol";
import "./LoanAgentEvents.sol";

abstract contract LoanAgentAdmin is ILoanAgent, LoanAgentModifiers, LoanAgentEvents {
    function setPUSD(
        address newPUSD
    ) external override onlyOwner() {
        require(newPUSD != address(0), "NON_ZEROADDRESS");
        PUSD = newPUSD;

        emit SetPUSD(newPUSD);
    }

    function setMidLayer(
        address newMiddleLayer
    ) external override onlyOwner() {
        require(newMiddleLayer != address(0), "NON_ZEROADDRESS");
        middleLayer = IMiddleLayer(newMiddleLayer);

        emit SetMidLayer(newMiddleLayer);
    }

    function setMasterCID(
        uint256 newChainId
    ) external override onlyOwner() {
        masterCID = newChainId;

        emit SetMasterCID(newChainId);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "./interfaces/ILoanAgent.sol";
// import "../interfaces/IPToken.sol";
// import "../PUSD.sol";
// import { ReentrancyGuard } from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";

// import "./interfaces/EIP20Interface.sol";
// import "./oracle/PrimeOracle.sol";

import "./interfaces/ILoanAgent.sol";
import "./LoanAgentAdmin.sol";
import "./LoanAgentEvents.sol";
import "./LoanAgentMessageHandler.sol";
import "./LoanAgentInternals.sol";
import "../../util/CommonModifiers.sol";

contract SatelliteLoanAgent is
    ILoanAgent,
    LoanAgentAdmin,
    LoanAgentMessageHandler,
    LoanAgentInternals,
    CommonModifiers
{
    function initialize(address eccAddress) external override // InterestRateModel _interestRateModel
    {
        ecc = IECC(eccAddress);
        // NOTE: What is this for
        borrowIndex = 1e18;
        // interestRateModel = _interestRateModel;
        admin = payable(msg.sender);
    }

    /**
     * @notice Users borrow assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     */
    function borrow(uint256 borrowAmount) external payable virtual override {
        _sendBorrow(msg.sender, borrowAmount);
    }

    function repayBorrow(
        uint256 repayAmount
    ) external payable virtual override returns (bool) {
        _repayBorrowFresh(msg.sender, msg.sender, repayAmount);

        return true;
    }

    function repayBorrowBehalf(
        address borrower,
        uint256 repayAmount
    ) external payable virtual override returns (bool) {
        _repayBorrowFresh(msg.sender, borrower, repayAmount);

        return true;
    }

    fallback() external payable {}
}

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
    constructor(address _delegateeAddress, address eccAddress) {
        admin = delegatorAdmin = payable(msg.sender);

        setDelegateeAddress(_delegateeAddress);

        _delegatecall(abi.encodeWithSelector(
            ILoanAgent.initialize.selector,
            eccAddress
        ));
    }

    function initialize(address eccAddress) external override {}

    function borrow(uint256 borrowAmount) external payable override {
        _delegatecall(abi.encodeWithSelector(
            SatelliteLoanAgent.borrow.selector,
            borrowAmount
        ));
    }

    function repayBorrow(uint256 repayAmount) external payable override returns (bool success) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            SatelliteLoanAgent.repayBorrow.selector,
            repayAmount
        ));

        (success) = abi.decode(data, (bool));

        emit RepayBorrow(success);
    }

    function repayBorrowBehalf(
        address borrower,
        uint256 repayAmount
    ) external payable override returns (bool success) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            SatelliteLoanAgent.repayBorrowBehalf.selector,
            borrower,
            repayAmount
        ));

        (success) = abi.decode(data, (bool));

        emit RepayBorrowBehalf(success);
    }

    function borrowApproved(
        IHelper.FBBorrow memory params,
        bytes32 metadata
    ) external payable override {
        _delegatecall(abi.encodeWithSelector(
            LoanAgentMessageHandler.borrowApproved.selector,
            params,
            metadata
        ));
    }

    function setPUSD(address newPUSD) external override {
        _delegatecall(abi.encodeWithSelector(
            LoanAgentAdmin.setPUSD.selector,
            newPUSD
        ));
    }

    function setMidLayer(address newMiddleLayer) external override {
        _delegatecall(abi.encodeWithSelector(
            LoanAgentAdmin.setMidLayer.selector,
            newMiddleLayer
        ));
    }

    function setMasterCID(uint256 newChainId) external override {
        _delegatecall(abi.encodeWithSelector(
            LoanAgentAdmin.setMasterCID.selector,
            newChainId
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract LoanAgentDelegatorEvents {

    event RepayBorrow(bool success);
    event RepayBorrowBehalf(bool success);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MiddleLayerAdmin.sol";
import "../satellite/pToken/PTokenMessageHandler.sol";

import "../interfaces/IHelper.sol";
import "./interfaces/IMiddleLayer.sol";
import "../util/CommonModifiers.sol";

contract MiddleLayer is IMiddleLayer, MiddleLayerAdmin, CommonModifiers {
    constructor(uint256 newChainId) {
        owner = msg.sender;
        cid = newChainId;
    }

    event MessageSent (
        uint256 _dstChainId,
        bytes params,
        address _refundAddress,
        address fallbackAddress
    );

    event MessageReceived(
        uint256 _srcChainId,
        bytes payload
    );

/*
    function autoRoute(
        uint256 _dstChainId,
        bytes memory _destination,
        bytes memory params,
        address payable _refundAddress,
        bytes memory _adapterParams
    ) external view returns (
        uint256 estimatedGas,
        uint256 estimatedArrival,
        uint256 route
    ) {
        (   uint256[] memory _estimatedGas,
            uint256[] memory _estimatedArrival
        ) = _checkRoute(
            _dstChainId,
            _destination,
            params,
            _refundAddress,
            _adapterParams
        );

        // determine which route is best and return those estimates along with the route id
    }

    function checkRoute(
        uint256 _dstChainId,
        bytes memory _destination,
        bytes memory params,
        address payable _refundAddress,
        bytes memory _adapterParams
    ) external view returns (
        uint256[] memory estimatedGas,
        uint256[] memory estimatedArrival
    ) {
        return _checkRoute(
            _dstChainId,
            _destination,
            params,
            _refundAddress,
            _adapterParams
        );
    }

    function _checkRoute(
        uint256 _dstChainId,
        bytes memory _destination,
        bytes memory params,
        address payable _refundAddress,
        bytes memory _adapterParams
    ) internal view returns (
        uint256[] memory estimatedGas,
        uint256[] memory estimatedArrival
    ) {

    }
*/

    function msend(
        uint256 _dstChainId,
        bytes memory params,
        address payable _refundAddress,
        address fallbackAddress
    ) external payable override onlyAuth() {
        // if thisChain == dstChain, process the send directly instead of through router

        emit MessageSent (
            _dstChainId,
            params,
            _refundAddress,
            fallbackAddress
        );

        if (fallbackAddress == address(0)) {
            uint256 hash = uint256(keccak256(abi.encodePacked(params, block.timestamp, _dstChainId)));
            // This prng is safe as its not logic reliant, and produces a safe output given the routing protocol that is chosen is not offline
            // slither-disable-next-line weak-prng
            routes[hash % routes.length].msend{value: msg.value}(
                _dstChainId, // destination LayerZero chainId
                params, // bytes payload
                _refundAddress // refund address
            );
            return;
        }
        IRoute(fallbackAddress).msend{value:msg.value}(
            _dstChainId,
            params,
            _refundAddress
        );
    }

    // slither-disable-next-line assembly
    function mreceive(
        uint256 _srcChainId,
        bytes memory payload
    ) external override onlyRoute() {
        IHelper.Selector selector;
        bytes32 metadata;
        assembly {
            metadata := mload(add(payload, 0x20))
            selector := mload(add(payload, 0x40))
        }

        emit MessageReceived(
            _srcChainId,
            payload
        );

        if (IHelper.Selector.MASTER_DEPOSIT == selector) {
            // slither-disable-next-line all
            IHelper.MDeposit memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
                mstore(add(params, 0x60), mload(add(payload, 0xa0)))
                mstore(add(params, 0x80), mload(add(payload, 0xc0)))
            }

            masterState.masterDeposit(
                params,
                metadata,
                _srcChainId
            );
        } else if (IHelper.Selector.MASTER_REDEEM_ALLOWED == selector) {
            // slither-disable-next-line all
            IHelper.MRedeemAllowed memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
                mstore(add(params, 0x60), mload(add(payload, 0xa0)))
            }

            masterState.redeemAllowed(
                params,
                metadata,
                _srcChainId,
                msg.sender
            );
        } else if (IHelper.Selector.FB_REDEEM == selector) {
            // slither-disable-next-line all
            IHelper.FBRedeem memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
                mstore(add(params, 0x60), mload(add(payload, 0xa0)))
            }

            PTokenMessageHandler(params.pToken).completeRedeem(
                params,
                metadata
            );
        } else if (IHelper.Selector.MASTER_REPAY == selector) {
            // slither-disable-next-line all
            IHelper.MRepay memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
                mstore(add(params, 0x60), mload(add(payload, 0xa0)))
            }

            masterState.masterRepay(
                params,
                metadata,
                _srcChainId
            );
        } else if (IHelper.Selector.MASTER_BORROW_ALLOWED == selector) {
            // slither-disable-next-line all
            IHelper.MBorrowAllowed memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
            }

            masterState.borrowAllowed(
                params,
                metadata,
                _srcChainId,
                msg.sender
            );
        } else if (IHelper.Selector.FB_BORROW == selector) {
            // slither-disable-next-line all
            IHelper.FBBorrow memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
            }

            loanAgent.borrowApproved(
                params,
                metadata
            );
        } else if (IHelper.Selector.SATELLITE_LIQUIDATE_BORROW == selector) {
            // slither-disable-next-line all
            IHelper.SLiquidateBorrow memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
                mstore(add(params, 0x60), mload(add(payload, 0xa0)))
                mstore(add(params, 0x80), mload(add(payload, 0xc0)))
            }

            PTokenMessageHandler(params.pTokenCollateral).seize(
                params,
                metadata
            );
        } else if (IHelper.Selector.MASTER_TRANSFER_ALLOWED == selector) {
            // slither-disable-next-line all
            IHelper.MTransferAllowed memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
                mstore(add(params, 0x60), mload(add(payload, 0xa0)))
                mstore(add(params, 0x80), mload(add(payload, 0xc0)))
                mstore(add(params, 0xa0), mload(add(payload, 0xe0)))
            }

            masterState.transferAllowed(
                params,
                metadata,
                _srcChainId,
                msg.sender
            );
        } else if (IHelper.Selector.FB_COMPLETE_TRANSFER == selector) {
            // slither-disable-next-line all
            IHelper.FBCompleteTransfer memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
                mstore(add(params, 0x60), mload(add(payload, 0xa0)))
                mstore(add(params, 0x80), mload(add(payload, 0xc0)))
                mstore(add(params, 0xa0), mload(add(payload, 0xe0)))
            }

            PTokenMessageHandler(params.pToken).completeTransfer(
                params,
                metadata
            );
        } else if (IHelper.Selector.PUSD_BRIDGE == selector) {
            // slither-disable-next-line all
            IHelper.PUSDBridge memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
            }
            pusd.mintFromChain(
                params,
                metadata,
                _srcChainId
            );
        }
    }

    fallback() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MiddleLayerModifiers.sol";

abstract contract MiddleLayerAdmin is MiddleLayerStorage, MiddleLayerModifiers {
    event ChangeOwner(
        address newOwner
    );

    function changeOwner(address newOwner) external onlyOwner() {
        require(newOwner != address(0), "NON_ZEROADDRESS");
        owner = newOwner;
        emit ChangeOwner(newOwner);
    }

    function _changeAuth(
        address contractAddr,
        bool status
    ) internal {
        require(contractAddr != address(0), "NON_ZEROADDRESS");
        authContracts[contractAddr] = status;
    }

    function changeAuth(address contractAddr, bool status) external onlyOwner() {
        _changeAuth(contractAddr, status);
    }

    function changeManyAuth(
        address[] calldata contractAddr,
        bool[] calldata status
    ) external onlyOwner() {
        require(contractAddr.length == status.length, "Mismatch len");
        // slither-disable-next-line uninitialized-local
        for (uint8 i; i < contractAddr.length; i++) {
            _changeAuth(contractAddr[i], status[i]);
        }
    }

    function setMasterState(address newMasterState) external onlyOwner() {
        require(newMasterState != address(0), "NON_ZEROADDRESS");
        masterState = MasterMessageHandler(newMasterState);
    }

    function setLoanAgent(address newLoanAgent) external onlyOwner() {
        require(newLoanAgent != address(0), "NON_ZEROADDRESS");
        loanAgent = ILoanAgent(newLoanAgent);
    }

    function setPUSD(address newPUSD) external onlyOwner() {
        require(newPUSD != address(0), "NON_ZEROADDRESS");
        pusd = PUSDMessageHandler(newPUSD);
    }

    function addRoute(IRoute newRoute) external onlyOwner() {
        require(address(newRoute) != address(0), "NON_ZEROADDRESS");
        routes.push(newRoute);
        authRoutes[address(newRoute)] = true;
    }

    // slither-disable-next-line costly-loop
    function removeRoute(IRoute fallbackAddressToRemove) external onlyOwner() {
        // slither-disable-next-line uninitialized-local
        for (uint i; i < routes.length; i++) {
            if (routes[i] == fallbackAddressToRemove) {
                // swap the route to remove with the last item
                routes[i] = routes[routes.length-1];
                // pop the last item
                routes.pop();

                authRoutes[address(fallbackAddressToRemove)] = false;
                return;
            }
        }
        revert("ROUTE_NOT_FOUND");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MiddleLayerStorage.sol";

abstract contract MiddleLayerModifiers is MiddleLayerStorage {
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyAuth() {
        require(authContracts[msg.sender], "Unauthorized caller");
        _;
    }

    modifier onlyRoute() {
        require(authRoutes[msg.sender], "Unauthorized caller");
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../irm/interfaces/IIRM.sol";
import "../irm/IRMModifiers.sol";
import "../oracle/interfaces/IPrimeOracle.sol";

contract IRM is IIRM, IRMModifiers {

    function initialize(
        uint256 borrowInterestRatePerYear,
        uint8  _borrowInterestRateDecimals,
        uint256 _basisPointsTickSizePerYear,
        uint256 _basisPointsUpperTickPerYear,
        uint256 _pusdLowerTargetPrice,
        uint256 _pusdUpperTargetPrice,
        uint256 _blocksPerYear,
        address _primeOracle
    ) external onlyOwner() {
        primeOracle = IPrimeOracle(_primeOracle);
        blocksPerYear = _blocksPerYear;
        borrowInterestRatePerBlock = borrowInterestRatePerYear / blocksPerYear;
        borrowInterestRateDecimals = _borrowInterestRateDecimals;
        basisPointsTickSize = _basisPointsTickSizePerYear / blocksPerYear;
        basisPointsUpperTick = _basisPointsUpperTickPerYear / blocksPerYear;
        basisPointsLowerTick = 0;
        pusdLowerTargetPrice = _pusdLowerTargetPrice;
        pusdUpperTargetPrice = _pusdUpperTargetPrice;
        observationPeriod = 0;
    }

    function getBorrowRateDecimals() external view returns (uint8){
        return borrowInterestRateDecimals;
    }

    /**
    * @notice Calculates the current borrow interest rate per block
    * @return The borrow rate per block (as a percentage, and scaled by 1e18)
    */
    function getBorrowRate() external view returns (uint256) {
        return borrowInterestRatePerBlock;
    }

    function getBasisPointsTickSize() external view returns (uint256) {
        return basisPointsTickSize;
    }

    function getBasisPointsUpperTick() external view returns (uint256) {
        return basisPointsUpperTick;
    }

    function getBasisPointsLowerTick() external view returns (uint256) {
        return basisPointsLowerTick;
    }

    function getPusdLowerTargetPrice() external view returns (uint256) {
        return pusdLowerTargetPrice;
    }

    function getPusdUpperTargetPrice() external view returns (uint256) {
        return pusdUpperTargetPrice;
    }

    // FIXME: Failures when onlyOwner() is uncommented: https://primeprotocol.atlassian.net/browse/PC-318
    function setBorrowRate() external /* onlyOwner() */ returns (uint256) {
        uint256 elapsedTime = block.timestamp - lastObservationTimestamp;

        if (elapsedTime <= observationPeriod) {
            return borrowInterestRatePerBlock;
        }

        uint256 priorBorrowInterestRatePerBlock = borrowInterestRatePerBlock;
        (uint256 pusdPrice, ) = primeOracle.getPusdPrice();
        if (pusdPrice > pusdUpperTargetPrice) {
            if (borrowInterestRatePerBlock < basisPointsUpperTick) {
                borrowInterestRatePerBlock -= basisPointsTickSize;
            }
        }
        else if (pusdPrice < pusdLowerTargetPrice) {
            if (borrowInterestRatePerBlock * blocksPerYear >= basisPointsTickSize) {
                borrowInterestRatePerBlock += basisPointsTickSize;
            }
        }

        lastObservationTimestamp = block.timestamp;
        return priorBorrowInterestRatePerBlock;
    }

    function setBasisPointsTickSize(
        uint256 newBasisPointsTickSize
    ) external onlyOwner() returns (uint256) {
        basisPointsTickSize = newBasisPointsTickSize;
        return basisPointsTickSize;
    }

    function setBasisPointsUpperTick(
        uint256 newBasisPointsUpperTick
    ) external onlyOwner() returns (uint256) {
        basisPointsUpperTick = newBasisPointsUpperTick;
        return basisPointsUpperTick;
    }

    function setBasisPointsLowerTick(
      uint256 newBasisPointsLowerTick
    ) external onlyOwner() returns (uint256) {
        basisPointsLowerTick = newBasisPointsLowerTick;
        return basisPointsLowerTick;
    }

    function setPusdLowerTargetPrice(
        uint256 newPusdLowerTargetPrice
    ) external onlyOwner() returns (uint256) {
        pusdLowerTargetPrice = newPusdLowerTargetPrice;
        return pusdLowerTargetPrice;
    }

    function setPusdUpperTargetPrice(
        uint256 newPusdUpperTargetPrice
    ) external onlyOwner() returns (uint256) {
        pusdUpperTargetPrice = newPusdUpperTargetPrice;
        return pusdUpperTargetPrice;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IRMStorage.sol";

abstract contract IRMModifiers is IRMStorage {
    modifier onlyOwner() {
        require(msg.sender == admin, "ONLY_OWNER");
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../oracle/interfaces/IPrimeOracle.sol";

abstract contract IRMStorage {
    
    address public admin;

    IPrimeOracle public primeOracle;

    uint256 public borrowInterestRatePerBlock;
    uint8   public borrowInterestRateDecimals;
    uint256 public basisPointsTickSize;
    uint256 public basisPointsUpperTick;
    uint256 public basisPointsLowerTick;
    uint256 public pusdLowerTargetPrice;
    uint256 public pusdUpperTargetPrice;
    uint256 public lastObservationTimestamp;
    uint256 public observationPeriod;
    uint256 public blocksPerYear;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../oracle/interfaces/IPrimeOracle.sol";
import "../oracle/interfaces/IPrimeOracleGetter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainlinkFeedGetter is IPrimeOracleGetter {

    // Map of asset price feeds (asset => priceSource)
    mapping(uint256 => mapping(address => AggregatorV3Interface)) private assetFeeds;

    //TODO: allow transfer of ownership
    address public admin;

    /**
    * @dev Only the admin can call functions marked by this modifier.
    **/
    modifier onlyAdmin {
        require(msg.sender == admin, "Unauthorized use of function");
        _;
    }

    /// @notice constructor
    /// @param assets list of addresses of the assets
    /// @param feeds The address of the feed of each asset
    constructor(
        uint256[] memory chainIds,
        address[] memory assets,
        address[] memory feeds
    ) {
        admin = msg.sender;
        if (chainIds.length == 0 || assets.length == 0 || feeds.length == 0) return;
        _setAssetFeeds(chainIds, assets, feeds);
    }

    /// @inheritdoc IPrimeOracleGetter
    function getAssetPrice(uint256 chainId, address asset, address) external view override returns (uint256) {
        AggregatorV3Interface feed = assetFeeds[chainId][asset];
        if (address(feed) != address(0)) {
            (, int256 answer, , , ) = feed.latestRoundData();
            return uint256(answer);
        }
        return 0;
    }

    function getPriceDecimals(uint256 chainId, address asset, address) external view override returns (uint256) {
        AggregatorV3Interface feed = assetFeeds[chainId][asset];
        if (address(feed) != address(0)) {
            return feed.decimals();
        }
        return 0;
    }

    function _getAssetFeed(uint256 chainId, address asset) internal view returns (address){
        return address(assetFeeds[chainId][asset]);
    }

    function getAssetFeed(uint256 chainId, address asset) external view override returns (address)
    {
        return _getAssetFeed(chainId, asset);
    }

    /// @inheritdoc IPrimeOracleGetter
    function setAssetFeeds(uint256[] calldata chainIds, address[] calldata assets, address[] calldata feeds)
        external
        override
        onlyAdmin()
    {
        _setAssetFeeds(chainIds, assets, feeds);
    }

    /**
    * @notice Internal function to set the feeds for each asset
    * @param assets The addresses of the assets
    * @param feeds The address of the feed of each asset
    */
    function _setAssetFeeds(uint256[] memory chainIds, address[] memory assets, address[] memory feeds) internal {
        require(chainIds.length == assets.length && assets.length == feeds.length, "ERROR: Length mismatch between 'assets' and 'feeds'");
        // slither-disable-next-line uninitialized-local
        for (uint256 i; i < assets.length; i++) {
            assetFeeds[chainIds[i]][assets[i]] = AggregatorV3Interface(feeds[i]);
            emit AssetFeedUpdated(chainIds[i], assets[i], feeds[i]);
        }
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IMaster.sol";
import "./MasterEvents.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./irm/IRMStorage.sol";

abstract contract MasterInternals is IMaster, MasterEvents {
    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return (error code, the calculated balance or 0 if error code is non-zero)
     */
    function _borrowBalanceStored(
        address account
    ) internal view virtual override returns (uint256, uint256) {
        /* Note: we do not assert that the market is up to date */

        BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

        /* If borrowBalance = 0 then borrowIndex is likely also 0.
        * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
        */
        if (borrowSnapshot.principal == 0) {
            return (0, 0);
        }

        /* Calculate new borrow balance using the interest index:
        *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
        */
        uint256 principalTimesIndex = borrowSnapshot.principal * borrowIndex;
        uint256 result = principalTimesIndex / borrowSnapshot.interestIndex;

        return (result, borrowSnapshot.principal);
    }

    function _accrueInterest() internal virtual override {
        if (accrualBlockNumber != block.number) {
            uint256 accrualBlockNumberPrior = accrualBlockNumber;
            uint256 borrowIndexPrior = borrowIndex;
            uint256 reservesPrior = totalReserves;
            uint256 borrowsPrior = totalBorrows;

            uint256 borrowRatePrior = interestRateModel.setBorrowRate();

            require(block.number >= accrualBlockNumberPrior, "Cannot calculate data");

            uint256 blockDelta = block.number - accrualBlockNumberPrior;

            uint256 simpleInterestFactor = borrowRatePrior * blockDelta;

            uint8 normalizeFactor = IRMStorage(address(interestRateModel)).borrowInterestRateDecimals();

            uint256 interestAccumulated = (simpleInterestFactor * borrowsPrior) /
                10**normalizeFactor;

            uint256 totalBorrowsNew = interestAccumulated + borrowsPrior;

            uint256 borrowIndexNew = (simpleInterestFactor * borrowIndexPrior) /
                10**normalizeFactor + borrowIndexPrior;

            uint256 totalReservesNew = (reserveFactor * interestAccumulated) /
                10**normalizeFactor + reservesPrior;

            /////////////////////////
            // EFFECTS & INTERACTIONS
            // (No safe failures beyond this point)

            accrualBlockNumber = block.number;
            borrowIndex = borrowIndexNew;
            totalBorrows = totalBorrowsNew;
            totalReserves = totalReservesNew;
            // emit AccrueInterest(interestAccumulated, borrowIndexNew, totalBorrowsNew);
        }
    }

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param token The market to enter
     * @param chainId The chainId
     * @param borrower The address of the account to modify
     */
    // slither-disable-next-line low-level-calls
    function _addToMarket(
        address token,
        uint256 chainId,
        address borrower
    ) internal virtual override returns (bool) {
        if (markets[chainId][token].accountMembership[borrower]) {
            return true;
        }

        if (!markets[chainId][token].isListed) {
            return false;
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if an account is in a particular market
        markets[chainId][token].accountMembership[borrower] = true;

        CollateralMarket memory market = CollateralMarket({
            token: token,
            chainId: chainId,
            decimals: markets[chainId][token].decimals
        });

        accountAssets[borrower].push(market);

        emit MarketEntered(market.chainId, market.token, borrower);

        return true;
    }

    /*
    * @notice Removes asset from sender's account liquidity calculation
    * @dev Sender must not be providing necessary collateral for an outstanding borrow.
    * @param pTokenAddress The address of the asset to be removed
    */
    function _exitMarket(uint256 chainId, address token, address user) internal override returns (bool) {
        /* Get sender tokensHeld and amountOwed underlying from the pToken */

        /* Fail if the sender is not permitted to redeem all of their tokens */
        Market storage marketToExit = markets[chainId][token];

        /* Return true if the sender is not already ‘in’ the market */
        if (!marketToExit.accountMembership[user]) {
            return true;
        }

        /* Set pToken account membership to false */
        delete marketToExit.accountMembership[user];

        /* Delete pToken from the account’s list of assets */
        // load into memory for faster iteration
        CollateralMarket[] memory userAssetList = accountAssets[user];
        uint256 len = userAssetList.length;
        uint256 assetIndex = len;
        for (uint256 i = 0; i < len; i++) {
            if (userAssetList[i].token == token && userAssetList[i].chainId == chainId) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken - TODO: can this never be reached?
        require(assetIndex < len, "ASSET_NOT_FOUND");

        // copy last item in list to location of item to be removed, reduce length by 1
        CollateralMarket[] storage storedList = accountAssets[user];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.pop();

        emit MarketExited(chainId, token, user);

        return true;
    }


    /**
     * @notice Get a snapshot of the account's balance, and the cached exchange rate
     * @dev This is used by risk engine to more efficiently perform liquidity checks.
     * @param user Address of the account to snapshot
     * @param chainId metadata of the ptoken
     * @param token metadata of the ptoken
     * @return (possible error, token balance, exchange rate)
     */
    function _getAccountSnapshot(
        address user,
        uint256 chainId,
        address token
    ) internal view virtual override returns (uint256, uint256) {
        uint256 pTokenBalance = collateralBalances[chainId][user][token];
        uint256 exchangeRate = markets[chainId][token].initialExchangeRate;
        return (pTokenBalance, exchangeRate);
    }

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `pTokenBalance` is the number of pTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint256 sumCollateral;
        uint256 sumBorrowPlusEffects;
        uint256 pTokenBalance;
        uint256 borrowBalance;
        uint256 collateralFactor;
        uint256 exchangeRate;
        uint256 oraclePrice;
        uint256 oracleDecimals;
        uint256 tokensToDenom;
    }

    function _getHypotheticalAccountLiquidity(
        address account,
        address pTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) internal virtual override returns (uint256, uint256) {
        AccountLiquidityLocalVars memory vars; // Holds all our calculation results

        //add in the existing borrow
        (vars.sumBorrowPlusEffects, ) = _borrowBalanceStored(account);
        // For each asset the account is in
        CollateralMarket[] memory assets = accountAssets[account];

        require(assets.length > 0, "no account assets");

        // slither-disable-next-line uninitialized-local
        for (uint256 i; i < assets.length; i++) {
            CollateralMarket memory asset = assets[i];

            // Read the balances and exchange rate from the pToken
            (vars.pTokenBalance, vars.exchangeRate) = _getAccountSnapshot(
                account,
                asset.chainId,
                asset.token
            );

            // Unlike prime protocol, getUnderlyingPrice is relatively expensive because we use ChainLink as our primary price feed.
            // If user has no supply / borrow balance on this asset, and user is not redeeming / borrowing this asset, skip it.
            // slither-disable-next-line incorrect-equality
            if (vars.pTokenBalance == 0) {
                continue;
            }

            uint256 precision = markets[asset.chainId][asset.token].decimals;

	        uint256 multiplier = 10**precision;

            // TODO: Logic check this - want borrow/redeem operations to get LTV ratio based on PUSD, otherwise, want liquidations to not be affected
            // Liquidate: getAbsMaxLtvRatio - don't want to liquidate based on PUSD price
            if (borrowAmount == 0 && redeemTokens == 0) {
                vars.collateralFactor = collateralRatioModel.getAbsMaxLtvRatio(asset.chainId, IPToken(asset.token)); // liquidate
            } else if (markets[asset.chainId][asset.token].isPaused && borrowAmount > 0) { // if borrow and market paused, do not count towards acc liquidity
                continue;
            } else { // borrow/redeem
                vars.collateralFactor = collateralRatioModel.getCurrentMaxLtvRatio(asset.chainId, IPToken(asset.token)); 
            }

            // TODO: using hard coded price of 1, FIX THIS
            (vars.oraclePrice, vars.oracleDecimals) = oracle.getUnderlyingPrice(asset.chainId, asset.token);
            
            require(vars.oraclePrice != 0, "PRICE_ERROR");

            // Pre-compute a conversion factor from tokens -> usp (should be 10e18)
            vars.tokensToDenom = ((vars.collateralFactor * vars.exchangeRate) / 10**factorDecimals);
            vars.tokensToDenom = (vars.tokensToDenom * vars.oraclePrice) / 10**vars.oracleDecimals;

            // sumCollateral += tokensToDenom * pTokenBalance
            vars.sumCollateral =
                (vars.tokensToDenom * vars.pTokenBalance) /
                multiplier +
                vars.sumCollateral;

            if (asset.token == pTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects += (vars.tokensToDenom * redeemTokens) /
                    multiplier; /* normalize */
            }
        }

        // //get the multiplier and the oracle price from the loanAgent
        // // Read the balances and exchange rate from the pToken
        // (vars.pTokenBalance, vars.exchangeRate) = asset.getAccountSnapshot(
        //   account
        // );
        // // sumBorrowPlusEffects += oraclePrice * borrowBalance

        // borrow effect
        // sumBorrowPlusEffects += oraclePrice * borrowAmount
        vars.sumBorrowPlusEffects += borrowAmount;

        emit AccountLiquidity(vars.sumCollateral, vars.sumBorrowPlusEffects);

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    function _liquidateCalculateSeizeTokens(
        address pTokenCollateral,
        uint256 chainId,
        uint256 actualRepayAmount
    ) internal view virtual override returns (uint256) {
        /* TODO: Read oracle prices for borrowed and collateral markets */
        // PUSD Price
        uint8 pusdDecimals = ERC20(pusd).decimals();
        uint256 priceBorrowed = 10**pusdDecimals;
        
        (uint256 priceCollateral, ) = oracle.getUnderlyingPrice(chainId, pTokenCollateral);
        require(priceCollateral > 0 && priceBorrowed > 0, "PRICE_FETCH");

        uint8  pTokenDecimals = markets[chainId][pTokenCollateral].decimals;

        uint256 pusdMultiplier = 10**pusdDecimals;
        uint256 pTokenMultiplier = 10**pTokenDecimals;
        uint256 exchangeRate = markets[chainId][pTokenCollateral].initialExchangeRate;
        uint256 incentive;
        //      liquidityIncentive, and CollateralFactor should be customized for each market
        if(pusdDecimals >= factorDecimals){
            incentive = liquidityIncentive*10**(pusdDecimals - factorDecimals);
        }
        else{
            incentive = liquidityIncentive/10**(factorDecimals - pusdDecimals);
        }

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        uint256 seizeTokensInPusd = (actualRepayAmount *
            (pusdMultiplier + incentive) *
            priceBorrowed) / (pusdMultiplier**2);
        uint256 pTokenExchangeRate = priceCollateral * pusdMultiplier / priceBorrowed;
        uint256 seizeTokens = seizeTokensInPusd * pTokenExchangeRate / pusdMultiplier;
        return seizeTokens;
    }

    function _liquidateBorrowAllowed(
        address pTokenCollateral,
        address borrower,
        uint256 chainId,
        uint256 repayAmount
    ) internal virtual override returns (bool) {
        if (!markets[chainId][pTokenCollateral].isListed) {
            return false;
        }
        /* The borrower must have shortfall in order to be liquidatable */
        (, uint256 shortfall) = _getHypotheticalAccountLiquidity(
            borrower,
            address(0),
            0,
            0
        );

        // slither-disable-next-line incorrect-equality
        if (shortfall == 0) {
            return false;
        }

        /* The liquidator may not repay more than what is allowed by the closeFactor */
        (uint256 borrowBalance, ) = _borrowBalanceStored(borrower);

        uint256 maxClose = (closeFactor * borrowBalance) / 10**factorDecimals;

        if (repayAmount > maxClose) {
            return false;
        }

        return true;
    }

    struct RepayBorrowLocalVars {
        uint256 repayAmount;
        uint256 borrowerIndex;
        uint256 accountBorrows;
        uint256 accountBorrowsNew;
        uint256 totalBorrowsNew;
        uint256 actualRepayAmount;
    }

    function _repayBorrowFresh(
        address borrower,
        uint256 repayAmount /*override*/
    ) internal virtual returns (uint256) {
        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != block.number) revert("REPAY_BORROW_FRESHNESS_CHECK");

        // slither-disable-next-line uninitialized-local
        RepayBorrowLocalVars memory vars;

        /* We remember the original borrowerIndex for verification purposes */
        vars.borrowerIndex = accountBorrows[borrower].interestIndex;

        /* We fetch the amount the borrower owes, with accumulated interest */
        (vars.accountBorrows, ) = _borrowBalanceStored(borrower);

        /* If repayAmount == -1, repayAmount = accountBorrows */
        // As of Solidity v0.8 Explicit conversions between literals and an integer type T are only allowed if the literal lies between type(T).min and type(T).max. In particular, replace usages of uint(-1) with type(uint).max.
        // type(uint).max
        vars.actualRepayAmount = repayAmount == type(uint256).max
            ? vars.accountBorrows
            : repayAmount;

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We call doTransferIn for the payer and the repayAmount
         *  Note: The pToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the pToken holds an additional repayAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *   it returns the amount actually transferred, in case of a fee.
         */
        // vars.actualRepayAmount = doTransferIn(payer, vars.repayAmount);
        // TODO: Handle this in lz call
        // PUSDAddress.burnFrom(/*msg.sender*/ -> payer, vars.repayAmount); // burn the pusd

        // vars.actualRepayAmount = vars.repayAmount;

        /*
         * We calculate the new borrower and total borrow balances, failing on underflow:
         *  accountBorrowsNew = accountBorrows - actualRepayAmount
         *  totalBorrowsNew = totalBorrows - actualRepayAmount
         */
        require(
            vars.accountBorrows >= vars.actualRepayAmount,
            "REPAY_GT_BORROWS"
        );
        // ! This case should be impossible if the above check passes
        require(totalBorrows >= vars.actualRepayAmount, "REPAY_GT_TBORROWS");

        vars.accountBorrowsNew = vars.accountBorrows - vars.actualRepayAmount;
        vars.totalBorrowsNew = totalBorrows - vars.actualRepayAmount;

        accountBorrows[borrower].principal = vars.accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = vars.totalBorrowsNew;

        /* We emit a RepayBorrow event */
        // emit RepayBorrow(
        //     payer,
        //     borrower,
        //     vars.actualRepayAmount,
        //     vars.accountBorrowsNew,
        //     vars.totalBorrowsNew
        // );

        return vars.actualRepayAmount;
    }

    function _seizeAllowed() internal virtual returns (bool) {
        // return seizeGuardianPaused;
    }

    function _liquidateBorrow(
        address pTokenCollateral,
        address borrower,
        uint256 chainId,
        uint256 repayAmount
    ) internal virtual override returns (bool) {
        /* Fail if liquidate not allowed */
        require(
            _liquidateBorrowAllowed(
                pTokenCollateral,
                borrower,
                chainId,
                repayAmount
            ),
            "LIQUIDATE_RISKENGINE_REJECTION"
        );

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != block.number) revert("LIQUIDATE_FRESHNESS_CHECK");

        /* Fail if borrower = liquidator */
        // ? Using msg.sender here is more optimal than using a local var
        // ? that is in every case assigned to msg.sender
        require(borrower != msg.sender, "LIQUIDATE_LIQUIDATOR_IS_BORROWER");

        /* Fail if repayAmount = 0 */
        require(repayAmount > 0, "LIQUIDATE_CLOSE_AMOUNT_IS_ZERO");

        /* Fail if repayAmount = -1 */
        // NOTE: What case is this check covering?
        // require(repayAmount != type(uint128).max, "INVALID_CLOSE_AMOUNT_REQUESTED | LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX");

        // Fail if repayBorrow fails
        uint256 actualRepayAmount = _repayBorrowFresh(
            // msg.sender, // ! payer value unused in function call
            borrower,
            repayAmount
        );

        uint256 protocolSeizeShareAmount = (actualRepayAmount * protocolSeizeShare)/(10**factorDecimals);

        // We calculate the number of collateral tokens that will be seized
        uint256 seizeTokens = _liquidateCalculateSeizeTokens(
            pTokenCollateral,
            chainId,
            actualRepayAmount - protocolSeizeShareAmount
        );

        uint256 collateralBalance = collateralBalances[chainId][borrower][pTokenCollateral];

        // Revert if borrower collateral token balance < seizeTokens
        require(
            collateralBalance >= seizeTokens,
            "LIQUIDATE_SEIZE_TOO_MUCH"
        );

        accountBorrows[borrower].principal += protocolSeizeShareAmount;
        collateralBalances[chainId][borrower][pTokenCollateral] = collateralBalance - seizeTokens;
        collateralBalances[chainId][msg.sender][pTokenCollateral] += seizeTokens;
        markets[chainId][pTokenCollateral].totalSupply -= seizeTokens;
        totalReserves += protocolSeizeShareAmount;

        ERC20Burnable(pusd).burnFrom(msg.sender, actualRepayAmount);

        // ! If this call fails on satellite we accept a fallback call
        // ! to revert above state changes
        satelliteLiquidateBorrow(
            chainId,
            borrower,
            msg.sender,
            seizeTokens,
            pTokenCollateral
        );

        /* We emit a LiquidateBorrow event */
        // emit LiquidateBorrow(
        //     msg.sender,
        //     borrower,
        //     actualRepayAmount,
        //     address(pTokenCollateral),
        //     seizeTokens
        // );

        return true;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../MasterStorage.sol";

abstract contract IMasterState is MasterStorage {

    function borrowBalanceStored(
        address account
    ) external virtual returns (uint256, uint256);

    function accrueInterest() external virtual;

    function enterMarkets(
        address[] calldata tokens,
        uint256[] calldata chainIds
    ) external virtual returns (bool[] memory r);

    function exitMarkets(
        uint256[] calldata chainIds, 
        address[] calldata tokens
    ) external virtual returns (bool[] memory successes);

    function getAccountAssets(
        address accountAddress
    ) external virtual returns (CollateralMarket[] memory);

    function getAccountLiquidity(
        address account
    ) external virtual returns (uint256, uint256);

    function liquidateCalculateSeizeTokens(
        address pTokenCollateral,
        uint256 chainId,
        uint256 actualRepayAmount
    ) external virtual returns (uint256);

    function liquidateBorrowAllowed(
        address pTokenCollateral,
        address borrower,
        uint256 chainId,
        uint256 repayAmount
    ) external virtual returns (bool);

    function liquidateBorrow(
        address pTokenCollateral,
        address borrower,
        uint256 chainId,
        uint256 repayAmount
    ) external virtual payable returns (bool);

    function addChain(uint256 chainId) external virtual;

    function changeOwner(address newOwner) external virtual;

    function changeMiddleLayer(
        IMiddleLayer oldMid,
        IMiddleLayer newMid
    ) external virtual;

    /**
     * @notice Add the market to the markets mapping and set it as listed
     * @dev Admin function to set isListed and add support for the market
     * @param token The address of the market (token) to list
     * @param chainId corresponding chain of the market
     */
    function supportMarket(
        address token,
        uint256 chainId,
        uint256 initialExchangeRate_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address underlying_
    ) external virtual;

    function changeLiqIncentive(uint256 newLiqIncentive) external virtual;

    function pauseMarket(uint256 chainId, address token, bool pause) external virtual;

    function changeCloseFactor(uint256 newCloseFactor) external virtual;

    function changeFactorDecimals(uint8 newFactorDecimals) external virtual;

    function changeProtocolSeizeShare(uint256 newProtocolSeizeShare) external virtual;

    function setPUSD(address newPUSD) external virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MasterModifiers.sol";
import "./MasterEvents.sol";
import "./interfaces/IMaster.sol";
import "./interfaces/IMasterState.sol";

abstract contract MasterAdmin is IMaster, IMasterState, MasterModifiers, MasterEvents {
    function addChain(uint256 chainId) external override onlyOwner() {
        chains.push(chainId);

        emit AddChain(chainId);
    }

    function changeOwner(address newOwner) external override onlyOwner() {
        require(newOwner != address(0), "NON_ZEROADDRESS");
        admin = newOwner;

        emit ChangeOwner(newOwner);
    }

    function changeMiddleLayer(
        IMiddleLayer oldMid,
        IMiddleLayer newMid
    ) external override onlyOwner() {
        require(middleLayer == oldMid, "INVALID_MIDDLE_LAYER");
        middleLayer = newMid;

        emit ChangeMiddleLayer(address(oldMid), address(newMid));
    }

    /**
     * @notice Add the market to the markets mapping and set it as listed
     * @dev Admin function to set isListed and add support for the market
     * @param token The address of the market (token) to list
     * @param chainId corresponding chain of the market
     */
    function supportMarket(
        address token,
        uint256 chainId,
        uint256 initialExchangeRate_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address underlying_
    ) external override onlyOwner() {
        require(!markets[chainId][token].isListed, "SUPPORT_MARKET_EXISTS");

        markets[chainId][token].isListed = true;
        markets[chainId][token].initialExchangeRate = initialExchangeRate_;
        markets[chainId][token].name = name_;
        markets[chainId][token].symbol = symbol_;
        markets[chainId][token].decimals = decimals_;
        markets[chainId][token].underlying = underlying_;

        // slither-disable-next-line uninitialized-local
        for (uint256 i; i < allMarkets.length; i++) {
            require(
                allMarkets[i].token != token ||
                    allMarkets[i].chainId != chainId,
                "MARKET_EXISTS"
            );
        }
        CollateralMarket memory market = CollateralMarket({
            token: token,
            chainId: chainId,
            decimals: decimals_
        });

        allMarkets.push(market);

        emit MarketListed(token);
    }

    function pauseMarket(uint256 chainId, address token, bool pause) external override onlyOwner() {
        markets[chainId][token].isPaused = pause;

        emit MarketPaused(chainId, token, pause);
    }

    function changeLiqIncentive(uint256 newLiqIncentive) external override onlyOwner() {
        liquidityIncentive = newLiqIncentive;

        emit ChangeLiqIncentive(newLiqIncentive);
    }

    function changeCloseFactor(uint256 newCloseFactor) external override onlyOwner() {
        closeFactor = newCloseFactor;

        emit ChangeCloseFactor(newCloseFactor);
    }

    function changeFactorDecimals(uint8 newFactorDecimals) external override onlyOwner() {
        factorDecimals = newFactorDecimals;

        emit ChangeFactorDecimals(newFactorDecimals);
    }

    function changeProtocolSeizeShare(uint256 newProtocolSeizeShare)
        external
        override
        onlyOwner()
    {
        protocolSeizeShare = newProtocolSeizeShare;

        emit ChangeProtocolSeizeShare(newProtocolSeizeShare);
    }

    function setPUSD(address newPUSD) external override onlyOwner() {
        require(newPUSD != address(0), "NON_ZEROADDRESS");
        pusd = newPUSD;

        emit SetPUSD(newPUSD);
    }

    function setReserveFactor(uint256 newFactor) external onlyOwner() {
        reserveFactor = newFactor;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IMaster.sol";
import "./interfaces/IMasterState.sol";
import "./MasterEvents.sol";
import "./MasterAdmin.sol";
import "./MasterMessageHandler.sol";
import "./MasterInternals.sol";

contract MasterState is
    IMaster,
    IMasterState,
    MasterEvents,
    MasterAdmin,
    MasterMessageHandler,
    MasterInternals
{

    function initialize(address middleLayerAddress, address eccAddress, address crmAddress, address irmAddress, address primeOracle) external onlyOwner() {
        middleLayer = IMiddleLayer(middleLayerAddress);
        ecc = IECC(eccAddress);
        borrowIndex = 1e18;
        accrualBlockNumber = block.number;
        collateralRatioModel = ICRM(crmAddress);
        interestRateModel = IIRM(irmAddress);
        oracle = IPrimeOracle(primeOracle);
    }

    function borrowBalanceStored(
        address account
    ) external override view returns (uint256, uint256) {
        return _borrowBalanceStored(account);
    }

    function accrueInterest() external override {
        _accrueInterest();
    }

    function enterMarkets(address[] calldata tokens, uint256[] calldata chainIds)
        public
        override
        returns (bool[] memory r)
    {
        uint256 tokensLen = tokens.length;
        uint256 chainIdLen = chainIds.length;

        require(tokensLen == chainIdLen, "ARRAY_LENGTH");

        r = new bool[](tokensLen);
        for (uint256 i = 0; i < tokensLen; i++) {
            address token = tokens[i];
            uint256 chainId = chainIds[i];
            r[i] = _addToMarket(token, chainId, msg.sender);
        }
    }

    function exitMarkets(
        uint256[] calldata chainIds, 
        address[] calldata tokens
    ) external override returns (bool[] memory successes) 
    {

        uint256 tokensLen = tokens.length;
        uint256 chainIdLen = chainIds.length;

        require(tokensLen == chainIdLen, "ARRAY_LENGTH");

        successes = new bool[](tokensLen);
        for (uint256 i = 0; i < tokensLen; i++) {
            address token = tokens[i];
            uint256 chainId = chainIds[i];
            successes[i] = _exitMarket(chainId, token, msg.sender);
        }
    }

    function getAccountAssets(address accountAddress)
        external
        view
        override
        returns (CollateralMarket[] memory)
    {
        return accountAssets[accountAddress];
    }

    function getAccountLiquidity(address account)
        external
        override
        returns (uint256, uint256)
    {

        return _getHypotheticalAccountLiquidity(account, address(0), 0, 0);
    }

    function liquidateCalculateSeizeTokens(
        address pTokenCollateral,
        uint256 chainId,
        uint256 actualRepayAmount
    ) external override returns (uint256) {
        return
            _liquidateCalculateSeizeTokens(
                pTokenCollateral,
                chainId,
                actualRepayAmount
            );
    }

    function liquidateBorrowAllowed(
        address pTokenCollateral,
        address borrower,
        uint256 chainId,
        uint256 repayAmount
    ) external override returns (bool) {
        return
            _liquidateBorrowAllowed(
                pTokenCollateral,
                borrower,
                chainId,
                repayAmount
            );
    }

    function liquidateBorrow(
        address pTokenCollateral,
        address borrower,
        uint256 chainId,
        uint256 repayAmount
    ) external override payable returns (bool) {
        _accrueInterest();

        return _liquidateBorrow(pTokenCollateral, borrower, chainId, repayAmount);
    }
}

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "../../master/MasterState.sol";
import "../../master/MasterAdmin.sol";
import "../../master/interfaces/IMasterState.sol";
import "../../master/MasterStorage.sol";
import "../interfaces/IDelegator.sol";
import "./events/MasterStateDelegatorEvents.sol";

contract MasterStateDelegator is
    MasterStorage,
    IMasterState,
    MasterStateDelegatorEvents,
    IDelegator
{

    constructor(
        address _delegateeAddress,
        address newMiddleLayer,
        address eccAddress,
        address crmAddress,
        address irmAddress,
        address oracleAddress
    ) {
        admin = delegatorAdmin = payable(msg.sender);

        setDelegateeAddress(_delegateeAddress);

        _delegatecall(abi.encodeWithSelector(
            MasterState.initialize.selector,
            newMiddleLayer,
            eccAddress,
            crmAddress,
            irmAddress,
            oracleAddress
        ));
    }

    function borrowBalanceStored(
        address account
    ) external view override returns (uint256 totalBorrowBalance, uint256 principal) {
        bytes memory data = _staticcall(abi.encodeWithSelector(
            MasterState.borrowBalanceStored.selector,
            account
        ));

        (totalBorrowBalance, principal) = abi.decode(data, (uint256, uint256));
    }

    function accrueInterest() external override {
        _delegatecall(abi.encodeWithSelector(
            MasterState.accrueInterest.selector
        ));
    }

    function enterMarkets(
        address[] calldata tokens,
        uint256[] calldata chainIds
    ) external override returns (bool[] memory successes) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            MasterState.enterMarkets.selector,
            tokens,
            chainIds
        ));

        (successes) = abi.decode(data, (bool[]));

        emit EnterMarkets(successes);
    }

    function exitMarkets(
        uint256[] calldata chainIds, 
        address[] calldata tokens
    ) external override returns (bool[] memory successes) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            MasterState.exitMarkets.selector,
            chainIds,
            tokens
        ));

        (successes) = abi.decode(data, (bool[]));
    }

    function getAccountAssets(
        address accountAddress
    ) external view override returns (CollateralMarket[] memory collateralMarkets) {
        bytes memory data = _staticcall(abi.encodeWithSelector(
            MasterState.getAccountAssets.selector,
            accountAddress
        ));

        (collateralMarkets) = abi.decode(data, (CollateralMarket[]));
    }

    function getAccountLiquidity(
        address account
    ) external override returns (uint256 liquidity, uint256 shortfall) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            MasterState.getAccountLiquidity.selector,
            account
        ));

        (liquidity, shortfall) = abi.decode(data, (uint256, uint256));
    }

    function liquidateCalculateSeizeTokens(
        address pTokenCollateral,
        uint256 chainId,
        uint256 actualRepayAmount
    ) external override returns (uint256 amount) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            MasterState.liquidateCalculateSeizeTokens.selector,
            pTokenCollateral,
            chainId,
            actualRepayAmount
        ));

        (amount) = abi.decode(data, (uint256));
    }

    function liquidateBorrowAllowed(
        address pTokenCollateral,
        address borrower,
        uint256 chainId,
        uint256 repayAmount
    ) external override returns (bool success) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            MasterState.liquidateBorrowAllowed.selector,
            pTokenCollateral,
            borrower,
            chainId,
            repayAmount
        ));
        (success) = abi.decode(data, (bool));

        emit LiquidateBorrowAllowed(success);
    }

    function liquidateBorrow(
        address pTokenCollateral,
        address borrower,
        uint256 chainId,
        uint256 repayAmount
    ) external override payable returns (bool success) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            MasterState.liquidateBorrow.selector,
            pTokenCollateral,
            borrower,
            chainId,
            repayAmount
        ));

        (success) = abi.decode(data, (bool));

        emit LiquidateBorrow(success);
    }

    function addChain(uint256 chainId) external override {
        _delegatecall(abi.encodeWithSelector(
            MasterAdmin.addChain.selector,
            chainId
        ));
    }

    function changeOwner(address newOwner) external override {
        _delegatecall(abi.encodeWithSelector(
            MasterAdmin.changeOwner.selector,
            newOwner
        ));
    }

    function changeMiddleLayer(
        IMiddleLayer oldMid,
        IMiddleLayer newMid
    ) external override {
        _delegatecall(abi.encodeWithSelector(
            MasterAdmin.changeMiddleLayer.selector,
            oldMid,
            newMid
        ));
    }

    /**
     * @notice Add the market to the markets mapping and set it as listed
     * @dev Admin function to set isListed and add support for the market
     * @param token The address of the market (token) to list
     * @param chainId corresponding chain of the market
     */
    function supportMarket(
        address token,
        uint256 chainId,
        uint256 initialExchangeRate_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address underlying_
    ) external override {
        _delegatecall(abi.encodeWithSelector(
            MasterAdmin.supportMarket.selector,
            token,
            chainId,
            initialExchangeRate_,
            name_,
            symbol_,
            decimals_,
            underlying_
        ));
    }

    function pauseMarket(uint256 chainId, address token, bool pause) external override {
        _delegatecall(abi.encodeWithSelector(
            MasterAdmin.pauseMarket.selector,
            chainId,
            token,
            pause
        ));
    }

    function changeLiqIncentive(uint256 newLiqIncentive) external override {
        _delegatecall(abi.encodeWithSelector(
            MasterAdmin.changeLiqIncentive.selector,
            newLiqIncentive
        ));
    }

    function changeCloseFactor(uint256 newCloseFactor) external override {
        _delegatecall(abi.encodeWithSelector(
            MasterAdmin.changeCloseFactor.selector,
            newCloseFactor
        ));
    }

    function changeFactorDecimals(uint8 newFactorDecimals) external override {
        _delegatecall(abi.encodeWithSelector(
            MasterAdmin.changeFactorDecimals.selector,
            newFactorDecimals
        ));
    }

    function changeProtocolSeizeShare(uint256 newProtocolSeizeShare) external override {
        _delegatecall(abi.encodeWithSelector(
            MasterAdmin.changeProtocolSeizeShare.selector,
            newProtocolSeizeShare
        ));
    }

    function setPUSD(address newPUSD) external override {
        _delegatecall(abi.encodeWithSelector(
            MasterAdmin.setPUSD.selector,
            newPUSD
        ));
    }

    // ? This is safe so long as the implmentation contract does not have any obvious
    // ? vulns around calling functions with raised permissions ie admin function callable by anyone
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

import "../../../master/MasterStorage.sol";

abstract contract MasterStateDelegatorEvents is MasterStorage {

    event BorrowBalanceStored(uint256 totalBorrowBalance, uint256 principal);
    event EnterMarkets(bool[] successes);
    event GetAccountAssets(CollateralMarket[] collateralMarkets);
    event ExchangeRateStored(uint256 rate);
    event GetAccountLiquidity(uint256 liquidity, uint256 shortfall);
    event LiquidateCalculateSeizeTokens(uint256 amount);
    event LiquidateBorrowAllowed(bool success);
    event LiquidateBorrow(bool success);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../satellite/pToken/interfaces/IPToken.sol";
import "./interfaces/ICRM.sol";

abstract contract CRMEvents {
    event CollateralRatioModelUpdated(
        uint256 chainId,
        IPToken asset,
        ICRM collateralRatioModel
    );

    event AssetLtvRatioUpdated(
        uint256 chainId,
        IPToken asset,
        uint256 ltvRatio
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./CRMStorage.sol";
import "./CRMEvents.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CRM is ICRM, CRMStorage, CRMEvents {

    modifier onlyAdmin() {
        require(msg.sender == admin, "Unauthorized use of function");
        _;
    }

    function initialize(
        address primeOracleParam,
        uint256[] memory chainIds,
        IPToken[] memory assets,
        uint256[] memory absMaxLtvRatiosParam,
        uint8 ltvRatioDecimalsParam,
        uint256 pusdPriceCeilingParam,
        uint256 pusdPriceFloorParam
    ) external onlyAdmin() {
        ICRM[] memory _collateralRatioModels = new ICRM[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
                _collateralRatioModels[i] = ICRM(this);
        }
        _setCollateralRatioModels(chainIds, assets, _collateralRatioModels);
        _setAbsMaxLtvRatios(chainIds, assets, absMaxLtvRatiosParam);
        primeOracle = IPrimeOracle(primeOracleParam);
        pusdPriceCeiling = pusdPriceCeilingParam;
        pusdPriceFloor = pusdPriceFloorParam;
        ltvRatioDecimals = ltvRatioDecimalsParam;
    }

    /* external getters */

    function getCollateralRatioModel(
        uint256 chainId, 
        IPToken asset
    ) external view override returns (address){
            return address(collateralRatioModels[chainId][asset]);
    }

    function getLtvRatioDecimals() external view override returns(uint8 decimals){
        return ltvRatioDecimals;
    }

    function getCurrentMaxLtvRatios(
        uint256[] memory chainIds, 
        IPToken[] memory assets
    ) external override returns (uint256[] memory){
            require(chainIds.length == assets.length, "ERROR: chainIds and assets are of unequal length.");
            uint256[] memory ltvRequirements = new uint256[](assets.length);
            for (uint256 i = 0; i < assets.length; i++) {
                ICRM crm = collateralRatioModels[chainIds[i]][assets[i]];
                require(address(crm) != address(0), "ERROR: CRM not found for chainId and token");
                ltvRequirements[i] = crm.getCurrentMaxLtvRatio(chainIds[i], assets[i]);
            }
            return ltvRequirements;
    }

    function getCurrentMaxLtvRatio(
        uint256 chainId,
        IPToken asset
    ) external view override returns (uint256) {
        (uint256 pusdPrice, ) = _getPusdPrice();
        if (pusdPrice >= pusdPriceCeiling) {

            return absMaxLtvRatios[chainId][asset];
        }
        else if (pusdPrice <= pusdPriceFloor) {
            return 0;
        } 
        else {
            uint256 priceDelta = pusdPrice - pusdPriceFloor;
            return (priceDelta * absMaxLtvRatios[chainId][asset]) / 1e4;
        }
    }

    function getAbsMaxLtvRatio(
        uint256 chainId,
        IPToken asset
    ) external view override returns (uint256) {
        return absMaxLtvRatios[chainId][asset];
    }

    /* external setters */

    function setPusdPriceCeiling(
        uint256 price
    ) external override onlyAdmin() returns (uint256) {
        return _setPusdPriceCeiling(price);
    }

    function setPusdPriceFloor(
        uint256 price
    ) external override onlyAdmin() returns (uint256) {
        return _setPusdPriceFloor(price);
    }

    function setAbsMaxLtvRatios(
        uint256[] memory chainIds,
        IPToken[] memory assets,
        uint256[] memory absMaxLtvRatios
    ) external override onlyAdmin() {
        _setAbsMaxLtvRatios(chainIds, assets, absMaxLtvRatios);
    }

    function setCollateralRatioModels(
        uint256[] memory chainIds,
        IPToken[] memory assets,
        ICRM[] memory collateralRatioModels
    ) external override onlyAdmin() {
        _setCollateralRatioModels(chainIds, assets, collateralRatioModels);
    }

    /* internal getters */

    //TODO: oracle integration
    function _getPusdPrice() internal view returns (uint256, uint256) {
        return primeOracle.getPusdPrice();
    }

    /* internal setters */

    function _setPusdPriceCeiling(
        uint256 price
    ) internal returns (uint256) {
        pusdPriceCeiling = price;
        return pusdPriceCeiling;
    }

    function _setPusdPriceFloor(
        uint256 price
    ) internal returns (uint256) {
        pusdPriceFloor = price;
        return pusdPriceFloor;
    }


    function _setAbsMaxLtvRatios(
        uint256[] memory chainIds,
        IPToken[] memory assets,
        uint256[] memory maxLtvRatios
    ) internal {
        require(
            assets.length == maxLtvRatios.length && assets.length == chainIds.length,
            "ERROR: Length mismatch between 'assets', 'assetLtvRatios', 'chainIds'"
        );
        for (uint256 i = 0; i < assets.length; i++) {
            absMaxLtvRatios[chainIds[i]][assets[i]] = maxLtvRatios[i];
            emit AssetLtvRatioUpdated(chainIds[i], assets[i], maxLtvRatios[i]);
        }
    }

    function _setCollateralRatioModels(
        uint256[] memory chainIds,
        IPToken[] memory assets,
        ICRM[] memory collateralModels
    ) internal {
        require(
            assets.length == collateralModels.length && assets.length == chainIds.length,
            "ERROR: Length mismatch between 'assets', 'assetLtvRatios', 'chainIds'"
        );
        for (uint256 i = 0; i < assets.length; i++) {
            collateralRatioModels[chainIds[i]][assets[i]] = collateralModels[i];
            emit CollateralRatioModelUpdated(chainIds[i], assets[i], collateralModels[i]);
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../oracle/interfaces/IPrimeOracle.sol";
import "./interfaces/ICRM.sol";

abstract contract CRMStorage {

    address public admin;

    IPrimeOracle public primeOracle;
    uint256 public pusdPriceCeiling;
    uint256 public pusdPriceFloor;

    // slither-disable-next-line unused-state
    mapping(uint256 => mapping(IPToken => ICRM)) internal collateralRatioModels;

    // slither-disable-next-line unused-state
    mapping(uint256 => mapping(IPToken => uint256)) public absMaxLtvRatios;

    uint8 internal ltvRatioDecimals;
}

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "../../master/crm/interfaces/ICRM.sol";
import "../../master/crm/CRMStorage.sol";
import "../../master/crm/CRM.sol";
import "../interfaces/IDelegator.sol";
import "./events/CRMDelegatorEvents.sol";
import "../../satellite/pToken/interfaces/IPToken.sol";

contract CRMDelegator is
    ICRM,
    CRMStorage,
    CRMDelegatorEvents,
    IDelegator
{
    constructor(
        address newDelegate,
        address primeOracleParam,
        uint256[] memory chainIds, 
        IPToken[] memory assets,
        uint256[] memory absMaxLtvRatiosParam,
        uint8 ltvRatioDecimalsParam,
        uint256 pusdPriceCeilingParam,
        uint256 pusdPriceFloorParam
    ) {
        admin = delegatorAdmin = payable(msg.sender);

        setDelegateeAddress(newDelegate);

        _delegatecall(abi.encodeWithSelector(
            CRM.initialize.selector,
            primeOracleParam,
            chainIds,
            assets,
            absMaxLtvRatiosParam,
            ltvRatioDecimalsParam,
            pusdPriceCeilingParam,
            pusdPriceFloorParam
        ));
    }

    function getLtvRatioDecimals() external view override returns (uint8 decimals) {
        bytes memory data = _staticcall(abi.encodeWithSelector(
            CRM.getLtvRatioDecimals.selector
        ));

        (decimals) = abi.decode(data, (uint8));
    }

    function getCollateralRatioModel(uint256 chainId, IPToken asset) external view override returns (address model) {
        bytes memory data = _staticcall(abi.encodeWithSelector(
            CRM.getCollateralRatioModel.selector,
            chainId,
            asset
        ));

        (model) = abi.decode(data, (address));
    }

    function getCurrentMaxLtvRatios(uint256[] memory chainIds, IPToken[] memory assets) external view returns (uint256[] memory ratios) {
        bytes memory data = _staticcall(abi.encodeWithSelector(
            CRM.getCurrentMaxLtvRatios.selector,
            chainIds,
            assets
        ));

        (ratios) = abi.decode(data, (uint256[]));
    }

    function getAbsMaxLtvRatio(uint256 chainId, IPToken asset) external view returns (uint256 ratio) {
        bytes memory data = _staticcall(abi.encodeWithSelector(
            CRM.getAbsMaxLtvRatio.selector,
            chainId,
            asset
        ));

        (ratio) = abi.decode(data, (uint256));
    }

    function getCurrentMaxLtvRatio(uint256 chainId, IPToken asset) external view returns (uint256 ratio) {
        bytes memory data = _staticcall(abi.encodeWithSelector(
            CRM.getCurrentMaxLtvRatio.selector,
            chainId,
            asset
        ));

        (ratio) = abi.decode(data, (uint256));
    }

    function setPusdPriceCeiling(uint256 price) external returns (uint256 ceiling) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            CRM.setPusdPriceCeiling.selector,
            price
        ));

        (ceiling) = abi.decode(data, (uint256));

        emit SetPusdPriceCeiling(ceiling);
    }

    function setPusdPriceFloor(uint256 price) external returns (uint256 floor) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            CRM.setPusdPriceFloor.selector,
            price
        ));

        (floor) = abi.decode(data, (uint256));

        emit SetPusdPriceFloor(floor);
    }

    function setAbsMaxLtvRatios(uint256[] memory chainIds, IPToken[] memory assets, uint256[] memory maxLtvRatios) external {
        _delegatecall(abi.encodeWithSelector(
            CRM.setAbsMaxLtvRatios.selector,
            chainIds,
            assets,
            maxLtvRatios
        ));
    }

    function setCollateralRatioModels(uint256[] memory chainIds, IPToken[] memory assets, ICRM[] memory collateralRatioModels) external {
        _delegatecall(abi.encodeWithSelector(
            CRM.setCollateralRatioModels.selector,
            chainIds,
            assets,
            collateralRatioModels
        ));
    }

    // ? This is safe so long as the implmentation contract does not have any obvious
    // ? vulns around calling functions with raised permissions ie admin function callable by anyone
    // controlled-delegatecall,low-level-calls
    // slither-disable-next-line all
    fallback() external {
        /* If a function is not defined above, we can still call it using msg.data. */
        (bool success,) = delegateeAddress.delegatecall(msg.data);

        assembly {
            let freeMemPtr := mload(0x40)
            returndatacopy(freeMemPtr, 0, returndatasize())

            switch success
            case 0 { revert(freeMemPtr, returndatasize()) }
            default { return(freeMemPtr, returndatasize()) }
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract CRMDelegatorEvents {

    event GetCollateralRatioModel(address model);
    event GetCurrentMaxLtvRatios(uint256[] ratios);
    event GetCurrentMaxLtvRatio(uint256 ratio);
    event SetPusdPriceCeiling(uint256 ceiling);
    event SetPusdPriceFloor(uint256 price);
}

//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.4;

import "../../master/irm/interfaces/IIRM.sol";
import "../../master/irm/IRMStorage.sol";
import "../../master/irm/IRM.sol";
import "../interfaces/IDelegator.sol";
import "./events/IRMDelegatorEvents.sol";

contract IRMDelegator is
    IIRM,
    IRMStorage,
    IRMDelegatorEvents,
    IDelegator
{
    constructor(
        address delegateeAddress,
        uint256 _borrowInterestRatePerYear,
        uint8   _borrowInterestRateDecimals,
        uint256 _basisPointsTickSizePerYear,
        uint256 _basisPointsUpperTickPerYear,
        uint256 _pusdLowerTargetPrice,
        uint256 _pusdUpperTargetPrice,
        uint256 _blocksPerYear,
        address _primeOracle
    ) {
        admin = delegatorAdmin = payable(msg.sender);

        setDelegateeAddress(delegateeAddress);

        _delegatecall(abi.encodeWithSelector(
            IRM.initialize.selector,
            _borrowInterestRatePerYear,
            _borrowInterestRateDecimals,
            _basisPointsTickSizePerYear,
            _basisPointsUpperTickPerYear,
            _pusdLowerTargetPrice,
            _pusdUpperTargetPrice,
            _blocksPerYear,
            _primeOracle
        ));
    }

    function getBasisPointsTickSize() external view returns (uint256 tickSize) {
        bytes memory data = _staticcall(abi.encodeWithSelector(
            IRM.getBasisPointsTickSize.selector
        ));

        (tickSize) = abi.decode(data, (uint256));
    }

    function getBasisPointsUpperTick() external view returns (uint256 tick) {
        bytes memory data = _staticcall(abi.encodeWithSelector(
            IRM.getBasisPointsUpperTick.selector
        ));

        (tick) = abi.decode(data, (uint256));
    }

    function getBasisPointsLowerTick() external view returns (uint256 tick) {
        bytes memory data = _staticcall(abi.encodeWithSelector(
            IRM.getBasisPointsLowerTick.selector
        ));

        (tick) = abi.decode(data, (uint256));
    }

    function getPusdLowerTargetPrice() external view returns (uint256 lowerPrice) {
        bytes memory data = _staticcall(abi.encodeWithSelector(
            IRM.getPusdLowerTargetPrice.selector
        ));

        (lowerPrice) = abi.decode(data, (uint256));
    }

    function getPusdUpperTargetPrice() external view returns (uint256 upperPrice) {
        bytes memory data = _staticcall(abi.encodeWithSelector(
            IRM.getPusdUpperTargetPrice.selector
        ));

        (upperPrice) = abi.decode(data, (uint256));
    }


    function setBasisPointsTickSize(uint256 price) external returns (uint256 tickSize) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            IRM.setBasisPointsTickSize.selector,
            price
        ));

        (tickSize) = abi.decode(data, (uint256));

        emit SetBasisPointsTickSize(tickSize);
    }

    function setBasisPointsUpperTick(uint256 price) external returns (uint256 tick) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            IRM.setBasisPointsUpperTick.selector,
            price
        ));

        (tick) = abi.decode(data, (uint256));

        emit SetBasisPointsUpperTick(tick);
    }

    function setBasisPointsLowerTick(uint256 lowerTick) external returns (uint256 tick) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            IRM.setBasisPointsLowerTick.selector,
            lowerTick
        ));

        (tick) = abi.decode(data, (uint256));

        emit SetBasisPointsLowerTick(tick);
    }

    function getBorrowRateDecimals() external view returns (uint8 decimals) {
        bytes memory data = _staticcall(abi.encodeWithSelector(
            IRM.getBorrowRateDecimals.selector
        ));

        (decimals) = abi.decode(data, (uint8));
    }

    function getBorrowRate() external view returns (uint256 rate) {
        bytes memory data = _staticcall(abi.encodeWithSelector(
            IRM.getBorrowRate.selector
        ));

        (rate) = abi.decode(data, (uint256));
    }

    function setBorrowRate() external override returns (uint256 rate) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            IRM.setBorrowRate.selector
        ));

        (rate) = abi.decode(data, (uint256));

        emit SetBorrowRate(rate);
    }

    function setPusdLowerTargetPrice(uint256 lowerPrice) external override returns (uint256 price) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            IRM.setPusdLowerTargetPrice.selector,
            lowerPrice
        ));

        (price) = abi.decode(data, (uint256));

        emit SetPusdLowerTargetPrice(price);
    }

    function setPusdUpperTargetPrice(uint256 upperPrice) external override returns (uint256 price) {
        bytes memory data = _delegatecall(abi.encodeWithSelector(
            IRM.setPusdUpperTargetPrice.selector,
            upperPrice
        ));

        (price) = abi.decode(data, (uint256));

        emit SetPusdUpperTargetPrice(price);
    }

    // ? This is safe so long as the implmentation contract does not have any obvious
    // ? vulns around calling functions with raised permissions ie admin function callable by anyone
    // controlled-delegatecall,low-level-calls
    // slither-disable-next-line all
        fallback() external {
        /* If a function is not defined above, we can still call it using msg.data. */
        (bool success,) = delegateeAddress.delegatecall(msg.data);

        assembly {
            let freeMemPtr := mload(0x40)
            returndatacopy(freeMemPtr, 0, returndatasize())

            switch success
            case 0 { revert(freeMemPtr, returndatasize()) }
            default { return(freeMemPtr, returndatasize()) }
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract IRMDelegatorEvents {

    event GetBasisPointsTickSize(uint256 tickSize);
    event GetBasisPointsUpperTick(uint256 tick);
    event GetBasisPointsLowerTick(uint256 tick);
    event SetBasisPointsTickSize (uint256 tickSize);
    event SetBasisPointsUpperTick (uint256 tick);
    event SetBasisPointsLowerTick(uint256 tick);
    event GetBorrowRate(uint256 rate);
    event SetBorrowRate(uint256 rate);
    event SetPusdLowerTargetPrice(uint256 lowerPrice);
    event SetPusdUpperTargetPrice(uint256 upperPrice);
}