// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


import "./Pausable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./SmartDebtRegister.sol";
import "./CapexmoveChildToken.sol";


contract SmartDebt is ERC20, Pausable {

    using SafeMath for uint256;

    // Attributes related to the loan
    address private _issuer;

    CapexmoveChildToken private _capexmoveChildToken;

    uint256 private _faceAmountInCapexmoveChildToken;

    uint256 private _couponAmountInCapexmoveChildToken;

    uint256 private _couponPaymentPeriodInSeconds;

    uint private _numberOfCouponPayments;

    SmartDebtRegister private _smartDebtRegister;

    string private _contractId;

    uint256 private _supply;
    
    uint256 private _minimumDenomination;

    uint private _contractStartTimeInSeconds;

    uint private _lendTimeInSeconds;

    struct Payment {
        uint256 amount;
        uint timestamp;
    }

    mapping (uint => Payment) private _payments;

    uint private _paymentsCount = 0;

    uint256 private _totalCapexmoveChildTokensToRepay;

    uint256 private _totalCapexmoveChildTokensRepaid = 0;

    enum SmartDebtState {
        ContractDeployed,
        InvestorsTransferredFunds,
        IssuerStartedRepayments,
        Closed
    }

    SmartDebtState private _state;

    constructor(
        address issuer_,

        CapexmoveChildToken capexmoveChildToken_,
        uint256 faceAmountInCapexmoveChildToken_,
        uint256 couponAmountInCapexmoveChildToken_,
        uint256 couponPaymentPeriodInSeconds_,
        uint numberOfCouponPayments_,

        SmartDebtRegister smartDebtRegister_,
        string memory contractId_,

        string memory name_,
        string memory symbol_,
        uint256 minimumDenomination_
    )
    ERC20(name_, symbol_) {
        _owner = _msgSender();

        _issuer = issuer_;

        _capexmoveChildToken = capexmoveChildToken_;
        _capexmoveChildToken.registerSmartDebt(address(this), _issuer, faceAmountInCapexmoveChildToken_);
        _faceAmountInCapexmoveChildToken = faceAmountInCapexmoveChildToken_;
        _couponAmountInCapexmoveChildToken = couponAmountInCapexmoveChildToken_;
        _couponPaymentPeriodInSeconds = couponPaymentPeriodInSeconds_;
        _numberOfCouponPayments = numberOfCouponPayments_;
        _totalCapexmoveChildTokensToRepay = _couponAmountInCapexmoveChildToken
                        .mul(_numberOfCouponPayments)
                        .add(_faceAmountInCapexmoveChildToken);

        _smartDebtRegister = smartDebtRegister_;
        _contractId = contractId_;
        _smartDebtRegister.registerSmartDebt(_contractId, address(this));

        _supply = _faceAmountInCapexmoveChildToken.div(minimumDenomination_);
        _minimumDenomination = minimumDenomination_;
        _contractStartTimeInSeconds = block.timestamp;
        _state = SmartDebtState.ContractDeployed;
        _setupDecimals(0);
    }

    function getFaceAmount() public view returns (uint256) {
        return _faceAmountInCapexmoveChildToken;
    }

    function getCouponAmount() public view returns (uint256) {
        return _couponAmountInCapexmoveChildToken;
    }

    function getCouponPaymentPeriodInSeconds() public view returns (uint256) {
        return _couponPaymentPeriodInSeconds;
    }

    function getNumberOfCouponPayments() public view returns (uint256) {
        return _numberOfCouponPayments;
    }

    function getContractId() public view returns (string memory) {
        return _contractId;
    }

    function getContractStartTimeInSeconds() public view returns (uint) {
        return _contractStartTimeInSeconds;
    }

    function lend() public returns (bool) {

        require(_state == SmartDebtState.ContractDeployed);

        uint256 capexmoveChildBalance = _capexmoveChildToken.balanceOf(address(this));

		uint256 investment = _capexmoveChildToken.allowance(_msgSender(), address(this));

		// TODO : add min investment value check
		if (capexmoveChildBalance.add(investment) > _faceAmountInCapexmoveChildToken) {
			investment = _faceAmountInCapexmoveChildToken.sub(capexmoveChildBalance);
		}

		_capexmoveChildToken.transferFrom(_msgSender(), address(this), investment);

		emit LendTokens(_msgSender(), investment.div(_minimumDenomination));

		// TODO: is it necessary, buring later costs gas
		_mint(_msgSender(), investment.div(_minimumDenomination));

		capexmoveChildBalance = capexmoveChildBalance.add(investment);

		if (capexmoveChildBalance >= _faceAmountInCapexmoveChildToken) {
			// Bond is filled, capexmoveChildBalance == _faceAmountInCapexmoveChildToken
			_capexmoveChildToken.transfer(_issuer, _faceAmountInCapexmoveChildToken);

			_lendTimeInSeconds = block.timestamp;

			_state = SmartDebtState.InvestorsTransferredFunds;
			_capexmoveChildToken.activateSmartDebt(address(this));
			emit BondActivated(_issuer);
		}
		return true;
	}

    function getLendTimeInSeconds() public view returns (uint) {
        return _lendTimeInSeconds;
    }

    function registerRepayment(uint256 amount_) public returns (bool) {

        require(_msgSender() == address(_capexmoveChildToken));
        require(_state == SmartDebtState.InvestorsTransferredFunds || _state == SmartDebtState.IssuerStartedRepayments);

        _payments[_paymentsCount].amount = amount_;
        _payments[_paymentsCount].timestamp = block.timestamp;
        _paymentsCount = _paymentsCount + 1;

        _totalCapexmoveChildTokensRepaid = _totalCapexmoveChildTokensRepaid.add(amount_);

        if (_totalCapexmoveChildTokensRepaid >= _totalCapexmoveChildTokensToRepay) {

			address[] memory investors = _capexmoveChildToken.getInvestors(address(this));
			uint investorsCount = _capexmoveChildToken.getInvestorsCnt(address(this));

			for (uint i = 0; i < investorsCount; ++i) {
				_burn(investors[i], balanceOf(investors[i]));
			}
            _state = SmartDebtState.Closed;

        }else {
            if (_state == SmartDebtState.InvestorsTransferredFunds) {
                _state = SmartDebtState.IssuerStartedRepayments;
            }
        }

        emit RepayTokens(_issuer, _capexmoveChildToken.getInvestors(address(this))[0], amount_);

        return true;
    }

    function getTotalCapexmoveChildTokensToRepay()  public view returns (uint) {
        return _totalCapexmoveChildTokensToRepay;
    }

    function getTotalCapexmoveChildTokensRepaid()  public view returns (uint) {
        return _totalCapexmoveChildTokensRepaid;
    }

    function getPaymentsCount() public view returns (uint) {
        return _paymentsCount;
    }

    function getPayment(uint ind) public view returns (Payment memory) {
        return _payments[ind];
    }

    function getPaymentAmount(uint ind) public view returns (uint256) {
        return _payments[ind].amount;
    }

    function getPaymentTimestamp(uint ind) public view returns (uint) {
        return _payments[ind].timestamp;
    }

    function getState() public view returns (SmartDebtState) {
        return _state;
    }

    event LendTokens(address indexed _investor, uint256 _amountInCapexmoveChildToken);

	// TODO
	event BondActivated(address indexed _issuer);

    event RepayTokens(address indexed _issuer, address indexed _investor, uint256 _amountInCapexmoveChildToken);
}