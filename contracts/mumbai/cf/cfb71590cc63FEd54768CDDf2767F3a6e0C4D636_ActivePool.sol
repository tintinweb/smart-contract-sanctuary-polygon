// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./Interfaces/IActivePool.sol";
import "./Interfaces/IPreonController.sol";
import "./Interfaces/IERC20.sol";
import "./Interfaces/IPreonVaultToken.sol";
import "./Interfaces/IDefaultPool.sol";
import "./Dependencies/SafeMath.sol";
import "./Dependencies/PoolBase2.sol";
import "./Dependencies/SafeERC20.sol";

/**
 * @title Holds the all collateral and STAR debt (but not STAR tokens) for all active troves
 * @notice When a trove is liquidated, its collateral and STAR debt are transferred from the Active Pool, to either the
 * Stability Pool, the Default Pool, or both, depending on the liquidation conditions
 */
contract ActivePool is IActivePool, PoolBase2 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant NAME = "ActivePool";

    address internal borrowerOperationsAddress;
    address internal troveManagerAddress;
    address internal stabilityPoolAddress;
    address internal defaultPoolAddress;
    address internal troveManagerLiquidationsAddress;
    address internal troveManagerRedemptionsAddress;
    address internal collSurplusPoolAddress;

    // deposited collateral tracker. Colls is always the controller list of all collateral tokens. Amounts
    newColls internal poolColl;

    // STAR Debt tracker. Tracker of all debt in the system.
    uint256 public STARDebt;

    // --- Events ---

    // event ActivePoolSTARDebtUpdated(uint _STARDebt);
    event ActivePoolBalanceUpdated(address _collateral, uint _amount);
    event ActivePoolBalancesUpdated(address[] _collaterals, uint256[] _amounts);
    event CollateralsSent(
        address[] _collaterals,
        uint256[] _amounts,
        address _to
    );

    // --- Contract setters ---
    bool private addressSet;

    /**
     * @notice Sets the addresses of all contracts used
     */
    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _stabilityPoolAddress,
        address _defaultPoolAddress,
        address _controllerAddress,
        address _troveManagerLiquidationsAddress,
        address _troveManagerRedemptionsAddress,
        address _collSurplusPoolAddress
    ) external {
        require(addressSet == false, "Addresses already set");
        addressSet = true;

        borrowerOperationsAddress = _borrowerOperationsAddress;
        troveManagerAddress = _troveManagerAddress;
        stabilityPoolAddress = _stabilityPoolAddress;
        defaultPoolAddress = _defaultPoolAddress;
        controller = IPreonController(_controllerAddress);
        troveManagerLiquidationsAddress = _troveManagerLiquidationsAddress;
        troveManagerRedemptionsAddress = _troveManagerRedemptionsAddress;
        collSurplusPoolAddress = _collSurplusPoolAddress;
    }

    // --- Getters for public variables. Required by IPool interface ---

    /**
     * @notice Returns the amount of a given collateral in state. Not necessarily the contract's actual balance since people can
     *  send collateral in
     */
    function getCollateral(address _collateral)
        public
        view
        override
        returns (uint256)
    {
        return poolColl.amounts[controller.getIndex(_collateral)];
    }

    /**
     * @notice Returns all collateral balances in state. Not necessarily the contract's actual balances. since people can send collateral in
     */
    function getAllCollateral()
        external
        view
        override
        returns (address[] memory, uint256[] memory)
    {
        return (poolColl.tokens, poolColl.amounts);
    }

    /**
     * @notice returns the VC value of a given collateralAddress in this contract
     * @param _collateral The address of the collateral
     */
    function getCollateralVC(address _collateral)
        external
        view
        override
        returns (uint256)
    {
        return controller.getValueVC(_collateral, getCollateral(_collateral));
    }

    /**
     * @notice returns the individual Amount value of a subset of collaterals in this contract and the Default Pool
     * contract as well. AP + DP Balance
     * @dev used in getTotalVariableDepositFeeAndUpdate in PreonController
     * @param _collaterals collaterals to get the amount value of
     * @return the Amounts of the collaterals in this contract and the Default Pool
     */
    function getAmountsSubsetSystem(address[] memory _collaterals)
        external
        view
        override
        returns (uint256[] memory)
    {
        (
            uint256[] memory summedAmounts,
            uint256[] memory controllerIndices
        ) = IDefaultPool(defaultPoolAddress).getAmountsSubset(_collaterals);
        for (uint i = 0; i < _collaterals.length; i++) {
            summedAmounts[i] = summedAmounts[i].add(
                poolColl.amounts[controllerIndices[i]]
            );
        }
        return summedAmounts;
    }

    /**
     * @notice Returns the VC value of the contract's collateral held
     * @dev Not necessarily equal to the the contract's raw VC balance - Collateral can be forcibly sent to contracts
     *  Computed when called by taking the collateral balances and multiplying them by the corresponding price and ratio and then summing that
     */
    function getVC() external view override returns (uint256 totalVC) {
        return controller.getValuesVC(poolColl.tokens, poolColl.amounts);
    }

    /**
     * @notice Function for aggregating active pool and default pool amounts when looping through
     * @dev more gas efficient than looping through through all coll in both default pool and this pool
     */
    function getVCSystem()
        external
        view
        override
        returns (uint256 totalVCSystem)
    {
        uint256 len = poolColl.tokens.length;
        uint256[] memory summedAmounts = IDefaultPool(defaultPoolAddress)
            .getAllAmounts();
        for (uint256 i; i < len; ++i) {
            summedAmounts[i] = summedAmounts[i].add(poolColl.amounts[i]);
        }
        return controller.getValuesVC(poolColl.tokens, summedAmounts);
    }

    /**
     * @notice Returns VC as well as RVC of the collateral in this contract
     * @return totalVC the VC using collateral weight
     * @return totalRVC the VC using redemption collateral weight
     */
    function getVCAndRVC()
        external
        view
        override
        returns (uint256 totalVC, uint256 totalRVC)
    {
        (totalVC, totalRVC) = controller.getValuesVCAndRVC(
            poolColl.tokens,
            poolColl.amounts
        );
    }

    /**
     * @notice Function for getting the VC value but using the Recovery ratio instead of the safety ratio
     * @dev Aggregates active pool and default pool amounts in one function loop for gas efficiency
     * @return totalVC VC value of the collateral in this contract, using safety ratio
     * @return totalRVC VC value of the collateral in this contract, using recovery ratio
     */
    function getVCAndRVCSystem()
        external
        view
        override
        returns (uint256 totalVC, uint256 totalRVC)
    {
        uint256 len = poolColl.tokens.length;
        uint256[] memory summedAmounts = IDefaultPool(defaultPoolAddress)
            .getAllAmounts();
        for (uint256 i; i < len; ++i) {
            summedAmounts[i] = summedAmounts[i].add(poolColl.amounts[i]);
        }
        (totalVC, totalRVC) = controller.getValuesVCAndRVC(
            poolColl.tokens,
            summedAmounts
        );
    }

    /**
     * @notice returns STAR Debt that this pool holds
     */
    function getSTARDebt() external view override returns (uint256) {
        return STARDebt;
    }

    // --- Pool functionality ---

    /**
     * @notice Internal function to send collateral out of this contract
     * @param _to Address to sent collateral to
     * @param _collateral Address of collateral
     * @param _amount The amount of collateral to be sent
     */
    function _sendCollateral(
        address _to,
        address _collateral,
        uint256 _amount,
        uint256 _index
    ) internal {
        _logCollateralDecrease(_to, _collateral, _amount, _index);
        IERC20(_collateral).safeTransfer(_to, _amount);
    }

    /**
     * @notice Internal function to log collateral decrease, after sending
     * collateral out either from just a transfer or from vault token action
     */
    function _logCollateralDecrease(
        address _to,
        address _collateral,
        uint256 _amount,
        uint256 _index
    ) internal {
        poolColl.amounts[_index] = poolColl.amounts[_index].sub(_amount);
        emit ActivePoolBalanceUpdated(_collateral, _amount);
        emit CollateralSent(_collateral, _to, _amount);
    }

    /**
     * @notice Function sends multiple collaterals from active pool. If the receiver is a pool, updates the balance.
     * @dev Must be called by borrower operations, trove manager, or stability pool
     * @param _to Address to send collateral to
     * @param _tokens Number of tokens
     * @param _amounts Amount of collateral to be sent
     */
    function sendCollaterals(
        address _to,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external override {
        _requireCallerIsBOorTroveMorTMLorSP();
        uint256 len = _tokens.length;
        require(len == _amounts.length, "AP:Lengths");
        uint256[] memory indices = controller.getIndices(_tokens);
        for (uint256 i; i < len; ++i) {
            uint256 thisAmount = _amounts[i];
            if (thisAmount != 0) {
                _sendCollateral(_to, _tokens[i], thisAmount, indices[i]); // reverts if send fails
            }
        }

        if (_needsUpdateCollateral(_to)) {
            ICollateralReceiver(_to).receiveCollateral(_tokens, _amounts);
        }

        emit CollateralsSent(_tokens, _amounts, _to);
    }

    /**
     * @notice This function calls unwraps the collaterals and sends them to _to, if they are vault tokens assets.
     * @dev Not callable from outside the protocol
     * @param _to Address of where collaterals send to
     * @param _tokens Collateral list addresses
     * @param _amounts Amount list of collateral to be sent
     */
    function sendCollateralsUnwrap(
        address _to,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external override {
        _requireCallerIsBOorTroveMorTMLorSP();
        uint256 tokensLen = _tokens.length;
        require(tokensLen == _amounts.length, "AP:Lengths");
        uint256[] memory indices = controller.getIndices(_tokens);
        bool[] memory isWrapped = controller.isWrappedMany(_tokens);
        for (uint256 i; i < tokensLen; ++i) {
            uint256 amount = _amounts[i];
            if (amount != 0) {
                if (isWrapped[i]) {
                    address collateral = _tokens[i];

                    // Update pool coll tracker
                    _logCollateralDecrease(_to, collateral, amount, indices[i]);

                    // Unwraps for original owner. _amounts[i] is in terms of the receipt token, and
                    // the user will receive back the underlying based on the current exchange rate.
                    IPreonVaultToken(collateral).redeem(_to, amount);
                } else {
                    _sendCollateral(_to, _tokens[i], amount, indices[i]); // reverts if send fails
                }
            }
        }
    }

    /**
     * @notice Function for sending single collateral
     */
    function sendSingleCollateral(
        address _to,
        address _token,
        uint256 _amount
    ) external override {
        _requireCallerIsBOorTMorTML();
        _sendCollateral(_to, _token, _amount, controller.getIndex(_token)); // reverts if send fails
    }

    /**
     * @notice Function for sending single collateral and unwrapping. Currently only used by borrower operations unlever up functionality
     * Unwraps asset for the user in that case.
     */
    function sendSingleCollateralUnwrap(
        address _to,
        address _token,
        uint256 _amount
    ) external override {
        _requireCallerIsBorrowerOperations();
        if (controller.isWrapped(_token)) {
            // Unwraps for original owner. _amounts[i] is in terms of the receipt token, and
            // the user will receive back the underlying based on the current exchange rate.
            _logCollateralDecrease(
                _to,
                _token,
                _amount,
                controller.getIndex(_token)
            );
            IPreonVaultToken(_token).redeem(_to, _amount);
        } else {
            _sendCollateral(_to, _token, _amount, controller.getIndex(_token)); // reverts if send fails
        }
    }

    /**
     * @notice View function that returns if the contract transferring to needs to have its balances updated, aka is a pool in the protocol other than this one.
     * @param _contractAddress The address of the contract
     * @return True if balances need to be updated, False if balances don't need to be updated
     */
    function _needsUpdateCollateral(address _contractAddress)
        internal
        view
        returns (bool)
    {
        return ((_contractAddress == defaultPoolAddress) ||
            (_contractAddress == stabilityPoolAddress) ||
            (_contractAddress == collSurplusPoolAddress));
    }

    /**
     * @notice Increases the tracked STAR Debt of this pool.
     * @param _amount to increase by
     */
    function increaseSTARDebt(uint256 _amount) external override {
        _requireCallerIsBOorTMorTML();
        STARDebt = STARDebt.add(_amount);
        emit ActivePoolSTARDebtUpdated(STARDebt);
    }

    /**
     * @notice Increases the tracked STAR Debt of this pool.
     * @param _amount to decrease by
     */
    function decreaseSTARDebt(uint256 _amount) external override {
        _requireCallerIsBOorTroveMorSP();
        STARDebt = STARDebt.sub(_amount);
        emit ActivePoolSTARDebtUpdated(STARDebt);
    }

    /**
     * @dev should be called by BorrowerOperations or DefaultPool
     * __after__ collateral is transferred to this contract
     */
    function receiveCollateral(
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external override {
        _requireCallerIsBorrowerOperationsOrDefaultPool();
        poolColl.amounts = _leftSumColls(poolColl, _tokens, _amounts);
        emit ActivePoolBalancesUpdated(_tokens, _amounts);
    }

    /**
     * @notice Adds collateral type from controller. The controller whitelisted list of collateral should always be
     * equal to the whitelisted ActivePool poolColl list.
     * @param _collateral The address of the collateral
     */
    function addCollateralType(address _collateral) external override {
        _requireCallerIsPreonController();
        poolColl.tokens.push(_collateral);
        poolColl.amounts.push(0);
    }

    // --- 'require' functions ---

    function _requireCallerIsBOorTroveMorTMLorSP() internal view {
        if (
            msg.sender != borrowerOperationsAddress &&
            msg.sender != troveManagerAddress &&
            msg.sender != stabilityPoolAddress &&
            msg.sender != troveManagerLiquidationsAddress &&
            msg.sender != troveManagerRedemptionsAddress
        ) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsBorrowerOperationsOrDefaultPool() internal view {
        if (
            msg.sender != borrowerOperationsAddress &&
            msg.sender != defaultPoolAddress
        ) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsBorrowerOperations() internal view {
        if (msg.sender != borrowerOperationsAddress) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsBOorTroveMorSP() internal view {
        if (
            msg.sender != borrowerOperationsAddress &&
            msg.sender != troveManagerAddress &&
            msg.sender != stabilityPoolAddress &&
            msg.sender != troveManagerRedemptionsAddress
        ) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsBOorTMorTML() internal view {
        if (
            msg.sender != borrowerOperationsAddress &&
            msg.sender != troveManagerAddress &&
            msg.sender != troveManagerLiquidationsAddress
        ) {
            _revertWrongFuncCaller();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @notice Checks if 'account' is a contract
     * @dev It is unsafe to assume that an address for which this function returns
        false is an externally-owned account (EOA) and not a contract.
        Among others, `isContract` will return false for the following
        types of addresses:
        - an externally-owned account
        - a contract in construction
        - an address where a contract will be created
        - an address where a contract lived, but was destroyed
     * @param account The address of an account
     * @return true if account is a contract, false if account is not a contract
    */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size != 0;
    }

    /**
     * @notice sends `amount` wei to `recipient`, forwarding all available gas and reverting on errors.
     * @dev Replacement for Solidity's `transfer`
        https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
        of certain opcodes, possibly making contracts go over the 2300 gas limit
        imposed by `transfer`, making them unable to receive funds via
        `transfer`. {sendValue} removes this limitation.
        
        https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
        
        IMPORTANT: because control is transferred to `recipient`, care must be
        taken to not create reentrancy vulnerabilities. Consider using
        {ReentrancyGuard} or the
        https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     * @param recipient The address of where the wei 'amount' is sent to 
     * @param amount the 'amount' of wei to be transfered to 'recipient'
      */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @notice Performs a Solidity function call using a low level `call`.
     * @dev A plain`call` is an unsafe replacement for a function call: use this function instead.
        If `target` reverts with a revert reason, it is bubbled up by this
        function (like regular Solidity function calls).
        
        Returns the raw returned data. To convert to the expected return value,
        use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
        
        Requirements:
        
        - `target` must be a contract.
        - calling `target` with `data` must not revert.
        
        _Available since v3.1._
     * @param target The address of a contract
     * @param data In bytes 
     * @return Solidity's functionCall 
      */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    // function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    //     return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    // }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    // function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    //     require(isContract(target), "Address: delegate call to non-contract");

    //     // solhint-disable-next-line avoid-low-level-calls
    //     (bool success, bytes memory returndata) = target.delegatecall(data);
    //     return _verifyCallResult(success, returndata, errorMessage);
    // }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length != 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./PreonMath.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "./PreonCustomBase.sol";
import "./SafeMath.sol";

/*
 * Base contract for ActivePool and DefaultPool. Inherits from PreonCustomBase
 * and contains additional array operation functions and _requireCallerIsPreonController()
 */
contract PoolBase2 is PreonCustomBase {
    using SafeMath for uint256;
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;

    /**
     * @notice More efficient version of sumColls when dealing with all whitelisted tokens.
     *    Used by pool accounting of tokens inside that pool.
     * @dev Inspired by left join in relational databases, _coll1 is always taken while
     *    _tokens and _amounts are just added to that side. _coll1 index is actually equal
     *    always to the index in PreonController of that token. Time complexity depends
     *    here on the number of whitelisted tokens = L since that it equals pool coll length.
     *    Time complexity is therefore O(L)
     */
    function _leftSumColls(
        newColls memory _coll1,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal pure returns (uint[] memory) {
        // If nothing on the right side then return the original.
        if (_amounts.length == 0) {
            return _coll1.amounts;
        }

        uint256 coll1Len = _coll1.amounts.length;
        uint256 tokensLen = _tokens.length;
        // Result will always be coll1 len size.
        uint[] memory sumAmounts = new uint[](coll1Len);

        uint256 i = 0;
        uint256 j = 0;

        // Sum through all tokens until either left or right side reaches end.
        while (i < tokensLen && j < coll1Len) {
            // If tokens match up then sum them together.
            if (_tokens[i] == _coll1.tokens[j]) {
                sumAmounts[j] = _coll1.amounts[j].add(_amounts[i]);
                ++i;
            }
            // Otherwise just take the left side.
            else {
                sumAmounts[j] = _coll1.amounts[j];
            }
            ++j;
        }
        // If right side ran out add the remaining amounts in the left side.
        while (j < coll1Len) {
            sumAmounts[j] = _coll1.amounts[j];
            ++j;
        }

        return sumAmounts;
    }

    /**
     * @notice More efficient version of subColls when dealing with all whitelisted tokens.
     *    Used by pool accounting of tokens inside that pool.
     * @dev Inspired by left join in relational databases, _coll1 is always taken while
     *    _tokens and _amounts are just subbed from that side. _coll1 index is actually equal
     *    always to the index in PreonController of that token. Time complexity depends
     *    here on the number of whitelisted tokens = L since that it equals pool coll length.
     *    Time complexity is therefore O(L)
     */
    function _leftSubColls(
        newColls memory _coll1,
        address[] memory _subTokens,
        uint[] memory _subAmounts
    ) internal pure returns (uint[] memory) {
        // If nothing on the right side then return the original.
        if (_subTokens.length == 0) {
            return _coll1.amounts;
        }

        uint256 coll1Len = _coll1.amounts.length;
        uint256 tokensLen = _subTokens.length;
        // Result will always be coll1 len size.
        uint[] memory diffAmounts = new uint[](coll1Len);

        uint256 i = 0;
        uint256 j = 0;

        // Sub through all tokens until either left or right side reaches end.
        while (i < tokensLen && j < coll1Len) {
            // If tokens match up then subtract them
            if (_subTokens[i] == _coll1.tokens[j]) {
                diffAmounts[j] = _coll1.amounts[j].sub(_subAmounts[i]);
                ++i;
            }
            // Otherwise just take the left side.
            else {
                diffAmounts[j] = _coll1.amounts[j];
            }
            ++j;
        }
        // If right side ran out add the remaining amounts in the left side.
        while (j < coll1Len) {
            diffAmounts[j] = _coll1.amounts[j];
            ++j;
        }

        return diffAmounts;
    }

    function _requireCallerIsPreonController() internal view {
        if (msg.sender != address(controller)) {
            _revertWrongFuncCaller();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./SafeMath.sol";
import "../Interfaces/IERC20.sol";
import "../Interfaces/IPreonController.sol";

/**
 * Contains shared functionality for many of the system files
 * PreonCustomBase is inherited by PoolBase2 and LiquityBase
 */

contract PreonCustomBase {
    using SafeMath for uint256;

    IPreonController internal controller;

    struct newColls {
        // tokens and amounts should be the same length
        address[] tokens;
        uint256[] amounts;
    }

    uint256 public constant DECIMAL_PRECISION = 1e18;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    /**
     * @notice Returns _coll1.amounts plus _coll2.amounts
     * @dev Invariant that _coll1.tokens and _coll2.tokens are sorted by whitelist order of token indices from the PreonController.
     *    So, if WAVAX is whitelisted first, then WETH, then USDC, then [WAVAX, USDC] is a valid input order but [USDC, WAVAX] is not.
     *    This is done for gas efficiency. We use a sliding window approach to increment the indices of the tokens we are adding together
     *    from _coll1 and from _coll2. We will start at tokenIndex1 and tokenIndex2. To keep the invariant of ordered collateral in
     *    each trove, we need to merge coll1 and coll2 in order based on the PreonController whitelist order. If the token indices
     *    line up, then they are the same and we add the sum. Otherwise we add the smaller index to keep them in order and move on.
     *    Once we reach the end of either tokens1 or tokens2, we add the remaining ones to the sum individually without summing.
     *    n is the number of tokens in the coll1, and m is the number of tokens in the coll2. k is defined as the number of tokens
     *    in the summed version. k = n + m - (overlap). The time complexity here depends on O(n + m) in the first loop and tail calls,
     *    and O(k) in the last loop. The total time complexity is O(n + m + k). If we assume that n is bigger than m(arbitrary between
     *    n and m), then since k is bounded by n we can say the time complexity is O(3n). This does not depend on all whitelisted tokens.
     */
    function _sumColls(newColls memory _coll1, newColls memory _coll2)
        internal
        view
        returns (newColls memory finalColls)
    {
        uint256 coll2Len = _coll2.tokens.length;
        uint256 coll1Len = _coll1.tokens.length;
        // If either is 0 then just return the other one.
        if (coll2Len == 0) {
            return _coll1;
        } else if (coll1Len == 0) {
            return _coll2;
        }
        // Create temporary n + m sized array.
        newColls memory coll3;
        coll3.tokens = new address[](coll1Len + coll2Len);
        coll3.amounts = new uint256[](coll1Len + coll2Len);

        // Tracker for the coll1 array.
        uint256 i = 0;
        // Tracker for the coll2 array.
        uint256 j = 0;
        // Tracker for nonzero entries.
        uint256 k = 0;

        uint256[] memory tokenIndices1 = controller.getIndices(_coll1.tokens);
        uint256[] memory tokenIndices2 = controller.getIndices(_coll2.tokens);

        // Tracker for token whitelist index for all coll1
        uint256 tokenIndex1 = tokenIndices1[i];
        // Tracker for token whitelist index for all coll2
        uint256 tokenIndex2 = tokenIndices2[j];

        // This loop will break out if either token index reaches the end inside the conditions.
        while (true) {
            if (tokenIndex1 < tokenIndex2) {
                // If tokenIndex1 is less than tokenIndex2 then that means it should be added first by itself.
                coll3.tokens[k] = _coll1.tokens[i];
                coll3.amounts[k] = _coll1.amounts[i];
                ++i;
                // If we reached the end of coll1 then we exit out.
                if (i == coll1Len) {
                    break;
                }
                tokenIndex1 = tokenIndices1[i];
            } else if (tokenIndex2 < tokenIndex1) {
                // If tokenIndex2 is less than tokenIndex1 then that means it should be added first by itself.
                coll3.tokens[k] = _coll2.tokens[j];
                coll3.amounts[k] = _coll2.amounts[j];
                ++j;
                // If we reached the end of coll2 then we exit out.
                if (j == coll2Len) {
                    break;
                }
                tokenIndex2 = tokenIndices2[j];
            } else {
                // If the token indices match up then they are the same token, so we add them together.
                coll3.tokens[k] = _coll1.tokens[i];
                coll3.amounts[k] = _coll1.amounts[i].add(_coll2.amounts[j]);
                ++i;
                ++j;
                // If we reached the end of coll1 or coll2 then we exit out.
                if (i == coll1Len || j == coll2Len) {
                    break;
                }
                tokenIndex1 = tokenIndices1[i];
                tokenIndex2 = tokenIndices2[j];
            }
            ++k;
        }
        ++k;
        // Add remaining tokens from coll1 if we reached the end of coll2 inside the previous loop.
        while (i < coll1Len) {
            coll3.tokens[k] = _coll1.tokens[i];
            coll3.amounts[k] = _coll1.amounts[i];
            ++i;
            ++k;
        }
        // Add remaining tokens from coll2 if we reached the end of coll1 inside the previous loop.
        while (j < coll2Len) {
            coll3.tokens[k] = _coll2.tokens[j];
            coll3.amounts[k] = _coll2.amounts[j];
            ++j;
            ++k;
        }

        // K is the resulting amount of nonzero entries that are in coll3, so we add them to finalTokens and return.
        address[] memory sumTokens = new address[](k);
        uint256[] memory sumAmounts = new uint256[](k);
        for (i = 0; i < k; ++i) {
            sumTokens[i] = coll3.tokens[i];
            sumAmounts[i] = coll3.amounts[i];
        }

        finalColls.tokens = sumTokens;
        finalColls.amounts = sumAmounts;
    }

    function _revertWrongFuncCaller() internal pure {
        revert("WFC");
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./SafeMath.sol";

library PreonMath {
    using SafeMath for uint;
    using SafeMath for uint256;

    uint internal constant DECIMAL_PRECISION = 1e18;
    uint internal constant HALF_DECIMAL_PRECISION = 5e17;

    function _min(uint _a, uint _b) internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a : _b;
    }

    /**
     * @notice Multiply two decimal numbers 
     * @dev Use normal rounding rules: 
        -round product up if 19'th mantissa digit >= 5
        -round product down if 19'th mantissa digit < 5
     */
    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x.mul(y);

        decProd = prod_xy.add(HALF_DECIMAL_PRECISION).div(DECIMAL_PRECISION);
    }

    /*
     * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
     *
     * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
     *
     * Called by two functions that represent time in units of minutes:
     * 1) TroveManager._calcDecayedBaseRate
     * 2) CommunityIssuance._getCumulativeIssuanceFraction
     *
     * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
     * "minutes in 1000 years": 60 * 24 * 365 * 1000
     *
     * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
     * negligibly different from just passing the cap, since:
     *
     * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
     * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
     */
    function _decPow(uint _base, uint _minutes) internal pure returns (uint) {
        if (_minutes > 5256e5) {
            _minutes = 5256e5;
        } // cap to avoid overflow

        if (_minutes == 0) {
            return DECIMAL_PRECISION;
        }

        uint y = DECIMAL_PRECISION;
        uint x = _base;
        uint n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n.div(2);
            } else {
                // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }

        return decMul(x, y);
    }

    function _getAbsoluteDifference(uint _a, uint _b)
        internal
        pure
        returns (uint)
    {
        return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.2;

import "../Interfaces/IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        require(
            oldAllowance >= value,
            "SafeERC20: decreased allowance below zero"
        );
        uint256 newAllowance = oldAllowance - value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length != 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library SafeMathJoe {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "div by 0");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b != 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./IPool.sol";

interface IActivePool is IPool {
    // --- Events ---
    event ActivePoolSTARDebtUpdated(uint _STARDebt);
    event ActivePoolCollateralBalanceUpdated(address _collateral, uint _amount);

    // --- Functions ---

    function sendCollaterals(
        address _to,
        address[] memory _tokens,
        uint[] memory _amounts
    ) external;

    function sendCollateralsUnwrap(
        address _to,
        address[] memory _tokens,
        uint[] memory _amounts
    ) external;

    function sendSingleCollateral(
        address _to,
        address _token,
        uint256 _amount
    ) external;

    function sendSingleCollateralUnwrap(
        address _to,
        address _token,
        uint256 _amount
    ) external;

    function getCollateralVC(address collateralAddress)
        external
        view
        returns (uint);

    function addCollateralType(address _collateral) external;

    function getAmountsSubsetSystem(address[] memory _collaterals)
        external
        view
        returns (uint256[] memory);

    function getVCSystem() external view returns (uint256 totalVCSystem);

    function getVCAndRVCSystem()
        external
        view
        returns (uint256 totalVC, uint256 totalRVC);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

interface ICollateralReceiver {
    function receiveCollateral(address[] memory _tokens, uint[] memory _amounts)
        external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./IPool.sol";

interface IDefaultPool is IPool {
    // --- Events ---
    event DefaultPoolSTARDebtUpdated(uint256 _STARDebt);
    event DefaultPoolETHBalanceUpdated(uint256 _ETH);

    // --- Functions ---

    function sendCollsToActivePool(
        address[] memory _collaterals,
        uint256[] memory _amounts
    ) external;

    function addCollateralType(address _collateral) external;

    function getCollateralVC(address collateralAddress)
        external
        view
        returns (uint256);

    function getAmountsSubset(address[] memory _collaterals)
        external
        view
        returns (uint256[] memory amounts, uint256[] memory controllerIndices);

    function getAllAmounts() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    // event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    // event Approval(
    //     address indexed owner,
    //     address indexed spender,
    //     uint256 value
    // );
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./ICollateralReceiver.sol";

// Common interface for the Pools.
interface IPool is ICollateralReceiver {
    // --- Events ---

    event ETHBalanceUpdated(uint _newBalance);
    event STARBalanceUpdated(uint _newBalance);
    event EtherSent(address _to, uint _amount);
    event CollateralSent(address _collateral, address _to, uint _amount);

    // --- Functions ---

    function getVC() external view returns (uint totalVC);

    function getVCAndRVC() external view returns (uint totalVC, uint totalRVC);

    function getCollateral(address collateralAddress)
        external
        view
        returns (uint);

    function getAllCollateral()
        external
        view
        returns (address[] memory, uint256[] memory);

    function getSTARDebt() external view returns (uint);

    function increaseSTARDebt(uint _amount) external;

    function decreaseSTARDebt(uint _amount) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

interface IPreonController {
    struct Addresses {
        address _activePoolAddress;
        address _defaultPoolAddress;
        address _stabilityPoolAddress;
        address _collSurplusPoolAddress;
        address _borrowerOperationsAddress;
        address _starTokenAddress;
        address _STARFeeRecipientAddress;
        address _preonFinanceTreasury;
        address _sortedTrovesAddress;
        address _vePREONAddress;
        address _troveManagerRedemptionsAddress;
        address _claimAddress;
        address _threeDayTimelock;
        address _twoWeekTimelock;
    }

    // ======== Mutable Only Owner-Instantaneous ========
    function setAddresses(Addresses memory _addresses) external;

    function endBootstrap() external;

    function deprecateAllCollateral() external;

    function deprecateCollateral(address _collateral) external;

    function setLeverUp(bool _enabled) external;

    function setFeeBootstrapPeriodEnabled(bool _enabled) external;

    function updateGlobalSTARMinting(bool _canMint) external;

    function removeValidSTARMinter(address _minter) external;

    function removeVePreonCaller(address _contractAddress) external;

    function updateRedemptionsEnabled(bool _enabled) external;

    function changeFeeCurve(address _collateral, address _feeCurve) external;

    // ======== Mutable Only Owner-3 Day TimeLock ========
    function addCollateral(
        address _collateral,
        uint256 _safetyRatio,
        uint256 _recoveryRatio,
        address _oracle,
        uint256 _decimals,
        address _feeCurve,
        bool _isWrapped,
        address _routerAddress
    ) external;

    function unDeprecateCollateral(address _collateral) external;

    function updateMaxCollsInTrove(uint _newMax) external;

    function changeRatios(
        address _collateral,
        uint256 _newSafetyRatio,
        uint256 _newRecoveryRatio
    ) external;

    function setDefaultRouter(address _collateral, address _router) external;

    function changePreonFinanceTreasury(address _newTreasury) external;

    function changeClaimAddress(address _newClaimAddress) external;

    function changeSTARFeeRecipient(address _newFeeRecipient) external;

    function changePreonFinanceTreasurySplit(uint256 _newSplit) external;

    function changeRedemptionBorrowerFeeSplit(uint256 _newSplit) external;

    function updateAbsorptionColls(
        address[] memory _colls,
        uint[] memory _weights
    ) external;

    function changeOracle(address _collateral, address _oracle) external;

    // ======== Mutable Only Owner-2 Week TimeLock ========
    function addValidSTARMinter(address _minter) external;

    function changeBoostMinuteDecayFactor(uint256 _newBoostMinuteDecayFactor)
        external;

    function changeGlobalBoostMultiplier(uint256 _newBoostMinuteDecayFactor)
        external;

    function addVePreonCaller(address _contractAddress) external;

    function updateMaxSystemColls(uint _newMax) external;

    // ======= VIEW FUNCTIONS FOR COLLATERAL PARAMS =======
    function getValidCollateral() external view returns (address[] memory);

    function getOracle(address _collateral) external view returns (address);

    function getSafetyRatio(address _collateral)
        external
        view
        returns (uint256);

    function getRecoveryRatio(address _collateral)
        external
        view
        returns (uint256);

    function getIsActive(address _collateral) external view returns (bool);

    function getFeeCurve(address _collateral) external view returns (address);

    function getDecimals(address _collateral) external view returns (uint256);

    function getIndex(address _collateral) external view returns (uint256);

    function getIndices(address[] memory _colls)
        external
        view
        returns (uint256[] memory indices);

    function checkCollateralListSingle(address[] memory _colls, bool _deposit)
        external
        view;

    function checkCollateralListDouble(
        address[] memory _depositColls,
        address[] memory _withdrawColls
    ) external view;

    function isWrapped(address _collateral) external view returns (bool);

    function isWrappedMany(address[] memory _collaterals)
        external
        view
        returns (bool[] memory wrapped);

    function getDefaultRouterAddress(address _collateral)
        external
        view
        returns (address);

    // ======= VIEW FUNCTIONS FOR VC / USD VALUE =======
    function getPrice(address _collateral) external view returns (uint256);

    function getValuesVC(address[] memory _collaterals, uint[] memory _amounts)
        external
        view
        returns (uint);

    function getValuesRVC(address[] memory _collaterals, uint[] memory _amounts)
        external
        view
        returns (uint);

    function getValuesVCAndRVC(
        address[] memory _collaterals,
        uint[] memory _amounts
    ) external view returns (uint VC, uint256 RVC);

    function getValuesUSD(address[] memory _collaterals, uint[] memory _amounts)
        external
        view
        returns (uint256);

    function getValueVC(address _collateral, uint _amount)
        external
        view
        returns (uint);

    function getValueRVC(address _collateral, uint _amount)
        external
        view
        returns (uint);

    function getValueUSD(address _collateral, uint _amount)
        external
        view
        returns (uint256);

    function getValuesVCIndividual(
        address[] memory _collaterals,
        uint256[] memory _amounts
    ) external view returns (uint256[] memory);

    // ======= VIEW FUNCTIONS FOR CONTRACT FUNCTIONALITY =======
    function getPreonFinanceTreasury() external view returns (address);

    function getPreonFinanceTreasurySplit() external view returns (uint256);

    function getRedemptionBorrowerFeeSplit() external view returns (uint256);

    function getSTARFeeRecipient() external view returns (address);

    function leverUpEnabled() external view returns (bool);

    function getMaxCollsInTrove() external view returns (uint);

    function getFeeSplitInformation()
        external
        view
        returns (
            uint256,
            address,
            address
        );

    function getClaimAddress() external view returns (address);

    function getAbsorptionCollParams()
        external
        view
        returns (address[] memory, uint[] memory);

    function getVariableDepositFee(
        address _collateral,
        uint _collateralVCInput,
        uint256 _collateralVCBalancePost,
        uint256 _totalVCBalancePre,
        uint256 _totalVCBalancePost
    ) external view returns (uint256 fee);

    // ======== Mutable Function For Fees ========
    function getTotalVariableDepositFeeAndUpdate(
        address[] memory _tokensIn,
        uint256[] memory _amountsIn,
        uint256[] memory _leverages,
        uint256 _entireSystemCollVC,
        uint256 _VCin,
        uint256 _VCout
    ) external returns (uint256 STARFee, uint256 boostFactor);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

/**
 * @notice Interface for use of wrapping and unwrapping vault tokens in the Preon Finance borrowing
 * protocol.
 */
interface IPreonVaultToken {
    function deposit(uint256 _amt) external returns (uint256 receiptTokens);

    function depositFor(
        address _borrower,
        address _recipient,
        uint256 _amt
    ) external returns (uint256 receiptTokens);

    function redeem(address _to, uint256 _amt)
        external
        returns (uint256 underlyingTokens);

    function redeem(uint256 _amt) external returns (uint256 underlyingTokens);

    function redeemFor(
        uint256 _amt,
        address _from,
        address _to
    ) external returns (uint256 underlyingTokens);
}