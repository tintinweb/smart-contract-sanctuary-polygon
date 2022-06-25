/**
 *Submitted for verification at polygonscan.com on 2022-06-24
*/

// SPDX-License-Identifier: MIT
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

// File: contracts/LotteryChain/LotteryChainBalance.sol


pragma solidity >= 0.7.0 < 0.9.0;



interface EvolveCoinTokenInterface {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);   
}


interface EvolveCoinLiquidityInterface {
    function transferForLiquidity() external payable;
}


contract LotteryChainBalance is Ownable{

    // ##### Variables #####
    address public evolveCoinTokenAddress = 0x8CfE14E2C4060C4C560ba3A07dA110b71EB7Ef01;
    EvolveCoinTokenInterface evolveCoinTokenInstance = EvolveCoinTokenInterface(evolveCoinTokenAddress);

    address public evolveCoinLiquidityAddress = 0x6b9B3810ab2A1d2494F02eb79587A3052a5024b2;
    EvolveCoinLiquidityInterface evolveCoinLiquidityInstance = EvolveCoinLiquidityInterface(evolveCoinLiquidityAddress);

    mapping(address => bool) public approvedContracts;

    address [] public creatorsAddresses = [
        0xBAb15eBE906A5a52cA50Fa03bFCD1397C6c40072,
        0x874767A2d01A986b811d9aa77F8A3cD70F6966cE
        ];

    uint256 public evoTokensToClaim = 1;
    uint256 public decimalsEvoTokensToClaim = 18;
    // ######


    // ##### Functions #####
    function claimTokensForWinners(address [] memory winnersAddresses, uint256 percentageForEvolveLiquidity) external {
        require(approvedContracts[msg.sender]);

        uint256 amountToClaim = evoTokensToClaim * 10 ** decimalsEvoTokensToClaim;

        for (uint256 i = 0; i<winnersAddresses.length; i++) {
            evolveCoinTokenInstance.transferFrom(address(this), winnersAddresses[i], amountToClaim);
        }

        //transferForEvoLiquidity(percentageForEvolveLiquidity);

    }

    function transferForEvoLiquidity (uint256 _percentageForEvolveLiquidity) internal {
        evolveCoinLiquidityInstance.transferForLiquidity{value: _percentageForEvolveLiquidity}();
    }


    // ##### SETTINGS FUNCTIONS #####
    function setEvoTokensPrices (uint256 _evoTokensToClaim, uint256 _decimalsEvoTokensToClaim) public onlyOwner {
        evoTokensToClaim = _evoTokensToClaim;
        decimalsEvoTokensToClaim = _decimalsEvoTokensToClaim;
    }

    function swapLiquidityContract (address _newLiquidityAddress) public onlyOwner {
        evolveCoinLiquidityAddress = _newLiquidityAddress;
        evolveCoinLiquidityInstance = EvolveCoinLiquidityInterface(evolveCoinLiquidityAddress);
    }

    function setAddresses (address [] memory _addresses) public onlyOwner {
        creatorsAddresses = _addresses;
    }

    function approveContract(address _newAddress) public onlyOwner {
        require (!approvedContracts[_newAddress]);
        approvedContracts[_newAddress] = true;
    }

    function disapproveContract(address _oldAddress) public onlyOwner {
        require (approvedContracts[_oldAddress]);
        delete approvedContracts[_oldAddress];
    }
    // ######


    // ###### Finance Functions ######
    function transferBalance() public payable {}


    function withdraw () public onlyOwner {
        for (uint256 i = 0; i < creatorsAddresses.length; i++){
            payable(creatorsAddresses[i]).transfer(address(this).balance / creatorsAddresses.length);
        }
    }
    // #####


}