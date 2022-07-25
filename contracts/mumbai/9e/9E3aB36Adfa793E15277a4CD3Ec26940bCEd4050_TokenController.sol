//  SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

import './interfaces/IUserProxyFactory.sol';
import './interfaces/IVTokenFactory.sol';
import './interfaces/ILendingPool.sol';
import './BridgeControl.sol';



contract TokenController {

    address public lendingPOOL;
    address public bridgeControl;
    address public vTokenFactory;
    address public proxyFactory;

    constructor(address _lendingPOOL, address _bridgeControl, address _vTokenFactory,address _proxyFactory){
        lendingPOOL = _lendingPOOL;
        bridgeControl = _bridgeControl;
        vTokenFactory = _vTokenFactory;
        proxyFactory = _proxyFactory;
    }
    function withdrawToEthereum(address asset, uint256 amount) public {
		address vToken = IVTokenFactory(vTokenFactory).getVToken(asset);
        require(vToken == address(0), "unknow token");
		ILendingPool(lendingPOOL).withdraw(vToken,amount,address(this));
		BridgeControl(bridgeControl).transferToEthereum(vToken, address(this), amount);
	}

    function borrowToEthereum(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode) public {
        address vToken = IVTokenFactory(vTokenFactory).getVToken(asset);
        require(vToken == address(0), "unknow token");
		ILendingPool(lendingPOOL).borrow(vToken, amount, interestRateMode, referralCode, address(this));
        IERC20(vToken).transfer(bridgeControl,amount);
		BridgeControl(bridgeControl).transferToEthereum(vToken, address(this), amount);
	}

    function borrow(address asset, uint256 amount,uint256 interestRateMode,uint16 referralCode) public {
		address vToken = IVTokenFactory(vTokenFactory).getVToken(asset);
        require(vToken == address(0), "unknow token");
		ILendingPool(lendingPOOL).borrow(vToken,amount,interestRateMode,referralCode,address(this));
		ILendingPool(lendingPOOL).deposit(vToken,amount,address(this),referralCode);
	}

    function transfer(address asset, uint256 amount,address to) public {
		address vToken = IVTokenFactory(vTokenFactory).getVToken(asset);
        require(vToken == address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(to);
        require(proxyAddr != address(0), "unknow to");
         ( , , , , , , ,address aToken, , , , ) = ILendingPool(lendingPOOL).getReserveData(vToken);
		IERC20(aToken).transfer(proxyAddr,amount);
	}
    function transferToEthereum(address asset, uint256 amount,address to) public {
		address vToken = IVTokenFactory(vTokenFactory).getVToken(asset);
        require(vToken == address(0), "unknow token");
		address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(to);
        require(proxyAddr != address(0), "unknow to");
		ILendingPool(lendingPOOL).withdraw(vToken,amount,bridgeControl);
		BridgeControl(bridgeControl).transferToEthereum(vToken, proxyAddr, amount);
    }
    function transferCredit(address asset, uint256 amount,address to,uint256 interestRateMode,uint16 referralCode) public {
		address vToken = IVTokenFactory(vTokenFactory).getVToken(asset);
        require(vToken == address(0), "unknow token");
		address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(to);
        require(proxyAddr != address(0), "unknow to");
		ILendingPool(lendingPOOL).borrow(vToken,amount,interestRateMode,referralCode,address(this));
		ILendingPool(lendingPOOL).deposit(vToken,amount,proxyAddr,referralCode);
	}

    function transferCreditToEthereum(address asset, uint256 amount,address to,uint256 interestRateMode,uint16 referralCode) public {
		address vToken = IVTokenFactory(vTokenFactory).getVToken(asset);
        require(vToken == address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(to);
        require(proxyAddr != address(0), "unknow to");
		ILendingPool(lendingPOOL).borrow(vToken,amount,interestRateMode,referralCode,address(this));
		IERC20(vToken).transfer(bridgeControl,amount);
		BridgeControl(bridgeControl).transferToEthereum(vToken, proxyAddr, amount);
	}

    function repay(address asset, uint256 amount,uint256 rateMode) public {
		address vToken = IVTokenFactory(vTokenFactory).getVToken(asset);
        require(vToken == address(0), "unknow token");
		ILendingPool(lendingPOOL).withdraw(vToken,amount,address(this));
		ILendingPool(lendingPOOL).repay(vToken, amount,rateMode,address(this));
		uint256 balanceAfterRepay = IERC20(vToken).balanceOf(address(this));
		if(balanceAfterRepay != 0){
			ILendingPool(lendingPOOL).deposit(vToken,balanceAfterRepay,address(this),0);
		}
	}
}

//  SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

import './interfaces/IUserProxy.sol';
import './interfaces/IUserProxyFactory.sol';
import './interfaces/IVTokenFactory.sol';
import './interfaces/IVToken.sol';
import './interfaces/ILendingPool.sol';
import './interfaces/IERC20.sol';


contract BridgeControl {

    address public proxyFactory;
    address public vTokenFactory;
    address public lendingPool;

    event TransferToEthereum(address indexed ethAddr, address indexed proxyAddr, address token, address vToken, uint256 value);
    event TransferFromEthereum(address indexed ethAddr, address indexed proxyAddr, address token, address vToken, uint256 value);

    event TransferFromEthereumForDeposit(address indexed ethAddr, address indexed proxyAddr, address token, address vToken, uint256 value);
    event TransferFromEthereumForRepay(address indexed ethAddr, address indexed proxyAddr, address token, address vToken, uint256 value);
    constructor(address _proxyFactory, address _vTokenFactory,address _lendingPool){
        proxyFactory = _proxyFactory;
        vTokenFactory = _vTokenFactory;
        lendingPool = _lendingPool;
    }

	function transferToEthereum(address vToken, address to, uint256 amount) external {//TODO 只能准给本合约然后本合约再去跨链，方便后边收手续费
        address ethAddr = IUserProxy(to).owner();
        require(ethAddr != address(0), 'PROXY_EXISTS');
        address token = IVToken(vToken).ETHToken();
        require(token != address(0), "unknow token");
		IERC20(vToken).burn(address(this), amount);
        emit TransferToEthereum(ethAddr, to, token, vToken, amount);
	}

	function transferFromEthereumForDeposit(address token, address to, uint256 amount) external {//TODO 暂时还缺少多签鉴权
        address vToken = IVTokenFactory(vTokenFactory).getVToken(token);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(to);
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(proxyFactory).createProxy(to,lendingPool);
        }
		IERC20(vToken).mint(address(this), amount);
        ILendingPool(lendingPool).deposit(vToken,amount,proxyAddr,0);
        emit TransferFromEthereumForDeposit(to, proxyAddr, token, vToken, amount);
	}

    function transferFromEthereumForRepay(address token, address to, uint256 amount,uint256 rateMode) external {//TODO 暂时还缺少多签鉴权
        address vToken = IVTokenFactory(vTokenFactory).getVToken(token);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(to);
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(proxyFactory).createProxy(to,lendingPool);
        }
		IERC20(vToken).mint(proxyAddr,amount);
        ILendingPool(lendingPool).repay(vToken, amount,rateMode,proxyAddr);
        uint256 balanceAfterRepay = IERC20(vToken).balanceOf(address(this));
        if(balanceAfterRepay > 0){
            ILendingPool(lendingPool).deposit(vToken,balanceAfterRepay,proxyAddr,0);
        }
        emit TransferFromEthereumForRepay(to, proxyAddr, token, vToken, amount);
	}
     function transferFromEthereum(address token, address to, uint256 amount) external {//TODO 暂时还缺少多签鉴权
        address vToken = IVTokenFactory(vTokenFactory).getVToken(token);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(to);
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(proxyFactory).createProxy(to,lendingPool);
        }
		IERC20(vToken).mint(proxyAddr, amount);
        emit TransferFromEthereum(to, proxyAddr, token, vToken, amount);
	}

}

//  SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;
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

//  SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

interface IVTokenFactory {
    event VTokenCreated(address indexed token, address vToken);
    function getVToken(address token) external view returns (address vToken);
    function createVToken(address token,string memory name,string memory symbol,uint8 decimals,address bridgeControl) external returns (address vToken);
}

//  SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

interface IUserProxyFactory {
    event ProxyCreated(address indexed owner, address proxy);
    function getProxy(address owner) external view returns (address proxy);
    function createProxy(address owner,address lendingPool) external returns (address proxy);
}

//  SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

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

    function mint(address spender, uint256 amount) external;
    function burn(address spender, uint256 amount) external;
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

//  SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

interface IVToken {
    function factory() external view returns (address);
    function ETHToken() external returns (address vToken);
}

//  SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

interface IUserProxy {
    enum Operation {Call, DelegateCall}
    function factory() external view returns (address);
    function owner() external view returns (address);
    function initialize(address,address) external;
    function execTransaction(address,uint256,bytes calldata,Operation,bytes memory) external;
}