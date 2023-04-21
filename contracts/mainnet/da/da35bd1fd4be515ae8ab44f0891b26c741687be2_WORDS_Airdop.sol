/**
 *Submitted for verification at polygonscan.com on 2023-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IERC20 {

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

interface AirdropToken{
    function balanceOf(address account) external view returns (uint256);
}

contract WORDS_Airdop{

    IERC20 public tokenWORDS;
    address public owner;
    uint256 public amountAirdrop=200*10**18;
    uint256 public unlockTime = 120; // seconds

    struct Player {
        uint256 airdropDate;
        uint256 unlockDate;
        uint256 amountWORDS;
    }
    uint public mapSize=0;
    mapping(address => Player) public arrayPlayers;

    constructor(address token){
        owner = msg.sender;
        tokenWORDS = IERC20(token);
    }

    function getTotalPlayers() public view returns(uint){
        return mapSize;
    }

    modifier checkOwner(){
        require(msg.sender==owner, "You are not allowed.");
        _;
    }

    function airdropToken(address receiver) public checkOwner{
        require(tokenWORDS.balanceOf(address(this))>=amountAirdrop, "Not enought token to airdrop now");
        tokenWORDS.transfer(receiver, amountAirdrop);

        uint256 newAmount = arrayPlayers[receiver].amountWORDS + amountAirdrop;
        uint256 newUnlockTime = block.timestamp + unlockTime;

        Player memory newPlayer = Player(block.timestamp, newUnlockTime, newAmount);
        arrayPlayers[receiver]= newPlayer;
    }

    function getWalletInfo(address wallet) public view returns(uint256, uint256, uint256, bool){
        bool status = true;  // blocked
        if(block.timestamp>arrayPlayers[wallet].unlockDate){
            status = false; // unblocked
        }
        return(arrayPlayers[wallet].airdropDate, arrayPlayers[wallet].unlockDate, arrayPlayers[wallet].amountWORDS, status);
    }

    function updateUnlockTime(uint newLockTime) public checkOwner{
        unlockTime = newLockTime;
    }

    function updateTokenAddress(address newAddress) public checkOwner{
        tokenWORDS = IERC20(newAddress);
    }

    function withdraw_BNB() public checkOwner{
        require(address(this).balance>0, "Do not have bnb");
        payable(owner).transfer(address(this).balance);
    }

    function withdraw_WORDS() public checkOwner{
        require(tokenWORDS.balanceOf(address(this))>0, "Do not have WORDS");
        tokenWORDS.transfer(owner, tokenWORDS.balanceOf(address(this)));
    }

}