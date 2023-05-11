/**
 *Submitted for verification at polygonscan.com on 2023-05-11
*/

/**
 *Submitted for verification at polygonscan.com on 2023-05-02
*/

// SPDX-License-Identifier: None

pragma solidity 0.8.18;

contract Ownership {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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
        emit OwnershipTransferred(oldOwner,  newOwner);
    }
}
interface CubixPackSell {
    struct userInfo
    {        
        uint256 uID;
        address referrer;
        address placement;
        uint position;
        uint256 depositAmt;
        uint256 depositUSDAmt;
        uint256 directusers;
        uint256 teamCount;
        uint joiningpkg;
        uint256 pairs;      
        uint createTime;  
    }

    function UserInfo(address _address) external returns (userInfo memory);
    function feeAddress() external returns(address);
    function cubixToken() external returns(address);
    

}
interface IERC20 {

    function decimals() external view returns (uint256);
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
contract CubixIncomeWithdraw is Ownership {
    CubixPackSell public cubixPackSellV1;
    IERC20 public cubixToken;
    uint256 public totalClaimed;
    mapping (address => uint256) public claimedAmount;
    bool public safeguard;  //putting safeguard on will halt all non-owner functions
    mapping (address => bool) public frozenAccount;
    event FrozenAccounts(address target, bool frozen); 
    event userClaimReq(address indexed _user, uint256 _amount, address _refAddress, uint pkgIndex);
    event IncomeClaimed(address indexed _user, uint256 _amount, address _refAddress, uint pkgIndex);
    constructor(address _cubixPackSellV1){                    
        cubixPackSellV1 = CubixPackSell(_cubixPackSellV1);
        cubixToken = IERC20(CubixPackSell(_cubixPackSellV1).cubixToken());          
    }
    function showContractTokenBalance() public view returns(uint256)
    {
        return cubixToken.balanceOf(address(this));
    }
    function setCubixPackSell(address _cubixPackSellV1) external onlyOwner {
        cubixPackSellV1 = CubixPackSell(_cubixPackSellV1); 
        cubixToken = IERC20(CubixPackSell(_cubixPackSellV1).cubixToken());         
    }
   function freezeAccount(address target, bool freeze) external onlyOwner {
        frozenAccount[target] = freeze;
        emit  FrozenAccounts(target, freeze);
    }
    function changeSafeguardStatus() external onlyOwner {
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;
        }
    }
    function withdrawCubixTokens(uint256 amount) external onlyOwner {
        require(cubixToken.balanceOf(address(this)) > amount, "Insufficient tokens") ;
        cubixToken.transfer(owner(), amount);
    }
    function claim(uint256 _amt) external{
        require(!safeguard);
        require(!frozenAccount[msg.sender], "caller has been frozen");
        require(cubixPackSellV1.UserInfo(msg.sender).referrer != address(0), "Invalid user");
        claimedAmount[msg.sender] = _amt;
        totalClaimed += _amt;
        emit userClaimReq(msg.sender, _amt, cubixPackSellV1.UserInfo(msg.sender).referrer, cubixPackSellV1.UserInfo(msg.sender).joiningpkg);        
    }
    function approveWithdrawal(address[] memory users, uint256[] memory _amount) external onlyOwner {    
        require(!safeguard);
        require(users.length <= 30, "Not more than 30 users");
        for (uint256 index = 0; index < users.length; index++) 
        {
            if(cubixPackSellV1.UserInfo(users[index]).referrer != address(0))
            {
                if(claimedAmount[users[index]] >= _amount[index]){
                    claimedAmount[users[index]] = 0;
                    cubixToken.transfer(users[index], _amount[index]);
                    if(totalClaimed > _amount[index]){
                        totalClaimed -= _amount[index];
                    }
                    emit IncomeClaimed(users[index], _amount[index], cubixPackSellV1.UserInfo(users[index]).referrer, cubixPackSellV1.UserInfo(users[index]).joiningpkg);
                }
            }
        }
    }
}