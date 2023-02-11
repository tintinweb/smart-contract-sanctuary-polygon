/**
 *Submitted for verification at polygonscan.com on 2023-02-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

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

contract SmartFeeder is Ownable {

    address internal USDT_ADDRESS;
    address public WETH_ADDRESS;
    address public bridgeContractAddress;
    address public SwapRouter02Address;
    uint256 internal _id;
    // SwapRouter02
    ISwapRouter router;
    IDexilonBridge bridgeContract;

    event ETHDistribution(
        address[] validators,
        uint256[] ethAmounts
    );
    

    constructor(address _bridgeContractAddress) {
        bridgeContractAddress = _bridgeContractAddress;
        bridgeContract = IDexilonBridge(bridgeContractAddress);
        USDT_ADDRESS = 0x8F54629e7D660871ABAb8a6B4809A839dEd396dE;
        WETH_ADDRESS = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
        SwapRouter02Address = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
        router = ISwapRouter(SwapRouter02Address);
        IERC20(USDT_ADDRESS).approve(SwapRouter02Address, type(uint256).max);
    }
    

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function setWeth(address new_weth_address) external onlyOwner {
        WETH_ADDRESS = new_weth_address;
    }

    function setBridge(address _bridgeContractAddress) external onlyOwner {
        bridgeContractAddress = _bridgeContractAddress;
        bridgeContract = IDexilonBridge(bridgeContractAddress);
    }

    function setRouter(address _SwapRouter02Address) external onlyOwner {
        SwapRouter02Address = _SwapRouter02Address;
        router = ISwapRouter(SwapRouter02Address);
    }

    function initiateDistribution(uint256 id, address tokenAddress, uint24 poolFee, address[] calldata validators, uint256[] calldata parts) external onlyOwner 
        returns (uint256[] memory) {
        
        // id of this distribution must be higher than saved previous id
        require(id > _id, "id too low");

        uint256 summ_parts;
        uint256 summ_given;
        address[] memory activeValidators;
        uint256[] memory eth_given = new uint256[](parts.length);
        // Just checking length
        require(validators.length == parts.length, "Arrays do not match");
        // Checking summ of parts and validators
        activeValidators = bridgeContract.getActiveValidators();
        for (uint i; i < parts.length; i++) { 
            summ_parts += parts[i];
            require(isAddressInArray(validators[i], activeValidators), "Not an active validator");
            }
        require(summ_parts == 100_000000, "Parts not 100_000000");

        // Check allowance for the token
        if (IERC20(tokenAddress).allowance(address(this), SwapRouter02Address) == 0) {
            IERC20(tokenAddress).approve(SwapRouter02Address, type(uint256).max);
        }

        // Claiming USDT from the Bridge
        bridgeContract.withdraw(tokenAddress);
        // Swapping all USDT to WETH
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenAddress,
                tokenOut: WETH_ADDRESS,
                fee: poolFee,
                recipient: address(this),
                amountIn: IERC20(tokenAddress).balanceOf(address(this)),
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        router.exactInputSingle(params);
        // Unwrapping all WETH to ETH
        IWETH(WETH_ADDRESS).withdraw(IWETH(WETH_ADDRESS).balanceOf(address(this)));
        // Splitting all the ETH
        for (uint i; i < parts.length; i++) {
            eth_given[i] = address(this).balance * parts[i] / 100_000000;
            summ_given += eth_given[i];
        }
        eth_given[parts.length - 1] += address(this).balance - summ_given;
        // Sending all ETH to validators in parameters
        for (uint i; i < validators.length; i++) { 
            (bool sent, ) = payable(validators[i]).call{ value: eth_given[i] }("");
            require(sent, "Failed to send Ether");
            // payable(validators[i]).transfer(eth_given[i]);
            }
        
        // saving new id
        _id = id;
        
        emit ETHDistribution(validators, eth_given);

        return eth_given;
    }

    function isAddressInArray(address _address, address[] memory _array) internal pure returns (bool) {
        uint256 arrayLength;
        arrayLength = _array.length;
        for (uint256 i; i < arrayLength; ) {
            if (_address == _array[i]) {
                return true;
            }
            unchecked { ++i; }
        }
        return false;
    }

    function recoverToken(address tokenAddress) external onlyOwner {
        uint256 tokenBalance;
        tokenBalance = IERC20(tokenAddress).balanceOf(address(this));
        require(tokenBalance > 0, "Zero token balance");
        IERC20(tokenAddress).transfer(msg.sender, tokenBalance);
    }

    function recoverEth() external onlyOwner {
        (bool sent, ) = payable(msg.sender).call{ value: address(this).balance }("");
        require(sent, "Failed to send Ether");
    }

}



interface IDexilonBridge {
    function withdraw(address _tokenAddress) external;
    function getActiveValidators() external view returns (address[] memory);
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint amountIn;
        uint amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint amountOut);

    function WETH9() external returns (address);
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

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint amount) external;
}