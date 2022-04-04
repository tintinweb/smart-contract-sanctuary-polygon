// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/interfaces/IUniswapV2Router02.sol";
import "../utils/interfaces/IUniswapV2Factory.sol";
import "../utils/interfaces/INewNODERewardManagement.sol";
import "../utils/interfaces/IRewardPool.sol";

import "../utils/types/ERC20.sol";
import "../utils/types/Ownable.sol";

contract NodeHelper_V1_2 is Ownable {
    using SafeMath for uint256;

    INewNODERewardManagement public nodeRewardManagement;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address public PENT;

    address public vault;
    address public rewardsPool;
    address public treasury;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    uint256 public rewardsFee_Node = 50;
    uint256 public rewardsFee_Claim = 60;
    uint256 public liquidityPoolFee_Node = 50;
    uint256 public liquidityPoolFee_Claim = 20;
    uint256 public vaultFee = 10;
    uint256 public treasuryFee = 10;

    uint256 public cashoutFee = 10;

    bool private swapping = false;
    bool private swapLiquify = true;
    uint256 public swapTokensAmount = 30000000000000000000;
	uint256[] private nodeFees;

    uint256 public nodePriceLesser = 1000000000000000000;
    uint256 public nodePriceCommon = 5000000000000000000;
    uint256 public nodePriceLegendary = 10000000000000000000;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event LiquidityWalletUpdated(
        address indexed newLiquidityWallet,
        address indexed oldLiquidityWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor(
        address[] memory addresses,
        address _management,
        address _uniswapV2Router
    ) {
        nodeRewardManagement = INewNODERewardManagement(_management);

        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);

		nodeFees = [1000000000000000000, 1000000000000000000, 1000000000000000000, 1000000000000000000, 1000000000000000000, 1000000000000000000, 980000000000000000, 960000000000000000, 940000000000000000, 910000000000000000, 880000000000000000, 850000000000000000, 820000000000000000, 780000000000000000, 750000000000000000, 720000000000000000, 690000000000000000, 650000000000000000, 610000000000000000, 570000000000000000, 520000000000000000, 470000000000000000, 420000000000000000, 360000000000000000, 300000000000000000, 240000000000000000, 180000000000000000, 150000000000000000, 120000000000000000, 100000000000000000];

        PENT = addresses[0];
        vault = addresses[1];
        rewardsPool = addresses[2];
        treasury = addresses[3];

        address pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(
            uniswapV2Router.WETH(),
            PENT
        );

        if (pair == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(uniswapV2Router.WETH(), PENT);
        } else {
            uniswapV2Pair = pair;
        }
    }

    receive() external payable {}

    function getNodeNumberOf(address account) public view returns (uint256) {
        return nodeRewardManagement._getNodeNumberOf(account);
    }

    function getRewardAmount() public view returns (uint256) {
        return nodeRewardManagement._getRewardAmountOf(msg.sender);
    }

    function getFusionCost() public view returns(uint256, uint256, uint256) {
        return nodeRewardManagement._getFusionCost();
    }

    function getNodePrices() public view returns (uint256, uint256, uint256) {
        return nodeRewardManagement._getNodePrices();
    } 

    function getNodePrice(uint256 _type, bool isFusion) public view returns (uint256) {
        return nodeRewardManagement.getNodePrice(_type, isFusion);
    }

    function getTaxForFusion() public view returns (uint256, uint256, uint256) {
        return nodeRewardManagement._getTaxForFusion();
    }

    function getClaimInterval() public view returns (uint256) {
        return nodeRewardManagement.claimInterval();
    }

    function getRewardsPerMinute() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (nodeRewardManagement.rewardPerMinuteLesser(), nodeRewardManagement.rewardPerMinuteCommon(), nodeRewardManagement.rewardPerMinuteLegendary(), nodeRewardManagement.rewardsPerMinuteOMEGA(), nodeRewardManagement.rewardPerMinuteLesserStake(), nodeRewardManagement.rewardPerMinuteCommonStake(), nodeRewardManagement.rewardPerMinuteLegendaryStake());
    }

    function getNodeCounts() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return nodeRewardManagement._getNodeCounts(msg.sender);
    }

    function getNodesInfo() public view returns (string memory) {
        return nodeRewardManagement._getNodesInfo(msg.sender);
    }

    function getNodesType() public view returns (string memory) {
        return nodeRewardManagement._getNodesType(msg.sender);
    }

    function getNodesName() public view returns (string memory) {
        return nodeRewardManagement._getNodesName(msg.sender);
    }

    function getNodesCreatime() public view returns (string memory) {
        return nodeRewardManagement._getNodesCreationTime(msg.sender);
    }

	function getNodesExpireTime() public view returns (string memory) {
        return nodeRewardManagement._getNodesExpireTime(msg.sender);
    }

    function getNodesRewards() public view returns (string memory) {
        return nodeRewardManagement._getNodesRewardAvailable(msg.sender);
    }

    function getNodesLastClaims() public view returns (string memory) {
        return nodeRewardManagement._getNodesLastClaimTime(msg.sender);
    }

    function getTotalNodesCreated() public view returns (uint256) {
        return nodeRewardManagement.totalNodesCreated();
    }




















    // public functions

	function withdrawStakingPosition(uint256 index, uint256 nodeType) public {
		address account = msg.sender;

        nodeRewardManagement.withdrawAmount(account, index, nodeType);

        uint256 amount;

        if (nodeType == 1) {
            amount = nodePriceLesser;
        } else if (nodeType == 2) {
            amount = nodePriceCommon;
        } else {
            amount = nodePriceLegendary;
        }

        IRewardPool(rewardsPool).rewardTo(account, amount);
	}

	function createNodeWithStakePosition(string memory name, uint256 stakeDays, uint256 _type) public {
        require(bytes(name).length > 3 && bytes(name).length < 32, "NAME SIZE INVALID");
        require(_type > 0 && _type < 4, "NOT AVAILABLE"); 

		address sender = msg.sender;

	    require(sender != address(0), "ZERO ADDRESS");

		require(sender != vault && sender != rewardsPool && sender != treasury, "CANNOT CREATE NODE");
        require(stakeDays >= 1 && stakeDays <= 30, "STAKE TIME ERROR");

		uint256 duration = stakeDays * 1 days;
		uint256 nodeFee = nodeFees[stakeDays - 1];

		uint256 nodePrice = nodeRewardManagement.getNodePrice(_type, false);
		require(IERC20(PENT).balanceOf(sender) >= nodePrice + nodeFee, "BALANCE TOO LOW");

        nodePrice = nodePrice + nodeFee;

        uint256 paidAmount = nodeRewardManagement._compoundForNode(sender, nodePrice, _type, false);

        require(paidAmount <= nodePrice, "Incorrect Calculation when compound");

        if (paidAmount == nodePrice) {
            IRewardPool(rewardsPool).rewardTo(address(this), nodePrice);
        } else if (paidAmount < nodePrice) {
            IRewardPool(rewardsPool).rewardTo(address(this), paidAmount);
            require(IERC20(PENT).balanceOf(sender) >= nodePrice - paidAmount, "BALANCE TOO LOW");
            IERC20(PENT).transferFrom(sender, address(this), nodePrice - paidAmount);
        }

        uint256 contractTokenBalance = IERC20(PENT).balanceOf(address(this));

        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;

        if (
            swapAmountOk &&
            swapLiquify &&
            !swapping &&
            sender != owner()
        ) {
            swapping = true;

            uint256 rewardsPoolTokens = contractTokenBalance
                .mul(rewardsFee_Node)
                .div(100);
            
            IERC20(PENT).transfer(address(rewardsPool), rewardsPoolTokens);

            uint256 swapTokens = contractTokenBalance.mul(liquidityPoolFee_Node).div(
                100
            );

            swapAndLiquify(swapTokens);

            swapping = false;
        }

        nodeRewardManagement.createNode(sender, name, duration, _type, 1);
    }

    function cashoutReward(uint256 blocktime) public {
        address sender = msg.sender;
        require(sender != address(0), "ZERO ADDRESS");
        require(
            sender != treasury && sender != rewardsPool && sender != vault,
            "CANNOT CASHOUT REWARDS"
        );
        uint256 rewardAmount = nodeRewardManagement._getRewardAmountOf( sender, blocktime );
        require(
            rewardAmount > 0,
            "NOT ENOUGH REWARD TO CASH OUT"
        );

		uint256 feeAmount = rewardAmount.mul(cashoutFee).div(100);
		rewardAmount = rewardAmount.sub(feeAmount);

        if (
            cashoutFee > 0 &&
            swapLiquify
        ) {
            IRewardPool(rewardsPool).rewardTo(address(this), feeAmount * (100 - rewardsFee_Claim) / 100);
			
            uint256 swapTokens = feeAmount.mul(liquidityPoolFee_Claim).div(
                100
            );

            swapAndLiquify(swapTokens);

            uint256 vaultTokens = feeAmount.mul(vaultFee).div(100);
            swapAndSendToFee(vault, vaultTokens);

            uint256 treasuryTokens = feeAmount.mul(treasuryFee).div(100);
            swapAndSendToFee(treasury, treasuryTokens);
        }

        IRewardPool(rewardsPool).rewardTo(sender, rewardAmount);
        nodeRewardManagement._cashoutNodeReward(sender, blocktime);
    }

    function cashoutAll() public {
        address sender = msg.sender;
        
        require(
            sender != address(0),
            "ZERO ADDRESS"
        );
        require(
            sender != vault && sender != rewardsPool && sender != vault,
            "CANNOT CASHOUT REWARDS"
        );
        uint256 rewardAmount = nodeRewardManagement._getRewardAmountOf(sender);
        require(
            rewardAmount > 0,
            "NOT ENOUGH TO CASH OUT"
        );

        uint256 feeAmount = rewardAmount.mul(cashoutFee).div(100);
		rewardAmount = rewardAmount.sub(feeAmount);

        if (
            cashoutFee > 0 &&
            swapLiquify
        ) {
            IRewardPool(rewardsPool).rewardTo(address(this), feeAmount * (100 - rewardsFee_Claim) / 100);

            uint256 swapTokens = feeAmount.mul(liquidityPoolFee_Claim).div(
                100
            );

            swapAndLiquify(swapTokens);

            uint256 vaultTokens = feeAmount.mul(vaultFee).div(100);
            swapAndSendToFee(vault, vaultTokens);

            uint256 treasuryTokens = feeAmount.mul(treasuryFee).div(100);
            swapAndSendToFee(treasury, treasuryTokens);
        }

        IRewardPool(rewardsPool).rewardTo(sender, rewardAmount);
        nodeRewardManagement._cashoutAllNodesReward(sender);
    }

    function createNodeWithTokens(string memory name, uint256 _type) public {
        require(_type > 0 &&  _type < 4, "NOT ALLOWED");
        _createNodeWithTokens(name, _type, false);
    }

    function fusionNode(uint256 _method, string memory name) public {
        require(_method > 0 &&  _method < 4, "NOT ALLOWED");
        address sender = msg.sender;
        nodeRewardManagement.fusionNode(_method, sender);
        _createNodeWithTokens(name, _method.add(1), true);
    }























    // Only Owner

    function getRewardAmountOf(address account)
        public
        view
        onlyOwner
        returns (uint256)
    {
        return nodeRewardManagement._getRewardAmountOf(account);
    }

	function changeNodeFees(uint256[] memory newNodeFees) public onlyOwner {
		require(newNodeFees.length == 30, "ITEM ERROR");
		nodeFees = newNodeFees;
	}

    function changeNodePrices(uint256 newNodePriceLesser, uint256 newNodePriceCommon, uint256 newNodePriceLegendary) public onlyOwner {
        nodePriceLesser = newNodePriceLesser;
        nodePriceCommon = newNodePriceCommon;
        nodePriceLegendary = newNodePriceLegendary;
        nodeRewardManagement._changeNodePrice(newNodePriceLesser, newNodePriceCommon, newNodePriceLegendary);
    }

    function changeClaimInterval(uint256 newInterval) public onlyOwner {
        nodeRewardManagement._changeClaimInterval(newInterval);
    }

    function changeRewardsPerMinute(uint256 newPriceLesser, uint256 newPriceCommon, uint256 newPriceLegendary, uint256 newPriceOMEGA, uint256 newPriceLesserStake, uint256 newPriceCommonStake, uint256 newPriceLegendaryStake) public onlyOwner {
        nodeRewardManagement._changeRewardsPerMinute(newPriceLesser, newPriceCommon, newPriceLegendary, newPriceOMEGA, newPriceLesserStake, newPriceCommonStake, newPriceLegendaryStake);
    }

	function manualswap(uint amount) public onlyOwner {
		if (amount > IERC20(PENT).balanceOf(address(this))) amount = IERC20(PENT).balanceOf(address(this));
		swapTokensForEth(amount);
	}

	function manualsend(uint amount) public onlyOwner {
		if (amount > address(this).balance) amount = address(this).balance;
		payable(owner()).transfer(amount);
	}

    function toggleFusionMode() public onlyOwner {
        nodeRewardManagement.toggleFusionMode();
    }

    function setNodeCountForFusion(uint256 _nodeCountForLesser, uint256 _nodeCountForCommon, uint256 _nodeCountForLegendary) public onlyOwner {
        nodeRewardManagement.setNodeCountForFusion(_nodeCountForLesser, _nodeCountForCommon, _nodeCountForLegendary);
    }

    function setTaxForFusion(uint256 _taxForLesser, uint256 _taxForCommon, uint256 _taxForLegendary) public onlyOwner {
        nodeRewardManagement.setTaxForFusion(_taxForLesser, _taxForCommon, _taxForLegendary);
    }

    function updateNodeManagement(address _nodeRewardManagement) external onlyOwner {
        require(_nodeRewardManagement != address(0), "CANNOT BE ZERO");
        nodeRewardManagement = INewNODERewardManagement(_nodeRewardManagement);
    }

    function updateSwapTokensAmount(uint256 newVal) external onlyOwner {
        swapTokensAmount = newVal;
    }

    function updateVaultWall(address payable wall) external onlyOwner {
        vault = wall;
    }

    function updateRewardsWall(address payable wall) external onlyOwner {
        rewardsPool = wall;
    }

    function updateTreasuryWall(address payable wall) external onlyOwner {
        treasury = wall;
    }

    function updateRewardsFeeNode(uint256 value) external onlyOwner {
        rewardsFee_Node = value;
    }

    function updateRewardsFeeClaim(uint256 value) external onlyOwner {
        rewardsFee_Claim = value;
    }

    function updateLiquidityFeeNode(uint256 value) external onlyOwner {
        liquidityPoolFee_Node = value;
    }

    function updateLiquidityFeeClaim(uint256 value) external onlyOwner {
        liquidityPoolFee_Claim = value;
    }

    function updateVaultFee(uint256 value) external onlyOwner {
        vaultFee = value;
    }

    function updateTreasuryFee(uint256 value) external onlyOwner {
        treasuryFee = value;
    }

    function updateCashoutFee(uint256 value) external onlyOwner {
        cashoutFee = value;
    }

    function changeSwapLiquify(bool newVal) public onlyOwner {
        swapLiquify = newVal;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "ALEADY SET");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(PENT, uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function updatePENTAddress(address _PENT) public onlyOwner {
        require(_PENT != address(0), "PENT ZERO ADDRESS");
        PENT = _PENT;
    }










    // Private

    function swapAndSendToFee(address destination, uint256 tokens) private {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = (address(this).balance).sub(initialETHBalance);
        (bool success, ) = destination.call{value: newBalance}("");
        require(success, "PAYMENT FAIL");
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

	function swapTokensForEth(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
        path[0] = PENT;
        path[1] = uniswapV2Router.WETH();

        IERC20(PENT).approve(address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
	}

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        IERC20(PENT).approve(address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            PENT,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    function _createNodeWithTokens(string memory name, uint256 _type, bool isFusion) private {
        require(bytes(name).length > 3 && bytes(name).length < 20, "NAME SIZE INVALID");
        if (_type == 4) {
            require(isFusion, "ONLY ENABLE WHEN FUSING");
        }

		address sender = msg.sender;

	    require(sender != address(0), "ZERO ADDRESS");
        
		require(sender != vault && sender != rewardsPool && sender != treasury, "CANNOT CREATE NODE");
        
		uint256 nodePrice = nodeRewardManagement.getNodePrice(_type, isFusion);

        
        uint256 paidAmount = 0;
        if (nodeRewardManagement._getNodeNumberOf(sender) > 0) {
            if (isFusion) {
                paidAmount = nodeRewardManagement._compoundForNode(sender, nodePrice, _type - 1, isFusion);
            } else {
                paidAmount = nodeRewardManagement._compoundForNode(sender, nodePrice, _type, isFusion);
            }
        }

        if (paidAmount == nodePrice) {
            IRewardPool(rewardsPool).rewardTo(address(this), nodePrice);
        } else if (paidAmount < nodePrice) {
            IRewardPool(rewardsPool).rewardTo(address(this), paidAmount);
            require(IERC20(PENT).balanceOf(sender) >= nodePrice - paidAmount, "BALANCE TOO LOW");
            IERC20(PENT).transferFrom(sender, address(this), nodePrice - paidAmount);
        } else if (paidAmount > nodePrice) {
            uint256 rewardAmount = paidAmount.sub(nodePrice);

            uint256 feeAmount = rewardAmount.mul(cashoutFee).div(100);
            rewardAmount = rewardAmount.sub(feeAmount);

            if (
                cashoutFee > 0 &&
                swapLiquify
            ) {
                IRewardPool(rewardsPool).rewardTo(address(this), feeAmount * (100 - rewardsFee_Claim) / 100);

                uint256 amount = feeAmount * (100 - rewardsFee_Claim) / 100;
                
                uint256 swapTokens = amount.mul(liquidityPoolFee_Claim).div(
                    100
                );

                swapAndLiquify(swapTokens);

                uint256 vaultTokens = amount.mul(vaultFee).div(100);
                swapAndSendToFee(vault, vaultTokens);

                uint256 treasuryTokens = amount.mul(treasuryFee).div(100);
                swapAndSendToFee(treasury, treasuryTokens);
            }

            IRewardPool(rewardsPool).rewardTo(sender, rewardAmount);
        }

        if (isFusion) {
            IERC20(PENT).transfer(deadWallet, nodePrice);
        }

        uint256 contractTokenBalance = IERC20(PENT).balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;

        if (
            swapAmountOk &&
            swapLiquify &&
            !swapping &&
            sender != owner()
        ) {
            swapping = true;

            uint256 rewardsPoolTokens = contractTokenBalance
                .mul(rewardsFee_Node)
                .div(100);

            IERC20(PENT).transfer(rewardsPool, rewardsPoolTokens);
			
            uint256 swapTokens = contractTokenBalance.mul(liquidityPoolFee_Node).div(
                100
            );

            swapAndLiquify(swapTokens);

            swapping = false;
        }
        nodeRewardManagement.createNode(sender, name, 0, _type, 0);
    }

    function test() external onlyOwner {
        IRewardPool(rewardsPool).rewardTo(address(this), 100000000000000000);
        

        uint256 amount = 100000000000000000;
        
        uint256 swapTokens = amount.mul(liquidityPoolFee_Claim).div(
            100
        );

        uint256 vaultTokens = amount.mul(vaultFee).div(100);
        swapAndSendToFee(vault, vaultTokens);

        uint256 treasuryTokens = amount.mul(treasuryFee).div(100);
        swapAndSendToFee(treasury, treasuryTokens);

        swapAndLiquify(swapTokens);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface INewNODERewardManagement {
    function getNodePrice(uint256 _type, bool isFusion) external view returns (uint256);

    function createNode(address account, string memory name, uint256 expireTime, uint256 _type, uint256 isStake) external;
    
    function _getRewardAmountOf(address account) external view returns (uint256);

    function _getRewardAmountOf(address account, uint256 index) external view returns (uint256);

    function _cashoutNodeReward(address account, uint256 index) external returns (uint256);

    function _cashoutAllNodesReward(address account) external returns (uint256);

    function _getNodeNumberOf(address account) external view returns (uint256);

    function _changeNodePrice(uint256 newNodePriceOne, uint256 newNodePriceFive, uint256 newNodePriceTen) external;

    function _changeClaimInterval(uint256 newInterval) external;

    function claimInterval() external view returns (uint256);

    function _changeRewardsPerMinute(uint256 newPriceLesser, uint256 newPriceCommon, uint256 newPriceLegendary, uint256 newPriceOMEGA, uint256 newPriceLesserStake, uint256 newPriceCommonStake, uint256 newPriceLegendaryStake) external;

    function rewardPerMinuteLesser() external view returns (uint256);

    function rewardPerMinuteCommon() external view returns (uint256);

    function rewardPerMinuteLegendary() external view returns (uint256);

    function rewardsPerMinuteOMEGA() external view returns (uint256);

    function rewardPerMinuteLesserStake() external view returns (uint256);

    function rewardPerMinuteCommonStake() external view returns (uint256);

    function rewardPerMinuteLegendaryStake() external view returns (uint256);

    function _getFusionCost() external view returns (uint256, uint256, uint256);

    function _getNodePrices() external view returns (uint256, uint256, uint256);

    function _getNodeCounts(address account) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256);

    function _getTaxForFusion() external view returns (uint256, uint256, uint256);

    function _getNodesType(address account) external view returns (string memory);

    function _getNodesInfo(address account) external view returns (string memory);

    function _getNodesName(address account) external view returns (string memory);

    function _getNodesCreationTime(address account) external view returns (string memory);

    function _getNodesExpireTime(address account) external view returns (string memory);

    function _getNodesRewardAvailable(address account) external view returns (string memory);

    function _getNodesLastClaimTime(address account) external view returns (string memory);

    function totalNodesCreated() external view returns (uint256);

    // Fusion
    function toggleFusionMode() external;

    function setNodeCountForFusion(uint256 _nodeCountForLesser, uint256 _nodeCountForCommon, uint256 _nodeCountForLegendary) external;

    function setTaxForFusion(uint256 _taxForLesser, uint256 _taxForCommon, uint256 _taxForLegendary) external;

    function fusionNode(uint256 _method, address _account) external;

    function withdrawAmount(address account, uint256 index, uint256 nodeType) external;

    function _compoundForNode(address account, uint256 amount, uint256 _type, bool isFusion) external returns(uint256);

    // migrate
    function migrateNode(address _account, string memory _name, uint256 _creationTime, uint256 _lastClaimTime, uint256 _expireTime, uint256 _type, uint256 _isStake, uint256 _rewardedAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IRewardPool {
    function rewardTo(address _account, uint256 _rewardAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
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
        address token,
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
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
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
        address token,
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
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
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
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Metadata.sol";

import "../libraries/SafeMath.sol";

contract ERC20 is IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}