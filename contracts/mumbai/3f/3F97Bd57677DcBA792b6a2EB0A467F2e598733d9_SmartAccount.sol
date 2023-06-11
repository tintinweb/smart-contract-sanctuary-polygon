/**
 *Submitted for verification at polygonscan.com on 2023-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ERC20Interface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

interface BalancePortfolioABT{
    function InclockedAmt(address, int256) external;
    function DeclockedAmt(address, int256) external;
    function IncunlockedAmt(address, int256) external; 
    function DecunlockedAmt(address, int256) external;
    function IncliquidityBalance(address , int256) external;
    function DecliquidityBalance(address , int256 ) external;
    function getliquidityBalance(address ) external view returns(int256);
    function getLockedBalance(address) external view returns(int256);
    function getUnlockedBalance(address) external view returns(int256);
    function setOwner(address) external; 
    function getAbtId(address user) external view returns(uint256);
    function getOwner() external view returns(address); 
}

interface PlaceOrder{
    function LPmatch(address traderSA, address lpSA, address buyToken, address sellToken, int256 orderAmt, int256 matchedAmt, int256 fees) external;
}




interface SACStorage{
    function isEOARegistered(address) external view returns(bool);
    function isSmartAccount(address) external view returns(bool);
    function getSA(address) external view returns(address);
}
// interface MFArecovery{
//     function confirmHash(address,bytes32) external view returns(bool);
// }

interface Valutinterface{
    function deposit(uint256,address,address,address,address ) external;
    function withdraw(address,uint256,address,address,address,address,address) external;
    function addLiquidity(int256, address, address) external;
    function removeLiquidity(int256,address,address) external;
    function LPmatch(address, address, address, address, address, int256, int256, int256 ,address) external;
}

contract SmartAccount {

    event Deposit(address indexed depositor, address indexed to, uint256 amount);
    event Withdrawal(address indexed withdrawer,address indexed from, uint256 amount);
    
    mapping(string =>mapping(address => bool)) whitelistToken;
    function deposit(uint256 amount, address to, address erc20, address erc20Valut, address balancePortfolioABTAddres, address SACStorageAddrs) external {
        require(amount > 0, "Must deposit a positive amount");
        SACStorage sacStorage = SACStorage(SACStorageAddrs);
        address isSA = sacStorage.getSA(msg.sender);
        require(isSA==address(this),"caller is not a owner of SA");
        Valutinterface valut = Valutinterface(erc20Valut);
        valut.deposit(amount,to,erc20,balancePortfolioABTAddres,SACStorageAddrs);
        emit Deposit(msg.sender,address(this),amount);
    }

    function withdraw(uint256 amount, address reciever, address erc20Valut, address erc20, address balancePortfolioABTAddres, address SACStorageAddrs,address _MFAaddress) external {
        require(amount > 0, "Must withdraw a positive amount");
        SACStorage sacStorage = SACStorage(SACStorageAddrs);
        address isSA = sacStorage.getSA(msg.sender);
        require(isSA==address(this),"caller is not a owner of SA");
        Valutinterface valut = Valutinterface(erc20Valut);
        valut.withdraw(msg.sender,amount,reciever,erc20,balancePortfolioABTAddres,SACStorageAddrs,_MFAaddress);
        emit Withdrawal(msg.sender,address(this), amount);
    }

    function addLiquidity(int256 amount, address erc20Valut, address balancePortfolioABTAddres, address SACStorageAddrs) external {
        require(amount > 0, "Must add a positive amount");
        SACStorage sacStorage = SACStorage(SACStorageAddrs);
        address isSA = sacStorage.getSA(msg.sender);
        require(isSA==address(this),"caller is not a owner of SA");
        Valutinterface valut = Valutinterface(erc20Valut);
        valut.addLiquidity(amount,balancePortfolioABTAddres,SACStorageAddrs);

    }
    function addPermissibleToken(string memory pair, address perERC20, address SACStorageAddrs) external {
        SACStorage sacStorage = SACStorage(SACStorageAddrs);
        address isSA = sacStorage.getSA(msg.sender);
        require(isSA==address(this),"caller is not a owner of SA");
        whitelistToken[pair][perERC20] = true;
    }

    function removeLiquidity(int256 amount, address erc20Valut, address balancePortfolioABTAddres, address SACStorageAddrs) external {
        require(amount > 0, "Must remove a positive amount");
        SACStorage sacStorage = SACStorage(SACStorageAddrs);
        address isSA = sacStorage.getSA(msg.sender);
        require(isSA==address(this),"caller is not a owner of SA");
        Valutinterface valut = Valutinterface(erc20Valut);
        valut.removeLiquidity(amount,balancePortfolioABTAddres,SACStorageAddrs);
    }

    function tradeSwap(address lpSA,address dextrSA, address buyToken, address sellToken, int256 orderAmt, int256 matchedAmt, int256 fees, address SACStorageAddrs, address erc20Valut) external {
        SACStorage sacStorage = SACStorage(SACStorageAddrs);
        address isSA = sacStorage.getSA(msg.sender);
        require(isSA==address(this),"caller is not a owner of SA");
        Valutinterface valut = Valutinterface(erc20Valut);
        valut.LPmatch(address(this),lpSA,dextrSA, buyToken,sellToken,orderAmt,matchedAmt,fees,SACStorageAddrs);
    }

    function isPerToken(string memory pair, address perERC20) external view returns(bool) {
        return whitelistToken[pair][perERC20];
    }
    


}