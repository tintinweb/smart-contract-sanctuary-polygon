/**
 *Submitted for verification at polygonscan.com on 2022-05-19
*/

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


// File contracts/Test.sol

pragma solidity ^0.8.0;

interface IOracle {
    function latestAnswer() external view returns(uint256);
}

 interface UniswapV2Router02 {
     function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

 interface ERC20 {
     function transfer(address to, uint value) external returns (bool);
     function balanceOf(address owner) external view returns (uint);
}

contract Test is Ownable {

    //slipagge porcentual se divide por 1000, 1 decimal, el 100% es 1000
    uint256 public slippagePorcentual = 5; //0,5%
    //oracle address
    address public constant oracleAddress = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant MATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    IOracle private _oracle;
    UniswapV2Router02 private _router;

    constructor() {
        _oracle = IOracle(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
        _router = UniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    }

    function buyTokens () payable external{
        require(msg.value > 0, "Cannot send 0 wei");
        uint256 weiAmount = msg.value;
        uint256 maticToUsdPrice =  _oracle.latestAnswer() *10**10;
        uint256 usdcAmount =  (maticToUsdPrice * 10**18 /weiAmount) / 10**12;
        //modificar para que slipagge sea variable
        uint256 amountOutMin = usdcAmount - usdcAmount * slippagePorcentual/1000;
        address[] memory path = new address[](2);
        path[1] = USDC;
        path[0] = MATIC;
        _router.swapExactETHForTokens{value:weiAmount}(amountOutMin,path, address(this), block.timestamp);
        bool success = ERC20(USDC).transfer(owner(),ERC20(USDC).balanceOf(address(this)));
        require(success, "Forward funds fail");
    }

    function setSlippage(uint256 newSlippage) external onlyOwner {
        slippagePorcentual = newSlippage;
    }
}