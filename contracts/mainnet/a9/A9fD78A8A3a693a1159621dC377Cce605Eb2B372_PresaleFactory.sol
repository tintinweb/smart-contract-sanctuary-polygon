// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Presale.sol";
import "./PresaleTypes.sol";
import "./interface/IPresaleProxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PresaleFactory is
    PresaleTypes,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    address private operator;
    address private presaleProxy;

    string[] public contractArray;
    mapping(string => address) private contractsList;
    event Created(string indexed presaleName, address indexed presaleContract);

    function initialize(address _operator, address _presaleProxy)
        public
        initializer
    {
        OwnableUpgradeable.initialize();
        setOperator(_operator);
        setPresaleProxy(_presaleProxy);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setOperator(address _operator) public onlyOwner {
        operator = _operator;
    }

    function getOperator() public view returns (address) {
        return operator;
    }

    function setPresaleProxy(address _presaleProxy) public onlyOwner {
        presaleProxy = _presaleProxy;
    }

    function getPresaleProxy() public view returns (address) {
        return presaleProxy;
    }

    function create(
        string memory _presaleName,
        Ruleset[] memory _rulesetList,
        uint256[] memory _spots,
        IERC20 _investToken,
        IERC20 _presaleToken,
        IERC20 _ticketToken,
        string memory _fractalListId,
        PriceStage[] memory _priceStages,
        PoolParams memory _poolParams,
        IncentiveStruct[] memory _incentiveStructList
    ) external returns (address _contractAddress) {
        require(
            contractsList[_presaleName] == address(0),
            "PSF: project already exists."
        );

        Presale newContract = new Presale(
            msg.sender,
            _presaleName,
            _rulesetList,
            _spots,
            _investToken,
            _presaleToken,
            operator,
            presaleProxy,
            _priceStages,
            _poolParams,
            _incentiveStructList
        );

        contractArray.push(_presaleName);
        contractsList[_presaleName] = address(newContract);
        _contractAddress = address(newContract);
        IPresaleProxy(presaleProxy).insertPresaleProject(
            _presaleName,
            address(_investToken),
            address(_ticketToken),
            _fractalListId,
            address(newContract)
        );
        emit Created(_presaleName, address(newContract));
    }

    function getContract(string memory _preSaleName)
        external
        view
        returns (address _contractAddress)
    {
        _contractAddress = contractsList[_preSaleName];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./PresaleProxy.sol";
import "./PresaleTypes.sol";
import "./interface/IPresale.sol";

import "../libraries/UniERC20.sol";
import "./Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Presale is IPresale, PresaleTypes, Ownable, ReentrancyGuard {
    using UniERC20 for IERC20;
    using SafeERC20 for IERC20;

    event PurchasePreSaleToken(address beneficiary);
    event TokensReleased(address beneficiary, uint256 amount);

    uint256 public constant ONE_MONTH = 4 hours;

    string public presaleName;

    PresaleState public state;

    uint256 public investedAmount;
    uint256 public totalInvestorShare;
    uint256 public totalOperatorShare;

    address[] public investors;
    mapping(address => InvestorStruct) public investorIndex;

    Ruleset[] public rulesetList;
    PriceStage[] public priceStages;
    IncentiveStruct[] public incentiveStructList;

    PriceStage public priceStage;

    uint256[] public spots;

    IERC20 private investToken;
    IERC20 private presaleToken;

    address public presaleProxy;
    address public operator;

    PoolParams public poolParams;

    constructor(
        address _owner,
        string memory _presaleName,
        Ruleset[] memory _rulesetList,
        uint256[] memory _spots,
        IERC20 _investToken,
        IERC20 _presaleToken,
        address _operator,
        address _presaleProxy,
        PriceStage[] memory _priceStages,
        PoolParams memory _poolParams,
        IncentiveStruct[] memory _incentiveStructList
    ) {
        setOwner(_owner);
        presaleName = _presaleName;
        for (uint256 i = 0; i < _rulesetList.length; i++) {
            rulesetList.push(_rulesetList[i]);
        }

        for (uint256 i = 0; i < _priceStages.length; i++) {
            priceStages.push(_priceStages[i]);
        }
        priceStages[priceStages.length - 1].amount = _poolParams.hardCap;

        for (uint256 i = 0; i < _spots.length; i++) {
            spots.push(_spots[i]);
        }

        for (uint256 i = 0; i < _incentiveStructList.length; i++) {
            incentiveStructList.push(_incentiveStructList[i]);
        }

        priceStage = _priceStages[0];

        investToken = _investToken;
        presaleToken = _presaleToken;
        operator = _operator;

        require(
            _presaleProxy != address(0),
            "PresaleContract address is zero."
        );
        presaleProxy = _presaleProxy;

        poolParams = _poolParams;
        state = PresaleState.PREOPEN;
    }

    modifier whenNotStop() {
        updatePoolState();

        require(
            state != PresaleState.PREOPEN,
            "privateSale is in preopen state"
        );
        require(state != PresaleState.CLOSE, "privateSale is in close state");
        require(
            state != PresaleState.FAILURE,
            "privateSale is in failure state"
        );
        require(
            investedAmount < poolParams.hardCap,
            "investment reached hardcap"
        );
        _;
    }

    function purchasePreSaleToken(uint256 _amount, address _account)
        external
        nonReentrant
        whenNotStop
    {
        require(
            msg.sender == presaleProxy,
            "Request is not from opportunity Contract."
        );
        require(_account != operator, "account should be defer from operator");
        require(
            _amount >= poolParams.minInvest,
            "Can't buy with an amount less than minimum invest"
        );

        uint256 _remainsAmount = poolParams.hardCap - investedAmount;

        require(_remainsAmount >= _amount, "investment exceed hardcap");

        investToken.safeTransferFrom(presaleProxy, address(this), _amount);

        if (!investorIndex[_account].exist) {
            investors.push(_account);

            investorIndex[_account].exist = true;
            investorIndex[_account].vestingType = VestingType.INVESTORS;
            investorIndex[_account].state = InvestorState.INVESTED;
            investorIndex[_account].balance = _amount;
        } else {
            investorIndex[_account].balance += _amount;
        }
        updateShares(_account, _amount);
        investedAmount += _amount;
        updateStage();

        emit PurchasePreSaleToken(_account);
    }

    // someone must call updatePoolState after Close time
    function updatePool() external {
        updatePoolState();
    }

    function withdrawInvestmentsByBeneficiary() external onlyOwner {
        updatePoolState();
        require(state == PresaleState.CLOSE, "the presale is not closed yet");
        updateOperatorShare();
        uint256 balance = investToken.balanceOf(address(this));
        address _owner = owner();

        investToken.safeTransfer(_owner, balance);
    }

    function withdrawInvestedToken() external {
        updatePoolState();
        require(investorIndex[msg.sender].exist, "the account is not exists");
        require(state == PresaleState.FAILURE, "state is not failure");
        uint256 _userBalance = investorIndex[msg.sender].balance;
        investToken.safeTransfer(msg.sender, _userBalance);

        delete investorIndex[msg.sender];
        uint256 _index;
        for (uint256 i = 0; i < investors.length; i++) {
            address _userAddress = investors[i];
            if (_userAddress == msg.sender) {
                _index = i;
                break;
            }
        }
        investors[_index] = investors[investors.length - 1];
        investors.pop();
    }

    function buyTicket(address _account) external whenNotStop {
        require(spots.length > 0, "No ticket remains");
        require(
            msg.sender == presaleProxy,
            "Request is not from opportunity Contract."
        );

        require(investorIndex[_account].exist, "the account is not exists");
        require(
            investorIndex[_account].state != InvestorState.VIP,
            "The user is already VIP"
        );

        uint256 newInvestorShare = investorIndex[_account].balance *
            priceStages[0].priceRatio *
            1e12;

        uint256 differenceOfShare = newInvestorShare -
            investorIndex[_account].investorShare;

        investorIndex[_account].investorShare = newInvestorShare;
        investorIndex[_account].state = InvestorState.VIP;

        totalInvestorShare += differenceOfShare;

        spots.pop();
    }

    function getTicket() external view returns (uint256) {
        require(spots.length > 0, "No ticket remains");

        return spots[spots.length - 1];
    }

    function getTickets() external view returns (uint256[] memory) {
        return spots;
    }

    function getPoolDetail()
        external
        view
        returns (
            uint256,
            uint256,
            PoolParams memory,
            PriceStage[] memory,
            PriceStage memory
        )
    {
        return (
            investedAmount,
            totalInvestorShare,
            poolParams,
            priceStages,
            priceStage
        );
    }

    function updateStage() internal {
        for (uint256 i = 0; i < priceStages.length; i++) {
            if (investedAmount < priceStages[i].amount) {
                priceStage = priceStages[i];
                break;
            }
        }
    }

    function updatePoolState() internal {
        if (
            state == PresaleState.PREOPEN &&
            poolParams.startDate < block.timestamp
        ) {
            state = PresaleState.THREEHOURS;
        }

        if (
            state == PresaleState.THREEHOURS &&
            poolParams.startDate + 3 hours < block.timestamp
        ) {
            state = PresaleState.FIFO;
        }

        if (
            state == PresaleState.FIFO && poolParams.endDate < block.timestamp
        ) {
            if (poolParams.softCap <= investedAmount) {
                state = PresaleState.CLOSE;
            } else {
                state = PresaleState.FAILURE;
            }
        }
    }

    function updateShares(address _account, uint256 _amount) internal {
        uint256 _investorShare = 0;
        InvestorState _investorState = investorIndex[_account].state; // gas saving

        if (
            state == PresaleState.THREEHOURS ||
            _investorState == InvestorState.VIP
        ) {
            _investorShare = _amount * priceStages[0].priceRatio * 1e12;
        } else if (state == PresaleState.FIFO) {
            _investorShare = _amount * priceStage.priceRatio * 1e12;
        }

        investorIndex[_account].investorShare += _investorShare;
        totalInvestorShare += _investorShare;
    }

    function updateOperatorShare() internal {
        require(
            !investorIndex[operator].exist,
            "Operator share was clculated before."
        );
        for (uint256 i = 0; i < incentiveStructList.length; i++) {
            if (investedAmount <= incentiveStructList[i].amount) {
                totalOperatorShare =
                    (totalInvestorShare * incentiveStructList[i].percentage) /
                    10000;
                break;
            }
        }

        investors.push(operator);

        investorIndex[operator].exist = true;
        investorIndex[operator].investorShare = totalOperatorShare;
        investorIndex[operator].state = InvestorState.INVESTED;
        investorIndex[operator].vestingType = VestingType.OPERATOR;
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release(address payable _investor) external {
        require(investorIndex[_investor].exist, "investor does not exist");
        require(
            msg.sender == _investor,
            "message sender is not equal investor"
        );

        uint256 _unreleased = getReleasable(_investor);

        require(_unreleased > 0, "releasable amount is zero");

        investorIndex[_investor].released =
            investorIndex[_investor].released +
            _unreleased;

        IERC20(presaleToken).safeTransfer(_investor, _unreleased);

        emit TokensReleased(_investor, _unreleased);
    }

    function getReleasable(address _investor) public view returns (uint256) {
        require(investorIndex[_investor].exist, "investor does not exist");

        return vestedAmount(_investor) - investorIndex[_investor].released;
    }

    function vestedAmount(address _investor) private view returns (uint256) {
        // a month is 2592000 seconds
        if (
            block.timestamp <
            poolParams.tgeDate + (rulesetList[0].month * ONE_MONTH)
        ) {
            return 0;
        }

        uint256 _index;
        for (uint256 i = 0; i < rulesetList.length; i++) {
            Ruleset memory _ruleset = rulesetList[i];
            uint256 _releaseDate = poolParams.tgeDate +
                (_ruleset.month * ONE_MONTH);
            if (_releaseDate < block.timestamp) {
                _index = i;
            }
        }

        return
            (investorIndex[_investor].investorShare *
                rulesetList[_index].value) / 100;
    }

    function nextRelease() public view returns (uint256, uint256) {
        // a month is 2592000 seconds
        uint256 _index = rulesetList.length - 1;
        for (uint256 i = 0; i < rulesetList.length; i++) {
            if (
                block.timestamp <
                poolParams.tgeDate + (rulesetList[i].month * ONE_MONTH)
            ) {
                _index = i;
                break;
            }
        }

        uint256 _releaseTime = poolParams.tgeDate +
            (rulesetList[_index].month * ONE_MONTH);
        uint256 _releaseAmount = ((totalInvestorShare + totalOperatorShare) *
            rulesetList[_index].value) / 100;

        return (_releaseAmount, _releaseTime);
    }

    function nextUserRelease(address _investor)
        public
        view
        returns (uint256, uint256)
    {
        require(investorIndex[_investor].exist, "investor does not exist");

        // a month is 2592000 seconds
        uint256 _index = rulesetList.length - 1;
        for (uint256 i = 0; i < rulesetList.length; i++) {
            if (
                block.timestamp <
                poolParams.tgeDate + (rulesetList[i].month * ONE_MONTH)
            ) {
                _index = i;
                break;
            }
        }

        uint256 _releaseTime = poolParams.tgeDate +
            (rulesetList[_index].month * ONE_MONTH);
        uint256 _releaseAmount = (investorIndex[_investor].investorShare *
            rulesetList[_index].value) / 100;

        return (_releaseAmount, _releaseTime);
    }

    function setTgeDate(uint256 _date) external onlyOwner {
        poolParams.tgeDate = _date;
    }

    function setPresaleContract(address contract_) external onlyOwner {
        presaleProxy = contract_;
    }

    //todo must be removed
    function withdrawTokenAll(IERC20 _token) external nonReentrant onlyOwner {
        uint256 _balance = _token.balanceOf(address(this));

        _token.safeTransfer(owner(), _balance);
    }
}

pragma solidity ^0.8.0;

contract PresaleTypes {
    //0: Investors, 1: Operator
    enum VestingType {
        INVESTORS,
        OPERATOR
    }

    enum PresaleState {
        PREOPEN,
        THREEHOURS,
        FIFO,
        CLOSE,
        FAILURE
    }

    enum InvestorState {
        INVESTED,
        VIP
    }

    struct InvestorStruct {
        uint256 investorShare;
        uint256 released;
        uint256 balance;
        VestingType vestingType;
        InvestorState state;
        bool exist;
    }

    struct Ruleset {
        uint256 month;
        uint256 value; //VestingTypeStruct: coefficient, BeneficiaryStruct: amount
    }

    struct PriceStage {
        uint256 amount;
        uint256 priceRatio;
    }

    struct IncentiveStruct {
        uint256 amount;
        uint256 percentage;
    }

    struct PoolParams {
        uint256 startDate;
        uint256 tgeDate;
        uint256 endDate;
        uint256 hardCap;
        uint256 softCap;
        uint256 minInvest;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IPresaleProxy {
    function insertPresaleProject(
        string memory _presaleName,
        address _investToken,
        address _ticketToken,
        string memory _fractalListId,
        address _presaleContract
    ) external;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../helpers/OwnableUpgradeable.sol";
import "../libraries/UniERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./interface/IPresale.sol";
import "./interface/FractalRegistry.sol";

contract PresaleProxy is
    Initializable,
    UUPSUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    using UniERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct PresaleMetadata {
        address investToken;
        address ticketToken;
        string fractalListId;
        address presaleContract;
        bool exist;
    }

    mapping(string => PresaleMetadata) public presaleProject;

    address private fractalContract;
    mapping(address => bool) private isWhiteListedInvestors;
    address public swapContract;

    event Swapped(
        string indexed presaleName,
        address indexed user,
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 amountOut
    );
    event InvestedByToken(
        string indexed presaleName,
        address indexed user,
        address token,
        uint256 amount
    );
    event Invested(
        string indexed presaleName,
        address indexed user,
        address token,
        uint256 amount
    );
    event Purchased(
        string indexed presaleName,
        address indexed user,
        uint256 amount
    );
    event WithdrawnFunds(address token, uint256 amount, address receiver);

    //todo ICONX: Complete comments
    /**
     * @dev todo
     * @param fractalContract_ The threshold for the values of input tokens
     * @param whiteListedInvestorsList_ whiteList
     * @param swapContract_ swapContract
     **/
    function initialize(
        address fractalContract_,
        address[] memory whiteListedInvestorsList_,
        address swapContract_
    ) public initializer {
        OwnableUpgradeable.initialize();
        setFractalContract(fractalContract_);
        addWhiteListedInvestors(whiteListedInvestorsList_);
        swapContract = swapContract_;
    }

    modifier approvedInvestor(
        string memory _presaleName,
        address _userAddress
    ) {
        require(isKYC(_presaleName, _userAddress), "PSP: user is not approved");
        _;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function insertPresaleProject(
        string memory _presaleName,
        address _investToken,
        address _ticketToken,
        string memory _fractalListId,
        address _presaleContract
    ) external {
        require(
            !presaleProject[_presaleName].exist,
            "PSP: peoject already exists."
        );

        PresaleMetadata memory _newPresaleMetadata;
        _newPresaleMetadata.investToken = _investToken;
        _newPresaleMetadata.ticketToken = _ticketToken;
        _newPresaleMetadata.fractalListId = _fractalListId;
        _newPresaleMetadata.presaleContract = _presaleContract;
        _newPresaleMetadata.exist = true;

        presaleProject[_presaleName] = _newPresaleMetadata;
    }

    //todo what about update of common field in both contract?
    function updatePresaleProject(
        //todo is update method required???
        string memory _presaleName,
        address _investToken,
        address _ticketToken,
        string memory _fractalListId,
        address _presaleContract
    ) external {
        require(
            presaleProject[_presaleName].exist,
            "PSP: peoject does not exists."
        );

        PresaleMetadata memory _newPresaleMetadata;
        _newPresaleMetadata.investToken = _investToken;
        _newPresaleMetadata.ticketToken = _ticketToken;
        _newPresaleMetadata.fractalListId = _fractalListId;
        _newPresaleMetadata.presaleContract = _presaleContract;
        _newPresaleMetadata.exist = true;

        presaleProject[_presaleName] = _newPresaleMetadata;
    }

    function invest(
        string memory _presaleName,
        address _userAddress,
        uint256 _amount
    ) external approvedInvestor(_presaleName, _userAddress) whenNotPaused {
        require(
            presaleProject[_presaleName].exist,
            "PSP: Invalid project name."
        );
        IERC20Upgradeable _investToken = IERC20Upgradeable(
            presaleProject[_presaleName].investToken
        );

        uint256 _beforeBalance = _investToken.uniBalanceOf(address(this));
        _transferFrom(_investToken, _amount);
        uint256 _afterBalance = _investToken.uniBalanceOf(address(this));

        uint256 _amountOut = _afterBalance - _beforeBalance;

        emit Invested(
            _presaleName,
            _userAddress,
            address(_investToken),
            _amount
        );

        _purchase(_presaleName, _userAddress, _amountOut);
    }

    /**
     * @dev Token is received
     * @param _presaleName The name of the sale
     * @param _userAddress The address of the user
     * @param _token The address of the fromToken in the swap transaction
     * @param _amount The total amount of _token to be swapped to tokenA or tokenB and to add liquidity
     * @param _swapData The transaction to swap _token to tokenA or tokenB
     */
    function investByToken(
        string memory _presaleName,
        address _userAddress,
        IERC20Upgradeable _token,
        uint256 _amount,
        bytes calldata _swapData
    )
        external
        payable
        approvedInvestor(_presaleName, _userAddress)
        whenNotPaused
    {
        require(
            presaleProject[_presaleName].exist,
            "PSP: Invalid project name."
        );
        IERC20Upgradeable _investToken = IERC20Upgradeable(
            presaleProject[_presaleName].investToken
        ); // gas savings

        if (_token.isETH()) {
            require(msg.value >= _amount, "oe03");
        } else {
            _transferFrom(_token, _amount);
        }

        emit InvestedByToken(
            _presaleName,
            _userAddress,
            address(_token),
            _amount
        );

        uint256 _amountOut = _swap(
            _presaleName,
            _token,
            _investToken,
            _amount,
            _swapData
        );
        require(_amountOut > 0, "PSP: something went wrong when swapping");

        _purchase(_presaleName, _userAddress, _amountOut);
    }

    function setFractalContract(address fractalContract_) public {
        require(
            fractalContract_ != address(0),
            "PSP: `fractalContract` is zero"
        );
        fractalContract = fractalContract_;
    }

    function addWhiteListedInvestors(address[] memory whiteListedInvestorsList_)
        public
    {
        for (uint8 i = 0; i < whiteListedInvestorsList_.length; i++) {
            isWhiteListedInvestors[whiteListedInvestorsList_[i]] = true;
        }
    }

    function _swap(
        string memory _presaleName,
        IERC20Upgradeable _fromToken,
        IERC20Upgradeable _toToken,
        uint256 _amount,
        bytes calldata _data
    ) private returns (uint256) {
        require(
            presaleProject[_presaleName].exist,
            "PSP: Invalid project name."
        );
        uint256 _beforeBalance = _toToken.uniBalanceOf(address(this));
        uint256 _amountOut = swap(_presaleName, _fromToken, _amount, _data);
        uint256 _afterBalance = _toToken.uniBalanceOf(address(this));
        require(_afterBalance - _beforeBalance == _amountOut, "oe05");
        emit Swapped(
            _presaleName,
            msg.sender,
            address(_fromToken),
            address(_toToken),
            _amount,
            _amountOut
        );
        return _amountOut;
    }

    function swap(
        string memory _presaleName,
        IERC20Upgradeable _fromToken,
        uint256 _amount,
        bytes calldata _data
    ) internal returns (uint256) {
        require(
            presaleProject[_presaleName].exist,
            "PSP: Invalid project name."
        );
        address _swapContract = swapContract; // gas savings
        if (!_fromToken.isETH()) {
            _fromToken.uniApprove(_swapContract, _amount);
        }
        bytes memory returnData = AddressUpgradeable.functionCallWithValue(
            _swapContract,
            _data,
            _fromToken.isETH() ? _amount : 0
        );
        return abi.decode(returnData, (uint256));
    }

    function _purchase(
        string memory _presaleName,
        address _userAddress,
        uint256 _amount
    ) private {
        require(
            presaleProject[_presaleName].exist,
            "PSP: Invalid project name."
        );
        purchase(_presaleName, _userAddress, _amount);
        emit Purchased(_presaleName, _userAddress, _amount);
    }

    function purchase(
        string memory _presaleName,
        address _userAddress,
        uint256 _amount
    ) internal {
        require(
            presaleProject[_presaleName].exist,
            "PSP: Invalid project name."
        );
        IPresale _presale = IPresale(
            presaleProject[_presaleName].presaleContract
        ); // gas savings
        IERC20Upgradeable _investToken = IERC20Upgradeable(
            presaleProject[_presaleName].investToken
        ); // gas savings
        _investToken.uniApprove(address(_presale), _amount);
        _presale.purchasePreSaleToken(_amount, _userAddress);
    }

    function buyTicket(string memory _presaleName, address _userAddress)
        external
        payable
    {
        require(
            presaleProject[_presaleName].exist,
            "PSP: Invalid project name."
        );
        IPresale _presale = IPresale(
            presaleProject[_presaleName].presaleContract
        ); // gas savings
        IERC20Upgradeable _ticketToken = IERC20Upgradeable(
            presaleProject[_presaleName].ticketToken
        ); // gas savings

        uint256 _ticketAmount = _presale.getTicket();

        _ticketToken.safeTransferFrom(msg.sender, address(this), _ticketAmount);

        _presale.buyTicket(_userAddress);
    }

    function _transferFrom(IERC20Upgradeable _token, uint256 _amount) private {
        uint256 _beforeBalance = _token.uniBalanceOf(address(this));
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _afterBalance = _token.uniBalanceOf(address(this));
        require(_afterBalance - _beforeBalance == _amount, "oe07");
    }

    function isKYC(string memory _presaleName, address _userAddress)
        public
        view
        returns (bool)
    {
        require(
            presaleProject[_presaleName].exist,
            "PSP: Invalid project name."
        );

        FractalRegistry registry = FractalRegistry(fractalContract);
        bytes32 fractalId = registry.getFractalId(_userAddress);
        string memory fractalListId = presaleProject[_presaleName]
            .fractalListId;
        bool kyc = registry.isUserInList(fractalId, fractalListId);
        bool _isWhiteListedInvestors = isWhiteListedInvestors[_userAddress];

        return _isWhiteListedInvestors || kyc;
    }

    function withdrawFunds(
        address _token,
        uint256 _amount,
        address payable _receiver
    ) external onlyOwner {
        IERC20Upgradeable(_token).uniTransfer(_receiver, _amount);
        emit WithdrawnFunds(_token, _amount, _receiver);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IPresale {
    function purchasePreSaleToken(uint256 _amount, address _account) external;

    function buyTicket(address _account) external;

    function getTicket() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


library UniERC20 {
    using SafeERC20 for IERC20;

    IERC20 private constant _ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 private constant _MATIC_ADDRESS = IERC20(0x0000000000000000000000000000000000001010);
    IERC20 private constant _ZERO_ADDRESS = IERC20(address(0));

    function isETH(IERC20 token) internal pure returns (bool) {
        return (token == _ZERO_ADDRESS || token == _ETH_ADDRESS || token == _MATIC_ADDRESS);
    }

    function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    function uniTransfer(IERC20 token, address payable to, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                to.transfer(amount);
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    function uniApprove(IERC20 token, address to, uint256 amount) internal {
        require(!isETH(token), "ce09");

        if (amount == 0) {
            token.safeApprove(to, 0);
        } else {
            uint256 allowance = token.allowance(address(this), to);
            if (allowance < amount) {
                token.safeIncreaseAllowance(to, amount - allowance);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "ce30");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public {
        require(msg.sender == _pendingOwner, "ce31");
        address previousOwner = _owner;
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        emit OwnershipTransferred(previousOwner, _owner);
    }

    function setOwner(address owner_) internal onlyOwner {
        _owner = owner_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title OwnableUpgradeable
 * @dev The contract provides a basic access control mechanism, where there is
 * an account (an owner) that can be granted exclusive access to specific
 * functions.
 *
 * By default, the owner account will be the one that deploys the contract.
 * This can later be changed through a two-step process:
 * {transferOwnership, claimOwnership}
 *
 * The contract is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to functions to restrict their use to the
 * owner.
 */
contract OwnableUpgradeable is Initializable {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The contract constructor that sets the original `owner` of the
     * contract to the sender account.
     */
    function initialize() internal onlyInitializing {
        _owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "ce30");
        _;
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
    * @dev Returns the address of the pending owner.
    */
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public {
        require(msg.sender == _pendingOwner, "ce31");
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        emit OwnershipTransferred(_owner, _pendingOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library UniERC20Upgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable private constant _ETH_ADDRESS = IERC20Upgradeable(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20Upgradeable private constant _MATIC_ADDRESS = IERC20Upgradeable(0x0000000000000000000000000000000000001010);
    IERC20Upgradeable private constant _ZERO_ADDRESS = IERC20Upgradeable(address(0));

    function isETH(IERC20Upgradeable token) internal pure returns (bool) {
        return (token == _ZERO_ADDRESS || token == _ETH_ADDRESS || token == _MATIC_ADDRESS);
    }

    function uniBalanceOf(IERC20Upgradeable token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    function uniTransfer(IERC20Upgradeable token, address payable to, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                to.transfer(amount);
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    function uniApprove(IERC20Upgradeable token, address to, uint256 amount) internal {
        require(!isETH(token), "ce09");

        if (amount == 0) {
            token.safeApprove(to, 0);
        } else {
            uint256 allowance = token.allowance(address(this), to);
            if (allowance < amount) {
                token.safeIncreaseAllowance(to, amount - allowance);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/// @title Fractal registry v0
/// @author Antoni Dikov and Shelby Doolittle
contract FractalRegistry {
    address root;
    mapping(address => bool) public delegates;

    mapping(address => bytes32) fractalIdForAddress;
    mapping(string => mapping(bytes32 => bool)) userLists;

    constructor(address _root) {
        root = _root;
    }

    /// @param addr is Eth address
    /// @return FractalId as bytes32
    function getFractalId(address addr) external view returns (bytes32) {
        return fractalIdForAddress[addr];
    }

    /// @notice Adds a user to the mapping of Eth address to FractalId.
    /// @param addr is Eth address.
    /// @param fractalId is FractalId in bytes32.
    function addUserAddress(address addr, bytes32 fractalId) external {
        requireMutatePermission();
        fractalIdForAddress[addr] = fractalId;
    }

    /// @notice Removes an address from the mapping of Eth address to FractalId.
    /// @param addr is Eth address.
    function removeUserAddress(address addr) external {
        requireMutatePermission();
        delete fractalIdForAddress[addr];
    }

    /// @notice Checks if a user by FractalId exists in a specific list.
    /// @param userId is FractalId in bytes32.
    /// @param listId is the list id.
    /// @return bool if the user is the specified list.
    function isUserInList(bytes32 userId, string memory listId)
    external
    view
    returns (bool)
    {
        return userLists[listId][userId];
    }

    /// @notice Add user by FractalId to a specific list.
    /// @param userId is FractalId in bytes32.
    /// @param listId is the list id.
    function addUserToList(bytes32 userId, string memory listId) external {
        requireMutatePermission();
        userLists[listId][userId] = true;
    }

    /// @notice Remove user by FractalId from a specific list.
    /// @param userId is FractalId in bytes32.
    /// @param listId is the list id.
    function removeUserFromList(bytes32 userId, string memory listId) external {
        requireMutatePermission();
        delete userLists[listId][userId];
    }

    /// @notice Only root can add delegates. Delegates have mutate permissions.
    /// @param addr is Eth address
    function addDelegate(address addr) external {
        require(msg.sender == root, "Must be root");
        delegates[addr] = true;
    }

    /// @notice Removing delegates is only posible from root or by himself.
    /// @param addr is Eth address
    function removeDelegate(address addr) external {
        require(
            msg.sender == root || msg.sender == addr,
            "Not allowed to remove address"
        );
        delete delegates[addr];
    }

    function requireMutatePermission() private view {
        require(
            msg.sender == root || delegates[msg.sender],
            "Not allowed to mutate"
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}