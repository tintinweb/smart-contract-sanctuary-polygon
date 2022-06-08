/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

// File: xvmc-contracts/libs/standard/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: xvmc-contracts/helper/contractSync.sol



pragma solidity 0.8.0;


interface IXVMCgovernor {
    function acPool1() external view returns (address);
    function acPool2() external view returns (address);
    function acPool3() external view returns (address);
    function acPool4() external view returns (address);
    function acPool5() external view returns (address);
    function acPool6() external view returns (address);
    function nftAllocationContract () external view returns (address);
	function nftStakingContract() external view returns (address);
}

interface IToken {
    function governor() external view returns (address);
}

interface IacPool {
    function setAdmin() external;
    function dummyToken() external view returns (IERC20);
}

interface IGovernor {
    function consensusContract() external view returns (address);
    function farmContract() external view returns (address);
    function fibonacceningContract() external view returns (address);
    function basicContract() external view returns (address);
    function treasuryWallet() external view returns (address);
    function nftWallet() external view returns (address);
    function oldChefOwner() external returns (address);
	function nftAllocationContract() external view returns (address);
}

interface IChange {
    function changeGovernor() external;
    function updatePools() external;
    function setAdmin() external;
    function setMasterchef() external;
}

interface INFTstaking {
	function setAdmin() external;
}

interface IMasterChef {
    function poolInfo(uint256) external returns (address, uint256, uint256, uint256, uint16);
}
contract XVMCsyncContracts {
    address public immutable tokenXVMC;
    
    address public acPool1;
    address public acPool2;
    address public acPool3;
    address public acPool4;
    address public acPool5;
    address public acPool6;


    constructor(address _xvmc) {
        tokenXVMC = _xvmc;
    }

    function updateAll() external {
        updatePoolsOwner();
        updateSideContractsOwner();
        updatePoolsInSideContracts();
        updateMasterchef();
		nftStaking();
    }

    function updatePools() public {
        address governor = IToken(tokenXVMC).governor();

        acPool1 = IXVMCgovernor(governor).acPool1();
        acPool2 = IXVMCgovernor(governor).acPool2();
        acPool3 = IXVMCgovernor(governor).acPool3();
        acPool4 = IXVMCgovernor(governor).acPool4();
        acPool5 = IXVMCgovernor(governor).acPool5();
        acPool6 = IXVMCgovernor(governor).acPool6();
    }

    function updatePoolsOwner() public {
        updatePools();

        IacPool(acPool1).setAdmin();
        IacPool(acPool2).setAdmin();
        IacPool(acPool3).setAdmin();
        IacPool(acPool4).setAdmin();
        IacPool(acPool5).setAdmin();
        IacPool(acPool6).setAdmin();
    }

    function updateSideContractsOwner() public {
        address governor = IToken(tokenXVMC).governor();

        IChange(IGovernor(governor).consensusContract()).changeGovernor();
        IChange(IGovernor(governor).farmContract()).changeGovernor();
        IChange(IGovernor(governor).fibonacceningContract()).changeGovernor();
        IChange(IGovernor(governor).basicContract()).changeGovernor();
    }

    function updatePoolsInSideContracts() public {
        address governor = IToken(tokenXVMC).governor();

        IChange(IGovernor(governor).consensusContract()).updatePools();
        IChange(IGovernor(governor).basicContract()).updatePools();
    }

    //updates allocation contract owner, nft staking(admin)
    function nftStaking() public {
        address governor = IToken(tokenXVMC).governor();
		address _stakingContract = IXVMCgovernor(governor).nftStakingContract();

        IChange(IGovernor(governor).nftAllocationContract()).changeGovernor();
        INFTstaking(_stakingContract).setAdmin();
    }
    
    
    function updateMasterchef() public {
		address governor = IToken(tokenXVMC).governor();

        IChange(IGovernor(governor).farmContract()).setMasterchef();
        IChange(IGovernor(governor).fibonacceningContract()).setMasterchef();
    }
}