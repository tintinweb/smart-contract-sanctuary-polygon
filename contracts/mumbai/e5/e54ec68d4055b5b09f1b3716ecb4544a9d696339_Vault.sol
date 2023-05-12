// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./IERC721.sol";
import "./IERC20.sol";

import "./IOracle.sol";
import "./IStablecoin.sol";
import "./ILendingMarket.sol";
import "./IERC6065.sol";

contract Vault is ERC721, ERC721TokenReceiver, ILendingMarket {

	IStablecoin public STABLECOIN;
	IERC6065 public UNDERLYINGNFT;
	IOracle public ORACLE;
	address public LIQUIDATOR;
	address public GOVERNANCE;
	address public INTERESTRECEIVER;

	VaultSettings public SETTINGS;

	// for off-chain debt on asset, these are the ONLY tokens that are implemented for debtAmt
	// this contract treats all these as interchangable with $1
	address public immutable USDC;
	uint256 public constant USDC_decimals = 1e6;
	address public immutable USDT;
	uint256 public constant USDT_decimals = 1e6;
	address public immutable DAI;
	uint256 public constant DAI_decimals = 1e18;

	uint256 public constant KUSD_decimals = 1e6;

	// Global debt tracking variables
	uint256 public TOTALDEBTAMT; // total debt amt in system
	uint256 public TOTALDEBTACCRUEAT; // last timestamp debt was accrue() at
	uint256 public TOTALDEBTPORTION; // total debt portion, denominator of user specific portion -> Position.debtPortion

	struct VaultSettings {
		Rate debtInterest;
		Rate ltvMax;
		Rate liquidationCushion;
		Rate stablecoinInterestPortion;
		uint256 totalDebtCap;
		uint256 maxCallbackTime;
		uint256 maxValuation;
	}

	struct Rate {
		uint128 numerator;
		uint128 denominator;
	}

	struct Position {
		uint256 value;
		Rate ltvMax;
		uint256 debtPrincipal;
		uint256 debtPortion;
		address liquidator;
	}

	struct CallbackInfo {
		uint256 nftId;
		uint256 timestampInit;
		address oracle;
	}

	mapping(uint256 => Position) public POSITIONS;
	mapping(bytes32 => CallbackInfo) public CALLBACKS;

	event PositionOpened(address user, uint256 nftId, bytes32 chainlinkCallbackId);
	event CallbackError(bytes32 callback, uint256 nftId, bytes error);
	event CallbackSuccess(bytes32 callback, uint256 nftId, uint256 value, Rate ltvMax);
	event Borrowed(address nftOwner, uint256 nftId, uint256 borrowAmt, uint256 priorDebtAmt, uint256 newDebtAmt);
	event Repaid(address caller, address nftOwner, uint256 nftId, uint256 repaidAmt, uint256 priorDebtAmt, uint256 newDebtAmt);
	event PositionClosed(address nftOwner, uint256 nftId, uint256 repaidAmt);
	event Liquidated(address nftOwner, uint256 nftId, address liquidator, uint256 debtOwed, uint256 debtLimit);
	event LiquidationResolved(address nftOwner, uint256 nftId, address liquidator, uint256 finalDebtOwed, uint256 amtLiquidatedFor, int256 stablecoinHolderEarnings);

	constructor (
		address _underlyingNft, 
		address _stablecoin, 
		address _liquidator,
		address _oracle, 
		address _interestReceiver,
		address _usdc,
		address _usdt,
		address _dai,
		VaultSettings memory _settings
		) ERC721("Name This Position Token", "POS.TOK"){
		// TODO: name this ^^^^^^
		// TODO: reentrancy guard for re-enter attacks?

		UNDERLYINGNFT = IERC6065(_underlyingNft);
		STABLECOIN = IStablecoin(_stablecoin);
		LIQUIDATOR = _liquidator;
		ORACLE = IOracle(_oracle);

		_validateSettings(_settings);
		SETTINGS = _settings;

		GOVERNANCE = msg.sender;
		INTERESTRECEIVER = _interestReceiver;
		USDC = _usdc;
		USDT = _usdt;
		DAI = _dai;

		TOTALDEBTACCRUEAT = block.timestamp;
	}

	function _validateSettings(VaultSettings memory _settings) internal pure {
		Rate memory _10pct = Rate(10, 100);
		require(_rateFirstGtRateSecond(_10pct, _settings.debtInterest), "interest > 10%");

		Rate memory _90pct = Rate(90, 100);
		require(_rateFirstGtRateSecond(_90pct, _settings.ltvMax), "ltvMax > 90%");

		Rate memory _105pct = Rate(105, 100);
		Rate memory _100pct = Rate(100, 100);
		require(_rateFirstGtRateSecond(_105pct, _settings.liquidationCushion) && _rateFirstGtRateSecond(_settings.liquidationCushion, _100pct), "!(100% < liquidationCushion < 105%)");
	
		require(_rateFirstGtRateSecond(_100pct, _settings.stablecoinInterestPortion) || _settings.stablecoinInterestPortion.numerator == _settings.stablecoinInterestPortion.denominator, "stablecoinInterestPortion > 100%");

		require(_settings.maxCallbackTime >= 1 hours, "maxCallbackTime < 1 hour");
	}

	function tokenURI(uint256 _nftId) public view override returns (string memory){
		// TODO: implement for metadata of position NFT
	}

	///////////////
	// MODIFIERS //
	///////////////

	// ownerOf(_nftId) also asserts that this NFT exists
	modifier onlyPositionOwner(uint256 _nftId) {
		require(msg.sender == ownerOf(_nftId), "NOT_POS_OWNER");
		_;
	}

	modifier onlyGovernance(){
		require(msg.sender == GOVERNANCE, "NOT_GOVERNANCE");
		_;
	}

	/////////////
	// SETTERS //
	/////////////

	function setGovernance(address _new) external onlyGovernance {
		GOVERNANCE = _new;
	}

	function setInterestReceiver(address _new) external onlyGovernance {
		INTERESTRECEIVER = _new;
	}

	function setTotalDebtCap(uint256 _new) external onlyGovernance {
		SETTINGS.totalDebtCap = _new;
	}

	function setMaxValuation(uint256 _new) external onlyGovernance {
		SETTINGS.maxValuation = _new;
	}

	function setLiquidator(address _new) external onlyGovernance {
		LIQUIDATOR = _new;
	}

	function setOracle(address _new) external onlyGovernance {
		ORACLE = IOracle(_new);
	}

	/////////////////
	// VAULT LOGIC //
	/////////////////

	function accrueInterest() public {
		uint256 _newInterest = _calculateNewInterest();

        TOTALDEBTACCRUEAT = block.timestamp;
        TOTALDEBTAMT += _newInterest;

        uint256 _stablecoinInterest = _newInterest * SETTINGS.stablecoinInterestPortion.numerator / SETTINGS.stablecoinInterestPortion.denominator;
        uint256 _daoInterest = _newInterest - _stablecoinInterest;
        if (_stablecoinInterest != 0) STABLECOIN.rebase(int256(_stablecoinInterest));
       	if (_daoInterest != 0) STABLECOIN.mint(INTERESTRECEIVER, _daoInterest);
	}

	// issue a ERC721 NFT for anyone that opens a position on this vault
	// this NFT is like a derivative "positions NFT" which allow you to transfer your position around and then reclaim it later
	function openPosition(uint256 _nftId, address _paymentToken) external returns(bytes32){
		accrueInterest();

		_mint(msg.sender, _nftId); // mint a position NFT with the same nftId as deposited NFT
		UNDERLYINGNFT.transferFrom(msg.sender, address(this), _nftId);

		// charge initial fee, charging for Oracle call price
		uint256 _paymentAmt = ORACLE.getPayment(_paymentToken);
		require(_paymentAmt != 0, "invalid payment token");
		IERC20(_paymentToken).transferFrom(msg.sender, address(this), _paymentAmt);
		IERC20(_paymentToken).approve(address(ORACLE), _paymentAmt);

		bytes32 _callback = ORACLE.getPriceAndRisk(address(UNDERLYINGNFT), _nftId, _paymentToken);
		CallbackInfo memory _callbackInfo = CallbackInfo(_nftId, block.timestamp, address(ORACLE));
		CALLBACKS[_callback] = _callbackInfo;

		emit PositionOpened(msg.sender, _nftId, _callback);
		return _callback;
	}

	function callbackOracle(bytes32 _requestId, bytes memory _response, bytes memory _err) external {
		CallbackInfo memory _callbackInfo = CALLBACKS[_requestId];
		require(msg.sender == _callbackInfo.oracle, "!oracle");

		if (_err.length != 0){
			emit CallbackError(_requestId, _callbackInfo.nftId, _err);
		}
		else if (_callbackInfo.timestampInit == 0){
			emit CallbackError(_requestId, _callbackInfo.nftId, bytes("CALLBACK_ALREADY_RETURNED"));
		}
		else if (_callbackInfo.timestampInit + SETTINGS.maxCallbackTime < block.timestamp){
			emit CallbackError(_requestId, _callbackInfo.nftId, bytes("CALLBACK_TOO_LATE"));
		}
		else if (ownerOf(_callbackInfo.nftId) == address(0)){
			emit CallbackError(_requestId, _callbackInfo.nftId, bytes("COLLATERAL_WITHDRAWN"));
		}
		else if (_response.length != 64){
			emit CallbackError(_requestId, _callbackInfo.nftId, bytes("RESPONSE_NOT_UINT256,UINT256"));
		}
		else {
			Position memory _position = POSITIONS[_callbackInfo.nftId];

			if (_position.debtPrincipal != 0 || _position.debtPortion != 0 || _position.liquidator != address(0)){
				emit CallbackError(_requestId, _callbackInfo.nftId, bytes("LOAN_ALREADY_EXIST"));
			}
			else {
				uint256 _valueInDollars;
				uint256 _ltvBasisPts;
				(_valueInDollars, _ltvBasisPts) = abi.decode(_response, (uint256, uint256));
				Rate memory _ltvMax = Rate(uint128(_ltvBasisPts), 10000);

				uint256 _value = _valueInDollars * KUSD_decimals;

				// NOTE: error here if the value is too high. maxValue will need to be raised by governance
				if (_value > SETTINGS.maxValuation){
					emit CallbackError(_requestId, _callbackInfo.nftId, bytes("VALUE_EXCEED_MAX"));
				}
				else {
					Rate memory _maxAllowedLtv = SETTINGS.ltvMax;
					if (_rateFirstGtRateSecond(_ltvMax, _maxAllowedLtv)) _ltvMax = _maxAllowedLtv;

					_position.value = _value;
					_position.ltvMax = _ltvMax;

					POSITIONS[_callbackInfo.nftId] = _position;

					emit CallbackSuccess(_requestId, _callbackInfo.nftId, _value, _ltvMax);
				}
			}
		}

		delete CALLBACKS[_requestId];
	}

	function borrow(uint256 _nftId, uint256 _amt) external onlyPositionOwner(_nftId) {
		accrueInterest();

		Position memory _position = POSITIONS[_nftId];

		require(_amt != 0, "ZERO_AMT");
		require(SETTINGS.totalDebtCap >= TOTALDEBTAMT + _amt, "EXCEED_VAULT_DEBT_LIMIT");
		require(_position.liquidator == address(0), "POS_LIQUIDATED");

		uint256 _debtLimit = _getDebtLimit(_position, _adjustValue(_position.value, _nftId, false));
		uint256 _debtOwed = _getDebtAmt(_position);

		require(_debtLimit >= _debtOwed + _amt, "EXCEED_POS_DEBT_LIMIT"); // proposed debt exceed LTV ratio

		uint256 _totalDebtPortion = TOTALDEBTPORTION;
		uint256 _totalDebtAmt = TOTALDEBTAMT;
		if (_totalDebtPortion == 0){ // first loan for vault || all prior loans repaid
			TOTALDEBTPORTION = _amt;
			_position.debtPortion = _amt;
		}
		else {
			// math: initialize the "total debt portion" at _amt of first loan, and users debt position as _amt of first loan
			// on next loans: user debt portion == (total debt portion * new loan amt) / total debt amt
			// (remember: total debt amt gets incremented when accrueInterest() )
			// the "portion" is the underlying "shares" amount. every user owns some share of the debt
			// the "total debt amt" gets increased by the yearly interest rate, but the users shares just calculate on the fly. 
			uint256 _newUserDebtPortion = (_totalDebtPortion * _amt) / _totalDebtAmt;

			TOTALDEBTPORTION = _totalDebtPortion + _newUserDebtPortion;
			_position.debtPortion += _newUserDebtPortion;
		}
		_position.debtPrincipal += _amt;
		TOTALDEBTAMT = _totalDebtAmt + _amt;

		POSITIONS[_nftId] = _position;

		// NOTE: to add a borrow fee, just refrain from sending to user here, and send somewhere else
		STABLECOIN.mint(msg.sender, _amt); 

		emit Borrowed(msg.sender, _nftId, _amt, _debtOwed, _getDebtAmt(_position));
	}

	function repay(uint256 _nftId, uint256 _amt) external {
		accrueInterest();
		_repay(_nftId, _amt);
	}

	function _repay(uint256 _nftId, uint256 _amt) internal { 
		require(_amt != 0, "zero repay amt");

		Position memory _position = POSITIONS[_nftId];
		require(_position.liquidator == address(0), "POS_LIQUIDATED");

		uint256 _debtOwed = _getDebtAmt(_position);
		require(_debtOwed != 0, "no debt exists");

		uint256 _principal = _position.debtPrincipal;
		uint256 _interest = _debtOwed - _principal;

		_amt = _amt > _debtOwed ? _debtOwed : _amt;

		STABLECOIN.transferFrom(msg.sender, address(this), _amt);
		STABLECOIN.burn(_amt);
		
		uint256 _totalDebtAmt = TOTALDEBTAMT;
		uint256 _totalDebtPortion = TOTALDEBTPORTION;
		uint256 _paidPrincipal = _amt > _interest ? _amt - _interest : 0;
		uint256 _paidPortion = _amt == _debtOwed ? _position.debtPortion : (_totalDebtPortion * _amt) / _totalDebtAmt;

		TOTALDEBTAMT = _totalDebtAmt - _amt;
		TOTALDEBTPORTION = _totalDebtPortion - _paidPortion;

		_position.debtPortion -= _paidPortion;
		_position.debtPrincipal -= _paidPrincipal;

		POSITIONS[_nftId] = _position;

		emit Repaid(msg.sender, ownerOf(_nftId), _nftId, _amt, _debtOwed, _getDebtAmt(_position));
	}

	function closePosition(uint256 _nftId) external onlyPositionOwner(_nftId) {
		accrueInterest();

		Position memory _position = POSITIONS[_nftId];
		require(_position.liquidator == address(0), "POS_LIQUIDATED");

		uint256 _debtOwed = _getDebtAmt(_position);
		if (_debtOwed != 0){
			_repay(_nftId, _debtOwed); //  will error if they don't have enough STABLECOIN in wallet to repay all debt
		}

		delete POSITIONS[_nftId];
		_burn(_nftId); // burn position NFT
		UNDERLYINGNFT.transferFrom(address(this), msg.sender, _nftId);

		emit PositionClosed(msg.sender, _nftId, _debtOwed);
	}

	function liquidate(uint256 _nftId) external returns(ILendingMarket.LiquidationParams memory){
		require(msg.sender == LIQUIDATOR, "NOT_LIQUIDATOR");
		accrueInterest();

		Position memory _position = POSITIONS[_nftId];
		uint256 _debtOwed = _getDebtAmt(_position);
		uint256 _debtLimit = _getDebtLimit(_position, _adjustValue(_position.value, _nftId, true));
		uint256 _liqLimit = _debtLimit * SETTINGS.liquidationCushion.numerator / SETTINGS.liquidationCushion.denominator;
		require(_debtOwed > _liqLimit, "DEBT_LTEQ_LIQ_LIMIT");
		require(_position.liquidator == address(0), "POS_LIQUIDATED");

		POSITIONS[_nftId].liquidator = msg.sender;
		UNDERLYINGNFT.transferFrom(address(this), msg.sender, _nftId);

		emit Liquidated(ownerOf(_nftId), _nftId, msg.sender, _debtOwed, _debtLimit);
		return ILendingMarket.LiquidationParams(address(UNDERLYINGNFT), _nftId, _position.value);
	}

	function resolveLiquidation(uint256 _nftId, uint256 _amtSoldFor) external {
		accrueInterest();

		Position memory _position = POSITIONS[_nftId];
		require(msg.sender == _position.liquidator, "NOT_LIQUIDATOR"); // not msg.sender == LIQUIDATOR because liquidator contract can change

		uint256 _debt = _getDebtAmt(_position);
		TOTALDEBTAMT -= _debt;
		TOTALDEBTPORTION -= _position.debtPortion;
		int256 _difference = int256(_amtSoldFor) - int256(_debt);
		STABLECOIN.rebase(_difference); // stablecoin holders either earn, or pay for the difference

		delete POSITIONS[_nftId];
		address _owner = ownerOf(_nftId);
		_burn(_nftId);

		emit LiquidationResolved(_owner, _nftId, msg.sender, _debt, _amtSoldFor, _difference);
	}

	////////////////////////////////////////////
	///// DEBT AND INTEREST MATH FUNCTIONS /////
	////////////////////////////////////////////

	///////////////////////
	///// PUBLIC GETS /////
	///////////////////////

	function calculateNewInterest() external view returns(uint256) {
		return _calculateNewInterest();
	}

	// TODO: determine error if ownerOf == address(0)? -- either no position OR position token was sent to null address
	function debtLimitOf(uint256 _nftId) external view returns(uint256){
		Position memory _pos = POSITIONS[_nftId];
		return _getDebtLimit(_pos, _adjustValue(_pos.value, _nftId, false));
	}

	function liquidationLimitOf(uint256 _nftId) external view returns(uint256){
		Position memory _pos = POSITIONS[_nftId];
		uint256 _debtLimit = _getDebtLimit(_pos, _adjustValue(_pos.value, _nftId, true));
		return _debtLimit * SETTINGS.liquidationCushion.numerator / SETTINGS.liquidationCushion.denominator;
	}

	function debtOf(uint256 _nftId) external view returns(uint256){
		return _getDebtAmt(POSITIONS[_nftId]);
	}

	function adjustedValueOf(uint256 _nftId, bool _isForLiquidation) external view returns(uint256){
		return _adjustValue(POSITIONS[_nftId].value, _nftId, _isForLiquidation);
	}

	////////////////////////////
	///// ACTUAL FUNCTIONS /////
	////////////////////////////

	function _calculateNewInterest() internal view returns(uint256) {
		uint256 _elapsedTime = block.timestamp - TOTALDEBTACCRUEAT;
		if (_elapsedTime == 0) {
			return 0;
		}

		uint256 _totalDebt = TOTALDEBTAMT;
		if (_totalDebt == 0) {
			return 0;
		}

		return (_elapsedTime * _totalDebt * SETTINGS.debtInterest.numerator) / SETTINGS.debtInterest.denominator / 365 days;
	}

	// return maximum debt allowable on a token (LTV ratio for vault * value of NFT)
	function _getDebtLimit(Position memory _position, uint256 _adjustedValue) internal pure returns (uint256){
		return _adjustedValue * _position.ltvMax.numerator / _position.ltvMax.denominator;
	}

	// get current debt amt for a position
	function _getDebtAmt(Position memory _position) internal view returns (uint256){
		uint256 _tdp = TOTALDEBTPORTION;
		uint256 _calcDebt = _tdp == 0 ? 0 : (TOTALDEBTAMT * _position.debtPortion) / _tdp;

		// in case of rounding error for calculated debt, never return less debt than the principal (minimum of amt to repay)
		return _calcDebt < _position.debtPrincipal ? _position.debtPrincipal : _calcDebt;
	}

	// check the token for off-chain debt/foreclosure status -- this vault is ONLY compatible with USDC/USDT/DAI debts, and treats these debts as interchangeable with $1
	function _adjustValue(uint256 _assessedValue, uint256 _nftId, bool _isForLiquidation) internal view returns(uint256){
		address _debtToken;
		int256 _debtAmt;
		bool _foreclosed;
		(_debtToken, _debtAmt, _foreclosed) = UNDERLYINGNFT.debtOf(_nftId);

		if (_foreclosed) return 0;
		else if (_debtAmt > 0){
			if (_debtToken == USDC) return _assessedValue - uint256(_debtAmt) / (USDC_decimals / KUSD_decimals);
			else if (_debtToken == USDT) return _assessedValue - uint256(_debtAmt) / (USDT_decimals / KUSD_decimals);
			else if (_debtToken == DAI) return _assessedValue - uint256(_debtAmt) / (DAI_decimals / KUSD_decimals);
			// if this is for a liquidation, don't mark value as zero, disregard the debt entirely, if for a loan then mark collateral as ZERO
			else return _isForLiquidation ? _assessedValue : 0; 
		}
		else return _assessedValue;
	}

	// note: this only works cause all of these are uint, if signed denomonators we would need to modify
	function _rateFirstGtRateSecond(Rate memory _first, Rate memory _second) internal pure returns(bool){
		return _first.numerator * _second.denominator > _second.numerator * _first.denominator;
	}
}