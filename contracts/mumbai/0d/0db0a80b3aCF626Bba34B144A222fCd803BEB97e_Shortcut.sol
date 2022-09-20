// SPDX-License-Identifier: MIT

pragma solidity =0.8.14;

import {IShortcut} from "../interfaces/IShortcut.sol";

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
        uint _amOut
    ) 
    external 
    view
    returns(bool){
        address c = _getShortcutContract(_fromToken, _toToken);

        if(c == address(0)){
            return false;
        }else{
            return IShortcut(c).isValid(_fromToken, _toToken, _amIn, _amOut);
        }
    }

    function executeShortcut(
        address _fromToken,
        address _toToken,
        uint _amIn,
        uint _amOut
    )
    external 
    returns(uint){
        address c = _getShortcutContract(_fromToken, _toToken);
        require(c != address(0), "Shortcut not valid");
        return IShortcut(c).execute(msg.sender, _fromToken, _toToken, _amIn, _amOut);
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
        if(NCT.checkEligible(_token)){
            return address(NCT);
        }

        if(BCT.checkEligible(_token)){
            return address(BCT);
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
        address _maker,
        address _fromToken,
        address _toToken,
        uint _amIn,
        uint _amOut
    )
    external
    returns(uint);

    function checkEligible(address) external view returns(bool eligible);
}