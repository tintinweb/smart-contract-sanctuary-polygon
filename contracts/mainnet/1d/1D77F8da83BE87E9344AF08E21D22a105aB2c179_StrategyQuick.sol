// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

import "./Strategy.sol";
import "./interfaces/IDragonLair.sol";

contract StrategyQuick is Strategy {

    IDragonLair public constant D_QUICK = IDragonLair(0xf28164A485B0B2C90639E47b0f377b4a438a16B1);

    function _vaultHarvest() internal override {
        super._vaultHarvest();
        uint balance = D_QUICK.balanceOf(address(this));
        if (balance > 0) D_QUICK.leave(balance);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

import "./BaseStrategy.sol";
import "./MaximizerStrategy.sol";

//Standard v3 Strategy
contract Strategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using StrategyConfig for StrategyConfig.MemPointer;
    using Fee for Fee.Data[3];
    using VaultChonk for IVaultHealer;

    IStrategy immutable _maximizerImplementation;

    constructor() {
        _maximizerImplementation = _deployMaximizerImplementation();
	}

    function _deployMaximizerImplementation() internal virtual returns (IStrategy) {
        return new MaximizerStrategy();
    }

    function getMaximizerImplementation() external virtual override view returns (IStrategy) {
        return _maximizerImplementation;
    }

    function sellUnwanted(IERC20 tokenOut, uint amount) internal {
        IERC20[] memory path;
        bool toWeth;
        if (config.isPairStake()) {
            (IERC20 token0, IERC20 token1) = config.token0And1();
            (toWeth, path) = wethOnPath(tokenOut, token0);
            (bool toWethToken1,) = wethOnPath(tokenOut, token1);
            toWeth = toWeth && toWethToken1;
        } else {
            (toWeth, path) = wethOnPath(tokenOut, config.wantToken());
        }
        if (toWeth) safeSwap(amount, path); //swap to the native gas token if it's on the path
        else swapToWantToken(amount, tokenOut);
    }



    function _earn(Fee.Data[3] calldata fees, address, bytes calldata) internal virtual override returns (bool success, uint256 __wantLockedTotal) {
        _sync();        
        IERC20 _wantToken = config.wantToken();
		uint wantAmt = _wantToken.balanceOf(address(this)); 

        _vaultHarvest(); //Perform the harvest of earned reward tokens
        
        for (uint i; i < config.earnedLength(); i++) { //In case of multiple reward vaults, process each reward token
            (IERC20 earnedToken, uint dust) = config.earned(i);

            if (earnedToken != _wantToken) {
                uint256 earnedAmt = earnedToken.balanceOf(address(this));
                //don't waste gas swapping minuscule rewards
                if (earnedAmt > dust) sellUnwanted(earnedToken, earnedAmt);
            }
        }

        uint wantBalance = _wantToken.balanceOf(address(this));        
        if (wantBalance > config.wantDust()) {
            wantAmt = fees.payTokenFeePortion(_wantToken, wantBalance - wantAmt) + wantAmt; //fee portion on newly obtained want tokens
            success = true;
        }
        if (unwrapAllWeth()) {
            fees.payEthPortion(address(this).balance); //pays the fee portion
            uint wethAmt = address(this).balance;
            wrapAllEth();
            swapToWantToken(wethAmt, config.weth());
            success = true;
        }
        __wantLockedTotal = _wantToken.balanceOf(address(this)) + (success ? _farm() : _vaultSharesTotal());
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDragonLair is IERC20 {
    function enter(uint256 _quickAmount) external;
    
    function leave(uint256 _dQuickAmount) external;
    
    function QUICKBalance(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./libraries/StrategyConfig.sol";
import "./interfaces/IStrategy.sol";
import "./libraries/Fee.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./libraries/VaultChonk.sol";
import "./libraries/AddrCalc.sol";

abstract contract BaseStrategy is IStrategy, ERC165 {
    using SafeERC20 for IERC20;
    using StrategyConfig for StrategyConfig.MemPointer;
    using Fee for Fee.Data[3];

    uint constant FEE_MAX = 10000;
    uint16 constant CONFIG_POINTER = 0x200;
    StrategyConfig.MemPointer constant config = StrategyConfig.MemPointer.wrap(CONFIG_POINTER);
    IStrategy public immutable implementation;
    uint immutable WETH_DUST;
    uint constant LP_DUST = 2**16;
    IVaultHealer private _vaultHealer;

    constructor() {
        WETH_DUST = (block.chainid == 137 || block.chainid == 25) ? 1e18 : (block.chainid == 56 ? 1e16 : 1e14);
        implementation = this;
    }

    receive() external payable virtual { if (!Address.isContract(msg.sender)) revert Strategy_ImproperEthDeposit(msg.sender, msg.value); }

    //For VHv3.0 support. Returns the vaulthealer for a proxy; for an implementation, returns msg.sender to a contract or address(0) to an EOA
    function vaultHealer() external view returns (IVaultHealer) {
        return (implementation == this && msg.sender != tx.origin) ? IVaultHealer(msg.sender) : _vaultHealer;
    }

    modifier onlyVaultHealer { //must come after getConfig
        _requireVaultHealer();
        _;
    }
    function _requireVaultHealer() private view {
        //The address of this contract is a Cavendish create2 address with salt equal to the vid, and the VaultHealer is the deployer.
        //Address collisions are theoretically possible, but exceedingly rare. If one such false VaultHealer
        //address were calculated, it could not be used by anyone for the same reason that address(0) remains unclaimed.
        if (address(this) != Cavendish.computeAddress(bytes32(config.vid()), msg.sender)) revert Strategy_NotVaultHealer(msg.sender);
    }

    modifier getConfig() {
        if (implementation == this) revert Muppet(msg.sender);
        uint ptr = _getConfig();
        if (ptr != CONFIG_POINTER) revert Strategy_CriticalMemoryError(ptr);
        _;
    }

    function _getConfig() private view returns (uint ptr) {
        address configAddr = configAddress();
        assembly ("memory-safe") {
            let len := sub(extcodesize(configAddr), 1) //get length, subtracting 1 for the invalid opcode
            ptr := mload(0x40)
            if lt(ptr, CONFIG_POINTER) { ptr := CONFIG_POINTER }
            mstore(0x40, add(ptr, len)) //update free memory pointer
            extcodecopy(configAddr, ptr, 1, len) //get the data
        }
    }

    function initialize(bytes memory _config) external virtual {
        if (this == implementation) revert Strategy_InitializeOnlyByProxy();
        address configAddr;
        assembly ("memory-safe") {
            let len := mload(_config) //get length of config
            mstore(_config, 0x600c80380380823d39803df3fe) //simple bytecode which saves everything after the f3
            configAddr := create(0, add(_config, 19), add(len,13)) //0 value; send 13 bytes plus _config
        }
        if (configAddr != configAddress()) revert Strategy_AlreadyInitialized(); //also checks that create didn't fail

        _vaultHealer = IVaultHealer(msg.sender);
        this.initialize_(); //must be called by this contract externally

    }

    function initialize_() external getConfig {
        require(msg.sender == address(this));
        _initialSetup();
    }
    
    function _initialSetup() internal virtual {
        IERC20 want = config.wantToken();

        _vaultSharesTotal();

		want.safeIncreaseAllowance(address(_vaultHealer), type(uint256).max);

        if (_isMaximizer()) {

            (IERC20 targetWant,,,,,) = _vaultHealer.vaultInfo(config.targetVid());
            if (want != targetWant) {
                for (uint i; i < config.earnedLength(); i++) {
                    (IERC20 earned,) = config.earned(i);
                    if (earned == targetWant) {
                        earned.safeIncreaseAllowance(address(_vaultHealer), type(uint256).max);
                        break;
                    }
                }
            }
        }
    }

    //should only happen when this contract deposits as a maximizer
    function onERC1155Received(
        address operator, address from, uint256 id, uint256, bytes calldata) external view returns (bytes4) {
        if (operator != address(this)) revert Strategy_Improper1155Deposit(operator, from, id);
        return 0xf23a6e61;
    }

    //no batch transfer
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata, bytes calldata) external pure returns (bytes4) {
        revert Strategy_Improper1155BatchDeposit(operator, from, ids);
    }

    function panic() external getConfig onlyVaultHealer {
        _vaultEmergencyWithdraw();
    }
    function unpanic() external getConfig onlyVaultHealer { 
        _farm();
    }


    function router() external view getConfig returns (IUniRouter _router) { return config.router(); }
    function wantToken() external view getConfig returns (IERC20 _token) { return config.wantToken(); }
    function wantLockedTotal() external view getConfig returns (uint256) { return _wantLockedTotal(); }
    function _wantLockedTotal() internal view virtual returns (uint256) { return config.wantToken().balanceOf(address(this)) + _vaultSharesTotal(); }
    function configAddress() public view returns (address configAddr) { return AddrCalc.configAddress(); }

    modifier guardPrincipal {
        IERC20 _wantToken = config.wantToken();
        uint wantLockedBefore = _wantToken.balanceOf(address(this)) + _vaultSharesTotal();
        _;
        if (_wantToken.balanceOf(address(this)) + _vaultSharesTotal() < wantLockedBefore) revert Strategy_WantLockedLoss();
    }

    //Safely deposits want tokens in farm
    function _farm() internal virtual returns (uint256 vaultSharesAfter) {
        IERC20 _wantToken = config.wantToken();
        uint dust = config.wantDust();
        uint256 wantAmt = _wantToken.balanceOf(address(this));
        if (wantAmt < dust) return _vaultSharesTotal();
        
        uint256 sharesBefore = _vaultSharesTotal();
        _vaultDeposit(_wantToken, wantAmt); //approves the transfer then calls the pool contract to deposit
        vaultSharesAfter = _vaultSharesTotal();
        
        //safety check, will fail if there's a deposit fee rugpull or serious bug taking deposits
        if (vaultSharesAfter + _wantToken.balanceOf(address(this)) + dust < sharesBefore + wantAmt * config.slippageFactor() / 256)
            revert Strategy_ExcessiveFarmSlippage();
    }

    function safeSwap(
        uint256 _amountIn,
        IERC20 _tokenA,
        IERC20 _tokenB
    ) internal {
        if (_tokenA == _tokenB || _amountIn == 0) return; //Do nothing for one-token paths
        IERC20[] memory path = config.magnetite().findAndSavePath(address(config.router()), _tokenA, _tokenB);
        require(path[0] == _tokenA && path[path.length - 1] == _tokenB, "Strategy: received invalid path for swap");
        safeSwap(_amountIn, path);
    }

    //returns true if the path from A to B contains weth; if true, path from tokenA to weth
    //otherwise, path from tokenA to tokenB
    function wethOnPath(IERC20 _tokenA, IERC20 _tokenB) internal returns (bool containsWeth, IERC20[] memory path) {
        IERC20 weth = config.weth();
        if (_tokenA == weth) {
            path = new IERC20[](1);
            path[0] = weth;
            return (true, path);
        } else {
            path = config.magnetite().findAndSavePath(address(config.router()), _tokenA, _tokenB);
            if (_tokenB == weth) return (true, path);
            else {
                for (uint i = 1; i < path.length - 1; i++) {
                    if (path[i] == weth) {
                        assembly("memory-safe") { mstore(path, add(i,1)) } //truncate path at weth
                        return (true, path);
                    }
                }
            }
        }
    }

    function safeSwap(
        uint256 _amountIn,
        IERC20[] memory path
    ) internal virtual {
        if (_amountIn == 0 || path.length < 2) return;
        IUniRouter _router = config.router();
        IUniFactory factory = _router.factory();

        uint[] memory amounts = _router.getAmountsOut(_amountIn, path);
        IUniPair pair = factory.getPair(path[0], path[1]);
        path[0].safeTransfer(address(pair), _amountIn);
        
        if (config.feeOnTransfer()) {
            uint balanceBefore = path[path.length - 1].balanceOf(address(this));

            for (uint i = 1; i < path.length; i++) {
                (uint reserve0, uint reserve1,) = pair.getReserves();
                
                (uint amount0Out, uint amount1Out) = path[i - 1] < path[i] ? 
                    (uint(0), _router.getAmountOut(path[i - 1].balanceOf(address(pair)) - reserve0, reserve0, reserve1)) :
                    (_router.getAmountOut(path[i - 1].balanceOf(address(pair)) - reserve1, reserve1, reserve0), uint(0));

                if (i == path.length - 1) {
                    pair.swap(amount0Out, amount1Out, address(this), "");
                } else {
                    IUniPair nextPair = factory.getPair(path[i], path[i + 1]);
                    pair.swap(amount0Out, amount1Out, address(nextPair), "");
                    pair = nextPair;
                }
            }
            uint amountOutMin = amounts[amounts.length - 1] * config.slippageFactor() / 256;
            uint amountOutput = path[path.length - 1].balanceOf(address(this)) - balanceBefore;
            if (amountOutput < amountOutMin) revert InsufficientOutputAmount(amountOutput, amountOutMin);

        } else {
            
            for (uint i = 1; i < path.length; i++) {
                (uint amount0Out, uint amount1Out) = path[i - 1] < path[i] ? (uint(0), amounts[i]) : (amounts[i], uint(0));
                
                if (i == path.length - 1) {
                    pair.swap(amount0Out, amount1Out, address(this), "");
                } else {
                    IUniPair nextPair = factory.getPair(path[i], path[i + 1]);
                    pair.swap(amount0Out, amount1Out, address(nextPair), "");
                    pair = nextPair;
                }
            }
        }
    }

    function swapToWantToken(uint256 _amountIn, IERC20 _tokenA) internal {
        IERC20 want = config.wantToken();

        if (config.isPairStake()) {
            (IERC20 token0, IERC20 token1) = config.token0And1();

            if (block.timestamp % 2 == 0) {
                safeSwap(_amountIn / 2, _tokenA, token0);
                safeSwap(_amountIn / 2, _tokenA, token1);
            } else {
                safeSwap(_amountIn / 2, _tokenA, token1);
                safeSwap(_amountIn / 2, _tokenA, token0);            
            }

            mintPair(IUniPair(address(want)), token0, token1);
            
        } else {
            safeSwap(_amountIn, _tokenA, want);
        }
    }

    function mintPair(IUniPair pair, IERC20 token0, IERC20 token1) internal returns (uint liquidity) {
        (token0, token1) = token0 < token1 ? (token0, token1) : (token1, token0);
        pair.skim(address(this));
        
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));

        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        (uint amount0, uint amount1) = (balance0 * reserve1 < balance1 * reserve0) ?
            (balance0, balance0 * reserve1 / reserve0) :
            (balance1 * reserve0 / reserve1, balance1);

        if (amount0 * amount1 > 0) { //if both are nonzero
            token0.safeTransfer(address(pair), amount0);
            token1.safeTransfer(address(pair), amount1);
            liquidity = pair.mint(address(this));
            balance0 -= amount0;
            balance1 -= amount1;
        }

        if (balance0 > LP_DUST) {
            IERC20[] memory path = new IERC20[](2);
            (path[0], path[1]) = (token0, token1);
            safeSwap(balance0 / 3, path);
        } else if (balance1 > LP_DUST) {
            IERC20[] memory path = new IERC20[](2);
            (path[0], path[1]) = (token1, token0);
            safeSwap(balance1 / 3, path);
        }
    }

    function configInfo() external view getConfig returns (ConfigInfo memory info) {

        Tactics.TacticsA tacticsA = config.tacticsA();

        uint len = config.earnedLength();

        IERC20[] memory earned = new IERC20[](len);
        uint[] memory earnedDust = new uint[](len);
        for (uint i; i < len; i++) {
            (earned[i], earnedDust[i]) = config.earned(i);
        }

        info = ConfigInfo({
            vid: config.vid(),
            want: config.wantToken(),
            wantDust: config.wantDust(),
            masterchef: Tactics.masterchef(tacticsA),
            pid: Tactics.pid(tacticsA),
            _router: config.router(),
            _magnetite: config.magnetite(),
            earned: earned,
            earnedDust: earnedDust,
            slippageFactor: config.slippageFactor(),
            feeOnTransfer: config.feeOnTransfer()
        });
    }


    function tactics() external view getConfig returns (Tactics.TacticsA tacticsA, Tactics.TacticsB tacticsB) {
        (tacticsA, tacticsB) = config.tactics();
    }

    function isMaximizer() external view getConfig returns (bool) {
        return _isMaximizer();
    }

    //For IStrategy-conforming strategies who don't implement their own maximizers. Should revert if a strategy implementation
    //is incapable of supporting a maximizer.
    function getMaximizerImplementation() external virtual view returns (IStrategy) {
        revert Strategy_MaximizersNotSupported();
    }
    function _isMaximizer() internal virtual view returns (bool) { 
        assert(!config.isMaximizer());
        return false; 
    }

    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == type(IStrategy).interfaceId;
    }

    function vaultSharesTotal() external view getConfig returns (uint256) {
        return _vaultSharesTotal();
    }


    function _vaultSharesTotal() internal view virtual returns (uint256) {
        return Tactics.vaultSharesTotal(config.tacticsA());
    }
    function _vaultDeposit(IERC20 _wantToken, uint256 _amount) internal virtual {   
        //token allowance for the pool to pull the correct amount of funds only
        (Tactics.TacticsA tacticsA, Tactics.TacticsB tacticsB) = config.tactics();
        _wantToken.safeIncreaseAllowance(Tactics.masterchef(tacticsA), _amount);      
        Tactics.deposit(tacticsA, tacticsB, _amount);
    }
    function _vaultWithdraw(IERC20 /*_wantToken*/, uint256 _amount) internal virtual {
        (Tactics.TacticsA tacticsA, Tactics.TacticsB tacticsB) = config.tactics();
        Tactics.withdraw(tacticsA, tacticsB, _amount);
    }
    function _vaultHarvest() internal virtual {
        (Tactics.TacticsA tacticsA, Tactics.TacticsB tacticsB) = config.tactics();
        Tactics.harvest(tacticsA, tacticsB); // Harvest farm tokens
    }
    function _vaultEmergencyWithdraw() internal virtual {
        (Tactics.TacticsA tacticsA, Tactics.TacticsB tacticsB) = config.tactics();
        Tactics.emergencyVaultWithdraw(tacticsA, tacticsB);
    }

    function wrapAllEth() internal {
        if (address(this).balance > WETH_DUST) {
            config.weth().deposit{value: address(this).balance}();
        }
    }
    function unwrapAllWeth() internal returns (bool hasEth) {
        IWETH weth = config.weth();
        uint wethBal = weth.balanceOf(address(this));
        if (wethBal > WETH_DUST) {
            weth.withdraw(wethBal);
            return true;
        }
        return address(this).balance > WETH_DUST;
    }

    function _sync() internal virtual {}

    function earn(Fee.Data[3] calldata fees, address operator, bytes calldata data) external getConfig onlyVaultHealer guardPrincipal returns (bool success, uint256 __wantLockedTotal) {
        return _earn(fees, operator, data);
    }
    function _earn(Fee.Data[3] calldata fees, address operator, bytes calldata data) internal virtual returns (bool success, uint256 __wantLockedTotal);

    //VaultHealer calls this to add funds at a user's direction. VaultHealer manages the user shares
    function deposit(uint256 _wantAmt, uint256 _sharesTotal, bytes calldata) public virtual payable getConfig onlyVaultHealer returns (uint256 wantAdded, uint256 sharesAdded) {
        _sync();
        IERC20 _wantToken = config.wantToken();
        uint wantLockedBefore = _farm() + _wantToken.balanceOf(address(this));

        if (msg.value > 0) {
            IWETH weth = config.weth();
            weth.deposit{value: msg.value}();
            swapToWantToken(msg.value, weth);
        }

        //Before calling deposit here, the vaulthealer records how much the user deposits. Then with this
        //call, the strategy tells the vaulthealer to proceed with the transfer. This minimizes risk of
        //a rogue strategy 
        if (_wantAmt > 0) IVaultHealer(msg.sender).executePendingDeposit(address(this), uint192(_wantAmt));
        uint vaultSharesAfter = _farm(); //deposits the tokens in the pool
        // Proper deposit amount for tokens with fees, or vaults with deposit fees

        wantAdded = _wantToken.balanceOf(address(this)) + vaultSharesAfter - wantLockedBefore;
        sharesAdded = _sharesTotal == 0 ? wantAdded : Math.ceilDiv(wantAdded * _sharesTotal, wantLockedBefore);
        if (wantAdded < config.wantDust() || sharesAdded == 0) revert Strategy_DustDeposit(wantAdded);
    }


    //Correct logic to withdraw funds, based on share amounts provided by VaultHealer
    function withdraw(uint _wantAmt, uint _userShares, uint _sharesTotal, bytes calldata) public virtual getConfig onlyVaultHealer returns (uint sharesRemoved, uint wantAmt) {
        _sync();
        IERC20 _wantToken = config.wantToken();
        uint wantBal = _wantToken.balanceOf(address(this)); 
        uint wantLockedBefore = wantBal + _vaultSharesTotal();
        uint256 userWant = _userShares * wantLockedBefore / _sharesTotal; //User's balance, in want tokens
        
        // user requested all, very nearly all, or more than their balance, so withdraw all
        unchecked { //overflow is caught and handled in the second condition
            uint dust = config.wantDust();
            if (_wantAmt + dust > userWant || _wantAmt + dust < _wantAmt) {
				_wantAmt = userWant;
            }
        }

		uint withdrawSlippage;
        if (_wantAmt > wantBal) {
            uint toWithdraw = _wantAmt - wantBal;
            _vaultWithdraw(_wantToken, toWithdraw); //Withdraw from the masterchef, staking pool, etc.
            wantBal = _wantToken.balanceOf(address(this));
			uint wantLockedAfter = wantBal + _vaultSharesTotal();
			
			//Account for reflect, pool withdraw fee, etc; charge these to user
			withdrawSlippage = wantLockedAfter < wantLockedBefore ? wantLockedBefore - wantLockedAfter : 0;
		}
		
		//Calculate shares to remove
        sharesRemoved = (_wantAmt + withdrawSlippage) * _sharesTotal;
        sharesRemoved = Math.ceilDiv(sharesRemoved, wantLockedBefore);
		
        //Get final withdrawal amount
        if (sharesRemoved > _userShares) {
            sharesRemoved = _userShares;
        }
		wantAmt = sharesRemoved * wantLockedBefore / _sharesTotal;
        
        if (wantAmt <= withdrawSlippage) revert Strategy_TotalSlippageWithdrawal(); //nothing to withdraw after slippage
		
		wantAmt -= withdrawSlippage;
		if (wantAmt > wantBal) wantAmt = wantBal;
		
        return (sharesRemoved, wantAmt);

    }

    function generateConfig(
        Tactics.TacticsA _tacticsA,
        Tactics.TacticsB _tacticsB,
        address _wantToken,
        uint8 _wantDust,
        address _router,
        address _magnetite,
        uint8 _slippageFactor,
        bool _feeOnTransfer,
        address[] calldata _earned,
        uint8[] calldata _earnedDust
    ) external virtual view returns (bytes memory configData) {
        require(_earned.length > 0 && _earned.length < 0x20, "earned.length invalid");
        require(_earned.length == _earnedDust.length, "earned/dust length mismatch");
        uint8 vaultType = uint8(_earned.length);
        if (_feeOnTransfer) vaultType += 0x80;
        configData = abi.encodePacked(_tacticsA, _tacticsB, _wantToken, _wantDust, _router, _magnetite, _slippageFactor);
		
		IERC20 _targetWant = IERC20(_wantToken);

        //Look for LP tokens. If not, want must be a single-stake
        try IUniPair(address(_targetWant)).token0() returns (IERC20 _token0) {
            vaultType += 0x20;
            IERC20 _token1 = IUniPair(address(_targetWant)).token1();
            configData = abi.encodePacked(configData, vaultType, _token0, _token1);
        } catch { //if not LP, then single stake
            configData = abi.encodePacked(configData, vaultType);
        }

        for (uint i; i < _earned.length; i++) {
            configData = abi.encodePacked(configData, _earned[i], _earnedDust[i]);
        }

        configData = abi.encodePacked(configData, IUniRouter(_router).WETH());
    }

    function generateTactics(
        address _masterchef,
        uint24 pid, 
        uint8 vstReturnPosition, 
        bytes8 vstCode, //includes selector and encoded call format
        bytes8 depositCode, //includes selector and encoded call format
        bytes8 withdrawCode, //includes selector and encoded call format
        bytes8 harvestCode, //includes selector and encoded call format
        bytes8 emergencyCode//includes selector and encoded call format
    ) external virtual pure returns (Tactics.TacticsA tacticsA, Tactics.TacticsB tacticsB) {
        tacticsA = Tactics.TacticsA.wrap(bytes32(abi.encodePacked(bytes20(_masterchef),bytes3(pid),bytes1(vstReturnPosition),vstCode)));
        tacticsB = Tactics.TacticsB.wrap(bytes32(abi.encodePacked(depositCode, withdrawCode, harvestCode, emergencyCode)));
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

import "./BaseStrategy.sol";

//Standard v3 Maximizer Strategy
contract MaximizerStrategy is BaseStrategy {
    using StrategyConfig for StrategyConfig.MemPointer;
    using Fee for Fee.Data[3];

    function getMaximizerImplementation() external override view returns (IStrategy) {
        return implementation;
    }
    function _isMaximizer() internal override pure returns (bool) { 
        assert(config.isMaximizer());
        return true; 
    }

    function getTargetWant() internal view returns (IERC20 targetWant, uint dust, uint balance) {
        ConfigInfo memory targetConfig = VaultChonk.strat(IVaultHealer(msg.sender), config.vid() >> 16).configInfo();
		targetWant = targetConfig.want;
		dust = targetConfig.wantDust;
		balance = targetWant.balanceOf(address(this));
    }

    function _earn(Fee.Data[3] calldata fees, address, bytes calldata) internal virtual override returns (bool success, uint256 __wantLockedTotal) {
        _sync();
        (IERC20 targetWant, uint targetWantDust, uint targetWantAmt) = getTargetWant();

        _vaultHarvest(); //Perform the harvest of earned reward tokens
        
		IWETH weth = config.weth();
        for (uint i; i < config.earnedLength(); i++) { //Sell earned tokens
            (IERC20 earnedToken, uint dust) = config.earned(i);
            
            if (earnedToken != targetWant && earnedToken != weth) { //Don't sell targetWant tokens
                uint256 earnedAmt = earnedToken.balanceOf(address(this));
                if (earnedAmt > dust) { //Only swap if enough has been earned
                    safeSwap(earnedAmt, earnedToken, weth); //swap to the native gas token
                }
            }
        }

        uint targetWantBalance = targetWant.balanceOf(address(this));        
        if (targetWantBalance > targetWantDust) {
            targetWantAmt += fees.payTokenFeePortion(targetWant, targetWantBalance - targetWantAmt);
            success = true;
        }
        if (unwrapAllWeth()) {
            fees.payEthPortion(address(this).balance); //pays the fee portion
            success = true;
        }

        if (success) {
            
            try IVaultHealer(msg.sender).maximizerDeposit{value: address(this).balance}(config.vid(), targetWantAmt, "") {} //deposit the rest, and any targetWant tokens
            catch {  //compound want instead if maximizer doesn't work
                wrapAllEth();
                uint wethAmt = weth.balanceOf(address(this));
                if (wethAmt > WETH_DUST) {
                    swapToWantToken(wethAmt, weth);
                }
                if (targetWantAmt > targetWantDust) {
                    swapToWantToken(targetWantAmt, targetWant);
                }
                emit Strategy_MaximizerDepositFailure();
            }
        }

        __wantLockedTotal = config.wantToken().balanceOf(address(this)) + _farm();
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

import "./Tactics.sol";
import "../interfaces/IUniRouter.sol";
import "../interfaces/IMagnetite.sol";
import "../interfaces/IVaultHealer.sol";

library StrategyConfig {
    using StrategyConfig for MemPointer;
    
    type MemPointer is uint256;

    uint constant MASK_160 = 0x00ffffffffffffffffffffffffffffffffffffffff;

    function vid(MemPointer config) internal pure returns (uint256 _vid) {
        assembly ("memory-safe") {
            _vid := mload(config)
        }
    }
    function targetVid(MemPointer config) internal pure returns (uint256 _targetVid) {
        assembly ("memory-safe") {
            _targetVid := shr(0x10, mload(config))
        }
    }
    function isMaximizer(MemPointer config) internal pure returns (bool _isMaximizer) {
        assembly ("memory-safe") {
            _isMaximizer := gt(shr(0x10, mload(config)), 0)
        }
    }

    function tacticsA(MemPointer config) internal pure returns (Tactics.TacticsA _tacticsA) {
        assembly ("memory-safe") {
            _tacticsA := mload(add(0x20,config))
        }
    }

    function tactics(MemPointer config) internal pure returns (Tactics.TacticsA _tacticsA, Tactics.TacticsB _tacticsB) {
        assembly ("memory-safe") {
            _tacticsA := mload(add(0x20,config))
            _tacticsB := mload(add(config,0x40))
        }
    }
    function masterchef(MemPointer config) internal pure returns (address) {
        return Tactics.masterchef(tacticsA(config));
    }
    function wantToken(MemPointer config) internal pure returns (IERC20 want) {
        assembly ("memory-safe") {
            want := and(mload(add(config,0x54)), MASK_160)
        }
    }
    function wantDust(MemPointer config) internal pure returns (uint256 dust) {
        assembly ("memory-safe") {
            dust := shl(and(mload(add(config,0x55)), 0xff),1)
        }
    }
    function router(MemPointer config) internal pure returns (IUniRouter _router) {
        assembly ("memory-safe") {
            _router := and(mload(add(config,0x69)), MASK_160)
        }
    }
    function magnetite(MemPointer config) internal pure returns (IMagnetite _magnetite) {
        assembly ("memory-safe") {
            _magnetite := and(mload(add(config,0x7D)), MASK_160)
        }        
    }
    function slippageFactor(MemPointer config) internal pure returns (uint _factor) {
        assembly ("memory-safe") {
            _factor := and(mload(add(config,0x7E)), 0xff)
        }
    }
    function feeOnTransfer(MemPointer config) internal pure returns (bool _isFeeOnTransfer) {
        assembly ("memory-safe") {
            _isFeeOnTransfer := gt(and(mload(add(config,0x7F)), 0x80), 0)
        }
    }

    function isPairStake(MemPointer config) internal pure returns (bool _isPairStake) {
        assembly ("memory-safe") {
            _isPairStake := gt(and(mload(add(config,0x7F)), 0x20), 0)
        }
    }
    function earnedLength(MemPointer config) internal pure returns (uint _earnedLength) {
        assembly ("memory-safe") {
            _earnedLength := and(mload(add(config,0x7F)), 0x1f)
        }
    }
    function token0And1(MemPointer config) internal pure returns (IERC20 _token0, IERC20 _token1) {
        //assert(isPairStake(config));
        assembly ("memory-safe") {
            _token0 := and(mload(add(config,0x93)), MASK_160)
            _token1 := and(mload(add(config,0xA7)), MASK_160)
        }

    }
    function earned(MemPointer config, uint n) internal pure returns (IERC20 _earned, uint dust) {
        assert(n < earnedLength(config));
        bool pairStake = isPairStake(config);

        assembly ("memory-safe") {
            let offset := add(add(mul(n,0x15),0x93),config)
            if pairStake {
                offset := add(offset,0x28)
            }
            _earned := and(mload(offset), MASK_160)
            dust := shl(and(mload(add(offset,1)), 0xff) , 1)
        }
    }

    function earnedToken(MemPointer config, uint n) internal pure returns (IERC20 _earned) {
        assert(n < earnedLength(config));
        bool pairStake = isPairStake(config);

        assembly ("memory-safe") {
            let offset := add(add(mul(n,0x15),0x93),config)
            if pairStake {
                offset := add(offset,0x28)
            }
            _earned := and(mload(offset), MASK_160)
        }
    }
    function earnedDust(MemPointer config, uint n) internal pure returns (uint dust) {
        assert(n < earnedLength(config));
        bool pairStake = isPairStake(config);

        assembly ("memory-safe") {
            let offset := add(add(mul(n,0x15),0x94),config)
            if pairStake {
                offset := add(offset,0x28)
            }
            dust := shl(and(mload(offset), 0xff) , 1)
        }
    }

    function weth(MemPointer config) internal pure returns (IWETH _weth) {
        unchecked {
            uint offset = 0x93 + earnedLength(config) * 0x15;
            if (isPairStake(config)) offset += 0x28;
        
            assembly ("memory-safe") {
                _weth := and(mload(add(config,offset)), MASK_160)
            }
        }
    }

    function toConfig(bytes memory data) internal pure returns (MemPointer c) {
        assembly ("memory-safe") {
            c := add(data, 0x20)
        }
    }

    function configAddress(IStrategy strategy) internal pure returns (address configAddr) {
        assembly ("memory-safe") {
            mstore(0, or(0xd694000000000000000000000000000000000000000001000000000000000000, shl(80,strategy)))
            configAddr := and(MASK_160, keccak256(0, 23)) //create address, nonce 1
        }
    }

    function configInfo(IStrategy strategy) internal view returns (IStrategy.ConfigInfo memory info) {

        StrategyConfig.MemPointer config;
        address _configAddress = configAddress(strategy);

        assembly ("memory-safe") {
            config := mload(0x40)
            let size := extcodesize(_configAddress)
            if iszero(size) {
                mstore(0, "Strategy config does not exist")
                revert(0,0x20)
            }
            size := sub(size,1)
            extcodecopy(_configAddress, config, 1, size)
            mstore(0x40,add(config, size))
        }

        IERC20 want = config.wantToken();
        uint dust = config.wantDust();
        bytes32 _tacticsA = Tactics.TacticsA.unwrap(config.tacticsA());
        address _masterchef = address(bytes20(_tacticsA));
        uint24 pid = uint24(uint(_tacticsA) >> 72);

        uint len = config.earnedLength();

        IERC20[] memory _earned = new IERC20[](len);
        uint[] memory _earnedDust = new uint[](len);
        for (uint i; i < len; i++) {
            (_earned[i], _earnedDust[i]) = config.earned(i);
        }

        return IStrategy.ConfigInfo({
            vid: config.vid(),
            want: want,
            wantDust: dust,
            masterchef: _masterchef,
            pid: pid,
            _router: config.router(),
            _magnetite: config.magnetite(),
            earned: _earned,
            earnedDust: _earnedDust,
            slippageFactor: config.slippageFactor(),
            feeOnTransfer: config.feeOnTransfer()
        });
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IUniRouter.sol";
import "../libraries/Fee.sol";
import "../libraries/Tactics.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IMagnetite.sol";
import "./IVaultHealer.sol";

interface IStrategy is IERC165 {

    error Muppet(address caller); //1bfef483
    error IdenticalAddresses(IERC20 a, IERC20 b);
    error ZeroAddress();
    error InsufficientOutputAmount(uint amountOut, uint amountOutMin);
    error Strategy_CriticalMemoryError(uint ptr); //decbcfd4
    error Strategy_Improper1155Deposit(address operator, address from, uint id);
    error Strategy_Improper1155BatchDeposit(address operator, address from, uint[] ids);
    error Strategy_ImproperEthDeposit(address sender, uint amount);
    error Strategy_NotVaultHealer(address sender); //3da8f0c0
    error Strategy_InitializeOnlyByProxy(); //2ebab949
    error Strategy_ExcessiveFarmSlippage();
    error Strategy_WantLockedLoss();
	error Strategy_TotalSlippageWithdrawal(); //nothing to withdraw after slippage
	error Strategy_DustDeposit(uint256 wantAdded); //eaf3800a - Deposit amount is insignificant after slippage
    error Strategy_AlreadyInitialized();
    error Strategy_MaximizersNotSupported();

    event Strategy_MaximizerDepositFailure();

    function initialize (bytes calldata data) external;
    function wantToken() external view returns (IERC20); // Want address
    function wantLockedTotal() external view returns (uint256); // Total want tokens managed by strategy (vaultSharesTotal + want token balance)
	function vaultSharesTotal() external view returns (uint256); //Want tokens deposited in strategy's pool
    function earn(Fee.Data[3] memory fees, address _operator, bytes calldata _data) external returns (bool success, uint256 _wantLockedTotal); // Main want token compounding function
    
    function deposit(uint256 _wantAmt, uint256 _sharesTotal, bytes calldata _data) external payable returns (uint256 wantAdded, uint256 sharesAdded);
    function withdraw(uint256 _wantAmt, uint256 _userShares, uint256 _sharesTotal, bytes calldata _data) external returns (uint256 sharesRemoved, uint256 wantAmt);

    function panic() external;
    function unpanic() external;
    function router() external view returns (IUniRouter); // Univ2 router used by this strategy

    function vaultHealer() external view returns (IVaultHealer);
    function implementation() external view returns (IStrategy);
    function isMaximizer() external view returns (bool);
    function getMaximizerImplementation() external view returns (IStrategy);

    struct ConfigInfo {
        uint256 vid;
        IERC20 want;
        uint256 wantDust;
        address masterchef;
        uint pid;
        IUniRouter _router;
        IMagnetite _magnetite;
        IERC20[] earned;
        uint256[] earnedDust;
        uint slippageFactor;
        bool feeOnTransfer;
    }

    function configInfo() external view returns (ConfigInfo memory);
    function tactics() external view returns (Tactics.TacticsA tacticsA, Tactics.TacticsB tacticsB);
    
}

// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.14;

import "../interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library Fee {
    using Fee for Data;
    using Fee for Data[3];

    type Data is uint256;

    uint256 constant FEE_MAX = 3000; // 100 = 1% : basis points

    function rate(Data _fee) internal pure returns (uint16) {
        return uint16(Data.unwrap(_fee));
    }
    function receiver(Data _fee) internal pure returns (address) {
        return address(uint160(Data.unwrap(_fee) >> 16));
    }
    function receiverAndRate(Data _fee) internal pure returns (address, uint16) {
        uint fee = Data.unwrap(_fee);
        return (address(uint160(fee >> 16)), uint16(fee));
    }
    function create(address _receiver, uint16 _rate) internal pure returns (Data) {
        return Data.wrap((uint256(uint160(_receiver)) << 16) | _rate);
    }

    function totalRate(Data[3] calldata _fees) internal pure returns (uint16 total) {
        unchecked { //overflow is impossible if Fee.Data are valid
            total = uint16(Data.unwrap(_fees[0]) + Data.unwrap(_fees[1]) + Data.unwrap(_fees[2]));
            require(total <= FEE_MAX, "Max total fee of 30%");
        }
    }
    function check(Data[3] memory _fees, uint maxTotal) internal pure returns (uint16 total) {
        unchecked { //overflow is impossible if Fee.Data are valid
            total = uint16(Data.unwrap(_fees[0]) + Data.unwrap(_fees[1]) + Data.unwrap(_fees[2]));
            require(total <= maxTotal, "Max total fee exceeded");
        }
    }

    function getFeePortion(Data[3] calldata _fees, uint _amount) internal pure returns (uint amtPayable) {
        return _amount == 0 ? 0 : totalRate(_fees) * _amount;
    }

    //Token amount is all fees
    function payTokenFeeAll(Data[3] calldata _fees, IERC20 _token, uint _tokenAmt) internal {
        if (_tokenAmt == 0) return;
        uint feeTotalRate = totalRate(_fees);
        for (uint i; i < 3; i++) {
            (address _receiver, uint _rate) = Fee.receiverAndRate(_fees[i]);
            if (_receiver == address(0) || _rate == 0) break;
            SafeERC20.safeTransfer(_token, _receiver, _tokenAmt * _rate / feeTotalRate);
        }
    }
    //Amount includes fee and non-fee portions
    function payTokenFeePortion(Data[3] calldata _fees, IERC20 _token, uint _tokenAmt) internal returns (uint amtAfter) {
        if (_tokenAmt == 0) return 0;
        amtAfter = _tokenAmt;
        uint feeTotalRate = totalRate(_fees);
        uint feeTotalAmt = feeTotalRate * _tokenAmt / 10000;

        for (uint i; i < 3; i++) {
            (address _receiver, uint _rate) = Fee.receiverAndRate(_fees[i]);
            if (_receiver == address(0) || _rate == 0) break;
            uint amount = _tokenAmt * _rate / 10000;
            SafeERC20.safeTransfer(_token, _receiver, amount);
        }
        return _tokenAmt - feeTotalAmt;
    }

    //Use this if ethAmt is all fees
    function payEthAll(Data[3] calldata _fees, uint _ethAmt) internal {
        if (_ethAmt == 0) return;
        uint feeTotalRate = totalRate(_fees);
        for (uint i; i < 3; i++) {
            (address _receiver, uint _rate) = Fee.receiverAndRate(_fees[i]);
            if (_receiver == address(0) || _rate == 0) break;
            (bool success,) = _receiver.call{value: _ethAmt * _rate / feeTotalRate, gas: 0x40000}("");
            require(success, "Fee: Transfer failed");
        }
    }
    //Use this if ethAmt includes both fee and non-fee portions
    function payEthPortion(Data[3] calldata _fees, uint _ethAmt) internal returns (uint ethAfter) {
        ethAfter = _ethAmt;
        for (uint i; i < 3; i++) {
            (address _receiver, uint _rate) = Fee.receiverAndRate(_fees[i]);
            if (_receiver == address(0) || _rate == 0) break;
            uint amount = _ethAmt * _rate / 10000;
            (bool success,) = _receiver.call{value: amount, gas: 0x40000}("");
            require(success, "Fee: Transfer failed");
            ethAfter -= amount;
        }
    }
    function payWethPortion(Data[3] calldata _fees, IWETH weth, uint _wethAmt) internal returns (uint wethAfter) {
        uint feeTotalRate = totalRate(_fees);
        uint feeTotalAmt = feeTotalRate * _wethAmt / 10000;
        weth.withdraw(feeTotalAmt);
        for (uint i; i < 3; i++) {
            (address _receiver, uint _rate) = Fee.receiverAndRate(_fees[i]);
            if (_receiver == address(0) || _rate == 0) break;
            uint amount = _wethAmt * _rate / 10000;
            (bool success,) = _receiver.call{value: amount, gas: 0x40000}("");
            require(success, "Fee: Transfer failed");
        }
        return _wethAmt - feeTotalAmt;
    }

    function set(Data[3] storage _fees, address[3] memory _receivers, uint16[3] memory _rates) internal {

        uint feeTotal;
        for (uint i; i < 3; i++) {
            address _receiver = _receivers[i];
            uint16 _rate = _rates[i];
            require(_receiver != address(0) || _rate == 0, "Invalid treasury address");
            feeTotal += _rate;
            uint256 _fee = uint256(uint160(_receiver)) << 16 | _rate;
            _fees[i] = Data.wrap(_fee);
        }
        require(feeTotal <= 3000, "Max total fee of 30%");
    }

    function check(Data _fee, uint maxRate) internal pure { 
        (address _receiver, uint _rate) = _fee.receiverAndRate();
        if (_rate > 0) {
            require(_receiver != address(0), "Invalid treasury address");
            require(_rate <= maxRate, "Max withdraw fee exceeded");
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

import "../interfaces/IVaultHealer.sol";
import "../interfaces/IBoostPool.sol";
import "./Cavendish.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

library VaultChonk {
    using BitMaps for BitMaps.BitMap;

    event AddVault(uint indexed vid);
    event AddBoost(uint indexed boostid);

    function createVault(mapping(uint => IVaultHealer.VaultInfo) storage vaultInfo, uint vid, IStrategy _implementation, bytes calldata data) external {
        addVault(vaultInfo, vid, _implementation, data);
    }
	
    function createMaximizer(mapping(uint => IVaultHealer.VaultInfo) storage vaultInfo, uint targetVid, bytes calldata data) external returns (uint vid) {
		if (targetVid >= 2**208) revert IVaultHealer.MaximizerTooDeep(targetVid);
        IVaultHealer.VaultInfo storage targetVault = vaultInfo[targetVid];
        uint16 nonce = targetVault.numMaximizers + 1;
        vid = (targetVid << 16) | nonce;
        targetVault.numMaximizers = nonce;
        addVault(vaultInfo, vid, strat(targetVid).getMaximizerImplementation(), data);
    }

    function addVault(mapping(uint => IVaultHealer.VaultInfo) storage vaultInfo, uint256 vid, IStrategy implementation, bytes calldata data) private {
        //
        if (!implementation.supportsInterface(type(IStrategy).interfaceId) //doesn't support interface
            || implementation.implementation() != implementation //is proxy
        ) revert IVaultHealer.NotStrategyImpl(implementation);
        IVaultHealer implVaultHealer = implementation.vaultHealer();
        if (address(implVaultHealer) != address(this)) revert IVaultHealer.ImplWrongHealer(implVaultHealer);

        IStrategy _strat = IStrategy(Cavendish.clone(address(implementation), bytes32(uint(vid))));
        _strat.initialize(abi.encodePacked(vid, data));
        vaultInfo[vid].want = _strat.wantToken();
        vaultInfo[vid].active = true; //uninitialized vaults are paused; this unpauses
        emit AddVault(vid);
    }

    function createBoost(mapping(uint => IVaultHealer.VaultInfo) storage vaultInfo, BitMaps.BitMap storage activeBoosts, uint vid, address _implementation, bytes calldata initdata) external {
        if (vid >= 2**224) revert IVaultHealer.MaximizerTooDeep(vid);
        IVaultHealer.VaultInfo storage vault = vaultInfo[vid];
        uint16 nonce = vault.numBoosts;
        vault.numBoosts = nonce + 1;

        uint _boostID = (uint(bytes32(bytes4(0xB0057000 + nonce))) | vid);

        IBoostPool _boost = IBoostPool(Cavendish.clone(_implementation, bytes32(_boostID)));

        _boost.initialize(msg.sender, _boostID, initdata);
        activeBoosts.set(_boostID);
        emit AddBoost(_boostID);
    }

    //Computes the strategy address for any vid based on this contract's address and the vid's numeric value
    function strat(uint vid) internal view returns (IStrategy) {
        if (vid == 0) revert IVaultHealer.VidOutOfRange(0);
        return IStrategy(Cavendish.computeAddress(bytes32(vid)));
    }

    function strat(IVaultHealer vaultHealer, uint256 vid) internal pure returns (IStrategy) {
        if (vid == 0) revert IVaultHealer.VidOutOfRange(0);
        return IStrategy(Cavendish.computeAddress(bytes32(vid), address(vaultHealer)));
    }
	
    function boostInfo(
        uint16 len,
        BitMaps.BitMap storage activeBoosts, 
        BitMaps.BitMap storage userBoosts,
        address account,
        uint vid
    ) external view returns (
        IVaultHealer.BoostInfo[][3] memory boosts //active, finished, available
    ) {
        //Create bytes array indicating status of each boost pool and total number for each status
        bytes memory statuses = new bytes(len);
        uint numActive;
        uint numFinished;
        uint numAvailable;
        for (uint16 i; i < len; i++) {
            uint id = uint(bytes32(bytes4(0xB0057000 + i))) | vid;
            bytes1 status;

            if (userBoosts.get(id)) status = 0x01; //pool active for user
            if (activeBoosts.get(id) && boostPool(id).isActive()) status |= 0x02; //pool still paying rewards
            
            if (status == 0x00) continue; //pool finished, user isn't in, nothing to do
            else if (status == 0x01) numFinished++; //user in finished pool
            else if (status == 0x02) numAvailable++; //user not in active pool
            else numActive++; //user in active pool

            statuses[i] = status;
        }

        boosts[0] = new IVaultHealer.BoostInfo[](numActive);
        boosts[1] = new IVaultHealer.BoostInfo[](numFinished);
        boosts[2] = new IVaultHealer.BoostInfo[](numAvailable);

        uint[3] memory infoIndex;

        for (uint16 i; i < len; i++) {
            uint8 status = uint8(statuses[i]);
            if (status == 0) continue; //pool is done and user isn't in
            status %= 3;
            
            (uint boostID, IBoostPool pool) = boostPoolVid(vid, i);

            IVaultHealer.BoostInfo memory info = boosts[status][infoIndex[status]++]; //reference to the output array member where we will be storing the data

            info.id = boostID;
            (info.rewardToken, info.pendingReward) = pool.pendingReward(account);
        }
    }

    function boostPool(uint _boostID) internal view returns (IBoostPool) {
        return IBoostPool(Cavendish.computeAddress(bytes32(_boostID)));
    }

    function boostPoolVid(uint vid, uint16 n) internal view returns (uint, IBoostPool) {

        uint _boostID = (uint(bytes32(bytes4(0xB0057000 + n))) | vid);
        return (_boostID, boostPool(_boostID));
    }

	function sizeOf(address _contract) external view returns (uint256 size) {
	
		assembly ("memory-safe") {
			size := extcodesize(_contract)
		}
	}

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

library AddrCalc {

    //returns the first create address for the current address
    function configAddress() internal view returns (address configAddr) {
        assembly ("memory-safe") {
            mstore(0, or(0xd694000000000000000000000000000000000000000001000000000000000000, shl(80,address())))
            configAddr := and(0xffffffffffffffffffffffffffffffffffffffff, keccak256(0, 23)) //create address, nonce 1
        }
    }

    //returns the create address for some address and nonce
    function addressFrom(address _origin, uint _nonce) internal pure returns (address) {
        bytes32 data;
        if(_nonce == 0x00)          data = keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, bytes1(0x80)));
        else if(_nonce <= 0x7f)     data = keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, uint8(_nonce)));
        else if(_nonce <= 0xff)     data = keccak256(abi.encodePacked(bytes1(0xd7), bytes1(0x94), _origin, bytes1(0x81), uint8(_nonce)));
        else if(_nonce <= 0xffff)   data = keccak256(abi.encodePacked(bytes1(0xd8), bytes1(0x94), _origin, bytes1(0x82), uint16(_nonce)));
        else if(_nonce <= 0xffffff) data = keccak256(abi.encodePacked(bytes1(0xd9), bytes1(0x94), _origin, bytes1(0x83), uint24(_nonce)));
        else                        data = keccak256(abi.encodePacked(bytes1(0xda), bytes1(0x94), _origin, bytes1(0x84), uint32(_nonce))); // more than 2^32 nonces not realistic

        return address(uint160(uint256(data)));
    }

    //Standard function to compute a create2 address
    function computeAddress(
        bytes32 salt,
        address deployer,
        bytes32 initcodehash
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, initcodehash));
        return address(uint160(uint256(_data)));
    }

    //The nonce of a factory contract that uses CREATE, assuming no child contracts have selfdestructed
    function createFactoryNonce(address _origin) internal view returns (uint nonce) {
        unchecked {
            nonce = 1;
            uint top = 2**32;
            uint p = 1;
            while (p < top && p > 0) {
                address spawn = addressFrom(_origin, nonce + p); //
                if (spawn.code.length > 0) {
                    nonce += p;
                    p *= 2;
                    if (nonce + p > top) p = (top - nonce) / 2;
                } else {
                    top = nonce + p;
                    p /= 2;
                }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPLv2

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/Address.sol";

/// @title Tactics
/// @author ToweringTopaz
/// @notice Provides a generic method which vault strategies can use to call deposit/withdraw/balance on stakingpool or masterchef-like contracts
library Tactics {
    using Address for address;

    /*
    This library handles masterchef function call data packed as follows:

        uint256 tacticsA: 
            160: masterchef
            24: pid
            8: position of vaultSharesTotal function's returned amount within the returndata 
            32: selector for vaultSharesTotal
            32: vaultSharesTotal encoded call format

        uint256 tacticsB:
            32: deposit selector
            32: deposit encoded call format
            
            32: withdraw selector
            32: withdraw encoded call format
            
            32: harvest selector
            32: harvest encoded call format
            
            32: emergencyVaultWithdraw selector
            32: emergencyVaultWithdraw encoded call format

    Encoded calls use function selectors followed by single nibbles as follows, with the output packed to 32 bytes:
        0: end of line/null
        f: 32 bytes zero
		e: the number 1/boolean true
        4: specified amount
        3: address(this)
        2: pid
    */
    type TacticsA is bytes32;
    type TacticsB is bytes32;

    function masterchef(TacticsA tacticsA) internal pure returns (address) {
        return address(bytes20(TacticsA.unwrap(tacticsA)));
    }  
    function pid(TacticsA tacticsA) internal pure returns (uint24) {
        return uint24(bytes3(TacticsA.unwrap(tacticsA) << 160));
    }  
    function vaultSharesTotal(TacticsA tacticsA) internal view returns (uint256 amountStaked) {
        uint returnvarPosition = uint8(uint(TacticsA.unwrap(tacticsA)) >> 64); //where is our vaultshares in the return data
        uint64 encodedCall = uint64(uint(TacticsA.unwrap(tacticsA)));
        if (encodedCall == 0) return 0;
        bytes memory data = _generateCall(pid(tacticsA), encodedCall, 0); //pid, vst call, 0
        data = masterchef(tacticsA).functionStaticCall(data, "Tactics: staticcall failed");
        assembly ("memory-safe") {
            amountStaked := mload(add(data, add(0x20,returnvarPosition)))
        }
    }

    function deposit(TacticsA tacticsA, TacticsB tacticsB, uint256 amount) internal {
        _doCall(tacticsA, tacticsB, amount, 192);
    }
    function withdraw(TacticsA tacticsA, TacticsB tacticsB, uint256 amount) internal {
        _doCall(tacticsA, tacticsB, amount, 128);
    }
    function harvest(TacticsA tacticsA, TacticsB tacticsB) internal {
        _doCall(tacticsA, tacticsB, 0, 64);
    }
    function emergencyVaultWithdraw(TacticsA tacticsA, TacticsB tacticsB) internal {
        _doCall(tacticsA, tacticsB, 0, 0);
    }
    function _doCall(TacticsA tacticsA, TacticsB tacticsB, uint256 amount, uint256 offset) private {
        uint64 encodedCall = uint64(uint(TacticsB.unwrap(tacticsB)) >> offset);
        if (encodedCall == 0) return;
        bytes memory generatedCall = _generateCall(pid(tacticsA), encodedCall, amount);
        masterchef(tacticsA).functionCall(generatedCall, "Tactics: call failed");
        
    }

    function _generateCall(uint24 _pid, uint64 encodedCall, uint amount) private view returns (bytes memory generatedCall) {

        generatedCall = abi.encodePacked(bytes4(bytes8(encodedCall)));

        for (bytes4 params = bytes4(bytes8(encodedCall) << 32); params != 0; params <<= 4) {
            bytes1 p = bytes1(params) & bytes1(0xf0);
            uint256 word;
            if (p == 0x20) {
                word = _pid;
            } else if (p == 0x30) {
                word = uint(uint160(address(this)));
            } else if (p == 0x40) {
                word = amount;
			} else if (p == 0xe0) {
				word = 1;
            } else if (p != 0xf0) {
                revert("Tactics: invalid tactic");
            }
            generatedCall = abi.encodePacked(generatedCall, word);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IUniFactory.sol";
import "./IWETH.sol";

interface IUniRouter {
    function factory() external pure returns (IUniFactory);

    function WETH() external pure returns (IWETH);

    function addLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        IERC20 token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        IERC20 token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        IERC20 token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, IERC20[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, IERC20[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        IERC20 token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        IERC20 token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMagnetite {
    function findAndSavePath(address _router, IERC20 a, IERC20 b) external returns (IERC20[] memory path);
    function overridePath(address router, IERC20[] calldata _path) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IStrategy.sol";
import "./IVaultFeeManager.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./IBoostPool.sol";
import "../libraries/Cavendish.sol";

///@notice Interface for the Crystl v3 Vault central contract
interface IVaultHealer is IERC1155 {

    event AddVault(uint indexed vid);

    event Paused(uint indexed vid);
    event Unpaused(uint indexed vid);

    event Deposit(address indexed account, uint256 indexed vid, uint256 amount);
    event Withdraw(address indexed from, address indexed to, uint256 indexed vid, uint256 amount);

    event Earned(uint256 indexed vid, uint256 wantLockedTotal, uint256 totalSupply);
    event AddBoost(uint indexed boostid);
    event EnableBoost(address indexed user, uint indexed boostid);
    event BoostEmergencyWithdraw(address user, uint _boostID);
    event SetAutoEarn(uint indexed vid, bool earnBeforeDeposit, bool earnBeforeWithdraw);
    event FailedEarn(uint indexed vid, string reason);
    event FailedEarnBytes(uint indexed vid, bytes reason);
    event FailedWithdrawFee(uint indexed vid, string reason);
    event FailedWithdrawFeeBytes(uint indexed vid, bytes reason);
    event MaximizerHarvest(address indexed account, uint indexed vid, uint targetShares);
	
	error PausedError(uint256 vid); //Action cannot be completed on a paused vid
	error MaximizerTooDeep(uint256 targetVid); //Too many layers of nested maximizers (13 is plenty I should hope)
	error VidOutOfRange(uint256 vid); //Specified vid does not represent an existing vault
	error PanicCooldown(uint256 expiry); //Cannot panic this vault again until specified time
	error InvalidFallback(); //The fallback function should not be called in this context
	error WithdrawZeroBalance(address from); //User attempting to withdraw from a vault when they have zero shares
	error UnauthorizedPendingDepositAmount(); //Strategy attempting to pull more tokens from the user than authorized
    error RestrictedFunction(bytes4 selector);
    error NotStrategyImpl(IStrategy implementation);
    error ImplWrongHealer(IVaultHealer implHealer); //Attempting to use a strategy configured for another VH, not this one
    error InsufficientBalance(IERC20 token, address from, uint balance, uint requested);
    error InsufficientApproval(IERC20 token, address from, uint available, uint requested);

	error NotApprovedToEnableBoost(address account, address operator);
	error BoostPoolNotActive(uint256 _boostID);
	error BoostPoolAlreadyJoined(address account, uint256 _boostID);
	error BoostPoolNotJoined(address account, uint256 _boostID);
    error ArrayMismatch(uint lenA, uint lenB);

	error ERC1167_Create2Failed();	//Low-level error with creating a strategy proxy
	error ERC1167_ImplZeroAddress(); //If attempting to deploy a strategy with a zero implementation address
	
    ///@notice This is used solely by strategies to indirectly pull ERC20 tokens.
    function executePendingDeposit(address _to, uint192 _amount) external;
    ///@notice This is used solely by maximizer strategies to deposit their earnings
    function maximizerDeposit(uint256 _vid, uint256 _wantAmt, bytes calldata _data) external payable;
    ///@notice Compounds the listed vaults. Generally only needs to be called by an optimized earn script, not frontend users. Earn is triggered automatically on deposit and withdraw by default.
    function earn(uint256[] calldata vids) external returns (uint[] memory successGas);
    function earn(uint256[] calldata vids, bytes[] calldata data) external returns (uint[] memory successGas);

////Functions for users and frontend developers are below

    ///@notice Standard withdraw for msg.sender
    function withdraw(uint256 _vid, uint256 _wantAmt, bytes calldata _data) external;

    ///@notice Withdraw with custom to account
    function withdraw(uint256 _vid, uint256 _wantAmt, address _to, bytes calldata _data) external;

    function deposit(uint256 _vid, uint256 _wantAmt, bytes calldata _data) external payable;

    function totalSupply(uint256 vid) external view returns (uint256);

    ///@notice This returns the strategy address for any vid.
    ///@dev For dapp or contract usage, it may be better to calculate strategy addresses locally. The formula is in the function Cavendish.computeAddress
    //function strat(uint256 _vid) external view returns (IStrategy);

    struct VaultInfo {
        IERC20 want;
        uint8 noAutoEarn;
        bool active; //not paused
        uint48 lastEarnBlock;
        uint16 numBoosts;
        uint16 numMaximizers; //number of maximizer vaults pointing here. For vid 0x0045, its maximizer will be 0x00450001, 0x00450002, ...
    }

    function vaultInfo(uint vid) external view returns (IERC20, uint8, bool, uint48,uint16,uint16);

    function tokenData(address account, uint[] calldata vids) external view returns (uint[4][] memory data);

    //@notice Returns the number of non-maximizer vaults, where the want token is compounded within one strategy
    function numVaultsBase() external view returns (uint16);

    ///@notice The number of shares in a maximizer's target vault pending to a user account from said maximizer
    ///@param _account Some user account
    ///@param _vid The vid of the maximizer
    ///@dev The vid of the target is implied to be _vid >> 16
	function maximizerPendingTargetShares(address _account, uint256 _vid) external view returns (uint256);

    ///@notice The balance of a user's shares in a vault, plus any pending shares from maximizers
	function totalBalanceOf(address _account, uint256 _vid) external view returns (uint256 amount);

    ///@notice Harvests a single maximizer
    ///@param _vid The vid of the maximizer vault, which deposits into some other target
	function harvestMaximizer(uint256 _vid) external;

	///@notice Harvests all maximizers earning to the specified target vid
    ///@param _vid The vid of the target vault, to which many maximizers may deposit
    function harvestTarget(uint256 _vid) external;

    ///@notice This can be used to make two or more calls to the contract as an atomic transaction.
    ///@param inputs are the standard abi-encoded function calldata with selector. This can be any external function on vaultHealer.
    //function multicall(bytes[] calldata inputs) external returns (bytes[] memory);

    struct BoostInfo {
        uint id;
        IBoostPool pool;
        IERC20 rewardToken;
        uint pendingReward;
    }

    function vaultFeeManager() external view returns (IVaultFeeManager);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IUniPair.sol";

interface IUniFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(IERC20 tokenA, IERC20 tokenB) external view returns (IUniPair pair);
    function allPairs(uint) external view returns (IUniPair pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (IUniPair pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

// SPDX-License-Identifier: GPLv2
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IUniFactory.sol";

interface IUniPair is IERC20 {
  
  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amount1In,
      uint amount0Out,
      uint amount1Out,
      address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (IUniFactory);
  function token0() external view returns (IERC20);
  function token1() external view returns (IERC20);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../libraries/Fee.sol";

interface IVaultFeeManager {

    function getEarnFees(uint vid) external view returns (Fee.Data[3] memory fees);
    function getWithdrawFee(uint vid) external view returns (address receiver, uint16 rate);
    function getEarnFees(uint[] calldata vids) external view returns (Fee.Data[3][] memory fees);
    function getWithdrawFees(uint[] calldata vids) external view returns (Fee.Data[] memory fees);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBoostPool {
    function bonusEndBlock() external view returns (uint32);
    function BOOST_ID() external view returns (uint256);
    function joinPool(address _user, uint112 _amount) external;
    function harvest(address) external;
    function emergencyWithdraw(address _user) external returns (bool success);
    function notifyOnTransfer(address _from, address _to, uint256 _amount) external returns (bool poolDone);
    function initialize(address _owner, uint256 _boostID, bytes calldata initdata) external;
    function pendingReward(address _user) external view returns (IERC20 token, uint256 amount);
    function isActive() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

/// @title Cavendish clones
/// @author ToweringTopaz
/// @notice Creates ERC-1167 minimal proxies whose addresses depend only on the salt and deployer address
/// @dev See _fallback for important instructions

library Cavendish {

/*
    Proxy init bytecode: 

    11 bytes: 602d80343434335afa15f3

    60 push1 2d       : size
    80 dup1           : size size
    34 callvalue      : 0 size size 
    34 callvalue      : 0 0 size size 
    34 callvalue      : 0 0 0 size size 
    33 caller         : caller 0 0 0 size size
    5a gas            : gas caller 0 0 0 size size
    fa staticcall     : success size
    15 iszero         : 0 size
    f3 return         : 

*/
    
	bytes11 constant PROXY_INIT_CODE = hex'602d80343434335afa15f3';	//below is keccak256(abi.encodePacked(PROXY_INIT_CODE));
    bytes32 constant PROXY_INIT_HASH = hex'577cbdbf32026552c0ae211272febcff3ea352b0c755f8f39b49856dcac71019';

	error ERC1167_Create2Failed();
	error ERC1167_ImplZeroAddress();

    /// @notice Creates an 1167-compliant minimal proxy whose address is purely a function of the deployer address and the salt
    /// @param _implementation The contract to be cloned
    /// @param salt Used to determine and calculate the proxy address
    /// @return Address of the deployed proxy
    function clone(address _implementation, bytes32 salt) internal returns (address) {
        if (_implementation == address(0)) revert ERC1167_ImplZeroAddress();
        address instance;
        assembly ("memory-safe") {
            sstore(PROXY_INIT_HASH, shl(96, _implementation)) //store at slot PROXY_INIT_HASH which should be empty
            mstore(0, PROXY_INIT_CODE)
            instance := create2(0, 0x00, 11, salt)
            sstore(PROXY_INIT_HASH, 0) 
        }
        if (instance == address(0)) revert ERC1167_Create2Failed();
        return instance;
    }
    
    //Standard function to compute a create2 address deployed by this address, but not impacted by the target implemention
    function computeAddress(bytes32 salt) internal view returns (address) {
        return computeAddress(salt, address(this));
    }

    //Standard function to compute a create2 address, but not impacted by the target implemention
    function computeAddress(
        bytes32 salt,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, PROXY_INIT_HASH));
        return address(uint160(uint256(_data)));
    }
	
    /// @notice Called by the proxy constructor to provide the bytecode for the final proxy contract. 
    /// @dev Deployer contracts must call Cavendish._fallback() in their own fallback functions.
    ///      Generally compatible with contracts that use fallback functions. Simply call this at the
    ///       top of your fallback, and it will run only when needed.
    function _fallback() internal view {
        assembly ("memory-safe") {
            if iszero(extcodesize(caller())) { //will be, for a contract under construction
                let _implementation := sload(PROXY_INIT_HASH)
                if gt(_implementation, 0) {
                    mstore(0x00, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
                    mstore(0x0a, _implementation)
                    mstore(0x1e, 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                    return(0x00, 0x2d) //Return to external caller, not to any internal function
                }

            }
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}