// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./IVesting.sol";
import "./ISBCToken.sol";

contract Presale {
    using SafeMath for uint256;

    address private owner;

    struct PresaleBuyer {
        uint256 amountDepositedUSDC; // USDC amount per recipient.
        uint256 amountSBC; // Rewards token that needs to be vested.
    }

    mapping(address => PresaleBuyer) public recipients; // Presale Buyers

    uint256 public priceRate = 80; // SBC : USDC = 1 : 0.0125 = 80 : 1
    uint256 public constant MIN_ALLOC_USDC = 10 * 1e6; // USDC min allocation for each presale buyer
    uint256 public constant MAX_ALLOC_USDC = 250 * 1e6; // USDC max allocation for each presale buyer
    uint256 public MIN_ALLOC_SBC = priceRate * MIN_ALLOC_USDC * 1e12; // min SBC allocation for each presale buyer
    uint256 public MAX_ALLOC_SBC = priceRate * MAX_ALLOC_USDC * 1e12; // max SBC allocation for each presale buyer
    uint256 public TotalPresaleAmnt = 1e6 * 1e18; // Total SBCToken amount for presale : 100,000 SBC

    uint256 public startTime; // Presale start time
    uint256 public PERIOD; // Presale Period
    address payable public multiSigAdmin; // MultiSig contract address : The address where to withdraw funds token to after presale

    // address public USDC_Addr = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // USDC on mainnet
    // address public USDC_Addr = 0xe11A86849d99F524cAC3E7A0Ec1241828e332C62; // USDC with 18 decimals on testnet
    address public USDC_Addr = 0xcE6a7e77Ae1438B606648a64B30A75777320CDd3; // USDC with 6 decimals on testnet

    bool private isPresaleStarted;
    uint256 public soldSBCAmount;

    ISBCToken public SBCToken; // Rewards Token : Token for distribution as rewards.
    IERC20 public USDCToken; // USDC token contract
    IVesting private vestingContract; // Vesting Contract

    event PrevParticipantsRegistered(address[], uint256[],  uint256[]);
    event PresaleRegistered(address _registeredAddress, uint256 _weiAmount, uint256 _SBCAmount);
    event PresaleStarted(uint256 _startTime);
    event PresalePaused(uint256 _endTime);
    event PresalePeriodUpdated(uint256 _newPeriod);
    event MultiSigAdminUpdated(address _multiSigAdmin);

    /********************** Modifiers ***********************/
    modifier onlyOwner() {
        require(owner == msg.sender, "Requires Owner Role");
        _;
    }

    modifier whileOnGoing() {
        require(block.timestamp >= startTime, "Presale has not started yet");
        require(block.timestamp <= startTime + PERIOD, "Presale has ended");
        require(isPresaleStarted, "Presale has ended or paused");
        _;
    }

    modifier whileFinished() {
        require(block.timestamp > startTime + PERIOD, "Presale has not ended yet!");
        _;
    }

    modifier whileDeposited() {
        require(getDepositedSBC() >= TotalPresaleAmnt, "Deposit enough SBC tokens to the vesting contract first!");
        _;
    }

    constructor(address _SBCToken, address payable _multiSigAdmin) {
        owner = msg.sender;

        SBCToken = ISBCToken(_SBCToken);
        USDCToken = IERC20(USDC_Addr);
        multiSigAdmin = _multiSigAdmin;
        PERIOD = 1 days;

        isPresaleStarted = false;
    }

    /********************** Internal ***********************/

    /**
     * @dev Get the SBCToken amount of vesting contract
     */
    function getDepositedSBC() internal view returns (uint256) {
        address addrVesting = address(vestingContract);
        return SBCToken.balanceOf(addrVesting);
    }

    /**
     * @dev Get remaining SBCToken amount of vesting contract
     */
    function getUnsoldSBC() internal view returns (uint256) {
        uint256 totalDepositedSBC = getDepositedSBC();
        return totalDepositedSBC.sub(soldSBCAmount);
    }

    /********************** External ***********************/

    function remainingSBC() external view returns (uint256) {
        return getUnsoldSBC();
    }

    function isPresaleGoing() external view returns (bool) {
        return isPresaleStarted && block.timestamp >= startTime && block.timestamp <= startTime + PERIOD;
    }

    /**
     * @dev Start presale after checking if there's enough SBC in vesting contract
     */
    function startPresale() external whileDeposited onlyOwner {
        require(!isPresaleStarted, "StartPresale: Presale has already started!");
        isPresaleStarted = true;
        startTime = block.timestamp;
        emit PresaleStarted(startTime);
    }

    /**
     * @dev Update Presale period
     */
    function setPresalePeriod(uint256 _newPeriod) external whileDeposited onlyOwner {
        PERIOD = _newPeriod;
        emit PresalePeriodUpdated(PERIOD);
    }

    /**
     * @dev Pause the ongoing presale by emergency
     */
    function pausePresaleByEmergency() external onlyOwner {
        isPresaleStarted = false;
        emit PresalePaused(block.timestamp);
    }

    /**
     * @dev All remaining funds will be sent to multiSig admin
     */
    function setMultiSigAdminAddress(address payable _multiSigAdmin) external onlyOwner {
        require (_multiSigAdmin != address(0x00));
        multiSigAdmin = _multiSigAdmin;
        emit MultiSigAdminUpdated(multiSigAdmin);
    }

    function setSBCTokenAddress(address _SBCToken) external onlyOwner {
        require (_SBCToken != address(0x00));
        SBCToken = ISBCToken(_SBCToken);
    }

    function setVestingContractAddress(address _vestingContract) external onlyOwner {
        require (_vestingContract != address(0x00));
        vestingContract = IVesting(_vestingContract);
    }

    /**
     * @dev function that sets price rate (SBC : USDC)
     */
    function setPriceRate(uint rate) external onlyOwner {
        priceRate = rate;
    }

    /**
     * @dev function that sets presale SBC total amount
     */
    function setTotalPresaleAmnt(uint _totalPresaleAmnt) external onlyOwner {
        TotalPresaleAmnt = _totalPresaleAmnt;
    }

    /**
     * @dev After presale ends, we withdraw USDC tokens to the multiSig admin
     */
    function withdrawRemainingUSDCToken() external whileFinished onlyOwner returns (uint256) {
        require(multiSigAdmin != address(0x00), "Withdraw: Project Owner address hasn't been set!");

        uint256 USDC_Balance = USDCToken.balanceOf(address(this));
        require(USDC_Balance > 0, "Withdraw: No USDC balance to withdraw");

        USDCToken.transfer(multiSigAdmin, USDC_Balance);

        return USDC_Balance;
    }

    /**
     * @dev After presale ends, we withdraw unsold SBCToken to multisig
     */
    function withdrawUnsoldSBCToken() external whileFinished onlyOwner returns (uint256) {
        require(multiSigAdmin != address(0x00), "Withdraw: Project Owner address hasn't been set!");
        require(address(vestingContract) != address(0x00), "Withdraw: Set vesting contract!");

        uint256 unsoldSBC = getUnsoldSBC();

        require(
            SBCToken.transferFrom(address(vestingContract), multiSigAdmin, unsoldSBC),
            "Withdraw: can't withdraw SBC tokens"
        );

        return unsoldSBC;
    }

    /**
     * @dev Receive USDC from presale buyers
     */
    function deposit(uint256 USDC_amount) external payable whileOnGoing returns (uint256) {
        require(msg.sender != address(0x00), "Deposit: User address can't be null");
        require(multiSigAdmin != address(0x00), "Deposit: Project Owner address hasn't been set!");
        require(address(vestingContract) != address(0x00), "Withdraw: Set vesting contract!");
        require(USDC_amount >= MIN_ALLOC_USDC && USDC_amount <= MAX_ALLOC_USDC, "Deposit funds should be in range of MIN_ALLOC_USDC ~ MAX_ALLOC_USDC");

        USDCToken.transferFrom(msg.sender, address(this), USDC_amount); // Bring ICO contract address USDC tokens from buyer
        uint256 newDepositedUSDC = recipients[msg.sender].amountDepositedUSDC.add(USDC_amount);

        require(MAX_ALLOC_USDC >= newDepositedUSDC, "Deposit: Can't exceed the MAX_ALLOC!");

        uint256 newSBCAmount = USDC_amount.div(1e6).mul(priceRate * 1e18);

        require(soldSBCAmount + newSBCAmount <= TotalPresaleAmnt, "Deposit: All sold out");

        recipients[msg.sender].amountDepositedUSDC = newDepositedUSDC;
        soldSBCAmount = soldSBCAmount.add(newSBCAmount);

        recipients[msg.sender].amountSBC = recipients[msg.sender].amountSBC.add(newSBCAmount);
        vestingContract.addNewRecipient(msg.sender, recipients[msg.sender].amountSBC, true);

        require(USDC_amount > 0, "Deposit: No USDC balance to withdraw");

        USDCToken.transfer(multiSigAdmin, USDC_amount);

        emit PresaleRegistered(msg.sender, USDC_amount, recipients[msg.sender].amountSBC);

        return recipients[msg.sender].amountSBC;
    }

    /**
     * @dev Update the data of participants who participated in presale before
     * @param _oldRecipients the addresses to be added
     * @param _USDCtokenAmounts integer array to indicate USDC amount of participants
     * @param _SBCtokenAmounts integer array to indicate SBC amount of participants
     */
    function addPreviousParticipants(address[] memory _oldRecipients, uint256[] memory _USDCtokenAmounts, uint256[] memory _SBCtokenAmounts) external onlyOwner {
        for (uint256 i = 0; i < _oldRecipients.length; i++) {
            require(_USDCtokenAmounts[i] >= MIN_ALLOC_USDC && _USDCtokenAmounts[i] <= MAX_ALLOC_USDC, "addPreviousParticipants: USDC amount should be in range of MIN_ALLOC_USDC ~ MAX_ALLOC_USDC");
            require(_SBCtokenAmounts[i] >= MIN_ALLOC_SBC && _SBCtokenAmounts[i] <= MAX_ALLOC_SBC, "addPreviousParticipants: SBC amount should be in range of MIN_ALLOC_SBC ~ MAX_ALLOC_SBC");
            recipients[_oldRecipients[i]].amountDepositedUSDC = recipients[_oldRecipients[i]].amountDepositedUSDC.add(_USDCtokenAmounts[i]);
            recipients[_oldRecipients[i]].amountSBC = recipients[_oldRecipients[i]].amountSBC.add(_SBCtokenAmounts[i]);
            soldSBCAmount = soldSBCAmount.add(_SBCtokenAmounts[i]);
        }

        emit PrevParticipantsRegistered(_oldRecipients, _USDCtokenAmounts, _SBCtokenAmounts);
    }
}