/**
 *Submitted for verification at polygonscan.com on 2022-04-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor ()  {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        _status = _NOT_ENTERED;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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


contract IERC20 {

    function balanceOf(address account) external view returns (uint256){}

    function transfer(address recipient, uint256 amount) external returns (bool){}

}


contract FlashExchange is Ownable{
    using SafeMath for uint256;

    IERC20 public contractToken;

    uint256 public molecular;
    uint256 public denominator;
    uint256 public transferNum;

    mapping(address => bool) public isDeposit;

    event FlashExchangeMT(address indexed account,uint256 money,uint256 tokenMoney);
    event MaticWithdraw(address indexed from,address indexed to,uint256 money);
    event TokenWithdraw(address indexed from,address indexed to,uint256 money);
    event ContractToken(address indexed account,address indexed contractToken);
    event ExchangeRate(address indexed account,uint256 _molecular,uint256 _denominator);
    event TransferNum(address indexed account,uint256 _transferNum);

    constructor(address _contractToken){
        contractToken = IERC20(_contractToken);
    }

	receive() external payable {
		deposit();
	}

	function deposit() public payable nonReentrant{
        require(tx.origin == _msgSender(), "Cannot be called by external contract");
        require(transferNum > 0, "transferNum rate not set!!");
        require(molecular > 0, "exchange rate not set!!");
        require(denominator > 0, "exchange rate not set!!");
        require(msg.value >= transferNum, "Only 50matic can!!");
        require(!isDeposit[msg.sender], "It has been exchanged and cannot be exchanged!!");

        uint256 money = transferNum.mul(molecular).div(denominator);

        require(contractToken.balanceOf(address(this)) >= money,"Insufficient balance in token!");
        contractToken.transfer(msg.sender,money);
        
        isDeposit[msg.sender] = true;
        emit FlashExchangeMT(msg.sender,msg.value,money);// set log
    }

    function maticWithdraw(address to) public onlyOwner{
        require(payable(this).balance > 0,"Insufficient balance in matic!");
        payable(to).transfer(payable(this).balance);
        emit MaticWithdraw(msg.sender,to,payable(this).balance);
    }

    function tokenWithdraw(address to) public onlyOwner{
        require(contractToken.balanceOf(address(this)) > 0,"Insufficient balance in token!");
        contractToken.transfer(to,contractToken.balanceOf(address(this)));
        emit TokenWithdraw(msg.sender,to,contractToken.balanceOf(address(this)));
    }

    function setExchangeRate(uint256 _molecular, uint256 _denominator) public onlyOwner{
        molecular=_molecular;
        denominator=_denominator;
        emit ExchangeRate(msg.sender,_molecular,_denominator);
    }

    function setTransferNum(uint256 _transferNum) public onlyOwner{
        transferNum = _transferNum;
        emit TransferNum(msg.sender,_transferNum);
    }

}