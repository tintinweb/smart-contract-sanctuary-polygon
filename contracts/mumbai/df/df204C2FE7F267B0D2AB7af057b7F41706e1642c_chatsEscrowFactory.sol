// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "./chatsEscrow.sol";

contract chatsEscrowFactory {
    address owner;
    ///@custom:oz-upgrades-unsafe-allow constructor
    constructor() public {
        owner = msg.sender;
    }

    chatsEscrow[] public escrows; //an array that contains different ERC1155 tokens deployed
    mapping(uint256 => address) public indexToEscrow; //index to contract address mapping
    mapping(uint256 => string) public indexToEscrowName;
    event EscrowCreated(uint256 index, address escrowContract); //emitted when ERC1155 token is deployed

    // Deploy an instance of CHATS NFT collection
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    function deployEscrow
    (
        address _erc20TokenAddress,
        address _uniswapRouterAddress,
        address _wmaticContractAddress,
        string memory _campaignName
    ) external onlyOwner returns (address) {
        chatsEscrow t = new chatsEscrow(
        _erc20TokenAddress,
        _uniswapRouterAddress,
        _wmaticContractAddress,
        _campaignName
        );
        escrows.push(t);
        indexToEscrow[escrows.length - 1] = address(t);
        indexToEscrowName[escrows.length - 1] = _campaignName;        
        emit EscrowCreated(escrows.length-1,address(t));
        return address(t);
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IuniswapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

interface IquickswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IWMATIC {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address) external returns(uint);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract chatsEscrow  is Ownable {
    IuniswapRouter uniswapRouter;
    IWMATIC wmatic;
    IquickswapRouter quickswapRouter;
    
    address uniswapRouterAddress;
    address wmaticContractAddress;
    address campaignWalletAddress;
    address quickswapRouterAddress;

    mapping (address => uint256) public funder;
    mapping (address => bool)public fundAvailability;
    mapping (address => bool) public isFunder;
    mapping (address => bool) public withdrawalApproval;

    mapping (string => address) public stableCoins;
    mapping (string => address) public  erc20Tokens;

    uint256 public fundersCount;
    uint256 public stableCoinsCount;
    uint256 public erc20TokenCount;

    bool adminSignature = false;
    bool campaignStatus = true;

    string campaignName;

    string defaultStableCoin = "USDC";
///@custom:oz-upgrades-unsafe-allow constructor
    constructor (
        address _uniswapRouterAddress,
        address _wmaticContractAddress,
        address _quickswapRouter,
        string memory _campaignName
    ){
        uniswapRouterAddress = _uniswapRouterAddress;
        uniswapRouter = IuniswapRouter(_uniswapRouterAddress);
        wmatic = IWMATIC(_wmaticContractAddress);
        wmaticContractAddress = _wmaticContractAddress;
        campaignName = _campaignName;
        quickswapRouter = IquickswapRouter(_quickswapRouter);
        quickswapRouterAddress = _quickswapRouter;
    }

    modifier activeCampaign {
        require (campaignStatus == true, "Campaign is no longer active or has been suspended");
        _;
    }

    function adminSignatory (address withdrawer) public virtual onlyOwner returns (bool) {
        withdrawalApproval[withdrawer] = true;
        adminSignature = true;
        return true;
    }

    function endCampaign() public virtual onlyOwner returns(bool) {
        campaignStatus =false;
        return true;
    }

    function resumeCampaign () public virtual onlyOwner returns(bool) {
        campaignStatus = true;
        return true;
    }

    function updateStableCoin (address _coinAddress, string memory _symbol) public virtual onlyOwner returns (bool){
        stableCoins[_symbol] = _coinAddress;
        return true;
    }

        function updateErc20Token (address _tokenAddress, string memory _symbol) public virtual onlyOwner returns (bool){
        erc20Tokens[_symbol] = _tokenAddress;
        return true;
    }


    function fundCampaignStableCoin (string memory coinSymbol, uint256  _amount) public virtual activeCampaign returns (bool) {
        require (_amount > 0, "You cannot transfer zero amount");
        address coinAddress = stableCoins[coinSymbol];
        IERC20Metadata stableCoin =  IERC20Metadata(coinAddress);
        stableCoin.transferFrom(msg.sender, address(this),_amount);
        funder[msg.sender] = _amount + funder[msg.sender];
        fundAvailability[msg.sender] =  true;
        isFunder[msg.sender] = true;
        withdrawalApproval[msg.sender] = false;
        return true;
    }

    function fundCampaignMatic () public payable virtual activeCampaign returns (bool) {
        uint256 amount = msg.value;
        require (amount > 0, "You cannot transfer zero amount");
      
        address stableCoinAddress = stableCoins[defaultStableCoin];
        IuniswapRouter.ExactInputSingleParams memory params = IuniswapRouter
            .ExactInputSingleParams({
                tokenIn: wmaticContractAddress,
                tokenOut: stableCoinAddress,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp + 300,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        uint256 swappedUSDT = uniswapRouter.exactInputSingle{value:amount}(params);
        funder[msg.sender] = swappedUSDT + funder[msg.sender];
        fundAvailability[msg.sender] =  true;
        isFunder[msg.sender] = true;
        withdrawalApproval[msg.sender] = false;
        return true;
    }

        function fundCampaignErc20Token (string memory coinSymbol, uint256  _amount) public virtual activeCampaign returns (bool) {
        require (_amount > 0, "You cannot transfer zero amount");
        address erc20TokenAddress = erc20Tokens[coinSymbol];
        address stableCoinAddress = stableCoins[defaultStableCoin];
        IERC20Metadata erc20Token =  IERC20Metadata(erc20TokenAddress);
        erc20Token.transferFrom(msg.sender, address(this),_amount);
        uint256 deadline = block.timestamp +300;
        address[] memory path1 = new address[](2);
        path1[0] = erc20TokenAddress;
        path1[1] = stableCoinAddress;
        erc20Token.approve(quickswapRouterAddress, _amount);
        uint256[] memory swappedUSDC = quickswapRouter.swapExactTokensForTokens(
            _amount,
            0,
            path1,
            address(this),
            deadline
        );
        funder[msg.sender] = swappedUSDC[1] + funder[msg.sender];
        fundAvailability[msg.sender] =  true;
        isFunder[msg.sender] = true;
        withdrawalApproval[msg.sender] = false;
        return true;
    }

    function adminWithdrawFunds (uint256 _amount, address _offRampAddress, string memory symbol) public virtual onlyOwner returns(bool) {
        require (_amount > 0, "You cannot withdraw zero amount");
        address USDT = stableCoins[symbol];
        IERC20Metadata stableCoin = IERC20Metadata(USDT);
        require(stableCoin.balanceOf(address(this)) > _amount, "Amount requested exceeds token balance");
        stableCoin.transfer(_offRampAddress, _amount);
        return true;
    }

    function withdrawFunds (uint256 _amount, string memory symbol) public virtual returns (bool) {
        require(withdrawalApproval[msg.sender] == true, "You have not been approved to withdraw");
        require (_amount > 0, "You cannot withdraw zero amount");
        uint256 funderBalance = funder[msg.sender];
        require (funderBalance > 0, "You have no funds to withdraw");
        require (fundAvailability[msg.sender] == true, "You have no funds to withdraw");
        require (_amount <= funderBalance, "Amount requested is more than your balance");
        funder[msg.sender] = funderBalance - _amount;
        uint256 remainingBalance = funder[msg.sender];
        address USDT = stableCoins[symbol];
        IERC20Metadata stableCoin = IERC20Metadata(USDT);
        require(stableCoin.balanceOf(address(this)) > _amount, "Amount requested exceeds token balance");
        stableCoin.transfer(msg.sender, _amount);
        if (remainingBalance == 0){
            fundAvailability[msg.sender] = false;
            withdrawalApproval[msg.sender] = false;
            return true;
        }
        else {
            withdrawalApproval[msg.sender] = false;
            return true;
        }
    }

    function getFundAmount (address _funder) public view returns (uint256) {
        return funder[_funder];
    }

    function getFundAvailability (address _funder) public view returns (bool) {
        return fundAvailability[_funder];
    }

    function funderAvailable (address _funder) public view returns (bool) {
        return isFunder[_funder];
    }

    function WithdrawalApprovalStatus (address _funder) public view returns (bool) {
        return withdrawalApproval[_funder];
    }

    function getAdminSignature () public view returns(bool) {
        return adminSignature;
    }

    function getCampaignStatus () public view returns (bool) {
        return campaignStatus;
    }

    function getTokenBalance (string memory symbol) public view returns(uint256) {
        address USDT = stableCoins[symbol];
         IERC20Metadata stableCoin = IERC20Metadata(USDT);
        return stableCoin.balanceOf(address(this));
    }

}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
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