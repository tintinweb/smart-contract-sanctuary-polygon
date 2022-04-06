/**
 *Submitted for verification at polygonscan.com on 2022-04-06
*/

// SPDX-License-Identifier: MIT
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

    // custom add
    function decimals() external view returns (uint8) ;
}

interface LendErc20 {
    // Deposit ,requires token authorization
    function mint(uint256 mintAmount) external returns (uint256);
    function redeem(uint256 redeemTokens) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint256);
    function repayBorrow(uint256 repayAmount) external returns (uint256);
    function getAccountSnapshot(address account) external view returns (uint256, uint256, uint256, uint256);
    // borrow amount
    function borrowBalanceStored(address account) external view returns (uint);

    // deposit matic
    // function mint() external;
    // repay matic
    // function repayBorrow() external;
}

interface LendComptroller{
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);
    /**
     * PIGGY-MODIFY:
     * @notice Add assets to be included in account liquidity calculation
     * @param pTokens List of cToken market addresses to be activated
     * @return Whether to enter each corresponding market success indicator
     */
    function enterMarkets(address[] memory pTokens) external returns(uint[] memory);

    function exitMarket(address pTokenAddress) external returns (uint);

    // Query available loan (whether it is normal 0: normal, remaining loanable amount, loan asset premium)
    function getAccountLiquidity(address account) external view returns (uint, uint, uint) ;

    // Query the fund pool that has opened the pledge
    function getAssetsIn(address account) external view returns(address [] memory);
}

interface PoolProvider{
    // get pool address by token address
    function getUnderlyingByPToken(address underlying) external returns (address pToken);
}

contract HLend {
    function deposit(address token,uint256 amount) external  {
        address pool = getPool(token);
        IERC20(token).approve(pool,amount);
        LendErc20(pool).mint(amount);
    }

    // function depositMatic(address token,uint256 amount) external  {
    //     address pool = getPool(token);
    //     LendErc20(pool).mint();
    // }

    function borrow(address token,uint256 amount) external  {
        address pool = getPool(token);
        pledge(pool);
        LendErc20(pool).borrow(amount);
    }

    // withdraw token from pool, params: PToken, amount
    function withdrawByPToken(address pToken,uint256 amount) external {
        LendErc20(pToken).redeem(amount);
    }

    function withdraw(address token,uint256 amount) external{
        address pool = getPool(token);
        LendErc20(pool).redeem(amount);
    }

    function repayBorrow(address token,uint256 amount) external {
            address pool = getPool(token);
            IERC20(token).approve(pool,amount);
            LendErc20(pool).repayBorrow(amount);
        }

    // function repayBorrowMatic(address token) external {
    //         address pool = getPool(token);
    //         LendErc20(pool).repayBorrow();
    //     }

    // Turn on the pledge switch
    function pledge(address pool) internal {
        address comptorller = getLendComptroller();
        address [] memory assets = LendComptroller(comptorller).getAssetsIn(address(this));
        uint256 arrayLen = assets.length;
        bool hasPledge = false;
        for(uint256 i = 0;i<arrayLen;i++){
            if(pool == assets[i]){
                hasPledge = true;
            }
        }
        if(!hasPledge){
            address[] memory pledges = new address[](1);
            pledges[0] = pool;
            LendComptroller(comptorller).enterMarkets(pledges);
        }
    }

    // switch on the pledge
    function enterMarket(address[] memory pools) public{
            address comptorller = getLendComptroller();
            LendComptroller(comptorller).enterMarkets(pools);
    } 

    // whether the pool has been opened
    function  isEntermarket(address pToken) public view returns(address[] memory) {
        address comptorller = getLendComptroller();
        address[] memory assets = LendComptroller(comptorller).getAssetsIn(pToken);
        return assets;
    }

    // get pool address by token address
    function getPool(address token) internal  returns(address ){
       return PoolProvider(0x76831939fc9A078a9Fd4A5B005C8A19c9012bA45).getUnderlyingByPToken(token);
        
    }

    // get comptroller address
    function getLendComptroller() internal pure returns(address comptroller ){
        comptroller = 0xE19bedCc1beDF52F63b401bd21f16529be33Fc7E;
         return comptroller;
    }

    function getPoolDecimals() public pure returns(uint8){
        return 8;
    }
}