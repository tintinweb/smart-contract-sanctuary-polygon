/**
 *Submitted for verification at polygonscan.com on 2022-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IJavaSwapRoute {

    function sellUSDT(uint256 tokenAmountToSell) external returns (uint256 tokenAmount);
    function getLatestPriceCOPUSD() external returns (int256);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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

contract AutoSwap is Ownable{  

    uint256 public limitSellAmount = 500000;
    event WithdrawEvent(address withdrawToken, uint256 amount);
    IJavaSwapRoute JavaSwapRoute = IJavaSwapRoute(address(0x7e6A8E11866E1a6Dd60d223a4678E5eF6Cb377d9));

    function getUSDTBalance() payable external returns (uint256) {
        address _usdtToken = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
        address _dlyToken = 0x1659fFb2d40DfB1671Ac226A0D9Dcc95A774521A;
        uint256 usdtBlance = IERC20(_usdtToken).balanceOf(address(0x7e6A8E11866E1a6Dd60d223a4678E5eF6Cb377d9));
        if(usdtBlance > 5000000) {
            uint256 dlyPerUsdt = uint256(JavaSwapRoute.getLatestPriceCOPUSD())*10**12;
            uint256 dlyTokenAmountForUsdt = SafeMath.mul(dlyPerUsdt, usdtBlance);
            Account newContract = new Account();            
            require(
                IERC20(_dlyToken).transfer(address(newContract), dlyTokenAmountForUsdt),
                "Failed to transfer DLYCOP to new Account."            
            );            
        }
        return usdtBlance;
    }

    function withdraw(uint withdrawAmount, address withdrawToken) onlyOwner external {
        require(withdrawAmount <= IERC20(withdrawToken).balanceOf(address(this)), "WithdrawAmount cann't bigger than balance");                
        IERC20(withdrawToken).transfer(msg.sender, withdrawAmount);
        emit WithdrawEvent(withdrawToken, withdrawAmount);
    }  

}

contract Account is Ownable {

    event BuyUSDT(
        address buyer,
        uint256 amountSell
    );

    IJavaSwapRoute JavaSwapRoute = IJavaSwapRoute(address(0x7e6A8E11866E1a6Dd60d223a4678E5eF6Cb377d9));
    function autoDLYUSDTSwap(uint256 dlyAmount) public payable {    
        address _usdtToken = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;                    
        require(dlyAmount <= 0, "Faild action found");
        uint256 dlyTokenAmountToBuy;                
        if(dlyAmount >= 500000) {
            dlyTokenAmountToBuy = 500000;
        }        
        JavaSwapRoute.sellUSDT(dlyTokenAmountToBuy);   
        uint256 _usdtBlance = IERC20(_usdtToken).balanceOf(address(this));
        require(
            IERC20(_usdtToken).transfer(payable(msg.sender), _usdtBlance),
            "Failed to send usdt token to origin account."
        );        
        emit BuyUSDT(address(this), dlyTokenAmountToBuy);
        selfdestruct(payable(msg.sender));
    }
    
}