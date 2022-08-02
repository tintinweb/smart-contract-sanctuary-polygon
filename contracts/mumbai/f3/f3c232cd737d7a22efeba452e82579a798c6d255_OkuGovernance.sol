/**
 *Submitted for verification at polygonscan.com on 2022-08-02
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: Oku_treasury.sol

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;


interface IERC165 {

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
    */

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165{

    function mint(address from,uint tokenId,uint96 fee)  external returns(uint256);

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function restaurantOwner()external view returns(address);

}

    contract OkuGovernance is Ownable{

        IERC20 public stableCoin;
        uint counter=1;

        struct userDetails{
           address investedRestaurant;
           uint tokenId;
           uint amount;
           bool isMatic;
        }

        //total Matic Received By restaurant
        mapping(address=>uint) public totalMaticFundsPerRestaurant;
        //total stableCoin Received by eachRestaurant
        mapping(address=>uint) public totalUSDTFundsPerRestaurant;
        //get users Details
        mapping(address=>userDetails[]) public InvestorsDetails;
        // total Matic funds invested in particular restaurant
        mapping(address=>mapping(address=>uint)) public getUsersTotalMaticInvestment;
        //total USDT funds invested per user
        mapping(address=>mapping(address=>uint)) public getUsersTotalUSDTInvestment;
        // restaurant Owner Requested amount in Matic
        mapping(address=>mapping(address=>uint)) public getRequestedFundsInMatic;
        // restaurant Owner Requested amount in USDT
        mapping(address=>mapping(address=>uint)) public getRequestedFundsInUSDT;

        event Minted(address from,uint tokenID, uint amount);


        function buyNFT(address _nftAddress, uint96 fee,uint amount, bool isMatic) external payable{
            uint price;
            userDetails memory investors;
            if(isMatic){
             totalMaticFundsPerRestaurant[_nftAddress]+=msg.value;
             price=msg.value;
             investors.isMatic=true;
             investors.amount=msg.value;
             getUsersTotalMaticInvestment[msg.sender][_nftAddress]+=msg.value;
            }
            else{
                totalUSDTFundsPerRestaurant[_nftAddress]+=amount;
                stableCoin.transferFrom(msg.sender, address(this),amount);
                price=amount;
                investors.isMatic=false;
                investors.amount=amount;
                getUsersTotalMaticInvestment[msg.sender][_nftAddress]+=amount;
            }
            uint tokenId= counter;
            investors.investedRestaurant=_nftAddress;
            investors.tokenId=tokenId;
           InvestorsDetails[msg.sender].push(investors);
            uint token_Id=IERC1155(_nftAddress).mint(msg.sender,tokenId,fee);
            counter++;
            emit Minted(msg.sender,token_Id,price); 
        }


        function requestFunds(address _restaurantAddress ,uint amount,bool isMatic) external{
            address restaurantOwner=IERC1155(_restaurantAddress).restaurantOwner();
            require(restaurantOwner==msg.sender,"!Restuarant Owner");
            if(isMatic){
        getRequestedFundsInMatic[msg.sender][_restaurantAddress]=amount;

        require(totalMaticFundsPerRestaurant[_restaurantAddress]>=amount,"not Enough Funds");
             }else{
            getRequestedFundsInUSDT[msg.sender][_restaurantAddress]=amount; 
            require(totalUSDTFundsPerRestaurant[_restaurantAddress]>=amount,"not Enough Funds");  }
        }

        function releaseFunds(address _restaurantAddress, address  restaurantOwnerAddress, bool isMatic) external onlyOwner{
                     uint _amount;
                    if(isMatic){
                        _amount=getRequestedFundsInMatic[restaurantOwnerAddress][_restaurantAddress];
                        payable(restaurantOwnerAddress).transfer(_amount);

                        totalMaticFundsPerRestaurant[_restaurantAddress]-=_amount;

                    }else{
                        _amount=getRequestedFundsInUSDT[restaurantOwnerAddress][_restaurantAddress];
                         stableCoin.transfer(restaurantOwnerAddress,_amount);
                         totalUSDTFundsPerRestaurant[_restaurantAddress]-=_amount;
                    }
        }
    }