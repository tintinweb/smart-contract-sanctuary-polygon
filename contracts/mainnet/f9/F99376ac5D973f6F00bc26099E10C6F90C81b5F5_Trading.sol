//TODO add events

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./utils/MetaContext.sol";
import "./interfaces/ITrading.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPairsContract.sol";
import "./interfaces/IPosition.sol";
import "./interfaces/IGovNFT.sol";
import "./interfaces/IStableVault.sol";
import "./interfaces/INativeStableVault.sol";
import "./utils/TradingLibrary.sol";


interface IStable is IERC20 {
    function burnFrom(address account, uint amount) external;
    function mintFor(address account, uint amount) external;
}

interface ExtendedIERC20 is IERC20 {
    function decimals() external view returns (uint);
}

interface ERC20Permit is IERC20 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract Trading is MetaContext, ITrading {
    mapping(address => bool) private nodeProvided; // Used for TradingLibrary

    uint256 constant private DIVISION_CONSTANT = 10000; // 100%
    address constant private eth = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    uint public daoFees; // 0.1%
    uint public burnFees; // 0%
    uint public referralFees; // 0.01%
    uint public botFees; // 0.02%
    uint public maxGasPrice = 1000000000000; // 1000 gwei
    mapping(address => uint) public minPositionSize;
    uint public liqPercent = 9000; // Default 90%
    uint public maxWinPercent;

    bool public paused;

    bool public chainlinkEnabled;

    mapping(address => bool) public allowedMargin;

    IPairsContract public pairsContract;
    IPosition public position;
    IGovNFT public gov;

    mapping(address => bool) private isNode;
    uint256 public validSignatureTimer;
    uint256 public minNodeCount;

    mapping(uint => uint) public blockDelayPassed; // id => block.number
    uint public blockDelay;

    constructor(
        address _position,
        address _gov,
        address _pairsContract
    )
    {
        position = IPosition(_position);
        gov = IGovNFT(_gov);
        pairsContract = IPairsContract(_pairsContract);
    }



    // ===== END-USER FUNCTIONS =====

    /**
     * @param _tradeInfo Trade info
     * @param _priceData verifiable off-chain data
     * @param _signature node signature
     * @param _permitData data and signature needed for token approval
     */
    function initiateMarketOrder(
        TradeInfo calldata _tradeInfo,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature,
        ERC20PermitData calldata _permitData
    )
        external payable
    {
        _checkDelay(position.getCount());
        address _tigAsset = IStableVault(_tradeInfo.stableVault).stable();
        validateTrade(_tradeInfo.asset, _tigAsset, _tradeInfo.margin, _tradeInfo.leverage);
        _handleDeposit(_tigAsset, _tradeInfo.marginAsset, _tradeInfo.margin, _tradeInfo.stableVault, _permitData);
        uint256 _price = TradingLibrary.verifyAndCreatePrice(minNodeCount, validSignatureTimer, chainlinkEnabled, pairsContract.idToAsset(_tradeInfo.asset).chainlinkFeed, _priceData, _signature, nodeProvided, isNode);
        _setReferral(_tradeInfo.referral);
        uint256 margin = _handleOpenFees(_tradeInfo.asset, _tradeInfo.margin, _tigAsset, _tradeInfo.leverage, _msgSender());
        _checkSl(_tradeInfo.slPrice, _tradeInfo.direction, _price);
        if (_tradeInfo.direction) {
            pairsContract.modifyLongOi(_tradeInfo.asset, _tigAsset, true, margin*_tradeInfo.leverage/1e18);
        } else {
            pairsContract.modifyShortOi(_tradeInfo.asset, _tigAsset, true, margin*_tradeInfo.leverage/1e18);
        }
        updateFunding(_tradeInfo.asset, _tigAsset);
        position.mint(
            IPosition.MintTrade(
                _msgSender(),
                margin,
                _tradeInfo.leverage,
                _tradeInfo.asset,
                _tradeInfo.direction,
                _price,
                _tradeInfo.tpPrice,
                _tradeInfo.slPrice,
                0,
                _tigAsset
            )
        );
        emit PositionOpened(_tradeInfo, _msgSender(), _price, margin, position.getCount()-1);
    }

    /**
     * @dev initiate closing position
     * @param _id id of the position NFT
     * @param _percent percent of the position being closed in BP
     * @param _priceData verifiable off-chain data
     * @param _signature node signature
     * @param _stableVault StableVault address
     * @param _outputToken Token received upon closing trade
     */
    function initiateCloseOrder(
        uint _id,
        uint _percent,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature,
        address _stableVault,
        address _outputToken
    )
        external
    {
        _checkDelay(_id);
        _checkOwner(_id);
        IPosition.Trade memory _trade = position.trades(_id);
        require(_trade.orderType == 0, "Limit");        
        uint256 _price = TradingLibrary.verifyAndCreatePrice(minNodeCount, validSignatureTimer, chainlinkEnabled, pairsContract.idToAsset(_trade.asset).chainlinkFeed, _priceData, _signature, nodeProvided, isNode);
        require(_percent <= DIVISION_CONSTANT && _percent > 0, "Bad%");
        _closePosition(_id, _percent, _price, _stableVault, _outputToken); 
    }

    function initiateLimitOrder(
        TradeInfo calldata _tradeInfo,
        uint256 _orderType, // 1 limit, 2 momentum
        uint256 _price,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature,  
        ERC20PermitData calldata _permitData
    )
        external payable
    {
        _checkDelay(position.getCount());
        if (_orderType == 2) {
            uint _assetPrice = TradingLibrary.verifyAndCreatePrice(minNodeCount, validSignatureTimer, chainlinkEnabled, pairsContract.idToAsset(_tradeInfo.asset).chainlinkFeed, _priceData, _signature, nodeProvided, isNode);
            if (_tradeInfo.direction) {
                require(_price >= _assetPrice, "BadBuyStop");
            } else {
                require(_price <= _assetPrice, "BadSellStop");
            }
        }
        address _tigAsset = IStableVault(_tradeInfo.stableVault).stable();
        validateTrade(_tradeInfo.asset, _tigAsset, _tradeInfo.margin, _tradeInfo.leverage);
        require(_orderType > 0, "!Limit");
        require(_price > 0, "!Price");
        _handleDeposit(_tigAsset, _tradeInfo.marginAsset, _tradeInfo.margin, _tradeInfo.stableVault, _permitData);
        _checkSl(_tradeInfo.slPrice, _tradeInfo.direction, _price);
        _setReferral(_tradeInfo.referral);
        position.mint(
            IPosition.MintTrade(
                _msgSender(),
                _tradeInfo.margin,
                _tradeInfo.leverage,
                _tradeInfo.asset,
                _tradeInfo.direction,
                _price,
                _tradeInfo.tpPrice,
                _tradeInfo.slPrice,
                _orderType,
                _tigAsset
            )
        );
        emit PositionOpened(_tradeInfo, _msgSender(), _price, _tradeInfo.margin, position.getCount() - 1);
    }

    function cancelLimitOrder(
        uint256 _id
    )
        external
    {
        _checkDelay(_id);
        _checkOwner(_id);
        IPosition.Trade memory trade = position.trades(_id);
        IStable(trade.tigAsset).mintFor(_msgSender(), trade.margin);
        position.burn(_id);
        emit LimitCancelled(_id);
    }

    function addMargin(
        uint256 _id,
        uint256 _addMargin,
        address _marginAsset,
        address _stableVault,
        ERC20PermitData calldata _permitData
    )
        external payable
    {
        unchecked {
            _checkDelay(_id);
            _checkOwner(_id);
            IPosition.Trade memory _trade = position.trades(_id);
            IPairsContract.Asset memory asset = pairsContract.idToAsset(_trade.asset);
            uint256 _positionSize = _trade.margin * _trade.leverage / 1e18;
            uint256 _newMargin = _trade.margin + _addMargin;
            uint256 _newLeverage = _positionSize * 1e18 / _newMargin;
            require(_newLeverage >= asset.minLeverage, "<minLev");
            _handleDeposit(_trade.tigAsset, _marginAsset, _addMargin, _stableVault, _permitData);
            position.modifyMargin(_id, _newMargin, _newLeverage);
            emit MarginAdded(_id, _newMargin);
        }
    }

    function updateTpSl(
        bool _type, // true is TP
        uint _id,
        uint _limitPrice,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature
    )
        external
    {
        _checkOwner(_id);
        IPosition.Trade memory _trade = position.trades(_id);
        require(_trade.orderType == 0, "!updateLimit");
        if (_type) {
            position.modifyTp(_id, _limitPrice);
        } else {
            uint256 _price = TradingLibrary.verifyAndCreatePrice(minNodeCount, validSignatureTimer, chainlinkEnabled, pairsContract.idToAsset(_trade.asset).chainlinkFeed, _priceData, _signature, nodeProvided, isNode);
            _checkSl(_limitPrice, _trade.direction, _price);
            position.modifySl(_id, _limitPrice);
        }
        emit UpdateTPSL(_id, _type, _limitPrice);
    }

    function executeLimitOrder(
        uint _id, 
        PriceData[] calldata _priceData,
        bytes[] calldata _signature
    ) 
        external
    {
        _checkDelay(_id);
        _checkGas();
        require(!paused, "Paused");
        IPosition.Trade memory trade = position.trades(_id);
        uint256 _price = TradingLibrary.verifyAndCreatePrice(minNodeCount, validSignatureTimer, chainlinkEnabled, pairsContract.idToAsset(trade.asset).chainlinkFeed, _priceData, _signature, nodeProvided, isNode);
        require(trade.orderType != 0, "!execOpen");
        if (trade.direction && trade.orderType == 1) {
            require(trade.price >= _price, "BL");
        } else if (!trade.direction && trade.orderType == 1) {
            require(trade.price <= _price, "SL");      
        } else if (!trade.direction && trade.orderType == 2) {
            require(trade.price >= _price, "SS");
        } else {
            require(trade.price <= _price, "BS");
        }
        uint256 _newMargin = _handleOpenFees(trade.asset, trade.margin, trade.tigAsset, trade.leverage, trade.trader);
        if (trade.direction) {
            pairsContract.modifyLongOi(trade.asset, trade.tigAsset, true, _newMargin*trade.leverage/1e18);
        } else {
            pairsContract.modifyShortOi(trade.asset, trade.tigAsset, true, _newMargin*trade.leverage/1e18);
        }
        updateFunding(trade.asset, trade.tigAsset);
        position.executeLimitOrder(_id, trade.price, _newMargin);
        emit LimitOrderExecuted(trade.asset, trade.trader, trade.direction, _price, trade.leverage, _newMargin, _id);
    }

    /**
     * @dev liquidate position
     * @param _id id of the position NFT
     * @param _priceData verifiable off-chain data
     * @param _signature node signature
     */
    function liquidatePosition(
        uint _id,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature
    )
        external
    {
        unchecked{
            _checkGas();
            IPosition.Trade memory _trade = position.trades(_id);
            uint256 _price = TradingLibrary.verifyAndCreatePrice(minNodeCount, validSignatureTimer, chainlinkEnabled, pairsContract.idToAsset(_trade.asset).chainlinkFeed, _priceData, _signature, nodeProvided, isNode);
            require(_trade.orderType == 0, "!liqLimit");
            (,int256 _payout) = TradingLibrary.pnl(_trade.direction, _price, _trade.price, _trade.margin, _trade.leverage, _trade.accInterest);
            require(_payout <= int256(_trade.margin*(DIVISION_CONSTANT-liqPercent)/DIVISION_CONSTANT), "!liq");
            if (_trade.direction) {
                pairsContract.modifyLongOi(_trade.asset, _trade.tigAsset, false, _trade.margin*_trade.leverage/1e18);
            } else {
                pairsContract.modifyShortOi(_trade.asset, _trade.tigAsset, false, _trade.margin*_trade.leverage/1e18);
            }
            updateFunding(_trade.asset, _trade.tigAsset);
            IStable(_trade.tigAsset).mintFor(_msgSender(), ((_trade.margin*_trade.leverage/1e18)*pairsContract.idToAsset(_trade.asset).feeMultiplier/DIVISION_CONSTANT)*botFees/DIVISION_CONSTANT);
            position.burn(_id);
            emit PositionLiquidated(_id);
        }
    }

    /**
     * @dev close position at a pre-set price
     * @param _id id of the position NFT
     * @param _tp true if take profit
     * @param _priceData verifiable off-chain data
     * @param _signature node signature
     */
    function limitClose(
        uint _id,
        bool _tp,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature
    )
        external
    {
        _checkDelay(_id);
        _checkGas();
        IPosition.Trade memory _trade = position.trades(_id);
        uint256 _price = TradingLibrary.verifyAndCreatePrice(minNodeCount, validSignatureTimer, chainlinkEnabled, pairsContract.idToAsset(_trade.asset).chainlinkFeed, _priceData, _signature, nodeProvided, isNode);
        require(_trade.orderType == 0, "!closeLimit");
        uint _limitPrice;
        if (_tp) {
            require(_trade.tpPrice != 0, "!TP");
            if(_trade.direction) {
                require(_trade.tpPrice <= _price, "LTP");
            } else {
                require(_trade.tpPrice >= _price, "STP");
            }
            _limitPrice = _trade.tpPrice;
        } else {
            require(_trade.slPrice != 0, "!SL");
            if(_trade.direction) {
                require(_trade.slPrice >= _price, "LSL");
            } else {
                require(_trade.slPrice <= _price, "SSL");
            }
            _limitPrice = _trade.slPrice;
        }
        _closePosition(_id, DIVISION_CONSTANT, _limitPrice, address(0), _trade.tigAsset);
    }



    // ===== INTERNAL FUNCTIONS =====

    /**
     * @dev close the initiated position.
     * @param _id id of the position NFT
     * @param _percent percent of the position being closed in BP
     * @param _price asset price
     * @param _stableVault StableVault address
     * @param _outputToken Token that trader will receive
     */
    function _closePosition(
        uint _id,
        uint _percent,
        uint _price,
        address _stableVault,
        address _outputToken
    )
        internal
    {
        IPosition.Trade memory _trade = position.trades(_id);
        (int256 _positionSize, int256 _payout) = TradingLibrary.pnl(_trade.direction, _price, _trade.price, _trade.margin, _trade.leverage, _trade.accInterest);
        if (_trade.direction) {
            pairsContract.modifyLongOi(_trade.asset, _trade.tigAsset, false, (_trade.margin*_trade.leverage/1e18)*_percent/DIVISION_CONSTANT);
        } else {
            pairsContract.modifyShortOi(_trade.asset, _trade.tigAsset, false, (_trade.margin*_trade.leverage/1e18)*_percent/DIVISION_CONSTANT);     
        }
        position.setAccInterest(_id);
        updateFunding(_trade.asset, _trade.tigAsset);
        if (_percent < DIVISION_CONSTANT) {
            position.reducePosition(_id, _percent);
        } else {
            position.burn(_id);
        }
        uint256 _toMint;
        if (_payout > 0) {
            _toMint = _handleCloseFees(_trade.asset, uint256(_payout)*_percent/DIVISION_CONSTANT, _trade.tigAsset, uint256(_positionSize)*_percent/DIVISION_CONSTANT, _trade.trader);
            if (maxWinPercent > 0 && _toMint > _trade.margin*maxWinPercent/DIVISION_CONSTANT) {
                _toMint = _trade.margin*maxWinPercent/DIVISION_CONSTANT;
            }
            IStable(_trade.tigAsset).mintFor(address(this), _toMint);
            if (_outputToken == _trade.tigAsset) {
                IERC20(_outputToken).transfer(_trade.trader, _toMint);
            } else {
                if (_outputToken != eth) {
                    uint256 _balBefore = IERC20(_outputToken).balanceOf(address(this));
                    IStableVault(_stableVault).withdraw(_outputToken, _toMint);
                    require(IERC20(_outputToken).balanceOf(address(this)) == _balBefore + _toMint/(10**(18-ExtendedIERC20(_outputToken).decimals())), "BadWithdraw");
                    IERC20(_outputToken).transfer(_trade.trader, IERC20(_outputToken).balanceOf(address(this)) - _balBefore);          
                } else {
                    uint256 _balBefore = address(this).balance;
                    try INativeStableVault(_stableVault).withdrawNative(_toMint) {} catch {
                        revert("!VaultNativeSupport");
                    }
                    require(address(this).balance == _balBefore + _toMint, "BadNativeWithdraw");
                    payable(_msgSender()).transfer(address(this).balance - _balBefore);
                }
            }
        }
        emit PositionClosed(_id, _price, _percent, _toMint);
    }

    /**
     * @dev handle fees distribution and margin size after fees for opening
     * @param _asset asset id
     * @param _margin margin
     * @param _tigAsset margin asset
     * @param _leverage leverage
     * @param _trader trader address
     * @return _afterFees margin after fees
     */
    function _handleOpenFees(
        uint _asset,
        uint _margin,
        address _tigAsset,
        uint _leverage,
        address _trader
    )
        internal
        returns (uint256 _afterFees)
    {
        IPairsContract.Asset memory asset = pairsContract.idToAsset(_asset);
        uint[4] memory _fees = [ // Avoids stack too deep error
            daoFees*asset.feeMultiplier/DIVISION_CONSTANT,
            burnFees*asset.feeMultiplier/DIVISION_CONSTANT,
            referralFees*asset.feeMultiplier/DIVISION_CONSTANT,
            botFees*asset.feeMultiplier/DIVISION_CONSTANT
        ];
        if (pairsContract.getReferral(pairsContract.getReferred(_trader)) != address(0)) {
            IStable(_tigAsset).mintFor(
                pairsContract.getReferral(pairsContract.getReferred(_trader)),
                (_margin * _leverage / 1e18)
                * _fees[2] // get referral fee%
                / DIVISION_CONSTANT // divide by 100%
            );
            _fees[0] = _fees[0] - _fees[2];
        }
        if (_trader != _msgSender()) {
            IStable(_tigAsset).mintFor(
                _msgSender(),
                (_margin * _leverage / 1e18)
                * _fees[3] // get bot fee%
                / DIVISION_CONSTANT // divide by 100%
            );
            _fees[0] = _fees[0] - _fees[3];
        } else {
            _fees[3] = 0;
        }
        _afterFees =
            _margin - ( // subtract position size fees from margin
                (_margin * _leverage / 1e18)
                * (_fees[0] + _fees[1] + _fees[3]) // get total fee%
                / DIVISION_CONSTANT // divide by 100%
            );
        uint _daoFeesPaid = (_margin * _leverage / 1e18) * (_fees[0]) / DIVISION_CONSTANT;
        IStable(_tigAsset).mintFor(address(this), _daoFeesPaid);
        gov.distribute(_tigAsset, IStable(_tigAsset).balanceOf(address(this)));
    }

    /**
     * @dev handle fees distribution after closing
     * @param _asset asset id
     * @param _payout payout to trader before fees
     * @param _tigAsset margin asset
     * @param _positionSize position size + pnl
     * @param _trader trader address
     * @return payout_ payout to trader after fees
     */
    function _handleCloseFees(
        uint _asset,
        uint _payout,
        address _tigAsset,
        uint _positionSize,
        address _trader
    )
        internal
        returns (uint payout_)
    {
        IPairsContract.Asset memory asset = pairsContract.idToAsset(_asset);
        uint _daoFeesPaid = (_positionSize*daoFees/DIVISION_CONSTANT)*asset.feeMultiplier/DIVISION_CONSTANT;
        uint _burnFeesPaid = (_positionSize*burnFees/DIVISION_CONSTANT)*asset.feeMultiplier/DIVISION_CONSTANT;
        uint _referralFeesPaid = (_positionSize*referralFees/DIVISION_CONSTANT)*asset.feeMultiplier/DIVISION_CONSTANT;
        uint _botFeesPaid;
        address _referrer = pairsContract.getReferral(pairsContract.getReferred(_trader));
        if (_referrer != address(0)) {
            IStable(_tigAsset).mintFor(
                _referrer,
                _referralFeesPaid
            );
            _daoFeesPaid = _daoFeesPaid-_referralFeesPaid;
        }
        if (_trader != _msgSender()) {
            _botFeesPaid = (_positionSize*botFees/DIVISION_CONSTANT)*asset.feeMultiplier/DIVISION_CONSTANT;
            IStable(_tigAsset).mintFor(
                _msgSender(),
                _botFeesPaid
            );
            _daoFeesPaid = _daoFeesPaid - _botFeesPaid;
        }
        payout_ = _payout - _daoFeesPaid - _burnFeesPaid - _botFeesPaid;
        IStable(_tigAsset).mintFor(address(this), _daoFeesPaid);
        gov.distribute(_tigAsset, _daoFeesPaid);
        return payout_;
    }

    function _handleDeposit(address _tigAsset, address _marginAsset, uint256 _margin, address _stableVault, ERC20PermitData calldata _permitData) internal {
        IStable tigAsset = IStable(_tigAsset);
        if (_tigAsset != _marginAsset) {
            if (msg.value > 0) {
                require(_marginAsset == eth, "NativeDeposit");
            } else {
                if (_permitData.usePermit) {
                    ERC20Permit(_marginAsset).permit(_msgSender(), address(this), _permitData.amount, _permitData.deadline, _permitData.v, _permitData.r, _permitData.s);
                }
            }
            uint256 _balBefore = tigAsset.balanceOf(address(this));
            if (_marginAsset != eth){
                IERC20(_marginAsset).transferFrom(_msgSender(), address(this), _margin);
                IERC20(_marginAsset).approve(_stableVault, type(uint256).max);
                IStableVault(_stableVault).deposit(_marginAsset, _margin);
                require(tigAsset.balanceOf(address(this)) == _balBefore + _margin*(10**(18-ExtendedIERC20(_marginAsset).decimals())), "BadDeposit");
                tigAsset.burnFrom(address(this), tigAsset.balanceOf(address(this)));
            } else {
                require(msg.value == _margin, "msg.value != margin");
                try INativeStableVault(_stableVault).depositNative{value: _margin}() {} catch {
                    revert("!VaultNativeSupport");
                }
                require(tigAsset.balanceOf(address(this)) == _balBefore + _margin, "BadNativeDeposit");
                tigAsset.burnFrom(address(this), _margin);
            }
        } else {
            tigAsset.burnFrom(_msgSender(), _margin);
        }        
    }

    function updateFunding(uint256 _asset, address _tigAsset) internal {
        position.updateFunding(
            _asset,
            _tigAsset,
            pairsContract.idToOi(_asset, _tigAsset).longOi,
            pairsContract.idToOi(_asset, _tigAsset).shortOi,
            pairsContract.idToAsset(_asset).baseFundingRate
        );
    }

    function _setReferral(bytes32 _referral) internal {
        if (_referral != bytes32(0)) {
            if (pairsContract.getReferral(_referral) != address(0)) {
                if (pairsContract.getReferred(_msgSender()) == bytes32(0)) {
                    pairsContract.setReferred(_msgSender(), _referral);
                }
            }
        }
    }

    /**
     * @dev validates the inputs of trades
     * @param _asset asset id
     * @param _tigAsset margin asset
     * @param _margin margin
     * @param _leverage leverage
     */
    function validateTrade(uint _asset, address _tigAsset, uint _margin, uint _leverage) internal view {
        IPairsContract.Asset memory asset = pairsContract.idToAsset(_asset);
        require(allowedMargin[_tigAsset], "!Margin");
        require(!paused, "Paused");
        require(pairsContract.allowedAsset(_asset), "!Asset");
        require(_leverage >= asset.minLeverage && _leverage <= asset.maxLeverage, "BadLev");
        require(_margin*_leverage/1e18 >= minPositionSize[_tigAsset], "<minPos");
    }

    function _checkSl(uint _sl, bool _direction, uint _price) internal pure {
        if (_direction) {
            require (_sl <= _price, "BadLSL");
        } else {
            require (_sl >= _price || _sl == 0, "BadSSL");
        }
    }

    function _checkOwner(uint _id) internal view {
        require(position.ownerOf(_id) == _msgSender(), "!Owner");    
    }

    function _checkGas() internal view {
        require(tx.gasprice <= maxGasPrice, "gas!");    
    }

    function _checkDelay(uint _id) internal {
        unchecked {
            require(block.number >= blockDelayPassed[_id], "Wait");
            blockDelayPassed[_id] = block.number + blockDelay;            
        }
    }



    // ===== GOVERNANCE-ONLY =====

    /**
     * @notice in blocks not seconds
     */
    function setBlockDelay(
        uint _blockDelay
    )
        external
        onlyOwner
    {
        blockDelay = _blockDelay;
    }

    function setLiqPercent(
        uint _liqPercent
    )
        external
        onlyOwner
    {
        require(_liqPercent <= DIVISION_CONSTANT && _liqPercent >= 5000);
        liqPercent = _liqPercent;
    }

    function setMaxWinPercent(
        uint _maxWinPercent
    )
        external
        onlyOwner
    {
        require(_maxWinPercent >= 50000 || _maxWinPercent == 0);
        maxWinPercent = _maxWinPercent;
    }

    function setValidSignatureTimer(
        uint _validSignatureTimer
    )
        external
        onlyOwner
    {
        require(_validSignatureTimer > 0);
        validSignatureTimer = _validSignatureTimer;
    }

    function setMinNodeCount(
        uint _minNodeCount
    )
        external
        onlyOwner
    {
        require(_minNodeCount > 0);
        minNodeCount = _minNodeCount;
    }

    /**
     * @dev Allows a tigAsset to be used
     * @param _tigAsset tigAsset
     * @param _bool bool
     */
    function setAllowedMargin(
        address _tigAsset,
        bool _bool
    ) 
        external
        onlyOwner
    {
        allowedMargin[_tigAsset] = _bool;
        IStable(_tigAsset).approve(address(gov), type(uint).max);
    }

    /**
     * @dev changes the minimum position size
     * @param _tigAsset tigAsset
     * @param _min minimum position size 18 decimals
     */
    function setMinPositionSize(
        address _tigAsset,
        uint _min
    ) 
        external
        onlyOwner
    {
        minPositionSize[_tigAsset] = _min;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function setMaxGasPrice(uint _maxGasPrice) external onlyOwner {
        maxGasPrice = _maxGasPrice;
    }

    /**
     * @dev Sets the fees for the trading protocol
     * @param _daoFees Fees distributed to the DAO
     * @param _burnFees Fees which get burned
     * @param _referralFees Fees given to referrers
     * @param _botFees Fees given to bots that execute limit orders
     */
    function setFees(uint _daoFees, uint _burnFees, uint _referralFees, uint _botFees) external onlyOwner {
        unchecked {
            require(_daoFees >= _botFees+_referralFees);
            daoFees = _daoFees;
            burnFees = _burnFees;
            referralFees = _referralFees;
            botFees = _botFees;
        }
    }

    /**
     * @dev whitelists a node
     * @param _node node address
     * @param _bool bool
     */
    function setNode(address _node, bool _bool) external onlyOwner {
        isNode[_node] = _bool;
    }

    function setChainlinkEnabled(bool _bool) external onlyOwner {
        chainlinkEnabled = _bool;
    }

    // ===== EVENTS =====

    event PositionOpened(
        TradeInfo _tradeInfo,
        address _trader,
        uint _price,
        uint _marginAfterFees,
        uint _id
    );

    event PositionClosed(
        uint _id,
        uint _closePrice,
        uint _percent,
        uint _payout
    );

    event PositionLiquidated(
        uint _id
    );

    event LimitOrderExecuted(
        uint _asset,
        address _trader,
        bool _direction,
        uint _openPrice,
        uint _lev,
        uint _margin,
        uint _id
    );

    event UpdateTPSL(
        uint _id,
        bool _isTp,
        uint _price
    );

    event LimitCancelled(
        uint _id
    );

    event MarginAdded(
        uint _id,
        uint _newMargin
    );

    receive() external payable {}

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaContext is Ownable {
    mapping(address => bool) private _isTrustedForwarder;

    function setTrustedForwarder(address _forwarder, bool _bool) external onlyOwner {
        _isTrustedForwarder[_forwarder] = _bool;
    }

    function isTrustedForwarder(address _forwarder) external view returns (bool) {
        return _isTrustedForwarder[_forwarder];
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (_isTrustedForwarder[msg.sender]) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (_isTrustedForwarder[msg.sender]) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT

import "../utils/TradingLibrary.sol";

pragma solidity ^0.8.0;

interface ITrading {

    struct TradeInfo {
        uint256 margin;
        address marginAsset;
        address stableVault;
        uint256 leverage;
        uint256 asset;
        bool direction;
        uint256 tpPrice;
        uint256 slPrice;
        bytes32 referral;
    }

    struct ERC20PermitData {
        uint256 deadline;
        uint256 amount;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bool usePermit;
    }

    function initiateMarketOrder(
        TradeInfo calldata _tradeInfo,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature,
        ERC20PermitData calldata _permitData
    ) external payable;

    function initiateCloseOrder(
        uint _id,
        uint _percent,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature,
        address _stableVault,
        address _outputToken
    ) external;

    function initiateLimitOrder(
        TradeInfo calldata _tradeInfo,
        uint256 _orderType, // 1 limit, 2 momentum
        uint256 _price,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature,
        ERC20PermitData calldata _permitData
    ) external payable;

    function cancelLimitOrder(
        uint256 _id
    ) external;

    function addMargin(
        uint256 _id,
        uint256 _addMargin,
        address _marginAsset,
        address _stableVault,
        ERC20PermitData calldata _permitData
    ) external payable;

    function updateTpSl(
        bool _type, // true is TP
        uint _id,
        uint _limitPrice,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature
    ) external;

    function executeLimitOrder(
        uint _id, 
        PriceData[] calldata _priceData,
        bytes[] calldata _signature
    ) external;

    function liquidatePosition(
        uint _id,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature
    ) external;

    function limitClose(
        uint _id,
        bool _tp,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature
    ) external;

    function allowedMargin(address _tigAsset) external view returns (bool);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPairsContract {

    struct Asset {
        string name;
        address chainlinkFeed;
        uint256 minLeverage;
        uint256 maxLeverage;
        uint256 feeMultiplier;
        uint256 baseFundingRate;
    }

    struct OpenInterest {
        uint256 longOi;
        uint256 shortOi;
        uint256 maxOi;
    }

    function allowedAsset(uint) external view returns (bool);
    function idToAsset(uint256 _asset) external view returns (Asset memory);
    function idToOi(uint256 _asset, address _tigAsset) external view returns (OpenInterest memory);
    function setAssetBaseFundingRate(uint256 _asset, uint256 _baseFundingRate) external;
    function modifyLongOi(uint256 _asset, address _tigAsset, bool _onOpen, uint256 _amount) external;
    function modifyShortOi(uint256 _asset, address _tigAsset, bool _onOpen, uint256 _amount) external;

    function createReferralCode(bytes32 _hash) external;
    function setReferred(address _referredTrader, bytes32 _hash) external;
    function getReferred(address _trader) external view returns (bytes32);
    function getReferral(bytes32 _hash) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPosition {

    struct Trade {
        uint margin;
        uint leverage;
        uint asset;
        bool direction;
        uint price;
        uint tpPrice;
        uint slPrice;
        uint orderType;
        address trader;
        uint id;
        address tigAsset;
        int accInterest;
    }

    struct MintTrade {
        address account;
        uint256 margin;
        uint256 leverage;
        uint256 asset;
        bool direction;
        uint256 price;
        uint256 tp;
        uint256 sl;
        uint256 orderType;
        address tigAsset;
    }

    function trades(uint256) external view returns (Trade memory);
    function executeLimitOrder(uint256 _id, uint256 _price, uint256 _newMargin) external;
    function modifyMargin(uint256 _id, uint256 _newMargin, uint256 _newLeverage) external;
    function reducePosition(uint256 _id, uint256 _newMargin) external;
    function assetOpenPositions(uint256 _asset) external view returns (uint256[] calldata);
    function assetOpenPositionsIndexes(uint256 _asset, uint256 _id) external view returns (uint256);
    function limitOrders(uint256 _asset) external view returns (uint256[] memory);
    function limitOrderIndexes(uint256 _asset, uint256 _id) external view returns (uint256);
    function assetOpenPositionsLength(uint256 _asset) external view returns (uint256);
    function limitOrdersLength(uint256 _asset) external view returns (uint256);
    function ownerOf(uint _id) external view returns (address);
    function mint(MintTrade memory _mintTrade) external;
    function burn(uint _id) external;
    function modifyTp(uint _id, uint _tpPrice) external;
    function modifySl(uint _id, uint _slPrice) external;
    function getCount() external view returns (uint);
    function updateFunding(uint256 _asset, address _tigAsset, uint256 _longOi, uint256 _shortOi, uint256 _baseFundingRate) external;
    function setAccInterest(uint256 _id) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGovNFT {
    function distribute(address _tigAsset, uint _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStableVault {
    function deposit(address, uint) external;
    function withdraw(address, uint) external returns (uint256);
    function allowed(address) external view returns (bool);
    function stable() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INativeStableVault {
    function depositNative() external payable;
    function withdrawNative(uint256 _amount) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../interfaces/IPosition.sol";

interface IPrice {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint256);
}

struct PriceData {
    address provider;
    uint256 asset;
    uint256 price;
    uint256 timestamp;
    bool isClosed;
}

library TradingLibrary {

    using ECDSA for bytes32;

    function pnl(bool _direction, uint _currentPrice, uint _price, uint _margin, uint _leverage, int256 accInterest) external pure returns (int256 _positionSize, int256 _payout) {
        unchecked {
            if (_direction && _currentPrice >= _price) {
                _payout = int256(_margin) + int256(_margin * _leverage * (1e18 * _currentPrice / _price - 1e18)/1e18**2) + accInterest;
                _positionSize = int256(_margin * _leverage / 1e18) + int256(_margin * _leverage * (1e18 * _currentPrice / _price - 1e18)/1e18**2) + accInterest;
            } else if (_direction && _currentPrice < _price) {
                _payout = int256(_margin) - int256(_margin * _leverage * (1e18 - 1e18 * _currentPrice / _price)/1e18**2) + accInterest;
                _positionSize = int256(_margin * _leverage / 1e18) - int256(_margin * _leverage * (1e18 - 1e18 * _currentPrice / _price)/1e18**2) + accInterest;
            } else if (!_direction && _currentPrice <= _price) {
                _payout = int256(_margin) + int256(_margin * _leverage * (1e18 - 1e18 * _currentPrice / _price)/1e18**2) + accInterest;
                _positionSize = int256(_margin * _leverage / 1e18) + int256(_margin * _leverage * (1e18 - 1e18 * _currentPrice / _price)/1e18**2) + accInterest;
            } else {
                _payout = int256(_margin) - int256(_margin * _leverage * (1e18 * _currentPrice / _price - 1e18)/1e18**2) + accInterest;
                _positionSize = int256(_margin * _leverage / 1e18) - int256(_margin * _leverage * (1e18 * _currentPrice / _price - 1e18)/1e18**2) + accInterest;
            }
        }
    }

    function liqPrice(bool _direction, uint _tradePrice, uint _leverage, uint _margin, int _accInterest, uint _liqPercent) public pure returns (uint256 _liqPrice) {
        if (_direction) {
            _liqPrice = _tradePrice - ((_tradePrice*1e18/_leverage) * uint(int(_margin)+_accInterest) / _margin) * _liqPercent / 10000;
        } else {
            _liqPrice = _tradePrice + ((_tradePrice*1e18/_leverage) * uint(int(_margin)+_accInterest) / _margin) * _liqPercent / 10000;
        }
    }

    function getLiqPrice(address _positions, uint _id, uint _liqPercent) external view returns (uint256) {
        IPosition.Trade memory _trade = IPosition(_positions).trades(_id);
        return liqPrice(_trade.direction, _trade.price, _trade.leverage, _trade.margin, _trade.accInterest, _liqPercent);
    }

    function verifyAndCreatePrice(
        uint256 _minNodeCount,
        uint256 _validSignatureTimer,
        bool _chainlinkEnabled,
        address _chainlinkFeed,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature,        
        mapping(address => bool) storage _nodeProvided,
        mapping(address => bool) storage _isNode
    )
        external returns (uint256)
    {
        unchecked {
            uint256 _length = _signature.length;
            require(_priceData.length == _length, "length");
            require(_length >= _minNodeCount, "minNode");
            address[] memory _nodes = new address[](_length);
            uint256[] memory _prices = new uint256[](_length);
            for (uint256 i=0; i<_length; i++) {
                address _provider = (
                    keccak256(abi.encode(_priceData[i]))
                ).toEthSignedMessageHash().recover(_signature[i]);
                require(_provider == _priceData[i].provider, "BadSig");
                require(_isNode[_provider], "!Node");
                _nodes[i] = _provider;
                require(_nodeProvided[_provider] == false, "NodeP");
                _nodeProvided[_provider] = true;
                require(!_priceData[i].isClosed, "Closed");
                require(block.timestamp >= _priceData[i].timestamp, "FutSig");
                require(block.timestamp <= _priceData[i].timestamp + _validSignatureTimer, "ExpSig");
                require(_priceData[i].price > 0, "NoPrice");
                _prices[i] = _priceData[i].price;
            }
            uint256 _price = median(_prices);
            if (_chainlinkEnabled && _chainlinkFeed != address(0)) {
                int256 assetChainlinkPriceInt = IPrice(_chainlinkFeed).latestAnswer();
                if (assetChainlinkPriceInt != 0) {
                    uint256 assetChainlinkPrice = uint256(assetChainlinkPriceInt) * 10**(18 - IPrice(_chainlinkFeed).decimals());
                    require(
                        _price < assetChainlinkPrice+assetChainlinkPrice*2/100 &&
                        _price > assetChainlinkPrice-assetChainlinkPrice*2/100, "!chainlinkPrice"
                    );
                }
            }
            for (uint i=0; i<_length; i++) {
                delete _nodeProvided[_nodes[i]];
            }            
            return _price;            
        }
    }

    /**
     * @dev Gets the median value from an array
     * @param array array of unsigned integers to get the median from
     * @return median value from the array
     */
    function median(uint[] memory array) private pure returns(uint) {
        unchecked {
            sort(array, 0, array.length);
            return array.length % 2 == 0 ? (array[array.length/2-1]+array[array.length/2])/2 : array[array.length/2];            
        }
    }

    function swap(uint[] memory array, uint i, uint j) private pure { 
        (array[i], array[j]) = (array[j], array[i]); 
    }

    function sort(uint[] memory array, uint begin, uint end) private pure {
        unchecked {
            if (begin >= end) { return; }
            uint j = begin;
            uint pivot = array[j];
            for (uint i = begin + 1; i < end; ++i) {
                if (array[i] < pivot) {
                    swap(array, i, ++j);
                }
            }
            swap(array, begin, j);
            sort(array, begin, j);
            sort(array, j + 1, end);            
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}