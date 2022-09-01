//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MiddleLayerAdmin.sol";
import "../satellite/pToken/PTokenMessageHandler.sol";
import "../interfaces/IHelper.sol";
import "./interfaces/IMiddleLayer.sol";
import "../util/CommonModifiers.sol";

contract MiddleLayer is
    IMiddleLayer,
    MiddleLayerAdmin,
    CommonModifiers
{
    constructor(
        uint256 _newChainId,
        address _ecc
    ) {
        if (address(_ecc) == address(0)) revert AddressExpected();

        admin = msg.sender;
        cid = _newChainId;
        ecc = IECC(_ecc);
    }

    function msend(
        uint256 _dstChainId,
        bytes memory _params,
        address payable _refundAddress,
        address _fallbackAddress,
        bool _shouldPayGas
    ) external payable override onlyAuth() notPaused() {
        if (_refundAddress == address(0)) revert AddressExpected();

        if (cid == _dstChainId) {
            _mreceive(cid, _params, false);
            return;
        }

        bytes32 metadata = ecc.preRegMsg(_params, msg.sender);
        assembly {
            mstore(add(_params, 0x20), metadata)
        }

        emit MessageSent(
            _dstChainId,
            _params,
            _refundAddress,
            _fallbackAddress
        );

        if (_fallbackAddress == address(0)) {
            uint256 hash = uint256(keccak256(abi.encodePacked(_params, block.timestamp, _dstChainId)));
            // This prng is safe as its not logic reliant, and produces a safe output given the routing protocol that is chosen is not offline
            // slither-disable-next-line weak-prng
            routes[hash % routes.length].msend{value: msg.value}(
                _dstChainId, // destination chainId
                _params, // bytes payload
                _refundAddress, // refund address
                _shouldPayGas
            );
            return;
        }
        if (!authRoutes[_fallbackAddress]) revert RouteNotSupported(_fallbackAddress);
        IRoute(_fallbackAddress).msend{value:msg.value}(
            _dstChainId,
            _params,
            _refundAddress,
            _shouldPayGas
        );
    }

    function _checkECC(
        bool _external,
        bytes32 payloadHash,
        bytes32 metadata
    ) internal {
        if (_external) {
            if (!ecc.preProcessingValidation(
                payloadHash,
                metadata
            )) revert EccMessageAlreadyProcessed();
            if (!ecc.flagMsgValidated(
                payloadHash,
                metadata
            )) revert EccFailedToValidate();
        }
    }

    function mreceive(
        uint256 _srcChainId,
        bytes memory _payload
    ) external override onlyRoute() notPaused() {
        _mreceive(_srcChainId, _payload, true);
    }

    // slither-disable-next-line assembly
    function _mreceive(
        uint256 _srcChainId,
        bytes memory _payload,
        bool _external
    ) internal {
        IHelper.Selector selector;
        bytes32 metadata;
        assembly {
            metadata := mload(add(_payload, 0x20))
            selector := mload(add(_payload, 0x40))
        }

        emit MessageReceived(
            _srcChainId,
            _payload
        );

        if (IHelper.Selector.MASTER_DEPOSIT == selector) {
            // slither-disable-next-line all
            IHelper.MDeposit memory params;
            assembly {
                // skip 0x20 as that is metadata index
                mstore(add(params, 0x40), mload(add(_payload, 0x60))) /* user */
                mstore(add(params, 0x60), mload(add(_payload, 0x80))) /* pToken */
                mstore(add(params, 0x80), mload(add(_payload, 0xa0))) /* exchangeRate */
                mstore(add(params, 0xa0), mload(add(_payload, 0xc0))) /* depositAmount */
            }

            if (
                params.user == address(0) ||
                params.pToken == address(0)
            ) revert AddressExpected();
            if (params.depositAmount == 0) revert ExpectedDepositAmount();

            _checkECC(_external, keccak256(abi.encode(params)), metadata);

            masterState.masterDeposit(
                params,
                _srcChainId
            );
        } else if (IHelper.Selector.MASTER_WITHDRAW_ALLOWED == selector) {
            // slither-disable-next-line all
            IHelper.MWithdrawAllowed memory params;
            assembly {
                // skip 0x20 as that is metadata index
                mstore(add(params, 0x40), mload(add(_payload, 0x60))) /* pToken */
                mstore(add(params, 0x60), mload(add(_payload, 0x80))) /* user */
                mstore(add(params, 0x80), mload(add(_payload, 0xa0))) /* amount */
                mstore(add(params, 0xa0), mload(add(_payload, 0xc0))) /* exchangeRate */
            }

            if (
                params.user == address(0) ||
                params.pToken == address(0)
            ) revert AddressExpected();

            if (params.withdrawAmount == 0) revert ExpectedWithdrawAmount();

            _checkECC(_external, keccak256(abi.encode(params)), metadata);

            masterState.withdrawAllowed(
                params,
                _srcChainId,
                msg.sender
            );
        } else if (IHelper.Selector.FB_WITHDRAW == selector) {
            // slither-disable-next-line all
            IHelper.FBWithdraw memory params;
            assembly {
                // skip 0x20 as that is metadata index
                mstore(add(params, 0x40), mload(add(_payload, 0x60))) /* pToken */
                mstore(add(params, 0x60), mload(add(_payload, 0x80))) /* user */
                mstore(add(params, 0x80), mload(add(_payload, 0xa0))) /* withdrawAmount */
                mstore(add(params, 0xa0), mload(add(_payload, 0xc0))) /* exchangeRate */
            }

            if (
                params.user == address(0) ||
                params.pToken == address(0)
            ) revert AddressExpected();
            if (params.withdrawAmount == 0) revert ExpectedWithdrawAmount();

            _checkECC(_external, keccak256(abi.encode(params)), metadata);

            PTokenMessageHandler(params.pToken).completeWithdraw(
                params
            );
        } else if (IHelper.Selector.MASTER_REPAY == selector) {
            // slither-disable-next-line all
            IHelper.MRepay memory params;
            assembly {
                // skip 0x20 as that is metadata index
                mstore(add(params, 0x40), mload(add(_payload, 0x60))) /* borrower */
                mstore(add(params, 0x60), mload(add(_payload, 0x80))) /* amountRepaid */
                mstore(add(params, 0x80), mload(add(_payload, 0xa0))) /* loanMarketAsset */
            }

            if (
                params.borrower == address(0) ||
                params.loanMarketAsset == address(0)
            ) revert AddressExpected();
            if (params.amountRepaid == 0) revert ExpectedRepayAmount();

            _checkECC(_external, keccak256(abi.encode(params)), metadata);

            masterState.masterRepay(
                params,
                _srcChainId
            );
        } else if (IHelper.Selector.MASTER_BORROW_ALLOWED == selector) {
            // slither-disable-next-line all
            IHelper.MBorrowAllowed memory params;
            assembly {
                // skip 0x20 as that is metadata index
                mstore(add(params, 0x40), mload(add(_payload, 0x60))) /* user */
                mstore(add(params, 0x60), mload(add(_payload, 0x80))) /* borrowAmount */
                mstore(add(params, 0x80), mload(add(_payload, 0xa0))) /* loanMarketAsset */
            }

            if (
                params.user == address(0) ||
                params.loanMarketAsset == address(0)
            ) revert AddressExpected();
            if (params.borrowAmount == 0) revert ExpectedBorrowAmount();

            _checkECC(_external, keccak256(abi.encode(params)), metadata);

            masterState.borrowAllowed(
                params,
                _srcChainId,
                msg.sender
            );
        } else if (IHelper.Selector.FB_BORROW == selector) {
            // slither-disable-next-line all
            IHelper.FBBorrow memory params;
            assembly {
                // skip 0x20 as that is metadata index
                mstore(add(params, 0x40), mload(add(_payload, 0x60))) /* user */
                mstore(add(params, 0x60), mload(add(_payload, 0x80))) /* borrowAmount */
                mstore(add(params, 0x80), mload(add(_payload, 0xa0))) /* loanMarketAsset */
            }

            if (
                params.user == address(0) ||
                params.loanMarketAsset == address(0)
            ) revert AddressExpected();
            if (params.borrowAmount == 0) revert ExpectedBorrowAmount();

            _checkECC(_external, keccak256(abi.encode(params)), metadata);

            loanAgent.borrowApproved(
                params
            );
        } else if (IHelper.Selector.SATELLITE_LIQUIDATE_BORROW == selector) {
            // slither-disable-next-line all
            IHelper.SLiquidateBorrow memory params;
            assembly {
                // skip 0x20 as that is metadata index
                mstore(add(params, 0x40), mload(add(_payload, 0x60))) /* borrower */
                mstore(add(params, 0x60), mload(add(_payload, 0x80))) /* liquidator */
                mstore(add(params, 0x80), mload(add(_payload, 0xa0))) /* seizeTokens */
                mstore(add(params, 0xa0), mload(add(_payload, 0xc0))) /* pToken */
            }

            if (
                params.borrower == address(0) ||
                params.liquidator == address(0) ||
                params.pToken == address(0)
            ) revert AddressExpected();

            _checkECC(_external, keccak256(abi.encode(params)), metadata);

            PTokenMessageHandler(params.pToken).seize(
                params
            );
        } else if (IHelper.Selector.LOAN_ASSET_BRIDGE == selector) {
            // slither-disable-next-line all
            IHelper.LoanAssetBridge memory params;
            assembly {
                // skip 0x20 as that is metadata index
                mstore(add(params, 0x40), mload(add(_payload, 0x60))) /* minter */
                mstore(add(params, 0x60), mload(add(_payload, 0x80))) /* keccak256(loanAssetName() */
                mstore(add(params, 0x80), mload(add(_payload, 0xa0))) /* amount */
            }

            if (params.minter == address(0)) revert AddressExpected();
            if (params.amount == 0) revert ExpectedBridgeAmount();

            _checkECC(_external, keccak256(abi.encode(params)), metadata);

            if (localLoanAssets[params.loanAssetNameHash] == address(0)) revert AddressExpected();

            LoanAssetMessageHandler(localLoanAssets[params.loanAssetNameHash]).mintFromChain(
                params,
                _srcChainId
            );

        } else {
            revert InvalidSelector();
        }
    }

    fallback() external payable {}

    receive() payable external {}
}

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MiddleLayerModifiers.sol";
import "./MiddleLayerEvents.sol";

abstract contract MiddleLayerAdmin is
    MiddleLayerStorage,
    MiddleLayerModifiers,
    MiddleLayerEvents
{

    function changeAdmin(address _newAdmin) external onlyAdmin() {
        if(_newAdmin == address(0)) revert AddressExpected();
        admin = _newAdmin;
        emit ChangeAdmin(_newAdmin);
    }

    function _changeAuth(
        address _contractAddr,
        bool _status
    ) internal {
        if(_contractAddr == address(0)) revert AddressExpected();
        authContracts[_contractAddr] = _status;
    }

    function changeAuth(address _contractAddr, bool _status) external onlyAdmin() {
        if(_contractAddr == address(0)) revert AddressExpected();
        _changeAuth(_contractAddr, _status);
    }

    function changeManyAuth(
        address[] calldata _contractAddr,
        bool[] calldata _status
    ) external onlyAdmin() {
        // slither-disable-next-line uninitialized-local
        for (uint8 i; i < _contractAddr.length; i++) {
            address contractAddr = _contractAddr[i];
            if(contractAddr == address(0)) revert AddressExpected();
            _changeAuth(contractAddr, _status[i]);
        }
    }

    function setMasterState(address _newMasterState) external onlyAdmin() {
        if(_newMasterState == address(0)) revert AddressExpected();
        masterState = MasterMessageHandler(_newMasterState);
    }

    function setLoanAgent(address _newLoanAgent) external onlyAdmin() {
        if(_newLoanAgent == address(0)) revert AddressExpected();
        loanAgent = ILoanAgent(_newLoanAgent);
    }

    function addLoanAsset(
        string memory loanAssetName,
        address localLoanAsset
    ) external onlyAdmin() {
        if (bytes(loanAssetName).length == 0) revert NameExpected();
        if(localLoanAsset == address(0)) revert AddressExpected();
        localLoanAssets[keccak256(abi.encode(loanAssetName))] = localLoanAsset;
    }

    function removeLoanAsset(
        string memory loanAssetName
    ) external onlyAdmin() {
        if (bytes(loanAssetName).length == 0) revert NameExpected();
        localLoanAssets[keccak256(abi.encode(loanAssetName))] = address(0);
    }

    function addRoute(IRoute _newRoute) external onlyAdmin() {
        if(address(_newRoute) == address(0)) revert AddressExpected();
        routes.push(_newRoute);
        authRoutes[address(_newRoute)] = true;
    }

    // slither-disable-next-line costly-loop
    function removeRoute(IRoute _fallbackAddressToRemove) external onlyAdmin() returns (bool) {
        // slither-disable-next-line uninitialized-local
        for (uint256 i; i < routes.length; i++) {
            if (routes[i] == _fallbackAddressToRemove) {
                // swap the route to remove with the last item
                routes[i] = routes[routes.length - 1];
                // pop the last item
                routes.pop();

                authRoutes[address(_fallbackAddressToRemove)] = false;
                return true;
            }
        }
        return false;
    }

    function changePause(bool _pauseStatus) external onlyAdmin() {
        paused = _pauseStatus;
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
import "../../util/SafeTransfers.sol";

abstract contract PTokenMessageHandler is
    IPTokenInternals,
    IPTokenMessageHandler,
    PTokenModifiers,
    PTokenEvents,
    CommonModifiers,
    SafeTransfers
{

    // slither-disable-next-line assembly
    function _sendDeposit(
        address route,
        uint256 gas,
        uint256 depositAmount,
        uint256 exchangeRate
    ) internal virtual override {

        bytes memory payload = abi.encode(
            IHelper.MDeposit({
                metadata: uint256(0),
                selector: IHelper.Selector.MASTER_DEPOSIT,
                user: msg.sender,
                pToken: address(this),
                exchangeRate: exchangeRate,
                depositAmount: depositAmount
            })
        );

        middleLayer.msend{ value: gas }(
            masterCID,
            payload,
            payable(msg.sender),
            route,
            true
        );

        emit DepositSent(msg.sender, address(this), depositAmount);
    }

    // slither-disable-next-line assembly
    function _sendWithdraw(
        address user,
        address route,
        uint256 withdrawAmount,
        uint256 exchangeRate
    ) internal virtual override {

        bytes memory payload = abi.encode(
            IHelper.MWithdrawAllowed({
                metadata: uint256(0),
                selector: IHelper.Selector.MASTER_WITHDRAW_ALLOWED,
                pToken: address(this),
                user: user,
                withdrawAmount: withdrawAmount,
                exchangeRate: exchangeRate
            })
        );

        middleLayer.msend{ value: msg.value }(
            masterCID,
            payload,
            payable(msg.sender),
            route,
            true
        );

        emit WithdrawSent(user, address(this), accountTokens[msg.sender], withdrawAmount);
    }

    /**
     * @notice Transfers tokens to the withdrawer.
     */
    function completeWithdraw(
        IHelper.FBWithdraw memory params
    ) external virtual override onlyMid() {
        emit WithdrawApproved(
            params.user,
            address(this),
            params.withdrawAmount,
            true
        );

        if (accountTokens[params.user] < params.withdrawAmount) revert WithdrawTooMuch();

        totalSupply -= params.withdrawAmount;
        accountTokens[params.user] -= params.withdrawAmount;

        uint256 actualWithdrawAmount = (params.withdrawAmount * params.exchangeRate) / 10**EXCHANGE_RATE_DECIMALS;

        _doTransferOut(params.user, underlying, actualWithdrawAmount);
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another PToken.
     *  Its absolutely critical to use msg.sender as the seizer pToken and not a parameter.
     */
    function seize(
        IHelper.SLiquidateBorrow memory params
    ) external virtual override onlyMid() {
        if (accountTokens[params.borrower] < params.seizeTokens) revert SeizeTooMuch();

        uint256 exchangeRate = _getExchangeRate();

        totalSupply -= params.seizeTokens;
        accountTokens[params.borrower] -= params.seizeTokens;

        uint256 actualSeizeTokens = (params.seizeTokens * exchangeRate) / 10**EXCHANGE_RATE_DECIMALS;

        _doTransferOut(params.liquidator, underlying, actualSeizeTokens);
    }
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MiddleLayerStorage.sol";
import "../util/CommonErrors.sol";

abstract contract MiddleLayerModifiers is MiddleLayerStorage, CommonErrors {
    modifier onlyAdmin() {
        if(msg.sender != admin) revert OnlyAdmin();
        _;
    }

    modifier onlyAuth() {
        if (!authContracts[msg.sender]) revert OnlyAuth();
        _;
    }

    modifier onlyRoute() {
        if (!authRoutes[msg.sender]) revert OnlyRoute();
        _;
    }

    modifier notPaused() {
        if (paused) revert MiddleLayerPaused();
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MiddleLayerEvents {
    event MessageSent (
        uint256 _dstChainId,
        bytes _params,
        address _refundAddress,
        address _fallbackAddress
    );

    event MessageReceived(
        uint256 _srcChainId,
        bytes _payload
    );

    event ChangeAdmin(
        address newAdmin
    );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../master/MasterMessageHandler.sol";
import "../satellite/loanAgent/interfaces/ILoanAgent.sol";
import "../satellite/loanAsset/LoanAssetMessageHandler.sol";
import "./routes/interfaces/IRoute.sol";
import "../ecc/interfaces/IECC.sol";

abstract contract MiddleLayerStorage {
    MasterMessageHandler internal masterState;
    ILoanAgent internal loanAgent;
    IECC internal ecc;

    uint256 internal cid;

    address internal admin;

    bool internal paused;

    IRoute[] internal routes;

    mapping(bytes32 /* keccak256(loanAssetName) */ => address /* localLoanAsset */) public localLoanAssets;

    // addresses allowed to send messages to other chains
    mapping(address => bool) internal authContracts;

    // routes allowed to receive messages
    mapping(address => bool) public authRoutes;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IHelper.sol";

import "./interfaces/IMaster.sol";
import "./MasterModifiers.sol";
import "./MasterEvents.sol";

abstract contract MasterMessageHandler is IMaster, MasterModifiers, MasterEvents {
    // slither-disable-next-line assembly
    function _satelliteLiquidateBorrow(
        uint256 chainId,
        address borrower,
        address liquidator,
        uint256 seizeTokens,
        address pToken,
        address route
    ) internal virtual override {
        bytes memory payload = abi.encode(
            IHelper.SLiquidateBorrow({
                metadata: uint256(0),
                selector: IHelper.Selector.SATELLITE_LIQUIDATE_BORROW,
                borrower: borrower,
                liquidator: liquidator,
                seizeTokens: seizeTokens,
                pToken: pToken
            })
        );

        middleLayer.msend{value: msg.value}(
            chainId,
            payload, // bytes payload
            payable(msg.sender), // refund address
            route,
            true
        );
    }

    /// @dev Update the collateral balance for the given arguments
    /// @notice This will come from the satellite chain- the approve models
    function masterDeposit(
        IHelper.MDeposit memory params,
        uint256 chainId
    ) external payable onlyMid() {
        
        // Do not accept new deposits on a paused market
        if (markets[chainId][params.pToken].isPaused) revert MarketIsPaused();

        if (collateralBalances[chainId][params.user][params.pToken] == 0) {
            _enterMarket(params.pToken, chainId, params.user);

            emit NewCollateralBalance(params.user, chainId, params.pToken);
        }

        collateralBalances[chainId][params.user][params.pToken] += params.depositAmount;
        markets[chainId][params.pToken].totalSupply += params.depositAmount;
        markets[chainId][params.pToken].exchangeRate = params.exchangeRate;

        _syncAssetValue(params.pToken, chainId);

        emit CollateralDeposited(
            params.user,
            chainId,
            params.pToken,
            collateralBalances[chainId][params.user][params.pToken],
            params.depositAmount,
            markets[chainId][params.pToken].totalSupply
        );
    }

    // slither-disable-next-line assembly
    function borrowAllowed(
        IHelper.MBorrowAllowed memory params,
        uint256 chainId,
        address fallbackAddress
    ) external payable onlyMid() {
        address masterLoanMarket = masterLoanMarketAsset[chainId][params.loanMarketAsset];

        _accrueInterestOnSingleLoanMarket(masterLoanMarket);

        uint256 mintAmount = params.borrowAmount;
        uint256 shortfall;

        // Handle over-repayment situations
        // These are needed to clear a user's entire borrow balance as there is a delay between
        // triggering a repayment and payment being registered on the master state
        if (params.borrowAmount <= repayCredit[params.user][masterLoanMarket]) {
            // Withdrawing over-repay amount - automatically approved
            repayCredit[params.user][masterLoanMarket] -= params.borrowAmount;
            params.borrowAmount = 0;
        } else {
            if (repayCredit[params.user][masterLoanMarket] != 0) { 
                // Borrowing an amount that exceeds the repayCredit - still requires approval
                params.borrowAmount -= repayCredit[params.user][masterLoanMarket];
                repayCredit[params.user][masterLoanMarket] = 0;
            }
            _syncCollateralValue(params.user);
            (, shortfall) = _getHypotheticalAccountLiquidity(
                params.user,
                address(0),
                masterLoanMarket,
                0,
                params.borrowAmount
            );
        }

        //if approved, update the balance and fire off a return message
        // slither-disable-next-line incorrect-equality
        if (shortfall == 0) {
            uint256 _accountLoanMarketBorrows = _borrowBalanceStored(params.user, masterLoanMarket);

            if (_accountLoanMarketBorrows == 0) {
                if (!_enterLoanMarket(
                    params.user,
                    masterLoanMarket
                )) revert EnterLoanMarketFailed();
            }

            accountLoanMarketBorrows[params.user][masterLoanMarket].principal = _accountLoanMarketBorrows + params.borrowAmount;
            accountLoanMarketBorrows[params.user][masterLoanMarket].interestIndex = loanMarkets[masterLoanMarket].borrowIndex;
            loanMarkets[masterLoanMarket].totalBorrows += params.borrowAmount;

            bytes memory payload = abi.encode(
                IHelper.FBBorrow({
                    metadata: uint256(0),
                    selector: IHelper.Selector.FB_BORROW,
                    user: params.user,
                    borrowAmount: mintAmount,
                    loanMarketAsset: params.loanMarketAsset
                })
            );

            middleLayer.msend{ value: msg.value }(
                chainId,
                payload, // bytes payload
                payable(params.user), // refund address
                fallbackAddress,
                false
            );

            emit LoanApproved(
                params.user,
                accountLoanMarketBorrows[params.user][masterLoanMarket].principal,
                mintAmount,
                loanMarkets[masterLoanMarket].totalBorrows,
                masterLoanMarket
            );
        } else {
            emit LoanRejected(
                params.user,
                accountLoanMarketBorrows[params.user][masterLoanMarket].principal,
                params.borrowAmount,
                shortfall,
                masterLoanMarket
            );
        }
    }

    function masterRepay(
        IHelper.MRepay memory params,
        uint256 chainId
    ) external payable onlyMid() {
        address masterLoanMarket = masterLoanMarketAsset[chainId][params.loanMarketAsset];

        _accrueInterestOnSingleLoanMarket(masterLoanMarket);

        uint256 _accountLoanMarketBorrows = _borrowBalanceStored(params.borrower, masterLoanMarket);

        if (_accountLoanMarketBorrows < params.amountRepaid) {
            repayCredit[params.borrower][masterLoanMarket] += params.amountRepaid - _accountLoanMarketBorrows;
            params.amountRepaid = _accountLoanMarketBorrows;
        }

        accountLoanMarketBorrows[params.borrower][masterLoanMarket].principal = _accountLoanMarketBorrows - params.amountRepaid;
        accountLoanMarketBorrows[params.borrower][masterLoanMarket].interestIndex = loanMarkets[masterLoanMarket].borrowIndex;
        loanMarkets[masterLoanMarket].totalBorrows -= params.amountRepaid;

        // If user entirely repays their loan, exit them from the loan market
        if (accountLoanMarketBorrows[params.borrower][masterLoanMarket].principal == 0) {
            if (!_exitLoanMarket(
                params.borrower,
                masterLoanMarket
            )) revert ExitLoanMarketFailed();
        }

        emit LoanRepaid(
            params.borrower,
            accountLoanMarketBorrows[params.borrower][masterLoanMarket].principal,
            params.amountRepaid,
            loanMarkets[masterLoanMarket].totalBorrows,
            params.loanMarketAsset
        );
    }

    // slither-disable-next-line assembly
    function withdrawAllowed(
        IHelper.MWithdrawAllowed memory params,
        uint256 chainId,
        address fallbackAddress
    ) external payable onlyMid() {
        _accrueInterestOnAllLoanMarkets(params.user);

        uint256 collateralBal = collateralBalances[chainId][params.user][params.pToken];
        if (params.withdrawAmount == type(uint256).max) params.withdrawAmount = collateralBal;

        markets[chainId][params.pToken].exchangeRate = params.exchangeRate;

        // calculate if the user is still liquid after the withdraw
        (, uint256 shortfall) = _getHypotheticalAccountLiquidity(
            params.user,
            params.pToken,
            address(0),
            params.withdrawAmount,
            0
        );

        //if approved, update the balance and fire off a return message
        // slither-disable-next-line incorrect-equality
        if (shortfall == 0) {
            if (collateralBal == params.withdrawAmount) {
                if (!_exitMarket(
                    chainId,
                    params.pToken,
                    params.user
                )) revert ExitCollMarketFailed();
            }

            collateralBalances[chainId][params.user][params.pToken] -= params.withdrawAmount;
            collateralBal -= params.withdrawAmount;
            markets[chainId][params.pToken].totalSupply -= params.withdrawAmount;
            
            _syncAssetValue(params.pToken, chainId);

            bytes memory payload = abi.encode(
                IHelper.FBWithdraw({
                    metadata: uint256(0),
                    selector: IHelper.Selector.FB_WITHDRAW,
                    pToken: params.pToken,
                    user: params.user,
                    withdrawAmount: params.withdrawAmount,
                    exchangeRate: params.exchangeRate
                })
            );

            middleLayer.msend{value: msg.value}(
                chainId,
                payload, // bytes payload
                payable(params.user), // refund address
                fallbackAddress,
                false
            );

            emit CollateralWithdrawn(
                params.user,
                chainId,
                params.pToken,
                collateralBal,
                params.withdrawAmount,
                markets[chainId][params.pToken].totalSupply
            );
        } else {
            emit CollateralWithdrawalRejection(
                params.user,
                chainId,
                params.pToken,
                collateralBal,
                params.withdrawAmount,
                shortfall
            );
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

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./LoanAssetStorage.sol";
import "./LoanAssetAdmin.sol";
import "../../interfaces/IHelper.sol";
import "../../util/CommonModifiers.sol";

abstract contract LoanAssetMessageHandler is
    LoanAssetStorage,
    LoanAssetAdmin,
    ERC20Burnable,
    CommonModifiers
{

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    // slither-disable-next-line assembly
    function _sendTokensToChain(
        address receiver,
        address route,
        uint256 _dstChainId,
        uint256 amount
    ) internal {
        // burn senders loanAsset locally
        _burn(msg.sender, amount);

        bytes memory payload = abi.encode(
            IHelper.LoanAssetBridge({
                metadata: uint256(0),
                selector: IHelper.Selector.LOAN_ASSET_BRIDGE,
                minter: receiver,
                loanAssetNameHash: keccak256(abi.encode(this.symbol())),
                amount: amount
            })
        );

        middleLayer.msend{ value: msg.value }(
            _dstChainId,
            payload,
            payable(receiver), // refund address
            route,
            true
        );

        emit SentToChain(receiver, _dstChainId, amount);
    }

    function mintFromChain(
        IHelper.LoanAssetBridge memory params,
        uint256 srcChain
    ) external onlyMid() {
        _mint(params.minter, params.amount);

        emit ReceiveFromChain(params.minter, srcChain, params.amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRoute {
    function msend(
        uint256 _dstChainId,
        bytes memory _params,
        address payable _refundAddress,
        bool _shouldPayGas
    ) external payable;
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
        bytes32 payloadHash,
        bytes32 metadata
    ) external view returns (bool allowed);

    function flagMsgValidated(
        bytes32 payloadHash,
        bytes32 metadata
    ) external returns (bool);

    // function rsm(uint256 messagePtr) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../MasterStorage.sol";
import "../../util/CommonErrors.sol";

abstract contract IMaster is MasterStorage, CommonErrors {
    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return (error code, the calculated balance or 0 if error code is non-zero)
     */
    function _borrowBalanceStored(
        address account,
        address masterLoanMarket
    ) internal view virtual returns (uint256);

    function _accrueInterestOnSingleLoanMarket(
        address masterLoanMarket
    ) internal virtual;

    function _accrueInterestOnAllLoanMarkets(
        address account
    ) internal virtual;

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param pToken The market to enter
     * @param chainId The chainId
     * @param borrower The address of the account to modify
     */
    function _enterMarket(
        address pToken,
        uint256 chainId,
        address borrower
    ) internal virtual returns (bool);

    function _exitMarket(
        uint256 chainId,
        address pToken,
        address user
    ) internal virtual returns (bool);

    /**
     * @notice Get a snapshot of the account's balance, and the cached exchange rate
     * @dev This is used by risk engine to more efficiently perform liquidity checks.
     * @param user Address of the account to snapshot
     * @param chainId metadata of the ptoken
     * @param pToken metadata of the ptoken
     * @return (possible error, token balance, exchange rate)
     */
    function _getAccountSnapshot(
        address user,
        uint256 chainId,
        address pToken
    ) internal view virtual returns (uint256, uint256);

    function _getHypotheticalAccountLiquidity(
        address account,
        address pTokenModify,
        address borrowLoanMarket,
        uint256 withdrawTokens,
        uint256 borrowAmount
    ) internal view virtual returns (uint256, uint256);

    /**
     * @notice The liquidator liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this pToken to be liquidated
     * @param pToken The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function _liquidateBorrow(
        address pToken,
        address borrower,
        uint256 chainId,
        uint256 repayAmount,
        address route,
        address masterLoanMarket
    ) internal virtual returns (bool);

    function _liquidateCalculateSeizeTokens(
        address pToken,
        uint256 chainId,
        uint256 actualRepayAmount,
        address masterLoanMarket
    ) internal view virtual returns (uint256);

    function _liquidateBorrowAllowed(
        address pToken,
        address borrower,
        uint256 chainId
    ) internal virtual returns (bool);

    function _satelliteLiquidateBorrow(
        uint256 chainId,
        address borrower,
        address liquidator,
        uint256 seizeTokens,
        address pToken,
        address route
    ) internal virtual;

    function _enterLoanMarket(
        address borrower,
        address masterLoanMarket
    ) internal virtual returns (bool);

    function _exitLoanMarket(
        address borrower,
        address loanMarketAsset
    ) internal virtual returns (bool);


    function _syncCollateralValue(
        address account
    ) internal virtual;

    function _syncAssetValue(
        address pToken,
        uint256 chainId
    ) internal virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MasterStorage.sol";
import "./interfaces/IMaster.sol";

abstract contract MasterModifiers is MasterStorage, IMaster {
    modifier onlyAdmin() {
        if(msg.sender != admin) revert OnlyAdmin();
        _;
    }

    modifier onlyMid() {
        if (IMiddleLayer(msg.sender) != middleLayer) revert OnlyMiddleLayer();
        _;
    }

    modifier initOnlyOnce() {
        if(isInitialized) revert AlreadyInitialized();
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
        uint256 depositAmount,
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
        uint256 totalBorrows,
        address loanMarketAsset
    );

    event LoanRejected(
        address indexed user,
        uint256 balance,
        uint256 amount,
        uint256 shortfall,
        address loanMarketAsset
    );

    event LoanRepaid(
        address indexed user,
        uint256 balance,
        uint256 amountRepaid,
        uint256 totalBorrows,
        address loanMarketAsset
    );

    /// @notice Emitted when an account enters a deposit market
    event CollateralMarketEntered(uint256 chainId, address pToken, address borrower);

    event CollateralMarketExited(uint256 chainId, address pToken, address borrower);

    event LoanMarketEntered(address masterLoanMarket, address borrower);

    event LoanMarketExited(address masterLoanMarket, address borrower);

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

    event MarketPaused(uint256 chainId, address pToken, bool isPaused);

    event LoanMarketPaused(address masterLoanMarket, bool isPaused);

    event AddChain(uint256 chainId);

    event ChangeAdmin(address newAdmin);

    event ChangeMiddleLayer(address oldMid, address newMid);

    event CollateralMarketListed(
        uint256 indexed chainId,
        address indexed token,
        bool listed
    );

    event LoanMarketListed(
        address indexed masterLoanMarket,
        bool listed
    );

    event SatelliteLoanMarketSupported(
        uint256 chainId, 
        address satelliteLoanMarketAsset, 
        address masterLoanMarket
    );


    event ChangeLiqIncentive(uint256 newLiqIncentive);

    event ChangeFactorDecimals(uint8 newFactorDecimals);

    event ChangeCollateralFactor(uint256 newCollateralFactor);

    event ChangeProtocolSeizeShare(uint256 newProtocolSeizeShare);

    event AccountLiquidity(uint256 collateral, uint256 borrowPlusEffects);

    event MessageFailed(bytes data);

    event WithdrawFromReserves(
        uint256 amountWithdrawn,
        uint256 amountRemaining,
        address masterLoanMarketAsset,
        address receiver
    );

    event MaxCollateralPercentageUpdated(
        uint256 chainId,
        address asset,
        uint256 maxColateralPercentage
    );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../master/oracle/interfaces/IPrimeOracle.sol";
import "../middleLayer/interfaces/IMiddleLayer.sol";
import "../master/irm/router/interfaces/IIRMRouter.sol";
import "../master/crm/router/interfaces/ICRMRouter.sol";

abstract contract MasterStorage {

    /// @notice Administrator for this contract
    address public admin;

    /// @notice Whether or not the delegatee has been initialized or not.
    bool internal isInitialized;

    // slither-disable-next-line unused-state
    IMiddleLayer internal middleLayer;

    // slither-disable-next-line unused-state
    IIRMRouter public interestRateModel;
    ICRMRouter public collateralRatioModel;
    IPrimeOracle public oracle;

    uint8 public constant FACTOR_DECIMALS = 8;
    uint256 public totalUsdCollateralBalance;

    struct MarketIndex {
        uint256 chainId;  /// @notice The chainId on which the market exists
        address pToken; /// @notice The asset for which this market exists, e.g. e.g. USP, pBTC, pETH.
    }

    /// @notice Represents one of the collateral available on a given satellite chain. Key: <chainId, token>
    struct Market {
        uint256 exchangeRate;
        uint256 collateralValue;
        uint256 totalSupply;
        uint256 liquidityIncentive;
        uint256 protocolSeizeShare;
        address underlying;
        uint8 decimals;
        bool isListed;
        bool isPaused;
        bool isRebase;
    }

    /// @notice Mapping of account addresses to collateral balances
    mapping(uint256 /* chainId */ => mapping(address /* user */ => mapping(address /* token */ => uint256 /* tokenBalance */))) public collateralBalances;

    /// @notice Mapping of tokens -> max acceptable percentage risk by the protocol; precision of 8; 1e8 = 100%
    /// @notice Set to 1 if you want to disable this asset
    mapping(uint256 /* chainId */ => mapping(address /* token */ => uint256)) public maxCollateralPercentages;

    /// @notice Mapping of all depositors currently using this collateral market.
    mapping(address /* user */ => mapping(uint256 /* chainId */ => mapping(address /* token */ => bool /* isMember */))) public accountMembership;

    /// @notice Official mapping of tokens -> Market metadata.
    mapping(uint256 /* chainId */ => mapping(address /* token */ => Market)) public markets;

    /// @notice All collateral markets in use by a particular user.
    mapping(address /* user */ => MarketIndex[]) public accountCollateralMarkets;

    /// @notice Container for borrow balance information
    struct BorrowSnapshot {
        uint256 principal; /// @notice Total balance (with accrued interest), after applying the most recent balance-changing action
        uint256 interestIndex; /// @notice Global borrowIndex as of the most recent balance-changing action
    }

    /// @notice Represents one of the loan markets available by all satellite loan agents. Key: <chainId, loanMarketAsset>
    struct LoanMarket {
        uint256 accrualBlockNumber; /// @notice Block number that interest was last accrued at
        uint256 totalReserves; /// @notice Total amount of reserves of the underlying held in this market.
        uint256 totalBorrows; /// @notice Total amount of outstanding borrows of the underlying in this market.
		uint256 borrowIndex; /// @notice Accumulator of the total earned interest rate since the opening of the market.
        uint256 underlyingChainId; /// @notice The chainId on which the underlying asset exists.
        address underlying; /// @notice The underlying asset for which this loan market exists, e.g. USP, BTC, ETH.
        uint8 decimals; /// @notice The decimals of the underlying asset, e.g. 18.
        bool isListed;  /// @notice Whether or not this market is listed.
        bool isPaused; /// @notice User can no longer borrow on this market, but interest will still accrue.
    }

    /// @notice Mapping of account addresses to outstanding borrow balance.
    mapping(address /* borrower */ => mapping(address /* masterLoanMarketAsset */ => BorrowSnapshot)) public accountLoanMarketBorrows;

    mapping(address /* borrower */ => mapping(address /* masterLoanMarketAsset */ => uint256)) public repayCredit;

    /// @notice Mapping of all borrowers currently using this loan market.
    mapping(address /* borrower */ => mapping(address /* masterLoanMarketAsset */ => bool /* isMember */)) public isLoanMarketMember;

    /// @notice All currently supported loan market assets, e.g. USP, pBTC, pETH.
    mapping(address /* masterLoanMarketAsset */ => LoanMarket) public loanMarkets;

    /// @notice Map satellite chainId + satellite loanMarketAsset to the masterLoanMarket asset
    mapping(uint256 /* chainId */ => mapping(address /* satelliteLoanMarketAsset */ => address /* masterLoanMarketAsset */)) public masterLoanMarketAsset;

    /// @notice All loan markets in use by a particular borrower.
    mapping(address /* borrower */ => address[] /* masterLoanMarketAssets */) public accountLoanMarkets;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IPrimeOracleGetter.sol";
import "./PrimeOracleStorage.sol";

/**
 * @title IPrimeOracle
 * @author Prime
 * @notice The core interface for the Prime Oracle
 */
abstract contract IPrimeOracle is PrimeOracleStorage {

    /**
     * @dev Emitted after the price data feed of an asset is set/updated
     * @param asset The address of the asset
     * @param chainId The chainId of the asset
     * @param feed The price feed of the asset
     */
    event SetPrimaryFeed(uint256 chainId, address indexed asset, address indexed feed);

    /**
     * @dev Emitted after the price data feed of an asset is set/updated
     * @param asset The address of the asset
     * @param feed The price feed of the asset
     */
    event SetSecondaryFeed(uint256 chainId, address indexed asset, address indexed feed);

    /**
     * @dev Emitted after the exchange rate data feed of a loan market asset is set/updated
     * @param asset The address of the asset
     * @param chainId The chainId of the asset
     * @param feed The price feed of the asset
     */
    event SetExchangRatePrimaryFeed(uint256 chainId, address indexed asset, address indexed feed);

    /**
     * @dev Emitted after the exchange rate data feed of a loan market asset is set/updated
     * @param asset The address of the asset
     * @param feed The price feed of the asset
     */
    event SetExchangeRateSecondaryFeed(uint256 chainId, address indexed asset, address indexed feed);

    /**
     * @notice Get the underlying price of a cToken asset
     * @param collateralMarketUnderlying The PToken collateral to get the sasset price of
     * @param chainId the chainId to get an asset price for
     * @return The underlying asset price.
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(uint256 chainId, address collateralMarketUnderlying) external view virtual returns (uint256, uint8);

    /**
     * @notice Get the underlying borrow price of loanMarketAsset
     * @return The underlying borrow price
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPriceBorrow(
        uint256 chainId,
        address loanMarketUnderlying
    ) external view virtual returns (uint256, uint8);

    /**
     * @notice Get the exchange rate of loanMarketAsset to basis
     * @return The underlying exchange rate of loanMarketAsset to basis
     *  Zero means the price is unavailable.
     */
    function getBorrowAssetExchangeRate(
        uint256 loanMarketUnderlyingChainId,
        address loanMarketUnderlying
    ) external view virtual returns (uint256 /* ratio */, uint8 /* decimals */);

    /*** Admin Functions ***/

    /**
     * @notice Sets or replaces price feeds of assets
     * @param asset The addresses of the assets
     * @param feed The addresses of the price feeds
     */
    function setPrimaryFeed(uint256 chainId, address asset, IPrimeOracleGetter feed) external virtual;

    /**
     * @notice Sets or replaces price feeds of assets
     * @param asset The addresses of the assets
     * @param feed The addresses of the price feeds
     */
    function setSecondaryFeed(uint256 chainId, address asset, IPrimeOracleGetter feed) external virtual;

    /**
     * @notice Sets or replaces the exchange rate feed for loan market assets
     * @param asset The addresses of the assets
     * @param feed The addresses of the price feeds
     */
    function setExchangeRatePrimaryFeed(uint256 chainId, address asset, IPrimeOracleGetter feed) external virtual;

    /**
     * @notice Sets or replaces the exchange rate feed for loan market assets
     * @param asset The addresses of the assets
     * @param feed The addresses of the price feeds
     */
    function setExchangeRateSecondaryFeed(uint256 chainId, address asset, IPrimeOracleGetter feed) external virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IIRMRouter {
    function setBorrowRate(
        address masterLoanMarket
    ) external /* onlyMaster() */ returns (uint256 rate);

    function borrowInterestRatePerBlock(
        address masterLoanMarket
    ) external view returns (uint256);

    function basisPointsTickSize(
        address masterLoanMarket
    ) external view returns (uint256);

    function basisPointsUpperTick(
        address masterLoanMarket
    ) external view returns (uint256);

    function basisPointsLowerTick(
        address masterLoanMarket
    ) external view returns (uint256);

    function lowerTargetRatio(
        address masterLoanMarket
    ) external view returns (uint256);

    function upperTargetRatio(
        address masterLoanMarket
    ) external view returns (uint256);

    function lastObservationTimestamp(
        address masterLoanMarket
    ) external view returns (uint256);

    function blocksPerYear(
        address masterLoanMarket
    ) external view returns (uint256);

    function observationPeriod(
        address masterLoanMarket
    ) external view returns (uint256);

    function borrowInterestRateDecimals(
        address masterLoanMarket
    ) external view returns (uint8);

    function borrowInterestRateBase(
        address masterLoanMarket
    ) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ICRMRouter {
    function getLoanMarketPremium(
        address masterLoanMarket,
        uint256 loanMarketUnderlyingChainId,
        address loanMarketUnderlying
    ) external view returns (uint256 ratio, uint8 decimals);

    function getMaintenanceCollateralFactor(
        uint256 chainId,
        address asset
    ) external view returns (uint256 ratio, uint8 decimals);

    function getCollateralFactor(
        uint256 chainId,
        address asset
    ) external view returns (uint256 ratio, uint8 decimals);
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
     * @param asset The addresses of the assets
     * @param feed The addresses of the price feeds
     */
    function setAssetFeed(uint256 chainId, address asset, address feed) external;

    /**
     * @notice Returns the price data in the denom currency
     * @param quoteToken A token to return price data for
     * @param denomToken A token to price quoteToken against
     * @param price of the asset from the oracle
     * @param decimals of the asset from the oracle
     **/
    function getAssetPrice(
        uint256 chainId,
        address quoteToken,
        address denomToken
    ) external view returns (uint256 price, uint8 decimals);

    function getAssetRatio(
        address overlyingAsset,
        address underlyingAsset,
        uint256 underlyingChainId
    ) external view returns (uint256 ratio, uint8 decimals);

    /**
     * @notice Returns the price data in the denom currency
     * @param quoteToken A token to return price data for
     * @return return price of the asset from the oracle
     **/
    function getPriceDecimals(
        uint256 chainId,
        address quoteToken
    ) external view returns (uint256);

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IPrimeOracleGetter.sol";

/**
 * @title PrimeOracleStorage
 * @author Prime
 * @notice The core interface for the Prime Oracle storage variables
 */
abstract contract PrimeOracleStorage {
    address public pusdAddress;
    //TODO: allow transfer of ownership
    address public admin;
    // Map of asset price feeds (chainasset => priceSource)
    mapping(uint256 => mapping(address => IPrimeOracleGetter)) public primaryFeeds;
    mapping(uint256 => mapping(address => IPrimeOracleGetter)) public secondaryFeeds;
    mapping(uint256 => mapping(address => IPrimeOracleGetter)) public exchangeRatePrimaryFeeds;
    mapping(uint256 => mapping(address => IPrimeOracleGetter)) public exchangeRateSecondaryFeeds;
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

import "../../middleLayer/interfaces/IMiddleLayer.sol";

abstract contract LoanAssetStorage {

    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Underlying asset for this contract
     */
    address public underlyingAsset;

    /**
     * @notice Underlying chain id for this contract
     */
    uint256 public underlyingChainId;
    
    /**
     * @notice Indicates whether the loanAsset is currently bridgeable
     */
    bool internal paused;

    /**
     * @notice Synthetic Asset Decimals
     */
    uint8 internal _decimals;

    /**
     * @notice MiddleLayer Interface
     */
    IMiddleLayer internal middleLayer;

    /**
     * @notice Mapping of minting permissions
     */    
    mapping(address /* facilitator */ => bool /* isAuth */) public mintAuth;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/ILoanAsset.sol";
import "./LoanAssetModifiers.sol";
import "./LoanAssetEvents.sol";

abstract contract LoanAssetAdmin is ILoanAsset, LoanAssetModifiers, LoanAssetEvents {
    
    function pauseSendTokens(
        bool newPauseStatus
    ) external onlyAdmin() {
        emit Paused(paused, newPauseStatus);

        paused = newPauseStatus;
    }

    function setMiddleLayer(
        address newMiddleLayer
    ) external onlyAdmin() {
        if (newMiddleLayer == address(0)) revert AddressExpected();

        emit SetMiddleLayer(address(middleLayer), newMiddleLayer);

        middleLayer = IMiddleLayer(newMiddleLayer);
    }

    function changeMintAuth(
        address minter,
        bool isAuth
    ) external onlyAdmin() {
        mintAuth[minter] = isAuth;

        emit ChangeMintAuth(minter, isAuth);
    }

    function changeAdmin(
        address newAdmin
    ) external onlyAdmin() {
        if (newAdmin == address(0)) revert AddressExpected();
        
        emit ChangeAdmin(admin, newAdmin);
        
        admin = newAdmin;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ILoanAsset {
    function mint(address to, uint256 amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./LoanAssetStorage.sol";
import "../../util/CommonErrors.sol";

abstract contract LoanAssetModifiers is LoanAssetStorage, CommonErrors {

    modifier onlyMintAuth() {
        if (!mintAuth[msg.sender]) revert OnlyMintAuth();
        _;
    }

    modifier onlyAdmin() {
        if(msg.sender != admin) revert OnlyAdmin();
        _;
    }

    modifier onlyMid() {
        if (msg.sender != address(middleLayer)) revert OnlyMiddleLayer();
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract LoanAssetEvents {

    /*** User Events ***/

    /**
     * @notice Event emitted when LoanAsset is sent cross-chain
     */
    event SentToChain(
        address toAddress,
        uint256 destChainId,
        uint256 amount
    );

    /**
     * @notice Event emitted when LoanAsset is received cross-chain
     */
    event ReceiveFromChain(
        address toAddress,
        uint256 srcChainId,
        uint256 amount
    );

    /*** Admin Events ***/

    event Paused(
        bool previousStatus,
        bool newStatus
    );

    event SetMiddleLayer(
        address oldMiddleLayer,
        address newMiddleLayer
    );

    event ChangeMintAuth(
        address minter,
        bool auth
    );

    event ChangeAdmin(
        address oldAdmin,
        address newAdmin
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../middleLayer/interfaces/IMiddleLayer.sol";
import "../../master/irm/interfaces/IIRM.sol";
import "../../master/crm/interfaces/ICRM.sol";

abstract contract PTokenStorage {
    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Mapping of whether or not a delegatee has been initialized or not.
     */
    // mapping(string /* contractName */ => bool /* isInitialized */) internal initializations;
    bool internal isInitialized;

    /**
     * @notice EIP-20 token for this PToken
     */
    address public underlying;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public constant EXCHANGE_RATE_DECIMALS = 18;

    /**
     * @notice Master ChainId
     */
    // slither-disable-next-line unused-state
    uint256 internal masterCID;

    /**
    * @notice Indicates whether the market is accepting deposits
    */
    bool public isPaused;

    /**
     * @notice Official record of the total tokens deposited
     */
    // slither-disable-next-line unused-state
    uint256 public totalSupply;

    /**
     * @notice The decimals of the underlying asset of this pToken's underlying, e.g. ETH of CETH of PCETH.
     */
    uint8 public underlyingDecimalsOfUnderlying;

    /**
     * @notice The current exchange rate between pToken deposits and underlying
     */
    uint256 public currentExchangeRate;

    /**
     * @notice MiddleLayer Interface
     */
    // slither-disable-next-line unused-state
    IMiddleLayer internal middleLayer;

    /**
     * @notice Official record of token balances for each account
     */
    // slither-disable-next-line unused-state
    mapping(address => uint256) public accountTokens;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/IPTokenInternals.sol";
import "../../util/dependency/compound/CTokenInterfaces.sol";
import "../../util/CommonErrors.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract PTokenInternals is IPTokenInternals, CommonErrors {

    function _getExchangeRate() internal virtual override returns (uint256 exchangeRate) {
        if (totalSupply == 0 || underlying == address(0)) {
            exchangeRate = 10**EXCHANGE_RATE_DECIMALS;
        } else {
            exchangeRate = (_getCashPrior() * 10**EXCHANGE_RATE_DECIMALS) / totalSupply;
        }
        currentExchangeRate = exchangeRate;
    }

    function _getCashPrior() internal virtual override view returns (uint256) {
        if (underlying == address(0)) return address(this).balance;
        IERC20 token = IERC20(underlying);
        return token.balanceOf(address(this));
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./PTokenStorage.sol";
import "../../util/CommonErrors.sol";

abstract contract PTokenModifiers is PTokenStorage, CommonErrors {
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

import "../../master/irm/interfaces/IIRM.sol";

abstract contract PTokenEvents {

    /*** User Events ***/

    event DepositSent(
        address indexed user,
        address indexed pToken,
        uint256 amount
    );

    event WithdrawSent(
        address indexed user,
        address indexed pToken,
        uint256 accountTokens,
        uint256 withdrawAmount
    );

     event WithdrawApproved(
         address indexed user,
         address indexed pToken,
         uint256 withdrawAmount,
         bool isWithdrawAllowed
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

import "../../../interfaces/IHelper.sol";

abstract contract IPTokenMessageHandler {

    function completeWithdraw(
        IHelper.FBWithdraw memory params
    ) external virtual;

    function seize(
        IHelper.SLiquidateBorrow memory params
    ) external virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./CommonErrors.sol";

abstract contract SafeTransfers is CommonErrors {
    
    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    // slither-disable-next-line assembly
    function _doTransferIn(
        address underlying,
        uint256 amount
    ) internal virtual returns (uint256) {
        if (underlying == address(0)) {
            if (msg.value < amount) revert TransferFailed(msg.sender, address(this));
            return amount;
        }
        IERC20 token = IERC20(underlying);
        uint256 balanceBefore = IERC20(underlying).balanceOf(address(this));
        
        // ? We are checking the transfer, but since we are doing so in an assembly block
        // ? Slither does not pick up on that and results in a hit
        // slither-disable-next-line unchecked-transfer
        token.transferFrom(msg.sender, address(this), amount);

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
        uint256 balanceAfter = IERC20(underlying).balanceOf(address(this));

        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    /**
    * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
    *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
    *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
    *      it is >= amount, this should not revert in normal conditions.
    *
    *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
    *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
    */
    // slither-disable-next-line assembly
    function _doTransferOut(
        address to,
        address underlying,
        uint256 amount
    ) internal virtual {
        if (underlying == address(0)) {
            if (address(this).balance < amount) revert TransferFailed(address(this), to);
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

interface IIRM {
    function setBasisPointsTickSize(uint256 price) external /* onlyAdmin() */ returns (uint256 tickSize);
    function setBasisPointsUpperTick(uint256 upperTick) external /* onlyAdmin() */ returns (uint256 tick);
    function setBasisPointsLowerTick(uint256 lowerTick) external /* onlyAdmin() */ returns (uint256 tick);
    function setlowerTargetRatio(uint256 lowerPrice) external /* onlyAdmin() */ returns (uint256 price);
    function setupperTargetRatio(uint256 upperPrice) external /* onlyAdmin() */ returns (uint256 price);
    function setBorrowRate() external /* OnlyRouter() */ returns (uint256 rate);
    function setRouter(address router) external /* onlyAdmin() */;
    function setObservationPeriod(uint256 obsPeriod) external /* onlyAdmin() */ returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ICRM {
    function getLoanMarketPremium(
        uint256 loanMarketUnderlyingChainId,
        address loanMarketUnderlying
    ) external view returns (uint256 ratio, uint8 decimals);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../PTokenStorage.sol";

abstract contract IPTokenInternals is PTokenStorage {//is IERC20 {

    function _sendDeposit(
        address route,
        uint256 gas,
        uint256 depositAmount,
        uint256 exchangeRate
    ) internal virtual;

    function _sendWithdraw(
        address user,
        address route,
        uint256 withdrawAmount,
        uint256 exchangeRate
    ) internal virtual;

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    function _getCashPrior() internal virtual view returns (uint256);

    /**
     * @notice Retrieves the exchange rate for a given token.
     * @dev Will always be 1 for non-IB/Rebase tokens.
     */
    function _getExchangeRate() internal virtual returns (uint256 exchangeRate);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract CTokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    // Maximum borrow rate that can ever be applied (.0005% / block)
    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    // Maximum fraction of interest that can be set aside for reserves
    uint internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    ComptrollerInterface public comptroller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    // Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
    uint internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    // Official record of token balances for each account
    mapping (address => uint) internal accountTokens;

    // Approved token transfer amounts on behalf of others
    mapping (address => mapping (address => uint)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    // Mapping of account addresses to outstanding borrow balances
    mapping(address => BorrowSnapshot) internal accountBorrows;

    /**
     * @notice Share of seized collateral that is added to reserves
     */
    uint public constant protocolSeizeShareMantissa = 2.8e16; //2.8%
}

abstract contract CTokenInterface is CTokenStorage {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    bool public constant isCToken = true;

    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Deposit(address minter, uint mintAmount, uint depositAmount);

    /**
     * @notice Event emitted when tokens are withdrawed
     */
    event Withdraw(address withdrawer, uint withdrawAmount, uint withdrawTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address cTokenCollateral, uint seizeTokens);

    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(ComptrollerInterface oldComptroller, ComptrollerInterface newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /*** User Interface ***/

    function transfer(address dst, uint amount) virtual external returns (bool);
    function transferFrom(address src, address dst, uint amount) virtual external returns (bool);
    function approve(address spender, uint amount) virtual external returns (bool);
    function allowance(address owner, address spender) virtual external view returns (uint);
    function balanceOf(address owner) virtual external view returns (uint);
    function balanceOfUnderlying(address owner) virtual external returns (uint);
    function getAccountSnapshot(address account) virtual external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() virtual external view returns (uint);
    function supplyRatePerBlock() virtual external view returns (uint);
    function totalBorrowsCurrent() virtual external returns (uint);
    function borrowBalanceCurrent(address account) virtual external returns (uint);
    function borrowBalanceStored(address account) virtual external view returns (uint);
    function exchangeRateCurrent() virtual external returns (uint);
    function exchangeRateStored() virtual external view returns (uint);
    function getCash() virtual external view returns (uint);
    function accrueInterest() virtual external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) virtual external returns (uint);


    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) virtual external returns (uint);
    function _acceptAdmin() virtual external returns (uint);
    function _setComptroller(ComptrollerInterface newComptroller) virtual external returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) virtual external returns (uint);
    function _reduceReserves(uint reduceAmount) virtual external returns (uint);
    function _setInterestRateModel(InterestRateModel newInterestRateModel) virtual external returns (uint);
}

/**
  * @title Compound's InterestRateModel Interface
  * @author Compound
  */
abstract contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) virtual external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) virtual external view returns (uint);
}

abstract contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) virtual external returns (uint[] memory);
    function exitMarket(address cToken) virtual external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address cToken, address minter, uint mintAmount) virtual external returns (uint);
    function mintVerify(address cToken, address minter, uint mintAmount, uint depositAmount) virtual external;

    function withdrawAllowed(address cToken, address withdrawer, uint withdrawTokens) virtual external returns (uint);
    function withdrawVerify(address cToken, address withdrawer, uint withdrawAmount, uint withdrawTokens) virtual external;

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) virtual external returns (uint);
    function borrowVerify(address cToken, address borrower, uint borrowAmount) virtual external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) virtual external returns (uint);
    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) virtual external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) virtual external returns (uint);
    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) virtual external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) virtual external returns (uint);
    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) virtual external;

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) virtual external returns (uint);
    function transferVerify(address cToken, address src, address dst, uint transferTokens) virtual external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) virtual external view returns (uint, uint);
}