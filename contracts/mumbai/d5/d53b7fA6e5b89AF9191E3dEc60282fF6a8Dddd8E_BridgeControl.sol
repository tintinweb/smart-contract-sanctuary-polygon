//  SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import './interfaces/IUserProxy.sol';
import './interfaces/IUserProxyFactory.sol';
import './interfaces/IVTokenFactory.sol';
import './interfaces/IVToken.sol';
import './interfaces/ILendingPool.sol';
import './interfaces/IERC20.sol';
import './libraries/Ownable.sol';

interface IVeDEFE {
    struct LockedBalance {
        int256 amount;
        uint256 end;
    }
    function createLockFor(
        address _beneficiary,
        uint256 _value,
        uint256 _unlockTime
    ) external;

    function increaseAmountFor(address _beneficiary, uint256 _value) external;
    function getLocked(address _addr) external view returns (LockedBalance memory);
}

contract BridgeControl is Ownable{

    address public proxyFactory;
    address public vTokenFactory;
    address public lendingPool;
    address public virtualDefedToken;
    address public veDEFE;
    mapping(bytes32=>bool) transactions;

    event TransferToEthereum(address indexed ethAddr, address indexed proxyAddr, address token, address vToken, uint256 value);
    event TransferFromEthereum(address indexed ethAddr, address indexed proxyAddr, address token, address vToken, uint256 value,bytes32 transactionId);
    event TransferFromEthereumForDeposit(address indexed ethAddr, address indexed proxyAddr, address token, address vToken, uint256 value,bytes32 transactionId);
    event TransferFromEthereumForRepay(address indexed ethAddr, address indexed proxyAddr, address token, address vToken, uint256 value,bytes32 transactionId);
    event lockFromEthereumLog(address indexed ethAddr, address indexed proxyAddr, address virtualDefedToken, uint256 amount, uint256 time);
    constructor(address _proxyFactory, address _vTokenFactory,address _lendingPool) public {
        proxyFactory = _proxyFactory;
        vTokenFactory = _vTokenFactory;
        lendingPool = _lendingPool;
    }

    function setVirtualDefedToken(address _virtualDefedToken,address _veDEFE) external onlyOwner{
        virtualDefedToken = _virtualDefedToken;
        veDEFE = _veDEFE;
    }



	function transferToEthereum(address vToken, address to, uint256 amount) external {//TODO 只能准给本合约然后本合约再去跨链，方便后边收手续费
        address ethAddr = IUserProxy(to).owner();
        require(ethAddr != address(0), 'PROXY_EXISTS');
        address token = IVToken(vToken).ETHToken();
        require(token != address(0), "unknow token");
		IERC20(vToken).burn(address(this), amount);
        emit TransferToEthereum(ethAddr, to, token, vToken, amount);
	}

	function transferFromEthereumForDeposit(bytes32 transactionId,address token, address to, uint256 amount) public onlyOwner {//TODO 暂时还缺少多签鉴权
        address vToken = IVTokenFactory(vTokenFactory).getVToken(token);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(to);
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(proxyFactory).createProxy(to);
        }
		IERC20(vToken).mint(address(this), amount);
        IERC20(vToken).approve(lendingPool,amount);
        ILendingPool(lendingPool).deposit(vToken,amount,proxyAddr,0);
        transactions[transactionId] = true;
        emit TransferFromEthereumForDeposit(to, proxyAddr, token, vToken, amount,transactionId);
	}

    function transferFromEthereumForRepay(bytes32 transactionId,address token, address to, uint256 amount,uint256 rateMode) public onlyOwner {//TODO 暂时还缺少多签鉴权
        address vToken = IVTokenFactory(vTokenFactory).getVToken(token);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(to);
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(proxyFactory).createProxy(to);
        }
		IERC20(vToken).mint(proxyAddr,amount);
        IERC20(vToken).approve(lendingPool,amount);
        ILendingPool(lendingPool).repay(vToken, amount,rateMode,proxyAddr);
        uint256 balanceAfterRepay = IERC20(vToken).balanceOf(address(this));
        if(balanceAfterRepay > 0){
            ILendingPool(lendingPool).deposit(vToken,balanceAfterRepay,proxyAddr,0);
        }
        transactions[transactionId] = true;
        emit TransferFromEthereumForRepay(to, proxyAddr, token, vToken, amount,transactionId);
	}
     function transferFromEthereum(bytes32 transactionId,address token, address to, uint256 amount) public onlyOwner {//TODO 暂时还缺少多签鉴权
        address vToken = IVTokenFactory(vTokenFactory).getVToken(token);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(to);
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(proxyFactory).createProxy(to);
        }
		IERC20(vToken).mint(proxyAddr, amount);
        transactions[transactionId] = true;
        emit TransferFromEthereum(to, proxyAddr, token, vToken, amount,transactionId);
	}

    function lockFromEthereum(address user, uint256 amount,uint256 time) public onlyOwner {//TODO 暂时还缺少多签鉴权
        address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(user);
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(proxyFactory).createProxy(user);
        }
		lockDefe(proxyAddr,amount,time);
        emit lockFromEthereumLog(user, proxyAddr, virtualDefedToken, amount,time);
	}

    function lockDefe(address proxyAddr,uint256 amount,uint256 time) internal{
        IVeDEFE.LockedBalance memory locked = IVeDEFE(veDEFE).getLocked(proxyAddr);
        IERC20(virtualDefedToken).approve(veDEFE,amount);
        if(locked.amount == 0){
            IVeDEFE(veDEFE).createLockFor(proxyAddr,amount,time);
        }else{
            IVeDEFE(veDEFE).increaseAmountFor(proxyAddr,amount);
        }
    }

}

//  SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public{
        _transferOwnership(msg.sender);
    }
        /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

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

interface IVToken {
    function ETHToken() external view  returns (address);
    function initialize(address _token, address _PToken,string memory tokenName,string memory tokenSymbol,uint8 tokenDecimals) external;
    function flashSwap(address to, bytes calldata data) external;
}

//  SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

interface IVTokenFactory {
    event VTokenCreated(address indexed token, address vToken);
    function bridgeControl() external view returns (address);
    function getVToken(address token) external view returns (address vToken);
    function createVToken(address token, address PToken,string memory tokenName,string memory tokenSymbol,uint8 tokenDecimals) external returns (address vToken);
    function setBridgeControl(address _bridgeControl) external;
}

//  SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

interface IUserProxyFactory {
    event ProxyCreated(address indexed owner, address proxy);
    function getProxy(address owner) external view returns (address proxy);
    function createProxy(address owner) external returns (address proxy);
}

//  SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

interface IUserProxy {
    enum Operation {Call, DelegateCall}
    function factory() external view returns (address);
    function owner() external view returns (address);
    function initialize(address,bytes32) external;
    function execTransaction(address,uint256,bytes calldata,Operation, uint256 nonce,bytes memory) external;
    function execTransaction(address,uint256,bytes calldata,Operation) external;
}