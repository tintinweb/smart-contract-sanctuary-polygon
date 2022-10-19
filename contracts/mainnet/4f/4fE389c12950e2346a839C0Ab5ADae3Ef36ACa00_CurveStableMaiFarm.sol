// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../BaseSiloAction.sol";
import "../../../interfaces/IAction.sol";
import "../../../interfaces/ICurvePool.sol";
import "../../../interfaces/ICurveLPToken.sol";
import "../../../interfaces/IMaiFarm.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../interfaces/IPriceOracle.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*          
Note: Used in between two mai vault actions, will take mai, and join mai stable farm
                        Curve Stable Farm Loan IO
                             ______________
                    Mai In->[              ]->Unused amount will be zero
            Reward Token A->[              ]->Reward Token A
            Reward Token B->[              ]->Reward Token B (if applicable)
         Mai out requested->[______________]->Mai out

Note: Top Mai in is Mai going into the farm
Note: Bottom Mai out, is Mai that is requested by the  preceding Mai Vault action

*/

struct ProtocolHelper{
    IMaiFarm MaiFarm;
    ICurveLPToken CurveLP;
    ICurvePool CurvePool;
    IERC20 MAI;
    IERC20 QI;
    IPriceOracle usdcPrice;
    IPriceOracle maiPrice;
    IPriceOracle daiPrice;
    IPriceOracle usdtPrice;
}

contract CurveStableMaiFarm is BaseSiloAction{
    //address constant public curveVyper = 0x5ab5C56B9db92Ba45a0B46a207286cD83C15C939;
    //address constant public mai3crvPool = 0x447646e84498552e62eCF097Cc305eaBFFF09308;
    //address constant public curveMai3crvToken = 0x447646e84498552e62eCF097Cc305eaBFFF09308;
    //address constant public maiFarm = 0x07Ca17Da3B54683f004d388F206269eF128C2356;
    //uint constant public pid = 0;

//configurationAddresses = [farm address, pool token address, pool token router address, address of actual pool, address of LP token?, guage deposit address]
//think you can get the pool token address by reading the minter address of the LP token
    constructor(string memory _name, address _siloFactory){
        name = _name;
        metaData = "address[4],address[4],uint";
        factory = _siloFactory;
        usesTakeFee = true;
        feeName = "Mai 3crv Farm Harvest Fee";
    }

    function enter(address implementation, bytes memory configuration, bytes memory inputData) public override returns(uint[4] memory outputAmounts){
        ProtocolHelper memory protocol = ProtocolHelper({
            MaiFarm: IMaiFarm(0x0635AF5ab29Fc7bbA007B8cebAD27b7A3d3D1958),
            CurveLP: ICurveLPToken(0x447646e84498552e62eCF097Cc305eaBFFF09308),
            CurvePool: ICurvePool(0x5ab5C56B9db92Ba45a0B46a207286cD83C15C939),
            MAI: IERC20(0xa3Fa99A148fA48D14Ed51d610c367C61876997F1),
            QI: IERC20(0x580A84C73811E1839F75d86d75d88cCa0c241fF4),
            usdcPrice: IPriceOracle(0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7),
            maiPrice: IPriceOracle(0xd8d483d813547CfB624b8Dc33a00F2fcbCd2D428),
            daiPrice: IPriceOracle(0x4746DeC9e833A82EC7C2C1356372CcF2cfcD2F3D),
            usdtPrice: IPriceOracle(0x0A6513e40db6EB1b165753AD52E80663aeA50545)
        });

        uint[4] memory inputAmounts = abi.decode(inputData, (uint[4]));
        
        //outputAmounts[1] = protocol.MaiFarm.pending(0, address(this)); //removed bc pending reverts if farm end block has passed
        outputAmounts[1] = protocol.QI.balanceOf(address(this));
        if(inputAmounts[0] == 0 && inputAmounts[3] == 0 && protocol.MaiFarm.deposited(0, address(this)) > 0 && protocol.MaiFarm.endBlock() > block.number){//just harvest rewards
            protocol.MaiFarm.deposit(0, 0);//harvest rewards
            outputAmounts[1] = protocol.QI.balanceOf(address(this)) - outputAmounts[1];
            outputAmounts[1] = _takeFee(implementation, outputAmounts[1], address(protocol.QI));
            outputAmounts[1] += inputAmounts[1];//add the initial amount that went in
        }
        else{
            uint lpPrice;
            {//calculate fair lp price
                uint minPrice = protocol.maiPrice.latestAnswer();
                if(protocol.usdcPrice.latestAnswer() < minPrice){
                    minPrice = protocol.usdcPrice.latestAnswer();
                }
                if(protocol.usdtPrice.latestAnswer() < minPrice){
                    minPrice = protocol.usdtPrice.latestAnswer();
                }
                if(protocol.daiPrice.latestAnswer() < minPrice){
                    minPrice = protocol.daiPrice.latestAnswer();
                }
                lpPrice = minPrice * protocol.CurveLP.get_virtual_price() / 10**18; 
            }
            if(inputAmounts[0] > 0){//want to deposit into curve and then into the farm
                uint[4] memory amounts;
                amounts[0] = inputAmounts[0];
                SafeERC20.safeApprove(protocol.MAI, address(protocol.CurvePool), inputAmounts[0]);
                uint lpTokenAmount = protocol.CurvePool.add_liquidity(address(protocol.CurveLP), amounts, 0);
                {
                    uint valueIn = inputAmounts[0] * protocol.maiPrice.latestAnswer() / 10**18;
                    uint valueOut = lpTokenAmount * lpPrice / 10**18;
                    require(valueOut >= (valueIn * 98 / 100), "Gravity Finance: Expected Value Out too low");
                }
                //uint lpTokenAmount = protocol.CurveLP.balanceOf(address(this));
                SafeERC20.safeApprove(protocol.CurveLP, address(protocol.MaiFarm), lpTokenAmount);
                protocol.MaiFarm.deposit(0, lpTokenAmount);
            }
            else if(inputAmounts[3] > 0){//want to repay some of the loan
                uint dollarValueRequested = inputAmounts[3] * protocol.maiPrice.latestAnswer() / 10**18;
                uint amountToRemove = 10**18 * dollarValueRequested / lpPrice;
                if(protocol.MaiFarm.deposited(0, address(this)) <= amountToRemove){
                    amountToRemove = protocol.MaiFarm.deposited(0, address(this));
                }
                protocol.MaiFarm.withdraw(0, amountToRemove);
                SafeERC20.safeApprove(protocol.CurveLP, address(protocol.CurvePool), amountToRemove);
                outputAmounts[3] = protocol.CurvePool.remove_liquidity_one_coin(address(protocol.CurveLP), amountToRemove, 0, 0);
                {
                    uint valueIn = amountToRemove * lpPrice / 10**18;
                    uint valueOut = outputAmounts[3] * protocol.maiPrice.latestAnswer() / 10**18;
                    require(valueOut >= (valueIn * 98 / 100), "Gravity Finance: Expected Value Out too low");
                }
            }
            outputAmounts[1] = protocol.QI.balanceOf(address(this)) - outputAmounts[1];
            outputAmounts[1] = _takeFee(implementation, outputAmounts[1], address(protocol.QI));
            outputAmounts[1] += inputAmounts[1];//add the initial amount that went in
        }
    }

    function exit(address implementation, bytes memory configuration, bytes memory outputData) public override returns(uint[4] memory outputAmounts){
        ProtocolHelper memory protocol = ProtocolHelper({
            MaiFarm: IMaiFarm(0x0635AF5ab29Fc7bbA007B8cebAD27b7A3d3D1958),
            CurveLP: ICurveLPToken(0x447646e84498552e62eCF097Cc305eaBFFF09308),
            CurvePool: ICurvePool(0x5ab5C56B9db92Ba45a0B46a207286cD83C15C939),
            MAI: IERC20(0xa3Fa99A148fA48D14Ed51d610c367C61876997F1),
            QI: IERC20(0x580A84C73811E1839F75d86d75d88cCa0c241fF4),
            usdcPrice: IPriceOracle(0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7),
            maiPrice: IPriceOracle(0xd8d483d813547CfB624b8Dc33a00F2fcbCd2D428),
            daiPrice: IPriceOracle(0x4746DeC9e833A82EC7C2C1356372CcF2cfcD2F3D),
            usdtPrice: IPriceOracle(0x0A6513e40db6EB1b165753AD52E80663aeA50545)
        });

        uint[4] memory inputAmounts = abi.decode(outputData, (uint[4]));
        
        //outputAmounts[1] = protocol.MaiFarm.pending(0, address(this)); //removed bc pending reverts if farm end block has passed
        outputAmounts[1] = protocol.QI.balanceOf(address(this));

        if(inputAmounts[0] == 0 && inputAmounts[3] == 0 && protocol.MaiFarm.deposited(0, address(this)) > 0 && protocol.MaiFarm.endBlock() > block.number){//just harvest rewards
            protocol.MaiFarm.deposit(0, 0);//harvest rewards
            outputAmounts[1] = protocol.QI.balanceOf(address(this)) - outputAmounts[1];
            outputAmounts[1] = _takeFee(implementation, outputAmounts[1], address(protocol.QI));
            outputAmounts[1] += inputAmounts[1];//add the initial amount that went in
        }
        else{
            uint lpPrice;
            {//calculate fair lp price
                uint minPrice = protocol.maiPrice.latestAnswer();
                if(protocol.usdcPrice.latestAnswer() < minPrice){
                    minPrice = protocol.usdcPrice.latestAnswer();
                }
                if(protocol.usdtPrice.latestAnswer() < minPrice){
                    minPrice = protocol.usdtPrice.latestAnswer();
                }
                if(protocol.daiPrice.latestAnswer() < minPrice){
                    minPrice = protocol.daiPrice.latestAnswer();
                }
                lpPrice = minPrice * protocol.CurveLP.get_virtual_price() / 10**18; 
            }
            if(inputAmounts[0] > 0){//want to deposit into curve and then into the farm
                uint[4] memory amounts;
                amounts[0] = inputAmounts[0];
                SafeERC20.safeApprove(protocol.MAI, address(protocol.CurvePool), inputAmounts[0]);
                uint lpTokenAmount = protocol.CurvePool.add_liquidity(address(protocol.CurveLP), amounts, 0);
                {
                    uint valueIn = inputAmounts[0] * protocol.maiPrice.latestAnswer() / 10**18;
                    uint valueOut = lpTokenAmount * lpPrice / 10**18;
                    require(valueOut >= (valueIn * 98 / 100), "Gravity Finance: Expected Value Out too low");
                }
                //uint lpTokenAmount = protocol.CurveLP.balanceOf(address(this));
                SafeERC20.safeApprove(protocol.CurveLP, address(protocol.MaiFarm), lpTokenAmount);
                protocol.MaiFarm.deposit(0, lpTokenAmount);
            }
            else if(inputAmounts[3] > 0){//want to repay some of the loan
                uint amountToRemove;
                if(inputAmounts[3] == 2**256 - 1){//want to remove entire stake
                    amountToRemove = protocol.MaiFarm.deposited(0, address(this));
                }
                else{//want to remove some of the stake
                    uint dollarValueRequested = inputAmounts[3] * protocol.maiPrice.latestAnswer() / 10**18;
                    amountToRemove = 10**18 * dollarValueRequested / lpPrice;
                    if(protocol.MaiFarm.deposited(0, address(this)) <= amountToRemove){
                        amountToRemove = protocol.MaiFarm.deposited(0, address(this));
                    }
                }
                protocol.MaiFarm.withdraw(0, amountToRemove);
                SafeERC20.safeApprove(protocol.CurveLP, address(protocol.CurvePool), amountToRemove);
                outputAmounts[3] = protocol.CurvePool.remove_liquidity_one_coin(address(protocol.CurveLP), amountToRemove, 0, 0);
                {
                    uint valueIn = amountToRemove * lpPrice / 10**18;
                    uint valueOut = outputAmounts[3] * protocol.maiPrice.latestAnswer() / 10**18;
                    require(valueOut >= (valueIn * 98 / 100), "Gravity Finance: Expected Value Out too low");
                }
            }
            outputAmounts[1] = protocol.QI.balanceOf(address(this)) - outputAmounts[1];
            outputAmounts[1] = _takeFee(implementation, outputAmounts[1], address(protocol.QI));
            outputAmounts[1] += inputAmounts[1];//add the initial amount that went in
        }
    }

    function createConfig(address[4] memory _inputs, address[4] memory _outputs, uint _trigger) public pure returns(bytes memory configData){
        configData = abi.encode(_inputs, _outputs, _trigger);
    }

    function showBalances(address _silo, bytes memory _configurationData) external view override returns(ActionBalance memory){
        ProtocolHelper memory protocol = ProtocolHelper({
            MaiFarm: IMaiFarm(0x0635AF5ab29Fc7bbA007B8cebAD27b7A3d3D1958),
            CurveLP: ICurveLPToken(0x447646e84498552e62eCF097Cc305eaBFFF09308),
            CurvePool: ICurvePool(0x5ab5C56B9db92Ba45a0B46a207286cD83C15C939),
            MAI: IERC20(0xa3Fa99A148fA48D14Ed51d610c367C61876997F1),
            QI: IERC20(0x580A84C73811E1839F75d86d75d88cCa0c241fF4),
            usdcPrice: IPriceOracle(0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7),
            maiPrice: IPriceOracle(0xd8d483d813547CfB624b8Dc33a00F2fcbCd2D428),
            daiPrice: IPriceOracle(0x4746DeC9e833A82EC7C2C1356372CcF2cfcD2F3D),
            usdtPrice: IPriceOracle(0x0A6513e40db6EB1b165753AD52E80663aeA50545)
        });
        uint lpPrice;
        {//calculate fair lp price
            uint minPrice = protocol.maiPrice.latestAnswer();
            if(protocol.usdcPrice.latestAnswer() < minPrice){
                minPrice = protocol.usdcPrice.latestAnswer();
            }
            if(protocol.usdtPrice.latestAnswer() < minPrice){
                minPrice = protocol.usdtPrice.latestAnswer();
            }
            if(protocol.daiPrice.latestAnswer() < minPrice){
                minPrice = protocol.daiPrice.latestAnswer();
            }
            lpPrice = minPrice * protocol.CurveLP.get_virtual_price() / 10**18;
            lpPrice = 10**8 * protocol.maiPrice.latestAnswer() / lpPrice;
        }
        uint convertedBal = protocol.MaiFarm.deposited(0, _silo) * lpPrice / 10**8;
        return ActionBalance({
            collateral: protocol.MaiFarm.deposited(0, _silo),
            debt: 0,
            collateralToken: address(protocol.CurveLP),
            debtToken: address(0),
            collateralConverted: convertedBal,
            collateralConvertedToken: address(protocol.MAI),
            lpUnderlyingBalances: string(abi.encodePacked((Strings.toString(convertedBal)))),
            lpUnderlyingTokens: string(abi.encodePacked(Strings.toHexString(uint160(address(protocol.MAI)), 20)))
        });
    }

    function actionValid(bytes memory _configurationData) external view override returns(bool, bool){
        ProtocolHelper memory protocol = ProtocolHelper({
            MaiFarm: IMaiFarm(0x0635AF5ab29Fc7bbA007B8cebAD27b7A3d3D1958),
            CurveLP: ICurveLPToken(0x447646e84498552e62eCF097Cc305eaBFFF09308),
            CurvePool: ICurvePool(0x5ab5C56B9db92Ba45a0B46a207286cD83C15C939),
            MAI: IERC20(0xa3Fa99A148fA48D14Ed51d610c367C61876997F1),
            QI: IERC20(0x580A84C73811E1839F75d86d75d88cCa0c241fF4),
            usdcPrice: IPriceOracle(0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7),
            maiPrice: IPriceOracle(0xd8d483d813547CfB624b8Dc33a00F2fcbCd2D428),
            daiPrice: IPriceOracle(0x4746DeC9e833A82EC7C2C1356372CcF2cfcD2F3D),
            usdtPrice: IPriceOracle(0x0A6513e40db6EB1b165753AD52E80663aeA50545)
        });
        return (ISiloFactory(getFactory()).actionValid(address(this)), protocol.MaiFarm.endBlock() > block.number);//second bool overwritten to logically account for the end block
    }

    function checkMaintain(bytes memory configuration) public view override returns(bool){
        if(ISilo(msg.sender).siloDelay() != 0){//user has chosen a time based upkeep schedule instead of an automatic one
            return false;
        }
        ProtocolHelper memory protocol = ProtocolHelper({
            MaiFarm: IMaiFarm(0x0635AF5ab29Fc7bbA007B8cebAD27b7A3d3D1958),
            CurveLP: ICurveLPToken(0x447646e84498552e62eCF097Cc305eaBFFF09308),
            CurvePool: ICurvePool(0x5ab5C56B9db92Ba45a0B46a207286cD83C15C939),
            MAI: IERC20(0xa3Fa99A148fA48D14Ed51d610c367C61876997F1),
            QI: IERC20(0x580A84C73811E1839F75d86d75d88cCa0c241fF4),
            usdcPrice: IPriceOracle(0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7),
            maiPrice: IPriceOracle(0xd8d483d813547CfB624b8Dc33a00F2fcbCd2D428),
            daiPrice: IPriceOracle(0x4746DeC9e833A82EC7C2C1356372CcF2cfcD2F3D),
            usdtPrice: IPriceOracle(0x0A6513e40db6EB1b165753AD52E80663aeA50545)
        });
        uint trigger;
        (,,trigger) = abi.decode(configuration, (address[4],address[4],uint));
        if(block.number < protocol.MaiFarm.endBlock() && protocol.MaiFarm.pending(0, msg.sender) >= trigger){
            
            return true;
        }
        return false;
    }

     function withdrawLimit(bytes memory configuration)
        public
        view
        override
        returns (
            uint256 currentBalance,
            uint256 possibleWithdraw,
            uint256 availableBlock,
            uint256 pendingReward
        )
    {
        IMaiFarm maiFarm = IMaiFarm(0x0635AF5ab29Fc7bbA007B8cebAD27b7A3d3D1958);
        pendingReward = maiFarm.pending(0, msg.sender);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/ISiloFactory.sol";
import "../../interfaces/ISilo.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/IAction.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseSiloAction is Ownable {

    bytes public configurationData;//if not set on deployment, then they use the value in the Silo
    string public name;
    string public feeName;//name displayed when showing fee information
    uint constant public MAX_TRANSIENT_VARIABLES = 4;
    address public factory;
    uint constant public FEE_DECIMALS = 10000;
    string public metaData;
    bool public usesTakeFee;

    /******************************Functions that can be implemented******************************/
    /**
     * @dev what a silo should do when entering a strategy and running this action
     */
    function enter(address implementation, bytes memory configuration, bytes memory inputData) public virtual returns(uint[4] memory){}

    /**
     * @dev what a silo should do when exiting a strategy and running this action
     */
    function exit(address implementation, bytes memory configuration, bytes memory outputData) public virtual returns(uint[4] memory){}

    function protocolStatistics() external view returns(string memory){}

    function showBalances(address _silo, bytes memory _configurationData) external view virtual returns(ActionBalance memory){}

    function showDust(address _silo, bytes memory _configurationData) external view virtual returns(address[] memory, uint[] memory){}


    /******************************external view functions******************************/
    function showFee(address _action) external view returns(string memory nameOfFee, uint[4] memory fees){
        nameOfFee = feeName;
        if(usesTakeFee){
            fees = ISiloFactory(IAction(_action).getFactory()).getFeeInfoNoTier(_action);
        }
    }

    function actionValid(bytes memory _configurationData) external view virtual returns(bool, bool){
        return (ISiloFactory(getFactory()).actionValid(address(this)), true);//second bool can be overwritten by individual actions
    }

    /******************************public view functions******************************/
    function getConfig() public view returns(bytes memory){
        return configurationData;
    }

    function getIsSilo(address _silo) public view returns(bool){
        return ISiloFactory(factory).isSilo(_silo);
    }

    function getFactory() public view returns(address){
        return factory;
    }

    function setFactory(address _siloFactory) public onlyOwner{
        factory = _siloFactory;
    }

    function getDecimals() public pure returns(uint){
        return FEE_DECIMALS;
    }

    function getMetaData() public view returns(string memory){
        return metaData;
    }

    function checkMaintain(bytes memory ) public view virtual returns(bool){
        return false;
    }

    function validateConfig(bytes memory ) public view virtual returns(bool){
        return true;
    }

    function checkUpkeep( bytes memory ) public view virtual returns(bool){
        return true;
    }

    function withdrawLimit(bytes memory _configurationData) public view virtual returns(uint,uint,uint,uint){
        return (0,0,0,0);
    }

    /******************************internal view functions******************************/
    function _takeFee(address _action, uint _gains, address _token) internal virtual returns(uint remaining){
        (uint fee, address recipient) = ISiloFactory(IAction(_action).getFactory()).getFeeInfo( _action);
        uint feeToTake = _gains * fee / IAction(_action).getDecimals();
        if(feeToTake > 0){
            SafeERC20.safeTransfer(IERC20(_token), recipient, feeToTake);
            remaining = _gains - feeToTake;    
        }
        else{
            remaining = _gains;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct ActionBalance{
    uint collateral;
    uint debt;
    address collateralToken;
    address debtToken;
    uint collateralConverted;
    address collateralConvertedToken;
    string lpUnderlyingBalances;
    string lpUnderlyingTokens;
}

interface IAction{
    function getConfig() external view returns(bytes memory config);
    function checkMaintain(bytes memory configuration) external view returns(bool);
    function checkUpkeep(bytes memory configuration) external view returns(bool);
    function withdrawLimit(bytes memory configuration) external view returns(uint,uint, uint, uint);
    function validateConfig(bytes memory configData) external view returns(bool); 
    function getMetaData() external view returns(string memory);
    function getFactory() external view returns(address);
    function getDecimals() external view returns(uint);
    function showFee(address _action) external view returns(string memory actionName, uint[4] memory fees);
    function showBalances(address _silo, bytes memory _configurationData) external view returns(ActionBalance memory);
    function showDust(address _silo, bytes memory _configurationData) external view returns(address[] memory, uint[] memory);
    function actionValid(bytes memory _configurationData) external view returns(bool, bool);
    function getIsSilo(address _silo) external view returns(bool);
    function setFactory(address _siloFactory) external ;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICurvePool{
    //function add_liquidity(uint[3] memory _amounts, uint _min_mint) external;
    function remove_liquidity(uint _amount, uint[3] memory _min_amounts) external;
    function add_liquidity(address _pool, uint256[4] memory _deposit_amounts, uint256 _min_mint_amount) external returns(uint);
    function remove_liquidity_one_coin(address _pool, uint256 _burn_amount, int128 i, uint256 _min_amount) external returns(uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICurveLPToken is IERC20{
    function get_virtual_price() external view returns(uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMaiFarm{
    function deposit(uint _pid, uint _amount) external;
    function withdraw(uint _pid, uint _amount) external;
    function deposited(uint _pid, address _user) external view returns(uint);
    function pending(uint _pid, address _user) external view returns(uint);
    function endBlock() external view returns(uint);
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

pragma solidity ^0.8.0;


interface IPriceOracle {
    function latestAnswer() external view returns(uint);
    function decimals() external view returns(uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ISiloFactory is IERC721Enumerable{
    function tokenMinimum(address _token) external view returns(uint _minimum);
    function balanceOf(address _owner) external view returns(uint);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function managerFactory() external view returns(address);
    function siloMap(uint _id) external view returns(address);
    function tierManager() external view returns(address);
    function ownerOf(uint _id) external view returns(address);
    function siloToId(address silo) external view returns(uint);
    function CreateSilo(address recipient) external returns(uint);
    function setActionStack(uint siloID, address[4] memory input, address[] memory _implementations, bytes[] memory _configurationData) external;
    function Withdraw(uint siloID) external;
    function getFeeInfo(address _action) external view returns(uint fee, address recipient);
    function strategyMaxGas() external view returns(uint);
    function strategyName(string memory _name) external view returns(uint);
    
    function getCatalogue(uint _type) external view returns(string[] memory);
    function getStrategyInputs(uint _id) external view returns(address[4] memory inputs);
    function getStrategyActions(uint _id) external view returns(address[] memory actions);
    function getStrategyConfigurationData(uint _id) external view returns(bytes[] memory configurationData);
    function useCustom(address _action) external view returns(bool);
    // function getFeeList(address _action) external view returns(uint[4] memory);
    function feeRecipient(address _action) external view returns(address);
    function defaultFeeList() external view returns(uint[4] memory);
    function defaultRecipient() external view returns(address);
    // function getTier(address _silo) external view returns(uint);

    function getFeeInfoNoTier(address _action) external view returns(uint[4] memory);
    function highRiskActions(address _action) external view returns(bool);
    function actionValid(address _action) external view returns(bool);
    function skipActionValidTeamCheck(address _user) external view returns(bool);
    function skipActionValidLogicCheck(address _user) external view returns(bool);
    function isSilo(address _silo) external view returns(bool);
    function currentStrategyId() external view returns(uint);
    function minBalance() external view returns(uint);
    
    function subFactory() external view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct PriceOracle {
    address oracle;
    uint256 actionPrice;
}

enum Statuses {
    PAUSED,
    DORMANT,
    MANAGED,
    UNWIND
}

interface ISilo {
    function initialize(uint256 siloID) external;

    function Deposit() external;

    function Withdraw(uint256 _requestedOut) external;

    function Maintain() external;

    function ExitSilo(address caller) external;

    function adminCall(address target, bytes memory data) external;

    function setStrategy(
        address[4] memory input,
        bytes[] memory _configurationData,
        address[] memory _implementations
    ) external;

    function getConfig() external view returns (bytes memory config);

    function withdrawToken(address token, address recipient) external;

    function adjustSiloDelay(uint256 _newDelay) external;

    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;

    function siloDelay() external view returns (uint256);

    function name() external view returns (string memory);

    function lastTimeMaintained() external view returns (uint256);

    function setName(string memory name) external;

    function deposited() external view returns (bool);

    function isNew() external view returns (bool);

    function setStrategyName(string memory _strategyName) external;

    function setStrategyCategory(uint256 _strategyCategory) external;

    function strategyName() external view returns (string memory);

    function tokenMinimum(address token) external view returns (uint256);

    function strategyCategory() external view returns (uint256);

    function adjustStrategy(
        uint256 _index,
        bytes memory _configurationData,
        address _implementation
    ) external;

    function viewStrategy()
        external
        view
        returns (address[] memory actions, bytes[] memory configData);

    function highRiskAction() external view returns (bool);

    function showActionStackValidity() external view returns (bool, bool);

    function getInputTokens() external view returns (address[4] memory);

    function getStatus() external view returns (Statuses);

    function pause() external;

    function unpause() external;

    function setActive() external;

    function possibleReinvestSilo() external view returns (bool possible) ;

    function getWithdrawLimitSiloInfo()
        external
        view
        returns (
            bool isLimit,
            uint256 currentBalance,
            uint256 possibleWithdraw,
            uint256 availableBlock,
            uint256 pendingReward
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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