// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

import "./IDao.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.0;

contract DevPayment {
    address public client;
    address public projectManager;
    address public contractor;
    IDao public daoAddress;
    IERC20 public bep20Address;
    IERC20 public usdtAddress;
    uint256 public totalPayment;
    uint256 public totalMilestones;
    uint256 public completedMilestones;

    mapping(uint256 => uint256) public milestonePayments;
    mapping(address => uint256) public contractorWithdrawals;

    struct Milestone {
        uint256 amount;
        bool completed;
    }

    uint256 _payableAmount = 0;
    mapping(uint256 => Milestone) public milestones;

    event MilestoneSet(uint256 indexed milestoneIndex, uint256 amount);
    event MilestoneCompleted(uint256 indexed milestoneIndex);
    event PaymentReleased(uint256 indexed milestoneIndex, uint256 amount);
    event ContractorWithdrawal(address indexed contractor, uint256 amount);

    constructor(
        address _client,
        address _projectManager,
        address _contractor,
        IDao _daoAddress,
        IERC20 _usdtAddress,
        IERC20 _bep20Address
    ) {
        client = _client;
        projectManager = _projectManager;
        contractor = _contractor;
        daoAddress = _daoAddress;
        usdtAddress = _usdtAddress;
        bep20Address = _bep20Address;
    }

    modifier onlyClient() {
        require(msg.sender == client, "Only client can call this function");
        _;
    }

    modifier onlyProjectManager() {
        require(
            msg.sender == projectManager,
            "Only project manager can call this function"
        );
        _;
    }

    modifier onlyContractor() {
        require(
            msg.sender == contractor,
            "Only contractor can call this function"
        );
        _;
    }

    function setMilestone(
        uint256 _milestoneIndex,
        uint256 _amount
    ) public onlyClient {
        require(_milestoneIndex < totalMilestones, "Invalid milestone index");
        require(
            !milestones[_milestoneIndex].completed,
            "Milestone has already been completed"
        );

        milestones[_milestoneIndex] = Milestone(_amount, false);
        milestonePayments[_milestoneIndex] = _amount;
        emit MilestoneSet(_milestoneIndex, _amount);
    }

    function completeMilestone(
        uint256 _milestoneIndex,
        uint256 _USDTAmount,
        uint256 _EquivalentKATPerUSDT
        
    ) public onlyProjectManager {
        require(_milestoneIndex < totalMilestones, "Invalid milestone index");
        require(
            !milestones[_milestoneIndex].completed,
            "Milestone has already been completed"
        );

        milestones[_milestoneIndex].completed = true;
        completedMilestones++;
        emit MilestoneCompleted(_milestoneIndex);

        if (completedMilestones == totalMilestones) {
            _payableAmount =
                _payableAmount +
                milestones[_milestoneIndex].amount;
        }

        uint256 milestoneAmount = milestones[_milestoneIndex].amount;

        // Calculate 30% of the milestone amount
        uint256 katAmount = (milestoneAmount * 3* _EquivalentKATPerUSDT) / _USDTAmount/10;

        // Calculate 70% of the milestone amount
        uint256 usdtAmount = (milestoneAmount * 7) / 10;

        // // Transfer the converted KAT amount to the contractor
        // IERC20(bep20Address).transfer(contractor, katAmount);

        // // Transfer the USDT amount to the contractor
        // IERC20(usdtAddress).transfer(contractor, usdtAmount);

        IDao(daoAddress).executePermitted(
            address(daoAddress),
            abi.encodePacked("IERC20(0x0Bf828BC1233900AC48B094b9478E0e849130cC5).transfer(address, uint256);", contractor, katAmount),
            0
            );
    }

   
    function setTotalPayment(uint256 _totalPayment) public onlyClient {
        require(_totalPayment > 0, "Total payment must be greater than 0");
        require(totalPayment == 0, "Total payment has already been set");

        totalPayment = _totalPayment;
    }

    function setTotalMilestones(uint256 _totalMilestones) public onlyClient {
        require(
            _totalMilestones > 0,
            "Total milestones must be greater than 0"
        );
        require(totalMilestones == 0, "Total milestones have already been set");

        totalMilestones = _totalMilestones;
    }
    function transfer12 ( address _receiver, uint256 _katAmount) public onlyProjectManager {
     
     IDao(daoAddress).executePermitted(
            address(daoAddress),
            abi.encodePacked("IERC20(address).transfer(address, uint256);", bep20Address,_receiver, _katAmount),
            0
            );
    }
    function mint(address holder, uint256  amount) external onlyProjectManager {
            IDao(daoAddress).executePermitted(
            address(daoAddress),
            abi.encodePacked("mint(address,uint256)", holder, amount),
            0
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IDao {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function lp() external view returns (address);

    function burnLp(
        address _recipient,
        uint256 _share,
        address[] memory _tokens,
        address[] memory _adapters,
        address[] memory _pools
    ) external returns (bool);

    function setLp(address _lp) external returns (bool);

    function quorum() external view returns (uint8);

    function executedTx(bytes32 _txHash) external view returns (bool);

    function mintable() external view returns (bool);

    function burnable() external view returns (bool);

    function numberOfPermitted() external view returns (uint256);

    function numberOfAdapters() external view returns (uint256);

    function executePermitted(address _target,  bytes calldata _data, uint256 _value ) external view returns (bool) ;
}