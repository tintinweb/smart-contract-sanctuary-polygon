/**
 *Submitted for verification at polygonscan.com on 2023-07-17
*/

pragma solidity ^0.8.0;

contract MilestonePaymentContract {
    address public client;
    address public projectManager;
    address public contractor;
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
        address _contractor
    ) {
        client = _client;
        projectManager = _projectManager;
        contractor = _contractor;
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

    function setMilestone(uint256 _milestoneIndex, uint256 _amount)
        public
        onlyClient
    {
        require(_milestoneIndex < totalMilestones, "Invalid milestone index");
        require(
            !milestones[_milestoneIndex].completed,
            "Milestone has already been completed"
        );

        milestones[_milestoneIndex] = Milestone(_amount, false);
        milestonePayments[_milestoneIndex] = _amount;
        emit MilestoneSet(_milestoneIndex, _amount);
    }

    function completeMilestone(uint256 _milestoneIndex)
        public
        onlyProjectManager
    {
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

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function contractorWithdraw(uint256 _amount) public onlyContractor {
        require(
            contractorWithdrawals[contractor] + _amount <= _payableAmount,
            "Withdrawal amount exceeds contractor's payment"
        );

        contractorWithdrawals[contractor] += _amount;
        (bool success, ) = payable(contractor).call{value: _amount}("");
        require(success, "Failed to withdraw payment");

        totalPayment -= _amount; // Trừ số tiền đã rút khỏi tổng số tiền thanh toán

        emit ContractorWithdrawal(contractor, _amount);
    }

    receive() external payable {
        // Receive payment from client
        require(msg.sender == client, "Only client can send payment");
        require(totalPayment > 0, "Total payment has not been set");

        require(
            address(this).balance + msg.value <= totalPayment,
            "Total payment exceeded"
        );
    }
}