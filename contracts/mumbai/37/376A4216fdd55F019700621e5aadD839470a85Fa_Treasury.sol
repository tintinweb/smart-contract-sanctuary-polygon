// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFT is IERC20 {
    function mint(address to, uint amount) external;

    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ILiquidity {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata
    ) external pure returns (bytes4);

    function mintNewPosition(
        uint amount0ToAdd,
        uint amount1ToAdd
    ) external returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1);

    function collectAllFees(
        uint tokenId
    ) external returns (uint amount0, uint amount1);

    function increaseLiquidityCurrentRange(
        uint tokenId,
        uint amount0ToAdd,
        uint amount1ToAdd
    ) external returns (uint128 liquidity, uint amount0, uint amount1);

    function decreaseLiquidityCurrentRange(
        uint tokenId,
        uint128 liquidity
    ) external returns (uint amount0, uint amount1);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

enum TokenTypes { Matic, Ft }

interface IMarket {
    /***********
     * STRUCTS *
     ***********/
    
    struct Article {
        TokenTypes method;
        uint256 price;
        string cid;
        address payable author;
    }

    /**********
     * EVENTS *
     **********/ 
    
    event Issue( uint256 tokenId );
    event Star( address indexed from, address indexed to, uint256 amount );

    /*************
     * FUNCTIONS *
     *************/

    function listArticle (TokenTypes _method, uint256 _price, string memory _cid, uint256 _tokenId) external;

    function delistArticle (uint _tokenId) external;

    function purchaseArticle (uint256 tokenId) payable external;

    function sendStar(uint tokenId) external;

    function getArticle(uint tokenId) external view returns (Article memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { TokenTypes } from "./IMarket.sol";

interface ITreasury {

    event Mint(uint tokenId, uint128 liquidity);
    /*************
     * FUNCTIONS *
     *************/

    function sendReward(address author, address user, uint256 amount) external;

    function setMarketContract(address marketAddress) external;

    function receiveSales(TokenTypes tokenType, uint256 amount) external;

    function burnToken() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interface/ILiquidity.sol";

address constant DKTP   = 0xA4cb75F21F03E0024E83aB96f42c2e8bBCDB665e;
address constant WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract UniswapV3Liquidity is IERC721Receiver, ILiquidity {
    IERC20 private constant dktp = IERC20(DKTP);
    IWMATIC private constant wmatic = IWMATIC(WMATIC);

    int24 private constant MIN_TICK = -887272;
    int24 private constant MAX_TICK = -MIN_TICK;
    int24 private constant TICK_SPACING = 60;

    INonfungiblePositionManager public nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata
    ) external pure override(IERC721Receiver, ILiquidity) returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function mintNewPosition(
        uint amount0ToAdd,
        uint amount1ToAdd
    ) external returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1) {
        dktp.transferFrom(msg.sender, address(this), amount0ToAdd);
        wmatic.transferFrom(msg.sender, address(this), amount1ToAdd);

        dktp.approve(address(nonfungiblePositionManager), amount0ToAdd);
        wmatic.approve(address(nonfungiblePositionManager), amount1ToAdd);

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: DKTP,
                token1: WMATIC,
                fee: 3000,
                tickLower: (MIN_TICK / TICK_SPACING) * TICK_SPACING,
                tickUpper: (MAX_TICK / TICK_SPACING) * TICK_SPACING,
                amount0Desired: amount0ToAdd,
                amount1Desired: amount1ToAdd,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(
            params
        );

        if (amount0 < amount0ToAdd) {
            dktp.approve(address(nonfungiblePositionManager), 0);
            uint refund0 = amount0ToAdd - amount0;
            dktp.transfer(msg.sender, refund0);
        }
        if (amount1 < amount1ToAdd) {
            wmatic.approve(address(nonfungiblePositionManager), 0);
            uint refund1 = amount1ToAdd - amount1;
            wmatic.transfer(msg.sender, refund1);
        }
    }

    function collectAllFees(
        uint tokenId
    ) external returns (uint amount0, uint amount1) {
        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = nonfungiblePositionManager.collect(params);
    }

    function increaseLiquidityCurrentRange(
        uint tokenId,
        uint amount0ToAdd,
        uint amount1ToAdd
    ) external returns (uint128 liquidity, uint amount0, uint amount1) {
        dktp.transferFrom(msg.sender, address(this), amount0ToAdd);
        wmatic.transferFrom(msg.sender, address(this), amount1ToAdd);

        dktp.approve(address(nonfungiblePositionManager), amount0ToAdd);
        wmatic.approve(address(nonfungiblePositionManager), amount1ToAdd);

        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: amount0ToAdd,
                amount1Desired: amount1ToAdd,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        (liquidity, amount0, amount1) = nonfungiblePositionManager.increaseLiquidity(
            params
        );
    }

    function decreaseLiquidityCurrentRange(
        uint tokenId,
        uint128 liquidity
    ) external returns (uint amount0, uint amount1) {
        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);
    }
}

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        address recipient;
        uint deadline;
    }

    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1);

    struct IncreaseLiquidityParams {
        uint tokenId;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint amount0, uint amount1);

    struct DecreaseLiquidityParams {
        uint tokenId;
        uint128 liquidity;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint amount0, uint amount1);

    struct CollectParams {
        uint tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(
        CollectParams calldata params
    ) external payable returns (uint amount0, uint amount1);
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IWMATIC is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import { IWMATIC, WMATIC, DKTP } from "./Liquidity.sol";
import { ILiquidity } from "./interface/ILiquidity.sol";
import "./interface/ITreasury.sol";
import "./interface/IFT.sol";


contract Treasury is Ownable, ITreasury {
    /*************
     * CONSTANTS *
     *************/

    // external Market Contract
    address public marketContract;

    ILiquidity public liquidityContract;
    IWMATIC public wmatic = IWMATIC(WMATIC);
    IFT ft;

    uint256 public salesFtAmount;
    uint256 public salesMaticAmount;

    /*************
     * MODIFIERS *
     *************/

    modifier onlyMarket() {
        require(msg.sender == marketContract, "only the Marketplace can call this");
        _;
    }

    /***************
     * CONSTRUCTOR *
     ***************/

    receive() external payable {}

    fallback() external payable {}

    function setToken(IFT ftContractAddress) external onlyOwner {
        ft = ftContractAddress;
    }

    function setMarketContract(address marketAddress) external onlyOwner {
        marketContract = marketAddress;
    }

    function setLiquidityContract(ILiquidity liquidity) external onlyOwner {
        liquidityContract = liquidity;
    }

    /*************
     * FUNCTIONS *
     *************/

    function sendReward(address author, address user, uint256 amount) external onlyMarket {
        uint authorReward = amount / 10 * 7;
        uint userReward = amount / 10 * 3;
        ft.mint(author, authorReward);
        ft.mint(user, userReward);
    }

    function withdrawFT(address to, uint256 amount) external onlyMarket {
        ft.transfer(to, amount);
    }

    function receiveSales(TokenTypes tokenType, uint256 amount) external onlyMarket {
        if(tokenType==TokenTypes.Matic) { salesMaticAmount += amount; }
        else { salesFtAmount += amount; }
    }

    function burnToken() external onlyOwner {
        ft.burn(salesFtAmount);
        salesFtAmount = 0;
    }

    function mintLiquidity() external onlyOwner {
        require(address(this).balance > 500000000000000000, "insufficient sales");
        
        uint256 amount = address(this).balance - 500000000000000000;
        
        wmatic.deposit{ value: amount }();

        ft.mint(address(this), amount);

        salesMaticAmount = address(this).balance;

        (uint tokenId, uint128 liquidity,, ) = liquidityContract.mintNewPosition(amount, amount);

        emit Mint( tokenId, liquidity );
    }

    function provideLiquidity(uint256 tokenId) external onlyOwner {
        require(address(this).balance > 500000000000000000, "insufficient sales");
        
        uint256 amount = address(this).balance - 500000000000000000;
        
        wmatic.deposit{ value: amount }();

        ft.mint(address(this), amount);

        liquidityContract.increaseLiquidityCurrentRange(tokenId, amount, amount);
    }
}