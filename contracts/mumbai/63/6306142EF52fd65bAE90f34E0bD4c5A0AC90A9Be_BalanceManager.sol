//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import "./interfaces/IOddzConfig.sol";
import "./interfaces/IOrderManager.sol";
import "./interfaces/IIndexPrice.sol";
import "./utils/oddzOwnable.sol";
import "./maths/OddzMath.sol";
import "./interfaces/IOddzVault.sol";
import "./maths/OddzSafeCast.sol";

contract BalanceManager is OddzOwnable {
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;
    using OddzSafeCast for uint256;
    using OddzSafeCast for uint128;
    using OddzSafeCast for int256;
    using OddzMath for uint256;
    using OddzMath for uint128;
    using OddzMath for int256;

    // VARIALBLES
    //

    struct PositionInfo {
        bool grouped;   // true if position in any group
        uint256 groupID; // group id if position is in group otherwise 0 (group id starts from 1)
        address baseToken;  // base token address
        int256 takerBasePositionSize; //trader base token amount
        int256 takerQuoteSize; //trader quote token amount
        uint256 collateralForPosition; // allocated collateral for this position
        int256 owedRealizedPnl; // owed realized profit and loss
    }



    struct GroupPositionsInfo {
        uint256 positionID;  // position id
        address baseToken;  // base token of the position
    }

    struct GroupInfo {
        bool autoLeverage;
        bool active;
        GroupPositionsInfo[] groupPositions;  // all the positions this group holds
        uint256 collateralAllocated;          // collateral allocated to this group
        int256 owedRealizedPnl;               // owed realized profit and loss
    }

    address public oddzConfig;
    address public oddzVault;
    address public oddzClearingHouse;
    address public orderManager;

    // trader => baseTokens
    // base tokens of each trader
    mapping(address => address[]) public traderBaseTokens;


    // trader => total collateral used by the trader for positions
    mapping(address => uint256) public totalUsedCollateralInPositions;

    //trader =>  positionIDs
    mapping(address => uint256[]) public traderPositions;

    // first key: id , second key : position info
    mapping(uint256 => PositionInfo) public traderPositionInfo;

    //trader=> groupIDs
    mapping(address => uint256[]) public traderGroups;

    // group id => group info
    mapping(uint256 => GroupInfo) public groupInfo;

    uint256 internal constant _DUST = 10 wei;

    //EVENTS

    /// @dev Emit whenever a trader's `owedRealizedPnl` is updated
    /// @param trader The address of the trader
    /// @param amount The amount changed
    event PnlRealized(address indexed trader, int256 amount);

    modifier onlyClearingHouse() {
        require(
            _msgSender() == oddzClearingHouse,
            "BalanceManager: Only clearhouse allowed"
        );
        _;
    }

    function initialize(address _oddzConfig, address _oddzVault)
        external
        initializer
    {
        require(
            _oddzConfig.isContract(),
            "BalanceManager : config address is not a contract"
        );
        require(
            _oddzVault.isContract(),
            "BalanceManager : oddz vault address is not a contract"
        );
        __OddzOwnable_init();
        oddzConfig = _oddzConfig;
        oddzVault = _oddzVault;
    }

    /**
     * @notice Used to update clearing house contract address
     * @param _clearingHouse Address of the clearing house contract
     */

    function updateClearingHouse(address _clearingHouse) external onlyOwner {
        require(
            _clearingHouse.isContract(),
            "BalanceManager : clearing house address is not a contract"
        );
        oddzClearingHouse = _clearingHouse;
    }

    /**
     * @notice Used to update Order Manager contract address
     * @param _orderManager Address of the clearing house contract
     */

    function updateOrderManager(address _orderManager) external onlyOwner {
        require(
            _orderManager.isContract(),
            "BalanceManager : Order Manager address is not a contract"
        );
        orderManager = _orderManager;
    }

    /**
     * @notice Used to update market participation of a trader.In which markets , traders has their positions
     * @param _trader Address of the trader
     * @param _baseToken base token address for which trader is performing action currently
     * @param _include if true add the market otherwise remove the market for the trader
     */
    function updateBaseTokensForTrader(
        address _trader,
        address _baseToken,
        bool _include
    ) external onlyClearingHouse {
        address[] storage baseTokens = traderBaseTokens[_trader];
        uint256 baseTokensLength = baseTokens.length;
        if (_include) {
            for (uint256 i = 0; i < baseTokensLength; i++) {
                if (baseTokens[i] == _baseToken) {
                    return;
                }
            }
            baseTokens.push(_baseToken);
            require(
                baseTokens.length <=
                    IOddzConfig(oddzConfig).maxMarketsPerAccount(),
                "BalanceManger : exceeding max number of markets"
            );
        }
        //Remove the tokens from the trader participating market
        else {
            //Checks if trader has some tokens in the uniswap pools
            if (
                IOrderManager(orderManager)
                    .getCurrentOrderIdsMap(_trader, _baseToken)
                    .length > 0
            ) {
                return;
            }

            uint256[] memory positions = traderPositions[_trader];

            for (uint256 i = 0; i < positions.length; i++) {
                if (traderPositionInfo[positions[i]].baseToken == _baseToken) {
                    if (
                        traderPositionInfo[positions[i]]
                            .takerBasePositionSize
                            .abs() >=
                        _DUST ||
                        traderPositionInfo[positions[i]].takerQuoteSize.abs() >=
                        _DUST
                    ) {
                        return;
                    }
                }
            }
            for (uint256 i = 0; i < baseTokensLength; i++) {
                if (baseTokens[i] == _baseToken) {
                    // Is removable index is not the last index then we need to swap it and then pop otherwise directly pop it
                    if (i != baseTokensLength - 1) {
                        baseTokens[i] = baseTokens[baseTokensLength - 1];
                    }
                    baseTokens.pop();
                    break;
                }
            }
        }
    }


    /**
     * @notice Used to update positions id and collateral of a trader
     * @param _trader Address of the trader
     * @param _positionID position id
     * @param _collateralForPosition collateral used in position
     * @param _existing   if the position id already exist or not
     * @param _group     if position is in any group or not
     * @param _push       true if we want to add the position and false if we want to remove position 
     */
    function updateTraderPositions(
        address _trader,
        uint256 _positionID,
        uint256 _collateralForPosition,
        bool _existing,
        bool _group,
        bool _push
    ) external onlyClearingHouse {
        if (_push) {
            if (!_existing) {
                traderPositions[_trader].push(_positionID);
            }
            if (!_group) {
                traderPositionInfo[_positionID]
                    .collateralForPosition = traderPositionInfo[_positionID]
                    .collateralForPosition
                    .add(_collateralForPosition);
            }
            totalUsedCollateralInPositions[
                _trader
            ] = totalUsedCollateralInPositions[_trader].add(
                _collateralForPosition
            );
        } else {
            PositionInfo memory positionInfo = traderPositionInfo[_positionID];
            if (
                positionInfo.takerBasePositionSize.abs() >= _DUST ||
                positionInfo.takerQuoteSize.abs() >= _DUST
            ) {
                return;
            } else {
                if (!_group) {
                    uint256 collateralAllocatedForPosition = traderPositionInfo[
                        _positionID
                    ].collateralForPosition;
                    IOddzVault(oddzVault).updateCollateralBalance(
                        _trader,
                        traderPositionInfo[_positionID].owedRealizedPnl
                    );
                    totalUsedCollateralInPositions[
                        _trader
                    ] = totalUsedCollateralInPositions[_trader].sub(
                        collateralAllocatedForPosition
                    );
                    delete traderPositionInfo[_positionID];
                    uint256[] storage allPositions = traderPositions[_trader];
                    uint256 positionslength = allPositions.length;
                    for (uint256 i = 0; i < positionslength; i++) {
                        if (allPositions[i] == _positionID) {
                            // Is removable index is not the last index then we need to swap it and then pop otherwise directly pop it
                            if (i != positionslength - 1) {
                                allPositions[i] = allPositions[
                                    positionslength - 1
                                ];
                            }
                            allPositions.pop();
                            break;
                        }
                    }
                }
            }
        }
    }


    /**
     * @notice Used to update groups ,positions in groups and collateral of a trader
     * @param _trader Address of the trader
     * @param _baseToken base token address
     * @param _positionID position id
     * @param _groupID  group id
     * @param _collateralForPosition collateral used in position
     * @param _isNewGroup  is this a new group or existing
     * @param _existing   if the position id already exist or not
     * @param _push       true if we want to add the position and false if we want to remove position 
     */
    function updateTraderGroups(
        address _trader,
        address _baseToken,
        uint256 _positionID,
        uint256 _groupID,
        uint256 _collateralForPosition,
        bool _isNewGroup,
        bool _existing,
        bool _push
    ) external onlyClearingHouse {
        if (_push) {
            if (!_existing) {
                GroupPositionsInfo[] storage groupPositions = groupInfo[
                    _groupID
                ].groupPositions;
                GroupPositionsInfo memory gpInfo = GroupPositionsInfo({
                    positionID: _positionID,
                    baseToken: _baseToken
                });
                groupPositions.push(gpInfo);
            }
            groupInfo[_groupID].collateralAllocated = groupInfo[_groupID]
                .collateralAllocated
                .add(_collateralForPosition);
            if (_isNewGroup) {
                traderGroups[_trader].push(_groupID);
            }

            if(!groupInfo[_groupID].active && (groupInfo[_groupID].groupPositions).length>0 ){
                groupInfo[_groupID].active=true;
            }
           
        } else {
            PositionInfo memory positionInfo = traderPositionInfo[_positionID];
            if (
                positionInfo.takerBasePositionSize.abs() >= _DUST ||
                positionInfo.takerQuoteSize.abs() >= _DUST
            ) {
                return;
            }
            GroupInfo storage gInfo;
            if (_groupID > 0) {
                gInfo = groupInfo[_groupID];
            }
            gInfo.owedRealizedPnl = gInfo.owedRealizedPnl.add(
                traderPositionInfo[_positionID].owedRealizedPnl
            );
            delete traderPositionInfo[_positionID];
            GroupPositionsInfo[] storage groupPositions = gInfo.groupPositions;
            for (uint256 i = 0; i < groupPositions.length; i++) {
                if (groupPositions[i].positionID == _positionID) {
                    if (i != groupPositions.length - 1) {
                        groupPositions[i] = groupPositions[
                            groupPositions.length - 1
                        ];
                    }
                    groupPositions.pop();
                    break;
                }
            }
            if (groupPositions.length == 0) {
                totalUsedCollateralInPositions[
                    _trader
                ] = totalUsedCollateralInPositions[_trader].sub(
                    gInfo.collateralAllocated
                );
                IOddzVault(oddzVault).updateCollateralBalance(
                    _trader,
                    gInfo.owedRealizedPnl
                );
                gInfo.collateralAllocated=0;
                gInfo.owedRealizedPnl=0;
                gInfo.active=false;
              /*   uint256[] storage allGroups = traderGroups[_trader];
                uint256 groupsLength = allGroups.length;
                for (uint256 i = 0; i < groupsLength; i++) {
                    if (allGroups[i] == _groupID) {
                        // Is removable index is not the last index then we need to swap it and then pop otherwise directly pop it
                        if (i != groupsLength - 1) {
                            allGroups[i] = allGroups[groupsLength - 1];
                        }
                        allGroups.pop();
                        break;
                    }
                } */
            }

            uint256[] storage allPositions = traderPositions[_trader];
            uint256 positionslength = allPositions.length;
            for (uint256 i = 0; i < positionslength; i++) {
                if (allPositions[i] == _positionID) {
                    // Is removable index is not the last index then we need to swap it and then pop otherwise directly pop it
                    if (i != positionslength - 1) {
                        allPositions[i] = allPositions[positionslength - 1];
                    }
                    allPositions.pop();
                    break;
                }
            }
        }
    }

    /**
     * @notice updates postionSize and quoteSize of the trader.Can only be called by oddz clearing house
     * @param _baseToken  base token address
     * @param _positionId  position id
     * @param _baseAmount the base token amount
     * @param _quoteAmount the quote token amount
     * @param _isGrouped   if the position is in any group or not
     * @param _groupId     group id if position is in any group otherwise 0
     * returns updated values
     */
    function updateTraderPositionInfo(
        address _baseToken,
        uint256 _positionId,
        int256 _baseAmount,
        int256 _quoteAmount,
        bool _isGrouped,
        uint256 _groupId
    ) external onlyClearingHouse returns (int256, int256) {
        PositionInfo storage info = traderPositionInfo[_positionId];
        info.baseToken = _baseToken;
        info.takerBasePositionSize = info.takerBasePositionSize.add(
            _baseAmount
        );
        info.takerQuoteSize = info.takerQuoteSize.add(_quoteAmount);
        info.grouped = _isGrouped;
        info.groupID = _groupId;

        return (info.takerBasePositionSize, info.takerQuoteSize);
    }

    /**
     * @notice Settles quote amount into owedRealized profit or loss.Can only be called by Oddz clearing house
     * @param _positionId       position id
     * @param _settlementAmount the amount to be settled
     */
    function settleQuoteToOwedRealizedPnl(
        uint256 _positionId,
        int256 _settlementAmount
    ) external onlyClearingHouse {
        _settleQuoteToOwedRealizedPnl(_positionId, _settlementAmount);
    }


     /**
     * @notice to get base token amount of a position
     * @param _positionID       position id
     * @return _positionSize    base token amount
     */
    function getTakerBasePositionSize(uint256 _positionID)
        external
        view
        returns (int256 _positionSize)
    {
        if (
            (traderPositionInfo[_positionID].takerBasePositionSize).abs() <
            _DUST
        ) {
            return 0;
        } else {
            return (traderPositionInfo[_positionID].takerBasePositionSize);
        }
    }


     /**
     * @notice to get quote token amount of a position
     * @param _positionID       position id
     * @return _quoteSize    quote token amount
     */
    function getTakerQuoteSize(uint256 _positionID)
        external
        view
        returns (int256 _quoteSize)
    {
        return traderPositionInfo[_positionID].takerQuoteSize;
    }


     /**
     * @notice It is used to get the total value(usd) of the position
     * @param _positionID       position id
     * @return _positionValue   Value(usd) of the position
     */
    function getTotalPositionInfo(uint256 _positionID)
        public
        view
        returns (uint256 _positionValue)
    {
        PositionInfo storage info = traderPositionInfo[_positionID];
        uint256 twapPrice = _getBaseTokenIndexPrice(info.baseToken);
        int256 totalBaseTokenValue = (info.takerBasePositionSize).mulDiv(
            twapPrice.toInt256(),
            1e18
        );
        if (info.takerQuoteSize >= 0) {
            return totalBaseTokenValue.abs();
        } else {
            //return (info.takerQuoteSize).add(totalBaseTokenValue).abs();
            return info.takerQuoteSize.abs();
        }
    }

    /**
     * @notice It is used to get the total value(usd) of  any group includes all the positions in the group
     * @param _groupId       group id
     * @return _groupSize   Value(usd) of the group
     */
    function getTotalGroupInfo(uint256 _groupId)
        external
        view
        returns (uint256 _groupSize)
    {
        GroupInfo memory gInfo = groupInfo[_groupId];
        GroupPositionsInfo[] memory groupPositionsInfo = gInfo.groupPositions;
        for (uint256 i = 0; i < groupPositionsInfo.length; i++) {
            uint256 positionID = groupPositionsInfo[i].positionID;
            _groupSize = _groupSize.add(getTotalPositionInfo(positionID));
        }
    }


     /**
     * @notice It is used to get the total value(usd) of  any liqudity order
     * @param _baseToken    Base token address
     * @param _orderId      order id
     * @return _orderValue   Value(usd) of the order
     */
    function getTotalOrderInfo(address _baseToken, bytes32 _orderId)
        external
        view
        returns (uint256 _orderValue)
    {
        IOrderManager.OrderInfo memory order = IOrderManager(orderManager)
            .getCurrentOrderMap(_orderId);
        uint256 twapPrice = _getBaseTokenIndexPrice(_baseToken);
        int256 totalBaseTokenValue = (order.baseAmountInPool.toInt256()).mulDiv(
            twapPrice.toInt256(),
            1e18
        );

        return
            (order.quoteAmountInPool.toInt256()).add(totalBaseTokenValue).abs();
    }

     /**
     * @notice used to get all the traders positions
     * @param _trader   trader address
     * @return _positions   all the position trader has
     */
    function getTraderPositions(address _trader)
        external
        view
        returns (uint256[] memory _positions)
    {
        return traderPositions[_trader];
    }

      /**
     * @notice used to get all the traders groups
     * @param _trader   trader address
     * @return _groups   all the groups trader has
     */
    function getTraderGroups(address _trader)
        external
        view
        returns (uint256[] memory _groups)
    {
        return traderGroups[_trader];
    }

     /**
     * @notice used to get  group information
     * @param _groupId  group id
     * @return _info   info of the group
     */
    function getGroupInfo(uint256 _groupId) external view returns (GroupInfo memory _info) {
        return groupInfo[_groupId];
    }

    /**
     * @notice Settles quote amount into owedRealized profit or loss
     * @param _positionId      position id
     * @param _settlementAmount the amount to be settled
     */
    function _settleQuoteToOwedRealizedPnl(
        uint256 _positionId,
        int256 _settlementAmount
    ) internal {
        PositionInfo storage info = traderPositionInfo[_positionId];
        info.takerQuoteSize = info.takerQuoteSize.sub(_settlementAmount);
        if (_settlementAmount != 0) {
            info.owedRealizedPnl = info.owedRealizedPnl.add(_settlementAmount);
            //emit PnlRealized(_trader, _settlementAmount);
        }
    }

    /**
     * @notice Fetch the price of the base token
     * @param _baseToken The Address of the base token
     * @return _twapPrice  of the base token
     */
    function _getBaseTokenIndexPrice(address _baseToken)
        internal
        view
        returns (uint256 _twapPrice)
    {
        return
            IIndexPrice(_baseToken).getBaseTokenIndexPrice(
                IOddzConfig(oddzConfig).twapInterval()
            );
    }

   
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
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
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMathUpgradeable {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;

interface IOddzConfig {
    /// @return _maxMarketsPerAccount Max value of total markets per account
    function maxMarketsPerAccount() external view returns (uint8 _maxMarketsPerAccount);

    /// @return _imRatio Initial margin ratio
    function initialMarginRatio() external view returns (uint24 _imRatio);

    /// @return _mmRatio Maintenance margin requirement ratio
    function maintenanceMarginRatio() external view returns (uint24 _mmRatio);

    /// @return _twapInterval TwapInterval for funding and prices (mark & index) calculations
    function twapInterval() external view returns (uint32 _twapInterval);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IOrderManager {


    /// @param liquidity          Liquidity amount
    /// @param lowerTick          Lower tick of liquidity range
    /// @param upperTick          Upper tick of liquidity range
    /// @param baseAmountInPool   number of base token added
    /// @param quoteAmountInPool  number of quote token added
     struct OrderInfo {
        uint128 liquidity;
        int24 lowerTick;
        int24 upperTick;
        uint256 baseAmountInPool;
        uint256 quoteAmountInPool;
        uint256 collateralForOrder;
    }
    /// @param trader                   Trader address
    /// @param baseToken                Base token address
    /// @param baseAmount               Base token amount
    /// @param quoteAmount              Quote token amount
    /// @param lowerTickOfOrder         Lower tick of liquidity range
    /// @param upperTickOfOrder         Upper tick of liquidity range
    struct AddLiquidityParams {
        address trader;
        address baseToken;
        uint256 baseAmount;
        uint256 quoteAmount;
        int24 lowerTickOfOrder;
        int24 upperTickOfOrder;
        uint256 collateralForOrder;
    }

    /*   /// @param baseAmount         The amount of base token added to the pool
    /// @param quoteAmount       
    /// @param liquidityAmount    
    struct AddLiquidityResponse {
        uint256 baseAmount;
        uint256 quoteAmount;
        uint128 liquidityAmount;
    } */

    /// @param trader                  Trader Address
    /// @param baseToken               Base token address
    /// @param lowerTickOfOrder        Lower tick of liquidity range
    /// @param upperTickOfOrder        Upper tick of liquidity range
    /// @param liquidityAmount         Amount of liquidity you want to remove
    struct RemoveLiquidityParams {
        address trader;
        address baseToken;
        int24 lowerTickOfOrder;
        int24 upperTickOfOrder;
        uint128 liquidityAmount;
    }

    /*  /// @param baseAmount       The amount of base token removed from the pool
    /// @param quoteAmount      The amount of quote token removed from the pool
    /// @param takerBaseAmount  The base amount which is different from what had been added
    /// @param takerQuoteAmount The quote amount which is different from what had been added
    struct RemoveLiquidityResponse {
        uint256 baseAmount;
        uint256 quoteAmount;
        int256 takerBaseAmount;
        int256 takerQuoteAmount;
    } */

    struct MintCallbackData {
        address trader;
        address pool;
    }


    struct ReplaySwapParams {
        address baseToken;
        bool isShort;
        bool shouldUpdateState;
        int256 amount;
        uint160 sqrtPriceLimitX96;
        uint24 exchangeFee;
        uint24 uniswapFee;
    }

    struct ReplaySwapResponse {
        int24 tick;
        uint256 fee;
    }

    /// @notice Add liquidity logic
    /// @dev Only used by `Oddz Clearing House` contract
    /// @param params Add liquidity params, detail on `IOrderManager.AddLiquidityParams`
    /// @return baseAmountResponse The amount of base token added to the pool
    /// @return quoteAmountResponse  The amount of quote token added to the pool
    /// @return liquidityAmountResponse The amount of liquidity added to the pool, derived from base & quote
    /// @return orderId                  order ID
    function addLiquidity(AddLiquidityParams calldata params)
        external
        returns (
            uint256 baseAmountResponse,
            uint256 quoteAmountResponse,
            uint128 liquidityAmountResponse,
            bytes32 orderId
        );

    /// @notice Remove liquidity logic, only used by `Oddz Clearing House` contract
    /// @param params Remove liquidity params, detail on `IOrderManager.RemoveLiquidityParams`
    /// @return baseAmountResponse  The amount of base token removed from the pool
    /// @return quoteAmountResponse The amount of quote token removed from the pool
    /// @return takerBaseAmountResponse The base amount which is different from what had been added
    /// @return takerQuoteAmountResponse The quote amount which is different from what had been added
    function removeLiquidity(RemoveLiquidityParams calldata params)
        external
        returns (
            uint256 baseAmountResponse,
            uint256 quoteAmountResponse,
            int256 takerBaseAmountResponse,
            int256 takerQuoteAmountResponse
        );

    /// @notice Used to get all the order ids of the trader for that market
    /// @param trader User address
    /// @param baseToken base token address
    /// @return orderIds all the order id of the user
    function getCurrentOrderIdsMap(address trader, address baseToken)
        external
        returns (bytes32[] memory orderIds);

    /// @notice Used to get all the order amounts in the pool
    /// @param trader User address
    /// @param baseToken base token address
    /// @param base if true only include base token amount in pool otherwise only include quote token amount in pool
    /// @return amountInPool Gives the total amount of a particular token in the pool for the user
    function getTotalOrdersAmountInPool(
        address trader,
        address baseToken,
        bool base
    ) external view returns (uint256 amountInPool);


    function getTotalCollateralForOrders(address trader)external view returns(uint256);

    function getCurrentOrderMap(bytes32 orderId) external view returns(OrderInfo memory);

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

interface IIndexPrice {
    /// @notice Returns the index price of the token.
    /// @param interval The interval represents twap interval.
    /// @return indexPrice Twap price with interval
    function getBaseTokenIndexPrice(uint256 interval) external view returns (uint256 indexPrice);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract OddzOwnable is ContextUpgradeable {

    address public owner;
    address public nominatedOwner;

    // __gap is reserved storage for adding more variables
    uint256[50] private __gap;

    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

    /**
     * @dev Checks the current caller is owner or not.If not throws error
     */
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable:Caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __OddzOwnable_init() internal initializer {
        __Context_init();
        address deployer = _msgSender();
        owner = deployer;
        emit OwnershipTransferred(address(0), deployer);
    }

    /**
     * @dev For renouncing the ownership , After calling this ,ownership will be 
     *  transfered to zero address 
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        nominatedOwner = address(0);
    }

    /**
     * @dev for nominating a new owner.Can only be called by existing owner
     * @param _newOwner New owner address
     */
    function nominateNewOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Ownable: newOwner can not be zero addresss");
    
        require(_newOwner != owner, "Ownable: newOwner can not be same as current owner");
        // same as candidate
        require(_newOwner != nominatedOwner, "Ownable : already nominated");

        nominatedOwner = _newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function AcceptOwnership() external {
    
        require(nominatedOwner != address(0), "Ownable: No one is nominated");
        require(nominatedOwner == _msgSender(), "Ownable: You are not nominated");

        // emitting event first to avoid caching values
        emit OwnershipTransferred(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "../uniswap/FixedPoint96.sol";
import "../uniswap/FullMath.sol";
import "./OddzSafeCast.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";

library OddzMath {
    using OddzSafeCast for int256;
    using SignedSafeMathUpgradeable for int256;
    using SafeMathUpgradeable for uint256;

    function formatSqrtPriceX96ToPriceX96(uint160 sqrtPriceX96) internal pure returns (uint256) {
        return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }

    function formatX10_18ToX96(uint256 valueX10_18) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX10_18, FixedPoint96.Q96, 1 ether);
    }

    function formatX96ToX10_18(uint256 valueX96) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX96, 1 ether, FixedPoint96.Q96);
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? value.toUint256() : neg256(value).toUint256();
    }

    function neg256(int256 a) internal pure returns (int256) {
        require(a > -2**255, "PerpMath: inversion overflow");
        return -a;
    }

    function neg256(uint256 a) internal pure returns (int256) {
        return -OddzSafeCast.toInt256(a);
    }

    function neg128(int128 a) internal pure returns (int128) {
        require(a > -2**127, "PerpMath: inversion overflow");
        return -a;
    }

    function neg128(uint128 a) internal pure returns (int128) {
        return -OddzSafeCast.toInt128(a);
    }

    function divBy10_18(int256 value) internal pure returns (int256) {
        // no overflow here
        return value / (1 ether);
    }

    function divBy10_18(uint256 value) internal pure returns (uint256) {
        // no overflow here
        return value / (1 ether);
    }

    function mulRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return FullMath.mulDiv(value, ratio, 1e6);
    }

    /// @param denominator cannot be 0 and is checked in FullMath.mulDiv()
    function mulDiv(
        int256 a,
        int256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        uint256 unsignedA = a < 0 ? uint256(neg256(a)) : uint256(a);
        uint256 unsignedB = b < 0 ? uint256(neg256(b)) : uint256(b);
        bool negative = ((a < 0 && b > 0) || (a > 0 && b < 0)) ? true : false;

        uint256 unsignedResult = FullMath.mulDiv(unsignedA, unsignedB, denominator);

        result = negative ? neg256(unsignedResult) : OddzSafeCast.toInt256(unsignedResult);

        return result;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;

interface IOddzVault {
 

      /**
     * @notice Returns how much margin is available for the isolated position
     * @param trader The Address of the trader
     * @param positionID  position id for which we are checking the collateral
     * @param ratio    ratio (initial margin ratio or maintenance margin ratio)
     */
    function getPositionCollateralByRatio(address trader,uint256 positionID, uint24 ratio) external view returns (int256);

      /**
     * @notice Returns how much margin is available for the group
     * @param trader The Address of the trader
     * @param groupID  group id for which we are checking the collateral
     * @param ratio    ratio (initial margin ratio or maintenance margin ratio)
     */
     function getGroupCollateralByRatio(
        address trader,
        uint256 groupID,
        uint24 ratio
    ) external view returns (int256);


     /**
     * @notice Returns how much margin is available for the liquidity order
     * @param trader The Address of the trader
     * @param baseToken base token address
     * @param orderID liquidity order for which we are checking the collateral
     * @param ratio    ratio (initial margin ratio or maintenance margin ratio)
     */
    function getLiquidityPositionCollateralByRatio(address trader,address baseToken,bytes32 orderID, uint24 ratio) external view returns (int256);

    
     /**
     * @notice updates the main balance of the trader.Called to settle owed Realized PnL.Can only be called by balance manager
     * @param trader The Address of the trader
     * @param amount settlement amount
     */
     function updateCollateralBalance(address trader,int256 amount) external;

    
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;

/**
 * @dev copy from "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol"
 * and rename to avoid naming conflict with uniswap
 */
library OddzSafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128 returnValue) {
        require(((returnValue = uint128(value)) == value), "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64 returnValue) {
        require(((returnValue = uint64(value)) == value), "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32 returnValue) {
        require(((returnValue = uint32(value)) == value), "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16 returnValue) {
        require(((returnValue = uint16(value)) == value), "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8 returnValue) {
        require(((returnValue = uint8(value)) == value), "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 returnValue) {
        require(((returnValue = int128(value)) == value), "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 returnValue) {
        require(((returnValue = int64(value)) == value), "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 returnValue) {
        require(((returnValue = int32(value)) == value), "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 returnValue) {
        require(((returnValue = int16(value)) == value), "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 returnValue) {
        require(((returnValue = int8(value)) == value), "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }


    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 returnValue) {
        require(((returnValue = int24(value)) == value), "SafeCast: value doesn't fit in an 24 bits");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}