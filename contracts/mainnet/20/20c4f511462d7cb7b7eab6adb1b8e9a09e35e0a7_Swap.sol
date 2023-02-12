/**
 *Submitted for verification at polygonscan.com on 2023-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


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

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint);

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
    function approve(address spender, uint amount) external returns (bool);

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
        uint amount
    ) external returns (bool);
}

interface DescStuct {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }
}

interface IAggregationExecutor {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function execute(address msgSender) external payable;  // 0x4b64e492
}

interface IGenericRouter is DescStuct {
    function swap(
        IAggregationExecutor executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    )
        external
        payable
        returns (
            uint256 returnAmount,
            uint256 spentAmount
        );

    function _execute(
        IAggregationExecutor executor,
        address srcTokenOwner,
        uint256 inputAmount,
        bytes calldata data
    ) 
        external;
}

contract Swap is DescStuct, Ownable {
    struct Investor {
        address ownerAddress;
        uint USDC_amount;
        uint WMATIC_amount;
        uint WBTC_amount;
        uint WETH_amount;
        uint LINK_amount;
        uint UNI_amount;
    }

    mapping(uint => Investor) investors;

    IGenericRouter ROUTER;

    IERC20 USDC = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F); // USDT
    IERC20 WMATIC = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270); 

    constructor(address _router){
        ROUTER = IGenericRouter(_router);
    }

    function unitSwap(  uint _tokenId,
                        uint fee,
                        IAggregationExecutor executor,
                        SwapDescription calldata desc,
                        bytes calldata permit,
                        bytes calldata data ) public 
                                              payable
                                              onlyOwner{


        // -----------------SWAP----------------------------------//
        (uint256 returnAmount, uint256 spentAmount) = ROUTER.swap(executor, desc, permit, data);              
        // -------------------------------------------------------//

        
        // -----------------COMMISION-----------------------------//
        uint remainingAmount = _calculateCommision(returnAmount, fee);
        // -------------------------------------------------------//


        // -----------------UPDATE METADATA-----------------------//
        _updateMetadata(_tokenId, address(desc.srcToken), address(desc.dstToken), remainingAmount, spentAmount);
        // -------------------------------------------------------//

    }


    function _calculateCommision(uint amount, uint fee) internal pure returns(uint){

        require(fee <= 3, "You're too zhadnyy");
        uint feeAmount = amount * (fee / 100);
        uint remainingAmount =  amount - feeAmount;
        return remainingAmount;
    }


    function _updateMetadata(uint _tokenId, address srcToken, address dstToken, uint returnAmount, uint spentAmount) internal {
        
        address tokenFrom = address(srcToken);
        address tokenTo = address(dstToken);

        // tokenFrom

        if (tokenFrom == address(USDC)){
            investors[_tokenId].USDC_amount -= spentAmount;

        } else if (tokenFrom == address(WMATIC)) {
            investors[_tokenId].WMATIC_amount -= spentAmount;
        }


        // tokenTo

        if (tokenTo == address(USDC)){
            investors[_tokenId].USDC_amount += returnAmount;

        } else if (tokenFrom == address(WMATIC)) {
            investors[_tokenId].WMATIC_amount += returnAmount;
        }
    }

    function approveAllTokens() external onlyOwner {
        WMATIC.approve(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }
}