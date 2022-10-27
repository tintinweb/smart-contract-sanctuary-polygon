//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.10;

import "Ownable.sol";
import "AccessControl.sol";
import { ISetToken } from "ISetToken.sol";

interface IAToken {
    // solhint-disable-next-line func-name-mixedcase
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

interface IAaveLeverageModule {
    function lever(
        address _setToken,
        address _borrowAsset,
        address _collateralAsset,
        uint256 _borrowQuantityUnits,
        uint256 _minReceiveQuantityUnits,
        string calldata _tradeAdapterName,
        bytes calldata _tradeData
    ) external;

    function delever(
        address _setToken,
        address _collateralAsset,
        address _repayAsset,
        uint256 _redeemQuantityUnits,
        uint256 _minRepayQuantityUnits,
        string calldata _tradeAdapterName,
        bytes calldata _tradeData
    ) external;
}

contract KellyManager is Ownable, AccessControl {
    uint256 public leverage;
    uint256 public slippage;
    uint256 public gasLimit;
    uint256 public lastExecuted;
    IAaveLeverageModule internal aaveLeverageModule;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    modifier onlyOperator {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Caller is not an operator");
        _;
    }

    constructor(address _aaveLeverageModule, uint256 _leverage, uint256 _slippage, uint256 _gasLimit) public {
        leverage = _leverage;
        slippage = _slippage;
        gasLimit = _gasLimit;
        aaveLeverageModule = IAaveLeverageModule(_aaveLeverageModule);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * PRIVELEGED OWNER FUNCTION. Low level function that allows the owner to make an arbitrary function
     * call to any contract.
     *
     * @param _target                 Address of the smart contract to call
     * @param _value                  Quantity of Ether to provide the call (typically 0)
     * @param _data                   Encoded function selector and arguments
     * @return _returnValue           Bytes encoded return value
     */
    function invoke(
        address _target,
        uint256 _value,
        bytes calldata _data
    )
        external
        onlyOwner
        returns (bytes memory _returnValue)
    {
        _returnValue = _target.functionCallWithValue(_data, _value);
    }

    // Allows the owner to update the leverage amount (scaled by 10 ^ 18)
    function setLeverage(uint256 _leverage) external onlyOwner {
        leverage = _leverage;
    }

    // Allows the owner to update the slippage amount (scaled by 10 ^ 18)
    function setSlippage(uint256 _slippage) external onlyOwner {
        slippage = _slippage;
    }

    // Allows the owner to reset the last execution time
    function resetExecutionTime() external onlyOwner {
        lastExecuted = 0;
    }

    // Allows the owner to update the gas limit
    function setGasLimit(uint256 _gasLimit) external onlyOwner {
        gasLimit = _gasLimit;
    }

    /**
     * PRIVELEGED OPERATOR FUNCTION. Allows the operator to make a lever or delever function
     * call to the AaveLeverageModule.
     *
     * @param _setToken                       Address of the Set Token
     * @param _borrowOrCollateralAsset        Address of the borrow asset
     * @param _collateralOrRepayAsset         Address of the collateral asset
     * @param _borrowOrRedeemQuantityUnits    Borrow quantity in set units
     * @param _minReceiveOrRepayQuantityUnits Minimum amount of received quantity units
     * @param _tradeAdapterName               The name of the trade adapter to use
     * @param _tradeData                      Data to be passed to the trade adapter
     */
    function operatorExecute(
        address _setToken,
        address _borrowOrCollateralAsset,
        address _collateralOrRepayAsset,
        uint256 _borrowOrRedeemQuantityUnits,
        uint256 _minReceiveOrRepayQuantityUnits,
        string calldata _tradeAdapterName,
        bytes calldata _tradeData
    )
        external
        onlyOperator
    {
        address[] memory components = ISetToken(_setToken).getComponents();
        require(
            (_collateralOrRepayAsset == components[1] &&
                _borrowOrCollateralAsset == IAToken(components[0]).UNDERLYING_ASSET_ADDRESS()) ||
            (_borrowOrCollateralAsset == components[1] &&
                _collateralOrRepayAsset == IAToken(components[0]).UNDERLYING_ASSET_ADDRESS()),
            "invalid components");
        _borrowOrCollateralAsset == components[1] ?
            aaveLeverageModule.lever(_setToken, _borrowOrCollateralAsset, _collateralOrRepayAsset,
                _borrowOrRedeemQuantityUnits, _minReceiveOrRepayQuantityUnits, _tradeAdapterName, _tradeData) :
            aaveLeverageModule.delever(_setToken, _borrowOrCollateralAsset, _collateralOrRepayAsset,
                _borrowOrRedeemQuantityUnits, _minReceiveOrRepayQuantityUnits, _tradeAdapterName, _tradeData);
        // solhint-disable-next-line not-rely-on-time
        lastExecuted = block.timestamp;
    }
}