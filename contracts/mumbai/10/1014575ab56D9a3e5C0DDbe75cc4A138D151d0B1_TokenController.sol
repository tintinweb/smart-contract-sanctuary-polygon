// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import './interfaces/IUserProxyFactory.sol';
import './interfaces/IUserProxy.sol';
import './interfaces/IVTokenFactory.sol';
import './interfaces/ILendingPool.sol';
import './interfaces/IERC20.sol';
import './interfaces/IBridgeControl.sol';
import './interfaces/ITokenController.sol';
import './interfaces/INetworkFeeController.sol';
import './interfaces/IIncentivesController.sol';


contract TokenController {

    struct Params {
    address  lendingPool;
    address  bridgeControl;
    address  vTokenFactory;
    address  proxyFactory;
    address  networkFeeController;
    }
    mapping(address => Params) public addressParams;

	event BorrowToEthereum(address asset,uint256 value,address toEthAdr);

	event Borrow(address asset,uint256 value,address toEthAdr);

	event Repay(address asset,uint256 value,uint256 rateMode);

	event WithdrawToEthereum(address asset,uint256 value,address toEthAdr);

	event Transfer(address asset,uint256 value,address toEthAdr);

	event TransferToEthereum(address asset,uint256 value,address toEthAdr);

	event TransferCredit(address asset,uint256 value,address toEthAdr,uint256 interestRateMode,uint16 referralCode);

	event TransferCreditToEthereum(address asset,uint256 value,address toEthAdr,uint256 interestRateMode,uint16 referralCode);


    

    constructor(address _lendingPOOL, address _bridgeControl, address _vTokenFactory,address _proxyFactory,address _networkFeeController) {
        address tokenController = address(this);
        addressParams[tokenController].lendingPool = _lendingPOOL;
        addressParams[tokenController].bridgeControl = _bridgeControl;
        addressParams[tokenController].vTokenFactory = _vTokenFactory;
        addressParams[tokenController].proxyFactory = _proxyFactory;
        addressParams[tokenController].networkFeeController = _networkFeeController;
    }
    function withdrawToEthereum(address tokenController,address asset, uint256 amount) public {
        bytes4 method = bytes4(keccak256("withdrawToEthereum(address,address,uint256)"));
        Params memory  params = TokenController(tokenController).getParams();
		address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        address ethUser = IUserProxy(address(this)).owner();
        require(vToken != address(0), "unknow token");
        ILendingPool(params.lendingPool).withdraw(vToken,amount,params.bridgeControl);
        (uint256 fee,address networkFeeVault) =INetworkFeeController(params.networkFeeController).getNetworkFee(ethUser,method,vToken,amount);
        if(fee > 0){
            IERC20(vToken).transfer(networkFeeVault,fee);
        }
        uint256 targetAmount = amount-fee;
		IBridgeControl(params.bridgeControl).transferToEthereum(address(this),vToken, address(this), targetAmount,1);
        emit WithdrawToEthereum(asset, targetAmount, ethUser);

	}

    function borrowToEthereum(address tokenController,address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode) public {
        bytes4 method = bytes4(keccak256("borrowToEthereum(address,address,uint256,uint256,uint16)"));
        Params memory  params = TokenController(tokenController).getParams();
        address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
        address ethUser = IUserProxy(address(this)).owner();
		ILendingPool(params.lendingPool).borrow(vToken, amount, interestRateMode, referralCode, address(this));
        (uint256 fee,address networkFeeVault) =INetworkFeeController(params.networkFeeController).getNetworkFee(ethUser,method,vToken,amount);
        if(fee > 0){
            IERC20(vToken).transfer(networkFeeVault,fee);
        }
        uint256 targetAmount = amount-fee;
        IERC20(vToken).transfer(params.bridgeControl,targetAmount);
		IBridgeControl(params.bridgeControl).transferToEthereum(address(this),vToken, address(this), targetAmount,2);
        emit BorrowToEthereum(asset, targetAmount, ethUser);
	}

    function borrow(address tokenController,address asset, uint256 amount,uint256 interestRateMode,uint16 referralCode) public {
        bytes4 method = bytes4(keccak256("borrow(address,address,uint256,uint256,uint16)"));
        Params memory  params = TokenController(tokenController).getParams();
		address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
        address ethUser = IUserProxy(address(this)).owner();
        ILendingPool(params.lendingPool).borrow(vToken,amount,interestRateMode,referralCode,address(this));
        (uint256 fee,address networkFeeVault) =INetworkFeeController(params.networkFeeController).getNetworkFee(ethUser,method,vToken,amount);
        if(fee > 0){
            IERC20(vToken).transfer(networkFeeVault,fee);
        }
        uint256 targetAmount = amount-fee;
        IERC20(vToken).approve(params.lendingPool,targetAmount);
		ILendingPool(params.lendingPool).deposit(vToken,targetAmount,address(this),referralCode);
        emit Borrow(asset,targetAmount,ethUser);
	}

    function transfer(address tokenController,address asset, uint256 amount,address to) public {
        bytes4 method = bytes4(keccak256("transfer(address,address,uint256,address)"));
        Params memory  params = TokenController(tokenController).getParams();
		address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(params.proxyFactory).getProxy(to);
        if(proxyAddr == address(0)){
            proxyAddr = IUserProxyFactory(params.proxyFactory).createProxy(to);
        }
       address ethUser = IUserProxy(address(this)).owner();
        (uint256 fee,address networkFeeVault) =INetworkFeeController(params.networkFeeController).getNetworkFee(ethUser,method,vToken,amount);
         if(fee > 0){
            ILendingPool(params.lendingPool).withdraw(vToken,fee,networkFeeVault);
        }
        uint256 targetAmount = amount-fee;
        ( , , , , , , ,address aToken, , , , ) = ILendingPool(params.lendingPool).getReserveData(vToken);
		IERC20(aToken).transfer(proxyAddr,targetAmount);
        emit Transfer(asset, targetAmount, to);
	}
    function transferToEthereum(address tokenController,address asset, uint256 amount,address to) public {
        bytes4 method = bytes4(keccak256("transferToEthereum(address,address,uint256,address)"));
        Params memory  params = TokenController(tokenController).getParams();
		address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
		address proxyAddr = IUserProxyFactory(params.proxyFactory).getProxy(to);
        if(proxyAddr == address(0)){
            proxyAddr = IUserProxyFactory(params.proxyFactory).createProxy(to);
        }
        address ethUser = IUserProxy(address(this)).owner();
		ILendingPool(params.lendingPool).withdraw(vToken,amount,params.bridgeControl);
        (uint256 fee,address networkFeeVault) =INetworkFeeController(params.networkFeeController).getNetworkFee(ethUser,method,vToken,amount);
        if(fee > 0){
            IERC20(vToken).transfer(networkFeeVault,fee);
        }
        uint256 targetAmount = amount-fee;
		IBridgeControl(params.bridgeControl).transferToEthereum(address(this),vToken, proxyAddr, targetAmount,3);
        emit TransferToEthereum(asset, targetAmount, to);
    }
    function transferCredit(address tokenController,address asset, uint256 amount,address to,uint256 interestRateMode,uint16 referralCode) public {
        bytes4 method = bytes4(keccak256("transferCredit(address,address,uint256,address,uint256,uint16)"));
        Params memory  params = TokenController(tokenController).getParams();
		address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
		address proxyAddr = IUserProxyFactory(params.proxyFactory).getProxy(to);
        address ethUser = IUserProxy(address(this)).owner();
        if(proxyAddr == address(0)){
            proxyAddr = IUserProxyFactory(params.proxyFactory).createProxy(to);
        }
		ILendingPool(params.lendingPool).borrow(vToken,amount,interestRateMode,referralCode,address(this));
        (uint256 fee,address networkFeeVault) =INetworkFeeController(params.networkFeeController).getNetworkFee(ethUser,method,vToken,amount);
         if(fee > 0){
            IERC20(vToken).transfer(networkFeeVault,fee);
        }
        uint256 targetAmount = amount-fee;
        IERC20(vToken).approve(params.lendingPool,targetAmount);
		ILendingPool(params.lendingPool).deposit(vToken,targetAmount,proxyAddr,referralCode);
        emit TransferCredit( asset, targetAmount, to, interestRateMode, referralCode);
	}


    function transferCreditToEthereum(address tokenController,address asset, uint256 amount,address to,uint256 interestRateMode,uint16 referralCode) public {
        bytes4 method = bytes4(keccak256("transferCreditToEthereum(address,address,uint256,address,uint256,uint16)"));
        Params memory  params = TokenController(tokenController).getParams();
		address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(params.proxyFactory).getProxy(to);
        address ethUser = IUserProxy(address(this)).owner();
        if(proxyAddr == address(0)){
            proxyAddr = IUserProxyFactory(params.proxyFactory).createProxy(to);
        }
		ILendingPool(params.lendingPool).borrow(vToken,amount,interestRateMode,referralCode,address(this));
        (uint256 fee,address networkFeeVault) =INetworkFeeController(params.networkFeeController).getNetworkFee(ethUser,method,vToken,amount);
         if(fee > 0){
            IERC20(vToken).transfer(networkFeeVault,fee);
        }
        uint256 targetAmount = amount-fee;
		IERC20(vToken).transfer(params.bridgeControl,targetAmount);
		IBridgeControl(params.bridgeControl).transferToEthereum(address(this),vToken, proxyAddr, targetAmount,4);
        emit TransferCreditToEthereum( asset, targetAmount,to, interestRateMode, referralCode);
	}

    function repay(address tokenController,address asset, uint256 amount,uint256 rateMode) public {
        bytes4 method = bytes4(keccak256("repay(address,address,uint256,uint256)"));
        Params memory  params = TokenController(tokenController).getParams();
		address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
		ILendingPool(params.lendingPool).withdraw(vToken,amount,address(this));
         address ethUser = IUserProxy(address(this)).owner();
        (uint256 fee,address networkFeeVault) =INetworkFeeController(params.networkFeeController).getNetworkFee(ethUser,method,vToken,amount);
        if(fee > 0){
            IERC20(vToken).transfer(networkFeeVault,fee);
        }
        uint256 targetAmount = amount-fee;
		ILendingPool(params.lendingPool).repay(vToken, targetAmount,rateMode,address(this));
		uint256 balanceAfterRepay = IERC20(vToken).balanceOf(address(this));
		if(balanceAfterRepay != 0){
			ILendingPool(params.lendingPool).deposit(vToken,balanceAfterRepay,address(this),0);
		}
        emit Repay(asset, targetAmount, rateMode);
	}

    function getParams() external view returns (Params memory){
        return addressParams[address(this)];

    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

interface IUserProxyFactory {
    event ProxyCreated(address indexed owner, address proxy);
    function getProxy(address owner) external view returns (address proxy);
    function createProxy(address owner) external returns (address proxy);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

interface IUserProxy {
    enum Operation {Call, DelegateCall}
    function owner() external view returns (address);
    function initialize(address,bytes32) external;
    function execTransaction(address,uint256,bytes calldata,Operation, uint256 nonce,bytes memory) external;
    function execTransaction(address,uint256,bytes calldata,Operation) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

interface IVTokenFactory {
    event VTokenCreated(address indexed token, address vToken);

    function bridgeControl() external view returns (address);

    function getVToken(address token) external view returns (address vToken);

    function createVToken(
        address token,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) external returns (address vToken);

    function setBridgeControl(address _bridgeControl) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;



interface ILendingPool {

    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

   
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getReserveData(address asset) external view returns (uint256,uint128,uint128,uint128,uint128,uint128,uint40,address,address,address,address,uint8);


}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    function decimals() external view returns (uint8);

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

    function mint(address spender, uint256 amount) external ;
    function burn(address spender, uint256 amount) external ;
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;
interface IBridgeControl {

   function transferToEthereum(address from,address vToken, address to, uint256 amount,uint256 action) external;
   function transferFromEthereumForDeposit(address token, address to, uint256 amount) external;
   function transferFromEthereumForRepay(address token, address to, uint256 amount,uint256 rateMode) external;
   function transferFromEthereum(address token, address to, uint256 amount) external;


}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

interface ITokenController {  
   function getParams() external view returns (address,address,address,address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

interface INetworkFeeController {
    function getNetworkFee(address sender, bytes4 method, address asset, uint256 amount) external view returns (uint256,address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;
interface IIncentivesController {

    function claimRewards(address[] memory _assets, uint256 amount) external;


}