/**
 *Submitted for verification at polygonscan.com on 2022-09-26
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;




//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IERC20
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract AirdropPayer {
    //----------------------------------------------------------------------------------------------------------
    address private _Owner;
    address private NFM=0x5Dd05762b831A977B974Db8759772D41F3D5Ff0b;

    constructor() {
        _Owner = msg.sender;        
    }

    function payOuts(address[] memory Receiver, uint256[] memory Amount)
        public
        returns (bool)
    {
        require(msg.sender==_Owner, "oO");
        require(Receiver.length == Amount.length, "nL");
        for(uint256 i=0; i<Receiver.length;i++){
            IERC20(address(NFM)).transfer(Receiver[i],(Amount[i]*10**18));
        }
        return true;
    }
    
    function _getWithdraw(
        address To
    ) public returns (bool) {
        require(msg.sender==_Owner, "oO");
        uint256 CoinAmount = IERC20(address(NFM)).balanceOf(address(this));        
            IERC20(address(NFM)).transfer(To, CoinAmount);
            return true;        
    }
}