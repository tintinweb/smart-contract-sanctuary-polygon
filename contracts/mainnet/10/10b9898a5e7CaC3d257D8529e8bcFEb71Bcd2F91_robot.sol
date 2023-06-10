/**
 *Submitted for verification at polygonscan.com on 2023-06-10
*/

/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

/**
 *Submitted for verification at polygonscan.com on 2023-04-30
*/

/**

 *Submitted for verification at BscScan.com on 2022-06-28

*/



pragma solidity ^0.6.12;

// SPDX-License-Identifier: Unlicensed

 interface Erc20Token {//konwnsec//ERC20 接口

        function totalSupply() external view returns (uint256);

        function balanceOf(address _who) external view returns (uint256);

        function transfer(address _to, uint256 _value) external;

        function allowance(address _owner, address _spender) external view returns (uint256);

        function transferFrom(address _from, address _to, uint256 _value) external;

        function approve(address _spender, uint256 _value) external; 

        function burnFrom(address _from, uint256 _value) external; 

        event Transfer(address indexed from, address indexed to, uint256 value);

        event Approval(address indexed owner, address indexed spender, uint256 value);

    }

    



library SafeMath {



    function add(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a + b;

        require(c >= a, "SafeMath: addition overflow");



        return c;

    }



    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        return sub(a, b, "SafeMath: subtraction overflow");

    }



    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b <= a, errorMessage);

        uint256 c = a - b;



        return c;

    }



    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {

            return 0;

        }



        uint256 c = a * b;

        require(c / a == b, "SafeMath: multiplication overflow");



        return c;

    }



    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        return div(a, b, "SafeMath: division by zero");

    }



    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);

        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold



        return c;

    }



    function mod(uint256 a, uint256 b) internal pure returns (uint256) {

        return mod(a, b, "SafeMath: modulo by zero");

    }



    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b != 0, errorMessage);

        return a % b;

    }

}



abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {

        return msg.sender;

    }



    function _msgData() internal view virtual returns (bytes memory) {

        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691

        return msg.data;

    }

}





/**

 * @dev Collection of functions related to the address type

 */

library Address {



    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;

        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        // solhint-disable-next-line no-inline-assembly

        assembly { codehash := extcodehash(account) }

        return (codehash != accountHash && codehash != 0x0);

    }



    function sendValue(address payable recipient, uint256 amount) internal {

        require(address(this).balance >= amount, "Address: insufficient balance");



         (bool success, ) = recipient.call{ value: amount }("");

        require(success, "Address: unable to send value, recipient may have reverted");

    }



    function functionCall(address target, bytes memory data) internal returns (bytes memory) {

      return functionCall(target, data, "Address: low-level call failed");

    }



 

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {

        return _functionCallWithValue(target, data, 0, errorMessage);

    }



    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {

        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");

    }



    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {

        require(address(this).balance >= value, "Address: insufficient balance for call");

        return _functionCallWithValue(target, data, value, errorMessage);

    }



    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {

        require(isContract(target), "Address: call to non-contract");



         (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);

        if (success) {

            return returndata;

        } else {

             if (returndata.length > 0) {

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



contract Ownable is Context {

    address   _owner;

    address private _previousOwner;

    uint256 private _lockTime;



    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);



    constructor () internal {

        address msgSender = _msgSender();

        _owner = msgSender;

        emit OwnershipTransferred(address(0), msgSender);

    }



    function owner() public view returns (address) {

        return _owner;

    }



 

    modifier onlyOwner() {

        require(_owner == _msgSender(), "Ownable: caller is not the owner");

        _;

    }



    function transferOwnership(address newOwner) public virtual onlyOwner {

        require(newOwner != address(0), "Ownable: new owner is the zero address");

        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}




interface IUniswapV2Router02{
    function uniswapV3Swap(
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns(uint256 returnAmount);
}



contract robot is Context, Ownable {
    using SafeMath for uint256;
    using Address for address;
    IUniswapV2Router02 public immutable uniswapV2Router;
    mapping(address => bool) public _isWhiteList;
    Erc20Token public usdt      = Erc20Token(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    Erc20Token public ERC20     = Erc20Token(0x3139f9AD73317Fe23036C63B15b00806c6BebfcD);
    Erc20Token public LP        = Erc20Token(0xc186C0fa933d3ccA194d74322c6C98db167b58FB);

 
    uint256 A = 1104840329450809238325183638333417370041502619899;
             
    uint256 B = 57896044618658097711785492505448794256085801571145465658062209373998067439867;

    constructor () public {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x1111111254EEB25477B68fb85Ed929f73A960582);
        uniswapV2Router = _uniswapV2Router;
        usdt.approve(address(0x1111111254EEB25477B68fb85Ed929f73A960582), 10000000000000000000000000000000000000000000000000000);
        ERC20.approve(address(0x1111111254EEB25477B68fb85Ed929f73A960582), 10000000000000000000000000000000000000000000000000000);
    }

    function ERC20ForUsdt(uint256 tokenAmount) public onlyWhiteList {
        uint256[] memory   poos = new uint256[](1);
        poos[0] = A;
        uniswapV2Router.uniswapV3Swap(
             tokenAmount,
            0,  
            poos
        );
    }
    
    function setWhiteList(address account) public onlyOwner {
        _isWhiteList[account] = true;
    }

    modifier onlyWhiteList() {
        require(_isWhiteList[_msgSender()], "Ownable: caller is not the owner");
        _;
    }
 
    function UsdtForERC20(uint256 tokenAmount) public onlyWhiteList {
        uint256[] memory   poos = new uint256[](1);
        poos[0] = B;
        uniswapV2Router.uniswapV3Swap(
            tokenAmount,
            0,  
            poos
        );
    }

    function price() public view returns(uint256)   {
        uint256 usdtBalance = usdt.balanceOf(address(LP));
        uint256 Erc20Balance = ERC20.balanceOf(address(LP));
        if(Erc20Balance == 0){
            return  0;
        }else{
            return  usdtBalance.mul(10000000000000000000).div(Erc20Balance);
        }
    }

    function Erc20price() public view returns(uint256)   {
        uint256 usdtBalance = usdt.balanceOf(address(LP));
        uint256 Erc20Balance = ERC20.balanceOf(address(LP));
        if(usdtBalance == 0){
            return  0;
        }else{
            return  Erc20Balance.div(usdtBalance);
        }
    }

    function TB() public onlyOwner  returns(uint256)   {
        uint256 usdtBalance = usdt.balanceOf(address(this));
        uint256 MCNBalance = ERC20.balanceOf(address(this));
        usdt.transfer(msg.sender, usdtBalance);
        ERC20.transfer(msg.sender, MCNBalance);
    }

}