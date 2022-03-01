/**
 *Submitted for verification at polygonscan.com on 2022-02-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
}

contract MultiSender
{
    
    uint256 public platfromFees;
    address devWallet;
    address owner;

    event TransferBatch(address from,address[] to,uint256[] amounts);
    
    constructor(
        uint256 _platformFees,
        address _devAddress,
        address _owner
    )
    {
       platfromFees =_platformFees;
       devWallet = _devAddress;
       owner = _owner;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function setPlatformFees(
        uint256 _fees
    ) external onlyOwner
    {
       platfromFees = _fees;
    }
    
    function setDevWallet(
        address _devAddress
    ) external onlyOwner
    {
       devWallet = _devAddress;
    }

    function transferOwnership(
        address _owner
    ) external onlyOwner
    {
       owner = _owner;
    }

    function withdrawBNB(
        uint256 _amount
    ) external onlyOwner
    {
       (bool success,) = devWallet.call{value:_amount}("");
       require(success,"refund failed"); 
    }

    function batchTokenTransfer(
        address _from,
        address[] memory _address,
        uint256[] memory _amounts,
        address token,
        uint256 totalAmount,
        bool isToken
    ) external payable
    {
        require(_address.length == _amounts.length, "address and amounts length mismatch");
        require(msg.value>=platfromFees,"send bnb for fees");
    
        transferBNB(platfromFees);

        if(isToken)
        {
            tokenTransfer(_from,_address,_amounts,token,totalAmount);
        }
        else
        { 
            require(msg.value>=totalAmount,"require more bnb");  
            bnbTransfer(_address,_amounts);
        }   

        emit TransferBatch(_from,_address,_amounts);
    }
      
    function tokenTransfer(
        address _from,
        address[] memory _address,
        uint256[] memory _amounts,
        address token,
        uint256 totalAmount
    ) internal
    {
        require(IERC20(token).allowance(msg.sender,address(this)) >= totalAmount,"allowance is not sufficient");
        
        IERC20(token).transferFrom(_from,address(this),totalAmount);
        
        for (uint256 i = 0; i < _address.length; ++i) {

            IERC20(token).transfer(_address[i],_amounts[i]); 

        }
        
    }
    
    function bnbTransfer(
        address[] memory _address,
        uint256[] memory _amounts
    ) internal
    {
        for (uint256 i = 0; i < _address.length; ++i) {

          (bool success,) = _address[i].call{value:_amounts[i]}("");
          require(success,"refund failed");  
  
        }
    }

    function transferBNB(
        uint256 _amount
    ) internal
    {
        (bool success,) = devWallet.call{value:_amount}("");
        require(success,"refund failed"); 
    }
    
    function get() public pure returns(address)
    {
        return address(0);
    }


}