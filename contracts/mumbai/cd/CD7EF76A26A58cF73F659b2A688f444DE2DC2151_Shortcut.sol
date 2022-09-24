// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity =0.8.14;

import {IShortcut} from "../interfaces/IShortcut.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool{
    function checkEligible(address erc20Addr)
        external
        view
        returns (bool);
}

contract Shortcut{

    IPool public NCT;
    IPool public BCT;
    address stablecoin;

    constructor(address _nct, address _bct, address _stablecoin){
        NCT = IPool(_nct);
        BCT = IPool(_bct);
        stablecoin = _stablecoin;
    }

    function checkShortcut(
        address _fromToken,
        address _toToken,
        uint _amIn,
        uint _minAmOut
    ) 
    external 
    view
    returns(bool){
        address c = _getShortcutContract(_fromToken, _toToken);

        if(c == address(0)){
            return false;
        }else{
            return IShortcut(c).isValid(_fromToken, _toToken, _amIn, _minAmOut);
        }
    }

    function executeShortcut(
        address _fromToken,
        address _toToken,
        uint _amIn,
        uint _minAmOut
    )
    external
    returns(uint amToReturn){
        address c = _getShortcutContract(_fromToken, _toToken);
        require(c != address(0), "Shortcut not valid");
        IERC20 fromToken = IERC20(_fromToken);
        fromToken.transferFrom(msg.sender, address(this), _amIn);
        fromToken.approve(c,_amIn);

        amToReturn = IShortcut(c).execute(_fromToken, _toToken, _amIn, _minAmOut);
        require(amToReturn >= _minAmOut, "Not enough tokens returned");
        IERC20(_toToken).transfer(msg.sender, amToReturn);
    }

    function _getShortcutContract(address _fromToken, address _toToken) internal view returns(address c){
        if(_fromToken == stablecoin){
            c = _getShortcutContract(_toToken);
        // if sell
        }else if(_toToken == stablecoin){
            c = _getShortcutContract(_fromToken);
        }else{
            return address(0);
        }
    }

    function _getShortcutContract(address _token) internal view returns(address){
        try NCT.checkEligible(_token) returns(bool eligible){
            if(eligible){
                return address(NCT);
            }
            try BCT.checkEligible(_token) returns(bool _eligible){
                if(_eligible){
                    return address(BCT);
                }
            }catch{
                return address(0);
            }
        }catch{
            return address(0);
        }
        
        return address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IShortcut{

    function isValid(
        address _fromToken,
        address _toToken,
        uint _amIn,
        uint _amOut
    )
    external
    view
    returns(bool);

    function execute(
        address _fromToken,
        address _toToken,
        uint _amIn,
        uint _amOut
    )
    external
    returns(uint);

    function checkEligible(address) external view returns(bool eligible);
}